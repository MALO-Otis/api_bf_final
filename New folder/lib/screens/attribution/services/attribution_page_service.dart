import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';
import '../../controle_de_donnes/services/firestore_data_service.dart';
import '../../controle_de_donnes/models/collecte_models.dart';
import '../../controle_de_donnes/services/quality_control_service.dart';
import '../../controle_de_donnes/models/quality_control_models.dart';

/// 🎯 SERVICE POUR LA PAGE D'ATTRIBUTION UNIFIÉE
///
/// Ce service gère toute la logique métier pour la nouvelle page d'attribution
/// unifiant extraction, filtrage et traitement cire
class AttributionPageService {
  static final AttributionPageService _instance =
      AttributionPageService._internal();
  factory AttributionPageService() => _instance;
  AttributionPageService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final QualityControlService _qualityService = QualityControlService();

  /// 📊 RÉCUPÉRATION DES PRODUITS DISPONIBLES POUR ATTRIBUTION
  ///
  /// Charge tous les produits contrôlés et conformes qui peuvent être attribués
  /// UTILISE LE MÊME SYSTÈME QUE LA PAGE PRINCIPALE POUR ÊTRE COHÉRENT
  Future<List<ProductControle>> getProduitsDisponiblesAttribution() async {
    try {
      debugPrint('🔄 Attribution: Début chargement produits...');

      // ✅ UTILISER LE SERVICE DE LA PAGE PRINCIPALE
      // Au lieu de chercher dans 'controles_qualite' (qui est vide)
      // On utilise FirestoreDataService qui va dans les vraies collections
      final collectesData =
          await FirestoreDataService.getCollectesFromFirestore();

      final produits = <ProductControle>[];
      int totalCollectesTraitees = 0;

      // Parcourir toutes les collectes pour extraire les produits contrôlés
      for (final section in collectesData.entries) {
        final collectes = section.value;
        totalCollectesTraitees += collectes.length;
        debugPrint(
            '📋 Attribution: Section ${section.key.name}: ${collectes.length} collectes');

        for (final collecte in collectes) {
          // Analyser chaque collecte
          final containersCount = collecte.containersCount ?? 0;
          debugPrint('   📦 Attribution: Collecte ${collecte.id}:');
          debugPrint('      - Type: ${collecte.runtimeType}');
          debugPrint('      - Site: ${collecte.site}');
          debugPrint('      - Date: ${collecte.date}');
          debugPrint('      - Technicien: ${collecte.technicien}');
          debugPrint('      - ContainersCount: $containersCount');
          debugPrint('      - TotalWeight: ${collecte.totalWeight}');

          // Convertir chaque collecte en produits disponibles pour attribution
          final produitsFromCollecte =
              await _convertCollecteToProductsControle(collecte);
          debugPrint(
              '      → Produits générés: ${produitsFromCollecte.length}');

          if (produitsFromCollecte.isNotEmpty) {
            debugPrint(
                '      → Premier produit: ${produitsFromCollecte.first.id}');
            debugPrint(
                '         - Nature: ${produitsFromCollecte.first.nature.name}');
            debugPrint(
                '         - Conforme: ${produitsFromCollecte.first.estConforme}');
            debugPrint(
                '         - Attribué: ${produitsFromCollecte.first.estAttribue}');
          }

          produits.addAll(produitsFromCollecte);
        }
      }

      debugPrint('📈 Attribution: Résumé collectes:');
      debugPrint('   - Total collectes traitées: $totalCollectesTraitees');
      debugPrint('   - Total produits générés: ${produits.length}');

      // Analyser la répartition par nature
      final brutsCount =
          produits.where((p) => p.nature == ProductNature.brut).length;
      final liquidesCount =
          produits.where((p) => p.nature == ProductNature.liquide).length;
      final cireCount =
          produits.where((p) => p.nature == ProductNature.cire).length;

      debugPrint('📊 Attribution: Répartition par nature:');
      debugPrint('   - Bruts: $brutsCount');
      debugPrint('   - Liquides: $liquidesCount');
      debugPrint('   - Cire: $cireCount');

      // Filtrer les produits qui peuvent être attribués
      final produitsDisponibles = produits.where(_peutEtreAttribue).toList();

      debugPrint('📊 Attribution: Filtrage final:');
      debugPrint('   - Avant filtrage: ${produits.length}');
      debugPrint('   - Après filtrage: ${produitsDisponibles.length}');

      // Analyser pourquoi certains produits sont filtrés
      final produitsRejetes =
          produits.where((p) => !_peutEtreAttribue(p)).toList();
      debugPrint('   - Produits rejetés: ${produitsRejetes.length}');

      if (produitsRejetes.isNotEmpty) {
        final premierRejete = produitsRejetes.first;
        debugPrint('   - Exemple rejeté: ${premierRejete.id}');
        debugPrint('     * estControle: ${premierRejete.estControle}');
        debugPrint('     * estConforme: ${premierRejete.estConforme}');
        debugPrint('     * estAttribue: ${premierRejete.estAttribue}');
        debugPrint('     * statutControle: ${premierRejete.statutControle}');
      }

      debugPrint(
          '✅ Attribution: ${produitsDisponibles.length} produits disponibles pour attribution');
      return produitsDisponibles;
    } catch (e) {
      debugPrint('❌ Attribution: Erreur récupération produits: $e');
      debugPrint('❌ Attribution: Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// 🔍 FILTRAGE AVANCÉ DES PRODUITS
  ///
  /// Applique des filtres spécifiques selon les critères
  List<ProductControle> filtrerProduits(
    List<ProductControle> produits, {
    ProductNature? nature,
    String? site,
    String? qualite,
    bool? urgentOnly,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? searchQuery,
  }) {
    return produits.where((produit) {
      // Filtre par nature
      if (nature != null && produit.nature != nature) return false;

      // Filtre par site
      if (site != null && produit.siteOrigine != site) return false;

      // Filtre par qualité
      if (qualite != null && produit.qualite != qualite) return false;

      // Filtre urgence
      if (urgentOnly == true && !produit.isUrgent) return false;

      // Filtre par date
      if (dateDebut != null && produit.dateReception.isBefore(dateDebut))
        return false;
      if (dateFin != null && produit.dateReception.isAfter(dateFin))
        return false;

      // Filtre par recherche textuelle
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!produit.producteur.toLowerCase().contains(query) &&
            !produit.codeContenant.toLowerCase().contains(query) &&
            !produit.village.toLowerCase().contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// 📈 CALCUL DES STATISTIQUES
  ///
  /// Génère les statistiques pour le tableau de bord
  Map<String, int> calculerStatistiques(List<ProductControle> produits) {
    final stats = <String, int>{
      'total': produits.length,
      'bruts': produits.where((p) => p.nature == ProductNature.brut).length,
      'liquides':
          produits.where((p) => p.nature == ProductNature.liquide).length,
      'cire': produits.where((p) => p.nature == ProductNature.cire).length,
      'urgents': produits.where((p) => p.isUrgent).length,
      'conformes': produits.where((p) => p.estConforme).length,
      'nonConformes': produits.where((p) => !p.estConforme).length,
    };

    // Statistiques par site
    final parSite = <String, int>{};
    for (final produit in produits) {
      parSite[produit.siteOrigine] = (parSite[produit.siteOrigine] ?? 0) + 1;
    }
    stats['nombreSites'] = parSite.length;

    return stats;
  }

  /// ✅ VÉRIFICATION D'ATTRIBUTION
  ///
  /// Vérifie si un produit peut être attribué
  bool _peutEtreAttribue(ProductControle produit) {
    // Le produit doit être contrôlé ET conforme ET non attribué
    return produit.estControle &&
        produit.estConforme &&
        !produit.estAttribue &&
        (produit.statutControle == 'valide' ||
            produit.statutControle == 'termine');
  }

  /// 🎯 ATTRIBUTION SPÉCIFIQUE PAR TYPE
  ///
  /// Récupère les produits disponibles pour un type d'attribution spécifique
  Future<List<ProductControle>> getProduitsParType(AttributionType type) async {
    final tousProduits = await getProduitsDisponiblesAttribution();

    return tousProduits.where((produit) {
      switch (type) {
        case AttributionType.extraction:
          return produit.nature == ProductNature.brut;
        case AttributionType.filtration:
          return produit.nature == ProductNature.liquide;
        case AttributionType.traitementCire:
          return produit.nature == ProductNature.cire;
      }
    }).toList();
  }

  /// 📊 STATISTIQUES DÉTAILLÉES PAR TYPE
  ///
  /// Génère des statistiques spécifiques pour chaque type d'attribution
  Future<Map<String, dynamic>> getStatistiquesDetaillees() async {
    final produits = await getProduitsDisponiblesAttribution();

    return {
      'global': calculerStatistiques(produits),
      'extraction': {
        'disponibles':
            produits.where((p) => p.nature == ProductNature.brut).length,
        'urgents': produits
            .where((p) => p.nature == ProductNature.brut && p.isUrgent)
            .length,
      },
      'filtrage': {
        'disponibles':
            produits.where((p) => p.nature == ProductNature.liquide).length,
        'urgents': produits
            .where((p) => p.nature == ProductNature.liquide && p.isUrgent)
            .length,
      },
      'traitementCire': {
        'disponibles':
            produits.where((p) => p.nature == ProductNature.cire).length,
        'urgents': produits
            .where((p) => p.nature == ProductNature.cire && p.isUrgent)
            .length,
      },
    };
  }

  /// 🔍 RECHERCHE AVANCÉE
  ///
  /// Effectue une recherche textuelle avancée
  Future<List<ProductControle>> rechercherProduits(String query) async {
    if (query.trim().isEmpty) return [];

    final produits = await getProduitsDisponiblesAttribution();
    final queryLower = query.toLowerCase().trim();

    return produits.where((produit) {
      return produit.codeContenant.toLowerCase().contains(queryLower) ||
          produit.producteur.toLowerCase().contains(queryLower) ||
          produit.village.toLowerCase().contains(queryLower) ||
          produit.commune.toLowerCase().contains(queryLower) ||
          produit.qualite.toLowerCase().contains(queryLower) ||
          produit.predominanceFlorale.toLowerCase().contains(queryLower);
    }).toList();
  }

  /// 🏷️ MISE À JOUR STATUT ATTRIBUTION
  ///
  /// Met à jour le statut d'attribution d'un produit
  Future<void> marquerCommeAttribue(
      String produitId, AttributionType type, String attributionId) async {
    try {
      await _firestore.collection('controles_qualite').doc(produitId).update({
        'estAttribue': true,
        'attributionId': attributionId,
        'typeAttribution': type.value,
        'dateAttribution': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Erreur mise à jour attribution: $e');
      rethrow;
    }
  }

  /// 🔄 CONVERSION DES COLLECTES EN PRODUITS CONTRÔLÉS
  ///
  /// Convertit une collecte (BaseCollecte) en liste de ProductControle
  /// 🔧 UTILISE UNIQUEMENT LES VRAIES DONNÉES DE CONTRÔLE QUALITÉ DEPUIS FIRESTORE !
  Future<List<ProductControle>> _convertCollecteToProductsControle(
      BaseCollecte collecte) async {
    final produits = <ProductControle>[];

    try {
      debugPrint(
          '🔄 [NOUVEAU] Récupération contrôles qualité pour collecte ${collecte.id}:');
      debugPrint('   - Type collecte: ${collecte.runtimeType}');
      debugPrint('   - Site: ${collecte.site}');
      debugPrint('   - Date: ${collecte.date}');

      // 🎯 RÉCUPÉRER LES CONTRÔLES PAR MÉTHODE ALTERNATIVE (containerCode)
      // Méthode 1: Essayer avec collecteId (pour les nouveaux contrôles)
      List<QualityControlData> controles =
          await _qualityService.getQualityControlsForCollecte(collecte.id);

      debugPrint('✅ Contrôles via collecteId: ${controles.length}');

      // Méthode 2: Si aucun contrôle trouvé, chercher par containerCode pattern
      if (controles.isEmpty) {
        debugPrint('🔍 Recherche alternative par containerCode...');
        controles = await _getQualityControlsByContainerPattern(collecte);
        debugPrint('✅ Contrôles via containerCode: ${controles.length}');
      }

      if (controles.isEmpty) {
        debugPrint(
            '⚠️ AUCUN contrôle qualité trouvé pour collecte ${collecte.id}');
        debugPrint('   📋 Type: ${collecte.runtimeType}');
        debugPrint('   📅 Date: ${collecte.date}');
        debugPrint('   🏭 Site: ${collecte.site}');
        return produits; // Retourner une liste vide
      }

      // 🔧 CRÉER LES PRODUITS À PARTIR DES VRAIES DONNÉES DE CONTRÔLE
      for (final controle in controles) {
        // Ne prendre que les produits conformes et non attribués
        if (controle.conformityStatus == ConformityStatus.conforme &&
            !controle.estAttribue) {
          debugPrint('   → Produit conforme trouvé: ${controle.containerCode}');
          debugPrint(
              '      - Poids total contrôle: ${controle.totalWeight} kg');
          debugPrint('      - Poids miel contrôle: ${controle.honeyWeight} kg');
          debugPrint('      - Qualité: ${controle.quality}');

          // Déterminer la nature selon le type de miel du contrôle
          ProductNature nature;
          switch (controle.honeyNature) {
            case HoneyNature.brut:
              nature = ProductNature.brut;
              break;
            case HoneyNature.prefilitre:
              nature = ProductNature.liquide;
              break;
          }

          final produit = ProductControle(
            id: '${collecte.id}_${controle.containerCode}',
            codeContenant: controle.containerCode,
            dateReception: controle.receptionDate,
            producteur: controle.producer,
            village: controle.apiaryVillage,
            commune: '', // Pas disponible dans les données de contrôle
            quartier: '', // Pas disponible dans les données de contrôle
            nature: nature,
            typeContenant: controle.containerType,
            numeroContenant: controle.containerNumber,
            // 🎯 UTILISER LES VRAIS POIDS DU CONTRÔLE QUALITÉ !
            poidsTotal: controle.totalWeight,
            poidsMiel: controle.honeyWeight,
            qualite: controle.quality,
            teneurEau: controle.waterContent,
            predominanceFlorale: controle.floralPredominance,
            estConforme: controle.conformityStatus == ConformityStatus.conforme,
            causeNonConformite: controle.nonConformityCause,
            observations: controle.observations,
            dateControle: controle.createdAt,
            controleur: controle.controllerName,
            estAttribue: controle.estAttribue,
            attributionId: controle.attributionId,
            typeAttribution: controle.typeAttribution,
            dateAttribution: controle.dateAttribution,
            controlId: controle.documentId ??
                '${controle.containerCode}_${controle.receptionDate.millisecondsSinceEpoch}', // 🆕 Utiliser le documentId réel ou fallback
            siteOrigine: collecte.site,
            collecteId: collecte.id,
            typeCollecte: collecte.runtimeType.toString(),
            dateCollecte: collecte.date,
            estControle: true,
            statutControle: 'valide',
            metadata: {
              'source': 'quality_control',
              'convertedAt': DateTime.now().toIso8601String(),
            },
          );

          produits.add(produit);

          debugPrint('   ✅ Produit créé depuis contrôle: ${produit.id}');
          debugPrint(
              '      - Poids total: ${produit.poidsTotal.toStringAsFixed(2)} kg (CONTRÔLE)');
          debugPrint(
              '      - Poids miel: ${produit.poidsMiel.toStringAsFixed(2)} kg (CONTRÔLE)');
          debugPrint('      - Nature: ${produit.nature.name}');
          debugPrint('      - Conforme: ${produit.estConforme}');
        } else {
          debugPrint('   ❌ Produit non disponible: ${controle.containerCode}');
          debugPrint(
              '      - Conforme: ${controle.conformityStatus == ConformityStatus.conforme}');
          debugPrint('      - Attribué: ${controle.estAttribue}');
        }
      }

      debugPrint('📊 === RÉSUMÉ COLLECTE ${collecte.id} ===');
      debugPrint('   🔍 Contrôles trouvés: ${controles.length}');
      debugPrint('   ✅ Produits disponibles: ${produits.length}');
      debugPrint(
          '   ⚖️ Poids total (depuis contrôles): ${produits.fold(0.0, (sum, p) => sum + p.poidsTotal).toStringAsFixed(2)} kg');
      debugPrint(
          '   🍯 Poids miel total (depuis contrôles): ${produits.fold(0.0, (sum, p) => sum + p.poidsMiel).toStringAsFixed(2)} kg');
      debugPrint('   ===============================================');

      return produits;
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur conversion collecte ${collecte.id}: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }

    return produits;
  }

  /// 🆕 RECHERCHE ALTERNATIVE PAR CONTAINERCODE EXACT
  ///
  /// Cherche les contrôles qualité qui correspondent exactement aux contenants de cette collecte
  /// Plus précis que le pattern matching, utilise les vrais containerCode
  Future<List<QualityControlData>> _getQualityControlsByContainerPattern(
      BaseCollecte collecte) async {
    try {
      // Récupérer TOUS les contrôles qualité existants
      final tousLesControles =
          await _qualityService.getAllQualityControlsFromFirestore();
      debugPrint('🔍 Total contrôles disponibles: ${tousLesControles.length}');

      if (tousLesControles.isEmpty) {
        return [];
      }

      // 🎯 EXTRAIRE LES VRAIS CONTAINERCODE DE CETTE COLLECTE
      final containerCodesCollecte =
          _extractContainerCodesFromCollecte(collecte);
      debugPrint('🎯 ContainerCodes réels de collecte ${collecte.id}:');
      for (final code in containerCodesCollecte) {
        debugPrint('   📦 $code');
      }

      if (containerCodesCollecte.isEmpty) {
        debugPrint('⚠️ Aucun containerCode trouvé dans la collecte');
        return [];
      }

      // Filtrer les contrôles qui correspondent EXACTEMENT aux containerCode de cette collecte
      final controlesCorrespondants = <QualityControlData>[];

      for (final controle in tousLesControles) {
        if (containerCodesCollecte.contains(controle.containerCode)) {
          controlesCorrespondants.add(controle);
          debugPrint('   ✅ MATCH EXACT: ${controle.containerCode}');
          debugPrint('      - Poids total: ${controle.totalWeight} kg');
          debugPrint('      - Poids miel: ${controle.honeyWeight} kg');
          debugPrint('      - Producteur: ${controle.producer}');
          debugPrint('      - Statut: ${controle.conformityStatus.name}');
        }
      }

      debugPrint(
          '📊 Contrôles trouvés par matching exact: ${controlesCorrespondants.length}');
      return controlesCorrespondants;
    } catch (e) {
      debugPrint('❌ Erreur recherche par containerCode exact: $e');
      return [];
    }
  }

  /// Extrait les containerCode réels d'une collecte
  List<String> _extractContainerCodesFromCollecte(BaseCollecte collecte) {
    final containerCodes = <String>[];

    try {
      debugPrint(
          '🔍 Extraction containerCodes de ${collecte.runtimeType} ${collecte.id}');

      if (collecte is Recolte) {
        // Pour les récoltes, parcourir les contenants
        for (final contenant in collecte.contenants) {
          containerCodes.add(contenant.id);
          debugPrint('   📦 Recolte → ${contenant.id}');
        }
      } else if (collecte is Scoop) {
        // Pour les SCOOP, parcourir les contenants
        for (final contenant in collecte.contenants) {
          containerCodes.add(contenant.id);
          debugPrint('   📦 Scoop → ${contenant.id}');
        }
      } else if (collecte is Individuel) {
        // Pour les individuel, parcourir les contenants
        for (final contenant in collecte.contenants) {
          containerCodes.add(contenant.id);
          debugPrint('   📦 Individuel → ${contenant.id}');
        }
      } else if (collecte is Miellerie) {
        // Pour les mielleries, parcourir les contenants
        for (final contenant in collecte.contenants) {
          containerCodes.add(contenant.id);
          debugPrint('   📦 Miellerie → ${contenant.id}');
        }
      } else {
        debugPrint('❌ Type de collecte non reconnu: ${collecte.runtimeType}');
      }

      debugPrint('✅ ${containerCodes.length} containerCodes extraits');
    } catch (e) {
      debugPrint('❌ Erreur extraction containerCodes: $e');
    }

    return containerCodes;
  }
}
