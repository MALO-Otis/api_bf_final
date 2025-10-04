import 'package:get/get.dart';
import '../../models/administration/geo_region.dart';
import '../../screens/collecte_de_donnes/core/collecte_geographie_service.dart';
/// Géographie du Burkina Faso : Interface Firestore
///
/// Cette classe remplace GeographieData en utilisant CollecteGeographieService
/// pour récupérer les données géographiques depuis Firestore.
/// Elle maintient la compatibilité avec l'ancien système.


class GeographieFirestore {
  // Service Firestore pour les données dynamiques
  static CollecteGeographieService? _geographieService;

  // Getter pour le service (avec initialisation paresseuse)
  static CollecteGeographieService get _service {
    try {
      _geographieService ??= Get.find<CollecteGeographieService>();
      return _geographieService!;
    } catch (e) {
      // Si le service n'est pas trouvé, on l'injecte
      Get.put(CollecteGeographieService());
      _geographieService = Get.find<CollecteGeographieService>();
      return _geographieService!;
    }
  }

  // --- MÉTHODES COMPATIBLES AVEC L'ANCIEN SYSTÈME ---

  /// Obtient toutes les régions
  static List<Map<String, dynamic>> get regionsBurkina {
    try {
      return _service.regionsMap;
    } catch (e) {
      print(
          '[GeographieFirestore] Erreur lors de la récupération des régions: $e');
      return _fallbackRegions;
    }
  }

  /// Obtient les provinces d'une région donnée
  static List<Map<String, dynamic>> getProvincesForRegion(String? codeRegion) {
    if (codeRegion == null) return [];

    try {
      return _service.getProvincesForRegionMap(codeRegion);
    } catch (e) {
      print(
          '[GeographieFirestore] Erreur lors de la récupération des provinces: $e');
      return [];
    }
  }

  /// Obtient les communes d'une province donnée
  static List<Map<String, dynamic>> getCommunesForProvince(
      String? codeRegion, String? codeProvince) {
    if (codeRegion == null || codeProvince == null) return [];

    try {
      return _service.getCommunesForProvinceMap(codeRegion, codeProvince);
    } catch (e) {
      print(
          '[GeographieFirestore] Erreur lors de la récupération des communes: $e');
      return [];
    }
  }

  /// Obtient les villages d'une commune donnée
  static List<Map<String, dynamic>> getVillagesForCommune(
      String? codeRegion, String? codeProvince, String? codeCommune) {
    if (codeRegion == null || codeProvince == null || codeCommune == null)
      return [];

    try {
      return _service.getVillagesForCommuneMap(
          codeRegion, codeProvince, codeCommune);
    } catch (e) {
      print(
          '[GeographieFirestore] Erreur lors de la récupération des villages: $e');
      return [];
    }
  }

  // --- MÉTHODES DE RECHERCHE PAR NOM ---

  /// Trouve le code d'une région par son nom
  static String? getRegionCodeByName(String regionName) {
    try {
      return _service.getRegionCodeByName(regionName);
    } catch (e) {
      print('[GeographieFirestore] Erreur lors de la recherche de région: $e');
      return null;
    }
  }

  /// Trouve le code d'une province par son nom
  static String? getProvinceCodeByName(
      String? codeRegion, String provinceName) {
    if (codeRegion == null) return null;

    try {
      return _service.getProvinceCodeByName(codeRegion, provinceName);
    } catch (e) {
      print(
          '[GeographieFirestore] Erreur lors de la recherche de province: $e');
      return null;
    }
  }

  /// Trouve le code d'une commune par son nom
  static String? getCommuneCodeByName(
      String? codeRegion, String? codeProvince, String communeName) {
    if (codeRegion == null || codeProvince == null) return null;

    try {
      return _service.getCommuneCodeByName(
          codeRegion, codeProvince, communeName);
    } catch (e) {
      print('[GeographieFirestore] Erreur lors de la recherche de commune: $e');
      return null;
    }
  }

