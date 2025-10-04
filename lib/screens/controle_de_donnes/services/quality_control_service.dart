import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'global_refresh_service.dart';
import '../models/collecte_models.dart';
import 'package:flutter/foundation.dart';
import '../models/quality_control_models.dart';
import '../../../authentication/user_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../quality_control/services/quality_computation_service.dart';

// Service pour la gestion des données de contrôle qualité
/// Résultat d'une mise à jour de collecte
class CollecteUpdateResult {
  final bool success;
  final String? collecteId;
  final String? collectionPath;

  const CollecteUpdateResult({
    required this.success,
    this.collecteId,
    this.collectionPath,
  });

  factory CollecteUpdateResult.success(
      {required String collecteId, String? collectionPath}) {
    return CollecteUpdateResult(
      success: true,
      collecteId: collecteId,
      collectionPath: collectionPath,
    );
  }

  factory CollecteUpdateResult.failure() {
    return const CollecteUpdateResult(success: false);
  }
}

/// Service pour sauvegarder et récupérer les données de contrôle qualité
class QualityControlService {
  static final QualityControlService _instance =
      QualityControlService._internal();
  factory QualityControlService() => _instance;
  QualityControlService._internal();

  // Instance Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Règles et calculs métier
  final QualityComputationService _computation =
      const QualityComputationService();

  // Stockage en mémoire pour cache (optionnel)
  final Map<String, QualityControlData> _qualityControlsCache = {};

  // Cache optimisé par collecte pour réduire les requêtes
  final Map<String, Map<String, dynamic>> _collecteControlStatsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Stream controllers pour les mises à jour en temps réel
  final StreamController<Map<String, QualityControlData>>
      _controlsStreamController =
      StreamController<Map<String, QualityControlData>>.broadcast();
  final StreamController<QualityStats> _statsStreamController =
      StreamController<QualityStats>.broadcast();

  // Streams publics pour écouter les changements
  Stream<Map<String, QualityControlData>> get controlsStream =>
      _controlsStreamController.stream;
  Stream<QualityStats> get statsStream => _statsStreamController.stream;

  // Dernières statistiques calculées
  QualityStats? _lastStats;

  /// Sauvegarde un contrôle qualité
  Future<bool> saveQualityControl(QualityControlData data,
      {String? collecteId}) async {
    try {
      // Récupérer le site de l'utilisateur connecté
      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';

      // 🆕 Créer un ID unique pour le document qui inclut l'ID de la collecte si disponible
      // Nettoyer le code de contenant pour éviter les caractères spéciaux
      final cleanContainerCode = _cleanContainerCode(data.containerCode);
      final cleanCollecteId =
          collecteId != null ? _cleanComponent(collecteId) : null;

      final docId = cleanCollecteId != null
          ? '${cleanContainerCode}_${cleanCollecteId}_${data.receptionDate.millisecondsSinceEpoch}'
          : '${cleanContainerCode}_${data.receptionDate.millisecondsSinceEpoch}';

      // Calculs métiers avant sauvegarde
      final trimmedObservation = data.observations?.trim();
      final normalizedObservation =
          (trimmedObservation == null || trimmedObservation.isEmpty)
              ? null
              : trimmedObservation;

      final observationError = _computation.validateObservation(
          data.conformityStatus, normalizedObservation);
      if (observationError != null) {
        throw ArgumentError(observationError);
      }

      final containerTypeEnum = _resolveContainerType(data.containerType);
      final computedWater = data.waterContent ??
          _computation.computeWaterContent(
            containerType: containerTypeEnum,
            odorProfile: data.odorProfile,
            depositLevel: data.depositLevel,
            manualMeasure: data.manualWaterContent,
          );

      final controllerName = (data.controllerName?.trim().isNotEmpty ?? false)
          ? data.controllerName!.trim()
          : (userSession.nom ?? 'Contrôleur');

      final normalizedData = data.copyWith(
        waterContent: computedWater,
        controllerName: controllerName,
        observations: normalizedObservation,
      );

      // Préparer les données pour Firestore
      final firestoreData = {
        'id': docId,
        'containerCode': normalizedData.containerCode,
        'receptionDate': Timestamp.fromDate(normalizedData.receptionDate),
        'producer': normalizedData.producer,
        'apiaryVillage': normalizedData.apiaryVillage,
        'hiveType': normalizedData.hiveType,
        'collectionStartDate': normalizedData.collectionStartDate != null
            ? Timestamp.fromDate(normalizedData.collectionStartDate!)
            : null,
        'collectionEndDate': normalizedData.collectionEndDate != null
            ? Timestamp.fromDate(normalizedData.collectionEndDate!)
            : null,
        'honeyNature': normalizedData.honeyNature.name,
        'containerType': normalizedData.containerType,
        'containerNumber': normalizedData.containerNumber,
        'totalWeight': normalizedData.totalWeight,
        'honeyWeight': normalizedData.honeyWeight,
        'quality': normalizedData.quality,
        'waterContent': normalizedData.waterContent,
        'manualWaterContent': normalizedData.manualWaterContent,
        'odorProfile': normalizedData.odorProfile.name,
        'depositLevel': normalizedData.depositLevel.name,
        'pollenLostKg': normalizedData.pollenLostKg,
        'residuePercent': normalizedData.residuePercent,
        'floralPredominance': normalizedData.floralPredominance,
        'conformityStatus': normalizedData.conformityStatus.name,
        'nonConformityCause': normalizedData.nonConformityCause,
        'observations': normalizedData.observations,
        'controllerName': normalizedData.controllerName,
        'createdAt': Timestamp.fromDate(normalizedData.createdAt),
        'site': siteUtilisateur,
        'dateCreation': FieldValue.serverTimestamp(),
        'derniereMiseAJour': FieldValue.serverTimestamp(),
        // 🆕 Champs pour optimisation interface
        'collecteId':
            collecteId, // 🔧 CORRECTION: Utiliser le collecteId passé en paramètre
        'collectionPath': null, // Chemin vers la collection d'origine
      };

      // Sauvegarder dans Firestore : Collection "controles_qualite" organisée par site
      await _firestore
          .collection('controles_qualite')
          .doc(siteUtilisateur)
          .collection('controles')
          .doc(docId)
          .set(firestoreData);

      // Mettre à jour le cache local
      _qualityControlsCache[docId] = normalizedData;

      if (kDebugMode) {
        print(
            '✅ Contrôle qualité sauvegardé en Firestore: controles_qualite/$siteUtilisateur/controles/$docId');
        print('📊 Contenant: ${data.containerCode}');
        print(
            '🆔 CollecteId: $collecteId ${collecteId != null ? "(✅ LIEN ÉTABLI)" : "(❌ MANQUANT)"}');
        print('👤 Contrôleur: ${normalizedData.controllerName}');
        print('✅ Conformité: ${normalizedData.conformityStatus.name}');
        print('⚖️ Poids total: ${normalizedData.totalWeight} kg');
        print('🍯 Poids miel: ${normalizedData.honeyWeight} kg');
        print(
            '💧 Teneur en eau calculée: ${normalizedData.waterContent?.toStringAsFixed(2) ?? '-'}%');
        print('🌼 Pollen perdu: ${normalizedData.pollenLostKg ?? 0} kg');
        print('🧪 Résidus: ${normalizedData.residuePercent ?? 0}%');
      }

      // Mettre à jour le cache local
      _qualityControlsCache[docId] = normalizedData;

      // Mettre à jour le champ de contrôle dans la collecte source
      await _updateCollecteControlStatus(normalizedData);

      // Notifier les listeners des changements
      _notifyListeners();

      // 🆕 INVALIDATION IMMÉDIATE DU CACHE avant les notifications
      // On utilise le containerCode pour invalider tous les caches potentiels
      _invalidateAllRelatedCaches(data.containerCode);

      // Notifier le service global pour rafraîchir les autres pages
      GlobalRefreshService().notifyQualityControlUpdate(data.containerCode);
      GlobalRefreshService().notifyCollecteUpdate(data.containerCode);

      // 🆕 Notification spécifique pour synchronisation interface
      GlobalRefreshService().notifyInterfaceSync(
        action: 'quality_control_updated',
        collecteId: collecteId ?? data.containerCode,
        containerCode: data.containerCode,
        additionalData: {
          'conformityStatus': normalizedData.conformityStatus.name,
          'controllerName': normalizedData.controllerName,
        },
      );

      if (kDebugMode) {
        print('✅ Contrôle qualité sauvegardé avec succès: $docId');
        print('📝 Collecte mise à jour avec l\'information de contrôle');
        print('📢 Notification envoyée aux autres pages');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la sauvegarde Firestore: $e');
      }
      return false;
    }
  }

