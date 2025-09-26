import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/user_role_service.dart';
import '../../../authentication/user_session.dart';

class ControleurDashboard extends StatefulWidget {
  const ControleurDashboard({super.key});

  @override
  State<ControleurDashboard> createState() => _ControleurDashboardState();
}

class _ControleurDashboardState extends State<ControleurDashboard> {
  final UserSession userSession = Get.find<UserSession>();
  final UserRoleService roleService = Get.find<UserRoleService>();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width < 1024;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header personnalisé
          _buildWelcomeSection(isMobile),
          const SizedBox(height: 24),

          // KPIs spécifiques au contrôleur
          _buildKPISection(isMobile, isTablet),
          const SizedBox(height: 24),

          // Actions rapides
          _buildQuickActionsSection(isMobile, isTablet),
          const SizedBox(height: 24),

          // Contrôles en attente
          _buildPendingControlsSection(isMobile),
          const SizedBox(height: 24),

          // Statistiques de contrôle
          _buildControlStatsSection(isMobile, isTablet),
          const SizedBox(height: 24),

          // Activité récente
          _buildRecentActivitySection(isMobile),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isMobile ? 30 : 40,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(
              Icons.verified_user,
              size: isMobile ? 30 : 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, ${userSession.nom}',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Contrôleur Qualité - ${userSession.site}',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Votre mission : Garantir la qualité de nos produits',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.white.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPISection(bool isMobile, bool isTablet) {
    final kpis = [
      {
        'title': 'Produits Contrôlés',
        'value': '147',
        'subtitle': 'Cette semaine',
        'icon': Icons.fact_check,
        'color': const Color(0xFF4CAF50),
        'trend': '+12%',
      },
      {
        'title': 'Taux Conformité',
        'value': '94.2%',
        'subtitle': 'Moyenne mensuelle',
        'icon': Icons.check_circle,
        'color': const Color(0xFF2196F3),
        'trend': '+2.1%',
      },
      {
        'title': 'En Attente',
        'value': '23',
        'subtitle': 'À contrôler',
        'icon': Icons.pending,
        'color': const Color(0xFFFF9800),
        'trend': '-5',
      },
      {
        'title': 'Rejets',
        'value': '8',
        'subtitle': 'Cette semaine',
        'icon': Icons.cancel,
        'color': const Color(0xFFF44336),
        'trend': '-3',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : (isTablet ? 2 : 4),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isMobile ? 1.1 : 1.3,
      ),
      itemCount: kpis.length,
      itemBuilder: (context, index) {
        final kpi = kpis[index];
        return _buildKPICard(kpi, isMobile);
      },
    );
  }

