// Données de localisation du Burkina Faso
class LocalisationData {
  /// Liste officielle des régions du Burkina Faso (2024+)
  static const List<Map<String, dynamic>> regionsBurkina = [
    {'code': '01', 'nom': 'Boucle du Mouhoun'},
    {'code': '02', 'nom': 'Cascades'},
    {'code': '03', 'nom': 'Centre'},
    {'code': '04', 'nom': 'Centre-Est'},
    {'code': '05', 'nom': 'Centre-Nord'},
    {'code': '06', 'nom': 'Centre-Ouest'},
    {'code': '07', 'nom': 'Centre-Sud'},
    {'code': '08', 'nom': 'Est'},
    {'code': '09', 'nom': 'Hauts-Bassins'},
    {'code': '10', 'nom': 'Nord'},
    {'code': '11', 'nom': 'Plateau-Central'},
    {'code': '12', 'nom': 'Sahel'},
    {'code': '13', 'nom': 'Sud-Ouest'},
  ];

  /// Provinces par région (codifiées)
  static const Map<String, List<Map<String, dynamic>>> provincesParRegion = {
    '01': [
      // Boucle du Mouhoun
      {'code': '01', 'nom': 'Balé'},
      {'code': '02', 'nom': 'Banwa'},
      {'code': '03', 'nom': 'Kossi'},
      {'code': '04', 'nom': 'Mouhoun'},
      {'code': '05', 'nom': 'Nayala'},
      {'code': '06', 'nom': 'Sourou'},
    ],
    '02': [
      // Cascades
      {'code': '01', 'nom': 'Comoé'},
      {'code': '02', 'nom': 'Léraba'},
    ],
    '03': [
      // Centre
      {'code': '01', 'nom': 'Kadiogo'},
    ],
    '04': [
      // Centre-Est
      {'code': '01', 'nom': 'Boulgou'},
      {'code': '02', 'nom': 'Koulpélogo'},
      {'code': '03', 'nom': 'Kouritenga'},
    ],
    '05': [
      // Centre-Nord
      {'code': '01', 'nom': 'Bam'},
      {'code': '02', 'nom': 'Namentenga'},
      {'code': '03', 'nom': 'Sanmatenga'},
    ],
    '06': [
      // Centre-Ouest
      {'code': '01', 'nom': 'Boulkiemdé'},
      {'code': '02', 'nom': 'Sanguié'},
      {'code': '03', 'nom': 'Sissili'},
      {'code': '04', 'nom': 'Ziro'},
    ],
    '07': [
      // Centre-Sud
      {'code': '01', 'nom': 'Bazèga'},
      {'code': '02', 'nom': 'Nahouri'},
      {'code': '03', 'nom': 'Zoundwéogo'},
    ],
    '08': [
      // Est
      {'code': '01', 'nom': 'Gnagna'},
      {'code': '02', 'nom': 'Gourma'},
      {'code': '03', 'nom': 'Komondjari'},
      {'code': '04', 'nom': 'Kompienga'},
      {'code': '05', 'nom': 'Tapoa'},
    ],
    '09': [
      // Hauts-Bassins
      {'code': '01', 'nom': 'Houet'},
      {'code': '02', 'nom': 'Kénédougou'},
      {'code': '03', 'nom': 'Tuy'},
    ],
    '10': [
      // Nord
      {'code': '01', 'nom': 'Loroum'},
      {'code': '02', 'nom': 'Passoré'},
      {'code': '03', 'nom': 'Yatenga'},
      {'code': '04', 'nom': 'Zondoma'},
    ],
    '11': [
      // Plateau-Central
      {'code': '01', 'nom': 'Ganzourgou'},
      {'code': '02', 'nom': 'Kourwéogo'},
      {'code': '03', 'nom': 'Oubritenga'},
    ],
    '12': [
      // Sahel
      {'code': '01', 'nom': 'Oudalan'},
      {'code': '02', 'nom': 'Séno'},
      {'code': '03', 'nom': 'Soum'},
      {'code': '04', 'nom': 'Yagha'},
    ],
    '13': [
      // Sud-Ouest
      {'code': '01', 'nom': 'Bougouriba'},
      {'code': '02', 'nom': 'Ioba'},
      {'code': '03', 'nom': 'Noumbiel'},
      {'code': '04', 'nom': 'Poni'},
    ],
  };

