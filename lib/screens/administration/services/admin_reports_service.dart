import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/admin_reports_models.dart';

class AdminReportsService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final UserSession _userSession = Get.find<UserSession>(); // Non utilisé pour l'instant

  // Données observables
  final Rx<ReportsData> _reportsData = ReportsData.empty().obs;
  final RxBool _isLoading = false.obs;

  // Getters
  ReportsData get reportsData => _reportsData.value;
  bool get isLoading => _isLoading.value;

  /// Charger tous les rapports
  Future<void> loadAllReports({
    required DateTime startDate,
    required DateTime endDate,
    required String site,
  }) async {
    _isLoading.value = true;

    try {
      // Charger les données réelles des modules existants
      final collecteStats = await _loadCollecteStats(startDate, endDate, site);
      final controleStats = await _loadControleStats(startDate, endDate, site);
      final extractionStats =
          await _loadExtractionStats(startDate, endDate, site);
      final filtrageStats = await _loadFiltrageStats(startDate, endDate, site);

      // Générer des données de test pour les modules en développement
      final _ = _generateConditionnementTestData(
          startDate, endDate); // Non utilisé pour l'instant
      final venteStats = _generateVenteTestData(startDate, endDate);
      final financialStats = _generateFinancialTestData(startDate, endDate);

      // Combiner toutes les données
      _reportsData.value = ReportsData(
        // Production (modules réels)
        totalCollecte: collecteStats.totalQuantity,
        totalControle: controleStats.totalControles.toDouble(),
        totalExtraction: extractionStats.totalQuantity,
        totalFiltrage: filtrageStats.totalQuantity,

        // Commercial (données de test)
        totalVentes: venteStats.totalVentes.toDouble(),
        chiffresAffaires: venteStats.chiffresAffaires,
        totalClients: venteStats.totalClients,

        // Financier (données de test)
        revenus: financialStats.revenus,
        charges: financialStats.charges,
        benefices: financialStats.benefices,

        // Graphiques et détails
        collecteByDate: collecteStats.dataByDate,
        controleByDate: controleStats.dataByDate,
        extractionByDate: extractionStats.dataByDate,
        filtrageByDate: filtrageStats.dataByDate,
        venteByDate: venteStats.dataByDate,

        // Par site
        collecteBySite: collecteStats.dataBySite,
        controleBySite: controleStats.dataBySite,
        extractionBySite: extractionStats.dataBySite,
        filtrageBySite: filtrageStats.dataBySite,

        // Performances
        rendementExtraction:
            _calculateRendementExtraction(extractionStats, collecteStats),
        tauxControleConforme: _calculateTauxControleConforme(controleStats),
        evolutionProduction: _calculateEvolutionProduction(
            collecteStats, extractionStats, filtrageStats),

        // Activité récente
        recentActivities: await _loadRecentActivities(site),

        // Dates
        startDate: startDate,
        endDate: endDate,
        site: site,
      );
    } catch (e) {
      print('Erreur lors du chargement des rapports: $e');
      _reportsData.value = ReportsData.empty();
    } finally {
      _isLoading.value = false;
    }
  }

  /// Charger les statistiques de collecte
  Future<ModuleStats> _loadCollecteStats(
      DateTime startDate, DateTime endDate, String site) async {
    try {
      Query query = _firestore
          .collectionGroup('collectes')
          .where('dateCollecte',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('dateCollecte',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate));

      if (site != 'all') {
        query = query.where('site', isEqualTo: site);
      }

      final snapshot = await query.get();

      double totalQuantity = 0;
      Map<String, double> dataByDate = {};
      Map<String, double> dataBySite = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final quantity = (data['quantiteCollectee'] as num?)?.toDouble() ?? 0;
        final date = (data['dateCollecte'] as Timestamp).toDate();
        final siteValue = data['site'] as String? ?? 'Inconnu';

        totalQuantity += quantity;

        // Par date
        final dateKey = '${date.day}/${date.month}';
        dataByDate[dateKey] = (dataByDate[dateKey] ?? 0) + quantity;

        // Par site
        dataBySite[siteValue] = (dataBySite[siteValue] ?? 0) + quantity;
      }

      return ModuleStats(
        totalQuantity: totalQuantity,
        totalControles: snapshot.docs.length,
        dataByDate: dataByDate,
        dataBySite: dataBySite,
      );
    } catch (e) {
      print('Erreur chargement collecte: $e');
      return ModuleStats.empty();
    }
  }

  /// Charger les statistiques de contrôle
  Future<ModuleStats> _loadControleStats(
      DateTime startDate, DateTime endDate, String site) async {
    try {
      Query query = _firestore
          .collectionGroup('controles')
          .where('dateControle',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('dateControle',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate));

      if (site != 'all') {
        query = query.where('site', isEqualTo: site);
      }

      final snapshot = await query.get();

      int totalControles = 0;
      int controlesConformes = 0;
      Map<String, double> dataByDate = {};
      Map<String, double> dataBySite = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final date = (data['dateControle'] as Timestamp).toDate();
        final siteValue = data['site'] as String? ?? 'Inconnu';
        final isConforme = data['isValidated'] as bool? ?? false;

        totalControles++;
        if (isConforme) controlesConformes++;

        // Par date
        final dateKey = '${date.day}/${date.month}';
        dataByDate[dateKey] = (dataByDate[dateKey] ?? 0) + 1;

        // Par site
        dataBySite[siteValue] = (dataBySite[siteValue] ?? 0) + 1;
      }

      return ModuleStats(
        totalQuantity: controlesConformes.toDouble(),
        totalControles: totalControles,
        dataByDate: dataByDate,
        dataBySite: dataBySite,
        conformeRate: totalControles > 0
            ? (controlesConformes.toDouble() / totalControles) * 100
            : 0,
      );
    } catch (e) {
      print('Erreur chargement contrôle: $e');
      return ModuleStats.empty();
    }
  }

  /// Charger les statistiques d'extraction
  Future<ModuleStats> _loadExtractionStats(
      DateTime startDate, DateTime endDate, String site) async {
    try {
      Query query = _firestore
          .collectionGroup('extractions')
          .where('dateExtraction',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('dateExtraction',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate));

      if (site != 'all') {
        query = query.where('site', isEqualTo: site);
      }

      final snapshot = await query.get();

      double totalQuantity = 0;
      Map<String, double> dataByDate = {};
      Map<String, double> dataBySite = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final quantity = (data['quantiteExtraite'] as num?)?.toDouble() ?? 0;
        final date = (data['dateExtraction'] as Timestamp).toDate();
        final siteValue = data['site'] as String? ?? 'Inconnu';

        totalQuantity += quantity;

        // Par date
        final dateKey = '${date.day}/${date.month}';
        dataByDate[dateKey] = (dataByDate[dateKey] ?? 0) + quantity;

        // Par site
        dataBySite[siteValue] = (dataBySite[siteValue] ?? 0) + quantity;
      }

      return ModuleStats(
        totalQuantity: totalQuantity,
        totalControles: snapshot.docs.length,
        dataByDate: dataByDate,
        dataBySite: dataBySite,
      );
    } catch (e) {
      print('Erreur chargement extraction: $e');
      return ModuleStats.empty();
    }
  }

  /// Charger les statistiques de filtrage
  Future<ModuleStats> _loadFiltrageStats(
      DateTime startDate, DateTime endDate, String site) async {
    try {
      Query query = _firestore
          .collectionGroup('produits_filtres')
          .where('dateFiltrage',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('dateFiltrage',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate));

      if (site != 'all') {
        query = query.where('site', isEqualTo: site);
      }

      final snapshot = await query.get();

      double totalQuantity = 0;
      Map<String, double> dataByDate = {};
      Map<String, double> dataBySite = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final quantity = (data['quantiteFiltre'] as num?)?.toDouble() ?? 0;
        final date = (data['dateFiltrage'] as Timestamp).toDate();
        final siteValue = data['site'] as String? ?? 'Inconnu';

        totalQuantity += quantity;

        // Par date
        final dateKey = '${date.day}/${date.month}';
        dataByDate[dateKey] = (dataByDate[dateKey] ?? 0) + quantity;

        // Par site
        dataBySite[siteValue] = (dataBySite[siteValue] ?? 0) + quantity;
      }

      return ModuleStats(
        totalQuantity: totalQuantity,
        totalControles: snapshot.docs.length,
        dataByDate: dataByDate,
        dataBySite: dataBySite,
      );
    } catch (e) {
      print('Erreur chargement filtrage: $e');
      return ModuleStats.empty();
    }
  }

  /// Générer des données de test pour le conditionnement
  TestModuleStats _generateConditionnementTestData(
      DateTime startDate, DateTime endDate) {
    final days = endDate.difference(startDate).inDays;
    Map<String, double> dataByDate = {};

    // Générer des données réalistes
    double totalQuantity = 0;
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey = '${date.day}/${date.month}';
      final quantity = (15 + (i % 7) * 5).toDouble(); // Variation réaliste
      dataByDate[dateKey] = quantity;
      totalQuantity += quantity;
    }

    return TestModuleStats(
      totalQuantity: totalQuantity,
      dataByDate: dataByDate,
      totalLots: (totalQuantity / 25).round(), // Moyenne 25kg par lot
    );
  }

  /// Générer des données de test pour les ventes
  TestVenteStats _generateVenteTestData(DateTime startDate, DateTime endDate) {
    final days = endDate.difference(startDate).inDays;
    Map<String, double> dataByDate = {};

    double totalVentes = 0;
    double chiffresAffaires = 0;

    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey = '${date.day}/${date.month}';
      final ventes = (2 + (i % 5)).toDouble(); // 2-6 ventes par jour
      final ca = ventes * (125000 + (i % 3) * 50000); // CA variable

      dataByDate[dateKey] = ventes;
      totalVentes += ventes;
      chiffresAffaires += ca;
    }

    return TestVenteStats(
      totalVentes: totalVentes,
      chiffresAffaires: chiffresAffaires,
      totalClients: (totalVentes * 0.7).round(), // 70% de clients uniques
      dataByDate: dataByDate,
    );
  }

  /// Générer des données de test pour les finances
  TestFinancialStats _generateFinancialTestData(
      DateTime startDate, DateTime endDate) {
    final days = endDate.difference(startDate).inDays;

    // Calculs basés sur la période
    final revenus = days * 450000; // 450k FCFA par jour en moyenne
    final charges = days * 280000; // 280k FCFA par jour en charges
    final benefices = revenus - charges;

    return TestFinancialStats(
      revenus: revenus.toDouble(),
      charges: charges.toDouble(),
      benefices: benefices.toDouble(),
    );
  }

  /// Charger l'activité récente
  Future<List<RecentActivity>> _loadRecentActivities(String site) async {
    try {
      final activities = <RecentActivity>[];

      // Récupérer les dernières collectes
      Query collecteQuery = _firestore
          .collectionGroup('collectes')
          .orderBy('dateCollecte', descending: true)
          .limit(5);

      if (site != 'all') {
        collecteQuery = collecteQuery.where('site', isEqualTo: site);
      }

      final collecteSnapshot = await collecteQuery.get();
      for (var doc in collecteSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        activities.add(RecentActivity(
          type: 'collecte',
          title: 'Nouvelle collecte',
          description:
              'Collecte de ${data['quantiteCollectee']}kg par ${data['apiculteurNom'] ?? 'Apiculteur'}',
          timestamp: (data['dateCollecte'] as Timestamp).toDate(),
          icon: '🍯',
          color: '#4CAF50',
        ));
      }

      // Récupérer les derniers contrôles
      Query controleQuery = _firestore
          .collectionGroup('controles')
          .orderBy('dateControle', descending: true)
          .limit(3);

      if (site != 'all') {
        controleQuery = controleQuery.where('site', isEqualTo: site);
      }

      final controleSnapshot = await controleQuery.get();
      for (var doc in controleSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final isConforme = data['isValidated'] as bool? ?? false;
        activities.add(RecentActivity(
          type: 'controle',
          title: 'Contrôle qualité',
          description:
              'Échantillon ${isConforme ? 'conforme' : 'non conforme'}',
          timestamp: (data['dateControle'] as Timestamp).toDate(),
          icon: isConforme ? '✅' : '❌',
          color: isConforme ? '#4CAF50' : '#F44336',
        ));
      }

      // Trier par date
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Ajouter quelques activités de test pour les modules en développement
      activities.addAll([
        RecentActivity(
          type: 'vente',
          title: 'Vente réalisée (TEST)',
          description: 'Vente de 15kg miel toutes fleurs - 975,000 FCFA',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          icon: '💰',
          color: '#2196F3',
        ),
        RecentActivity(
          type: 'conditionnement',
          title: 'Lot conditionné (TEST)',
          description: 'Lot LOT-2024-156 - 120 pots de 500g',
          timestamp: DateTime.now().subtract(const Duration(hours: 4)),
          icon: '📦',
          color: '#FF9800',
        ),
      ]);

      return activities.take(10).toList();
    } catch (e) {
      print('Erreur chargement activité récente: $e');
      return [];
    }
  }

  /// Calculer le rendement d'extraction
  double _calculateRendementExtraction(
      ModuleStats extraction, ModuleStats collecte) {
    if (collecte.totalQuantity == 0) return 0;
    return (extraction.totalQuantity / collecte.totalQuantity) * 100;
  }

  /// Calculer le taux de contrôle conforme
  double _calculateTauxControleConforme(ModuleStats controle) {
    return controle.conformeRate;
  }

  /// Calculer l'évolution de la production
  Map<String, double> _calculateEvolutionProduction(
      ModuleStats collecte, ModuleStats extraction, ModuleStats filtrage) {
    return {
      'collecte': collecte.totalQuantity,
      'extraction': extraction.totalQuantity,
      'filtrage': filtrage.totalQuantity,
    };
  }

  /// Exporter les rapports
  Future<Map<String, dynamic>> exportReports({
    required String format,
    required DateTime startDate,
    required DateTime endDate,
    required String site,
  }) async {
    try {
      final data = _reportsData.value;

      final exportData = {
        'periode': {
          'debut': startDate.toIso8601String(),
          'fin': endDate.toIso8601String(),
          'site': site,
        },
        'resume': {
          'collecte_totale': data.totalCollecte,
          'extraction_totale': data.totalExtraction,
          'filtrage_total': data.totalFiltrage,
          'controles_total': data.totalControle,
          'ventes_totales': data.totalVentes,
          'chiffre_affaires': data.chiffresAffaires,
          'benefices': data.benefices,
        },
        'details_par_date': {
          'collecte': data.collecteByDate,
          'extraction': data.extractionByDate,
          'filtrage': data.filtrageByDate,
          'ventes': data.venteByDate,
        },
        'details_par_site': {
          'collecte': data.collecteBySite,
          'extraction': data.extractionBySite,
          'filtrage': data.filtrageBySite,
        },
        'performances': {
          'rendement_extraction': data.rendementExtraction,
          'taux_controle_conforme': data.tauxControleConforme,
        },
        'activite_recente': data.recentActivities
            .map((a) => {
                  'type': a.type,
                  'titre': a.title,
                  'description': a.description,
                  'timestamp': a.timestamp.toIso8601String(),
                })
            .toList(),
      };

      return {
        'success': true,
        'data': exportData,
        'filename':
            'rapport_apisavana_${site}_${startDate.toIso8601String().split('T')[0]}_${endDate.toIso8601String().split('T')[0]}.$format',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur lors de l\'export: $e',
      };
    }
  }
}

