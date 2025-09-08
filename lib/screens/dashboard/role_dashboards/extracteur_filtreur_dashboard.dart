import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/user_role_service.dart';
import '../../../authentication/user_session.dart';

class ExtracteurFiltreurDashboard extends StatefulWidget {
  const ExtracteurFiltreurDashboard({super.key});

  @override
  State<ExtracteurFiltreurDashboard> createState() => _ExtracteurFiltreurDashboardState();
}

class _ExtracteurFiltreurDashboardState extends State<ExtracteurFiltreurDashboard> {
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
          
          // KPIs spécifiques production
          _buildKPISection(isMobile, isTablet),
          const SizedBox(height: 24),
          
          // Actions rapides
          _buildQuickActionsSection(isMobile, isTablet),
          const SizedBox(height: 24),
          
          // Processus en cours
          _buildActiveProcessSection(isMobile),
          const SizedBox(height: 24),
          
          // Statistiques de production
          _buildProductionStatsSection(isMobile, isTablet),
          const SizedBox(height: 24),
          
          // Équipements et maintenance
          _buildEquipmentSection(isMobile, isTablet),
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
          colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
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
              Icons.science,
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
                  '${userSession.role} - ${userSession.site}',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Votre mission : Transformer le miel brut en produit raffiné',
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
        'title': 'Kg Extraits',
        'value': '245',
        'subtitle': 'Cette semaine',
        'icon': Icons.opacity,
        'color': const Color(0xFF2196F3),
        'trend': '+18kg',
      },
      {
        'title': 'Kg Filtrés',
        'value': '189',
        'subtitle': 'Cette semaine',
        'icon': Icons.filter_alt,
        'color': const Color(0xFF4CAF50),
        'trend': '+12kg',
      },
      {
        'title': 'Rendement',
        'value': '87.3%',
        'subtitle': 'Extraction moyenne',
        'icon': Icons.trending_up,
        'color': const Color(0xFFFF9800),
        'trend': '+2.1%',
      },
      {
        'title': 'Lots en Cours',
        'value': '7',
        'subtitle': 'En traitement',
        'icon': Icons.hourglass_empty,
        'color': const Color(0xFF9C27B0),
        'trend': '+2',
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
        'title': 'Nouvelle Extraction',
        'subtitle': 'Démarrer un processus d\'extraction',
        'icon': Icons.play_arrow,
        'color': const Color(0xFF2196F3),
        'onTap': () => _navigateToNewExtraction(),
      },
      {
        'title': 'Nouveau Filtrage',
        'subtitle': 'Lancer un filtrage',
        'icon': Icons.filter_alt,
        'color': const Color(0xFF4CAF50),
        'onTap': () => _navigateToNewFiltrage(),
      },
      {
        'title': 'Produits Attribués',
        'subtitle': 'Voir les produits à traiter',
        'icon': Icons.assignment,
        'color': const Color(0xFFFF9800),
        'onTap': () => _navigateToAttributedProducts(),
      },
      {
        'title': 'Historique',
        'subtitle': 'Consulter l\'historique',
        'icon': Icons.history,
        'color': const Color(0xFF9C27B0),
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
            crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 4),
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
          border: Border.all(color: (action['color'] as Color).withOpacity(0.2)),
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

  Widget _buildActiveProcessSection(bool isMobile) {
    final processes = [
      {
        'type': 'Extraction',
        'lot': 'EXT-2024-089',
        'progress': 0.75,
        'status': 'En cours',
        'timeLeft': '45 min restantes',
        'color': const Color(0xFF2196F3),
      },
      {
        'type': 'Filtrage',
        'lot': 'FIL-2024-067',
        'progress': 0.35,
        'status': 'En cours',
        'timeLeft': '2h 15min restantes',
        'color': const Color(0xFF4CAF50),
      },
      {
        'type': 'Extraction',
        'lot': 'EXT-2024-090',
        'progress': 0.95,
        'status': 'Finalisation',
        'timeLeft': '10 min restantes',
        'color': const Color(0xFF2196F3),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Processus en Cours',
              style: TextStyle(
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D0C0D),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _navigateToAllProcesses,
              icon: const Icon(Icons.list_alt, size: 16),
              label: const Text('Voir tout'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: processes.length,
          itemBuilder: (context, index) {
            final process = processes[index];
            return _buildProcessCard(process, isMobile);
          },
        ),
      ],
    );
  }

  Widget _buildProcessCard(Map<String, dynamic> process, bool isMobile) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (process['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  process['type'] == 'Extraction' ? Icons.opacity : Icons.filter_alt,
                  color: process['color'],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${process['type']} - ${process['lot']}',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D0C0D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      process['status'],
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 14,
                        color: process['color'],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                process['timeLeft'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progression',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${(process['progress'] * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: process['color'],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: process['progress'],
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(process['color']),
                minHeight: 6,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewProcessDetails(process['lot']),
                  icon: const Icon(Icons.info, size: 16),
                  label: const Text('Détails'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: process['color'],
                    side: BorderSide(color: process['color']),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _controlProcess(process['lot']),
                  icon: const Icon(Icons.settings, size: 16),
                  label: const Text('Contrôler'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: process['color'],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductionStatsSection(bool isMobile, bool isTablet) {
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
            'Statistiques de Production',
            style: TextStyle(
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D0C0D),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Rendement Moyen',
                  '87.3%',
                  'Cette semaine',
                  Icons.trending_up,
                  const Color(0xFF4CAF50),
                  isMobile,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Temps Moyen',
                  '2h 45min',
                  'Par lot',
                  Icons.schedule,
                  const Color(0xFF2196F3),
                  isMobile,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Graphique placeholder
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Graphique de production\n(À implémenter)',
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

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 18 : 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2D0C0D),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentSection(bool isMobile, bool isTablet) {
    final equipment = [
      {
        'name': 'Extracteur #1',
        'status': 'En fonctionnement',
        'usage': 0.85,
        'color': const Color(0xFF4CAF50),
      },
      {
        'name': 'Extracteur #2',
        'status': 'Maintenance',
        'usage': 0.0,
        'color': const Color(0xFFF44336),
      },
      {
        'name': 'Filtreur Principal',
        'status': 'En fonctionnement',
        'usage': 0.62,
        'color': const Color(0xFF4CAF50),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'État des Équipements',
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
            childAspectRatio: isMobile ? 3.5 : 2.8,
          ),
          itemCount: equipment.length,
          itemBuilder: (context, index) {
            final item = equipment[index];
            return _buildEquipmentCard(item, isMobile);
          },
        ),
      ],
    );
  }

  Widget _buildEquipmentCard(Map<String, dynamic> equipment, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (equipment['color'] as Color).withOpacity(0.3)),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (equipment['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.precision_manufacturing,
                  color: equipment['color'],
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  equipment['name'],
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D0C0D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            equipment['status'],
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: equipment['color'],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (equipment['usage'] > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Utilisation: ${(equipment['usage'] * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: equipment['usage'],
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(equipment['color']),
              minHeight: 4,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(bool isMobile) {
    final activities = [
      {
        'action': 'Extraction terminée',
        'details': 'Lot EXT-2024-088 - 42kg extraits',
        'time': 'Il y a 20 min',
        'icon': Icons.check_circle,
        'color': const Color(0xFF4CAF50),
      },
      {
        'action': 'Filtrage démarré',
        'details': 'Lot FIL-2024-067 - Filtrage fin',
        'time': 'Il y a 1h',
        'icon': Icons.filter_alt,
        'color': const Color(0xFF2196F3),
      },
      {
        'action': 'Maintenance programmée',
        'details': 'Extracteur #2 - Nettoyage complet',
        'time': 'Il y a 2h',
        'icon': Icons.build,
        'color': const Color(0xFFFF9800),
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
  void _navigateToNewExtraction() {
    Get.snackbar(
      'Navigation',
      'Redirection vers Nouvelle Extraction',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _navigateToNewFiltrage() {
    Get.snackbar(
      'Navigation',
      'Redirection vers Nouveau Filtrage',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _navigateToAttributedProducts() {
    Get.snackbar(
      'Navigation',
      'Redirection vers Produits Attribués',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _navigateToHistory() {
    Get.snackbar(
      'Navigation',
      'Redirection vers Historique Production',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _navigateToAllProcesses() {
    Get.snackbar(
      'Navigation',
      'Redirection vers Tous les Processus',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _viewProcessDetails(String lot) {
    Get.snackbar(
      'Détails',
      'Affichage des détails pour $lot',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _controlProcess(String lot) {
    Get.snackbar(
      'Contrôle',
      'Contrôle du processus $lot',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
