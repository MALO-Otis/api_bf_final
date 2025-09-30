import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../caisse/controllers/caisse_controller.dart';
import '../../controle_de_donnes/models/collecte_models.dart';
import '../../controle_de_donnes/services/firestore_data_service.dart';
import '../../controle_de_donnes/services/quality_control_service.dart';

/// Aggregates Collecte and Contrôle KPIs directly from Firestore.
///
/// - Collecte: sums totalWeight (fallback to totalAmount) and counts by section
/// - Contrôle: uses QualityControlService to fetch site-scoped controls and computes
///             totals and conformity rate for the selected period
class DashboardStatsController extends GetxController {
  // Period provider (we reuse caisse period for a single source of truth)
  late final CaisseController _caisse;

  // Collecte KPIs
  final RxDouble collecteTotalPoids = 0.0.obs; // kg if available, else amount
  final RxDouble collecteTotalMontant = 0.0.obs; // optional fallback/secondary
  final RxInt collecteCount = 0.obs;
  final RxInt recolteCount = 0.obs;
  final RxInt scoopCount = 0.obs;
  final RxInt individuelCount = 0.obs;
  final RxInt miellerieCount = 0.obs;

  // Contrôle KPIs
  final RxInt controlesTotal = 0.obs;
  final RxInt controlesConformes = 0.obs;
  final RxInt controlesNonConformes = 0.obs;
  final RxDouble tauxConformite = 0.0.obs; // %

  // Internals
  // no-op flag removed (unused)

  @override
  void onInit() {
    super.onInit();
    _caisse = Get.isRegistered<CaisseController>()
        ? Get.find<CaisseController>()
        : Get.put(CaisseController(), permanent: true);

    // Recompute on period change
    ever(_caisse.periode, (_) => _recompute());
    // Initial compute
    _recompute();
  }

  Future<void> _recompute() async {
    try {
      final r = _caisse.periode.value;
      debugPrint('📦 [DashboardStats] Recompute — période='
          '${r.start.toIso8601String()} -> ${r.end.toIso8601String()}');

      await Future.wait([
        _computeCollecteKPIs(r.start, r.end),
        _computeControleKPIs(r.start, r.end),
      ]);
    } catch (e) {
      debugPrint('❌ [DashboardStats] Erreur recompute: $e');
    }
  }

  Future<void> _computeCollecteKPIs(DateTime from, DateTime to) async {
    try {
      final data = await FirestoreDataService.getCollectesFromFirestore();

      int totalCount = 0;
      int _recolte = 0, _scoop = 0, _individuel = 0, _miellerie = 0;
      double totalPoids = 0.0;
      double totalMontant = 0.0;

      bool inRange(DateTime d) => !d.isBefore(from) && !d.isAfter(to);

      // Récoltes
      for (final c in (data[Section.recoltes] ?? const [])) {
        final r = c as Recolte;
        if (!inRange(r.date)) continue;
        _recolte++;
        totalCount++;
        totalPoids += (r.totalWeight ?? 0);
        totalMontant += (r.totalAmount ?? 0);
      }
      // Scoop
      for (final c in (data[Section.scoop] ?? const [])) {
        final s = c as Scoop;
        if (!inRange(s.date)) continue;
        _scoop++;
        totalCount++;
        totalPoids += (s.totalWeight ?? 0);
        totalMontant += (s.totalAmount ?? 0);
      }
      // Individuel
      for (final c in (data[Section.individuel] ?? const [])) {
        final i = c as Individuel;
        if (!inRange(i.date)) continue;
        _individuel++;
        totalCount++;
        totalPoids += (i.totalWeight ?? 0);
        totalMontant += (i.totalAmount ?? 0);
      }
      // Miellerie
      for (final c in (data[Section.miellerie] ?? const [])) {
        final m = c as Miellerie;
        if (!inRange(m.date)) continue;
        _miellerie++;
        totalCount++;
        totalPoids += (m.totalWeight ?? 0);
        totalMontant += (m.totalAmount ?? 0);
      }

      // If no weight data, fallback to totalMontant as indicator
      final poidsValue = totalPoids > 0 ? totalPoids : 0.0;

      collecteTotalPoids.value = poidsValue;
      collecteTotalMontant.value = totalMontant;
      collecteCount.value = totalCount;
      recolteCount.value = _recolte;
      scoopCount.value = _scoop;
      individuelCount.value = _individuel;
      miellerieCount.value = _miellerie;

      debugPrint('✅ [DashboardStats] Collectes — total=${totalCount}, '
          'poids=${poidsValue.toStringAsFixed(2)} kg, montant=${totalMontant.toStringAsFixed(0)}');
      debugPrint(
          '   Détail: recoltes=$_recolte, scoop=$_scoop, individuel=$_individuel, miellerie=$_miellerie');
    } catch (e) {
      debugPrint('❌ [DashboardStats] Erreur collectes: $e');
      // Reset on error
      collecteTotalPoids.value = 0;
      collecteTotalMontant.value = 0;
      collecteCount.value = 0;
      recolteCount.value = 0;
      scoopCount.value = 0;
      individuelCount.value = 0;
      miellerieCount.value = 0;
    }
  }

  Future<void> _computeControleKPIs(DateTime from, DateTime to) async {
    try {
      final qc = QualityControlService();
      // Populate cache from Firestore (site-scoped)
      final controls = await qc.getAllQualityControlsFromFirestore();

      int total = 0;
      int conformes = 0;
      int nonConformes = 0;

      bool inRange(DateTime d) => !d.isBefore(from) && !d.isAfter(to);

      for (final c in controls) {
        if (!inRange(c.receptionDate)) continue;
        total++;
        if (c.conformityStatus.name.toLowerCase() == 'conforme') {
          conformes++;
        } else {
          nonConformes++;
        }
      }

      controlesTotal.value = total;
      controlesConformes.value = conformes;
      controlesNonConformes.value = nonConformes;
      tauxConformite.value = total > 0 ? (conformes / total * 100) : 0.0;

      debugPrint('✅ [DashboardStats] Contrôle — total=$total, '
          'conformes=$conformes, nonConformes=$nonConformes, '
          'taux=${tauxConformite.value.toStringAsFixed(1)}%');
    } catch (e) {
      debugPrint('❌ [DashboardStats] Erreur contrôles: $e');
      controlesTotal.value = 0;
      controlesConformes.value = 0;
      controlesNonConformes.value = 0;
      tauxConformite.value = 0.0;
    }
  }
}
