// Service pour générer des données mock pour le module de contrôle
import 'dart:math';
import '../models/collecte_models.dart';

class MockDataService {
  static final Random _random = Random();

  // Données de base pour la génération
  static const List<String> sites = [
    'Koudougou',
    'Ouagadougou',
    'Bobo',
    'Banfora',
    'Tenkodogo'
  ];

  static const List<String> techniciens = [
    'Otis Malo',
    'Marie D.',
    'Jean M.',
    'Awa B.',
    'Idrissa K.'
  ];

  static const List<String> statuses = [
    'en_attente',
    'collecte_terminee',
    'brouillon'
  ];

  static const List<String> florales = [
    'Karité',
    'Néré',
    'Acacia',
    'Moringa',
    'Anacardier',
    'Neem'
  ];

  static const List<String> hiveTypes = [
    'Kenyan Top Bar',
    'Langstroth',
    'Dadant',
    'Warré',
    'Traditionnelle'
  ];

  static const List<String> containerTypes = [
    'Bidon 30L',
    'Bidon 20L',
    'Pot 1L',
    'Jerrycan 25L',
    'Seau 10L'
  ];

  static const List<String> typesContenant = [
    'Bidon 30L',
    'Bidon 20L',
    'Pot 1L',
    'Jerrycan 25L',
    'Seau 10L'
  ];

  static const List<String> typesMiel = ['Liquide', 'Brute', 'Cire'];

  static const List<String> qualites = [
    'Excellent',
    'Très bon',
    'Bon',
    'Standard',
    'Passable'
  ];

  static const List<String> producteurs = [
    'Samba Traoré',
    'Aminata Ouédraogo',
    'Boureima Kaboré',
    'Mariam Sawadogo',
    'Ibrahim Compaoré',
    'Fatimata Diallo',
    'Seydou Sankara',
    'Aicha Zongo'
  ];

  /// Génère un nombre aléatoire autour d'une valeur de base
  static double randAround(double base, double delta) {
    final variation = (_random.nextDouble() * 2 - 1) * delta;
    final result = base + variation;
    return double.parse(result.toStringAsFixed(1));
  }

  /// Génère des données mock pour toutes les sections
  static Map<Section, List<BaseCollecte>> generateMockData(
      {int countPerSection = 48}) {
    final baseDate = DateTime.now().subtract(const Duration(days: 30));

    return {
      Section.recoltes: _generateRecoltes(countPerSection, baseDate),
      Section.scoop: _generateScoop(countPerSection, baseDate),
      Section.individuel: _generateIndividuel(countPerSection, baseDate),
    };
  }

  /// Génère des collectes de récolte
  static List<Recolte> _generateRecoltes(int count, DateTime baseDate) {
    final recoltes = <Recolte>[];

    for (int i = 0; i < count; i++) {
      final site = sites[i % sites.length];
      final date = baseDate.add(Duration(days: i));

      final contenants = <RecolteContenant>[
        RecolteContenant(
          id: 'REC-${(i + 1).toString().padLeft(3, "0")}-c1',
          hiveType: hiveTypes[_random.nextInt(hiveTypes.length)],
          containerType: containerTypes[_random.nextInt(containerTypes.length)],
          weight: randAround(60.0, 15.0),
          unitPrice: 4000,
          total: 0, // Sera calculé après
        ),
        RecolteContenant(
          id: 'REC-${(i + 1).toString().padLeft(3, "0")}-c2',
          hiveType: hiveTypes[_random.nextInt(hiveTypes.length)],
          containerType: containerTypes[_random.nextInt(containerTypes.length)],
          weight: randAround(40.5, 10.0),
          unitPrice: 4000,
          total: 0, // Sera calculé après
        ),
        RecolteContenant(
          id: 'REC-${(i + 1).toString().padLeft(3, "0")}-c3',
          hiveType: hiveTypes[_random.nextInt(hiveTypes.length)],
          containerType: containerTypes[_random.nextInt(containerTypes.length)],
          weight: randAround(85.0, 20.0),
          unitPrice: 4000,
          total: 0, // Sera calculé après
        ),
      ];

      // Calcul des totaux pour chaque contenant
      for (var contenant in contenants) {
        final newContenant = RecolteContenant(
          id: contenant.id,
          hiveType: contenant.hiveType,
          containerType: contenant.containerType,
          weight: contenant.weight,
          unitPrice: contenant.unitPrice,
          total: contenant.weight * contenant.unitPrice,
        );
        contenants[contenants.indexOf(contenant)] = newContenant;
      }

      final totalWeight = contenants.fold(0.0, (sum, c) => sum + c.weight);
      final totalAmount = contenants.fold(0.0, (sum, c) => sum + c.total);

      final recolte = Recolte(
        id: 'REC-${(i + 1).toString().padLeft(3, "0")}',
        path:
            'Sites/$site/nos_recoltes/REC-${(i + 1).toString().padLeft(3, "0")}',
        site: site,
        date: date,
        technicien: techniciens[i % techniciens.length],
        statut: statuses[i % statuses.length],
        totalWeight: totalWeight,
        totalAmount: totalAmount,
        region: 'Centre-Ouest',
        province: 'Boulkiemdé',
        commune: site,
        village: site,
        predominancesFlorales: [
          florales[_random.nextInt(florales.length)],
          florales[_random.nextInt(florales.length)],
        ].toSet().toList(),
        contenants: contenants,
      );

      recoltes.add(recolte);
    }

    return recoltes;
  }

