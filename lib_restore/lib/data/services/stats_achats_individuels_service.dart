import 'package:cloud_firestore/cloud_firestore.dart';

class StatsAchatsIndividuelsService {
  // Recalcule entièrement les statistiques avancées pour un site
  static Future<void> regenerateAdvancedStats(String site) async {
    final firestore = FirebaseFirestore.instance;

    // 1) Charger producteurs
    final producteursSnap = await firestore
        .collection('Sites')
        .doc(site)
        .collection('listes_prod')
        .get();

    // 2) Charger collectes individuelles
    final collectesSnap = await firestore
        .collection('Sites')
        .doc(site)
        .collection('nos_achats_individuels')
        .get();

    // Aggregations par village
    final Map<String, dynamic> villagesAgg = {};
    // Collectes par producteur
    final Map<String, dynamic> collectesProducteursAgg = {};

    // Index producteurs -> village / nom
    final Map<String, Map<String, String>> prodIndex = {};
    for (final d in producteursSnap.docs) {
      final data = d.data();
      final localisation =
          (data['localisation'] as Map<String, dynamic>?) ?? {};
      final village = localisation['village']?.toString() ?? 'Non spécifié';
      prodIndex[d.id] = {
        'village': village,
        'nom': data['nomPrenom']?.toString() ?? 'Nom inconnu',
      };
      villagesAgg.putIfAbsent(
          village,
          () => {
                'nom': village,
                'producteursSet': <String>{},
                // contenant par type
                'contenants': <String, Map<String, dynamic>>{},
                // quantités totales par type de miel
                'qteParType': <String, double>{},
              });
      (villagesAgg[village]['producteursSet'] as Set<String>).add(d.id);
    }

    for (final c in collectesSnap.docs) {
      final data = c.data();
      final idProd = data['id_producteur']?.toString() ?? '';
      final nomProd = data['nom_producteur']?.toString() ?? '';
      final contenants = (data['contenants'] as List<dynamic>?) ?? const [];
      final ts = (data['date_achat'] as Timestamp?) ??
          data['created_at'] as Timestamp?;
      final date = ts?.toDate() ?? DateTime.now();

      // Période min/max par producteur + compteur + décompte contenants/miel
      final cp = collectesProducteursAgg.putIfAbsent(
          idProd,
          () => {
                'id': idProd,
                'nom': nomProd,
                'collectes': 0,
                'first': date,
                'last': date,
                'containers': <String, int>{'Bidon': 0, 'Pot': 0},
                'miels': <String, int>{'Liquide': 0, 'Brute': 0, 'Cire': 0},
              }) as Map<String, dynamic>;
      cp['collectes'] = (cp['collectes'] as int) + 1;
      if (date.isBefore(cp['first'] as DateTime)) cp['first'] = date;
      if (date.isAfter(cp['last'] as DateTime)) cp['last'] = date;

      // Village du producteur
      final village = prodIndex[idProd]?['village'] ?? 'Non spécifié';
      final vBloc = villagesAgg.putIfAbsent(
          village,
          () => {
                'nom': village,
                'producteursSet': <String>{},
                'contenants': <String, Map<String, dynamic>>{},
                'qteParType': <String, double>{},
              }) as Map<String, dynamic>;

      for (final raw in contenants) {
        final m = raw as Map<String, dynamic>;
        final typeContenant = (m['type_contenant']?.toString() ?? '').trim();
        final typeMiel = (m['type_miel']?.toString() ?? '').trim();
        final quantite = (m['quantite'] ?? 0).toDouble();
        final prixUnitaire = (m['prix_unitaire'] ?? 0).toDouble();
        final montant =
            (m['montant_total'] ?? (quantite * prixUnitaire)).toDouble();

        if (typeContenant.isEmpty) continue;
        // Décompte containers/miel pour producteur
        final containers = cp['containers'] as Map<String, int>;
        containers[typeContenant] = (containers[typeContenant] ?? 0) + 1;
        final miels = cp['miels'] as Map<String, int>;
        miels[typeMiel] = (miels[typeMiel] ?? 0) + 1;

        // Village: bloc contenant
        final contenantsBloc =
            vBloc['contenants'] as Map<String, Map<String, dynamic>>;
        final cb = contenantsBloc.putIfAbsent(
            typeContenant,
            () => {
                  'type': typeContenant,
                  'nombre': 0,
                  'contenues': <String, Map<String, dynamic>>{},
                  'prixTotal': 0.0,
                });
        cb['nombre'] = (cb['nombre'] as int) + 1;
        cb['prixTotal'] = (cb['prixTotal'] as double) + montant;

        final contenues = cb['contenues'] as Map<String, Map<String, dynamic>>;
        final cc = contenues.putIfAbsent(
            typeMiel,
            () => {
                  'type': typeMiel,
                  'nombre': 0,
                  'poidsTotal': 0.0,
                  'prixTotal': 0.0,
                });
        cc['nombre'] = (cc['nombre'] as int) + 1;
        cc['poidsTotal'] = (cc['poidsTotal'] as double) + quantite;
        cc['prixTotal'] = (cc['prixTotal'] as double) + montant;

        // Village: quantités totales par type miel
        final qteParType = vBloc['qteParType'] as Map<String, double>;
        qteParType[typeMiel] = (qteParType[typeMiel] ?? 0) + quantite;
      }
    }

    // Conversion villages -> structure finale
    final List<Map<String, dynamic>> villages = [];
    villagesAgg.forEach((nomVillage, v) {
      final contenants = v['contenants'] as Map<String, Map<String, dynamic>>;
      final List<Map<String, dynamic>> contenantsList = [];
      contenants.forEach((k, bloc) {
        final contenues =
            bloc['contenues'] as Map<String, Map<String, dynamic>>;
        final List<Map<String, dynamic>> contenuesList = [];
        contenues.forEach((tm, c) {
          final n = (c['nombre'] as int);
          final poidsTotal = (c['poidsTotal'] as double);
          final prixTotal = (c['prixTotal'] as double);
          contenuesList.add({
            'type': c['type'],
            'nombre': n,
            'poidsMoyen': n > 0 ? (poidsTotal / n) : 0.0,
            'prixMoyen': n > 0 ? (prixTotal / n) : 0.0,
          });
        });
        contenantsList.add({
          'type': bloc['type'],
          'nombre': bloc['nombre'],
          'contenues': contenuesList,
          'prixTotal': (bloc['prixTotal'] as double),
        });
      });
      final qteParType = v['qteParType'] as Map<String, double>;
      final quantitesTotale = qteParType.entries
          .map((e) => {'type': e.key, 'quantite': e.value})
          .toList();

      final producteurs = (v['producteursSet'] as Set<String>).length;
      villages.add({
        'nom': nomVillage,
        'producteurs': producteurs,
        'contenant': contenantsList,
        'quantitesTotale': quantitesTotale,
      });
    });

    // collectesProducteurs -> structure finale
    final List<Map<String, dynamic>> collectesProducteurs = [];
    collectesProducteursAgg.forEach((id, cp) {
      final first = cp['first'] as DateTime;
      final last = cp['last'] as DateTime;
      final String periode = 'du ${_ddmmyyyy(first)} au ${_ddmmyyyy(last)}';
      final containers = (cp['containers'] as Map<String, int>);
      final miels = (cp['miels'] as Map<String, int>);
      collectesProducteurs.add({
        'id': id,
        'nom': cp['nom'],
        'collectes': [
          {
            'periode': periode,
            'nombre': cp['collectes'],
            'Pots': {
              'nombre': containers['Pot'] ?? 0,
              'types': miels, // répartition brute par type de miel
            },
            'Bidons': {
              'nombre': containers['Bidon'] ?? 0,
              'types': miels,
            }
          }
        ],
      });
    });

    // Écriture finale
    final statsRef = firestore
        .collection('Sites')
        .doc(site)
        .collection('nos_achats_individuels')
        .doc('statistiques_avancees');

    await statsRef.set({
      'villages': villages,
      'collectesProducteurs': collectesProducteurs,
      'updated_at': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  // Applique un delta sur site_infos/infos pour un mois
  static Future<void> applySiteInfosDelta({
    required String site,
    required String monthKey, // YYYY-MM
    double poidsDelta = 0,
    double montantDelta = 0,
    int deltaBidon = 0,
    int deltaPot = 0,
    List<String> mielTypesToUnion = const [],
  }) async {
    final ref = FirebaseFirestore.instance
        .collection('Sites')
        .doc(site)
        .collection('site_infos')
        .doc('infos');

    await ref.set({
      'total_poids_collecte_individuelle': FieldValue.increment(poidsDelta),
      'total_montant_collecte_individuelle': FieldValue.increment(montantDelta),
      'poids_par_mois.$monthKey': FieldValue.increment(poidsDelta),
      'montant_par_mois.$monthKey': FieldValue.increment(montantDelta),
      'contenant_collecter_par_mois.$monthKey.total':
          FieldValue.increment((deltaBidon + deltaPot).toDouble()),
      'contenant_collecter_par_mois.$monthKey.Bidon':
          FieldValue.increment(deltaBidon.toDouble()),
      'contenant_collecter_par_mois.$monthKey.Pot':
          FieldValue.increment(deltaPot.toDouble()),
      'miel_types_cumules': FieldValue.arrayUnion(mielTypesToUnion),
      'derniere_activite': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  static String _ddmmyyyy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
