import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/attribution_models_v2.dart';

/// Service Firestore pour la gestion des attributions
/// Structure: Collection [TypeReceveur] > Sous-collection [SiteDuReceveur]
class FirestoreAttributionService {
  static final FirestoreAttributionService _instance =
      FirestoreAttributionService._internal();
  factory FirestoreAttributionService() => _instance;
  FirestoreAttributionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Convertit le type d'attribution en nom de collection
  String getCollectionName(AttributionType type) {
    switch (type) {
      case AttributionType.extraction:
        return 'Extraction';
      case AttributionType.filtration:
        return 'Filtrage';
      case AttributionType.traitementCire:
        return 'Cire';
    }
  }

  /// Crée une attribution depuis le contrôle qualité
  Future<String> creerAttributionDepuisControle({
    required AttributionType type,
    required ProductNature natureProduitsAttribues,
    required String utilisateur,
    required List<String> listeContenants,
    required String sourceCollecteId,
    required String sourceType,
    required String siteOrigine,
    required String siteReceveur,
    required DateTime dateCollecte,
    String? commentaires,
    Map<String, dynamic>? metadata,
  }) async {
    return await sauvegarderAttribution(
      type: type,
      siteReceveur: siteReceveur,
      sourceCollecteId: sourceCollecteId,
      sourceType: sourceType,
      siteOrigine: siteOrigine,
      dateCollecte: dateCollecte,
      listeContenants: listeContenants,
      natureProduitsAttribues: natureProduitsAttribues,
      utilisateur: utilisateur,
      commentaires: commentaires,
      metadata: metadata,
    );
  }

