import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../authentication/user_session.dart';

/// Types de collecte supportés
enum CollecteType {
  recolte('REC'),
  scoop('SCO'),
  individuel('IND'),
  miellerie('MIE');

  const CollecteType(this.code);
  final String code;
}

/// Service pour générer et gérer les IDs universels des contenants
/// Format: {TYPE}_{VILLAGE}_{TECHNICIEN}_{PRODUCTEUR}_{DATE}_{NUMERO}
/// Exemple: REC_SAKOINSÉ_JEAN_MARIE_20241215_0001
class UniversalContainerIdService {
  static final UniversalContainerIdService _instance =
      UniversalContainerIdService._internal();
  factory UniversalContainerIdService() => _instance;
  UniversalContainerIdService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserSession _userSession = Get.find<UserSession>();

  /// Génère les IDs pour une collecte complète
  /// Retourne une liste d'IDs uniques avec compteur continu
  /// Pour les récoltes (REC), le producteur est optionnel car ce sont des sites d'entreprise
  Future<List<String>> generateCollecteContainerIds({
    required CollecteType type,
    required String village,
    required String technicien,
    String? producteur, // Optionnel pour les récoltes
    required DateTime dateCollecte,
    required int nombreContenants,
  }) async {
    try {
      if (kDebugMode) {
        print('🆔 UNIVERSAL ID: Génération IDs pour collecte');
        print('   - Type: ${type.code}');
        print('   - Village: $village');
        print('   - Technicien: $technicien');
        print('   - Producteur: $producteur');
        print(
            '   - Date: ${dateCollecte.day}/${dateCollecte.month}/${dateCollecte.year}');
        print('   - Contenants: $nombreContenants');
      }

      // Nettoyer et formater les composants
      final villageClean = _cleanComponent(village);
      final technicienClean = _cleanComponent(technicien);
      final dateStr = _formatDate(dateCollecte);

      // Pour les récoltes, pas de producteur (sites d'entreprise)
      String producteurKey;
      String idFormat;

      if (type == CollecteType.recolte) {
        // Format pour récolte: REC_VILLAGE_TECHNICIEN_DATE_NUMERO
        producteurKey = '${type.code}_${villageClean}_${technicienClean}';
        idFormat = '${type.code}_${villageClean}_${technicienClean}';
      } else {
        // Format normal: TYPE_VILLAGE_TECHNICIEN_PRODUCTEUR_DATE_NUMERO
        final producteurClean = _cleanComponent(producteur ?? '');
        producteurKey =
            '${type.code}_${villageClean}_${technicienClean}_${producteurClean}';
        idFormat =
            '${type.code}_${villageClean}_${technicienClean}_${producteurClean}';
      }

      if (kDebugMode) {
        print('🔑 Clé unique: $producteurKey');
        print('📝 Format ID: $idFormat');
      }

      // Récupérer le dernier numéro utilisé pour ce producteur
      final lastNumber = await _getLastContainerNumber(producteurKey);

      if (kDebugMode) {
        print('📊 Dernier numéro utilisé: $lastNumber');
      }

      // Générer la liste des IDs
      final List<String> containerIds = [];
      for (int i = 1; i <= nombreContenants; i++) {
        final numero = (lastNumber + i).toString().padLeft(4, '0');
        final containerId = '${idFormat}_${dateStr}_$numero';
        containerIds.add(containerId);
      }

      // Sauvegarder le nouveau compteur
      await _updateContainerCounter(
          producteurKey, lastNumber + nombreContenants);

      if (kDebugMode) {
        print('✅ IDs générés:');
        for (final id in containerIds) {
          print('   📦 $id');
        }
      }

      return containerIds;
    } catch (e) {
      if (kDebugMode) {
        print('❌ UNIVERSAL ID: Erreur génération IDs: $e');
      }
      throw Exception('Erreur lors de la génération des IDs: $e');
    }
  }

  /// Génère un ID de contrôle basé sur les données du formulaire
  String generateControlId({
    required CollecteType type,
    required String village,
    required String technicien,
    String? producteur, // Optionnel pour les récoltes
    required DateTime dateCollecte,
    required String numeroContenant,
  }) {
    final villageClean = _cleanComponent(village);
    final technicienClean = _cleanComponent(technicien);
    final dateStr = _formatDate(dateCollecte);

    // Nettoyer le numéro (enlever C si présent)
    String numeroClean = numeroContenant.toUpperCase();
    if (numeroClean.startsWith('C')) {
      numeroClean = numeroClean.substring(1);
    }
    numeroClean = numeroClean.padLeft(4, '0');

    // Générer l'ID selon le type
    String controlId;
    if (type == CollecteType.recolte) {
      // Format pour récolte: REC_VILLAGE_TECHNICIEN_DATE_NUMERO
      controlId =
          '${type.code}_${villageClean}_${technicienClean}_${dateStr}_$numeroClean';
    } else {
      // Format normal: TYPE_VILLAGE_TECHNICIEN_PRODUCTEUR_DATE_NUMERO
      final producteurClean = _cleanComponent(producteur ?? '');
      controlId =
          '${type.code}_${villageClean}_${technicienClean}_${producteurClean}_${dateStr}_$numeroClean';
    }

    if (kDebugMode) {
      print('🎯 CONTROL ID généré: $controlId');
    }

    return controlId;
  }

