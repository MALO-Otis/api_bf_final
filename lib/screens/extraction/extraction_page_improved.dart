import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import '../controle_de_donnes/models/attribution_models_v2.dart';
import 'models/extraction_models_improved.dart';
import 'services/extraction_service_improved.dart';
import 'widgets/extraction_widgets_improved.dart';
import 'widgets/extraction_modals_improved.dart';

/// 🟫 PAGE D'EXTRACTION AMÉLIORÉE - NOUVELLE GÉNÉRATION
///
/// Cette page d'extraction révolutionnée s'intègre parfaitement avec
/// le nouveau système d'attribution unifié pour offrir :
///
/// ✨ FONCTIONNALITÉS AVANCÉES :
/// - Réception automatique des produits attribués depuis le contrôle
/// - Interface moderne et responsive
/// - Suivi en temps réel des extractions
/// - Statistiques avancées et KPIs
/// - Gestion intelligente des priorités
/// - Processus d'extraction guidé
/// - Historique complet et traçabilité
class ExtractionPageImproved extends StatefulWidget {
  const ExtractionPageImproved({Key? key}) : super(key: key);

  @override
  State<ExtractionPageImproved> createState() => _ExtractionPageImprovedState();
}

class _ExtractionPageImprovedState extends State<ExtractionPageImproved>
    with TickerProviderStateMixin {
  // Services
  late final ExtractionServiceImproved _extractionService;

  // Controllers
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // State
  final RxBool _isLoading = true.obs;
  final RxList<ProductControle> _produitsAttribues = <ProductControle>[].obs;
  final RxList<ProductControle> _produitsFiltres = <ProductControle>[].obs;
  final RxList<ExtractionProcess> _extractionsEnCours =
      <ExtractionProcess>[].obs;
  final RxList<ExtractionResult> _extractionsTerminees =
      <ExtractionResult>[].obs;
  final RxString _searchQuery = ''.obs;
  final RxInt _selectedTabIndex = 0.obs;

  // Statistiques
  final RxMap<String, dynamic> _stats = <String, dynamic>{}.obs;

  // Timers
  Timer? _refreshTimer;
  Timer? _clockTimer;
  final RxString _currentTime = ''.obs;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeControllers();
    _startAutoRefresh();
    _startClock();
    _loadData();
  }

  void _initializeServices() {
    _extractionService = ExtractionServiceImproved();
  }

  void _initializeControllers() {
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      _selectedTabIndex.value = _tabController.index;
    });

    _searchController.addListener(() {
      _searchQuery.value = _searchController.text;
      _applyFilters();
    });
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadData();
    });
  }

  void _startClock() {
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateClock();
    });
  }

  void _updateClock() {
    final now = DateTime.now();
    _currentTime.value =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  Future<void> _loadData() async {
    try {
      _isLoading.value = true;

      // Charger les produits attribués pour extraction
      final produitsAttribues =
          await _extractionService.getProduitsAttribuesExtraction();
      _produitsAttribues.assignAll(produitsAttribues);

      // Charger les extractions en cours
      final extractionsEnCours =
          await _extractionService.getExtractionsEnCours();
      _extractionsEnCours.assignAll(extractionsEnCours);

      // Charger les extractions terminées
      final extractionsTerminees =
          await _extractionService.getExtractionsTerminees();
      _extractionsTerminees.assignAll(extractionsTerminees);

      // Calculer les statistiques
      _calculateStats();

      // Appliquer les filtres
      _applyFilters();
    } catch (e) {
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
    final stats = <String, dynamic>{
      'totalAttribues': _produitsAttribues.length,
      'enCours': _extractionsEnCours.length,
      'terminees': _extractionsTerminees.length,
      'poidsTotal':
          _produitsAttribues.fold(0.0, (sum, p) => sum + p.poidsTotal),
      'rendementMoyen': _extractionsTerminees.isEmpty
          ? 0.0
          : _extractionsTerminees.fold(0.0, (sum, e) => sum + e.rendement) /
              _extractionsTerminees.length,
      'dureeMoyenne': _extractionsTerminees.isEmpty
          ? 0
          : (_extractionsTerminees.fold(
                      0, (sum, e) => sum + e.duree.inMinutes) /
                  _extractionsTerminees.length)
              .round(),
      'urgents': _produitsAttribues.where((p) => p.isUrgent).length,
    };
    _stats.assignAll(stats);
  }

  void _applyFilters() {
    var produitsFiltres = _produitsAttribues.where((produit) {
      if (_searchQuery.value.isNotEmpty) {
        final query = _searchQuery.value.toLowerCase();
        if (!produit.producteur.toLowerCase().contains(query) &&
            !produit.codeContenant.toLowerCase().contains(query) &&
            !produit.village.toLowerCase().contains(query)) {
          return false;
        }
      }
      return true;
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
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Statistiques en haut
          _buildStatsSection(),

          // Barre de recherche
          _buildSearchBar(),

          // Onglets
          _buildTabBar(),

          // Contenu principal
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.science, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Module d\'Extraction',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Traitement des produits bruts',
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withOpacity(0.8)),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.brown[600],
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // Horloge temps réel
        Obx(() => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _currentTime.value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            )),

        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
          tooltip: 'Actualiser',
        ),

        IconButton(
          icon: const Icon(Icons.analytics),
          onPressed: () => _showAdvancedStats(),
          tooltip: 'Statistiques avancées',
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Obx(() => ExtractionStatsWidget(
            stats: _stats,
            isLoading: _isLoading.value,
          )),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher par producteur, code contenant, village...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Obx(() {
            if (_searchQuery.value.isNotEmpty) {
              return IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _searchController.clear(),
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
      child: TabBar(
        controller: _tabController,
        tabs: [
          _buildTab(
              'À Extraire', Icons.inventory, _stats['totalAttribues'] ?? 0),
          _buildTab('En Cours', Icons.play_circle, _stats['enCours'] ?? 0),
          _buildTab('Terminées', Icons.check_circle, _stats['terminees'] ?? 0),
        ],
        labelColor: Colors.brown[600],
        unselectedLabelColor: Colors.grey[600],
        indicator: BoxDecoration(
          color: Colors.brown[50],
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
      ),
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
              color: Colors.brown[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.brown[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Obx(() {
      if (_isLoading.value) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement des données d\'extraction...'),
            ],
          ),
        );
      }

      return TabBarView(
        controller: _tabController,
        children: [
          _buildProduitsList(), // À extraire
          _buildExtractionsEnCoursList(), // En cours
          _buildExtractionsTermineesList(), // Terminées
        ],
      );
    });
  }

  Widget _buildProduitsList() {
    if (_produitsFiltres.isEmpty) {
      return _buildEmptyState(
        'Aucun produit à extraire',
        'Tous les produits attribués ont été traités\nou aucun produit ne correspond à la recherche.',
        Icons.science_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _produitsFiltres.length,
      itemBuilder: (context, index) {
        final produit = _produitsFiltres[index];
        return ExtractionCardImproved(
          produit: produit,
          onDemarrerExtraction: () => _demarrerExtraction(produit),
          onDetails: () => _showProductDetails(produit),
        );
      },
    );
  }

  Widget _buildExtractionsEnCoursList() {
    if (_extractionsEnCours.isEmpty) {
      return _buildEmptyState(
        'Aucune extraction en cours',
        'Toutes les extractions sont terminées\nou suspendues.',
        Icons.play_circle_outline,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _extractionsEnCours.length,
      itemBuilder: (context, index) {
        final extraction = _extractionsEnCours[index];
        return ExtractionProcessCard(
          extraction: extraction,
          onTerminer: () => _terminerExtraction(extraction),
          onSuspendre: () => _suspendreExtraction(extraction),
          onDetails: () => _showExtractionDetails(extraction),
        );
      },
    );
  }

  Widget _buildExtractionsTermineesList() {
    if (_extractionsTerminees.isEmpty) {
      return _buildEmptyState(
        'Aucune extraction terminée',
        'Les extractions terminées apparaîtront ici.',
        Icons.check_circle_outline,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _extractionsTerminees.length,
      itemBuilder: (context, index) {
        final extraction = _extractionsTerminees[index];
        return ExtractionResultCard(
          result: extraction,
          onDetails: () => _showResultDetails(extraction),
          onReprocess: () => _reprocessExtraction(extraction),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
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
              backgroundColor: Colors.brown[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Obx(() {
      if (_selectedTabIndex.value != 0 || _produitsFiltres.isEmpty) {
        return const SizedBox();
      }

      return FloatingActionButton.extended(
        onPressed: _demarrerExtractionGroupee,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Extraction groupée'),
        backgroundColor: Colors.brown[600],
        foregroundColor: Colors.white,
      );
    });
  }

  // Actions sur les produits
  Future<void> _demarrerExtraction(ProductControle produit) async {
    final result = await Get.dialog<bool>(
      StartExtractionModalImproved(
        produit: produit,
        onConfirm: (details) async {
          await _extractionService.demarrerExtraction(
            produit: produit,
            extracteur: details['extracteur'],
            dateDebut: details['dateDebut'],
            instructions: details['instructions'],
          );
        },
      ),
    );

    if (result == true) {
      await _loadData();
      Get.snackbar(
        'Extraction démarrée',
        'Le traitement du produit ${produit.codeContenant} a commencé',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        icon: const Icon(Icons.check_circle, color: Colors.green),
      );
    }
  }

  Future<void> _terminerExtraction(ExtractionProcess extraction) async {
    final result = await Get.dialog<bool>(
      FinishExtractionModalImproved(
        extraction: extraction,
        onConfirm: (details) async {
          await _extractionService.terminerExtraction(
            extraction: extraction,
            poidsExtrait: details['poidsExtrait'],
            qualite: details['qualite'],
            observations: details['observations'],
          );
        },
      ),
    );

    if (result == true) {
      await _loadData();
      Get.snackbar(
        'Extraction terminée',
        'Le produit ${extraction.produit.codeContenant} a été traité avec succès',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        icon: const Icon(Icons.check_circle, color: Colors.green),
      );
    }
  }

  Future<void> _suspendreExtraction(ExtractionProcess extraction) async {
    final result = await Get.dialog<bool>(
      SuspendExtractionModal(
        extraction: extraction,
        onConfirm: (raison) async {
          await _extractionService.suspendreExtraction(
            extraction: extraction,
            raison: raison,
          );
        },
      ),
    );

    if (result == true) {
      await _loadData();
      Get.snackbar(
        'Extraction suspendue',
        'Le traitement du produit ${extraction.produit.codeContenant} a été suspendu',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        icon: const Icon(Icons.pause_circle, color: Colors.orange),
      );
    }
  }

  void _demarrerExtractionGroupee() {
    Get.dialog(
      BatchExtractionModal(
        produits: _produitsFiltres,
        onConfirm: (details) async {
          // Traitement de l'extraction groupée
          await _extractionService.demarrerExtractionGroupee(
            produits: details['produits'],
            extracteur: details['extracteur'],
            instructions: details['instructions'],
          );

          await _loadData();

          Get.snackbar(
            'Extraction groupée démarrée',
            '${details['produits'].length} produits en cours de traitement',
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
            icon: const Icon(Icons.check_circle, color: Colors.green),
          );
        },
      ),
    );
  }

  void _showProductDetails(ProductControle produit) {
    Get.dialog(
      ProductDetailsModal(produit: produit),
    );
  }

  void _showExtractionDetails(ExtractionProcess extraction) {
    Get.dialog(
      ExtractionProcessDetailsModal(extraction: extraction),
    );
  }

  void _showResultDetails(ExtractionResult result) {
    Get.dialog(
      ExtractionResultDetailsModal(result: result),
    );
  }

  void _reprocessExtraction(ExtractionResult result) {
    // TODO: Implémenter le retraitement
    Get.snackbar(
      'Fonctionnalité à venir',
      'Le retraitement sera disponible prochainement',
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
      icon: const Icon(Icons.info, color: Colors.blue),
    );
  }

  void _showAdvancedStats() {
    Get.dialog(
      AdvancedStatsModal(stats: _stats),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _refreshTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }
}
