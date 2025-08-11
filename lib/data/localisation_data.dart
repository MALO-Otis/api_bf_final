// Données de localisation du Burkina Faso
class LocalisationData {
  static const List<String> regionsBurkina = [
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

  static const Map<String, List<String>> provincesParRegion = {
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
    'Cascades': ['Comoé', 'Léraba'],
    'Centre-Est': ['Boulgou', 'Koulpélogo', 'Kouritenga'],
    'Centre-Nord': ['Bam', 'Namentenga', 'Sanmatenga'],
    'Centre-Ouest': ['Boulkiemdé', 'Sanguié', 'Sissili', 'Ziro'],
    'Centre-Sud': ['Bazèga', 'Nahouri', 'Zoundwéogo'],
    'Est': ['Gnagna', 'Gourma', 'Komondjari', 'Kompienga', 'Tapoa'],
    'Nord': ['Loroum', 'Passoré', 'Yatenga', 'Zondoma'],
    'Plateau-Central': ['Ganzourgou', 'Kourwéogo', 'Oubritenga'],
    'Sahel': ['Oudalan', 'Séno', 'Soum', 'Yagha'],
    'Sud-Ouest': ['Bougouriba', 'Ioba', 'Noumbiel', 'Poni'],
  };

  static const Map<String, List<String>> communesParProvince = {
    'Kadiogo': [
      'Ouagadougou',
      'Komki-Ipala',
      'Komsilga',
      'Koubri',
      'Pabré',
      'Saaba',
      'Tanghin-Dassouri'
    ],
    'Houet': [
      'Bobo-Dioulasso',
      'Bama',
      'Bobo-Dioulasso Rural',
      'Dandé',
      'Faramana',
      'Fô',
      'Karangasso-Sambla',
      'Karangasso-Vigué',
      'Koundougou',
      'Lena',
      'Padéma',
      'Péni',
      'Santidougou',
      'Satiri',
      'Toussiana'
    ],
    'Balé': [
      'Bagassi',
      'Bana',
      'Boromo',
      'Fara',
      'Oury',
      'Pâ',
      'Pompoï',
      'Poura',
      'Siby',
      'Yaho'
    ],
    // Ajoutez d'autres provinces selon vos besoins...
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
    'Supérieure ou Egale à 35'
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

  // Méthodes utilitaires
  static List<String> getProvincesForRegion(String? region) {
    if (region == null) return [];
    return provincesParRegion[region] ?? [];
  }

  static List<String> getCommunesForProvince(String? province) {
    if (province == null) return [];
    return communesParProvince[province] ?? [];
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
}
