/// Page principale pour les produits attribués à l'extraction
import 'package:flutter/material.dart';
import 'dart:async';

import '../models/attributed_product_models.dart';
import '../services/attributed_products_service.dart';
import '../widgets/attributed_product_card.dart';
import '../widgets/attributed_product_filters_widget.dart';
import '../widgets/attributed_product_stats_widget.dart';
import '../widgets/prelevement_modal.dart';

class AttributedProductsPage extends StatefulWidget {
  const AttributedProductsPage({super.key});

  @override
  State<AttributedProductsPage> createState() => _AttributedProductsPageState();
}

class _AttributedProductsPageState extends State<AttributedProductsPage>
    with TickerProviderStateMixin {
  final AttributedProductsService _service = AttributedProductsService();

  // État de l'application
  List<AttributedProduct> _allProducts = [];
  List<AttributedProduct> _filteredProducts = [];
  AttributedProductFilters _filters = const AttributedProductFilters();
  AttributedProductStats? _stats;
  bool _isLoading = true;
  String _sortBy =
      'dateAttribution'; // 'dateAttribution', 'dateReception', 'poids', 'provenance'
  bool _sortAscending = false;

  // Contrôleurs d'animation
  late AnimationController _headerGlowController;
  late AnimationController _refreshController;

  // Contrôleurs de texte
  final TextEditingController _searchController = TextEditingController();

  // Timer pour l'horloge temps réel
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

  // Options de groupe
  String _groupBy =
      'provenance'; // 'provenance', 'nature', 'attributeur', 'statut'

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
    _searchController.dispose();
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
  }

  /// Démarre l'horloge temps réel
  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  /// Charge les données
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final products = await _service.getAttributedProducts(filters: _filters);
      final stats = await _service.getStats(filters: _filters);

      if (mounted) {
        setState(() {
          _allProducts = products;
          _filteredProducts = _applySortAndGroup(products);
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Applique le tri et le groupement
  List<AttributedProduct> _applySortAndGroup(List<AttributedProduct> products) {
    // Tri
    products.sort((a, b) {
      int result;
      switch (_sortBy) {
        case 'dateAttribution':
          result = a.dateAttribution.compareTo(b.dateAttribution);
          break;
        case 'dateReception':
          result = a.dateReception.compareTo(b.dateReception);
          break;
        case 'poids':
          result = a.poidsDisponible.compareTo(b.poidsDisponible);
          break;
        case 'provenance':
          result = a.codeLocalisation.compareTo(b.codeLocalisation);
          break;
        default:
          result = a.dateAttribution.compareTo(b.dateAttribution);
      }
      return _sortAscending ? result : -result;
    });

    return products;
  }

  /// Applique les filtres
  void _applyFilters(AttributedProductFilters newFilters) {
    setState(() {
      _filters = newFilters;
      _searchController.text = _filters.searchQuery;
    });
    _loadData();
  }

  /// Applique la recherche
  void _applySearch(String query) {
    final newFilters = _filters.copyWith(searchQuery: query);
    _applyFilters(newFilters);
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

  /// Rafraîchit les données
  Future<void> _refresh() async {
    _refreshController.forward();
    await _service.refresh();
    await _loadData();
    _refreshController.reset();
  }

  /// Affiche la modal de prélèvement
  void _showPrelevementModal(AttributedProduct product) {
    showDialog(
      context: context,
      builder: (context) => PrelevementModal(
        product: product,
        onPrelevementCreated: () {
          _loadData(); // Recharger les données
        },
      ),
    );
  }

  /// Affiche les détails du produit
  void _showProductDetails(AttributedProduct product) {
    showDialog(
      context: context,
      builder: (context) => _ProductDetailsDialog(product: product),
    );
  }

  /// Groupe les produits selon le critère sélectionné
  Map<String, List<AttributedProduct>> _groupProducts() {
    final Map<String, List<AttributedProduct>> grouped = {};

    for (final product in _filteredProducts) {
      String groupKey;
      switch (_groupBy) {
        case 'provenance':
          groupKey = product.codeLocalisation;
          break;
        case 'nature':
          groupKey = product.nature.label;
          break;
        case 'attributeur':
          groupKey = product.attributeur;
          break;
        case 'statut':
          groupKey = product.statut.label;
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
      body: Column(
        children: [
          // En-tête
          _buildHeader(theme, isMobile),

          // Contenu principal avec scroll flexible
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Statistiques - compactes sur mobile
                  if (_stats != null)
                    Padding(
                      padding: EdgeInsets.all(isMobile ? 8 : 16),
                      child: AttributedProductStatsWidget(stats: _stats!),
                    ),

                  // Barre de recherche et filtres
                  _buildSearchAndFilters(theme, isMobile),

                  // Liste des produits avec hauteur adaptative
                  SizedBox(
                    height: MediaQuery.of(context).size.height *
                        0.4, // 40% de la hauteur d'écran
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildProductsList(theme, isMobile),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refresh,
        backgroundColor: theme.colorScheme.primary,
        child: RotationTransition(
          turns: _refreshController,
          child: const Icon(Icons.refresh, color: Colors.white),
        ),
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
            color: theme.colorScheme.primary.withOpacity(0.3),
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
                              color: Colors.white.withOpacity(0.9),
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
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(
                            0.3 + _headerGlowController.value * 0.4,
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

  /// Construit la barre de recherche et les filtres
  Widget _buildSearchAndFilters(ThemeData theme, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
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
              // Bouton filtres
              IconButton(
                onPressed: () => _showFiltersDialog(theme),
                icon: Badge(
                  isLabelVisible: _filters.hasActiveFilters,
                  label: Text(_filters.getActiveFiltersCount().toString()),
                  child: const Icon(Icons.filter_list),
                ),
                tooltip: 'Filtres',
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
                  items: const [
                    DropdownMenuItem(
                      value: 'dateAttribution',
                      child: Text('Date d\'attribution'),
                    ),
                    DropdownMenuItem(
                      value: 'dateReception',
                      child: Text('Date de réception'),
                    ),
                    DropdownMenuItem(
                      value: 'poids',
                      child: Text('Poids disponible'),
                    ),
                    DropdownMenuItem(
                      value: 'provenance',
                      child: Text('Provenance'),
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
      return Center(
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
      );
    }

    final groupedProducts = _groupProducts();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedProducts.length,
      itemBuilder: (context, index) {
        final groupKey = groupedProducts.keys.elementAt(index);
        final products = groupedProducts[groupKey]!;

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
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),

            // Produits du groupe
            ...products.map((product) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AttributedProductCard(
                    product: product,
                    onPrelevementTap: () => _showPrelevementModal(product),
                    onDetailsTap: () => _showProductDetails(product),
                  ),
                )),

            const SizedBox(height: 16),
          ],
        );
      },
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

  /// Affiche la dialog des filtres
  void _showFiltersDialog(ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AttributedProductFiltersWidget(
        currentFilters: _filters,
        onFiltersApplied: _applyFilters,
      ),
    );
  }
}

/// Dialog pour afficher les détails d'un produit
class _ProductDetailsDialog extends StatelessWidget {
  final AttributedProduct product;

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
                    // Informations générales
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
                        _buildDetailRow(
                            'Type contenant', product.typeContenant),
                        _buildDetailRow('Qualité', product.qualite),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Poids et prélèvements
                    _buildSection(
                      theme,
                      'Poids et Prélèvements',
                      Icons.scale,
                      [
                        _buildDetailRow(
                          'Poids original',
                          '${product.poidsOriginal.toStringAsFixed(2)} kg',
                        ),
                        _buildDetailRow(
                          'Poids disponible',
                          '${product.poidsDisponible.toStringAsFixed(2)} kg',
                        ),
                        _buildDetailRow(
                          'Poids prélevé',
                          '${product.poidsResidus.toStringAsFixed(2)} kg',
                        ),
                        _buildDetailRow(
                          'Pourcentage prélevé',
                          '${product.pourcentagePrelevementTotal.toStringAsFixed(1)}%',
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Dates
                    _buildSection(
                      theme,
                      'Dates',
                      Icons.calendar_today,
                      [
                        _buildDetailRow(
                          'Date de collecte',
                          _formatDate(product.dateCollecte),
                        ),
                        _buildDetailRow(
                          'Date de réception',
                          _formatDate(product.dateReception),
                        ),
                        _buildDetailRow(
                          'Date d\'attribution',
                          _formatDate(product.dateAttribution),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Historique des prélèvements
                    if (product.prelevements.isNotEmpty) ...[
                      _buildSection(
                        theme,
                        'Historique des Prélèvements',
                        Icons.history,
                        product.prelevements
                            .map((prelevement) =>
                                _buildPrelevementItem(theme, prelevement))
                            .toList(),
                      ),
                    ],
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

  Widget _buildPrelevementItem(ThemeData theme, Prelevement prelevement) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getPrelevementIcon(prelevement.statut),
                color: _getPrelevementColor(prelevement.statut),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${prelevement.poidsPreleve.toStringAsFixed(2)} kg - ${prelevement.type.label}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      _getPrelevementColor(prelevement.statut).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  prelevement.statut.label,
                  style: TextStyle(
                    color: _getPrelevementColor(prelevement.statut),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Date: ${_formatDate(prelevement.datePrelevement)}',
            style: theme.textTheme.bodySmall,
          ),
          if (prelevement.observations != null) ...[
            const SizedBox(height: 4),
            Text(
              'Observations: ${prelevement.observations}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  IconData _getPrelevementIcon(PrelevementStatus statut) {
    switch (statut) {
      case PrelevementStatus.enAttente:
        return Icons.schedule;
      case PrelevementStatus.enCours:
        return Icons.play_circle;
      case PrelevementStatus.termine:
        return Icons.check_circle;
      case PrelevementStatus.suspendu:
        return Icons.pause_circle;
    }
  }

  Color _getPrelevementColor(PrelevementStatus statut) {
    switch (statut) {
      case PrelevementStatus.enAttente:
        return Colors.orange;
      case PrelevementStatus.enCours:
        return Colors.blue;
      case PrelevementStatus.termine:
        return Colors.green;
      case PrelevementStatus.suspendu:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
