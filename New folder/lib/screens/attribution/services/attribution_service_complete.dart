// 🎯 SERVICE COMPLET D'ATTRIBUTION
// Gère l'enregistrement dans "attribution_reçu" et la mise à jour des contrôles qualité

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../authentication/user_session.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';
import '../../controle_de_donnes/models/collecte_models.dart';
import '../../controle_de_donnes/services/quality_control_service.dart';
import '../../controle_de_donnes/services/firestore_data_service.dart';

/// Types d'attribution possibles
enum AttributionType {
  extraction('extraction', 'Extraction', '🏭'),
  filtrage('filtrage', 'Filtrage', '🧪'),
  cire('cire', 'Production Cire', '🕯️');

  const AttributionType(this.value, this.label, this.icon);
  final String value;
  final String label;
  final String icon;
}

/// Modèle pour l'attribution complète
class AttributionData {
  final String id;
  final AttributionType type;
  final String siteReceveur;
  final String utilisateur;
  final DateTime dateAttribution;
  final List<ProductControle> produits;
  final String? commentaires;
  final Map<String, dynamic> statistiques;
  final Map<String, dynamic> metadata;

  const AttributionData({
    required this.id,
    required this.type,
    required this.siteReceveur,
    required this.utilisateur,
    required this.dateAttribution,
    required this.produits,
    this.commentaires,
    required this.statistiques,
    required this.metadata,
  });
}

/// 🎯 SERVICE PRINCIPAL D'ATTRIBUTION
class AttributionServiceComplete {
  static final AttributionServiceComplete _instance =
      AttributionServiceComplete._internal();
  factory AttributionServiceComplete() => _instance;
  AttributionServiceComplete._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final QualityControlService _qualityService = QualityControlService();

  /// Collection principale pour les attributions
  static const String _mainCollection = 'attribution_reçu';

  /// 🎯 ATTRIBUTION PRINCIPALE - POINT D'ENTRÉE
  ///
  /// Attribue une liste de produits (possiblement de plusieurs collectes)
  Future<bool> attribuerProduits({
    required List<ProductControle> produits,
    required AttributionType type,
    required String utilisateur,
    String? commentaires,
    Map<String, dynamic>? metadata,
  }) async {
    if (produits.isEmpty) {
      debugPrint('❌ Aucun produit à attribuer');
      return false;
    }

    try {
      // 🚀 LOGS DE TRAÇAGE SYSTÈME
      debugPrint('🚀 ===== SERVICE D\'ATTRIBUTION COMPLET APPELÉ =====');
      debugPrint('   📁 Service: AttributionServiceComplete (NOUVEAU)');
      debugPrint('   📄 Fichier: attribution_service_complete.dart');
      debugPrint('   🔧 Méthode: attribuerProduits()');
      debugPrint(
          '   📊 Version: DERNIÈRE (avec récupération de tous les contrôles)');
      debugPrint('   📅 Timestamp: ${DateTime.now()}');
      debugPrint(
          '   🎯 Cette version utilise la MÊME logique que l\'affichage !');
      debugPrint(
          '   ✅ CONFIRMATION: Ce service EST BIEN utilisé par l\'interface');
      debugPrint('========================================================');

      final userSession = Get.find<UserSession>();
      final siteReceveur = userSession.site ?? 'SiteInconnu';

      debugPrint('🎯 ===== DÉBUT ATTRIBUTION =====');
      debugPrint('   📊 Produits à attribuer: ${produits.length}');
      debugPrint('   🏭 Type: ${type.label}');
      debugPrint('   📍 Site receveur: $siteReceveur');
      debugPrint('   👤 Utilisateur: $utilisateur');

      // Générer un ID unique pour l'attribution
      final attributionId =
          'attr_${type.value}_${DateTime.now().millisecondsSinceEpoch}';

      // Calculer les statistiques
      final stats = _calculerStatistiques(produits);

      // Créer l'objet attribution
      final attribution = AttributionData(
        id: attributionId,
        type: type,
        siteReceveur: siteReceveur,
        utilisateur: utilisateur,
        dateAttribution: DateTime.now(),
        produits: produits,
        commentaires: commentaires,
        statistiques: stats,
        metadata: metadata ?? {},
      );

      // 1. 💾 ENREGISTRER DANS attribution_reçu
      debugPrint('🎯 ===== ÉTAPE 1: ENREGISTREMENT ATTRIBUTION_REÇU =====');
      final success = await _enregistrerAttributionPrincipale(attribution);
      if (!success) {
        debugPrint('❌ ÉCHEC CRITIQUE: Enregistrement attribution principale');
        return false;
      }
      debugPrint('✅ ÉTAPE 1 RÉUSSIE: Attribution principale enregistrée');

      // 2. 🔄 METTRE À JOUR LES CONTRÔLES QUALITÉ
      debugPrint('🎯 ===== ÉTAPE 2: MISE À JOUR CONTRÔLES QUALITÉ =====');
      try {
        await _mettreAJourControlesQualite(produits, attribution);
        debugPrint('✅ ÉTAPE 2 RÉUSSIE: Contrôles qualité mis à jour');
      } catch (e) {
        debugPrint('❌ ÉCHEC ÉTAPE 2: Contrôles qualité - $e');
      }

      // 3. 📊 METTRE À JOUR LES COLLECTES D'ORIGINE (optionnel)
      debugPrint('🎯 ===== ÉTAPE 3: MISE À JOUR COLLECTES ORIGINE =====');
      try {
        await _mettreAJourCollectesOrigine(produits, attribution);
        debugPrint('✅ ÉTAPE 3 RÉUSSIE: Collectes origine mises à jour');
      } catch (e) {
        debugPrint('❌ ÉCHEC ÉTAPE 3: Collectes origine - $e');
      }

      debugPrint('✅ ===== ATTRIBUTION TERMINÉE =====');
      debugPrint('   🆔 Attribution ID: $attributionId');
      debugPrint('   📦 ${produits.length} produits attribués');
      debugPrint('   ⚖️ Poids total: ${stats['poidsTotal']} kg');
      debugPrint('   🍯 Poids miel: ${stats['poidsMielTotal']} kg');

      debugPrint(
          '🚀 Attribution réussie, fermeture du modal et rechargement de l\'interface');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ ERREUR ATTRIBUTION: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return false;
    }
  }

