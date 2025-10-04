import 'package:cloud_firestore/cloud_firestore.dart';

/// Service pour vérifier si une collecte peut être modifiée ou supprimée
/// basé sur le statut de traitement de ses contenants
class CollecteProtectionService {
  /// Vérifie si une collecte peut être modifiée/supprimée
  /// Retourne false si au moins un contenant a été traité
  static Future<CollecteProtectionStatus> checkCollecteModifiable(
    Map<String, dynamic> collecteData,
  ) async {
    try {
      print('🔒 PROTECTION: Vérification collecte ${collecteData['id']}');

      final String collecteId = collecteData['id']?.toString() ?? '';

      if (collecteId.isEmpty) {
        return CollecteProtectionStatus(
          isModifiable: false,
          reason: 'Données de collecte incomplètes',
          traitedContainers: [],
        );
      }

      print(
          '🔒 PROTECTION: Vérification directe dans les données de la collecte');

      // Vérifier directement dans les données de la collecte
      List<ContainerTraitementInfo> traitedContainers = [];

      // 1. Vérifier les contrôles (dans contenants[].controlInfo)
      final controlledContainers = _checkControlInContainers(collecteData);
      traitedContainers.addAll(controlledContainers);

      // 2. Vérifier les attributions (dans collecteData.attributions)
      final attributedContainers = _checkAttributionsInCollecte(collecteData);
      traitedContainers.addAll(attributedContainers);

      final bool isModifiable = traitedContainers.isEmpty;

      print(
          '🔒 PROTECTION: Collecte ${isModifiable ? "MODIFIABLE" : "PROTÉGÉE"}');
      if (!isModifiable) {
        print(
            '   Contenants traités: ${traitedContainers.map((c) => '${c.containerId} (${c.module})').join(', ')}');
      }

      return CollecteProtectionStatus(
        isModifiable: isModifiable,
        reason: isModifiable
            ? 'Collecte modifiable'
            : 'Certains contenants ont été traités',
        traitedContainers: traitedContainers,
      );
    } catch (e) {
      print('❌ PROTECTION: Erreur vérification: $e');
      return CollecteProtectionStatus(
        isModifiable: false,
        reason: 'Erreur lors de la vérification: $e',
        traitedContainers: [],
      );
    }
  }

  /// Vérifie les contrôles dans les contenants (controlInfo.isControlled = true)
  static List<ContainerTraitementInfo> _checkControlInContainers(
    Map<String, dynamic> collecteData,
  ) {
    final List<ContainerTraitementInfo> controlledContainers = [];

    try {
      // Récupérer les contenants
      final contenants = collecteData['contenants'] as List<dynamic>? ?? [];

      for (var contenant in contenants) {
        if (contenant is Map<String, dynamic>) {
          final String containerId = contenant['id']?.toString() ?? '';
          final controlInfo = contenant['controlInfo'] as Map<String, dynamic>?;

          if (controlInfo != null && containerId.isNotEmpty) {
            final bool isControlled = controlInfo['isControlled'] == true;

            if (isControlled) {
              print('🔍 PROTECTION: Contenant $containerId contrôlé');

              controlledContainers.add(ContainerTraitementInfo(
                containerId: containerId,
                module: 'Contrôle',
                status:
                    controlInfo['conformityStatus']?.toString() ?? 'contrôlé',
                dateTraitement: controlInfo['controlDate'],
                documentId: controlInfo['controlId']?.toString() ?? '',
                details:
                    'Contenant contrôlé par ${controlInfo['controllerName'] ?? 'Contrôleur'}',
              ));
            }
          }
        }
      }

      print(
          '🔍 PROTECTION: ${controlledContainers.length} contenants contrôlés trouvés');
    } catch (e) {
      print('❌ PROTECTION: Erreur vérification contrôles: $e');
    }

    return controlledContainers;
  }

