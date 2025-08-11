import 'dart:math';
import '../models/extraction_models.dart';

/// Service pour la gestion des données d'extraction
class ExtractionService {
  static final ExtractionService _instance = ExtractionService._internal();
  factory ExtractionService() => _instance;
  ExtractionService._internal();

  // Simulation d'une base de données en mémoire
  final List<ExtractionProduct> _products = [];
  final List<String> _sites = [
    'Ouaga',
    'Koudougou',
    'Bobo',
    'Mangodara',
    'Bagre',
    'Pô'
  ];
  final List<String> _collecteurs = [
    'Amadou Traoré',
    'Fatima Ouédraogo',
    'Ibrahim Sawadogo',
    'Aïssata Compaoré',
    'Moussa Kaboré',
    'Rasmané Zongo'
  ];
  final List<String> _extracteurs = [
    'Jean-Baptiste Ouédraogo',
    'Marie Kaboré',
    'Paul Sawadogo',
    'Aminata Traoré',
    'Boukary Compaoré',
    'Salamata Zongo'
  ];

  /// Génère des données d'extraction fictives
  List<ExtractionProduct> generateMockData({int count = 50}) {
    _products.clear();
    final random = Random();

    for (int i = 0; i < count; i++) {
      final dateAttribution =
          DateTime.now().subtract(Duration(days: random.nextInt(30)));

      final statut = ExtractionStatus
          .values[random.nextInt(ExtractionStatus.values.length)];
      final priorite = ExtractionPriority
          .values[random.nextInt(ExtractionPriority.values.length)];
      final type =
          ProductType.values[random.nextInt(ProductType.values.length)];

      DateTime? dateDebut;
      DateTime? dateFin;
      double? rendement;

      if (statut == ExtractionStatus.enCours ||
          statut == ExtractionStatus.termine) {
        dateDebut = dateAttribution.add(Duration(days: random.nextInt(5)));

        if (statut == ExtractionStatus.termine) {
          dateFin = dateDebut.add(Duration(hours: 2 + random.nextInt(8)));
          rendement = 75.0 + random.nextDouble() * 20; // 75-95%
        }
      }

      final product = ExtractionProduct(
        id: 'EXT${(i + 1).toString().padLeft(3, '0')}',
        nom: '${type.label} ${_sites[random.nextInt(_sites.length)]} #${i + 1}',
        type: type,
        origine: _sites[random.nextInt(_sites.length)],
        collecteur: _collecteurs[random.nextInt(_collecteurs.length)],
        dateAttribution: dateAttribution,
        dateExtractionPrevue:
            dateAttribution.add(Duration(days: 1 + random.nextInt(7))),
        quantiteContenants: 1 + random.nextInt(10),
        poidsTotal: 5.0 + random.nextDouble() * 45.0, // 5-50 kg
        statut: statut,
        priorite: priorite,
        instructions: random.nextBool() ? _getRandomInstructions() : null,
        commentaires: random.nextBool() ? _getRandomCommentaires() : null,
        qualite: _generateQualityData(random),
        attributeurId: 'CTRL${random.nextInt(5) + 1}',
        extracteurId: _extracteurs[random.nextInt(_extracteurs.length)],
        dateDebutExtraction: dateDebut,
        dateFinExtraction: dateFin,
        rendementExtraction: rendement,
        problemes: random.nextBool() ? _getRandomProblemes() : [],
        resultats: statut == ExtractionStatus.termine
            ? _generateResultats(random)
            : {},
      );

      _products.add(product);
    }

    return _products;
  }

  /// Instructions aléatoires
  String _getRandomInstructions() {
    final instructions = [
      'Extraction à température contrôlée (max 40°C)',
      'Filtrage fin requis après extraction',
      'Attention: produit cristallisé, chauffer légèrement',
      'Extraction urgente - priorité absolue',
      'Vérifier la teneur en eau avant extraction',
      'Produit de qualité premium - manipulation délicate',
    ];
    return instructions[Random().nextInt(instructions.length)];
  }

  /// Commentaires aléatoires
  String _getRandomCommentaires() {
    final commentaires = [
      'Produit de très bonne qualité',
      'Légère cristallisation observée',
      'Origine florale: acacia dominant',
      'Client VIP - traitement prioritaire',
      'Échantillon prélevé pour analyse',
      'Produit bio certifié',
    ];
    return commentaires[Random().nextInt(commentaires.length)];
  }

  /// Problèmes aléatoires
  List<String> _getRandomProblemes() {
    final problemes = [
      'Cristallisation excessive',
      'Teneur en eau élevée',
      'Présence d\'impuretés',
      'Température d\'extraction dépassée',
      'Équipement défaillant',
      'Contamination croisée détectée',
    ];
    final count = 1 + Random().nextInt(2); // 1-2 problèmes
    final selected = <String>[];
    for (int i = 0; i < count; i++) {
      final probleme = problemes[Random().nextInt(problemes.length)];
      if (!selected.contains(probleme)) {
        selected.add(probleme);
      }
    }
    return selected;
  }

  /// Données de qualité aléatoires
  Map<String, dynamic> _generateQualityData(Random random) {
    return {
      'teneurEau': 15.0 + random.nextDouble() * 5.0, // 15-20%
      'ph': 3.5 + random.nextDouble() * 1.5, // 3.5-5.0
      'conductivite': 200 + random.nextDouble() * 800, // 200-1000 μS/cm
      'couleur': [
        'Blanc',
        'Ambre clair',
        'Ambre',
        'Ambre foncé'
      ][random.nextInt(4)],
      'cristallisation': [
        'Liquide',
        'Partiellement cristallisé',
        'Cristallisé'
      ][random.nextInt(3)],
      'conformite': random.nextBool() ? 'Conforme' : 'Non conforme',
    };
  }

