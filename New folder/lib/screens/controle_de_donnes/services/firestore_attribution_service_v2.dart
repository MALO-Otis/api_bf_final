import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/attribution_models_v2.dart';

/// 🎯 SERVICE FIRESTORE POUR ATTRIBUTIONS - NOUVELLE STRUCTURE
///
/// Structure Firestore:
/// Attributions_recu/
/// ├── {siteReceveur}/           # Koudougou, Bobo, Ouaga, etc.
/// │   ├── Extraction/           # Sous-collection pour extraction
/// │   │   └── {attributionId}   # Documents d'attribution
/// │   ├── Cire/                 # Sous-collection pour traitement cire
/// │   │   └── {attributionId}   # Documents d'attribution
/// │   └── Filtrage/             # Sous-collection pour filtrage
/// │       └── {attributionId}   # Documents d'attribution
class FirestoreAttributionServiceV2 {
  static final FirestoreAttributionServiceV2 _instance =
      FirestoreAttributionServiceV2._internal();
  factory FirestoreAttributionServiceV2() => _instance;
  FirestoreAttributionServiceV2._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection principale
  static const String _mainCollection = 'Attributions_recu';

  /// Convertit le type d'attribution en nom de sous-collection
  String _getTypeCollectionName(AttributionType type) {
    switch (type) {
      case AttributionType.extraction:
        return 'Extraction';
      case AttributionType.filtration:
        return 'Filtrage';
      case AttributionType.traitementCire:
        return 'Cire';
    }
  }