  Widget _buildKPICard(Map<String, dynamic> kpi, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (kpi['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  kpi['icon'],
                  color: kpi['color'],
                  size: isMobile ? 20 : 24,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  kpi['trend'],
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            kpi['value'],
            style: TextStyle(
              fontSize: isMobile ? 20 : 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D0C0D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            kpi['title'],
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2D0C0D),
            ),
          ),
          Text(
            kpi['subtitle'],
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(bool isMobile, bool isTablet) {
    final actions = [
      {
        'title': 'Nouveau Contrôle',
        'subtitle': 'Lancer un contrôle qualité',
        'icon': Icons.add_task,
        'color': const Color(0xFF2196F3),
        'onTap': () => _navigateToNewControl(),
      },
      {
        'title': 'Attribuer Produits',
        'subtitle': 'Attribution après contrôle',
        'icon': Icons.assignment_turned_in,
        'color': const Color(0xFF4CAF50),
        'onTap': () => _navigateToAttribution(),
      },
      {
        'title': 'Historique',
        'subtitle': 'Voir tous les contrôles',
        'icon': Icons.history,
        'color': const Color(0xFFFF9800),
        'onTap': () => _navigateToHistory(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions Rapides',
          style: TextStyle(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D0C0D),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isMobile ? 3.5 : 2.5,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionCard(action, isMobile);
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action, bool isMobile) {
    return InkWell(
      onTap: action['onTap'],
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: (action['color'] as Color).withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (action['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                action['icon'],
                color: action['color'],
                size: isMobile ? 20 : 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    action['title'],
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D0C0D),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action['subtitle'],
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingControlsSection(bool isMobile) {
    final pendingControls = [
      {
        'code': 'REC_SAKOINSÉ_JEAN_MARIE_20241215_0001',
        'type': 'Miel Toutes Fleurs',
        'collecteur': 'Jean MARIE',
        'date': 'Il y a 2h',
        'priority': 'Haute',
      },
      {
        'code': 'SCO_KOUDOUGOU_PAUL_OUEDRAOGO_20241215_0003',
        'type': 'Miel Acacia',
        'collecteur': 'Paul OUEDRAOGO',
        'date': 'Il y a 4h',
        'priority': 'Normale',
      },
      {
        'code': 'IND_BAGRÉ_MARIE_TRAORE_20241215_0002',
        'type': 'Miel Karité',
        'collecteur': 'Marie TRAORE',
        'date': 'Il y a 6h',
        'priority': 'Normale',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Contrôles en Attente',
              style: TextStyle(
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D0C0D),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _navigateToAllPending,
              icon: const Icon(Icons.list_alt, size: 16),
              label: const Text('Voir tout'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2196F3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pendingControls.length,
          itemBuilder: (context, index) {
            final control = pendingControls[index];
            return _buildPendingControlCard(control, isMobile);
          },
        ),
      ],
    );
  }

  Widget _buildPendingControlCard(Map<String, dynamic> control, bool isMobile) {
    final isPriority = control['priority'] == 'Haute';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPriority
              ? const Color(0xFFF44336).withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: isPriority ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPriority
                      ? const Color(0xFFF44336).withOpacity(0.1)
                      : const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  control['priority'],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isPriority
                        ? const Color(0xFFF44336)
                        : const Color(0xFF2196F3),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                control['date'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            control['code'],
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D0C0D),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.science,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                control['type'],
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.person,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                control['collecteur'],
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _startControl(control['code']),
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Commencer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _viewDetails(control['code']),
                icon: const Icon(Icons.info, size: 16),
                label: const Text('Détails'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2196F3),
                  side: const BorderSide(color: Color(0xFF2196F3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlStatsSection(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques de Contrôle',
            style: TextStyle(
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D0C0D),
            ),
          ),
          const SizedBox(height: 16),
          // Graphique placeholder
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Graphique des contrôles\n(À implémenter)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(bool isMobile) {
    final activities = [
      {
        'action': 'Contrôle validé',
        'details': 'Miel Acacia - 25kg - Conforme',
        'time': 'Il y a 30 min',
        'icon': Icons.check_circle,
        'color': const Color(0xFF4CAF50),
      },
      {
        'action': 'Attribution effectuée',
        'details': '15 contenants attribués à l\'extraction',
        'time': 'Il y a 1h',
        'icon': Icons.assignment_turned_in,
        'color': const Color(0xFF2196F3),
      },
      {
        'action': 'Produit rejeté',
        'details': 'Miel Karité - Taux humidité élevé',
        'time': 'Il y a 2h',
        'icon': Icons.cancel,
        'color': const Color(0xFFF44336),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activité Récente',
          style: TextStyle(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D0C0D),
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return _buildActivityCard(activity, isMobile);
          },
        ),
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (activity['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              activity['icon'],
              color: activity['color'],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['action'],
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D0C0D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity['details'],
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            activity['time'],
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _navigateToNewControl() {
    // Navigation vers nouveau contrôle
    Get.snackbar(
      'Navigation',
      'Redirection vers Nouveau Contrôle',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _navigateToAttribution() {
    // Navigation vers attribution
    Get.snackbar(
      'Navigation',
      'Redirection vers Attribution',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _navigateToHistory() {
    // Navigation vers historique
    Get.snackbar(
      'Navigation',
      'Redirection vers Historique des Contrôles',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _navigateToAllPending() {
    // Navigation vers tous les contrôles en attente
    Get.snackbar(
      'Navigation',
      'Redirection vers Tous les Contrôles en Attente',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _startControl(String code) {
    // Démarrer un contrôle spécifique
    Get.snackbar(
      'Contrôle',
      'Démarrage du contrôle pour $code',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _viewDetails(String code) {
    // Voir les détails d'un produit
    Get.snackbar(
      'Détails',
      'Affichage des détails pour $code',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