  /// Trouve le code d'un village par son nom
  static String? getVillageCodeByName(String? codeRegion, String? codeProvince,
      String? codeCommune, String villageName) {
    if (codeRegion == null || codeProvince == null || codeCommune == null)
      return null;

    try {
      return _service.getVillageCodeByName(
          codeRegion, codeProvince, codeCommune, villageName);
    } catch (e) {
      print('[GeographieFirestore] Erreur lors de la recherche de village: $e');
      return null;
    }
  }

  // --- MÉTHODES DE VALIDATION ---

  /// Valide une hiérarchie géographique
  static bool validateHierarchy({
    String? codeRegion,
    String? codeProvince,
    String? codeCommune,
  }) {
    try {
      return _service.validateHierarchy(
        codeRegion: codeRegion,
        codeProvince: codeProvince,
        codeCommune: codeCommune,
      );
    } catch (e) {
      print('[GeographieFirestore] Erreur lors de la validation: $e');
      return false;
    }
  }

  // --- MÉTHODES UTILITAIRES ---

  /// Trouve la hiérarchie complète d'une localisation
  static Map<String, String?> findLocationHierarchy({
    String? regionName,
    String? provinceName,
    String? communeName,
  }) {
    try {
      return _service.findLocationHierarchy(
        regionName: regionName,
        provinceName: provinceName,
        communeName: communeName,
      );
    } catch (e) {
      print(
          '[GeographieFirestore] Erreur lors de la recherche de hiérarchie: $e');
      return {
        'regionCode': null,
        'provinceCode': null,
        'communeCode': null,
      };
    }
  }

  /// Formate un code de localisation
  static String formatLocationCode({
    String? regionName,
    String? provinceName,
    String? communeName,
    String? villageName,
  }) {
    final hierarchy = findLocationHierarchy(
      regionName: regionName,
      provinceName: provinceName,
      communeName: communeName,
    );

    final regionCode = hierarchy['regionCode'] ?? '00';
    final provinceCode = hierarchy['provinceCode'] ?? '00';
    final communeCode = hierarchy['communeCode'] ?? '00';

    final codesPart = '$regionCode-$provinceCode-$communeCode';
    final namesPart = [regionName, provinceName, communeName, villageName]
        .where((name) => name != null && name.isNotEmpty)
        .join('-');

    return '$codesPart / $namesPart';
  }

  /// Formate à partir d'un map de localisation
  static String formatLocationCodeFromMap(Map<String, String> localisation) {
    return formatLocationCode(
      regionName: localisation['region'],
      provinceName: localisation['province'],
      communeName: localisation['commune'],
      villageName: localisation['village'],
    );
  }

  // --- MÉTHODES D'INITIALISATION ---

  /// Force le rechargement des données depuis Firestore
  static Future<void> reloadData() async {
    try {
      await _service.loadGeographieData();
    } catch (e) {
      print('[GeographieFirestore] Erreur lors du rechargement: $e');
    }
  }

  /// Vérifie si les données sont chargées
  static bool get isDataLoaded {
    try {
      return _service.isDataLoaded;
    } catch (e) {
      return false;
    }
  }

  // --- DONNÉES DE FALLBACK (cas d'urgence) ---

  static const List<Map<String, dynamic>> _fallbackRegions = [
    {'code': '01', 'nom': 'BOUCLE DU MOUHOUN'},
    {'code': '02', 'nom': 'CASCADES'},
    {'code': '03', 'nom': 'CENTRE'},
    {'code': '04', 'nom': 'CENTRE-EST'},
    {'code': '05', 'nom': 'CENTRE-NORD'},
    {'code': '06', 'nom': 'CENTRE-OUEST'},
    {'code': '07', 'nom': 'CENTRE-SUD'},
    {'code': '08', 'nom': 'EST'},
    {'code': '09', 'nom': 'HAUTS-BASSINS'},
    {'code': '10', 'nom': 'NORD'},
    {'code': '11', 'nom': 'PLATEAU-CENTRAL'},
    {'code': '12', 'nom': 'SAHEL'},
    {'code': '13', 'nom': 'SUD-OUEST'},
  ];
}

// --- CLASSES UTILITAIRES POUR LA COMPATIBILITÉ ---

