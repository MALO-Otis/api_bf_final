// Modèles de données pour le contrôle qualité du miel
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum HoneyNature { brut, prefilitre }

enum ConformityStatus { conforme, nonConforme }

/// Modèle pour les données de contrôle qualité
class QualityControlData {
  final String? documentId; // 🆕 ID du document Firestore
  final String containerCode;
  final DateTime receptionDate;
  final String producer;
  final String apiaryVillage;
  final String hiveType;
  final DateTime? collectionStartDate;
  final DateTime? collectionEndDate;
  final HoneyNature honeyNature;
  final String containerType;
  final String containerNumber;
  final double totalWeight; // poids ensemble (miel + contenant)
  final double honeyWeight; // poids du miel seul
  final String quality;
  final double? waterContent; // teneur en eau en %
  final String floralPredominance;
  final ConformityStatus conformityStatus;
  final String? nonConformityCause;
  final String? observations;
  final DateTime createdAt;
  final String? controllerName;
  final bool estAttribue; // Si le produit a été attribué
  final String? attributionId; // ID de l'attribution si attribué
  final String?
      typeAttribution; // Type d'attribution (extraction, filtrage, cire)
  final DateTime? dateAttribution; // Date d'attribution

  const QualityControlData({
    this.documentId, // 🆕 ID du document Firestore
    required this.containerCode,
    required this.receptionDate,
    required this.producer,
    required this.apiaryVillage,
    required this.hiveType,
    this.collectionStartDate,
    this.collectionEndDate,
    required this.honeyNature,
    required this.containerType,
    required this.containerNumber,
    required this.totalWeight,
    required this.honeyWeight,
    required this.quality,
    this.waterContent,
    required this.floralPredominance,
    required this.conformityStatus,
    this.nonConformityCause,
    this.observations,
    required this.createdAt,
    this.controllerName,
    this.estAttribue = false,
    this.attributionId,
    this.typeAttribution,
    this.dateAttribution,
  });

  QualityControlData copyWith({
    String? documentId, // 🆕 ID du document Firestore
    String? containerCode,
    DateTime? receptionDate,
    String? producer,
    String? apiaryVillage,
    String? hiveType,
    DateTime? collectionStartDate,
    DateTime? collectionEndDate,
    HoneyNature? honeyNature,
    String? containerType,
    String? containerNumber,
    double? totalWeight,
    double? honeyWeight,
    String? quality,
    double? waterContent,
    String? floralPredominance,
    ConformityStatus? conformityStatus,
    String? nonConformityCause,
    String? observations,
    DateTime? createdAt,
    String? controllerName,
    bool? estAttribue,
    String? attributionId,
    String? typeAttribution,
    DateTime? dateAttribution,
  }) {
    return QualityControlData(
      documentId: documentId ?? this.documentId, // 🆕 ID du document Firestore
      containerCode: containerCode ?? this.containerCode,
      receptionDate: receptionDate ?? this.receptionDate,
      producer: producer ?? this.producer,
      apiaryVillage: apiaryVillage ?? this.apiaryVillage,
      hiveType: hiveType ?? this.hiveType,
      collectionStartDate: collectionStartDate ?? this.collectionStartDate,
      collectionEndDate: collectionEndDate ?? this.collectionEndDate,
      honeyNature: honeyNature ?? this.honeyNature,
      containerType: containerType ?? this.containerType,
      containerNumber: containerNumber ?? this.containerNumber,
      totalWeight: totalWeight ?? this.totalWeight,
      honeyWeight: honeyWeight ?? this.honeyWeight,
      quality: quality ?? this.quality,
      waterContent: waterContent ?? this.waterContent,
      floralPredominance: floralPredominance ?? this.floralPredominance,
      conformityStatus: conformityStatus ?? this.conformityStatus,
      nonConformityCause: nonConformityCause ?? this.nonConformityCause,
      observations: observations ?? this.observations,
      createdAt: createdAt ?? this.createdAt,
      controllerName: controllerName ?? this.controllerName,
      estAttribue: estAttribue ?? this.estAttribue,
      attributionId: attributionId ?? this.attributionId,
      typeAttribution: typeAttribution ?? this.typeAttribution,
      dateAttribution: dateAttribution ?? this.dateAttribution,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'containerCode': containerCode,
      'receptionDate': receptionDate.toIso8601String(),
      'producer': producer,
      'apiaryVillage': apiaryVillage,
      'hiveType': hiveType,
      'collectionStartDate': collectionStartDate?.toIso8601String(),
      'collectionEndDate': collectionEndDate?.toIso8601String(),
      'honeyNature': honeyNature.name,
      'containerType': containerType,
      'containerNumber': containerNumber,
      'totalWeight': totalWeight,
      'honeyWeight': honeyWeight,
      'quality': quality,
      'waterContent': waterContent,
      'floralPredominance': floralPredominance,
      'conformityStatus': conformityStatus.name,
      'nonConformityCause': nonConformityCause,
      'observations': observations,
      'createdAt': createdAt.toIso8601String(),
      'controllerName': controllerName,
      'estAttribue': estAttribue,
      'attributionId': attributionId,
      'typeAttribution': typeAttribution,
      'dateAttribution': dateAttribution?.toIso8601String(),
    };
  }

