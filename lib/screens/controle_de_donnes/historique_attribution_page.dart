import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/attribution_models_v2.dart';
import 'models/quality_control_models.dart';
import 'models/collecte_models.dart';
import 'services/quality_control_service.dart';
import 'services/firestore_data_service.dart';
import 'services/firestore_attribution_service.dart';

/// Page historique améliorée avec statistiques et données d'attribution
class HistoriqueAttributionPage extends StatefulWidget {
  const HistoriqueAttributionPage({super.key});

  @override
  State<HistoriqueAttributionPage> createState() =>
      _HistoriqueAttributionPageState();
}

class _HistoriqueAttributionPageState extends State<HistoriqueAttributionPage>
    with TickerProviderStateMixin {
  // Services
  final FirestoreAttributionService _attributionService =
      FirestoreAttributionService();
  final QualityControlService _qualityService = QualityControlService();

  // Contrôleurs
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // État
  bool _isLoading = true;
  List<Map<String, dynamic>> _allAttributions = [];
  List<Map<String, dynamic>> _filteredAttributions = [];
  List<QualityControlData> _allControls = [];
  List<QualityControlData> _filteredControls = [];
  Map<String, List<dynamic>> _allCollectes =
      {}; // Toutes les collectes par type
  List<dynamic> _filteredCollectes = []; // Collectes filtrées pour affichage

  // Statistiques
  AttributionStats _stats = AttributionStats(
    totalAttributions: 0,
    totalProduits: 0,
    totalPoids: 0.0,
    repartitionParType: {},
    repartitionParSite: {},
    repartitionParNature: {},
    tendancesMensuelles: {},
    tauxAttribution: 0.0,
    moyennePoidsProduit: 0.0,
  );

  // Statistiques étendues
  int _totalCollectes = 0;
  int _totalControles = 0;
  int _collectesControlees = 0;
  Map<String, int> _repartitionCollectesParType = {};
  Map<ConformityStatus, int> _repartitionControlesParStatut = {};

  // Filtres
  String _searchQuery = '';
  AttributionType? _selectedType;
  String? _selectedSite;
  // ProductNature? _selectedNature; // Non utilisé pour le moment
  DateTimeRange? _selectedDateRange;
  bool _showFilters = false;

  // Vue
  // int _selectedTabIndex = 0; // Non utilisé - géré par TabController
  String _sortBy = 'date';
  bool _sortAscending = false;
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    // S'assurer que le TabController est correctement initialisé pour 5 onglets
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: 0, // Commencer au premier onglet
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scrollController.addListener(_onScroll);
    _loadData();
  }

  @override
  void dispose() {
    // Disposer des contrôleurs de manière sécurisée
    if (_tabController.index < _tabController.length) {
      _tabController.dispose();
    }
    _fadeController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final bool shouldShow = _scrollController.offset > 300;
    if (_showScrollToTop != shouldShow) {
      setState(() => _showScrollToTop = shouldShow);
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      if (kDebugMode) {
        print('');
        print('🔍 HISTORIQUE: DÉBUT DU CHARGEMENT DES DONNÉES RÉELLES');
        print('🔍 HISTORIQUE: AUCUNE DONNÉE FICTIVE - TOUT DEPUIS FIRESTORE');
        print('');

        // Vérification de la session utilisateur
        print('👤 HISTORIQUE: Vérification session utilisateur...');
        try {
          // Essayons d'accéder aux informations de session
          print(
              '   📍 Service d\'attribution initialisé: ${_attributionService.toString()}');
        } catch (e) {
          print('   ❌ Erreur accès session: $e');
        }
      }

      // Charger les attributions avec logs détaillés
      if (kDebugMode) {
        print('📊 HISTORIQUE: Chargement des attributions...');
      }

      // Get extraction attributions using streams converted to lists
      final extractionStream = _attributionService.getAttributionsPourType(
          type: AttributionType.extraction);
      final extractionAttributions = await extractionStream.first;
      if (kDebugMode) {
        print('   ✅ Attributions EXTRACTION: ${extractionAttributions.length}');
      }

      final filtrageStream = _attributionService.getAttributionsPourType(
          type: AttributionType.filtration);
      final filtrageAttributions = await filtrageStream.first;
      if (kDebugMode) {
        print('   ✅ Attributions FILTRAGE: ${filtrageAttributions.length}');
      }

      final cireStream = _attributionService.getAttributionsPourType(
          type: AttributionType.traitementCire);
      final cireAttributions = await cireStream.first;
      if (kDebugMode) {
        print('   ✅ Attributions CIRE: ${cireAttributions.length}');
      }

      _allAttributions = [
        ...extractionAttributions,
        ...filtrageAttributions,
        ...cireAttributions,
      ];

      // ⚠️ FALLBACK: Si aucune attribution trouvée avec la méthode standard
      if (_allAttributions.isEmpty) {
        if (kDebugMode) {
          print(
              '⚠️ HISTORIQUE: AUCUNE ATTRIBUTION TROUVÉE avec la méthode par site');
          print('   🔄 Tentative de récupération globale de TOUS les sites...');
        }

        try {
          // Fallback: get all attributions from all types
          final allExtractionStream = _attributionService
              .getAttributionsPourType(type: AttributionType.extraction);
          final allFiltrageStream = _attributionService.getAttributionsPourType(
              type: AttributionType.filtration);
          final allCireStream = _attributionService.getAttributionsPourType(
              type: AttributionType.traitementCire);

          final results = await Future.wait([
            allExtractionStream.first,
            allFiltrageStream.first,
            allCireStream.first,
          ]);

          _allAttributions = [
            ...results[0],
            ...results[1],
            ...results[2],
          ];

          if (kDebugMode) {
            print(
                '   ✅ Récupération globale: ${_allAttributions.length} attributions trouvées');
            if (_allAttributions.isNotEmpty) {
              print('   📝 Première attribution globale:');
              final first = _allAttributions.first;
              print('      - ID: ${first['id']}');
              print('      - Type: ${first['type']}');
              print('      - Site origine: ${first['source']?['site']}');
              print('      - Site destination: ${first['siteDestination']}');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('   ❌ Erreur récupération globale: $e');
          }
        }

        // Si toujours aucune attribution
        if (_allAttributions.isEmpty) {
          if (kDebugMode) {
            print('');
            print('❌ HISTORIQUE: AUCUNE ATTRIBUTION TROUVÉE NULLE PART');
            print('   🔍 Causes possibles:');
            print('   1. Site utilisateur non configuré');
            print('   2. Collections Firestore vides');
            print('   3. Permissions Firestore insuffisantes');
            print('   4. Aucune attribution créée dans l\'app');
            print('');
            print(
                '   💡 Solution: Créez des attributions via "Attribution Intelligente"');
            print(
                '   📍 TOUTES les données viennent de Firestore - AUCUNE donnée fictive');
            print('');
          }
        }
      }

      if (kDebugMode) {
        print(
            '📊 HISTORIQUE: Total attributions chargées: ${_allAttributions.length}');
        if (_allAttributions.isNotEmpty) {
          print('   📝 Première attribution:');
          final first = _allAttributions.first;
          print('      - ID: ${first['id']}');
          print('      - Type: ${first['type']}');
          print('      - Site origine: ${first['source']?['site']}');
          print('      - Site destination: ${first['siteDestination']}');
          print('      - Date création: ${first['dateAttribution']}');
          print(
              '      - Contenants: ${(first['listeContenants'] as List?)?.length ?? 0}');
          print(
              '      - Poids: ${first['statistiques']?['poidsTotalEstime'] ?? 0.0} kg');
        }
      }

      // Charger les contrôles qualité avec logs
      if (kDebugMode) {
        print('🔬 HISTORIQUE: Chargement des contrôles qualité...');
      }

      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 365));
      _allControls =
          _qualityService.getQualityControlsByDateRange(startDate, endDate);

      if (kDebugMode) {
        print('   ✅ Contrôles qualité chargés: ${_allControls.length}');
        print(
            '   📅 Période: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}');
      }

      // 📦 NOUVEAU: Charger toutes les données reçues (collectes)
      if (kDebugMode) {
        print('📦 HISTORIQUE: Chargement des données reçues (collectes)...');
      }

      try {
        final rawCollectes =
            await FirestoreDataService.getCollectesFromFirestore();
        _allCollectes = rawCollectes.map(
            (key, value) => MapEntry(key.toString(), value.cast<dynamic>()));

        if (kDebugMode) {
          print('   ✅ Collections chargées:');
          _allCollectes.forEach((type, collectes) {
            print('      - $type: ${collectes.length} collectes');
          });

          final totalCollectes = _allCollectes.values
              .fold<int>(0, (sum, list) => sum + list.length);
          print('   📊 Total collectes: $totalCollectes');
        }
      } catch (e) {
        if (kDebugMode) {
          print('   ❌ Erreur chargement collectes: $e');
        }
        _allCollectes = {};
      }

      // Calculer les statistiques avec logs
      if (kDebugMode) {
        print('📊 HISTORIQUE: Calcul des statistiques...');
      }
      _calculateStats();
      _calculateExtendedStats();

      if (kDebugMode) {
        print('   ✅ Statistiques calculées:');
        print('      - Total attributions: ${_stats.totalAttributions}');
        print('      - Total produits: ${_stats.totalProduits}');
        print(
            '      - Poids total: ${_stats.totalPoids.toStringAsFixed(1)} kg');
        print(
            '      - Taux attribution: ${_stats.tauxAttribution.toStringAsFixed(1)}%');
        print('      - Répartition par type: ${_stats.repartitionParType}');
        print('      - Répartition par site: ${_stats.repartitionParSite}');
      }

      // Appliquer les filtres
      _applyFilters();

      if (kDebugMode) {
        print('🔍 HISTORIQUE: Filtrage terminé');
        print('   ✅ Attributions filtrées: ${_filteredAttributions.length}');
        print('');
        print('🎉 HISTORIQUE: CHARGEMENT TERMINÉ AVEC SUCCÈS');
        print('🎉 HISTORIQUE: CHARGEMENT TERMINÉ AVEC SUCCÈS');
        print('');
      }

      await Future.delayed(const Duration(milliseconds: 500));
      _fadeController.forward();
    } catch (e) {
      if (kDebugMode) {
        print('❌ HISTORIQUE: Erreur chargement: $e');
        print('   Stack trace: ${e.toString()}');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateStats() {
    if (kDebugMode) {
      print('📊 HISTORIQUE: _calculateStats() appelée');
      print(
          '   📊 Nombre d\'attributions à analyser: ${_allAttributions.length}');
    }

    if (_allAttributions.isEmpty) {
      if (kDebugMode) {
        print('   ⚠️ Aucune attribution trouvée - statistiques à zéro');
      }
      _stats = AttributionStats(
        totalAttributions: 0,
        totalProduits: 0,
        totalPoids: 0.0,
        repartitionParType: {},
        repartitionParSite: {},
        repartitionParNature: {},
        tendancesMensuelles: {},
        tauxAttribution: 0.0,
        moyennePoidsProduit: 0.0,
      );
      return;
    }

    // Calculs de base
    final totalAttributions = _allAttributions.length;
    final totalProduits = _allAttributions.fold<int>(0, (sum, attr) {
      final length = (attr['listeContenants'] as List?)?.length ?? 0;
      return sum + length;
    });
    final totalPoids = _allAttributions.fold<double>(
        0.0,
        (sum, attr) =>
            sum +
            (attr['statistiques']?['poidsTotalEstime'] as double? ?? 0.0));

    // Répartition par type
    final repartitionParType = <AttributionType, int>{};
    for (final attr in _allAttributions) {
      final typeStr = attr['type'] as String?;
      AttributionType? type;
      if (typeStr != null) {
        type = AttributionType.values.firstWhere(
          (t) => t.value == typeStr,
          orElse: () => AttributionType.extraction,
        );
      }
      if (type != null) {
        repartitionParType[type] = (repartitionParType[type] ?? 0) + 1;
      }
    }

    // Répartition par site de destination
    final repartitionParSite = <String, int>{};
    for (final attr in _allAttributions) {
      final site = attr['siteDestination'] as String? ?? 'Non spécifié';
      repartitionParSite[site] = (repartitionParSite[site] ?? 0) + 1;
    }

    // Tendances mensuelles (6 derniers mois)
    final tendancesMensuelles = <String, int>{};
    final now = DateTime.now();
    for (int i = 0; i < 6; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = DateFormat('MM/yyyy').format(month);
      tendancesMensuelles[monthKey] = 0;
    }

    for (final attr in _allAttributions) {
      final dateAttr = attr['dateAttribution'];
      DateTime? date;
      if (dateAttr is Timestamp) {
        date = dateAttr.toDate();
      } else if (dateAttr is DateTime) {
        date = dateAttr;
      }

      if (date != null) {
        final monthKey = DateFormat('MM/yyyy').format(date);
        if (tendancesMensuelles.containsKey(monthKey)) {
          tendancesMensuelles[monthKey] = tendancesMensuelles[monthKey]! + 1;
        }
      }
    }

    // Taux d'attribution (attributions / contrôles)
    final tauxAttribution = _allControls.isNotEmpty
        ? (totalAttributions / _allControls.length) * 100
        : 0.0;

    // Moyenne poids par produit
    final moyennePoidsProduit =
        totalProduits > 0 ? totalPoids / totalProduits : 0.0;

    _stats = AttributionStats(
      totalAttributions: totalAttributions,
      totalProduits: totalProduits,
      totalPoids: totalPoids,
      repartitionParType: repartitionParType,
      repartitionParSite: repartitionParSite,
      repartitionParNature: {}, // À calculer depuis les produits si nécessaire
      tendancesMensuelles: tendancesMensuelles,
      tauxAttribution: tauxAttribution,
      moyennePoidsProduit: moyennePoidsProduit,
    );
  }

  void _calculateExtendedStats() {
    if (kDebugMode) {
      print('📊 HISTORIQUE: _calculateExtendedStats() appelée');
    }

    // Statistiques des collectes
    _totalCollectes =
        _allCollectes.values.fold<int>(0, (sum, list) => sum + list.length);
    _repartitionCollectesParType = {};
    _collectesControlees = 0;

    _allCollectes.forEach((type, collectes) {
      _repartitionCollectesParType[type] = collectes.length;

      // Compter les collectes contrôlées
      for (final collecte in collectes) {
        final contenants = _getContenantsFromCollecte(collecte);
        bool hasControlledContainers = false;
        for (final contenant in contenants) {
          final controlInfo = contenant['controlInfo'];
          if (controlInfo != null && controlInfo.isControlled == true) {
            hasControlledContainers = true;
            break;
          }
        }
        if (hasControlledContainers) {
          _collectesControlees++;
        }
      }
    });

    // Statistiques des contrôles qualité
    _totalControles = _allControls.length;
    _repartitionControlesParStatut = {};

    for (final control in _allControls) {
      final statut = control.conformityStatus;
      _repartitionControlesParStatut[statut] =
          (_repartitionControlesParStatut[statut] ?? 0) + 1;
    }

    if (kDebugMode) {
      print('   📊 Statistiques étendues:');
      print('      - Total collectes: $_totalCollectes');
      print('      - Collectes contrôlées: $_collectesControlees');
      print('      - Total contrôles: $_totalControles');
      print('      - Répartition collectes: $_repartitionCollectesParType');
      print('      - Répartition contrôles: $_repartitionControlesParStatut');
    }
  }

  void _applyFilters() {
    // Initialiser les listes filtrées
    _filteredControls = List.from(_allControls);
    _filteredCollectes = [];

    _filteredAttributions = _allAttributions.where((attribution) {
      // Recherche textuelle
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final id = (attribution['id'] as String? ?? '').toLowerCase();
        final siteDestination =
            (attribution['siteDestination'] as String? ?? '').toLowerCase();
        final siteOrigine =
            (attribution['source']?['site'] as String? ?? '').toLowerCase();

        if (!id.contains(query) &&
            !siteDestination.contains(query) &&
            !siteOrigine.contains(query)) {
          return false;
        }
      }

      // Filtre type
      if (_selectedType != null) {
        final typeStr = attribution['type'] as String?;
        if (typeStr != _selectedType?.value) {
          return false;
        }
      }

      // Filtre site
      if (_selectedSite != null) {
        final siteDestination = attribution['siteDestination'] as String?;
        if (siteDestination != _selectedSite) {
          return false;
        }
      }

      // Filtre date
      if (_selectedDateRange != null) {
        final dateAttr = attribution['dateAttribution'];
        DateTime? date;
        if (dateAttr is Timestamp) {
          date = dateAttr.toDate();
        } else if (dateAttr is DateTime) {
          date = dateAttr;
        }

        if (date != null) {
          if (date.isBefore(_selectedDateRange!.start) ||
              date.isAfter(_selectedDateRange!.end)) {
            return false;
          }
        }
      }

      return true;
    }).toList();

    // Tri
    _filteredAttributions.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'date':
          final dateA = _getDateFromAttribution(a);
          final dateB = _getDateFromAttribution(b);
          comparison = dateA.compareTo(dateB);
          break;
        case 'site':
          final siteA = a['siteDestination'] as String? ?? '';
          final siteB = b['siteDestination'] as String? ?? '';
          comparison = siteA.compareTo(siteB);
          break;
        case 'type':
          final typeA = a['typeLabel'] as String? ?? '';
          final typeB = b['typeLabel'] as String? ?? '';
          comparison = typeA.compareTo(typeB);
          break;
        case 'poids':
          final poidsA =
              a['statistiques']?['poidsTotalEstime'] as double? ?? 0.0;
          final poidsB =
              b['statistiques']?['poidsTotalEstime'] as double? ?? 0.0;
          comparison = poidsA.compareTo(poidsB);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    // 🆕 Filtrer aussi les contrôles qualité
    _filteredControls = _allControls.where((control) {
      // Recherche textuelle
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!control.producer.toLowerCase().contains(query) &&
            !control.containerCode.toLowerCase().contains(query) &&
            !control.apiaryVillage.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Filtre date
      if (_selectedDateRange != null) {
        if (control.receptionDate.isBefore(_selectedDateRange!.start) ||
            control.receptionDate.isAfter(_selectedDateRange!.end)) {
          return false;
        }
      }

      return true;
    }).toList();

    // 🆕 Filtrer les collectes
    _filteredCollectes = [];
    _allCollectes.forEach((type, collectes) {
      for (final collecte in collectes) {
        bool matches = true;

        // Recherche textuelle
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          // Adapter selon le type de collecte
          String searchText = '';

          // Propriétés communes à toutes les collectes
          if (collecte.technicien != null) {
            searchText += collecte.technicien!.toLowerCase();
          }

          // Propriétés spécifiques selon le type
          if (collecte is Recolte) {
            if (collecte.village != null) {
              searchText += ' ${collecte.village!.toLowerCase()}';
            }
            if (collecte.commune != null) {
              searchText += ' ${collecte.commune!.toLowerCase()}';
            }
          } else if (collecte is Scoop) {
            if (collecte.village != null) {
              searchText += ' ${collecte.village!.toLowerCase()}';
            }
            searchText += ' ${collecte.scoopNom.toLowerCase()}';
          } else if (collecte is Individuel) {
            if (collecte.village != null) {
              searchText += ' ${collecte.village!.toLowerCase()}';
            }
            searchText += ' ${collecte.nomProducteur.toLowerCase()}';
          } else if (collecte is Miellerie) {
            searchText += ' ${collecte.localite.toLowerCase()}';
            searchText += ' ${collecte.collecteurNom.toLowerCase()}';
            searchText += ' ${collecte.miellerieNom.toLowerCase()}';
          }

          if (searchText.isNotEmpty && !searchText.contains(query)) {
            matches = false;
          }
        }

        // Filtre date
        if (_selectedDateRange != null && matches) {
          final collecteDate = collecte.date;
          if (collecteDate != null) {
            if (collecteDate.isBefore(_selectedDateRange!.start) ||
                collecteDate.isAfter(_selectedDateRange!.end)) {
              matches = false;
            }
          }
        }

        if (matches) {
          _filteredCollectes.add(collecte);
        }
      }
    });

    setState(() {});
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _applyFilters();
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Colors.deepPurple.shade700,
                ),
          ),
          child: child!,
        );
      },
    );

    if (range != null) {
      setState(() => _selectedDateRange = range);
      _applyFilters();
    }
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedType = null;
      _selectedSite = null;
      // _selectedNature = null; // Non utilisé
      _selectedDateRange = null;
      _searchController.clear();
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Vérification de sécurité pour éviter les erreurs de TabController
    if (_tabController.length != 5) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Historique & Statistiques'),
          backgroundColor: Colors.deepPurple.shade700,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initialisation en cours...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Historique & Statistiques',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon:
                Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip:
                _showFilters ? 'Masquer les filtres' : 'Afficher les filtres',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Vue d\'ensemble'),
            Tab(icon: Icon(Icons.assignment), text: 'Attributions'),
            Tab(icon: Icon(Icons.science), text: 'Contrôles Qualité'),
            Tab(icon: Icon(Icons.inventory), text: 'Données Reçues'),
            Tab(icon: Icon(Icons.timeline), text: 'Chronologie'),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoadingView()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  if (_showFilters) _buildFiltersSection(theme, isMobile),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        try {
                          return TabBarView(
                            controller: _tabController,
                            children: [
                              _buildOverviewTab(theme, isMobile),
                              _buildAttributionsTab(theme, isMobile),
                              _buildControlsTab(theme, isMobile),
                              _buildCollectesTab(theme, isMobile),
                              _buildTimelineTab(theme, isMobile),
                            ],
                          );
                        } catch (e) {
                          if (kDebugMode) {
                            print('❌ HISTORIQUE: Erreur TabBarView: $e');
                          }
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Erreur de chargement',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Veuillez redémarrer l\'application',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Retour'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton(
              heroTag: 'fab-scroll-top-historique-attribution',
              onPressed: _scrollToTop,
              backgroundColor: Colors.deepPurple.shade700,
              foregroundColor: Colors.white,
              child: const Icon(Icons.keyboard_arrow_up),
            )
          : null,
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(Colors.deepPurple.shade700),
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement des données historiques...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(ThemeData theme, bool isMobile) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: Colors.deepPurple.shade700),
              const SizedBox(width: 8),
              Text(
                'Filtres avancés',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple.shade700,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text('Effacer'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par ID, site...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 12),
          if (isMobile) ..._buildMobileFilters() else ..._buildDesktopFilters(),
        ],
      ),
    );
  }

  List<Widget> _buildMobileFilters() {
    return [
      _buildTypeFilter(),
      const SizedBox(height: 12),
      _buildSiteFilter(),
      const SizedBox(height: 12),
      _buildDateRangeFilter(),
    ];
  }

  List<Widget> _buildDesktopFilters() {
    return [
      Row(
        children: [
          Expanded(child: _buildTypeFilter()),
          const SizedBox(width: 12),
          Expanded(child: _buildSiteFilter()),
          const SizedBox(width: 12),
          Expanded(child: _buildDateRangeFilter()),
        ],
      ),
    ];
  }

  Widget _buildTypeFilter() {
    return DropdownButtonFormField<AttributionType?>(
      value: _selectedType,
      decoration: const InputDecoration(
        labelText: 'Type d\'attribution',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Tous les types')),
        DropdownMenuItem(
          value: AttributionType.extraction,
          child: Row(
            children: [
              Icon(Icons.science, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Text('Extraction'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: AttributionType.filtration,
          child: Row(
            children: [
              Icon(Icons.filter_alt, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text('Filtrage'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: AttributionType.traitementCire,
          child: Row(
            children: [
              Icon(Icons.texture, color: Colors.brown, size: 20),
              const SizedBox(width: 8),
              const Text('Traitement Cire'),
            ],
          ),
        ),
      ],
      onChanged: (value) {
        setState(() => _selectedType = value);
        _applyFilters();
      },
    );
  }

  Widget _buildSiteFilter() {
    final sites = _allAttributions
        .map((a) => a['siteDestination'] as String? ?? 'Non spécifié')
        .toSet()
        .toList()
      ..sort();

    return DropdownButtonFormField<String?>(
      value: _selectedSite,
      decoration: const InputDecoration(
        labelText: 'Site de destination',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Tous les sites')),
        ...sites.map((site) => DropdownMenuItem(
              value: site,
              child: Text(site),
            )),
      ],
      onChanged: (value) {
        setState(() => _selectedSite = value);
        _applyFilters();
      },
    );
  }

  Widget _buildDateRangeFilter() {
    return InkWell(
      onTap: _selectDateRange,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Période',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Row(
          children: [
            Icon(Icons.date_range, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedDateRange != null
                    ? '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}'
                    : 'Sélectionner une période',
                style: TextStyle(
                  color: _selectedDateRange != null
                      ? Colors.black
                      : Colors.grey.shade600,
                ),
              ),
            ),
            if (_selectedDateRange != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  setState(() => _selectedDateRange = null);
                  _applyFilters();
                },
              ),
          ],
        ),
      ),
    );
  }

  // Vue d'ensemble avec statistiques
  Widget _buildOverviewTab(ThemeData theme, bool isMobile) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistiques principales
          _buildMainStatsCards(theme, isMobile),
          const SizedBox(height: 24),

          // 🆕 Statistiques étendues
          _buildExtendedStatsCards(theme, isMobile),
          const SizedBox(height: 24),

          // Graphiques et tendances
          _buildChartsSection(theme, isMobile),
          const SizedBox(height: 24),

          // Répartitions
          _buildDistributionSection(theme, isMobile),
        ],
      ),
    );
  }

  Widget _buildMainStatsCards(ThemeData theme, bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                'Attributions',
                _stats.totalAttributions.toString(),
                Icons.assignment,
                Colors.deepPurple,
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard(
                'Produits',
                _stats.totalProduits.toString(),
                Icons.inventory,
                Colors.blue,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                'Poids Total',
                '${_stats.totalPoids.toStringAsFixed(1)} kg',
                Icons.scale,
                Colors.green,
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard(
                'Taux Attribution',
                '${_stats.tauxAttribution.toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.orange,
              )),
            ],
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
              child: _buildStatCard(
            'Total Attributions',
            _stats.totalAttributions.toString(),
            Icons.assignment,
            Colors.deepPurple,
          )),
          const SizedBox(width: 16),
          Expanded(
              child: _buildStatCard(
            'Produits Attribués',
            _stats.totalProduits.toString(),
            Icons.inventory,
            Colors.blue,
          )),
          const SizedBox(width: 16),
          Expanded(
              child: _buildStatCard(
            'Poids Total',
            '${_stats.totalPoids.toStringAsFixed(1)} kg',
            Icons.scale,
            Colors.green,
          )),
          const SizedBox(width: 16),
          Expanded(
              child: _buildStatCard(
            'Taux d\'Attribution',
            '${_stats.tauxAttribution.toStringAsFixed(1)}%',
            Icons.trending_up,
            Colors.orange,
          )),
          const SizedBox(width: 16),
          Expanded(
              child: _buildStatCard(
            'Moyenne/Produit',
            '${_stats.moyennePoidsProduit.toStringAsFixed(1)} kg',
            Icons.balance,
            Colors.purple,
          )),
        ],
      );
    }
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtendedStatsCards(ThemeData theme, bool isMobile) {
    final collectesControlees = _collectesControlees;
    final tauxControle = _totalCollectes > 0
        ? (collectesControlees / _totalCollectes * 100).toStringAsFixed(1)
        : '0.0';

    final controlesConformes =
        _repartitionControlesParStatut[ConformityStatus.conforme] ?? 0;
    final tauxConformite = _totalControles > 0
        ? (controlesConformes / _totalControles * 100).toStringAsFixed(1)
        : '0.0';

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Données Reçues & Contrôles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Collectes',
                  _totalCollectes.toString(),
                  Icons.inventory,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Contrôlées',
                  '$collectesControlees ($tauxControle%)',
                  Icons.verified,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Contrôles QC',
                  _totalControles.toString(),
                  Icons.science,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Conformes',
                  '$controlesConformes ($tauxConformite%)',
                  Icons.check_circle,
                  Colors.teal,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Données Reçues & Contrôles Qualité',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Collectes',
                  _totalCollectes.toString(),
                  Icons.inventory,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Collectes Contrôlées',
                  '$collectesControlees ($tauxControle%)',
                  Icons.verified,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Contrôles Qualité',
                  _totalControles.toString(),
                  Icons.science,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Contrôles Conformes',
                  '$controlesConformes ($tauxConformite%)',
                  Icons.check_circle,
                  Colors.teal,
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildChartsSection(ThemeData theme, bool isMobile) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.deepPurple.shade700),
                const SizedBox(width: 8),
                Text(
                  'Tendances (6 derniers mois)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTrendChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    final sortedMonths = _stats.tendancesMensuelles.keys.toList()
      ..sort((a, b) {
        final dateA = DateFormat('MM/yyyy').parse(a);
        final dateB = DateFormat('MM/yyyy').parse(b);
        return dateA.compareTo(dateB);
      });

    if (sortedMonths.isEmpty) {
      return const Center(
        child: Text('Aucune donnée disponible'),
      );
    }

    final maxValue =
        _stats.tendancesMensuelles.values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: sortedMonths.map((month) {
          final value = _stats.tendancesMensuelles[month]!;
          final height = maxValue > 0 ? (value / maxValue) * 150 : 0.0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (value > 0) ...[
                    Text(
                      value.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    month,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDistributionSection(ThemeData theme, bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: _buildDistributionCard(
            'Répartition par Type',
            Icons.category,
            _stats.repartitionParType.map((key, value) => MapEntry(
                  _getTypeLabel(key),
                  value,
                )),
            _getTypeColors(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDistributionCard(
            'Sites de Destination',
            Icons.location_on,
            _stats.repartitionParSite,
            _getSiteColors(),
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionCard(
    String title,
    IconData icon,
    Map<String, int> data,
    Map<String, Color> colors,
  ) {
    final total = data.values.fold<int>(0, (sum, value) => sum + value);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.deepPurple.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (data.isEmpty)
              const Center(child: Text('Aucune donnée'))
            else
              ...data.entries.map((entry) {
                final percentage =
                    total > 0 ? (entry.value / total) * 100 : 0.0;
                final color = colors[entry.key] ?? Colors.grey;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(AttributionType type) {
    return type.label;
  }

  /// Helper method to extract date from attribution map
  DateTime _getDateFromAttribution(Map<String, dynamic> attribution) {
    final dateAttr = attribution['dateAttribution'];
    if (dateAttr is Timestamp) {
      return dateAttr.toDate();
    } else if (dateAttr is DateTime) {
      return dateAttr;
    }
    return DateTime(1970); // Fallback date
  }

  Map<String, Color> _getTypeColors() {
    return {
      'Extraction': Colors.green,
      'Filtrage': Colors.blue,
      'Traitement Cire': Colors.brown,
    };
  }

  Map<String, Color> _getSiteColors() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    final sites = _stats.repartitionParSite.keys.toList();
    final result = <String, Color>{};

    for (int i = 0; i < sites.length; i++) {
      result[sites[i]] = colors[i % colors.length];
    }

    return result;
  }

  // Onglet Attributions
  Widget _buildAttributionsTab(ThemeData theme, bool isMobile) {
    if (_filteredAttributions.isEmpty) {
      return _buildEmptyState('Aucune attribution trouvée', Icons.assignment);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _filteredAttributions.length,
      itemBuilder: (context, index) {
        final attribution = _filteredAttributions[index];
        return _buildAttributionCard(attribution, theme, isMobile);
      },
    );
  }

  Widget _buildAttributionCard(
      Map<String, dynamic> attribution, ThemeData theme, bool isMobile) {
    final typeStr = attribution['type'] as String?;
    AttributionType type = AttributionType.extraction; // default
    if (typeStr != null) {
      type = AttributionType.values.firstWhere(
        (t) => t.value == typeStr,
        orElse: () => AttributionType.extraction,
      );
    }
    final typeColor = _getTypeColor(type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getTypeIcon(type), size: 16, color: typeColor),
                      const SizedBox(width: 4),
                      Text(
                        _getTypeLabel(type),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd/MM/yyyy à HH:mm')
                      .format(_getDateFromAttribution(attribution)),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ID et statut
            Row(
              children: [
                Expanded(
                  child: Text(
                    attribution['id'] as String? ?? 'ID non disponible',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                            attribution['statut'] as String? ?? 'attribue')
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    attribution['statut'] as String? ?? 'Attribué',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(
                          attribution['statut'] as String? ?? 'attribue'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Sites
            Row(
              children: [
                Icon(Icons.arrow_forward,
                    size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${attribution['source']?['site'] as String? ?? 'Non spécifié'} → ${attribution['siteDestination'] as String? ?? 'Non spécifié'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Statistiques
            Row(
              children: [
                _buildInfoChip(Icons.inventory,
                    '${(attribution['listeContenants'] as List?)?.length ?? 0} contenants'),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.scale,
                    '${(attribution['statistiques']?['poidsTotalEstime'] as double? ?? 0.0).toStringAsFixed(1)} kg'),
                if (attribution['commentaires'] != null &&
                    (attribution['commentaires'] as String).isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.info, 'Commentaires'),
                ],
              ],
            ),

            if (attribution['commentaires'] != null &&
                (attribution['commentaires'] as String).isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  attribution['commentaires'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(AttributionType type) {
    switch (type) {
      case AttributionType.extraction:
        return Colors.green;
      case AttributionType.filtration:
        return Colors.blue;
      case AttributionType.traitementCire:
        return Colors.brown;
    }
  }

  IconData _getTypeIcon(AttributionType type) {
    switch (type) {
      case AttributionType.extraction:
        return Icons.science;
      case AttributionType.filtration:
        return Icons.filter_alt;
      case AttributionType.traitementCire:
        return Icons.texture;
    }
  }

  Color _getStatusColor(String statut) {
    switch (statut.toLowerCase()) {
      case 'en_attente_reception':
        return Colors.orange;
      case 'recu':
        return Colors.blue;
      case 'traite':
        return Colors.green;
      case 'annule':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Onglet Contrôles (simplifié)
  Widget _buildControlsTab(ThemeData theme, bool isMobile) {
    if (_allControls.isEmpty) {
      return _buildEmptyState('Aucun contrôle trouvé', Icons.science);
    }

    // Statistiques rapides des contrôles
    final conformeCount = _allControls
        .where((c) => c.conformityStatus == ConformityStatus.conforme)
        .length;
    final tauxConformite = (_allControls.isNotEmpty
        ? (conformeCount / _allControls.length) * 100
        : 0.0);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats rapides
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                'Total Contrôles',
                _allControls.length.toString(),
                Icons.science,
                Colors.blue,
              )),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildStatCard(
                'Conformes',
                conformeCount.toString(),
                Icons.check_circle,
                Colors.green,
              )),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildStatCard(
                'Taux Conformité',
                '${tauxConformite.toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.orange,
              )),
            ],
          ),
          const SizedBox(height: 24),

          // Message d'information
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pour voir les détails complets des contrôles qualité, utilisez la page "Historique des Contrôles" dans le menu principal.',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📦 NOUVEL ONGLET: Données Reçues (Collectes)
  Widget _buildCollectesTab(ThemeData theme, bool isMobile) {
    if (_filteredCollectes.isEmpty) {
      return _buildEmptyState('Aucune collecte trouvée', Icons.inventory);
    }

    return Column(
      children: [
        // En-tête avec statistiques rapides
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              _buildQuickStat(
                  'Total Collectes',
                  _filteredCollectes.length.toString(),
                  Icons.inventory,
                  Colors.blue),
              const SizedBox(width: 16),
              _buildQuickStat('Types', _allCollectes.keys.length.toString(),
                  Icons.category, Colors.green),
              const SizedBox(width: 16),
              _buildQuickStat(
                  'Contrôlées',
                  _getControlledCollectesCount().toString(),
                  Icons.verified,
                  Colors.orange),
            ],
          ),
        ),

        // Liste des collectes avec pagination
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _filteredCollectes.length,
            itemBuilder: (context, index) {
              final collecte = _filteredCollectes[index];
              return _buildCollecteCard(collecte, theme, isMobile);
            },
          ),
        ),
      ],
    );
  }

  // 🕒 NOUVEL ONGLET: Chronologie
  Widget _buildTimelineTab(ThemeData theme, bool isMobile) {
    // Combiner toutes les données avec leurs dates pour une chronologie
    final timelineItems = <TimelineItem>[];

    // Ajouter les attributions
    for (final attribution in _filteredAttributions) {
      final typeLabel = attribution['typeLabel'] as String? ?? 'Attribution';
      final contenants = (attribution['listeContenants'] as List?)?.length ?? 0;
      final siteDestination =
          attribution['siteDestination'] as String? ?? 'Non spécifié';

      timelineItems.add(TimelineItem(
        date: _getDateFromAttribution(attribution),
        type: TimelineItemType.attribution,
        title: 'Attribution $typeLabel',
        subtitle: '$contenants contenants → $siteDestination',
        data: attribution,
      ));
    }

    // Ajouter les contrôles
    for (final control in _filteredControls) {
      timelineItems.add(TimelineItem(
        date: control.receptionDate,
        type: TimelineItemType.control,
        title: 'Contrôle Qualité',
        subtitle: '${control.containerCode} - ${control.producer}',
        data: control,
      ));
    }

    // Ajouter les collectes
    for (final collecte in _filteredCollectes) {
      final date = collecte.date;
      if (date != null) {
        // Récupérer le nom selon le type de collecte
        String nom = 'Nom inconnu';
        if (collecte is Recolte) {
          nom = collecte.technicien ?? 'Technicien inconnu';
        } else if (collecte is Scoop) {
          nom = collecte.scoopNom;
        } else if (collecte is Individuel) {
          nom = collecte.nomProducteur;
        } else if (collecte is Miellerie) {
          nom = collecte.collecteurNom;
        }

        timelineItems.add(TimelineItem(
          date: date,
          type: TimelineItemType.collecte,
          title: 'Collecte ${collecte.runtimeType.toString()}',
          subtitle: nom,
          data: collecte,
        ));
      }
    }

    // Trier par date (plus récent en premier)
    timelineItems.sort((a, b) => b.date.compareTo(a.date));

    if (timelineItems.isEmpty) {
      return _buildEmptyState('Aucune activité trouvée', Icons.timeline);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: timelineItems.length,
      itemBuilder: (context, index) {
        final item = timelineItems[index];
        return _buildTimelineItem(
            item, theme, index == timelineItems.length - 1);
      },
    );
  }

  Widget _buildQuickStat(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  int _getControlledCollectesCount() {
    int count = 0;
    for (final collecte in _filteredCollectes) {
      // Vérifier si la collecte a des contenants contrôlés
      final contenants = _getContenantsFromCollecte(collecte);
      for (final contenant in contenants) {
        final controlInfo = contenant['controlInfo'];
        if (controlInfo != null && controlInfo.isControlled == true) {
          count++;
          break; // Une collecte contrôlée = +1, pas par contenant
        }
      }
    }
    return count;
  }

  Widget _buildCollecteCard(dynamic collecte, ThemeData theme, bool isMobile) {
    final String type = collecte.runtimeType.toString();

    // Récupérer le nom selon le type de collecte
    String nom = 'Nom inconnu';
    String village = 'Village inconnu';

    if (collecte is Recolte) {
      nom = collecte.technicien ?? 'Technicien inconnu';
      village = collecte.village ?? collecte.commune ?? 'Village inconnu';
    } else if (collecte is Scoop) {
      nom = collecte.scoopNom;
      village = collecte.village ?? 'Village inconnu';
    } else if (collecte is Individuel) {
      nom = collecte.nomProducteur;
      village = collecte.village ?? 'Village inconnu';
    } else if (collecte is Miellerie) {
      nom = collecte.collecteurNom;
      village = collecte.localite;
    }

    final DateTime? date = collecte.date;
    final contenants = _getContenantsFromCollecte(collecte);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCollecteTypeColor(type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getCollecteTypeColor(type),
                    ),
                  ),
                ),
                const Spacer(),
                if (date != null)
                  Text(
                    DateFormat('dd/MM/yyyy').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Informations principales
            Text(
              nom,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  village,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Statistiques des contenants
            Row(
              children: [
                _buildInfoChip(
                    Icons.inventory, '${contenants.length} contenants'),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.scale,
                    '${_getTotalWeight(contenants).toStringAsFixed(1)} kg'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(TimelineItem item, ThemeData theme, bool isLast) {
    final color = _getTimelineItemColor(item.type);
    final icon = _getTimelineItemIcon(item.type);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),

        // Content
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('dd/MM HH:mm').format(item.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getCollecteTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'recolte':
        return Colors.green;
      case 'scoop':
        return Colors.blue;
      case 'individuel':
        return Colors.orange;
      case 'miellerie':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getTimelineItemColor(TimelineItemType type) {
    switch (type) {
      case TimelineItemType.attribution:
        return Colors.deepPurple;
      case TimelineItemType.control:
        return Colors.blue;
      case TimelineItemType.collecte:
        return Colors.green;
    }
  }

  IconData _getTimelineItemIcon(TimelineItemType type) {
    switch (type) {
      case TimelineItemType.attribution:
        return Icons.assignment;
      case TimelineItemType.control:
        return Icons.science;
      case TimelineItemType.collecte:
        return Icons.inventory;
    }
  }

  double _getTotalWeight(List<Map<String, dynamic>> contenants) {
    double total = 0.0;
    for (final contenant in contenants) {
      final weight = contenant['poids'] ??
          contenant['quantite'] ??
          contenant['weight'] ??
          0.0;
      if (weight is num) {
        total += weight.toDouble();
      }
    }
    return total;
  }

  /// Récupère les contenants d'une collecte selon son type
  List<Map<String, dynamic>> _getContenantsFromCollecte(dynamic collecte) {
    if (collecte is Recolte) {
      return collecte.contenants
          .map((c) => {
                'id': c.id,
                'typeRuche': c.hiveType,
                'typeContenant': c.containerType,
                'poids': c.weight,
                'weight': c.weight,
                'prixUnitaire': c.unitPrice,
                'montantTotal': c.total,
                'controlInfo': c.controlInfo,
              })
          .toList();
    } else if (collecte is Scoop) {
      return collecte.contenants
          .map((c) => {
                'id': c.id,
                'typeContenant': c.typeContenant,
                'typeMiel': c.typeMiel,
                'quantite': c.quantite,
                'poids': c.quantite,
                'prixUnitaire': c.prixUnitaire,
                'montantTotal': c.montantTotal,
                'predominanceFlorale': c.predominanceFlorale,
                'controlInfo': c.controlInfo,
              })
          .toList();
    } else if (collecte is Individuel) {
      return collecte.contenants
          .map((c) => {
                'id': c.id,
                'typeContenant': c.typeContenant,
                'typeMiel': c.typeMiel,
                'quantite': c.quantite,
                'poids': c.quantite,
                'prixUnitaire': c.prixUnitaire,
                'montantTotal': c.montantTotal,
                'predominanceFlorale': 'Non spécifiée',
                'controlInfo': c.controlInfo,
              })
          .toList();
    } else if (collecte is Miellerie) {
      return collecte.contenants
          .map((c) => {
                'id': c.id,
                'typeContenant': c.typeContenant,
                'typeMiel': c.typeMiel,
                'quantite': c.quantite,
                'poids': c.quantite,
                'prixUnitaire': c.prixUnitaire,
                'montantTotal': c.montantTotal,
                'observations': c.observations,
                'controlInfo': c.controlInfo,
              })
          .toList();
    }
    return [];
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Modifiez vos filtres ou créez de nouvelles attributions',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Modèle pour les éléments de chronologie
class TimelineItem {
  final DateTime date;
  final TimelineItemType type;
  final String title;
  final String subtitle;
  final dynamic data;

  const TimelineItem({
    required this.date,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.data,
  });
}

/// Types d'éléments de chronologie
enum TimelineItemType {
  attribution,
  control,
  collecte,
}

/// Modèle pour les statistiques d'attribution
class AttributionStats {
  final int totalAttributions;
  final int totalProduits;
  final double totalPoids;
  final Map<AttributionType, int> repartitionParType;
  final Map<String, int> repartitionParSite;
  final Map<ProductNature, int> repartitionParNature;
  final Map<String, int> tendancesMensuelles;
  final double tauxAttribution;
  final double moyennePoidsProduit;

  const AttributionStats({
    required this.totalAttributions,
    required this.totalProduits,
    required this.totalPoids,
    required this.repartitionParType,
    required this.repartitionParSite,
    required this.repartitionParNature,
    required this.tendancesMensuelles,
    required this.tauxAttribution,
    required this.moyennePoidsProduit,
  });
}
