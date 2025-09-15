/// 🛒 SERVICE PRINCIPAL DE GESTION DES VENTES
///
/// Gestion complète des produits conditionnés, prélèvements, ventes, restitutions et pertes

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../authentication/user_session.dart';
import '../models/vente_models.dart';

class VenteService {
  static final VenteService _instance = VenteService._internal();
  factory VenteService() => _instance;
  VenteService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserSession _userSession = Get.find<UserSession>();

  /// Sites disponibles
  final List<String> sites = [
    'Koudougou',
    'Ouagadougou',
    'Bobo-Dioulasso',
    'Mangodara',
    'Bagre',
    'Pô'
  ];

  // ====== GESTION DES PRODUITS CONDITIONNÉS ======

  /// Récupère tous les produits conditionnés disponibles pour la vente
  Future<List<ProduitConditionne>> getProduitsConditionnes(
      {String? siteFilter}) async {
    try {
      debugPrint('🛒 ===== RÉCUPÉRATION PRODUITS CONDITIONNÉS =====');
      debugPrint('   🎯 Site filter: ${siteFilter ?? "Tous"}');

      final List<ProduitConditionne> produits = [];
      final sitesToCheck = siteFilter != null ? [siteFilter] : sites;

      for (final site in sitesToCheck) {
        debugPrint('   📍 Analyse du site: $site');

        // Récupérer tous les conditionnements du site
        final conditionnementSnapshot = await _firestore
            .collection('Conditionnement')
            .doc(site)
            .collection('processus')
            .get();

        debugPrint(
            '      ✅ ${conditionnementSnapshot.docs.length} conditionnements trouvés');

        for (final doc in conditionnementSnapshot.docs) {
          final data = doc.data();

          // Récupérer les détails des emballages
          final emballagesSnapshot =
              await doc.reference.collection('emballages_produits').get();

          for (final emballageDoc in emballagesSnapshot.docs) {
            final emballageData = emballageDoc.data();

            // Créer un produit conditionné pour chaque type d'emballage
            final produit = _creerProduitConditionne(
              doc.id,
              data,
              emballageDoc.id,
              emballageData,
              site,
            );

            if (produit != null && produit.quantiteDisponible > 0) {
              produits.add(produit);
            }
          }
        }
      }

      debugPrint('✅ Total produits conditionnés: ${produits.length}');
      debugPrint(
          '   📊 Valeur totale: ${produits.fold(0.0, (sum, p) => sum + p.valeurTotale)} FCFA');
      debugPrint('=============================================');

      return produits;
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur récupération produits conditionnés: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return [];
    }
  }

  /// Crée un ProduitConditionne à partir des données Firestore
  ProduitConditionne? _creerProduitConditionne(
    String conditionnementId,
    Map<String, dynamic> conditionnementData,
    String emballageId,
    Map<String, dynamic> emballageData,
    String site,
  ) {
    try {
      // Générer un ID unique pour le produit
      final produitId = '${conditionnementId}_${emballageId}';

      return ProduitConditionne(
        id: produitId,
        numeroLot: conditionnementData['numeroLot'] ?? conditionnementId,
        codeContenant: conditionnementData['codeContenant'] ?? '',
        producteur: conditionnementData['producteur'] ?? 'Inconnu',
        village: conditionnementData['village'] ?? 'Inconnu',
        siteOrigine: site,
        predominanceFlorale:
            conditionnementData['predominanceFlorale'] ?? 'Mille fleurs',
        typeEmballage: emballageData['type'] ?? 'Pot',
        contenanceKg: (emballageData['contenanceKg'] ?? 0.0).toDouble(),
        quantiteDisponible:
            emballageData['quantiteDisponible'] ?? emballageData['nombre'] ?? 0,
        quantiteInitiale: emballageData['nombre'] ?? 0,
        prixUnitaire: (emballageData['prixUnitaire'] ?? 0.0).toDouble(),
        dateConditionnement:
            (conditionnementData['dateConditionnement'] as Timestamp?)
                    ?.toDate() ??
                DateTime.now(),
        dateExpiration: _calculerDateExpiration(
          (conditionnementData['dateConditionnement'] as Timestamp?)
                  ?.toDate() ??
              DateTime.now(),
        ),
        statut: StatutProduit.disponible,
        observations: conditionnementData['observations'],
      );
    } catch (e) {
      debugPrint('❌ Erreur création produit conditionné: $e');
      return null;
    }
  }

  /// Calcule la date d'expiration (2 ans après conditionnement)
  DateTime _calculerDateExpiration(DateTime dateConditionnement) {
    return dateConditionnement.add(const Duration(days: 730)); // 2 ans
  }

