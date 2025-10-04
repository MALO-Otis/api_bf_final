import 'package:collection/collection.dart';

/// Représente une région métier officielle.
class MetierRegion {
  final String code;
  final String name;
  final List<String> legacyNames;

  const MetierRegion({
    required this.code,
    required this.name,
    this.legacyNames = const [],
  });
}

/// Représente une province rattachée à une région métier.
class MetierProvince {
  final String code;
  final String name;
  final String regionCode;
  final String? legacyName;
  final String? chefLieu;

  const MetierProvince({
    required this.code,
    required this.name,
    required this.regionCode,
    this.legacyName,
    this.chefLieu,
  });
}

/// Découpage administratif 2025 utilisé par le module Collecte.
/// Les codes restent stables pour garantir la traçabilité entre les modules.
class CollecteReferenceData2025 {
  /// Liste des 17 régions officielles.
  static const List<MetierRegion> regions = [
    MetierRegion(
      code: 'RG01',
      name: 'Bankui',
      legacyNames: ['Boucle du Mouhoun'],
    ),
    MetierRegion(
      code: 'RG02',
      name: 'Sourou',
      legacyNames: ['Boucle du Mouhoun'],
    ),
    MetierRegion(
      code: 'RG03',
      name: 'Djôrô',
      legacyNames: ['Sud-Ouest'],
    ),
    MetierRegion(
      code: 'RG04',
      name: 'Guiriko',
      legacyNames: ['Hauts-Bassins'],
    ),
    MetierRegion(
      code: 'RG05',
      name: 'Tannounyan',
      legacyNames: ['Cascades'],
    ),
    MetierRegion(
      code: 'RG06',
      name: 'Kadiogo',
      legacyNames: ['Centre'],
    ),
    MetierRegion(
      code: 'RG07',
      name: 'Nakambé',
      legacyNames: ['Centre-Est'],
    ),
    MetierRegion(
      code: 'RG08',
      name: 'Kuilsé',
      legacyNames: ['Centre-Nord'],
    ),
    MetierRegion(
      code: 'RG09',
      name: 'Nando',
      legacyNames: ['Centre-Ouest'],
    ),
    MetierRegion(
      code: 'RG10',
      name: 'Nazinon',
      legacyNames: ['Centre-Sud'],
    ),
    MetierRegion(
      code: 'RG11',
      name: 'Oubri',
      legacyNames: ['Plateau-Central'],
    ),
    MetierRegion(
      code: 'RG12',
      name: 'Yaadga',
      legacyNames: ['Nord'],
    ),
    MetierRegion(
      code: 'RG13',
      name: 'Goulmou',
      legacyNames: ['Est'],
    ),
    MetierRegion(
      code: 'RG14',
      name: 'Tapoa',
      legacyNames: ['Est'],
    ),
    MetierRegion(
      code: 'RG15',
      name: 'Sirba',
      legacyNames: ['Est', 'Gnagna'],
    ),
    MetierRegion(
      code: 'RG16',
      name: 'Soum',
      legacyNames: ['Sahel'],
    ),
    MetierRegion(
      code: 'RG17',
      name: 'Liptako',
      legacyNames: ['Sahel'],
    ),
  ];