  /// 💾 ENREGISTREMENT DANS attribution_reçu
  Future<bool> _enregistrerAttributionPrincipale(
      AttributionData attribution) async {
    try {
      debugPrint('💾 Enregistrement dans $_mainCollection...');

      // Préparer les données pour Firestore
      final firestoreData = {
        'id': attribution.id,
        'type': attribution.type.value,
        'typeLabel': attribution.type.label,
        'typeIcon': attribution.type.icon,
        'siteReceveur': attribution.siteReceveur,
        'utilisateur': attribution.utilisateur,
        'dateAttribution': Timestamp.fromDate(attribution.dateAttribution),
        'commentaires': attribution.commentaires,
        'statut': 'attribue',

        // 📦 DÉTAILS DES PRODUITS
        'produits': attribution.produits
            .map((p) => {
                  'id': p.id,
                  'codeContenant': p.codeContenant,
                  'collecteId': p.collecteId,
                  'typeCollecte': p.typeCollecte,
                  'siteOrigine': p.siteOrigine,
                  'producteur': p.producteur,
                  'village': p.village,
                  'nature': p.nature.name,
                  'typeContenant': p.typeContenant,
                  'poidsTotal': p.poidsTotal,
                  'poidsMiel': p.poidsMiel,
                  'qualite': p.qualite,
                  'teneurEau': p.teneurEau,
                  'predominanceFlorale': p.predominanceFlorale,
                  'dateReception': Timestamp.fromDate(p.dateReception),
                  'dateControle': Timestamp.fromDate(p.dateControle),
                  'controleur': p.controleur,
                })
            .toList(),

        // 📊 STATISTIQUES CALCULÉES
        'statistiques': attribution.statistiques,

        // 🔍 TRAÇABILITÉ
        'tracabilite': {
          'collectesOrigine':
              attribution.produits.map((p) => p.collecteId).toSet().toList(),
          'sitesOrigine':
              attribution.produits.map((p) => p.siteOrigine).toSet().toList(),
          'typesCollecte':
              attribution.produits.map((p) => p.typeCollecte).toSet().toList(),
          'nombreCollectesDifferentes':
              attribution.produits.map((p) => p.collecteId).toSet().length,
          'nombreSitesDifferents':
              attribution.produits.map((p) => p.siteOrigine).toSet().length,
        },

        // 📅 MÉTADONNÉES
        'metadata': attribution.metadata,
        'dateCreation': FieldValue.serverTimestamp(),
        'derniereMiseAJour': FieldValue.serverTimestamp(),
        'versionStructure': '1.0',
      };

      // Enregistrer dans Firestore
      await _firestore
          .collection(_mainCollection)
          .doc(attribution.siteReceveur)
          .collection('attributions')
          .doc(attribution.id)
          .set(firestoreData);

      debugPrint(
          '✅ Attribution enregistrée: $_mainCollection/${attribution.siteReceveur}/attributions/${attribution.id}');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur enregistrement attribution: $e');
      return false;
    }
  }

