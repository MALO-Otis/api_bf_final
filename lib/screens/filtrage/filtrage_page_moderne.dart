import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:async';

import '../controle_de_donnes/services/attribution_service.dart';
import '../../authentication/user_session.dart';
import 'models/filtrage_models.dart';
import 'services/filtrage_service.dart';
import 'widgets/filtrage_card.dart';
import 'widgets/filtrage_modals.dart';

/// Page moderne de filtrage basée sur le design de la page d'extraction
class FiltragePageModerne extends StatefulWidget {
  const FiltragePageModerne({super.key});

  @override
  State<FiltragePageModerne> createState() => _FiltragePageModerneState();
}

class _FiltragePageModerneState extends State<FiltragePageModerne>
    with TickerProviderStateMixin {
  final AttributionService _attributionService = AttributionService();

  // État de l'application
  List<FiltrageProduct> _allProducts = [];
  List<FiltrageProduct> _filteredProducts = [];
  FiltrageFilters _filters = FiltrageFilters();
  bool _isLoading = true;
  int _notifications = 0;

  // Contrôleurs d'animation
  late AnimationController _headerGlowController;
  late AnimationController _counterController;
  late Animation<double> _counterAnimation;

  // Contrôleur de tabs
  late TabController _tabController;

  // Contrôleurs de texte
  final TextEditingController _searchController = TextEditingController();

  // Timer pour l'horloge temps réel
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();

    // Configuration des contrôleurs d'animation
    _headerGlowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _counterController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _counterAnimation = CurvedAnimation(
      parent: _counterController,
      curve: Curves.elasticOut,
    );

    // Configuration du TabController
    _tabController = TabController(length: 4, vsync: this);

    // Démarrer l'horloge temps réel
    _startClock();

    // Chargement des données
    _loadData();

    // Démarrer les animations
    _headerGlowController.repeat(reverse: true);
    _counterController.forward();
  }

  @override
  void dispose() {
    _headerGlowController.dispose();
    _counterController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    _clockTimer?.cancel();
    super.dispose();
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Mise à jour de l'horloge si nécessaire
        });
      }
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      if (kDebugMode) {
        print('🚀 FILTRAGE: Chargement des produits contrôlés...');
      }

      // Charger les produits depuis le service d'attribution (produits contrôlés)
      await _attributionService.initialiserDonnees();
      final produits = _attributionService.obtenirTousLesProduits();

      if (kDebugMode) {
        print('✅ FILTRAGE: ${produits.length} produits contrôlés chargés');
      }

      // Convertir en produits de filtrage
      _allProducts = produits
          .where((p) => p.estConforme && !p.estAttribue)
          .map((p) => FiltrageProduct.fromProductControle(p))
          .toList();

      // Calculer les notifications (produits urgents)
      _notifications = _allProducts.where((p) => p.isUrgent).length;

      _applyFilters();
    } catch (e) {
      if (kDebugMode) {
        print('❌ FILTRAGE: Erreur lors du chargement: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Erreur lors du chargement: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        // Filtre par recherche
        if (_filters.searchQuery.isNotEmpty) {
          final query = _filters.searchQuery.toLowerCase();
          if (!product.producteur.toLowerCase().contains(query) &&
              !product.village.toLowerCase().contains(query) &&
              !product.codeContenant.toLowerCase().contains(query)) {
            return false;
          }
        }

        // Filtre par type de collecte
        if (_filters.selectedTypes.isNotEmpty &&
            !_filters.selectedTypes.contains(product.typeCollecte)) {
          return false;
        }

        // Filtre par statut de filtrage
        if (_filters.selectedStatuses.isNotEmpty &&
            !_filters.selectedStatuses.contains(product.statutFiltrage)) {
          return false;
        }

        // Filtre par site
        if (_filters.selectedSites.isNotEmpty &&
            !_filters.selectedSites.contains(product.siteOrigine)) {
          return false;
        }

        // Filtre par nature
        if (_filters.selectedNatures.isNotEmpty &&
            !_filters.selectedNatures.contains(product.nature)) {
          return false;
        }

        // Filtre par urgence
        if (_filters.showOnlyUrgent && !product.isUrgent) {
          return false;
        }

        // Filtre par date
        if (_filters.dateDebut != null &&
            product.dateReception.isBefore(_filters.dateDebut!)) {
          return false;
        }

        if (_filters.dateFin != null &&
            product.dateReception
                .isAfter(_filters.dateFin!.add(const Duration(days: 1)))) {
          return false;
        }

        return true;
      }).toList();

      // Tri
      switch (_filters.sortBy) {
        case FiltrageSort.date:
          _filteredProducts.sort((a, b) => _filters.sortAscending
              ? a.dateReception.compareTo(b.dateReception)
              : b.dateReception.compareTo(a.dateReception));
          break;
        case FiltrageSort.poids:
          _filteredProducts.sort((a, b) => _filters.sortAscending
              ? a.poids.compareTo(b.poids)
              : b.poids.compareTo(a.poids));
          break;
        case FiltrageSort.producteur:
          _filteredProducts.sort((a, b) => _filters.sortAscending
              ? a.producteur.compareTo(b.producteur)
              : b.producteur.compareTo(a.producteur));
          break;
        case FiltrageSort.urgence:
          _filteredProducts.sort((a, b) {
            if (a.isUrgent && !b.isUrgent)
              return _filters.sortAscending ? -1 : 1;
            if (!a.isUrgent && b.isUrgent)
              return _filters.sortAscending ? 1 : -1;
            return 0;
          });
          break;
      }
    });
  }

  void _resetFilters() {
    setState(() {
      _filters = FiltrageFilters();
      _searchController.clear();
    });
    _applyFilters();
  }

  void _showFiltersModal() {
    showDialog(
      context: context,
      builder: (context) => FiltrageFiltersModal(
        filters: _filters,
        onApply: (newFilters) {
          setState(() => _filters = newFilters);
          _applyFilters();
        },
        allProducts: _allProducts,
      ),
    );
  }

  void _showStatsModal() {
    showDialog(
      context: context,
      builder: (context) => FiltrageStatsModal(
        products: _filteredProducts,
        allProducts: _allProducts,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Layout responsive - variables disponibles si nécessaire
    // final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepOrange.shade50,
              Colors.orange.shade50,
              Colors.amber.shade50,
            ],
          ),
        ),
        child: Column(
          children: [
            _buildModernHeader(),
            _buildTabBarSection(),
            Expanded(
              child: _isLoading ? _buildLoadingState() : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepOrange.shade600,
            Colors.orange.shade500,
            Colors.amber.shade400,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                tooltip: 'Retour',
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedBuilder(
                      animation: _headerGlowController,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(
                                  0.3 + 0.2 * _headerGlowController.value,
                                ),
                                blurRadius:
                                    10 + 5 * _headerGlowController.value,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            'Filtrage / Maturation',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.deepOrange.shade800
                                      .withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Gestion des produits contrôlés',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildHeaderStats(),
            ],
          ),
          const SizedBox(height: 20),
          _buildSearchAndActions(),
        ],
      ),
    );
  }

  Widget _buildHeaderStats() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.filter_alt, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              AnimatedBuilder(
                animation: _counterAnimation,
                builder: (context, child) {
                  return Text(
                    '${(_filteredProducts.length * _counterAnimation.value).round()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
          Text(
            'Produits',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          if (_notifications > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.priority_high,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '$_notifications',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchAndActions() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher par producteur, village, code...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () {
                          _searchController.clear();
                          _filters = _filters.copyWith(searchQuery: '');
                          _applyFilters();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              onChanged: (value) {
                _filters = _filters.copyWith(searchQuery: value);
                _applyFilters();
              },
            ),
          ),
        ),
        const SizedBox(width: 15),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        _buildActionButton(
          icon: Icons.filter_list,
          onPressed: _showFiltersModal,
          tooltip: 'Filtres avancés',
          hasNotification: _filters.hasActiveFilters,
        ),
        const SizedBox(width: 10),
        _buildActionButton(
          icon: Icons.bar_chart,
          onPressed: _showStatsModal,
          tooltip: 'Statistiques',
        ),
        const SizedBox(width: 10),
        _buildActionButton(
          icon: Icons.refresh,
          onPressed: _loadData,
          tooltip: 'Actualiser',
        ),
        const SizedBox(width: 10),
        _buildActionButton(
          icon: Icons.clear_all,
          onPressed: _resetFilters,
          tooltip: 'Réinitialiser',
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool hasNotification = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Stack(
        children: [
          IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
            tooltip: tooltip,
          ),
          if (hasNotification)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBarSection() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.deepOrange,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.deepOrange,
        tabs: const [
          Tab(icon: Icon(Icons.eco), text: 'Récoltes'),
          Tab(icon: Icon(Icons.groups), text: 'SCOOP'),
          Tab(icon: Icon(Icons.person), text: 'Individuel'),
          Tab(icon: Icon(Icons.house), text: 'Miellerie'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildProductsList('recoltes'),
        _buildProductsList('scoop'),
        _buildProductsList('individuel'),
        _buildProductsList('miellerie'),
      ],
    );
  }

  Widget _buildProductsList(String type) {
    final products =
        _filteredProducts.where((p) => p.typeCollecte == type).toList();

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_alt_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun produit ${_getTypeLabel(type)}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajustez vos filtres pour voir plus de résultats',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FiltrageCard(
            product: product,
            onTap: () => _showProductDetails(product),
            onStartFiltrage: () => _startFiltrage(product),
            onAssign: () => _assignToAgent(product),
          ),
        );
      },
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'recoltes':
        return 'de récolte';
      case 'scoop':
        return 'SCOOP';
      case 'individuel':
        return 'individuel';
      case 'miellerie':
        return 'de miellerie';
      default:
        return '';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_alt_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun produit à filtrer',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Les produits contrôlés et conformes apparaîtront ici',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
          ),
          SizedBox(height: 20),
          Text(
            'Chargement des produits...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDetails(FiltrageProduct product) {
    showDialog(
      context: context,
      builder: (context) => FiltrageProductDetailsModal(product: product),
    );
  }

  void _startFiltrage(FiltrageProduct product) {
    showDialog(
      context: context,
      builder: (context) => FiltrageProcessModal(
        product: product,
        onComplete: (result) {
          // Mettre à jour le statut du produit
          _loadData(); // Recharger les données

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Filtrage de ${product.codeContenant} terminé'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _assignToAgent(FiltrageProduct product) {
    showDialog(
      context: context,
      builder: (context) => FiltrageAssignmentModal(
        product: product,
        onAssign: (agent) {
          // Traiter l'attribution
          _loadData(); // Recharger les données

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.person_add, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('${product.codeContenant} attribué à $agent'),
                ],
              ),
              backgroundColor: Colors.blue,
            ),
          );
        },
      ),
    );
  }
}
