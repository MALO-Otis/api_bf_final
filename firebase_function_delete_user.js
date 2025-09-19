// Firebase Function pour supprimer les utilisateurs de Firebase Auth
// Placez ce code dans functions/index.js de votre projet Firebase

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialiser Firebase Admin (si pas déjà fait)
if (!admin.apps.length) {
    admin.initializeApp();
}

/**
 * Fonction Cloud qui surveille les demandes de suppression d'utilisateurs
 * Se déclenche quand un document est créé dans 'auth_deletion_requests'
 */
exports.deleteUserFromAuth = functions.firestore
    .document('auth_deletion_requests/{requestId}')
    .onCreate(async (snap, context) => {
        const requestId = context.params.requestId;
        const data = snap.data();

        console.log(`🗑️ Nouvelle demande de suppression: ${requestId}`);
        console.log(`👤 Utilisateur: ${data.email} (ID: ${data.userId})`);
        console.log(`👨‍💼 Demandé par: ${data.requestedBy}`);

        try {
            // 1. Vérifier que l'utilisateur existe dans Firebase Auth
            let userRecord;
            try {
                userRecord = await admin.auth().getUser(data.userId);
                console.log(`✅ Utilisateur trouvé dans Firebase Auth: ${userRecord.email}`);
            } catch (error) {
                if (error.code === 'auth/user-not-found') {
                    console.log(`⚠️ Utilisateur déjà supprimé de Firebase Auth: ${data.userId}`);

                    // Marquer comme complété même si déjà supprimé
                    await snap.ref.update({
                        status: 'completed',
                        completedAt: admin.firestore.FieldValue.serverTimestamp(),
                        note: 'Utilisateur déjà supprimé de Firebase Auth'
                    });

                    return;
                }
                throw error;
            }

            // 2. Supprimer l'utilisateur de Firebase Auth
            await admin.auth().deleteUser(data.userId);
            console.log(`✅ Utilisateur ${data.email} supprimé de Firebase Auth`);

            // 3. Marquer la demande comme traitée avec succès
            await snap.ref.update({
                status: 'completed',
                completedAt: admin.firestore.FieldValue.serverTimestamp(),
                deletedFromAuth: true,
                note: `Utilisateur ${data.email} supprimé avec succès de Firebase Auth`
            });

            console.log(`🎉 Suppression terminée avec succès pour: ${data.email}`);

            // 4. Optionnel: Envoyer une notification ou log dans une autre collection
            await admin.firestore().collection('admin_notifications').add({
                type: 'user_deleted',
                userId: data.userId,
                userEmail: data.email,
                deletedBy: data.requestedBy,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                message: `Utilisateur ${data.email} supprimé définitivement par ${data.requestedBy}`
            });

        } catch (error) {
            console.error(`❌ Erreur lors de la suppression de ${data.email}:`, error);

            // Marquer la demande comme échouée
            await snap.ref.update({
                status: 'error',
                error: error.message,
                errorCode: error.code || 'unknown',
                errorAt: admin.firestore.FieldValue.serverTimestamp(),
                note: `Échec de la suppression: ${error.message}`
            });

            // Optionnel: Envoyer une alerte aux administrateurs
            await admin.firestore().collection('admin_notifications').add({
                type: 'user_deletion_error',
                userId: data.userId,
                userEmail: data.email,
                requestedBy: data.requestedBy,
                error: error.message,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                priority: 'high'
            });
        }
    });

/**
 * Fonction pour nettoyer les anciennes demandes de suppression
 * À exécuter périodiquement (par exemple, tous les jours)
 */
exports.cleanupDeletionRequests = functions.pubsub
    .schedule('every 24 hours')
    .onRun(async (context) => {
        console.log('🧹 Nettoyage des anciennes demandes de suppression...');

        // Supprimer les demandes terminées depuis plus de 30 jours
        const cutoffDate = new Date();
        cutoffDate.setDate(cutoffDate.getDate() - 30);

        const oldRequests = await admin.firestore()
            .collection('auth_deletion_requests')
            .where('status', 'in', ['completed', 'error'])
            .where('completedAt', '<', cutoffDate)
            .get();

        const batch = admin.firestore().batch();
        let deleteCount = 0;

        oldRequests.forEach((doc) => {
            batch.delete(doc.ref);
            deleteCount++;
        });

        if (deleteCount > 0) {
            await batch.commit();
            console.log(`✅ ${deleteCount} anciennes demandes supprimées`);
        } else {
            console.log('ℹ️ Aucune ancienne demande à supprimer');
        }

        return null;
    });

/**
 * Fonction HTTP pour vérifier le statut d'une demande de suppression
 * Utile pour le débogage ou le monitoring
 */
exports.checkDeletionStatus = functions.https.onRequest(async (req, res) => {
    // Vérifier l'authentification (ajoutez vos propres vérifications)
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Non autorisé' });
    }

    const requestId = req.query.requestId;
    if (!requestId) {
        return res.status(400).json({ error: 'requestId requis' });
    }

    try {
        const doc = await admin.firestore()
            .collection('auth_deletion_requests')
            .doc(requestId)
            .get();

        if (!doc.exists) {
            return res.status(404).json({ error: 'Demande non trouvée' });
        }

        const data = doc.data();
        return res.json({
            requestId,
            status: data.status,
            userEmail: data.email,
            requestedBy: data.requestedBy,
            requestedAt: data.requestedAt,
            completedAt: data.completedAt,
            error: data.error,
            note: data.note
        });

    } catch (error) {
        console.error('Erreur vérification statut:', error);
        return res.status(500).json({ error: 'Erreur serveur' });
    }
});

/**
 * Instructions de déploiement:
 * 
 * 1. Installer les dépendances:
 *    npm install firebase-functions firebase-admin
 * 
 * 2. Déployer les fonctions:
 *    firebase deploy --only functions
 * 
 * 3. Configurer les permissions Firestore pour les fonctions
 * 
 * 4. Tester avec une demande de suppression test
 */

