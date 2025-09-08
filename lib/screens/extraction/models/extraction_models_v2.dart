import '../../controle_de_donnes/models/attribution_models_v2.dart';

/// Technologie d'extraction utilisée
enum TechnologieExtraction {
  manuelle('Manuelle'),
  machine('Machine');

  const TechnologieExtraction(this.label);
  final String label;
}

/// Statut d'une extraction
enum StatutExtraction {
  en_cours('En cours'),
  terminee('Terminée'),
  annulee('Annulée');

  const StatutExtraction(this.label);
  final String label;
}

/// Modèle pour une extraction complète
class ExtractionData {
  final String id;
  final String siteExtraction;
  final String extracteur;
  final DateTime dateExtraction;
  final TechnologieExtraction technologie;
  final List<ProductControle>
      produitsExtraction; // Produits sélectionnés pour extraction
  final double poidsTotal; // Somme des poids des contenants (auto-calculé)
  final double quantiteExtraiteReelle; // Quantité réellement extraite (saisie)
  final double
      residusRestants; // Auto-calculé : poidsTotal - quantiteExtraiteReelle
  final String? observations;
  final StatutExtraction statut;
  final DateTime dateCreation;
  final DateTime? dateModification;

  // Statistiques
  final double rendementExtraction; // quantiteExtraiteReelle / poidsTotal * 100
  final int nombreContenants; // produits.length

  ExtractionData({
    required this.id,
    required this.siteExtraction,
    required this.extracteur,
    required this.dateExtraction,
    required this.technologie,
    required this.produitsExtraction,
    required this.quantiteExtraiteReelle,
    this.observations,
    this.statut = StatutExtraction.en_cours,
    DateTime? dateCreation,
    this.dateModification,
  })  : poidsTotal =
            produitsExtraction.fold(0.0, (sum, p) => sum + p.poidsTotal),
        residusRestants =
            produitsExtraction.fold(0.0, (sum, p) => sum + p.poidsTotal) -
                quantiteExtraiteReelle,
        rendementExtraction =
            produitsExtraction.fold(0.0, (sum, p) => sum + p.poidsTotal) > 0
                ? (quantiteExtraiteReelle /
                        produitsExtraction.fold(
                            0.0, (sum, p) => sum + p.poidsTotal)) *
                    100
                : 0,
        nombreContenants = produitsExtraction.length,
        dateCreation = dateCreation ?? DateTime.now();

  /// Convertit en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'siteExtraction': siteExtraction,
      'extracteur': extracteur,
      'dateExtraction': dateExtraction.toIso8601String(),
      'technologie': technologie.name,
      'produitsExtraction': produitsExtraction.map((p) => p.toMap()).toList(),
      'poidsTotal': poidsTotal,
      'quantiteExtraiteReelle': quantiteExtraiteReelle,
      'residusRestants': residusRestants,
      'observations': observations,
      'statut': statut.name,
      'dateCreation': dateCreation.toIso8601String(),
      'dateModification': dateModification?.toIso8601String(),
      'rendementExtraction': rendementExtraction,
      'nombreContenants': nombreContenants,