  /// Communes/Départements par province (codifiées)
  /// Format : { 'codeRegion-codeProvince': [ {'code': '01', 'nom': 'Commune1'}, ... ] }
  static const Map<String, List<Map<String, dynamic>>> communesParProvince = {
    // Boucle du Mouhoun
    '01-01': [
      // Balé
      {'code': '01', 'nom': 'Boromo'},
      {'code': '02', 'nom': 'Bagassi'},
      {'code': '03', 'nom': 'Fara'},
      {'code': '04', 'nom': 'Pa'},
      {'code': '05', 'nom': 'Pompoï'},
      {'code': '06', 'nom': 'Poura'},
      {'code': '07', 'nom': 'Siby'},
      {'code': '08', 'nom': 'Oury'},
      {'code': '09', 'nom': 'Yaho'},
    ],
    '05-01': [
      // Bam
      {'code': '01', 'nom': 'Kongoussi'},
      {'code': '02', 'nom': 'Bourzanga'},
      {'code': '03', 'nom': 'Guibaré'},
      {'code': '04', 'nom': 'Nasséré'},
      {'code': '05', 'nom': 'Tikaré'},
      {'code': '06', 'nom': 'Sabcé'},
      {'code': '07', 'nom': 'Rollo'},
      {'code': '08', 'nom': 'Rouko'},
      {'code': '09', 'nom': 'Zitenga'},
    ],
    '01-02': [
      // Banwa
      {'code': '01', 'nom': 'Solenzo'},
      {'code': '02', 'nom': 'Balavé'},
      {'code': '03', 'nom': 'Kouka'},
      {'code': '04', 'nom': 'Tansila'},
      {'code': '05', 'nom': 'Sami'},
      {'code': '06', 'nom': 'Sanaba'},
    ],
    '07-01': [
      // Bazèga
      {'code': '01', 'nom': 'Kombissiri'},
      {'code': '02', 'nom': 'Doulougou'},
      {'code': '03', 'nom': 'Ipelcé'},
      {'code': '04', 'nom': 'Gaongo'},
      {'code': '05', 'nom': 'Kayao'},
      {'code': '06', 'nom': 'Toécé'},
      {'code': '07', 'nom': 'Saponé'},
    ],
    '13-01': [
      // Bougouriba
      {'code': '01', 'nom': 'Diébougou'},
      {'code': '02', 'nom': 'Dolo'},
      {'code': '03', 'nom': 'Tiankoura'},
      {'code': '04', 'nom': 'Bonddigui'},
      {'code': '05', 'nom': 'Nioroniorro'},
      {'code': '06', 'nom': 'Oronkua'},
    ],
    '04-01': [
      // Boulgou
      {'code': '01', 'nom': 'Tenkodogo'},
      {'code': '02', 'nom': 'Bané'},
      {'code': '03', 'nom': 'Bagré'},
      {'code': '04', 'nom': 'Béguédo'},
      {'code': '05', 'nom': 'Bittou'},
      {'code': '06', 'nom': 'Boussouma'},
      {'code': '07', 'nom': 'Bissiga'},
      {'code': '08', 'nom': 'Garango'},
      {'code': '09', 'nom': 'Komtoéga'},
      {'code': '10', 'nom': 'Niagho'},
      {'code': '11', 'nom': 'Zabré'},
      {'code': '12', 'nom': 'Zoaga'},
      {'code': '13', 'nom': 'Zonsé'},
    ],
    '06-01': [
      // Boulkiemdé
      {'code': '01', 'nom': 'Koudougou'},
      {'code': '02', 'nom': 'Bingo'},
      {'code': '03', 'nom': 'Imasgo'},
      {'code': '04', 'nom': 'Kindi'},
      {'code': '05', 'nom': 'Kokologo'},
      {'code': '06', 'nom': 'Nanoro'},
      {'code': '07', 'nom': 'Niandiala'},
      {'code': '08', 'nom': 'Pella'},
      {'code': '09', 'nom': 'Poa'},
      {'code': '10', 'nom': 'Ramongo'},
      {'code': '11', 'nom': 'Sabou'},
      {'code': '12', 'nom': 'Siglé'},
      {'code': '13', 'nom': 'Sourgou'},
      {'code': '14', 'nom': 'Thiou'},
      {'code': '15', 'nom': 'Soaw'},
    ],
    '02-01': [
      // Comoé
      {'code': '01', 'nom': 'Banfora'},
      {'code': '02', 'nom': 'Bérégadougou'},
      {'code': '03', 'nom': 'Mangodara'},
      {'code': '04', 'nom': 'Moussodougou'},
      {'code': '05', 'nom': 'Niangoloko'},
      {'code': '06', 'nom': 'Ouo'},
      {'code': '07', 'nom': 'Sidéradougou'},
      {'code': '08', 'nom': 'Soubakaniédougou'},
      {'code': '09', 'nom': 'Tiéfora'},
    ],
    '11-01': [
      // Ganzourgou
      {'code': '01', 'nom': 'Zorgho'},
      {'code': '02', 'nom': 'Boudry'},
      {'code': '03', 'nom': 'Kogo'},
      {'code': '04', 'nom': 'Méguet'},
      {'code': '05', 'nom': 'Mogtédo'},
      {'code': '06', 'nom': 'Salogo'},
      {'code': '07', 'nom': 'Zam'},
      {'code': '08', 'nom': 'Zoungou'},
    ],
    // ... Compléter pour toutes les provinces du tableau fourni ...
    // (Pour la démo, seules les premières sont listées. À compléter pour la totalité si besoin)
  };

