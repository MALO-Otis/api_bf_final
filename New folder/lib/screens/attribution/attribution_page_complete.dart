import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'widgets/attribution_filters.dart';
import 'pages/attribution_history_page.dart';
import 'widgets/attribution_stats_widget.dart';
import 'services/attribution_page_service.dart';
import 'services/attribution_service_complete.dart';
import '../controle_de_donnes/models/collecte_models.dart';
import '../controle_de_donnes/models/attribution_models_v2.dart' as models;

/// 🎯 PAGE D'ATTRIBUTION PRINCIPALE - SYSTÈME MODERNE
///
/// Cette page unifie tous les processus d'attribution avec le nouveau modal modernisé
/// - 🟫 Extraction (produits bruts)
/// - 🔵 Filtrage (produits liquides)
/// - 🟤 Traitement Cire (produits cire)
class AttributionPageComplete extends StatefulWidget {
  const AttributionPageComplete({Key? key}) : super(key: key);

  @override
  State<AttributionPageComplete> createState() =>
      _AttributionPageCompleteState();
}

class _AttributionPageCompleteState extends State<AttributionPageComplete>
    with TickerProviderStateMixin {
  // Services
  late final AttributionPageService _attributionService;
  late final AttributionServiceComplete _attributionServiceComplete;

  // Controllers
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // State
  final RxBool _isLoading = true.obs;
  final RxList<models.ProductControle> _produitsDisponibles =
      <models.ProductControle>[].obs;
  final RxList<models.ProductControle> _produitsFiltres =
      <models.ProductControle>[].obs;
  final Rx<AttributionFilters> _filtres = AttributionFilters().obs;
  final RxString _searchQuery = ''.obs;
  final RxInt _selectedTabIndex = 0.obs;

  // 🆕 SÉLECTION MULTIPLE
  final RxList<models.ProductControle> _produitsSelectionnes =
      <models.ProductControle>[].obs;
  final RxBool _modeSelectionMultiple = false.obs;

  // Statistiques
  final RxMap<String, int> _stats = <String, int>{}.obs;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeControllers();
    _loadData();
  }

  void _initializeServices() {
    _attributionService = AttributionPageService();
    _attributionServiceComplete = AttributionServiceComplete();
  }

  void _initializeControllers() {
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      _selectedTabIndex.value = _tabController.index;
      _applyFilters();
    });

    _searchController.addListener(() {
      _searchQuery.value = _searchController.text;
      _applyFilters();
    });
  }

  Future<void> _loadData() async {
    try {
      _isLoading.value = true;

      if (kDebugMode) {
        print('');
        print('🚀 [Attribution Complete] ===== DÉBUT CHARGEMENT DONNÉES =====');
        print('   📅 Timestamp: ${DateTime.now()}');
        print('   🔄 Statut loading: ${_isLoading.value}');
        print('   📊 Produits actuels: ${_produitsDisponibles.length}');
      }

      // Charger tous les produits contrôlés disponibles pour attribution
      final produits =
          await _attributionService.getProduitsDisponiblesAttribution();

      if (kDebugMode) {
        print('✅ [Attribution Complete] Produits chargés depuis le service:');
        print('   📦 Nombre total: ${produits.length}');

        // Analyse détaillée des poids
        double poidsTotal = 0.0;
        Map<models.ProductNature, int> repartition = {};
        Map<String, double> poidsByCollecte = {};

        for (final produit in produits) {
          poidsTotal += produit.poidsTotal;
          repartition[produit.nature] = (repartition[produit.nature] ?? 0) + 1;
          poidsByCollecte[produit.collecteId] =
              (poidsByCollecte[produit.collecteId] ?? 0) + produit.poidsTotal;
        }

        print('   ⚖️ Poids total: ${poidsTotal.toStringAsFixed(2)} kg');
        print('   🎯 Répartition par nature:');
        repartition.forEach((nature, count) {
          print(
              '      - ${nature.toString().split('.').last}: $count produits');
        });

        // Détail des premiers produits pour diagnostic
        print('   📋 DÉTAIL DES PREMIERS PRODUITS:');
        for (int i = 0; i < produits.length && i < 5; i++) {
          final p = produits[i];
          print(
              '      - ${p.codeContenant}: ${p.poidsTotal}kg total, ${p.poidsMiel}kg miel');
          print('        * Collecte: ${p.collecteId}');
          print('        * Conforme: ${p.estConforme}');
          print('        * Nature: ${p.nature.toString().split('.').last}');
        }
        if (produits.length > 5) {
          print('      ... et ${produits.length - 5} autres produits');
        }
      }

      // Assigner les produits AVANT de calculer les stats
      _produitsDisponibles.assignAll(produits);

      // Calculer les statistiques APRÈS avoir assigné les produits
      _calculateStats();

      // Appliquer les filtres initiaux
      _applyFilters();

      if (kDebugMode) {
        print('');
        print('✅ [Attribution Complete] ===== CHARGEMENT TERMINÉ =====');
        print('   📊 Produits assignés: ${_produitsDisponibles.length}');
        print('   🔍 Produits filtrés: ${_produitsFiltres.length}');
        print('   📈 Statistiques calculées: ${_stats.length} entrées');
        print('   🎯 Stats détaillées:');
        _stats.forEach((key, value) {
          print('      - $key: $value');
        });
        print('   📅 Fin du chargement: ${DateTime.now()}');
        print('========================================================');
        print('');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('');
        print('❌❌❌ [Attribution Complete] ERREUR CRITIQUE ❌❌❌');
        print('   🚨 Type d\'erreur: ${e.runtimeType}');
        print('   📝 Message: $e');
        print('   📅 Timestamp: ${DateTime.now()}');
        print('   🔍 État au moment de l\'erreur:');
        print('      - Produits disponibles: ${_produitsDisponibles.length}');
        print('      - Produits filtrés: ${_produitsFiltres.length}');
        print('      - Statut loading: ${_isLoading.value}');
        print('   📍 Stack trace:');
        print(stackTrace.toString());
        print(
            '================================================================');
        print('');
      }

      Get.snackbar(
        'Erreur',
        'Impossible de charger les données: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void _calculateStats() {
    // Calculer les stats sur TOUS les produits disponibles (pas filtrés)
    final stats = <String, int>{
      'total': _produitsDisponibles.length,
      'bruts': _produitsDisponibles
          .where((p) => p.nature == models.ProductNature.brut)
          .length,
      'liquides': _produitsDisponibles
          .where((p) => p.nature == models.ProductNature.liquide)
          .length,
      'cire': _produitsDisponibles
          .where((p) => p.nature == models.ProductNature.cire)
          .length,
      'urgents': _produitsDisponibles.where((p) => p.isUrgent).length,
    };

    debugPrint('📊 Statistiques calculées:');
    debugPrint('   Total: ${stats['total']}');
    debugPrint('   Bruts: ${stats['bruts']}');
    debugPrint('   Liquides: ${stats['liquides']}');
    debugPrint('   Cire: ${stats['cire']}');

    // Forcer la mise à jour de l'interface
    _stats.clear();
    _stats.addAll(stats);
  }

  void _applyFilters() {
    var produitsFiltres = _produitsDisponibles.where((produit) {
      // Filtre par onglet (nature de produit)
      switch (_selectedTabIndex.value) {
        case 0: // Tous
          break;
        case 1: // Extraction (bruts)
          if (produit.nature != models.ProductNature.brut) return false;
          break;
        case 2: // Filtrage (liquides)
          if (produit.nature != models.ProductNature.liquide) return false;
          break;
        case 3: // Traitement Cire
          if (produit.nature != models.ProductNature.cire) return false;
          break;
      }

      // Filtre par recherche
      if (_searchQuery.value.isNotEmpty) {
        final query = _searchQuery.value.toLowerCase();
        if (!produit.producteur.toLowerCase().contains(query) &&
            !produit.codeContenant.toLowerCase().contains(query) &&
            !produit.village.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Autres filtres
      return _filtres.value.matches(produit);
    }).toList();

    // Tri par urgence puis par date
    produitsFiltres.sort((a, b) {
      if (a.isUrgent && !b.isUrgent) return -1;
      if (!a.isUrgent && b.isUrgent) return 1;
      return b.dateReception.compareTo(a.dateReception);
    });

    _produitsFiltres.assignAll(produitsFiltres);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar
          _buildSliverAppBar(),

          // 🆕 MODE SÉLECTION INDICATOR
          SliverToBoxAdapter(
            child: _buildSelectionModeIndicator(),
          ),

          // Statistiques
          SliverToBoxAdapter(
            child: _buildStatsSection(),
          ),

          // Barre de recherche et filtres
          SliverToBoxAdapter(
            child: _buildSearchAndFilters(),
          ),

          // Onglets
          SliverToBoxAdapter(
            child: _buildTabBar(),
          ),

          // Contenu principal (collectes groupées)
          _buildSliverContent(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// 🎯 INDICATEUR MODE SÉLECTION
  Widget _buildSelectionModeIndicator() {
    return Obx(() {
      if (!_modeSelectionMultiple.value) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.touch_app, color: Colors.blue.shade600, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mode sélection multiple activé',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${_produitsSelectionnes.length} produit(s) sélectionné(s)',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (_produitsSelectionnes.isNotEmpty)
              TextButton(
                onPressed: () => _produitsSelectionnes.clear(),
                child: const Text('Tout désélectionner'),
              ),
            IconButton(
              onPressed: () {
                _produitsSelectionnes.clear();
                _modeSelectionMultiple.value = false;
              },
              icon: const Icon(Icons.close),
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      );
    });
  }

  /// 🎨 CONSTRUCTION SLIVER APP BAR
  ///
  /// App bar qui se rétracte avec le scroll
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      centerTitle: false,
      backgroundColor: Colors.indigo[600],
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.indigo[700]!,
                Colors.indigo[500]!,
              ],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final collapsed = constraints.maxHeight <= (kToolbarHeight + 20);
              return Stack(
                children: [
                  // Expanded header (big title + subtitle)
                  AnimatedOpacity(
                    opacity: collapsed ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Padding(
                      padding:
                          const EdgeInsets.only(left: 16, right: 16, top: 50),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.assignment_turned_in,
                                size: 24, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Attribution de Produits',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Extraction • Filtrage • Traitement Cire',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Collapsed header (small title only)
                  Positioned(
                    left: 16,
                    bottom: 12,
                    child: AnimatedOpacity(
                      opacity: collapsed ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      child: const Text(
                        'Attribution de Produits',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
          tooltip: 'Actualiser',
        ),
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: () => _showHistorique(),
          tooltip: 'Historique',
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Obx(() => AttributionStatsWidget(
            stats: _stats,
            isLoading: _isLoading.value,
          )),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Barre de recherche
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par producteur, code, village...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(() {
                  if (_searchQuery.value.isNotEmpty) {
                    return IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    );
                  }
                  return const SizedBox.shrink();
                }),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Bouton filtres
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune),
              onPressed: () => _showFiltersModal(),
              tooltip: 'Filtres avancés',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Obx(() => TabBar(
            controller: _tabController,
            tabs: [
              _buildTab('Tous', Icons.all_inclusive, _stats['total'] ?? 0),
              _buildTab('Extraction', Icons.science, _stats['bruts'] ?? 0),
              _buildTab('Filtrage', Icons.water_drop, _stats['liquides'] ?? 0),
              _buildTab('Traitement Cire', Icons.spa, _stats['cire'] ?? 0),
            ],
            labelColor: Colors.indigo[600],
            unselectedLabelColor: Colors.grey[600],
            indicator: BoxDecoration(
              color: Colors.indigo[50],
              borderRadius: BorderRadius.circular(8),
            ),
            indicatorPadding: const EdgeInsets.all(4),
            dividerColor: Colors.transparent,
          )),
    );
  }

  Widget _buildTab(String label, IconData icon, int count) {
    return Tab(
      height: 60,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.indigo[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 CONSTRUCTION SLIVER CONTENT
  ///
  /// Contenu principal avec produits regroupés par collecte
  Widget _buildSliverContent() {
    return Obx(() {
      if (_isLoading.value) {
        return SliverFillRemaining(
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Chargement des produits...'),
              ],
            ),
          ),
        );
      }

      if (_produitsFiltres.isEmpty) {
        return SliverFillRemaining(
          child: _buildEmptyState(),
        );
      }

      // Regrouper les produits par collecte
      final produitsParCollecte = _groupProductsByCollecte(_produitsFiltres);

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final collecteEntry = produitsParCollecte.entries.elementAt(index);
            final collecteId = collecteEntry.key;
            final produits = collecteEntry.value;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildCollecteExpansionCard(collecteId, produits),
            );
          },
          childCount: produitsParCollecte.length,
        ),
      );
    });
  }

  /// 📦 REGROUPEMENT DES PRODUITS PAR COLLECTE
  ///
  /// Groupe les produits selon leur ID de collecte
  Map<String, List<models.ProductControle>> _groupProductsByCollecte(
      List<models.ProductControle> produits) {
    final groupes = <String, List<models.ProductControle>>{};

    for (final produit in produits) {
      final collecteId = produit.collecteId;
      if (!groupes.containsKey(collecteId)) {
        groupes[collecteId] = [];
      }
      groupes[collecteId]!.add(produit);
    }

    // Trier les groupes par date de collecte (plus récent en premier)
    final sortedEntries = groupes.entries.toList()
      ..sort((a, b) {
        final dateA = a.value.first.dateCollecte;
        final dateB = b.value.first.dateCollecte;
        return dateB.compareTo(dateA);
      });

    return Map.fromEntries(sortedEntries);
  }

  /// 🎴 CARTE D'EXPANSION POUR UNE COLLECTE
  ///
  /// Carte dépliante contenant tous les produits d'une collecte
  Widget _buildCollecteExpansionCard(
      String collecteId, List<models.ProductControle> produits) {
    final premierProduit = produits.first;
    final nbProduits = produits.length;
    final poidsTotal =
        produits.fold(0.0, (sum, p) => sum + p.poidsTotal).toStringAsFixed(1);
    final poidsMielTotal =
        produits.fold(0.0, (sum, p) => sum + p.poidsMiel).toStringAsFixed(1);
    final nbUrgents = produits.where((p) => p.isUrgent).length;

    return Card(
      elevation: 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getCollecteTypeColor(premierProduit.typeCollecte)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCollecteTypeIcon(premierProduit.typeCollecte),
              color: _getCollecteTypeColor(premierProduit.typeCollecte),
              size: 24,
            ),
          ),
          title: Text(
            'Collecte ${premierProduit.typeCollecte}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${premierProduit.siteOrigine} • ${_formatDate(premierProduit.dateCollecte)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildInfoChip('$nbProduits produits', Colors.blue),
                  _buildInfoChip('Total: $poidsTotal kg', Colors.indigo),
                  _buildInfoChip('Miel: $poidsMielTotal kg', Colors.green),
                  if (nbUrgents > 0)
                    _buildInfoChip('$nbUrgents urgents', Colors.red),
                ],
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                children: produits
                    .map((produit) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildProductMiniCard(produit),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🎨 CONSTRUCTION CHIP INFORMATIF
  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Format long product codes based on available width
  /// - When isVeryNarrow is true: show an ellipsized prefix with the last N digits
  ///   example: REC_REO_..._0002 (for keepLastDigits=4)
  /// - Otherwise: return the full code (ellipsis applied by Text where used)
  String _formatProductCode(String code,
      {required bool isVeryNarrow, int keepLastDigits = 4}) {
    if (!isVeryNarrow) return code;
    if (code.length <= keepLastDigits + 3) return code;
    final tail = code.substring(code.length - keepLastDigits);
    return '...$tail';
  }

  /// 📱 MINI CARTE PRODUIT
  ///
  /// Carte compacte pour afficher un produit dans la collecte
  Widget _buildProductMiniCard(models.ProductControle produit) {
    return Obx(() {
      final isSelected = _produitsSelectionnes.contains(produit);
      final isSelectionMode = _modeSelectionMultiple.value;

      return GestureDetector(
        onTap: isSelectionMode
            ? () {
                if (isSelected) {
                  _produitsSelectionnes.remove(produit);
                } else {
                  _produitsSelectionnes.add(produit);
                }
              }
            : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blue.shade100
                : (produit.isUrgent ? Colors.red[50] : Colors.grey[50]),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Colors.blue.shade400
                  : (produit.isUrgent ? Colors.red[200]! : Colors.grey[200]!),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Icône nature produit
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _getNatureColor(produit.nature).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getNatureIcon(produit.nature),
                  color: _getNatureColor(produit.nature),
                  size: 16,
                ),
              ),

              const SizedBox(width: 12),

              // Informations produit
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isVeryNarrow = constraints.maxWidth < 560;
                              final display = _formatProductCode(
                                produit.codeContenant,
                                isVeryNarrow: isVeryNarrow,
                                keepLastDigits: 4,
                              );
                              return Text(
                                display,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: _getNatureColor(produit.nature)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            produit.nature.label,
                            style: TextStyle(
                              color: _getNatureColor(produit.nature),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (produit.isUrgent) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.access_time,
                              color: Colors.red, size: 12),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(Icons.scale, color: Colors.blue[600], size: 12),
                        Text(
                          'Total: ${produit.poidsTotal.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(Icons.water_drop,
                            color: Colors.green[600], size: 12),
                        Text(
                          'Miel: ${produit.poidsMiel.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Boutons d'action / Checkbox sélection
              if (isSelectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    if (value == true) {
                      _produitsSelectionnes.add(produit);
                    } else {
                      _produitsSelectionnes.remove(produit);
                    }
                  },
                  activeColor: Colors.blue.shade600,
                )
              else
                PopupMenuButton<AttributionType>(
                  onSelected: (type) => _attribuerProduit(produit, type),
                  icon: Icon(
                    Icons.assignment_turned_in,
                    color: Colors.indigo[600],
                    size: 20,
                  ),
                  tooltip: 'Attribuer ce produit',
                  itemBuilder: (context) => _buildAttributionMenuItems(produit),
                ),
            ],
          ),
        ),
      );
    });
  }

  /// 🎯 ATTRIBUTION D'UN SEUL PRODUIT
  Future<void> _attribuerProduit(
      models.ProductControle produit, AttributionType type) async {
    await _attribuerProduits([produit], type);
  }

  /// 🎯 ATTRIBUTION DE PLUSIEURS PRODUITS (NOUVEAU SYSTÈME)
  Future<void> _attribuerProduits(
      List<models.ProductControle> produits, AttributionType type) async {
    if (produits.isEmpty) {
      Get.snackbar(
        'Attention',
        'Aucun produit sélectionné pour attribution',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        icon: const Icon(Icons.warning, color: Colors.orange),
      );
      return;
    }

    try {
      if (kDebugMode) {
        print('🎯 ===== ATTRIBUTION MULTIPLE =====');
        print('   📊 Nombre de produits: ${produits.length}');
        print('   🏭 Type: ${type.label}');
        print(
            '   🗂️ Collectes différentes: ${produits.map((p) => p.collecteId).toSet().length}');
        final poidsTotal = produits.fold(0.0, (sum, p) => sum + p.poidsTotal);
        final poidsMielTotal =
            produits.fold(0.0, (sum, p) => sum + p.poidsMiel);
        print('   ⚖️ Poids total: ${poidsTotal.toStringAsFixed(2)} kg');
        print('   🍯 Poids miel: ${poidsMielTotal.toStringAsFixed(2)} kg');
      }

      // Vérifier que tous les produits peuvent être attribués
      final produitsInvalides =
          produits.where((p) => !_canBeAttributed(p, type)).toList();
      if (produitsInvalides.isNotEmpty) {
        await _showProduitsInvalidesDialog(produitsInvalides, type);
        return;
      }

      // Afficher le dialogue de confirmation d'attribution multiple
      final confirmation = await _showAttributionMultipleDialog(produits, type);
      if (confirmation != true) return;

      // Afficher le loading
      _isLoading.value = true;

      // Effectuer l'attribution avec le nouveau service complet
      final utilisateur =
          'Utilisateur Attribution'; // TODO: Récupérer depuis UserSession
      final success = await _attributionServiceComplete.attribuerProduits(
        produits: produits,
        type: type,
        utilisateur: utilisateur,
        commentaires: null, // TODO: Récupérer depuis le dialogue
      );

      _isLoading.value = false;

      if (success) {
        // Succès - Nettoyer la sélection
        _produitsSelectionnes.clear();
        _modeSelectionMultiple.value = false;

        // Recharger les données pour refléter les changements
        await _loadData();

        if (kDebugMode) {
          print('✅ Attribution multiple réussie !');
          print('   📦 ${produits.length} produits attribués');
          print('   🏭 Type: ${type.label}');
          print(
              '   📊 Nouveaux totaux: ${_produitsDisponibles.length} produits disponibles');
        }

        Get.snackbar(
          'Attribution réussie',
          '${produits.length} produit(s) attribué(s) avec succès pour ${type.label}',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          icon: Icon(Icons.check_circle, color: Colors.green),
          duration: const Duration(seconds: 4),
        );
      } else {
        // Échec
        Get.snackbar(
          'Erreur d\'attribution',
          'Impossible d\'attribuer les produits sélectionnés',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          icon: const Icon(Icons.error, color: Colors.red),
        );
      }
    } catch (e, stackTrace) {
      _isLoading.value = false;

      if (kDebugMode) {
        print('❌ ERREUR ATTRIBUTION MULTIPLE: $e');
        print('Stack trace: $stackTrace');
      }

      Get.snackbar(
        'Erreur d\'attribution',
        'Une erreur est survenue lors de l\'attribution: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    }
  }

  bool _canBeAttributed(models.ProductControle produit, AttributionType type) {
    switch (type) {
      case AttributionType.extraction:
        return produit.nature == models.ProductNature.brut &&
            produit.estConforme &&
            !produit.estAttribue;
      case AttributionType.filtrage:
        return produit.nature == models.ProductNature.liquide &&
            produit.estConforme &&
            !produit.estAttribue;
      case AttributionType.cire:
        return produit.nature == models.ProductNature.cire &&
            produit.estConforme &&
            !produit.estAttribue;
    }
  }

  String _getAttributionErrorMessage(
      models.ProductControle produit, AttributionType type) {
    if (produit.estAttribue) {
      return 'Ce produit a déjà été attribué';
    }

    if (!produit.estConforme) {
      return 'Seuls les produits conformes peuvent être attribués';
    }

    switch (type) {
      case AttributionType.extraction:
        return 'Seuls les produits bruts peuvent être attribués à l\'extraction';
      case AttributionType.filtrage:
        return 'Seuls les produits liquides peuvent être attribués au filtrage';
      case AttributionType.cire:
        return 'Seuls les produits cire peuvent être attribués à la production cire';
    }
  }

  /// 🚫 DIALOGUE PRODUITS INVALIDES
  Future<void> _showProduitsInvalidesDialog(
      List<models.ProductControle> produitsInvalides,
      AttributionType type) async {
    return Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Produits incompatibles'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${produitsInvalides.length} produit(s) ne peuvent pas être attribués pour ${type.label}:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...produitsInvalides.take(5).map((produit) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.close, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isVeryNarrow = constraints.maxWidth < 350;
                            final displayCode = _formatProductCode(
                              produit.codeContenant,
                              isVeryNarrow: isVeryNarrow,
                              keepLastDigits: 4,
                            );
                            return Text(
                              '$displayCode - ${_getAttributionErrorMessage(produit, type)}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                )),
            if (produitsInvalides.length > 5)
              Text(
                '... et ${produitsInvalides.length - 5} autre(s)',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  /// 📋 DIALOGUE DE CONFIRMATION D'ATTRIBUTION MULTIPLE (MODERNE)
  Future<bool?> _showAttributionMultipleDialog(
      List<models.ProductControle> produits, AttributionType type) async {
    // Calculs des statistiques
    final poidsTotal = produits.fold(0.0, (sum, p) => sum + p.poidsTotal);
    final poidsMielTotal = produits.fold(0.0, (sum, p) => sum + p.poidsMiel);
    final collectesDifferentes =
        produits.map((p) => p.collecteId).toSet().length;
    final sitesDifferents = produits.map((p) => p.siteOrigine).toSet().length;

    // Répartition par nature
    final repartitionNatures = <models.ProductNature, int>{};
    for (final produit in produits) {
      repartitionNatures[produit.nature] =
          (repartitionNatures[produit.nature] ?? 0) + 1;
    }

    // Qualités moyennes
    final qualites = produits.map((p) => p.qualite).toSet().toList();
    final rendementMoyen = poidsMielTotal / poidsTotal * 100;

    return Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: _getTypeGradient(type),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    type.icon,
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attribution ${type.label}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${produits.length} produit(s) sélectionné(s)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.all(16),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 450, maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📊 STATISTIQUES PRINCIPALES
                _buildStatCard(
                  'Statistiques principales',
                  Icons.analytics_outlined,
                  [
                    _buildStatRow('Poids total',
                        '${poidsTotal.toStringAsFixed(2)} kg', Icons.scale),
                    _buildStatRow(
                        'Poids miel',
                        '${poidsMielTotal.toStringAsFixed(2)} kg',
                        Icons.water_drop),
                    _buildStatRow(
                        'Rendement moyen',
                        '${rendementMoyen.toStringAsFixed(1)}%',
                        Icons.trending_up),
                  ],
                  Colors.blue.shade50,
                  Colors.blue.shade200,
                ),

                const SizedBox(height: 12),

                // 🌍 TRAÇABILITÉ
                _buildStatCard(
                  'Traçabilité',
                  Icons.public,
                  [
                    _buildStatRow('Collectes différentes',
                        '$collectesDifferentes', Icons.inventory_2),
                    _buildStatRow('Sites différents', '$sitesDifferents',
                        Icons.location_on),
                    _buildStatRow(
                        'Producteurs uniques',
                        '${produits.map((p) => p.producteur).toSet().length}',
                        Icons.people),
                  ],
                  Colors.green.shade50,
                  Colors.green.shade200,
                ),

                const SizedBox(height: 12),

                // 🏷️ RÉPARTITION PAR NATURE
                _buildNatureCard(repartitionNatures),

                const SizedBox(height: 12),

                // 🏆 QUALITÉ
                _buildQualityCard(qualites),

                const SizedBox(height: 12),

                // 📦 LISTE DES PRODUITS
                _buildProductList(produits),

                // ⚠️ AVERTISSEMENTS
                if (collectesDifferentes > 1) ...[
                  const SizedBox(height: 12),
                  _buildWarningCard(
                    'Attribution multi-collectes',
                    'Cette attribution concerne des produits de $collectesDifferentes collectes différentes.',
                    Icons.info,
                    Colors.orange,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: _getTypeGradient(type),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Confirmer l\'attribution',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Couleur selon la nature du produit
  Color _getNatureColor(models.ProductNature nature) {
    switch (nature) {
      case models.ProductNature.brut:
        return const Color(0xFF8D6E63); // Brun naturel sophistiqué
      case models.ProductNature.liquide:
        return const Color(0xFF42A5F5); // Bleu liquide élégant
      case models.ProductNature.cire:
        return const Color(0xFFFFB74D); // Ambre doré chaleureux
      case models.ProductNature.filtre:
        return const Color(0xFF78909C); // Gris bleuté moderne
    }
  }

  /// Couleur selon le type d'attribution
  // Note: Removed unused overload taking a local AttributionType; we use the
  // widget-scoped _getTypeColor() defined later based on models.AttributionType.

  /// Couleur de fond dégradée selon le type d'attribution
  LinearGradient _getTypeGradient(AttributionType type) {
    switch (type) {
      case AttributionType.extraction:
        return LinearGradient(
          colors: [const Color(0xFF6D4C41), const Color(0xFF8D6E63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AttributionType.filtrage:
        return LinearGradient(
          colors: [const Color(0xFF1E88E5), const Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AttributionType.cire:
        return LinearGradient(
          colors: [const Color(0xFFF57C00), const Color(0xFFFFB74D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  // 🎨 MÉTHODES HELPER POUR LE DIALOGUE MODERNE

  /// Construit une carte de statistiques
  Widget _buildStatCard(String title, IconData icon, List<Widget> rows,
      Color bgColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: borderColor.withOpacity(0.8), size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: borderColor.withOpacity(0.9),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  /// Construit une ligne de statistique
  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la carte de répartition par nature
  Widget _buildNatureCard(Map<models.ProductNature, int> repartition) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.shade100,
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category, color: Colors.purple.shade600, size: 18),
              const SizedBox(width: 6),
              Text(
                'Répartition par nature',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.purple.shade700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: repartition.entries.map((entry) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getNatureColor(entry.key).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _getNatureColor(entry.key).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getNatureColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${entry.key.name.toUpperCase()}: ${entry.value}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _getNatureColor(entry.key).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Construit la carte de qualité
  Widget _buildQualityCard(List<String> qualites) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.shade100,
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber.shade600, size: 18),
              const SizedBox(width: 6),
              Text(
                'Qualité des produits',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: qualites.map((qualite) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Text(
                  qualite,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.amber.shade800,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Construit la liste des produits
  Widget _buildProductList(List<models.ProductControle> produits) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2, color: Colors.grey.shade600, size: 18),
              const SizedBox(width: 6),
              Text(
                'Produits sélectionnés (${produits.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: ListView.builder(
              itemCount: produits.length,
              itemBuilder: (context, index) {
                final produit = produits[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 1),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade200,
                        width: index < produits.length - 1 ? 1 : 0,
                      ),
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getNatureColor(produit.nature),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _getNatureColor(produit.nature)
                                .withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          produit.nature.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    title: LayoutBuilder(
                      builder: (context, constraints) {
                        final isVeryNarrow = constraints.maxWidth < 300;
                        final display = _formatProductCode(
                          produit.codeContenant,
                          isVeryNarrow: isVeryNarrow,
                          keepLastDigits: 4,
                        );
                        return Text(
                          display,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                    subtitle: Text(
                      '${produit.poidsMiel.toStringAsFixed(1)} kg • ${produit.producteur}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Text(
                        produit.qualite,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une carte d'avertissement
  Widget _buildWarningCard(
      String title, String message, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
        boxShadow: [
          BoxShadow(
            color: color.shade100,
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.shade100,
              shape: BoxShape.circle,
              border: Border.all(color: color.shade300),
            ),
            child: Icon(icon, color: color.shade600, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color.shade700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🎈 FLOATING ACTION BUTTONS
  Widget? _buildFloatingActionButton() {
    return Obx(() {
      if (_produitsFiltres.isEmpty) return const SizedBox.shrink();

      // Mode sélection multiple - Retourner seulement le bouton d'attribution
      if (_modeSelectionMultiple.value) {
        if (_produitsSelectionnes.isNotEmpty) {
          return FloatingActionButton.extended(
            heroTag: 'attribuer',
            onPressed: () => _showSelectionAttributionDialog(),
            backgroundColor: Colors.green,
            icon: const Icon(Icons.assignment_turned_in),
            label: Text('Attribuer (${_produitsSelectionnes.length})'),
          );
        } else {
          return FloatingActionButton(
            heroTag: 'cancel',
            onPressed: () {
              _produitsSelectionnes.clear();
              _modeSelectionMultiple.value = false;
            },
            backgroundColor: Colors.grey,
            child: const Icon(Icons.close),
            tooltip: 'Annuler sélection',
          );
        }
      }

      // Mode normal
      return FloatingActionButton.extended(
        onPressed: () {
          _modeSelectionMultiple.value = true;
          Get.snackbar(
            'Mode sélection activé',
            'Touchez les produits pour les sélectionner',
            backgroundColor: Colors.blue.shade100,
            colorText: Colors.blue.shade800,
            icon: const Icon(Icons.touch_app, color: Colors.blue),
            duration: const Duration(seconds: 2),
          );
        },
        icon: const Icon(Icons.checklist),
        label: const Text('Sélection multiple'),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
      );
    });
  }

  /// 🎯 AFFICHER LE NOUVEAU MODAL D'ATTRIBUTION MODERNE
  Future<void> _showModernAttributionModal(
    List<models.ProductControle> produits,
    models.AttributionType type,
  ) async {
    // Créer une collecte virtuelle pour le modal
    // (Le modal attend une collecte, mais ici on a des produits de plusieurs collectes)
    final collecteVirtuelle = _createVirtualCollecte(produits);

    await Get.dialog(
      ModernAttributionModal(
        collecte: collecteVirtuelle,
        type: type,
        selectedProducts: produits,
        onConfirmed: (attributionData) async {
          await _processAttribution(produits, type, attributionData);
        },
      ),
    );
  }

  BaseCollecte _createVirtualCollecte(List<models.ProductControle> produits) {
    // Créer une collecte virtuelle qui représente la sélection
    final totalWeight = produits.fold(0.0, (sum, p) => sum + p.poidsTotal);

    return Scoop(
      id: 'virtual_${DateTime.now().millisecondsSinceEpoch}',
      path: '/virtual/selection',
      date: DateTime.now(),
      scoopNom: 'Sélection Multiple',
      site: 'Sélection Multiple',
      contenants: produits
          .map((p) => ScoopContenant(
                id: p.codeContenant,
                typeContenant: p.typeContenant,
                typeMiel: 'brut',
                quantite: p.poidsTotal,
                prixUnitaire: 0.0,
                montantTotal: 0.0,
                predominanceFlorale: p.predominanceFlorale,
              ))
          .toList(),
      totalWeight: totalWeight,
      totalAmount: 0.0,
      statut: 'SELECTIONNE',
    );
  }

  /// Convertir le type models.AttributionType vers le type du service
  AttributionType _convertToServiceType(models.AttributionType type) {
    switch (type) {
      case models.AttributionType.extraction:
        return AttributionType.extraction;
      case models.AttributionType.filtration:
        return AttributionType.filtrage;
      case models.AttributionType.traitementCire:
        return AttributionType.cire;
    }
  }

  Future<void> _processAttribution(
    List<models.ProductControle> produits,
    models.AttributionType type,
    Map<String, dynamic> attributionData,
  ) async {
    try {
      _isLoading.value = true;

      if (kDebugMode) {
        print('🎯 Attribution en cours...');
        print('   Produits: ${produits.length}');
        print('   Type: ${type.label}');
      }

      // Convertir le type models.AttributionType vers le type du service
      final serviceType = _convertToServiceType(type);

      // 🚀 LOGS DE TRAÇAGE INTERFACE PRINCIPALE
      debugPrint('🖥️ ===== INTERFACE PRINCIPALE APPELLE LE SERVICE =====');
      debugPrint('   📄 Fichier: attribution_page_complete.dart');
      debugPrint('   🔧 Méthode: _processAttribution()');
      debugPrint('   🎯 Service utilisé: AttributionServiceComplete (NOUVEAU)');
      debugPrint('   📊 Nombre de produits: ${produits.length}');
      debugPrint('   🏭 Type: ${serviceType.label}');
      debugPrint('   ✅ CONFIRMATION: Le bon service est appelé !');
      debugPrint('=========================================================');

      final success = await _attributionServiceComplete.attribuerProduits(
        produits: produits,
        type: serviceType,
        utilisateur: attributionData['utilisateur'] ?? 'Utilisateur',
        commentaires: attributionData['commentaires'],
        // siteReceveur et selectedContenants ne sont pas dans la méthode du service
      );

      _isLoading.value = false;

      if (success) {
        // 🚀 LOGS DE TRAÇAGE SUCCESS
        debugPrint('🎊 ===== ATTRIBUTION RÉUSSIE - NETTOYAGE INTERFACE =====');
        debugPrint('   ✅ Service d\'attribution terminé avec succès');
        debugPrint('   🧹 Nettoyage de la sélection...');
        debugPrint('   🔄 Rechargement des données...');
        debugPrint('   🚪 Fermeture du modal...');
        debugPrint('   📊 Notification utilisateur...');

        // Succès - Nettoyer la sélection
        _produitsSelectionnes.clear();
        _modeSelectionMultiple.value = false;

        // Recharger les données
        await _loadData();
        debugPrint('   ✅ Données rechargées');

        Get.snackbar(
          '✅ Attribution réussie',
          '${produits.length} produit(s) attribué(s) à ${type.label}',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          icon: const Icon(Icons.check_circle, color: Colors.green),
          duration: const Duration(seconds: 3),
        );

        // Fermer le modal avec vérification
        debugPrint('   🚪 Tentative de fermeture du modal...');
        if (Get.isDialogOpen ?? false) {
          Get.back(); // Fermer le dialog
          debugPrint('   ✅ Dialog fermé');
        } else if (Get.isBottomSheetOpen ?? false) {
          Get.back(); // Fermer le bottom sheet
          debugPrint('   ✅ Bottom sheet fermé');
        } else {
          Get.back(); // Fermer normalement
          debugPrint('   ✅ Modal fermé normalement');
        }

        // Double vérification avec délai
        Future.delayed(const Duration(milliseconds: 100), () {
          if (Get.isDialogOpen ?? false) {
            Get.back();
            debugPrint('   🔄 Fermeture supplémentaire du modal');
          }
        });

        debugPrint(
            '===========================================================');
      } else {
        Get.snackbar(
          '❌ Erreur d\'attribution',
          'Impossible d\'attribuer les produits',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          icon: const Icon(Icons.error, color: Colors.red),
        );
      }
    } catch (e) {
      _isLoading.value = false;
      Get.snackbar(
        '❌ Erreur',
        'Erreur lors de l\'attribution: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    }
  }

  /// 🎯 ATTRIBUTION INTELLIGENTE DIRECTE - PLUS DE DIALOGUE MOCHE !
  Future<void> _showSelectionAttributionDialog() async {
    if (_produitsSelectionnes.isEmpty) return;

    // 🧠 LOGIQUE INTELLIGENTE : Détecter automatiquement le meilleur type
    final typesSupportes =
        <models.AttributionType, List<models.ProductControle>>{};

    for (final type in models.AttributionType.values) {
      final serviceType = _convertToServiceType(type);
      final produitsCompatibles = _produitsSelectionnes
          .where((p) => _canBeAttributed(p, serviceType))
          .toList();

      if (produitsCompatibles.isNotEmpty) {
        typesSupportes[type] = produitsCompatibles;
      }
    }

    if (typesSupportes.isEmpty) {
      Get.snackbar(
        '⚠️ Aucun produit compatible',
        'Les produits sélectionnés ne peuvent pas être attribués',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        icon: const Icon(Icons.warning, color: Colors.orange),
      );
      return;
    }

    // 🎯 SI UN SEUL TYPE DISPONIBLE = ATTRIBUTION DIRECTE INTELLIGENTE !
    if (typesSupportes.length == 1) {
      final entry = typesSupportes.entries.first;
      await _showModernAttributionModal(entry.value, entry.key);
      return;
    }

    // 🎨 SÉLECTION MODERNE AVEC CARDS VISUELLES (pas de dialogue moche !)
    await _showTypeSelectionCards(typesSupportes);
  }

  /// 🎨 SÉLECTION VISUELLE MODERNE DES TYPES D'ATTRIBUTION
  Future<void> _showTypeSelectionCards(
      Map<models.AttributionType, List<models.ProductControle>>
          typesSupportes) async {
    await Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🎯 HEADER MODERNE
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade600, Colors.purple.shade500],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.auto_awesome,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🚀 Attribution Intelligente',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_produitsSelectionnes.length} produits • ${typesSupportes.length} types disponibles',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 🎴 CARDS VISUELLES POUR CHAQUE TYPE
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: typesSupportes.entries.map((entry) {
                      final type = entry.key;
                      final produits = entry.value;
                      final colors = _getTypeGradientColorsSelection(type);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () {
                            Get.back();
                            _showModernAttributionModal(produits, type);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: colors),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.first.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getTypeIconSelection(type),
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            _getTypeEmojiSelection(type),
                                            style:
                                                const TextStyle(fontSize: 20),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            type.label,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${produits.length} produit(s) compatible(s) • ${produits.fold(0.0, (sum, p) => sum + p.poidsTotal).toStringAsFixed(1)} kg',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // ❌ BOUTON ANNULER
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                  label: const Text('Annuler'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    side: BorderSide(color: Colors.grey.shade400),
                    foregroundColor: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Méthodes helper pour les couleurs du nouveau système de sélection
  List<Color> _getTypeGradientColorsSelection(models.AttributionType type) {
    switch (type) {
      case models.AttributionType.extraction:
        return [Colors.blue.shade600, Colors.blue.shade400];
      case models.AttributionType.filtration:
        return [Colors.purple.shade600, Colors.purple.shade400];
      case models.AttributionType.traitementCire:
        return [Colors.orange.shade600, Colors.orange.shade400];
    }
  }

  IconData _getTypeIconSelection(models.AttributionType type) {
    switch (type) {
      case models.AttributionType.extraction:
        return Icons.science;
      case models.AttributionType.filtration:
        return Icons.filter_alt;
      case models.AttributionType.traitementCire:
        return Icons.wb_sunny;
    }
  }

  String _getTypeEmojiSelection(models.AttributionType type) {
    switch (type) {
      case models.AttributionType.extraction:
        return '🧪';
      case models.AttributionType.filtration:
        return '🔍';
      case models.AttributionType.traitementCire:
        return '🌞';
    }
  }

  /// 📭 ÉTAT VIDE
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun produit disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tous les produits contrôlés ont été attribués\nou aucun produit ne correspond aux filtres.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 HISTORIQUE
  void _showHistorique() {
    Get.to(() => const AttributionHistoryPage());
  }

  /// 🔧 MODAL FILTRES
  void _showFiltersModal() {
    Get.bottomSheet(
      Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtres avancés',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[600],
              ),
            ),
            const SizedBox(height: 16),
            const Expanded(
              child: Center(
                child: Text('Filtres seront bientôt disponibles...'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🎨 MÉTHODES UTILITAIRES POUR L'INTERFACE

  /// Couleur selon le type de collecte
  Color _getCollecteTypeColor(String typeCollecte) {
    switch (typeCollecte.toLowerCase()) {
      case 'recolte':
        return Colors.brown;
      case 'scoop':
        return Colors.blue;
      case 'individuel':
        return Colors.green;
      case 'miellerie':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Icône selon le type de collecte
  IconData _getCollecteTypeIcon(String typeCollecte) {
    switch (typeCollecte.toLowerCase()) {
      case 'recolte':
        return Icons.agriculture;
      case 'scoop':
        return Icons.local_shipping;
      case 'individuel':
        return Icons.person;
      case 'miellerie':
        return Icons.factory;
      default:
        return Icons.inventory;
    }
  }

  /// Icône selon la nature du produit
  IconData _getNatureIcon(models.ProductNature nature) {
    switch (nature) {
      case models.ProductNature.brut:
        return Icons.science;
      case models.ProductNature.liquide:
        return Icons.water_drop;
      case models.ProductNature.cire:
        return Icons.spa;
      case models.ProductNature.filtre:
        return Icons.filter_alt;
    }
  }

  /// Formatage de date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Menu contextuel pour l'attribution
  List<PopupMenuEntry<AttributionType>> _buildAttributionMenuItems(
      models.ProductControle produit) {
    final items = <PopupMenuEntry<AttributionType>>[];

    // Extraction - seulement pour produits bruts
    if (produit.nature == models.ProductNature.brut) {
      items.add(
        PopupMenuItem<AttributionType>(
          value: AttributionType.extraction,
          child: Row(
            children: [
              Icon(Icons.science, color: Colors.brown[600], size: 18),
              const SizedBox(width: 8),
              const Text('Extraction'),
            ],
          ),
        ),
      );
    }

    // Filtrage - seulement pour produits liquides
    if (produit.nature == models.ProductNature.liquide) {
      items.add(
        PopupMenuItem<AttributionType>(
          value: AttributionType.filtrage,
          child: Row(
            children: [
              Icon(Icons.water_drop, color: Colors.blue[600], size: 18),
              const SizedBox(width: 8),
              const Text('Filtrage'),
            ],
          ),
        ),
      );
    }

    // Traitement Cire - seulement pour produits cire
    if (produit.nature == models.ProductNature.cire) {
      items.add(
        PopupMenuItem<AttributionType>(
          value: AttributionType.cire,
          child: Row(
            children: [
              Icon(Icons.spa, color: Colors.amber[700], size: 18),
              const SizedBox(width: 8),
              const Text('Production Cire'),
            ],
          ),
        ),
      );
    }

    return items;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

/// 🎯 NOUVEAU MODAL D'ATTRIBUTION MODERNE
class ModernAttributionModal extends StatefulWidget {
  final BaseCollecte collecte;
  final models.AttributionType type;
  final List<models.ProductControle> selectedProducts;
  final Function(Map<String, dynamic>) onConfirmed;

  const ModernAttributionModal({
    super.key,
    required this.collecte,
    required this.type,
    required this.selectedProducts,
    required this.onConfirmed,
  });

  @override
  State<ModernAttributionModal> createState() => _ModernAttributionModalState();
}

class _ModernAttributionModalState extends State<ModernAttributionModal>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _commentairesController = TextEditingController();

  // État du formulaire
  String _utilisateur = '';
  String _siteReceveur = '';
  List<String> _selectedContenants = [];
  List<String> _availableContenants = [];
  bool _isLoading = false;

  // Liste des sites disponibles selon le type d'attribution
  final List<String> _sitesExtraction = [
    'Koudougou',
    'Bobo-Dioulasso',
    'Ouagadougou',
    'Banfora',
  ];

  final List<String> _sitesFiltrage = [
    'Koudougou',
    'Bobo-Dioulasso',
    'Ouagadougou',
  ];

  // Animation
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _loadContenants();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  void _loadContenants() {
    // Charger les contenants depuis les produits sélectionnés
    _availableContenants =
        widget.selectedProducts.map((p) => p.codeContenant).toList();
    _selectedContenants =
        List.from(_availableContenants); // Tous sélectionnés par défaut
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentairesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? screenSize.width * 0.95 : 600,
                  maxHeight: screenSize.height * 0.9,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModernHeader(),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCollecteInfo(),
                              const SizedBox(height: 20),
                              _buildUtilisateurField(),
                              const SizedBox(height: 16),
                              _buildSiteReceveurField(),
                              const SizedBox(height: 16),
                              _buildContainantsSelection(),
                              const SizedBox(height: 16),
                              _buildCommentairesField(),
                              const SizedBox(height: 20),
                              _buildSummarySection(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Copie des méthodes build du modal de controle_attribution_modal.dart
  Widget _buildModernHeader() {
    final colors = _getTypeGradientColors();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getTypeIcon(),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getTypeEmoji(),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.type.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.selectedProducts.length} produits • ${_getTotalWeight().toStringAsFixed(1)} kg',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Fermer',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollecteInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getTypeColor().withOpacity(0.05),
            _getTypeColor().withOpacity(0.02),
          ],
        ),
        border: Border.all(color: _getTypeColor().withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _getTypeColor().withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: _getTypeColor(), size: 20),
              const SizedBox(width: 8),
              Text(
                'Informations de sélection',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getTypeColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Poids total',
                  '${_getTotalWeight().toStringAsFixed(1)} kg',
                  Icons.scale,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Contenants',
                  '${widget.selectedProducts.length}',
                  Icons.inventory,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle,
                    color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Sélection prête pour attribution',
                    style: TextStyle(
                      color: Colors.green,
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

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: _getTypeColor(), size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getTypeColor(),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilisateurField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: '👤 Utilisateur responsable',
        hintText: 'Nom de l\'utilisateur',
        prefixIcon: const Icon(Icons.person),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez saisir le nom de l\'utilisateur';
        }
        return null;
      },
      onSaved: (value) => _utilisateur = value ?? '',
    );
  }

  Widget _buildSiteReceveurField() {
    final sites = widget.type == models.AttributionType.extraction
        ? _sitesExtraction
        : _sitesFiltrage;

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: '🏭 Site receveur',
        hintText: 'Sélectionnez le site de destination',
        prefixIcon: const Icon(Icons.location_city),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: sites
          .map((site) => DropdownMenuItem(
                value: site,
                child: Text(site),
              ))
          .toList(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez sélectionner un site receveur';
        }
        return null;
      },
      onChanged: (value) {
        setState(() {
          _siteReceveur = value ?? '';
        });
      },
    );
  }

  Widget _buildContainantsSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📦 Contenants à attribuer',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _getTypeColor(),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade50,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedContenants.length}/${_availableContenants.length} sélectionnés',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedContenants =
                                List.from(_availableContenants);
                          });
                        },
                        child: const Text('Tout'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedContenants.clear();
                          });
                        },
                        child: const Text('Aucun'),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    children: _availableContenants.map((contenant) {
                      final isSelected =
                          _selectedContenants.contains(contenant);
                      return CheckboxListTile(
                        dense: true,
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedContenants.add(contenant);
                            } else {
                              _selectedContenants.remove(contenant);
                            }
                          });
                        },
                        title: Text(
                          contenant,
                          style: const TextStyle(fontSize: 13),
                        ),
                        activeColor: _getTypeColor(),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentairesField() {
    return TextFormField(
      controller: _commentairesController,
      decoration: InputDecoration(
        labelText: '💬 Commentaires (optionnel)',
        hintText: 'Ajoutez des commentaires ou instructions...',
        prefixIcon: const Icon(Icons.comment),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      maxLines: 3,
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getTypeColor().withOpacity(0.05),
            _getTypeColor().withOpacity(0.02),
          ],
        ),
        border: Border.all(color: _getTypeColor().withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _getTypeColor().withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize, color: _getTypeColor(), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Résumé de l\'attribution',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getTypeColor(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Type d\'attribution',
                  widget.type.label,
                  _getTypeIcon(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Contenants',
                  '${_selectedContenants.length}',
                  Icons.inventory,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_siteReceveur.isNotEmpty || _utilisateur.isNotEmpty) ...[
            if (_siteReceveur.isNotEmpty)
              _buildModernSummaryRow(
                  'Site receveur', _siteReceveur, Icons.location_city),
            if (_utilisateur.isNotEmpty)
              _buildModernSummaryRow('Utilisateur', _utilisateur, Icons.person),
            _buildModernSummaryRow(
              'Date d\'attribution',
              _formatDate(DateTime.now()),
              Icons.calendar_today,
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle,
                    color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Prêt pour l\'attribution !',
                    style: TextStyle(
                      color: Colors.green,
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

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: _getTypeColor(), size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _getTypeColor(),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernSummaryRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _getTypeColor()),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
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

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade50,
            Colors.grey.shade100,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.cancel),
              label: const Text('Annuler'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.grey.shade400),
                foregroundColor: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getTypeGradientColors(),
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: _getTypeColor().withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _confirmer,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(_getTypeIcon()),
                label: Text(_isLoading ? 'Attribution...' : 'Confirmer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmer() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedContenants.isEmpty) {
      Get.snackbar(
        'Attention',
        'Veuillez sélectionner au moins un contenant',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        icon: const Icon(Icons.warning, color: Colors.orange),
      );
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    // Délai pour l'animation
    await Future.delayed(const Duration(milliseconds: 500));

    // Appeler le callback avec les données
    widget.onConfirmed({
      'utilisateur': _utilisateur,
      'siteReceveur': _siteReceveur,
      'selectedContenants': _selectedContenants,
      'commentaires': _commentairesController.text,
    });

    setState(() {
      _isLoading = false;
    });
  }

  // Méthodes d'assistance pour les couleurs et icônes
  List<Color> _getTypeGradientColors() {
    switch (widget.type) {
      case models.AttributionType.extraction:
        return [Colors.blue.shade600, Colors.blue.shade400];
      case models.AttributionType.filtration:
        return [Colors.purple.shade600, Colors.purple.shade400];
      case models.AttributionType.traitementCire:
        return [Colors.orange.shade600, Colors.orange.shade400];
    }
  }

  Color _getTypeColor() {
    switch (widget.type) {
      case models.AttributionType.extraction:
        return Colors.blue.shade600;
      case models.AttributionType.filtration:
        return Colors.purple.shade600;
      case models.AttributionType.traitementCire:
        return Colors.orange.shade600;
    }
  }

  IconData _getTypeIcon() {
    switch (widget.type) {
      case models.AttributionType.extraction:
        return Icons.science;
      case models.AttributionType.filtration:
        return Icons.filter_alt;
      case models.AttributionType.traitementCire:
        return Icons.wb_sunny;
    }
  }

  String _getTypeEmoji() {
    switch (widget.type) {
      case models.AttributionType.extraction:
        return '🧪';
      case models.AttributionType.filtration:
        return '🔍';
      case models.AttributionType.traitementCire:
        return '🌞';
    }
  }

  double _getTotalWeight() {
    return widget.selectedProducts.fold(0.0, (sum, p) => sum + p.poidsTotal);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
