/**
 * Notifications backend
 * - Creates notifications in `notifications_caisse` when new collectes are recorded
 * - Schedules a daily job to notify overdue credits (>= 30 days)
 */

import { setGlobalOptions } from "firebase-functions/v2";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

// Initialize Admin SDK once
initializeApp();
const db = getFirestore();
const messaging = getMessaging();

// Use same region as Firestore to reduce latency
setGlobalOptions({ region: "africa-south1" });

// Shared helper to create a notification document
async function createNotification(params: {
    site: string;
    type: string;
    titre: string;
    message: string;
    priorite?: "basse" | "normale" | "haute";
    data?: Record<string, unknown>;
    id?: string; // optional deterministic id for idempotence
}) {
    const id = params.id ?? `NOTIF_${Date.now()}`;
    const doc = {
        id,
        type: params.type,
        site: params.site,
        dateCreation: FieldValue.serverTimestamp(),
        titre: params.titre,
        message: params.message,
        statut: "non_lue",
        priorite: params.priorite ?? "normale",
        donnees: params.data ?? {},
    };
    await db.collection("notifications_caisse").doc(id).set(doc, { merge: false });
    logger.info(`[notifications] created`, { id, type: params.type, site: params.site });
}

// ============ Collecte notifications (onCreate) ============

export const onRecolteCreated = onDocumentCreated(
    "Sites/{site}/nos_collectes_recoltes/{docId}",
    async (event) => {
        const site = event.params["site"] as string;
        const data = event.data?.data() ?? {};
        const poidsTotal = data.poidsTotal ?? data.totalPoids ?? data.weight ?? null;
        const montantTotal = data.montantTotal ?? data.total ?? null;
        const titre = "Nouvelle collecte – Récoltes";
        const message = `Une collecte Récoltes a été enregistrée${poidsTotal ? ` · ${poidsTotal} kg` : ""
            }${montantTotal ? ` · ${montantTotal} FCFA` : ""}`;
        await createNotification({
            site,
            type: "collecte_recolte",
            titre,
            message,
            priorite: "normale",
            data: { docId: event.params["docId"], poidsTotal, montantTotal },
        });
    }
);

export const onScoopCreated = onDocumentCreated(
    "Sites/{site}/nos_achats_scoop_contenants/{docId}",
    async (event) => {
        const site = event.params["site"] as string;
        const data = event.data?.data() ?? {};
        const poidsTotal = data.total_poids ?? data.poidsTotal ?? null;
        const montantTotal = data.total_montant ?? data.montantTotal ?? null;
        const titre = "Nouvel achat – SCOOP";
        const message = `Un achat SCOOP a été enregistré${poidsTotal ? ` · ${poidsTotal} kg` : ""
            }${montantTotal ? ` · ${montantTotal} FCFA` : ""}`;
        await createNotification({
            site,
            type: "collecte_scoop",
            titre,
            message,
            priorite: "normale",
            data: { docId: event.params["docId"], poidsTotal, montantTotal },
        });
    }
);

export const onIndividuelCreated = onDocumentCreated(
    "Sites/{site}/nos_achats_individuels/{docId}",
    async (event) => {
        const site = event.params["site"] as string;
        const data = event.data?.data() ?? {};
        const poidsTotal = data.total_poids ?? data.poidsTotal ?? null;
        const montantTotal = data.total_montant ?? data.montantTotal ?? null;
        const titre = "Nouvel achat – Individuel";
        const message = `Un achat Individuel a été enregistré${poidsTotal ? ` · ${poidsTotal} kg` : ""
            }${montantTotal ? ` · ${montantTotal} FCFA` : ""}`;
        await createNotification({
            site,
            type: "collecte_individuel",
            titre,
            message,
            priorite: "normale",
            data: { docId: event.params["docId"], poidsTotal, montantTotal },
        });
    }
);

