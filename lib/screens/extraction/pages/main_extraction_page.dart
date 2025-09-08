/// Page principale d'extraction avec onglets
import 'package:flutter/material.dart';
// import '../extraction_page.dart'; // ANCIEN - Fichier désactivé
import 'attributed_products_page.dart';
import 'extraction_history_page.dart';

class MainExtractionPage extends StatefulWidget {
  const MainExtractionPage({super.key});

  @override
  State<MainExtractionPage> createState() => _MainExtractionPageState();
}

class _MainExtractionPageState extends State<MainExtractionPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      appBar: AppBar(
        title: const Text('Module d\'Extraction'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(
              icon: Icon(Icons.science),
              text: 'Produits Attribués',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Historique',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Nouvelle interface des produits attribués
          AttributedProductsPage(),

          // ✅ NOUVEAU: Page d'historique des extractions avec statistiques
          ExtractionHistoryPage(),
        ],
      ),
    );
  }
}

/// Page placeholder pour l'ancien historique d'extraction
class _PlaceholderHistoriquePage extends StatelessWidget {
  const _PlaceholderHistoriquePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Historique Extraction',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Interface en cours de migration',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Utilisez l\'onglet "Produits Attribués" pour\naccéder aux fonctionnalités d\'extraction.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