/// Classe utilitaire pour maintenir la compatibilité avec l'ancien système
class GeographieUtils {
  /// Obtient toutes les provinces d'une région donnée (compatibilité)
  static List<String> getProvincesByRegion(String region) {
    final regionCode = GeographieFirestore.getRegionCodeByName(region);
    if (regionCode == null) return [];

    final provinces = GeographieFirestore.getProvincesForRegion(regionCode);
    return provinces.map((p) => p['nom'].toString()).toList();
  }

  /// Obtient toutes les communes d'une province donnée (compatibilité)
  static List<String> getCommunesByProvince(String province) {
    // Recherche dans toutes les régions pour trouver la province
    for (final region in GeographieFirestore.regionsBurkina) {
      final regionCode = region['code'];
      final provinces = GeographieFirestore.getProvincesForRegion(regionCode);

      for (final prov in provinces) {
        if (prov['nom'].toString().toLowerCase() == province.toLowerCase()) {
          final provinceCode = prov['code'];
          final communes = GeographieFirestore.getCommunesForProvince(
              regionCode, provinceCode);
          return communes.map((c) => c['nom'].toString()).toList();
        }
      }
    }
    return [];
  }

  /// Obtient tous les villages d'une commune donnée (compatibilité)
  static List<String> getVillagesByCommune(String commune) {
    // Recherche dans toutes les communes pour trouver les villages
    for (final region in GeographieFirestore.regionsBurkina) {
      final regionCode = region['code'];
      final provinces = GeographieFirestore.getProvincesForRegion(regionCode);

      for (final province in provinces) {
        final provinceCode = province['code'];
        final communes = GeographieFirestore.getCommunesForProvince(
            regionCode, provinceCode);

        for (final comm in communes) {
          if (comm['nom'].toString().toLowerCase() == commune.toLowerCase()) {
            final communeCode = comm['code'];
            final villages = GeographieFirestore.getVillagesForCommune(
                regionCode, provinceCode, communeCode);
            return villages.map((v) => v['nom'].toString()).toList();
          }
        }
      }
    }
    return [];
  }

  /// Trouve la région d'une province donnée (compatibilité)
  static String? getRegionByProvince(String province) {
    for (final region in GeographieFirestore.regionsBurkina) {
      final regionCode = region['code'];
      final provinces = GeographieFirestore.getProvincesForRegion(regionCode);

      if (provinces.any(
          (p) => p['nom'].toString().toLowerCase() == province.toLowerCase())) {
        return region['nom'];
      }
    }
    return null;
  }

  /// Trouve la province d'une commune donnée (compatibilité)
  static String? getProvinceByCommune(String commune) {
    for (final region in GeographieFirestore.regionsBurkina) {
      final regionCode = region['code'];
      final provinces = GeographieFirestore.getProvincesForRegion(regionCode);

      for (final province in provinces) {
        final provinceCode = province['code'];
        final communes = GeographieFirestore.getCommunesForProvince(
            regionCode, provinceCode);

        if (communes.any((c) =>
            c['nom'].toString().toLowerCase() == commune.toLowerCase())) {
          return province['nom'];
        }
      }
    }
    return null;
  }

  /// Trouve la commune d'un village donné (compatibilité)
  static String? getCommuneByVillage(String village) {
    for (final region in GeographieFirestore.regionsBurkina) {
      final regionCode = region['code'];
      final provinces = GeographieFirestore.getProvincesForRegion(regionCode);

      for (final province in provinces) {
        final provinceCode = province['code'];
        final communes = GeographieFirestore.getCommunesForProvince(
            regionCode, provinceCode);

        for (final commune in communes) {
          final communeCode = commune['code'];
          final villages = GeographieFirestore.getVillagesForCommune(
              regionCode, provinceCode, communeCode);

          if (villages.any((v) =>
              v['nom'].toString().toLowerCase() == village.toLowerCase())) {
            return commune['nom'];
          }
        }
      }
    }
    return null;
  }

  /// Recherche géographique complète (compatibilité)
  static Map<String, String?> getCompleteLocation(String village) {
    final commune = getCommuneByVillage(village);
    final province = commune != null ? getProvinceByCommune(commune) : null;
    final region = province != null ? getRegionByProvince(province) : null;

    return {
      'region': region,
      'province': province,
      'commune': commune,
      'village': village.toUpperCase(),
    };
  }