  /// Vérifie si un ID de contrôle correspond à un contenant existant
  Future<ContainerMatchResult> verifyContainerMatch({
    required String controlId,
    required String site,
  }) async {
    try {
      if (kDebugMode) {
        print('🔍 VERIFY: Vérification correspondance pour $controlId');
      }

      // Décomposer l'ID de contrôle
      final components = _parseContainerId(controlId);
      if (components == null) {
        return ContainerMatchResult(
          found: false,
          error: 'Format d\'ID invalide: $controlId',
          containerId: controlId,
        );
      }

      if (kDebugMode) {
        print('🧩 Composants extraits:');
        print('   - Type: ${components.type}');
        print('   - Village: ${components.village}');
        print('   - Technicien: ${components.technicien}');
        print('   - Producteur: ${components.producteur}');
        print('   - Date: ${components.date}');
        print('   - Numéro: ${components.numero}');
      }

      // Rechercher dans toutes les collections de collecte
      final collecteInfo = await _findCollecteByContainerId(controlId, site);

      if (collecteInfo != null) {
        if (kDebugMode) {
          print(
              '✅ VERIFY: Contenant trouvé dans ${collecteInfo.collectionType}');
          print('   - Document: ${collecteInfo.documentId}');
          print('   - Index: ${collecteInfo.containerIndex}');
        }

        return ContainerMatchResult(
          found: true,
          containerId: controlId,
          collecteInfo: collecteInfo,
          components: components,
        );
      } else {
        if (kDebugMode) {
          print('❌ VERIFY: Contenant non trouvé');
        }

        return ContainerMatchResult(
          found: false,
          error: 'Contenant non trouvé: $controlId',
          containerId: controlId,
          components: components,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ VERIFY: Erreur vérification: $e');
      }

      return ContainerMatchResult(
        found: false,
        error: 'Erreur lors de la vérification: $e',
        containerId: controlId,
      );
    }
  }

  /// Récupère le dernier numéro de contenant utilisé pour un producteur
  Future<int> _getLastContainerNumber(String producteurKey) async {
    try {
      final doc = await _firestore
          .collection('Sites')
          .doc(_userSession.site)
          .collection('container_counters')
          .doc(producteurKey)
          .get();

      if (doc.exists) {
        return doc.data()?['lastNumber'] ?? 0;
      }
      return 0;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération compteur: $e');
      }
      return 0;
    }
  }

  /// Met à jour le compteur de contenants pour un producteur
  Future<void> _updateContainerCounter(
      String producteurKey, int newNumber) async {
    try {
      await _firestore
          .collection('Sites')
          .doc(_userSession.site)
          .collection('container_counters')
          .doc(producteurKey)
          .set({
        'lastNumber': newNumber,
        'updatedAt': FieldValue.serverTimestamp(),
        'site': _userSession.site,
      }, SetOptions(merge: true));

      if (kDebugMode) {
        print('✅ Compteur mis à jour: $producteurKey -> $newNumber');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur mise à jour compteur: $e');
      }
    }
  }

