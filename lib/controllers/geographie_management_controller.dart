import 'package:get/get.dart';
import '../screens/administration/models/geographie_models.dart';
import '../screens/administration/services/geographie_management_service.dart';

class GeographieManagementController extends GetxController {
  final GeographieManagementService _service =
      Get.find<GeographieManagementService>();

  // Observable pour l'état de chargement
  RxBool get isLoading => _service.isLoading;

  // Observable pour les erreurs
  RxnString get error => _service.error;

  // Observable pour les données
  RxList<GeoRegion> get regions => _service.regions;

  // Indicateur de modifications non sauvegardées
  RxBool get hasPendingChanges => _service.hasPendingChanges;

  @override
  void onInit() {
    super.onInit();
    // Charger les données au démarrage
    loadData();
  }

  /// Charge les données géographiques
  Future<void> loadData() async {
    await _service.loadGeographieData();
  }

  /// Actualise les données
  Future<void> refreshData() async {
    await _service.loadGeographieData();
  }

  /// Sauvegarde les données
  Future<bool> saveData() async {
    return _service.saveGeographieData();
  }

  // Méthodes pour les régions
  Future<bool> addRegion(String nom) async {
    return _service.addRegion(nom);
  }

  Future<bool> updateRegion(int index, String nouveauNom) async {
    return _service.updateRegion(index, nouveauNom);
  }

  Future<bool> deleteRegion(int index) async {
    return _service.deleteRegion(index);
  }

  // Méthodes pour les provinces
  Future<bool> addProvince(int regionIndex, String nom) async {
    return _service.addProvince(regionIndex, nom);
  }

  Future<bool> updateProvince(
      int regionIndex, int provinceIndex, String nouveauNom) async {
    return _service.updateProvince(regionIndex, provinceIndex, nouveauNom);
  }

  Future<bool> deleteProvince(int regionIndex, int provinceIndex) async {
    return _service.deleteProvince(regionIndex, provinceIndex);
  }

  // Méthodes pour les communes
  Future<bool> addCommune(
      int regionIndex, int provinceIndex, String nom) async {
    return _service.addCommune(regionIndex, provinceIndex, nom);
  }

  Future<bool> updateCommune(int regionIndex, int provinceIndex,
      int communeIndex, String nouveauNom) async {
    return _service.updateCommune(
        regionIndex, provinceIndex, communeIndex, nouveauNom);
  }

  Future<bool> deleteCommune(
      int regionIndex, int provinceIndex, int communeIndex) async {
    return _service.deleteCommune(regionIndex, provinceIndex, communeIndex);
  }

  // Méthodes pour les villages
  Future<bool> addVillage(
      int regionIndex, int provinceIndex, int communeIndex, String nom) async {
    return _service.addVillage(regionIndex, provinceIndex, communeIndex, nom);
  }

  Future<bool> updateVillage(int regionIndex, int provinceIndex,
      int communeIndex, int villageIndex, String nouveauNom) async {
    return _service.updateVillage(
        regionIndex, provinceIndex, communeIndex, villageIndex, nouveauNom);
  }

  Future<bool> deleteVillage(int regionIndex, int provinceIndex,
      int communeIndex, int villageIndex) async {
    return _service.deleteVillage(
        regionIndex, provinceIndex, communeIndex, villageIndex);
  }

  /// Obtient les statistiques totales
  Map<String, int> getStatistics() {
    final totalRegions = regions.length;
    final totalProvinces =
        regions.fold<int>(0, (total, region) => total + region.provincesCount);
    final totalCommunes =
        regions.fold<int>(0, (total, region) => total + region.communesCount);
    final totalVillages =
        regions.fold<int>(0, (total, region) => total + region.villagesCount);

    return {
      'regions': totalRegions,
      'provinces': totalProvinces,
      'communes': totalCommunes,
      'villages': totalVillages,
    };
  }

