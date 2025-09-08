import 'package:flutter/material.dart';
import '../models/filtered_product_models.dart';
import '../services/filtered_products_service.dart';
import '../widgets/filtered_product_card.dart';
import '../widgets/filtered_product_stats_widget.dart';
import '../widgets/filtrage_modal.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';

/// Page principale des produits attribués au filtrage
class FilteredProductsPage extends StatefulWidget {
  const FilteredProductsPage({super.key});

  @override
  State<FilteredProductsPage> createState() => _FilteredProductsPageState();
}

class _FilteredProductsPageState extends State<FilteredProductsPage> {
  final FilteredProductsService _service = FilteredProductsService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<FilteredProduct> _products = [];
  FilteredProductStats? _stats;

  // Filtres
  FilteredProductStatus? _selectedStatut;
  ProductNature? _selectedNature;
  String? _selectedSite;
  bool? _selectedOrigineControle;
  bool? _selectedOrigineExtraction;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final filters = FilteredProductFilters(
        statut: _selectedStatut,
        nature: _selectedNature,
        producteur:
            _searchController.text.isEmpty ? null : _searchController.text,
        origineControle: _selectedOrigineControle,
        origineExtraction: _selectedOrigineExtraction,
      );

      final products = await _service.getFilteredProducts(
        siteFiltreur: _selectedSite,
        filters: filters,
      );

      final stats = await _service.getStats(
        siteFiltreur: _selectedSite,
        filters: filters,
      );

      setState(() {
        _products = products;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    await _service.refresh();
    await _loadData();
  }

  void _clearFilters() {
    setState(() {
      _selectedStatut = null;
      _selectedNature = null;
      _selectedSite = null;
      _selectedOrigineControle = null;
      _selectedOrigineExtraction = null;
      _searchController.clear();
    });
    _loadData();
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

          // Statistiques
          if (_stats != null) FilteredProductStatsWidget(stats: _stats!),

          // Barre de recherche et filtres
          _buildSearchAndFilters(theme, isMobile),

          // Liste des produits
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Statistiques compactes
                  if (_stats != null)
                    Padding(
                      padding: EdgeInsets.all(isMobile ? 8 : 16),
                      child: FilteredProductStatsWidget(stats: _stats!),
                    ),

                  // Liste des produits avec hauteur adaptative
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
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
    );
  }

