import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controle_de_donnes/models/collecte_models.dart';
import '../../vente/controllers/espace_commercial_controller.dart';
import '../../controle_de_donnes/services/firestore_data_service.dart';

/// ChartDataController agrège les séries mensuelles Ventes/Collecte
/// et prépare les données pour les graphiques (Line/Bar/Area/Pie)
class ChartDataController extends GetxController {
  final RxList<String> months = <String>[].obs; // 'Jan', 'Fév', ...
  final RxList<double> ventesMonthly =
      <double>[].obs; // même longueur que months
  final RxList<double> collecteMonthly =
      <double>[].obs; // même longueur que months

  // Données du camembert: (label, valeur, couleur)
  final RxList<_PieSlice> pieSlices = <_PieSlice>[].obs;

  // Carte utilitaire pour labelliser les mois
  static const List<String> _mois = [
    'Jan',
    'Fév',
    'Mar',
    'Avr',
    'Mai',
    'Juin',
    'Juil',
    'Aoû',
    'Sep',
    'Oct',
    'Nov',
    'Déc'
  ];

  // Chargement initial et écoute des ventes en temps réel via EspaceCommercialController
  @override
  void onInit() {
    super.onInit();
    // S'assurer que le contrôleur commercial est enregistré
    final esc = Get.isRegistered<EspaceCommercialController>()
        ? Get.find<EspaceCommercialController>()
        : Get.put(EspaceCommercialController(), permanent: true);

    // Recalculer à chaque changement de ventes (temps réel)
    ever<List<dynamic>>(esc.ventes, (_) => _rebuildFromSources());

    // Charger une première fois (ventes + collectes)
    _rebuildFromSources();
  }

  Future<void> _rebuildFromSources() async {
    try {
      final esc = Get.find<EspaceCommercialController>();

      // 1) Agrégation des ventes (depuis le contrôleur, temps réel)
      final Map<DateTime, double> ventesParMois = {};
      for (final v in esc.ventes) {
        final d = DateTime(v.dateVente.year, v.dateVente.month);
        final val = (v.montantTotal).toDouble();
        ventesParMois[d] = (ventesParMois[d] ?? 0) + val;
      }

      // 2) Agrégation des collectes (chargement Firestore one-shot)
      //    On cumule les poids (kg) si disponibles, sinon les montants
      final Map<DateTime, double> collecteParMois = {};
      try {
        final data = await FirestoreDataService.getCollectesFromFirestore();

        // Helper pour pousser une collecte
        void pushCollecte(BaseCollecte c, double poids, double montant) {
          final d = DateTime(c.date.year, c.date.month);
          final toAdd = poids > 0 ? poids : montant; // priorise le poids
          collecteParMois[d] = (collecteParMois[d] ?? 0) + toAdd;
        }

        // Récoltes
        for (final c in (data[Section.recoltes] ?? const [])) {
          final r = c as Recolte;
          pushCollecte(r, r.totalWeight ?? 0, r.totalAmount ?? 0);
        }
        // Scoop
        for (final c in (data[Section.scoop] ?? const [])) {
          final s = c as Scoop;
          pushCollecte(s, s.totalWeight ?? 0, s.totalAmount ?? 0);
        }
        // Individuel
        for (final c in (data[Section.individuel] ?? const [])) {
          final i = c as Individuel;
          pushCollecte(i, i.totalWeight ?? 0, i.totalAmount ?? 0);
        }
        // Miellerie
        for (final c in (data[Section.miellerie] ?? const [])) {
          final m = c as Miellerie;
          pushCollecte(m, m.totalWeight ?? 0, m.totalAmount ?? 0);
        }

        // 3) Camembert: top 4 prédominances florales + "Autres"
        final Map<String, double> florales = {};
        for (final c in (data[Section.recoltes] ?? const [])) {
          final r = c as Recolte;
          if ((r.predominancesFlorales?.isNotEmpty ?? false) == false) {
            continue;
          }
          // si plusieurs pour une collecte, répartir le poids total équitablement
          final double poidsBase = (r.totalWeight ?? 0) > 0
              ? (r.totalWeight ?? 0)
              : (r.totalAmount ?? 0);
          final int denom = (r.predominancesFlorales?.isNotEmpty ?? false)
              ? r.predominancesFlorales!.length
              : 1;
          final double p = denom == 0 ? 0 : (poidsBase / denom);
          for (final f in (r.predominancesFlorales ?? const <String>[])) {
            final key = f.trim();
            if (key.isEmpty) continue;
            florales[key] = (florales[key] ?? 0) + p;
          }
        }
        _buildPieSlicesFromFlorales(florales);
      } catch (_) {
        // Si échec collecte, on garde les séries des ventes, et pie par défaut vide
        pieSlices.assignAll([]);
      }

      // 4) Construire l'axe temporel commun (tous les mois vus)
      final Set<DateTime> allMonths = {
        ...ventesParMois.keys,
        ...collecteParMois.keys
      };
      final List<DateTime> sorted = allMonths.toList()
        ..sort((a, b) => a.compareTo(b));

      // Si aucune donnée, générer un mois courant avec 0
      if (sorted.isEmpty) {
        final now = DateTime.now();
        sorted.add(DateTime(now.year, now.month));
      }

      // Alimenter les listes observables
      final m = <String>[];
      final vSeries = <double>[];
      final cSeries = <double>[];
      for (final d in sorted) {
        m.add(_mois[d.month - 1]);
        vSeries.add(ventesParMois[d] ?? 0);
        cSeries.add(collecteParMois[d] ?? 0);
      }

      months.assignAll(m);
      ventesMonthly.assignAll(vSeries);
      collecteMonthly.assignAll(cSeries);
    } catch (e) {
      // En cas de souci, ne rien casser: garder listes actuelles
      debugPrint('ChartDataController rebuild error: $e');
    }
  }

  void _buildPieSlicesFromFlorales(Map<String, double> florales) {
    if (florales.isEmpty) {
      pieSlices.assignAll([]);
      return;
    }
    final entries = florales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final palette = <Color>[
      const Color(0xFFF49101), // kHighlightColor
      Colors.deepPurple,
      Colors.green,
      Colors.yellowAccent,
      Colors.orange,
    ];

    final List<_PieSlice> out = [];
    double autres = 0;
    for (int i = 0; i < entries.length; i++) {
      if (i < 4) {
        out.add(_PieSlice(
            entries[i].key, entries[i].value, palette[i % palette.length]));
      } else {
        autres += entries[i].value;
      }
    }
    if (autres > 0) {
      out.add(_PieSlice('Autres', autres, palette[4 % palette.length]));
    }
    pieSlices.assignAll(out);
  }

  // Helpers d'accès pratique pour les charts
  List<FlSpot> get ventesSpots => List.generate(ventesMonthly.length,
      (i) => FlSpot(i.toDouble(), ventesMonthly[i].toDouble()));
  List<FlSpot> get collecteSpots => List.generate(collecteMonthly.length,
      (i) => FlSpot(i.toDouble(), collecteMonthly[i].toDouble()));
}

class _PieSlice {
  final String name;
  final double value;
  final Color color;
  _PieSlice(this.name, this.value, this.color);
}