      // Métadonnées pour les statistiques
      'metadata': {
        'nombreProduits': produitsExtraction.length,
        'typesNature':
            produitsExtraction.map((p) => p.nature.name).toSet().toList(),
        'sitesOrigine':
            produitsExtraction.map((p) => p.siteOrigine).toSet().toList(),
        'villagesTouches':
            produitsExtraction.map((p) => p.village).toSet().toList(),
        'periodeExtraction': {
          'debut': dateExtraction.toIso8601String(),
          'fin': dateExtraction.toIso8601String(),
        },
      },
    };
  }

  /// Crée depuis une Map Firestore
  factory ExtractionData.fromMap(Map<String, dynamic> map) {
    return ExtractionData(
      id: map['id'] ?? '',
      siteExtraction: map['siteExtraction'] ?? '',
      extracteur: map['extracteur'] ?? '',
      dateExtraction: DateTime.parse(map['dateExtraction']),
      technologie: TechnologieExtraction.values.firstWhere(
        (t) => t.name == map['technologie'],
        orElse: () => TechnologieExtraction.manuelle,
      ),
      produitsExtraction: (map['produitsExtraction'] as List<dynamic>?)
              ?.map((p) => ProductControle.fromMap(p))
              .toList() ??
          [],
      quantiteExtraiteReelle: (map['quantiteExtraiteReelle'] ?? 0).toDouble(),
      observations: map['observations'],
      statut: StatutExtraction.values.firstWhere(
        (s) => s.name == map['statut'],
        orElse: () => StatutExtraction.en_cours,
      ),
      dateCreation: map['dateCreation'] != null
          ? DateTime.parse(map['dateCreation'])
          : DateTime.now(),
      dateModification: map['dateModification'] != null
          ? DateTime.parse(map['dateModification'])
          : null,
    );
  }

  /// Copie avec modifications
  ExtractionData copyWith({
    String? id,
    String? siteExtraction,
    String? extracteur,
    DateTime? dateExtraction,
    TechnologieExtraction? technologie,
    List<ProductControle>? produitsExtraction,
    double? quantiteExtraiteReelle,
    String? observations,
    StatutExtraction? statut,
    DateTime? dateCreation,
    DateTime? dateModification,
  }) {
    return ExtractionData(
      id: id ?? this.id,
      siteExtraction: siteExtraction ?? this.siteExtraction,
      extracteur: extracteur ?? this.extracteur,
      dateExtraction: dateExtraction ?? this.dateExtraction,
      technologie: technologie ?? this.technologie,
      produitsExtraction: produitsExtraction ?? this.produitsExtraction,
      quantiteExtraiteReelle:
          quantiteExtraiteReelle ?? this.quantiteExtraiteReelle,
      observations: observations ?? this.observations,
      statut: statut ?? this.statut,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? DateTime.now(),
    );
  }
}

/// Modèle pour les statistiques d'extraction
class ExtractionStatistics {
  final int totalExtractions;
  final double poidsTotal;
  final double quantiteTotaleExtraite;
  final double rendementMoyen;
  final Map<String, int> repartitionTechnologie;
  final Map<String, double> repartitionSites;
  final DateTime? premiereExtraction;
  final DateTime? derniereExtraction;

  ExtractionStatistics({
    required this.totalExtractions,
    required this.poidsTotal,
    required this.quantiteTotaleExtraite,
    required this.rendementMoyen,
    required this.repartitionTechnologie,
    required this.repartitionSites,
    this.premiereExtraction,
    this.derniereExtraction,
  });

  /// Convertit en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'totalExtractions': totalExtractions,
      'poidsTotal': poidsTotal,
      'quantiteTotaleExtraite': quantiteTotaleExtraite,
      'rendementMoyen': rendementMoyen,
      'repartitionTechnologie': repartitionTechnologie,
      'repartitionSites': repartitionSites,
      'premiereExtraction': premiereExtraction?.toIso8601String(),
      'derniereExtraction': derniereExtraction?.toIso8601String(),
      'derniereMiseAJour': DateTime.now().toIso8601String(),
    };
  }

  /// Crée depuis une Map Firestore
  factory ExtractionStatistics.fromMap(Map<String, dynamic> map) {
    return ExtractionStatistics(
      totalExtractions: map['totalExtractions'] ?? 0,
      poidsTotal: (map['poidsTotal'] ?? 0).toDouble(),
      quantiteTotaleExtraite: (map['quantiteTotaleExtraite'] ?? 0).toDouble(),
      rendementMoyen: (map['rendementMoyen'] ?? 0).toDouble(),
      repartitionTechnologie:
          Map<String, int>.from(map['repartitionTechnologie'] ?? {}),
      repartitionSites: Map<String, double>.from(map['repartitionSites'] ?? {}),
      premiereExtraction: map['premiereExtraction'] != null
          ? DateTime.parse(map['premiereExtraction'])
          : null,
      derniereExtraction: map['derniereExtraction'] != null
          ? DateTime.parse(map['derniereExtraction'])
          : null,
    );
  }
}
