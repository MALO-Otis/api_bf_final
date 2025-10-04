import 'package:get/get.dart';
import '../models/geographie_models.dart';
import '../../../data/geographe/geographie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service pour la gestion des données géographiques.
/// Sauvegarde toutes les informations dans la collection 'metiers', document 'geographie_data'.
class GeographieManagementService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collectionName = 'metiers';
  static const String _documentId = 'geographie_data';

  final RxList<GeoRegion> regions = <GeoRegion>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();
  final RxBool hasPendingChanges = false.obs;

  void _log(
    String message, {
    Map<String, dynamic>? data,
    bool isError = false,
  }) {
    final buffer = StringBuffer('[GeographieService] $message');
    if (data != null && data.isNotEmpty) {
      final extras =
          data.entries.map((entry) => '${entry.key}=${entry.value}').join(', ');
      buffer.write(' | $extras');
    }
    Get.log(buffer.toString(), isError: isError);
  }

  @override
  void onInit() {
    super.onInit();
    loadGeographieData();
  }

  Future<void> loadGeographieData() async {
    _log('load:start');
    try {
      isLoading.value = true;
      error.value = null;

      final doc =
          await _firestore.collection(_collectionName).doc(_documentId).get();

      if (doc.exists && doc.data() != null && doc.data()!['regions'] != null) {
        final rawRegions = List<dynamic>.from(doc.data()!['regions']);
        regions.assignAll(rawRegions
            .map((regionMap) => GeoRegion.fromMap(
                Map<String, dynamic>.from(regionMap as Map<dynamic, dynamic>)))
            .toList());
        hasPendingChanges.value = false;
        _log('load:success', data: {'regions': regions.length});
      } else {
        _log('load:empty-remote', data: {'fallback': 'initialize-defaults'});
        await _initializeDefaultData();
      }
    } catch (e) {
      error.value = 'Erreur lors du chargement des données: $e';
      _log('load:error', data: {'error': e.toString()}, isError: true);
      if (regions.isEmpty) {
        regions.assignAll(_buildDefaultRegionsFromStatic());
        _log('load:error-fallback-defaults', data: {'regions': regions.length});
      }
    } finally {
      isLoading.value = false;
      _log('load:finished', data: {
        'regions': regions.length,
        'pendingChanges': hasPendingChanges.value,
      });
    }
  }

  Future<void> _initializeDefaultData() async {
    final defaults = _buildDefaultRegionsFromStatic();
    _log('defaults:seed', data: {'regions': defaults.length});
    regions.assignAll(defaults);
    hasPendingChanges.value = true;
    await saveGeographieData();
  }

  Future<void> resetToDefaultData() async {
    _log('defaults:reset-requested');
    await _initializeDefaultData();
    Get.snackbar(
      'Réinitialisé',
      'Les données géographiques ont été rechargées depuis la source 2025.',
      snackPosition: SnackPosition.TOP,
    );
  }

  List<GeoRegion> _buildDefaultRegionsFromStatic() {
    final defaults = <GeoRegion>[];

    for (final regionEntry in GeographieData.regionsBurkina) {
      final regionCode = (regionEntry['code'] ?? '').toString();
      final regionName = (regionEntry['nom'] ?? '').toString();

      final provincesData =
          GeographieData.provincesParRegion[regionCode] ?? const [];
      final provinces = provincesData.map((provinceEntry) {
        final provinceCode = (provinceEntry['code'] ?? '').toString();
        final provinceName = (provinceEntry['nom'] ?? '').toString();

        final communesData =
            GeographieData.communesParProvince['$regionCode-$provinceCode'] ??
                const [];
        final communes = communesData.map((communeEntry) {
          final communeCode = (communeEntry['code'] ?? '').toString();
          final communeName = (communeEntry['nom'] ?? '').toString();

          final villages =
              _resolveVillages(regionCode, provinceCode, communeCode);

          return GeoCommune(
            code: communeCode,
            nom: communeName,
            villages: villages,
          );
        }).toList();

        return GeoProvince(
          code: provinceCode,
          nom: provinceName,
          communes: communes,
        );
      }).toList();

      defaults.add(GeoRegion(
        code: regionCode,
        nom: regionName,
        provinces: provinces,
      ));
    }

    return defaults;
  }

  List<GeoVillage> _resolveVillages(
    String regionCode,
    String provinceCode,
    String communeCode,
  ) {
    final prefix = '$regionCode-$provinceCode-$communeCode';
    final seen = <String>{};
    final results = <GeoVillage>[];

    GeographieData.villagesParCommune.forEach((key, villageList) {
      if (key == prefix || key.startsWith('$prefix-')) {
        for (final villageEntry in villageList) {
          final name = (villageEntry['nom'] ?? '').toString().trim();
          if (name.isEmpty) continue;

          final normalized = name.toUpperCase();
          if (seen.add(normalized)) {
            final rawCode = (villageEntry['code'] ?? '').toString();
            final formattedCode = rawCode.isEmpty
                ? (results.length + 1).toString().padLeft(2, '0')
                : rawCode.padLeft(2, '0');
            results.add(GeoVillage(code: formattedCode, nom: name));
          }
        }
      }
    });

    results.sort((a, b) => a.nom.compareTo(b.nom));
    return results;
  }

  Future<bool> saveGeographieData() async {
    try {
      isLoading.value = true;
      error.value = null;

      final totalRegions = regions.length;
      final totalProvinces =
          regions.fold<int>(0, (total, r) => total + r.provincesCount);
      final totalCommunes =
          regions.fold<int>(0, (total, r) => total + r.communesCount);
      final totalVillages =
          regions.fold<int>(0, (total, r) => total + r.villagesCount);

      _log('save:start', data: {
        'regions': totalRegions,
        'provinces': totalProvinces,
        'communes': totalCommunes,
        'villages': totalVillages,
      });

      final data = {
        'regions': regions.map((r) => r.toMap()).toList(),
        'metadata': {
          'version': '2025.1',
          'lastUpdated': FieldValue.serverTimestamp(),
          'counts': {
            'regions': totalRegions,
            'provinces': totalProvinces,
            'communes': totalCommunes,
            'villages': totalVillages,
          },
          'source': 'geographie.dart',
        },
      };

      await _firestore
          .collection(_collectionName)
          .doc(_documentId)
          .set(data, SetOptions(merge: true));

      hasPendingChanges.value = false;

      Get.snackbar(
        'Succès',
        'Données géographiques sauvegardées avec succès',
        snackPosition: SnackPosition.TOP,
      );

      _log('save:success', data: {
        'regions': totalRegions,
        'pendingChanges': hasPendingChanges.value,
      });

      return true;
    } catch (e) {
      error.value = 'Erreur lors de la sauvegarde: $e';
      Get.snackbar(
        'Erreur',
        'Impossible de sauvegarder: $e',
        snackPosition: SnackPosition.TOP,
      );
      _log('save:error', data: {'error': e.toString()}, isError: true);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addRegion(String nom) async {
    final trimmed = nom.trim();
    if (trimmed.isEmpty) {
      error.value = 'Le nom de la région ne peut pas être vide';
      _log('region:add:invalid-name', data: {'input': nom}, isError: true);
      return false;
    }

    final newCode = _generateNextCode(regions.map((r) => r.code).toList());
    regions.add(GeoRegion(code: newCode, nom: trimmed, provinces: []));
    regions.refresh();
    hasPendingChanges.value = true;
    _log('region:add:success', data: {
      'code': newCode,
      'name': trimmed,
      'totalRegions': regions.length,
    });
    return true;
  }

  Future<bool> updateRegion(int regionIndex, String newNom) async {
    final region = _getRegion(regionIndex);
    final trimmed = newNom.trim();
    if (region == null || trimmed.isEmpty) {
      error.value = 'Impossible de modifier la région sélectionnée';
      _log('region:update:invalid',
          data: {'index': regionIndex, 'input': newNom}, isError: true);
      return false;
    }

    region.nom = trimmed;
    regions.refresh();
    hasPendingChanges.value = true;
    _log('region:update:success',
        data: {'index': regionIndex, 'name': trimmed});
    return true;
  }

  Future<bool> deleteRegion(int regionIndex) async {
    if (regionIndex < 0 || regionIndex >= regions.length) {
      error.value = 'Indice de région invalide';
      _log('region:delete:invalid-index',
          data: {'index': regionIndex}, isError: true);
      return false;
    }

    regions.removeAt(regionIndex);
    regions.refresh();
    hasPendingChanges.value = true;
    _log('region:delete:success', data: {
      'index': regionIndex,
      'remainingRegions': regions.length,
    });
    return true;
  }

  Future<bool> addProvince(int regionIndex, String nom) async {
    final region = _getRegion(regionIndex);
    final trimmed = nom.trim();
    if (region == null || trimmed.isEmpty) {
      error.value = 'Impossible d\'ajouter la province';
      _log('province:add:invalid',
          data: {'regionIndex': regionIndex, 'input': nom}, isError: true);
      return false;
    }

    final newCode =
        _generateNextCode(region.provinces.map((p) => p.code).toList());
    region.provinces
        .add(GeoProvince(code: newCode, nom: trimmed, communes: []));
    regions.refresh();
    hasPendingChanges.value = true;
    _log('province:add:success', data: {
      'regionIndex': regionIndex,
      'code': newCode,
      'name': trimmed,
      'totalProvinces': region.provinces.length,
    });
    return true;
  }

  Future<bool> updateProvince(
      int regionIndex, int provinceIndex, String newNom) async {
    final province = _getProvince(regionIndex, provinceIndex);
    final trimmed = newNom.trim();
    if (province == null || trimmed.isEmpty) {
      error.value = 'Impossible de modifier la province';
      _log('province:update:invalid',
          data: {
            'regionIndex': regionIndex,
            'provinceIndex': provinceIndex,
            'input': newNom,
          },
          isError: true);
      return false;
    }

    province.nom = trimmed;
    regions.refresh();
    hasPendingChanges.value = true;
    _log('province:update:success', data: {
      'regionIndex': regionIndex,
      'provinceIndex': provinceIndex,
      'name': trimmed,
    });
    return true;
  }

  Future<bool> deleteProvince(int regionIndex, int provinceIndex) async {
    final region = _getRegion(regionIndex);
    if (region == null ||
        provinceIndex < 0 ||
        provinceIndex >= region.provinces.length) {
      error.value = 'Indice de province invalide';
      _log('province:delete:invalid',
          data: {
            'regionIndex': regionIndex,
            'provinceIndex': provinceIndex,
          },
          isError: true);
      return false;
    }

    region.provinces.removeAt(provinceIndex);
    regions.refresh();
    hasPendingChanges.value = true;
    _log('province:delete:success', data: {
      'regionIndex': regionIndex,
      'provinceIndex': provinceIndex,
      'remainingProvinces': region.provinces.length,
    });
    return true;
  }

  Future<bool> addCommune(
      int regionIndex, int provinceIndex, String nom) async {
    final province = _getProvince(regionIndex, provinceIndex);
    final trimmed = nom.trim();
    if (province == null || trimmed.isEmpty) {
      error.value = 'Impossible d\'ajouter la commune';
      _log('commune:add:invalid',
          data: {
            'regionIndex': regionIndex,
            'provinceIndex': provinceIndex,
            'input': nom,
          },
          isError: true);
      return false;
    }

    final newCode =
        _generateNextCode(province.communes.map((c) => c.code).toList());
    province.communes.add(
      GeoCommune(code: newCode, nom: trimmed, villages: []),
    );
    regions.refresh();
    hasPendingChanges.value = true;
    _log('commune:add:success', data: {
      'regionIndex': regionIndex,
      'provinceIndex': provinceIndex,
      'code': newCode,
      'name': trimmed,
      'totalCommunes': province.communes.length,
    });
    return true;
  }

  Future<bool> updateCommune(int regionIndex, int provinceIndex,
      int communeIndex, String newNom) async {
    final commune = _getCommune(regionIndex, provinceIndex, communeIndex);
    final trimmed = newNom.trim();
    if (commune == null || trimmed.isEmpty) {
      error.value = 'Impossible de modifier la commune';
      _log('commune:update:invalid',
          data: {
            'regionIndex': regionIndex,
            'provinceIndex': provinceIndex,
            'communeIndex': communeIndex,
            'input': newNom,
          },
          isError: true);
      return false;
    }

    commune.nom = trimmed;
    regions.refresh();
    hasPendingChanges.value = true;
    _log('commune:update:success', data: {
      'regionIndex': regionIndex,
      'provinceIndex': provinceIndex,
      'communeIndex': communeIndex,
      'name': trimmed,
    });
    return true;
  }

  Future<bool> deleteCommune(
      int regionIndex, int provinceIndex, int communeIndex) async {
    final province = _getProvince(regionIndex, provinceIndex);
    if (province == null ||
        communeIndex < 0 ||
        communeIndex >= province.communes.length) {
      error.value = 'Indice de commune invalide';
      _log('commune:delete:invalid',
          data: {
            'regionIndex': regionIndex,
            'provinceIndex': provinceIndex,
            'communeIndex': communeIndex,
          },
          isError: true);
      return false;
    }

    province.communes.removeAt(communeIndex);
    regions.refresh();
    hasPendingChanges.value = true;
    _log('commune:delete:success', data: {
      'regionIndex': regionIndex,
      'provinceIndex': provinceIndex,
      'communeIndex': communeIndex,
      'remainingCommunes': province.communes.length,
    });
    return true;
  }

  Future<bool> addVillage(
      int regionIndex, int provinceIndex, int communeIndex, String nom) async {
    final commune = _getCommune(regionIndex, provinceIndex, communeIndex);
    final trimmed = nom.trim();
    if (commune == null || trimmed.isEmpty) {
      error.value = 'Impossible d\'ajouter le village';
      _log('village:add:invalid',
          data: {
            'regionIndex': regionIndex,
            'provinceIndex': provinceIndex,
            'communeIndex': communeIndex,
            'input': nom,
          },
          isError: true);
      return false;
    }

    final newCode =
        _generateNextCode(commune.villages.map((v) => v.code).toList());
    commune.villages.add(GeoVillage(code: newCode, nom: trimmed));
    commune.villages.sort((a, b) => a.nom.compareTo(b.nom));
    regions.refresh();
    hasPendingChanges.value = true;
    _log('village:add:success', data: {
      'regionIndex': regionIndex,
      'provinceIndex': provinceIndex,
      'communeIndex': communeIndex,
      'code': newCode,
      'name': trimmed,
      'totalVillages': commune.villages.length,
    });
    return true;
  }

  Future<bool> updateVillage(int regionIndex, int provinceIndex,
      int communeIndex, int villageIndex, String newNom) async {
    final commune = _getCommune(regionIndex, provinceIndex, communeIndex);
    final trimmed = newNom.trim();
    if (commune == null || trimmed.isEmpty) {
      error.value = 'Impossible de modifier le village';
      _log('village:update:invalid-commune',
          data: {
            'regionIndex': regionIndex,
            'provinceIndex': provinceIndex,
            'communeIndex': communeIndex,
            'input': newNom,
          },
          isError: true);
      return false;
    }

    if (villageIndex < 0 || villageIndex >= commune.villages.length) {
      error.value = 'Indice de village invalide';
      _log('village:update:invalid-index',
          data: {
            'regionIndex': regionIndex,
            'provinceIndex': provinceIndex,
            'communeIndex': communeIndex,
            'villageIndex': villageIndex,
          },
          isError: true);
      return false;
    }

    commune.villages[villageIndex].nom = trimmed;
    commune.villages.sort((a, b) => a.nom.compareTo(b.nom));
    regions.refresh();
    hasPendingChanges.value = true;
    _log('village:update:success', data: {
      'regionIndex': regionIndex,
      'provinceIndex': provinceIndex,
      'communeIndex': communeIndex,
      'villageIndex': villageIndex,
      'name': trimmed,
    });
    return true;
  }

  Future<bool> deleteVillage(int regionIndex, int provinceIndex,
      int communeIndex, int villageIndex) async {
    final commune = _getCommune(regionIndex, provinceIndex, communeIndex);
    if (commune == null ||
        villageIndex < 0 ||
        villageIndex >= commune.villages.length) {
      error.value = 'Indice de village invalide';
      _log('village:delete:invalid',
          data: {
            'regionIndex': regionIndex,
            'provinceIndex': provinceIndex,
            'communeIndex': communeIndex,
            'villageIndex': villageIndex,
          },
          isError: true);
      return false;
    }

    commune.villages.removeAt(villageIndex);
    regions.refresh();
    hasPendingChanges.value = true;
    _log('village:delete:success', data: {
      'regionIndex': regionIndex,
      'provinceIndex': provinceIndex,
      'communeIndex': communeIndex,
      'villageIndex': villageIndex,
      'remainingVillages': commune.villages.length,
    });
    return true;
  }

  GeoRegion? _getRegion(int index) {
    if (index < 0 || index >= regions.length) return null;
    return regions[index];
  }

  GeoProvince? _getProvince(int regionIndex, int provinceIndex) {
    final region = _getRegion(regionIndex);
    if (region == null ||
        provinceIndex < 0 ||
        provinceIndex >= region.provinces.length) {
      return null;
    }
    return region.provinces[provinceIndex];
  }

  GeoCommune? _getCommune(
      int regionIndex, int provinceIndex, int communeIndex) {
    final province = _getProvince(regionIndex, provinceIndex);
    if (province == null ||
        communeIndex < 0 ||
        communeIndex >= province.communes.length) {
      return null;
    }
    return province.communes[communeIndex];
  }

  String _generateNextCode(List<String> existingCodes) {
    int maxCode = 0;
    for (final code in existingCodes) {
      final parsed = int.tryParse(code);
      if (parsed != null && parsed > maxCode) {
        maxCode = parsed;
      }
    }
    return (maxCode + 1).toString().padLeft(2, '0');
  }
}
