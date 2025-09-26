import 'dart:math' as math;
import 'extraction_history_page.dart';
import 'package:flutter/material.dart';
import 'attributed_products_page.dart';

/// Page principale d'extraction avec onglets
// import '../extraction_page.dart'; // ANCIEN - Fichier désactivé

class MainExtractionPage extends StatefulWidget {
  final int initialTabIndex; // 0: Produits, 1: Historique
  const MainExtractionPage({super.key, this.initialTabIndex = 0});

  @override
  State<MainExtractionPage> createState() => _MainExtractionPageState();
}

class _MainExtractionPageState extends State<MainExtractionPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final clampedIndex = math.min(1, math.max(0, widget.initialTabIndex));
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: clampedIndex,
    );
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
// Ancien placeholder d'historique supprimé (remplacé par ExtractionHistoryPage)
