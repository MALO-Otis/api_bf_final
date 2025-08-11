import 'package:cloud_firestore/cloud_firestore.dart';

class StatsAchatsScoopService {
  static Future<void> regenerateAdvancedStats(String site) async {
    final firestore = FirebaseFirestore.instance;

    final achatsSnap = await firestore
        .collection('Sites')
        .doc(site)
        .collection('nos_achats_scoop')
        .get();

    // Agrégations par SCOOP
    final Map<String, Map<String, dynamic>> scoopAgg = {};

    for (final d in achatsSnap.docs) {
      final data = d.data();
      final scoopId = data['scoop_id']?.toString() ?? '';
      final scoopNom = data['scoop_nom']?.toString() ?? 'SCOOP';
      final contenants = (data['contenants'] as List<dynamic>? ?? const []);

      final s = scoopAgg.putIfAbsent(
          scoopId.isEmpty ? scoopNom : scoopId,
          () => {
                'id': scoopId,
                'nom': scoopNom,
                'nombreAchats': 0,
                'poidsTotal': 0.0,
                'montantTotal': 0.0,
                'contenants': <String, int>{'Bidon': 0, 'Pot': 0},
                'miels': <String, double>{'Liquide': 0, 'Brute': 0, 'Cire': 0},
              });
      s['nombreAchats'] = (s['nombreAchats'] as int) + 1;

      for (final raw in contenants) {
        final m = raw as Map<String, dynamic>;
        final typeCont = (m['type_contenant']?.toString() ?? '').trim();
        final typeMiel = (m['type_miel']?.toString() ?? '').trim();
        final qte = (m['quantite'] ?? 0).toDouble();
        final pu = (m['prix_unitaire'] ?? 0).toDouble();
        final mt = (m['montant_total'] ?? (qte * pu)).toDouble();

        s['poidsTotal'] = (s['poidsTotal'] as double) + qte;
        s['montantTotal'] = (s['montantTotal'] as double) + mt;

        final cont = s['contenants'] as Map<String, int>;
        cont[typeCont] = (cont[typeCont] ?? 0) + 1;

        final miels = s['miels'] as Map<String, double>;
        miels[typeMiel] = (miels[typeMiel] ?? 0) + qte;
      }
    }

    final stats = {
      'scoops': scoopAgg.values
          .map((s) => {
                'id': s['id'],
                'nom': s['nom'],
                'achats': s['nombreAchats'],
                'poidsTotal': s['poidsTotal'],
                'montantTotal': s['montantTotal'],
                'contenants': (s['contenants'] as Map<String, int>)
                    .entries
                    .map((e) => {'type': e.key, 'nombre': e.value})
                    .toList(),
                'quantitesMiel': (s['miels'] as Map<String, double>)
                    .entries
                    .map((e) => {'type': e.key, 'quantite': e.value})
                    .toList(),
              })
          .toList(),
      'updated_at': Timestamp.now(),
    };

    await firestore
        .collection('Sites')
        .doc(site)
        .collection('nos_achats_scoop')
        .doc('statistiques_avancees')
        .set(stats, SetOptions(merge: true));
  }
}