  /// Récupère un contrôle qualité par code de contenant
  Future<QualityControlData?> getQualityControl(
      String containerCode, DateTime receptionDate,
      {String? collecteId}) async {
    try {
      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';

      // 🆕 Générer un docId unique qui inclut l'ID de la collecte si disponible
      // Nettoyer les composants pour éviter les caractères spéciaux
      final cleanContainerCode = _cleanContainerCode(containerCode);
      final cleanCollecteId =
          collecteId != null ? _cleanComponent(collecteId) : null;

      final docId = cleanCollecteId != null
          ? '${cleanContainerCode}_${cleanCollecteId}_${receptionDate.millisecondsSinceEpoch}'
          : '${cleanContainerCode}_${receptionDate.millisecondsSinceEpoch}';

      if (kDebugMode) {
        print('🔍 QUALITY: Recherche contrôle pour $containerCode');
        print('   - Site: $siteUtilisateur');
        print('   - DocId: $docId');
        print('   - Date: $receptionDate');
        print('   - CollecteId: $collecteId');
      }

      // Vérifier d'abord le cache
      if (_qualityControlsCache.containsKey(docId)) {
        if (kDebugMode) {
          print('✅ QUALITY: Contrôle trouvé dans le cache pour $containerCode');
        }
        return _qualityControlsCache[docId];
      }

      if (kDebugMode) {
        print('🔍 QUALITY: Recherche dans Firestore pour $containerCode...');
        print('   - Collection: controles_qualite/$siteUtilisateur/controles');
        print('   - Document: $docId');
      }

      // Récupérer depuis Firestore
      final doc = await _firestore
          .collection('controles_qualite')
          .doc(siteUtilisateur)
          .collection('controles')
          .doc(docId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final qualityControl = QualityControlData.fromFirestore(data,
            documentId: docId); // 🆕 Passer le documentId

        // Mettre en cache
        _qualityControlsCache[docId] = qualityControl;

        if (kDebugMode) {
          print(
              '✅ QUALITY: Contrôle trouvé dans Firestore pour $containerCode');
          print('   - Statut: ${qualityControl.conformityStatus}');
          print('   - Nature: ${qualityControl.honeyNature}');
        }

        return qualityControl;
      }

      if (kDebugMode) {
        print('❌ QUALITY: Aucun contrôle trouvé pour $containerCode');
        print('   - Doc exists: ${doc.exists}');
        print('   - Has data: ${doc.data() != null}');
      }

      // Essayer une recherche alternative par containerCode seulement
      if (kDebugMode) {
        print(
            '🔍 QUALITY: Tentative de recherche alternative par containerCode...');
      }

      final querySnapshot = await _firestore
          .collection('controles_qualite')
          .doc(siteUtilisateur)
          .collection('controles')
          .where('containerCode', isEqualTo: containerCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        final qualityControl = QualityControlData.fromFirestore(data,
            documentId: doc.id); // 🆕 Passer le documentId réel

        // Mettre en cache avec la clé originale
        _qualityControlsCache[docId] = qualityControl;

        if (kDebugMode) {
          print(
              '✅ QUALITY: Contrôle trouvé par recherche alternative pour $containerCode');
          print('   - Document ID: ${doc.id}');
          print('   - Statut: ${qualityControl.conformityStatus}');
        }

        return qualityControl;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la récupération Firestore: $e');
      }
      return null;
    }
  }

  /// Récupère tous les contrôles qualité disponibles
  List<QualityControlData> getAllQualityControls() {
    return _qualityControlsCache.values.toList();
  }

  /// Vérifie si un contenant spécifique est contrôlé (alias pour simplicité)
  Future<bool> isContainerControlled(
      String containerCode, DateTime receptionDate,
      {String? collecteId}) async {
    final control = await getQualityControl(containerCode, receptionDate,
        collecteId: collecteId);
    return control != null;
  }

  /// Obtient les statistiques de contrôle pour une liste de contenants
  Future<Map<String, int>> getControlStatsForContainers(
      List<String> containerCodes, DateTime receptionDate) async {
    int controlledCount = 0;

    for (final code in containerCodes) {
      if (await isContainerControlled(code, receptionDate)) {
        controlledCount++;
      }
    }

    return {
      'total': containerCodes.length,
      'controlled': controlledCount,
      'uncontrolled': containerCodes.length - controlledCount,
    };
  }

