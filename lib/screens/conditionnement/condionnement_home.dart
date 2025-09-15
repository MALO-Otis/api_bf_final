/// 🎯 PAGE D'ACCUEIL MODERNE DU MODULE CONDITIONNEMENT
///
/// Interface design moderne avec cartes attrayantes et animations fluides
/// pour la gestion des lots filtrés disponibles au conditionnement

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../utils/smart_appbar.dart';
import '../../../authentication/user_session.dart';
import 'conditionnement_models.dart';
import 'services/conditionnement_db_service.dart';
import 'conditionnement_edit.dart';

class ConditionnementHomePage extends StatefulWidget {
  const ConditionnementHomePage({super.key});

  @override
  State<ConditionnementHomePage> createState() =>
      _ConditionnementHomePageState();
}

class _ConditionnementHomePageState extends State<ConditionnementHomePage>
    with TickerProviderStateMixin {
  late ConditionnementDbService _service;
  final UserSession _userSession = Get.find<UserSession>();

  // Animation controllers
  late AnimationController _headerAnimationController;
  late AnimationController _cardAnimationController;
  late AnimationController _fabAnimationController;

  // Animations
  late Animation<double> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _fabRotationAnimation;

  // État de l'application
  bool _showFilters = false;
  String? _selectedSiteFilter;
  String _searchQuery = '';
  List<LotFiltre> _filteredLots = [];
  Map<String, dynamic> _statistics = {};

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeService();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _cardAnimationController.dispose();
    _fabAnimationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Initialise le service
  void _initializeService() {
    _service = Get.put(ConditionnementDbService());
  }

  /// Initialise les animations
  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _headerSlideAnimation = Tween<double>(
      begin: -100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutBack,
    ));

    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeIn,
    ));

    _cardScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.elasticOut,
    ));

    _fabRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  /// Charge les données
  Future<void> _loadData() async {
    try {
      // Recharger les données du service
      await _service.refreshData();

      // Récupérer les statistiques
      _statistics = await _service.getStatistiques();

      _applyFilters();

      // Démarrer les animations
      _headerAnimationController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      _cardAnimationController.forward();
      await Future.delayed(const Duration(milliseconds: 300));
      _fabAnimationController.forward();
    } catch (e) {
      _showErrorSnackbar('Erreur lors du chargement des données: $e');
    }
  }

  /// Applique les filtres de recherche
  void _applyFilters() {
    final allLots = _service.lotsDisponibles;
    _filteredLots = allLots.where((lot) {
      // Filtre de recherche textuelle
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return lot.lotOrigine.toLowerCase().contains(query) ||
            lot.predominanceFlorale.toLowerCase().contains(query) ||
            lot.site.toLowerCase().contains(query) ||
            lot.technicien.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    // Trier par date de filtrage (plus récent en premier)
    _filteredLots.sort((a, b) => b.dateFiltrage.compareTo(a.dateFiltrage));
  }

  /// Gestion de la recherche
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  /// Affiche une snackbar d'erreur
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(theme),
      body: Obx(() => _service.isLoading
          ? _buildLoadingView()
          : _buildMainContent(isMobile)),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Construit l'AppBar moderne
  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return SmartAppBar(
      title: "🧊 Conditionnement",
      backgroundColor: const Color(0xFF2E7D32),
      onBackPressed: () => Get.offAllNamed('/dashboard'),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune),
          onPressed: () => setState(() => _showFilters = !_showFilters),
          tooltip: 'Filtres',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
          tooltip: 'Actualiser',
        ),
      ],
    );
  }

  /// Construit la vue de chargement
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 2),
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, child) {
              return CircularProgressIndicator(
                value: value,
                strokeWidth: 6,
                backgroundColor: Colors.grey.shade300,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Chargement des lots filtrés...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit le contenu principal
  Widget _buildMainContent(bool isMobile) {
    return Column(
      children: [
        // En-tête avec statistiques
        _buildHeaderSection(isMobile),

        // Section des filtres (optionnelle)
        if (_showFilters) _buildFiltersSection(isMobile),

        // Liste des lots
        Expanded(child: _buildLotsGrid(isMobile)),
      ],
    );
  }

  /// Construit la section d'en-tête avec statistiques
  Widget _buildHeaderSection(bool isMobile) {
    return AnimatedBuilder(
      animation: _headerAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _headerSlideAnimation.value),
          child: Opacity(
            opacity: _headerFadeAnimation.value,
            child: Container(
              margin: EdgeInsets.all(isMobile ? 12 : 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  children: [
                    // Titre et recherche
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lots disponibles au conditionnement',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isMobile ? 18 : 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sélectionnez un lot pour démarrer le conditionnement',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: isMobile ? 12 : 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isMobile) _buildSearchBar(),
                      ],
                    ),

                    if (isMobile) ...[
                      const SizedBox(height: 16),
                      _buildSearchBar(),
                    ],

                    const SizedBox(height: 20),

                    // Statistiques
                    _buildStatisticsRow(isMobile),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Construit la barre de recherche
  Widget _buildSearchBar() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Rechercher un lot...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.7)),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  /// Construit la ligne de statistiques
  Widget _buildStatisticsRow(bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Lots disponibles',
            _statistics['lotsDisponibles']?.toString() ?? '0',
            Icons.inventory_2,
            Colors.white,
            isMobile,
          ),
        ),
        SizedBox(width: isMobile ? 8 : 16),
        Expanded(
          child: _buildStatCard(
            'Quantité totale',
            '${(_statistics['quantiteTotaleDisponible'] ?? 0).toStringAsFixed(1)} kg',
            Icons.scale,
            Colors.white,
            isMobile,
          ),
        ),
        SizedBox(width: isMobile ? 8 : 16),
        Expanded(
          child: _buildStatCard(
            'Lots conditionnés',
            _statistics['lotsConditionnes']?.toString() ?? '0',
            Icons.check_circle,
            Colors.white,
            isMobile,
          ),
        ),
      ],
    );
  }

  /// Construit une carte de statistique
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isMobile ? 20 : 24),
          SizedBox(height: isMobile ? 4 : 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: isMobile ? 16 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: color.withOpacity(0.9),
              fontSize: isMobile ? 10 : 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Construit la section des filtres
  Widget _buildFiltersSection(bool isMobile) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _showFilters ? (isMobile ? 80 : 60) : 0,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.filter_list, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            if (_userSession.role == 'admin') ...[
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSiteFilter,
                  decoration: const InputDecoration(
                    labelText: 'Site',
                    border: InputBorder.none,
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: null, child: Text('Tous les sites')),
                    DropdownMenuItem(
                        value: 'Koudougou', child: Text('Koudougou')),
                    DropdownMenuItem(
                        value: 'Ouagadougou', child: Text('Ouagadougou')),
                    DropdownMenuItem(
                        value: 'Bobo-Dioulasso', child: Text('Bobo-Dioulasso')),
                    DropdownMenuItem(value: 'Kaya', child: Text('Kaya')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedSiteFilter = value);
                    _loadData();
                  },
                ),
              ),
            ] else ...[
              Expanded(
                child: Text(
                  'Site: ${_userSession.site}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Construit la grille des lots
  Widget _buildLotsGrid(bool isMobile) {
    if (_filteredLots.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardScaleAnimation.value,
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            itemCount: _filteredLots.length,
            itemBuilder: (context, index) {
              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 50)),
                margin: const EdgeInsets.only(bottom: 16),
                child: _buildLotCard(_filteredLots[index], isMobile, index),
              );
            },
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
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun lot disponible',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Aucun lot ne correspond à votre recherche'
                : 'Tous les lots filtrés ont déjà été conditionnés\nou sont expirés',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une carte de lot
  Widget _buildLotCard(LotFiltre lot, bool isMobile, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0, end: 1),
      builder: (context, animationValue, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - animationValue)),
          child: Opacity(
            opacity: animationValue,
            child: Hero(
              tag: 'lot_${lot.id}',
              child: Card(
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        _getFloralTypeColor(lot.typeFlorale).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête de la carte
                        _buildCardHeader(lot, isMobile),

                        const SizedBox(height: 16),

                        // Informations principales
                        _buildCardMainInfo(lot, isMobile),

                        const SizedBox(height: 16),

                        // Badges et indicateurs
                        _buildCardBadges(lot, isMobile),

                        const SizedBox(height: 20),

                        // Actions
                        _buildCardActions(lot, isMobile),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Construit l'en-tête de la carte
  Widget _buildCardHeader(LotFiltre lot, bool isMobile) {
    return Row(
      children: [
        // Icône du type de florale
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getFloralTypeColor(lot.typeFlorale).withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: _getFloralTypeColor(lot.typeFlorale).withOpacity(0.3),
            ),
          ),
          child: Text(
            ConditionnementUtils.iconesByFlorale[lot.typeFlorale] ?? '🍯',
            style: const TextStyle(fontSize: 24),
          ),
        ),

        const SizedBox(width: 16),

        // Informations de base
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Lot ${lot.lotOrigine}',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (lot.estConditionne)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Text(
                        'Conditionné',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    lot.site,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.person, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      lot.technicien,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    'Filtré le ${DateFormat('dd/MM/yyyy').format(lot.dateFiltrage)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
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

  /// Construit les informations principales de la carte
  Widget _buildCardMainInfo(LotFiltre lot, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoItem(
              'Quantité reçue',
              '${lot.quantiteRecue.toStringAsFixed(1)} kg',
              Icons.scale,
              Colors.blue.shade600,
              isMobile,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 20),
          Expanded(
            child: _buildInfoItem(
              'Reste à conditionner',
              '${lot.quantiteRestante.toStringAsFixed(1)} kg',
              Icons.inventory,
              lot.quantiteRestante > 0
                  ? Colors.orange.shade600
                  : Colors.green.shade600,
              isMobile,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit un élément d'information
  Widget _buildInfoItem(
      String label, String value, IconData icon, Color color, bool isMobile) {
    return Column(
      children: [
        Icon(icon, color: color, size: isMobile ? 20 : 24),
        SizedBox(height: isMobile ? 4 : 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 10 : 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Construit les badges de la carte
  Widget _buildCardBadges(LotFiltre lot, bool isMobile) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Badge du type de florale
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getFloralTypeColor(lot.typeFlorale).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getFloralTypeColor(lot.typeFlorale).withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ConditionnementUtils.iconesByFlorale[lot.typeFlorale] ?? '🍯',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 4),
              Text(
                lot.predominanceFlorale,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getFloralTypeColor(lot.typeFlorale),
                ),
              ),
            ],
          ),
        ),

        // Badge d'urgence si proche de l'expiration
        if (_isDueForConditioning(lot))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time,
                    size: 14, color: Colors.orange.shade700),
                const SizedBox(width: 4),
                Text(
                  'Urgente',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Construit les actions de la carte
  Widget _buildCardActions(LotFiltre lot, bool isMobile) {
    return Row(
      children: [
        // Bouton d'information
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showLotDetails(lot),
            icon: const Icon(Icons.info_outline),
            label: const Text('Détails'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 12 : 16,
                horizontal: isMobile ? 16 : 20,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Bouton de conditionnement
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed:
                lot.peutEtreConditionne ? () => _startConditioning(lot) : null,
            icon: lot.estConditionne
                ? const Icon(Icons.check_circle)
                : const Icon(Icons.precision_manufacturing),
            label: Text(lot.estConditionne ? 'Conditionné' : 'Conditionner'),
            style: ElevatedButton.styleFrom(
              backgroundColor: lot.estConditionne
                  ? Colors.green.shade600
                  : const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade600,
              elevation: lot.peutEtreConditionne ? 4 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 12 : 16,
                horizontal: isMobile ? 16 : 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Construit le bouton d'action flottant
  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _fabAnimationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _fabRotationAnimation.value * 2 * 3.14159,
          child: FloatingActionButton.extended(
            onPressed: () => _showStatisticsDialog(),
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            elevation: 8,
            icon: const Icon(Icons.analytics),
            label: const Text('Statistiques'),
          ),
        );
      },
    );
  }

  /// Obtient la couleur selon le type de florale
  Color _getFloralTypeColor(TypeFlorale type) {
    switch (type) {
      case TypeFlorale.monoFleur:
        return const Color(0xFFFF6B35);
      case TypeFlorale.milleFleurs:
        return const Color(0xFFF7931E);
      case TypeFlorale.mixte:
        return const Color(0xFFFFD23F);
    }
  }

  /// Vérifie si le lot est urgent à conditionner
  bool _isDueForConditioning(LotFiltre lot) {
    final daysSinceFiltering =
        DateTime.now().difference(lot.dateFiltrage).inDays;
    return daysSinceFiltering >= 25; // Urgent si filtré il y a plus de 25 jours
  }

  /// Démarre le conditionnement d'un lot
  void _startConditioning(LotFiltre lot) {
    print('\n🚀🚀🚀 NAVIGATION VERS CONDITIONNEMENT EDIT PAGE ! 🚀🚀🚀');
    print('📍 Depuis: ConditionnementHomePage');
    print(
        '📍 Vers: ConditionnementEditPage (avec améliorations ultra-réactives)');
    print('🎯 Lot sélectionné: ${lot.lotOrigine}');
    print('✅ Navigation en cours...');

    Get.to(
      () => ConditionnementEditPage(lotFiltrageData: lot.toMap()),
      transition: Transition.rightToLeftWithFade,
      duration: const Duration(milliseconds: 300),
    )?.then((_) {
      // Recharger les données après retour
      _loadData();
    });
  }

  /// Affiche les détails d'un lot
  void _showLotDetails(LotFiltre lot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildLotDetailsModal(lot),
    );
  }

  /// Construit le modal des détails du lot
  Widget _buildLotDetailsModal(LotFiltre lot) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // En-tête du modal
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getFloralTypeColor(lot.typeFlorale).withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      ConditionnementUtils.iconesByFlorale[lot.typeFlorale] ??
                          '🍯',
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lot ${lot.lotOrigine}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Détails complets du lot filtré',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Contenu des détails
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailSection('Informations générales', [
                    _buildDetailRow('Lot d\'origine', lot.lotOrigine),
                    _buildDetailRow('Collecte ID', lot.collecteId),
                    _buildDetailRow('Site', lot.site),
                    _buildDetailRow('Technicien', lot.technicien),
                    _buildDetailRow(
                        'Date de filtrage',
                        DateFormat('dd/MM/yyyy à HH:mm')
                            .format(lot.dateFiltrage)),
                  ]),
                  const SizedBox(height: 24),
                  _buildDetailSection('Quantités', [
                    _buildDetailRow('Quantité reçue',
                        '${lot.quantiteRecue.toStringAsFixed(2)} kg'),
                    _buildDetailRow('Quantité restante',
                        '${lot.quantiteRestante.toStringAsFixed(2)} kg'),
                    _buildDetailRow('Pourcentage disponible',
                        '${((lot.quantiteRestante / lot.quantiteRecue) * 100).toStringAsFixed(1)}%'),
                  ]),
                  const SizedBox(height: 24),
                  _buildDetailSection('Caractéristiques', [
                    _buildDetailRow(
                        'Prédominance florale', lot.predominanceFlorale),
                    _buildDetailRow('Type de florale', lot.typeFlorale.label),
                    _buildDetailRow('Statut',
                        lot.estConditionne ? 'Conditionné' : 'Disponible'),
                    if (lot.dateConditionnement != null)
                      _buildDetailRow(
                          'Date conditionnement',
                          DateFormat('dd/MM/yyyy')
                              .format(lot.dateConditionnement!)),
                  ]),
                  const SizedBox(height: 24),
                  _buildDetailSection('État du filtrage', [
                    _buildDetailRow('Peut être conditionné',
                        lot.peutEtreConditionne ? 'Oui' : 'Non'),
                    _buildDetailRow(
                        'Filtrage expiré', lot.filtrageExpire ? 'Oui' : 'Non'),
                    _buildDetailRow('Jours depuis filtrage',
                        '${DateTime.now().difference(lot.dateFiltrage).inDays} jours'),
                  ]),
                ],
              ),
            ),
          ),

          // Actions du modal
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'),
                  ),
                ),
                const SizedBox(width: 12),
                if (lot.peutEtreConditionne) ...[
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _startConditioning(lot);
                      },
                      icon: const Icon(Icons.precision_manufacturing),
                      label: const Text('Conditionner'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une section de détails
  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  /// Construit une ligne de détail
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const Text(' : '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche le dialogue des statistiques
  void _showStatisticsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques du conditionnement'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatisticRow('Lots disponibles',
                  _statistics['lotsDisponibles']?.toString() ?? '0'),
              _buildStatisticRow('Lots conditionnés',
                  _statistics['lotsConditionnes']?.toString() ?? '0'),
              _buildStatisticRow('Quantité totale disponible',
                  '${(_statistics['quantiteTotaleDisponible'] ?? 0).toStringAsFixed(1)} kg'),
              _buildStatisticRow('Quantité totale conditionnée',
                  '${(_statistics['quantiteTotaleConditionnee'] ?? 0).toStringAsFixed(1)} kg'),
              _buildStatisticRow(
                  'Valeur totale conditionnée',
                  ConditionnementUtils.formatPrix(
                      _statistics['valeurTotaleConditionnee'] ?? 0)),
              _buildStatisticRow('Nombre total de pots',
                  _statistics['nombreTotalPots']?.toString() ?? '0'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// Construit une ligne de statistique
  Widget _buildStatisticRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
