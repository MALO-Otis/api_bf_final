/// 📊 PAGE STOCK CONDITIONNÉ
///
/// Interface moderne pour visualiser et gérer le stock de produits conditionnés

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../utils/smart_appbar.dart';
import '../conditionnement_models.dart';
import '../services/conditionnement_service.dart';

class StockConditionnePage extends StatefulWidget {
  const StockConditionnePage({super.key});

  @override
  State<StockConditionnePage> createState() => _StockConditionnePageState();
}

class _StockConditionnePageState extends State<StockConditionnePage>
    with TickerProviderStateMixin {
  final ConditionnementService _service = ConditionnementService();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _listController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _listAnimation;

  // État de l'application
  bool _isLoading = true;
  List<ConditionnementData> _conditionnements = [];
  Map<String, dynamic> _statistics = {};
  String _searchQuery = '';
  String? _selectedSiteFilter;

  // Controllers
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _listController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _listController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _listAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _listController,
      curve: Curves.elasticOut,
    ));

    // Démarrer les animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _listController.forward();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _service.getConditionnements(),
        _service.getStatistiquesConditionnement(),
      ]);

      _conditionnements = results[0] as List<ConditionnementData>;
      _statistics = results[1] as Map<String, dynamic>;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les données: $e',
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  List<ConditionnementData> get _filteredConditionnements {
    return _conditionnements.where((conditionnement) {
      if (_searchQuery.isNotEmpty) {
        return conditionnement.lotOrigine.lotOrigine
                .toLowerCase()
                .contains(_searchQuery) ||
            conditionnement.lotOrigine.predominanceFlorale
                .toLowerCase()
                .contains(_searchQuery) ||
            conditionnement.lotOrigine.site
                .toLowerCase()
                .contains(_searchQuery);
      }
      if (_selectedSiteFilter != null) {
        return conditionnement.lotOrigine.site == _selectedSiteFilter;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: SmartAppBar(
        title: "📊 Stock Conditionné",
        backgroundColor: const Color(0xFF9C27B0),
        onBackPressed: () => Get.back(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingView() : _buildMainContent(isMobile),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 6,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9C27B0)),
          ),
          const SizedBox(height: 24),
          Text(
            'Chargement du stock...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isMobile) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Column(
            children: [
              // En-tête avec statistiques
              _buildHeaderSection(isMobile),

              // Filtres et recherche
              _buildFiltersSection(isMobile),

              // Liste du stock
              Expanded(child: _buildStockList(isMobile)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(bool isMobile) {
    return Container(
      margin: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '📊',
                    style: TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock Conditionné',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 18 : 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Inventory complet des produits conditionnés',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Statistiques
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Lots en stock',
                    _statistics['lotsConditionnes']?.toString() ?? '0',
                    Icons.warehouse,
                    Colors.white,
                    isMobile,
                  ),
                ),
                SizedBox(width: isMobile ? 8 : 16),
                Expanded(
                  child: _buildStatCard(
                    'Quantité totale',
                    '${(_statistics['quantiteTotaleConditionnee'] ?? 0).toStringAsFixed(1)} kg',
                    Icons.scale,
                    Colors.white,
                    isMobile,
                  ),
                ),
                SizedBox(width: isMobile ? 8 : 16),
                Expanded(
                  child: _buildStatCard(
                    'Valeur stock',
                    ConditionnementUtils.formatPrix(
                        _statistics['valeurTotaleConditionnee'] ?? 0),
                    Icons.attach_money,
                    Colors.white,
                    isMobile,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isMobile ? 18 : 24),
          SizedBox(height: isMobile ? 4 : 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: isMobile ? 10 : 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: TextStyle(
              color: color.withOpacity(0.9),
              fontSize: isMobile ? 8 : 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(bool isMobile) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Recherche
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un lot...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          if (!isMobile) ...[
            const SizedBox(width: 16),

            // Filtre par site
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                value: _selectedSiteFilter,
                decoration: InputDecoration(
                  labelText: 'Site',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Tous les sites')),
                  DropdownMenuItem(
                      value: 'Koudougou', child: Text('Koudougou')),
                  DropdownMenuItem(
                      value: 'Ouagadougou', child: Text('Ouagadougou')),
                  DropdownMenuItem(
                      value: 'Bobo-Dioulasso', child: Text('Bobo-Dioulasso')),
                  DropdownMenuItem(value: 'Kaya', child: Text('Kaya')),
                ],
                onChanged: (value) {
                  setState(() => _selectedSiteFilter = value);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStockList(bool isMobile) {
    final filteredList = _filteredConditionnements;

    if (filteredList.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _listAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _listAnimation.value,
          child: ListView.builder(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 50)),
                margin: const EdgeInsets.only(bottom: 16),
                child: _buildStockCard(filteredList[index], isMobile, index),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStockCard(
      ConditionnementData conditionnement, bool isMobile, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0, end: 1),
      builder: (context, animationValue, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animationValue)),
          child: Opacity(
            opacity: animationValue,
            child: Card(
              elevation: 6,
              shadowColor: Colors.purple.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      _getFloralTypeColor(
                              conditionnement.lotOrigine.typeFlorale)
                          .withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getFloralTypeColor(
                                      conditionnement.lotOrigine.typeFlorale)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              ConditionnementUtils.iconesByFlorale[
                                      conditionnement.lotOrigine.typeFlorale] ??
                                  '🍯',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lot ${conditionnement.lotOrigine.lotOrigine}',
                                  style: TextStyle(
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  conditionnement
                                      .lotOrigine.predominanceFlorale,
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 14,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                Text(
                                  'Conditionné le ${DateFormat('dd/MM/yyyy').format(conditionnement.dateConditionnement)}',
                                  style: TextStyle(
                                    fontSize: isMobile ? 10 : 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Text(
                              'En stock',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Informations détaillées
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildInfoColumn(
                                  'Quantité',
                                  '${conditionnement.quantiteConditionnee.toStringAsFixed(1)} kg',
                                  Icons.scale,
                                  Colors.blue.shade600,
                                  isMobile,
                                ),
                                _buildInfoColumn(
                                  'Total pots',
                                  conditionnement.nbTotalPots.toString(),
                                  Icons.inventory_2,
                                  Colors.orange.shade600,
                                  isMobile,
                                ),
                                _buildInfoColumn(
                                  'Valeur',
                                  ConditionnementUtils.formatPrix(
                                      conditionnement.prixTotal),
                                  Icons.attach_money,
                                  Colors.green.shade600,
                                  isMobile,
                                ),
                              ],
                            ),
                            if (conditionnement.emballages.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Détail des emballages :',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: conditionnement.emballages
                                    .map(
                                      (emballage) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getFloralTypeColor(
                                                  conditionnement
                                                      .lotOrigine.typeFlorale)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: _getFloralTypeColor(
                                                    conditionnement
                                                        .lotOrigine.typeFlorale)
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        child: Text(
                                          '${emballage.type.nom}: ${emballage.nombreUnitesReelles}',
                                          style: TextStyle(
                                            fontSize: isMobile ? 10 : 12,
                                            fontWeight: FontWeight.w600,
                                            color: _getFloralTypeColor(
                                                conditionnement
                                                    .lotOrigine.typeFlorale),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoColumn(
      String label, String value, IconData icon, Color color, bool isMobile) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: isMobile ? 16 : 20),
          SizedBox(height: isMobile ? 4 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 8 : 10,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warehouse_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun stock trouvé',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Aucun stock ne correspond à votre recherche'
                : 'Aucun produit conditionné en stock',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getFloralTypeColor(TypeFlorale type) {
    switch (type) {
      case TypeFlorale.monoFleur:
        return const Color(0xFFFF6B35);
      case TypeFlorale.milleFleurs:
        return const Color(0xFFF7931E);
      case TypeFlorale.mixte:
        return const Color(0xFFFFD23F);
    }
  }
}
