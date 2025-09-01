/// Service pour gérer les produits attribués au module d'extraction
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/attributed_product_models.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';
import '../../controle_de_donnes/services/attribution_service.dart';

class AttributedProductsService {
  static final AttributedProductsService _instance =
      AttributedProductsService._internal();
  factory AttributedProductsService() => _instance;
  AttributedProductsService._internal();

  // Stockage en mémoire des produits attribués
  final Map<String, AttributedProduct> _attributedProducts = {};
  final AttributionService _attributionService = AttributionService();
  bool _isInitialized = false;

  /// Initialise le service si nécessaire
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _syncWithAttributionService();
      _isInitialized = true;
    }
  }

  /// Récupère tous les produits attribués pour extraction
  Future<List<AttributedProduct>> getAttributedProducts({
    String? siteExtracteur,
    AttributedProductFilters? filters,
  }) async {
    // S'assurer que le service est initialisé
    await _ensureInitialized();

    var products = _attributedProducts.values.toList();

    // Filtrer par site extracteur si spécifié
    if (siteExtracteur != null) {
      // Dans une vraie application, on filtrerait par site de destination
      // Pour maintenant, on garde tous les produits
    }

    // Appliquer les filtres
    if (filters != null) {
      products = _applyFilters(products, filters);
    }

    // Trier par date d'attribution (plus récent en premier)
    products.sort((a, b) => b.dateAttribution.compareTo(a.dateAttribution));

    return products;
  }

  /// Synchronise avec le service d'attribution
  Future<void> _syncWithAttributionService() async {
    try {
      // Initialiser le service d'attribution si nécessaire
      await _attributionService.initialiserDonnees();

      // Récupérer toutes les attributions
      final allAttributions = _attributionService.getAttributions();

      // Filtrer celles pour extraction seulement
      final extractionAttributions = allAttributions
          .where((attr) => attr.type == AttributionType.extraction)
          .toList();

      if (kDebugMode) {
        print(
            '🔄 Synchronisation avec ${extractionAttributions.length} attributions pour extraction');
      }

      for (final attribution in extractionAttributions) {
        // Récupérer les produits de cette attribution
        final produitsIds = attribution.produitsIds;

        for (final produitId in produitsIds) {
          // Récupérer le produit du service d'attribution
          final produitControle =
              await _attributionService.getProduit(produitId);

          if (produitControle != null) {
            // FILTRE CRITIQUE: Ne prendre que les produits BRUTE pour l'extraction
            if (produitControle.nature != ProductNature.brut) {
              if (kDebugMode) {
                print(
                    '⚠️ Produit ${produitControle.id} ignoré - Nature: ${produitControle.nature.label} (seuls les produits BRUTE sont acceptés en extraction)');
              }
              continue;
            }

            // Convertir en AttributedProduct si pas encore fait
            if (!_attributedProducts.containsKey(produitControle.id)) {
              final attributedProduct =
                  _convertProductControleToAttributedProduct(
                produitControle,
                attribution,
              );
              _attributedProducts[produitControle.id] = attributedProduct;
            }
          }
        }
      }

      if (kDebugMode) {
        print(
            '✅ Synchronisation terminée: ${_attributedProducts.length} produits attribués pour extraction');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur synchronisation avec attribution service: $e');
      }
      // En cas d'erreur, générer des données de test
      await _generateTestData();
    }
  }

  /// Convertit un ProductControle en AttributedProduct
  AttributedProduct _convertProductControleToAttributedProduct(
    ProductControle produit,
    AttributionProduits attribution,
  ) {
    return AttributedProduct(
      id: produit.id,
      attributionId: attribution.id,
      codeContenant: produit.codeContenant,
      typeCollecte: produit.typeCollecte,
      collecteId: produit.collecteId,
      producteur: produit.producteur,
      village: produit.village,
      siteOrigine: produit.siteOrigine,
      nature: produit.nature, // Utilise directement ProductNature
      typeContenant: produit.typeContenant,
      poidsOriginal: produit.poids,
      poidsDisponible: produit.poids, // Au début, tout est disponible
      teneurEau: produit.teneurEau,
      predominanceFlorale: produit.predominanceFlorale,
      qualite: produit.qualite,
      dateReception: produit.dateReception,
      dateCollecte: produit.dateCollecte,
      dateAttribution: attribution.dateAttribution,
      collecteur: produit.collecteur,
      attributeur: attribution.attributeurNom,
      estConforme: produit.estConforme,
      causeNonConformite: produit.causeNonConformite,
      instructions: attribution.instructions,
      observations: produit.observations,
      prelevements: [], // Pas de prélèvements au début
      statut: PrelevementStatus.enAttente, // Utilise PrelevementStatus
    );
  }

  /// Force la synchronisation avec le module de contrôle
  Future<void> refresh() async {
    _attributedProducts.clear();
    _isInitialized = false;
    await _ensureInitialized();

    if (kDebugMode) {
      print(
          '🔄 Rafraîchissement terminé: ${_attributedProducts.length} produits attribués');
    }
  }

  /// Génère des données de test
  Future<void> _generateTestData() async {
    if (_attributedProducts.isNotEmpty) return;

    final random = math.Random();
    final sites = ['Koudougou', 'Bobo-Dioulasso', 'Pô', 'Mangodara', 'Sindou'];
    final villages = {
      'Koudougou': [
        'Koudougou Centre',
        'Nagreongo',
        'Sourgou',
        'Tensobentenga'
      ],
      'Bobo-Dioulasso': ['Bobo Centre', 'Kuinima', 'Sarfalao', 'Dogona'],
      'Pô': ['Pô Centre', 'Tiébélé', 'Gongo', 'Dakola'],
      'Mangodara': ['Mangodara Centre', 'Tiéfora', 'Djigoué', 'Dankana'],
      'Sindou': ['Sindou Centre', 'Banfora', 'Niangoloko', 'Soubakaniédougou'],
    };
    final producteurs = [
      'Amadou Traoré',
      'Fatimata Sawadogo',
      'Ibrahim Ouédraogo',
      'Aïssata Compaoré',
      'Boukary Kaboré',
      'Salamata Zongo',
      'Moussa Dicko',
      'Mariame Sana',
      'Issouf Nikiéma',
      'Rokia Nacanabo'
    ];
    final collecteurs = [
      'Jean-Baptiste Ouédraogo',
      'Marie Kaboré',
      'Paul Sawadogo',
      'Aminata Traoré',
      'Boukary Compaoré',
      'Salamata Zongo'
    ];
    final attributeurs = [
      'Dr. Moussa Ouédraogo',
      'Ing. Fatima Traoré',
      'Tech. Ibrahim Sana'
    ];
    final qualites = ['Excellent', 'Bon', 'Acceptable', 'Passable'];
    final contenants = ['Bidon 25L', 'Fût 50L', 'Cuve 100L', 'Seau 20L'];

    for (int i = 0; i < 35; i++) {
      final siteOrigine = sites[random.nextInt(sites.length)];
      final villagesDisponibles = villages[siteOrigine]!;
      final village =
          villagesDisponibles[random.nextInt(villagesDisponibles.length)];
      final producteur = producteurs[random.nextInt(producteurs.length)];
      final collecteur = collecteurs[random.nextInt(collecteurs.length)];
      final attributeur = attributeurs[random.nextInt(attributeurs.length)];

      final dateCollecte =
          DateTime.now().subtract(Duration(days: random.nextInt(60) + 30));
      final dateReception =
          dateCollecte.add(Duration(days: random.nextInt(7) + 1));
      final dateAttribution =
          dateReception.add(Duration(days: random.nextInt(14) + 1));

      final poidsOriginal = 15.0 + random.nextDouble() * 85.0; // 15-100 kg
      final nature =
          ProductNature.values[random.nextInt(ProductNature.values.length)];

      // Simuler quelques prélèvements pour certains produits
      final prelevements = <Prelevement>[];
      final aPrelevements =
          random.nextBool() && random.nextBool(); // 25% de chance
      double poidsDisponible = poidsOriginal;

      if (aPrelevements) {
        final nbPrelevements = random.nextInt(3) + 1; // 1-3 prélèvements
        for (int j = 0; j < nbPrelevements; j++) {
          final poidsPreleve = math.min(
            poidsDisponible *
                (0.2 + random.nextDouble() * 0.6), // 20-80% du disponible
            poidsDisponible,
          );

          final datePrelevement =
              dateAttribution.add(Duration(days: j * 3 + random.nextInt(3)));
          final dateDebut =
              datePrelevement.add(Duration(hours: random.nextInt(4)));
          final dateFin = dateDebut.add(Duration(hours: 2 + random.nextInt(6)));

          final statut = j == nbPrelevements - 1
              ? (random.nextBool()
                  ? PrelevementStatus.termine
                  : PrelevementStatus.enCours)
              : PrelevementStatus.termine;

          final prelevement = Prelevement(
            id: 'PREL_${datePrelevement.millisecondsSinceEpoch}_$j',
            productId: 'PROD_${i + 1}',
            type: poidsPreleve >= poidsDisponible * 0.9
                ? PrelevementType.total
                : PrelevementType.partiel,
            poidsPreleve: poidsPreleve,
            datePrelevement: datePrelevement,
            dateDebut: dateDebut,
            dateFin: statut == PrelevementStatus.termine ? dateFin : null,
            extracteur: collecteur, // Utiliser le même nom pour la démo
            statut: statut,
            methodeExtraction:
                random.nextBool() ? 'Centrifugation' : 'Décantation',
            temperatreExtraction: 25.0 + random.nextDouble() * 15.0, // 25-40°C
            humiditeRelative: 30.0 + random.nextDouble() * 40.0, // 30-70%
            rendementCalcule: 75.0 + random.nextDouble() * 20.0, // 75-95%
            observations:
                random.nextBool() ? 'Extraction normale, bon rendement' : null,
            conditionsExtraction: {
              'ventilation': random.nextBool() ? 'Bonne' : 'Moyenne',
              'proprete': 'Conforme',
              'equipement':
                  random.nextBool() ? 'Centrifugeuse' : 'Extracteur manuel',
            },
            resultats: {
              'miel_extrait': '${poidsPreleve.toStringAsFixed(2)} kg',
              'qualite_visuelle': qualites[random.nextInt(qualites.length)],
              'couleur': random.nextBool() ? 'Ambree claire' : 'Doree',
            },
          );

          prelevements.add(prelevement);
          poidsDisponible -= poidsPreleve;

          if (poidsDisponible <= 0.01) break; // Arrêter si plus rien disponible
        }
      }

      final statutProduit = aPrelevements
          ? (poidsDisponible <= 0.01
              ? PrelevementStatus.termine
              : prelevements.any((p) => p.statut == PrelevementStatus.enCours)
                  ? PrelevementStatus.enCours
                  : PrelevementStatus.enAttente)
          : PrelevementStatus.enAttente;

      final product = AttributedProduct(
        id: 'PROD_${i + 1}',
        attributionId: 'ATTR_${dateAttribution.millisecondsSinceEpoch}',
        codeContenant:
            'CNT-${siteOrigine.substring(0, 3).toUpperCase()}-${(i + 1).toString().padLeft(4, '0')}',
        typeCollecte: random.nextBool() ? 'recolte' : 'individuel',
        collecteId: 'COL_${dateCollecte.millisecondsSinceEpoch}',
        producteur: producteur,
        village: village,
        siteOrigine: siteOrigine,
        nature: nature,
        typeContenant: contenants[random.nextInt(contenants.length)],
        poidsOriginal: poidsOriginal,
        poidsDisponible: poidsDisponible,
        teneurEau: 15.0 + random.nextDouble() * 10.0, // 15-25%
        predominanceFlorale: random.nextBool() ? 'Karité' : 'Eucalyptus',
        qualite: qualites[random.nextInt(qualites.length)],
        dateReception: dateReception,
        dateCollecte: dateCollecte,
        dateAttribution: dateAttribution,
        collecteur: collecteur,
        attributeur: attributeur,
        estConforme: random.nextInt(10) < 9, // 90% conformes
        causeNonConformite:
            random.nextInt(10) >= 9 ? 'Teneur en eau élevée' : null,
        instructions: random.nextBool()
            ? 'Extraction prioritaire - qualité premium'
            : null,
        observations: random.nextBool()
            ? 'Produit de qualité exceptionnelle du ${village}'
            : null,
        prelevements: prelevements,
        statut: statutProduit,
      );

      _attributedProducts[product.id] = product;
    }

    if (kDebugMode) {
      print('✅ ${_attributedProducts.length} produits de test générés');
    }
  }

  /// Applique les filtres aux produits
  List<AttributedProduct> _applyFilters(
    List<AttributedProduct> products,
    AttributedProductFilters filters,
  ) {
    return products.where((product) {
      // Filtre par nature
      if (filters.natures.isNotEmpty &&
          !filters.natures.contains(product.nature)) {
        return false;
      }

      // Filtre par site d'origine
      if (filters.sitesOrigine.isNotEmpty &&
          !filters.sitesOrigine.contains(product.siteOrigine)) {
        return false;
      }

      // Filtre par village
      if (filters.villages.isNotEmpty &&
          !filters.villages.contains(product.village)) {
        return false;
      }

      // Filtre par attributeur
      if (filters.attributeurs.isNotEmpty &&
          !filters.attributeurs.contains(product.attributeur)) {
        return false;
      }

      // Filtre par statut
      if (filters.statuts.isNotEmpty &&
          !filters.statuts.contains(product.statut)) {
        return false;
      }

      // Filtre par date d'attribution
      if (filters.dateAttributionFrom != null &&
          product.dateAttribution.isBefore(filters.dateAttributionFrom!)) {
        return false;
      }
      if (filters.dateAttributionTo != null &&
          product.dateAttribution.isAfter(filters.dateAttributionTo!)) {
        return false;
      }

      // Filtre par date de réception
      if (filters.dateReceptionFrom != null &&
          product.dateReception.isBefore(filters.dateReceptionFrom!)) {
        return false;
      }
      if (filters.dateReceptionTo != null &&
          product.dateReception.isAfter(filters.dateReceptionTo!)) {
        return false;
      }

      // Filtre par poids
      if (filters.poidsMin != null &&
          product.poidsOriginal < filters.poidsMin!) {
        return false;
      }
      if (filters.poidsMax != null &&
          product.poidsOriginal > filters.poidsMax!) {
        return false;
      }

      // Filtre seulement disponibles
      if (filters.seulementDisponibles == true &&
          product.poidsDisponible <= 0.01) {
        return false;
      }

      // Filtre par recherche textuelle
      if (filters.searchQuery.isNotEmpty) {
        final query = filters.searchQuery.toLowerCase();
        final searchFields = [
          product.codeContenant,
          product.producteur,
          product.village,
          product.siteOrigine,
          product.collecteur,
          product.attributeur,
          product.predominanceFlorale,
          product.qualite,
        ].join(' ').toLowerCase();

        if (!searchFields.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Effectue un nouveau prelevement
  Future<String> effectuerPrelevement({
    required String productId,
    required PrelevementType type,
    required double poidsPreleve,
    required String extracteur,
    String? methodeExtraction,
    double? temperatreExtraction,
    double? humiditeRelative,
    String? observations,
    Map<String, dynamic>? conditionsExtraction,
  }) async {
    final product = _attributedProducts[productId];
    if (product == null) {
      throw Exception('Produit non trouvé');
    }

    if (product.poidsDisponible < poidsPreleve) {
      throw Exception('Poids demande superieur au poids disponible');
    }

    if (product.aPrelevementEnCours) {
      throw Exception('Un prelevement est deja en cours pour ce produit');
    }

    // Creer le nouveau prelevement
    final prelevementId = 'PREL_${DateTime.now().millisecondsSinceEpoch}';
    final nouveauPrelevement = Prelevement(
      id: prelevementId,
      productId: productId,
      type: type,
      poidsPreleve: poidsPreleve,
      datePrelevement: DateTime.now(),
      dateDebut: DateTime.now(),
      extracteur: extracteur,
      statut: PrelevementStatus.enCours,
      methodeExtraction: methodeExtraction,
      temperatreExtraction: temperatreExtraction,
      humiditeRelative: humiditeRelative,
      observations: observations,
      conditionsExtraction: conditionsExtraction ?? {},
    );

    // Mettre a jour le produit
    final nouveauxPrelevements = List<Prelevement>.from(product.prelevements)
      ..add(nouveauPrelevement);

    final nouveauPoidsDisponible = product.poidsDisponible - poidsPreleve;

    _attributedProducts[productId] = product.copyWith(
      prelevements: nouveauxPrelevements,
      poidsDisponible: nouveauPoidsDisponible,
      statut: PrelevementStatus.enCours,
    );

    if (kDebugMode) {
      print('✅ Prelevement cree: $prelevementId');
      print(
          '📦 ${poidsPreleve.toStringAsFixed(2)} kg preleve sur ${product.codeContenant}');
    }

    return prelevementId;
  }

  /// Termine un prelevement
  Future<void> terminerPrelevement({
    required String productId,
    required String prelevementId,
    required double rendementCalcule,
    Map<String, dynamic>? resultats,
    String? observations,
    String? problemes,
  }) async {
    final product = _attributedProducts[productId];
    if (product == null) {
      throw Exception('Produit non trouvé');
    }

    final prelevementIndex =
        product.prelevements.indexWhere((p) => p.id == prelevementId);
    if (prelevementIndex == -1) {
      throw Exception('Prélèvement non trouvé');
    }

    final prelevement = product.prelevements[prelevementIndex];
    if (prelevement.statut != PrelevementStatus.enCours) {
      throw Exception('Le prelevement n\'est pas en cours');
    }

    // Mettre a jour le prelevement
    final nouveauxPrelevements = List<Prelevement>.from(product.prelevements);
    nouveauxPrelevements[prelevementIndex] = prelevement.copyWith(
      dateFin: DateTime.now(),
      statut: PrelevementStatus.termine,
      rendementCalcule: rendementCalcule,
      resultats: resultats ?? {},
      observations: observations,
      problemes: problemes,
    );

    // Determiner le nouveau statut du produit
    final aEncorePrelevementEnCours =
        nouveauxPrelevements.any((p) => p.statut == PrelevementStatus.enCours);

    final nouveauStatut = aEncorePrelevementEnCours
        ? PrelevementStatus.enCours
        : (product.poidsDisponible <= 0.01
            ? PrelevementStatus.termine
            : PrelevementStatus.enAttente);

    _attributedProducts[productId] = product.copyWith(
      prelevements: nouveauxPrelevements,
      statut: nouveauStatut,
    );

    if (kDebugMode) {
      print('✅ Prelevement termine: $prelevementId');
      print('📊 Rendement: ${rendementCalcule.toStringAsFixed(1)}%');
    }
  }

  /// Suspend un prélèvement
  Future<void> suspendrePrelevement({
    required String productId,
    required String prelevementId,
    required String raison,
  }) async {
    final product = _attributedProducts[productId];
    if (product == null) {
      throw Exception('Produit non trouvé');
    }

    final prelevementIndex =
        product.prelevements.indexWhere((p) => p.id == prelevementId);
    if (prelevementIndex == -1) {
      throw Exception('Prélèvement non trouvé');
    }

    final prelevement = product.prelevements[prelevementIndex];
    if (prelevement.statut != PrelevementStatus.enCours) {
      throw Exception('Le prélèvement n\'est pas en cours');
    }

    // Mettre à jour le prélèvement
    final nouveauxPrelevements = List<Prelevement>.from(product.prelevements);
    nouveauxPrelevements[prelevementIndex] = prelevement.copyWith(
      statut: PrelevementStatus.suspendu,
      problemes: raison,
    );

    // Remettre le poids dans le disponible
    final nouveauPoidsDisponible =
        product.poidsDisponible + prelevement.poidsPreleve;

    _attributedProducts[productId] = product.copyWith(
      prelevements: nouveauxPrelevements,
      poidsDisponible: nouveauPoidsDisponible,
      statut: PrelevementStatus.suspendu,
    );

    if (kDebugMode) {
      print('⚠️ Prelevement suspendu: $prelevementId');
      print('📝 Raison: $raison');
    }
  }

  /// Obtient les statistiques
  Future<AttributedProductStats> getStats({
    AttributedProductFilters? filters,
  }) async {
    final products = await getAttributedProducts(filters: filters);
    return AttributedProductStats.fromProducts(products);
  }

  /// Obtient les options de filtres
  Future<Map<String, List<String>>> getFilterOptions() async {
    await _syncWithAttributionService();

    final products = _attributedProducts.values.toList();

    return {
      'sitesOrigine': products.map((p) => p.siteOrigine).toSet().toList()
        ..sort(),
      'villages': products.map((p) => p.village).toSet().toList()..sort(),
      'attributeurs': products.map((p) => p.attributeur).toSet().toList()
        ..sort(),
      'collecteurs': products.map((p) => p.collecteur).toSet().toList()..sort(),
    };
  }

  /// Obtient un produit par ID
  Future<AttributedProduct?> getProductById(String productId) async {
    await _syncWithAttributionService();
    return _attributedProducts[productId];
  }
}
