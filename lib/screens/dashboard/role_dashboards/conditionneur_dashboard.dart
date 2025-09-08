import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/user_role_service.dart';
import '../../../authentication/user_session.dart';

class ConditionneurDashboard extends StatefulWidget {
  const ConditionneurDashboard({super.key});

  @override
  State<ConditionneurDashboard> createState() => _ConditionneurDashboardState();
}

class _ConditionneurDashboardState extends State<ConditionneurDashboard> {
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
          
          // KPIs spécifiques conditionnement
          _buildKPISection(isMobile, isTablet),
          const SizedBox(height: 24),
          
          // Actions rapides
          _buildQuickActionsSection(isMobile, isTablet),
          const SizedBox(height: 24),
          
          // Lots disponibles
          _buildAvailableLotsSection(isMobile),
          const SizedBox(height: 24),
          
          // Stock emballages
          _buildPackagingStockSection(isMobile, isTablet),
          const SizedBox(height: 24),
          
          // Commandes urgentes
          _buildUrgentOrdersSection(isMobile),
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
          colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withOpacity(0.3),
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
              Icons.inventory,
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
                  'Conditionneur - ${userSession.site}',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Votre mission : Emballer le miel pour la commercialisation',
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
        'title': 'Lots Conditionnés',
        'value': '34',
        'subtitle': 'Cette semaine',
        'icon': Icons.check_box,
        'color': const Color(0xFF4CAF50),
        'trend': '+6',
      },
      {
        'title': 'Pots Produits',
        'value': '2,847',
        'subtitle': 'Cette semaine',
        'icon': Icons.inventory_2,
        'color': const Color(0xFF2196F3),
        'trend': '+285',
      },
      {
        'title': 'Stock Emballages',
        'value': '87%',
        'subtitle': 'Niveau global',
        'icon': Icons.all_inbox,
        'color': const Color(0xFFFF9800),
        'trend': '-3%',
      },
      {
        'title': 'Commandes Urgentes',
        'value': '5',
        'subtitle': 'À traiter',
        'icon': Icons.priority_high,
        'color': const Color(0xFFF44336),
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
        'title': 'Nouveau Conditionnement',
        'subtitle': 'Conditionner un lot filtré',
        'icon': Icons.add_box,
        'color': const Color(0xFF4CAF50),
        'onTap': () => _navigateToNewConditioning(),
      },
      {
        'title': 'Lots Disponibles',
        'subtitle': 'Voir les lots à conditionner',
        'icon': Icons.list_alt,
        'color': const Color(0xFF2196F3),
        'onTap': () => _navigateToAvailableLots(),
      },
      {
        'title': 'Stock Emballages',
        'subtitle': 'Gérer les emballages',
        'icon': Icons.inventory,
        'color': const Color(0xFFFF9800),
        'onTap': () => _navigateToPackagingStock(),
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

  Widget _buildAvailableLotsSection(bool isMobile) {
    final lots = [
      {
        'numero': 'Lot-504-920',
        'type': 'Miel Toutes Fleurs',
        'quantite': '45.2kg',
        'date_filtrage': 'Il y a 2 jours',
        'priorite': 'Haute',
        'florale': 'Toutes Fleurs',
      },
      {
        'numero': 'Lot-505-123',
        'type': 'Miel Acacia',
        'quantite': '32.8kg',
        'date_filtrage': 'Il y a 3 jours',
        'priorite': 'Normale',
        'florale': 'Acacia',
      },
      {
        'numero': 'Lot-503-789',
        'type': 'Miel Karité',
        'quantite': '28.5kg',
        'date_filtrage': 'Il y a 4 jours',
        'priorite': 'Normale',
        'florale': 'Karité',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Lots Prêts à Conditionner',
              style: TextStyle(
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D0C0D),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _navigateToAllAvailableLots,
              icon: const Icon(Icons.list_alt, size: 16),
              label: const Text('Voir tout'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF9800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: lots.length,
          itemBuilder: (context, index) {
            final lot = lots[index];
            return _buildLotCard(lot, isMobile);
          },
        ),
      ],
    );
  }

  Widget _buildLotCard(Map<String, dynamic> lot, bool isMobile) {
    final isPriority = lot['priorite'] == 'Haute';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPriority ? const Color(0xFFF44336).withOpacity(0.3) : Colors.grey.withOpacity(0.2),
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
                  color: isPriority ? const Color(0xFFF44336).withOpacity(0.1) : const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  lot['priorite'],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isPriority ? const Color(0xFFF44336) : const Color(0xFF4CAF50),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  lot['florale'],
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF9800),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lot['numero'],
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D0C0D),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.scale,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                lot['quantite'],
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.schedule,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Filtré ${lot['date_filtrage']}',
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
                  onPressed: () => _startConditioning(lot['numero']),
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Conditionner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
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
                onPressed: () => _viewLotDetails(lot['numero']),
                icon: const Icon(Icons.info, size: 16),
                label: const Text('Détails'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4CAF50),
                  side: const BorderSide(color: Color(0xFF4CAF50)),
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

  Widget _buildPackagingStockSection(bool isMobile, bool isTablet) {
    final packaging = [
      {'type': '500g', 'stock': 1250, 'min': 500, 'color': const Color(0xFF4CAF50)},
      {'type': '250g', 'stock': 890, 'min': 400, 'color': const Color(0xFF4CAF50)},
      {'type': '1Kg', 'stock': 320, 'min': 300, 'color': const Color(0xFFFF9800)},
      {'type': 'Stick 20g', 'stock': 150, 'min': 200, 'color': const Color(0xFFF44336)},
      {'type': '30g Alvéoles', 'stock': 680, 'min': 500, 'color': const Color(0xFF4CAF50)},
      {'type': '7Kg', 'stock': 45, 'min': 50, 'color': const Color(0xFFF44336)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stock des Emballages',
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
            crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 6),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isMobile ? 1.2 : 1.1,
          ),
          itemCount: packaging.length,
          itemBuilder: (context, index) {
            final pack = packaging[index];
            return _buildPackagingCard(pack, isMobile);
          },
        ),
      ],
    );
  }

  Widget _buildPackagingCard(Map<String, dynamic> pack, bool isMobile) {
    final isLow = pack['stock'] < pack['min'];
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLow ? const Color(0xFFF44336).withOpacity(0.3) : Colors.grey.withOpacity(0.2),
          width: isLow ? 2 : 1,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (pack['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.inventory_2,
              color: pack['color'],
              size: isMobile ? 16 : 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pack['type'],
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D0C0D),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${pack['stock']}',
            style: TextStyle(
              fontSize: isMobile ? 16 : 20,
              fontWeight: FontWeight.bold,
              color: pack['color'],
            ),
          ),
          Text(
            'unités',
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              color: Colors.grey[600],
            ),
          ),
          if (isLow) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF44336).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'FAIBLE',
                style: TextStyle(
                  fontSize: isMobile ? 8 : 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF44336),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUrgentOrdersSection(bool isMobile) {
    final orders = [
      {
        'client': 'Épicerie Bio Nature',
        'produit': 'Miel Acacia 500g x 50',
        'deadline': 'Demain 14h',
        'status': 'urgent',
      },
      {
        'client': 'Supermarché Central',
        'produit': 'Miel Toutes Fleurs 250g x 100',
        'deadline': 'Dans 2 jours',
        'status': 'normal',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Commandes Urgentes',
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
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order, isMobile);
          },
        ),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, bool isMobile) {
    final isUrgent = order['status'] == 'urgent';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent ? const Color(0xFFF44336).withOpacity(0.3) : Colors.grey.withOpacity(0.2),
          width: isUrgent ? 2 : 1,
        ),
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
              color: (isUrgent ? const Color(0xFFF44336) : const Color(0xFF4CAF50)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isUrgent ? Icons.priority_high : Icons.shopping_cart,
              color: isUrgent ? const Color(0xFFF44336) : const Color(0xFF4CAF50),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order['client'],
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D0C0D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order['produit'],
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Deadline: ${order['deadline']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isUrgent ? const Color(0xFFF44336) : const Color(0xFF4CAF50),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _processOrder(order['client']),
            style: ElevatedButton.styleFrom(
              backgroundColor: isUrgent ? const Color(0xFFF44336) : const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Traiter',
              style: TextStyle(fontSize: isMobile ? 12 : 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(bool isMobile) {
    final activities = [
      {
        'action': 'Lot conditionné',
        'details': 'Lot-504-920 - 156 pots 500g produits',
        'time': 'Il y a 1h',
        'icon': Icons.check_circle,
        'color': const Color(0xFF4CAF50),
      },
      {
        'action': 'Réapprovisionnement',
        'details': 'Pots 250g - 500 unités reçues',
        'time': 'Il y a 2h',
        'icon': Icons.local_shipping,
        'color': const Color(0xFF2196F3),
      },
      {
        'action': 'Commande expédiée',
        'details': 'Épicerie Bio Nature - 50 pots livrés',
        'time': 'Il y a 3h',
        'icon': Icons.send,
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
  void _navigateToNewConditioning() {
    Get.snackbar(
      'Navigation',
      'Redirection vers Nouveau Conditionnement',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _navigateToAvailableLots() {
    Get.snackbar(
      'Navigation',
      'Redirection vers Lots Disponibles',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _navigateToPackagingStock() {
    Get.snackbar(
      'Navigation',
      'Redirection vers Stock Emballages',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _navigateToHistory() {
    Get.snackbar(
      'Navigation',
      'Redirection vers Historique Conditionnement',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _navigateToAllAvailableLots() {
    Get.snackbar(
      'Navigation',
      'Redirection vers Tous les Lots Disponibles',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _startConditioning(String numero) {
    Get.snackbar(
      'Conditionnement',
      'Démarrage du conditionnement pour $numero',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _viewLotDetails(String numero) {
    Get.snackbar(
      'Détails',
      'Affichage des détails pour $numero',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _processOrder(String client) {
    Get.snackbar(
      'Commande',
      'Traitement de la commande pour $client',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
