import 'package:flutter/material.dart';

/// Toutes les étapes couvrant la chaîne de valeur.
enum QualityChainStep {
  collecte,
  controle,
  extraction,
  filtration,
  maturation,
  conditionnement,
  attribution,
  vente,
}

extension QualityChainStepX on QualityChainStep {
  String get label {
    switch (this) {
      case QualityChainStep.collecte:
        return 'Collecte';
      case QualityChainStep.controle:
        return 'Contrôle';
      case QualityChainStep.extraction:
        return 'Extraction';
      case QualityChainStep.filtration:
        return 'Filtration';
      case QualityChainStep.maturation:
        return 'Maturation';
      case QualityChainStep.conditionnement:
        return 'Conditionnement';
      case QualityChainStep.attribution:
        return 'Attribution';
      case QualityChainStep.vente:
        return 'Vente';
    }
  }

  IconData get icon {
    switch (this) {
      case QualityChainStep.collecte:
        return Icons.nature_outlined;
      case QualityChainStep.controle:
        return Icons.verified_user_outlined;
      case QualityChainStep.extraction:
        return Icons.science_outlined;
      case QualityChainStep.filtration:
        return Icons.filter_alt_outlined;
      case QualityChainStep.maturation:
        return Icons.bubble_chart_outlined;
      case QualityChainStep.conditionnement:
        return Icons.inventory_2_outlined;
      case QualityChainStep.attribution:
        return Icons.assignment_return_outlined;
      case QualityChainStep.vente:
        return Icons.storefront_outlined;
    }
  }
}

/// Palette des odeurs possibles lors du contrôle.
enum QualityOdorProfile {
  floral,
  vegetal,
  fumee,
  fermentation,
  neutre,
  suspect
}

extension QualityOdorProfileX on QualityOdorProfile {
  String get label {
    switch (this) {
      case QualityOdorProfile.floral:
        return 'Floral/Doux';
      case QualityOdorProfile.vegetal:
        return 'Végétal';
      case QualityOdorProfile.fumee:
        return 'Fumé';
      case QualityOdorProfile.fermentation:
        return 'Fermentation';
      case QualityOdorProfile.neutre:
        return 'Neutre';
      case QualityOdorProfile.suspect:
        return 'Suspect';
    }
  }
}

/// Niveau de dépôt observé dans le contenant.
enum QualityDepositLevel { aucun, faible, moyen, important }

extension QualityDepositLevelX on QualityDepositLevel {
  String get label {
    switch (this) {
      case QualityDepositLevel.aucun:
        return 'Aucun dépôt';
      case QualityDepositLevel.faible:
        return 'Dépôt léger';
      case QualityDepositLevel.moyen:
        return 'Dépôt modéré';
      case QualityDepositLevel.important:
        return 'Dépôt important';
    }
  }
}
