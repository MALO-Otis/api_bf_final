import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../authentication/user_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/controle_de_donnes/models/attribution_models_v2.dart';

/// Service complet pour la gestion du filtrage avec sauvegarde en base
class FiltrageServiceComplete {
  static final FiltrageServiceComplete _instance =
      FiltrageServiceComplete._internal();
  factory FiltrageServiceComplete() => _instance;
  FiltrageServiceComplete._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserSession _userSession = Get.find<UserSession>();

  /// Enregistre un processus de filtrage complet en base de données
  Future<bool> enregistrerFiltrage({
    required List<ProductControle> produitsSelectionnes,
    required String numeroLot,
    required DateTime dateFiltrage,
    required String technologie,
    required double quantiteTotale,
    required double quantiteFiltree,
    required double residusRestants,
    required double rendementFiltrage,
    String? observations,
  }) async {
    try {
      final site = _userSession.site ?? 'Site_Inconnu';
      final utilisateur = _userSession.email ?? 'Utilisateur_Inconnu';
      final timestamp = Timestamp.fromDate(dateFiltrage);

      debugPrint('🔄 [FiltrageService] Début enregistrement filtrage');
      debugPrint('   📍 Site: $site');
      debugPrint('   👤 Utilisateur: $utilisateur');
      debugPrint('   🏷️ Numéro de lot: $numeroLot');
      debugPrint('   📦 Produits: ${produitsSelectionnes.length}');

      // Collection principale du filtrage par site
      final filtrageCollection =
          _firestore.collection('Filtrage').doc(site).collection('processus');

      // Document principal du filtrage
      final filtrageDoc = filtrageCollection.doc(numeroLot);

      // 1. Créer le document principal de filtrage
      await filtrageDoc.set({
        'numeroLot': numeroLot,
        'site': site,
        'utilisateur': utilisateur,
        'dateFiltrage': timestamp,
        'dateCreation': FieldValue.serverTimestamp(),
        'technologie': technologie,
        'statut': 'termine',

        // Quantités
        'quantiteTotale': quantiteTotale,
        'quantiteFiltree': quantiteFiltree,
        'residusRestants': residusRestants,
        'rendementFiltrage': rendementFiltrage,

        // Compteurs
        'nombreProduits': produitsSelectionnes.length,

        // Métadonnées
        'observations': observations ?? '',
        'version': '1.0',
      });

      debugPrint('✅ [FiltrageService] Document principal créé');

      // 2. Sauvegarder les détails des produits filtrés
      final batch = _firestore.batch();

      for (int i = 0; i < produitsSelectionnes.length; i++) {
        final produit = produitsSelectionnes[i];

        // Calculer la quantité filtrée proportionnelle pour ce produit
        final quantiteProduitFiltree =
            (produit.poidsTotal / quantiteTotale) * quantiteFiltree;
        final rendementProduit =
            (quantiteProduitFiltree / produit.poidsTotal) * 100;

        final produitDoc = filtrageDoc
            .collection('produits_filtres')
            .doc('${produit.codeContenant}_${i + 1}');

        batch.set(produitDoc, {
          'codeContenant': produit.codeContenant,
          'producteur': produit.producteur,
          'poidsInitial': produit.poidsTotal,
          'quantiteFiltree': quantiteProduitFiltree,
          'residusProduit': produit.poidsTotal - quantiteProduitFiltree,
          'rendementProduit': rendementProduit,
          'ordreTraitement': i + 1,
          'dateTraitement': timestamp,

          // Données originales du produit
          'donneesOriginales': {
            'predominanceFlorale': produit.predominanceFlorale,
            'village': produit.village,
            'dateControle': produit.dateControle,
            'statutControle': produit.statutControle,
          },
        });
      }

      await batch.commit();
      debugPrint(
          '✅ [FiltrageService] ${produitsSelectionnes.length} produits filtrés enregistrés');

      // 3. Créer la sous-collection de statistiques
      await _creerStatistiquesFiltrage(
        filtrageDoc: filtrageDoc,
        site: site,
        numeroLot: numeroLot,
        produitsSelectionnes: produitsSelectionnes,
        quantiteTotale: quantiteTotale,
        quantiteFiltree: quantiteFiltree,
        residusRestants: residusRestants,
        rendementFiltrage: rendementFiltrage,
        technologie: technologie,
        dateFiltrage: dateFiltrage,
      );

      // 4. Marquer les produits D'ATTRIBUTION comme filtrés (mise à jour des tableaux produits)
      await _marquerProduitsAttribuesCommeFiltres(
        produitsSelectionnes,
        numeroLot,
        site,
      );

      // 5. Marquer les produits d'extraction comme filtrés
      await _marquerProduitsExtraitsCommeFiltres(
        produitsSelectionnes,
        numeroLot,
        site,
      );

      // 6. Mettre à jour les compteurs globaux du site
      await _mettreAJourCompteursGlobaux(
          site, quantiteFiltree, produitsSelectionnes.length);

      debugPrint(
          '✅ [FiltrageService] Filtrage enregistré avec succès: $numeroLot');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ [FiltrageService] Erreur enregistrement filtrage: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return false;
    }
  }

