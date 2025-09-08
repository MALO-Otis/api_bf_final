import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/user_role_service.dart';
import '../../../authentication/user_session.dart';

class CommercialDashboard extends StatefulWidget {
  const CommercialDashboard({super.key});

  @override
  State<CommercialDashboard> createState() => _CommercialDashboardState();
}

class _CommercialDashboardState extends State<CommercialDashboard> {
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
          
          // KPIs spécifiques commercial
          _buildKPISection(isMobile, isTablet),
          const SizedBox(height: 24),
          
          // Actions rapides
          _buildQuickActionsSection(isMobile, isTablet),
          const SizedBox(height: 24),
          
          // Mes prélèvements
          _buildMyPrelevementsSection(isMobile),
          const SizedBox(height: 24),
          
          // Clients récents
          _buildRecentClientsSection(isMobile, isTablet),
          const SizedBox(height: 24),
          
          // Objectifs et performance
          _buildPerformanceSection(isMobile),
          const SizedBox(height: 24),
          
          // Activité récente
          _buildRecentActivitySection(isMobile),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(bool isMobile) {
    final isCommercial = userSession.role?.toLowerCase().contains('commercial') == true;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCommercial 
            ? [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)]
            : [const Color(0xFF607D8B), const Color(0xFF455A64)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isCommercial ? const Color(0xFF9C27B0) : const Color(0xFF607D8B)).withOpacity(0.3),
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
              isCommercial ? Icons.trending_up : Icons.point_of_sale,
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
                  isCommercial 
                    ? 'Votre mission : Développer les ventes et fidéliser la clientèle'
                    : 'Votre mission : Gérer les encaissements et la caisse',
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
    final isCommercial = userSession.role?.toLowerCase().contains('commercial') == true;
    