  /// Génère des collectes SCOOP
  static List<Scoop> _generateScoop(int count, DateTime baseDate) {
    final scoops = <Scoop>[];

    for (int i = 0; i < count; i++) {
      final site = sites[(i + 1) % sites.length];
      final date = baseDate.add(Duration(days: i));

      final contenants = <ScoopContenant>[
        ScoopContenant(
          typeContenant: typesContenant[_random.nextInt(typesContenant.length)],
          typeMiel: typesMiel[_random.nextInt(typesMiel.length)],
          quantite: randAround(150.0, 25.0),
          prixUnitaire: 4000,
          montantTotal: 0, // Sera calculé après
          predominanceFlorale: florales[_random.nextInt(florales.length)],
        ),
        ScoopContenant(
          typeContenant: typesContenant[_random.nextInt(typesContenant.length)],
          typeMiel: typesMiel[_random.nextInt(typesMiel.length)],
          quantite: randAround(70.0, 15.0),
          prixUnitaire: 4000,
          montantTotal: 0, // Sera calculé après
        ),
      ];

      // Calcul des totaux pour chaque contenant
      for (var i = 0; i < contenants.length; i++) {
        final contenant = contenants[i];
        contenants[i] = ScoopContenant(
          typeContenant: contenant.typeContenant,
          typeMiel: contenant.typeMiel,
          quantite: contenant.quantite,
          prixUnitaire: contenant.prixUnitaire,
          montantTotal: contenant.quantite * contenant.prixUnitaire,
          predominanceFlorale: contenant.predominanceFlorale,
        );
      }

      final totalWeight = contenants.fold(0.0, (sum, c) => sum + c.quantite);
      final totalAmount =
          contenants.fold(0.0, (sum, c) => sum + c.montantTotal);

      final scoop = Scoop(
        id: 'SC-${(20250801 + i).toString()}',
        path: 'Sites/$site/nos_achats_scoop/SC-${(20250801 + i).toString()}',
        site: site,
        date: date,
        technicien: techniciens[(i + 2) % techniciens.length],
        statut: statuses[(i + 1) % statuses.length],
        totalWeight: totalWeight,
        totalAmount: totalAmount,
        scoopNom: 'SCOOP Rucher ${_random.nextInt(100)}',
        periodeCollecte: 'Grande Miélliée',
        qualite: qualites[_random.nextInt(qualites.length)],
        localisation: '$site Centre',
        contenants: contenants,
      );

      scoops.add(scoop);
    }

    return scoops;
  }

  /// Génère des collectes individuelles
  static List<Individuel> _generateIndividuel(int count, DateTime baseDate) {
    final individuels = <Individuel>[];

    for (int i = 0; i < count; i++) {
      final site = sites[(i + 2) % sites.length];
      final date = baseDate.add(Duration(days: i));

      final contenants = <IndividuelContenant>[
        IndividuelContenant(
          typeContenant: typesContenant[_random.nextInt(typesContenant.length)],
          typeMiel: typesMiel[_random.nextInt(typesMiel.length)],
          quantite: randAround(60.0, 15.0),
          prixUnitaire: 4000,
          montantTotal: 0, // Sera calculé après
        ),
        IndividuelContenant(
          typeContenant: typesContenant[_random.nextInt(typesContenant.length)],
          typeMiel: typesMiel[_random.nextInt(typesMiel.length)],
          quantite: randAround(35.0, 10.0),
          prixUnitaire: 4000,
          montantTotal: 0, // Sera calculé après
        ),
      ];

      // Calcul des totaux pour chaque contenant
      for (var i = 0; i < contenants.length; i++) {
        final contenant = contenants[i];
        contenants[i] = IndividuelContenant(
          typeContenant: contenant.typeContenant,
          typeMiel: contenant.typeMiel,
          quantite: contenant.quantite,
          prixUnitaire: contenant.prixUnitaire,
          montantTotal: contenant.quantite * contenant.prixUnitaire,
        );
      }

      final totalWeight = contenants.fold(0.0, (sum, c) => sum + c.quantite);
      final totalAmount =
          contenants.fold(0.0, (sum, c) => sum + c.montantTotal);

      final individuel = Individuel(
        id: 'IND-${(20250801 + i).toString()}',
        path:
            'Sites/$site/nos_achats_individuels/IND-${(20250801 + i).toString()}',
        site: site,
        date: date,
        technicien: techniciens[(i + 3) % techniciens.length],
        statut: statuses[(i + 2) % statuses.length],
        totalWeight: totalWeight,
        totalAmount: totalAmount,
        nomProducteur: producteurs[i % producteurs.length],
        originesFlorales: [
          florales[_random.nextInt(florales.length)],
          florales[_random.nextInt(florales.length)],
        ].toSet().toList(),
        observations: _random.nextBool()
            ? 'Qualité correcte, taux d\'humidité acceptable.'
            : null,
        contenants: contenants,
      );

      individuels.add(individuel);
    }

    return individuels;
  }

  /// Obtient toutes les données d'options pour les filtres
  static Map<String, List<String>> getFilterOptions(
      Map<Section, List<BaseCollecte>> data) {
    final allCollectes = [
      ...data[Section.recoltes] ?? [],
      ...data[Section.scoop] ?? [],
      ...data[Section.individuel] ?? [],
    ];

    final allSites = allCollectes.map((c) => c.site).cast<String>().toSet().toList()..sort();
    final allTechs = allCollectes
        .map((c) => c.technicien)
        .where((t) => t != null && t.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList()
      ..sort();

    return {
      'sites': allSites,
      'techniciens': allTechs,
      'statuses': List<String>.from(statuses),
      'florales': List<String>.from(florales),
    };
  }
}
