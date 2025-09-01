import 'package:flutter/foundation.dart';
import '../models/filtered_product_models.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';
import '../../controle_de_donnes/services/attribution_service.dart';
import '../../extraction/services/extraction_service.dart';

/// Service pour gérer les produits attribués au filtrage
class FilteredProductsService {
  static final FilteredProductsService _instance =
      FilteredProductsService._internal();
  factory FilteredProductsService() => _instance;
  FilteredProductsService._internal();

  // Stockage en mémoire des produits attribués au filtrage
  final Map<String, FilteredProduct> _filteredProducts = {};
  final AttributionService _attributionService = AttributionService();
  final ExtractionService _extractionService = ExtractionService();
  bool _isInitialized = false;

  /// Initialise le service si nécessaire
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _syncWithAttributionService();
      await _syncWithExtractionService();
      _isInitialized = true;
    }
  }

  /// Récupère tous les produits attribués pour filtrage
  Future<List<FilteredProduct>> getFilteredProducts({
    String? siteFiltreur,
    FilteredProductFilters? filters,
  }) async {
    // S'assurer que le service est initialisé
    await _ensureInitialized();

    var products = _filteredProducts.values.toList();

    // Appliquer les filtres si fournis
    if (filters != null) {
      products = products.where((p) => filters.matches(p)).toList();
    }

    // Filtrer par site si spécifié
    if (siteFiltreur != null) {
      products = products
          .where((p) =>
              p.siteOrigine.toLowerCase().contains(siteFiltreur.toLowerCase()))
          .toList();
    }

    // Trier par date d'attribution (plus récent en premier)
    products.sort((a, b) => b.dateAttribution.compareTo(a.dateAttribution));

    if (kDebugMode) {
      print(
          '📦 Filtrage: ${products.length} produits récupérés pour le site $siteFiltreur');
    }

    return products;
  }

  /// Synchronise avec le service d'attribution pour les produits LIQUIDE du contrôle
  Future<void> _syncWithAttributionService() async {
    try {
      // Récupérer UNIQUEMENT les attributions pour filtration (produits LIQUIDE)
      final attributions = await _attributionService
          .getAttributionsByType(AttributionType.filtration);

      for (final attribution in attributions) {
        final produitsIds = attribution.produitsIds;

        for (final produitId in produitsIds) {
          // Récupérer le produit du service d'attribution
          final produitControle =
              await _attributionService.getProduit(produitId);

          if (produitControle != null) {
            // FILTRE CRITIQUE: Ne prendre que les produits LIQUIDE/FILTRE pour le filtrage
            if (produitControle.nature != ProductNature.filtre) {
              if (kDebugMode) {
                print(
                    '⚠️ Produit ${produitControle.id} ignoré - Nature: ${produitControle.nature.label} (seuls les produits LIQUIDE sont acceptés en filtrage)');
              }
              continue;
            }

            // Convertir en FilteredProduct si pas encore fait
            if (!_filteredProducts.containsKey(produitControle.id)) {
              final filteredProduct = FilteredProduct.fromProductControle(
                produitControle,
                attribution.id,
                attribution.attributeurNom,
                attribution.dateAttribution,
              );
              _filteredProducts[produitControle.id] = filteredProduct;
            }
          }
        }
      }

      if (kDebugMode) {
        final controlCount = _filteredProducts.values
            .where((p) => p.estOrigineDuControle)
            .length;
        print(
            '✅ Synchronisation contrôle terminée: $controlCount produits LIQUIDE attribués pour filtrage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur synchronisation avec attribution service: $e');
      }
    }
  }

  /// Synchronise avec le service d'extraction pour les produits extraits non filtrés
  Future<void> _syncWithExtractionService() async {
    try {
      // Récupérer tous les produits extraits qui ont été attribués au filtrage par l'extracteur
      final extractions = await _extractionService.getExtractions();

      for (final extraction in extractions) {
        // Vérifier si cette extraction a été attribuée au filtrage
        if (extraction['attributions'] != null) {
          final attributions = extraction['attributions'] as List;

          for (final attribution in attributions) {
            if (attribution['type'] == 'filtration') {
              // Créer un FilteredProduct à partir du produit extrait
              final filteredProduct = FilteredProduct.fromExtractedProduct(
                extraction,
                attribution['id'],
                attribution['extracteur_nom'],
                DateTime.parse(attribution['date_attribution']),
              );

              _filteredProducts[filteredProduct.id] = filteredProduct;
            }
          }
        }
      }

      if (kDebugMode) {
        final extractionCount = _filteredProducts.values
            .where((p) => p.estOrigineDeLExtraction)
            .length;
        print(
            '✅ Synchronisation extraction terminée: $extractionCount produits extraits attribués pour filtrage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur synchronisation avec extraction service: $e');
        // En cas d'erreur, générer des données de test d'extraction
        await _generateTestExtractionData();
      }
    }
  }

  /// Force la synchronisation avec les modules de contrôle et extraction
  Future<void> refresh() async {
    _filteredProducts.clear();
    _isInitialized = false;
    await _ensureInitialized();

    if (kDebugMode) {
      final controlCount =
          _filteredProducts.values.where((p) => p.estOrigineDuControle).length;
      final extractionCount = _filteredProducts.values
          .where((p) => p.estOrigineDeLExtraction)
          .length;
      print(
          '🔄 Rafraîchissement terminé: $controlCount produits du contrôle + $extractionCount produits de l\'extraction = ${_filteredProducts.length} total');
    }
  }

  /// Calcule les statistiques des produits filtrés
  Future<FilteredProductStats> getStats({
    String? siteFiltreur,
    FilteredProductFilters? filters,
  }) async {
    final products = await getFilteredProducts(
      siteFiltreur: siteFiltreur,
      filters: filters,
    );
    return FilteredProductStats.fromProducts(products);
  }

  /// Commence le filtrage d'un produit
  Future<FilteredProduct> startFiltrage(String productId) async {
    final product = _filteredProducts[productId];
    if (product == null) {
      throw Exception('Produit non trouvé: $productId');
    }

    if (product.statut != FilteredProductStatus.enAttente) {
      throw Exception('Le produit n\'est pas en attente de filtrage');
    }

    final updatedProduct = product.copyWith(
      statut: FilteredProductStatus.enCoursTraitement,
      dateDebutFiltrage: DateTime.now(),
    );

    _filteredProducts[productId] = updatedProduct;

    if (kDebugMode) {
      print('🚀 Filtrage démarré pour le produit ${product.codeContenant}');
    }

    return updatedProduct;
  }

  /// Termine le filtrage d'un produit
  Future<FilteredProduct> completeFiltrage(
    String productId,
    double poidsFiltre, {
    String? observations,
  }) async {
    final product = _filteredProducts[productId];
    if (product == null) {
      throw Exception('Produit non trouvé: $productId');
    }

    if (product.statut != FilteredProductStatus.enCoursTraitement) {
      throw Exception('Le produit n\'est pas en cours de filtrage');
    }

    final updatedProduct = product.copyWith(
      statut: FilteredProductStatus.termine,
      dateFinFiltrage: DateTime.now(),
      poidsFiltre: poidsFiltre,
      observations: observations,
      poidsDisponible:
          poidsFiltre, // Le poids disponible devient le poids filtré
    );

    _filteredProducts[productId] = updatedProduct;

    if (kDebugMode) {
      final rendement = updatedProduct.rendementFiltrage;
      print(
          '✅ Filtrage terminé pour ${product.codeContenant}: ${poidsFiltre}kg (rendement: ${rendement?.toStringAsFixed(1)}%)');
    }

    return updatedProduct;
  }

  /// Suspend le filtrage d'un produit
  Future<FilteredProduct> suspendFiltrage(
    String productId, {
    String? raison,
  }) async {
    final product = _filteredProducts[productId];
    if (product == null) {
      throw Exception('Produit non trouvé: $productId');
    }

    final updatedProduct = product.copyWith(
      statut: FilteredProductStatus.suspendu,
      observations: raison,
    );

    _filteredProducts[productId] = updatedProduct;

    if (kDebugMode) {
      print('⏸️ Filtrage suspendu pour ${product.codeContenant}: $raison');
    }

    return updatedProduct;
  }

  /// Reprend le filtrage d'un produit suspendu
  Future<FilteredProduct> resumeFiltrage(String productId) async {
    final product = _filteredProducts[productId];
    if (product == null) {
      throw Exception('Produit non trouvé: $productId');
    }

    if (product.statut != FilteredProductStatus.suspendu) {
      throw Exception('Le produit n\'est pas suspendu');
    }

    final updatedProduct = product.copyWith(
      statut: product.dateDebutFiltrage != null
          ? FilteredProductStatus.enCoursTraitement
          : FilteredProductStatus.enAttente,
    );

    _filteredProducts[productId] = updatedProduct;

    if (kDebugMode) {
      print('▶️ Filtrage repris pour ${product.codeContenant}');
    }

    return updatedProduct;
  }

  /// Récupère un produit par son ID
  Future<FilteredProduct?> getProduct(String productId) async {
    await _ensureInitialized();
    return _filteredProducts[productId];
  }

  /// Génère des données de test pour les produits d'extraction
  Future<void> _generateTestExtractionData() async {
    final testExtractions = [
      {
        'id': 'ext_001',
        'codeContenant': 'EXT_BF_2024_001',
        'typeCollecte': 'recolte',
        'collecteId': 'rec_001',
        'producteur': 'OUEDRAOGO Moussa',
        'village': 'Koudougou',
        'siteOrigine': 'Koudougou',
        'typeContenant': 'Bidon 25L',
        'poidsExtrait': 18.5,
        'teneurEau': 18.2,
        'predominanceFlorale': 'Karité',
        'qualite': 'Extra',
        'dateExtraction': '2024-01-15T10:30:00Z',
        'attributions': [
          {
            'id': 'attr_ext_001',
            'type': 'filtration',
            'extracteur_nom': 'KONE Salif',
            'date_attribution': '2024-01-15T16:00:00Z',
          }
        ],
      },
      {
        'id': 'ext_002',
        'codeContenant': 'EXT_BF_2024_002',
        'typeCollecte': 'individuel',
        'collecteId': 'ind_002',
        'producteur': 'TRAORE Fatou',
        'village': 'Bobo-Dioulasso',
        'siteOrigine': 'Bobo-Dioulasso',
        'typeContenant': 'Bidon 20L',
        'poidsExtrait': 15.2,
        'teneurEau': 17.8,
        'predominanceFlorale': 'Acacia',
        'qualite': 'Premium',
        'dateExtraction': '2024-01-16T14:15:00Z',
        'attributions': [
          {
            'id': 'attr_ext_002',
            'type': 'filtration',
            'extracteur_nom': 'SAWADOGO Pierre',
            'date_attribution': '2024-01-16T17:30:00Z',
          }
        ],
      },
    ];

    for (final extraction in testExtractions) {
      final attributions = extraction['attributions'] as List;
      for (final attribution in attributions) {
        if (attribution['type'] == 'filtration') {
          final filteredProduct = FilteredProduct.fromExtractedProduct(
            extraction,
            attribution['id'],
            attribution['extracteur_nom'],
            DateTime.parse(attribution['date_attribution']),
          );

          _filteredProducts[filteredProduct.id] = filteredProduct;
        }
      }
    }

    if (kDebugMode) {
      print('🧪 Données de test d\'extraction générées pour le filtrage');
    }
  }

  /// Récupère les produits par site
  Future<Map<String, List<FilteredProduct>>> getProductsBySite() async {
    await _ensureInitialized();

    final productsBySite = <String, List<FilteredProduct>>{};

    for (final product in _filteredProducts.values) {
      final site = product.siteOrigine;
      if (!productsBySite.containsKey(site)) {
        productsBySite[site] = [];
      }
      productsBySite[site]!.add(product);
    }

    // Trier les produits de chaque site par date
    for (final products in productsBySite.values) {
      products.sort((a, b) => b.dateAttribution.compareTo(a.dateAttribution));
    }

    return productsBySite;
  }

  /// Récupère les statistiques par origine
  Future<Map<String, int>> getStatsParOrigine() async {
    await _ensureInitialized();

    final controleCount =
        _filteredProducts.values.where((p) => p.estOrigineDuControle).length;
    final extractionCount =
        _filteredProducts.values.where((p) => p.estOrigineDeLExtraction).length;

    return {
      'controle': controleCount,
      'extraction': extractionCount,
      'total': _filteredProducts.length,
    };
  }
}

