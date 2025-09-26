import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/commercial_models.dart';
import '../widgets/attributions_tab.dart';
import '../widgets/admin_panel_widget.dart';
import '../services/commercial_service.dart';
import '../widgets/statistiques_simple.dart';
import '../widgets/lots_disponibles_tab.dart';
import '../widgets/gestion_commerciaux_tab.dart';

/// 🏪 NOUVELLE GESTION COMMERCIALE ULTRA-MODERNE
///
/// Interface complète avec gestion intelligente des lots, attributions et statistiques
/// Design responsive, chargement ultra-rapide et UX optimisée

class NouvelleGestionCommerciale extends StatefulWidget {
  const NouvelleGestionCommerciale({super.key});

  @override
  State<NouvelleGestionCommerciale> createState() =>
      _NouvelleGestionCommercialeState();
}

class _NouvelleGestionCommercialeState extends State<NouvelleGestionCommerciale>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final CommercialService _commercialService = Get.put(CommercialService());

  // État de l'interface
  final RxInt _currentTabIndex = 0.obs;
  final RxBool _isLoading = true.obs;
  final RxString _searchText = ''.obs;

  // Compteurs pour badges
  final RxInt _nombreLots = 0.obs;
  final RxInt _nombreAttributions = 0.obs;
  final RxDouble _valeurTotale = 0.0.obs;
  // Versionnement pour forcer le rebuild des onglets après MAJ (ex: attribution)
  final RxInt _tabsVersion = 0.obs;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    // Éviter les mises à jour d'Obx pendant le premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    // Pour éviter les décalages et mismatches, on fixe à 5 onglets
    // et on affiche une vue "Accès restreint" si non admin.
    _tabController = TabController(length: 5, vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutQuart),
    );

    // Écouter les changements d'onglet
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _currentTabIndex.value = _tabController.index;
        _onTabChanged(_tabController.index);
      }
    });

    _fadeController.forward();
  }

  Future<void> _loadInitialData() async {
    try {
      _isLoading.value = true;
      // On ne force qu'une seule fois les lots; les stats utilisent TTL interne
      await _commercialService.getLotsAvecCache(forceRefresh: true);
      await _commercialService.calculerStatistiques(forceRefresh: false);

      // Mettre à jour les compteurs
      _updateCounters();
    } catch (e) {
      debugPrint(
          '❌ [NouvelleGestionCommerciale] Erreur chargement initial: $e');
      _showErrorSnackbar(
          'Erreur de chargement', 'Impossible de charger les données');
    } finally {
      _isLoading.value = false;
    }
  }

  void _updateCounters() async {
    debugPrint(
        '🔄 [NouvelleGestionCommerciale] Mise à jour des compteurs et rechargement des données');

    try {
      // Rafraîchir toutes les données pour propager aux autres onglets
      await _commercialService.rafraichirToutesLesDonnees();

      // Mettre à jour les compteurs avec les nouvelles données
      final lots = _commercialService.lots;
      final attributions = _commercialService.attributions;

      _nombreLots.value = lots.where((lot) => lot.quantiteRestante > 0).length;
      _nombreAttributions.value = attributions.length;
      _valeurTotale.value =
          lots.fold(0.0, (sum, lot) => sum + lot.valeurRestante);

      debugPrint(
          '✅ [NouvelleGestionCommerciale] Compteurs mis à jour: ${_nombreLots.value} lots, ${_nombreAttributions.value} attributions');
      // Forcer un rebuild des onglets pour refléter les nouvelles données
      _tabsVersion.value++;
    } catch (e) {
      debugPrint(
          '❌ [NouvelleGestionCommerciale] Erreur lors de la mise à jour: $e');

      // Fallback : utiliser les données en cache
      final lots = _commercialService.lots;
      final attributions = _commercialService.attributions;

      _nombreLots.value = lots.where((lot) => lot.quantiteRestante > 0).length;
      _nombreAttributions.value = attributions.length;
      _valeurTotale.value =
          lots.fold(0.0, (sum, lot) => sum + lot.valeurRestante);
      // Même en fallback, on force un léger rebuild pour synchroniser l'affichage
      _tabsVersion.value++;
    }
  }

  void _onTabChanged(int index) {
    // Logique spécifique selon l'onglet sélectionné
    switch (index) {
      case 0: // Produits disponibles
        debugPrint(
            '📦 [NouvelleGestionCommerciale] Onglet Produits sélectionné');
        break;
      case 1: // Attributions
        debugPrint(
            '🎯 [NouvelleGestionCommerciale] Onglet Attributions sélectionné');
        break;
      case 2: // Statistiques
        debugPrint(
            '📊 [NouvelleGestionCommerciale] Onglet Statistiques sélectionné');
        break;
    }
  }

  Future<void> _onRefresh() async {
    debugPrint('🔄 [NouvelleGestionCommerciale] Rafraîchissement manuel...');

    _isLoading.value = true;
    try {
      await _commercialService.rafraichirToutesLesDonnees();
      _updateCounters();
      _showSuccessSnackbar('✅ Données actualisées',
          'Toutes les informations ont été mises à jour');
    } catch (e) {
      _showErrorSnackbar('Erreur de rafraîchissement',
          'Impossible de mettre à jour les données');
    } finally {
      _isLoading.value = false;
    }
  }

  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: const Color(0xFF4CAF50),
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: const Color(0xFF263238),
      colorText: Colors.white,
      icon: const Icon(Icons.error, color: Colors.white),
      duration: const Duration(seconds: 4),
      snackPosition: SnackPosition.TOP,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildSmartAppBar(context),
      body: Obx(() => _isLoading.value
          ? _buildLoadingView(context)
          : _buildMainContent(context)),
    );
  }

  PreferredSizeWidget _buildSmartAppBar(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return AppBar(
      backgroundColor: const Color(0xFF1976D2),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Gestion Commerciale',
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!isMobile)
            Text(
              'Module optimisé pour les performances',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
        ],
      ),
      actions: [
        // Bouton de recherche
        if (!isMobile)
          SizedBox(
            width: 200,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: TextField(
                onChanged: (value) => _searchText.value = value,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  prefixIcon:
                      Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
          ),

        // Bouton de rafraîchissement
        Obx(() => IconButton(
              icon: _isLoading.value
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh, color: Colors.white),
              onPressed: _isLoading.value ? null : _onRefresh,
              tooltip: 'Actualiser',
            )),
        IconButton(
          icon: const Icon(Icons.speed, color: Colors.white),
          tooltip: 'Diagnostics lots',
          onPressed: () {
            final age = _commercialService.ageCacheLots;
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Diagnostics Lots'),
                content: Obx(() {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lots cache: ${_commercialService.lots.length}'),
                      Text(
                          'Âge cache: ${age == null ? '—' : '${age.inSeconds}s'}'),
                      Text(
                          'Stats builds: ${_commercialService.statistiquesComputations}'),
                      Text(
                          'Requêtes lots: ${_commercialService.fetchLotsCount}'),
                      Text(
                          'Requêtes attributions: ${_commercialService.attributionsFetchCount}'),
                    ],
                  );
                }),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fermer'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      _isLoading.value = true;
                      await _commercialService.getLotsAvecCache(
                          forceRefresh: true);
                      await _commercialService.calculerStatistiques(
                          forceRefresh: true);
                      _isLoading.value = false;
                      _updateCounters();
                    },
                    child: const Text('Force Refresh'),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(width: 8),
      ],
      bottom: _buildTabBar(context),
    );
  }

  PreferredSizeWidget _buildTabBar(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return TabBar(
      controller: _tabController,
      isScrollable: true,
      indicatorColor: Colors.white,
      indicatorWeight: 3,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white.withOpacity(0.7),
      labelStyle: TextStyle(
        fontSize: isMobile ? 12 : 14,
        fontWeight: FontWeight.w600,
      ),
      tabs: [
        // Onglet Produits Disponibles
        Obx(() => Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inventory_2, size: 18),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(isMobile ? 'Produits' : 'Produits Disponibles'),
                      if (!isMobile && _nombreLots.value > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_nombreLots.value}',
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            )),

        // Onglet Attributions
        Obx(() => Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.assignment, size: 18),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Attributions'),
                      if (!isMobile && _nombreAttributions.value > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_nombreAttributions.value}',
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            )),

        // Onglet Statistiques
        Obx(() => Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.analytics, size: 18),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Statistiques'),
                      if (!isMobile && _valeurTotale.value > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9C27B0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${(_valeurTotale.value / 1000000).toStringAsFixed(1)}M',
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            )),

        // Onglet Gestion Commerciaux
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.group, size: 18),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(isMobile ? 'Équipe' : 'Commerciaux'),
                ],
              ),
            ],
          ),
        ),

        // Onglet Administration (toujours présent pour garder la cohérence)
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _commercialService.estAdmin
                    ? Icons.admin_panel_settings
                    : Icons.lock_outline,
                size: 18,
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(isMobile ? 'Admin' : 'Administration'),
                  if (!_commercialService.estAdmin && !isMobile)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Restreint',
                        style:
                            TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingView(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Chargement des données commerciales...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Optimisation des performances en cours',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 24),
                // Indicateur de progression stylisé
                Container(
                  width: 200,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFF1976D2)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Obx(() {
            // Utiliser NestedScrollView pour rendre le header (métriques) scrollable avec le contenu
            final version = _tabsVersion.value; // déclenche le rebuild
            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(child: _buildQuickMetrics(context)),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  // Onglet 1: Produits disponibles
                  KeyedSubtree(
                    key: ValueKey('tab-produits-v$version'),
                    child: LotsDisponiblesTab(
                      commercialService: _commercialService,
                      searchText: _searchText,
                      onLotsUpdated: _updateCounters,
                    ),
                  ),

                  // Onglet 2: Attributions
                  KeyedSubtree(
                    key: ValueKey('tab-attributions-v$version'),
                    child: AttributionsTab(
                      commercialService: _commercialService,
                      searchText: _searchText,
                      onAttributionsUpdated: _updateCounters,
                    ),
                  ),

                  // Onglet 3: Statistiques
                  KeyedSubtree(
                    key: ValueKey('tab-stats-v$version'),
                    child: StatistiquesSimple(
                      commercialService: _commercialService,
                    ),
                  ),

                  // Onglet 4: Gestion des commerciaux
                  KeyedSubtree(
                    key: ValueKey('tab-commerciaux-v$version'),
                    child: GestionCommerciauxTab(
                      commercialService: _commercialService,
                    ),
                  ),

                  // Onglet 5: Administration ou Accès restreint
                  KeyedSubtree(
                    key: ValueKey('tab-admin-v$version'),
                    child: _commercialService.estAdmin
                        ? AdminPanelWidget(
                            commercialService: _commercialService,
                          )
                        : _buildRestrictedAdminView(context),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildRestrictedAdminView(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Accès restreint',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Supprimé: l'ancien wrapper _buildTabWithHeader n'est plus utilisé

  Widget _buildQuickMetrics(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Obx(() {
        if (isMobile) {
          return Column(
            children: [
              _buildQuickMetricItem(
                icon: Icons.inventory_2,
                label: 'Lots Disponibles',
                value: '${_nombreLots.value}',
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickMetricItem(
                      icon: Icons.assignment,
                      label: 'Attributions',
                      value: '${_nombreAttributions.value}',
                      color: Colors.white,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickMetricItem(
                      icon: Icons.monetization_on,
                      label: 'Valeur Stock',
                      value:
                          '${(_valeurTotale.value / 1000000).toStringAsFixed(1)}M',
                      color: Colors.white,
                      compact: true,
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(
                child: _buildQuickMetricItem(
                  icon: Icons.inventory_2,
                  label: 'Lots Disponibles',
                  value: '${_nombreLots.value}',
                  subtitle: 'Produits en stock',
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildQuickMetricItem(
                  icon: Icons.assignment,
                  label: 'Attributions',
                  value: '${_nombreAttributions.value}',
                  subtitle: 'En cours',
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildQuickMetricItem(
                  icon: Icons.monetization_on,
                  label: 'Valeur Stock',
                  value: CommercialUtils.formatPrix(_valeurTotale.value),
                  subtitle: 'Disponible',
                  color: Colors.white,
                ),
              ),
            ],
          );
        }
      }),
    );
  }

  Widget _buildQuickMetricItem({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    required Color color,
    bool compact = false,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(compact ? 8 : 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: compact ? 20 : 24,
          ),
        ),
        SizedBox(width: compact ? 8 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: compact ? 16 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: color.withOpacity(0.9),
                  fontSize: compact ? 11 : 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null && !compact)
                Text(
                  subtitle,
                  style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
