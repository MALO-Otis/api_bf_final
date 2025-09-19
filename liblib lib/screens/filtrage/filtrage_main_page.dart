/// Page principale de filtrage avec onglets (inspirée du module extraction)
import 'package:flutter/material.dart';
import 'pages/filtrage_products_page.dart';
import 'pages/filtrage_historique_page.dart';

class FiltrageMainPage extends StatefulWidget {
  const FiltrageMainPage({super.key});

  @override
  State<FiltrageMainPage> createState() => _FiltrageMainPageState();
}

class _FiltrageMainPageState extends State<FiltrageMainPage>
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
        title: const Text('Module de Filtrage'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(
              icon: Icon(Icons.filter_alt),
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
          // Nouvelle interface des produits attribués (comme extraction)
          FiltrageProductsPage(),

          // Page d'historique des filtrages avec statistiques
          FiltrageHistoriquePage(),
        ],
      ),
    );
  }
}
