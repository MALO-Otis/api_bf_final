import 'dart:async';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'widgets/extraction_card.dart';
import 'package:flutter/material.dart';
import 'models/extraction_models.dart';
import 'widgets/extraction_modals.dart';
import 'services/extraction_service.dart';
import 'widgets/control_attribution_stats_widget.dart';
import '../attribution/attribution_page_complete.dart';
/* 
🚫 ANCIEN FICHIER D'EXTRACTION - DÉSACTIVÉ
Ce fichier utilise l'ancien système et n'est plus utilisé.
La nouvelle interface est dans pages/attributed_products_page.dart
qui récupère les données depuis attribution_reçu




/// Page principale d'extraction de données
class ExtractionPage extends StatefulWidget {
  const ExtractionPage({super.key});

  @override
  State<ExtractionPage> createState() => _ExtractionPageState();
}

class _ExtractionPageState extends State<ExtractionPage>
    with TickerProviderStateMixin {
  final ExtractionService _service = ExtractionService();

  // État de l'application
  List<ExtractionProduct> _allProducts = [];
  List<ExtractionProduct> _filteredProducts = [];
  ExtractionFilters _filters = ExtractionFilters();
  bool _isLoading = true;
  int _notifications = 3;

  // Contrôleurs d'animation
  late AnimationController _headerGlowController;
  late AnimationController _counterController;
  late Animation<double> _counterAnimation;

  // Contrôleur de tabs
  late TabController _tabController;

  // Contrôleurs de texte
  final TextEditingController _searchController = TextEditingController();

  // État des modales - variables supprimées car gérées directement dans showDialog

  // Timer pour l'horloge temps réel
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeTabs();
    _loadData();
    _startClock();
    _simulateNotifications();
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

  /// Initialise les animations
  void _initializeAnimations() {
    _headerGlowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _counterController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _counterAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _counterController,
      curve: Curves.easeOutCubic,
    ));
  }

  /// Initialise les tabs
  void _initializeTabs() {
    _tabController = TabController(
      length: 2, // Ancienne interface + Nouveaux produits attribués
      vsync: this,
    );
  }

  /// Charge les données depuis le module contrôle et les données mock
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Écouter les produits en temps réel depuis le module contrôle
    _service.getAllProductsStream().listen((products) {
      if (mounted) {
        setState(() {
          _allProducts = products;
          _applyFilters();
          _isLoading = false;
        });
        _counterController.forward();
      }
    });
  }

  /// Démarre l'horloge temps réel
  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _currentTime = DateTime.now());
    });
  }

  /// Simule les notifications en temps réel
  void _simulateNotifications() {
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _notifications += 2);
        _showToast('Nouvelle attribution', '2 nouveaux produits à traiter');
      }
    });
  }

  /// Applique les filtres
  void _applyFilters() {
    _filteredProducts = _service.filterProducts(_allProducts, _filters);
  }

  /// Met à jour les filtres
  void _updateFilters(ExtractionFilters newFilters) {
    setState(() {
      _filters = newFilters;
      _applyFilters();
    });
  }

  /// Réinitialise les filtres
  void _resetFilters() {
    _searchController.clear();
    _updateFilters(ExtractionFilters());
  }

  /// Affiche un toast
  void _showToast(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(message, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Ouvre la page d'attribution
  void _openAttributionPage() {
    Get.to(() => const AttributionPageComplete());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: _isLoading
          ? _buildLoadingView()
          : isMobile
              ? _buildMobileLayout(theme)
              : _buildDesktopLayout(theme, isTablet),
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
              heroTag: 'fab-extraction-open-attribution',
              onPressed: _openAttributionPage,
              icon: const Icon(Icons.assignment),
              label: const Text('Attributions'),
              backgroundColor: Colors.blue.shade600,
            )
          : null,
    );
  }

  /// Vue de chargement
  Widget _buildLoadingView() {
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

  /// Layout mobile avec CustomScrollView
  Widget _buildMobileLayout(ThemeData theme) {
    return CustomScrollView(
      slivers: [
        // Header mobile
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildHeader(theme, true),
          ),
        ),

        // Statistiques des attributions du module contrôle
        const SliverToBoxAdapter(
          child: ControlAttributionStatsWidget(),
        ),

        // Stats dashboard
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildStatsDashboard(theme, true),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Filtres mobile
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildFiltersBar(theme, true),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Liste des produits
        _buildProductsList(theme, true),
      ],
    );
  }

  /// Layout desktop/tablette
  Widget _buildDesktopLayout(ThemeData theme, bool isTablet) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(theme, false),

          const SizedBox(height: 24),

          // Statistiques des attributions du module contrôle
          const ControlAttributionStatsWidget(),

          const SizedBox(height: 24),

          // Stats dashboard
          _buildStatsDashboard(theme, false),

          const SizedBox(height: 24),

          // Filtres
          _buildFiltersBar(theme, false),

          const SizedBox(height: 24),

          // Liste des produits - sans hauteur fixe pour laisser les cards s'étendre
          _filteredProducts.isEmpty
              ? _buildEmptyState(theme)
              : _buildProductsWrap(theme, isTablet),
        ],
      ),
    );
  }

  /// Header avec effet de glow et horloge temps réel
  Widget _buildHeader(ThemeData theme, bool isMobile) {
    return AnimatedBuilder(
      animation: _headerGlowController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2)),
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 2.0,
              colors: [
                theme.colorScheme.primary
                    .withValues(alpha: 0.1 * _headerGlowController.value),
                Colors.transparent,
              ],
            ),
          ),
          child: Card(
            elevation: 2,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: isMobile
                  ? _buildMobileHeader(theme)
                  : _buildDesktopHeader(theme),
            ),
          ),
        );
      },
    );
  }

  /// Header mobile
  Widget _buildMobileHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre et icône
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.science,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Extraction de Données',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Gestion des produits attribués',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Informations utilisateur et notifications
        Row(
          children: [
            // Temps réel
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Temps réel',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(_currentTime),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Notifications
            Stack(
              children: [
                IconButton(
                  onPressed: () =>
                      _showToast('Notifications', '$_notifications nouvelles'),
                  icon: const Icon(Icons.notifications_outlined),
                ),
                if (_notifications > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 20, minHeight: 20),
                      child: Text(
                        '$_notifications',
                        style: TextStyle(
                          color: theme.colorScheme.onError,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 8),

            // Avatar utilisateur
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    'JD',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connecté',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Jean Dupont',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Header desktop
  Widget _buildDesktopHeader(ThemeData theme) {
    return Row(
      children: [
        // Titre et description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.science,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Extraction de Données',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Gestion des produits attribués pour extraction',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Informations temps réel et utilisateur
        Row(
          children: [
            // Temps réel
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Temps réel',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(_currentTime),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Bouton Attributions
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.purple.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: _openAttributionPage,
                icon: const Icon(Icons.assignment, size: 18),
                label: const Text('Attributions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Notifications
            Stack(
              children: [
                IconButton(
                  onPressed: () =>
                      _showToast('Notifications', '$_notifications nouvelles'),
                  icon: const Icon(Icons.notifications_outlined),
                ),
                if (_notifications > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 20, minHeight: 20),
                      child: Text(
                        '$_notifications',
                        style: TextStyle(
                          color: theme.colorScheme.onError,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 16),

            // Avatar utilisateur
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Connecté',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Jean Dupont',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    'JD',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Dashboard de statistiques avec animations
  Widget _buildStatsDashboard(ThemeData theme, bool isMobile) {
    final stats = _service.getStats();

    return AnimatedBuilder(
      animation: _counterAnimation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMobile) ...[
              Text(
                'Statistiques',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Grille de stats responsive
            LayoutBuilder(
              builder: (context, constraints) {
                int columns;
                double cardAspectRatio;

                if (constraints.maxWidth < 600) {
                  columns = 2; // Mobile: 2 colonnes
                  cardAspectRatio = 1.4;
                } else if (constraints.maxWidth < 900) {
                  columns = 3; // Tablette: 3 colonnes
                  cardAspectRatio = 1.3;
                } else if (constraints.maxWidth < 1400) {
                  columns = 4; // Desktop: 4 colonnes
                  cardAspectRatio = 1.3;
                } else {
                  columns = 5; // Écrans très larges: 5 colonnes
                  cardAspectRatio = 1.2;
                }

                final statCards = [
                  _buildStatCard(
                    theme,
                    'En Attente',
                    (stats.enAttente * _counterAnimation.value).round(),
                    Icons.schedule,
                    Colors.orange,
                    isMobile,
                  ),
                  _buildStatCard(
                    theme,
                    'En Cours',
                    (stats.enCours * _counterAnimation.value).round(),
                    Icons.play_circle,
                    Colors.blue,
                    isMobile,
                  ),
                  _buildStatCard(
                    theme,
                    'Terminés',
                    (stats.termines * _counterAnimation.value).round(),
                    Icons.check_circle,
                    Colors.green,
                    isMobile,
                  ),
                  _buildStatCard(
                    theme,
                    'Suspendus',
                    (stats.suspendus * _counterAnimation.value).round(),
                    Icons.pause_circle,
                    Colors.red,
                    isMobile,
                  ),
                  _buildStatCard(
                    theme,
                    'Poids Total',
                    '${(stats.poidsTotal * _counterAnimation.value).toStringAsFixed(1)} kg',
                    Icons.monitor_weight,
                    theme.colorScheme.primary,
                    isMobile,
                  ),
                  _buildStatCard(
                    theme,
                    'Rendement Moyen',
                    '${(stats.rendementMoyen * _counterAnimation.value).toStringAsFixed(1)}%',
                    Icons.trending_up,
                    Colors.green,
                    isMobile,
                    showProgress: true,
                    progressValue: stats.rendementMoyen,
                  ),
                  _buildStatCard(
                    theme,
                    'Temps Moyen',
                    _formatDuration(stats.tempsExtractionMoyen),
                    Icons.timer,
                    theme.colorScheme.primary,
                    isMobile,
                  ),
                ];

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    // Ratio adaptatif selon le nombre de colonnes
                    childAspectRatio: cardAspectRatio,
                  ),
                  itemCount: statCards.length,
                  itemBuilder: (context, index) => statCards[index],
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// Carte de statistique individuelle
  Widget _buildStatCard(
    ThemeData theme,
    String label,
    dynamic value,
    IconData icon,
    Color color,
    bool isMobile, {
    bool showProgress = false,
    double progressValue = 0.0,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec icône
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 6 : 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: isMobile ? 16 : 20,
                  ),
                ),
                const Spacer(),
                if (showProgress)
                  SizedBox(
                    width: isMobile ? 40 : 50,
                    height: isMobile ? 40 : 50,
                    child: _buildCircularProgress(
                      progressValue * _counterAnimation.value,
                      color,
                      isMobile,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Label
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // Valeur
            Text(
              value.toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: isMobile ? 18 : 20,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Progress circulaire pour les pourcentages
  Widget _buildCircularProgress(double value, Color color, bool isMobile) {
    final size = isMobile ? 40.0 : 50.0;
    final strokeWidth = isMobile ? 4.0 : 6.0;

    return CustomPaint(
      size: Size(size, size),
      painter: _CircularProgressPainter(
        progress: value / 100,
        color: color,
        strokeWidth: strokeWidth,
      ),
      child: Center(
        child: Text(
          '${value.round()}%',
          style: TextStyle(
            fontSize: isMobile ? 10 : 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  /// Barre de filtres avancés
  Widget _buildFiltersBar(ThemeData theme, bool isMobile) {
    final activeFiltersCount = _filters.getActiveFiltersCount();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header des filtres
            Row(
              children: [
                Text(
                  'Filtres',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (activeFiltersCount > 0) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Actifs: $activeFiltersCount',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Reset'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Filtres responsive
            if (isMobile)
              _buildMobileFilters(theme)
            else
              _buildDesktopFilters(theme),
          ],
        ),
      ),
    );
  }

  /// Filtres mobile (collapsible)
  Widget _buildMobileFilters(ThemeData theme) {
    return ExpansionTile(
      title: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Recherche globale',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (value) {
                _updateFilters(_filters.copyWith(searchQuery: value));
              },
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.tune,
            color: theme.colorScheme.primary,
          ),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Première ligne
              Row(
                children: [
                  Expanded(
                    child: _buildFilterDropdown(
                      'Statut',
                      _filters.statuts.isEmpty
                          ? null
                          : _filters.statuts.first.label,
                      ExtractionStatus.values
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.label),
                              ))
                          .toList(),
                      (value) {
                        _updateFilters(_filters.copyWith(
                          statuts: value != null ? [value] : [],
                        ));
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterDropdown(
                      'Priorité',
                      _filters.priorites.isEmpty
                          ? null
                          : _filters.priorites.first.label,
                      ExtractionPriority.values
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.label),
                              ))
                          .toList(),
                      (value) {
                        _updateFilters(_filters.copyWith(
                          priorites: value != null ? [value] : [],
                        ));
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Deuxième ligne
              Row(
                children: [
                  Expanded(
                    child: _buildFilterDropdown(
                      'Type',
                      _filters.types.isEmpty
                          ? null
                          : _filters.types.first.label,
                      ProductType.values
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.label),
                              ))
                          .toList(),
                      (value) {
                        _updateFilters(_filters.copyWith(
                          types: value != null ? [value] : [],
                        ));
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterDropdown(
                      'Origine',
                      _filters.origines.isEmpty
                          ? null
                          : _filters.origines.first,
                      _service
                          .getFilterOptions()['origines']!
                          .map((o) => DropdownMenuItem(
                                value: o,
                                child: Text(o),
                              ))
                          .toList(),
                      (value) {
                        _updateFilters(_filters.copyWith(
                          origines: value != null ? [value] : [],
                        ));
                      },
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

  /// Filtres desktop (horizontal)
  Widget _buildDesktopFilters(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcul de la largeur disponible pour déterminer si on a besoin du scroll
        const minFilterWidth = 200.0;
        const searchWidth = 300.0;
        const spacing = 16.0;
        final totalFiltersWidth =
            searchWidth + (minFilterWidth * 5) + (spacing * 5);

        final needsScroll = totalFiltersWidth > constraints.maxWidth;

        Widget filtersRow = Row(
          children: [
            // Recherche
            SizedBox(
              width: 230,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Recherche',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onChanged: (value) {
                  _updateFilters(_filters.copyWith(searchQuery: value));
                },
              ),
            ),

            const SizedBox(width: 16),

            // Filtres dropdown
            SizedBox(
              width: 140,
              child: _buildFilterDropdown(
                'Statut',
                _filters.statuts.isEmpty ? null : _filters.statuts.first.label,
                ExtractionStatus.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.label),
                        ))
                    .toList(),
                (value) {
                  _updateFilters(_filters.copyWith(
                    statuts: value != null ? [value] : [],
                  ));
                },
              ),
            ),

            const SizedBox(width: 14),

            SizedBox(
              width: 140,
              child: _buildFilterDropdown(
                'Priorité',
                _filters.priorites.isEmpty
                    ? null
                    : _filters.priorites.first.label,
                ExtractionPriority.values
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.label),
                        ))
                    .toList(),
                (value) {
                  _updateFilters(_filters.copyWith(
                    priorites: value != null ? [value] : [],
                  ));
                },
              ),
            ),

            const SizedBox(width: 14),

            SizedBox(
              width: 170,
              child: _buildFilterDropdown(
                'Type',
                _filters.types.isEmpty ? null : _filters.types.first.label,
                ProductType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.label),
                        ))
                    .toList(),
                (value) {
                  _updateFilters(_filters.copyWith(
                    types: value != null ? [value] : [],
                  ));
                },
              ),
            ),

            const SizedBox(width: 14),

            SizedBox(
              width: 160,
              child: _buildFilterDropdown(
                'Origine',
                _filters.origines.isEmpty ? null : _filters.origines.first,
                _service
                    .getFilterOptions()['origines']!
                    .map((o) => DropdownMenuItem(
                          value: o,
                          child: Text(o),
                        ))
                    .toList(),
                (value) {
                  _updateFilters(_filters.copyWith(
                    origines: value != null ? [value] : [],
                  ));
                },
              ),
            ),
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
  Widget _buildFilterDropdown<T>(
    String hint,
    String? value,
    List<DropdownMenuItem<T>> items,
    void Function(T?) onChanged,
  ) {
    return DropdownButtonFormField<T>(
      value: items.any((item) => item.value.toString() == value)
          ? items.firstWhere((item) => item.value.toString() == value).value
          : null,
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      isExpanded: true,
      items: [
        DropdownMenuItem<T>(
          value: null,
          child: Text('Tous'),
        ),
        ...items,
      ],
      onChanged: onChanged,
    );
  }

  /// Liste des produits pour mobile (Sliver)
  Widget _buildProductsList(ThemeData theme, bool isMobile) {
    if (_filteredProducts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildEmptyState(theme),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = _filteredProducts[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ExtractionCard(
                product: product,
                isDesktopMode: false, // Mobile toujours false
                onTap: () => _showProductDetails(product),
                onStartExtraction: () => _startExtraction(product),
                onCompleteExtraction: () => _completeExtraction(product),
                onSuspendExtraction: () => _suspendExtraction(product),
              ),
            );
          },
          childCount: _filteredProducts.length,
        ),
      ),
    );
  }

  /// Agencement des produits en Wrap (hauteur variable par card)
  Widget _buildProductsWrap(ThemeData theme, bool isTablet) {
    final columns = isTablet ? 2 : 3;
    const spacing = 14.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalSpacing = spacing * (columns - 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final product in _filteredProducts)
              SizedBox(
                width: itemWidth,
                child: ExtractionCard(
                  product: product,
                  isDesktopMode: true,
                  onTap: () => _showProductDetails(product),
                  onStartExtraction: () => _startExtraction(product),
                  onCompleteExtraction: () => _completeExtraction(product),
                  onSuspendExtraction: () => _suspendExtraction(product),
                ),
              ),
          ],
        );
      },
    );
  }

  /// État vide
  Widget _buildEmptyState(ThemeData theme) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun produit trouvé',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez de modifier vos filtres ou contactez le contrôleur',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualiser'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () =>
                      _showToast('Support', 'Contactez l\'assistance'),
                  icon: const Icon(Icons.support_agent),
                  label: const Text('Support'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Actions sur les produits
  void _showProductDetails(ExtractionProduct product) {
    _showToast(product.nom,
        'ID ${product.id} • ${product.type.label} • ${product.origine}');
  }

  void _startExtraction(ExtractionProduct product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StartExtractionModal(
        product: product,
        onCancel: () => Navigator.of(context).pop(),
        onConfirm: (data) {
          Navigator.of(context).pop();
          _service.startExtraction(product.id);
          setState(() {
            _allProducts = _service.getAllProducts();
            _applyFilters();
          });
          _showToast(
            'Extraction démarrée',
            '${product.id} • ${data['date']} ${data['time']}',
          );
        },
      ),
    );
  }

  void _completeExtraction(ExtractionProduct product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FinishExtractionModal(
        product: product,
        onCancel: () => Navigator.of(context).pop(),
        onConfirm: (data) {
          Navigator.of(context).pop();
          _service.completeExtraction(product.id, {
            'quantity': data['quantity'],
            'yield': data['yield'],
            'quality': data['quality'],
          });
          setState(() {
            _allProducts = _service.getAllProducts();
            _applyFilters();
          });
          _showToast(
            data['validate'] ? 'Extraction validée' : 'Résultats sauvegardés',
            '${product.id} • ${data['quantity']} kg • ${data['yield']}%',
          );
        },
      ),
    );
  }

  void _suspendExtraction(ExtractionProduct product) {
    _service.suspendExtraction(product.id, 'Suspendu par l\'utilisateur');
    setState(() {
      _allProducts = _service.getAllProducts();
      _applyFilters();
    });
    _showToast(
        'Extraction suspendue', '${product.id} est maintenant en pause.');
  }

  // Utilitaires de formatage
  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}min';
  }
}

/// Painter pour le progress circulaire
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

*/ // Fin du commentaire - ancien fichier désactivé
