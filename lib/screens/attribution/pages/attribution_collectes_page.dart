import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../widgets/collecte_attribution_card.dart';
import '../../controle_de_donnes/models/collecte_models.dart';
import '../../controle_de_donnes/services/firestore_data_service.dart';
import '../services/attribution_collectes_service.dart' as attribution;
import '../../controle_de_donnes/models/attribution_models_v2.dart' as models;
import '../../controle_de_donnes/services/firestore_attribution_service_v2.dart';
library;


/// 🎯 PAGE D'ATTRIBUTION PAR COLLECTES - NOUVELLE GÉNÉRATION
///
/// Cette page affiche les collectes avec leurs produits contrôlés organisés par cartes dépliantes :
/// - 🏭 COLLECTES RÉCOLTES → Produits Bruts (Extraction)
/// - 🥄 COLLECTES SCOOP → Produits Liquides (Filtrage) + Cire (Traitement)
/// - 👤 COLLECTES INDIVIDUELLES → Produits Liquides (Filtrage)
/// - 🍯 COLLECTES MIELLERIE → Produits Liquides (Filtrage)
///
/// Fonctionnalités principales :
/// ✅ Affichage des collectes avec informations détaillées

/// ✅ Cards dépliantes avec produits contrôlés par collecte
/// ✅ Statistiques précises : total reçu, contrôlé, restant
/// ✅ Filtrage par type de collecte et statut
/// ✅ Attribution directe depuis les cartes
/// ✅ Synchronisation en temps réel



class AttributionCollectesPage extends StatefulWidget {
  const AttributionCollectesPage({super.key});

  @override
  State<AttributionCollectesPage> createState() =>
      _AttributionCollectesPageState();
}

