import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../authentication/user_session.dart';
import '../models/filtered_product_models.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';
import 'filtrage_service_improved.dart';

/// Service pour gérer les produits filtrés
class FilteredProductsService {
  static final FilteredProductsService _instance =
      FilteredProductsService._internal();
  factory FilteredProductsService() => _instance;
  FilteredProductsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserSession _userSession = Get.find<UserSession>();
  final FiltrageServiceImproved _filtrageService = FiltrageServiceImproved();

  // Cache local des produits filtrés
  final List<FilteredProduct> _filteredProducts = [];

  /// Collection des produits filtrés
  String get _collection => 'Sites/${_userSession.site}/produits_filtres';

  /// Initialise le service
  Future<void> initialize() async {
    await _loadFilteredProducts();
    await _syncWithAttributionService();
  }

  /// ✅ NOUVEAU: Synchronise avec le service de filtrage pour récupérer les produits liquides
  Future<void> _syncWithAttributionService() async {
    try {
      if (kDebugMode) {
        print('🔄 FILTRAGE: Synchronisation avec le service de filtrage...');
      }

      // Récupérer tous les produits attribués au filtrage
      final allProducts = await _filtrageService.getProduitsAttribuesFiltrage();

      // Filtrer uniquement les produits liquides conformes attribués au filtrage
      final liquidProducts = allProducts.where((product) {
        return product.nature == ProductNature.liquide &&
            product.estConforme &&
            product.estControle;
      }).toList();

      if (kDebugMode) {
        print('✅ FILTRAGE: ${liquidProducts.length} produits liquides trouvés');
      }

      // Convertir en produits filtrés si ils ne sont pas déjà dans notre collection
      for (final product in liquidProducts) {
        final existingProduct =
            _filteredProducts.where((fp) => fp.id == product.id).isNotEmpty
                ? _filteredProducts.where((fp) => fp.id == product.id).first
                : null;

        if (existingProduct == null) {
          // Créer un nouveau produit filtré avec les paramètres corrects
          final filteredProduct = FilteredProduct.fromProductControle(
            product,
            'AUTO_${product.id}', // ID d'attribution automatique
            'Système', // Attributeur automatique
            DateTime.now(), // Date d'attribution automatique
          );

          // Sauvegarder en base si nécessaire
          await _saveFilteredProduct(filteredProduct);

          // Ajouter au cache local
          _filteredProducts.add(filteredProduct);

          if (kDebugMode) {
            print(
                '➕ FILTRAGE: Produit ${product.codeContenant} ajouté à la collection de filtrage');
          }
        }
      }

      if (kDebugMode) {
        print(
            '✅ FILTRAGE: Synchronisation terminée - ${_filteredProducts.length} produits dans la collection');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FILTRAGE: Erreur lors de la synchronisation: $e');
      }
    }
  }

  /// Charge les produits filtrés depuis Firestore
  Future<void> _loadFilteredProducts() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('dateReception', descending: true)
          .get();