  /// NOUVELLE MÉTHODE OPTIMISÉE: Obtient les statistiques de contrôle directement depuis les données de collecte
  Map<String, int> getControlStatsFromCollecteData(dynamic collecteData) {
    if (kDebugMode) {
      print('🔍 ===== DÉBUT getControlStatsFromCollecteData =====');
      print('🔍 CollecteData type: ${collecteData.runtimeType}');
      print('🔍 CollecteData null: ${collecteData == null}');
    }

    if (collecteData == null) {
      if (kDebugMode) {
        print('❌ CollecteData est null - retour stats vides');
      }
      return {'total': 0, 'controlled': 0, 'uncontrolled': 0};
    }

    // CORRECTION: Accéder aux données depuis l'objet collecte
    List<dynamic> contenants;

    // Gérer les différents types d'objets collecte
    if (collecteData is Map<String, dynamic>) {
      if (kDebugMode) {
        print('📄 CollecteData est Map<String, dynamic>');
        print('📄 Clés disponibles: ${collecteData.keys.toList()}');
      }
      contenants = collecteData['contenants'] as List<dynamic>? ?? [];
      if (kDebugMode) {
        print('📄 Contenants extraits de Map: ${contenants.length} éléments');
      }
    } else {
      if (kDebugMode) {
        print('📄 CollecteData est objet (${collecteData.runtimeType})');
      }
      // Pour les objets de type Recolte, Scoop, etc.
      try {
        contenants =
            (collecteData as dynamic).contenants as List<dynamic>? ?? [];
        if (kDebugMode) {
          print(
              '📄 Contenants extraits directement: ${contenants.length} éléments');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Erreur accès direct contenants: $e');
          print('⚠️ Tentative toMap()...');
        }
        // Fallback vers toMap si disponible
        try {
          final collecteMap =
              (collecteData as dynamic).toMap() as Map<String, dynamic>;
          contenants = collecteMap['contenants'] as List<dynamic>? ?? [];
          if (kDebugMode) {
            print(
                '📄 Contenants extraits via toMap(): ${contenants.length} éléments');
          }
        } catch (e2) {
          if (kDebugMode) {
            print('❌ Erreur toMap(): $e2');
          }
          return {'total': 0, 'controlled': 0, 'uncontrolled': 0};
        }
      }
    }

    if (contenants.isEmpty) {
      if (kDebugMode) {
        print('❌ Contenants vide - retour stats vides');
      }
      return {'total': 0, 'controlled': 0, 'uncontrolled': 0};
    }

    if (kDebugMode) {
      print('📊 ANALYSE DE ${contenants.length} CONTENANTS:');
    }

    int controlledCount = 0;
    int totalCount = 0;

    for (final contenant in contenants) {
      totalCount++;
      if (kDebugMode) {
        print('📦 --- CONTENANT ${totalCount} ---');
        print('📦 Type: ${contenant.runtimeType}');
      }

      // Vérifier si le contenant a un champ controlInfo avec isControlled = true
      try {
        String contenantId = 'ID_INCONNU';
        bool isControlled = false;

        // CORRECTION: Gérer les différents types de contenants
        if (contenant is Map<String, dynamic>) {
          // Données brutes depuis Firestore (cas Map)
          contenantId = contenant['id']?.toString() ?? 'ID_MANQUANT';
          final controlInfo = contenant['controlInfo'] as Map<String, dynamic>?;
          isControlled =
              controlInfo != null && controlInfo['isControlled'] == true;

          if (kDebugMode) {
            print('📦 ID (Map): $contenantId');
            print('📦 ControlInfo (Map): $controlInfo');
          }
        } else {
          // Objets typés (RecolteContenant, ScoopContenant, etc.)
          try {
            final contenantObj = contenant as dynamic;
            contenantId = contenantObj.id?.toString() ?? 'ID_OBJET_MANQUANT';
            final controlInfo = contenantObj.controlInfo;
            isControlled =
                controlInfo != null && controlInfo.isControlled == true;

            if (kDebugMode) {
              print('📦 ID (Objet): $contenantId');
              print(
                  '📦 ControlInfo (Objet): isControlled=${controlInfo?.isControlled}');
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Erreur accès objet: $e');
            }
          }
        }

        if (isControlled) {
          controlledCount++;
          if (kDebugMode) {
            print('✅ CONTENANT $contenantId → CONTRÔLÉ');
          }
        } else {
          if (kDebugMode) {
            print('❌ CONTENANT $contenantId → NON CONTRÔLÉ');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Erreur traitement contenant: $e');
        }
        // Si controlInfo n'existe pas, le contenant n'est pas contrôlé
      }
    }

    final result = {
      'total': totalCount,
      'controlled': controlledCount,
      'uncontrolled': totalCount - controlledCount,
    };

    if (kDebugMode) {
      print('🎯 ===== RÉSULTAT FINAL =====');
      print('🎯 Total contenants: $totalCount');
      print('🎯 Contenants contrôlés: $controlledCount');
      print('🎯 Contenants non contrôlés: ${totalCount - controlledCount}');
      print('🎯 ========================');
    }

    return result;
  }

  /// NOUVELLE MÉTHODE OPTIMISÉE: Vérifie si un contenant est contrôlé directement depuis les données de collecte
  bool isContainerControlledFromCollecteData(
      dynamic collecteData, String containerCode) {
    if (collecteData == null) return false;

    final contenants = collecteData.contenants;
    if (contenants == null) return false;

    if (kDebugMode) {
      print(
          '🔍 Recherche du contenant $containerCode dans ${contenants.length} contenants');
    }

    // ✅ CORRECTION: Chercher le contenant par son ID réel
    for (final contenant in contenants) {
      try {
        // Obtenir l'ID du contenant
        String contenantId = '';
        if (contenant is Map<String, dynamic>) {
          contenantId = contenant['id']?.toString() ?? '';
        } else {
          // Objet typé (RecolteContenant, ScoopContenant, IndividuelContenant)
          final contenantObj = contenant as dynamic;
          contenantId = contenantObj.id?.toString() ?? '';
        }

        if (kDebugMode) {
          print('🔍 Comparaison: "$contenantId" vs "$containerCode"');
        }

        // Si c'est le bon contenant, vérifier son statut de contrôle
        if (contenantId == containerCode) {
          if (kDebugMode) {
            print('✅ Contenant trouvé: $containerCode');
          }

          // Récupérer le controlInfo
          dynamic controlInfo;
          if (contenant is Map<String, dynamic>) {
            controlInfo = contenant['controlInfo'];
          } else {
            final contenantObj = contenant as dynamic;
            controlInfo = contenantObj.controlInfo;
          }

          if (controlInfo != null) {
            bool isControlled = false;
            if (controlInfo is Map<String, dynamic>) {
              isControlled = controlInfo['isControlled'] == true;
            } else {
              isControlled = controlInfo.isControlled == true;
            }

            if (kDebugMode) {
              print('🎯 Contenant $containerCode → Contrôlé: $isControlled');
            }
            return isControlled;
          } else {
            if (kDebugMode) {
              print('❌ Contenant $containerCode → Pas de controlInfo');
            }
            return false;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Erreur traitement contenant: $e');
        }
        continue;
      }
    }

    if (kDebugMode) {
      print('❌ Contenant $containerCode non trouvé');
    }
    return false;
  }

  /// NOUVELLE MÉTHODE OPTIMISÉE: Obtient les informations de contrôle d'un contenant depuis les données de collecte
  ContainerControlInfo? getContainerControlInfoFromCollecteData(
      dynamic collecteData, String containerCode) {
    if (collecteData == null) return null;

    final contenants = collecteData.contenants;
    if (contenants == null) return null;

    // ✅ CORRECTION: Chercher le contenant par son ID réel
    for (final contenant in contenants) {
      try {
        // Obtenir l'ID du contenant
        String contenantId = '';
        if (contenant is Map<String, dynamic>) {
          contenantId = contenant['id']?.toString() ?? '';
        } else {
          // Objet typé (RecolteContenant, ScoopContenant, IndividuelContenant)
          final contenantObj = contenant as dynamic;
          contenantId = contenantObj.id?.toString() ?? '';
        }

        // Si c'est le bon contenant, récupérer son controlInfo
        if (contenantId == containerCode) {
          if (contenant is Map<String, dynamic>) {
            final controlInfoData =
                contenant['controlInfo'] as Map<String, dynamic>?;
            if (controlInfoData != null) {
              return ContainerControlInfo.fromMap(controlInfoData);
            }
          } else {
            final contenantObj = contenant as dynamic;
            return contenantObj.controlInfo as ContainerControlInfo?;
          }
          return null; // Contenant trouvé mais pas de controlInfo
        }
      } catch (e) {
        continue;
      }
    }

    return null; // Contenant non trouvé
  }

  /// Récupère tous les contrôles qualité pour une période donnée
  List<QualityControlData> getQualityControlsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    // Cette méthode est maintenant asynchrone et utilise Firestore
    // Pour la compatibilité immédiate, on retourne le cache local
    return _qualityControlsCache.values
        .where((control) =>
            control.receptionDate
                .isAfter(startDate.subtract(const Duration(days: 1))) &&
            control.receptionDate
                .isBefore(endDate.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => b.receptionDate.compareTo(a.receptionDate));
  }

  /// Récupère tous les contrôles qualité d'un producteur
  List<QualityControlData> getQualityControlsByProducer(String producer) {
    return _qualityControlsCache.values
        .where((control) =>
            control.producer.toLowerCase().contains(producer.toLowerCase()))
        .toList()
      ..sort((a, b) => b.receptionDate.compareTo(a.receptionDate));
  }

  /// Récupère les statistiques de conformité
  QualityStats getQualityStats({DateTime? startDate, DateTime? endDate}) {
    var controls = _qualityControlsCache.values.toList();

    if (startDate != null && endDate != null) {
      controls = controls
          .where((control) =>
              control.receptionDate
                  .isAfter(startDate.subtract(const Duration(days: 1))) &&
              control.receptionDate
                  .isBefore(endDate.add(const Duration(days: 1))))
          .toList();
    }

    final total = controls.length;
    final conforme = controls
        .where((c) => c.conformityStatus == ConformityStatus.conforme)
        .length;
    final nonConforme = total - conforme;

    final averageWaterContent = controls
            .where((c) => c.waterContent != null)
            .fold<double>(0, (sum, c) => sum + c.waterContent!) /
        controls.where((c) => c.waterContent != null).length;

    final totalHoneyWeight =
        controls.fold<double>(0, (sum, c) => sum + c.honeyWeight);

    return QualityStats(
      totalControls: total,
      conformeCount: conforme,
      nonConformeCount: nonConforme,
      conformityRate: total > 0 ? (conforme / total) * 100 : 0,
      averageWaterContent: averageWaterContent.isNaN ? 0 : averageWaterContent,
      totalHoneyWeight: totalHoneyWeight,
    );
  }

  /// Supprime un contrôle qualité
  Future<bool> deleteQualityControl(
      String containerCode, DateTime receptionDate) async {
    try {
      final key = '${containerCode}_${receptionDate.millisecondsSinceEpoch}';
      _qualityControlsCache.remove(key);

      await Future.delayed(const Duration(milliseconds: 200));

      if (kDebugMode) {
        print('🗑️ Contrôle qualité supprimé: $key');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la suppression: $e');
      }
      return false;
    }
  }

  /// Exporte les données en JSON
  String exportToJson({DateTime? startDate, DateTime? endDate}) {
    var controls = _qualityControlsCache.values.toList();

    if (startDate != null && endDate != null) {
      controls = controls
          .where((control) =>
              control.receptionDate
                  .isAfter(startDate.subtract(const Duration(days: 1))) &&
              control.receptionDate
                  .isBefore(endDate.add(const Duration(days: 1))))
          .toList();
    }

    final data = {
      'export_date': DateTime.now().toIso8601String(),
      'total_controls': controls.length,
      'quality_controls': controls.map((c) => c.toJson()).toList(),
    };

    return jsonEncode(data);
  }

  /// Vérifie si un contenant a déjà été contrôlé (vérification cache local uniquement)
  bool isContainerControlledInCache(
      String containerCode, DateTime receptionDate) {
    final key = '${containerCode}_${receptionDate.millisecondsSinceEpoch}';
    return _qualityControlsCache.containsKey(key);
  }

  /// Récupère les causes de non-conformité les plus fréquentes
  Map<String, int> getNonConformityCauses() {
    final causes = <String, int>{};

    for (final control in _qualityControlsCache.values) {
      if (control.conformityStatus == ConformityStatus.nonConforme &&
          control.nonConformityCause != null) {
        final cause = control.nonConformityCause!;
        causes[cause] = (causes[cause] ?? 0) + 1;
      }
    }

    // Trier par fréquence décroissante
    final sortedEntries = causes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }

  /// Supprime toutes les données de test fictives
  Future<void> clearTestData() async {
    try {
      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';

      // Liste des codes de contenants fictifs à supprimer
      final testContainerCodes = [
        'REF001',
        'IND002',
        'MIE003',
        'SCO004',
        'REF005',
        'IND006',
        'MIE007',
        'SCO008'
      ];

      final batch = _firestore.batch();
      int deleteCount = 0;

      for (final containerCode in testContainerCodes) {
        final querySnapshot = await _firestore
            .collection('controles_qualite')
            .doc(siteUtilisateur)
            .collection('controles')
            .where('containerCode', isEqualTo: containerCode)
            .get();

        for (final doc in querySnapshot.docs) {
          batch.delete(doc.reference);
          deleteCount++;
        }
      }

      if (deleteCount > 0) {
        await batch.commit();

        // Vider le cache
        _qualityControlsCache.clear();

        if (kDebugMode) {
          print('✅ Supprimé $deleteCount données de test fictives');
        }
      } else {
        if (kDebugMode) {
          print('ℹ️ Aucune donnée de test fictive trouvée à supprimer');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la suppression des données de test: $e');
      }
      rethrow;
    }
  }

  /// Récupère tous les contrôles qualité depuis Firestore
  Future<List<QualityControlData>> getAllQualityControlsFromFirestore() async {
    try {
      // 🚀 LOGS DE TRAÇAGE SERVICE QUALITÉ
      debugPrint('🔍 ===== SERVICE QUALITÉ APPELÉ POUR RÉCUPÉRATION =====');
      debugPrint('   📁 Service: QualityControlService');
      debugPrint('   🔧 Méthode: getAllQualityControlsFromFirestore()');
      debugPrint(
          '   🎯 Cette méthode fonctionne parfaitement pour l\'affichage');
      debugPrint(
          '   ✅ CONFIRMATION: Elle est utilisée par le système d\'attribution');
      debugPrint('   📅 Timestamp: ${DateTime.now()}');
      debugPrint('==========================================================');

      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';
      debugPrint('🏭 Site utilisateur: $siteUtilisateur');

      final querySnapshot = await _firestore
          .collection('controles_qualite')
          .doc(siteUtilisateur)
          .collection('controles')
          .orderBy('receptionDate', descending: true)
          .get();

      final controls = <QualityControlData>[];
      debugPrint(
          '📊 Traitement de ${querySnapshot.docs.length} documents trouvés...');

      for (int i = 0; i < querySnapshot.docs.length; i++) {
        final doc = querySnapshot.docs[i];
        final data = doc.data();

        debugPrint('   📄 Document ${i + 1}: ${doc.id}');
        debugPrint('   📦 ContainerCode: ${data['containerCode']}');

        final control = QualityControlData.fromFirestore(data,
            documentId: doc.id); // 🆕 Passer le documentId réel
        controls.add(control);

        debugPrint(
            '   ✅ Contrôle ajouté avec documentId: ${control.documentId}');

        // Mettre en cache
        final key =
            '${control.containerCode}_${control.receptionDate.millisecondsSinceEpoch}';
        _qualityControlsCache[key] = control;
      }

      debugPrint('🎊 ===== RÉSULTAT FINAL RÉCUPÉRATION =====');
      debugPrint(
          '   ✅ SUCCÈS: ${controls.length} contrôles qualité récupérés depuis Firestore');
      debugPrint('   🎯 Tous les contrôles ont leur documentId réel !');
      debugPrint(
          '   📊 Cette liste sera utilisée pour filtrer par containerCode');
      debugPrint('   🚀 Exactement comme pour l\'affichage des produits !');
      debugPrint('=============================================');

      return controls;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la récupération Firestore: $e');
      }
      return [];
    }
  }

  /// Méthodes privées pour la gestion des streams
  void _notifyListeners() {
    // Notifier les changements dans les contrôles
    _controlsStreamController.add(Map.from(_qualityControlsCache));

    // Calculer et notifier les nouvelles statistiques
    final newStats = getQualityStats();
    _lastStats = newStats;
    _statsStreamController.add(newStats);
  }

  /// Met à jour le champ de contrôle dans la collecte source
  Future<void> _updateCollecteControlStatus(
      QualityControlData controlData) async {
    try {
      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';

      // Créer l'information de contrôle à ajouter
      final controlInfo = {
        'isControlled': true,
        'conformityStatus': controlData.conformityStatus.name,
        'controlDate': Timestamp.fromDate(controlData.createdAt),
        'controllerName': controlData.controllerName,
        'controlId':
            '${_cleanContainerCode(controlData.containerCode)}_${controlData.receptionDate.millisecondsSinceEpoch}',
      };

      if (kDebugMode) {
        print('🔄 MISE À JOUR COLLECTE - Début');
        print('📦 Contenant: ${controlData.containerCode}');
        print('👥 Producteur: ${controlData.producer}');
        print('📅 Date: ${controlData.receptionDate}');
      }

      // 🆕 DÉTECTION BASÉE SUR LA RECHERCHE EN BASE DE DONNÉES
      final String collectionType =
          await _detectCollectionTypeFromDatabase(controlData, siteUtilisateur);
      final CollecteUpdateResult updateResult =
          await _updateSpecificCollectionType(
        collectionType: collectionType,
        siteUtilisateur: siteUtilisateur,
        controlData: controlData,
        controlInfo: controlInfo,
      );

      if (!updateResult.success) {
        if (kDebugMode) {
          print('⚠️ Détection automatique échouée, essai de tous les types...');
        }
        final fallbackResult = await _updateAllCollectionTypes(
            siteUtilisateur, controlData, controlInfo);

        // Si trouvé dans le fallback, mettre à jour le contrôle avec l'ID de collecte
        if (fallbackResult.success && fallbackResult.collecteId != null) {
          await _updateQualityControlWithCollecteId(
              controlData, fallbackResult.collecteId!);
          // 🔄 FORCER LA MISE À JOUR IMMÉDIATE DE L'INTERFACE
          _forceInterfaceUpdate(
              fallbackResult.collecteId!, controlData.containerCode);
        }
      } else if (updateResult.collecteId != null) {
        // Mettre à jour le contrôle qualité avec l'ID de collecte trouvé
        await _updateQualityControlWithCollecteId(
            controlData, updateResult.collecteId!);
        // 🔄 FORCER LA MISE À JOUR IMMÉDIATE DE L'INTERFACE
        _forceInterfaceUpdate(
            updateResult.collecteId!, controlData.containerCode);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la mise à jour de la collecte: $e');
      }
    }
  }

  /// Détecte le type de collecte en recherchant RÉELLEMENT dans la base de données
  Future<String> _detectCollectionTypeFromDatabase(
      QualityControlData controlData, String siteUtilisateur) async {
    final containerCode = controlData.containerCode;

    if (kDebugMode) {
      print('🔍 ===== DÉTECTION TYPE PAR ID CONTENANT =====');
      print('🔍 Producteur/Collecteur: "${controlData.producer}"');
      print('🔍 Contenant: $containerCode');
      print('🔍 Date: ${controlData.receptionDate}');
      print('🔍 Site: $siteUtilisateur');
      print('🔍 ==========================================');
    }

    // 🆕 NOUVEAU SYSTÈME: Détection par suffixe de l'ID
    if (containerCode.contains('_')) {
      final parts = containerCode.split('_');
      if (parts.length >= 2) {
        final suffix = parts[1].toLowerCase();

        if (kDebugMode) {
          print('🔍 🎯 SUFFIXE DÉTECTÉ: "$suffix"');
        }

        switch (suffix) {
          case 'recolte':
          case 'recoltes':
            if (kDebugMode) print('🔍 ✅ TYPE: RÉCOLTES (par suffixe)');
            return 'recoltes';
          case 'scoop':
            if (kDebugMode) print('🔍 ✅ TYPE: SCOOP (par suffixe)');
            return 'scoop';
          case 'individuel':
          case 'individuels':
            if (kDebugMode) print('🔍 ✅ TYPE: INDIVIDUELS (par suffixe)');
            return 'individuels';
          default:
            if (kDebugMode) print('🔍 ⚠️ Suffixe "$suffix" non reconnu');
        }
      }
    }

    // 🔄 FALLBACK: Recherche en base de données (ancien système)
    if (kDebugMode) {
      print('🔍 ⚠️ Pas de suffixe reconnu, recherche en BDD...');
    }

    // Période de recherche élargie (7 jours)
    final searchDate = controlData.receptionDate;
    final startDate =
        DateTime(searchDate.year, searchDate.month, searchDate.day)
            .subtract(const Duration(days: 3));
    final endDate = DateTime(searchDate.year, searchDate.month, searchDate.day)
        .add(const Duration(days: 4));

    if (kDebugMode) {
      print(
          '🔍 Période de recherche: ${startDate.toLocal()} → ${endDate.toLocal()}');
    }

    // ÉTAPE 1: Rechercher dans RÉCOLTES
    try {
      if (kDebugMode) print('🔍 1️⃣ RECHERCHE DANS RÉCOLTES...');

      final recolteSnapshot = await FirebaseFirestore.instance
          .collection('Sites')
          .doc(siteUtilisateur)
          .collection('nos_collectes_recoltes')
          .where('created_at',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      for (final doc in recolteSnapshot.docs) {
        final data = doc.data();
        final List<dynamic> contenants = data['contenants'] ?? [];

        for (int i = 0; i < contenants.length; i++) {
          // Vérifier les deux formats: nouveau (avec suffixe) et ancien (sans suffixe)
          final containerIdOld = 'C${(i + 1).toString().padLeft(3, '0')}';
          final containerIdNew =
              'C${(i + 1).toString().padLeft(3, '0')}_recolte';

          if (containerCode == containerIdOld ||
              containerCode == containerIdNew) {
            if (kDebugMode) {
              print('🔍 ✅ TROUVÉ DANS RÉCOLTES: ${doc.id}');
              print('🔍    Contenant: $containerCode (index $i)');
            }
            return 'recoltes';
          }
        }
      }
      if (kDebugMode) print('🔍 ❌ Pas trouvé dans récoltes');
    } catch (e) {
      if (kDebugMode) print('🔍 ❌ Erreur recherche récoltes: $e');
    }

    // ÉTAPE 2: Rechercher dans SCOOP
    try {
      if (kDebugMode) print('🔍 2️⃣ RECHERCHE DANS SCOOP...');

      final scoopSnapshot = await FirebaseFirestore.instance
          .collection('Sites')
          .doc(siteUtilisateur)
          .collection('nos_achats_scoop_contenants')
          .where('created_at',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      for (final doc in scoopSnapshot.docs) {
        final data = doc.data();
        final List<dynamic> contenants = data['contenants'] ?? [];

        for (int i = 0; i < contenants.length; i++) {
          // Vérifier les deux formats: nouveau (avec suffixe) et ancien (sans suffixe)
          final containerIdOld = 'C${(i + 1).toString().padLeft(3, '0')}';
          final containerIdNew = 'C${(i + 1).toString().padLeft(3, '0')}_scoop';

          if (containerCode == containerIdOld ||
              containerCode == containerIdNew) {
            if (kDebugMode) {
              print('🔍 ✅ TROUVÉ DANS SCOOP: ${doc.id}');
              print('🔍    SCOOP: ${data['scoop_nom'] ?? 'N/A'}');
              print('🔍    Collecteur: ${data['collecteur_nom'] ?? 'N/A'}');
              print('🔍    Contenant: $containerCode (index $i)');
            }
            return 'scoop';
          }
        }
      }
      if (kDebugMode) print('🔍 ❌ Pas trouvé dans SCOOP');
    } catch (e) {
      if (kDebugMode) print('🔍 ❌ Erreur recherche SCOOP: $e');
    }

    // ÉTAPE 3: Rechercher dans INDIVIDUELS
    try {
      if (kDebugMode) print('🔍 3️⃣ RECHERCHE DANS INDIVIDUELS...');

      final individuelSnapshot = await FirebaseFirestore.instance
          .collection('Sites')
          .doc(siteUtilisateur)
          .collection('nos_achats_individuels')
          .where('created_at',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      for (final doc in individuelSnapshot.docs) {
        final data = doc.data();
        final List<dynamic> contenants = data['contenants'] ?? [];

        for (int i = 0; i < contenants.length; i++) {
          // Vérifier les deux formats: nouveau (avec suffixe) et ancien (sans suffixe)
          final containerIdOld = 'C${(i + 1).toString().padLeft(3, '0')}';
          final containerIdNew =
              'C${(i + 1).toString().padLeft(3, '0')}_individuel';

          if (containerCode == containerIdOld ||
              containerCode == containerIdNew) {
            if (kDebugMode) {
              print('🔍 ✅ TROUVÉ DANS INDIVIDUELS: ${doc.id}');
              print('🔍    Producteur: ${data['producteur_nom'] ?? 'N/A'}');
              print('🔍    Contenant: $containerCode (index $i)');
            }
            return 'individuels';
          }
        }
      }
      if (kDebugMode) print('🔍 ❌ Pas trouvé dans individuels');
    } catch (e) {
      if (kDebugMode) print('🔍 ❌ Erreur recherche individuels: $e');
    }

    // FALLBACK: Si rien trouvé, utiliser l'ancienne méthode
    if (kDebugMode) {
      print('🔍 ⚠️ AUCUNE CORRESPONDANCE TROUVÉE EN BDD');
      print('🔍 🔄 Fallback vers détection par nom...');
    }

    return _detectCollectionTypeImproved(controlData);
  }

  /// Détecte le type de collecte basé sur toutes les données disponibles (ULTRA-FIABLE)
  String _detectCollectionTypeImproved(QualityControlData controlData) {
    final producer = controlData.producer;
    final apiaryVillage = controlData.apiaryVillage;
    final containerCode = controlData.containerCode;
    final floralPredominance = controlData.floralPredominance;
    final quality = controlData.quality;

    if (kDebugMode) {
      print('🔍 ===== DÉTECTION TYPE COLLECTE ULTRA-FIABLE =====');
      print('🔍 Producteur/Collecteur: "$producer"');
      print('🔍 Village rucher: "$apiaryVillage"');
      print('🔍 Code contenant: "$containerCode"');
      print('🔍 Prédominance florale: "$floralPredominance"');
      print('🔍 Qualité: "$quality"');
      print('🔍 Date réception: ${controlData.receptionDate}');
      print('🔍 ================================================');
    }

    final producerLower = producer.toLowerCase();
    final apiaryVillageLower = apiaryVillage.toLowerCase();
    final floralLower = floralPredominance.toLowerCase();
    final qualityLower = quality.toLowerCase();

    int scoopScore = 0;
    int recolteScore = 0;
    int individuelScore = 0;

    // === SYSTÈME DE SCORING MULTI-CRITÈRES ===

    // 1. ANALYSE DU PRODUCTEUR/COLLECTEUR
    if (kDebugMode) print('🔍 1️⃣ ANALYSE DU PRODUCTEUR...');

    // Indicateurs SCOOP forts
    final scoopKeywords = [
      'scoop',
      'coopérative',
      'cooperative',
      'coop',
      'groupement',
      'union',
      'doup',
      'kabore',
      'maham',
      'président',
      'rucher',
      'société',
      'association'
    ];

    for (final keyword in scoopKeywords) {
      if (producerLower.contains(keyword)) {
        scoopScore += 10;
        if (kDebugMode)
          print('🔍   ✅ SCOOP: "$keyword" trouvé (+10) → Score: $scoopScore');
      }
    }

    // Indicateurs INDIVIDUELS forts
    final individuelKeywords = [
      'miellerie',
      'mielleur',
      'producteur individuel',
      'individuel',
      'entreprise'
    ];

    for (final keyword in individuelKeywords) {
      if (producerLower.contains(keyword)) {
        individuelScore += 10;
        if (kDebugMode)
          print(
              '🔍   ✅ INDIVIDUEL: "$keyword" trouvé (+10) → Score: $individuelScore');
      }
    }

    // Indicateurs RÉCOLTES (noms propres d'apiculteurs)
    if (producerLower.contains(' ') && producerLower.split(' ').length >= 2) {
      // Pattern nom + prénom typique d'apiculteurs
      final words = producerLower.split(' ');
      bool hasTypicalName = false;

      // Noms/prénoms burkinabé typiques
      final burkinabeNames = [
        'abdoulaye',
        'aminata',
        'boureima',
        'mariam',
        'ibrahim',
        'fatimata',
        'seydou',
        'aicha',
        'ousmane',
        'kadiatou',
        'moussa',
        'fatoumata',
        'clément',
        'yameogo',
        'ouédraogo',
        'kaboré',
        'sawadogo',
        'compaoré',
        'diallo',
        'sankara',
        'zongo',
        'traoré'
      ];

      for (final word in words) {
        if (burkinabeNames
            .any((name) => word.contains(name) || name.contains(word))) {
          hasTypicalName = true;
          break;
        }
      }

      if (hasTypicalName || words.length >= 3) {
        recolteScore += 8;
        if (kDebugMode)
          print(
              '🔍   ✅ RÉCOLTE: Nom propre d\'apiculteur détecté (+8) → Score: $recolteScore');
      }
    }

    // 2. ANALYSE DU VILLAGE/LOCALISATION
    if (kDebugMode) print('🔍 2️⃣ ANALYSE DU VILLAGE...');

    // Villages/zones associés aux SCOOP
    final scoopZones = ['dassa', 'sanguie', 'centre-ouest', 'rucher', 'zone'];
    for (final zone in scoopZones) {
      if (apiaryVillageLower.contains(zone)) {
        scoopScore += 3;
        if (kDebugMode)
          print(
              '🔍   ✅ SCOOP: Zone "$zone" détectée (+3) → Score: $scoopScore');
      }
    }

    // 3. ANALYSE DE LA QUALITÉ/PRÉDOMINANCE
    if (kDebugMode) print('🔍 3️⃣ ANALYSE QUALITÉ & FLORALE...');

    // Qualités typiques des SCOOP (production organisée)
    final scoopQualities = ['excellent', 'très bon', 'standardisé', 'certifié'];
    for (final qual in scoopQualities) {
      if (qualityLower.contains(qual)) {
        scoopScore += 2;
        if (kDebugMode)
          print('🔍   ✅ SCOOP: Qualité "$qual" (+2) → Score: $scoopScore');
      }
    }

    // Prédominances typiques des récoltes individuelles
    final recolteFlowers = ['karité', 'néré', 'acacia', 'moringa'];
    for (final flower in recolteFlowers) {
      if (floralLower.contains(flower)) {
        recolteScore += 2;
        if (kDebugMode)
          print(
              '🔍   ✅ RÉCOLTE: Florale "$flower" (+2) → Score: $recolteScore');
      }
    }

    // 4. ANALYSE TEMPORELLE (heure de contrôle)
    if (kDebugMode) print('🔍 4️⃣ ANALYSE TEMPORELLE...');

    final hour = controlData.receptionDate.hour;
    if (hour >= 8 && hour <= 16) {
      // Heures de travail → plus probable pour SCOOP (collecte organisée)
      scoopScore += 1;
      if (kDebugMode)
        print(
            '🔍   ✅ SCOOP: Heure professionnelle ($hour h) (+1) → Score: $scoopScore');
    } else {
      // Hors heures → plus probable pour récolte individuelle
      recolteScore += 1;
      if (kDebugMode)
        print(
            '🔍   ✅ RÉCOLTE: Heure individuelle ($hour h) (+1) → Score: $recolteScore');
    }

    // === DÉCISION FINALE BASÉE SUR LES SCORES ===
    if (kDebugMode) {
      print('🔍 ===== SCORES FINAUX =====');
      print('🔍 🥄 SCOOP: $scoopScore points');
      print('🔍 🏭 RÉCOLTE: $recolteScore points');
      print('🔍 👤 INDIVIDUEL: $individuelScore points');
      print('🔍 ==========================');
    }

    // Seuil minimum pour une décision fiable
    final maxScore = [scoopScore, recolteScore, individuelScore]
        .reduce((a, b) => a > b ? a : b);

    if (maxScore >= 5) {
      // Seuil de confiance
      if (scoopScore == maxScore) {
        if (kDebugMode)
          print('🔍 🎯 DÉCISION: SCOOP (score: $scoopScore - confiance haute)');
        return 'scoop';
      } else if (individuelScore == maxScore) {
        if (kDebugMode)
          print(
              '🔍 🎯 DÉCISION: INDIVIDUELS (score: $individuelScore - confiance haute)');
        return 'individuels';
      } else {
        if (kDebugMode)
          print(
              '🔍 🎯 DÉCISION: RÉCOLTES (score: $recolteScore - confiance haute)');
        return 'recoltes';
      }
    }

    // Si scores faibles, utiliser logique contextuelle simple
    if (kDebugMode) {
      print('🔍 ⚠️ Scores faibles, analyse contextuelle simple...');
    }

    // Si le nom ressemble à un nom propre, c'est probablement une récolte
    if (producerLower.contains(' ') && producerLower.split(' ').length >= 2) {
      if (kDebugMode) {
        print('🔍 🎯 DÉCISION: RÉCOLTES (nom propre - confiance moyenne)');
      }
      return 'recoltes';
    }

    // Fallback vers méthode originale
    if (kDebugMode) {
      print('🔍 ⚠️ FALLBACK vers méthode simple...');
    }
    return _detectCollectionType(producer);
  }

  /// Détecte le type de collecte basé sur le producteur (MÉTHODE ORIGINALE)
  String _detectCollectionType(String producer) {
    final producerLower = producer.toLowerCase();

    if (kDebugMode) {
      print('🔍 === DÉTECTION TYPE COLLECTE ===');
      print('🔍 Producteur/Collecteur: "$producer"');
      print('🔍 Producteur lowercase: "$producerLower"');
    }

    // 1. Vérification SCOOP (recherche élargie)
    if (producerLower.contains('scoop') ||
        producerLower.contains('coopérative') ||
        producerLower.contains('cooperative') ||
        producerLower.contains('coop') ||
        producerLower.contains('groupement') ||
        producerLower.contains('union') ||
        producerLower.contains('doup') || // Nom fréquent dans les SCOOPs
        producerLower.contains('kabore') || // Président fréquent
        producerLower.contains('maham')) {
      // Nom SCOOP fréquent
      if (kDebugMode) print('📍 ✅ Type détecté: SCOOP (mots-clés trouvés)');
      return 'scoop';
    }

    // 2. Vérification INDIVIDUELS
    if (producerLower.contains('miellerie') ||
        producerLower.contains('mielleur') ||
        producerLower.contains('producteur individuel') ||
        producerLower.contains('individuel')) {
      if (kDebugMode) print('📍 ✅ Type détecté: INDIVIDUELS');
      return 'individuels';
    }

    // 3. Par défaut: RÉCOLTES (plus fréquent que SCOOP dans la plupart des cas)
    // Si aucun mot-clé spécifique, c'est probablement une récolte d'apiculteur
    if (kDebugMode) {
      print('📍 ⚠️ Aucun mot-clé spécifique trouvé');
      print(
          '📍 🏭 Type détecté: RÉCOLTES (défaut - producteur individuel probable)');
    }
    return 'recoltes'; // Retour au défaut RÉCOLTES
  }

  /// Met à jour un type spécifique de collecte
  Future<CollecteUpdateResult> _updateSpecificCollectionType({
    required String collectionType,
    required String siteUtilisateur,
    required QualityControlData controlData,
    required Map<String, dynamic> controlInfo,
  }) async {
    try {
      final Map<String, dynamic> collectionConfig =
          _getCollectionConfig(collectionType, siteUtilisateur);

      if (kDebugMode) {
        print('🎯 Mise à jour type: $collectionType');
        print('📁 Chemin: ${collectionConfig['path']}');
      }

      // Chercher dans une plage de dates plus large (7 derniers jours)
      final dateRecherche = controlData.receptionDate;
      final dateDebut = DateTime(
        dateRecherche.year,
        dateRecherche.month,
        dateRecherche.day - 7, // 7 jours avant
      );
      final dateFin = DateTime(
        dateRecherche.year,
        dateRecherche.month,
        dateRecherche.day + 1, // Jour suivant
      );

      if (kDebugMode) {
        print('🔍 Recherche élargie:');
        print('🔍   Date contrôle: $dateRecherche');
        print('🔍   Période recherche: $dateDebut → $dateFin');
      }

      final querySnapshot = await _firestore
          .collection(collectionConfig['collection1'])
          .doc(collectionConfig['doc'])
          .collection(collectionConfig['collection2'])
          .where(collectionConfig['dateField'],
              isGreaterThanOrEqualTo: Timestamp.fromDate(dateDebut))
          .where(collectionConfig['dateField'],
              isLessThan: Timestamp.fromDate(dateFin))
          .get();

      if (kDebugMode) {
        print('📊 Nombre de documents trouvés: ${querySnapshot.docs.length}');
      }

      if (kDebugMode && querySnapshot.docs.isNotEmpty) {
        print('📋 Documents trouvés dans la période:');
        for (final doc in querySnapshot.docs) {
          final data = doc.data();
          final docDate = data[collectionConfig['dateField']];
          print('📋   - ${doc.id}: date = $docDate');
        }
      }

      for (final doc in querySnapshot.docs) {
        final bool updated = await _updateContainerInDocument(
          doc: doc,
          controlData: controlData,
          controlInfo: controlInfo,
          collectionType: collectionType,
        );

        if (updated) {
          if (kDebugMode) {
            print('🎉 SUCCÈS MISE À JOUR dans ${doc.id}');
          }
          return CollecteUpdateResult.success(
            collecteId: doc.id,
            collectionPath: collectionConfig['path'],
          );
        }
      }

      return CollecteUpdateResult.failure();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur pour type $collectionType: $e');
      }
      return CollecteUpdateResult.failure();
    }
  }

  /// Configure les chemins pour chaque type de collecte
  Map<String, dynamic> _getCollectionConfig(String type, String site) {
    switch (type) {
      case 'recoltes':
        return {
          'collection1': 'Sites',
          'doc': site,
          'collection2': 'nos_collectes_recoltes',
          'dateField': 'createdAt',
          'path': 'Sites/$site/nos_collectes_recoltes'
        };
      case 'scoop':
        return {
          'collection1': 'Sites',
          'doc': site,
          'collection2': 'nos_achats_scoop_contenants',
          'dateField': 'created_at',
          'path': 'Sites/$site/nos_achats_scoop_contenants'
        };
      case 'individuels':
        return {
          'collection1': 'Sites',
          'doc': site,
          'collection2': 'nos_achats_individuels',
          'dateField': 'created_at',
          'path': 'Sites/$site/nos_achats_individuels'
        };
      default:
        return _getCollectionConfig('recoltes', site);
    }
  }

  /// Met à jour le contenant dans un document spécifique
  Future<bool> _updateContainerInDocument({
    required QueryDocumentSnapshot doc,
    required QualityControlData controlData,
    required Map<String, dynamic> controlInfo,
    required String collectionType,
  }) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final contenants = data['contenants'] as List<dynamic>?;

      if (contenants == null) {
        if (kDebugMode) {
          print('⚠️ Aucun contenant dans le document ${doc.id}');
        }
        return false;
      }

      if (kDebugMode) {
        print(
            '🔍 Recherche dans document ${doc.id} (${contenants.length} contenants)');
        print('🔍 Cherche contenant: ${controlData.containerCode}');
        print('🔍 Producteur contrôle: ${controlData.producer}');
      }

      for (int i = 0; i < contenants.length; i++) {
        final contenant = contenants[i] as Map<String, dynamic>;

        // 🆕 RECHERCHE PAR ID RÉEL STOCKÉ EN BASE (pas par index)
        final contenantId = contenant['id']?.toString() ??
            'C${(i + 1).toString().padLeft(3, '0')}'; // Fallback pour anciens contenants

        if (kDebugMode) {
          print('🔍   Contenant ${i + 1}: ID = $contenantId');
        }

        if (contenantId == controlData.containerCode) {
          if (kDebugMode) {
            print('✅ MATCH TROUVÉ - Contenant $contenantId correspond !');
          }
          contenants[i]['controlInfo'] = controlInfo;

          await doc.reference.update({
            'contenants': contenants,
            'derniereMiseAJour': FieldValue.serverTimestamp(),
          });

          if (kDebugMode) {
            print('✅ SUCCÈS - Collecte mise à jour !');
            print('📄 Document: ${doc.id}');
            print('📦 Contenant: $contenantId (index $i)');
            print('🏷️ Type: $collectionType');
            print('📁 Chemin: ${doc.reference.path}');
          }

          return true;
        }
      }

      if (kDebugMode) {
        print(
            '⚠️ Contenant ${controlData.containerCode} non trouvé dans ${doc.id}');
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur mise à jour document ${doc.id}: $e');
      }
      return false;
    }
  }

  /// Fallback: essaie tous les types de collecte (ordre de priorité logique)
  Future<CollecteUpdateResult> _updateAllCollectionTypes(
    String siteUtilisateur,
    QualityControlData controlData,
    Map<String, dynamic> controlInfo,
  ) async {
    // Ordre de priorité: récoltes (plus fréquent), puis SCOOP, puis individuels
    final types = ['recoltes', 'scoop', 'individuels'];

    if (kDebugMode) {
      print('🔄 FALLBACK: Essai de tous les types...');
    }

    for (final type in types) {
      if (kDebugMode) {
        print('🔍 Essai du type: $type');
      }

      final result = await _updateSpecificCollectionType(
        collectionType: type,
        siteUtilisateur: siteUtilisateur,
        controlData: controlData,
        controlInfo: controlInfo,
      );

      if (result.success) {
        if (kDebugMode) {
          print('✅ FALLBACK RÉUSSI avec type: $type');
        }
        return result;
      }
    }

    if (kDebugMode) {
      print(
          '❌ ÉCHEC TOTAL - Aucune collecte trouvée pour ${controlData.containerCode}');
      print('📅 Date recherchée: ${controlData.receptionDate}');
      print('🏢 Site: $siteUtilisateur');
    }

    return CollecteUpdateResult.failure();
  }

  /// Met à jour le contrôle qualité avec l'ID de collecte d'origine
  Future<void> _updateQualityControlWithCollecteId(
    QualityControlData controlData,
    String collecteId,
  ) async {
    try {
      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';
      final docId =
          '${_cleanContainerCode(controlData.containerCode)}_${controlData.receptionDate.millisecondsSinceEpoch}';

      await _firestore
          .collection('controles_qualite')
          .doc(siteUtilisateur)
          .collection('controles')
          .doc(docId)
          .update({
        'collecteId': collecteId,
        'derniereMiseAJour': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ Contrôle qualité mis à jour avec collecteId: $collecteId');
        print('📦 Contenant: ${controlData.containerCode}');
        print('🔗 Lien établi avec la collecte d\'origine');
      }

      // Invalider le cache pour cette collecte
      invalidateCollecteCache(collecteId);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la mise à jour du collecteId: $e');
      }
    }
  }

  /// Récupère tous les contrôles qualité pour une collecte spécifique
  Future<List<QualityControlData>> getQualityControlsForCollecte(
      String collecteId) async {
    try {
      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';

      final querySnapshot = await _firestore
          .collection('controles_qualite')
          .doc(siteUtilisateur)
          .collection('controles')
          .where('collecteId', isEqualTo: collecteId)
          .get();

      final controls = <QualityControlData>[];
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final control = QualityControlData.fromFirestore(data);
        controls.add(control);
      }

      if (kDebugMode) {
        print(
            '📊 Récupéré ${controls.length} contrôles pour collecte $collecteId');
      }

      return controls;
    } catch (e) {
      if (kDebugMode) {
        print(
            '❌ Erreur lors de la récupération des contrôles pour collecte $collecteId: $e');
      }
      return [];
    }
  }

  /// Met à jour les champs d'attribution d'un contrôle qualité
  Future<void> updateQualityControlAttribution(
    String containerCode,
    DateTime receptionDate,
    String attributionId,
    String typeAttribution,
    DateTime dateAttribution,
  ) async {
    try {
      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';
      final docId =
          '${_cleanContainerCode(containerCode)}_${receptionDate.millisecondsSinceEpoch}';

      debugPrint('🔄 ===== DÉBUT MISE À JOUR CONTRÔLE QUALITÉ =====');
      debugPrint('   📦 Container Code: $containerCode');
      debugPrint(
          '   📦 Container Code nettoyé: ${_cleanContainerCode(containerCode)}');
      debugPrint('   📅 Reception Date: $receptionDate');
      debugPrint(
          '   📅 Reception Date milliseconds: ${receptionDate.millisecondsSinceEpoch}');
      debugPrint('   🆔 Doc ID: $docId');
      debugPrint('   🏭 Site Utilisateur: $siteUtilisateur');
      debugPrint('   🎯 Attribution ID: $attributionId');
      debugPrint('   🏭 Type Attribution: $typeAttribution');
      debugPrint('   📅 Date Attribution: $dateAttribution');

      final docPath = 'controles_qualite/$siteUtilisateur/controles/$docId';
      debugPrint('   📂 Document Path: $docPath');

      // Vérifier si le document existe avant de le mettre à jour
      final docRef = _firestore
          .collection('controles_qualite')
          .doc(siteUtilisateur)
          .collection('controles')
          .doc(docId);

      final docSnapshot = await docRef.get();
      debugPrint('   📄 Document existe: ${docSnapshot.exists}');

      if (!docSnapshot.exists) {
        debugPrint('   ❌ ERREUR: Document n\'existe pas! Chemin: $docPath');
        throw Exception('Document de contrôle qualité non trouvé: $docPath');
      }

      final updateData = {
        'estAttribue': true,
        'attributionId': attributionId,
        'typeAttribution': typeAttribution,
        'dateAttribution': Timestamp.fromDate(dateAttribution),
        'derniereMiseAJour': FieldValue.serverTimestamp(),
      };

      debugPrint('   📝 Données de mise à jour: $updateData');
      debugPrint('   🚀 Lancement de la mise à jour Firestore...');

      await docRef.update(updateData);

      debugPrint('   ✅ Mise à jour Firestore RÉUSSIE');

      // Mettre à jour le cache local si disponible
      if (_qualityControlsCache.containsKey(docId)) {
        debugPrint('   🔄 Mise à jour du cache local...');
        final cachedControl = _qualityControlsCache[docId]!;
        _qualityControlsCache[docId] = cachedControl.copyWith(
          estAttribue: true,
          attributionId: attributionId,
          typeAttribution: typeAttribution,
          dateAttribution: dateAttribution,
        );
        debugPrint('   ✅ Cache local mis à jour');
      } else {
        debugPrint('   ⚠️ Pas de cache local pour ce document');
      }

      debugPrint('✅ ===== CONTRÔLE QUALITÉ ATTRIBUÉ AVEC SUCCÈS =====');
      debugPrint('   📦 Container: $containerCode');
      debugPrint('   🆔 Attribution: $attributionId');
      debugPrint('   🏭 Type: $typeAttribution');
    } catch (e, stackTrace) {
      debugPrint('❌ ===== ERREUR MISE À JOUR CONTRÔLE QUALITÉ =====');
      debugPrint('   📦 Container: $containerCode');
      debugPrint('   ❌ Erreur: $e');
      debugPrint('   ❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// 🆕 VERSION CORRIGÉE : Met à jour l'attribution avec le controlId existant
  Future<void> updateQualityControlAttributionByControlId(
    String controlId,
    String attributionId,
    String typeAttribution,
    DateTime dateAttribution,
  ) async {
    try {
      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';

      debugPrint('🔄 ===== DÉBUT MISE À JOUR CONTRÔLE (PAR CONTROL ID) =====');
      debugPrint('   🆔 Control ID: $controlId');
      debugPrint('   🏭 Site Utilisateur: $siteUtilisateur');
      debugPrint('   🎯 Attribution ID: $attributionId');
      debugPrint('   🏭 Type Attribution: $typeAttribution');
      debugPrint('   📅 Date Attribution: $dateAttribution');

      final docPath = 'controles_qualite/$siteUtilisateur/controles/$controlId';
      debugPrint('   📂 Document Path: $docPath');

      // Référence directe au document avec le controlId
      final docRef = _firestore
          .collection('controles_qualite')
          .doc(siteUtilisateur)
          .collection('controles')
          .doc(controlId);

      final docSnapshot = await docRef.get();
      debugPrint('   📄 Document existe: ${docSnapshot.exists}');

      if (!docSnapshot.exists) {
        debugPrint('   ❌ ERREUR: Document n\'existe pas! Chemin: $docPath');
        throw Exception('Document de contrôle qualité non trouvé: $docPath');
      }

      final updateData = {
        'estAttribue': true,
        'attributionId': attributionId,
        'typeAttribution': typeAttribution,
        'dateAttribution': Timestamp.fromDate(dateAttribution),
        'derniereMiseAJour': FieldValue.serverTimestamp(),
      };

      debugPrint('   📝 Données de mise à jour: $updateData');
      debugPrint('   🚀 Lancement de la mise à jour Firestore...');

      await docRef.update(updateData);

      debugPrint('   ✅ Mise à jour Firestore RÉUSSIE');

      // Mettre à jour le cache local si disponible
      if (_qualityControlsCache.containsKey(controlId)) {
        debugPrint('   🔄 Mise à jour du cache local...');
        final cachedControl = _qualityControlsCache[controlId]!;
        _qualityControlsCache[controlId] = cachedControl.copyWith(
          estAttribue: true,
          attributionId: attributionId,
          typeAttribution: typeAttribution,
          dateAttribution: dateAttribution,
        );
        debugPrint('   ✅ Cache local mis à jour');
      } else {
        debugPrint('   ⚠️ Pas de cache local pour ce document');
      }

      debugPrint(
          '✅ ===== CONTRÔLE QUALITÉ ATTRIBUÉ AVEC SUCCÈS (CONTROL ID) =====');
      debugPrint('   🆔 Control ID: $controlId');
      debugPrint('   🎯 Attribution: $attributionId');
      debugPrint('   🏭 Type: $typeAttribution');
    } catch (e, stackTrace) {
      debugPrint(
          '❌ ===== ERREUR MISE À JOUR CONTRÔLE QUALITÉ (CONTROL ID) =====');
      debugPrint('   🆔 Control ID: $controlId');
      debugPrint('   ❌ Erreur: $e');
      debugPrint('   ❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Récupère l'état de contrôle optimisé pour une collecte avec cache
  Future<Map<String, dynamic>> getOptimizedControlStatusForCollecte(
      String collecteId) async {
    try {
      // Vérifier le cache (valide pendant 5 minutes)
      final cacheKey = collecteId;
      final cachedTimestamp = _cacheTimestamps[cacheKey];
      final now = DateTime.now();

      if (cachedTimestamp != null &&
          now.difference(cachedTimestamp).inMinutes < 5 &&
          _collecteControlStatsCache.containsKey(cacheKey)) {
        if (kDebugMode) {
          print('📦 Cache hit pour collecte $collecteId');
        }
        return _collecteControlStatsCache[cacheKey]!;
      }

      // Cache manqué ou expiré, charger depuis Firestore
      if (kDebugMode) {
        print(
            '🔄 Cache miss pour collecte $collecteId, chargement depuis Firestore');
      }

      final controls = await getQualityControlsForCollecte(collecteId);

      final Map<String, QualityControlData> controlsByContainer = {};
      for (final control in controls) {
        controlsByContainer[control.containerCode] = control;
      }

      final stats = {
        'totalControls': controls.length,
        'controlsByContainer': controlsByContainer,
        'conformeCount': controls
            .where((c) => c.conformityStatus == ConformityStatus.conforme)
            .length,
        'nonConformeCount': controls
            .where((c) => c.conformityStatus == ConformityStatus.nonConforme)
            .length,
        'lastUpdated': now.toIso8601String(),
      };

      // Mettre en cache
      _collecteControlStatsCache[cacheKey] = stats;
      _cacheTimestamps[cacheKey] = now;

      if (kDebugMode) {
        print('📊 Statistiques optimisées pour collecte $collecteId:');
        print('   - Total contrôles: ${stats['totalControls']}');
        print('   - Conformes: ${stats['conformeCount']}');
        print('   - Non-conformes: ${stats['nonConformeCount']}');
        print('💾 Mise en cache pour 5 minutes');
      }

      return stats;
    } catch (e) {
      if (kDebugMode) {
        print(
            '❌ Erreur lors du calcul des statistiques pour collecte $collecteId: $e');
      }
      return {};
    }
  }

  /// Invalide le cache pour une collecte spécifique
  void invalidateCollecteCache(String collecteId) {
    _collecteControlStatsCache.remove(collecteId);
    _cacheTimestamps.remove(collecteId);

    if (kDebugMode) {
      print('🗑️ Cache invalidé pour collecte $collecteId');
    }
  }

  /// Invalide tout le cache
  void invalidateAllCache() {
    _collecteControlStatsCache.clear();
    _cacheTimestamps.clear();

    if (kDebugMode) {
      print('🗑️ Tout le cache invalidé');
    }
  }

  /// Invalide tous les caches liés à un contenant
  void _invalidateAllRelatedCaches(String containerCode) {
    if (kDebugMode) {
      print(
          '🗑️ Invalidation de tous les caches pour contenant: $containerCode');
    }

    // Invalider tout le cache car on ne connaît pas encore l'ID de collecte
    invalidateAllCache();

    if (kDebugMode) {
      print('💾 Tous les caches invalidés pour forcer le refresh');
    }
  }

  /// Force la mise à jour immédiate de l'interface
  void _forceInterfaceUpdate(String collecteId, String containerCode) {
    if (kDebugMode) {
      print('🔄 FORCE INTERFACE UPDATE');
      print('📋 CollecteId: $collecteId');
      print('📦 ContainerCode: $containerCode');
    }

    // 1. Invalider le cache immédiatement
    invalidateCollecteCache(collecteId);

    // 2. Envoyer une notification spécifique avec l'ID de collecte
    GlobalRefreshService()
        .notifyQualityControlUpdate('$collecteId:$containerCode');

    // 3. Envoyer aussi la notification générale
    GlobalRefreshService().notifyCollecteUpdate(collecteId);

    // 4. Notifier les listeners des changements locaux
    _notifyListeners();

    if (kDebugMode) {
      print('✅ Interface forcée à se mettre à jour');
      print('🔔 Notifications envoyées');
      print('💾 Cache invalidé');
    }
  }

  /// MÉTHODE DE TEST: Simule la mise à jour en temps réel
  Future<void> debugTestLiveUpdate(
      String collecteId, String containerCode) async {
    if (!kDebugMode) return;

    print('🧪 TEST LIVE UPDATE');
    print('📋 CollecteId: $collecteId');
    print('📦 ContainerCode: $containerCode');

    // 1. Vérifier l'état du cache avant
    final statsBefore = _collecteControlStatsCache[collecteId];
    print('💾 Cache avant: ${statsBefore != null ? 'EXISTS' : 'EMPTY'}');

    // 2. Invalider le cache
    invalidateCollecteCache(collecteId);
    print('🗑️ Cache invalidé');

    // 3. Envoyer les notifications
    GlobalRefreshService()
        .notifyQualityControlUpdate('$collecteId:$containerCode');
    GlobalRefreshService().notifyCollecteUpdate(collecteId);
    print('🔔 Notifications envoyées');

    // 4. Recharger les stats
    final statsAfter = await getOptimizedControlStatusForCollecte(collecteId);
    print('📊 Stats après: ${statsAfter['totalControls']} contrôles');

    print('✅ Test terminé');
  }

  /// Dispose les streams
  void dispose() {
    _controlsStreamController.close();
    _statsStreamController.close();
  }

  /// Recharge toutes les données depuis Firestore et met à jour les streams
  Future<void> refreshAllData() async {
    try {
      if (kDebugMode) {
        print(
            '🧹 QUALITY: Nettoyage complet du cache (${_qualityControlsCache.length} entrées supprimées)');
      }

      // Vider complètement tous les caches
      _qualityControlsCache.clear();
      _collecteControlStatsCache.clear();
      _cacheTimestamps.clear();

      if (kDebugMode) {
        print('📡 QUALITY: Rechargement depuis Firestore...');
      }

      final controls = await getAllQualityControlsFromFirestore();

      // Vider le cache et le remplir avec les nouvelles données
      _qualityControlsCache.clear();
      for (final control in controls) {
        final key =
            '${_cleanContainerCode(control.containerCode)}_${control.receptionDate.millisecondsSinceEpoch}';
        _qualityControlsCache[key] = control;
      }

      // Notifier les listeners
      _notifyListeners();

      if (kDebugMode) {
        print(
            '✅ Données de contrôle qualité rechargées: ${controls.length} contrôles');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors du rechargement des données: $e');
      }
    }
  }

  /// DEBUG: Vérifie l'état des contrôles d'une collecte spécifique
  Future<void> debugCheckCollecteControlStatus(
      String collecteId, String collectionName) async {
    if (!kDebugMode) return;

    try {
      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';

      final doc = await _firestore
          .collection(collectionName)
          .doc(siteUtilisateur)
          .collection('data')
          .doc(collecteId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final contenants = data['contenants'] as List<dynamic>?;

        print('🔍 DEBUG - État de la collecte $collecteId:');
        print('📦 Nombre de contenants: ${contenants?.length ?? 0}');

        if (contenants != null) {
          for (int i = 0; i < contenants.length; i++) {
            final contenant = contenants[i];
            final id =
                contenant['id'] ?? 'C${(i + 1).toString().padLeft(3, '0')}';
            final controlInfo = contenant['controlInfo'];

            if (controlInfo != null) {
              print(
                  '✅ Contenant $id: CONTRÔLÉ - ${controlInfo['conformityStatus']} par ${controlInfo['controllerName']}');
            } else {
              print('❌ Contenant $id: NON CONTRÔLÉ');
            }
          }
        }
      } else {
        print(
            '⚠️ DEBUG: Collecte $collecteId non trouvée dans $collectionName');
      }
    } catch (e) {
      print('❌ DEBUG: Erreur lors de la vérification: $e');
    }
  }

  /// Nettoie et formate un composant d'ID (même logique que UniversalContainerIdService)
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

  ContainerType _resolveContainerType(String rawValue) {
    final lower = rawValue.toLowerCase();
    return ContainerType.values.firstWhere(
      (type) =>
          type.name.toLowerCase() == lower || type.label.toLowerCase() == lower,
      orElse: () => ContainerType.bidon,
    );
  }

  /// Nettoie spécifiquement un code de contenant
  String _cleanContainerCode(String containerCode) {
    // Pour les codes de contenants, on garde une logique similaire mais adaptée
    String cleaned = containerCode
        .trim() // Enlever espaces début/fin
        .toUpperCase() // Mettre en majuscules
        .replaceAll(RegExp(r'[^A-Z0-9_]'),
            ''); // Garder lettres, chiffres et underscore

    // S'assurer qu'il y a au moins un caractère
    if (cleaned.isEmpty) {
      cleaned = 'CONTAINER_INCONNU';
    }

    return cleaned;
  }
}

/// Modèle pour les statistiques de qualité
class QualityStats {
  final int totalControls;
  final int conformeCount;
  final int nonConformeCount;
  final double conformityRate;
  final double averageWaterContent;
  final double totalHoneyWeight;

  const QualityStats({
    required this.totalControls,
    required this.conformeCount,
    required this.nonConformeCount,
    required this.conformityRate,
    required this.averageWaterContent,
    required this.totalHoneyWeight,
  });
}
