/// Service pour gérer l'état de contrôle des produits
import 'package:flutter/foundation.dart';
import '../screens/controle_de_donnes/models/attribution_models_v2.dart';

/// Énumération des statuts de contrôle possibles
enum ProductControlStatus {
  nonControle('non_controle', 'Non Contrôlé',
      'Le produit n\'a pas encore été contrôlé'),
  enAttente('en_attente', 'En Attente', 'En attente de contrôle'),
  enCours('en_cours', 'En Cours', 'Contrôle en cours'),
  termine('termine', 'Terminé', 'Contrôle terminé mais pas encore validé'),
  valide('valide', 'Validé', 'Contrôle validé, produit prêt pour attribution'),
  refuse('refuse', 'Refusé', 'Contrôle refusé, produit non conforme'),
  nonConforme('non_conforme', 'Non Conforme', 'Produit déclaré non conforme');

  const ProductControlStatus(this.value, this.label, this.description);
  final String value;
  final String label;
  final String description;
}

/// Service pour gérer l'état de contrôle des produits
class ProductControlStatusService {
  static final ProductControlStatusService _instance =
      ProductControlStatusService._internal();
  factory ProductControlStatusService() => _instance;
  ProductControlStatusService._internal();

  /// Détermine si un produit peut être attribué selon son statut de contrôle
  bool canBeAttributed(ProductControle product) {
    // Le produit DOIT être contrôlé
    if (!product.estControle) {
      if (kDebugMode) {
        print('❌ ATTRIBUTION: Produit ${product.codeContenant} non contrôlé');
      }
      return false;
    }

    // Le produit DOIT être conforme
    if (!product.estConforme) {
      if (kDebugMode) {
        print('❌ ATTRIBUTION: Produit ${product.codeContenant} non conforme');
      }
      return false;
    }

    // Le statut DOIT être validé
    final status = getControlStatus(product.statutControle);
    if (status != ProductControlStatus.valide) {
      if (kDebugMode) {
        print(
            '❌ ATTRIBUTION: Produit ${product.codeContenant} statut ${status.label}');
      }
      return false;
    }

    // Le produit ne doit PAS déjà être attribué
    if (product.estAttribue) {
      if (kDebugMode) {
        print('❌ ATTRIBUTION: Produit ${product.codeContenant} déjà attribué');
      }
      return false;
    }

    return true;
  }

  /// Détermine si un produit peut être utilisé pour l'extraction
  bool canBeExtracted(ProductControle product) {
    if (!canBeAttributed(product)) return false;

    if (product.nature != ProductNature.brut) {
      if (kDebugMode) {
        print(
            '❌ EXTRACTION: Produit ${product.codeContenant} n\'est pas brut (${product.nature.label})');
      }
      return false;
    }

    return true;
  }

  /// Détermine si un produit peut être utilisé pour le filtrage
  bool canBeFiltered(ProductControle product) {
    if (!canBeAttributed(product)) return false;

    if (product.nature != ProductNature.liquide) {
      if (kDebugMode) {
        print(
            '❌ FILTRAGE: Produit ${product.codeContenant} n\'est pas liquide (${product.nature.label})');
      }
      return false;
    }

    return true;
  }

  /// Détermine si un produit cire peut être traité directement
  bool canBeProcessedAsCire(ProductControle product) {
    // La cire a des règles spéciales : elle peut être traitée même sans contrôle traditionnel
    if (product.nature != ProductNature.cire) {
      if (kDebugMode) {
        print(
            '❌ CIRE: Produit ${product.codeContenant} n\'est pas de la cire (${product.nature.label})');
      }
      return false;
    }

    // Pour la cire, on accepte si elle est conforme OU si elle n'a pas encore été contrôlée
    // (la cire passe directement au traitement)
    if (!product.estConforme && product.estControle) {
      if (kDebugMode) {
        print(
            '❌ CIRE: Produit ${product.codeContenant} cire contrôlée mais non conforme');
      }
      return false;
    }

    // Le produit ne doit PAS déjà être attribué
    if (product.estAttribue) {
      if (kDebugMode) {
        print('❌ CIRE: Produit ${product.codeContenant} déjà attribué');
      }
      return false;
    }

    return true;
  }

  /// Convertit une chaîne de statut en enum
  ProductControlStatus getControlStatus(String? statusString) {
    if (statusString == null) return ProductControlStatus.nonControle;

    for (final status in ProductControlStatus.values) {
      if (status.value == statusString.toLowerCase()) {
        return status;
      }
    }

    return ProductControlStatus.nonControle;
  }

  /// Met à jour le statut de contrôle d'un produit
  ProductControle updateControlStatus(
    ProductControle product,
    ProductControlStatus newStatus, {
    bool? isConforme,
    String? nonConformityReason,
    String? observations,
  }) {
    final updatedProduct = product.copyWith(
      estControle: newStatus != ProductControlStatus.nonControle,
      statutControle: newStatus.value,
      estConforme: isConforme ??
          (newStatus == ProductControlStatus.valide ||
              newStatus == ProductControlStatus.termine),
      causeNonConformite: !product.estConforme ? nonConformityReason : null,
      observations: observations,
    );

    if (kDebugMode) {
      print(
          '🔄 STATUT: Produit ${product.codeContenant} -> ${newStatus.label}');
    }

    return updatedProduct;
  }

