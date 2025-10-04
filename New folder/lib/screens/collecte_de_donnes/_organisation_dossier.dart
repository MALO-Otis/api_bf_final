/*
 * ====================================================================
 * ORGANISATION DU DOSSIER COLLECTE DE DONNÉES
 * ====================================================================
 * 
 * Ce dossier contient à la fois les anciens et nouveaux codes de collecte.
 * Voici l'organisation :
 * 
 * NOUVEAU CODE (ACTIF) :
 * ----------------------
 * - nouvelle_collecte_recolte.dart         → Nouveau formulaire moderne de collecte
 * - utilitaire_des_formulaires.dart        → Utilitaires pour les nouveaux formulaires
 * - widgets/ (dossier)                     → Widgets réutilisables pour nouveaux formulaires
 * 
 * ANCIEN CODE (DÉSACTIVÉ - RÉFÉRENCE SEULEMENT) :
 * ------------------------------------------------
 * - collecte_donnes.dart                   → Ancien système de collecte (DÉSACTIVÉ)
 * - mes_collectes.dart                     → Gestion des collectes (peut contenir ancien code)
 * - modifier_collecte.dart                 → Modification des collectes (ancien système)
 * - modifier_collecte_Indiv.dart          → Modification collectes individuelles
 * - modifier_collecte_recolte.dart        → Modification collectes récolte
 * - modifier_collecte_SCOOP.dart          → Modification collectes SCOOP
 * - selecteur_florale.dart                → Sélecteur de prédominance florale
 * - _ancien_code_reference.dart           → Structures de référence de l'ancien code
 * 
 * NOTES IMPORTANTES :
 * -------------------
 * 1. Seuls les fichiers du "NOUVEAU CODE" doivent être utilisés en production
 * 2. Les fichiers "ANCIEN CODE" sont conservés pour extraction de données
 * 3. Tous les imports vers l'ancien code sont désactivés
 * 4. Pour utiliser une fonctionnalité, privilégier toujours le nouveau code
 * 
 * MIGRATION EN COURS :
 * --------------------
 * - ✅ Nouvelle collecte récolte (nouvelle_collecte_recolte.dart)
 * - ⏳ Migration des autres types de collecte (à venir)
 * - ⏳ Migration de l'historique et visualisation (à venir)
 * 
 */

/*
 * ====================================================================
 * ÉTAT ACTUEL DES DÉSACTIVATIONS - MISE À JOUR
 * ====================================================================
 * 
 * ANCIEN CODE DÉSACTIVÉ (CONSERVÉ POUR EXTRACTION) :
 * ---------------------------------------------------
 * ✅ collecte_donnes.dart                   → Entièrement désactivé (imports commentés, code en bloc /* */)
 * ✅ selecteur_florale.dart                → Entièrement désactivé (imports commentés, code en bloc /* */)
 * ✅ modifier_collecte.dart                → Entièrement désactivé (imports commentés, code en bloc /* */)
 * ✅ modifier_collecte_recolte.dart        → Entièrement désactivé (imports commentés, code en bloc /* */)
 * ✅ modifier_collecte_Indiv_disabled.dart         → Désactivé et archivé
 * ✅ modifier_collecte_SCOOP_disabled.dart         → Désactivé et archivé
 * ⚠️  mes_collectes.dart                   → Partiellement désactivé (imports anciens commentés, fonctions de modification désactivées)
 * 
 * NOUVEAU CODE ACTIF :
 * --------------------
 * ✅ nouvelle_collecte_recolte.dart         → Nouveau formulaire moderne de collecte
 * ✅ utilitaire_des_formulaires.dart        → Utilitaires pour les nouveaux formulaires
 * ✅ widgets/ (dossier)                     → Widgets réutilisables pour nouveaux formulaires
 * 
 * DÉPENDANCES NETTOYÉES :
 * -----------------------
 * ✅ main.dart                             → Import collecte_donnes.dart commenté, route mise à jour
 * ✅ dashboard.dart                        → Import collecte_donnes.dart commenté, navigation mise à jour
 * 
 * ACTIONS RESTANTES :
 * -------------------
 * 1. Désactiver modifier_collecte_Indiv.dart et modifier_collecte_SCOOP.dart
 * 2. Nettoyer les variables inutilisées dans mes_collectes.dart
 * 3. Tester l'application pour s'assurer qu'aucune référence active à l'ancien code ne subsiste
 * 4. Optionnel : Migrer les fonctionnalités utiles vers le nouveau système
 * 
 */
