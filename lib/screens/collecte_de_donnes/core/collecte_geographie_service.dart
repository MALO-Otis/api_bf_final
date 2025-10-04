import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../administration/models/geographie_models.dart';

/// Service pour récupérer les données géographiques depuis Firestore
/// au lieu d'utiliser des données codées en dur.
/// Les données proviennent de /metiers/geographie_data
class CollecteGeographieService extends GetxService {
  final FirebaseFirestore _firestore;

  // Cache des données pour éviter les appels répétés
  final RxList<GeoRegion> _regions = <GeoRegion>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;

  CollecteGeographieService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Getters observables
  List<GeoRegion> get regions => _regions;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;

  @override
  void onInit() {
    super.onInit();
    print('[CollecteGeographieService] 🚀 Service initialisé via onInit()');
    print(
        '[CollecteGeographieService] 📊 État initial : ${_regions.length} régions chargées');
    loadGeographieData();
  }

  /// Charge les données géographiques depuis Firestore
  Future<void> loadGeographieData() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      print(
          '[CollecteGeographieService] 🔄 Début du chargement des données géographiques...');

      final doc =
          await _firestore.collection('metiers').doc('geographie_data').get();

      print(
          '[CollecteGeographieService] 📄 Document récupéré: exists=${doc.exists}');

      if (!doc.exists) {
        throw Exception('Document geographie_data non trouvé dans /metiers/');
      }

      final data = doc.data()!;
      print('[CollecteGeographieService] 📊 Données brutes: ${data.keys}');

      final regionsData = data['regions'] as List<dynamic>? ?? [];
      print(
          '[CollecteGeographieService] 🗺️  Régions trouvées: ${regionsData.length}');

      final loadedRegions = regionsData.map((regionMap) {
        return GeoRegion.fromMap(regionMap as Map<String, dynamic>);
      }).toList();

      _regions.value = loadedRegions;

      print(
          '[CollecteGeographieService] ✅ ${loadedRegions.length} régions chargées avec succès');
      print(
          '[CollecteGeographieService] 📋 Première région: ${loadedRegions.isNotEmpty ? loadedRegions.first.nom : "Aucune"}');