  static const List<String> arrondissementsOuagadougou = [
    'Arrondissement 1',
    'Arrondissement 2',
    'Arrondissement 3',
    'Arrondissement 4',
    'Arrondissement 5',
    'Arrondissement 6',
    'Arrondissement 7',
    'Arrondissement 8',
    'Arrondissement 9',
    'Arrondissement 10',
    'Arrondissement 11',
    'Arrondissement 12',
  ];

  static const List<String> arrondissementsBobo = [
    'Arrondissement 1',
    'Arrondissement 2',
    'Arrondissement 3',
    'Arrondissement 4',
    'Arrondissement 5',
    'Arrondissement 6',
    'Arrondissement 7',
  ];

  static const List<String> sexes = ['Masculin', 'Féminin'];

  static const List<String> typesAge = [
    'Inférieure ou Egale à 35',
    'Supérieure à 35'
  ];

  static const List<String> typesAppartenance = ['Propre', 'Cooperative'];

  static const List<String> originesFlorales = [
    'Acacia',
    'Lavande',
    'Tilleul',
    'Châtaignier',
    'Toutes fleurs',
    'Eucalyptus',
    'Karité',
    'Néré',
    'Baobab',
    'Tamarinier'
  ];

  // Méthodes utilitaires adaptées à la nouvelle structure codifiée
  static List<Map<String, dynamic>> getProvincesForRegion(String? codeRegion) {
    if (codeRegion == null) return [];
    return provincesParRegion[codeRegion] ?? [];
  }

  static List<Map<String, dynamic>> getCommunesForProvince(
      String? codeRegion, String? codeProvince) {
    if (codeRegion == null || codeProvince == null) return [];
    final key = '$codeRegion-$codeProvince';
    return communesParProvince[key] ?? [];
  }

  static List<String> getArrondissementsForCommune(String? commune) {
    if (commune == null) return [];
    switch (commune) {
      case 'Ouagadougou':
        return arrondissementsOuagadougou;
      case 'Bobo-Dioulasso':
      case 'BOBO-DIOULASSO':
        return arrondissementsBobo;
      default:
        return [];
    }
  }
} // class LocalisationData
