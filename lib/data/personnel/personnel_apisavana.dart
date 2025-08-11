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

// Sites disponibles
const List<String> sitesApisavana = [
  'Koudougou',
  'Bobo',
  'Mangodara',
  'Po',
  'Sindou',
  'Orodara',
  'Sapouy',
  'Leo',
  'Bagré',
];

// Prédominances florales complètes
const List<String> predominancesFlorales = [
  'CAJOU',
  'MANGUE',
  'KARITÉ',
  'FORÊT',
  'NERE',
  'LIANE',
  'MORINGA',
  'MELANGE',
  'CHAMPS',
  'CHAMPS MELANGE',
  'CHAMPS SIMPLES',
  'ORANGES',
  'GOYAVIER',
  'AUTRES ARBRES À FLEURS',
  'BAS FONDS',
  'Toroyiri//kaakangan',
  'Diospyros mespiliformis',
  'AUTRE(S) FOURRAGE',
  'DETARIUM',
  'RAISIN',
  'TAMARIN',
  'SANAYIRI',
  'EUCALYPTUS',
  'FILAO',
  'ZAABA',
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