  // ====== GESTION DES PRÉLÈVEMENTS ======

  /// Crée un nouveau prélèvement
  Future<bool> creerPrelevement({
    required String commercialId,
    required String commercialNom,
    required List<Map<String, dynamic>> produitsSelectionnes,
    String? observations,
  }) async {
    try {
      final site = _userSession.site ?? 'Site_Inconnu';
      final magazinierId = _userSession.email ?? 'Magazinier_Inconnu';
      final magazinierNom = _userSession.email ?? 'Magazinier';

      final prelevementId = 'PREL_${DateTime.now().millisecondsSinceEpoch}';

      debugPrint('🔄 [VenteService] Création prélèvement: $prelevementId');

      // Calculer la valeur totale
      double valeurTotale = 0.0;
      final List<ProduitPreleve> produitsPreleves = [];

      for (final produitData in produitsSelectionnes) {
        final produitPreleve = ProduitPreleve(
          produitId: produitData['produitId'] ?? '',
          numeroLot: produitData['numeroLot'] ?? '',
          typeEmballage: produitData['typeEmballage'] ?? '',
          contenanceKg: (produitData['contenanceKg'] ?? 0.0).toDouble(),
          quantitePreleve: produitData['quantitePreleve'] ?? 0,
          prixUnitaire: (produitData['prixUnitaire'] ?? 0.0).toDouble(),
          valeurTotale: (produitData['quantitePreleve'] ?? 0) *
              (produitData['prixUnitaire'] ?? 0.0),
        );

        produitsPreleves.add(produitPreleve);
        valeurTotale += produitPreleve.valeurTotale;
      }

      // Créer le prélèvement
      final prelevement = Prelevement(
        id: prelevementId,
        commercialId: commercialId,
        commercialNom: commercialNom,
        magazinierId: magazinierId,
        magazinierNom: magazinierNom,
        datePrelevement: DateTime.now(),
        produits: produitsPreleves,
        valeurTotale: valeurTotale,
        statut: StatutPrelevement.enCours,
        observations: observations,
      );

      // Enregistrer en Firestore
      await _firestore
          .collection('Vente')
          .doc(site)
          .collection('prelevements')
          .doc(prelevementId)
          .set(prelevement.toMap());

      // Mettre à jour les quantités disponibles des produits
      await _mettreAJourQuantitesApresPrelevement(produitsPreleves, site);

      debugPrint('✅ [VenteService] Prélèvement créé: $prelevementId');
      debugPrint(
          '   💰 Valeur totale: ${valeurTotale.toStringAsFixed(0)} FCFA');
      debugPrint('   📦 Produits prélevés: ${produitsPreleves.length}');

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ [VenteService] Erreur création prélèvement: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return false;
    }
  }