  /// 📝 SAUVEGARDE UNE ATTRIBUTION COMPLÈTE
  ///
  /// Structure: Attributions_recu/{siteReceveur}/{typeAttribution}/{attributionId}
  Future<String> sauvegarderAttribution({
    required AttributionType type,
    required String siteReceveur,
    required List<ProductControle> produits,
    required String utilisateur,
    String? commentaires,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (kDebugMode) {
        print(
            '🔄 Début sauvegarde attribution vers $siteReceveur (${type.label})');
        print('📦 ${produits.length} produits à attribuer');
      }

      final attributionId = 'attr_${DateTime.now().millisecondsSinceEpoch}';
      final typeCollectionName = _getTypeCollectionName(type);

      // Préparer les données des contenants avec détails complets
      final contenantsDetails = produits
          .map((produit) => {
                'codeContenant': produit.codeContenant,
                'producteur': produit.producteur,
                'village': produit.village,
                'commune': produit.commune,
                'quartier': produit.quartier,
                'siteOrigine': produit.siteOrigine,
                'collecteId': produit.collecteId,
                'typeCollecte': produit.typeCollecte,
                'dateCollecte': Timestamp.fromDate(produit.dateCollecte),
                'dateReception': Timestamp.fromDate(produit.dateReception),
                'typeContenant': produit.typeContenant,
                'numeroContenant': produit.numeroContenant,
                'poidsTotal': produit.poidsTotal,
                'poidsMiel': produit.poidsMiel,
                'qualite': produit.qualite,
                'teneurEau': produit.teneurEau,
                'predominanceFlorale': produit.predominanceFlorale,
                'nature': produit.nature.name,
                'estConforme': produit.estConforme,
                'causeNonConformite': produit.causeNonConformite,
                'observations': produit.observations,
                'dateControle': Timestamp.fromDate(produit.dateControle),
                'controleur': produit.controleur,
                'metadata': produit.metadata ?? {},
              })
          .toList();

      // Calculer les statistiques
      final poidsTotal = produits.fold(0.0, (sum, p) => sum + p.poidsTotal);
      final poidsMielTotal = produits.fold(0.0, (sum, p) => sum + p.poidsMiel);

      // Données complètes de l'attribution
      final attributionData = {
        'id': attributionId,
        'type': type.value,
        'typeLabel': type.label,
        'siteReceveur': siteReceveur,
        'utilisateur': utilisateur,
        'dateAttribution': FieldValue.serverTimestamp(),
        'statut': 'attribue',
        'commentaires': commentaires,
        'metadata': metadata ?? {},

        // Détails complets des contenants
        'contenants': contenantsDetails,
        'listeCodesContenants': produits.map((p) => p.codeContenant).toList(),

        // Statistiques calculées
        'statistiques': {
          'nombreContenants': produits.length,
          'poidsTotal': poidsTotal,
          'poidsMielTotal': poidsMielTotal,
          'nombreSitesOrigine':
              produits.map((p) => p.siteOrigine).toSet().length,
          'nombreCollectes': produits.map((p) => p.collecteId).toSet().length,
          'repartitionQualite': _calculerRepartitionQualite(produits),
          'repartitionNature': _calculerRepartitionNature(produits),
        },

        // Informations de traçabilité
        'tracabilite': {
          'dateCreation': FieldValue.serverTimestamp(),
          'derniereMiseAJour': FieldValue.serverTimestamp(),
          'versionStructure': '2.0',
        },
      };

      // Sauvegarder dans la nouvelle structure
      final docRef = _firestore
          .collection(_mainCollection)
          .doc(siteReceveur)
          .collection(typeCollectionName)
          .doc(attributionId);

      await docRef.set(attributionData);

      if (kDebugMode) {
        print(
            '✅ Attribution sauvegardée: $_mainCollection/$siteReceveur/$typeCollectionName/$attributionId');
      }

      // Marquer les contenants comme attribués dans leurs collectes d'origine
      await _marquerContenantsCommeAttribues(produits, attributionId, type);

      // Mettre à jour les statistiques du site
      await _mettreAJourStatistiquesSite(
          siteReceveur, type, produits.length, poidsTotal);

      return attributionId;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur sauvegarde attribution: $e');
      }
      rethrow;
    }
  }

  /// 🏷️ MARQUE LES CONTENANTS COMME ATTRIBUÉS DANS LEURS COLLECTES D'ORIGINE
  ///
  /// Met à jour chaque contenant dans sa collecte d'origine pour indiquer l'attribution
  Future<void> _marquerContenantsCommeAttribues(
    List<ProductControle> produits,
    String attributionId,
    AttributionType type,
  ) async {
    try {
      if (kDebugMode) {
        print('🏷️ Marquage des contenants comme attribués...');
      }

      // Grouper les produits par collecte pour optimiser les requêtes
      final produitsParCollecte = <String, List<ProductControle>>{};
      for (final produit in produits) {
        final collecteId = produit.collecteId;
        if (!produitsParCollecte.containsKey(collecteId)) {
          produitsParCollecte[collecteId] = [];
        }
        produitsParCollecte[collecteId]!.add(produit);
      }

      // Traiter chaque collecte
      for (final entry in produitsParCollecte.entries) {
        final collecteId = entry.key;
        final produitsCollecte = entry.value;

        await _marquerContenantsCollecte(
            collecteId, produitsCollecte, attributionId, type);
      }

      if (kDebugMode) {
        print('✅ ${produits.length} contenants marqués comme attribués');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur marquage contenants: $e');
      }
      // Ne pas faire échouer l'attribution pour cette erreur
    }
  }

  /// 📋 MARQUE LES CONTENANTS D'UNE COLLECTE SPÉCIFIQUE
  Future<void> _marquerContenantsCollecte(
    String collecteId,
    List<ProductControle> produits,
    String attributionId,
    AttributionType type,
  ) async {
    try {
      final premierproduit = produits.first;
      final siteOrigine = premierproduit.siteOrigine;
      final typeCollecte = premierproduit.typeCollecte;

      // Déterminer le chemin de la collecte selon le type
      DocumentReference? collecteRef;

      switch (typeCollecte.toLowerCase()) {
        case 'recoltes':
        case 'recolte':
          collecteRef = _firestore
              .collection('Sites')
              .doc(siteOrigine)
              .collection('nos_collectes_recoltes')
              .doc(collecteId);
          break;
        case 'scoop':
          collecteRef = _firestore
              .collection('Sites')
              .doc(siteOrigine)
              .collection('nos_achats_scoop_contenants')
              .doc(collecteId);
          break;
        case 'individuel':
          collecteRef = _firestore
              .collection('Sites')
              .doc(siteOrigine)
              .collection('nos_achats_individuels')
              .doc(collecteId);
          break;
        case 'miellerie':
          collecteRef = _firestore
              .collection('Sites')
              .doc(siteOrigine)
              .collection('nos_achats_miellerie')
              .doc(collecteId);
          break;
        default:
          if (kDebugMode) {
            print('⚠️ Type de collecte non reconnu: $typeCollecte');
          }
          return;
      }

      if (collecteRef == null) return;

      // Récupérer le document de la collecte
      final collecteDoc = await collecteRef.get();
      if (!collecteDoc.exists) {
        if (kDebugMode) {
          print('⚠️ Collecte non trouvée: $collecteId');
        }
        return;
      }

      final collecteData = collecteDoc.data() as Map<String, dynamic>;
      final contenants =
          List<Map<String, dynamic>>.from(collecteData['contenants'] ?? []);

      // Marquer les contenants correspondants
      bool hasChanges = false;
      for (final produit in produits) {
        for (int i = 0; i < contenants.length; i++) {
          final contenant = contenants[i];

          // Identifier le contenant par code ou index
          if (_contenantCorrespond(contenant, produit, i)) {
            // Ajouter les informations d'attribution
            contenant['attribution'] = {
              'estAttribue': true,
              'attributionId': attributionId,
              'typeAttribution': type.value,
              'typeAttributionLabel': type.label,
              'dateAttribution': FieldValue.serverTimestamp(),
              'siteReceveur': produits.first.siteOrigine, // Site receveur
            };
            hasChanges = true;

            if (kDebugMode) {
              print(
                  '📝 Contenant ${produit.codeContenant} marqué comme attribué');
            }
            break;
          }
        }
      }

      // Sauvegarder les modifications si nécessaire
      if (hasChanges) {
        await collecteRef.update({'contenants': contenants});
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur marquage collecte $collecteId: $e');
      }
    }
  }

  /// 🔍 VÉRIFIE SI UN CONTENANT CORRESPOND À UN PRODUIT
  bool _contenantCorrespond(
      Map<String, dynamic> contenant, ProductControle produit, int index) {
    // Méthode 1: Par code contenant (si disponible)
    final codeContenant =
        contenant['codeContenant'] ?? contenant['code'] ?? contenant['id'];
    if (codeContenant != null &&
        codeContenant.toString() == produit.codeContenant) {
      return true;
    }

    // Méthode 2: Par propriétés combinées (poids, type, etc.)
    final poids =
        contenant['weight'] ?? contenant['poids'] ?? contenant['poidsTotal'];
    final typeContenant = contenant['containerType'] ??
        contenant['typeContenant'] ??
        contenant['type'];

    if (poids != null && typeContenant != null) {
      final poidsMatch = (poids as num).toDouble() == produit.poidsTotal;
      final typeMatch = typeContenant.toString() == produit.typeContenant;

      if (poidsMatch && typeMatch) {
        return true;
      }
    }

    // Méthode 3: Par index si pas d'autre correspondance (fallback)
    // Cette méthode est moins fiable mais peut être utilisée en dernier recours
    return false;
  }

  /// 📊 CALCULE LA RÉPARTITION PAR QUALITÉ
  Map<String, int> _calculerRepartitionQualite(List<ProductControle> produits) {
    final repartition = <String, int>{};
    for (final produit in produits) {
      final qualite = produit.qualite;
      repartition[qualite] = (repartition[qualite] ?? 0) + 1;
    }
    return repartition;
  }

  /// 🏷️ CALCULE LA RÉPARTITION PAR NATURE
  Map<String, int> _calculerRepartitionNature(List<ProductControle> produits) {
    final repartition = <String, int>{};
    for (final produit in produits) {
      final nature = produit.nature.name;
      repartition[nature] = (repartition[nature] ?? 0) + 1;
    }
    return repartition;
  }

  /// 📈 MET À JOUR LES STATISTIQUES DU SITE
  Future<void> _mettreAJourStatistiquesSite(
    String siteReceveur,
    AttributionType type,
    int nombreContenants,
    double poidsTotal,
  ) async {
    try {
      final siteRef = _firestore.collection(_mainCollection).doc(siteReceveur);
      final typeCollectionName = _getTypeCollectionName(type);

      await _firestore.runTransaction((transaction) async {
        final siteDoc = await transaction.get(siteRef);

        Map<String, dynamic> siteData;
        if (siteDoc.exists) {
          siteData = Map<String, dynamic>.from(siteDoc.data()!);
        } else {
          siteData = {
            'nomSite': siteReceveur,
            'dateCreation': FieldValue.serverTimestamp(),
            'statistiques': {},
          };
        }

        // Mettre à jour les statistiques globales
        final stats = Map<String, dynamic>.from(siteData['statistiques'] ?? {});
        stats['totalAttributions'] = (stats['totalAttributions'] ?? 0) + 1;
        stats['totalContenants'] =
            (stats['totalContenants'] ?? 0) + nombreContenants;
        stats['poidsTotal'] = (stats['poidsTotal'] ?? 0.0) + poidsTotal;
        stats['derniereAttribution'] = FieldValue.serverTimestamp();

        // Statistiques par type
        if (!stats.containsKey('parType')) {
          stats['parType'] = {};
        }
        final statsParType = Map<String, dynamic>.from(stats['parType']);
        if (!statsParType.containsKey(typeCollectionName)) {
          statsParType[typeCollectionName] = {
            'nombreAttributions': 0,
            'nombreContenants': 0,
            'poidsTotal': 0.0,
          };
        }
        final statsType =
            Map<String, dynamic>.from(statsParType[typeCollectionName]);
        statsType['nombreAttributions'] =
            (statsType['nombreAttributions'] ?? 0) + 1;
        statsType['nombreContenants'] =
            (statsType['nombreContenants'] ?? 0) + nombreContenants;
        statsType['poidsTotal'] = (statsType['poidsTotal'] ?? 0.0) + poidsTotal;
        statsType['derniereAttribution'] = FieldValue.serverTimestamp();

        statsParType[typeCollectionName] = statsType;
        stats['parType'] = statsParType;
        siteData['statistiques'] = stats;
        siteData['derniereMiseAJour'] = FieldValue.serverTimestamp();

        transaction.set(siteRef, siteData);
      });
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erreur mise à jour statistiques site: $e');
      }
    }
  }

  /// 📋 RÉCUPÈRE LES ATTRIBUTIONS D'UN SITE POUR UN TYPE DONNÉ
  Stream<List<Map<String, dynamic>>> getAttributionsPourSite({
    required String siteReceveur,
    required AttributionType type,
    int? limite,
  }) {
    final typeCollectionName = _getTypeCollectionName(type);

    Query query = _firestore
        .collection(_mainCollection)
        .doc(siteReceveur)
        .collection(typeCollectionName)
        .orderBy('dateAttribution', descending: true);

    if (limite != null) {
      query = query.limit(limite);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data =
            Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// 📊 RÉCUPÈRE LES STATISTIQUES D'UN SITE
  Future<Map<String, dynamic>?> getStatistiquesSite(String siteReceveur) async {
    try {
      final siteDoc =
          await _firestore.collection(_mainCollection).doc(siteReceveur).get();

      if (siteDoc.exists) {
        return Map<String, dynamic>.from(siteDoc.data()!);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération statistiques: $e');
      }
      return null;
    }
  }

  /// 🔍 RÉCUPÈRE UNE ATTRIBUTION SPÉCIFIQUE
  Future<Map<String, dynamic>?> getAttribution({
    required String siteReceveur,
    required AttributionType type,
    required String attributionId,
  }) async {
    try {
      final typeCollectionName = _getTypeCollectionName(type);

      final doc = await _firestore
          .collection(_mainCollection)
          .doc(siteReceveur)
          .collection(typeCollectionName)
          .doc(attributionId)
          .get();

      if (doc.exists) {
        final data = Map<String, dynamic>.from(doc.data()!);
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération attribution: $e');
      }
      return null;
    }
  }
}
