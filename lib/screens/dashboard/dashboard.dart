import 'package:apisavana_gestion/authentication/user_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

final Map<String, List<String>> roleModules = {
  "Admin": [
    "collecte",
    "controle",
    "extraction",
    "filtrage",
    "conditionnement",
    "gestion de ventes",
    "ventes",
    "rapports"
  ],
  "Collecteur": ["collecte"],
  "Contrôleur": ["controle"],
  "Extracteur": ["extraction"],
  "Filtreur": ["filtrage"],
  "Conditionneur": ["conditionnement"],
  "Commercial": ["gestion de ventes", "ventes", "rapports"],
  "Gestionaire Commerciale": ["gestion de ventes", "ventes", "rapports"],
  "Magazinier": ["gestion de ventes", "stock", "rapports"],
  "Caissier": ["gestion de ventes", "ventes", "rapports"],
};

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final GlobalKey<ScaffoldState> _scaffoldKey;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  DateTimeRange? _selectedRange;
  String? _selectedCommercial;
  String? _selectedClient;
  String? _selectedLot;
  String? _selectedTypeVente; // "Comptant", "Crédit", "Recouvrement", null=Tous
  String graphType = "Tout"; // "Tout", "Ventes", "Collecte", "Stock"

  // Ajoute ces variables à ta classe :
  DateTime? _detailsFilterStart;
  DateTime? _detailsFilterEnd;
  String _detailsSearch = ""; // Pour la recherche texte

  List<String> commerciaux = [];
  List<String> clients = [];
  List<String> lots = [];

  List<String> _xLabels = [];
  List<Map<String, double>> barChartData = [];
  bool _isLoadingChart = true;
  String? chartError;

  List<Map<String, dynamic>> _alertes = [];
  List<Map<String, dynamic>> _logs = [];
  Map<String, num> kpis = {};
  Map<String, List<Map<String, dynamic>>> details = {};

  // Pour tri et pagination des détails
  String? _sortField;
  bool _sortAscending = true;
  int _detailsPage = 0;
  static const int _detailsPageSize = 20;

  bool get isLargeScreen => MediaQuery.of(context).size.width >= 900;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(duration: Duration(milliseconds: 900), vsync: this);
    _fadeInAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
    _scaffoldKey = GlobalKey<ScaffoldState>();
    if (!Get.isRegistered<UserSession>()) Get.put(UserSession());
    _initDefaultRange();
    _loadAllData();
  }

  void _initDefaultRange() {
    final now = DateTime.now();
    _selectedRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
  }

  Future<void> _loadAllData() async {
    try {
      setState(() => _isLoadingChart = true);
      await Future.wait([
        _loadDropdowns(),
        _loadKPIsAndDetails(),
        _loadChartData(),
        _loadAlertes(),
        _loadLogs(),
      ]);
    } catch (e) {
      setState(() {
        chartError = "Erreur chargement données : $e";
      });
    } finally {
      setState(() => _isLoadingChart = false);
    }
  }

  Future<void> _loadDropdowns() async {
    try {
      final commSnap = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .where('role', isEqualTo: 'Commercial')
          .get();
      commerciaux = commSnap.docs
          .map((d) => d.data()['nom'] ?? d.id)
          .whereType<String>()
          .toList();

      final cliSnap =
          await FirebaseFirestore.instance.collection('clients').get();
      clients = cliSnap.docs
          .map((d) => d.data()['nomBoutique'] ?? d.data()['nomGerant'] ?? d.id)
          .whereType<String>()
          .toList();

      final lotSnap =
          await FirebaseFirestore.instance.collection('conditionnement').get();
      lots = lotSnap.docs
          .map((d) => d.data()['lotOrigine'] ?? d.id)
          .whereType<String>()
          .toList();
    } catch (_) {
      commerciaux = [];
      clients = [];
      lots = [];
    }
  }

  Future<void> _loadKPIsAndDetails() async {
    double qteVentes = 0,
        montantVentes = 0,
        qteCollecte = 0,
        qteStock = 0,
        credits = 0;
    List<Map<String, dynamic>> ventesList = [];
    List<Map<String, dynamic>> collecteList = [];
    List<Map<String, dynamic>> stockList = [];
    List<Map<String, dynamic>> creditsList = [];

    // Ventes
    try {
      final snapVentes = await FirebaseFirestore.instance
          .collectionGroup('ventes_effectuees')
          .get();
      for (var doc in snapVentes.docs) {
        final v = doc.data() as Map<String, dynamic>;
        final embVendus = v['emballagesVendus'] ?? [];
        double qte = 0;
        for (final emb in embVendus) {
          qte += (emb['contenanceKg'] ?? 0.0) * (emb['nombre'] ?? 0);
        }
        qteVentes += qte;
        montantVentes += (v['montantTotal'] ?? 0.0) is num
            ? (v['montantTotal'] ?? 0.0)
            : 0.0;
        ventesList.add(v);
        if (v['typeVente'] == "Crédit" && (v['montantRestant'] ?? 0) > 0) {
          credits += (v['montantRestant'] ?? 0.0);
          creditsList.add(v);
        }
      }
    } catch (_) {}

    // Collecte
    try {
      final snapCollecte =
          await FirebaseFirestore.instance.collection('collectes').get();
      for (var doc in snapCollecte.docs) {
        final sousColl = await doc.reference.collection('Récolte').get();
        for (var s in sousColl.docs) {
          var d = s.data();
          if (d['details'] is List) {
            for (var detail in (d['details'] as List)) {
              qteCollecte += (detail['quantite'] ?? 0.0) is num
                  ? (detail['quantite'] ?? 0.0)
                  : 0.0;
              collecteList.add(detail as Map<String, dynamic>);
            }
          } else {
            qteCollecte += (d['quantiteKg'] ?? 0.0) is num
                ? (d['quantiteKg'] ?? 0.0)
                : 0.0;
            collecteList.add(d);
          }
        }
      }
    } catch (_) {}

    // Stock
    try {
      final snapStock =
          await FirebaseFirestore.instance.collection('conditionnement').get();
      for (var doc in snapStock.docs) {
        qteStock += (doc.data()['quantiteRestante'] ?? 0.0) is num
            ? (doc.data()['quantiteRestante'] ?? 0.0)
            : 0.0;
        stockList.add(doc.data());
      }
    } catch (_) {}

    kpis = {
      "Ventes": qteVentes,
      "Montant ventes": montantVentes,
      "Collecte": qteCollecte,
      "Stock": qteStock,
      "Crédits à recouvrer": credits,
    };
    details = {
      "Ventes": ventesList,
      "Collecte": collecteList,
      "Stock": stockList,
      "Crédits à recouvrer": creditsList,
    };
    setState(() {});
  }

  Future<void> _loadChartData() async {
    try {
      setState(() {
        _isLoadingChart = true;
        chartError = null;
      });
      final nbDays =
          _selectedRange!.end.difference(_selectedRange!.start).inDays;
      final bool byMonth = nbDays > 60;
      List<DateTime> xAxisPoints = [];
      if (byMonth) {
        DateTime d = DateTime(
            _selectedRange!.start.year, _selectedRange!.start.month, 1);
        while (d.isBefore(_selectedRange!.end)) {
          xAxisPoints.add(d);
          d = DateTime(d.year, d.month + 1, 1);
        }
      } else {
        DateTime d = _selectedRange!.start;
        while (!d.isAfter(_selectedRange!.end)) {
          xAxisPoints.add(DateTime(d.year, d.month, d.day));
          d = d.add(const Duration(days: 1));
        }
      }
      _xLabels = xAxisPoints
          .map((d) => byMonth
              ? DateFormat('MM/yyyy').format(d)
              : DateFormat('dd/MM').format(d))
          .toList();

      // Préparation des barres pour chaque série
      barChartData = List.generate(_xLabels.length, (idx) {
        return {
          "Ventes": 0.0,
          "Collecte": 0.0,
          "Stock": 0.0,
        };
      });

      // Ventes
      try {
        final ventesQ = FirebaseFirestore.instance
            .collectionGroup('ventes_effectuees')
            .where('dateVente', isGreaterThanOrEqualTo: _selectedRange!.start)
            .where('dateVente', isLessThanOrEqualTo: _selectedRange!.end);
        final ventesSnap = await ventesQ.get();
        for (var doc in ventesSnap.docs) {
          final v = doc.data() as Map<String, dynamic>;
          DateTime? dt = (v['dateVente'] is Timestamp)
              ? (v['dateVente'] as Timestamp).toDate()
              : null;
          if (dt == null) continue;
          int idx = byMonth
              ? ((dt.year - xAxisPoints[0].year) * 12 +
                  (dt.month - xAxisPoints[0].month))
              : dt.difference(xAxisPoints[0]).inDays;
          if (idx < 0 || idx >= _xLabels.length) continue;
          double qte = 0;
          final embVendus = v['emballagesVendus'] ?? [];
          for (final emb in embVendus) {
            qte += (emb['contenanceKg'] ?? 0.0) * (emb['nombre'] ?? 0);
          }
          barChartData[idx]["Ventes"] =
              (barChartData[idx]["Ventes"] ?? 0) + qte;
        }
      } catch (_) {}

      // Collecte
      try {
        final collecteSnap = await FirebaseFirestore.instance
            .collection('collectes')
            .where('dateCollecte',
                isGreaterThanOrEqualTo: _selectedRange!.start)
            .where('dateCollecte', isLessThanOrEqualTo: _selectedRange!.end)
            .get();
        for (var doc in collecteSnap.docs) {
          final data = doc.data();
          DateTime? dt = (data['dateCollecte'] as Timestamp?)?.toDate();
          if (dt == null) continue;
          int idx = byMonth
              ? ((dt.year - xAxisPoints[0].year) * 12 +
                  (dt.month - xAxisPoints[0].month))
              : dt.difference(xAxisPoints[0]).inDays;
          if (idx < 0 || idx >= _xLabels.length) continue;
          double score = 0;
          final sousColl = await doc.reference.collection('Récolte').get();
          for (var s in sousColl.docs) {
            final d = s.data();
            if (d['details'] is List) {
              for (var detail in (d['details'] as List)) {
                score += (detail['quantite'] ?? 0.0) is num
                    ? (detail['quantite'] ?? 0.0)
                    : 0.0;
              }
            } else {
              score += (d['quantiteKg'] ?? 0.0) is num
                  ? (d['quantiteKg'] ?? 0.0)
                  : 0.0;
            }
          }
          barChartData[idx]["Collecte"] =
              (barChartData[idx]["Collecte"] ?? 0) + score;
        }
      } catch (_) {}

      // Stock pour toute période (pas que byMonth)
      try {
        final stockSnap = await FirebaseFirestore.instance
            .collection('conditionnement')
            .get();
        for (var doc in stockSnap.docs) {
          DateTime? dt = (doc.data()['date'] is Timestamp)
              ? (doc.data()['date'] as Timestamp).toDate()
              : null;
          if (dt == null) continue;
          int idx = byMonth
              ? ((dt.year - xAxisPoints[0].year) * 12 +
                  (dt.month - xAxisPoints[0].month))
              : dt.difference(xAxisPoints[0]).inDays;
          if (idx < 0 || idx >= _xLabels.length) continue;
          barChartData[idx]["Stock"] = (barChartData[idx]["Stock"] ?? 0) +
              (doc.data()['quantiteRestante'] ?? 0);
        }
      } catch (_) {}

      setState(() => chartError = null);
    } catch (e) {
      setState(() => chartError = "Erreur: $e");
    } finally {
      setState(() => _isLoadingChart = false);
    }
  }

  Widget _activityBarChart() {
    final List<Color> colors = [
      Colors.blueAccent, // Ventes
      Colors.green[700]!, // Collecte
      Colors.red[700]! // Stock
    ];
    final List<String> legendLabels = ["Ventes", "Collecte", "Stock"];
    List<String> displayed = legendLabels;
    if (graphType != "Tout") {
      displayed = [graphType];
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: EdgeInsets.symmetric(vertical: 18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.deepPurple, size: 26),
                SizedBox(width: 10),
                Text(
                  "Activité (${_selectedRange == null ? "..." : "${DateFormat('dd/MM/yyyy').format(_selectedRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedRange!.end)}"})",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                ),
                Spacer(),
                ...["Tout", ...legendLabels].map((t) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: ChoiceChip(
                        label: Text(t),
                        selected: graphType == t,
                        onSelected: (_) => setState(() => graphType = t),
                      ),
                    )),
                SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    // Correction pour bug showDateRangePicker
                    final now = DateTime.now();
                    final maxDate = DateTime(now.year, now.month, now.day)
                        .add(Duration(days: 2));
                    DateTimeRange? initial = _selectedRange;
                    if (initial != null && initial.end.isAfter(maxDate)) {
                      initial =
                          DateTimeRange(start: initial.start, end: maxDate);
                    }
                    final picked = await showDateRangePicker(
                      context: context,
                      initialDateRange: initial,
                      firstDate: DateTime(2022, 1, 1),
                      lastDate: maxDate,
                    );
                    if (picked != null) {
                      setState(() => _selectedRange = picked);
                      await _loadChartData();
                    }
                  },
                  icon: Icon(Icons.date_range, size: 20),
                  label: Text("Période"),
                  style: OutlinedButton.styleFrom(shape: StadiumBorder()),
                ),
              ],
            ),
            SizedBox(height: 14),
            Row(
              children: [
                _filterDropdown<String>(
                  hint: "Commercial",
                  values: commerciaux,
                  selected: _selectedCommercial,
                  onChanged: (v) => setState(() {
                    _selectedCommercial = v;
                    _loadChartData();
                  }),
                ),
                SizedBox(width: 8),
                _filterDropdown<String>(
                  hint: "Client",
                  values: clients,
                  selected: _selectedClient,
                  onChanged: (v) => setState(() {
                    _selectedClient = v;
                    _loadChartData();
                  }),
                ),
                SizedBox(width: 8),
                _filterDropdown<String>(
                  hint: "Lot",
                  values: lots,
                  selected: _selectedLot,
                  onChanged: (v) => setState(() {
                    _selectedLot = v;
                    _loadChartData();
                  }),
                ),
                SizedBox(width: 8),
                _filterDropdown<String>(
                  hint: "Type vente",
                  values: ["Comptant", "Crédit", "Recouvrement"],
                  selected: _selectedTypeVente,
                  onChanged: (v) => setState(() {
                    _selectedTypeVente = v;
                    _loadChartData();
                  }),
                ),
              ],
            ),
            SizedBox(height: 15),
            SizedBox(
              height: 270,
              child: _isLoadingChart
                  ? Center(child: CircularProgressIndicator())
                  : chartError != null
                      ? Center(
                          child: Text(
                              "Erreur chargement graphique: $chartError",
                              style: TextStyle(color: Colors.red)))
                      : (graphType == "Stock" &&
                              (barChartData.isEmpty ||
                                  barChartData.every(
                                      (row) => (row["Stock"] ?? 0.0) == 0.0)))
                          ? Center(
                              child: Text(
                                  "Aucune donnée Stock sur la période sélectionnée ou données invalides.",
                                  style: TextStyle(color: Colors.orange[900])))
                          : (barChartData.isEmpty ||
                                  barChartData.length != _xLabels.length ||
                                  displayed.isEmpty ||
                                  barChartData.every((row) => displayed.every(
                                      (label) =>
                                          row[label] == null ||
                                          row[label]!.isNaN ||
                                          row[label] == 0.0)))
                              ? Center(
                                  child: Text(
                                      "Aucune donnée sur la période sélectionnée ou données invalides.",
                                      style:
                                          TextStyle(color: Colors.grey[700])))
                              : BarChart(
                                  BarChartData(
                                    barGroups:
                                        List.generate(barChartData.length, (i) {
                                      final row = barChartData[i];
                                      return BarChartGroupData(
                                        x: i,
                                        barRods: List.generate(displayed.length,
                                            (j) {
                                          final label = displayed[j];
                                          final y = row[label] ?? 0;
                                          return BarChartRodData(
                                            toY: y.isNaN ? 0 : y,
                                            color: colors[
                                                legendLabels.indexOf(label)],
                                            width: 14,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          );
                                        }),
                                      );
                                    }),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                          getTitlesWidget: (value, meta) =>
                                              Padding(
                                            padding: const EdgeInsets.only(
                                                right: 4.0),
                                            child: Text(
                                                value.toInt().toString(),
                                                style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 12)),
                                          ),
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 44,
                                          interval: (_xLabels.length / 6)
                                              .ceilToDouble()
                                              .clamp(1, 100),
                                          getTitlesWidget: (value, meta) {
                                            final idx = value.toInt();
                                            if (idx < 0 ||
                                                idx >= _xLabels.length)
                                              return Container();
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0),
                                              child: Text(_xLabels[idx],
                                                  style: TextStyle(
                                                      color: Colors.grey[700],
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w500)),
                                            );
                                          },
                                        ),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                    ),
                                    gridData: FlGridData(
                                        show: true, horizontalInterval: 10),
                                    barTouchData: BarTouchData(
                                      enabled: true,
                                      touchTooltipData: BarTouchTooltipData(
                                        getTooltipItem:
                                            (group, groupIndex, rod, rodIndex) {
                                          final label = displayed[rodIndex];
                                          return BarTooltipItem(
                                            "$label: ${rod.toY.toStringAsFixed(2)}",
                                            TextStyle(
                                              color: colors[
                                                  legendLabels.indexOf(label)],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 20,
                children: legendLabels
                    .where((l) => displayed.contains(l))
                    .map((label) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 12,
                        color: colors[legendLabels.indexOf(label)],
                        margin: EdgeInsets.only(right: 6),
                      ),
                      Text(label),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailsPopup(String label, List<Map<String, dynamic>> rows) {
    showDialog(
      context: context,
      builder: (ctx) {
        // Etats locaux pour la popup (on ne pollue pas l'état global !)
        String localSortField = _sortField ?? '';
        bool localSortAscending = _sortAscending;
        int localDetailsPage = 0;
        String localSearch = '';
        DateTime? localFilterStart;
        DateTime? localFilterEnd;
        final searchController = TextEditingController();

        // Pour update le champ recherche sans perdre le focus
        searchController.text = localSearch;
        searchController.selection = TextSelection.fromPosition(
            TextPosition(offset: searchController.text.length));

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Filtres dynamiques
            List<Map<String, dynamic>> filteredRows = rows.where((row) {
              // Filtre texte
              if (localSearch.trim().isNotEmpty) {
                final search = localSearch.trim().toLowerCase();
                final match = row.entries.any((e) =>
                    (e.value?.toString().toLowerCase() ?? '').contains(search));
                if (!match) return false;
              }
              // Filtre date
              DateTime? dt;
              if (row['dateCollecte'] is Timestamp)
                dt = (row['dateCollecte'] as Timestamp).toDate();
              else if (row['dateVente'] is Timestamp)
                dt = (row['dateVente'] as Timestamp).toDate();
              else if (row['date'] is Timestamp)
                dt = (row['date'] as Timestamp).toDate();
              if (localFilterStart != null &&
                  dt != null &&
                  dt.isBefore(localFilterStart!)) return false;
              if (localFilterEnd != null &&
                  dt != null &&
                  dt.isAfter(localFilterEnd!)) return false;
              return true;
            }).toList();
            // Tri
            if (localSortField.isNotEmpty) {
              filteredRows.sort((a, b) {
                var va = a[localSortField];
                var vb = b[localSortField];
                if (va == null && vb == null) return 0;
                if (va == null) return localSortAscending ? -1 : 1;
                if (vb == null) return localSortAscending ? 1 : -1;
                if (va is num && vb is num) {
                  return localSortAscending
                      ? va.compareTo(vb)
                      : vb.compareTo(va);
                }
                if (va is Comparable && vb is Comparable) {
                  return localSortAscending
                      ? va.compareTo(vb)
                      : vb.compareTo(va);
                }
                return 0;
              });
            } else {
              // Tri sur la date décroissante par défaut
              filteredRows.sort((a, b) {
                DateTime? da, db;
                if (a['dateCollecte'] is Timestamp)
                  da = (a['dateCollecte'] as Timestamp).toDate();
                else if (a['dateVente'] is Timestamp)
                  da = (a['dateVente'] as Timestamp).toDate();
                else if (a['date'] is Timestamp)
                  da = (a['date'] as Timestamp).toDate();
                if (b['dateCollecte'] is Timestamp)
                  db = (b['dateCollecte'] as Timestamp).toDate();
                else if (b['dateVente'] is Timestamp)
                  db = (b['dateVente'] as Timestamp).toDate();
                else if (b['date'] is Timestamp)
                  db = (b['date'] as Timestamp).toDate();
                if (da == null && db == null) return 0;
                if (da == null) return 1;
                if (db == null) return -1;
                return db.compareTo(da);
              });
            }
            // Pagination
            int pageCount = (filteredRows.length / _detailsPageSize).ceil();
            final pagedRows = filteredRows.length > _detailsPageSize
                ? filteredRows.sublist(
                    localDetailsPage * _detailsPageSize,
                    (localDetailsPage + 1) * _detailsPageSize >
                            filteredRows.length
                        ? filteredRows.length
                        : (localDetailsPage + 1) * _detailsPageSize)
                : filteredRows;

            // Champs de tri dispos
            final triFields = rows.isNotEmpty
                ? rows.first.keys
                    .where((k) => rows.any((r) => r[k] != null))
                    .toList()
                : [];

            // Plage de dates mini-maxi
            DateTime? minDate, maxDate;
            for (final row in rows) {
              DateTime? dt;
              if (row['dateCollecte'] is Timestamp)
                dt = (row['dateCollecte'] as Timestamp).toDate();
              else if (row['dateVente'] is Timestamp)
                dt = (row['dateVente'] as Timestamp).toDate();
              else if (row['date'] is Timestamp)
                dt = (row['date'] as Timestamp).toDate();
              if (dt != null) {
                if (minDate == null || dt.isBefore(minDate)) minDate = dt;
                if (maxDate == null || dt.isAfter(maxDate)) maxDate = dt;
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$label - Détail (${filteredRows.length}/${rows.length})",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (rows.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 0),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 6,
                        spacing: 10,
                        children: [
                          // Recherche texte (ne pas recréer le controller à chaque build)
                          SizedBox(
                            width: 220,
                            child: TextField(
                              controller: searchController,
                              decoration: InputDecoration(
                                hintText: "Recherche (tous champs)",
                                prefixIcon: Icon(Icons.search, size: 17),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onChanged: (v) {
                                setStateDialog(() {
                                  localSearch = v;
                                  localDetailsPage = 0;
                                });
                              },
                            ),
                          ),
                          // Tri champ
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Trier par: "),
                              DropdownButton<String>(
                                value: localSortField.isNotEmpty
                                    ? localSortField
                                    : null,
                                hint: Text("Champ"),
                                items: triFields
                                    .map((k) => DropdownMenuItem<String>(
                                          value: k,
                                          child: Text(k),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  setStateDialog(() {
                                    localSortField = v ?? '';
                                    localSortAscending = true;
                                    localDetailsPage = 0;
                                  });
                                },
                              ),
                              IconButton(
                                icon: Icon(localSortAscending
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward),
                                tooltip: "Inverser l'ordre",
                                onPressed: localSortField.isEmpty
                                    ? null
                                    : () {
                                        setStateDialog(() {
                                          localSortAscending =
                                              !localSortAscending;
                                          localDetailsPage = 0;
                                        });
                                      },
                              ),
                            ],
                          ),
                          // Filtre date
                          if (minDate != null && maxDate != null)
                            OutlinedButton.icon(
                              icon: Icon(Icons.date_range, size: 18),
                              label: Text(
                                localFilterStart != null &&
                                        localFilterEnd != null
                                    ? "${DateFormat('dd/MM/yy').format(localFilterStart!)} - ${DateFormat('dd/MM/yy').format(localFilterEnd!)}"
                                    : "Filtrer dates",
                                style: TextStyle(fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                shape: StadiumBorder(),
                                minimumSize: Size(0, 32),
                              ),
                              onPressed: () async {
                                final picked = await showDateRangePicker(
                                  context: context,
                                  initialDateRange: (localFilterStart != null &&
                                          localFilterEnd != null)
                                      ? DateTimeRange(
                                          start: localFilterStart!,
                                          end: localFilterEnd!)
                                      : DateTimeRange(
                                          start: minDate!, end: maxDate!),
                                  firstDate: minDate!,
                                  lastDate: maxDate!,
                                );
                                if (picked != null) {
                                  setStateDialog(() {
                                    localFilterStart = picked.start;
                                    localFilterEnd = picked.end;
                                    localDetailsPage = 0;
                                  });
                                }
                              },
                            ),
                          if (localFilterStart != null ||
                              localFilterEnd != null)
                            IconButton(
                              icon: Icon(Icons.clear),
                              tooltip: "Supprimer filtre date",
                              onPressed: () {
                                setStateDialog(() {
                                  localFilterStart = null;
                                  localFilterEnd = null;
                                  localDetailsPage = 0;
                                });
                              },
                            ),
                          // Pagination
                          if (filteredRows.length > _detailsPageSize)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.chevron_left),
                                  onPressed: localDetailsPage > 0
                                      ? () => setStateDialog(() {
                                            localDetailsPage--;
                                          })
                                      : null,
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                      "${localDetailsPage + 1} / $pageCount"),
                                ),
                                IconButton(
                                  icon: Icon(Icons.chevron_right),
                                  onPressed: localDetailsPage < pageCount - 1
                                      ? () => setStateDialog(() {
                                            localDetailsPage++;
                                          })
                                      : null,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                height: 480,
                child: pagedRows.isEmpty
                    ? Center(
                        child: Text(
                            "Aucun détail à afficher sur la période/filtre/texte."))
                    : Scrollbar(
                        thumbVisibility: true,
                        child: ListView.separated(
                          itemCount: pagedRows.length,
                          separatorBuilder: (_, __) => Divider(),
                          itemBuilder: (_, i) {
                            final data = pagedRows[i];
                            if (label.toLowerCase().contains("vente")) {
                              return _venteDetailCard(data);
                            } else if (label
                                .toLowerCase()
                                .contains("collecte")) {
                              return _collecteDetailCard(data);
                            } else if (label.toLowerCase().contains("stock")) {
                              return _stockDetailCard(data);
                            } else if (label.toLowerCase().contains("crédit")) {
                              return _creditDetailCard(data);
                            }
                            return _genericDetailCard(data);
                          },
                        ),
                      ),
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                    },
                    child: Text("Fermer"))
              ],
            );
          },
        );
      },
    );
  }

// Remplace ton _collecteDetailCard par celui-ci pour un affichage complet et lisible
  Widget _collecteDetailCard(Map<String, dynamic> data) {
    DateTime? dt;
    if (data['dateCollecte'] is Timestamp)
      dt = (data['dateCollecte'] as Timestamp).toDate();
    else if (data['date'] is Timestamp)
      dt = (data['date'] as Timestamp).toDate();

    final quantite = data['quantite'] ?? data['quantiteKg'];
    final lot = data['lotOrigine'] ?? data['lot'];
    final collecteur = data['nomCollecteur'] ?? data['collecteur'] ?? "";

    return Card(
      color: Colors.green[50],
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              collecteur.toString().isNotEmpty ? collecteur : "Collecte",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Colors.green[900]),
            ),
            SizedBox(height: 2),
            Text(
                "Date : ${dt != null ? DateFormat('dd/MM/yyyy').format(dt) : ''}",
                style: TextStyle(color: Colors.grey[700])),
            if (quantite != null)
              Text("Quantité : $quantite kg",
                  style: TextStyle(fontWeight: FontWeight.w600)),
            if (lot != null) Text("Lot origine : $lot"),
            if (data['commentaire'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text("Commentaire : ${data['commentaire']}",
                    style: TextStyle(color: Colors.black54)),
              ),
            ...data.entries
                .where((e) => ![
                      'nomCollecteur',
                      'collecteur',
                      'dateCollecte',
                      'date',
                      'quantite',
                      'quantiteKg',
                      'lotOrigine',
                      'lot',
                      'commentaire'
                    ].contains(e.key))
                .map((e) => Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${e.key} : ",
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800])),
                          Expanded(
                              child: Text('${e.value}',
                                  style: TextStyle(color: Colors.grey[700])))
                        ],
                      ),
                    )),
          ],
        ),
      ),
    );
  }

  Widget _drilldownCard(String label, IconData icon, num value,
      {required List<Map<String, dynamic>> details}) {
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.symmetric(vertical: 7, horizontal: 3),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap:
              details.isEmpty ? null : () => _showDetailsPopup(label, details),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                    label == "Stock"
                        ? Icons.storage
                        : label.toLowerCase().contains("vente")
                            ? Icons.shopping_cart
                            : label.toLowerCase().contains("collecte")
                                ? Icons.api
                                : label.toLowerCase().contains("crédit")
                                    ? Icons.money_off
                                    : Icons.info_outline,
                    size: 32,
                    color: label == "Stock"
                        ? Colors.orange[800]
                        : label.toLowerCase().contains("vente")
                            ? Colors.amber[800]
                            : label.toLowerCase().contains("collecte")
                                ? Colors.green[800]
                                : label.toLowerCase().contains("crédit")
                                    ? Colors.red[800]
                                    : Colors.grey[700]),
                SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("$value",
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: label == "Stock"
                                  ? Colors.orange[800]
                                  : label.toLowerCase().contains("vente")
                                      ? Colors.amber[800]
                                      : label.toLowerCase().contains("collecte")
                                          ? Colors.green[800]
                                          : label
                                                  .toLowerCase()
                                                  .contains("crédit")
                                              ? Colors.red[800]
                                              : Colors.grey[700])),
                    ],
                  ),
                ),
                if (details.isNotEmpty)
                  Icon(Icons.arrow_forward_ios,
                      color: Colors.amber[800], size: 19)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _venteDetailCard(Map<String, dynamic> data) {
    final emb = (data['emballagesVendus'] as List?) ?? [];
    return Card(
      color: Colors.blue[50],
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${data['nomClient'] ?? data['nomBoutique'] ?? 'Vente'}",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Colors.blue[900]),
            ),
            Text("Date : ${_formatDate(data['dateVente'])}",
                style: TextStyle(color: Colors.grey[700])),
            Text("Montant : ${data['montantTotal'] ?? 0} FCFA",
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.green)),
            if (data['typeVente'] != null)
              Text("Type : ${data['typeVente']}",
                  style: TextStyle(color: Colors.deepPurple)),
            if (emb.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text("Emballages vendus :",
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ...emb
                .map((e) => Text("- ${e['contenanceKg']}kg x ${e['nombre']}")),
            if (data['commentaire'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text("Commentaire : ${data['commentaire']}",
                    style: TextStyle(color: Colors.black54)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stockDetailCard(Map<String, dynamic> data) {
    return Card(
      color: Colors.orange[50],
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Lot : ${data['lotOrigine'] ?? 'Stock'}",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Colors.orange[900])),
            Text("Date : ${_formatDate(data['date'])}",
                style: TextStyle(color: Colors.grey[700])),
            Text("Quantité restante : ${data['quantiteRestante'] ?? 0} kg",
                style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _creditDetailCard(Map<String, dynamic> data) {
    return Card(
      color: Colors.red[50],
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${data['nomClient'] ?? data['nomBoutique'] ?? 'Crédit'}",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Colors.red[900])),
            Text("Date vente : ${_formatDate(data['dateVente'])}",
                style: TextStyle(color: Colors.grey[700])),
            Text("Montant restant : ${data['montantRestant'] ?? 0} FCFA",
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.red[800])),
            Text("Montant total : ${data['montantTotal'] ?? 0} FCFA"),
            if (data['dateEcheance'] != null)
              Text("Échéance : ${_formatDate(data['dateEcheance'])}",
                  style: TextStyle(color: Colors.red[400])),
          ],
        ),
      ),
    );
  }

  Widget _genericDetailCard(Map<String, dynamic> data) {
    return Card(
      color: Colors.amber[50],
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: data.entries.map((e) {
            return Text("${e.key} : ${e.value}");
          }).toList(),
        ),
      ),
    );
  }

  String _formatDate(dynamic ts) {
    if (ts is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(ts.toDate());
    } else if (ts is DateTime) {
      return DateFormat('dd/MM/yyyy').format(ts);
    } else if (ts != null) {
      return ts.toString();
    } else {
      return "";
    }
  }

  Future<void> _loadAlertes() async {
    List<Map<String, dynamic>> alertes = [];
    try {
      final filtrageSnap = await FirebaseFirestore.instance
          .collection('filtrage')
          .where('statutFiltrage', isEqualTo: 'Filtrage total')
          .get();
      int lotsNonCond = 0;
      for (var doc in filtrageSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['statutConditionnement'] != 'Conditionné') lotsNonCond++;
      }
      if (lotsNonCond > 0) {
        alertes.add({
          "type": "Stock bas",
          "message": "$lotsNonCond lots filtrés à conditionner",
        });
      }
      final ventesSnap = await FirebaseFirestore.instance
          .collectionGroup('ventes_effectuees')
          .where('typeVente', isEqualTo: 'Crédit')
          .get();
      int credits = ventesSnap.docs.length;
      if (credits > 0) {
        alertes.add({
          "type": "Crédit en attente",
          "message": "$credits ventes à crédit à recouvrer",
        });
      }
    } catch (_) {}
    setState(() => _alertes = alertes);
  }

  Future<void> _loadLogs() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('logs')
          .orderBy('date', descending: true)
          .limit(20)
          .get();
      _logs = snap.docs.map((d) {
        final data = d.data();
        return {
          "date": (data['date'] as Timestamp).toDate(),
          "action": data['action'] ?? "",
          "user": data['user'] ?? "",
          "details": data['details'] ?? "",
        };
      }).toList();
      setState(() {});
    } catch (_) {
      _logs = [];
      setState(() {});
    }
  }

  Widget _buildHeader(BuildContext context) {
    final userSession = Get.find<UserSession>();
    final role = userSession.role ?? "";
    final isAdmin = role.toLowerCase() == "admin";
    final allowedModules = roleModules[role] ?? [];

    final navButtons = [
      _headerBtn("collecte", Icons.api, () => _onModuleSelected("collecte"),
          enabled: isAdmin || allowedModules.contains("collecte")),
      _headerBtn(
          "controle", Icons.verified, () => _onModuleSelected("controle"),
          enabled: isAdmin || allowedModules.contains("controle")),
      _headerBtn(
          "extraction", Icons.science, () => _onModuleSelected("extraction"),
          enabled: isAdmin || allowedModules.contains("extraction")),
      _headerBtn("filtrage", Icons.science, () => _onModuleSelected("filtrage"),
          enabled: isAdmin || allowedModules.contains("filtrage")),
      _headerBtn("conditionnement", Icons.science,
          () => _onModuleSelected("conditionnement"),
          enabled: isAdmin || allowedModules.contains("conditionnement")),
      _headerBtn("gestion de ventes", Icons.science,
          () => _onModuleSelected("gestion de ventes"),
          enabled: isAdmin || allowedModules.contains("gestion de ventes")),
      _headerBtn(
          "ventes", Icons.shopping_cart, () => _onModuleSelected("ventes"),
          enabled: isAdmin || allowedModules.contains("ventes")),
      _headerBtn("stock", Icons.storage, () => _onModuleSelected("stock"),
          enabled: isAdmin || allowedModules.contains("stock")),
      _headerBtn(
          "rapports", Icons.bar_chart, () => _onModuleSelected("rapports"),
          enabled: isAdmin || allowedModules.contains("rapports")),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      color: Colors.amber[50],
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                "assets/logo/logo.jpeg",
                width: 60,
                height: 60,
              ),
              SizedBox(width: 10),
              Text(
                "Apisavana",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[900],
                  fontSize: 22,
                  letterSpacing: 2,
                ),
              )
            ],
          ),
          Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (userSession.photoUrl != null)
                CircleAvatar(
                  backgroundImage: NetworkImage(userSession.photoUrl!),
                  radius: 17,
                  backgroundColor: Colors.amber[100],
                )
              else
                CircleAvatar(
                  radius: 17,
                  backgroundColor: Colors.amber[100],
                  child: Icon(Icons.person, color: Colors.amber[800], size: 18),
                ),
              SizedBox(width: 7),
              Text(
                "${userSession.nom ?? ''} (${userSession.role ?? ''})",
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
              ),
              SizedBox(width: 16),
            ],
          ),
          if (isLargeScreen)
            Expanded(
              flex: 8,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...navButtons,
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.settings, color: Colors.blueGrey[900]),
                      tooltip: "Paramètres",
                      onPressed: _onSettings,
                      splashRadius: 22,
                    ),
                    SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.logout, color: Colors.red[900]),
                      tooltip: "Déconnexion",
                      onPressed: () => Get.offAllNamed('/login'),
                      splashRadius: 22,
                    ),
                  ],
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.menu, color: Colors.amber[900], size: 32),
              tooltip: "Menu",
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              splashRadius: 28,
            ),
        ],
      ),
    );
  }

  Widget _buildDrawerMenu() {
    final userSession = Get.find<UserSession>();
    final role = userSession.role ?? "";
    final isAdmin = role.toLowerCase() == "admin";
    final allowedModules = roleModules[role] ?? [];
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.amber[100]),
            child: Row(
              children: [
                Image.asset("assets/logo/logo.jpeg", width: 40, height: 40),
                SizedBox(width: 90),
                Text(
                  "Apisavana",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[900],
                      fontSize: 22),
                ),
              ],
            ),
          ),
          _drawerItem("Collecte", Icons.api, "collecte",
              isAdmin || allowedModules.contains("collecte")),
          _drawerItem("Contrôle", Icons.verified, "controle",
              isAdmin || allowedModules.contains("controle")),
          _drawerItem("Extraction", Icons.science, "extraction",
              isAdmin || allowedModules.contains("extraction")),
          _drawerItem("Filtrage", Icons.science, "filtrage",
              isAdmin || allowedModules.contains("filtrage")),
          _drawerItem("Conditionnement", Icons.science, "conditionnement",
              isAdmin || allowedModules.contains("conditionnement")),
          _drawerItem("Gestion de ventes", Icons.science, "gestion de ventes",
              isAdmin || allowedModules.contains("gestion de ventes")),
          _drawerItem("Ventes", Icons.shopping_cart, "ventes",
              isAdmin || allowedModules.contains("ventes")),
          _drawerItem("Stock", Icons.storage, "stock",
              isAdmin || allowedModules.contains("stock")),
          _drawerItem("Rapports", Icons.bar_chart, "rapports",
              isAdmin || allowedModules.contains("rapports")),
          Divider(),
          ListTile(
            leading: Icon(Icons.settings, color: Colors.blueGrey[900]),
            title: Text("Paramètres"),
            onTap: _onSettings,
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red[900]),
            title: Text("Déconnexion"),
            onTap: () => Get.offAllNamed('/login'),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(String title, IconData icon, String module, bool enabled) {
    return ListTile(
      leading:
          Icon(icon, color: enabled ? Colors.amber[900] : Colors.grey[400]),
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? Colors.amber[900] : Colors.grey[400],
          fontWeight: FontWeight.w500,
        ),
      ),
      enabled: enabled,
      onTap: enabled ? () => _onModuleSelected(module) : null,
    );
  }

  Widget _filterDropdown<T>({
    required String hint,
    required List<T> values,
    required T? selected,
    required void Function(T?) onChanged,
  }) {
    return SizedBox(
      width: 170,
      child: DropdownButton<T>(
        value: selected,
        isExpanded: true,
        hint: Text(hint),
        items: [
          DropdownMenuItem<T>(value: null, child: Text('Tous')),
          ...values.map(
              (v) => DropdownMenuItem<T>(value: v, child: Text(v.toString()))),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _logsSection() {
    if (_logs.isEmpty) {
      return Card(
        child: ListTile(
          leading: Icon(Icons.history, color: Colors.amber[900]),
          title: Text("Aucune activité récente",
              style: TextStyle(color: Colors.grey[700])),
        ),
      );
    }
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Historique des actions",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Divider(),
            ..._logs.map((log) => ListTile(
                  leading: Icon(Icons.circle_rounded,
                      color: Colors.amber[900], size: 16),
                  title: Text(log["action"],
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    "${DateFormat('dd/MM/yy HH:mm').format(log["date"])} • ${log["user"]} • ${log["details"]}",
                    style: TextStyle(fontSize: 13),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(Map alerte) {
    Color color;
    IconData icon;
    if (alerte["type"] == "Stock bas") {
      color = Colors.orange[200]!;
      icon = Icons.warning_amber_rounded;
    } else if (alerte["type"] == "Crédit en attente") {
      color = Colors.red[100]!;
      icon = Icons.money_off;
    } else {
      color = Colors.red[50]!;
      icon = Icons.error_outline;
    }
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: Card(
        color: color,
        child: ListTile(
          leading: Icon(icon, color: Colors.red[700]),
          title: Text(
            alerte["type"],
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(alerte["message"]),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0, top: 24.0),
        child: Text(
          text,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      );

  void _onModuleSelected(String module) {
    Get.snackbar(
      "Navigation",
      "Aller au module $module",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.amber[100],
      duration: Duration(seconds: 1),
    );
    String route = "";
    switch (module.toLowerCase()) {
      case "collecte":
        route = "/collecte";
        break;
      case "controle":
        route = "/controle";
        break;
      case "extraction":
        route = "/extraction";
        break;
      case "filtrage":
        route = "/filtrage";
        break;
      case "conditionnement":
        route = "/conditionnement";
        break;
      case "gestion de ventes":
        route = "/gestion_de_ventes";
        break;
      case "ventes":
        route = "/ventes";
        break;
      case "stock":
        route = "/stock";
        break;
      case "rapports":
        route = "/rapports";
        break;
      default:
        route = "/";
    }
    if (route.isNotEmpty) {
      Get.toNamed(route);
    }
  }

  Widget _headerBtn(String label, IconData icon, VoidCallback onPressed,
      {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: TextButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon,
            color: enabled ? Colors.amber[900] : Colors.grey[400], size: 21),
        label: Text(
          label,
          style: TextStyle(
              color: enabled ? Colors.amber[900] : Colors.grey[400],
              fontWeight: FontWeight.w600,
              fontSize: 14),
        ),
        style: TextButton.styleFrom(
          foregroundColor: enabled ? Colors.amber[900] : Colors.grey[400],
          backgroundColor:
              enabled ? Colors.amber[100]?.withOpacity(0.4) : Colors.grey[200],
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          shape: StadiumBorder(),
        ),
      ),
    );
  }

  void _onSettings() {
    Get.snackbar(
      "Paramètres",
      "Ici tu peux gérer les paramètres de l'application.",
      backgroundColor: Colors.blue[100],
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userSession = Get.find<UserSession>();
    final role = userSession.role ?? "";
    final isAdmin = role.toLowerCase() == "admin";
    final allowedModules = roleModules[role] ?? [];

    final cards = [
      _drilldownCard("Ventes", Icons.shopping_cart, kpis["Ventes"] ?? 0,
          details: details["Ventes"] ?? []),
      _drilldownCard("Collecte", Icons.api, kpis["Collecte"] ?? 0,
          details: details["Collecte"] ?? []),
      _drilldownCard("Stock", Icons.storage, kpis["Stock"] ?? 0,
          details: details["Stock"] ?? []),
      _drilldownCard("Crédits à recouvrer", Icons.money_off,
          kpis["Crédits à recouvrer"] ?? 0,
          details: details["Crédits à recouvrer"] ?? []),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: isLargeScreen ? null : _buildDrawerMenu(),
      backgroundColor: Colors.amber[50],
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 1200),
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    children: [
                      _sectionTitle("Résumé des informations clés"),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount =
                              constraints.maxWidth > 900 ? 2 : 1;
                          return Wrap(
                            spacing: 24,
                            runSpacing: 18,
                            children: List.generate(
                              cards.length,
                              (i) => SizedBox(
                                width: constraints.maxWidth / crossAxisCount -
                                    (crossAxisCount == 2 ? 24 : 0),
                                child: cards[i],
                              ),
                            ),
                          );
                        },
                      ),
                      _sectionTitle("Activité principale"),
                      _activityBarChart(),
                      _sectionTitle("Alertes"),
                      _alertes.isEmpty
                          ? Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text("Aucune alerte",
                                  style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w500)),
                            )
                          : Column(
                              children: _alertes.map(_buildAlertCard).toList(),
                            ),
                      _sectionTitle("Historique"),
                      _logsSection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
