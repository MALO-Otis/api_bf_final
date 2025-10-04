import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../authentication/user_session.dart';
import '../../collecte_de_donnes/historiques_collectes.dart';

class CollecteurDashboard extends StatefulWidget {
  const CollecteurDashboard({super.key});

  @override
  State<CollecteurDashboard> createState() => _CollecteurDashboardState();
}

class _CollecteurDashboardState extends State<CollecteurDashboard> {
  final UserSession userSession = Get.find<UserSession>();

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

          // KPIs spécifiques au collecteur
          _buildKPISection(isMobile, isTablet),
          const SizedBox(height: 24),

          // Actions rapides
          _buildQuickActionsSection(isMobile, isTablet),
          const SizedBox(height: 24),

          // Collectes en cours
          _buildOngoingCollectionsSection(isMobile),
          const SizedBox(height: 24),

          // Statistiques de collecte
          _buildCollectionStatsSection(isMobile, isTablet),
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
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isMobile ? 25 : 35,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(
              Icons.agriculture,
              size: isMobile ? 25 : 35,
              color: Colors.white,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, ${userSession.email?.split('@').first ?? 'Collecteur'} !',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 18 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tableau de bord Collecteur',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isMobile ? 14 : 16,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Site: ${userSession.site ?? 'Non défini'}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

  Widget _buildKPISection(bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Indicateurs Clés',
          style: TextStyle(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isMobile ? 1.2 : 1.5,
          children: [
            _buildKPICard(
              'Collectes Aujourd\'hui',
              '12',
              Icons.agriculture,
              Colors.green,
              isMobile,
            ),
            _buildKPICard(
              'Quantité Collectée',
              '245 kg',
              Icons.scale,
              Colors.blue,
              isMobile,
            ),
            _buildKPICard(
              'Producteurs Actifs',
              '8',
              Icons.people,
              Colors.orange,
              isMobile,
            ),
            _buildKPICard(
              'Objectif Mensuel',
              '85%',
              Icons.trending_up,
              Colors.purple,
              isMobile,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard(
      String title, String value, IconData icon, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: isMobile ? 24 : 32,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 18 : 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions Rapides',
          style: TextStyle(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isMobile ? 1.1 : 1.3,
          children: [
            _buildActionCard(
              'Nouvelle Collecte',
              Icons.add_circle_outline,
              Colors.green,
              () {
                // Navigation vers nouvelle collecte
                Get.snackbar('Action', 'Nouvelle collecte');
              },
              isMobile,
            ),
            _buildActionCard(
              'Historique',
              Icons.history,
              Colors.blue,
              () {
                // Navigation vers historique des collectes
                Get.to(() => const HistoriquesCollectesPage());
              },
              isMobile,
            ),
            _buildActionCard(
              'Récoltes',
              Icons.agriculture,
              Colors.orange,
              () {
                // Navigation vers récoltes
                Get.snackbar('Action', 'Gestion des récoltes');
              },
              isMobile,
            ),
            _buildActionCard(
              'Achats SCOOPS',
              Icons.inventory_2,
              Colors.purple,
              () {
                // Navigation vers achats SCOOPS
                Get.snackbar('Action', 'Achat Scoop');
              },
              isMobile,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color,
      VoidCallback onTap, bool isMobile) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: isMobile ? 28 : 36,
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOngoingCollectionsSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Collectes en Cours',
          style: TextStyle(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildCollectionItem(
                  'Producteur A', '45 kg', 'En cours', Colors.orange, isMobile),
              _buildCollectionItem(
                  'Producteur B', '32 kg', 'Terminée', Colors.green, isMobile),
              _buildCollectionItem(
                  'Producteur C', '28 kg', 'En attente', Colors.blue, isMobile),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionItem(String producteur, String quantite, String statut,
      Color color, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: isMobile ? 20 : 24,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(
              Icons.person,
              color: color,
              size: isMobile ? 16 : 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producteur,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  quantite,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statut,
              style: TextStyle(
                fontSize: isMobile ? 10 : 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionStatsSection(bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistiques de Collecte',
          style: TextStyle(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildStatRow(
                  'Collectes cette semaine', '24', Colors.green, isMobile),
              _buildStatRow('Quantité totale', '456 kg', Colors.blue, isMobile),
              _buildStatRow(
                  'Moyenne par collecte', '19 kg', Colors.orange, isMobile),
              _buildStatRow('Taux de réussite', '92%', Colors.purple, isMobile),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, Color color, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activité Récente',
          style: TextStyle(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildActivityItem('Nouvelle collecte enregistrée',
                  'Il y a 2 heures', Icons.add_circle, Colors.green, isMobile),
              _buildActivityItem('Collecte terminée - Producteur B',
                  'Il y a 4 heures', Icons.check_circle, Colors.blue, isMobile),
              _buildActivityItem('Achat de contenants SCOOPS', 'Hier',
                  Icons.inventory, Colors.orange, isMobile),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
      String title, String time, IconData icon, Color color, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: isMobile ? 16 : 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