  /// Crée les statistiques détaillées du filtrage
  Future<void> _creerStatistiquesFiltrage({
    required DocumentReference filtrageDoc,
    required String site,
    required String numeroLot,
    required List<ProductControle> produitsSelectionnes,
    required double quantiteTotale,
    required double quantiteFiltree,
    required double residusRestants,
    required double rendementFiltrage,
    required String technologie,
    required DateTime dateFiltrage,
  }) async {
    try {
      debugPrint('📊 [FiltrageService] Création des statistiques...');

      // Analyse par producteur
      final Map<String, Map<String, dynamic>> statsProducteurs = {};
      for (final produit in produitsSelectionnes) {
        final producteur = produit.producteur;
        if (!statsProducteurs.containsKey(producteur)) {
          statsProducteurs[producteur] = {
            'nombreProduits': 0,
            'poidsTotal': 0.0,
            'quantiteFiltree': 0.0,
          };
        }

        final quantiteProduitFiltree =
            (produit.poidsTotal / quantiteTotale) * quantiteFiltree;
        statsProducteurs[producteur]!['nombreProduits'] += 1;
        statsProducteurs[producteur]!['poidsTotal'] += produit.poidsTotal;
        statsProducteurs[producteur]!['quantiteFiltree'] +=
            quantiteProduitFiltree;
      }

      // Analyse par localité
      final Map<String, int> statsLocalites = {};
      for (final produit in produitsSelectionnes) {
        final village = produit.village;
        statsLocalites[village] = (statsLocalites[village] ?? 0) + 1;
      }

      // Document de statistiques
      await filtrageDoc.collection('statistiques').doc('resume').set({
        'numeroLot': numeroLot,
        'site': site,
        'dateAnalyse': FieldValue.serverTimestamp(),

        // Statistiques générales
        'quantites': {
          'totaleInitiale': quantiteTotale,
          'totaleFiltree': quantiteFiltree,
          'totalResidus': residusRestants,
          'rendementGlobal': rendementFiltrage,
        },

        // Analyse de performance
        'performance': {
          'technologie': technologie,
          'efficacite': rendementFiltrage >= 75
              ? 'Excellente'
              : rendementFiltrage >= 60
                  ? 'Bonne'
                  : rendementFiltrage >= 45
                      ? 'Moyenne'
                      : 'Faible',
          'categorieRendement': _categoriserRendement(rendementFiltrage),
          'tauxResidusPourcent': (residusRestants / quantiteTotale) * 100,
        },

        // Analyse par producteur
        'producteurs': {
          'nombreProducteurs': statsProducteurs.length,
          'detailsProducteurs': statsProducteurs,
          'producteurLePlusProductif':
              _trouverProducteurLePlusProductif(statsProducteurs),
        },

        // Analyse géographique
        'geographie': {
          'nombreLocalites': statsLocalites.length,
          'repartitionLocalites': statsLocalites,
          'localitePrincipale': _trouverLocalitePrincipale(statsLocalites),
        },

        // Métadonnées
        'metadonnees': {
          'dateTraitement': Timestamp.fromDate(dateFiltrage),
          'dureeEstimee':
              '${(produitsSelectionnes.length * 15)} minutes', // 15 min par produit estimé
          'nombreProduitsTraites': produitsSelectionnes.length,
        },
      });

      debugPrint('✅ [FiltrageService] Statistiques créées');
    } catch (e) {
      debugPrint('❌ [FiltrageService] Erreur création statistiques: $e');
    }
  }

  /// Marque les produits d'extraction comme filtrés
  Future<void> _marquerProduitsExtraitsCommeFiltres(
    List<ProductControle> produitsSelectionnes,
    String numeroLot,
    String site,
  ) async {
    try {
      debugPrint(
          '🔄 [FiltrageService] Marquage des produits extraits comme filtrés...');

      final batch = _firestore.batch();
      int produitsMisAJour = 0;

      for (final produit in produitsSelectionnes) {
        // Identifier les produits provenant d'extraction (ID commence par 'extraction_')
        if (produit.id.startsWith('extraction_')) {
          final extractionId = produit.id.replaceFirst('extraction_', '');

          debugPrint('   📦 Marquage extraction: $extractionId');
          debugPrint('   🏷️ Code contenant: ${produit.codeContenant}');

          // Mettre à jour le document d'extraction
          final extractionDoc = _firestore
              .collection('Extraction')
              .doc(site)
              .collection('extractions')
              .doc(extractionId);

          batch.update(extractionDoc, {
            'estFiltre': true,
            'numeroLotFiltrage': numeroLot,
            'dateMarquageFiltrage': FieldValue.serverTimestamp(),
            'codeContenant': produit.codeContenant, // ✅ Ajout du code contenant
          });

          produitsMisAJour++;
        }
      }

      if (produitsMisAJour > 0) {
        await batch.commit();
        debugPrint(
            '✅ [FiltrageService] $produitsMisAJour extractions marquées comme filtrées');
      } else {
        debugPrint(
            'ℹ️ [FiltrageService] Aucune extraction à marquer (produits du contrôle uniquement)');
      }
    } catch (e) {
      debugPrint('❌ [FiltrageService] Erreur marquage extractions: $e');
    }
  }

