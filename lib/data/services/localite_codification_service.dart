import '../geographe/geographie.dart';

/// Service pour générer les codes de localité automatiquement
/// Format: XX-XX-XX (région-province-commune)
/// Basé sur l'ordre alphabétique des entités géographiques
class LocaliteCodificationService {
  /// Génère un code de localité complet au format XX-XX-XX
  ///
  /// [regionNom] - Nom de la région
  /// [provinceNom] - Nom de la province
  /// [communeNom] - Nom de la commune
  ///
  /// Retourne un code au format "01-02-03" ou null si des informations manquent
  static String? generateCodeLocalite({
    required String regionNom,
    required String provinceNom,
    required String communeNom,
  }) {
    try {
      // Nettoyer et valider les entrées
      final regionClean = regionNom.trim();
      final provinceClean = provinceNom.trim();
      final communeClean = communeNom.trim();

      if (regionClean.isEmpty ||
          provinceClean.isEmpty ||
          communeClean.isEmpty) {
        print('❌ LocaliteCodificationService: Paramètres manquants');
        return null;
      }

      // Obtenir le code région
      final codeRegion = _getRegionCode(regionClean);
      if (codeRegion == null) {
        print(
            '❌ LocaliteCodificationService: Région non trouvée: $regionClean');
        return null;
      }

      // Obtenir le code province
      final codeProvince = _getProvinceCode(codeRegion, provinceClean);
      if (codeProvince == null) {
        print(
            '❌ LocaliteCodificationService: Province non trouvée: $provinceClean dans $regionClean');
        return null;
      }

      // Obtenir le code commune
      final codeCommune =
          _getCommuneCode(codeRegion, codeProvince, communeClean);
      if (codeCommune == null) {
        print(
            '❌ LocaliteCodificationService: Commune non trouvée: $communeClean dans $provinceClean');
        return null;
      }

      final codeComplet = '$codeRegion-$codeProvince-$codeCommune';
      print(
          '✅ LocaliteCodificationService: Code généré: $codeComplet pour $regionClean > $provinceClean > $communeClean');

      return codeComplet;
    } catch (e) {
      print('❌ LocaliteCodificationService: Erreur lors de la génération: $e');
      return null;
    }
  }

  /// Génère un code de localité à partir d'un Map de localisation
  static String? generateCodeFromMap(Map<String, String> localisation) {
    return generateCodeLocalite(
      regionNom: localisation['region'] ?? '',
      provinceNom: localisation['province'] ?? '',
      communeNom: localisation['commune'] ?? '',
    );
  }

  /// Décode un code de localité pour obtenir les noms complets
  ///
  /// [codeLocalite] - Code au format "01-02-03"
  ///
  /// Retourne un Map avec les noms complets ou null si le code est invalide
  static Map<String, String>? decodeCodeLocalite(String codeLocalite) {
    try {
      final parts = codeLocalite.split('-');
      if (parts.length != 3) {
        print(
            '❌ LocaliteCodificationService: Format de code invalide: $codeLocalite');
        return null;
      }

      final codeRegion = parts[0];
      final codeProvince = parts[1];
      final codeCommune = parts[2];

      // Récupérer les noms à partir des codes
      final regionNom = _getRegionName(codeRegion);
      if (regionNom == null) {
        print(
            '❌ LocaliteCodificationService: Code région invalide: $codeRegion');
        return null;
      }

      final provinceNom = _getProvinceName(codeRegion, codeProvince);
      if (provinceNom == null) {
        print(
            '❌ LocaliteCodificationService: Code province invalide: $codeProvince dans région $codeRegion');
        return null;
      }

      final communeNom = _getCommuneName(codeRegion, codeProvince, codeCommune);
      if (communeNom == null) {
        print(
            '❌ LocaliteCodificationService: Code commune invalide: $codeCommune dans province $codeProvince');
        return null;
      }

      return {
        'region': regionNom,
        'province': provinceNom,
        'commune': communeNom,
        'codeLocalite': codeLocalite,
      };
    } catch (e) {
      print('❌ LocaliteCodificationService: Erreur lors du décodage: $e');
      return null;
    }
  }

  /// Valide si un code de localité est correct
  static bool validateCodeLocalite(String codeLocalite) {
    return decodeCodeLocalite(codeLocalite) != null;
  }

  /// Formate un code de localité pour l'affichage
  /// Format: "01-02-03 (Région > Province > Commune)"
  static String formatCodeForDisplay(String codeLocalite) {
    final decoded = decodeCodeLocalite(codeLocalite);
    if (decoded == null) return codeLocalite;

    return '$codeLocalite (${decoded['region']} > ${decoded['province']} > ${decoded['commune']})';
  }

  // MÉTHODES PRIVÉES POUR L'OBTENTION DES CODES

  /// Obtient le code d'une région par son nom
  static String? _getRegionCode(String regionNom) {
    // Recherche directe par nom (exact ou avec anciens noms entre parenthèses)
    for (final region in GeographieData.regionsBurkina) {
      final nom = region['nom'] as String;
      if (_compareNames(nom, regionNom)) {
        return region['code'] as String;
      }
    }
    return null;
  }

  /// Obtient le code d'une province par son nom dans une région
  static String? _getProvinceCode(String codeRegion, String provinceNom) {
    final provinces = GeographieData.provincesParRegion[codeRegion];
    if (provinces == null) return null;

    for (final province in provinces) {
      final nom = province['nom'] as String;
      if (_compareNames(nom, provinceNom)) {
        return province['code'] as String;
      }
    }
    return null;
  }