class _AttributionCollectesPageState extends State<AttributionCollectesPage>
    with TickerProviderStateMixin {
  // Services
  late final attribution.AttributionCollectesService _attributionService;
  late final FirestoreAttributionServiceV2 _attributionServiceV2;

  // Controllers
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // State management
  final RxBool _isLoading = true.obs;
  final RxMap<Section, List<BaseCollecte>> _collectesData =
      <Section, List<BaseCollecte>>{}.obs;
  final RxMap<String, attribution.CollecteControlInfo> _collectesControlInfo =
      <String, attribution.CollecteControlInfo>{}.obs;
  final RxString _searchQuery = ''.obs;
  final RxInt _selectedTabIndex = 0.obs;
  final RxBool _showOnlyWithProducts = false.obs;

  // Statistiques
  final RxMap<String, CollecteStats> _stats = <String, CollecteStats>{}.obs;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeControllers();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeServices() {
    _attributionService = attribution.AttributionCollectesService();
    _attributionServiceV2 = FirestoreAttributionServiceV2();
  }

  void _initializeControllers() {
    // 4 onglets : Toutes, Récoltes, SCOOP, Individuelles
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      _selectedTabIndex.value = _tabController.index;
    });

    _searchController.addListener(() {
      _searchQuery.value = _searchController.text;
    });
  }

  Future<void> _loadData() async {
    try {
      _isLoading.value = true;

      if (kDebugMode) {
        print('');
        print('🚀 [Attribution Page] ===== DÉBUT CHARGEMENT DES DONNÉES =====');
        print('   📅 Timestamp: ${DateTime.now()}');
        print(
            '   🏪 État actuel des collectes: ${_collectesData.length} sections');
        print(
            '   📊 État actuel des contrôles: ${_collectesControlInfo.length} collectes');
        print('   🔄 Statut loading: ${_isLoading.value}');
      }

      // 1. Charger toutes les collectes depuis Firestore
      if (kDebugMode) {
        print(
            '🔄 [Attribution Page] Chargement des collectes depuis Firestore...');
      }
      final collectesData =
          await FirestoreDataService.getCollectesFromFirestore();
      _collectesData.assignAll(collectesData);

      if (kDebugMode) {
        print('✅ [Attribution Page] Collectes chargées depuis Firestore:');
        for (final entry in collectesData.entries) {
          final section = entry.key;
          final collectes = entry.value;
          print('   📦 ${section.name}: ${collectes.length} collectes');

          // Détail des premières collectes de chaque section
          if (collectes.isNotEmpty) {
            for (int i = 0; i < collectes.length && i < 3; i++) {
              final collecte = collectes[i];
              print(
                  '      - ${collecte.id} (${collecte.site}, ${collecte.date.day}/${collecte.date.month})');
            }
            if (collectes.length > 3) {
              print('      ... et ${collectes.length - 3} autres');
            }
          }
        }
        int totalCollectes = collectesData.values.expand((list) => list).length;
        print('   🎯 TOTAL GÉNÉRAL: $totalCollectes collectes chargées');

        if (totalCollectes == 0) {
          print('   ⚠️ ATTENTION: Aucune collecte trouvée dans Firestore !');
        }
      }

      // 2. Charger les informations de contrôle pour chaque collecte
      if (kDebugMode) {
        print(
            '🔄 [Attribution Page] Chargement des informations de contrôle...');
      }
      await _loadControlInfo();

      // 3. Calculer les statistiques
      if (kDebugMode) {
        print('📊 [Attribution Page] Calcul des statistiques...');
      }
      _calculateStats();

      if (kDebugMode) {
        print('');
        print('✅ [Attribution Page] ===== DONNÉES CHARGÉES AVEC SUCCÈS =====');
        final globalStats = _stats['global'];
        if (globalStats != null) {
          print('📈 [Attribution Page] STATISTIQUES GLOBALES FINALES:');
          print('   📊 Total collectes: ${globalStats.totalCollectes}');
          print(
              '   🎯 Collectes avec produits: ${globalStats.collectesAvecProduits}');
          print('   📦 Total contenants reçus: ${globalStats.totalRecus}');
          print(
              '   ✅ Total contenants contrôlés: ${globalStats.totalControles}');
          print('   ⏳ Total contenants restants: ${globalStats.totalRestants}');
          print(
              '   📊 Taux de contrôle: ${globalStats.tauxControle.toStringAsFixed(1)}%');

          // Analyse des problèmes potentiels
          if (globalStats.totalRecus == 0) {
            print('   ⚠️ PROBLÈME: Aucun contenant déclaré reçu !');
          } else if (globalStats.totalControles == 0) {
            print('   ⚠️ PROBLÈME: Aucun contenant contrôlé !');
          } else if (globalStats.tauxControle < 50) {
            print(
                '   ⚠️ ATTENTION: Taux de contrôle faible (${globalStats.tauxControle.toStringAsFixed(1)}%)');
          } else {
            print('   ✅ Taux de contrôle correct');
          }
        } else {
          print('   ❌ ERREUR: Statistiques globales non disponibles !');
        }

        print(
            '   🔄 Total collectes avec info contrôle: ${_collectesControlInfo.length}');
        print('   📅 Fin du chargement: ${DateTime.now()}');
        print('========================================================');
        print('');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('');
        print('❌❌❌ [Attribution Page] ERREUR CRITIQUE LORS DU CHARGEMENT ❌❌❌');
        print('   🚨 Type d\'erreur: ${e.runtimeType}');
        print('   📝 Message d\'erreur: $e');
        print('   📅 Timestamp: ${DateTime.now()}');
        print('   🔍 État au moment de l\'erreur:');
        print('      - Collectes chargées: ${_collectesData.length} sections');
        print(
            '      - Contrôles chargés: ${_collectesControlInfo.length} collectes');
        print('      - Statut loading: ${_isLoading.value}');
        print('   📍 Stack trace complet:');
        print(stackTrace.toString());
        print(
            '================================================================');
        print('');
      }
      Get.snackbar(
        'Erreur',
        'Impossible de charger les données: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } finally {
      _isLoading.value = false;
      if (kDebugMode) {
        print('🏁 [Attribution Page] Fin chargement des données');
      }
    }
  }

  Future<void> _loadControlInfo() async {
    final Map<String, attribution.CollecteControlInfo> controlInfo = {};

    if (kDebugMode) {
      print('🔄 [Attribution Page] Début chargement informations de contrôle');
      print('   Sections trouvées: ${_collectesData.keys.toList()}');
      int totalCollectes = _collectesData.values.expand((list) => list).length;
      print('   Total collectes à traiter: $totalCollectes');
    }

    // Traiter toutes les collectes de toutes les sections
    for (final entry in _collectesData.entries) {
      final section = entry.key;
      final collectes = entry.value;

      if (kDebugMode) {
        print(
            '📋 [Attribution Page] Traitement section ${section.name}: ${collectes.length} collectes');
      }

      for (final collecte in collectes) {
        try {
          if (kDebugMode) {
            print('🔍 [Attribution Page] Traitement collecte ${collecte.id}');
            print('   Site: ${collecte.site}, Date: ${collecte.date}');
            print('   Type: ${collecte.runtimeType}');
            print('   Contenants déclarés: ${collecte.containersCount}');
          }

          // Récupérer les informations de contrôle pour cette collecte
          final info = await _attributionService.getControlInfoForCollecte(
              collecte.id, collecte);
          controlInfo[collecte.id] = info;

          if (kDebugMode) {
            print(
                '📊 [Attribution Page] Collecte ${collecte.id} (${section.name}): ');
            print('   Total contenants: ${info.totalContainers}');
            print('   Contenants contrôlés: ${info.controlledContainers}');
            print('   Conformes: ${info.conformeCount}');
            print('   Non conformes: ${info.nonConformeCount}');
            print('   Restants: ${info.totalRestants}');
            print(
                '   Produits conformes disponibles: ${info.produitsConformesDisponibles.length}');

            // 🔍 LOGS DÉTAILLÉS DES POIDS
            print('   💰 POIDS DÉTAILLÉS (depuis Firestore):');
            print(
                '      - Poids total: ${info.poidsTotal.toStringAsFixed(2)} kg');
            print(
                '      - Poids conformes: ${info.poidsConformes.toStringAsFixed(2)} kg');
            print(
                '      - Poids non conformes: ${info.poidsNonConformes.toStringAsFixed(2)} kg');

            // Détail par contenant contrôlé
            if (info.controlsByContainer.isNotEmpty) {
              print('   📦 DÉTAIL PAR CONTENANT:');
              info.controlsByContainer.forEach((containerCode, control) {
                print(
                    '      - $containerCode: ${control.totalWeight}kg total, ${control.honeyWeight}kg miel, ${control.conformityStatus}');
              });
            } else {
              print('   ⚠️ AUCUN CONTRÔLE DÉTAILLÉ TROUVÉ pour cette collecte');
            }

            // Comparaison avec les contenants déclarés
            print('   🔍 COMPARAISON:');
            print('      - Contenants déclarés: ${collecte.containersCount}');
            print('      - Contenants contrôlés: ${info.controlledContainers}');
            print(
                '      - Différence: ${(collecte.containersCount ?? 0) - info.controlledContainers}');

            if (info.produitsConformesDisponibles.isNotEmpty) {
              print('   🎯 Détails des produits conformes:');
              for (final produit in info.produitsConformesDisponibles) {
                print(
                    '     - Code: ${produit.containerCode}, Qualité: ${produit.quality}');
              }
            }
          }
        } catch (e, stackTrace) {
          if (kDebugMode) {
            print(
                '❌ [Attribution Page] ERREUR récupération contrôle pour ${collecte.id}');
            print('   🔍 Détails de la collecte:');
            print('      - ID: ${collecte.id}');
            print('      - Site: ${collecte.site}');
            print('      - Date: ${collecte.date}');
            print('      - Type: ${collecte.runtimeType}');
            print('      - Contenants déclarés: ${collecte.containersCount}');
            print('   ❌ Erreur: $e');
            print('   📍 Stack trace: $stackTrace');
            print('   🔧 Tentative de récupération avec info vide...');
          }
          // Créer une info vide en cas d'erreur
          controlInfo[collecte.id] = attribution.CollecteControlInfo(
            collecteId: collecte.id,
            totalContainers: collecte.containersCount ?? 0,
            controlledContainers: 0,
            conformeCount: 0,
            nonConformeCount: 0,
            controlsByContainer: {},
            lastUpdated: DateTime.now(),
          );
        }
      }
    }

    _collectesControlInfo.assignAll(controlInfo);

    if (kDebugMode) {
      print('✅ [Attribution Page] Fin chargement informations de contrôle');
      print('   Total infos chargées: ${controlInfo.length}');

      int totalConformes =
          controlInfo.values.fold(0, (sum, info) => sum + info.conformeCount);
      print('   Total produits conformes: $totalConformes');

      final collectesAvecProduits =
          controlInfo.values.where((info) => info.conformeCount > 0).length;
      print('   Collectes avec produits conformes: $collectesAvecProduits');
    }
  }

  void _calculateStats() {
    final Map<String, CollecteStats> stats = {};

    // Statistiques par section
    for (final entry in _collectesData.entries) {
      final section = entry.key;
      final collectes = entry.value;

      int totalCollectes = collectes.length;
      int totalRecus = 0;
      int totalControles = 0;
      int totalRestants = 0;
      int collectesAvecProduits = 0;

      for (final collecte in collectes) {
        final controlInfo = _collectesControlInfo[collecte.id];
        if (controlInfo != null) {
          totalRecus += controlInfo.totalContainers;
          totalControles += controlInfo.controlledContainers;
          totalRestants += controlInfo.totalRestants;

          if (controlInfo.controlledContainers > 0) {
            collectesAvecProduits++;
          }
        }
      }

      stats[section.name] = CollecteStats(
        totalCollectes: totalCollectes,
        collectesAvecProduits: collectesAvecProduits,
        totalRecus: totalRecus,
        totalControles: totalControles,
        totalRestants: totalRestants,
        tauxControle: totalRecus > 0 ? (totalControles / totalRecus * 100) : 0,
      );
    }

    // Statistiques globales
    final globalStats = stats.values.fold(
      CollecteStats(
        totalCollectes: 0,
        collectesAvecProduits: 0,
        totalRecus: 0,
        totalControles: 0,
        totalRestants: 0,
        tauxControle: 0,
      ),
      (acc, stat) => CollecteStats(
        totalCollectes: acc.totalCollectes + stat.totalCollectes,
        collectesAvecProduits:
            acc.collectesAvecProduits + stat.collectesAvecProduits,
        totalRecus: acc.totalRecus + stat.totalRecus,
        totalControles: acc.totalControles + stat.totalControles,
        totalRestants: acc.totalRestants + stat.totalRestants,
        tauxControle: 0, // Sera recalculé
      ),
    );

    globalStats.tauxControle = globalStats.totalRecus > 0
        ? (globalStats.totalControles / globalStats.totalRecus * 100)
        : 0;

    stats['global'] = globalStats;
    _stats.assignAll(stats);
  }

  List<BaseCollecte> get _collectesFiltrees {
    List<BaseCollecte> collectes = [];

    // Sélection par onglet
    switch (_selectedTabIndex.value) {
      case 0: // Toutes
        collectes = _collectesData.values.expand((list) => list).toList();
        break;
      case 1: // Récoltes
        collectes = _collectesData[Section.recoltes] ?? [];
        break;
      case 2: // SCOOP
        collectes = _collectesData[Section.scoop] ?? [];
        break;
      case 3: // Individuelles
        collectes = _collectesData[Section.individuel] ?? [];
        break;
    }

    // Filtre par recherche
    if (_searchQuery.value.isNotEmpty) {
      final query = _searchQuery.value.toLowerCase();
      collectes = collectes.where((collecte) {
        return collecte.site.toLowerCase().contains(query) ||
            (collecte.technicien?.toLowerCase().contains(query) ?? false) ||
            (collecte is Recolte &&
                (collecte.village?.toLowerCase().contains(query) ?? false)) ||
            (collecte is Scoop &&
                collecte.scoopNom.toLowerCase().contains(query));
      }).toList();
    }

    // Filtre par collectes avec produits contrôlés
    if (_showOnlyWithProducts.value) {
      collectes = collectes.where((collecte) {
        final controlInfo = _collectesControlInfo[collecte.id];
        return controlInfo != null && controlInfo.controlledContainers > 0;
      }).toList();
    }

    // Trier par date (plus récent en premier)
    collectes.sort((a, b) => b.date.compareTo(a.date));

    return collectes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attribution par Collectes'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Toutes', icon: Icon(Icons.all_inclusive)),
            Tab(text: 'Récoltes', icon: Icon(Icons.agriculture)),
            Tab(text: 'SCOOP', icon: Icon(Icons.groups)),
            Tab(text: 'Individuelles', icon: Icon(Icons.person)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Obx(() {
        if (_isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Chargement des collectes...'),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Statistiques
            _buildStatsSection(),

            // Filtres et recherche
            _buildFiltersSection(),

            // Liste des collectes
            Expanded(
              child: _buildCollectesList(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatsSection() {
    return Obx(() {
      final currentSection = _selectedTabIndex.value == 0
          ? 'global'
          : [
              'global',
              'recoltes',
              'scoop',
              'individuel'
            ][_selectedTabIndex.value];

      final stats = _stats[currentSection];
      if (stats == null) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Collectes',
                '${stats.totalCollectes}',
                '${stats.collectesAvecProduits} avec produits',
                Icons.inventory_2,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Reçus',
                '${stats.totalRecus}',
                '${stats.totalControles} contrôlés',
                Icons.inbox,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Restants',
                '${stats.totalRestants}',
                '${stats.tauxControle.toStringAsFixed(1)}% contrôlé',
                Icons.pending_actions,
                Colors.orange,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard(
      String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w500)),
            ],
          ),
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
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par site, technicien, village...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Obx(() => _searchQuery.value.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _searchQuery.value = '';
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : const SizedBox.shrink()),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Filtres additionnels
          Row(
            children: [
              Obx(() => FilterChip(
                    label: const Text('Avec produits contrôlés'),
                    selected: _showOnlyWithProducts.value,
                    onSelected: (selected) {
                      _showOnlyWithProducts.value = selected;
                    },
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollectesList() {
    return Obx(() {
      final collectes = _collectesFiltrees;

      if (collectes.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Aucune collecte trouvée',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Modifiez vos filtres ou actualisez les données',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: collectes.length,
        itemBuilder: (context, index) {
          final collecte = collectes[index];
          final controlInfo = _collectesControlInfo[collecte.id];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CollecteAttributionCard(
              collecte: collecte,
              controlInfo: controlInfo,
              onAttributeProducts: (produits) =>
                  _handleAttributeProducts(collecte, produits),
              onViewDetails: () => _showCollecteDetails(collecte),
            ),
          );
        },
      );
    });
  }

  void _handleAttributeProducts(
      BaseCollecte collecte, List<models.ProductControle> produits) {
    _showAttributionDialog(collecte, produits);
  }

  /// 🔍 DÉTERMINE LA SECTION D'UNE COLLECTE
  Section _determineSection(BaseCollecte collecte) {
    if (collecte is Recolte) return Section.recoltes;
    if (collecte is Scoop) return Section.scoop;
    if (collecte is Individuel) return Section.individuel;
    return Section.miellerie;
  }

  /// 🎯 DIALOGUE D'ATTRIBUTION AVEC NOUVELLE STRUCTURE V2
  void _showAttributionDialog(
      BaseCollecte collecte, List<models.ProductControle> produits) {
    if (produits.isEmpty) {
      Get.snackbar(
        'Attention',
        'Aucun produit sélectionné pour attribution',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        icon: const Icon(Icons.warning, color: Colors.orange),
      );
      return;
    }

    // Déterminer le type d'attribution selon la section
    final section = _determineSection(collecte);
    models.AttributionType? typeAttribution;
    String description = '';

    switch (section) {
      case Section.recoltes:
        typeAttribution = models.AttributionType.extraction;
        description = 'Extraction (produits bruts)';
        break;
      case Section.scoop:
      case Section.individuel:
      case Section.miellerie:
        // Pour ces sections, proposer un choix entre Filtrage et Cire
        _showProductTypeSelectionDialog(collecte, produits);
        return;
    }

    _showSiteSelectionDialog(collecte, produits, typeAttribution, description);
  }

  /// 🔄 DIALOGUE DE SÉLECTION DU TYPE DE PRODUIT (Filtrage/Cire)
  void _showProductTypeSelectionDialog(
      BaseCollecte collecte, List<models.ProductControle> produits) {
    Get.dialog(
      AlertDialog(
        title: const Text('Type d\'attribution'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Sélectionnez le type d\'attribution pour ${produits.length} produits:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.filter_alt, color: Colors.blue),
              title: const Text('Filtrage'),
              subtitle: const Text('Produits liquides'),
              onTap: () {
                Get.back();
                _showSiteSelectionDialog(
                    collecte,
                    produits,
                    models.AttributionType.filtration,
                    'Filtrage (produits liquides)');
              },
            ),
            ListTile(
              leading: const Icon(Icons.wb_sunny, color: Colors.amber),
              title: const Text('Traitement Cire'),
              subtitle: const Text('Produits cire'),
              onTap: () {
                Get.back();
                _showSiteSelectionDialog(collecte, produits,
                    models.AttributionType.traitementCire, 'Traitement cire');
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 🏭 DIALOGUE DE SÉLECTION DU SITE RECEVEUR
  void _showSiteSelectionDialog(
      BaseCollecte collecte,
      List<models.ProductControle> produits,
      models.AttributionType type,
      String description) {
    final sites = ['Koudougou', 'Bobo-Dioulasso', 'Ouagadougou', 'Banfora'];
    String? selectedSite;
    final commentController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('Attribution - $description'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Collecte: ${collecte.id}'),
              Text('Produits: ${produits.length}'),
              const SizedBox(height: 16),
              const Text('Site receveur:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setState) => DropdownButtonFormField<String>(
                  value: selectedSite,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Sélectionnez un site',
                  ),
                  items: sites
                      .map((site) =>
                          DropdownMenuItem(value: site, child: Text(site)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedSite = value),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Commentaires (optionnel):',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ajouter des commentaires...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: selectedSite != null
                ? () {
                    Get.back();
                    _executeAttribution(
                      collecte,
                      produits,
                      type,
                      selectedSite!,
                      commentController.text.trim(),
                    );
                  }
                : null,
            child: const Text('Attribuer'),
          ),
        ],
      ),
    );
  }

  /// 🔄 CONVERTIT LES PRODUITS DU SERVICE D'ATTRIBUTION VERS LE FORMAT V2
  List<models.ProductControle> _convertToV2Products(
    BaseCollecte collecte,
    List<models.ProductControle> produitsAttribution,
  ) {
    if (kDebugMode) {
      print('🔄 [Attribution Page] ===== CONVERSION PRODUITS VERS V2 =====');
      print('   📦 Collecte: ${collecte.id}');
      print(
          '   📊 Nombre de produits à convertir: ${produitsAttribution.length}');

      // Détail des poids avant conversion
      double totalPoidsOrigine = 0.0;
      for (final produit in produitsAttribution) {
        double poids = produit.poidsTotal;
        totalPoidsOrigine += poids;
        if (kDebugMode) {
          print('      - ${produit.codeContenant}: ${poids}kg');
        }
      }
      print(
          '   ⚖️ Poids total origine: ${totalPoidsOrigine.toStringAsFixed(2)} kg');
    }

    // Les produits sont déjà au format correct, retourner directement
    return produitsAttribution;
  }

  /// ✅ EXÉCUTION DE L'ATTRIBUTION AVEC LE SERVICE V2
  Future<void> _executeAttribution(
    BaseCollecte collecte,
    List<models.ProductControle> produits,
    models.AttributionType type,
    String siteReceveur,
    String commentaires,
  ) async {
    try {
      if (kDebugMode) {
        print('');
        print('🎯 [Attribution Page] ===== DÉBUT EXÉCUTION ATTRIBUTION =====');
        print('   📦 Collecte: ${collecte.id}');
        print('   🏭 Site: ${collecte.site}');
        print('   📅 Date collecte: ${collecte.date}');
        print('   🎯 Type attribution: ${type.toString()}');
        print('   🏪 Site receveur: $siteReceveur');
        print('   💬 Commentaires: $commentaires');
        print('   📊 Nombre de produits: ${produits.length}');

        // Détail des produits à attribuer
        print('   📋 DÉTAIL DES PRODUITS À ATTRIBUER:');
        for (int i = 0; i < produits.length && i < 5; i++) {
          final produit = produits[i];
          print(
              '      - ${produit.codeContenant}: ${produit.poidsTotal}kg (${produit.estConforme ? 'Conforme' : 'Non conforme'})');
        }
        if (produits.length > 5) {
          print('      ... et ${produits.length - 5} autres produits');
        }

        // Calcul du poids total à attribuer
        double poidsTotal = produits.fold(0.0, (sum, p) => sum + p.poidsTotal);
        print(
            '   ⚖️ Poids total à attribuer: ${poidsTotal.toStringAsFixed(2)} kg');
        print('   🕐 Timestamp: ${DateTime.now()}');
      }
      // Afficher un indicateur de chargement
      Get.dialog(
        const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Attribution en cours...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // Convertir les produits au format v2
      final produitsV2 = _convertToV2Products(collecte, produits);

      // Sauvegarder l'attribution avec la nouvelle structure
      final attributionId = await _attributionServiceV2.sauvegarderAttribution(
        type: type,
        siteReceveur: siteReceveur,
        produits: produitsV2,
        utilisateur:
            'Utilisateur actuel', // TODO: Récupérer l'utilisateur connecté
        commentaires: commentaires.isNotEmpty ? commentaires : null,
        metadata: {
          'collecteOrigine': collecte.id,
          'siteOrigine': collecte.site,
          'dateCollecte': collecte.date.toIso8601String(),
          'version': 'v2.0',
        },
      );

      // Fermer le dialogue de chargement
      Get.back();

      if (kDebugMode) {
        print('✅ [Attribution Page] Attribution sauvegardée avec succès !');
        print('   🆔 ID d\'attribution: $attributionId');
        print('   📦 Collecte traitée: ${collecte.id}');
        print('   📊 Produits attribués: ${produitsV2.length}');
        print(
            '   ⚖️ Poids total attribué: ${produitsV2.fold(0.0, (sum, p) => sum + p.poidsTotal).toStringAsFixed(2)} kg');
        print('   🏪 Site receveur: $siteReceveur');
        print('   🕐 Fin attribution: ${DateTime.now()}');
      }

      // Recharger les données pour refléter les changements
      if (kDebugMode) {
        print(
            '🔄 [Attribution Page] Rechargement des données après attribution...');
      }
      await _loadControlInfo();
      _calculateStats();

      // Afficher le succès
      Get.snackbar(
        'Succès',
        'Attribution sauvegardée avec succès!\nID: $attributionId',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        icon: const Icon(Icons.check_circle, color: Colors.green),
        duration: const Duration(seconds: 4),
      );

      print('✅ Attribution réussie: $attributionId');
      print(
          '📁 Structure: Attributions_recu/$siteReceveur/${type.label}/$attributionId');
    } catch (e, stackTrace) {
      // Fermer le dialogue de chargement en cas d'erreur
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      if (kDebugMode) {
        print('');
        print('❌❌❌ [Attribution Page] ERREUR LORS DE L\'ATTRIBUTION ❌❌❌');
        print('   🚨 Type d\'erreur: ${e.runtimeType}');
        print('   📝 Message: $e');
        print('   📦 Collecte concernée: ${collecte.id}');
        print('   🏭 Site origine: ${collecte.site}');
        print('   🎯 Type attribution: ${type.toString()}');
        print('   🏪 Site receveur: $siteReceveur');
        print('   📊 Nombre de produits: ${produits.length}');
        print('   🕐 Timestamp erreur: ${DateTime.now()}');
        print('   📍 Stack trace:');
        print(stackTrace.toString());
        print(
            '================================================================');
        print('');
      }
      Get.snackbar(
        'Erreur',
        'Impossible de sauvegarder l\'attribution: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
        duration: const Duration(seconds: 5),
      );
    }
  }

  void _showCollecteDetails(BaseCollecte collecte) {
    // TODO: Afficher les détails de la collecte
    print('Affichage des détails de la collecte ${collecte.id}');
  }
}

/// 📊 Statistiques d'une collecte ou section
class CollecteStats {
  final int totalCollectes;
  final int collectesAvecProduits;
  final int totalRecus;
  final int totalControles;
  final int totalRestants;
  double tauxControle;

  CollecteStats({
    required this.totalCollectes,
    required this.collectesAvecProduits,
    required this.totalRecus,
    required this.totalControles,
    required this.totalRestants,
    required this.tauxControle,
  });
}
