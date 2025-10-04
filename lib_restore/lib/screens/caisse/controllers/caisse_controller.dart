import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../services/sales_kpi_service.dart';
import '../../vente/models/vente_models.dart';
import '../models/transaction_commerciale.dart';
import '../../../authentication/user_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // pour DateTimeRange
import '../../vente/controllers/espace_commercial_controller.dart';

/// Controller d'agrégation pour l'Espace Caissier
/// S'appuie exclusivement sur les flux réactifs d'EspaceCommercialController
class CaisseController extends GetxController {
  final EspaceCommercialController espaceCtrl =
      Get.find<EspaceCommercialController>();

  // Filtres
  // Par défaut: 6 derniers mois (évite KPIs = 0 si aucune vente aujourd'hui)
  final Rx<DateTimeRange> periode = Rx<DateTimeRange>(DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 180)),
    end: DateTime.now(),
  ));
  final RxString commercialFiltre = ''.obs; // vide = tous (selon rôle)

  // KPIs principaux
  final RxDouble caBrut = 0.0.obs;
  final RxDouble caNet = 0.0.obs;
  final RxDouble creditAttente = 0.0.obs;
  final RxDouble creditRembourse = 0.0.obs;
  final RxDouble valeurRestitutions = 0.0.obs;
  final RxDouble valeurPertes = 0.0.obs;
  final RxDouble tauxRestitution = 0.0.obs; // %
  final RxDouble tauxPertes = 0.0.obs; // %
  final RxDouble cashTheorique = 0.0.obs;
  final RxDouble efficacite =
      0.0.obs; // produits vendus / produits prélevés sortis

  // Ventilation modes de paiement
  final RxDouble caEspece = 0.0.obs;
  final RxDouble caMobile = 0.0.obs; // mobile money / transfert
  final RxDouble caAutres = 0.0.obs; // chèques, etc.
  final RxDouble pctEspece = 0.0.obs;
  final RxDouble pctMobile = 0.0.obs;
  final RxDouble pctAutres = 0.0.obs;

  // Détails / tables
  final RxList<Vente> ventesFiltrees = <Vente>[].obs;
  final RxList<Restitution> restitutionsFiltrees = <Restitution>[].obs;
  final RxList<Perte> pertesFiltrees = <Perte>[].obs;

  // Top produits (typeEmballage -> map)
  final RxList<MapEntry<String, _ProduitAgg>> topProduits =
      <MapEntry<String, _ProduitAgg>>[].obs;

  // Timeline CA (points agrégés par jour ou heure)
  final RxList<_PointCA> timeline = <_PointCA>[].obs;

  // Anomalies simples
  final RxList<String> anomalies = <String>[].obs;

  // ================= RECONCILIATION CAISSIER =================
  // Lignes synthétiques par commercial pour validation / approbation
  final RxList<CaisseReconciliationLine> reconciliationLines =
      <CaisseReconciliationLine>[].obs;
  final RxMap<String, double> _cashRecu =
      <String, double>{}.obs; // commercialId -> montant saisi
  final RxBool reconciliationAuto = true.obs; // si recalcul auto après saisie
  // Evite d'élargir la période plus d'une fois automatiquement
  bool _autoExpandedOnce = false;

  void setCashRecu(String commercialId, double montant) {
    _cashRecu[commercialId] = montant;
    _recomputeReconciliation();
  }

  double cashRecuFor(String commercialId) => _cashRecu[commercialId] ?? 0;

  @override
  void onInit() {
    super.onInit();
    // Ecoute des flux de base pour recomputations
    everAll([
      espaceCtrl.ventes,
      espaceCtrl.restitutions,
      espaceCtrl.pertes,
      periode,
      commercialFiltre,
    ], (_) => _recompute());
    _recompute();
  }

  void setPeriode(DateTimeRange range) {
    periode.value = range;
  }

  void setCommercial(String id) {
    commercialFiltre.value = id; // vide = tous
  }

  bool _inPeriode(DateTime d) {
    final r = periode.value;
    return !d.isBefore(r.start) && !d.isAfter(r.end);
  }

  bool _matchCommercial(String commercialId) {
    if (commercialFiltre.value.isEmpty) return true;
    return commercialId == commercialFiltre.value;
  }

  Future<void> _recompute() async {
    // Diagnostics sur la période et le commercial
    final r = periode.value;
    final filtre =
        commercialFiltre.value.isEmpty ? 'TOUS' : commercialFiltre.value;
    print("📆 [CaisseController] Recompute KPIs pour période: "
        "${DateFormat('yyyy-MM-dd HH:mm').format(r.start)} -> "
        "${DateFormat('yyyy-MM-dd HH:mm').format(r.end)} | filtre commercial=$filtre");

    // 1) DB-first aggregation for KPIs
    try {
      final site = espaceCtrl.effectiveSite;
      final r = periode.value;
      String? commercialId;
      if (commercialFiltre.value.isNotEmpty) {
        commercialId = commercialFiltre.value;
      } else if (espaceCtrl.isWideScopeRole) {
        commercialId = null; // agrégation site complète
      } else {
        // Commercial: prendre l'email utilisateur courant
        try {
          final session = Get.find<UserSession>();
          commercialId = session.email;
        } catch (_) {
          commercialId = null;
        }
      }
      final svc = await SalesKpiService.getKpis(
        site: site,
        start: r.start,
        end: r.end,
        commercialId: commercialId,
      );
      if (svc != null) {
        caBrut.value = svc.caBrut;
        creditAttente.value = svc.creditAttente;
        creditRembourse.value = svc.creditRembourse;
        caNet.value = svc.caNet;
        valeurRestitutions.value = svc.valeurRestitutions;
        valeurPertes.value = svc.valeurPertes;
        tauxRestitution.value =
            svc.caBrut > 0 ? (svc.valeurRestitutions / svc.caBrut * 100) : 0;
        tauxPertes.value =
            svc.caBrut > 0 ? (svc.valeurPertes / svc.caBrut * 100) : 0;
        cashTheorique.value = svc.caNet;
        caEspece.value = svc.caEspece;
        caMobile.value = svc.caMobile;
        caAutres.value = svc.caAutres;
        if (svc.caBrut > 0) {
          pctEspece.value = svc.caEspece / svc.caBrut * 100;
          pctMobile.value = svc.caMobile / svc.caBrut * 100;
          pctAutres.value = svc.caAutres / svc.caBrut * 100;
        } else {
          pctEspece.value = pctMobile.value = pctAutres.value = 0;
        }

        print('✅ [CaisseController] KPIs mis à jour depuis Firestore '
            '(DB-first). Site=$site, commercial=${commercialId ?? 'ALL'}');

        // Top produits & timeline need concrete lists; if ventes list is empty, we attempt a light fetch to build them
        // Here, keep legacy derived lists if present; otherwise leave charts as-is
      } else {
        print(
            '🟡 [CaisseController] Service KPIs Firestore nul — on passe au chemin local.');
        throw Exception('Service KPI null');
      }
    } catch (e) {
      print(
          '🟠 [CaisseController] DB-first KPIs échoués: $e — on utilise les listes locales.');

      // 2) Legacy local lists as fallback for KPIs and charts
      final ventes = espaceCtrl.ventes
          .where((v) =>
              _inPeriode(v.dateVente) && _matchCommercial(v.commercialId))
          .toList();
      final restits = espaceCtrl.restitutions
          .where((r) =>
              _inPeriode(r.dateRestitution) && _matchCommercial(r.commercialId))
          .toList();
      final pertes = espaceCtrl.pertes
          .where((p) =>
              _inPeriode(p.datePerte) && _matchCommercial(p.commercialId))
          .toList();

      print(
          '📊 [CaisseController] Données filtrées (fallback local) — ventes=${ventes.length}, '
          'restitutions=${restits.length}, pertes=${pertes.length}');

      // Auto‑expand (une seule fois) si aucune donnée trouvée dans la période
      if (ventes.isEmpty &&
          restits.isEmpty &&
          pertes.isEmpty &&
          !_autoExpandedOnce) {
        _autoExpandedOnce = true;
        final expanded = DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 365)),
          end: DateTime.now(),
        );
        print(
            'ℹ️ [CaisseController] Aucune donnée locale — extension automatique à 12 mois: '
            '${DateFormat('yyyy-MM-dd').format(expanded.start)} -> '
            '${DateFormat('yyyy-MM-dd').format(expanded.end)}');
        periode.value = expanded; // déclenchera un nouveau _recompute
        return;
      }

      // Fallback: si toujours aucune donnée (même après éventuelle extension),
      // tenter une agrégation depuis transactions_commerciales
      if (ventes.isEmpty && restits.isEmpty && pertes.isEmpty) {
        final ok = await _recomputeFromTransactionsFallback();
        if (ok) return; // KPIs mis à jour via fallback
      }

      ventesFiltrees.assignAll(ventes);
      restitutionsFiltrees.assignAll(restits);
      pertesFiltrees.assignAll(pertes);

      double _caBrut = 0, _creditAttente = 0, _creditRembourse = 0;
      double _espece = 0,
          _mobile = 0,
          _autres = 0; // ventilation brute (non annulées uniquement)
      int produitsVendus = 0;
      for (final v in ventes) {
        if (v.statut != StatutVente.annulee) {
          _caBrut += v.montantTotal;
          produitsVendus += v.produits.fold(0, (s, p) => s + p.quantiteVendue);
          // Ventilation par mode (on répartit en brut, même si crédit partiel)
          switch (v.modePaiement) {
            case ModePaiement.espece:
              _espece += v.montantTotal;
              break;
            case ModePaiement.mobile:
              _mobile += v.montantTotal;
              break;
            case ModePaiement.virement:
            case ModePaiement.carte:
            case ModePaiement.cheque:
            case ModePaiement
                  .credit: // On regroupe dans autres pour la ventilation brute
              _autres += v.montantTotal;
              break;
          }
        }
        if (v.statut == StatutVente.creditEnAttente)
          _creditAttente += v.montantTotal;
        if (v.statut == StatutVente.creditRembourse)
          _creditRembourse += v.montantTotal;
      }

      double _valRestits = 0;
      int produitsRestitues = 0;
      for (final r in restits) {
        _valRestits += r.valeurTotale;
        produitsRestitues +=
            r.produits.fold(0, (s, p) => s + p.quantiteRestituee);
      }

      double _valPertes = 0;
      int produitsPerdus = 0;
      for (final p in pertes) {
        _valPertes += p.valeurTotale;
        produitsPerdus += p.produits.fold(0, (s, x) => s + x.quantitePerdue);
      }

      final _caNet = _caBrut - _creditAttente;
      final _cashTheo =
          _caNet; // (si politique: pertes déjà exclues des ventes)

      caBrut.value = _caBrut;
      creditAttente.value = _creditAttente;
      creditRembourse.value = _creditRembourse;
      caNet.value = _caNet;
      valeurRestitutions.value = _valRestits;
      valeurPertes.value = _valPertes;
      tauxRestitution.value = _caBrut > 0 ? (_valRestits / _caBrut * 100) : 0;
      tauxPertes.value = _caBrut > 0 ? (_valPertes / _caBrut * 100) : 0;
      cashTheorique.value = _cashTheo;

      // Ventilation
      caEspece.value = _espece;
      caMobile.value = _mobile;
      caAutres.value = _autres;
      if (_caBrut > 0) {
        pctEspece.value = _espece / _caBrut * 100;
        pctMobile.value = _mobile / _caBrut * 100;
        pctAutres.value = _autres / _caBrut * 100;
      } else {
        pctEspece.value = pctMobile.value = pctAutres.value = 0;
      }

      // Efficacité simple = produits vendus / (produits vendus + restitués + perdus)
      final denom = (produitsVendus + produitsRestitues + produitsPerdus);
      efficacite.value = denom > 0 ? (produitsVendus / denom * 100) : 0;

      _computeTopProduits(ventes);
      _computeTimeline(ventes);
      _detectAnomalies(ventes, restits, pertes);
      _recomputeReconciliation();
    }
  }

  /// Recalcule les KPIs depuis la collection transactions_commerciales
  /// lorsque les sous-collections Vente/{site}/... sont vides.
  /// Retourne true si le fallback a été utilisé et les KPIs mis à jour.
  Future<bool> _recomputeFromTransactionsFallback() async {
    try {
      final site = espaceCtrl.effectiveSite;
      if (site.isEmpty) return false;
      final r = periode.value;

      print('🟡 [CaisseController] Fallback transactions_commerciales activé '
          'pour site=$site, période='
          '${DateFormat('yyyy-MM-dd').format(r.start)} -> '
          '${DateFormat('yyyy-MM-dd').format(r.end)}');

      final snap = await FirebaseFirestore.instance
          .collection('transactions_commerciales')
          .where('site', isEqualTo: site)
          .where('dateCreation',
              isGreaterThanOrEqualTo: Timestamp.fromDate(r.start))
          .where('dateCreation', isLessThanOrEqualTo: Timestamp.fromDate(r.end))
          .get();

      if (snap.docs.isEmpty) {
        print(
            '🟡 [CaisseController] Aucun document dans transactions_commerciales '
            'pour le site/période.');
        return false;
      }

      final txs = snap.docs
          .map((d) => TransactionCommerciale.fromMap(d.data()))
          .toList();

      double _caBrut = 0,
          _creditAttente = 0,
          _creditRembourse = 0, // non fourni directement, on le laisse à 0
          _valRestits =
              0, // non disponible en valeur dans le modèle de transaction
          _valPertes = 0,
          _espece = 0,
          _mobile = 0,
          _autres = 0;

      // Agrégation financière depuis le résumé de chaque transaction
      for (final t in txs) {
        final rfin = t.resumeFinancier;
        _caBrut += rfin.totalVentes;
        _creditAttente += rfin.totalCredits;
        _valPertes += rfin.totalPertes;
        // Restitutions en valeur non disponibles -> laisser à 0 et journaliser
        _espece += rfin.espece;
        _mobile += rfin.mobile;
        _autres += rfin.autres;
      }

      final _caNet = _caBrut - _creditAttente;
      final _cashTheo = _caNet;

      // Affectation KPIs
      caBrut.value = _caBrut;
      creditAttente.value = _creditAttente;
      creditRembourse.value = _creditRembourse;
      caNet.value = _caNet;
      valeurRestitutions.value = _valRestits;
      valeurPertes.value = _valPertes;
      tauxRestitution.value = _caBrut > 0 ? (_valRestits / _caBrut * 100) : 0;
      tauxPertes.value = _caBrut > 0 ? (_valPertes / _caBrut * 100) : 0;
      cashTheorique.value = _cashTheo;

      // Ventilation
      caEspece.value = _espece;
      caMobile.value = _mobile;
      caAutres.value = _autres;
      if (_caBrut > 0) {
        pctEspece.value = _espece / _caBrut * 100;
        pctMobile.value = _mobile / _caBrut * 100;
        pctAutres.value = _autres / _caBrut * 100;
      } else {
        pctEspece.value = pctMobile.value = pctAutres.value = 0;
      }

      // Top produits (par typeEmballage) et timeline à partir des détails de ventes des transactions
      _computeTopProduitsFromTransactions(txs);
      _computeTimelineFromTransactions(txs);

      // Anomalies basées sur les KPIs courants
      anomalies.assignAll([]);
      _detectAnomalies(const [], const [], const []);

      // Réconciliation non disponible sans modèles Vente/Restitution/Perte détaillés
      reconciliationLines.assignAll([]);

      print('✅ [CaisseController] KPIs mis à jour via fallback transactions '
          '(tx=${txs.length}). Note: valeurRestitutions indisponible → 0.');
      return true;
    } catch (e) {
      print('❌ [CaisseController] Erreur fallback transactions: $e');
      return false;
    }
  }

  void _computeTopProduitsFromTransactions(List<TransactionCommerciale> txs) {
    final Map<String, _ProduitAgg> agg = {};
    for (final t in txs) {
      for (final v in t.ventes) {
        for (final p in v.produits) {
          final key = p.typeEmballage;
          agg.update(key, (old) => old.add(p.quantiteVendue, p.montantTotal),
              ifAbsent: () => _ProduitAgg(p.quantiteVendue, p.montantTotal));
        }
      }
    }
    final sorted = agg.entries.toList()
      ..sort((a, b) => b.value.montant.compareTo(a.value.montant));
    topProduits.assignAll(sorted.take(5));
  }

  void _computeTimelineFromTransactions(List<TransactionCommerciale> txs) {
    final r = periode.value;
    final sameDay = r.start.year == r.end.year &&
        r.start.month == r.end.month &&
        r.start.day == r.end.day;
    final Map<String, double> buckets = {};
    final fmt = sameDay ? DateFormat('HH') : DateFormat('dd/MM');
    for (final t in txs) {
      for (final v in t.ventes) {
        final key = fmt.format(v.date);
        buckets.update(key, (old) => old + v.montantTotal,
            ifAbsent: () => v.montantTotal);
      }
    }
    final points = buckets.entries.map((e) => _PointCA(e.key, e.value)).toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    timeline.assignAll(points);
  }

  void _recomputeReconciliation() {
    final List<CaisseReconciliationLine> lignes = [];
    final Map<String, _CommercialAgg> agg = {};
    for (final v in ventesFiltrees) {
      if (v.statut == StatutVente.annulee) continue;
      final a = agg.putIfAbsent(
          v.commercialId,
          () => _CommercialAgg(
              commercialId: v.commercialId, commercialNom: v.commercialId));
      a.caBrut += v.montantTotal;
      if (v.statut == StatutVente.creditEnAttente) a.credit += v.montantTotal;
      if (v.statut == StatutVente.creditRembourse)
        a.creditRembourse += v.montantTotal;
      switch (v.modePaiement) {
        case ModePaiement.espece:
          a.caEspece += v.montantTotal;
          break;
        case ModePaiement.mobile:
          a.caMobile += v.montantTotal;
          break;
        default:
          a.caAutres += v.montantTotal;
      }
    }
    for (final r in restitutionsFiltrees) {
      final a = agg.putIfAbsent(
          r.commercialId,
          () => _CommercialAgg(
              commercialId: r.commercialId, commercialNom: r.commercialId));
      a.restitutions += r.valeurTotale;
    }
    for (final p in pertesFiltrees) {
      final a = agg.putIfAbsent(
          p.commercialId,
          () => _CommercialAgg(
              commercialId: p.commercialId, commercialNom: p.commercialId));
      a.pertes += p.valeurTotale;
    }
    agg.forEach((_, a) {
      final theorique = a.caBrut - a.credit + a.creditRembourse;
      final montantRecu = cashRecuFor(a.commercialId);
      final ecart = montantRecu - theorique;
      lignes.add(CaisseReconciliationLine(
        commercialId: a.commercialId,
        commercialNom: a.commercialNom,
        caBrut: a.caBrut,
        credit: a.credit,
        creditRembourse: a.creditRembourse,
        restitutions: a.restitutions,
        pertes: a.pertes,
        caEspece: a.caEspece,
        caMobile: a.caMobile,
        caAutres: a.caAutres,
        cashTheorique: theorique,
        cashRecu: montantRecu,
        ecart: ecart,
      ));
    });
    lignes.sort((a, b) => a.commercialNom.compareTo(b.commercialNom));
    reconciliationLines.assignAll(lignes);
  }

  void _computeTopProduits(List<Vente> ventes) {
    final Map<String, _ProduitAgg> agg = {};
    for (final v in ventes) {
      for (final p in v.produits) {
        final key = p.typeEmballage;
        agg.update(key, (old) => old.add(p.quantiteVendue, p.montantTotal),
            ifAbsent: () => _ProduitAgg(p.quantiteVendue, p.montantTotal));
      }
    }
    final sorted = agg.entries.toList()
      ..sort((a, b) => b.value.montant.compareTo(a.value.montant));
    topProduits.assignAll(sorted.take(5));
  }

  void _computeTimeline(List<Vente> ventes) {
    final r = periode.value;
    final sameDay = r.start.year == r.end.year &&
        r.start.month == r.end.month &&
        r.start.day == r.end.day;
    final Map<String, double> buckets = {};
    final fmt = sameDay ? DateFormat('HH') : DateFormat('dd/MM');
    for (final v in ventes) {
      final key = fmt.format(v.dateVente);
      buckets.update(key, (old) => old + v.montantTotal,
          ifAbsent: () => v.montantTotal);
    }
    final points = buckets.entries.map((e) => _PointCA(e.key, e.value)).toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    timeline.assignAll(points);
  }

  void _detectAnomalies(
      List<Vente> ventes, List<Restitution> restits, List<Perte> pertes) {
    final List<String> list = [];
    final annulees =
        ventes.where((v) => v.statut == StatutVente.annulee).length;
    if (annulees >= 3) list.add('Beaucoup de ventes annulées ($annulees)');
    if (creditAttente.value > 0 &&
        creditAttente.value / (caBrut.value == 0 ? 1 : caBrut.value) > 0.4) {
      list.add('Crédits élevés (>40% CA)');
    }
    if (tauxPertes.value > 5) {
      list.add('Taux de pertes anormal (>5%)');
    }
    if (tauxRestitution.value > 30) {
      list.add('Taux de restitution élevé (>30%)');
    }
    // Anomalie ventilation : un mode >90% si CA brut > 100k (suspect de non diversification)
    if (caBrut.value > 100000) {
      if (pctEspece.value > 90) list.add('Dépendance forte à l\'espèce (>90%)');
      if (pctMobile.value > 90)
        list.add('Dépendance forte au mobile money (>90%)');
    }
    anomalies.assignAll(list);
  }

  // --- EXPORT / SNAPSHOT ---
  CaisseKPIs snapshot() => CaisseKPIs(
        periode: periode.value,
        caBrut: caBrut.value,
        caNet: caNet.value,
        creditAttente: creditAttente.value,
        creditRembourse: creditRembourse.value,
        valeurRestitutions: valeurRestitutions.value,
        valeurPertes: valeurPertes.value,
        tauxRestitution: tauxRestitution.value,
        tauxPertes: tauxPertes.value,
        cashTheorique: cashTheorique.value,
        efficacite: efficacite.value,
        caEspece: caEspece.value,
        caMobile: caMobile.value,
        caAutres: caAutres.value,
        pctEspece: pctEspece.value,
        pctMobile: pctMobile.value,
        pctAutres: pctAutres.value,
        anomalies: anomalies.toList(),
      );

  String exportCsv(
      {bool includeTimeline = true, bool includeTopProduits = true}) {
    final buf = StringBuffer();
    final snap = snapshot();
    buf.writeln('Section;Cle;Valeur');
    void w(String cle, Object v) => buf.writeln('KPIs;$cle;$v');
    w('PeriodeStart', snap.periode.start.toIso8601String());
    w('PeriodeEnd', snap.periode.end.toIso8601String());
    w('CaBrut', snap.caBrut.toStringAsFixed(2));
    w('CaNet', snap.caNet.toStringAsFixed(2));
    w('CreditAttente', snap.creditAttente.toStringAsFixed(2));
    w('CreditRembourse', snap.creditRembourse.toStringAsFixed(2));
    w('ValeurRestitutions', snap.valeurRestitutions.toStringAsFixed(2));
    w('ValeurPertes', snap.valeurPertes.toStringAsFixed(2));
    w('TauxRestitution', snap.tauxRestitution.toStringAsFixed(2));
    w('TauxPertes', snap.tauxPertes.toStringAsFixed(2));
    w('CashTheorique', snap.cashTheorique.toStringAsFixed(2));
    w('Efficacite', snap.efficacite.toStringAsFixed(2));
    w('CaEspece', snap.caEspece.toStringAsFixed(2));
    w('CaMobile', snap.caMobile.toStringAsFixed(2));
    w('CaAutres', snap.caAutres.toStringAsFixed(2));
    w('PctEspece', snap.pctEspece.toStringAsFixed(2));
    w('PctMobile', snap.pctMobile.toStringAsFixed(2));
    w('PctAutres', snap.pctAutres.toStringAsFixed(2));
    if (snap.anomalies.isNotEmpty) {
      for (final a in snap.anomalies) {
        buf.writeln('Anomalies;Alerte;$a');
      }
    }
    if (includeTimeline) {
      for (final p in timeline) {
        buf.writeln('Timeline;${p.label};${p.valeur.toStringAsFixed(2)}');
      }
    }
    if (includeTopProduits) {
      for (final e in topProduits) {
        buf.writeln(
            'TopProduit;${e.key};${e.value.montant.toStringAsFixed(2)}');
      }
    }
    return buf.toString();
  }
}

