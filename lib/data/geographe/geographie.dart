// Ce fichier est généré automatiquement à partir du tableau CODE TRAÇABILITÉ regions au quartier
// Structure hiérarchique complète : régions, provinces, communes, villages
// Données exhaustives pour le Burkina Faso

// Liste exhaustive des régions du Burkina Faso
const List<String> regionsBurkina = [
  'CASCADES',
  'HAUTS-BASSINS',
  'BOUCLE DU MOUHOUN',
  'CENTRE-OUEST',
  'CENTRE-SUD',
  'SUD-OUEST',
];

// Provinces par région
const Map<String, List<String>> provincesParRegion = {
  'CASCADES': ['LERABA', 'COMOE'],
  'HAUTS-BASSINS': ['HOUET', 'KENEDOUGOU', 'TUY'],
  'BOUCLE DU MOUHOUN': ['MOUHOUN', 'BALE'],
  'CENTRE-OUEST': ['SISSILI', 'BOULKIEMDE', 'SANGUIE'],
  'CENTRE-SUD': ['NAHOURI'],
  'SUD-OUEST': ['PONI', 'IOBA'],
};

// Communes par province
const Map<String, List<String>> communesParProvince = {
  'LERABA': [
    'LOUMANA',
    'SINDOU',
    'OUELENI',
    'KANKALABA',
    'DOUNA',
    'DAKORO',
    'WOLONKOTO'
  ],
  'COMOE': ['SIDERADOUGOU', 'MANGODARA', 'SOUBAKANIEDOUGOU', 'MOUSSODOUGOU'],
  'HOUET': [
    'TOUSSIANA',
    'SATIRI',
    'KARANGASSO-VIGUE',
    'PENI',
    'BOBO',
    'BAMA',
    'BADARA'
  ],
  'KENEDOUGOU': ['KOURINION', 'KOLOKO', 'KANGALA', 'ORODARA'],
  'TUY': ['BEKUY', 'BEREBA', 'KOUMBIA'],
  'MOUHOUN': ['DOUROULA', 'DEDOUGOU', 'TCHERIBA'],
  'BALE': ['SIBY', 'PA'],
  'SISSILI': ['TO'],
  'BOULKIEMDE': [
    'KOUDOUGOU',
    'IMASGO',
    'SABOU',
    'SOURGOU',
    'PELLA',
    'POA',
    'SOAW',
    'KOKOLOGO'
  ],
  'SANGUIE': ['DASSA', 'REO', 'TENADO', 'GOUNDI'],
  'NAHOURI': ['PO', 'GUIARO'],
  'PONI': ['BOUROUM-BOUROUM'],
  'IOBA': ['DANO'],
};