  /// Met à jour les compteurs globaux du site
  Future<void> _mettreAJourCompteursGlobaux(
      String site, double quantiteFiltree, int nombreProduits) async {
    try {
      debugPrint('📊 [FiltrageService] Mise à jour compteurs globaux...');

      final compteursDoc = _firestore
          .collection('Compteurs')
          .doc('filtrage')
          .collection('sites')
          .doc(site);

      await compteursDoc.set({
        'site': site,
        'derniereMiseAJour': FieldValue.serverTimestamp(),
        'quantiteTotaleFiltree': FieldValue.increment(quantiteFiltree),
        'nombreTotalProduitsFiltres': FieldValue.increment(nombreProduits),
        'nombreTotalFiltrages': FieldValue.increment(1),
      }, SetOptions(merge: true));

      debugPrint('✅ [FiltrageService] Compteurs globaux mis à jour');
    } catch (e) {
      debugPrint('❌ [FiltrageService] Erreur compteurs globaux: $e');
    }
  }

  /// ✅ Marque les produits ATTRIBUÉS (dans attribution_reçu) comme filtrés
  Future<void> _marquerProduitsAttribuesCommeFiltres(
    List<ProductControle> produitsSelectionnes,
    String numeroLot,
    String site,
  ) async {
    try {
      debugPrint(
          '🔄 [FiltrageService] Marquage des produits attribués comme filtrés...');

      if (produitsSelectionnes.isEmpty) return;

      final codesAFiltrer =
          produitsSelectionnes.map((p) => p.codeContenant).toSet();

      final attributionsRef = _firestore
          .collection('attribution_reçu')
          .doc(site)
          .collection('attributions')
          .where('type', isEqualTo: 'filtrage');

      final snapshot = await attributionsRef.get();
      int docsModifies = 0;

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final produits =
            (data['produits'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        bool aChange = false;
        final produitsMaj = <Map<String, dynamic>>[];
        for (final p in produits) {
          final code = (p['codeContenant'] ?? '').toString();
          if (codesAFiltrer.contains(code)) {
            aChange = true;
            produitsMaj.add({
              ...p,
              'estFiltre': true,
              'numeroLotFiltrage': numeroLot,
              'dateFiltrage': FieldValue.serverTimestamp(),
            });
          } else {
            produitsMaj.add(p);
          }
        }

        if (aChange) {
          batch.update(doc.reference, {
            'produits': produitsMaj,
            'derniereMiseAJour': FieldValue.serverTimestamp(),
          });
          docsModifies++;
        }
      }

      if (docsModifies > 0) {
        await batch.commit();
        debugPrint(
            '✅ [FiltrageService] $docsModifies document(s) d\'attribution mis à jour (estFiltre=true)');
      } else {
        debugPrint(
            'ℹ️ [FiltrageService] Aucun document d\'attribution nécessitant une mise à jour');
      }
    } catch (e) {
      debugPrint('❌ [FiltrageService] Erreur marquage produits attribués: $e');
    }
  }

  /// Catégorise le rendement de filtrage
  String _categoriserRendement(double rendement) {
    if (rendement >= 85) return 'Premium';
    if (rendement >= 75) return 'Excellent';
    if (rendement >= 65) return 'Tres_Bon';
    if (rendement >= 55) return 'Bon';
    if (rendement >= 45) return 'Moyen';
    if (rendement >= 35) return 'Faible';
    return 'Tres_Faible';
  }

  /// Trouve le producteur le plus productif
  String? _trouverProducteurLePlusProductif(
      Map<String, Map<String, dynamic>> statsProducteurs) {
    if (statsProducteurs.isEmpty) return null;

    String? meilleur;
    double maxQuantite = 0;

    for (final entry in statsProducteurs.entries) {
      final quantite = entry.value['quantiteFiltree'] as double;
      if (quantite > maxQuantite) {
        maxQuantite = quantite;
        meilleur = entry.key;
      }
    }

    return meilleur;
  }

  /// Trouve la localité principale
  String? _trouverLocalitePrincipale(Map<String, int> statsLocalites) {
    if (statsLocalites.isEmpty) return null;

    String? principale;
    int maxCount = 0;

    for (final entry in statsLocalites.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        principale = entry.key;
      }
    }

    return principale;
  }

  /// Récupère l'historique des filtrages d'un site
  Future<List<Map<String, dynamic>>> obtenirHistoriqueFiltrage(
      String site) async {
    try {
      final query = await _firestore
          .collection('Filtrage')
          .doc(site)
          .collection('processus')
          .orderBy('dateCreation', descending: true)
          .limit(50)
          .get();

      return query.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      debugPrint('❌ [FiltrageService] Erreur récupération historique: $e');
      return [];
    }
  }
}
