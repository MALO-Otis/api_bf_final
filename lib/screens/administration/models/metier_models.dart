import 'package:flutter/foundation.dart';

/// Liste ordonnée des conditionnements de miel pris en charge.
const List<String> kHoneyPackagingOrder = [
  '1kg',
  '1.5kg',
  '720g',
  '500g',
  '250g',
  '30g',
  '20g',
  '125g',
  '7kg',
];

/// Libellés lisibles pour les conditionnements.
const Map<String, String> kHoneyPackagingLabels = {
  '1kg': 'Pot 1 kg',
  '1.5kg': 'Pot 1.5 kg',
  '720g': 'Pot 720 g',
  '500g': 'Pot 500 g',
  '250g': 'Pot 250 g',
  '30g': 'Mini pot 30 g',
  '20g': 'Mini pot 20 g',
  '125g': 'Pot 125 g',
  '7kg': 'Bidon de 7kg',
};

/// Représente une prédominance florale disponible pour les produits.
class FloralPredominence {
  final String id;
  final String name;

  const FloralPredominence({
    required this.id,
    required this.name,
  });

  FloralPredominence copyWith({
    String? id,
    String? name,
  }) {
    return FloralPredominence(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMetadataMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  static FloralPredominence fromFirestore({
    required Map<String, dynamic> metadata,
  }) {
    return FloralPredominence(
      id: metadata['id']?.toString() ??
          metadata['name'] ??
          UniqueKey().toString(),
      name: metadata['name']?.toString() ?? 'Sans nom',
    );
  }
}

/// Types de contenants pour la tarification par contenant
enum ContainerType {
  fut('Fût'),
  seau('Seau'),
  bidon('Bidon'),
  pot('Pot'),
  sac('Sac');

  const ContainerType(this.displayName);
  final String displayName;
}

/// Modèle pour les prix par type de contenant
class ContainerPricing {
  final String containerType;
  final double pricePerKg;
  final DateTime lastUpdated;
  final String updatedBy;

  const ContainerPricing({
    required this.containerType,
    required this.pricePerKg,
    required this.lastUpdated,
    required this.updatedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'containerType': containerType,
      'pricePerKg': pricePerKg,
      'lastUpdated': lastUpdated.toIso8601String(),
      'updatedBy': updatedBy,
    };
  }

  static ContainerPricing fromMap(Map<String, dynamic> map) {
    return ContainerPricing(
      containerType: map['containerType'] ?? '',
      pricePerKg: (map['pricePerKg'] ?? 0.0).toDouble(),
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(map['lastUpdated'])
          : DateTime.now(),
      updatedBy: map['updatedBy'] ?? '',
    );
  }

  ContainerPricing copyWith({
    String? containerType,
    double? pricePerKg,
    DateTime? lastUpdated,
    String? updatedBy,
  }) {
    return ContainerPricing(
      containerType: containerType ?? this.containerType,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