// Villages par commune - Structure complète basée sur le tableau de traçabilité
const Map<String, List<String>> villagesParCommune = {
  'LOUMANA': [
    'KANGOURA',
    'SOUMADOUGOUDJAN',
    'NIANSOGONI',
    'LOUMANA',
    'TCHONGO',
    'BAGUERA'
  ],
  'SINDOU': ['TOURNY', 'SINDOU', 'MASONON'],
  'OUELENI': ['NALERE', 'TENA', 'TINOU', 'NAMBOENA', 'BEBOUGOU'],
  'KANKALABA': ['NIANTONO', 'BOUGOULA', 'KANKALABA', 'KOLASSO', 'DIONSO'],
  'DOUNA': ['DOUNA'],
  'DAKORO': ['DAKORO', 'KASSEGUERA'],
  'WOLONKOTO': ['WOLONKOTO'],
  'SIDERADOUGOU': ['ZANGAZOLI', 'SIDERADOUGOU', 'KOUERE'],
  'MANGODARA': [
    'MANGODARA',
    'TORANDOUGOU',
    'GNAMINADOUGOU',
    'FARAKORO',
    'SOKOURA',
    'TOROKORO',
    'BAKARIDJAN',
    'BANAKORO',
    'BANAKELESSO',
    'KANDO',
    'DIARRAKOROSSO',
    'GAMBI',
    'LARABIN',
    'KORGO',
    'SIRAKORO',
    'TOMIKOROSSO',
    'TORGO',
    'DANDOUGOU',
    'GONKODJAN'
  ],
  'SOUBAKANIEDOUGOU': ['SOUBAKANIEDOUGOU'],
  'MOUSSODOUGOU': ['MOUSSODOUGOU'],
  'TOUSSIANA': ['TOUSSIANA', 'TAPOKO'],
  'SATIRI': ['SALA', 'KOROMA', 'SATIRI'],
  'KARANGASSO-VIGUE': [
    'DEREGUAN',
    'KARANGASSO VIGUE',
    'OUERE',
    'DAN',
    'SOUMOUSSO'
  ],
  'PENI': ['GNANFOGO', 'MOUSSOBADOUGOU', 'KOUMANDARA', 'PENI'],
  'BOBO': ['NOUMOUSSO', 'BOBO', 'DAFINSO', 'DOUFIGUISSO'],
  'BAMA': ['SOUNGALODAGA', 'BAMA'],
  'BADARA': ['BADARA'],
  'KOURINION': ['TOUSSIAMASSO', 'KOURINION', 'SIPIGUI', 'SIDI', 'GUENA'],
  'KOLOKO': ['SIFARASSO', 'KOKOUNA'],
  'KANGALA': ['MAHON', 'WOLONKOTO', 'SOKOURABA'],
  'ORODARA': ['ORODARA'],
  'BEKUY': ['ZEKUY'],
  'BEREBA': ['MARO'],
  'KOUMBIA': ['KOUMBIA'],
  'DOUROULA': [
    'KANCONO',
    'DOUROULA',
    'BLADI',
    'KIRICONGO',
    'KOUSSIRI',
    'KASSACONGO',
    'NOROGTENGA'
  ],
  'DEDOUGOU': ['DEDOUGOU', 'KARI'],
  'TCHERIBA': [
    'BANOUBA',
    'BISSANDEROU',
    'ETOUAYOU',
    'GAMADOUGOU',
    'OUALOU',
    'OUEZALA',
    'TCHERIBA',
    'TIKAN',
    'BEKEYOU',
    'YOULOU',
    'TIERKOU'
  ],
  'SIBY': ['BALLAO', 'SOROBOULY', 'SOUHO', 'DIDIE', 'SIBY'],
  'PA': ['DIDIE'],
  'TO': ['TO'],
  'KOUDOUGOU': ['TIOGO MOSRI', 'SALLA', 'KANKALBILA', 'SIGAGHIN', 'RAMONGO'],
  'IMASGO': ['OUERA'],
  'SABOU': ['NADIOLO'],
  'SOURGOU': ['SOURGOU'],
  'PELLA': ['PELLA'],
  'POA': ['POA'],
  'SOAW': ['SOAW'],
  'KOKOLOGO': ['KOKOLOGO'],
  'DASSA': ['DASSA'],
  'REO': ['PERKOAN'],
  'TENADO': ['TENADO', 'TIALGO', 'TIOGO'],
  'GOUNDI': ['GOUNDI'],
  'PO': ['BOUROU', 'TIAKANE', 'YARO'],
  'GUIARO': ['KOLLO', 'OUALEM', 'SARO'],
  'BOUROUM-BOUROUM': ['BOUROUM-BOUROUM'],
  'DANO': ['DANO'],
};

// Fonctions utilitaires pour la navigation hiérarchique
class GeographieUtils {
  /// Obtient toutes les provinces d'une région donnée
  static List<String> getProvincesByRegion(String region) {
    return provincesParRegion[region.toUpperCase()] ?? [];
  }

  /// Obtient toutes les communes d'une province donnée
  static List<String> getCommunesByProvince(String province) {
    return communesParProvince[province.toUpperCase()] ?? [];
  }

  /// Obtient tous les villages d'une commune donnée
  static List<String> getVillagesByCommune(String commune) {
    return villagesParCommune[commune.toUpperCase()] ?? [];
  }

  /// Trouve la région d'une province donnée
  static String? getRegionByProvince(String province) {
    for (final entry in provincesParRegion.entries) {
      if (entry.value.contains(province.toUpperCase())) {
        return entry.key;
      }
    }
    return null;
  }

  /// Trouve la province d'une commune donnée
  static String? getProvinceByCommune(String commune) {
    for (final entry in communesParProvince.entries) {
      if (entry.value.contains(commune.toUpperCase())) {
        return entry.key;
      }
    }
    return null;
  }

  /// Trouve la commune d'un village donné
  static String? getCommuneByVillage(String village) {
    for (final entry in villagesParCommune.entries) {
      if (entry.value.contains(village.toUpperCase())) {
        return entry.key;
      }
    }
    return null;
  }

  /// Recherche géographique complète
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

  /// Valide si une hiérarchie géographique est cohérente
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

  /// Recherche par nom partiel (autocomplete)
  static List<String> searchRegions(String query) {
    return regionsBurkina
        .where((r) => r.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  static List<String> searchProvinces(String query, {String? region}) {
    final provinces = region != null
        ? getProvincesByRegion(region)
        : provincesParRegion.values.expand((p) => p).toList();
    return provinces
        .where((p) => p.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  static List<String> searchCommunes(String query, {String? province}) {
    final communes = province != null
        ? getCommunesByProvince(province)
        : communesParProvince.values.expand((c) => c).toList();
    return communes
        .where((c) => c.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  static List<String> searchVillages(String query, {String? commune}) {
    final villages = commune != null
        ? getVillagesByCommune(commune)
        : villagesParCommune.values.expand((v) => v).toList();
    return villages
        .where((v) => v.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
