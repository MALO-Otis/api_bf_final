/// Service pour récupérer les vraies données des collectes depuis Firestore
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../authentication/user_session.dart';
import '../models/collecte_models.dart';

class FirestoreDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Structure des collections Firestore basée sur l'analyse du code
  ///
  /// RÉCOLTES: Sites/{site}/nos_collectes_recoltes/
  /// SCOOP: Sites/{site}/nos_achats_scoop_contenants/ OU {site}/collectes_scoop/collectes_scoop/ (legacy)
  /// INDIVIDUEL: Sites/{site}/nos_achats_individuels/
  /// MIELLERIE: Sites/{site}/nos_achats_miellerie/ (assumé)

  /// Récupère toutes les collectes réelles depuis Firestore
  static Future<Map<Section, List<BaseCollecte>>>
      getCollectesFromFirestore() async {
    try {
      final userSession = Get.find<UserSession>();
      final userSite = userSession.site ?? '';

      if (userSite.isEmpty) {
        throw Exception('Aucun site utilisateur trouvé');
      }

      print(
          '🔍 Chargement des collectes depuis Firestore pour le site: $userSite');

      // Chargement en parallèle de toutes les sections
      if (kDebugMode) {
        print('📊 ===== DÉBUT CHARGEMENT TOUTES COLLECTES =====');
        print('📊 Site utilisateur: $userSite');
        print('📊 Lancement du chargement en parallèle...');
      }

      final results = await Future.wait([
        _getRecoltes(userSite),
        _getScoop(userSite),
        _getIndividuel(userSite),
        _getMiellerie(userSite),
      ]);

      final data = {
        Section.recoltes: results[0],
        Section.scoop: results[1],
        Section.individuel: results[2],
        Section.miellerie: results[3],
      };

      if (kDebugMode) {
        print('📊 ===== CHARGEMENT TERMINÉ =====');
        print('📊 ✅ RÉSUMÉ GLOBAL:');
        print('📊    🏭 Récoltes: ${data[Section.recoltes]!.length} collectes');
        print('📊    🥄 SCOOP: ${data[Section.scoop]!.length} collectes');
        print(
            '📊    👤 Individuel: ${data[Section.individuel]!.length} collectes');
        print(
            '📊    🍯 Miellerie: ${data[Section.miellerie]!.length} collectes');
        print(
            '📊    📊 TOTAL: ${data.values.expand((list) => list).length} collectes');
        print('📊 ================================');
      }

      print('✅ Collectes chargées:');
      print('   - Récoltes: ${data[Section.recoltes]!.length}');
      print('   - SCOOP: ${data[Section.scoop]!.length}');
      print('   - Individuel: ${data[Section.individuel]!.length}');
      print('   - Miellerie: ${data[Section.miellerie]!.length}');

      return data;
    } catch (e) {
      print('❌ Erreur lors du chargement des collectes: $e');
      rethrow;
    }
  }

  /// Récupère les collectes de récoltes
  static Future<List<Recolte>> _getRecoltes(String site) async {
    final recoltes = <Recolte>[];

    try {
      // Nouveau chemin: Sites/{site}/nos_collectes_recoltes
      final snapshot = await _firestore
          .collection('Sites')
          .doc(site)
          .collection('nos_collectes_recoltes')
          .orderBy('createdAt', descending: true)
          .get();

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final recolte = _mapToRecolte(doc.id, site, data);
          recoltes.add(recolte);
        } catch (e) {
          print('⚠️ Erreur conversion récolte ${doc.id}: $e');
        }
      }

      print(
          '✅ ${recoltes.length} récoltes chargées depuis Sites/$site/nos_collectes_recoltes');
    } catch (e) {
      print('❌ Erreur chargement récoltes: $e');

      // Fallback vers l'ancien chemin si nécessaire
      try {
        final legacySnapshot = await _firestore
            .collection(site)
            .doc('collectes_recolte')
            .collection('collectes_recolte')
            .orderBy('createdAt', descending: true)
            .get();

        for (final doc in legacySnapshot.docs) {
          try {
            final data = doc.data();
            final recolte = _mapToRecolte(doc.id, site, data);
            recoltes.add(recolte);
          } catch (e) {
            print('⚠️ Erreur conversion récolte legacy ${doc.id}: $e');
          }
        }

        print(
            '✅ ${recoltes.length} récoltes chargées depuis $site/collectes_recolte (legacy)');
      } catch (e2) {
        print('❌ Erreur fallback récoltes: $e2');
      }
    }

    return recoltes;
  }

  /// Récupère les collectes SCOOP
  static Future<List<Scoop>> _getScoop(String site) async {
    final scoops = <Scoop>[];

    try {
      // Nouveau chemin: Sites/{site}/nos_achats_scoop_contenants
      final snapshot = await _firestore
          .collection('Sites')
          .doc(site)
          .collection('nos_achats_scoop_contenants')
          .orderBy('created_at', descending: true)
          .get();

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final scoop = await _mapToScoopAsync(doc.id, site, data);
          scoops.add(scoop);
        } catch (e) {
          print('⚠️ Erreur conversion SCOOP ${doc.id}: $e');
        }
      }

      print(
          '✅ ${scoops.length} SCOOP chargés depuis Sites/$site/nos_achats_scoop_contenants');
    } catch (e) {
      print('❌ Erreur chargement SCOOP: $e');

      // Fallback vers l'ancien chemin
      try {
        final legacySnapshot = await _firestore
            .collection(site)
            .doc('collectes_scoop')
            .collection('collectes_scoop')
            .orderBy('createdAt', descending: true)
            .get();

        for (final doc in legacySnapshot.docs) {
          try {
            final data = doc.data();
            final scoop = _mapToScoopLegacy(doc.id, site, data);
            scoops.add(scoop);
          } catch (e) {
            print('⚠️ Erreur conversion SCOOP legacy ${doc.id}: $e');
          }
        }

        print(
            '✅ ${scoops.length} SCOOP chargés depuis $site/collectes_scoop (legacy)');
      } catch (e2) {
        print('❌ Erreur fallback SCOOP: $e2');
      }
    }

    return scoops;
  }

  /// Récupère les collectes individuelles
  static Future<List<Individuel>> _getIndividuel(String site) async {
    final individuels = <Individuel>[];

    try {
      // Chemin: Sites/{site}/nos_achats_individuels
      final snapshot = await _firestore
          .collection('Sites')
          .doc(site)
          .collection('nos_achats_individuels')
          .orderBy('created_at', descending: true)
          .get();

      for (final doc in snapshot.docs) {
        try {
          // Ignorer les documents de statistiques
          if (doc.id.startsWith('_') || doc.id.contains('statistiques')) {
            continue;
          }

          final data = doc.data();
          final individuel = await _mapToIndividuelAsync(doc.id, site, data);
          individuels.add(individuel);
        } catch (e) {
          print('⚠️ Erreur conversion Individuel ${doc.id}: $e');
        }
      }

      print(
          '✅ ${individuels.length} collectes individuelles chargées depuis Sites/$site/nos_achats_individuels');
    } catch (e) {
      print('❌ Erreur chargement individuels: $e');
    }

    return individuels;
  }

  /// Convertit les données Firestore en modèle Recolte
  static Recolte _mapToRecolte(
      String docId, String site, Map<String, dynamic> data) {
    final contenants = <RecolteContenant>[];

    // Conversion des contenants
    final contenantsData = data['contenants'] as List<dynamic>? ?? [];
    for (int i = 0; i < contenantsData.length; i++) {
      final contenantData = contenantsData[i] as Map<String, dynamic>;

      if (kDebugMode) {
        print('🏭 === CONTENANT ${i + 1} ===');
        print('🏭 Données brutes: ${contenantData.keys.toList()}');
      }

      // ✅ RÉCUPÉRATION DE L'ID DEPUIS FIRESTORE (ou fallback si absent)
      final contenantId = contenantData['id']?.toString() ??
          'C${(i + 1).toString().padLeft(3, '0')}_recolte';

      if (kDebugMode) {
        print('🏭 Contenant récolte ${i + 1}: ID généré = $contenantId');
      }

      // Récupérer les informations de contrôle si elles existent
      ContainerControlInfo controlInfo = const ContainerControlInfo();
      if (contenantData['controlInfo'] != null) {
        if (kDebugMode) {
          print('🏭 ControlInfo trouvé: ${contenantData['controlInfo']}');
        }
        try {
          final controlInfoData =
              contenantData['controlInfo'] as Map<String, dynamic>;
          controlInfo = ContainerControlInfo.fromMap(controlInfoData);
          if (kDebugMode) {
            print(
                '🏭 ControlInfo parsé: isControlled=${controlInfo.isControlled}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Erreur lors de la lecture du controlInfo: $e');
          }
        }
      } else {
        if (kDebugMode) {
          print('🏭 Aucun controlInfo');
        }
      }

      contenants.add(RecolteContenant(
        id: contenantId, // ✅ CORRIGÉ: Utiliser l'ID réel
        hiveType: contenantData['hiveType']?.toString() ?? 'Non spécifié',
        containerType:
            contenantData['containerType']?.toString() ?? 'Non spécifié',
        weight: (contenantData['weight'] ?? 0).toDouble(),
        unitPrice: (contenantData['unitPrice'] ?? 0).toDouble(),
        total: (contenantData['total'] ?? 0).toDouble(),
        controlInfo: controlInfo, // ✅ AJOUTÉ: Inclure les infos de contrôle
      ));
    }

    // Conversion des prédominances florales
    final predominancesFlorales = <String>[];
    final floralesData = data['predominances_florales'];
    if (floralesData is List) {
      predominancesFlorales.addAll(floralesData.map((e) => e.toString()));
    }

    return Recolte(
      id: docId,
      path: 'Sites/$site/nos_collectes_recoltes/$docId',
      site: site,
      date: _extractDate(data),
      technicien: data['technicien_nom']?.toString(),
      statut: data['status']?.toString() ?? data['statut']?.toString(),
      totalWeight: (data['totalWeight'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      region: data['region']?.toString(),
      province: data['province']?.toString(),
      commune: data['commune']?.toString(),
      village: data['village']?.toString(),
      predominancesFlorales: predominancesFlorales,
      contenants: contenants,
    );
  }

  /// Convertit les données Firestore en modèle Scoop (avec infos géographiques)
  static Future<Scoop> _mapToScoopAsync(
      String docId, String site, Map<String, dynamic> data) async {
    final contenants = <ScoopContenant>[];

    if (kDebugMode) {
      print('🥄 ===== DÉBUT MAPPING SCOOP $docId =====');
      print('🥄 Site: $site');
      print('🥄 Champs disponibles: ${data.keys.toList()}');
      print('🥄 Données brutes complètes: $data');
      print('🥄 =====================================');
    }

    // Conversion des contenants/produits - Essayer différents champs
    List<dynamic> produitsData = [];

    // Vérifier les différents noms de champs possibles
    if (data['produits'] != null) {
      produitsData = data['produits'] as List<dynamic>;
      if (kDebugMode)
        print(
            '🥄 Utilisation du champ "produits": ${produitsData.length} éléments');
    } else if (data['contenants'] != null) {
      produitsData = data['contenants'] as List<dynamic>;
      if (kDebugMode)
        print(
            '🥄 Utilisation du champ "contenants": ${produitsData.length} éléments');
    } else if (data['details'] != null) {
      produitsData = data['details'] as List<dynamic>;
      if (kDebugMode)
        print(
            '🥄 Utilisation du champ "details": ${produitsData.length} éléments');
    }

    for (int i = 0; i < produitsData.length; i++) {
      final produitData = produitsData[i] as Map<String, dynamic>;

      if (kDebugMode) {
        print('🥄 === PRODUIT ${i + 1} ===');
        print('🥄 Champs produit: ${produitData.keys.toList()}');
      }

      // ✅ RÉCUPÉRATION DE L'ID DEPUIS FIRESTORE (ou fallback si absent)
      final contenantId = produitData['id']?.toString() ??
          'C${(i + 1).toString().padLeft(3, '0')}_scoop';

      if (kDebugMode) {
        print('🥄 Contenant SCOOP ${i + 1}: ID généré = $contenantId');
      }

      // Récupérer les informations de contrôle si elles existent
      ContainerControlInfo controlInfo = const ContainerControlInfo();
      if (produitData['controlInfo'] != null) {
        if (kDebugMode) {
          print('🥄 ControlInfo trouvé: ${produitData['controlInfo']}');
        }
        try {
          final controlInfoData =
              produitData['controlInfo'] as Map<String, dynamic>;
          controlInfo = ContainerControlInfo.fromMap(controlInfoData);
          if (kDebugMode) {
            print(
                '🥄 ControlInfo parsé: isControlled=${controlInfo.isControlled}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Erreur lors de la lecture du controlInfo SCOOP: $e');
          }
        }
      } else {
        if (kDebugMode) {
          print('🥄 Aucun controlInfo');
        }
      }

      contenants.add(ScoopContenant(
        id: contenantId, // ✅ CORRIGÉ: Utiliser l'ID réel
        typeContenant: produitData['typeContenant']?.toString() ??
            produitData['type_contenant']?.toString() ??
            'Non spécifié',
        typeMiel: produitData['typeMiel']?.toString() ??
            produitData['type_miel']?.toString() ??
            'Non spécifié',
        quantite:
            (produitData['poids'] ?? produitData['quantite'] ?? 0).toDouble(),
        prixUnitaire: (produitData['prix'] ?? produitData['prix_unitaire'] ?? 0)
            .toDouble(),
        montantTotal: (produitData['montant_total'] ??
                (produitData['poids'] ?? 0).toDouble() *
                    (produitData['prix'] ?? 0).toDouble())
            .toDouble(),
        predominanceFlorale: produitData['predominance_florale']?.toString(),
        controlInfo: controlInfo, // ✅ AJOUTÉ: Inclure les infos de contrôle
      ));
    }

    // Récupération des informations géographiques depuis listes_scoop
    String? region, province, commune, village;
    final scoopId = data['scoop_id']?.toString();

    if (kDebugMode) {
      print('🥄 === RÉCUPÉRATION INFOS GÉOGRAPHIQUES SCOOP ===');
      print('🥄 SCOOP ID extrait: $scoopId');
      print('🥄 Chemin de recherche: Sites/$site/listes_scoop/$scoopId');
    }

    if (scoopId != null && scoopId.isNotEmpty) {
      try {
        if (kDebugMode) {
          print('🥄 🔍 Recherche du SCOOP dans la base...');
        }

        final scoopDoc = await _firestore
            .collection('Sites')
            .doc(site)
            .collection('listes_scoop')
            .doc(scoopId)
            .get();

        if (kDebugMode) {
          print('🥄 📄 Document SCOOP trouvé: ${scoopDoc.exists}');
        }

        if (scoopDoc.exists) {
          final scoopData = scoopDoc.data()!;
          region = scoopData['region']?.toString();
          province = scoopData['province']?.toString();
          commune = scoopData['commune']?.toString();
          village = scoopData['village']?.toString();

          if (kDebugMode) {
            print('🥄 ✅ DONNÉES SCOOP TROUVÉES:');
            print('🥄    - Nom SCOOP: ${scoopData['nom']}');
            print('🥄    - Président: ${scoopData['president']}');
            print('🥄    - Région: $region');
            print('🥄    - Province: $province');
            print('🥄    - Commune: $commune');
            print('🥄    - Village: $village');
            print('🥄    - Données complètes: $scoopData');
          }
        } else {
          if (kDebugMode) {
            print('🥄 ❌ SCOOP NON TROUVÉ dans listes_scoop!');
            print(
                '🥄 Vérifiez que le SCOOP existe dans Sites/$site/listes_scoop/$scoopId');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('🥄 ❌ ERREUR récupération info géographiques SCOOP: $e');
          print('🥄 Stack trace: ${StackTrace.current}');
        }
      }
    } else {
      if (kDebugMode) {
        print(
            '🥄 ⚠️ SCOOP ID vide ou null - impossible de récupérer les infos géographiques');
      }
    }

    // Extraction de la localisation (fallback)
    final localisation = data['localisation']?.toString() ??
        (region != null
            ? '$region › $province › $commune'
            : '$site, Centre-Ouest, Boulkiemdé');

    final scoop = Scoop(
      id: docId,
      path: 'Sites/$site/nos_achats_scoop_contenants/$docId',
      site: site,
      date: _extractDate(data),
      technicien: data['collecteur_nom']?.toString() ??
          data['technicien_nom']?.toString(),
      statut: data['statut']?.toString() ?? data['status']?.toString(),
      totalWeight: (data['poids_total'] ?? data['totalWeight'] ?? 0).toDouble(),
      totalAmount:
          (data['montant_total'] ?? data['totalAmount'] ?? 0).toDouble(),
      scoopNom: data['scoop_nom']?.toString() ??
          data['scoop_name']?.toString() ??
          'SCOOP $site',
      periodeCollecte: data['periode_collecte']?.toString() ??
          _formatPeriodeFromDate(_extractDate(data)),
      qualite: data['qualite']?.toString(),
      localisation: localisation,
      region: region,
      province: province,
      commune: commune,
      village: village,
      contenants: contenants,
    );

    if (kDebugMode) {
      print('🥄 ===== SCOOP MAPPÉ AVEC SUCCÈS =====');
      print('🥄 ID: ${scoop.id}');
      print('🥄 Nom SCOOP: ${scoop.scoopNom}');
      print('🥄 Date: ${scoop.date}');
      print('🥄 Technicien: ${scoop.technicien}');
      print('🥄 Statut: ${scoop.statut}');
      print('🥄 Poids total: ${scoop.totalWeight} kg');
      print('🥄 Montant total: ${scoop.totalAmount} FCFA');
      print('🥄 Période: ${scoop.periodeCollecte}');
      print('🥄 Qualité: ${scoop.qualite}');
      print('🥄 Localisation: ${scoop.localisation}');
      print('🥄 Région: ${scoop.region}');
      print('🥄 Province: ${scoop.province}');
      print('🥄 Commune: ${scoop.commune}');
      print('🥄 Village: ${scoop.village}');
      print('🥄 Nombre de contenants: ${scoop.contenants.length}');
      for (int i = 0; i < scoop.contenants.length; i++) {
        final c = scoop.contenants[i];
        print(
            '🥄   Contenant ${i + 1} (${c.id}): ${c.typeContenant} ${c.typeMiel} - ${c.quantite}kg à ${c.prixUnitaire} FCFA/kg = ${c.montantTotal} FCFA');
      }
      print('🥄 =====================================');
    }

    return scoop;
  }

  /// Convertit les données Firestore legacy en modèle Scoop
  static Scoop _mapToScoopLegacy(
      String docId, String site, Map<String, dynamic> data) {
    final contenants = <ScoopContenant>[];

    // Conversion des contenants legacy
    final detailsData = data['details'] as List<dynamic>? ??
        data['produits'] as List<dynamic>? ??
        [];
    for (int i = 0; i < detailsData.length; i++) {
      final detailData = detailsData[i] as Map<String, dynamic>;
      contenants.add(ScoopContenant(
        id: '$docId-d${i + 1}',
        typeContenant:
            detailData['containerType']?.toString() ?? 'Non spécifié',
        typeMiel: detailData['typeMiel']?.toString() ?? 'Non spécifié',
        quantite:
            (detailData['quantite'] ?? detailData['weight'] ?? 0).toDouble(),
        prixUnitaire:
            (detailData['prixUnitaire'] ?? detailData['unitPrice'] ?? 0)
                .toDouble(),
        montantTotal:
            (detailData['montantTotal'] ?? detailData['total'] ?? 0).toDouble(),
      ));
    }

    return Scoop(
      id: docId,
      path: '$site/collectes_scoop/collectes_scoop/$docId',
      site: site,
      date: _extractDate(data),
      technicien: data['technicien_nom']?.toString(),
      statut: data['status']?.toString(),
      totalWeight: (data['totalWeight'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      scoopNom: data['scoop_name']?.toString() ?? 'SCOOP $site',
      periodeCollecte: _formatPeriodeFromDate(_extractDate(data)),
      qualite: data['qualite']?.toString(),
      localisation:
          '$site > Province > Commune', // Valeur par défaut pour legacy
      region: null, // Legacy n'a pas d'infos géographiques détaillées
      province: null,
      commune: null,
      village: null,
      contenants: contenants,
    );
  }

  /// Convertit les données Firestore en modèle Individuel (avec infos géographiques)
  static Future<Individuel> _mapToIndividuelAsync(
      String docId, String site, Map<String, dynamic> data) async {
    final contenants = <IndividuelContenant>[];

    if (kDebugMode) {
      print('👤 ===== DÉBUT MAPPING INDIVIDUEL $docId =====');
      print('👤 Site: $site');
      print('👤 Champs disponibles: ${data.keys.toList()}');
      print('👤 Données brutes complètes: $data');
      print('👤 ==========================================');
    }

    // Conversion des contenants - ID maintenant inclus dans le modèle
    final contenantsData = data['contenants'] as List<dynamic>? ?? [];
    for (int i = 0; i < contenantsData.length; i++) {
      final contenant = contenantsData[i] as Map<String, dynamic>;

      if (kDebugMode) {
        print('👤 === CONTENANT ${i + 1} ===');
        print('👤 Données brutes: ${contenant.keys.toList()}');
      }

      // Récupérer les informations de contrôle si elles existent
      ContainerControlInfo controlInfo = const ContainerControlInfo();
      if (contenant['controlInfo'] != null) {
        try {
          final controlInfoData =
              contenant['controlInfo'] as Map<String, dynamic>;
          controlInfo = ContainerControlInfo.fromMap(controlInfoData);
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Erreur lors de la lecture du controlInfo Individuel: $e');
          }
        }
      }

      // L'ID est maintenant directement récupéré du modèle
      final contenantId = contenant['id']?.toString() ??
          'C${(i + 1).toString().padLeft(3, '0')}_individuel';

      if (kDebugMode) {
        print('👤 Contenant individuel ${i + 1}: ID = $contenantId');
      }

      contenants.add(IndividuelContenant(
        id: contenantId, // ✅ ID du contenant (maintenant inclus dans le modèle)
        typeContenant:
            contenant['type_contenant']?.toString() ?? 'Non spécifié',
        typeMiel: contenant['type_miel']?.toString() ??
            contenant['origine_florale']?.toString() ??
            'Non spécifié',
        quantite:
            (contenant['quantite_kg'] ?? contenant['quantite'] ?? 0).toDouble(),
        prixUnitaire: (contenant['prix_unitaire'] ?? 0).toDouble(),
        montantTotal: (contenant['montant_total'] ?? 0).toDouble(),
        controlInfo: controlInfo, // ✅ AJOUTÉ: Inclure les infos de contrôle
      ));
    }

    // Conversion des origines florales
    final originesFlorales = <String>[];
    final floralesData = data['origines_florales'];
    if (floralesData is List) {
      originesFlorales.addAll(floralesData.map((e) => e.toString()));
    }

    // Récupération des informations géographiques depuis listes_prod
    String? region, province, commune, village;
    final producteurId = data['id_producteur']?.toString();

    if (kDebugMode) {
      print('👤 === RÉCUPÉRATION INFOS GÉOGRAPHIQUES PRODUCTEUR ===');
      print('👤 Producteur ID extrait: $producteurId');
      print('👤 Chemin de recherche: Sites/$site/listes_prod/$producteurId');
    }

    if (producteurId != null && producteurId.isNotEmpty) {
      try {
        if (kDebugMode) {
          print('👤 🔍 Recherche du producteur dans la base...');
        }

        final producteurDoc = await _firestore
            .collection('Sites')
            .doc(site)
            .collection('listes_prod')
            .doc(producteurId)
            .get();

        if (kDebugMode) {
          print('👤 📄 Document producteur trouvé: ${producteurDoc.exists}');
        }

        if (producteurDoc.exists) {
          final producteurData = producteurDoc.data()!;
          final localisationData =
              producteurData['localisation'] as Map<String, dynamic>?;

          if (kDebugMode) {
            print('👤 ✅ DONNÉES PRODUCTEUR TROUVÉES:');
            print('👤    - Nom: ${producteurData['nomPrenom']}');
            print('👤    - Téléphone: ${producteurData['telephone']}');
            print('👤    - Sexe: ${producteurData['sexe']}');
            print('👤    - Âge: ${producteurData['age']}');
            print('👤    - Localisation data: $localisationData');
          }

          if (localisationData != null) {
            region = localisationData['region']?.toString();
            province = localisationData['province']?.toString();
            commune = localisationData['commune']?.toString();
            village = localisationData['village']?.toString();

            if (kDebugMode) {
              print('👤 📍 INFOS GÉOGRAPHIQUES EXTRAITES:');
              print('👤    - Région: $region');
              print('👤    - Province: $province');
              print('👤    - Commune: $commune');
              print('👤    - Village: $village');
            }
          } else {
            if (kDebugMode) {
              print(
                  '👤 ⚠️ Aucune donnée de localisation trouvée dans le document producteur');
            }
          }
        } else {
          if (kDebugMode) {
            print('👤 ❌ PRODUCTEUR NON TROUVÉ dans listes_prod!');
            print(
                '👤 Vérifiez que le producteur existe dans Sites/$site/listes_prod/$producteurId');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('👤 ❌ ERREUR récupération info géographiques producteur: $e');
          print('👤 Stack trace: ${StackTrace.current}');
        }
      }
    } else {
      if (kDebugMode) {
        print(
            '👤 ⚠️ Producteur ID vide ou null - impossible de récupérer les infos géographiques');
      }
    }

    // Génération de localisation (fallback)
    String? localisation;
    if (region != null) {
      localisation = '$region › $province › $commune › $village';
    } else {
      // Fallback vers les anciennes données
      final producteurLocalisation =
          data['producteur_localisation'] as Map<String, dynamic>?;
      if (producteurLocalisation != null) {
        final parts = [
          producteurLocalisation['region'],
          producteurLocalisation['province'],
          producteurLocalisation['commune'],
          producteurLocalisation['village'],
        ].where((part) => part != null && part.toString().isNotEmpty);
        localisation = parts.join(' › ');
      }
    }

    final individuel = Individuel(
      id: docId,
      path: 'Sites/$site/nos_achats_individuels/$docId',
      site: site,
      date: _extractDate(data),
      technicien: data['collecteur_nom']?.toString() ??
          data['technicien_nom']?.toString(),
      statut: data['statut']?.toString() ?? data['status']?.toString(),
      totalWeight: (data['poids_total'] ?? data['totalWeight'] ?? 0).toDouble(),
      totalAmount:
          (data['montant_total'] ?? data['totalAmount'] ?? 0).toDouble(),
      nomProducteur: data['nom_producteur']?.toString() ?? 'Producteur inconnu',
      originesFlorales: originesFlorales,
      observations: data['observations']?.toString(),
      localisation: localisation ?? '$site › Province › Commune',
      region: region,
      province: province,
      commune: commune,
      village: village,
      contenants: contenants,
    );

    if (kDebugMode) {
      print('👤 ===== INDIVIDUEL MAPPÉ AVEC SUCCÈS =====');
      print('👤 ID: ${individuel.id}');
      print('👤 Nom producteur: ${individuel.nomProducteur}');
      print('👤 Date: ${individuel.date}');
      print('👤 Technicien: ${individuel.technicien}');
      print('👤 Statut: ${individuel.statut}');
      print('👤 Poids total: ${individuel.totalWeight} kg');
      print('👤 Montant total: ${individuel.totalAmount} FCFA');
      print('👤 Localisation: ${individuel.localisation}');
      print('👤 Région: ${individuel.region}');
      print('👤 Province: ${individuel.province}');
      print('👤 Commune: ${individuel.commune}');
      print('👤 Village: ${individuel.village}');
      print('👤 Origines florales: ${individuel.originesFlorales}');
      print('👤 Observations: ${individuel.observations}');
      print('👤 Nombre de contenants: ${individuel.contenants.length}');
      for (int i = 0; i < individuel.contenants.length; i++) {
        final c = individuel.contenants[i];
        print(
            '👤   Contenant ${i + 1} (${c.id}): ${c.typeContenant} ${c.typeMiel} - ${c.quantite}kg à ${c.prixUnitaire} FCFA/kg = ${c.montantTotal} FCFA');
      }
      print('👤 ==========================================');
    }

    return individuel;
  }

  /// Récupère les collectes de miellerie
  static Future<List<Miellerie>> _getMiellerie(String site) async {
    final mielleries = <Miellerie>[];

    try {
      // Chemin: Sites/{site}/nos_collecte_mielleries
      final snapshot = await _firestore
          .collection('Sites')
          .doc(site)
          .collection('nos_collecte_mielleries')
          .orderBy('created_at', descending: true)
          .get();

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final miellerie = _mapToMiellerie(doc.id, site, data);
          mielleries.add(miellerie);
        } catch (e) {
          print('⚠️ Erreur conversion miellerie ${doc.id}: $e');
        }
      }

      print(
          '✅ ${mielleries.length} mielleries chargées depuis Sites/$site/nos_collecte_mielleries');
    } catch (e) {
      print('❌ Erreur chargement mielleries pour $site: $e');
    }

    return mielleries;
  }

  /// Mappe les données Firestore vers un objet Miellerie
  static Miellerie _mapToMiellerie(String docId, String site, Map<String, dynamic> data) {
    // Extraction des contenants avec IDs
    final contenantsData = data['contenants'] as List<dynamic>? ?? [];
    final contenants = <MiellerieContenant>[];

    for (int i = 0; i < contenantsData.length; i++) {
      final contenantData = contenantsData[i] as Map<String, dynamic>;
      
      // Générer un ID si manquant (pour compatibilité avec anciens enregistrements)
      final containerId = contenantData['id'] ?? 'C${(i + 1).toString().padLeft(3, '0')}_miellerie';
      
      final contenant = MiellerieContenant(
        id: containerId,
        typeContenant: contenantData['type_contenant']?.toString() ?? '',
        typeMiel: contenantData['type_collecte']?.toString() ?? '',
        quantite: (contenantData['quantite'] ?? 0).toDouble(),
        prixUnitaire: (contenantData['prix_unitaire'] ?? 0).toDouble(),
        montantTotal: (contenantData['montant_total'] ?? 0).toDouble(),
        observations: contenantData['notes']?.toString(),
      );
      contenants.add(contenant);
    }

    // Calculs des totaux
    double totalWeight = contenants.fold(0.0, (sum, c) => sum + c.quantite);
    double totalAmount = contenants.fold(0.0, (sum, c) => sum + c.montantTotal);

    final miellerie = Miellerie(
      id: docId,
      path: 'Sites/$site/nos_collecte_mielleries/$docId',
      site: site,
      date: _extractDate(data),
      technicien: data['collecteur_nom']?.toString(),
      statut: data['statut']?.toString() ?? 'collecte_terminee',
      totalWeight: totalWeight,
      totalAmount: totalAmount,
      containersCount: contenants.length,
      collecteurNom: data['collecteur_nom']?.toString() ?? '',
      miellerieNom: data['miellerie_nom']?.toString() ?? '',
      localite: data['localite']?.toString() ?? '',
      cooperativeNom: data['cooperative_nom']?.toString() ?? '',
      repondant: data['repondant']?.toString() ?? '',
      contenants: contenants,
      observations: data['observations']?.toString(),
    );

    if (kDebugMode) {
      print('🍯 ===== MIELLERIE MAPPÉE AVEC SUCCÈS =====');
      print('🍯 ID: ${miellerie.id}');
      print('🍯 Collecteur: ${miellerie.collecteurNom}');
      print('🍯 Miellerie: ${miellerie.miellerieNom}');
      print('🍯 Localité: ${miellerie.localite}');
      print('🍯 Coopérative: ${miellerie.cooperativeNom}');
      print('🍯 Date: ${miellerie.date}');
      print('🍯 Statut: ${miellerie.statut}');
      print('🍯 Poids total: ${miellerie.totalWeight} kg');
      print('🍯 Montant total: ${miellerie.totalAmount} FCFA');
      print('🍯 Nombre de contenants: ${miellerie.contenants.length}');
      for (int i = 0; i < miellerie.contenants.length; i++) {
        final c = miellerie.contenants[i];
        print(
            '🍯   Contenant ${i + 1} (${c.id}): ${c.typeContenant} ${c.typeMiel} - ${c.quantite}kg à ${c.prixUnitaire} FCFA/kg = ${c.montantTotal} FCFA');
      }
      print('🍯 ==========================================');
    }

    return miellerie;
  }

  /// Extrait la date depuis les données Firestore
  static DateTime _extractDate(Map<String, dynamic> data) {
    // Essayer différents champs de date
    final dateFields = [
      'date_achat',
      'created_at',
      'createdAt',
      'date_collecte'
    ];

    for (final field in dateFields) {
      final dateValue = data[field];
      if (dateValue != null) {
        if (dateValue is Timestamp) {
          return dateValue.toDate();
        } else if (dateValue is String) {
          try {
            return DateTime.parse(dateValue);
          } catch (e) {
            continue;
          }
        }
      }
    }

    return DateTime.now();
  }

  /// Formate une période à partir d'une date
  static String _formatPeriodeFromDate(DateTime date) {
    final monthNames = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];

    return '${monthNames[date.month - 1]} ${date.year}';
  }

  /// Récupère les options de filtrage basées sur les données réelles
  static Future<Map<String, List<String>>> getFilterOptions(
      Map<Section, List<BaseCollecte>> data) async {
    final sites = <String>{};
    final techniciens = <String>{};
    final statuses = <String>{};

    for (final sectionData in data.values) {
      for (final collecte in sectionData) {
        sites.add(collecte.site);
        if (collecte.technicien != null && collecte.technicien!.isNotEmpty) {
          techniciens.add(collecte.technicien!);
        }
        if (collecte.statut != null && collecte.statut!.isNotEmpty) {
          statuses.add(collecte.statut!);
        }
      }
    }

    return {
      'sites': sites.toList()..sort(),
      'techniciens': techniciens.toList()..sort(),
      'statuses': statuses.toList()..sort(),
    };
  }
}
