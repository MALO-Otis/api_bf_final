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
  '7kg': 'Seau 7 kg',
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
      id: metadata['id']?.toString() ?? metadata['name'] ?? UniqueKey().toString(),
      name: metadata['name']?.toString() ?? 'Sans nom',
    );
  }
}
