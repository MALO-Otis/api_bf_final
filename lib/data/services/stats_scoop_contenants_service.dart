import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/scoop_models.dart';

/// Service pour gérer les statistiques des achats SCOOP avec contenants
class StatsScoopContenantsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Régénère les statistiques avancées pour un site donné
  static Future<void> regenerateAdvancedStats(String site) async {
    try {
      // Charger toutes les collectes SCOOP contenants
      final collectesSnapshot = await _firestore
          .collection('Sites')
          .doc(site)
          .collection('nos_achats_scoop_contenants')
          .get();

      // Charger tous les SCOOPs
      final scoopsSnapshot = await _firestore.collection('SCOOPs').get();

      final Map<String, Map<String, dynamic>> statsByScoops = {};
      double totalPoids = 0;
      double totalMontant = 0;
      int totalCollectes = 0;
      int totalContenants = 0;
      int totalBidons = 0;
      int totalPots = 0;
      final Set<String> allMielTypes = {};

      // Traiter chaque collecte
      for (final doc in collectesSnapshot.docs) {
        final collecte = CollecteScoopModel.fromFirestore(doc);
        totalCollectes++;
        totalPoids += collecte.poidsTotal;
        totalMontant += collecte.montantTotal;
        totalContenants += collecte.contenants.length;
        totalBidons += collecte.nombreBidons;
        totalPots += collecte.nombrePots;
        allMielTypes.addAll(collecte.mielTypes);

        // Stats par SCOOP
        if (!statsByScoops.containsKey(collecte.scoopId)) {
          statsByScoops[collecte.scoopId] = {
            'nom': collecte.scoopNom,
            'totalCollectes': 0,
            'totalPoids': 0.0,
            'totalMontant': 0.0,
            'totalContenants': 0,
            'totalBidons': 0,
            'totalPots': 0,
            'contenants': <String, Map<String, dynamic>>{},
            'mielTypes': <String>{},
            'collectes': <Map<String, dynamic>>[],
          };
        }

        final scoopStats = statsByScoops[collecte.scoopId]!;
        scoopStats['totalCollectes'] =
            (scoopStats['totalCollectes'] as int) + 1;
        scoopStats['totalPoids'] =
            (scoopStats['totalPoids'] as double) + collecte.poidsTotal;
        scoopStats['totalMontant'] =
            (scoopStats['totalMontant'] as double) + collecte.montantTotal;
        scoopStats['totalContenants'] =
            (scoopStats['totalContenants'] as int) + collecte.contenants.length;
        scoopStats['totalBidons'] =
            (scoopStats['totalBidons'] as int) + collecte.nombreBidons;
        scoopStats['totalPots'] =
            (scoopStats['totalPots'] as int) + collecte.nombrePots;
        (scoopStats['mielTypes'] as Set<String>).addAll(collecte.mielTypes);

        // Détails par contenant type
        final contenants =
            scoopStats['contenants'] as Map<String, Map<String, dynamic>>;
        for (final contenant in collecte.contenants) {
          final key =
              '${contenant.typeContenant.label}_${contenant.typeMiel.label}';
          if (!contenants.containsKey(key)) {
            contenants[key] = {
              'typeContenant': contenant.typeContenant.label,
              'typeMiel': contenant.typeMiel.label,
              'nombre': 0,
              'poidsMoyen': 0.0,
              'prixMoyen': 0.0,
              'poidsTotal': 0.0,
              'prixTotal': 0.0,
            };
          }
          final stats = contenants[key]!;
          stats['nombre'] = (stats['nombre'] as int) + 1;
          stats['poidsTotal'] =
              (stats['poidsTotal'] as double) + contenant.poids;
          stats['prixTotal'] = (stats['prixTotal'] as double) + contenant.prix;
          stats['poidsMoyen'] =
              (stats['poidsTotal'] as double) / (stats['nombre'] as int);
          stats['prixMoyen'] =
              (stats['prixTotal'] as double) / (stats['nombre'] as int);
        }

        // Historique des collectes
        (scoopStats['collectes'] as List<Map<String, dynamic>>).add({
          'id': collecte.id,
          'date': collecte.dateAchat.toIso8601String(),
          'periode': collecte.periodeCollecte,
          'poids': collecte.poidsTotal,
          'montant': collecte.montantTotal,
          'nombreContenants': collecte.contenants.length,
          'bidons': collecte.nombreBidons,
          'pots': collecte.nombrePots,
        });
      }

      // Construire la structure finale des statistiques
      final Map<String, dynamic> statistiques = {
        'totauxGlobaux': {
          'totalCollectes': totalCollectes,
          'totalPoids': totalPoids,
          'totalMontant': totalMontant,
          'totalContenants': totalContenants,
          'totalBidons': totalBidons,
          'totalPots': totalPots,
          'mielTypesCumules': allMielTypes.toList(),
        },
        'scoops': statsByScoops.entries.map((entry) {
          final stats = entry.value;
          return {
            'id': entry.key,
            'nom': stats['nom'],
            'totalCollectes': stats['totalCollectes'],
            'totalPoids': stats['totalPoids'],
            'totalMontant': stats['totalMontant'],
            'totalContenants': stats['totalContenants'],
            'contenants':
                (stats['contenants'] as Map<String, Map<String, dynamic>>)
                    .values
                    .map((c) => {
                          'typeContenant': c['typeContenant'],
                          'typeMiel': c['typeMiel'],
                          'nombre': c['nombre'],
                          'poidsMoyen': c['poidsMoyen'],
                          'prixMoyen': c['prixMoyen'],
                        })
                    .toList(),
            'mielTypes': (stats['mielTypes'] as Set<String>).toList(),
            'collectes': stats['collectes'],
          };
        }).toList(),
        'derniereMAJ': Timestamp.now(),
      };

      // Enregistrer les statistiques
      await _firestore
          .collection('Sites')
          .doc(site)
          .collection('nos_achats_scoop_contenants')
          .doc('statistiques_avancees')
          .set(statistiques);

      print('✅ Statistiques SCOOP contenants régénérées pour le site: $site');
    } catch (e) {
      print('❌ Erreur lors de la régénération des stats SCOOP contenants: $e');
      rethrow;
    }
  }

  /// Applique un delta aux statistiques du site_infos
  static Future<void> applySiteInfosDelta({
    required String site,
    required String monthKey,
    required double poidsDelta,
    required double montantDelta,
    required int deltaBidon,
    required int deltaPot,
    List<String> mielTypesToUnion = const [],
  }) async {
    try {
      final siteRef = _firestore
          .collection('Sites')
          .doc(site)
          .collection('site_infos')
          .doc('infos');

      final Map<String, dynamic> updates = {
        'total_collectes_scoop_contenants': FieldValue.increment(1),
        'total_poids_scoop_contenants': FieldValue.increment(poidsDelta),
        'total_montant_scoop_contenants': FieldValue.increment(montantDelta),
        'collectes_par_mois_scoop_contenants.$monthKey':
            FieldValue.increment(1),
        'poids_par_mois_scoop_contenants.$monthKey':
            FieldValue.increment(poidsDelta),
        'montant_par_mois_scoop_contenants.$monthKey':
            FieldValue.increment(montantDelta),
        'contenant_collecter_par_mois_scoop_contenants.$monthKey.total':
            FieldValue.increment((deltaBidon + deltaPot).toDouble()),
        'contenant_collecter_par_mois_scoop_contenants.$monthKey.Bidon':
            FieldValue.increment(deltaBidon.toDouble()),
        'contenant_collecter_par_mois_scoop_contenants.$monthKey.Pot':
            FieldValue.increment(deltaPot.toDouble()),
        'derniere_activite': FieldValue.serverTimestamp(),
      };

      if (mielTypesToUnion.isNotEmpty) {
        updates['miel_types_cumules_scoop_contenants'] =
            FieldValue.arrayUnion(mielTypesToUnion);
      }

      await siteRef.set(updates, SetOptions(merge: true));
      print('✅ Site infos mis à jour pour SCOOP contenants');
    } catch (e) {
      print('❌ Erreur mise à jour site infos SCOOP contenants: $e');
      rethrow;
    }
  }

  /// Charge les SCOOPs disponibles pour un site
  static Future<List<ScoopModel>> loadScoopsForSite(String site) async {
    try {
      final snapshot = await _firestore
          .collection('Sites')
          .doc(site)
          .collection('listes_scoop')
          .orderBy('nom')
          .get();

      return snapshot.docs.map((doc) => ScoopModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Erreur chargement SCOOPs: $e');
      return [];
    }
  }

  /// Enregistre un nouveau SCOOP
  static Future<String> createScoop(ScoopModel scoop, String site) async {
    try {
      final data = scoop.toFirestore();
      // Créer un ID personnalisé basé sur le nom (comme pour les producteurs)
      final scoopId =
          'scoop_${scoop.nom.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

      await _firestore
          .collection('Sites')
          .doc(site)
          .collection('listes_scoop')
          .doc(scoopId)
          .set(data);

      print('✅ SCOOP créé avec ID: $scoopId');
      return scoopId;
    } catch (e) {
      print('❌ Erreur création SCOOP: $e');
      rethrow;
    }
  }

  /// Sauvegarde une collecte SCOOP avec contenants
  static Future<void> saveCollecteScoop(CollecteScoopModel collecte) async {
    try {
      final docRef = _firestore
          .collection('Sites')
          .doc(collecte.site)
          .collection('nos_achats_scoop_contenants')
          .doc();

      final collecteWithId = CollecteScoopModel(
        id: docRef.id,
        dateAchat: collecte.dateAchat,
        periodeCollecte: collecte.periodeCollecte,
        scoopId: collecte.scoopId,
        scoopNom: collecte.scoopNom,
        contenants: collecte.contenants,
        poidsTotal: collecte.poidsTotal,
        montantTotal: collecte.montantTotal,
        observations: collecte.observations,
        collecteurId: collecte.collecteurId,
        collecteurNom: collecte.collecteurNom,
        site: collecte.site,
        createdAt: collecte.createdAt,
        statut: collecte.statut,
      );

      await docRef.set(collecteWithId.toFirestore());

      // Mise à jour des statistiques du site
      final monthKey =
          '${collecte.dateAchat.year.toString().padLeft(4, '0')}-${collecte.dateAchat.month.toString().padLeft(2, '0')}';
      await applySiteInfosDelta(
        site: collecte.site,
        monthKey: monthKey,
        poidsDelta: collecte.poidsTotal,
        montantDelta: collecte.montantTotal,
        deltaBidon: collecte.nombreBidons,
        deltaPot: collecte.nombrePots,
        mielTypesToUnion: collecte.mielTypes.toList(),
      );

      // Régénération des statistiques avancées
      await regenerateAdvancedStats(collecte.site);

      print('✅ Collecte SCOOP contenants sauvegardée avec ID: ${docRef.id}');
    } catch (e) {
      print('❌ Erreur sauvegarde collecte SCOOP contenants: $e');
      rethrow;
    }
  }
}