  /// Vérifie les attributions dans la collecte (attributions[])
  static List<ContainerTraitementInfo> _checkAttributionsInCollecte(
    Map<String, dynamic> collecteData,
  ) {
    final List<ContainerTraitementInfo> attributedContainers = [];

    try {
      // Récupérer les attributions
      final attributions = collecteData['attributions'] as List<dynamic>? ?? [];

      for (var attribution in attributions) {
        if (attribution is Map<String, dynamic>) {
          final String attributionId =
              attribution['attributionId']?.toString() ?? '';
          final String typeAttribution =
              attribution['typeAttribution']?.toString() ?? '';
          final String dateAttribution =
              attribution['dateAttribution']?.toString() ?? '';
          final List<dynamic> contenantsAttribues =
              attribution['contenants'] as List<dynamic>? ?? [];

          if (attributionId.isNotEmpty && contenantsAttribues.isNotEmpty) {
            print(
                '🎯 PROTECTION: Attribution trouvée: $typeAttribution avec ${contenantsAttribues.length} contenants');

            for (var containerId in contenantsAttribues) {
              final String containerIdStr = containerId.toString();

              attributedContainers.add(ContainerTraitementInfo(
                containerId: containerIdStr,
                module: _getModuleNameFromAttribution(typeAttribution),
                status: 'attribué',
                dateTraitement: dateAttribution,
                documentId: attributionId,
                details: 'Contenant attribué pour $typeAttribution',
              ));
            }
          }
        }
      }

      print(
          '🎯 PROTECTION: ${attributedContainers.length} contenants attribués trouvés');
    } catch (e) {
      print('❌ PROTECTION: Erreur vérification attributions: $e');
    }

    return attributedContainers;
  }

  /// Convertit le type d'attribution en nom de module
  static String _getModuleNameFromAttribution(String typeAttribution) {
    switch (typeAttribution.toLowerCase()) {
      case 'extraction':
        return 'Extraction';
      case 'filtrage':
        return 'Filtrage';
      case 'conditionnement':
        return 'Conditionnement';
      case 'commercialisation':
      case 'vente':
        return 'Commercialisation';
      default:
        return 'Attribution ($typeAttribution)';
    }
  }
}

/// Statut de protection d'une collecte
class CollecteProtectionStatus {
  final bool isModifiable;
  final String reason;
  final List<ContainerTraitementInfo> traitedContainers;

  CollecteProtectionStatus({
    required this.isModifiable,
    required this.reason,
    required this.traitedContainers,
  });

  /// Obtient un message d'information pour l'utilisateur
  String get userMessage {
    if (isModifiable) {
      return 'Cette collecte peut être modifiée';
    } else {
      final modules = traitedContainers.map((c) => c.module).toSet().join(', ');
      return 'Modification impossible: ${traitedContainers.length} contenant(s) traité(s) dans: $modules';
    }
  }

  /// Obtient une description détaillée
  String get detailedDescription {
    if (isModifiable) {
      return 'Aucun contenant de cette collecte n\'a été traité dans les modules suivants.';
    } else {
      final descriptions = traitedContainers
          .map((c) => '• ${c.containerId}: ${c.details} (${c.module})')
          .join('\n');
      return 'Contenants traités:\n$descriptions';
    }
  }
}

/// Information sur le traitement d'un contenant
class ContainerTraitementInfo {
  final String containerId;
  final String module;
  final String status;
  final dynamic dateTraitement;
  final String documentId;
  final String details;

  ContainerTraitementInfo({
    required this.containerId,
    required this.module,
    required this.status,
    required this.dateTraitement,
    required this.documentId,
    required this.details,
  });

  /// Obtient la date formatée
  String get dateFormatee {
    if (dateTraitement == null) return 'Date inconnue';

    try {
      if (dateTraitement is Timestamp) {
        final date = (dateTraitement as Timestamp).toDate();
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      } else if (dateTraitement is DateTime) {
        final date = dateTraitement as DateTime;
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      } else if (dateTraitement is String) {
        // Format ISO: "2025-09-05T15:01:41.556809"
        final dateStr = dateTraitement as String;
        if (dateStr.contains('T')) {
          final datePart = dateStr.split('T')[0];
          final parts = datePart.split('-');
          if (parts.length == 3) {
            return '${parts[2]}/${parts[1]}/${parts[0]}'; // DD/MM/YYYY
          }
        }
        return dateStr;
      } else {
        return dateTraitement.toString();
      }
    } catch (e) {
      return 'Date invalide';
    }
  }
}