  /// Construit un QualityControlData depuis les données Firestore
  factory QualityControlData.fromFirestore(Map<String, dynamic> data,
      {String? documentId}) {
    return QualityControlData(
      documentId:
          documentId, // 🆕 ID du document Firestore passé depuis le service
      containerCode: data['containerCode'] ?? '',
      receptionDate: data['receptionDate'] is Timestamp
          ? (data['receptionDate'] as Timestamp).toDate()
          : DateTime.parse(
              data['receptionDate'] ?? DateTime.now().toIso8601String()),
      producer: data['producer'] ?? '',
      apiaryVillage: data['apiaryVillage'] ?? '',
      hiveType: data['hiveType'] ?? '',
      collectionStartDate: data['collectionStartDate'] != null
          ? (data['collectionStartDate'] is Timestamp
              ? (data['collectionStartDate'] as Timestamp).toDate()
              : DateTime.parse(data['collectionStartDate']))
          : null,
      collectionEndDate: data['collectionEndDate'] != null
          ? (data['collectionEndDate'] is Timestamp
              ? (data['collectionEndDate'] as Timestamp).toDate()
              : DateTime.parse(data['collectionEndDate']))
          : null,
      honeyNature: HoneyNature.values.firstWhere(
        (e) => e.name == data['honeyNature'],
        orElse: () => HoneyNature.brut,
      ),
      containerType: data['containerType'] ?? '',
      containerNumber: data['containerNumber'] ?? '',
      totalWeight: (data['totalWeight'] ?? 0.0).toDouble(),
      honeyWeight: (data['honeyWeight'] ?? 0.0).toDouble(),
      quality: data['quality'] ?? '',
      waterContent: data['waterContent']?.toDouble(),
      floralPredominance: data['floralPredominance'] ?? '',
      conformityStatus: ConformityStatus.values.firstWhere(
        (e) => e.name == data['conformityStatus'],
        orElse: () => ConformityStatus.conforme,
      ),
      nonConformityCause: data['nonConformityCause'],
      observations: data['observations'],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(
              data['createdAt'] ?? DateTime.now().toIso8601String()),
      controllerName: data['controllerName'] ?? '',
      estAttribue: data['estAttribue'] ?? false,
      attributionId: data['attributionId'],
      typeAttribution: data['typeAttribution'],
      dateAttribution: data['dateAttribution'] != null
          ? (data['dateAttribution'] is Timestamp
              ? (data['dateAttribution'] as Timestamp).toDate()
              : DateTime.parse(data['dateAttribution']))
          : null,
    );
  }

  factory QualityControlData.fromJson(Map<String, dynamic> json,
      {String? documentId}) {
    return QualityControlData(
      documentId: documentId, // 🆕 ID du document
      containerCode: json['containerCode'] ?? '',
      receptionDate: DateTime.parse(json['receptionDate']),
      producer: json['producer'] ?? '',
      apiaryVillage: json['apiaryVillage'] ?? '',
      hiveType: json['hiveType'] ?? '',
      collectionStartDate: json['collectionStartDate'] != null
          ? DateTime.parse(json['collectionStartDate'])
          : null,
      collectionEndDate: json['collectionEndDate'] != null
          ? DateTime.parse(json['collectionEndDate'])
          : null,
      honeyNature: HoneyNature.values.firstWhere(
        (e) => e.name == json['honeyNature'],
        orElse: () => HoneyNature.brut,
      ),
      containerType: json['containerType'] ?? '',
      containerNumber: json['containerNumber'] ?? '',
      totalWeight: (json['totalWeight'] ?? 0).toDouble(),
      honeyWeight: (json['honeyWeight'] ?? 0).toDouble(),
      quality: json['quality'] ?? '',
      waterContent: json['waterContent']?.toDouble(),
      floralPredominance: json['floralPredominance'] ?? '',
      conformityStatus: ConformityStatus.values.firstWhere(
        (e) => e.name == json['conformityStatus'],
        orElse: () => ConformityStatus.conforme,
      ),
      nonConformityCause: json['nonConformityCause'],
      observations: json['observations'],
      createdAt: DateTime.parse(json['createdAt']),
      controllerName: json['controllerName'],
      estAttribue: json['estAttribue'] ?? false,
      attributionId: json['attributionId'],
      typeAttribution: json['typeAttribution'],
      dateAttribution: json['dateAttribution'] != null
          ? DateTime.parse(json['dateAttribution'])
          : null,
    );
  }
}

/// Utilitaires pour le contrôle qualité
class QualityControlUtils {
  static String getHoneyNatureLabel(HoneyNature nature) {
    switch (nature) {
      case HoneyNature.brut:
        return 'Brut';
      case HoneyNature.prefilitre:
        return 'Préfiltré';
    }
  }

  static String getConformityStatusLabel(ConformityStatus status) {
    switch (status) {
      case ConformityStatus.conforme:
        return 'Conforme (C)';
      case ConformityStatus.nonConforme:
        return 'Non Conforme (NC)';
    }
  }

  static Color getConformityStatusColor(ConformityStatus status) {
    switch (status) {
      case ConformityStatus.conforme:
        return Colors.green;
      case ConformityStatus.nonConforme:
        return Colors.red;
    }
  }

  static IconData getConformityStatusIcon(ConformityStatus status) {
    switch (status) {
      case ConformityStatus.conforme:
        return Icons.check_circle;
      case ConformityStatus.nonConforme:
        return Icons.cancel;
    }
  }

  static String formatPercentage(double? value) {
    if (value == null) return '';
    return '${value.toStringAsFixed(1)}%';
  }

  static String formatWeight(double value) {
    return '${value.toStringAsFixed(2)} kg';
  }
}