  /// Provinces mises à jour et rattachées à leur région.
  static const List<MetierProvince> provinces = [
    MetierProvince(
      code: 'PR01',
      name: 'Balé',
      regionCode: 'RG01',
    ),
    MetierProvince(
      code: 'PR02',
      name: 'Banwa',
      regionCode: 'RG01',
    ),
    MetierProvince(
      code: 'PR03',
      name: 'Kossin',
      legacyName: 'Kossi',
      regionCode: 'RG01',
    ),
    MetierProvince(
      code: 'PR04',
      name: 'Mouhoun',
      regionCode: 'RG01',
    ),
    MetierProvince(
      code: 'PR05',
      name: 'Nayala',
      regionCode: 'RG01',
    ),
    MetierProvince(
      code: 'PR06',
      name: 'Sourou',
      regionCode: 'RG02',
    ),
    MetierProvince(
      code: 'PR07',
      name: 'Bougouriba',
      regionCode: 'RG03',
    ),
    MetierProvince(
      code: 'PR08',
      name: 'Ioba',
      regionCode: 'RG03',
    ),
    MetierProvince(
      code: 'PR09',
      name: 'Noumbiel',
      regionCode: 'RG03',
    ),
    MetierProvince(
      code: 'PR10',
      name: 'Poni',
      regionCode: 'RG03',
    ),
    MetierProvince(
      code: 'PR11',
      name: 'Houet',
      regionCode: 'RG04',
    ),
    MetierProvince(
      code: 'PR12',
      name: 'Kénédougou',
      regionCode: 'RG04',
    ),
    MetierProvince(
      code: 'PR13',
      name: 'Tuy',
      regionCode: 'RG04',
    ),
    MetierProvince(
      code: 'PR14',
      name: 'Comoé',
      regionCode: 'RG05',
    ),
    MetierProvince(
      code: 'PR15',
      name: 'Léraba',
      regionCode: 'RG05',
    ),
    MetierProvince(
      code: 'PR16',
      name: 'Kadiogo',
      regionCode: 'RG06',
    ),
    MetierProvince(
      code: 'PR17',
      name: 'Boulgou',
      regionCode: 'RG07',
    ),
    MetierProvince(
      code: 'PR18',
      name: 'Koulpélogo',
      regionCode: 'RG07',
    ),
    MetierProvince(
      code: 'PR19',
      name: 'Kouritenga',
      regionCode: 'RG07',
    ),
    MetierProvince(
      code: 'PR20',
      name: 'Bam',
      regionCode: 'RG08',
    ),
    MetierProvince(
      code: 'PR21',
      name: 'Sandbondtenga',
      legacyName: 'Sanmatenga',
      regionCode: 'RG08',
    ),
    MetierProvince(
      code: 'PR22',
      name: 'Namentenga',
      regionCode: 'RG08',
    ),
    MetierProvince(
      code: 'PR23',
      name: 'Boulkiemdé',
      regionCode: 'RG09',
    ),
    MetierProvince(
      code: 'PR24',
      name: 'Sanguié',
      regionCode: 'RG09',
    ),
    MetierProvince(
      code: 'PR25',
      name: 'Sissili',
      regionCode: 'RG09',
    ),
    MetierProvince(
      code: 'PR26',
      name: 'Ziro',
      regionCode: 'RG09',
    ),
    MetierProvince(
      code: 'PR27',
      name: 'Bazèga',
      regionCode: 'RG10',
    ),
    MetierProvince(
      code: 'PR28',
      name: 'Nahouri',
      regionCode: 'RG10',
    ),
    MetierProvince(
      code: 'PR29',
      name: 'Zoundwéogo',
      regionCode: 'RG10',
    ),
    MetierProvince(
      code: 'PR30',
      name: 'Bassitenga',
      legacyName: 'Oubritenga',
      regionCode: 'RG11',
    ),
    MetierProvince(
      code: 'PR31',
      name: 'Ganzourgou',
      regionCode: 'RG11',
    ),
    MetierProvince(
      code: 'PR32',
      name: 'Kourwéogo',
      regionCode: 'RG11',
    ),
    MetierProvince(
      code: 'PR33',
      name: 'Loroum',
      regionCode: 'RG12',
    ),
    MetierProvince(
      code: 'PR34',
      name: 'Passoré',
      regionCode: 'RG12',
    ),
    MetierProvince(
      code: 'PR35',
      name: 'Yatenga',
      regionCode: 'RG12',
    ),
    MetierProvince(
      code: 'PR36',
      name: 'Zondoma',
      regionCode: 'RG12',
    ),
    MetierProvince(
      code: 'PR37',
      name: 'Gourma',
      regionCode: 'RG13',
    ),
    MetierProvince(
      code: 'PR38',
      name: 'Komondjari',
      regionCode: 'RG13',
    ),
    MetierProvince(
      code: 'PR39',
      name: 'Kompienga',
      regionCode: 'RG13',
    ),
    MetierProvince(
      code: 'PR40',
      name: 'Tapoa',
      regionCode: 'RG14',
    ),
    MetierProvince(
      code: 'PR41',
      name: 'Gnagna',
      regionCode: 'RG15',
    ),
    MetierProvince(
      code: 'PR42',
      name: 'Dyamongou',
      chefLieu: 'Kantchari',
      regionCode: 'RG15',
    ),
    MetierProvince(
      code: 'PR43',
      name: 'Djelgodji',
      legacyName: 'Soum',
      regionCode: 'RG16',
    ),
    MetierProvince(
      code: 'PR44',
      name: 'Karo-Peli',
      chefLieu: 'Arbinda',
      regionCode: 'RG16',
    ),
    MetierProvince(
      code: 'PR45',
      name: 'Oudalan',
      regionCode: 'RG17',
    ),
    MetierProvince(
      code: 'PR46',
      name: 'Séno',
      regionCode: 'RG17',
    ),
    MetierProvince(
      code: 'PR47',
      name: 'Yagha',
      regionCode: 'RG17',
    ),
  ];

  /// Accès rapide à une région via son code.
  static MetierRegion? findRegionByCode(String code) =>
      regions.firstWhereOrNull((region) => region.code == code);

  /// Recherche tolérante au nom (officiel ou hérité).
  static MetierRegion? resolveRegion(String name) {
    final normalised = name.trim().toLowerCase();
    return regions.firstWhereOrNull((region) {
      if (region.name.toLowerCase() == normalised) return true;
      return region.legacyNames
          .any((legacy) => legacy.toLowerCase() == normalised);
    });
  }

  /// Retourne la liste des provinces d'une région donnée.
  static List<MetierProvince> provincesForRegion(String regionCode) {
    return provinces
        .where((province) => province.regionCode == regionCode)
        .toList();
  }

  /// Résout une province par son nom officiel ou historique.
  static MetierProvince? resolveProvince(String name) {
    final normalised = name.trim().toLowerCase();
    return provinces.firstWhereOrNull((province) {
      if (province.name.toLowerCase() == normalised) return true;
      if (province.legacyName != null &&
          province.legacyName!.toLowerCase() == normalised) {
        return true;
      }
      return false;
    });
  }
}