      _filteredProducts.clear();
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final filteredProduct = FilteredProduct.fromMap(data);
        _filteredProducts.add(filteredProduct);
      }

      if (kDebugMode) {
        print(
            '✅ FILTRAGE: ${_filteredProducts.length} produits filtrés chargés depuis Firestore');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FILTRAGE: Erreur lors du chargement: $e');
      }
    }
  }

  /// Sauvegarde un produit filtré
  Future<void> _saveFilteredProduct(FilteredProduct product) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(product.id)
          .set(product.toMap());

      if (kDebugMode) {
        print('💾 FILTRAGE: Produit ${product.codeContenant} sauvegardé');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FILTRAGE: Erreur sauvegarde: $e');
      }
    }
  }

  /// ✅ NOUVEAU: Ajoute un produit depuis le service d'extraction (produit extrait vers filtrage)
  Future<void> addFromExtractedProduct(
      Map<String, dynamic> extractedProductData) async {
    try {
      // Créer un produit filtré depuis les données d'extraction avec les bons paramètres
      final filteredProduct = FilteredProduct.fromExtractedProduct(
        extractedProductData,
        'EXTRACT_${extractedProductData['id']}', // ID d'attribution
        extractedProductData['extracteur'] ?? 'Extracteur', // Nom extracteur
        DateTime.now(), // Date d'attribution
      );

      // Sauvegarder en base
      await _saveFilteredProduct(filteredProduct);

      // Ajouter au cache local
      _filteredProducts.add(filteredProduct);

      if (kDebugMode) {
        print(
            '✅ FILTRAGE: Produit extrait ${filteredProduct.codeContenant} ajouté au filtrage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FILTRAGE: Erreur ajout produit extrait: $e');
      }
      rethrow;
    }
  }

  /// ✅ NOUVEAU: Met à jour le statut d'un produit (en cours de filtrage, terminé, etc.)
  Future<void> updateProductStatus(
    String productId, {
    String? attributeur,
    DateTime? dateDebutFiltrage,
    DateTime? dateFinFiltrage,
    double? poidsFiltre,
    String? observations,
    required FilteredProductStatus statut,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'statut': statut.value,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (attributeur != null) updateData['attributeur'] = attributeur;
      if (dateDebutFiltrage != null)
        updateData['date_debut_filtrage'] = dateDebutFiltrage.toIso8601String();
      if (dateFinFiltrage != null)
        updateData['date_fin_filtrage'] = dateFinFiltrage.toIso8601String();
      if (poidsFiltre != null) updateData['poids_filtre'] = poidsFiltre;
      if (observations != null) updateData['observations'] = observations;

      await _firestore
          .collection(_collection)
          .doc(productId)
          .update(updateData);

      // Mettre à jour le cache local
      final index = _filteredProducts.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final oldProduct = _filteredProducts[index];
        final updatedProduct = oldProduct.copyWith(
          attributeur: attributeur,
          dateDebutFiltrage: dateDebutFiltrage,
          dateFinFiltrage: dateFinFiltrage,
          poidsFiltre: poidsFiltre,
          observations: observations,
          statut: statut,
        );
        _filteredProducts[index] = updatedProduct;
      }

      if (kDebugMode) {
        print(
            '✅ FILTRAGE: Statut mis à jour pour $productId → ${statut.label}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FILTRAGE: Erreur mise à jour statut: $e');
      }
      rethrow;
    }
  }

  /// Récupère tous les produits filtrés
  List<FilteredProduct> getAllFilteredProducts() {
    return List.from(_filteredProducts);
  }

  /// ✅ NOUVEAU: Récupère les produits par statut
  List<FilteredProduct> getProductsByStatus(FilteredProductStatus statut) {
    return _filteredProducts.where((product) {
      return product.statut == statut;
    }).toList();
  }

  /// ✅ NOUVEAU: Récupère les produits attribués à un agent
  List<FilteredProduct> getProductsByAgent(String attributeur) {
    return _filteredProducts.where((product) {
      return product.attributeur == attributeur;
    }).toList();
  }

  /// ✅ NOUVEAU: Récupère les statistiques de filtrage
  Map<String, dynamic> getFilteringStats() {
    final total = _filteredProducts.length;
    final enCours = _filteredProducts
        .where((p) => p.statut == FilteredProductStatus.enCoursTraitement)
        .length;
    final termines = _filteredProducts
        .where((p) => p.statut == FilteredProductStatus.termine)
        .length;
    final enAttente = _filteredProducts
        .where((p) => p.statut == FilteredProductStatus.enAttente)
        .length;

    final poidsTotal =
        _filteredProducts.fold<double>(0.0, (sum, p) => sum + p.poidsOriginal);
    final poidsFiltre = _filteredProducts
        .where((p) => p.poidsFiltre != null)
        .fold<double>(0.0, (sum, p) => sum + (p.poidsFiltre ?? 0));

    return {
      'total': total,
      'enAttente': enAttente,
      'enCours': enCours,
      'termines': termines,
      'poidsTotal': poidsTotal,
      'poidsFiltre': poidsFiltre,
      'rendementMoyen': poidsTotal > 0 ? (poidsFiltre / poidsTotal) * 100 : 0,
    };
  }

  /// Supprime un produit filtré
  Future<void> removeFilteredProduct(String productId) async {
    try {
      await _firestore.collection(_collection).doc(productId).delete();
      _filteredProducts.removeWhere((p) => p.id == productId);

      if (kDebugMode) {
        print('🗑️ FILTRAGE: Produit $productId supprimé');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FILTRAGE: Erreur suppression: $e');
      }
      rethrow;
    }
  }

  /// ✅ NOUVEAU: Récupère les produits filtrés avec filtres optionnels
  Future<List<FilteredProduct>> getFilteredProducts({
    String? siteFiltreur,
    FilteredProductFilters? filters,
  }) async {
    // S'assurer que les données sont à jour
    if (_filteredProducts.isEmpty) {
      await initialize();
    }

    List<FilteredProduct> products = List.from(_filteredProducts);

    // Appliquer les filtres si fournis
    if (filters != null) {
      products = products.where((product) => filters.matches(product)).toList();
    }

    // Filtrer par site si spécifié
    if (siteFiltreur != null && siteFiltreur.isNotEmpty) {
      products = products.where((product) {
        return product.siteOrigine
            .toLowerCase()
            .contains(siteFiltreur.toLowerCase());
      }).toList();
    }

    // Trier par date de réception (plus récent en premier)
    products.sort((a, b) => b.dateReception.compareTo(a.dateReception));

    if (kDebugMode) {
      print(
          '📋 FILTRAGE: ${products.length} produits retournés après filtrage');
    }

    return products;
  }

  /// ✅ NOUVEAU: Récupère les statistiques avec filtres optionnels
  Future<FilteredProductStats> getStats({
    String? siteFiltreur,
    FilteredProductFilters? filters,
  }) async {
    // Récupérer les produits avec les mêmes filtres
    final products = await getFilteredProducts(
      siteFiltreur: siteFiltreur,
      filters: filters,
    );

    // Générer les statistiques à partir des produits filtrés
    return FilteredProductStats.fromProducts(products);
  }

  /// Démarre le filtrage d'un produit
  Future<FilteredProduct> startFiltrage(String productId) async {
    try {
      final now = DateTime.now();

      // Mettre à jour le statut et la date de début
      await updateProductStatus(
        productId,
        dateDebutFiltrage: now,
        statut: FilteredProductStatus.enCoursTraitement,
      );

      // Récupérer le produit mis à jour depuis le cache
      final updatedProduct =
          _filteredProducts.firstWhere((p) => p.id == productId);

      if (kDebugMode) {
        print(
            '🚀 FILTRAGE: Filtrage démarré pour ${updatedProduct.codeContenant}');
      }

      return updatedProduct;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FILTRAGE: Erreur démarrage filtrage: $e');
      }
      rethrow;
    }
  }

  /// Termine le filtrage d'un produit
  Future<FilteredProduct> completeFiltrage(
    String productId,
    double poidsFiltre, {
    String? observations,
  }) async {
    try {
      final now = DateTime.now();

      // Calculer le rendement
      final product = _filteredProducts.firstWhere((p) => p.id == productId);
      final rendement = (poidsFiltre / product.poidsOriginal) * 100;

      // Mettre à jour avec toutes les données finales
      final updateData = <String, dynamic>{
        'statut': FilteredProductStatus.termine.value,
        'date_fin_filtrage': now.toIso8601String(),
        'poids_filtre': poidsFiltre,
        'rendement_filtrage': rendement,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (observations != null && observations.isNotEmpty) {
        updateData['observations'] = observations;
      }

      // Calculer la durée si on a une date de début
      if (product.dateDebutFiltrage != null) {
        final duree = now.difference(product.dateDebutFiltrage!);
        updateData['duree_filtrage'] = duree.inMinutes;
      }

      await _firestore
          .collection(_collection)
          .doc(productId)
          .update(updateData);

      // Mettre à jour le cache local
      final index = _filteredProducts.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final oldProduct = _filteredProducts[index];
        final updatedProduct = oldProduct.copyWith(
          dateFinFiltrage: now,
          poidsFiltre: poidsFiltre,
          observations: observations,
          statut: FilteredProductStatus.termine,
        );
        _filteredProducts[index] = updatedProduct;

        if (kDebugMode) {
          print(
              '✅ FILTRAGE: Filtrage terminé pour ${updatedProduct.codeContenant} - Rendement: ${rendement.toStringAsFixed(1)}%');
        }

        return updatedProduct;
      }

      throw Exception('Produit non trouvé dans le cache');
    } catch (e) {
      if (kDebugMode) {
        print('❌ FILTRAGE: Erreur finalisation filtrage: $e');
      }
      rethrow;
    }
  }

  /// Suspend le filtrage d'un produit
  Future<FilteredProduct> suspendFiltrage(
    String productId, {
    String? raison,
  }) async {
    try {
      // Mettre à jour le statut en suspension avec la raison
      await updateProductStatus(
        productId,
        observations: raison ?? 'Filtrage suspendu',
        statut: FilteredProductStatus.suspendu,
      );

      // Récupérer le produit mis à jour depuis le cache
      final updatedProduct =
          _filteredProducts.firstWhere((p) => p.id == productId);

      if (kDebugMode) {
        print(
            '⏸️ FILTRAGE: Filtrage suspendu pour ${updatedProduct.codeContenant}');
        if (raison != null) print('   Raison: $raison');
      }

      return updatedProduct;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FILTRAGE: Erreur suspension filtrage: $e');
      }
      rethrow;
    }
  }

  /// Reprend le filtrage d'un produit suspendu
  Future<FilteredProduct> resumeFiltrage(String productId) async {
    try {
      // Remettre en cours de traitement
      await updateProductStatus(
        productId,
        statut: FilteredProductStatus.enCoursTraitement,
      );

      // Récupérer le produit mis à jour depuis le cache
      final updatedProduct =
          _filteredProducts.firstWhere((p) => p.id == productId);

      if (kDebugMode) {
        print(
            '▶️ FILTRAGE: Filtrage repris pour ${updatedProduct.codeContenant}');
      }

      return updatedProduct;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FILTRAGE: Erreur reprise filtrage: $e');
      }
      rethrow;
    }
  }

  /// Actualise les données
  Future<void> refresh() async {
    await _loadFilteredProducts();
    await _syncWithAttributionService();
  }
}