  /// Obtient le code d'une commune par son nom dans une province
  static String? _getCommuneCode(
      String codeRegion, String codeProvince, String communeNom) {
    final communes =
        GeographieData.getCommunesForProvince(codeRegion, codeProvince);

    for (final commune in communes) {
      final nom = commune['nom'] as String;
      if (_compareNames(nom, communeNom)) {
        return commune['code'] as String;
      }
    }
    return null;
  }

  // MÉTHODES PRIVÉES POUR L'OBTENTION DES NOMS

  /// Obtient le nom d'une région par son code
  static String? _getRegionName(String codeRegion) {
    for (final region in GeographieData.regionsBurkina) {
      if (region['code'] == codeRegion) {
        return region['nom'] as String;
      }
    }
    return null;
  }

  /// Obtient le nom d'une province par son code dans une région
  static String? _getProvinceName(String codeRegion, String codeProvince) {
    final provinces = GeographieData.provincesParRegion[codeRegion];
    if (provinces == null) return null;

    for (final province in provinces) {
      if (province['code'] == codeProvince) {
        return province['nom'] as String;
      }
    }
    return null;
  }

  /// Obtient le nom d'une commune par son code dans une province
  static String? _getCommuneName(
      String codeRegion, String codeProvince, String codeCommune) {
    final communes =
        GeographieData.getCommunesForProvince(codeRegion, codeProvince);

    for (final commune in communes) {
      if (commune['code'] == codeCommune) {
        return commune['nom'] as String;
      }
    }
    return null;
  }

  // MÉTHODES UTILITAIRES

  /// Compare deux noms géographiques en tenant compte des variantes
  /// Gère les anciens noms entre parenthèses et les différences de casse
  static bool _compareNames(String nomSysteme, String nomRecherche) {
    final nomSystemeClean = nomSysteme.toLowerCase().trim();
    final nomRechercheClean = nomRecherche.toLowerCase().trim();

    // Comparaison exacte
    if (nomSystemeClean == nomRechercheClean) return true;

    // Comparaison avec extraction du nom principal (avant parenthèses)
    final nomPrincipal = nomSystemeClean.split('(').first.trim();
    if (nomPrincipal == nomRechercheClean) return true;

    // Comparaison avec extraction du nom entre parenthèses
    if (nomSystemeClean.contains('(') && nomSystemeClean.contains(')')) {
      final start = nomSystemeClean.indexOf('(') + 1;
      final end = nomSystemeClean.indexOf(')');
      if (start < end) {
        final nomParentheses = nomSystemeClean.substring(start, end).trim();
        if (nomParentheses == nomRechercheClean) return true;
      }
    }

    // Comparaison avec suppression des tirets et espaces
    final nomSystemeSimplifie =
        nomSystemeClean.replaceAll(RegExp(r'[-\s]'), '');
    final nomRechercheSimplifie =
        nomRechercheClean.replaceAll(RegExp(r'[-\s]'), '');
    if (nomSystemeSimplifie == nomRechercheSimplifie) return true;

    return false;
  }

  /// Obtient des statistiques sur le système de codification
  static Map<String, int> getStatistics() {
    int totalRegions = GeographieData.regionsBurkina.length;
    int totalProvinces = 0;
    int totalCommunes = 0;

    for (final regionCode in GeographieData.provincesParRegion.keys) {
      final provinces = GeographieData.provincesParRegion[regionCode]!;
      totalProvinces += provinces.length;

      for (final province in provinces) {
        final provinceCode = province['code'] as String;
        final communes =
            GeographieData.getCommunesForProvince(regionCode, provinceCode);
        totalCommunes += communes.length;
      }
    }

    return {
      'regions': totalRegions,
      'provinces': totalProvinces,
      'communes': totalCommunes,
    };
  }

  /// Test de performance du service
  static Map<String, dynamic> runPerformanceTest() {
    final stopwatch = Stopwatch()..start();
    int successCount = 0;
    int errorCount = 0;
    final List<String> testCodes = [];

    // Test sur un échantillon de chaque région
    for (final region in GeographieData.regionsBurkina.take(5)) {
      final regionCode = region['code'] as String;
      final regionNom = region['nom'] as String;

      final provinces = GeographieData.provincesParRegion[regionCode];
      if (provinces != null && provinces.isNotEmpty) {
        final province = provinces.first;
        final provinceNom = province['nom'] as String;
        final provinceCode = province['code'] as String;

        final communes =
            GeographieData.getCommunesForProvince(regionCode, provinceCode);
        if (communes.isNotEmpty) {
          final commune = communes.first;
          final communeNom = commune['nom'] as String;

          final code = generateCodeLocalite(
            regionNom: regionNom,
            provinceNom: provinceNom,
            communeNom: communeNom,
          );

          if (code != null) {
            successCount++;
            testCodes.add(code);
          } else {
            errorCount++;
          }
        }
      }
    }

    stopwatch.stop();

    return {
      'duration_ms': stopwatch.elapsedMilliseconds,
      'success_count': successCount,
      'error_count': errorCount,
      'sample_codes': testCodes,
      'performance_ok':
          stopwatch.elapsedMilliseconds < 1000, // Moins d'1 seconde
    };
  }
}