  /// Valide si une hiérarchie géographique est cohérente (compatibilité)
  static bool validateHierarchy({
    String? region,
    String? province,
    String? commune,
    String? village,
  }) {
    if (region != null && province != null) {
      if (!getProvincesByRegion(region).contains(province.toUpperCase())) {
        return false;
      }
    }

    if (province != null && commune != null) {
      if (!getCommunesByProvince(province).contains(commune.toUpperCase())) {
        return false;
      }
    }

    if (commune != null && village != null) {
      if (!getVillagesByCommune(commune).contains(village.toUpperCase())) {
        return false;
      }
    }

    return true;
  }

  /// Recherche par nom partiel - régions (compatibilité)
  static List<String> searchRegions(String query) {
    return GeographieFirestore.regionsBurkina
        .where((r) =>
            r['nom'].toString().toLowerCase().contains(query.toLowerCase()))
        .map((r) => r['nom'].toString())
        .toList();
  }

  /// Recherche par nom partiel - provinces (compatibilité)
  static List<String> searchProvinces(String query, {String? region}) {
    if (region != null) {
      return getProvincesByRegion(region)
          .where((p) => p.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } else {
      // Recherche dans toutes les provinces
      final allProvinces = <String>[];
      for (final reg in GeographieFirestore.regionsBurkina) {
        final provinces =
            GeographieFirestore.getProvincesForRegion(reg['code']);
        allProvinces.addAll(provinces.map((p) => p['nom'].toString()));
      }
      return allProvinces
          .where((p) => p.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  /// Recherche par nom partiel - communes (compatibilité)
  static List<String> searchCommunes(String query, {String? province}) {
    if (province != null) {
      return getCommunesByProvince(province)
          .where((c) => c.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } else {
      // Recherche dans toutes les communes
      final allCommunes = <String>[];
      for (final region in GeographieFirestore.regionsBurkina) {
        final regionCode = region['code'];
        final provinces = GeographieFirestore.getProvincesForRegion(regionCode);
        for (final province in provinces) {
          final provinceCode = province['code'];
          final communes = GeographieFirestore.getCommunesForProvince(
              regionCode, provinceCode);
          allCommunes.addAll(communes.map((c) => c['nom'].toString()));
        }
      }
      return allCommunes
          .where((c) => c.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  /// Recherche par nom partiel - villages (compatibilité)
  static List<String> searchVillages(String query, {String? commune}) {
    if (commune != null) {
      return getVillagesByCommune(commune)
          .where((v) => v.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } else {
      // Recherche dans tous les villages
      final allVillages = <String>[];
      for (final region in GeographieFirestore.regionsBurkina) {
        final regionCode = region['code'];
        final provinces = GeographieFirestore.getProvincesForRegion(regionCode);
        for (final province in provinces) {
          final provinceCode = province['code'];
          final communes = GeographieFirestore.getCommunesForProvince(
              regionCode, provinceCode);
          for (final commune in communes) {
            final communeCode = commune['code'];
            final villages = GeographieFirestore.getVillagesForCommune(
                regionCode, provinceCode, communeCode);
            allVillages.addAll(villages.map((v) => v['nom'].toString()));
          }
        }
      }
      return allVillages
          .where((v) => v.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }
}

// --- ALIAS DE COMPATIBILITÉ ---

/// Alias pour maintenir la compatibilité avec l'ancien système
typedef GeographieData = GeographieFirestore;

// Liste de compatibilité pour l'ancien système
List<String> get regionsBurkina =>
    GeographieFirestore.regionsBurkina.map((r) => r['nom'].toString()).toList();

// Maps de compatibilité pour l'ancien système
Map<String, List<String>> get provincesParRegion {
  final Map<String, List<String>> result = {};
  for (final region in GeographieFirestore.regionsBurkina) {
    final regionName = region['nom'].toString();
    final regionCode = region['code'];
    final provinces = GeographieFirestore.getProvincesForRegion(regionCode);
    result[regionName] = provinces.map((p) => p['nom'].toString()).toList();
  }
  return result;
}