  /// Sauvegarde une attribution dans Firestore
  /// Structure: Collection [TypeReceveur] > Sous-collection [SiteReceveur] > Document [AttributionId]
  Future<String> sauvegarderAttribution({
    required AttributionType type,
    required String siteReceveur,
    required String sourceCollecteId,
    required String sourceType,
    required String siteOrigine,
    required DateTime dateCollecte,
    required List<String> listeContenants,
    required ProductNature natureProduitsAttribues,
    required String utilisateur,
    String? commentaires,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final collectionName = getCollectionName(type);
      final attributionId = 'attr_${DateTime.now().millisecondsSinceEpoch}';

      // Données de l'attribution
      final attributionData = {
        'id': attributionId,
        'type': type.value,
        'typeLabel': type.label,
        'dateAttribution': FieldValue.serverTimestamp(),
        'utilisateur': utilisateur,
        'listeContenants': listeContenants,
        'statut': 'attribue', // Statut initial
        'commentaires': commentaires,
        'metadata': metadata ?? {},

        // Informations sur la source
        'source': {
          'collecteId': sourceCollecteId,
          'type': sourceType,
          'site': siteOrigine,
          'dateCollecte': Timestamp.fromDate(dateCollecte),
        },

        // Classification des produits
        'natureProduitsAttribues': natureProduitsAttribues.name,

        // Site de destination
        'siteDestination': siteReceveur,

        // Métadonnées de création
        'dateCreation': FieldValue.serverTimestamp(),
        'derniereMiseAJour': FieldValue.serverTimestamp(),

        // Statistiques
        'statistiques': {
          'nombreContenants': listeContenants.length,
          'poidsTotalEstime': 0.0, // À calculer si disponible
          'montantTotalEstime': 0.0, // À calculer si disponible
        },
      };

      // Sauvegarder dans la structure: Collection [TypeReceveur] > Sous-collection [SiteReceveur]
      await _firestore
          .collection(collectionName)
          .doc(siteReceveur)
          .collection('attributions')
          .doc(attributionId)
          .set(attributionData);

      // Mettre à jour le document du site avec les statistiques
      await _mettreAJourStatistiquesSite(
          collectionName, siteReceveur, listeContenants.length);

      if (kDebugMode) {
        print(
            '✅ Attribution sauvegardée: $collectionName/$siteReceveur/attributions/$attributionId');
      }

      return attributionId;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur sauvegarde attribution: $e');
      }
      rethrow;
    }
  }

  /// Met à jour les statistiques du site dans le document principal
  Future<void> _mettreAJourStatistiquesSite(
      String collectionName, String siteReceveur, int nombreContenants) async {
    try {
      final siteRef = _firestore.collection(collectionName).doc(siteReceveur);

      await _firestore.runTransaction((transaction) async {
        final siteDoc = await transaction.get(siteRef);

        if (siteDoc.exists) {
          // Mettre à jour les statistiques existantes
          final data = siteDoc.data()!;
          final stats = Map<String, dynamic>.from(data['statistiques'] ?? {});

          stats['totalAttributions'] = (stats['totalAttributions'] ?? 0) + 1;
          stats['totalContenants'] =
              (stats['totalContenants'] ?? 0) + nombreContenants;
          stats['derniereAttribution'] = FieldValue.serverTimestamp();

          transaction.update(siteRef, {
            'statistiques': stats,
            'derniereMiseAJour': FieldValue.serverTimestamp(),
          });
        } else {
          // Créer le document du site s'il n'existe pas
          transaction.set(siteRef, {
            'nomSite': siteReceveur,
            'typeReceveur': collectionName,
            'statistiques': {
              'totalAttributions': 1,
              'totalContenants': nombreContenants,
              'premiereAttribution': FieldValue.serverTimestamp(),
              'derniereAttribution': FieldValue.serverTimestamp(),
            },
            'dateCreation': FieldValue.serverTimestamp(),
            'derniereMiseAJour': FieldValue.serverTimestamp(),
            'actif': true,
          });
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erreur mise à jour statistiques site: $e');
      }
      // Ne pas faire échouer l'attribution pour une erreur de statistiques
    }
  }

  /// Récupère les attributions d'un site pour un type donné
  Stream<List<Map<String, dynamic>>> getAttributionsPourSite({
    required AttributionType type,
    required String siteReceveur,
    int? limite,
  }) {
    final collectionName = getCollectionName(type);

    Query query = _firestore
        .collection(collectionName)
        .doc(siteReceveur)
        .collection('attributions')
        .orderBy('dateAttribution', descending: true);

    if (limite != null) {
      query = query.limit(limite);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Récupère toutes les attributions d'un type donné
  Stream<List<Map<String, dynamic>>> getAttributionsPourType({
    required AttributionType type,
    int? limite,
  }) {
    final collectionName = getCollectionName(type);

    return _firestore
        .collection(collectionName)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<Map<String, dynamic>> attributions = [];

      for (final siteDoc in snapshot.docs) {
        final siteId = siteDoc.id;

        Query query = siteDoc.reference
            .collection('attributions')
            .orderBy('dateAttribution', descending: true);

        if (limite != null) {
          query = query.limit(limite);
        }

        final attributionsSnapshot = await query.get();

        for (final attrDoc in attributionsSnapshot.docs) {
          final data = attrDoc.data() as Map<String, dynamic>;
          data['id'] = attrDoc.id;
          data['siteReceveur'] = siteId;
          attributions.add(data);
        }
      }

      // Trier par date décroissante
      attributions.sort((a, b) {
        final dateA =
            (a['dateAttribution'] as Timestamp?)?.toDate() ?? DateTime(1970);
        final dateB =
            (b['dateAttribution'] as Timestamp?)?.toDate() ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });

      return limite != null ? attributions.take(limite).toList() : attributions;
    });
  }

  /// Récupère les statistiques d'un site pour un type donné
  Future<Map<String, dynamic>?> getStatistiquesSite({
    required AttributionType type,
    required String siteReceveur,
  }) async {
    try {
      final collectionName = getCollectionName(type);
      final doc =
          await _firestore.collection(collectionName).doc(siteReceveur).get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération statistiques: $e');
      }
      return null;
    }
  }

  /// Récupère tous les sites pour un type donné
  Stream<List<Map<String, dynamic>>> getSitesPourType(AttributionType type) {
    final collectionName = getCollectionName(type);

    return _firestore.collection(collectionName).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Met à jour le statut d'une attribution
  Future<void> mettreAJourStatut({
    required AttributionType type,
    required String siteReceveur,
    required String attributionId,
    required String nouveauStatut,
    required String utilisateur,
    String? commentaire,
  }) async {
    try {
      final collectionName = getCollectionName(type);

      await _firestore
          .collection(collectionName)
          .doc(siteReceveur)
          .collection('attributions')
          .doc(attributionId)
          .update({
        'statut': nouveauStatut,
        'dateModification': FieldValue.serverTimestamp(),
        'utilisateurModification': utilisateur,
        'derniereMiseAJour': FieldValue.serverTimestamp(),
        if (commentaire != null) 'commentaireModification': commentaire,
      });

      if (kDebugMode) {
        print('✅ Statut mis à jour: $attributionId -> $nouveauStatut');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur mise à jour statut: $e');
      }
      rethrow;
    }
  }

  /// Supprime une attribution (soft delete)
  Future<void> supprimerAttribution({
    required AttributionType type,
    required String siteReceveur,
    required String attributionId,
    required String utilisateur,
  }) async {
    try {
      final collectionName = getCollectionName(type);

      await _firestore
          .collection(collectionName)
          .doc(siteReceveur)
          .collection('attributions')
          .doc(attributionId)
          .update({
        'supprime': true,
        'dateSuppression': FieldValue.serverTimestamp(),
        'utilisateurSuppression': utilisateur,
        'derniereMiseAJour': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ Attribution supprimée: $attributionId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur suppression attribution: $e');
      }
      rethrow;
    }
  }
}
