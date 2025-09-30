import 'package:flutter/foundation.dart';
import '../../vente/models/vente_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SalesKpis {
  final double caBrut;
  final double creditAttente;
  final double creditRembourse;
  final double caEspece;
  final double caMobile;
  final double caAutres;
  final double valeurRestitutions;
  final double valeurPertes;
  const SalesKpis({
    required this.caBrut,
    required this.creditAttente,
    required this.creditRembourse,
    required this.caEspece,
    required this.caMobile,
    required this.caAutres,
    required this.valeurRestitutions,
    required this.valeurPertes,
  });
  double get caNet => caBrut - creditAttente;
}

class SalesKpiService {
  static final _db = FirebaseFirestore.instance;

  /// Aggregates KPIs from Firestore collections under Vente/{site}/...
  /// - Filters by date range and optional commercialId
  static Future<SalesKpis?> getKpis({
    required String site,
    required DateTime start,
    required DateTime end,
    String? commercialId,
  }) async {
    if (site.isEmpty) return null;
    try {
      if (kDebugMode) {
        debugPrint('[SalesKpiService] Fetch KPIs site=$site, '
            'range=${start.toIso8601String()} -> ${end.toIso8601String()}, '
            'commercialId=${commercialId ?? "<ALL>"}');
      }

      // Fetch ventes
      Query ventesQ = _db
          .collection('Vente')
          .doc(site)
          .collection('ventes')
          .where('dateVente', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('dateVente', isLessThanOrEqualTo: Timestamp.fromDate(end));
      if (commercialId != null && commercialId.isNotEmpty) {
        ventesQ = ventesQ.where('commercialId', isEqualTo: commercialId);
      }
      final ventesSnap = await ventesQ.get();

      double caBrut = 0,
          creditAttente = 0,
          creditRembourse = 0,
          caEspece = 0,
          caMobile = 0,
          caAutres = 0;

      for (final d in ventesSnap.docs) {
        final v = Vente.fromMap(d.data() as Map<String, dynamic>);
        if (v.statut != StatutVente.annulee) {
          caBrut += v.montantTotal;
          switch (v.modePaiement) {
            case ModePaiement.espece:
              caEspece += v.montantTotal;
              break;
            case ModePaiement.mobile:
              caMobile += v.montantTotal;
              break;
            default:
              caAutres += v.montantTotal;
          }
        }
        if (v.statut == StatutVente.creditEnAttente)
          creditAttente += v.montantTotal;
        if (v.statut == StatutVente.creditRembourse)
          creditRembourse += v.montantTotal;
      }

      // Fetch restitutions
      Query restitsQ = _db
          .collection('Vente')
          .doc(site)
          .collection('restitutions')
          .where('dateRestitution',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('dateRestitution',
              isLessThanOrEqualTo: Timestamp.fromDate(end));
      if (commercialId != null && commercialId.isNotEmpty) {
        restitsQ = restitsQ.where('commercialId', isEqualTo: commercialId);
      }
      final restitsSnap = await restitsQ.get();
      double valeurRestitutions = 0;
      for (final d in restitsSnap.docs) {
        final r = Restitution.fromMap(d.data() as Map<String, dynamic>);
        valeurRestitutions += r.valeurTotale;
      }

      // Fetch pertes
      Query pertesQ = _db
          .collection('Vente')
          .doc(site)
          .collection('pertes')
          .where('datePerte', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('datePerte', isLessThanOrEqualTo: Timestamp.fromDate(end));
      if (commercialId != null && commercialId.isNotEmpty) {
        pertesQ = pertesQ.where('commercialId', isEqualTo: commercialId);
      }
      final pertesSnap = await pertesQ.get();
      double valeurPertes = 0;
      for (final d in pertesSnap.docs) {
        final p = Perte.fromMap(d.data() as Map<String, dynamic>);
        valeurPertes += p.valeurTotale;
      }

      return SalesKpis(
        caBrut: caBrut,
        creditAttente: creditAttente,
        creditRembourse: creditRembourse,
        caEspece: caEspece,
        caMobile: caMobile,
        caAutres: caAutres,
        valeurRestitutions: valeurRestitutions,
        valeurPertes: valeurPertes,
      );
    } catch (e) {
      debugPrint('❌ [SalesKpiService] Erreur agrégation KPIs: $e');
      return null;
    }
  }
}