export const onMiellerieCreated = onDocumentCreated(
    // NOTE: Project uses 'nos_collecte_mielleries' for Miellerie collectes
    "Sites/{site}/nos_collecte_mielleries/{docId}",
    async (event) => {
        const site = event.params["site"] as string;
        const data = event.data?.data() ?? {};
        const poidsTotal = data.poidsTotal ?? null;
        const montantTotal = data.montantTotal ?? null;
        const titre = "Nouvelle collecte – Miellerie";
        const message = `Une collecte Miellerie a été enregistrée${poidsTotal ? ` · ${poidsTotal} kg` : ""
            }${montantTotal ? ` · ${montantTotal} FCFA` : ""}`;
        await createNotification({
            site,
            type: "collecte_miellerie",
            titre,
            message,
            priorite: "normale",
            data: { docId: event.params["docId"], poidsTotal, montantTotal },
        });
    }
);

// ============ Scheduled notifications for overdue credits ============

export const notifyOverdueCredits = onSchedule({
    schedule: "0 6 * * *", // every day at 06:00
    timeZone: "Africa/Abidjan",
    retryCount: 3,
}, async () => {
    logger.info("[scheduler] Checking for overdue credits (>=30 days)");
    const threshold = new Date();
    threshold.setDate(threshold.getDate() - 30);

    // Iterate sites under root collection 'Vente/{site}/ventes'
    const sitesSnap = await db.collection("Vente").listDocuments();
    for (const siteDoc of sitesSnap) {
        const site = siteDoc.id;
        try {
            // Fetch credit ventes, filter by date in code to avoid composite indexes
            const ventesSnap = await db
                .collection("Vente").doc(site)
                .collection("ventes")
                .where("statut", "==", "creditEnAttente")
                .get();

            if (ventesSnap.empty) {
                continue;
            }

            for (const doc of ventesSnap.docs) {
                const v = doc.data();
                const venteId = v.id ?? doc.id;
                const client = v.clientNom ?? "Client";
                const restant = typeof v.montantRestant === "number" ? v.montantRestant : null;
                const dateVente: Timestamp | null = v.dateVente ?? null;
                if (dateVente && dateVente.toDate() > threshold) {
                    continue; // not overdue yet
                }
                const titre = "Crédit en retard (>= 30 jours)";
                const message = `Le crédit du client ${client} est en retard${restant ? ` · ${restant} FCFA` : ""}`;
                const notifId = `credit_overdue_${site}_${venteId}`;

                // Idempotent creation
                const notifRef = db.collection("notifications_caisse").doc(notifId);
                const existing = await notifRef.get();
                if (!existing.exists) {
                    await notifRef.set({
                        id: notifId,
                        type: "credit_overdue",
                        site,
                        dateCreation: FieldValue.serverTimestamp(),
                        titre,
                        message,
                        statut: "non_lue",
                        priorite: "haute",
                        donnees: {
                            venteId,
                            client,
                            montantRestant: restant,
                            dateVente,
                        },
                    });
                    logger.info("[scheduler] overdue credit notified", { site, venteId });
                }
            }
        } catch (err) {
            logger.error("[scheduler] error while scanning site", { site, err });
        }
    }
});

// ============ Push FCM when a new notification is created ============
export const pushOnNotificationCreated = onDocumentCreated(
    "notifications_caisse/{notifId}",
    async (event) => {
        const data = event.data?.data();
        if (!data) return;
        const site = (data.site as string) || "";
        if (!site) return;

        const title = (data.titre as string) || "Notification";
        const body = (data.message as string) || "Vous avez une nouvelle notification";
        const type = (data.type as string) || "info";

        // Fetch tokens for this site
        const tokensSnap = await db
            .collection("device_tokens")
            .where("site", "==", site)
            .get();
        if (tokensSnap.empty) return;

        const tokens: string[] = tokensSnap.docs
            .map((d) => (d.data().token as string) || "")
            .filter((t) => !!t);
        if (tokens.length === 0) return;

        // Send data-only message with notification payload for platforms that show it
        await messaging.sendEachForMulticast({
            tokens,
            data: {
                type,
                site,
                titre: title,
                message: body,
                notifId: (data.id as string) || event.params["notifId"],
            },
            notification: {
                title: title,
                body: body,
            },
        });
    }
);
