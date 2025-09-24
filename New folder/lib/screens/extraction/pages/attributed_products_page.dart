import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../widgets/extraction_form_modal.dart';
import '../../../authentication/user_session.dart';
import '../services/extraction_attribution_service.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';

/// Page principale pour les produits attribués à l'extraction

// ANCIEN SYSTÈME COMMENTÉ - Utilise maintenant attribution_reçu
// import '../models/attributed_product_models.dart';
// import '../services/attributed_products_service.dart';
// import '../widgets/attributed_product_card.dart';
// import '../widgets/attributed_product_filters_widget.dart';
// import '../widgets/attributed_product_stats_widget.dart';
// import '../widgets/prelevement_modal.dart';

// NOUVEAU SYSTÈME - Utilise attribution_reçu

class AttributedProductsPage extends StatefulWidget {
  const AttributedProductsPage({super.key});

  @override
  State<AttributedProductsPage> createState() => _AttributedProductsPageState();
}

class _AttributedProductsPageState extends State<AttributedProductsPage>
    with TickerProviderStateMixin {
  final ExtractionAttributionService _service = ExtractionAttributionService();

  // État de l'application - NOUVEAU SYSTÈME
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

  // ✅ NOUVEAU: Sélection pour extraction
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

  /// Initialise les animations
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

    // Écouter le scroll pour les boutons de navigation
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted)
      return; // ✅ CORRECTION: Vérifier si le widget est encore monté

    final offset = _scrollController.offset;

    // Afficher les boutons après 150px de scroll
    final shouldShow = offset > 150;
    // Détecter si on est près du haut (dans les premiers 250px)
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

  /// Démarre l'horloge temps réel
  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      } else {
        // ✅ CORRECTION: Annuler le timer si le widget est détruit
        timer.cancel();
      }
    });
  }

  /// Charge les données depuis attribution_reçu
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('🔄 [Extraction] Chargement des produits d\'extraction...');

      // Récupérer les produits et statistiques depuis attribution_reçu
      final userSession = Get.find<UserSession>();
      final isAdmin =
          userSession.role == 'admin' || userSession.role == 'coordinateur';
      final userSite = userSession.site;

      final products =
          await _service.getProduitsExtraction(searchQuery: _searchQuery);
      final stats = await _service.getStatistiquesExtraction();

      // ✅ NOUVEAU: Récupérer les statistiques de contrôle par site
      final statsControle = await _service.getStatistiquesControleParSite(
        siteSpecifique: isAdmin ? null : userSite,
      );

      debugPrint('✅ [Extraction] ${products.length} produits chargés');

      if (mounted) {
        setState(() {
          _allProducts = products;
          _filteredProducts = _applySortAndGroup(products);
          _stats = stats;
          _statsControle = statsControle;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [Extraction] Erreur chargement: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Erreur de chargement des produits d\'extraction: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Applique le tri et le groupement - NOUVEAU SYSTÈME
  List<ProductControle> _applySortAndGroup(List<ProductControle> products) {
    // Tri avec nouveaux champs ProductControle
    products.sort((a, b) {
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

    return products;
  }

  /// Applique la recherche - NOUVEAU SYSTÈME SIMPLIFIÉ
  void _applySearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadData(); // Recharger avec nouveau critère de recherche
  }

  /// Change le tri
  void _changeSorting(String newSortBy) {
    setState(() {
      if (_sortBy == newSortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = newSortBy;
        _sortAscending = false;
      }
      _filteredProducts = _applySortAndGroup(_allProducts);
    });
  }

  /// Change le groupement
  void _changeGrouping(String newGroupBy) {
    setState(() {
      _groupBy = newGroupBy;
    });
  }

  /// Rafraîchit les données - NOUVEAU SYSTÈME
  Future<void> _refresh() async {
    _refreshController.forward();
    await _loadData();
    _refreshController.reset();
  }

  /// Affiche les détails du produit - NOUVEAU SYSTÈME
  void _showProductDetails(ProductControle product) {
    showDialog(
      context: context,
      builder: (context) => _ProductDetailsDialog(product: product),
    );
  }

  /// Affiche une modal simplifiée pour le prélèvement
  void _showPrelevementModal(ProductControle product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Prélèvement - ${product.codeContenant}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Producteur: ${product.producteur}'),
            Text('Village: ${product.village}'),
            Text('Poids total: ${product.poidsTotal.toStringAsFixed(2)} kg'),
            Text('Poids miel: ${product.poidsMiel.toStringAsFixed(2)} kg'),
            const SizedBox(height: 16),
            const Text('Fonctionnalité de prélèvement en développement...'),
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

  /// Groupe les produits selon le critère sélectionné - NOUVEAU SYSTÈME
  Map<String, List<ProductControle>> _groupProducts() {
    final Map<String, List<ProductControle>> grouped = {};

    for (final product in _filteredProducts) {
      String groupKey;
      switch (_groupBy) {
        case 'provenance':
          groupKey = '${product.village} (${product.siteOrigine})';
          break;
        case 'nature':
          groupKey = product.nature.label;
          break;
        case 'attributeur':
          groupKey = 'Attribution'; // Groupement par attribution
          break;
        case 'statut':
          groupKey = product.estAttribue ? 'Attribué' : 'Disponible';
          break;
        default:
          groupKey = 'Tous';
      }

      grouped.putIfAbsent(groupKey, () => []);
      grouped[groupKey]!.add(product);
    }

    return grouped;
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
                        // ✅ En-tête maintenant scrollable
                        _buildHeader(theme, isMobile),

                        // Statistiques - NOUVEAU SYSTÈME SIMPLIFIÉ
                        if (_stats != null)
                          Padding(
                            padding: EdgeInsets.all(isMobile ? 8 : 16),
                            child: _buildStatsWidget(theme, isMobile),
                          ),

                        // ✅ NOUVEAU: Bande d'informations de contrôle par site
                        if (_statsControle != null)
                          _buildBandeControleInfo(theme, isMobile),

                        // Barre de recherche et filtres
                        _buildSearchAndFilters(theme, isMobile),

                        // Liste des produits
                        _buildProductsList(theme, isMobile),

                        // Espacement final pour éviter que le FAB cache le contenu
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
          // Boutons de navigation (haut/bas) - apparaissent lors du scroll
          if (_showScrollButtons) ...[
            ScaleTransition(
              scale: _scrollButtonController,
              child: FloatingActionButton(
                heroTag: 'fab-scroll-navigation-products',
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

          // Bouton principal (extraction ou refresh)
          _hasSelection
              ? FloatingActionButton.extended(
                  heroTag: 'fab-extraction',
                  onPressed: _lancerExtraction,
                  backgroundColor: Colors.blue.shade600,
                  icon: const Icon(Icons.science, color: Colors.white),
                  label: Text(
                    'Extraire (${_selectedProductIds.length})',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )
              : FloatingActionButton(
                  heroTag: 'fab-refresh-attributed-products',
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

  /// Construit l'en-tête
  Widget _buildHeader(ThemeData theme, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
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
                      Icons.science,
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
                          'Extraction - Produits Attribués',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!isMobile)
                          Text(
                            'Gestion des prélèvements et extractions',
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

  /// ✅ NOUVEAU: Construit la bande d'informations de contrôle par site
  Widget _buildBandeControleInfo(ThemeData theme, bool isMobile) {
    if (_statsControle == null) return const SizedBox.shrink();

    final userSession = Get.find<UserSession>();
    final isAdmin =
        userSession.role == 'admin' || userSession.role == 'coordinateur';
    final sites = _statsControle!['sites'] as Map<String, dynamic>;
    final global = _statsControle!['global'] as Map<String, dynamic>;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Icon(Icons.verified_user, color: Colors.teal.shade600, size: 24),
              const SizedBox(width: 8),
              Text(
                isAdmin
                    ? 'Contrôles par Site'
                    : 'Contrôles - ${userSession.site}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.shade600,
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
            // Vue Admin: Tous les sites
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sites.entries.map((entry) {
                final site = entry.key;
                final stats = entry.value as Map<String, dynamic>;
                return _buildSiteControlCard(theme, site, stats, isMobile);
              }).toList(),
            ),

            const SizedBox(height: 12),

            // Résumé global
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildGlobalStat('Total', '${global['totalControles']}',
                      Icons.inventory_2),
                  _buildGlobalStat(
                      'Extraits', '${global['extraits']}', Icons.check_circle),
                  _buildGlobalStat('En attente', '${global['enAttente']}',
                      Icons.hourglass_empty),
                ],
              ),
            ),
          ] else ...[
            // Vue Extracteur: Site spécifique
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
    final extraits = stats['extraits'] ?? 0;
    final enAttente = stats['enAttente'] ?? 0;
    final pourcentageExtrait = total > 0 ? (extraits / total * 100) : 0.0;

    return Container(
      width: isExpanded ? double.infinity : (isMobile ? 140 : 160),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_city, color: Colors.teal.shade600, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  site,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade600,
                      ),
                    ),
                    Text(
                      'Pour Extraction',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isExpanded) ...[
                Column(
                  children: [
                    Text(
                      '$extraits',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade600,
                      ),
                    ),
                    Text(
                      'Extraits',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    Text(
                      '$enAttente',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade600,
                      ),
                    ),
                    Text(
                      'En attente',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          if (!isExpanded) ...[
            const SizedBox(height: 4),
            Text(
              '${pourcentageExtrait.toStringAsFixed(0)}% extraits',
              style: TextStyle(
                fontSize: 10,
                color: pourcentageExtrait > 70 ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGlobalStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.teal.shade600, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// Construit la barre de recherche et les filtres
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
                    hintText: 'Rechercher un produit, producteur, village...',
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
              // Bouton filtres - SIMPLIFIÉ
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
              // Tri
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: InputDecoration(
                    labelText: 'Trier par',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'dateReception',
                      child: Text('Date de réception'),
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
                      child: Text('Nature du produit'),
                    ),
                  ],
                  onChanged: (value) => _changeSorting(value!),
                ),
              ),

              const SizedBox(width: 12),

              // Ordre de tri
              IconButton(
                onPressed: () => _changeSorting(_sortBy),
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                tooltip: _sortAscending ? 'Croissant' : 'Décroissant',
              ),

              const SizedBox(width: 12),

              // Groupement
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _groupBy,
                  decoration: InputDecoration(
                    labelText: 'Grouper par',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'provenance',
                      child: Text('Provenance'),
                    ),
                    DropdownMenuItem(
                      value: 'nature',
                      child: Text('Nature du produit'),
                    ),
                    DropdownMenuItem(
                      value: 'attributeur',
                      child: Text('Attributeur'),
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

  /// Construit la liste des produits
  Widget _buildProductsList(ThemeData theme, bool isMobile) {
    if (_filteredProducts.isEmpty) {
      return Container(
        height: 300, // Hauteur fixe pour l'état vide
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun produit attribué',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Les produits attribués pour extraction apparaîtront ici',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final groupedProducts = _groupProducts();

    // ✅ CORRECTION CRITIQUE: Remplacer ListView par Column pour éviter viewport infini
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
                    Icon(
                      _getGroupIcon(_groupBy),
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$groupKey (${products.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Divider(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),

              // Produits du groupe - NOUVEAU SYSTÈME
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

  /// Retourne l'icône pour le groupement
  IconData _getGroupIcon(String groupBy) {
    switch (groupBy) {
      case 'provenance':
        return Icons.location_on;
      case 'nature':
        return Icons.category;
      case 'attributeur':
        return Icons.person;
      case 'statut':
        return Icons.flag;
      default:
        return Icons.group;
    }
  }

  /// Construit le widget de statistiques - NOUVEAU SYSTÈME
  Widget _buildStatsWidget(ThemeData theme, bool isMobile) {
    if (_stats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.secondary.withValues(alpha: 0.1)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              theme,
              '${_stats!['totalProduits']}',
              'Produits',
              Icons.inventory_2,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              theme,
              '${(_stats!['poidsTotal'] as double).toStringAsFixed(1)} kg',
              'Poids Total',
              Icons.scale,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              theme,
              '${(_stats!['poidsMielTotal'] as double).toStringAsFixed(1)} kg',
              'Poids Miel',
              Icons.water_drop,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      ThemeData theme, String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  /// Construit la carte d'un produit - NOUVEAU SYSTÈME
  Widget _buildProductCard(ThemeData theme, ProductControle product) {
    final isSelected = _selectedProductIds.contains(product.id);

    return Card(
      elevation: 2,
      color: isSelected ? Colors.blue.shade50 : null,
      child: InkWell(
        onTap: () => _toggleProductSelection(product.id),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec checkbox
              Row(
                children: [
                  // ✅ NOUVEAU: Checkbox de sélection
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleProductSelection(product.id),
                    activeColor: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getNatureColor(product.nature)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      product.nature.label,
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
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Miel: ${product.poidsMiel.toStringAsFixed(1)} kg',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Actions
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
                      product.estConforme ? 'Conforme' : 'Non conforme',
                      style: TextStyle(
                        color:
                            product.estConforme ? Colors.green : Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
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

  /// ✅ NOUVEAU: Basculer la sélection d'un produit
  void _toggleProductSelection(String productId) {
    setState(() {
      if (_selectedProductIds.contains(productId)) {
        _selectedProductIds.remove(productId);
      } else {
        _selectedProductIds.add(productId);
      }
    });
  }

  /// ✅ NOUVEAU: Sélectionner tous les produits
  void _selectAllProducts() {
    setState(() {
      _selectedProductIds.addAll(_filteredProducts.map((p) => p.id));
    });
  }

  /// ✅ NOUVEAU: Désélectionner tous les produits
  void _deselectAllProducts() {
    setState(() {
      _selectedProductIds.clear();
    });
  }

  /// ✅ NOUVEAU: Lancer l'extraction des produits sélectionnés
  void _lancerExtraction() {
    if (_selectedProductIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Veuillez sélectionner au moins un produit pour l\'extraction.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Récupérer les produits sélectionnés
    final produitsSelectionnes = _filteredProducts
        .where((p) => _selectedProductIds.contains(p.id))
        .toList();

    // Ouvrir le formulaire d'extraction
    showDialog(
      context: context,
      builder: (context) => ExtractionFormModal(
        produitsSelectionnes: produitsSelectionnes,
        onExtractionComplete: () {
          // Recharger les données et vider la sélection
          _deselectAllProducts();
          _refresh();
        },
      ),
    );
  }
}

/// Dialog pour afficher les détails d'un produit - NOUVEAU SYSTÈME
class _ProductDetailsDialog extends StatelessWidget {
  final ProductControle product;

  const _ProductDetailsDialog({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Icon(
                  Icons.inventory_2,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Détails du Produit',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informations générales - NOUVEAU SYSTÈME
                    _buildSection(
                      theme,
                      'Informations Générales',
                      Icons.info,
                      [
                        _buildDetailRow(
                            'Code contenant', product.codeContenant),
                        _buildDetailRow('Producteur', product.producteur),
                        _buildDetailRow('Village', product.village),
                        _buildDetailRow('Site d\'origine', product.siteOrigine),
                        _buildDetailRow('Nature', product.nature.label),
                        // _buildDetailRow('Collecteur', product.collecteur), // Propriété non disponible
                        _buildDetailRow('Qualité', product.qualite),
                        _buildDetailRow(
                            'Conforme', product.estConforme ? 'Oui' : 'Non'),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Poids et mesures
                    _buildSection(
                      theme,
                      'Poids et Mesures',
                      Icons.scale,
                      [
                        _buildDetailRow('Poids total',
                            '${product.poidsTotal.toStringAsFixed(2)} kg'),
                        _buildDetailRow('Poids miel',
                            '${product.poidsMiel.toStringAsFixed(2)} kg'),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Dates
                    _buildSection(
                      theme,
                      'Dates',
                      Icons.calendar_today,
                      [
                        _buildDetailRow('Date de réception',
                            _formatDate(product.dateReception)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Attribution
                    _buildSection(
                      theme,
                      'Attribution',
                      Icons.assignment,
                      [
                        _buildDetailRow('Collecte ID', product.collecteId),
                        _buildDetailRow('Statut',
                            product.estAttribue ? 'Attribué' : 'Disponible'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  // Méthodes de prélèvement supprimées - utilise maintenant le nouveau système

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
