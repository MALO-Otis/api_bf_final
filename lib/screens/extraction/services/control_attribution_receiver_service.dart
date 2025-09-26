import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../authentication/user_session.dart';
import '../models/extraction_models.dart';

/// Service pour récupérer les attributions du module contrôle dans le module extraction
/// Filtre automatiquement les données selon le site de l'extracteur
class ControlAttributionReceiverService {
  static final ControlAttributionReceiverService _instance =
      ControlAttributionReceiverService._internal();
  factory ControlAttributionReceiverService() => _instance;
  ControlAttributionReceiverService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Récupère le site de l'utilisateur connecté
  String _getUserSite() {
    try {
      final userSession = Get.find<UserSession>();
      return userSession.site ?? 'Inconnu';
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Impossible de récupérer le site utilisateur: $e');
      }
      return 'Inconnu';
    }
  }

  /// Récupère les attributions d'extraction pour le site de l'utilisateur
  Stream<List<ExtractionProduct>> getAttributionsForCurrentSite() {
    final userSite = _getUserSite();

    if (userSite == 'Inconnu') {
      if (kDebugMode) {
        print('❌ Site utilisateur inconnu, aucune attribution récupérée');
      }
      return Stream.value([]);
    }

    if (kDebugMode) {
      print('🔍 Récupération des attributions pour le site: $userSite');
    }

    return _firestore
        .collection('Extraction')
        .doc(userSite)
        .collection('attributions')
        .where('supprime', isEqualTo: false) // Exclure les supprimés
        .orderBy('dateAttribution', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return _convertToExtractionProduct(doc.data(), doc.id);
            } catch (e) {
              if (kDebugMode) {
                print('❌ Erreur conversion attribution ${doc.id}: $e');
              }
              return null;
            }
          })
          .where((product) => product != null)
          .cast<ExtractionProduct>()
          .toList();
    });
  }

  /// Récupère une attribution spécifique par ID
  Future<ExtractionProduct?> getAttributionById(String attributionId) async {
    final userSite = _getUserSite();

    if (userSite == 'Inconnu') return null;

    try {
      final doc = await _firestore
          .collection('Extraction')
          .doc(userSite)
          .collection('attributions')
          .doc(attributionId)
          .get();

      if (!doc.exists) return null;

      return _convertToExtractionProduct(doc.data()!, doc.id);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération attribution $attributionId: $e');
      }
      return null;
    }
  }

  /// Convertit une attribution Firestore en ExtractionProduct
  ExtractionProduct _convertToExtractionProduct(
      Map<String, dynamic> data, String id) {
    final source = data['source'] as Map<String, dynamic>? ?? {};
    final metadata = data['metadata'] as Map<String, dynamic>? ?? {};
    final stats = data['statistiques'] as Map<String, dynamic>? ?? {};

    // Convertir le statut de contrôle en statut d'extraction
    final statutControl = data['statut'] as String? ?? 'attribueExtraction';
    final statutExtraction =
        _convertControlStatusToExtractionStatus(statutControl);

    // Déterminer le type de produit selon la nature
    final nature = data['natureProduitsAttribues'] as String? ?? 'brut';
    final productType =
        nature == 'brut' ? ProductType.mielBrut : ProductType.mielCristallise;

    // Récupérer les informations temporelles
    final dateAttribution =
        (data['dateAttribution'] as Timestamp?)?.toDate() ?? DateTime.now();

    return ExtractionProduct(
      id: id,
      nom: 'Attribution ${id.substring(id.length - 6)}', // Nom basé sur l'ID
      type: productType,
      origine: source['site'] as String? ??
          'Inconnu', // Site d'origine de la collecte
      collecteur: data['utilisateur'] as String? ??
          'Inconnu', // Utilisateur qui a fait l'attribution
      dateAttribution: dateAttribution,
      dateExtractionPrevue: _calculateExpectedExtractionDate(dateAttribution),
      quantiteContenants: (data['listeContenants'] as List?)?.length ?? 0,
      poidsTotal: (stats['poidsTotalEstime'] as num?)?.toDouble() ?? 0.0,
      statut: statutExtraction,
      priorite: _determinePriority(dateAttribution, productType),
      instructions: data['commentaires'] as String?,
      commentaires: 'Attribution depuis le module contrôle',
      qualite: _buildQualityData(metadata),
      attributeurId: data['utilisateur'] as String? ?? 'Inconnu',
      extracteurId: _getUserSite(), // Site actuel = extracteur
      dateDebutExtraction: null,
      dateFinExtraction: null,
      rendementExtraction: null,
      problemes: [],
      resultats: {},
    );
  }

  /// Convertit un statut de contrôle en statut d'extraction
  ExtractionStatus _convertControlStatusToExtractionStatus(
      String controlStatus) {
    switch (controlStatus) {
      case 'attribueExtraction':
        return ExtractionStatus.enAttente;
      case 'enCours':
        return ExtractionStatus.enCours;
      case 'termine':
        return ExtractionStatus.termine;
      case 'annule':
        return ExtractionStatus.suspendu;
      default:
        return ExtractionStatus.enAttente;
    }
  }

  /// Calcule la date d'extraction prévue (2-3 jours après attribution)
  DateTime? _calculateExpectedExtractionDate(DateTime dateAttribution) {
    return dateAttribution.add(const Duration(days: 2));
  }

  /// Détermine la priorité selon la date et le type
  ExtractionPriority _determinePriority(
      DateTime dateAttribution, ProductType type) {
    final daysSinceAttribution =
        DateTime.now().difference(dateAttribution).inDays;

    if (daysSinceAttribution >= 5) {
      return ExtractionPriority.urgente; // Attribution ancienne
    } else if (type == ProductType.mielBrut && daysSinceAttribution >= 2) {
      return ExtractionPriority
          .urgente; // Miel brut doit être traité rapidement
    } else if (daysSinceAttribution >= 1) {
      return ExtractionPriority.normale;
    } else {
      return ExtractionPriority.differee; // Attribution récente
    }
  }

  /// Construit les données de qualité depuis les métadonnées
  Map<String, dynamic> _buildQualityData(Map<String, dynamic> metadata) {
    return {
      'poids_total': metadata['totalWeight'] ?? 0.0,
      'montant_total': metadata['totalAmount'] ?? 0.0,
      'nombre_contenants': metadata['nombreContenants'] ?? 0,
      'source_module': 'controle',
      'created_from_control': metadata['createdFromControl'] ?? true,
    };
  }

  /// Met à jour le statut d'une attribution dans Firestore
  Future<void> updateAttributionStatus({
    required String attributionId,
    required ExtractionStatus newStatus,
    String? commentaire,
    Map<String, dynamic>? resultats,
  }) async {
    final userSite = _getUserSite();
    if (userSite == 'Inconnu') return;

    try {
      final updateData = <String, dynamic>{
        'statut': _convertExtractionStatusToControlStatus(newStatus),
        'derniereMiseAJour': FieldValue.serverTimestamp(),
      };

      if (commentaire != null) {
        updateData['commentaireExtracteur'] = commentaire;
      }

      if (resultats != null) {
        updateData['resultatsExtraction'] = resultats;
      }

      // Ajouter des dates selon le statut
      switch (newStatus) {
        case ExtractionStatus.enCours:
          updateData['dateDebutExtraction'] = FieldValue.serverTimestamp();
          break;
        case ExtractionStatus.termine:
          updateData['dateFinExtraction'] = FieldValue.serverTimestamp();
          if (resultats?['rendement'] != null) {
            updateData['rendementExtraction'] = resultats!['rendement'];
          }
          break;
        case ExtractionStatus.suspendu:
          updateData['dateAnnulation'] = FieldValue.serverTimestamp();
          break;
        default:
          break;
      }

      await _firestore
          .collection('Extraction')
          .doc(userSite)
          .collection('attributions')
          .doc(attributionId)
          .update(updateData);

      if (kDebugMode) {
        print('✅ Statut mis à jour: $attributionId -> ${newStatus.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur mise à jour statut: $e');
      }
      rethrow;
    }
  }

  /// Convertit un statut d'extraction en statut de contrôle
  String _convertExtractionStatusToControlStatus(
      ExtractionStatus extractionStatus) {
    switch (extractionStatus) {
      case ExtractionStatus.enAttente:
        return 'attribueExtraction';
      case ExtractionStatus.enCours:
        return 'enCours';
      case ExtractionStatus.termine:
        return 'termine';
      case ExtractionStatus.suspendu:
        return 'annule';
      case ExtractionStatus.erreur:
        return 'annule';
    }
  }

  /// Récupère les statistiques du site actuel
  Future<Map<String, dynamic>?> getSiteStatistics() async {
    final userSite = _getUserSite();
    if (userSite == 'Inconnu') return null;

    try {
      final doc = await _firestore.collection('Extraction').doc(userSite).get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération statistiques: $e');
      }
      return null;
    }
  }

  /// Compte les attributions par statut pour le site actuel
  Stream<Map<String, int>> getAttributionCountsByStatus() {
    final userSite = _getUserSite();

    if (userSite == 'Inconnu') {
      return Stream.value({});
    }

    return _firestore
        .collection('Extraction')
        .doc(userSite)
        .collection('attributions')
        .where('supprime', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final counts = <String, int>{
        'enAttente': 0,
        'enCours': 0,
        'termine': 0,
        'total': snapshot.docs.length,
      };

      for (final doc in snapshot.docs) {
        final statut = doc.data()['statut'] as String? ?? 'attribueExtraction';
        final extractionStatus =
            _convertControlStatusToExtractionStatus(statut);

        switch (extractionStatus) {
          case ExtractionStatus.enAttente:
            counts['enAttente'] = (counts['enAttente'] ?? 0) + 1;
            break;
          case ExtractionStatus.enCours:
            counts['enCours'] = (counts['enCours'] ?? 0) + 1;
            break;
          case ExtractionStatus.termine:
            counts['termine'] = (counts['termine'] ?? 0) + 1;
            break;
          default:
            break;
        }
      }

      return counts;
    });
  }
}