      // Logs détaillés pour vérifier la structure
      if (loadedRegions.isNotEmpty) {
        final firstRegion = loadedRegions.first;
        print('[CollecteGeographieService] 🔍 Détail première région:');
        print('  - Code: ${firstRegion.code}');
        print('  - Nom: ${firstRegion.nom}');
        print('  - Provinces: ${firstRegion.provinces.length}');

        if (firstRegion.provinces.isNotEmpty) {
          final firstProvince = firstRegion.provinces.first;
          print(
              '  - Première province: ${firstProvince.nom} (${firstProvince.communes.length} communes)');

          if (firstProvince.communes.isNotEmpty) {
            final firstCommune = firstProvince.communes.first;
            print(
                '  - Première commune: ${firstCommune.nom} (${firstCommune.villages.length} villages)');
          }
        }
      }
    } catch (e) {
      _error.value = 'Erreur lors du chargement: $e';
      print('[CollecteGeographieService] ❌ Erreur: $e');
    } finally {
      _isLoading.value = false;
      print(
          '[CollecteGeographieService] 🏁 Chargement terminé. isLoading=${_isLoading.value}, regions=${_regions.length}');
    }
  }

  /// Recharge les données depuis Firestore
  Future<void> refreshData() async {
    await loadGeographieData();
  }

  /// Récupère une région par son nom
  GeoRegion? getRegionByName(String name) {
    return _regions.firstWhereOrNull((region) => region.nom == name);
  }

  /// Récupère une région par son code
  GeoRegion? getRegionByCode(String code) {
    return _regions.firstWhereOrNull((region) => region.code == code);
  }

  /// Récupère les provinces d'une région par le code de la région
  List<GeoProvince> getProvincesForRegionCode(String regionCode) {
    final region = getRegionByCode(regionCode);
    return region?.provinces ?? [];
  }

  /// Récupère une province par région et nom de province
  GeoProvince? getProvince(String regionName, String provinceName) {
    final regionCode = getRegionCodeByName(regionName);
    if (regionCode == null) return null;
    final provinces = getProvincesForRegionCode(regionCode);
    return provinces
        .firstWhereOrNull((province) => province.nom == provinceName);
  }

  /// Récupère les communes d'une province
  List<GeoCommune> getCommunes(String regionName, String provinceName) {
    final province = getProvince(regionName, provinceName);
    return province?.communes ?? [];
  }

  /// Récupère une commune spécifique
  GeoCommune? getCommune(
      String regionName, String provinceName, String communeName) {
    final communes = getCommunes(regionName, provinceName);
    return communes.firstWhereOrNull((commune) => commune.nom == communeName);
  }

  /// Récupère les villages d'une commune
  List<GeoVillage> getVillages(
      String regionName, String provinceName, String communeName) {
    final commune = getCommune(regionName, provinceName, communeName);
    return commune?.villages ?? [];
  }

  /// Récupère un village spécifique
  GeoVillage? getVillage(String regionName, String provinceName,
      String communeName, String villageName) {
    final villages = getVillages(regionName, provinceName, communeName);
    return villages.firstWhereOrNull((village) => village.nom == villageName);
  }

  /// Méthodes de compatibilité avec l'ancien système GeographieData

  /// Récupère le code d'un village
  String getVillageCodeByName(String regionCode, String provinceCode,
      String communeCode, String villageName) {
    final region = getRegionByCode(regionCode);
    final province =
        region?.provinces.firstWhereOrNull((p) => p.code == provinceCode);
    final commune =
        province?.communes.firstWhereOrNull((c) => c.code == communeCode);
    final village =
        commune?.villages.firstWhereOrNull((v) => v.nom == villageName);
    return village?.code ?? '';
  }

  /// Récupère les provinces pour une région (format Map pour compatibilité)
  List<Map<String, dynamic>> getProvincesForRegionMap(String regionCode) {
    final provinces = getProvincesForRegionCode(regionCode);
    return provinces
        .map((province) => {
              'code': province.code,
              'nom': province.nom,
            })
        .toList();
  }

  /// Récupère les communes pour une province (format Map pour compatibilité)
  List<Map<String, dynamic>> getCommunesForProvinceMap(
      String regionCode, String provinceCode) {
    final region = getRegionByCode(regionCode);
    final province =
        region?.provinces.firstWhereOrNull((p) => p.code == provinceCode);
    return province?.communes
            .map((commune) => {
                  'code': commune.code,
                  'nom': commune.nom,
                })
            .toList() ??
        [];
  }

  /// Récupère les villages pour une commune (format Map pour compatibilité)
  List<Map<String, dynamic>> getVillagesForCommuneMap(
      String regionCode, String provinceCode, String communeCode) {
    final region = getRegionByCode(regionCode);
    final province =
        region?.provinces.firstWhereOrNull((p) => p.code == provinceCode);
    final commune =
        province?.communes.firstWhereOrNull((c) => c.code == communeCode);
    return commune?.villages
            .map((village) => {
                  'code': village.code,
                  'nom': village.nom,
                })
            .toList() ??
        [];
  }

  /// Format location pour affichage (compatible avec l'ancien système)
  String formatLocationCodeFromMap(Map<String, dynamic> localisation) {
    final region = localisation['region']?.toString() ?? '';
    final province = localisation['province']?.toString() ?? '';
    final commune = localisation['commune']?.toString() ?? '';
    final village = localisation['village']?.toString() ?? '';

    if (village.isNotEmpty) {
      return '$region › $province › $commune › $village';
    } else if (commune.isNotEmpty) {
      return '$region › $province › $commune';
    } else if (province.isNotEmpty) {
      return '$region › $province';
    } else if (region.isNotEmpty) {
      return region;
    }
    return 'Non spécifié';
  }

  /// Méthode pour obtenir les régions au format Map (compatibilité)
  List<Map<String, dynamic>> get regionsMap {
    return _regions
        .map((region) => {
              'code': region.code,
              'nom': region.nom,
            })
        .toList();
  }

  /// Méthode pour obtenir les noms des régions (format List de String)
  List<String> getRegionNames() {
    return _regions.map((region) => region.nom).toList();
  }

  /// Méthode pour obtenir les noms des provinces d'une région
  List<String> getProvinceNames(String regionName) {
    final regionCode = getRegionCodeByName(regionName);
    if (regionCode == null) return [];
    final provinces = getProvincesForRegion(regionCode);
    return provinces.map((province) => province['nom']!).toList();
  }

  /// Méthode pour obtenir les noms des communes d'une province
  List<String> getCommuneNames(String regionName, String provinceName) {
    final communes = getCommunes(regionName, provinceName);
    return communes.map((commune) => commune.nom).toList();
  }

  /// Méthode pour obtenir les noms des villages d'une commune
  List<String> getVillageNames(
      String regionName, String provinceName, String communeName) {
    final villages = getVillages(regionName, provinceName, communeName);
    return villages.map((village) => village.nom).toList();
  }

  /// Vérifie si les données sont disponibles
  bool get hasData => _regions.isNotEmpty;

  /// Vérifie si les données sont chargées (alias pour hasData)
  bool get isDataLoaded => hasData;

  /// Méthode utilitaire pour obtenir les statistiques des données
  Map<String, int> getStats() {
    int provinceCount = 0;
    int communeCount = 0;
    int villageCount = 0;

    for (final region in _regions) {
      provinceCount += region.provinces.length;
      for (final province in region.provinces) {
        communeCount += province.communes.length;
        for (final commune in province.communes) {
          villageCount += commune.villages.length;
        }
      }
    }

    return {
      'regions': _regions.length,
      'provinces': provinceCount,
      'communes': communeCount,
      'villages': villageCount,
    };
  }

  // MÉTHODES DE REMPLACEMENT POUR GeographieData

  /// Obtient le code d'une région par son nom
  String? getRegionCodeByName(String regionName) {
    final region = _regions.firstWhereOrNull((r) => r.nom == regionName);
    return region?.code;
  }

  /// Obtient les provinces d'une région
  List<Map<String, String>> getProvincesForRegion(String regionCode) {
    final region = _regions.firstWhereOrNull((r) => r.code == regionCode);
    return region?.provinces
            .map((p) => {'code': p.code, 'nom': p.nom})
            .toList() ??
        [];
  }

  /// Obtient le code d'une province par son nom dans une région
  String? getProvinceCodeByName(String regionCode, String provinceName) {
    final region = _regions.firstWhereOrNull((r) => r.code == regionCode);
    final province =
        region?.provinces.firstWhereOrNull((p) => p.nom == provinceName);
    return province?.code;
  }

  /// Obtient les communes d'une province
  List<Map<String, String>> getCommunesForProvince(
      String regionCode, String provinceCode) {
    final region = _regions.firstWhereOrNull((r) => r.code == regionCode);
    final province =
        region?.provinces.firstWhereOrNull((p) => p.code == provinceCode);
    return province?.communes
            .map((c) => {'code': c.code, 'nom': c.nom})
            .toList() ??
        [];
  }

  /// Obtient le code d'une commune par son nom dans une province
  String? getCommuneCodeByName(
      String regionCode, String provinceCode, String communeName) {
    final region = _regions.firstWhereOrNull((r) => r.code == regionCode);
    final province =
        region?.provinces.firstWhereOrNull((p) => p.code == provinceCode);
    final commune =
        province?.communes.firstWhereOrNull((c) => c.nom == communeName);
    return commune?.code;
  }

  /// Obtient les villages d'une commune
  List<Map<String, String>> getVillagesForCommune(
      String regionCode, String provinceCode, String communeCode) {
    final region = _regions.firstWhereOrNull((r) => r.code == regionCode);
    final province =
        region?.provinces.firstWhereOrNull((p) => p.code == provinceCode);
    final commune =
        province?.communes.firstWhereOrNull((c) => c.code == communeCode);
    return commune?.villages
            .map((v) => {'code': v.code, 'nom': v.nom})
            .toList() ??
        [];
  }

  /// Formate le code de localisation à partir de paramètres nommés
  String formatLocationCode({
    String? regionName,
    String? provinceName,
    String? communeName,
    String? villageName,
  }) {
    final localisation = <String, String>{};
    if (regionName != null) localisation['region'] = regionName;
    if (provinceName != null) localisation['province'] = provinceName;
    if (communeName != null) localisation['commune'] = communeName;
    if (villageName != null) localisation['village'] = villageName;

    return formatLocationCodeFromMap(localisation);
  }
}
