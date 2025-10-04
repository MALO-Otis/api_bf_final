import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../authentication/user_session.dart';
import '../pages/admin_validation_simplifiee_page.dart';
import '../services/transaction_commerciale_service.dart';
import '../pages/caisse_recuperation_prelevements_page.dart';

/// 🔗 MODULE D'INTÉGRATION SYSTÈME DE GESTION TRANSACTIONS COMMERCIALES
///
/// Ce module centralise l'accès aux nouvelles fonctionnalités de gestion des transactions :
/// - Interface caisse de récupération des prélèvements
/// - Interface admin de validation des transactions
/// - Navigation contextuelle selon le rôle utilisateur

class TransactionCommercialeModule {
  static final TransactionCommercialeModule _instance =
      TransactionCommercialeModule._internal();
  factory TransactionCommercialeModule() => _instance;
  TransactionCommercialeModule._internal();

  /// Instance du service principal
  static TransactionCommercialeService get service =>
      TransactionCommercialeService.instance;

  /// Navigation vers l'interface caisse
  static void ouvrirInterfaceCaisse() {
    final userSession = Get.find<UserSession>();

    if (userSession.site == null || userSession.site!.isEmpty) {
      Get.snackbar(
        '⚠️ Site requis',
        'Vous devez être assigné à un site pour accéder à cette fonctionnalité.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    Get.to(() => const CaisseRecuperationPrelevementsPage());
  }

  /// Navigation vers l'interface admin
  static void ouvrirInterfaceAdmin() {
    final userSession = Get.find<UserSession>();

    if (!_isAdmin(userSession)) {
      Get.snackbar(
        '🚫 Accès refusé',
        'Seuls les administrateurs peuvent accéder à cette fonctionnalité.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    Get.to(() => const AdminValidationSimplifiePage());
  }

  /// Vérification des droits admin
  static bool _isAdmin(UserSession userSession) {
    // Vérification simple basée sur le nom d'utilisateur ou d'autres critères
    final nom = userSession.nom?.toLowerCase() ?? '';
    return nom.contains('admin') ||
        nom.contains('superviseur') ||
        nom.contains('gestionnaire');
  }

  /// Menu contextuel de navigation selon le rôle
  static Widget buildMenuContextuel() {
    return Builder(
      builder: (context) {
        final userSession = Get.find<UserSession>();
        final isAdmin = _isAdmin(userSession);
        final hasSite =
            userSession.site != null && userSession.site!.isNotEmpty;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête du menu
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1F2937),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_tree, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Gestion Transactions',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Options du menu
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Interface Caisse
                  ListTile(
                    leading: Icon(
                      Icons.point_of_sale,
                      color: hasSite ? const Color(0xFF0EA5E9) : Colors.grey,
                    ),
                    title: const Text('Interface Caisse'),
                    subtitle: const Text('Récupération des prélèvements'),
                    trailing: Icon(
                      hasSite ? Icons.arrow_forward_ios : Icons.lock,
                      size: 16,
                      color: hasSite ? Colors.grey : Colors.red,
                    ),
                    onTap: hasSite ? ouvrirInterfaceCaisse : null,
                    enabled: hasSite,
                  ),

                  if (hasSite && isAdmin) const Divider(),

                  // Interface Admin
                  if (isAdmin)
                    ListTile(
                      leading: const Icon(
                        Icons.admin_panel_settings,
                        color: Color(0xFF7C3AED),
                      ),
                      title: const Text('Interface Admin'),
                      subtitle: const Text('Validation des transactions'),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: ouvrirInterfaceAdmin,
                    ),

                  // Informations utilisateur
                  const Divider(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Utilisateur: ${userSession.nom ?? "Non défini"}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Site: ${userSession.site ?? "Non assigné"}',
                          style: TextStyle(
                            fontSize: 12,
                            color: hasSite ? Colors.grey[600] : Colors.red,
                          ),
                        ),
                        Text(
                          'Rôle: ${isAdmin ? "Administrateur" : "Utilisateur"}',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isAdmin ? Colors.purple[600] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Bouton d'accès rapide pour le dashboard commercial
  static Widget buildBoutonAccesDashboard() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFF0EA5E9), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _ouvrirMenuContextuel(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.account_tree,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gestion Transactions',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Validation et suivi des prélèvements',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Ouverture du menu contextuel
  static void _ouvrirMenuContextuel() {
    Get.bottomSheet(
      buildMenuContextuel(),
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
    );
  }

  /// Widget de notification pour les nouveaux prélèvements (pour les caissiers)
  static Widget buildNotificationCaisse() {
    final userSession = Get.find<UserSession>();
    final site = userSession.site;

    if (site == null || site.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.getNotificationsCaisse(site),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];
        final nombreNonLues =
            notifications.where((n) => n['statut'] != 'lue').length;

        if (nombreNonLues == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            color: const Color(0xFF0EA5E9),
            child: ListTile(
              leading:
                  const Icon(Icons.notifications_active, color: Colors.white),
              title: Text(
                '$nombreNonLues nouveau${nombreNonLues > 1 ? 'x' : ''} prélèvement${nombreNonLues > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Appuyez pour voir les détails',
                style: TextStyle(color: Colors.white70),
              ),
              trailing: const Icon(Icons.arrow_forward, color: Colors.white),
              onTap: ouvrirInterfaceCaisse,
            ),
          ),
        );
      },
    );
  }

  /// Widget de statistiques rapides pour l'admin
  static Widget buildStatistiquesRapides() {
    final userSession = Get.find<UserSession>();

    if (!_isAdmin(userSession)) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<Map<String, dynamic>>(
      stream: service.getStatistiquesAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data ?? {};
        final recuperees = stats['recuperees'] ?? 0;

        if (recuperees == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            color: const Color(0xFF7C3AED),
            child: ListTile(
              leading: const Icon(Icons.fact_check, color: Colors.white),
              title: Text(
                '$recuperees transaction${recuperees > 1 ? 's' : ''} à valider',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Validation administrative requise',
                style: TextStyle(color: Colors.white70),
              ),
              trailing: const Icon(Icons.arrow_forward, color: Colors.white),
              onTap: ouvrirInterfaceAdmin,
            ),
          ),
        );
      },
    );
  }

  /// Initialisation du module (à appeler au démarrage de l'app)
  static void initialiser() {
    // Enregistrement du service GetX
    if (!Get.isRegistered<TransactionCommercialeService>()) {
      // Create and register the service directly to avoid calling the
      // `TransactionCommercialeService.instance` getter which uses Get.find()
      // and will throw if the service isn't already registered.
      Get.put(TransactionCommercialeService());
    }
  }
}
