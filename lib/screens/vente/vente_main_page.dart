import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../utils/smart_appbar.dart';
import 'package:flutter/foundation.dart';
import 'pages/vente_commercial_page.dart';
import '../../authentication/user_session.dart';
import 'pages/nouvelle_gestion_commerciale.dart';
import 'controllers/espace_commercial_controller.dart';

/// 🛒 PAGE PRINCIPALE DU MODULE DE VENTE
///
/// Point d'entrée du module de gestion des ventes

class VenteMainPage extends StatelessWidget {
  const VenteMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final userSession = Get.find<UserSession>();
    final userRole = userSession.role ?? '';

    // ⚡ IMPORTANT: Initialiser le controller central dès l'entrée dans le module vente
    if (!Get.isRegistered<EspaceCommercialController>()) {
      Get.put(EspaceCommercialController(), permanent: true);
      debugPrint('🔧 [VenteMainPage] EspaceCommercialController initialisé');
    }

    // Déterminer les permissions
    final isAdmin = userRole == 'Admin';
    final isMagazinier = userRole == 'Magazinier';
    final isGestionnaire = userRole == 'Gestionnaire Commercial';
    final isCommercial = userRole == 'Commercial';

    final canManageStock = isAdmin || isMagazinier || isGestionnaire;
    final canSell = isCommercial || isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: SmartAppBar(
        title: "🛒 Gestion des Ventes",
        backgroundColor: const Color(0xFF1976D2),
        onBackPressed: () => Get.back(),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          children: [
            _buildWelcomeSection(isMobile, userSession),
            const SizedBox(height: 32),
            _buildAccessCards(isMobile, canManageStock, canSell),
            const SizedBox(height: 32),
            _buildInfoSection(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(bool isMobile, UserSession userSession) {
    final userName = userSession.email?.split('@')[0] ?? 'Utilisateur';
    final userRole = userSession.role ?? 'Utilisateur';

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('🛒', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue $userName',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Module de Gestion des Ventes',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isMobile ? 14 : 16,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    userRole,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessCards(bool isMobile, bool canManageStock, bool canSell) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accès aux fonctionnalités',
          style: TextStyle(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        if (isMobile)
          Column(
            children: [
              // MODULE COMMERCIAL PRINCIPAL
              if (canManageStock)
                _buildAccessCard(
                  '🚀 Gestion Commerciale',
                  'Module optimisé avec gestion intelligente des lots, attributions en temps réel et statistiques avancées',
                  Icons.auto_graph,
                  const Color(0xFF4CAF50),
                  () => Get.to(() => const NouvelleGestionCommerciale()),
                  isMobile,
                ),
              if (canManageStock) const SizedBox(height: 16),
              if (canSell)
                _buildAccessCard(
                  'Espace Commercial',
                  'Effectuer des ventes, restitutions et déclarer des pertes',
                  Icons.point_of_sale,
                  const Color(0xFF9C27B0),
                  () => Get.to(() => const VenteCommercialPage()),
                  isMobile,
                ),
            ],
          )
        else
          Column(
            children: [
              // MODULE COMMERCIAL PRINCIPAL
              if (canManageStock)
                _buildAccessCard(
                  '🚀 Gestion Commerciale',
                  'Module optimisé avec gestion intelligente des lots, attributions en temps réel et statistiques avancées',
                  Icons.auto_graph,
                  const Color(0xFF4CAF50),
                  () => Get.to(() => const NouvelleGestionCommerciale()),
                  isMobile,
                ),
              if (canManageStock && canSell) const SizedBox(height: 16),
              if (canSell)
                _buildAccessCard(
                  'Espace Commercial',
                  'Effectuer des ventes, restitutions et déclarer des pertes',
                  Icons.point_of_sale,
                  const Color(0xFF9C27B0),
                  () => Get.to(() => const VenteCommercialPage()),
                  isMobile,
                ),
            ],
          ),
        if (!canManageStock && !canSell)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.lock, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Accès restreint. Contactez votre administrateur pour obtenir les permissions nécessaires.',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAccessCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isMobile, {
    bool isNew = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 20 : 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: isMobile ? 24 : 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          // 🆕 Badge NOUVEAU
                          if (isNew)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF6B35),
                                    Color(0xFFF7931E)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.auto_awesome,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'NOUVEAU',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isMobile ? 9 : 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: color, size: 16),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue.shade600),
              const SizedBox(width: 12),
              Text(
                'À propos du module',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Le module de gestion des ventes permet de :\n\n'
            '• 📦 Gérer les produits conditionnés disponibles\n'
            '• 🛒 Créer des prélèvements pour les commerciaux\n'
            '• 💰 Enregistrer les ventes avec détails clients\n'
            '• 🔄 Traiter les restitutions de produits invendus\n'
            '• ⚠️ Déclarer et valider les pertes\n'
            '• 📊 Suivre les statistiques de performance\n\n'
            'Chaque action est tracée et les stocks sont automatiquement mis à jour.',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
