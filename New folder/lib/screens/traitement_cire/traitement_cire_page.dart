import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import '../controle_de_donnes/models/attribution_models_v2.dart';
import '../attribution/services/attribution_page_service.dart';
import 'models/cire_models_improved.dart';
import 'services/cire_traitement_service_improved.dart';
// TODO: Create these widget files when needed
// import 'widgets/cire_card_improved.dart';
// import 'widgets/cire_stats_widget.dart';
// import 'widgets/cire_modals_improved.dart';

/// 🟤 PAGE DE TRAITEMENT DE CIRE - NOUVELLE GÉNÉRATION
///
/// Cette page de traitement de cire révolutionnée s'intègre parfaitement avec
/// le nouveau système d'attribution unifié pour offrir :
///
/// ✨ FONCTIONNALITÉS AVANCÉES :
/// - Réception automatique des produits cire attribués
/// - Interface moderne et responsive
/// - Processus de traitement guidé (purification, moulage, conditionnement)
/// - Suivi en temps réel des traitements
/// - Gestion intelligente de la qualité
/// - Calculs automatiques de rendement
/// - Historique complet et traçabilité
/// - Gestion des différents types de cire
class TraitementCirePage extends StatefulWidget {
  const TraitementCirePage({Key? key}) : super(key: key);

  @override
  State<TraitementCirePage> createState() => _TraitementCirePageState();
}