class _ProduitAgg {
  int quantite;
  double montant;
  _ProduitAgg(this.quantite, this.montant);
  _ProduitAgg add(int q, double m) {
    quantite += q;
    montant += m;
    return this;
  }
}

class _PointCA {
  final String label;
  final double valeur;
  _PointCA(this.label, this.valeur);
}

class CaisseKPIs {
  final DateTimeRange periode;
  final double caBrut;
  final double caNet;
  final double creditAttente;
  final double creditRembourse;
  final double valeurRestitutions;
  final double valeurPertes;
  final double tauxRestitution;
  final double tauxPertes;
  final double cashTheorique;
  final double efficacite;
  final double caEspece;
  final double caMobile;
  final double caAutres;
  final double pctEspece;
  final double pctMobile;
  final double pctAutres;
  final List<String> anomalies;
  CaisseKPIs({
    required this.periode,
    required this.caBrut,
    required this.caNet,
    required this.creditAttente,
    required this.creditRembourse,
    required this.valeurRestitutions,
    required this.valeurPertes,
    required this.tauxRestitution,
    required this.tauxPertes,
    required this.cashTheorique,
    required this.efficacite,
    required this.caEspece,
    required this.caMobile,
    required this.caAutres,
    required this.pctEspece,
    required this.pctMobile,
    required this.pctAutres,
    required this.anomalies,
  });
}

// ================== MODELES RECONCILIATION ==================
class CaisseReconciliationLine {
  final String commercialId;
  final String commercialNom;
  final double caBrut;
  final double credit;
  final double creditRembourse;
  final double restitutions;
  final double pertes;
  final double caEspece;
  final double caMobile;
  final double caAutres;
  final double
      cashTheorique; // estimation encaissement attendu (brut - credit + credit remb.)
  final double cashRecu; // saisi par caissier
  final double ecart; // cashRecu - cashTheorique
  CaisseReconciliationLine({
    required this.commercialId,
    required this.commercialNom,
    required this.caBrut,
    required this.credit,
    required this.creditRembourse,
    required this.restitutions,
    required this.pertes,
    required this.caEspece,
    required this.caMobile,
    required this.caAutres,
    required this.cashTheorique,
    required this.cashRecu,
    required this.ecart,
  });
}

class _CommercialAgg {
  final String commercialId;
  final String commercialNom;
  double caBrut = 0;
  double credit = 0;
  double creditRembourse = 0;
  double restitutions = 0;
  double pertes = 0;
  double caEspece = 0;
  double caMobile = 0;
  double caAutres = 0;
  _CommercialAgg({required this.commercialId, required this.commercialNom});
}
