import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import '../models/attribution_models.dart';
import '../services/attribution_service.dart';
import '../services/extraction_service.dart';
import '../widgets/attribution_card.dart';
import '../widgets/attribution_modals.dart';
import '../widgets/attribution_filters.dart';
import '../widgets/attribution_stats.dart';

/*
/// ⚠️ CODE COMPLÈTEMENT COMMENTÉ - NE PLUS UTILISER ⚠️
/// Cette page AttributionPage (extraction) n'est plus utilisée.
/// Le système d'attribution principal utilise maintenant AttributionPageComplete.

class AttributionPage extends StatefulWidget {
  const AttributionPage({super.key});

  @override
  State<AttributionPage> createState() => _AttributionPageState();
}

class _AttributionPageState extends State<AttributionPage>
    with TickerProviderStateMixin {
  final AttributionService _attributionService = AttributionService();
  final ExtractionService _extractionService = ExtractionService();

  // État de l'application
  List<AttributionExtraction> _allAttributions = [];
  List<AttributionExtraction> _filteredAttributions = [];
  AttributionFilters _filters = AttributionFilters();
  bool _isLoading = true;
  String _searchQuery = '';

  // Contrôleurs d'animation
  late AnimationController _headerController;
  late AnimationController _statsController;
  late Animation<double> _headerAnimation;
  late Animation<double> _statsAnimation;

  // Contrôleurs de texte
  final TextEditingController _searchController = TextEditingController();

  // Timer pour l'horloge
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
    _startClock();

    // Écouter les changements du service
    _attributionService.addListener(_onAttributionServiceChanged);
  }

  @override
  void dispose() {
    _headerController.dispose();
    _statsController.dispose();
    _searchController.dispose();
    _clockTimer?.cancel();
    _attributionService.removeListener(_onAttributionServiceChanged);
    super.dispose();
  }

  /// Initialise les animations
  void _initializeAnimations() {
    _headerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _statsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _headerAnimation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeInOut,
    ));

    _statsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statsController,
      curve: Curves.elasticOut,
    ));
  }

  /// Charge les données
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 500));

    _allAttributions = _attributionService.attributions;
    _applyFilters();

    setState(() => _isLoading = false);
    _statsController.forward();
  }

  /// Démarre l'horloge
  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _currentTime = DateTime.now());
    });
  }

  /// Callback quand le service change
  void _onAttributionServiceChanged() {
    _allAttributions = _attributionService.attributions;
    _applyFilters();
  }

  /// Applique les filtres
  void _applyFilters() {
    var filtered = _attributionService.filtrerAttributions(_filters);

    // Appliquer la recherche textuelle
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((attribution) =>
              attribution.lotId.toLowerCase().contains(query) ||
              attribution.utilisateur.toLowerCase().contains(query) ||
              attribution.statut.label.toLowerCase().contains(query))
          .toList();
    }

    setState(() {
      _filteredAttributions = filtered;
    });
  }

  /// Gère la recherche
  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _applyFilters();
  }

  /// Gère les changements de filtres
  void _onFiltersChanged(AttributionFilters newFilters) {
    setState(() => _filters = newFilters);
    _applyFilters();
  }

  /// Affiche le modal de nouvelle attribution
  void _showNewAttributionModal() async {
    final products = _extractionService
        .getAllProducts()
        .where((p) => !_attributionService.contenantEstAttribue(p.id))
        .toList();

    if (products.isEmpty) {
      Get.snackbar(
        'Aucun contenant disponible',
        'Tous les contenants sont déjà attribués',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        icon: const Icon(Icons.warning, color: Colors.orange),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AttributionFormModal(
        availableProducts: products,
        utilisateurs: _attributionService.utilisateurs,
      ),
    );

    if (result != null) {
      try {
        await _attributionService.creerAttribution(
          utilisateur: result['utilisateur'],
          lotId: result['lotId'],
          listeContenants: result['listeContenants'],
          commentaires: result['commentaires'],
          metadata: result['metadata'] ?? {},
        );

        Get.snackbar(
          'Attribution créée',
          'Lot ${result['lotId']} attribué avec succès',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          icon: const Icon(Icons.check_circle, color: Colors.green),
        );
      } catch (e) {
        Get.snackbar(
          'Erreur',
          e.toString(),
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          icon: const Icon(Icons.error, color: Colors.red),
        );
      }
    }
  }

  /// Affiche le modal de modification d'attribution
  void _showEditAttributionModal(AttributionExtraction attribution) async {
    final products = _extractionService.getAllProducts();
    final availableProducts = products
        .where((p) =>
            attribution.listeContenants.contains(p.id) ||
            !_attributionService.contenantEstAttribue(p.id))
        .toList();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AttributionFormModal(
        attribution: attribution,
        availableProducts: availableProducts,
        utilisateurs: _attributionService.utilisateurs,
      ),
    );

    if (result != null) {
      try {
        await _attributionService.modifierAttribution(
          attributionId: attribution.id,
          lotId: result['lotId'],
          listeContenants: result['listeContenants'],
          statut: result['statut'],
          commentaires: result['commentaires'],
          utilisateurModification: result['utilisateur'],
          metadata: result['metadata'],
        );

        Get.snackbar(
          'Attribution modifiée',
          'Lot ${result['lotId']} mis à jour avec succès',
          backgroundColor: Colors.blue.shade100,
          colorText: Colors.blue.shade800,
          icon: const Icon(Icons.edit, color: Colors.blue),
        );
      } catch (e) {
        Get.snackbar(
          'Erreur',
          e.toString(),
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          icon: const Icon(Icons.error, color: Colors.red),
        );
      }
    }
  }

  /// Confirme et annule une attribution
  void _confirmCancelAttribution(AttributionExtraction attribution) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer l\'annulation'),
        content: Text(
            'Êtes-vous sûr de vouloir annuler l\'attribution du lot ${attribution.lotId} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Confirmer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _attributionService.annulerAttribution(
          attributionId: attribution.id,
          utilisateurAnnulation:
              'Utilisateur actuel', // TODO: Récupérer l'utilisateur connecté
          motifAnnulation: 'Annulation manuelle',
        );

        Get.snackbar(
          'Attribution annulée',
          'Lot ${attribution.lotId} annulé avec succès',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
          icon: const Icon(Icons.cancel, color: Colors.orange),
        );
      } catch (e) {
        Get.snackbar(
          'Erreur',
          e.toString(),
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          icon: const Icon(Icons.error, color: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats =
        _attributionService.calculerStatistiques(_filteredAttributions);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 600 && screenWidth <= 1200;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header avec animations
                _buildAnimatedHeader(isDesktop),

                // Statistiques
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: AttributionStatsWidget(
                    stats: stats,
                    animation: _statsAnimation,
                    isDesktop: isDesktop,
                  ),
                ),

                // Barre de recherche et filtres
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Rechercher par lot, utilisateur...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      AttributionFiltersWidget(
                        filters: _filters,
                        onFiltersChanged: _onFiltersChanged,
                        attributions: _allAttributions,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Liste des attributions
                Expanded(
                  child: _filteredAttributions.isEmpty
                      ? _buildEmptyState()
                      : _buildAttributionsList(isDesktop, isTablet),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-extraction-attribution-new',
        onPressed: _showNewAttributionModal,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle Attribution'),
        backgroundColor: Colors.blue.shade600,
      ),
    );
  }

  /// Construit le header animé
  Widget _buildAnimatedHeader(bool isDesktop) {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade600.withOpacity(_headerAnimation.value),
                Colors.purple.shade600.withOpacity(_headerAnimation.value),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            title: Text(
              'Gestion des Attributions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isDesktop ? 24 : 20,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${_currentTime.day}/${_currentTime.month}/${_currentTime.year}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Construit l'état vide
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune attribution trouvée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filters.isActive
                ? 'Essayez de modifier vos filtres'
                : 'Créez votre première attribution',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  /// Construit la liste des attributions
  Widget _buildAttributionsList(bool isDesktop, bool isTablet) {
    if (isDesktop) {
      // Grille pour desktop
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.8,
          ),
          itemCount: _filteredAttributions.length,
          itemBuilder: (context, index) {
            return AttributionCard(
              attribution: _filteredAttributions[index],
              extractionProducts: _extractionService.getAllProducts(),
              onEdit: () =>
                  _showEditAttributionModal(_filteredAttributions[index]),
              onCancel: () =>
                  _confirmCancelAttribution(_filteredAttributions[index]),
            );
          },
        ),
      );
    } else {
      // Liste pour mobile/tablet
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredAttributions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AttributionCard(
              attribution: _filteredAttributions[index],
              extractionProducts: _extractionService.getAllProducts(),
              onEdit: () =>
                  _showEditAttributionModal(_filteredAttributions[index]),
              onCancel: () =>
                  _confirmCancelAttribution(_filteredAttributions[index]),
            ),
          );
        },
      );
    }
  }
}
*/

// ⚠️ Fichier complètement commenté - Utiliser AttributionPageComplete à la place
