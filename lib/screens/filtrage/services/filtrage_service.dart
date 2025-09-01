import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../authentication/user_session.dart';
import '../models/filtrage_models.dart';

/// Service pour gérer le processus de filtrage/maturation
class FiltrageService {
  static final FiltrageService _instance = FiltrageService._internal();
  factory FiltrageService() => _instance;
  FiltrageService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserSession _userSession = Get.find<UserSession>();

  /// Collection des processus de filtrage
  String get _filtrageCollection =>
      'Sites/${_userSession.site}/processus_filtrage';

  /// Collection des résultats de filtrage
  String get _resultatsCollection =>
      'Sites/${_userSession.site}/resultats_filtrage';

  /// Démarre un processus de filtrage pour un produit
  Future<void> demarrerFiltrage({
    required FiltrageProduct product,
    required String agentFiltrage,
    String? observations,
  }) async {
    try {
      if (kDebugMode) {
        print(
            '🔄 FILTRAGE: Démarrage du filtrage pour ${product.codeContenant}');
      }

      final processData = {
        'productId': product.id,
        'codeContenant': product.codeContenant,
        'agentFiltrage': agentFiltrage,
        'dateDebut': DateTime.now().toIso8601String(),
        'statutFiltrage': StatutFiltrage.en_cours.name,
        'poidsInitial': product.poids,
        'typeCollecte': product.typeCollecte,
        'producteur': product.producteur,
        'observations': observations,
        'site': _userSession.site,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Sauvegarder le processus
      await _firestore
          .collection(_filtrageCollection)
          .doc(product.id)
          .set(processData);

      if (kDebugMode) {
        print('✅ FILTRAGE: Processus démarré pour ${product.codeContenant}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FILTRAGE: Erreur lors du démarrage: $e');
      }
      throw Exception('Erreur lors du démarrage du filtrage: $e');
    }
  }

  /// Termine un processus de filtrage
  Future<FiltrageResult> terminerFiltrage({
    required String productId,
    required double poidsFinal,
    String? observations,
    String? probleme,
  }) async {
    try {
      if (kDebugMode) {
        print('🏁 FILTRAGE: Fin du filtrage pour $productId');
      }

      // Récupérer le processus en cours
      final processDoc =
          await _firestore.collection(_filtrageCollection).doc(productId).get();

      if (!processDoc.exists) {
        throw Exception('Processus de filtrage non trouvé');
      }

      final processData = processDoc.data()!;
      final dateDebut = DateTime.parse(processData['dateDebut']);
      final poidsInitial = (processData['poidsInitial'] ?? 0).toDouble();
      final agentFiltrage = processData['agentFiltrage'] ?? '';

      // Créer le résultat
      final result = FiltrageResult(
        productId: productId,
        dateDebut: dateDebut,
        dateFin: DateTime.now(),
        agentFiltrage: agentFiltrage,
        poidsInitial: poidsInitial,
        poidsFinal: poidsFinal,
        observations: observations,
        succes: probleme == null || probleme.isEmpty,
        probleme: probleme,
      );

      // Sauvegarder le résultat
      await _firestore
          .collection(_resultatsCollection)
          .doc(productId)
          .set(result.toMap());

      // Mettre à jour le processus
      await _firestore.collection(_filtrageCollection).doc(productId).update({
        'statutFiltrage': probleme == null
            ? StatutFiltrage.termine.name
            : StatutFiltrage.probleme.name,
        'dateFin': DateTime.now().toIso8601String(),
        'poidsFinal': poidsFinal,
        'observationsFin': observations,
        'probleme': probleme,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ FILTRAGE: Processus terminé pour $productId');
        print('   - Poids initial: ${poidsInitial}kg');
        print('   - Poids final: ${poidsFinal}kg');
        print('   - Taux de perte: ${result.tauxPerte.toStringAsFixed(1)}%');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FILTRAGE: Erreur lors de la finalisation: $e');
      }
      throw Exception('Erreur lors de la finalisation du filtrage: $e');
    }
  }

  /// Récupère le statut d'un produit en filtrage
  Future<Map<String, dynamic>?> getStatutFiltrage(String productId) async {
    try {
      final doc =
          await _firestore.collection(_filtrageCollection).doc(productId).get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FILTRAGE: Erreur lors de la récupération du statut: $e');
      }
      return null;
    }
  }

  /// Récupère tous les processus de filtrage en cours
  Future<List<Map<String, dynamic>>> getProcessusEnCours() async {
    try {
      final querySnapshot = await _firestore
          .collection(_filtrageCollection)
          .where('statutFiltrage', isEqualTo: StatutFiltrage.en_cours.name)
          .orderBy('dateDebut', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ FILTRAGE: Erreur lors de la récupération des processus: $e');
      }
      return [];
    }
  }

  /// Récupère l'historique des filtrages
  Future<List<FiltrageResult>> getHistoriqueFiltrage({
    DateTime? debut,
    DateTime? fin,
    String? agentFiltrage,
  }) async {
    try {
      Query query = _firestore.collection(_resultatsCollection);

      if (agentFiltrage != null && agentFiltrage.isNotEmpty) {
        query = query.where('agentFiltrage', isEqualTo: agentFiltrage);
      }

      if (debut != null) {
        query = query.where('dateDebut',
            isGreaterThanOrEqualTo: debut.toIso8601String());
      }

      if (fin != null) {
        query =
            query.where('dateFin', isLessThanOrEqualTo: fin.toIso8601String());
      }

      final querySnapshot =
          await query.orderBy('dateFin', descending: true).get();

      return querySnapshot.docs
          .map((doc) =>
              FiltrageResult.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print(
            '❌ FILTRAGE: Erreur lors de la récupération de l\'historique: $e');
      }
      return [];
    }
  }

  /// Calcule les statistiques de filtrage
  Future<Map<String, dynamic>> getStatistiquesFiltrage({
    DateTime? debut,
    DateTime? fin,
  }) async {
    try {
      final results = await getHistoriqueFiltrage(debut: debut, fin: fin);

      if (results.isEmpty) {
        return {
          'totalProcessus': 0,
          'processusReussis': 0,
          'processusEchoues': 0,
          'tauxReussite': 0.0,
          'poidsInitialTotal': 0.0,
          'poidsFinalTotal': 0.0,
          'perteMoyenne': 0.0,
          'agents': <String>[],
        };
      }

      final totalProcessus = results.length;
      final processusReussis = results.where((r) => r.succes).length;
      final processusEchoues = totalProcessus - processusReussis;
      final tauxReussite = (processusReussis / totalProcessus) * 100;

      final poidsInitialTotal =
          results.map((r) => r.poidsInitial).reduce((a, b) => a + b);

      final poidsFinalTotal = results
          .where((r) => r.succes)
          .map((r) => r.poidsFinal)
          .fold(0.0, (a, b) => a + b);

      final perteMoyenne = results
              .where((r) => r.succes)
              .map((r) => r.tauxPerte)
              .fold(0.0, (a, b) => a + b) /
          processusReussis;

      final agents = results.map((r) => r.agentFiltrage).toSet().toList();

      return {
        'totalProcessus': totalProcessus,
        'processusReussis': processusReussis,
        'processusEchoues': processusEchoues,
        'tauxReussite': tauxReussite,
        'poidsInitialTotal': poidsInitialTotal,
        'poidsFinalTotal': poidsFinalTotal,
        'perteMoyenne': perteMoyenne,
        'agents': agents,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ FILTRAGE: Erreur lors du calcul des statistiques: $e');
      }
      return {};
    }
  }

  /// Attribue un produit à un agent de filtrage
  Future<void> attribuerProduit({
    required String productId,
    required String agentFiltrage,
    String? observations,
  }) async {
    try {
      if (kDebugMode) {
        print(
            '👤 FILTRAGE: Attribution du produit $productId à $agentFiltrage');
      }

      final attributionData = {
        'productId': productId,
        'agentFiltrage': agentFiltrage,
        'dateAttribution': DateTime.now().toIso8601String(),
        'observations': observations,
        'statut': 'attribue',
        'site': _userSession.site,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('Sites/${_userSession.site}/attributions_filtrage')
          .doc(productId)
          .set(attributionData);

      if (kDebugMode) {
        print('✅ FILTRAGE: Produit $productId attribué à $agentFiltrage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FILTRAGE: Erreur lors de l\'attribution: $e');
      }
      throw Exception('Erreur lors de l\'attribution: $e');
    }
  }

  /// Récupère la liste des agents de filtrage disponibles
  Future<List<String>> getAgentsFiltrage() async {
    try {
      // Pour l'instant, retourner une liste statique
      // TODO: Récupérer depuis la base de données des utilisateurs
      return [
        'Agent Filtrage 1',
        'Agent Filtrage 2',
        'Agent Filtrage 3',
        'Marie OUEDRAOGO',
        'Paul SAWADOGO',
        'Fatou TRAORE',
      ];
    } catch (e) {
      if (kDebugMode) {
        print('❌ FILTRAGE: Erreur lors de la récupération des agents: $e');
      }
      return [];
    }
  }

  /// Annule un processus de filtrage
  Future<void> annulerFiltrage(String productId, String raison) async {
    try {
      if (kDebugMode) {
        print('❌ FILTRAGE: Annulation du filtrage pour $productId');
      }

      await _firestore.collection(_filtrageCollection).doc(productId).update({
        'statutFiltrage': StatutFiltrage.probleme.name,
        'dateFin': DateTime.now().toIso8601String(),
        'probleme': raison,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ FILTRAGE: Processus annulé pour $productId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FILTRAGE: Erreur lors de l\'annulation: $e');
      }
      throw Exception('Erreur lors de l\'annulation: $e');
    }
  }

  /// Stream pour suivre les processus en temps réel
  Stream<List<Map<String, dynamic>>> streamProcessusEnCours() {
    return _firestore
        .collection(_filtrageCollection)
        .where('statutFiltrage', isEqualTo: StatutFiltrage.en_cours.name)
        .orderBy('dateDebut', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  /// Supprime définitivement un processus de filtrage
  Future<void> supprimerProcessus(String productId) async {
    try {
      if (kDebugMode) {
        print('🗑️ FILTRAGE: Suppression du processus $productId');
      }

      // Supprimer le processus
      await _firestore.collection(_filtrageCollection).doc(productId).delete();

      // Supprimer le résultat s'il existe
      await _firestore.collection(_resultatsCollection).doc(productId).delete();

      if (kDebugMode) {
        print('✅ FILTRAGE: Processus $productId supprimé');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FILTRAGE: Erreur lors de la suppression: $e');
      }
      throw Exception('Erreur lors de la suppression: $e');
    }
  }
}
