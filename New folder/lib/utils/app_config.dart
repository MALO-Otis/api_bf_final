import 'package:flutter/material.dart';

// Configuration des couleurs
class AppColors {
  static const Color primary = Color(0xFFF49101);
  static const Color secondary = Color(0xFF2D0C0D);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53E3E);
  static const Color info = Color(0xFF2196F3);

  // Couleurs spécifiques aux collectes
  static const Color collecteBackground = Color(0xFFFFF8E1);
  static const Color collecteBorder = Color(0xFFFFCC02);
  static const Color producteurCard = Color(0xFFE8F5E8);
  static const Color contenantCard = Color(0xFFF3E5F5);
}

// Configuration des constantes de l'application
class AppConstants {
  // Types de ruches
  static const List<String> typesRuches = [
    'Traditionnelle',
    'Moderne',
    'Langstroth',
    'Dadant',
    'Warré',
  ];

  // Types de miel
  static const List<String> typesMiel = [
    'Acacia',
    'Lavande',
    'Tilleul',
    'Châtaignier',
    'Toutes fleurs',
    'Eucalyptus',
    'Thym',
    'Romarin',
    'Colza',
    'Tournesol',
  ];

  // Régions du Burkina Faso
  static const List<String> regions = [
    'Boucle du Mouhoun',
    'Cascades',
    'Centre',
    'Centre-Est',
    'Centre-Nord',
    'Centre-Ouest',
    'Centre-Sud',
    'Est',
    'Hauts-Bassins',
    'Nord',
    'Plateau-Central',
    'Sahel',
    'Sud-Ouest',
  ];

  // Provinces par région (exemple pour quelques régions)
  static const Map<String, List<String>> provincesByRegion = {
    'Centre': ['Kadiogo'],
    'Hauts-Bassins': ['Houet', 'Kénédougou', 'Tuy'],
    'Boucle du Mouhoun': [
      'Balé',
      'Banwa',
      'Kossi',
      'Mouhoun',
      'Nayala',
      'Sourou'
    ],
    'Centre-Ouest': ['Boulkiemdé', 'Sanguié', 'Sissili', 'Ziro'],
    'Sud-Ouest': ['Bougouriba', 'Ioba', 'Noumbiel', 'Poni'],
  };

  // Sexes
  static const List<String> sexes = ['Masculin', 'Féminin'];

  // Statuts de collecte
  static const List<String> statutsCollecte = [
    'collecte_en_cours',
    'collecte_terminee',
    'en_attente_controle',
    'controle_ok',
    'controle_ko',
    'en_stock',
  ];

  // Limites de validation
  static const int ageMinimum = 18;
  static const int ageMaximum = 100;
  static const double quantiteMinimum = 0.1;
  static const double quantiteMaximum = 1000.0;
  static const double prixMinimum = 100.0;
  static const double prixMaximum = 10000.0;

  // Pagination
  static const int itemsParPage = 20;
  static const int maxItemsParPage = 100;

  // Formats de date
  static const String formatDateComplete = 'dd/MM/yyyy HH:mm';
  static const String formatDateSimple = 'dd/MM/yyyy';
  static const String formatDateFichier = 'yyyy_MM_dd';
}

// Configuration des styles
class AppStyles {
  // TextStyles
  static const TextStyle titre1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle titre2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle titre3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle sousTitre = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );

  static const TextStyle corpsTexte = TextStyle(
    fontSize: 14,
  );

  static const TextStyle petitTexte = TextStyle(
    fontSize: 12,
  );

  // Décoration des cartes
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withValues(alpha: 0.1),
        spreadRadius: 1,
        blurRadius: 5,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Décoration des champs de saisie
  static InputDecoration inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.error, width: 1),
      ),
    );
  }

  // Style des boutons
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 48),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  static ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    side: const BorderSide(color: AppColors.primary),
    minimumSize: const Size(double.infinity, 48),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );
}

// Utilitaires pour l'application
class AppUtils {
  // Validation des champs
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est obligatoire';
    }
    return null;
  }

  static String? validateNumber(String? value, String fieldName,
      {double? min, double? max}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est obligatoire';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return '$fieldName doit être un nombre valide';
    }

    if (min != null && number < min) {
      return '$fieldName doit être supérieur ou égal à $min';
    }

    if (max != null && number > max) {
      return '$fieldName doit être inférieur ou égal à $max';
    }

    return null;
  }

  static String? validateAge(String? value) {
    return validateNumber(value, 'Âge',
        min: AppConstants.ageMinimum.toDouble(),
        max: AppConstants.ageMaximum.toDouble());
  }

  static String? validateQuantite(String? value) {
    return validateNumber(value, 'Quantité',
        min: AppConstants.quantiteMinimum, max: AppConstants.quantiteMaximum);
  }

  static String? validatePrix(String? value) {
    return validateNumber(value, 'Prix',
        min: AppConstants.prixMinimum, max: AppConstants.prixMaximum);
  }

  // Formatage des nombres
  static String formatMontant(double montant) {
    return '${montant.toStringAsFixed(0)} FCFA';
  }

  static String formatQuantite(double quantite) {
    return '${quantite.toStringAsFixed(2)} kg';
  }

  // Génération d'IDs
  static String generateCollecteId() {
    final now = DateTime.now();
    final dateStr =
        "${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}";
    return "collectes_${dateStr}_${now.millisecondsSinceEpoch}";
  }

  static String generateProducteurId(String numero) {
    return 'prod_$numero';
  }

  // Gestion des erreurs
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