  /// Résultats d'extraction aléatoires
  Map<String, String> _generateResultats(Random random) {
    return {
      'quantiteExtraite':
          '${(15.0 + random.nextDouble() * 35.0).toStringAsFixed(2)} kg',
      'qualiteFinale': ['A+', 'A', 'B+', 'B'][random.nextInt(4)],
      'dateExtraction': DateTime.now()
          .subtract(Duration(days: random.nextInt(7)))
          .toString()
          .split(' ')[0],
      'operateur': _extracteurs[random.nextInt(_extracteurs.length)],
      'dureeExtraction': '${2 + random.nextInt(6)}h ${random.nextInt(60)}min',
    };
  }

  /// Récupère tous les produits
  List<ExtractionProduct> getAllProducts() {
    if (_products.isEmpty) {
      generateMockData();
    }
    return List.from(_products);
  }

  /// Filtre les produits selon les critères
  List<ExtractionProduct> filterProducts(
      List<ExtractionProduct> products, ExtractionFilters filters) {
    return products.where((product) {
      // Filtre par statut
      if (filters.statuts.isNotEmpty &&
          !filters.statuts.contains(product.statut)) {
        return false;
      }

      // Filtre par priorité
      if (filters.priorites.isNotEmpty &&
          !filters.priorites.contains(product.priorite)) {
        return false;
      }

      // Filtre par type
      if (filters.types.isNotEmpty && !filters.types.contains(product.type)) {
        return false;
      }

      // Filtre par origine
      if (filters.origines.isNotEmpty &&
          !filters.origines.contains(product.origine)) {
        return false;
      }

      // Filtre par extracteur
      if (filters.extracteurs.isNotEmpty &&
          !filters.extracteurs.contains(product.extracteurId)) {
        return false;
      }

      // Filtre par date de début
      if (filters.dateDebutFrom != null &&
          product.dateDebutExtraction != null) {
        if (product.dateDebutExtraction!.isBefore(filters.dateDebutFrom!)) {
          return false;
        }
      }
      if (filters.dateDebutTo != null && product.dateDebutExtraction != null) {
        if (product.dateDebutExtraction!.isAfter(filters.dateDebutTo!)) {
          return false;
        }
      }

      // Filtre par date de fin
      if (filters.dateFinFrom != null && product.dateFinExtraction != null) {
        if (product.dateFinExtraction!.isBefore(filters.dateFinFrom!)) {
          return false;
        }
      }
      if (filters.dateFinTo != null && product.dateFinExtraction != null) {
        if (product.dateFinExtraction!.isAfter(filters.dateFinTo!)) {
          return false;
        }
      }

      // Filtre par poids
      if (filters.poidsMin != null && product.poidsTotal < filters.poidsMin!) {
        return false;
      }
      if (filters.poidsMax != null && product.poidsTotal > filters.poidsMax!) {
        return false;
      }

      // Filtre par rendement
      if (filters.rendementMin != null && product.rendementExtraction != null) {
        if (product.rendementExtraction! < filters.rendementMin!) {
          return false;
        }
      }
      if (filters.rendementMax != null && product.rendementExtraction != null) {
        if (product.rendementExtraction! > filters.rendementMax!) {
          return false;
        }
      }

      // Filtre par recherche textuelle
      if (filters.searchQuery.isNotEmpty) {
        final query = filters.searchQuery.toLowerCase();
        final searchText =
            '${product.nom} ${product.collecteur} ${product.origine} ${product.extracteurId}'
                .toLowerCase();
        if (!searchText.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Met à jour le statut d'un produit
  void updateProductStatus(String productId, ExtractionStatus newStatus) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final product = _products[index];
      final now = DateTime.now();

      ExtractionProduct updatedProduct = product.copyWith(statut: newStatus);

      // Met à jour les dates selon le statut
      switch (newStatus) {
        case ExtractionStatus.enCours:
          updatedProduct = updatedProduct.copyWith(dateDebutExtraction: now);
          break;
        case ExtractionStatus.termine:
          if (product.dateDebutExtraction != null) {
            updatedProduct = updatedProduct.copyWith(
              dateFinExtraction: now,
              rendementExtraction: 75.0 + Random().nextDouble() * 20,
            );
          }
          break;
        default:
          break;
      }

      _products[index] = updatedProduct;
    }
  }

  /// Démarre l'extraction d'un produit
  void startExtraction(String productId) {
    updateProductStatus(productId, ExtractionStatus.enCours);
  }

  /// Termine l'extraction d'un produit
  void completeExtraction(String productId, Map<String, String> resultats) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      _products[index] = _products[index].copyWith(
        statut: ExtractionStatus.termine,
        dateFinExtraction: DateTime.now(),
        rendementExtraction: double.tryParse(resultats['rendement'] ?? '85'),
        resultats: resultats,
      );
    }
  }

  /// Suspend l'extraction d'un produit
  void suspendExtraction(String productId, String raison) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final problems = List<String>.from(_products[index].problemes);
      problems.add(raison);
      _products[index] = _products[index].copyWith(
        statut: ExtractionStatus.suspendu,
        problemes: problems,
      );
    }
  }

  /// Récupère les options de filtres
  Map<String, List<String>> getFilterOptions() {
    final products = getAllProducts();

    return {
      'origines': _sites,
      'extracteurs': _extracteurs,
      'collecteurs': products.map((p) => p.collecteur).toSet().toList()..sort(),
    };
  }

  /// Calcule les statistiques
  ExtractionStats getStats() {
    final products = getAllProducts();
    return ExtractionStats.fromProducts(products);
  }
}
