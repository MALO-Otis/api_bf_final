import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../widgets/filtrage_form_modal.dart';
import '../../../authentication/user_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/filtrage_attribution_service.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';

/// Page principale pour les produits attribués au filtrage (inspirée du module extraction)

class FiltrageProductsPage extends StatefulWidget {
  const FiltrageProductsPage({super.key});

  @override
  State<FiltrageProductsPage> createState() => _FiltrageProductsPageState();
}

class _FiltrageProductsPageState extends State<FiltrageProductsPage>
    with TickerProviderStateMixin {
  final FiltrageAttributionService _service = FiltrageAttributionService();

  // État de l'application - NOUVEAU SYSTÈME (comme extraction)
  List<ProductControle> _allProducts = [];
  List<ProductControle> _filteredProducts = [];
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _statsControle;
  bool _isLoading = true;
  String _sortBy =
      'dateReception'; // 'dateReception', 'poids', 'provenance', 'nature'
  bool _sortAscending = false;
  String _searchQuery = '';

  // Contrôleurs d'animation
  late AnimationController _headerGlowController;
  late AnimationController _refreshController;
  late AnimationController _scrollButtonController;

  // Contrôleurs de texte et scroll
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Timer pour l'horloge temps réel
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

  // Options de groupe
  String _groupBy =
      'provenance'; // 'provenance', 'nature', 'attributeur', 'statut'

  // ✅ NOUVEAU: Sélection pour filtrage
  final Set<String> _selectedProductIds = {};
  bool get _hasSelection => _selectedProductIds.isNotEmpty;

  // État du scroll pour les boutons de navigation
  bool _showScrollButtons = false;
  bool _isNearTop = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
    _startClock();
  }

  @override
  void dispose() {
    _headerGlowController.dispose();
    _refreshController.dispose();
    _scrollButtonController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _clockTimer?.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    _headerGlowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scrollButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return;

    final offset = _scrollController.offset;
    final shouldShow = offset > 150;
    final nearTop = offset < 250;

    if (shouldShow != _showScrollButtons || nearTop != _isNearTop) {
      setState(() {
        _showScrollButtons = shouldShow;
        _isNearTop = nearTop;
      });

      if (shouldShow) {
        _scrollButtonController.forward();
      } else {
        _scrollButtonController.reverse();
      }
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      } else {
        timer.cancel();
      }
    });
  }

  /// Charge les données depuis le service (inspiré du module extraction)
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('🔄 [Filtrage] Chargement des produits pour filtrage...');

      final userSession = Get.find<UserSession>();
      final isAdmin =
          userSession.role == 'admin' || userSession.role == 'coordinateur';
      final userSite = userSession.site;

      // ✅ SPÉCIFIQUE FILTRAGE: Récupérer produits liquides attribués + extraits du même site
      final products = await _service.getProduitsFilterage(
          searchQuery: null); // Pas de filtre de recherche pour l'instant
      final stats = await _service.getStatistiquesFiltrage();

      // Récupérer les statistiques de contrôle par site pour le filtrage
      final statsControle = await _service.getStatistiquesControleParSite(
        siteSpecifique: isAdmin ? null : userSite,
      );

      debugPrint(
          '✅ [Filtrage] ${products.length} produits chargés pour filtrage');
      debugPrint('   - Produits liquides attribués depuis le contrôle');
      debugPrint('   - Produits extraits (miel liquide) du même site');

      // Debug: afficher les premiers produits
      if (products.isNotEmpty) {
        debugPrint('📋 Premiers produits récupérés:');
        for (int i = 0; i < (products.length > 3 ? 3 : products.length); i++) {
          final p = products[i];
          debugPrint(
              '   ${i + 1}. ${p.codeContenant} - ${p.nature.label} - ${p.village}');
        }
      } else {
        debugPrint('⚠️ Aucun produit récupéré - vérifier les données sources');
        debugPrint(
            '💡 Tentative de récupération avec une approche alternative...');

        // Essayer de récupérer directement depuis le contrôle pour test
        try {
          final testProducts = await _getTestProducts();
          if (testProducts.isNotEmpty) {
            debugPrint('✅ ${testProducts.length} produits de test récupérés');
            products.addAll(testProducts);
          }
        } catch (e) {
          debugPrint('❌ Erreur récupération produits de test: $e');
        }
      }

      if (mounted) {
        setState(() {
          _allProducts = products;
          // Simplification: application directe des filtres de recherche locaux
          _filteredProducts = _applyLocalFilters(products);
          _stats = stats;
          _statsControle = statsControle;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [Filtrage] Erreur chargement: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement des produits de filtrage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Méthode de test pour récupérer des produits directement depuis le contrôle
  Future<List<ProductControle>> _getTestProducts() async {
    try {
      debugPrint(
          '🧪 [Test] Récupération directe depuis la collection Controle...');
      final firestore = FirebaseFirestore.instance;
      final List<ProductControle> testProducts = [];

      // Récupérer directement depuis la collection Controle
      final controleSnapshot = await firestore
          .collection('Controle')
          .where('nature', whereIn: ['MIEL_LIQUIDE', 'MIEL_SOLIDE'])
          .limit(20)
          .get();

      debugPrint(
          '   📊 ${controleSnapshot.docs.length} documents trouvés dans Controle');

      for (final doc in controleSnapshot.docs) {
        try {
          final data = doc.data();

          // Créer un ProductControle depuis les données de contrôle
          final product = ProductControle(
            id: doc.id,
            codeContenant: data['codeContenant'] ?? doc.id,
            dateReception: (data['dateReception'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            producteur: data['producteur'] ?? 'Producteur inconnu',
            village: data['village'] ?? 'Village inconnu',
            commune: data['commune'] ?? '',
            quartier: data['quartier'] ?? '',
            nature: ProductNature.values.firstWhere(
              (nature) => nature.name == (data['nature'] ?? 'liquide'),
              orElse: () => ProductNature.liquide,
            ),
            typeContenant: data['typeContenant'] ?? 'BIDON',
            numeroContenant: data['numeroContenant'] ?? '',
            poidsTotal: (data['poids'] ?? data['poidsTotal'] ?? 0).toDouble(),
            poidsMiel:
                (data['poidsMiel'] ?? data['poidsTotal'] ?? 0).toDouble(),
            qualite: data['qualite'] ?? 'BONNE',
            teneurEau: (data['teneurEau'] ?? 0).toDouble(),
            predominanceFlorale: data['predominanceFlorale'] ?? 'Mille fleurs',
            estConforme: data['estConforme'] ?? true,
            causeNonConformite: data['causeNonConformite'],
            observations: data['observations'],
            dateControle: (data['dateControle'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            controleur: data['technicienControle'] ?? '',
            estAttribue: true,
            siteOrigine: data['site'] ?? 'Koudougou',
            collecteId: data['collecteId'] ?? '',
            typeCollecte: data['typeCollecte'] ?? 'STANDARD',
            dateCollecte: (data['dateCollecte'] as Timestamp?)?.toDate() ??
                DateTime.now(),
          );

          testProducts.add(product);
          debugPrint('   ✅ Produit test ajouté: ${product.codeContenant}');
        } catch (e) {
          debugPrint('   ❌ Erreur parsing produit test ${doc.id}: $e');
        }
      }

      return testProducts;
    } catch (e) {
      debugPrint('❌ [Test] Erreur récupération produits test: $e');
      return [];
    }
  }

  /// Applique les filtres locaux (recherche, tri) sans recharger depuis le serveur
  List<ProductControle> _applyLocalFilters(List<ProductControle> products) {
    debugPrint(
        '🔍 [Filtrage] Application des filtres locaux sur ${products.length} produits');

    // 1. Appliquer la recherche locale
    List<ProductControle> filtered = products;
    if (_searchQuery.isNotEmpty) {
      filtered = products.where((product) {
        final query = _searchQuery.toLowerCase();
        return product.codeContenant.toLowerCase().contains(query) ||
            product.village.toLowerCase().contains(query) ||
            product.producteur.toLowerCase().contains(query) ||
            product.nature.label.toLowerCase().contains(query);
      }).toList();
      debugPrint(
          '   📝 Après recherche "${_searchQuery}": ${filtered.length} produits');
    }

    // 2. Appliquer le tri
    filtered.sort((a, b) {
      int result;
      switch (_sortBy) {
        case 'dateReception':
          result = a.dateReception.compareTo(b.dateReception);
          break;
        case 'poids':
          result = a.poidsTotal.compareTo(b.poidsTotal);
          break;
        case 'provenance':
          result = a.village.compareTo(b.village);
          break;
        case 'nature':
          result = a.nature.name.compareTo(b.nature.name);
          break;
        default:
          result = a.dateReception.compareTo(b.dateReception);
      }
      return _sortAscending ? result : -result;
    });

    debugPrint(
        '   🔄 Après tri par $_sortBy (${_sortAscending ? "croissant" : "décroissant"}): ${filtered.length} produits');
    return filtered;
  }

  void _applySearch(String query) {
    setState(() {
      _searchQuery = query;
      // Application immédiate des filtres locaux sans recharger les données
      _filteredProducts = _applyLocalFilters(_allProducts);
    });
  }

  void _changeSorting(String newSortBy) {
    setState(() {
      if (_sortBy == newSortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = newSortBy;
        _sortAscending = false;
      }
      // Application immédiate des filtres locaux
      _filteredProducts = _applyLocalFilters(_allProducts);
    });
  }

  void _changeGrouping(String newGroupBy) {
    setState(() {
      _groupBy = newGroupBy;
    });
  }

  Future<void> _refresh() async {
    _refreshController.forward();
    await _loadData();
    _refreshController.reset();
  }

  /// Groupe les produits selon les critères spécifiques au filtrage
  Map<String, List<ProductControle>> _groupProducts() {
    final Map<String, List<ProductControle>> grouped = {};

    for (final product in _filteredProducts) {
      String groupKey;
      switch (_groupBy) {
        case 'provenance':
          groupKey = '📍 ${product.village} (${product.siteOrigine})';
          break;
        case 'nature':
          groupKey =
              '${_getNatureIcon(product.nature)} ${product.nature.label}';
          break;
        case 'attributeur':
          groupKey = '👤 ${product.controleur ?? 'Contrôleur inconnu'}';
          break;
        case 'statut':
          groupKey = product.estConforme
              ? '✅ Conforme pour filtrage'
              : '⚠️ Non conforme';
          break;
        default:
          groupKey = 'Tous';
      }

      grouped.putIfAbsent(groupKey, () => []);
      grouped[groupKey]!.add(product);
    }

    return grouped;
  }

  String _getNatureIcon(ProductNature nature) {
    switch (nature) {
      case ProductNature.brut:
        return '🍯';
      case ProductNature.liquide:
        return '💧';
      case ProductNature.cire:
        return '🟨';
      case ProductNature.filtre:
        return '🔍';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  controller: _scrollController,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      children: [
                        // En-tête scrollable
                        _buildHeader(theme, isMobile),

                        // Statistiques
                        if (_stats != null)
                          Padding(
                            padding: EdgeInsets.all(isMobile ? 8 : 16),
                            child: _buildStatsWidget(theme, isMobile),
                          ),

                        // Bande d'informations de contrôle par site
                        if (_statsControle != null)
                          _buildBandeControleInfo(theme, isMobile),

                        // Barre de recherche et filtres
                        _buildSearchAndFilters(theme, isMobile),

                        // Liste des produits
                        _buildProductsList(theme, isMobile),

                        // Espacement final
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Boutons de navigation
          if (_showScrollButtons) ...[
            ScaleTransition(
              scale: _scrollButtonController,
              child: FloatingActionButton(
                heroTag: 'fab-scroll-navigation-filtrage',
                mini: true,
                onPressed: _isNearTop ? _scrollToBottom : _scrollToTop,
                backgroundColor:
                    theme.colorScheme.secondary.withValues(alpha: 0.9),
                child: Icon(
                  _isNearTop
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_up,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Bouton principal
          _hasSelection
              ? FloatingActionButton.extended(
                  heroTag: 'fab-filtrage',
                  onPressed: _lancerFiltrage,
                  backgroundColor: Colors.purple.shade600,
                  icon: const Icon(Icons.filter_alt, color: Colors.white),
                  label: Text(
                    'Filtrer (${_selectedProductIds.length})',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )
              : FloatingActionButton(
                  heroTag: 'fab-refresh-filtrage',
                  onPressed: _refresh,
                  backgroundColor: theme.colorScheme.primary,
                  child: RotationTransition(
                    turns: _refreshController,
                    child: const Icon(Icons.refresh, color: Colors.white),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade600, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.shade600.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!isMobile) ...[
                    Icon(
                      Icons.filter_alt,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filtrage - Produits Attribués',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!isMobile)
                          Text(
                            'Produits liquides contrôlés + Miel extrait à filtrer',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Horloge temps réel
                  AnimatedBuilder(
                    animation: _headerGlowController,
                    builder: (context, child) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: 0.3 + _headerGlowController.value * 0.4,
                          ),
                        ),
                      ),
                      child: Text(
                        '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsWidget(ThemeData theme, bool isMobile) {
    if (_stats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade50,
            Colors.blue.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_alt, color: Colors.purple.shade600, size: 24),
              const SizedBox(width: 8),
              Text(
                'Statistiques Filtrage',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  theme,
                  '${_stats!['totalProduits']}',
                  'Produits Total',
                  Icons.inventory_2,
                  Colors.purple.shade600,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  theme,
                  '${_stats!['attribues'] ?? 0}',
                  'Attribués',
                  Icons.assignment,
                  Colors.blue.shade600,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  theme,
                  '${_stats!['extraits'] ?? 0}',
                  'Miel Extrait',
                  Icons.science,
                  Colors.green.shade600,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  theme,
                  '${(_stats!['poidsTotal'] as double).toStringAsFixed(1)} kg',
                  'Poids Total',
                  Icons.scale,
                  Colors.orange.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      ThemeData theme, String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBandeControleInfo(ThemeData theme, bool isMobile) {
    if (_statsControle == null) return const SizedBox.shrink();

    final userSession = Get.find<UserSession>();
    final isAdmin =
        userSession.role == 'admin' || userSession.role == 'coordinateur';
    final sites = _statsControle!['sites'] as Map<String, dynamic>;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.pink.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_alt, color: Colors.purple.shade600, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAdmin
                      ? 'Produits pour FILTRAGE par Site'
                      : 'Produits pour FILTRAGE - ${userSession.site}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'LIVE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isAdmin) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sites.entries.map((entry) {
                final site = entry.key;
                final stats = entry.value as Map<String, dynamic>;
                return _buildSiteControlCard(theme, site, stats, isMobile);
              }).toList(),
            ),
          ] else ...[
            if (sites.containsKey(userSession.site))
              _buildSiteControlCard(
                  theme, userSession.site!, sites[userSession.site!], isMobile,
                  isExpanded: true),
          ],
        ],
      ),
    );
  }

  Widget _buildSiteControlCard(
      ThemeData theme, String site, Map<String, dynamic> stats, bool isMobile,
      {bool isExpanded = false}) {
    final total = stats['totalControles'] ?? 0;
    // Variables utilisées pour la logique mais pas affichées directement
    // final filtres = stats['filtres'] ?? 0;
    // final enAttente = stats['enAttente'] ?? 0;

    return Container(
      width: isExpanded ? double.infinity : (isMobile ? 140 : 160),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_city,
                  color: Colors.purple.shade600, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  site,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$total',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade600,
            ),
          ),
          Text(
            'Pour Filtrage',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(ThemeData theme, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          // Barre de recherche
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par code, producteur, village...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                  onChanged: _applySearch,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _refresh(),
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualiser',
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Options de tri et groupement
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  isExpanded: true,
                  decoration: InputDecoration(
                    label: const Text(
                      'Trier par',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'dateReception',
                      child: Text(
                        'Date de réception',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'poids',
                      child: Text('Poids total'),
                    ),
                    DropdownMenuItem(
                      value: 'provenance',
                      child: Text('Provenance'),
                    ),
                    DropdownMenuItem(
                      value: 'nature',
                      child: Text(
                        'Nature du produit',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (value) => _changeSorting(value!),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _changeSorting(_sortBy),
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                tooltip: _sortAscending ? 'Croissant' : 'Décroissant',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _groupBy,
                  isExpanded: true,
                  decoration: InputDecoration(
                    label: const Text(
                      'Grouper par',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'provenance',
                      child: Text('Provenance'),
                    ),
                    DropdownMenuItem(
                      value: 'nature',
                      child: Text('Nature'),
                    ),
                    DropdownMenuItem(
                      value: 'attributeur',
                      child: Text('Contrôleur'),
                    ),
                    DropdownMenuItem(
                      value: 'statut',
                      child: Text('Statut'),
                    ),
                  ],
                  onChanged: (value) => _changeGrouping(value!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(ThemeData theme, bool isMobile) {
    if (_filteredProducts.isEmpty) {
      return Container(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.filter_alt_off,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun produit pour filtrage',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Aucun produit ne correspond à la recherche "${_searchQuery}"'
                    : 'Les produits liquides contrôlés et le miel extrait\ndu même site apparaîtront ici une fois attribués',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Debug: ${_allProducts.length} produits totaux disponibles',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final groupedProducts = _groupProducts();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: groupedProducts.entries.map((entry) {
          final groupKey = entry.key;
          final products = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête du groupe
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(
                      groupKey,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${products.length}',
                        style: TextStyle(
                          color: Colors.purple.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Divider(
                        color: Colors.purple.shade300,
                      ),
                    ),
                  ],
                ),
              ),

              // Produits du groupe
              ...products.map((product) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildProductCard(theme, product),
                  )),

              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductCard(ThemeData theme, ProductControle product) {
    final isSelected = _selectedProductIds.contains(product.id);
    final isFromExtraction =
        !product.estAttribue; // Produit venant d'extraction (miel liquide)

    return Card(
      elevation: 2,
      color: isSelected
          ? Colors.purple.shade50
          : (isFromExtraction ? Colors.green.shade50 : null),
      child: InkWell(
        onTap: () => _toggleProductSelection(product.id),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec checkbox et badges
              Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleProductSelection(product.id),
                    activeColor: Colors.purple.shade600,
                  ),
                  const SizedBox(width: 8),

                  // Badge source
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isFromExtraction
                          ? Colors.green.shade100
                          : Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isFromExtraction
                          ? '🍯 MIEL EXTRAIT'
                          : '📋 LIQUIDE CONTRÔLÉ',
                      style: TextStyle(
                        color: isFromExtraction
                            ? Colors.green.shade700
                            : Colors.purple.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Badge nature
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getNatureColor(product.nature)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_getNatureIcon(product.nature)} ${product.nature.label}',
                      style: TextStyle(
                        color: _getNatureColor(product.nature),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const Spacer(),
                  Flexible(
                    child: Tooltip(
                      message: product.codeContenant,
                      child: Text(
                        product.codeContenant,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Informations principales
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.producteur,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 16, color: theme.colorScheme.outline),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${product.village} (${product.siteOrigine})',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (isFromExtraction) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Source: Extraction ${product.siteOrigine}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${product.poidsTotal.toStringAsFixed(1)} kg',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isFromExtraction
                              ? Colors.green.shade600
                              : Colors.purple.shade600,
                        ),
                      ),
                      Text(
                        isFromExtraction
                            ? 'Miel liquide extrait'
                            : 'Miel: ${product.poidsMiel.toStringAsFixed(1)} kg',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Actions et statut
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: product.estConforme
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      product.estConforme ? '✅ Conforme' : '⚠️ Non conforme',
                      style: TextStyle(
                        color:
                            product.estConforme ? Colors.green : Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Qualité: ${product.qualite}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNatureColor(ProductNature nature) {
    switch (nature) {
      case ProductNature.brut:
        return Colors.amber;
      case ProductNature.liquide:
        return Colors.blue;
      case ProductNature.cire:
        return Colors.yellow;
      case ProductNature.filtre:
        return Colors.purple;
    }
  }

  void _toggleProductSelection(String productId) {
    setState(() {
      if (_selectedProductIds.contains(productId)) {
        _selectedProductIds.remove(productId);
      } else {
        _selectedProductIds.add(productId);
      }
    });
  }

  /// Lance le processus de filtrage pour les produits sélectionnés
  void _lancerFiltrage() {
    if (_selectedProductIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Veuillez sélectionner au moins un produit pour le filtrage.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final produitsSelectionnes = _filteredProducts
        .where((p) => _selectedProductIds.contains(p.id))
        .toList();

    debugPrint(
        '🔄 [Filtrage] Lancement du filtrage pour ${produitsSelectionnes.length} produits');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FiltrageFormModal(
        produitsSelectionnes: produitsSelectionnes,
        onFiltrageComplete: () {
          setState(() {
            _selectedProductIds.clear();
          });
          _refresh();
        },
      ),
    );
  }
}
