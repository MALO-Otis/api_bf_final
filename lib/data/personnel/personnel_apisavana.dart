// Données du personnel APISAVANA
// Structure complète : techniciens par site avec contacts

class TechnicienInfo {
  final String nom;
  final String prenom;
  final String site;
  final String telephone;
  final String nomComplet;

  const TechnicienInfo({
    required this.nom,
    required this.prenom,
    required this.site,
    required this.telephone,
  }) : nomComplet = '$prenom $nom';

  @override
  String toString() => nomComplet;
}

// Liste complète des techniciens APISAVANA
const List<TechnicienInfo> techniciensApisavana = [
  TechnicienInfo(
    nom: 'ZOUNGRANA',
    prenom: 'Valentin',
    site: 'Koudougou',
    telephone: '70417016',
  ),
  TechnicienInfo(
    nom: 'ROAMBA',
    prenom: 'F Y Ferdinand',
    site: 'Koudougou',
    telephone: '70551041',
  ),
  TechnicienInfo(
    nom: 'YAMEOGO',
    prenom: 'A Clément',
    site: 'Koudougou',
    telephone: '65239801',
  ),
  TechnicienInfo(
    nom: 'SANOU',
    prenom: 'Sitelé',
    site: 'Bobo',
    telephone: '64691315',
  ),
  TechnicienInfo(
    nom: 'YAMEOGO',
    prenom: 'Justin',
    site: 'Bobo',
    telephone: '72663949',
  ),
  TechnicienInfo(
    nom: 'SANOGO',
    prenom: 'Issouf',
    site: 'Mangodara',
    telephone: '76519205',
  ),
  TechnicienInfo(
    nom: 'OUATTARA',
    prenom: 'Baladji',
    site: 'Mangodara',
    telephone: '',
  ),
  TechnicienInfo(
    nom: 'OUTTARA',
    prenom: 'Lassina',
    site: 'Mangodara',
    telephone: '',
  ),
  TechnicienInfo(
    nom: 'YAMEOGO',
    prenom: 'Innocent',
    site: 'Mangodara',
    telephone: '55756926',
  ),
  TechnicienInfo(
    nom: 'OUEDRAOGO',
    prenom: 'Issouf',
    site: 'Po',
    telephone: '63111260',
  ),
  TechnicienInfo(
    nom: 'YAMEOGO',
    prenom: 'Hippolyte',
    site: 'Po',
    telephone: '77742102',
  ),
  TechnicienInfo(
    nom: 'TRAORE',
    prenom: 'Abdoul Aziz',
    site: 'Sindou',
    telephone: '75172236',
  ),
  TechnicienInfo(
    nom: 'SIEMDE',
    prenom: 'Souleymane',
    site: 'Orodara',
    telephone: '67901737',
  ),
  TechnicienInfo(
    nom: 'KABORE',
    prenom: 'Adama',
    site: 'Sapouy',
    telephone: '51905379',
  ),
  TechnicienInfo(
    nom: 'OUEDRAOGO',
    prenom: 'Adama',
    site: 'Leo',
    telephone: '54420020',
  ),
  TechnicienInfo(
    nom: 'MILOGO',
    prenom: 'Anicet',
    site: 'Bagré',
    telephone: '76895996',
  ),
];

// Sites disponibles (Mielleries)
const List<String> sitesApisavana = [
  'Koudougou',
  'Bingo',
  'Soaw',
  'Dalo',
  'Dassa',
  'Léo',
  'PÔ',
  'Bagré',
  'Bobo Dioulasso',
  'Dereguan',
  'Sifarasso',
  'Mahon',
  'Mangodara',
  'Niantono',
  'Nalere',
  'Tourni',
  'Bougoula',
  'Bouroum Bouroum',
];

// Prédominances florales nettoyées - Uniquement des noms d'arbres et plantes mellifères
const List<String> predominancesFlorales = [
  'Karité',
  'Néré',
  'Acacia',
  'Manguier',
  'Eucalyptus',
  'Tamarinier',
  'Baobab',
  'Citronnier',
  'Moringa',
  'Cajoutier',
  "neemier",
  "anacrde",
  "tamarinier",
  'Kapokier',
  'Zaaba',
  'Oranger',
  'Goyavier',
];

// Fonctions utilitaires
class PersonnelUtils {
  /// Obtient tous les techniciens d'un site donné
  static List<TechnicienInfo> getTechniciensBySite(String site) {
    return techniciensApisavana
        .where((t) => t.site.toLowerCase() == site.toLowerCase())
        .toList();
  }

