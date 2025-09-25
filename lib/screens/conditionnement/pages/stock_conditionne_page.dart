import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../conditionnement_models.dart';
import '../../../utils/smart_appbar.dart';
import '../services/conditionnement_db_service.dart';

/// 📊 PAGE STOCK CONDITIONNÉ
///
/// Interface moderne pour visualiser et gérer le stock de produits conditionnés

class StockConditionnePage extends StatefulWidget {
  const StockConditionnePage({super.key});

  @override
  State<StockConditionnePage> createState() => _StockConditionnePageState();
}

class _StockConditionnePageState extends State<StockConditionnePage>
    with TickerProviderStateMixin {
  late ConditionnementDbService _service;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _listController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _listAnimation; // (conservé pour future animations)

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

    try {
      _service = Get.find<ConditionnementDbService>();
    } catch (e) {
      print(
          'ℹ️ [StockPage] Instance service absente, initialisation nouvelle: $e');
      _service = Get.put(ConditionnementDbService());
    }

    _initializeAnimations();
    _searchController.addListener(_onSearchChanged);

    // 🔥 Décaler le chargement après l'initialisation complète
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
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
    if (mounted) {
      _fadeController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _listController.forward();
        }
      });
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      print('🔄 [StockPage] Début du chargement des données...');

      // 🔥 UTILISATION DU SERVICE DB MODERNE
      await _service.refreshData();

      if (!mounted) return;

      _conditionnements = _service.conditionnements;
      print(
          '📊 [StockPage] Conditionnements récupérés: ${_conditionnements.length}');

      _statistics = _generateStatistics(_conditionnements);
      print('📈 [StockPage] Statistiques générées: $_statistics');
    } catch (e) {
      print('❌ [StockPage] Erreur chargement: $e');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            'Erreur',
            'Impossible de charger les données: $e',
            backgroundColor: Colors.red.shade600,
            colorText: Colors.white,
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('✅ [StockPage] Chargement terminé');
    }
  }

  /// 🐛 DEBUG - Forcer le rechargement avec logs détaillés
  Future<void> _debugLoadData() async {
    print('🐛 [DEBUG] =================================');
    print('🐛 [DEBUG] DÉMARRAGE DEBUG STOCK CONDITIONNÉ');
    print('🐛 [DEBUG] =================================');

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Vérifier l'état du service
      print('🐛 [DEBUG] Service disponible: true');
      print('🐛 [DEBUG] Service loading: ${_service.isLoading}');
      print(
          '🐛 [DEBUG] Conditionnements actuels: ${_service.conditionnements.length}');

      // Forcer le rechargement complet
      print('🐛 [DEBUG] Lancement refreshData...');
      await _service.refreshData();

      // Vérifier les résultats
      _conditionnements = _service.conditionnements;
      print(
          '🐛 [DEBUG] Après refresh - Conditionnements: ${_conditionnements.length}');

      if (_conditionnements.isNotEmpty) {
        print('🐛 [DEBUG] Premier conditionnement:');
        final premier = _conditionnements.first;
        print('  - ID: ${premier.id}');
        print('  - Lot: ${premier.lotOrigine.lotOrigine}');
        print('  - Date: ${premier.dateConditionnement}');
        print('  - Quantité: ${premier.quantiteConditionnee}kg');
        print('  - Emballages: ${premier.emballages.length}');
      }

      _statistics = _generateStatistics(_conditionnements);
      print('🐛 [DEBUG] Statistiques: $_statistics');

      // Message de succès
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            'Debug Info',
            'Conditionnements trouvés: ${_conditionnements.length}',
            backgroundColor: Colors.blue.shade600,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        });
      }
    } catch (e) {
      print('🐛 [DEBUG] ERREUR: $e');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            'Erreur Debug',
            'Erreur: $e',
            backgroundColor: Colors.red.shade600,
            colorText: Colors.white,
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('🐛 [DEBUG] =================================');
      print('🐛 [DEBUG] FIN DEBUG STOCK CONDITIONNÉ');
      print('🐛 [DEBUG] =================================');
    }
  }

  // Test data creation removed per requirement

  /// 📊 GÉNÉRATION DES STATISTIQUES À PARTIR DES CONDITIONNEMENTS
  Map<String, dynamic> _generateStatistics(
      List<ConditionnementData> conditionnements) {
    if (conditionnements.isEmpty) {
      return {
        'totalLots': 0,
        'quantiteTotale': 0.0,
        'valeurTotale': 0.0,
      };
    }

    double quantiteTotale = 0.0;
    double valeurTotale = 0.0;
    final sitesStats = <String, Map<String, dynamic>>{};
    final floraleStats = <String, Map<String, dynamic>>{};

    for (final conditionnement in conditionnements) {
      quantiteTotale += conditionnement.quantiteConditionnee;
      valeurTotale += conditionnement.prixTotal;

      // Stats par site
      final site = conditionnement.lotOrigine.site;
      sitesStats[site] ??= {'nombre': 0, 'quantite': 0.0, 'valeur': 0.0};
      sitesStats[site]!['nombre'] = (sitesStats[site]!['nombre'] as int) + 1;
      sitesStats[site]!['quantite'] =
          (sitesStats[site]!['quantite'] as double) +
              conditionnement.quantiteConditionnee;
      sitesStats[site]!['valeur'] =
          (sitesStats[site]!['valeur'] as double) + conditionnement.prixTotal;

      // Stats par florale
      final florale = conditionnement.lotOrigine.predominanceFlorale;
      floraleStats[florale] ??= {'nombre': 0, 'quantite': 0.0, 'valeur': 0.0};
      floraleStats[florale]!['nombre'] =
          (floraleStats[florale]!['nombre'] as int) + 1;
      floraleStats[florale]!['quantite'] =
          (floraleStats[florale]!['quantite'] as double) +
              conditionnement.quantiteConditionnee;
      floraleStats[florale]!['valeur'] =
          (floraleStats[florale]!['valeur'] as double) +
              conditionnement.prixTotal;
    }

    return {
      'totalLots': conditionnements.length,
      'quantiteTotale': quantiteTotale,
      'valeurTotale': valeurTotale,
      'repartitionSites': sitesStats,
      'repartitionFlorale': floraleStats,
    };
  }

  void _onSearchChanged() {
    if (!mounted) return;
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
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _debugLoadData,
            tooltip: 'Debug - Forcer rechargement',
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
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeaderSection(isMobile)),
              SliverToBoxAdapter(child: _buildFiltersSection(isMobile)),
              SliverPadding(
                padding: EdgeInsets.only(
                    left: isMobile ? 12 : 20,
                    right: isMobile ? 12 : 20,
                    bottom: 40),
                sliver: _buildStockListSliver(isMobile),
              ),
            ],
          ),
        );
      },
    );
  }

  SliverList _buildStockListSliver(bool isMobile) {
    final items = _filteredConditionnements;
    if (items.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: EdgeInsets.only(
                left: isMobile ? 12 : 20, right: isMobile ? 12 : 20, top: 40),
            child: _buildEmptyState(),
          )
        ]),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final conditionnement = items[index];
          return AnimatedBuilder(
            animation: _listAnimation,
            builder: (context, child) => Opacity(
              opacity: _listAnimation.value,
              child: Transform.translate(
                offset: Offset(0, (1 - _listAnimation.value) * 20),
                child: child,
              ),
            ),
            child: _buildStockCard(conditionnement, isMobile, index),
          );
        },
        childCount: items.length,
      ),
    );
  }

  Widget _buildStockCard(ConditionnementData c, bool isMobile, int index) {
    return _buildConditionnementCard(c, isMobile);
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

            // Statistiques 🔥 MISE À JOUR
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '🏭',
                    'Lots',
                    '${_statistics['totalLots'] ?? 0}',
                    'Total de lots conditionnés',
                    isMobile,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '⚖️',
                    'Quantité',
                    '${(_statistics['quantiteTotale'] ?? 0.0).toStringAsFixed(1)} kg',
                    'Poids total en stock',
                    isMobile,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '💰',
                    'Valeur',
                    '${(_statistics['valeurTotale'] ?? 0.0).toStringAsFixed(0)} FCFA',
                    'Valeur totale du stock',
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

  /// 📊 WIDGET CARD STATISTIQUE
  Widget _buildStatCard(
      String icon, String title, String value, String subtitle, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            icon,
            style: TextStyle(fontSize: isMobile ? 20 : 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: isMobile ? 10 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: isMobile ? 8 : 10,
            ),
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un lot...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9C27B0)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _selectedSiteFilter,
            hint: const Text('Site'),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Tous les sites'),
              ),
              ...(_statistics['repartitionSites'] as Map<String, dynamic>? ??
                      {})
                  .keys
                  .map((site) => DropdownMenuItem<String>(
                        value: site,
                        child: Text(site),
                      )),
            ],
            onChanged: (value) {
              if (mounted) {
                setState(() {
                  _selectedSiteFilter = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  // Ancienne méthode _buildStockList supprimée (remplacée par SliverList)

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
              Icons.inventory_2,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun stock trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aucun produit conditionné en stock',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),

          // Bouton de debug visible pour diagnostiquer
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Diagnostic',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _debugLoadData,
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Diagnostiquer le problème'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // Button for creating test data removed
                const SizedBox(height: 8),
                Text(
                  'Cliquez pour voir les détails techniques\ndans la console de debug',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionnementCard(
      ConditionnementData conditionnement, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _showConditionnementDetails(conditionnement),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9C27B0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ConditionnementUtils.iconesByFlorale[
                                conditionnement.lotOrigine.typeFlorale] ??
                            '🍯',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lot ${conditionnement.lotOrigine.lotOrigine}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            conditionnement.lotOrigine.predominanceFlorale,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: isMobile ? 12 : 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${conditionnement.quantiteConditionnee.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF9C27B0),
                            fontSize: isMobile ? 12 : 14,
                          ),
                        ),
                        Text(
                          '${conditionnement.prixTotal.toStringAsFixed(0)} FCFA',
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: isMobile ? 10 : 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      conditionnement.lotOrigine.site,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd/MM/yyyy')
                          .format(conditionnement.dateConditionnement),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ...conditionnement.emballages.take(3).map(
                          (emb) => Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9C27B0).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${emb.nombreSaisi}x ${emb.type.nom}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                    if (conditionnement.emballages.length > 3)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+${conditionnement.emballages.length - 3}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showConditionnementDetails(ConditionnementData conditionnement) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 700),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9C27B0).withOpacity(0.1),
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
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              conditionnement.lotOrigine.predominanceFlorale,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow('Site', conditionnement.lotOrigine.site),
                  _buildDetailRow(
                      'Date de conditionnement',
                      DateFormat('dd/MM/yyyy')
                          .format(conditionnement.dateConditionnement)),
                  _buildDetailRow('Quantité conditionnée',
                      '${conditionnement.quantiteConditionnee.toStringAsFixed(2)} kg'),
                  _buildDetailRow('Prix total',
                      '${conditionnement.prixTotal.toStringAsFixed(0)} FCFA'),
                  const SizedBox(height: 16),
                  const Text(
                    'Emballages:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // En-tête des colonnes
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 24), // espace pour icône
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Type',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text('Contenu',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700)),
                        ),
                        Expanded(
                          child: Text('Unites',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700)),
                        ),
                        Expanded(
                          child: Text('Poids',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700)),
                        ),
                        Expanded(
                          child: Text('Prix',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...conditionnement.emballages.map((emb) {
                    final contenance = emb.type.contenanceKg;
                    final nb = emb.nombreUnitesReelles;
                    final poids = emb.poidsTotal;
                    final prix = emb.prixTotal;
                    final prixUnitaire = nb > 0 ? prix / nb : 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(emb.type.icone),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: Text('${emb.type.nom}'),
                          ),
                          Expanded(
                            child: Text('${contenance.toStringAsFixed(2)}kg',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12)),
                          ),
                          Expanded(
                            child: Text('$nb',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12)),
                          ),
                          Expanded(
                            child: Text('${poids.toStringAsFixed(2)}kg',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12)),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${prix.toStringAsFixed(0)} FCFA',
                                    style: TextStyle(
                                        color: Colors.green.shade600,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12)),
                                Text('${prixUnitaire.toStringAsFixed(0)} u',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 10)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  _buildDetailRow('Quantité restante',
                      '${conditionnement.quantiteRestante.toStringAsFixed(2)} kg'),
                  if (conditionnement.observations?.isNotEmpty == true)
                    _buildDetailRow(
                        'Observations', conditionnement.observations!.trim()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(' : '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
