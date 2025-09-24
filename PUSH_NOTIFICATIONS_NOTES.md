Push notifications setup notes

Overview
- Client integrates firebase_messaging to register a device token and save it into Firestore collection `device_tokens` with uid/site metadata.
- Cloud Functions create documents in `notifications_caisse` for collectes/achats and overdue credits.
- A trigger `pushOnNotificationCreated` fans out an FCM push to all `device_tokens` for the same site whenever a new notification is created.

Web specifics
- The service worker `web/firebase-messaging-sw.js` is added to receive background notifications on Flutter Web.
- Ensure hosting deploy includes this file at the root of the web app. Flutter serves from `/`, so this path is correct.

Testing checklist
1) Run the app, login, and confirm a document appears in `device_tokens` with fields: token, uid, site, platform, updatedAt.
2) Create a new collecte (or achat) record under the site to trigger a notification in `notifications_caisse`.
3) Confirm a push arrives on the device (foreground and background). On web, a browser notification prompt may be required.
4) For overdue credits: mark a vente with statut `creditEnAttente` and backdate `dateVente` more than 30 days, then run the scheduled function once via console or wait for the daily schedule.

Notes
- Functions region: africa-south1 (aligned with Firestore location).
- If pushes are not received: check Cloud Functions logs for `pushOnNotificationCreated`, ensure tokens exist for the corresponding site, and verify browser notification permissions.
