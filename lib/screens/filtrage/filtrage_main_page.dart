import 'package:flutter/material.dart';
import 'pages/filtered_products_page.dart';

/// Page principale du module de filtrage moderne
class FiltrageMainPage extends StatefulWidget {
  const FiltrageMainPage({super.key});

  @override
  State<FiltrageMainPage> createState() => _FiltrageMainPageState();
}

class _FiltrageMainPageState extends State<FiltrageMainPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Module de Filtrage',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                tooltip: 'Retour au Dashboard',
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    _showInfoDialog(context);
                  },
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  tooltip: 'Informations sur le module',
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.inventory_2),
                    text: 'Produits Attribués',
                  ),
                  Tab(
                    icon: Icon(Icons.assignment),
                    text: 'Attribution',
                  ),
                  Tab(
                    icon: Icon(Icons.analytics),
                    text: 'Statistiques',
                  ),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Onglet 1: Produits attribués au filtrage
            const FilteredProductsPage(),

            // Onglet 2: Système d'attribution (à implémenter)
            _buildAttributionTab(theme),

            // Onglet 3: Statistiques avancées (à implémenter)
            _buildStatsTab(theme),
          ],
        ),
      ),
    );
  }

  /// Onglet d'attribution (placeholder)
  Widget _buildAttributionTab(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment,
            size: 64,
            color: theme.disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Système d\'Attribution',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cette section permettra aux extracteurs\nd\'attribuer leurs produits aux filtreurs',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fonctionnalité en cours de développement'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.build),
            label: const Text('Bientôt disponible'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Onglet de statistiques (placeholder)
  Widget _buildStatsTab(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics,
            size: 64,
            color: theme.disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Statistiques Avancées',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rendements, performance, historiques\net analyses approfondies',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fonctionnalité en cours de développement'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.build),
            label: const Text('Bientôt disponible'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Dialog d'informations sur le module
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.water_drop, color: Colors.blue),
            SizedBox(width: 8),
            Text('Module de Filtrage'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ce module gère le filtrage des produits liquides provenant de deux sources principales :',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.verified_user, size: 16, color: Colors.teal),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Produits liquides contrôlés directement attribués depuis le module de contrôle',
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.science, size: 16, color: Colors.purple),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Produits extraits (non filtrés) attribués par les extracteurs',
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Fonctionnalités :',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text('• Suivi en temps réel des produits attribués'),
            Text('• Processus de filtrage guidé'),
            Text('• Calcul automatique des rendements'),
            Text('• Gestion des suspensions et reprises'),
            Text('• Statistiques détaillées'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