/// Classes pour les statistiques des modules
class ModuleStats {
  final double totalQuantity;
  final int totalControles;
  final Map<String, double> dataByDate;
  final Map<String, double> dataBySite;
  final double conformeRate;

  ModuleStats({
    required this.totalQuantity,
    required this.totalControles,
    required this.dataByDate,
    required this.dataBySite,
    this.conformeRate = 0,
  });

  factory ModuleStats.empty() {
    return ModuleStats(
      totalQuantity: 0,
      totalControles: 0,
      dataByDate: {},
      dataBySite: {},
    );
  }
}

/// Classes pour les statistiques de test
class TestModuleStats {
  final double totalQuantity;
  final Map<String, double> dataByDate;
  final int totalLots;

  TestModuleStats({
    required this.totalQuantity,
    required this.dataByDate,
    required this.totalLots,
  });
}

class TestVenteStats {
  final double totalVentes;
  final double chiffresAffaires;
  final int totalClients;
  final Map<String, double> dataByDate;

  TestVenteStats({
    required this.totalVentes,
    required this.chiffresAffaires,
    required this.totalClients,
    required this.dataByDate,
  });
}

class TestFinancialStats {
  final double revenus;
  final double charges;
  final double benefices;

  TestFinancialStats({
    required this.revenus,
    required this.charges,
    required this.benefices,
  });
}