  /// Construit l'en-tête de la page
  Widget _buildHeader(ThemeData theme, bool isMobile) {
    return Container(
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
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Row(
            children: [
              // Bouton retour
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
              ),

              const SizedBox(width: 16),

              // Titre et informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filtrage - Produits Attribués',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Produits liquides contrôlés et extraits non filtrés',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              // Bouton rafraîchir
              IconButton(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
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
      child:
          isMobile ? _buildMobileFilters(theme) : _buildDesktopFilters(theme),
    );
  }

  /// Filtres mobile (vertical)
  Widget _buildMobileFilters(ThemeData theme) {
    return Column(
      children: [
        // Recherche
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher par producteur...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _loadData();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onSubmitted: (_) => _loadData(),
        ),

        const SizedBox(height: 12),

        // Filtres
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildDropdownFilter<FilteredProductStatus?>(
                'Statut',
                _selectedStatut,
                [null, ...FilteredProductStatus.values],
                (value) => value?.label ?? 'Tous',
                (value) {
                  setState(() => _selectedStatut = value);
                  _loadData();
                },
              ),
              const SizedBox(width: 8),
              _buildDropdownFilter<ProductNature?>(
                'Nature',
                _selectedNature,
                [null, ...ProductNature.values],
                (value) => value?.label ?? 'Toutes',
                (value) {
                  setState(() => _selectedNature = value);
                  _loadData();
                },
              ),
              const SizedBox(width: 8),
              _buildOriginFilter(),
              const SizedBox(width: 8),
              _buildClearFiltersButton(),
            ],
          ),
        ),
      ],
    );
  }

  /// Filtres desktop (horizontal)
  Widget _buildDesktopFilters(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcul de la largeur disponible pour déterminer si on a besoin du scroll
        const minFilterWidth = 200.0;
        const searchWidth = 300.0;
        const spacing = 16.0;
        final totalFiltersWidth =
            searchWidth + (minFilterWidth * 4) + (spacing * 4);

        final needsScroll = totalFiltersWidth > constraints.maxWidth;

        Widget filtersRow = Row(
          children: [
            // Recherche
            SizedBox(
              width: searchWidth,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher par producteur...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _loadData();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) => _loadData(),
              ),
            ),

            const SizedBox(width: spacing),

            // Filtres
            Flexible(
              child: _buildDropdownFilter<FilteredProductStatus?>(
                'Statut',
                _selectedStatut,
                [null, ...FilteredProductStatus.values],
                (value) => value?.label ?? 'Tous',
                (value) {
                  setState(() => _selectedStatut = value);
                  _loadData();
                },
              ),
            ),

            const SizedBox(width: spacing),

            Flexible(
              child: _buildDropdownFilter<ProductNature?>(
                'Nature',
                _selectedNature,
                [null, ...ProductNature.values],
                (value) => value?.label ?? 'Toutes',
                (value) {
                  setState(() => _selectedNature = value);
                  _loadData();
                },
              ),
            ),

            const SizedBox(width: spacing),

            Flexible(child: _buildOriginFilter()),

            const SizedBox(width: spacing),

            _buildClearFiltersButton(),
          ],
        );

        // Retourner avec ou sans scroll selon l'espace disponible
        if (needsScroll) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicHeight(child: filtersRow),
          );
        } else {
          return filtersRow;
        }
      },
    );
  }

  /// Dropdown de filtre générique
  Widget _buildDropdownFilter<T>(
    String label,
    T value,
    List<T> items,
    String Function(T) labelBuilder,
    void Function(T?) onChanged,
  ) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(labelBuilder(item)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  /// Filtre d'origine
  Widget _buildOriginFilter() {
    return DropdownButtonFormField<String?>(
      value: _selectedOrigineControle == true
          ? 'controle'
          : _selectedOrigineExtraction == true
              ? 'extraction'
              : null,
      decoration: InputDecoration(
        labelText: 'Origine',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: const [
        DropdownMenuItem<String?>(value: null, child: Text('Toutes')),
        DropdownMenuItem<String?>(value: 'controle', child: Text('Contrôle')),
        DropdownMenuItem<String?>(
            value: 'extraction', child: Text('Extraction')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedOrigineControle = value == 'controle' ? true : null;
          _selectedOrigineExtraction = value == 'extraction' ? true : null;
        });
        _loadData();
      },
    );
  }

  /// Bouton pour effacer les filtres
  Widget _buildClearFiltersButton() {
    return IconButton(
      onPressed: _clearFilters,
      icon: const Icon(Icons.clear_all),
      tooltip: 'Effacer les filtres',
      style: IconButton.styleFrom(
        backgroundColor: Colors.grey.withOpacity(0.1),
      ),
    );
  }

  /// Construit la liste des produits
  Widget _buildProductsList(ThemeData theme, bool isMobile) {
    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun produit attribué au filtrage',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les produits liquides contrôlés et extraits\napparaîtront ici une fois attribués',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isMobile ? 8 : 16),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FilteredProductCard(
            product: product,
            onTap: () => _showFiltrageModal(product),
            onRefresh: _loadData,
          ),
        );
      },
    );
  }

  /// Affiche le modal de filtrage
  void _showFiltrageModal(FilteredProduct product) {
    // Convertir FilteredProduct en ProductControle pour le modal
    final productControle = ProductControle(
      id: product.id,
      codeContenant: product.codeContenant,
      collecteId: product.collecteId,
      producteur: product.producteur,
      village: product.village,
      commune: product.village, // Utiliser village comme commune par défaut
      quartier: 'Centre', // Valeur par défaut
      siteOrigine: product.siteOrigine,
      nature: product.nature,
      typeContenant: product.typeContenant,
      numeroContenant: product.codeContenant,
      qualite: product.qualite,
      poidsTotal: product.poidsOriginal,
      poidsMiel: product.poidsOriginal,
      predominanceFlorale: product.predominanceFlorale,
      dateCollecte: product.dateReception.subtract(const Duration(days: 1)),
      dateReception: product.dateReception,
      dateControle: product.dateReception,
      estAttribue: product.estOrigineDuControle,
      estConforme: true,
      typeCollecte: product.typeCollecte,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FiltrageModal(
        product: productControle,
        onCompleted: _loadData,
      ),
    );
  }
}
