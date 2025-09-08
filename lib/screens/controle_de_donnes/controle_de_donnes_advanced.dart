// Page principale du module de contrôle avancé
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../../authentication/user_session.dart';
import 'models/collecte_models.dart';
import 'models/attribution_models_v2.dart';
// import 'services/mock_data_service.dart'; // SERVICE SUPPRIMÉ - Générait des données fictives
import 'services/firestore_data_service.dart';
import 'services/pdf_statistics_service.dart';
import 'services/quality_control_service.dart';
import 'package:share_plus/share_plus.dart';
// Import supprimé car non utilisé
import 'services/global_refresh_service.dart';
import 'utils/formatters.dart';
import 'widgets/stat_card.dart';
import 'widgets/multi_select_popover.dart';
import 'widgets/collecte_card.dart';
import 'widgets/details_dialog.dart';
import 'widgets/control_attribution_modal.dart';
import '../extraction/pages/main_extraction_page.dart';
import '../attribution/attribution_page_complete.dart';
import 'historique_controle_page.dart';
import 'historique_attribution_page.dart';

class ControlePageDashboard extends StatefulWidget {
  const ControlePageDashboard({super.key});

  @override
  State<ControlePageDashboard> createState() => _ControlePageDashboardState();
}

class _ControlePageDashboardState extends State<ControlePageDashboard>
    with TickerProviderStateMixin {
  // Contrôleurs et état
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // final ControlAttributionService _attributionService =
  //     ControlAttributionService(); // Non utilisé

  // Données
  Map<Section, List<BaseCollecte>> _allData = {};
  Map<String, List<String>> _filterOptions = {};

  // État de l'interface
  Section _activeTab = Section.recoltes;
  String _searchQuery = '';
  bool _showFilters = false;
  bool _isLoading = true;
  bool _isGeneratingPDF = false;

  // Filtres et tri
  CollecteFilters _filters = CollecteFilters();
  SortKey _sortKey = SortKey.date;

  // Pagination infinie
  int _visibleItems = 20;
  final int _pageSize = 20;

  // Dialog de détails
  // Variables supprimées car maintenant on utilise showModalBottomSheet

  // Rôle utilisateur
  Role _userRole = Role.admin;

  // Subscriptions pour les notifications globales
  late StreamSubscription _qualityControlUpdateSubscription;
  late StreamSubscription _collecteUpdateSubscription;
  late StreamSubscription _interfaceSyncSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 4,
        vsync:
            this); // 4 onglets (récoltes, SCOOP, individuel, miellerie) + bouton historique séparé
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);

    _initializeUserRole();
    _loadData();
    _setupKeyboardShortcuts();
    _setupGlobalRefreshListeners();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _qualityControlUpdateSubscription.cancel();
    _collecteUpdateSubscription.cancel();
    _interfaceSyncSubscription.cancel();
    super.dispose();
  }

  void _initializeUserRole() {
    try {
      final userSession = Get.find<UserSession>();
      final role = userSession.role?.toLowerCase() ?? '';
      _userRole = role.contains('admin') ? Role.admin : Role.controller;
    } catch (e) {
      _userRole = Role.controller; // Par défaut
    }
  }

  void _loadData() async {
    setState(() => _isLoading = true);

    try {
      print('🔄 Chargement des données depuis Firestore...');

      // Chargement des vraies données depuis Firestore
      final data = await FirestoreDataService.getCollectesFromFirestore();
      final options = await FirestoreDataService.getFilterOptions(data);

      // Charger les données de contrôle qualité en parallèle
      QualityControlService().refreshAllData();

      if (!mounted) return;

      setState(() {
        _allData = data;
        _filterOptions = options;
        _isLoading = false;
        _visibleItems = _pageSize;
      });

      print('✅ Données Firestore chargées avec succès');
      print('   - Récoltes: ${data[Section.recoltes]?.length ?? 0}');
      print('   - SCOOP: ${data[Section.scoop]?.length ?? 0}');
      print('   - Individuel: ${data[Section.individuel]?.length ?? 0}');
      print('   - Miellerie: ${data[Section.miellerie]?.length ?? 0}');
    } catch (e) {
      print('❌ Erreur chargement Firestore: $e');

      if (!mounted) return;

      // Afficher l'erreur sans utiliser de données fictives
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Erreur lors du chargement des données: $e'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );

      // Initialiser avec des données vides
      setState(() {
        _allData = {
          Section.recoltes: [],
          Section.scoop: [],
          Section.individuel: [],
          Section.miellerie: [],
        };
        _filterOptions = {
          'sites': [],
          'techniciens': [],
          'statuses': [],
        };
        _isLoading = false;
        _visibleItems = _pageSize;
      });
    }
  }

  void _setupKeyboardShortcuts() {
    // Les raccourcis clavier sont gérés dans le widget build avec Focus
  }

  /// Configure les listeners pour les notifications globales de mise à jour
  void _setupGlobalRefreshListeners() {
    final globalRefreshService = GlobalRefreshService();

    // Écouter les mises à jour de contrôles qualité
    _qualityControlUpdateSubscription = globalRefreshService
        .qualityControlUpdatesStream
        .listen((containerCode) {
      print(
          '📢 Page principale: Notification contrôle mis à jour - $containerCode');
      if (mounted) {
        _refreshData();
      }
    });

    // Écouter les mises à jour de collectes
    _collecteUpdateSubscription =
        globalRefreshService.collecteUpdatesStream.listen((collecteId) {
      print(
          '📢 Page principale: Notification collecte mise à jour - $collecteId');
      if (mounted) {
        _refreshData();
      }
    });

    // 🆕 Écouter les synchronisations spécifiques entre interfaces
    _interfaceSyncSubscription =
        globalRefreshService.interfaceSyncStream.listen((syncData) {
      if (mounted) {
        final action = syncData['action'] as String?;
        final collecteId = syncData['collecteId'] as String?;
        final containerCode = syncData['containerCode'] as String?;

        print('🔄 Page principale: Synchronisation interface - $action');
        print('   CollecteId: $collecteId, ContainerCode: $containerCode');

        switch (action) {
          case 'quality_control_updated':
            _refreshDataForCollecte(collecteId);
            break;
          case 'collecte_details_opened':
            // Interface de détails ouverte, préparer les données
            _preloadCollecteData(collecteId);
            break;
          default:
            _refreshData();
        }
      }
    });
  }

  /// Rafraîchit les données depuis Firestore
  Future<void> _refreshData() async {
    _loadData();
  }

  /// Rafraîchit les données pour une collecte spécifique
  Future<void> _refreshDataForCollecte(String? collecteId) async {
    if (collecteId == null) {
      _refreshData();
      return;
    }

    print('🔄 Rafraîchissement spécifique pour collecte: $collecteId');

    // Pour l'instant, on fait un refresh complet mais optimisé
    // TODO: Implémenter un refresh plus granulaire par collecte
    _refreshData();
  }

  /// Précharge les données d'une collecte pour optimiser l'affichage des détails
  Future<void> _preloadCollecteData(String? collecteId) async {
    if (collecteId == null) return;

    print('📋 Préchargement données pour collecte: $collecteId');

    // Précharger les contrôles qualité pour cette collecte
    try {
      final qualityService = QualityControlService();
      await qualityService.getOptimizedControlStatusForCollecte(collecteId);
      print('✅ Données préchargées pour $collecteId');
    } catch (e) {
      print('❌ Erreur préchargement: $e');
    }
  }

  /// Génère et télécharge le rapport PDF des statistiques
  Future<void> _generatePDFReport() async {
    setState(() => _isGeneratingPDF = true);

    try {
      print('🔄 Génération du rapport PDF...');

      // Générer le PDF avec toutes les données (sans vérification de permissions)
      final pdfFile =
          await PDFStatisticsService.generateStatisticsReport(_allData);

      print('✅ PDF généré: ${pdfFile.path}');

      if (!mounted) return;

      // Afficher une notification de succès avec option de partage
      final isInDownloads = pdfFile.path.contains('Download');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Rapport PDF généré avec succès !',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      isInDownloads
                          ? 'Fichier sauvé dans Téléchargements'
                          : 'Fichier sauvé dans Documents',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'OUVRIR DOSSIER',
            textColor: Colors.white,
            onPressed: () => _showFileLocation(pdfFile),
          ),
        ),
      );
    } catch (e) {
      print('❌ Erreur génération PDF: $e');

      if (!mounted) return;

      // Gestion d'erreur spécifique pour les permissions
      String errorMessage = 'Erreur lors de la génération du PDF';
      if (e.toString().contains('MissingPluginException')) {
        errorMessage =
            'Problème de configuration des permissions. Le PDF sera sauvegardé dans le cache de l\'application.';
        // Tenter une génération alternative
        _generatePDFWithoutPermissions();
        return;
      } else if (e.toString().contains('Permission')) {
        errorMessage =
            'Permission de stockage requise. Veuillez autoriser l\'accès au stockage dans les paramètres.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(errorMessage),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPDF = false);
      }
    }
  }

  /// Génère le PDF sans vérification de permissions (utilise le cache de l'app)
  Future<void> _generatePDFWithoutPermissions() async {
    try {
      print('🔄 Génération PDF alternative (sans permissions)...');

      // Créer un service PDF modifié qui utilise le cache temporaire
      final pdfFile =
          await PDFStatisticsService.generateStatisticsReportToCache(_allData);

      print('✅ PDF généré dans le cache: ${pdfFile.path}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'PDF généré dans le cache temporaire !',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'PARTAGER',
            textColor: Colors.white,
            onPressed: () => _sharePDFFile(pdfFile),
          ),
        ),
      );
    } catch (e) {
      print('❌ Erreur génération PDF alternative: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de générer le PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Affiche l'emplacement du fichier PDF
  void _showFileLocation(File pdfFile) {
    final isInDownloads = pdfFile.path.contains('Download');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.folder, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Fichier PDF sauvegardé'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Le fichier a été sauvegardé dans :',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isInDownloads
                        ? '📁 Dossier Téléchargements'
                        : '📁 Dossier Documents',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pdfFile.path.split('/').last,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isInDownloads
                  ? 'Vous pouvez le retrouver dans l\'application Fichiers > Téléchargements'
                  : 'Le fichier est dans le dossier Documents de l\'application',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _sharePDFFile(pdfFile);
            },
            icon: const Icon(Icons.share, size: 16),
            label: const Text('Partager'),
          ),
        ],
      ),
    );
  }

  /// Partage le fichier PDF
  Future<void> _sharePDFFile(File pdfFile) async {
    try {
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'Rapport statistique des collectes de miel',
        subject: 'Rapport PDF - Statistiques des Collectes',
      );
    } catch (e) {
      print('❌ Erreur partage PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du partage: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;

    setState(() {
      _activeTab = Section.values[_tabController.index];
      _visibleItems = _pageSize; // Reset de la pagination
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    final filtered = _getFilteredAndSortedData();
    if (_visibleItems < filtered.length) {
      setState(() {
        _visibleItems = (_visibleItems + _pageSize).clamp(0, filtered.length);
      });
    }
  }

  /// Gère l'attribution d'une collecte vers extraction ou filtration
  void _handleAttribution(BaseCollecte collecte, AttributionType type) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ControlAttributionModal(
        collecte: collecte,
        type: type,
      ),
    );

    if (result == true) {
      // L'attribution a été créée avec succès
      // Optionnel: rafraîchir les données ou afficher un feedback
      setState(() {
        // Force un rafraîchissement de l'interface
      });
    }
  }

  List<BaseCollecte> _getFilteredAndSortedData() {
    final sectionData = _allData[_activeTab] ?? [];

    // Filtrage par rôle
    var filtered = sectionData.where((item) {
      if (_userRole == Role.controller) {
        // Un contrôleur ne voit que son site
        final userSession = Get.find<UserSession>();
        final userSite = userSession.site ?? '';
        if (userSite.isNotEmpty && item.site != userSite) {
          return false;
        }
      }
      return true;
    }).toList();

    // Filtrage par recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        final title = Formatters.getTitleForCollecte(_activeTab, item);
        final searchableText =
            '$title ${item.id} ${item.technicien ?? ''}'.toLowerCase();
        return searchableText.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filtrage par critères
    filtered = filtered.where((item) => _matchesFilters(item)).toList();

    // Tri
    filtered.sort((a, b) => _compareBySortKey(a, b));

    return filtered;
  }

  bool _matchesFilters(BaseCollecte item) {
    // Sites
    if (_filters.sites.isNotEmpty && !_filters.sites.contains(item.site)) {
      return false;
    }

    // Technicien
    if (_filters.technicien.isNotEmpty &&
        item.technicien != _filters.technicien) {
      return false;
    }

    // Statut
    if (_filters.statut.isNotEmpty && item.statut != _filters.statut) {
      return false;
    }

    // Dates
    if (_filters.dateFrom != null && item.date.isBefore(_filters.dateFrom!)) {
      return false;
    }
    if (_filters.dateTo != null && item.date.isAfter(_filters.dateTo!)) {
      return false;
    }

    // Florales (selon le type d'item)
    if (_filters.florales.isNotEmpty) {
      List<String> itemFlorales = [];
      switch (_activeTab) {
        case Section.recoltes:
          itemFlorales = (item as Recolte).predominancesFlorales ?? [];
          break;
        case Section.individuel:
          itemFlorales = (item as Individuel).originesFlorales ?? [];
          break;
        case Section.scoop:
          // Pour SCOOP, on utilise les prédominances des contenants
          final scoop = item as Scoop;
          itemFlorales = scoop.contenants
              .where((c) => c.predominanceFlorale != null)
              .map((c) => c.predominanceFlorale!)
              .toSet()
              .toList();
          break;
        case Section.miellerie:
          // Pour Miellerie, on peut utiliser une liste vide ou des prédominances spécifiques
          itemFlorales = [];
          break;
      }
      if (!_filters.florales.any((f) => itemFlorales.contains(f))) {
        return false;
      }
    }

    // Filtres numériques
    final poids = item.totalWeight ?? 0;
    final montant = item.totalAmount ?? 0;
    final contenants = item.containersCount ?? 0;

    if (_filters.poidsMin != null && poids < _filters.poidsMin!) return false;
    if (_filters.poidsMax != null && poids > _filters.poidsMax!) return false;
    if (_filters.montantMin != null && montant < _filters.montantMin!)
      return false;
    if (_filters.montantMax != null && montant > _filters.montantMax!)
      return false;
    if (_filters.contMin != null && contenants < _filters.contMin!)
      return false;
    if (_filters.contMax != null && contenants > _filters.contMax!)
      return false;

    return true;
  }

  int _compareBySortKey(BaseCollecte a, BaseCollecte b) {
    switch (_sortKey) {
      case SortKey.date:
        return b.date.compareTo(a.date);
      case SortKey.site:
        return a.site.compareTo(b.site);
      case SortKey.technicien:
        return (a.technicien ?? '').compareTo(b.technicien ?? '');
      case SortKey.poids:
        return (b.totalWeight ?? 0).compareTo(a.totalWeight ?? 0);
      case SortKey.montant:
        return (b.totalAmount ?? 0).compareTo(a.totalAmount ?? 0);
      case SortKey.contenants:
        return (b.containersCount ?? 0).compareTo(a.containersCount ?? 0);
      case SortKey.libelleAsc:
        final titleA = Formatters.getTitleForCollecte(_activeTab, a);
        final titleB = Formatters.getTitleForCollecte(_activeTab, b);
        return titleA.compareTo(titleB);
      case SortKey.libelleDesc:
        final titleA = Formatters.getTitleForCollecte(_activeTab, a);
        final titleB = Formatters.getTitleForCollecte(_activeTab, b);
        return titleB.compareTo(titleA);
    }
  }

  CollecteStats _calculateStats(List<BaseCollecte> data) {
    final total = data.length;
    final poids = data.fold(0.0, (sum, item) => sum + (item.totalWeight ?? 0));
    final montant =
        data.fold(0.0, (sum, item) => sum + (item.totalAmount ?? 0));
    final contenants =
        data.fold(0, (sum, item) => sum + (item.containersCount ?? 0));

    return CollecteStats(
      total: total,
      poids: poids,
      montant: montant,
      contenants: contenants,
    );
  }

  /// Calcule les statistiques avec les données de contrôle qualité
  Future<CollecteStats> _calculateStatsWithQualityControl(
      List<BaseCollecte> data) async {
    final baseStats = _calculateStats(data);

    try {
      final qualityService = QualityControlService();
      int totalControles = 0;

      for (final collecte in data) {
        final containerCount = collecte.containersCount ?? 0;
        final containerCodes = List.generate(containerCount,
            (index) => 'C${(index + 1).toString().padLeft(3, '0')}');

        final controlStats = await qualityService.getControlStatsForContainers(
            containerCodes, collecte.date);

        totalControles += controlStats['controlled'] ?? 0;
      }

      final totalContenants = baseStats.contenants;
      final tauxControle =
          totalContenants > 0 ? (totalControles / totalContenants) * 100 : 0.0;

      return baseStats.copyWith(
        contenantsControles: totalControles,
        contenantsNonControles: totalContenants - totalControles,
        tauxControle: tauxControle,
      );
    } catch (e) {
      print('❌ Erreur calcul statistiques contrôle: $e');
      return baseStats;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredData = _getFilteredAndSortedData();
    final stats = _calculateStats(filteredData);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.slash) {
            _searchController.text = '';
            FocusScope.of(context).requestFocus();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.keyF) {
            setState(() => _showFilters = !_showFilters);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: _isLoading
            ? _buildLoadingView()
            : isMobile
                // Nouveau layout mobile basé sur Slivers pour éviter les overflows
                ? _buildMobileScrollContent(theme, stats, filteredData)
                // Layout desktop/tablette existant
                : Column(
                    children: [
                      _buildHeader(theme, stats),
                      if (_showFilters) _buildFiltersBar(theme),
                      Expanded(child: _buildMainContent(theme, filteredData)),
                    ],
                  ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouton Attribution Intelligente
            FloatingActionButton.extended(
              heroTag: 'fab-advanced-attribution',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AttributionPageComplete(),
                  ),
                );
              },
              backgroundColor: Colors.deepPurple.shade700,
              icon: const Icon(Icons.assignment_turned_in, color: Colors.white),
              label: const Text('Attribution',
                  style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 12),
            // Bouton Historique (Menu avec 2 options)
            FloatingActionButton.extended(
              heroTag: 'fab-advanced-historique',
              onPressed: () {
                _showHistoriqueMenu(context);
              },
              backgroundColor: Colors.deepPurple.shade700,
              icon: const Icon(Icons.history, color: Colors.white),
              label: const Text('Historique',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  /// 🆕 Affiche le menu de choix entre les deux pages historiques
  void _showHistoriqueMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history,
                    color: Colors.deepPurple.shade700, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Choisir la page historique',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Option 1: Nouvelle page (recommandée)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.dashboard, color: Colors.deepPurple.shade700),
              ),
              title: Row(
                children: [
                  const Text(
                    'Historique Complet',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'RECOMMANDÉ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: const Text(
                  'Attributions + Contrôles + Statistiques avancées'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoriqueAttributionPage(),
                  ),
                );
              },
            ),

            const Divider(),

            // Option 2: Ancienne page (contrôles seulement)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.science, color: Colors.blue.shade700),
              ),
              title: Row(
                children: [
                  const Text(
                    'Historique des Contrôles',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ANCIENNE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: const Text('Contrôles qualité uniquement'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoriqueControlePage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// Nouveau contenu mobile: tout en Slivers (header, filtres, stats, liste)
  Widget _buildMobileScrollContent(
    ThemeData theme,
    CollecteStats stats,
    List<BaseCollecte> filteredData,
  ) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Header + onglets
        SliverToBoxAdapter(child: _buildHeader(theme, stats)),

        // Filtres conditionnels
        if (_showFilters) SliverToBoxAdapter(child: _buildFiltersBar(theme)),

        // Statistiques
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildStatsSection(theme, filteredData),
          ),
        ),

        // Header de liste
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildListHeader(theme, filteredData),
          ),
        ),

        // Liste des collectes
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final visible = filteredData.take(_visibleItems).toList();
              if (index < visible.length) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: CollecteCard(
                    section: _activeTab,
                    item: visible[index],
                    canEdit: _userRole == Role.admin,
                    onOpen: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => DetailsDialog(
                          isOpen: true,
                          onOpenChange: (open) => Navigator.of(context).pop(),
                          section: _activeTab,
                          item: visible[index],
                        ),
                      );
                    },
                    onEdit: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Modification sera bientôt disponible'),
                        ),
                      );
                    },
                    onDelete: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Collecte supprimée avec succès'),
                        ),
                      );
                    },
                  ),
                );
              }

              if (_visibleItems < filteredData.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              return const SizedBox.shrink();
            },
            childCount: _visibleItems < filteredData.length
                ? _visibleItems + 1
                : _visibleItems,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, CollecteStats stats) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Titre et actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Collectes — Détails avancés',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Module de contrôle et d\'analyse des collectes',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions header
                _buildHeaderActions(theme),
              ],
            ),
          ),

          // Onglets
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Récoltes'),
                Tab(text: 'SCOOP'),
                Tab(text: 'Individuel'),
                Tab(text: 'Miellerie'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActions(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth < 900;

        if (isMobile) {
          // Layout mobile - interface moderne et épurée
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Barre de recherche moderne avec design amélioré
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Rechercher une collecte...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.6),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 22,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                  _visibleItems = _pageSize;
                                });
                              },
                              icon: Icon(
                                Icons.clear_rounded,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _visibleItems = _pageSize;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Actions compactes avec design moderne
                Row(
                  children: [
                    // Bouton filtres avec badge
                    Expanded(
                      flex: 2,
                      child: Material(
                        color: _showFilters || _filters.hasActiveFilters
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () =>
                              setState(() => _showFilters = !_showFilters),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _showFilters
                                      ? Icons.filter_alt
                                      : Icons.filter_alt_outlined,
                                  size: 18,
                                  color:
                                      _showFilters || _filters.hasActiveFilters
                                          ? theme.colorScheme.onPrimaryContainer
                                          : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Filtres',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: _showFilters ||
                                            _filters.hasActiveFilters
                                        ? theme.colorScheme.onPrimaryContainer
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_filters.hasActiveFilters) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${_filters.getActiveFiltersCount()}',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onPrimary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Bouton rafraîchir
                    Material(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: _isLoading ? null : _refreshData,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: _isLoading
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.refresh_rounded,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 18,
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Bouton téléchargement PDF moderne
                    Expanded(
                      flex: 2,
                      child: Material(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: _isGeneratingPDF ? null : _generatePDFReport,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isGeneratingPDF) ...[
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Génération...',
                                    style: TextStyle(
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ] else ...[
                                  Icon(
                                    Icons.picture_as_pdf_rounded,
                                    color: theme.colorScheme.onPrimary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Rapport PDF',
                                    style: TextStyle(
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        } else if (isTablet) {
          // Layout tablette - plus compact que desktop
          return Column(
            children: [
              Row(
                children: [
                  // Barre de recherche
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher… (/ pour focus)',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _visibleItems = _pageSize;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bouton filtres
                  OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _showFilters = !_showFilters),
                    icon: const Icon(Icons.filter_alt, size: 16),
                    label: const Text('Filtres'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _showFilters || _filters.hasActiveFilters
                          ? theme.colorScheme.primaryContainer
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bouton PDF pour tablette
                  ElevatedButton.icon(
                    onPressed: _isGeneratingPDF ? null : _generatePDFReport,
                    icon: _isGeneratingPDF
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : const Icon(Icons.picture_as_pdf_rounded, size: 16),
                    label: Text(
                        _isGeneratingPDF ? 'Génération...' : 'Rapport PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 🆕 Affichage du rôle utilisateur (lecture seule)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _userRole == Role.admin
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : theme.colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _userRole == Role.admin
                          ? theme.colorScheme.primary
                          : theme.colorScheme.secondary,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _userRole == Role.admin
                            ? Icons.admin_panel_settings
                            : Icons.verified_user,
                        size: 16,
                        color: _userRole == Role.admin
                            ? theme.colorScheme.primary
                            : theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _userRole == Role.admin
                            ? 'Administrateur'
                            : 'Contrôleur',
                        style: TextStyle(
                          color: _userRole == Role.admin
                              ? theme.colorScheme.primary
                              : theme.colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        } else {
          // Layout desktop - comme avant mais optimisé
          return Wrap(
            spacing: 8,
            children: [
              // Barre de recherche
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher… (/ pour focus)',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _visibleItems = _pageSize;
                    });
                  },
                ),
              ),

              // Bouton filtres
              OutlinedButton.icon(
                onPressed: () => setState(() => _showFilters = !_showFilters),
                icon: const Icon(Icons.filter_alt, size: 16),
                label: const Text('Filtres'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: _showFilters || _filters.hasActiveFilters
                      ? theme.colorScheme.primaryContainer
                      : null,
                ),
              ),

              // Bouton PDF pour desktop
              ElevatedButton.icon(
                onPressed: _isGeneratingPDF ? null : _generatePDFReport,
                icon: _isGeneratingPDF
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded, size: 16),
                label: Text(_isGeneratingPDF ? 'Génération...' : 'Rapport PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),

              // 🆕 Affichage du rôle utilisateur (lecture seule)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _userRole == Role.admin
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : theme.colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _userRole == Role.admin
                        ? theme.colorScheme.primary
                        : theme.colorScheme.secondary,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _userRole == Role.admin
                          ? Icons.admin_panel_settings
                          : Icons.verified_user,
                      size: 16,
                      color: _userRole == Role.admin
                          ? theme.colorScheme.primary
                          : theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _userRole == Role.admin ? 'Administrateur' : 'Contrôleur',
                      style: TextStyle(
                        color: _userRole == Role.admin
                            ? theme.colorScheme.primary
                            : theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildFiltersBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Première ligne de filtres
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              if (isMobile) {
                return Column(
                  children: [
                    _buildMobileFilters(theme),
                    const SizedBox(height: 12),
                    _buildFilterActions(theme),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildDesktopFilters(theme),
                    const SizedBox(height: 12),
                    _buildNumericFilters(theme),
                    const SizedBox(height: 12),
                    _buildFilterActions(theme),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFilters(ThemeData theme) {
    return Row(
      children: [
        // Sites (admin seulement)
        if (_userRole == Role.admin)
          Expanded(
            child: MultiSelectPopover(
              label: 'Sites',
              options: _filterOptions['sites'] ?? [],
              values: _filters.sites,
              onChange: (values) {
                setState(() {
                  _filters = _filters.copyWith(sites: values);
                  _visibleItems = _pageSize;
                });
              },
            ),
          ),

        const SizedBox(width: 12),

        // Technicien
        Expanded(
          child: _buildDropdownFilter(
            'Technicien',
            _filters.technicien,
            ['', ...(_filterOptions['techniciens'] ?? [])],
            (value) => setState(() {
              _filters = _filters.copyWith(technicien: value ?? '');
              _visibleItems = _pageSize;
            }),
          ),
        ),

        const SizedBox(width: 12),

        // Statut
        Expanded(
          child: _buildDropdownFilter(
            'Statut',
            _filters.statut,
            ['', ...(_filterOptions['statuses'] ?? [])],
            (value) => setState(() {
              _filters = _filters.copyWith(statut: value ?? '');
              _visibleItems = _pageSize;
            }),
          ),
        ),

        const SizedBox(width: 12),

        // Dates
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(
                child: _buildDateFilter(
                  'Du',
                  _filters.dateFrom,
                  (date) => setState(() {
                    _filters = _filters.copyWith(dateFrom: date);
                    _visibleItems = _pageSize;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDateFilter(
                  'Au',
                  _filters.dateTo,
                  (date) => setState(() {
                    _filters = _filters.copyWith(dateTo: date);
                    _visibleItems = _pageSize;
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFilters(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header des filtres
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Filtres avancés',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_filters.hasActiveFilters)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filters = _filters.reset();
                        _visibleItems = _pageSize;
                      });
                    },
                    child: Text(
                      'Réinitialiser',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Contenu des filtres
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sites (admin seulement)
                if (_userRole == Role.admin) ...[
                  _buildModernFilterCard(
                    theme,
                    'Sites de collecte',
                    Icons.location_on_rounded,
                    child: MultiSelectPopover(
                      label: 'Sélectionner les sites',
                      options: _filterOptions['sites'] ?? [],
                      values: _filters.sites,
                      onChange: (values) {
                        setState(() {
                          _filters = _filters.copyWith(sites: values);
                          _visibleItems = _pageSize;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Technicien et Statut
                Row(
                  children: [
                    Expanded(
                      child: _buildModernFilterCard(
                        theme,
                        'Technicien',
                        Icons.person_rounded,
                        child: _buildModernDropdown(
                          theme,
                          'Tous les techniciens',
                          _filters.technicien,
                          ['', ...(_filterOptions['techniciens'] ?? [])],
                          (value) => setState(() {
                            _filters =
                                _filters.copyWith(technicien: value ?? '');
                            _visibleItems = _pageSize;
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModernFilterCard(
                        theme,
                        'Statut',
                        Icons.flag_rounded,
                        child: _buildModernDropdown(
                          theme,
                          'Tous les statuts',
                          _filters.statut,
                          ['', ...(_filterOptions['statuses'] ?? [])],
                          (value) => setState(() {
                            _filters = _filters.copyWith(statut: value ?? '');
                            _visibleItems = _pageSize;
                          }),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Période de collecte
                _buildModernFilterCard(
                  theme,
                  'Période de collecte',
                  Icons.date_range_rounded,
                  child: _buildModernDateFilter(theme),
                ),

                const SizedBox(height: 16),

                // Prédominances florales
                _buildModernFilterCard(
                  theme,
                  'Prédominances florales',
                  Icons.local_florist_rounded,
                  child: MultiSelectPopover(
                    label: 'Sélectionner les florales',
                    options: _filterOptions['florales'] ?? [],
                    values: _filters.florales,
                    onChange: (values) {
                      setState(() {
                        _filters = _filters.copyWith(florales: values);
                        _visibleItems = _pageSize;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Filtres numériques - Accordéon moderne
                _buildModernNumericFilters(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumericFilters(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildNumericFilter(
            'Poids min (kg)',
            _filters.poidsMin?.toString() ?? '',
            (value) => setState(() {
              _filters = _filters.copyWith(
                poidsMin: double.tryParse(value),
              );
              _visibleItems = _pageSize;
            }),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildNumericFilter(
            'Poids max (kg)',
            _filters.poidsMax?.toString() ?? '',
            (value) => setState(() {
              _filters = _filters.copyWith(
                poidsMax: double.tryParse(value),
              );
              _visibleItems = _pageSize;
            }),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildNumericFilter(
            'Montant min',
            _filters.montantMin?.toString() ?? '',
            (value) => setState(() {
              _filters = _filters.copyWith(
                montantMin: double.tryParse(value),
              );
              _visibleItems = _pageSize;
            }),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildNumericFilter(
            'Montant max',
            _filters.montantMax?.toString() ?? '',
            (value) => setState(() {
              _filters = _filters.copyWith(
                montantMax: double.tryParse(value),
              );
              _visibleItems = _pageSize;
            }),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildNumericFilter(
            '#cont. min',
            _filters.contMin?.toString() ?? '',
            (value) => setState(() {
              _filters = _filters.copyWith(
                contMin: int.tryParse(value),
              );
              _visibleItems = _pageSize;
            }),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildNumericFilter(
            '#cont. max',
            _filters.contMax?.toString() ?? '',
            (value) => setState(() {
              _filters = _filters.copyWith(
                contMax: int.tryParse(value),
              );
              _visibleItems = _pageSize;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterActions(ThemeData theme) {
    return Row(
      children: [
        const Spacer(),
        OutlinedButton(
          onPressed: () {
            setState(() {
              _filters = _filters.reset();
              _visibleItems = _pageSize;
            });
          },
          child: const Text('Réinitialiser'),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Filtres appliqués')),
            );
          },
          child: const Text('Appliquer'),
        ),
      ],
    );
  }

  Widget _buildDropdownFilter(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value.isEmpty ? null : value,
          items: options
              .map(
                (option) => DropdownMenuItem(
                  value: option.isEmpty ? null : option,
                  child: Text(option.isEmpty ? 'Tous' : option),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilter(
    String label,
    DateTime? value,
    ValueChanged<DateTime?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              onChanged(date);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null
                        ? Formatters.formatDate(value)
                        : 'Sélectionner',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const Icon(Icons.calendar_today, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumericFilter(
    String placeholder,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return TextField(
      decoration: InputDecoration(
        hintText: placeholder,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
      ),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      controller: TextEditingController(text: value),
    );
  }

  // Nouvelles fonctions pour le mobile responsive
  Widget _buildCompactDateFilter(
    String label,
    DateTime? value,
    ValueChanged<DateTime?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              onChanged(date);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null ? Formatters.formatDate(value) : 'Date',
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.calendar_today, size: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileNumericFiltersAccordion(ThemeData theme) {
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          'Filtres numériques',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: const Icon(Icons.tune, size: 20),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Poids
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactNumericFilter(
                        'Poids min (kg)',
                        _filters.poidsMin?.toString() ?? '',
                        (value) => setState(() {
                          _filters = _filters.copyWith(
                              poidsMin: double.tryParse(value));
                          _visibleItems = _pageSize;
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactNumericFilter(
                        'Poids max (kg)',
                        _filters.poidsMax?.toString() ?? '',
                        (value) => setState(() {
                          _filters = _filters.copyWith(
                              poidsMax: double.tryParse(value));
                          _visibleItems = _pageSize;
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Montant
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactNumericFilter(
                        'Montant min',
                        _filters.montantMin?.toString() ?? '',
                        (value) => setState(() {
                          _filters = _filters.copyWith(
                              montantMin: double.tryParse(value));
                          _visibleItems = _pageSize;
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactNumericFilter(
                        'Montant max',
                        _filters.montantMax?.toString() ?? '',
                        (value) => setState(() {
                          _filters = _filters.copyWith(
                              montantMax: double.tryParse(value));
                          _visibleItems = _pageSize;
                        }),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactNumericFilter(
    String placeholder,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return TextField(
      decoration: InputDecoration(
        hintText: placeholder,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ),
        isDense: true,
      ),
      style: Theme.of(context).textTheme.bodySmall,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      controller: TextEditingController(text: value),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildMainContent(ThemeData theme, List<BaseCollecte> filteredData) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Statistiques
          _buildStatsSection(theme, filteredData),

          const SizedBox(height: 16),

          // Header de la liste
          _buildListHeader(theme, filteredData),

          const SizedBox(height: 16),

          // Liste des collectes
          Expanded(
            child: _buildCollectesList(theme, filteredData),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(ThemeData theme, List<BaseCollecte> data) {
    final stats = _calculateStats(data);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isVerySmall = screenWidth < 360;

    final statCards = [
      StatCard(
        label: isMobile ? 'Total' : 'Total collectes',
        value: stats.total.toString(),
        icon: Icons.list_alt,
      ),
      StatCard(
        label: isMobile ? 'Poids' : 'Poids total',
        value: Formatters.formatKg(stats.poids),
        tone: StatCardTone.success,
        icon: Icons.scale,
      ),
      StatCard(
        label: isMobile ? 'Montant' : 'Montant total',
        value: Formatters.formatFCFA(stats.montant),
        tone: StatCardTone.warning,
        icon: Icons.attach_money,
      ),
      StatCard(
        label: isMobile ? 'Contenants' : 'Nombre de contenants',
        value: stats.contenants.toString(),
        tone: StatCardTone.info,
        icon: Icons.inventory_2,
      ),
    ];

    if (isMobile) {
      // Sur mobile, affichage responsive avec hauteur flexible
      return Container(
        padding: const EdgeInsets.all(16),
        child: IntrinsicHeight(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isVerySmall) ...[
                // Très petits écrans : 2x2 grid avec hauteur flexible
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: statCards[0]),
                      const SizedBox(width: 8),
                      Expanded(child: statCards[1]),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: statCards[2]),
                      const SizedBox(width: 8),
                      Expanded(child: statCards[3]),
                    ],
                  ),
                ),
              ] else ...[
                // Écrans mobiles moyens : 2 lignes, 2 cartes par ligne avec hauteur flexible
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: statCards[0]),
                      const SizedBox(width: 8),
                      Expanded(child: statCards[1]),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: statCards[2]),
                      const SizedBox(width: 8),
                      Expanded(child: statCards[3]),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    } else {
      // Desktop : utiliser StatsGrid original
      return StatsGrid(stats: statCards);
    }
  }

  Widget _buildListHeader(ThemeData theme, List<BaseCollecte> data) {
    return Row(
      children: [
        Text(
          '${data.length} résultat${data.length > 1 ? 's' : ''}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),

        const Spacer(),

        // Menu de tri
        PopupMenuButton<SortKey>(
          child: OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.sort, size: 16),
            label: Text('Trier: ${_sortKey.label}'),
          ),
          itemBuilder: (context) => SortKey.values
              .map(
                (key) => PopupMenuItem(
                  value: key,
                  child: Text(key.label),
                ),
              )
              .toList(),
          onSelected: (key) {
            setState(() {
              _sortKey = key;
              _visibleItems = _pageSize;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCollectesList(ThemeData theme, List<BaseCollecte> data) {
    if (data.isEmpty) {
      return _buildEmptyState(theme);
    }

    final visibleData = data.take(_visibleItems).toList();

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index < visibleData.length) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CollecteCard(
                    section: _activeTab,
                    item: visibleData[index],
                    canEdit: _userRole == Role.admin,
                    onOpen: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => DetailsDialog(
                          isOpen: true,
                          onOpenChange: (open) => Navigator.of(context).pop(),
                          section: _activeTab,
                          item: visibleData[index],
                        ),
                      );
                    },
                    onEdit: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Modification sera bientôt disponible'),
                        ),
                      );
                    },
                    onDelete: () {
                      // Simulation de suppression
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Collecte supprimée avec succès'),
                        ),
                      );
                    },
                  ),
                );
              }

              // Chargement des éléments suivants
              if (_visibleItems < data.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              return const SizedBox.shrink();
            },
            childCount:
                _visibleItems < data.length ? _visibleItems + 1 : _visibleItems,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune collecte trouvée',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ajustez vos filtres ou créez une nouvelle collecte.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Création de collecte sera bientôt disponible'),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Créer une collecte'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Nouvelles fonctions helper pour les filtres modernes sur mobile
  Widget _buildModernFilterCard(
    ThemeData theme,
    String title,
    IconData icon, {
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildModernDropdown(
    ThemeData theme,
    String hint,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: DropdownButton<String>(
        value: value.isEmpty ? null : value,
        hint: Text(
          hint,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        isExpanded: true,
        underline: const SizedBox.shrink(),
        icon: Icon(
          Icons.expand_more_rounded,
          color: theme.colorScheme.onSurfaceVariant,
          size: 20,
        ),
        items: options
            .map(
              (option) => DropdownMenuItem(
                value: option.isEmpty ? null : option,
                child: Text(
                  option.isEmpty ? hint : option,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: option.isEmpty
                        ? theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.6)
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildModernDateFilter(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildModernDateField(
            theme,
            'Date de début',
            _filters.dateFrom,
            (date) => setState(() {
              _filters = _filters.copyWith(dateFrom: date);
              _visibleItems = _pageSize;
            }),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildModernDateField(
            theme,
            'Date de fin',
            _filters.dateTo,
            (date) => setState(() {
              _filters = _filters.copyWith(dateTo: date);
              _visibleItems = _pageSize;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildModernDateField(
    ThemeData theme,
    String label,
    DateTime? value,
    ValueChanged<DateTime?> onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value != null ? Formatters.formatDate(value) : label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: value != null
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.6),
                ),
              ),
            ),
            if (value != null)
              InkWell(
                onTap: () => onChanged(null),
                child: Icon(
                  Icons.clear_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernNumericFilters(ThemeData theme) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 8),
      leading: Icon(
        Icons.analytics_rounded,
        color: theme.colorScheme.primary,
        size: 20,
      ),
      title: Text(
        'Filtres numériques',
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        // Poids
        Row(
          children: [
            Expanded(
              child: _buildModernNumericField(
                theme,
                'Poids min (kg)',
                _filters.poidsMin?.toString() ?? '',
                (value) => setState(() {
                  _filters = _filters.copyWith(
                    poidsMin: double.tryParse(value),
                  );
                  _visibleItems = _pageSize;
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernNumericField(
                theme,
                'Poids max (kg)',
                _filters.poidsMax?.toString() ?? '',
                (value) => setState(() {
                  _filters = _filters.copyWith(
                    poidsMax: double.tryParse(value),
                  );
                  _visibleItems = _pageSize;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Montant
        Row(
          children: [
            Expanded(
              child: _buildModernNumericField(
                theme,
                'Montant min (FCFA)',
                _filters.montantMin?.toString() ?? '',
                (value) => setState(() {
                  _filters = _filters.copyWith(
                    montantMin: double.tryParse(value),
                  );
                  _visibleItems = _pageSize;
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernNumericField(
                theme,
                'Montant max (FCFA)',
                _filters.montantMax?.toString() ?? '',
                (value) => setState(() {
                  _filters = _filters.copyWith(
                    montantMax: double.tryParse(value),
                  );
                  _visibleItems = _pageSize;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Contenants
        Row(
          children: [
            Expanded(
              child: _buildModernNumericField(
                theme,
                'Contenants min',
                _filters.contMin?.toString() ?? '',
                (value) => setState(() {
                  _filters = _filters.copyWith(
                    contMin: int.tryParse(value),
                  );
                  _visibleItems = _pageSize;
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernNumericField(
                theme,
                'Contenants max',
                _filters.contMax?.toString() ?? '',
                (value) => setState(() {
                  _filters = _filters.copyWith(
                    contMax: int.tryParse(value),
                  );
                  _visibleItems = _pageSize;
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernNumericField(
    ThemeData theme,
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: TextField(
        controller: TextEditingController(text: value)
          ..selection = TextSelection.fromPosition(
            TextPosition(offset: value.length),
          ),
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        keyboardType: TextInputType.number,
        onChanged: onChanged,
      ),
    );
  }

  /// FloatingActionButton pour l'attribution de produits
  Widget _buildProductAttributionFAB(ThemeData theme) {
    return FloatingActionButton.extended(
      heroTag: 'fab-advanced-product-attribution',
      onPressed: () => _showProductAttributionMenu(theme),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      icon: const Icon(Icons.assignment_turned_in),
      label: const Text('Attribuer'),
      tooltip: 'Attribuer des produits pour traitement',
    );
  }

  /// Affiche le menu d'options d'attribution de produits
  void _showProductAttributionMenu(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Permet un contrôle complet de la hauteur
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6, // Hauteur initiale (60% de l'écran)
        minChildSize: 0.4, // Hauteur minimum (40% de l'écran)
        maxChildSize: 0.9, // Hauteur maximum (90% de l'écran)
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle indicator pour le drag
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Contenu scrollable
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(
                            Icons.assignment_turned_in,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Attribution de produits',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Sélectionnez le type de traitement',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Description supplémentaire
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Choisissez le type de traitement selon la nature des produits à attribuer',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Options d'attribution
                      _buildAttributionOption(
                        theme,
                        'Filtrage',
                        'Produits liquides pour filtrage\nDestiné aux filtreurs qualifiés',
                        Icons.filter_alt,
                        Colors.blue,
                        () => _navigateToAttribution('filtrage'),
                      ),

                      const SizedBox(height: 16),

                      _buildAttributionOption(
                        theme,
                        'Extraction',
                        'Produits bruts pour extraction\nDestiné aux extracteurs spécialisés',
                        Icons.science,
                        Colors.green,
                        () => _navigateToAttribution('extraction'),
                      ),

                      const SizedBox(height: 16),

                      _buildAttributionOption(
                        theme,
                        'Traitement Cire',
                        'Acide pour traitement de la cire\nDestiné aux conditionneurs experts',
                        Icons.cleaning_services,
                        Colors.orange,
                        () => _navigateToAttribution('traitement_cire'),
                      ),

                      const SizedBox(height: 32),

                      // Footer avec informations supplémentaires
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Horaires d\'attribution: 8h - 17h',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.support_agent,
                                  size: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Support: +226 XX XX XX XX',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Espace supplémentaire pour le scroll
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget pour une option d'attribution
  Widget _buildAttributionOption(
    ThemeData theme,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color.withValues(alpha: 0.7),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Navigation vers la page d'attribution selon le type
  void _navigateToAttribution(String type) {
    Navigator.of(context).pop(); // Fermer le modal

    // Navigation vers la page d'extraction si c'est pour extraction
    if (type == 'extraction') {
      Get.to(() => const MainExtractionPage());
    } else {
      // Pour les autres types, afficher un message pour l'instant
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                _getIconForType(type),
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text('Navigation vers attribution: ${_getTitleForType(type)}'),
            ],
          ),
          backgroundColor: _getColorForType(type),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'filtrage':
        return Icons.filter_alt;
      case 'extraction':
        return Icons.science;
      case 'traitement_cire':
        return Icons.cleaning_services;
      default:
        return Icons.assignment;
    }
  }

  String _getTitleForType(String type) {
    switch (type) {
      case 'filtrage':
        return 'Filtrage';
      case 'extraction':
        return 'Extraction';
      case 'traitement_cire':
        return 'Traitement Cire';
      default:
        return 'Attribution';
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'filtrage':
        return Colors.blue;
      case 'extraction':
        return Colors.green;
      case 'traitement_cire':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