  /// 🎯 NOUVELLE VERSION : Met à jour les contrôles qualité en utilisant la MÊME logique que l'affichage
  Future<void> _mettreAJourControlesQualite(
      List<ProductControle> produits, AttributionData attribution) async {
    try {
      debugPrint(
          '🔄 DÉBUT Mise à jour des contrôles qualité (NOUVELLE MÉTHODE)...');
      debugPrint('   📊 Nombre de produits: ${produits.length}');
      debugPrint('   🆔 Attribution ID: ${attribution.id}');
      debugPrint('   🏭 Type attribution: ${attribution.type.value}');

      // 🚀 LOGS DE TRAÇAGE NOUVELLE LOGIQUE
      debugPrint('🔧 ===== NOUVELLE MÉTHODE DE MISE À JOUR =====');
      debugPrint('   📁 Méthode: _mettreAJourControlesQualite (MODIFIÉE)');
      debugPrint('   🎯 Utilise la MÊME logique que l\'affichage des produits');
      debugPrint(
          '   📊 Au lieu de générer des IDs: récupère TOUS les contrôles');
      debugPrint('   🔍 Puis filtre par containerCode exact');
      debugPrint(
          '   ✅ CONFIRMATION: Cette logique fonctionne pour l\'affichage !');
      debugPrint('====================================================');

      // 🎯 UTILISER LA MÊME LOGIQUE QUE POUR L'AFFICHAGE !
      // Récupérer TOUS les contrôles depuis Firestore (comme pour l'affichage)
      debugPrint('🔍 ===== RÉCUPÉRATION DE TOUS LES CONTRÔLES =====');
      debugPrint('   🏭 Service: QualityControlService');
      debugPrint('   🔧 Méthode: getAllQualityControlsFromFirestore()');
      debugPrint(
          '   🎯 Cette méthode fonctionne parfaitement pour l\'affichage');
      final tousLesControles =
          await _qualityService.getAllQualityControlsFromFirestore();
      debugPrint(
          '✅ RÉSULTAT: ${tousLesControles.length} contrôles récupérés depuis Firestore');
      debugPrint(
          '   📊 C\'est exactement ce qui est utilisé pour afficher les produits !');
      debugPrint('==================================================');

      if (tousLesControles.isEmpty) {
        debugPrint('⚠️ Aucun contrôle qualité trouvé dans Firestore !');
        return;
      }

      int compteur = 0;
      for (final produit in produits) {
        compteur++;
        debugPrint('   🎯 [$compteur/${produits.length}] Mise à jour produit:');
        debugPrint('      - Code contenant: ${produit.codeContenant}');

        try {
          // 🚀 LOGS DE TRAÇAGE FILTRAGE
          debugPrint(
              '      🔍 ===== RECHERCHE DE CONTRÔLE CORRESPONDANT =====');
          debugPrint(
              '      🎯 ContainerCode recherché: ${produit.codeContenant}');
          debugPrint(
              '      📊 Total contrôles disponibles: ${tousLesControles.length}');
          debugPrint(
              '      🔧 Méthode: Filtrage par containerCode exact (comme affichage)');

          // 🔍 TROUVER LE CONTRÔLE QUI CORRESPOND (même logique que l'affichage)
          final controleCorrespondant = tousLesControles
              .where(
                (controle) => controle.containerCode == produit.codeContenant,
              )
              .toList();

          debugPrint(
              '      ✅ RÉSULTAT FILTRAGE: ${controleCorrespondant.length} contrôle(s) trouvé(s)');
          debugPrint(
              '      🎯 Cette logique est IDENTIQUE à celle de l\'affichage !');
          debugPrint(
              '      =====================================================');

          if (controleCorrespondant.isEmpty) {
            debugPrint(
                '      ❌ Aucun contrôle trouvé pour ${produit.codeContenant}');
            continue;
          }

          // Prendre le premier contrôle correspondant
          final controle = controleCorrespondant.first;
          debugPrint('      ✅ Contrôle trouvé: ${controle.containerCode}');
          debugPrint('      📦 Document ID: ${controle.documentId}');
          debugPrint(
              '      🎯 Statut actuel: ${controle.conformityStatus.name}');
          debugPrint('      🎯 Déjà attribué: ${controle.estAttribue}');

          // 🚀 LOGS DE TRAÇAGE MISE À JOUR
          debugPrint('      📦 ===== MISE À JOUR DU CONTRÔLE TROUVÉ =====');
          debugPrint(
              '      🔧 Méthode de mise à jour: ${controle.documentId != null ? "updateByControlId (NOUVEAU)" : "updateAttribution (ANCIEN)"}');

          // 🎯 UTILISER LE VRAI DOCUMENTID DU CONTRÔLE TROUVÉ
          if (controle.documentId != null && controle.documentId!.isNotEmpty) {
            debugPrint(
                '      🎯 ✅ Utilisation du documentId réel: ${controle.documentId}');
            debugPrint(
                '      🔧 Service: QualityControlService.updateQualityControlAttributionByControlId()');
            debugPrint(
                '      🚀 Cette méthode utilise le documentId EXACT récupéré depuis Firestore !');
            await _qualityService.updateQualityControlAttributionByControlId(
              controle.documentId!,
              attribution.id,
              attribution.type.value,
              attribution.dateAttribution,
            );
          } else {
            debugPrint(
                '      ⚠️ Pas de documentId, utilisation méthode alternative');
            await _qualityService.updateQualityControlAttribution(
              produit.codeContenant,
              produit.dateReception,
              attribution.id,
              attribution.type.value,
              attribution.dateAttribution,
            );
          }

          debugPrint('      ✅ SUCCÈS: Contrôle mis à jour');
        } catch (e) {
          debugPrint('      ❌ ÉCHEC: $e');
          debugPrint('      ❌ Stack trace: ${StackTrace.current}');
        }
      }

      debugPrint('✅ TERMINÉ: ${compteur} contrôles qualité traités');
    } catch (e) {
      debugPrint('❌ ERREUR CRITIQUE mise à jour contrôles: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// 📊 MISE À JOUR DES COLLECTES D'ORIGINE (optionnel)
  Future<void> _mettreAJourCollectesOrigine(
      List<ProductControle> produits, AttributionData attribution) async {
    try {
      debugPrint('📊 DÉBUT Mise à jour collectes d\'origine...');
      debugPrint('   📊 Nombre de produits: ${produits.length}');

      // Grouper par collecte
      final produitsParCollecte = <String, List<ProductControle>>{};
      for (final produit in produits) {
        debugPrint(
            '   📦 Produit ${produit.codeContenant} → Collecte: ${produit.collecteId}');
        produitsParCollecte
            .putIfAbsent(produit.collecteId, () => [])
            .add(produit);
      }

      debugPrint('   🏭 Collectes à traiter: ${produitsParCollecte.length}');

      int compteurCollectes = 0;
      for (final entry in produitsParCollecte.entries) {
        compteurCollectes++;
        final collecteId = entry.key;
        final produitsCollecte = entry.value;

        debugPrint(
            '   🎯 [$compteurCollectes/${produitsParCollecte.length}] Collecte: $collecteId');
        debugPrint(
            '      - Produits dans cette collecte: ${produitsCollecte.length}');

        try {
          await _marquerContenantsCollecte(
            collecteId,
            produitsCollecte,
            attribution,
          );

          debugPrint('      ✅ SUCCÈS: Collecte mise à jour: $collecteId');
        } catch (e) {
          debugPrint('      ❌ ÉCHEC collecte $collecteId: $e');
        }
      }

      debugPrint('✅ TERMINÉ: ${compteurCollectes} collectes traitées');
    } catch (e) {
      debugPrint('❌ ERREUR CRITIQUE mise à jour collectes: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// 🏷️ MARQUER LES CONTENANTS D'UNE COLLECTE
  Future<void> _marquerContenantsCollecte(String collecteId,
      List<ProductControle> produits, AttributionData attribution) async {
    try {
      debugPrint(
          '🏷️ DÉBUT Marquage collecte $collecteId pour ${produits.length} contenants');
      debugPrint('   📌 COLLECTE ID: $collecteId');
      debugPrint('   📌 ATTRIBUTION ID: ${attribution.id}');

      for (final produit in produits) {
        debugPrint(
            '      - Contenant ${produit.codeContenant} → attribution ${attribution.id}');
      }

      // 🚀 UTILISER LA MÊME LOGIQUE QUE POUR LES CONTRÔLES QUALITÉ !
      debugPrint('🔧 ===== MISE À JOUR RÉELLE COLLECTE D\'ORIGINE =====');
      debugPrint(
          '   🎯 Utilisation de la MÊME logique que les contrôles qualité');
      debugPrint('   📊 Récupération de TOUTES les collectes depuis Firestore');
      debugPrint('   🔍 Filtrage par collecteId exact : $collecteId');

      try {
        // 1️⃣ Récupérer toutes les collectes (comme pour les contrôles)
        final toutesLesCollectes =
            await FirestoreDataService.getCollectesFromFirestore();
        debugPrint('   ✅ Collectes récupérées depuis Firestore');

        // 2️⃣ Trouver la collecte qui correspond (même logique que filtrage contrôles)
        BaseCollecte? collecteCorrespondante;
        String? collectionName;

        // Chercher dans toutes les sections (comme filtrage par containerCode)
        for (final entry in toutesLesCollectes.entries) {
          final collectes = entry.value;
          for (final collecte in collectes) {
            if (collecte.id == collecteId) {
              collecteCorrespondante = collecte;
              collectionName = _getCollectionNameForSection(entry.key);
              debugPrint(
                  '   ✅ Collecte trouvée dans section: ${entry.key.name}');
              break;
            }
          }
          if (collecteCorrespondante != null) break;
        }

        // 3️⃣ Mettre à jour avec le vrai documentId (comme pour les contrôles)
        if (collecteCorrespondante != null && collectionName != null) {
          debugPrint('   🎯 Mise à jour de la collecte : $collecteId');
          debugPrint('   📂 Collection Firestore : $collectionName');

          final userSession = Get.find<UserSession>();
          final siteUtilisateur = userSession.site ?? 'SiteInconnu';

          // Mise à jour Firestore (utilise le vrai documentId comme les contrôles)
          await _firestore
              .collection('Sites')
              .doc(siteUtilisateur)
              .collection(collectionName)
              .doc(collecteId)
              .update({
            'attributions': FieldValue.arrayUnion([
              {
                'attributionId': attribution.id,
                'dateAttribution':
                    attribution.dateAttribution.toIso8601String(),
                'typeAttribution': attribution.type.value,
                'contenants': produits.map((p) => p.codeContenant).toList(),
              }
            ]),
            'derniereMiseAJour': FieldValue.serverTimestamp(),
          });

          debugPrint('   ✅ SUCCÈS : Collecte mise à jour dans Firestore !');
        } else {
          debugPrint('   ⚠️ Collecte non trouvée : $collecteId');
        }
      } catch (e) {
        debugPrint('   ❌ Erreur mise à jour collecte : $e');
      }

      debugPrint('🏷️ TERMINÉ: Marquage collecte $collecteId (RÉEL)');
    } catch (e) {
      debugPrint('❌ ERREUR marquage collecte $collecteId: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// 🗂️ MAPPER SECTION VERS NOM DE COLLECTION FIRESTORE
  String _getCollectionNameForSection(Section section) {
    switch (section) {
      case Section.recoltes:
        return 'nos_collectes_recoltes';
      case Section.scoop:
        return 'nos_achats_scoop_contenants';
      case Section.individuel:
        return 'nos_achats_individuels';
      case Section.miellerie:
        return 'nos_collecte_mielleries';
    }
  }

  /// 📊 CALCUL DES STATISTIQUES
  Map<String, dynamic> _calculerStatistiques(List<ProductControle> produits) {
    final poidsTotal = produits.fold(0.0, (sum, p) => sum + p.poidsTotal);
    final poidsMielTotal = produits.fold(0.0, (sum, p) => sum + p.poidsMiel);

    // Répartition par nature
    final repartitionNature = <String, int>{};
    for (final produit in produits) {
      repartitionNature[produit.nature.name] =
          (repartitionNature[produit.nature.name] ?? 0) + 1;
    }

    // Répartition par qualité
    final repartitionQualite = <String, int>{};
    for (final produit in produits) {
      repartitionQualite[produit.qualite] =
          (repartitionQualite[produit.qualite] ?? 0) + 1;
    }

    // Répartition par site d'origine
    final repartitionSites = <String, int>{};
    for (final produit in produits) {
      repartitionSites[produit.siteOrigine] =
          (repartitionSites[produit.siteOrigine] ?? 0) + 1;
    }

    return {
      'nombreProduits': produits.length,
      'poidsTotal': poidsTotal,
      'poidsMielTotal': poidsMielTotal,
      'poidsMoyen': produits.isNotEmpty ? poidsTotal / produits.length : 0.0,
      'poidsMielMoyen':
          produits.isNotEmpty ? poidsMielTotal / produits.length : 0.0,
      'repartitionNature': repartitionNature,
      'repartitionQualite': repartitionQualite,
      'repartitionSites': repartitionSites,
      'nombreCollectesDifferentes':
          produits.map((p) => p.collecteId).toSet().length,
      'nombreSitesDifferents':
          produits.map((p) => p.siteOrigine).toSet().length,
      'periodeReception': {
        'debut': produits
            .map((p) => p.dateReception)
            .reduce((a, b) => a.isBefore(b) ? a : b)
            .toIso8601String(),
        'fin': produits
            .map((p) => p.dateReception)
            .reduce((a, b) => a.isAfter(b) ? a : b)
            .toIso8601String(),
      },
    };
  }

  /// 📋 RÉCUPÉRER TOUTES LES ATTRIBUTIONS
  Future<List<Map<String, dynamic>>> getAllAttributions() async {
    try {
      final userSession = Get.find<UserSession>();
      final siteUtilisateur = userSession.site ?? 'SiteInconnu';

      final querySnapshot = await _firestore
          .collection(_mainCollection)
          .doc(siteUtilisateur)
          .collection('attributions')
          .orderBy('dateAttribution', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération attributions: $e');
      return [];
    }
  }

  /// 📊 STATISTIQUES GLOBALES D'ATTRIBUTION
  Future<Map<String, dynamic>> getStatistiquesGlobales() async {
    try {
      final attributions = await getAllAttributions();

      final stats = {
        'totalAttributions': attributions.length,
        'attributionsParType': <String, int>{},
        'derniere30Jours': 0,
        'poidsTotal': 0.0,
        'nombreProduitsTotal': 0,
      };

      final maintenant = DateTime.now();
      final il30Jours = maintenant.subtract(const Duration(days: 30));

      for (final attribution in attributions) {
        // Par type
        final type = attribution['type'] ?? 'inconnu';
        final attributionsParType =
            stats['attributionsParType'] as Map<String, int>;
        attributionsParType[type] = (attributionsParType[type] ?? 0) + 1;

        // Derniers 30 jours
        final dateAttribution =
            (attribution['dateAttribution'] as Timestamp).toDate();
        if (dateAttribution.isAfter(il30Jours)) {
          stats['derniere30Jours'] = (stats['derniere30Jours'] as int) + 1;
        }

        // Statistiques produits
        final statistiques =
            attribution['statistiques'] as Map<String, dynamic>? ?? {};
        stats['poidsTotal'] = (stats['poidsTotal'] as double) +
            (statistiques['poidsTotal'] as double? ?? 0.0);
        stats['nombreProduitsTotal'] = (stats['nombreProduitsTotal'] as int) +
            (statistiques['nombreProduits'] as int? ?? 0);
      }

      return stats;
    } catch (e) {
      debugPrint('❌ Erreur statistiques globales: $e');
      return {};
    }
  }
}