  /// Recherche dans les données géographiques
  List<Map<String, dynamic>> searchLocation(String query) {
    if (query.isEmpty) return [];

    List<Map<String, dynamic>> results = [];
    final lowerQuery = query.toLowerCase();

    for (int regionIndex = 0; regionIndex < regions.length; regionIndex++) {
      final region = regions[regionIndex];
      final regionName = region.nom.toLowerCase();

      // Recherche dans les régions
      if (regionName.contains(lowerQuery)) {
        results.add({
          'type': 'region',
          'nom': region.nom,
          'path': 'Région',
          'regionIndex': regionIndex,
        });
      }

      for (int provinceIndex = 0;
          provinceIndex < region.provinces.length;
          provinceIndex++) {
        final province = region.provinces[provinceIndex];
        final provinceName = province.nom.toLowerCase();

        // Recherche dans les provinces
        if (provinceName.contains(lowerQuery)) {
          results.add({
            'type': 'province',
            'nom': province.nom,
            'path': '${region.nom} > Province',
            'regionIndex': regionIndex,
            'provinceIndex': provinceIndex,
          });
        }

        for (int communeIndex = 0;
            communeIndex < province.communes.length;
            communeIndex++) {
          final commune = province.communes[communeIndex];
          final communeName = commune.nom.toLowerCase();

          // Recherche dans les communes
          if (communeName.contains(lowerQuery)) {
            results.add({
              'type': 'commune',
              'nom': commune.nom,
              'path': '${region.nom} > ${province.nom} > Commune',
              'regionIndex': regionIndex,
              'provinceIndex': provinceIndex,
              'communeIndex': communeIndex,
            });
          }

          for (int villageIndex = 0;
              villageIndex < commune.villages.length;
              villageIndex++) {
            final village = commune.villages[villageIndex];
            final villageName = village.nom.toLowerCase();

            // Recherche dans les villages
            if (villageName.contains(lowerQuery)) {
              results.add({
                'type': 'village',
                'nom': village.nom,
                'path':
                    '${region.nom} > ${province.nom} > ${commune.nom} > Village',
                'regionIndex': regionIndex,
                'provinceIndex': provinceIndex,
                'communeIndex': communeIndex,
                'villageIndex': villageIndex,
              });
            }
          }
        }
      }
    }

    return results;
  }

  /// Valide la structure des données
  bool validateData() {
    try {
      for (var region in regions) {
        if (region.nom.isEmpty) {
          return false;
        }

        for (var province in region.provinces) {
          if (province.nom.isEmpty) {
            return false;
          }

          for (var commune in province.communes) {
            if (commune.nom.isEmpty) {
              return false;
            }

            for (var village in commune.villages) {
              if (village.nom.isEmpty) {
                return false;
              }
            }
          }
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Exporte les données au format JSON
  Map<String, dynamic> exportData() {
    return {
      'regions': regions.map((region) => region.toMap()).toList(),
      'metadata': {
        'exportDate': DateTime.now().toIso8601String(),
        'totalRegions': regions.length,
        'statistics': getStatistics(),
      }
    };
  }

  /// Importe des données depuis un format JSON
  Future<bool> importData(Map<String, dynamic> data) async {
    try {
      if (data['regions'] != null) {
        final importedRegions =
            List<Map<String, dynamic>>.from(data['regions']);

        final parsedRegions = importedRegions
            .map((region) =>
                GeoRegion.fromMap(Map<String, dynamic>.from(region)))
            .toList();

        // Valider les données importées
        for (var region in parsedRegions) {
          if (region.nom.isEmpty) {
            throw Exception('Format de données invalide');
          }
        }

        // Remplacer les données actuelles
        _service.regions.clear();
        _service.regions.addAll(parsedRegions);
        _service.hasPendingChanges.value = true;

        return await saveData();
      }
      return false;
    } catch (e) {
      _service.error.value = 'Erreur lors de l\'importation: $e';
      return false;
    }
  }
}