  /// Recherche un technicien par nom complet
  static TechnicienInfo? findTechnicienByName(String nomComplet) {
    try {
      return techniciensApisavana.firstWhere(
          (t) => t.nomComplet.toLowerCase() == nomComplet.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  /// Recherche de techniciens par nom partiel
  static List<TechnicienInfo> searchTechniciens(String query) {
    final queryLower = query.toLowerCase();
    return techniciensApisavana
        .where((t) =>
            t.nomComplet.toLowerCase().contains(queryLower) ||
            t.nom.toLowerCase().contains(queryLower) ||
            t.prenom.toLowerCase().contains(queryLower))
        .toList();
  }

  /// Obtient tous les noms complets des techniciens
  static List<String> getAllTechnicienNames() {
    return techniciensApisavana.map((t) => t.nomComplet).toList();
  }

  /// Obtient tous les noms complets des techniciens d'un site
  static List<String> getTechnicienNamesBySite(String site) {
    return getTechniciensBySite(site).map((t) => t.nomComplet).toList();
  }

  /// Valide si un technicien appartient à un site
  static bool validateTechnicienSite(String technicienName, String site) {
    final technicien = findTechnicienByName(technicienName);
    return technicien?.site.toLowerCase() == site.toLowerCase();
  }
}

// ============================================================================
// 👥 PERSONNEL COMMERCIAL APISAVANA
// ============================================================================

/// Classe principale pour gérer le personnel APISAVANA
class PersonnelApisavana {
  /// Liste des commerciaux APISAVANA avec leurs zones d'intervention
  static const List<Map<String, String>> commerciaux = [
    // KOUDOUGOU
    {
      'nom': 'YAMEOGO Rose',
      'email': 'rose.yameogo@apisavana.bf',
      'telephone': '70123456',
      'zone': 'Koudougou',
    },

    // OUAGADOUGOU
    {
      'nom': 'KANSIEMO Marceline',
      'email': 'marceline.kansiemo@apisavana.bf',
      'telephone': '70234567',
      'zone': 'Ouagadougou',
    },
    {
      'nom': 'YAMEOGO Angeline',
      'email': 'angeline.yameogo@apisavana.bf',
      'telephone': '70345678',
      'zone': 'Ouagadougou',
    },
    {
      'nom': 'BAGUE SAFIATA',
      'email': 'safiata.bague@apisavana.bf',
      'telephone': '70456789',
      'zone': 'Ouagadougou',
    },
    {
      'nom': 'KIENTEGA Sidonie',
      'email': 'sidonie.kientega@apisavana.bf',
      'telephone': '70567890',
      'zone': 'Ouagadougou',
    },
    {
      'nom': 'BARA DOUKIATOU',
      'email': 'doukiatou.bara@apisavana.bf',
      'telephone': '70678901',
      'zone': 'Ouagadougou',
    },

    // BOBO DIOULASSO
    {
      'nom': 'SEMDE OUMAROU',
      'email': 'oumarou.semde@apisavana.bf',
      'telephone': '70789012',
      'zone': 'Bobo Dioulasso',
    },
    {
      'nom': 'TAPSOBA ZONABOU',
      'email': 'zonabou.tapsoba@apisavana.bf',
      'telephone': '70890123',
      'zone': 'Bobo Dioulasso',
    },

    // BAGRE
    {
      'nom': 'SEMDE KARIM',
      'email': 'karim.semde@apisavana.bf',
      'telephone': '70901234',
      'zone': 'Bagre',
    },

    // MANGODARA
    {
      'nom': 'YAMEOGO INNOCENT',
      'email': 'innocent.yameogo@apisavana.bf',
      'telephone': '55756926',
      'zone': 'Mangodara',
    },

    // PÔ
    {
      'nom': 'ZOUNGRANA HYPOLITE',
      'email': 'hypolite.zoungrana@apisavana.bf',
      'telephone': '71012345',
      'zone': 'Pô',
    },
  ];

  /// Obtient la liste de tous les commerciaux
  static List<Map<String, String>> getTousCommerciaux() => commerciaux;

  /// Recherche un commercial par email
  static Map<String, String>? getCommercialByEmail(String email) {
    try {
      return commerciaux.firstWhere((c) => c['email'] == email);
    } catch (e) {
      return null;
    }
  }

  /// Recherche des commerciaux par zone
  static List<Map<String, String>> getCommerciauxByZone(String zone) {
    return commerciaux
        .where((c) => c['zone']?.toLowerCase() == zone.toLowerCase())
        .toList();
  }

  /// Obtient tous les noms des commerciaux
  static List<String> getNomsCommerciaux() {
    return commerciaux
        .map((c) => c['nom'] ?? '')
        .where((nom) => nom.isNotEmpty)
        .toList();
  }

  /// Obtient toutes les zones commerciales
  static List<String> getZonesCommerciales() {
    return commerciaux
        .map((c) => c['zone'] ?? '')
        .where((zone) => zone.isNotEmpty)
        .toSet()
        .toList();
  }
}