  /// Met à jour les quantités après prélèvement
  Future<void> _mettreAJourQuantitesApresPrelevement(
    List<ProduitPreleve> produits,
    String site,
  ) async {
    try {
      final batch = _firestore.batch();

      for (final produit in produits) {
        // Décomposer l'ID pour retrouver le conditionnement et l'emballage
        final parts = produit.produitId.split('_');
        if (parts.length >= 2) {
          final conditionnementId = parts[0];
          final emballageId = parts.sublist(1).join('_');

          final emballageRef = _firestore
              .collection('Conditionnement')
              .doc(site)
              .collection('processus')
              .doc(conditionnementId)
              .collection('emballages_produits')
              .doc(emballageId);

          batch.update(emballageRef, {
            'quantiteDisponible':
                FieldValue.increment(-produit.quantitePreleve),
            'dernierPrelevement': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
      debugPrint('✅ Quantités mises à jour après prélèvement');
    } catch (e) {
      debugPrint('❌ Erreur mise à jour quantités: $e');
    }
  }

  /// Récupère les prélèvements d'un commercial
  Future<List<Prelevement>> getPrelevementsCommercial(
      String commercialId) async {
    try {
      final site = _userSession.site ?? 'Site_Inconnu';

      final prelevementsSnapshot = await _firestore
          .collection('Vente')
          .doc(site)
          .collection('prelevements')
          .where('commercialId', isEqualTo: commercialId)
          .orderBy('datePrelevement', descending: true)
          .get();

      final prelevements = prelevementsSnapshot.docs
          .map((doc) => Prelevement.fromMap(doc.data()))
          .toList();

      debugPrint(
          '✅ ${prelevements.length} prélèvements trouvés pour $commercialId');
      return prelevements;
    } catch (e) {
      debugPrint('❌ Erreur récupération prélèvements: $e');
      return [];
    }
  }

  // ====== GESTION DES VENTES ======

  /// Enregistre une nouvelle vente
  Future<bool> enregistrerVente(Vente vente) async {
    try {
      final site = _userSession.site ?? 'Site_Inconnu';

      await _firestore
          .collection('Vente')
          .doc(site)
          .collection('ventes')
          .doc(vente.id)
          .set(vente.toMap());

      debugPrint('✅ [VenteService] Vente enregistrée: ${vente.id}');
      debugPrint(
          '   💰 Montant: ${vente.montantTotal.toStringAsFixed(0)} FCFA');
      debugPrint('   👤 Client: ${vente.clientNom}');

      return true;
    } catch (e) {
      debugPrint('❌ [VenteService] Erreur enregistrement vente: $e');
      return false;
    }
  }

  // ====== GESTION DES CLIENTS ======

  /// Récupère tous les clients
  Future<List<Client>> getClients() async {
    try {
      final site = _userSession.site ?? 'Site_Inconnu';

      final clientsSnapshot = await _firestore
          .collection('Vente')
          .doc(site)
          .collection('clients')
          .where('estActif', isEqualTo: true)
          .orderBy('nom')
          .get();

      final clients = clientsSnapshot.docs
          .map((doc) => Client.fromMap(doc.data()))
          .toList();

      debugPrint('✅ ${clients.length} clients trouvés');
      return clients;
    } catch (e) {
      debugPrint('❌ Erreur récupération clients: $e');
      return [];
    }
  }

  /// Crée un nouveau client
  Future<bool> creerClient(Client client) async {
    try {
      final site = _userSession.site ?? 'Site_Inconnu';

      await _firestore
          .collection('Vente')
          .doc(site)
          .collection('clients')
          .doc(client.id)
          .set(client.toMap());

      debugPrint('✅ [VenteService] Client créé: ${client.nom}');
      return true;
    } catch (e) {
      debugPrint('❌ [VenteService] Erreur création client: $e');
      return false;
    }
  }

  // ====== GESTION DES RESTITUTIONS ======

  /// Enregistre une restitution
  Future<bool> enregistrerRestitution(Restitution restitution) async {
    try {
      final site = _userSession.site ?? 'Site_Inconnu';

      await _firestore
          .collection('Vente')
          .doc(site)
          .collection('restitutions')
          .doc(restitution.id)
          .set(restitution.toMap());

      // Remettre les produits en stock
      await _remettreProduitsEnStock(restitution.produits, site);

      debugPrint('✅ [VenteService] Restitution enregistrée: ${restitution.id}');
      return true;
    } catch (e) {
      debugPrint('❌ [VenteService] Erreur enregistrement restitution: $e');
      return false;
    }
  }

  /// Remet les produits restitués en stock
  Future<void> _remettreProduitsEnStock(
    List<ProduitRestitue> produits,
    String site,
  ) async {
    try {
      final batch = _firestore.batch();

      for (final produit in produits) {
        // Décomposer l'ID pour retrouver le conditionnement et l'emballage
        final parts = produit.produitId.split('_');
        if (parts.length >= 2) {
          final conditionnementId = parts[0];
          final emballageId = parts.sublist(1).join('_');

          final emballageRef = _firestore
              .collection('Conditionnement')
              .doc(site)
              .collection('processus')
              .doc(conditionnementId)
              .collection('emballages_produits')
              .doc(emballageId);

          batch.update(emballageRef, {
            'quantiteDisponible':
                FieldValue.increment(produit.quantiteRestituee),
            'derniereRestitution': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
      debugPrint('✅ Produits remis en stock après restitution');
    } catch (e) {
      debugPrint('❌ Erreur remise en stock: $e');
    }
  }

  // ====== GESTION DES PERTES ======

  /// Enregistre une perte
  Future<bool> enregistrerPerte(Perte perte) async {
    try {
      final site = _userSession.site ?? 'Site_Inconnu';

      await _firestore
          .collection('Vente')
          .doc(site)
          .collection('pertes')
          .doc(perte.id)
          .set(perte.toMap());

      debugPrint('✅ [VenteService] Perte enregistrée: ${perte.id}');
      debugPrint(
          '   💔 Valeur perdue: ${perte.valeurTotale.toStringAsFixed(0)} FCFA');

      return true;
    } catch (e) {
      debugPrint('❌ [VenteService] Erreur enregistrement perte: $e');
      return false;
    }
  }

  // ====== STATISTIQUES ======

  /// Récupère les statistiques globales de vente
  Future<Map<String, dynamic>> getStatistiquesVente(
      {String? siteFilter}) async {
    try {
      debugPrint('📊 Calcul statistiques vente...');

      final sitesToCheck = siteFilter != null ? [siteFilter] : sites;
      final Map<String, dynamic> stats = {
        'totalProduits': 0,
        'valeurStock': 0.0,
        'totalPrelevements': 0,
        'valeurPrelevements': 0.0,
        'totalVentes': 0,
        'chiffredAffaire': 0.0,
        'totalRestitutions': 0,
        'valeurRestitutions': 0.0,
        'totalPertes': 0,
        'valeurPertes': 0.0,
        'repartitionParSite': <String, Map<String, dynamic>>{},
      };

      for (final site in sitesToCheck) {
        // Statistiques par site
        final statsSite = await _getStatistiquesSite(site);
        stats['repartitionParSite'][site] = statsSite;

        // Agrégation globale
        stats['totalProduits'] += statsSite['totalProduits'] ?? 0;
        stats['valeurStock'] += statsSite['valeurStock'] ?? 0.0;
        stats['totalPrelevements'] += statsSite['totalPrelevements'] ?? 0;
        stats['valeurPrelevements'] += statsSite['valeurPrelevements'] ?? 0.0;
        stats['totalVentes'] += statsSite['totalVentes'] ?? 0;
        stats['chiffredAffaire'] += statsSite['chiffredAffaire'] ?? 0.0;
        stats['totalRestitutions'] += statsSite['totalRestitutions'] ?? 0;
        stats['valeurRestitutions'] += statsSite['valeurRestitutions'] ?? 0.0;
        stats['totalPertes'] += statsSite['totalPertes'] ?? 0;
        stats['valeurPertes'] += statsSite['valeurPertes'] ?? 0.0;
      }

      debugPrint('✅ Statistiques calculées');
      debugPrint('   📦 Total produits: ${stats['totalProduits']}');
      debugPrint('   💰 Valeur stock: ${stats['valeurStock']} FCFA');
      debugPrint('   🛒 Chiffre d\'affaire: ${stats['chiffredAffaire']} FCFA');

      return stats;
    } catch (e) {
      debugPrint('❌ Erreur calcul statistiques: $e');
      return {};
    }
  }

  /// Récupère les statistiques d'un site spécifique
  Future<Map<String, dynamic>> _getStatistiquesSite(String site) async {
    try {
      // Compter les produits conditionnés disponibles
      final produits = await getProduitsConditionnes(siteFilter: site);
      final totalProduits = produits.length;
      final valeurStock = produits.fold(0.0, (sum, p) => sum + p.valeurTotale);

      // Compter les prélèvements
      final prelevementsSnapshot = await _firestore
          .collection('Vente')
          .doc(site)
          .collection('prelevements')
          .get();

      final totalPrelevements = prelevementsSnapshot.docs.length;
      final valeurPrelevements =
          prelevementsSnapshot.docs.fold(0.0, (sum, doc) {
        return sum + ((doc.data()['valeurTotale'] ?? 0.0) as double);
      });

      // Compter les ventes
      final ventesSnapshot = await _firestore
          .collection('Vente')
          .doc(site)
          .collection('ventes')
          .get();

      final totalVentes = ventesSnapshot.docs.length;
      final chiffredAffaire = ventesSnapshot.docs.fold(0.0, (sum, doc) {
        return sum + ((doc.data()['montantTotal'] ?? 0.0) as double);
      });

      // Compter les restitutions
      final restitutionsSnapshot = await _firestore
          .collection('Vente')
          .doc(site)
          .collection('restitutions')
          .get();

      final totalRestitutions = restitutionsSnapshot.docs.length;
      final valeurRestitutions =
          restitutionsSnapshot.docs.fold(0.0, (sum, doc) {
        return sum + ((doc.data()['valeurTotale'] ?? 0.0) as double);
      });

      // Compter les pertes
      final pertesSnapshot = await _firestore
          .collection('Vente')
          .doc(site)
          .collection('pertes')
          .get();

      final totalPertes = pertesSnapshot.docs.length;
      final valeurPertes = pertesSnapshot.docs.fold(0.0, (sum, doc) {
        return sum + ((doc.data()['valeurTotale'] ?? 0.0) as double);
      });

      return {
        'totalProduits': totalProduits,
        'valeurStock': valeurStock,
        'totalPrelevements': totalPrelevements,
        'valeurPrelevements': valeurPrelevements,
        'totalVentes': totalVentes,
        'chiffredAffaire': chiffredAffaire,
        'totalRestitutions': totalRestitutions,
        'valeurRestitutions': valeurRestitutions,
        'totalPertes': totalPertes,
        'valeurPertes': valeurPertes,
      };
    } catch (e) {
      debugPrint('❌ Erreur statistiques site $site: $e');
      return {};
    }
  }
}