    final kpis = isCommercial ? [
      {
        'title': 'Ventes du Jour',
        'value': '1,247,500',
        'subtitle': 'FCFA',
        'icon': Icons.trending_up,
        'color': const Color(0xFF4CAF50),
        'trend': '+15.3%',
      },
      {
        'title': 'CA Commercial',
        'value': '12,850,000',
        'subtitle': 'FCFA ce mois',
        'icon': Icons.account_balance_wallet,
        'color': const Color(0xFF2196F3),
        'trend': '+8.7%',
      },
      {
        'title': 'Clients Actifs',
        'value': '47',
        'subtitle': 'Ce mois',
        'icon': Icons.people,
        'color': const Color(0xFF9C27B0),
        'trend': '+6',
      },
      {
        'title': 'Objectif',
        'value': '78%',
        'subtitle': 'Atteint',
        'icon': Icons.flag,
        'color': const Color(0xFFFF9800),
        'trend': '+12%',
      },
    ] : [
      {
        'title': 'Encaissements',
        'value': '2,450,000',
        'subtitle': 'FCFA aujourd\'hui',
        'icon': Icons.payments,
        'color': const Color(0xFF4CAF50),
        'trend': '+850K',
      },
      {
        'title': 'Crédits Accordés',
        'value': '8',
        'subtitle': 'Aujourd\'hui',
        'icon': Icons.credit_card,
        'color': const Color(0xFF2196F3),
        'trend': '+3',
      },
      {
        'title': 'Retards Paiement',
        'value': '12',
        'subtitle': 'À suivre',
        'icon': Icons.schedule,
        'color': const Color(0xFFF44336),
        'trend': '+2',
      },
      {
        'title': 'Solde Caisse',
        'value': '156,500',
        'subtitle': 'FCFA',
        'icon': Icons.account_balance,
        'color': const Color(0xFF607D8B),
        'trend': '=',
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
              fontSize: isMobile ? 16 : 22,
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
    final isCommercial = userSession.role?.toLowerCase().contains('commercial') == true;
    
    final actions = isCommercial ? [
      {
        'title': 'Nouvelle Vente',
        'subtitle': 'Enregistrer une vente',
        'icon': Icons.add_shopping_cart,
        'color': const Color(0xFF4CAF50),
        'onTap': () => _navigateToNewSale(),
      },
      {
        'title': 'Mes Prélèvements',
        'subtitle': 'Voir mes produits',
        'icon': Icons.inventory,
        'color': const Color(0xFF2196F3),
        'onTap': () => _navigateToMyPrelevements(),
      },
      {
        'title': 'Clients',
        'subtitle': 'Gérer la clientèle',
        'icon': Icons.people,
        'color': const Color(0xFF9C27B0),
        'onTap': () => _navigateToClients(),
      },
      {
        'title': 'Restitutions',
        'subtitle': 'Retours produits',
        'icon': Icons.undo,
        'color': const Color(0xFFFF9800),
        'onTap': () => _navigateToRestitutions(),
      },
    ] : [
      {
        'title': 'Nouvelle Vente',
        'subtitle': 'Encaisser une vente',
        'icon': Icons.point_of_sale,
        'color': const Color(0xFF4CAF50),
        'onTap': () => _navigateToNewSale(),
      },
      {
        'title': 'Gestion Crédit',
        'subtitle': 'Crédits et paiements',
        'icon': Icons.credit_card,
        'color': const Color(0xFF2196F3),
        'onTap': () => _navigateToCredits(),
      },
      {
        'title': 'Rapport Caisse',
        'subtitle': 'État de la caisse',
        'icon': Icons.assessment,
        'color': const Color(0xFF607D8B),
        'onTap': () => _navigateToCashReport(),
      },
      {
        'title': 'Historique',
        'subtitle': 'Transactions passées',
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

  Widget _buildMyPrelevementsSection(bool isMobile) {
    final prelevements = [
      {
        'produit': 'Miel Acacia 500g',
        'quantite': 45,
        'date': 'Il y a 2 jours',
        'statut': 'Disponible',
        'couleur': const Color(0xFF4CAF50),
      },
      {
        'produit': 'Miel Toutes Fleurs 250g',
        'quantite': 28,
        'date': 'Il y a 3 jours',
        'statut': 'Partiellement vendu',
        'couleur': const Color(0xFFFF9800),
      },
      {
        'produit': 'Miel Karité 1Kg',
        'quantite': 12,
        'date': 'Il y a 5 jours',
        'statut': 'Disponible',
        'couleur': const Color(0xFF4CAF50),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Mes Prélèvements',
              style: TextStyle(
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D0C0D),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _navigateToAllPrelevements,
              icon: const Icon(Icons.list_alt, size: 16),
              label: const Text('Voir tout'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF9C27B0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: prelevements.length,
          itemBuilder: (context, index) {
            final prelevement = prelevements[index];
            return _buildPrelevementCard(prelevement, isMobile);
          },
        ),
      ],
    );
  }

  Widget _buildPrelevementCard(Map<String, dynamic> prelevement, bool isMobile) {
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
              color: (prelevement['couleur'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.inventory_2,
              color: prelevement['couleur'],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prelevement['produit'],
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D0C0D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${prelevement['quantite']} unités - ${prelevement['date']}',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (prelevement['couleur'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    prelevement['statut'],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: prelevement['couleur'],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _sellProduct(prelevement['produit']),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Vendre',
              style: TextStyle(fontSize: isMobile ? 12 : 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentClientsSection(bool isMobile, bool isTablet) {
    final clients = [
      {
        'nom': 'Épicerie Bio Nature',
        'contact': '70 12 34 56',
        'derniere_vente': '2 jours',
        'montant': '485,000 FCFA',
        'statut': 'Actif',
      },
      {
        'nom': 'Supermarché Central',
        'contact': '76 89 12 34',
        'derniere_vente': '5 jours',
        'montant': '1,250,000 FCFA',
        'statut': 'Actif',
      },
      {
        'nom': 'Boulangerie SANKARA',
        'contact': '78 45 67 89',
        'derniere_vente': '15 jours',
        'montant': '320,000 FCFA',
        'statut': 'Inactif',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Clients Récents',
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
            childAspectRatio: isMobile ? 2.5 : 2.2,
          ),
          itemCount: clients.length,
          itemBuilder: (context, index) {
            final client = clients[index];
            return _buildClientCard(client, isMobile);
          },
        ),
      ],
    );
  }

  Widget _buildClientCard(Map<String, dynamic> client, bool isMobile) {
    final isActive = client['statut'] == 'Actif';
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? const Color(0xFF4CAF50).withOpacity(0.3) : Colors.grey.withOpacity(0.2),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (isActive ? const Color(0xFF4CAF50) : Colors.grey).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.business,
                  color: isActive ? const Color(0xFF4CAF50) : Colors.grey,
                  size: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isActive ? const Color(0xFF4CAF50) : Colors.grey).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  client['statut'],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isActive ? const Color(0xFF4CAF50) : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            client['nom'],
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D0C0D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            client['contact'],
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dernière vente: il y a ${client['derniere_vente']}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            client['montant'],
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection(bool isMobile) {
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
            'Performance et Objectifs',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Objectif Mensuel',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '16,500,000 FCFA',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D0C0D),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Réalisé',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '12,850,000 FCFA',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progression',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '78%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: 0.78,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                minHeight: 8,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(bool isMobile) {
    final activities = [
      {
        'action': 'Vente effectuée',
        'details': 'Épicerie Bio Nature - 25 pots 500g - 485,000 FCFA',
        'time': 'Il y a 2h',
        'icon': Icons.shopping_cart,
        'color': const Color(0xFF4CAF50),
      },
      {
        'action': 'Nouveau client',
        'details': 'Restaurant Le Palmier ajouté',
        'time': 'Il y a 4h',
        'icon': Icons.person_add,
        'color': const Color(0xFF2196F3),
      },
      {
        'action': 'Restitution',
        'details': '3 pots défectueux retournés',
        'time': 'Il y a 6h',
        'icon': Icons.undo,
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
  void _navigateToNewSale() {
    Get.snackbar(
      'Navigation',
      'Redirection vers Nouvelle Vente',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _navigateToMyPrelevements() {
    Get.snackbar(
      'Navigation',
      'Redirection vers Mes Prélèvements',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _navigateToClients() {
    Get.snackbar(
      'Navigation',
      'Redirection vers Gestion Clients',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _navigateToRestitutions() {
    Get.snackbar(
      'Navigation',
      'Redirection vers Restitutions',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _navigateToCredits() {
    Get.snackbar(
      'Navigation',
      'Redirection vers Gestion Crédits',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _navigateToCashReport() {
    Get.snackbar(
      'Navigation',
      'Redirection vers Rapport Caisse',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _navigateToHistory() {
    Get.snackbar(
      'Navigation',
      'Redirection vers Historique',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _navigateToAllPrelevements() {
    Get.snackbar(
      'Navigation',
      'Redirection vers Tous les Prélèvements',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _sellProduct(String produit) {
    Get.snackbar(
      'Vente',
      'Démarrage de la vente pour $produit',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
