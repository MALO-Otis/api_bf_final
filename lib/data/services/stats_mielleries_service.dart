import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/miellerie_models.dart';

class StatsMielleriesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sauvegarde une collecte Miellerie et met à jour les statistiques
  static Future<void> saveCollecteMiellerie(
      CollecteMiellerieModel collecte) async {
    try {
      // 1. Sauvegarder la collecte
      final docRef = await _firestore
          .collection('Sites')
          .doc(collecte.site)
          .collection('nos_collecte_mielleries')
          .add(collecte.toFirestore());

      print('✅ Collecte Miellerie sauvegardée avec ID: ${docRef.id}');

      // 2. Mettre à jour les statistiques du site
      await _updateSiteInfos(collecte);

      // 3. Régénérer les statistiques avancées
      await regenerateAdvancedStats(collecte.site);

      print('✅ Statistiques Mielleries mises à jour pour ${collecte.site}');
    } catch (e) {
      print('❌ Erreur sauvegarde collecte Miellerie: $e');
      rethrow;
    }
  }

  /// Met à jour les informations du site
  static Future<void> _updateSiteInfos(CollecteMiellerieModel collecte) async {
    try {
      final siteDocRef = _firestore
          .collection('Sites')
          .doc(collecte.site)
          .collection('site_infos')
          .doc('infos');

      final monthKey =
          '${collecte.dateCollecte.year}-${collecte.dateCollecte.month.toString().padLeft(2, '0')}';

      await siteDocRef.set({
        'total_collectes_mielleries': FieldValue.increment(1),
        'total_poids_collecte_miellerie':
            FieldValue.increment(collecte.poidsTotal),
        'total_montant_collecte_miellerie':
            FieldValue.increment(collecte.montantTotal),
        'collectes_mielleries_par_mois.$monthKey': FieldValue.increment(1),
        'poids_mielleries_par_mois.$monthKey':
            FieldValue.increment(collecte.poidsTotal),
        'montant_mielleries_par_mois.$monthKey':
            FieldValue.increment(collecte.montantTotal),
        'derniere_activite_miellerie': FieldValue.serverTimestamp(),
        'mielleries_actives': FieldValue.arrayUnion([collecte.miellerieNom]),
        'cooperatives_mielleries':
            FieldValue.arrayUnion([collecte.cooperativeNom]),
      }, SetOptions(merge: true));
    } catch (e) {
      print('❌ Erreur mise à jour site_infos Mielleries: $e');
      rethrow;
    }
  }

  /// Régénère les statistiques avancées pour les Mielleries
  static Future<void> regenerateAdvancedStats(String site) async {
    try {
      final collectesSnap = await _firestore
          .collection('Sites')
          .doc(site)
          .collection('nos_collecte_mielleries')
          .get();

      // Agrégations par Miellerie
      final Map<String, Map<String, dynamic>> miellerieAgg = {};
      final Map<String, Map<String, dynamic>> cooperativeAgg = {};

      for (final doc in collectesSnap.docs) {
        final collecte = CollecteMiellerieModel.fromFirestore(doc);

        // Agrégation par Miellerie
        final miellerieKey = collecte.miellerieId.isEmpty
            ? collecte.miellerieNom
            : collecte.miellerieId;
        final miellerieStats = miellerieAgg.putIfAbsent(
            miellerieKey,
            () => {
                  'id': collecte.miellerieId,
                  'nom': collecte.miellerieNom,
                  'localite': collecte.localite,
                  'cooperative_nom': collecte.cooperativeNom,
                  'repondant': collecte.repondant,
                  'nombre_collectes': 0,
                  'poids_total': 0.0,
                  'montant_total': 0.0,
                  'contenants': <String, int>{},
                  'types_collecte': <String, double>{},
                });

        miellerieStats['nombre_collectes'] =
            (miellerieStats['nombre_collectes'] as int) + 1;
        miellerieStats['poids_total'] =
            (miellerieStats['poids_total'] as double) + collecte.poidsTotal;
        miellerieStats['montant_total'] =
            (miellerieStats['montant_total'] as double) + collecte.montantTotal;

        // Agrégation des contenants et types
        final contenants = miellerieStats['contenants'] as Map<String, int>;
        final typesCollecte =
            miellerieStats['types_collecte'] as Map<String, double>;

        for (final contenant in collecte.contenants) {
          contenants[contenant.typeContenant] =
              (contenants[contenant.typeContenant] ?? 0) + 1;
          typesCollecte[contenant.typeCollecte] =
              (typesCollecte[contenant.typeCollecte] ?? 0.0) +
                  contenant.quantite;
        }

        // Agrégation par Coopérative
        final coopKey = collecte.cooperativeId.isEmpty
            ? collecte.cooperativeNom
            : collecte.cooperativeId;
        final coopStats = cooperativeAgg.putIfAbsent(
            coopKey,
            () => {
                  'id': collecte.cooperativeId,
                  'nom': collecte.cooperativeNom,
                  'nombre_mielleries': <String>{},
                  'nombre_collectes': 0,
                  'poids_total': 0.0,
                  'montant_total': 0.0,
                });

        (coopStats['nombre_mielleries'] as Set<String>).add(miellerieKey);
        coopStats['nombre_collectes'] =
            (coopStats['nombre_collectes'] as int) + 1;
        coopStats['poids_total'] =
            (coopStats['poids_total'] as double) + collecte.poidsTotal;
        coopStats['montant_total'] =
            (coopStats['montant_total'] as double) + collecte.montantTotal;
      }

      // Convertir les Sets en nombres pour les coopératives
      for (final coopStats in cooperativeAgg.values) {
        final mielleriesSet = coopStats['nombre_mielleries'] as Set<String>;
        coopStats['nombre_mielleries'] = mielleriesSet.length;
      }

      // Sauvegarder les statistiques
      final statsData = {
        'mielleries': miellerieAgg.values.toList(),
        'cooperatives': cooperativeAgg.values.toList(),
        'resume_global': {
          'total_mielleries': miellerieAgg.length,
          'total_cooperatives': cooperativeAgg.length,
          'total_collectes': collectesSnap.docs.length,
          'poids_total_global': miellerieAgg.values
              .fold<double>(0, (sum, m) => sum + (m['poids_total'] as double)),
          'montant_total_global': miellerieAgg.values.fold<double>(
              0, (sum, m) => sum + (m['montant_total'] as double)),
        },
        'derniere_mise_a_jour': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('Sites')
          .doc(site)
          .collection('nos_collecte_mielleries')
          .doc('statistiques_avancees')
          .set(statsData);

      print('✅ Statistiques avancées Mielleries régénérées pour $site');
    } catch (e) {
      print('❌ Erreur régénération stats Mielleries: $e');
      rethrow;
    }
  }

  /// Charge les Mielleries existantes pour un site
  static Future<List<MiellerieModel>> loadMielleriesForSite(String site) async {
    try {
      final snapshot = await _firestore
          .collection('Sites')
          .doc(site)
          .collection('listes_mielleries')
          .orderBy('nom')
          .get();

      return snapshot.docs
          .map((doc) => MiellerieModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur chargement Mielleries: $e');
      return [];
    }
  }

  /// Crée une nouvelle Miellerie
  static Future<String> createMiellerie(
      MiellerieModel miellerie, String site) async {
    try {
      final miellerieId =
          'miellerie_${miellerie.nom.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

      await _firestore
          .collection('Sites')
          .doc(site)
          .collection('listes_mielleries')
          .doc(miellerieId)
          .set(miellerie.toFirestore());

      print('✅ Miellerie créée avec ID: $miellerieId');
      return miellerieId;
    } catch (e) {
      print('❌ Erreur création Miellerie: $e');
      rethrow;
    }
  }

  /// Charge les SCOOPs disponibles (coopératives) pour sélection
  static Future<List<Map<String, dynamic>>> loadCooperativesForSite(
      String site) async {
    try {
      final snapshot = await _firestore
          .collection('Sites')
          .doc(site)
          .collection('listes_scoop')
          .orderBy('nom')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'nom': data['nom'] ?? '',
          'president': data['president'] ?? '',
          'telephone': data['telephone'] ?? '',
          'region': data['region'] ?? '',
          'province': data['province'] ?? '',
          'commune': data['commune'] ?? '',
          'village': data['village'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('❌ Erreur chargement coopératives: $e');
      return [];
    }
  }
}