class _TraitementCirePageState extends State<TraitementCirePage>
    with TickerProviderStateMixin {
  // Services
  late final CireTraitementServiceImproved _cireService;
  late final AttributionPageService _attributionService;

  // Controllers
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // State
  final RxBool _isLoading = true.obs;
  final RxList<ProductControle> _produitsAttribues = <ProductControle>[].obs;
  final RxList<ProductControle> _produitsFiltres = <ProductControle>[].obs;
  final RxList<CireTraitementProcess> _traitementsEnCours =
      <CireTraitementProcess>[].obs;
  final RxList<CireTraitementResult> _traitementsTermines =
      <CireTraitementResult>[].obs;
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
    _cireService = CireTraitementServiceImproved();
    _attributionService = AttributionPageService();
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

      // Charger les produits cire attribués
      final produitsAttribues = await _cireService.getProduitsAttribuesCire();
      _produitsAttribues.assignAll(produitsAttribues);

      // Charger les traitements en cours
      final traitementsEnCours = await _cireService.getTraitementsEnCours();
      _traitementsEnCours.assignAll(traitementsEnCours);

      // Charger les traitements terminés
      final traitementsTermines = await _cireService.getTraitementsTermines();
      _traitementsTermines.assignAll(traitementsTermines);

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
      'enCours': _traitementsEnCours.length,
      'termines': _traitementsTermines.length,
      'poidsTotal':
          _produitsAttribues.fold(0.0, (sum, p) => sum + p.poidsTotal),
      'rendementMoyen': _traitementsTermines.isEmpty
          ? 0.0
          : _traitementsTermines.fold(0.0, (sum, t) => sum + t.rendement) /
              _traitementsTermines.length,
      'dureeMoyenne': _traitementsTermines.isEmpty
          ? 0
          : _traitementsTermines.fold(0, (sum, t) => sum + t.duree.inMinutes) ~/
              _traitementsTermines.length,
      'urgents': _produitsAttribues.where((p) => p.isUrgent).length,
      'qualiteExcellente': _traitementsTermines
          .where((t) => t.qualiteFinale == 'Excellent')
          .length,
      'typesTraitement':
          _traitementsTermines.fold<Map<String, int>>({}, (map, t) {
        map[t.typeTraitement] = (map[t.typeTraitement] ?? 0) + 1;
        return map;
      }),
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
            child: const Icon(Icons.spa, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Traitement de Cire',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Purification et transformation',
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withOpacity(0.8)),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.amber[700],
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
      child: Obx(() => _buildStatsCards()),
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
          suffixIcon: Obx(() => _searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchQuery.value = '';
                  },
                )
              : const SizedBox.shrink()),
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
              'À Traiter', Icons.spa_outlined, _stats['totalAttribues'] ?? 0),
          _buildTab('En Cours', Icons.autorenew, _stats['enCours'] ?? 0),
          _buildTab('Terminés', Icons.done_all, _stats['termines'] ?? 0),
        ],
        labelColor: Colors.amber[700],
        unselectedLabelColor: Colors.grey[600],
        indicator: BoxDecoration(
          color: Colors.amber[50],
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
              color: Colors.amber[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.amber[800],
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
              Text('Chargement des données de traitement...'),
            ],
          ),
        );
      }

      return TabBarView(
        controller: _tabController,
        children: [
          _buildProduitsList(), // À traiter
          _buildTraitementsEnCoursList(), // En cours
          _buildTraitementsTerminesList(), // Terminés
        ],
      );
    });
  }

  Widget _buildProduitsList() {
    if (_produitsFiltres.isEmpty) {
      return _buildEmptyState(
        'Aucun produit à traiter',
        'Tous les produits cire attribués ont été traités\nou aucun produit ne correspond à la recherche.',
        Icons.spa_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _produitsFiltres.length,
      itemBuilder: (context, index) {
        final produit = _produitsFiltres[index];
        return CireCardImproved(
          produit: produit,
          onDemarrerTraitement: () => _demarrerTraitement(produit),
          onDetails: () => _showProductDetails(produit),
        );
      },
    );
  }

  Widget _buildTraitementsEnCoursList() {
    if (_traitementsEnCours.isEmpty) {
      return _buildEmptyState(
        'Aucun traitement en cours',
        'Tous les traitements sont terminés\nou suspendus.',
        Icons.autorenew,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _traitementsEnCours.length,
      itemBuilder: (context, index) {
        final traitement = _traitementsEnCours[index];
        return CireTraitementProcessCard(
          traitement: traitement,
          onFinish: () => _terminerTraitement(traitement),
          onSuspend: () => _suspendreTraitement(traitement),
          onViewDetails: () => _showTraitementDetails(traitement),
        );
      },
    );
  }

  Widget _buildTraitementsTerminesList() {
    if (_traitementsTermines.isEmpty) {
      return _buildEmptyState(
        'Aucun traitement terminé',
        'Les traitements terminés apparaîtront ici.',
        Icons.done_all,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _traitementsTermines.length,
      itemBuilder: (context, index) {
        final traitement = _traitementsTermines[index];
        return CireTraitementResultCard(
          result: traitement,
          onViewDetails: () => _showResultDetails(traitement),
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
              backgroundColor: Colors.amber[700],
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
        onPressed: _demarrerTraitementGroupe,
        icon: const Icon(Icons.batch_prediction),
        label: const Text('Traitement groupé'),
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
      );
    });
  }

  // Actions sur les produits
  Future<void> _demarrerTraitement(ProductControle produit) async {
    final result = await Get.dialog<bool>(
      StartCireTraitementModalImproved(
        produit: produit,
        onStart: (details) async {
          await _cireService.demarrerTraitement(
            produit: produit,
            operateur: details['operateur'],
            typeTraitement: details['typeTraitement'],
            dateDebut: details['dateDebut'],
            parametres: details['parametres'],
            instructions: details['instructions'],
          );
        },
      ),
    );

    if (result == true) {
      await _loadData();
      Get.snackbar(
        'Traitement démarré',
        'Le traitement du produit ${produit.codeContenant} a commencé',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        icon: const Icon(Icons.check_circle, color: Colors.green),
      );
    }
  }

  Future<void> _terminerTraitement(CireTraitementProcess traitement) async {
    final result = await Get.dialog<bool>(
      FinishCireTraitementModalImproved(
        traitement: traitement,
        onFinish: (details) async {
          await _cireService.terminerTraitement(
            traitement: traitement,
            poidsTraite: details['poidsTraite'],
            qualiteFinale: details['qualiteFinale'],
            couleur: details['couleur'],
            texture: details['texture'],
            observations: details['observations'],
          );
        },
      ),
    );

    if (result == true) {
      await _loadData();
      Get.snackbar(
        'Traitement terminé',
        'Le produit ${traitement.produit.codeContenant} a été traité avec succès',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        icon: const Icon(Icons.check_circle, color: Colors.green),
      );
    }
  }

  Future<void> _suspendreTraitement(CireTraitementProcess traitement) async {
    final result = await Get.dialog<bool>(
      SuspendCireTraitementModal(
        traitement: traitement,
        onSuspend: (raison) async {
          await _cireService.suspendreTraitement(
            traitement: traitement,
            raison: raison,
          );
        },
      ),
    );

    if (result == true) {
      await _loadData();
      Get.snackbar(
        'Traitement suspendu',
        'Le traitement du produit ${traitement.produit.codeContenant} a été suspendu',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        icon: const Icon(Icons.pause_circle, color: Colors.orange),
      );
    }
  }

  void _demarrerTraitementGroupe() {
    Get.dialog(
      BatchCireTraitementModal(
        produits: _produitsFiltres,
        onBatchStart: (details) async {
          // Traitement du traitement groupé
          await _cireService.demarrerTraitementGroupe(
            produits: details['produits'],
            operateur: details['operateur'],
            typeTraitement: details['typeTraitement'],
            parametres: details['parametres'],
            instructions: details['instructions'],
          );

          await _loadData();

          Get.snackbar(
            'Traitement groupé démarré',
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

  void _showTraitementDetails(CireTraitementProcess traitement) {
    Get.dialog(
      CireTraitementProcessDetailsModal(traitement: traitement),
    );
  }

  void _showResultDetails(CireTraitementResult result) {
    Get.dialog(
      CireTraitementResultDetailsModal(result: result),
    );
  }

  void _retraiterCire(CireTraitementResult result) {
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
      AdvancedCireStatsModal(stats: _stats),
    );
  }

  @override

  // Missing widget methods - TODO: implement properly
  Widget _buildStatsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          '${_stats['totalAttribues'] ?? 0}',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const Text('Total Attribués'),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          '${_stats['enCours'] ?? 0}',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const Text('En Cours'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget CireCardImproved({
    required ProductControle produit,
    required VoidCallback onDemarrerTraitement,
    required VoidCallback onDetails,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text('Produit ${produit.id}'),
        subtitle: Text('Poids: ${produit.poidsTotal}kg'),
        trailing: ElevatedButton(
          onPressed: onDemarrerTraitement,
          child: const Text('Démarrer'),
        ),
        onTap: onDetails,
      ),
    );
  }

  Widget CireTraitementProcessCard({
    required CireTraitementProcess traitement,
    required VoidCallback onFinish,
    required VoidCallback onSuspend,
    required VoidCallback onViewDetails,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text('Traitement ${traitement.id}'),
        subtitle: Text('En cours...'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: onFinish,
              child: const Text('Terminer'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onSuspend,
              child: const Text('Suspendre'),
            ),
          ],
        ),
        onTap: onViewDetails,
      ),
    );
  }

  Widget CireTraitementResultCard({
    required CireTraitementResult result,
    required VoidCallback onViewDetails,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text('Résultat ${result.id}'),
        subtitle: Text('Qualité: ${result.qualiteFinale}'),
        trailing: const Icon(Icons.check_circle, color: Colors.green),
        onTap: onViewDetails,
      ),
    );
  }

  Widget StartCireTraitementModalImproved({
    required ProductControle produit,
    required Function(Map<String, dynamic>) onStart,
  }) {
    return AlertDialog(
      title: const Text('Démarrer le traitement'),
      content: Text('Démarrer le traitement pour le produit ${produit.id}?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            onStart({});
            Navigator.of(context).pop();
          },
          child: const Text('Démarrer'),
        ),
      ],
    );
  }

  Widget FinishCireTraitementModalImproved({
    required CireTraitementProcess traitement,
    required Function(Map<String, dynamic>) onFinish,
  }) {
    return AlertDialog(
      title: const Text('Terminer le traitement'),
      content: Text('Terminer le traitement ${traitement.id}?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            onFinish({});
            Navigator.of(context).pop();
          },
          child: const Text('Terminer'),
        ),
      ],
    );
  }

  Widget SuspendCireTraitementModal({
    required CireTraitementProcess traitement,
    required Function(String) onSuspend,
  }) {
    return AlertDialog(
      title: const Text('Suspendre le traitement'),
      content: Text('Suspendre le traitement ${traitement.id}?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            onSuspend('Suspendu par l\'utilisateur');
            Navigator.of(context).pop();
          },
          child: const Text('Suspendre'),
        ),
      ],
    );
  }

  Widget BatchCireTraitementModal({
    required List<ProductControle> produits,
    required Function(Map<String, dynamic>) onBatchStart,
  }) {
    return AlertDialog(
      title: const Text('Traitement groupé'),
      content: Text('Démarrer le traitement pour ${produits.length} produits?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            onBatchStart({});
            Navigator.of(context).pop();
          },
          child: const Text('Démarrer'),
        ),
      ],
    );
  }

  Widget ProductDetailsModal({required ProductControle produit}) {
    return AlertDialog(
      title: Text('Détails du produit ${produit.id}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ID: ${produit.id}'),
          Text('Poids: ${produit.poidsTotal}kg'),
          Text('Date: ${produit.dateCollecte}'),
          Text('Contrôleur: ${produit.controleur}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Widget CireTraitementProcessDetailsModal(
      {required CireTraitementProcess traitement}) {
    return AlertDialog(
      title: Text('Détails du traitement ${traitement.id}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ID: ${traitement.id}'),
          Text('Status: ${traitement.statut.label}'),
          Text('Début: ${traitement.dateDebut}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Widget CireTraitementResultDetailsModal(
      {required CireTraitementResult result}) {
    return AlertDialog(
      title: Text('Détails du résultat ${result.id}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ID: ${result.id}'),
          Text('Qualité: ${result.qualiteFinale}'),
          Text('Rendement: ${result.rendement}%'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Widget AdvancedCireStatsModal({required Map<String, dynamic> stats}) {
    return AlertDialog(
      title: const Text('Statistiques avancées'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total: ${stats['totalAttribues'] ?? 0}'),
          Text('En cours: ${stats['enCours'] ?? 0}'),
          Text('Terminés: ${stats['termines'] ?? 0}'),
          Text('Poids total: ${stats['poidsTotal'] ?? 0}kg'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
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