  /// Recherche une collecte par ID de contenant
  Future<CollecteInfo?> _findCollecteByContainerId(
      String containerId, String site) async {
    // Rechercher dans chaque type de collecte
    final collections = [
      'nos_collectes_recoltes',
      'nos_achats_scoop_contenants',
      'nos_achats_individuels',
      'nos_collectes_mielleries',
    ];

    for (final collectionName in collections) {
      try {
        final querySnapshot = await _firestore
            .collection('Sites')
            .doc(site)
            .collection(collectionName)
            .get();

        for (final doc in querySnapshot.docs) {
          final data = doc.data();
          final contenants = data['contenants'] as List<dynamic>?;

          if (contenants != null) {
            for (int i = 0; i < contenants.length; i++) {
              final contenant = contenants[i] as Map<String, dynamic>;
              final contenantId = contenant['id']?.toString();

              if (contenantId == containerId) {
                return CollecteInfo(
                  documentId: doc.id,
                  collectionType: collectionName,
                  containerIndex: i,
                  collecteData: data,
                );
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Erreur recherche dans $collectionName: $e');
        }
      }
    }

    return null;
  }

  /// Décompose un ID de contenant en ses composants
  ContainerIdComponents? _parseContainerId(String containerId) {
    try {
      final parts = containerId.split('_');

      // Vérifier le format selon le type
      if (parts.isEmpty) return null;

      final type = parts[0];

      if (type == 'REC') {
        // Format récolte: REC_VILLAGE_TECHNICIEN_DATE_NUMERO (5 parties)
        if (parts.length != 5) return null;

        return ContainerIdComponents(
          type: parts[0],
          village: parts[1],
          technicien: parts[2],
          producteur: '', // Pas de producteur pour les récoltes
          date: parts[3],
          numero: parts[4],
        );
      } else {
        // Format normal: TYPE_VILLAGE_TECHNICIEN_PRODUCTEUR_DATE_NUMERO (6 parties)
        if (parts.length != 6) return null;

        return ContainerIdComponents(
          type: parts[0],
          village: parts[1],
          technicien: parts[2],
          producteur: parts[3],
          date: parts[4],
          numero: parts[5],
        );
      }
    } catch (e) {
      return null;
    }
  }

  /// Nettoie et formate un composant d'ID
  String _cleanComponent(String component) {
    // Nettoyer et normaliser le composant
    String cleaned = component
        .trim() // Enlever espaces début/fin
        .toUpperCase() // Mettre en majuscules
        .replaceAll(
            RegExp(r'[^A-Z0-9]'), ''); // Garder seulement lettres et chiffres

    // Augmenter significativement la limite à 20 caractères pour éviter la troncature
    if (cleaned.length > 20) {
      cleaned = cleaned.substring(0, 20);
    }

    // S'assurer qu'il y a au moins un caractère
    if (cleaned.isEmpty) {
      cleaned = 'INCONNU';
    }

    return cleaned;
  }

  /// Formate une date pour l'ID
  String _formatDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  /// MÉTHODE DE TEST : Génère des exemples d'IDs pour validation
  void debugTestIdGeneration() {
    if (!kDebugMode) return;

    print('🧪 TEST GÉNÉRATION IDs - Nouveaux formats avec noms complets');
    print('');

    // Test avec des noms longs pour vérifier qu'ils ne sont plus tronqués
    final testCases = [
      {
        'type': CollecteType.recolte,
        'village': 'Mangodara',
        'technicien': 'Issoufs Ano',
        'producteur': null, // Pas de producteur pour récolte
      },
      {
        'type': CollecteType.scoop,
        'village': 'Dadadan',
        'technicien': 'Bak',
        'producteur': 'Sanakravag',
      },
      {
        'type': CollecteType.individuel,
        'village': 'Boukinado',
        'technicien': 'Bak',
        'producteur': 'Bamounibak',
      },
      {
        'type': CollecteType.miellerie,
        'village': 'Mangodara',
        'technicien': 'Issoufs Ano',
        'producteur': 'Mangodara Cooperative',
      },
    ];

    for (final testCase in testCases) {
      final type = testCase['type'] as CollecteType;
      final village = testCase['village'] as String;
      final technicien = testCase['technicien'] as String;
      final producteur = testCase['producteur'] as String?;

      print('📋 Test ${type.code}:');
      print('   Village original: "$village"');
      print('   Technicien original: "$technicien"');
      if (producteur != null) {
        print('   Producteur original: "$producteur"');
      } else {
        print('   Producteur: AUCUN (site d\'entreprise)');
      }

      // Nettoyer les composants
      final villageClean = _cleanComponent(village);
      final technicienClean = _cleanComponent(technicien);
      final producteurClean =
          producteur != null ? _cleanComponent(producteur) : null;

      print('   Village nettoyé: "$villageClean"');
      print('   Technicien nettoyé: "$technicienClean"');
      if (producteurClean != null) {
        print('   Producteur nettoyé: "$producteurClean"');
      }

      // Générer l'ID de test
      final dateTest = DateTime(2025, 9, 2);
      final dateStr = _formatDate(dateTest);

      String idExample;
      if (type == CollecteType.recolte) {
        idExample =
            '${type.code}_${villageClean}_${technicienClean}_${dateStr}_0001';
      } else {
        idExample =
            '${type.code}_${villageClean}_${technicienClean}_${producteurClean}_${dateStr}_0001';
      }

      print('   ✅ ID généré: $idExample');
      print('   📏 Longueur totale: ${idExample.length} caractères');
      print('');
    }

    print('🎯 Résumé des améliorations:');
    print('   • Limite augmentée à 20 caractères par composant');
    print('   • Récoltes sans producteur (format spécial)');
    print('   • Noms complets préservés');
    print('   • Parsing intelligent selon le type');
    print('');
  }
}

/// Résultat de la vérification de correspondance d'un contenant
class ContainerMatchResult {
  final bool found;
  final String? error;
  final String? containerId;
  final CollecteInfo? collecteInfo;
  final ContainerIdComponents? components;

  ContainerMatchResult({
    required this.found,
    this.error,
    this.containerId,
    this.collecteInfo,
    this.components,
  });
}

/// Informations sur une collecte trouvée
class CollecteInfo {
  final String documentId;
  final String collectionType;
  final int containerIndex;
  final Map<String, dynamic> collecteData;

  CollecteInfo({
    required this.documentId,
    required this.collectionType,
    required this.containerIndex,
    required this.collecteData,
  });
}

/// Composants d'un ID de contenant décomposé
class ContainerIdComponents {
  final String type;
  final String village;
  final String technicien;
  final String producteur;
  final String date;
  final String numero;

  ContainerIdComponents({
    required this.type,
    required this.village,
    required this.technicien,
    required this.producteur,
    required this.date,
    required this.numero,
  });

  @override
  String toString() {
    return 'ContainerIdComponents(type: $type, village: $village, technicien: $technicien, producteur: $producteur, date: $date, numero: $numero)';
  }
}