  /// Vérifie la cohérence d'un produit
  List<String> validateProduct(ProductControle product) {
    final issues = <String>[];

    // Vérifications de base
    if (product.codeContenant.isEmpty) {
      issues.add('Code contenant manquant');
    }

    if (product.producteur.isEmpty) {
      issues.add('Producteur manquant');
    }

    if (product.poidsTotal <= 0) {
      issues.add('Poids invalide');
    }

    // Vérifications de cohérence du contrôle
    if (product.estControle && product.statutControle == null) {
      issues.add('Produit marqué comme contrôlé mais sans statut');
    }

    if (!product.estControle && product.statutControle != null) {
      issues.add('Produit non contrôlé mais avec un statut');
    }

    if (!product.estConforme && product.causeNonConformite == null) {
      issues.add('Produit non conforme sans cause spécifiée');
    }

    if (product.estConforme && product.causeNonConformite != null) {
      issues.add('Produit conforme avec cause de non-conformité');
    }

    // Vérifications d'attribution
    if (product.estAttribue && product.attributionId == null) {
      issues.add('Produit marqué comme attribué sans ID d\'attribution');
    }

    if (!product.estAttribue && product.attributionId != null) {
      issues.add('Produit non attribué avec ID d\'attribution');
    }

    // Vérifications spécifiques à la nature
    switch (product.nature) {
      case ProductNature.cire:
        if (product.teneurEau != null && product.teneurEau! > 5.0) {
          issues.add('Teneur en eau trop élevée pour de la cire');
        }
        break;
      case ProductNature.liquide:
        if (product.teneurEau != null && product.teneurEau! > 20.0) {
          issues.add('Teneur en eau trop élevée pour du miel liquide');
        }
        break;
      case ProductNature.brut:
        // Pas de vérifications spéciales pour le brut
        break;
      case ProductNature.filtre:
        if (product.teneurEau != null && product.teneurEau! > 18.0) {
          issues.add('Teneur en eau trop élevée pour du miel filtré');
        }
        break;
    }

    return issues;
  }

  /// Génère un rapport de statut pour un produit
  Map<String, dynamic> generateStatusReport(ProductControle product) {
    final status = getControlStatus(product.statutControle);
    final issues = validateProduct(product);

    return {
      'product_id': product.id,
      'code_contenant': product.codeContenant,
      'is_controlled': product.estControle,
      'is_compliant': product.estConforme,
      'is_attributed': product.estAttribue,
      'control_status': {
        'value': status.value,
        'label': status.label,
        'description': status.description,
      },
      'can_be_attributed': canBeAttributed(product),
      'attribution_rules': {
        'can_extract': canBeExtracted(product),
        'can_filter': canBeFiltered(product),
        'can_process_cire': canBeProcessedAsCire(product),
      },
      'issues': issues,
      'validation_passed': issues.isEmpty,
      'last_check': DateTime.now().toIso8601String(),
    };
  }

  /// Obtient des statistiques sur l'état de contrôle
  Map<String, dynamic> getControlStatistics(List<ProductControle> products) {
    final statusCounts = <String, int>{};
    final natureCounts = <String, int>{};
    final issuesCounts = <String, int>{};

    int totalControlled = 0;
    int totalCompliant = 0;
    int totalAttributed = 0;
    int totalWithIssues = 0;

    for (final product in products) {
      // Compter par statut
      final status = getControlStatus(product.statutControle);
      statusCounts[status.label] = (statusCounts[status.label] ?? 0) + 1;

      // Compter par nature
      natureCounts[product.nature.label] =
          (natureCounts[product.nature.label] ?? 0) + 1;

      // Compter les totaux
      if (product.estControle) totalControlled++;
      if (product.estConforme) totalCompliant++;
      if (product.estAttribue) totalAttributed++;

      // Compter les problèmes
      final issues = validateProduct(product);
      if (issues.isNotEmpty) {
        totalWithIssues++;
        for (final issue in issues) {
          issuesCounts[issue] = (issuesCounts[issue] ?? 0) + 1;
        }
      }
    }

    return {
      'total_products': products.length,
      'controlled': totalControlled,
      'compliant': totalCompliant,
      'attributed': totalAttributed,
      'with_issues': totalWithIssues,
      'available_for_attribution': products.where(canBeAttributed).length,
      'ready_for_extraction': products.where(canBeExtracted).length,
      'ready_for_filtering': products.where(canBeFiltered).length,
      'ready_for_cire_processing': products.where(canBeProcessedAsCire).length,
      'by_status': statusCounts,
      'by_nature': natureCounts,
      'common_issues': issuesCounts,
      'health_percentage': products.isEmpty
          ? 0.0
          : ((products.length - totalWithIssues) / products.length * 100),
    };
  }
}
