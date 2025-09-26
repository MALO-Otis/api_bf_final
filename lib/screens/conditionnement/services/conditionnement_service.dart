/// 🎯 SERVICE COMPLET POUR LE MODULE CONDITIONNEMENT
///
/// Service optimisé pour récupérer les lots filtrés et gérer le conditionnement
/// avec intégration complète aux modules filtrage et extraction

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../authentication/user_session.dart';
import '../conditionnement_models.dart';

/// Service principal pour le conditionnement
class ConditionnementService {
  static final ConditionnementService _instance =
      ConditionnementService._internal();
  factory ConditionnementService() => _instance;
  ConditionnementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache pour optimiser les performances
  final Map<String, LotFiltre> _lotsCache = {};
  final Map<String, ConditionnementData> _conditionnementsCache = {};
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  /// Vérifie si le cache est valide
  bool get _isCacheValid {
    return _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!) < _cacheValidityDuration;
  }

  /// Vide le cache
  void clearCache() {
    _lotsCache.clear();
    _conditionnementsCache.clear();
    _lastCacheUpdate = null;
  }

  /// 📊 RÉCUPÉRATION DES LOTS FILTRÉS DISPONIBLES POUR CONDITIONNEMENT
  ///
  /// Récupère tous les lots avec statutFiltrage = 'Filtrage total'
  /// et timer d'expiration pas dépassé
  Future<List<LotFiltre>> getLotsDisponiblesConditionnement({
    String? siteFilter,
    bool forcerRechargement = false,
  }) async {
    try {
      if (!forcerRechargement && _isCacheValid && _lotsCache.isNotEmpty) {
        debugPrint(
            '✅ [Conditionnement] Utilisation du cache - ${_lotsCache.length} lots');
        return _lotsCache.values.where((lot) {
          if (siteFilter != null && lot.site != siteFilter) return false;
          return lot.peutEtreConditionne;
        }).toList();
      }

      debugPrint('🔄 [Conditionnement] Rechargement des lots filtrés...');

      // Construire la requête de base
      Query query = _firestore
          .collection('filtrage')
          .where('statutFiltrage', isEqualTo: 'Filtrage total');

      // Ajouter le filtre par site si nécessaire
      if (siteFilter != null) {
        query = query.where('site', isEqualTo: siteFilter);
      }

      // Récupérer les données
      final snapshot = await query.get();

      debugPrint(
          '📊 [Conditionnement] ${snapshot.docs.length} lots filtrés trouvés');

      // Conversion en modèles
      final lots = <LotFiltre>[];
      for (final doc in snapshot.docs) {
        try {
          final lot = LotFiltre.fromFirestore(doc);

          // Vérifier si le lot peut être conditionné
          if (lot.peutEtreConditionne) {
            lots.add(lot);
            _lotsCache[lot.id] = lot;
          }

          debugPrint('   ✅ Lot ${lot.lotOrigine}: ${lot.quantiteRecue}kg, '
              'Peut être conditionné: ${lot.peutEtreConditionne}');
        } catch (e) {
          debugPrint('❌ Erreur parsing lot ${doc.id}: $e');
        }
      }

      _lastCacheUpdate = DateTime.now();

      // Trier par date de filtrage (plus récent en premier)
      lots.sort((a, b) => b.dateFiltrage.compareTo(a.dateFiltrage));

      debugPrint(
          '✅ [Conditionnement] ${lots.length} lots disponibles pour conditionnement');
      return lots;
    } catch (e) {
      debugPrint('❌ [Conditionnement] Erreur récupération lots: $e');
      rethrow;
    }
  }

  /// 📊 RÉCUPÉRATION D'UN LOT SPÉCIFIQUE
  Future<LotFiltre?> getLotById(String lotId) async {
    try {
      // Vérifier le cache d'abord
      if (_lotsCache.containsKey(lotId)) {
        return _lotsCache[lotId];
      }

      final doc = await _firestore.collection('filtrage').doc(lotId).get();
      if (!doc.exists) return null;

      final lot = LotFiltre.fromFirestore(doc);
      _lotsCache[lotId] = lot;

      return lot;
    } catch (e) {
      debugPrint('❌ [Conditionnement] Erreur récupération lot $lotId: $e');
      return null;
    }
  }

  /// 📊 RÉCUPÉRATION DES CONDITIONNEMENTS EXISTANTS
  Future<List<ConditionnementData>> getConditionnements({
    String? siteFilter,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    try {
      debugPrint('🔄 [Conditionnement] Récupération des conditionnements...');

      Query query = _firestore.collection('conditionnement');

      // Stratégie différente selon les filtres pour éviter les erreurs d'index
      bool needsComplexQuery =
          siteFilter != null || dateDebut != null || dateFin != null;

      if (needsComplexQuery) {
        // Si on a des filtres, on récupère tout et on filtre côté client temporairement
        // TODO: Supprimer cette logique une fois les index Firebase créés
        debugPrint(
            '⚠️ [Conditionnement] Utilisation du filtrage côté client (index manquants)');
        query = _firestore
            .collection('conditionnement')
            .limit(100); // Limiter pour les performances
      } else {
        // Si pas de filtre, on peut utiliser orderBy directement
        query = query.orderBy('date', descending: true);
      }

      final snapshot = await query.get();

      final conditionnements = <ConditionnementData>[];
      for (final doc in snapshot.docs) {
        try {
          final conditionnement = ConditionnementData.fromFirestore(doc);

          // Filtrage côté client si nécessaire (temporaire)
          if (needsComplexQuery) {
            bool shouldInclude = true;

            if (siteFilter != null &&
                conditionnement.lotOrigine.site != siteFilter) {
              shouldInclude = false;
            }

            if (dateDebut != null &&
                conditionnement.dateConditionnement.isBefore(dateDebut)) {
              shouldInclude = false;
            }

            if (dateFin != null &&
                conditionnement.dateConditionnement.isAfter(dateFin)) {
              shouldInclude = false;
            }

            if (!shouldInclude) continue;
          }

          conditionnements.add(conditionnement);
          _conditionnementsCache[doc.id] = conditionnement;
        } catch (e) {
          debugPrint('❌ Erreur parsing conditionnement ${doc.id}: $e');
        }
      }

      // Trier côté client si on a fait du filtrage côté client
      if (needsComplexQuery) {
        conditionnements.sort(
            (a, b) => b.dateConditionnement.compareTo(a.dateConditionnement));
      }

      debugPrint(
          '✅ [Conditionnement] ${conditionnements.length} conditionnements récupérés');
      return conditionnements;
    } catch (e) {
      debugPrint(
          '❌ [Conditionnement] Erreur récupération conditionnements: $e');
      rethrow;
    }
  }

  /// 📊 RÉCUPÉRATION D'UN CONDITIONNEMENT PAR LOT
  Future<ConditionnementData?> getConditionnementByLotId(String lotId) async {
    try {
      final snapshot = await _firestore
          .collection('conditionnement')
          .where('lotFiltrageId', isEqualTo: lotId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return ConditionnementData.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint(
          '❌ [Conditionnement] Erreur récupération conditionnement pour lot $lotId: $e');
      return null;
    }
  }

  /// 💾 ENREGISTREMENT D'UN CONDITIONNEMENT
  Future<String> enregistrerConditionnement(
      ConditionnementData conditionnement) async {
    try {
      debugPrint('🔄 [Conditionnement] Enregistrement du conditionnement...');

      // Validation stricte
      final erreurs =
          ConditionnementUtils.validerConditionnement(conditionnement);
      if (erreurs.isNotEmpty) {
        throw Exception('Validation échouée: ${erreurs.join(', ')}');
      }

      // 🔥 VÉRIFICATION INTELLIGENTE : Permettre la mise à jour
      final conditionnementExistant =
          await getConditionnementByLotId(conditionnement.lotOrigine.id);

      String? conditionnementIdExistant;
      if (conditionnementExistant != null) {
        conditionnementIdExistant = conditionnementExistant.id;
        debugPrint(
            '⚠️ [Conditionnement] Lot déjà conditionné, mise à jour du conditionnement existant: $conditionnementIdExistant');
      }

      // Transaction pour garantir la cohérence
      final batch = _firestore.batch();

      // 1. Enregistrer ou mettre à jour le conditionnement
      final conditionnementRef = _firestore
          .collection('conditionnement')
          .doc(conditionnementIdExistant);
      batch.set(conditionnementRef, conditionnement.toFirestore(),
          SetOptions(merge: true));

      // 2. Mettre à jour le document filtrage
      final filtrageRef =
          _firestore.collection('filtrage').doc(conditionnement.lotOrigine.id);
      batch.update(filtrageRef, {
        'statutConditionnement': 'Conditionné',
        'dateConditionnement':
            Timestamp.fromDate(conditionnement.dateConditionnement),
        'quantiteConditionnee': conditionnement.quantiteConditionnee,
        'quantiteRestante': conditionnement.quantiteRestante,
        'predominanceFlorale': conditionnement.lotOrigine.predominanceFlorale,
        'conditionnementId': conditionnementRef.id,
      });

      // Exécuter la transaction
      await batch.commit();

      // Invalider le cache
      clearCache();

      debugPrint(
          '✅ [Conditionnement] Conditionnement enregistré avec ID: ${conditionnementRef.id}');
      return conditionnementRef.id;
    } catch (e) {
      debugPrint('❌ [Conditionnement] Erreur enregistrement: $e');
      rethrow;
    }
  }

  /// 📊 STATISTIQUES DU CONDITIONNEMENT
  Future<Map<String, dynamic>> getStatistiquesConditionnement({
    String? siteFilter,
    DateTime? periode,
  }) async {
    try {
      debugPrint('🔄 [Conditionnement] Calcul des statistiques...');

      // Récupérer les lots disponibles
      final lotsDisponibles =
          await getLotsDisponiblesConditionnement(siteFilter: siteFilter);

      // Récupérer les conditionnements
      final conditionnements = await getConditionnements(
        siteFilter: siteFilter,
        dateDebut: periode,
      );

      // Calculer les statistiques
      final stats = {
        'lotsDisponibles': lotsDisponibles.length,
        'lotsConditionnes': conditionnements.length,
        'quantiteTotaleDisponible': lotsDisponibles.fold<double>(
            0, (sum, lot) => sum + lot.quantiteRestante),
        'quantiteTotaleConditionnee': conditionnements.fold<double>(
            0, (sum, cond) => sum + cond.quantiteConditionnee),
        'valeurTotaleConditionnee': conditionnements.fold<double>(
            0, (sum, cond) => sum + cond.prixTotal),
        'nombreTotalPots': conditionnements.fold<int>(
            0, (sum, cond) => sum + cond.nbTotalPots),

        // Répartition par type de florale
        'repartitionFlorale': _calculerRepartitionFlorale(conditionnements),

        // Emballages populaires
        'emballagesPopulaires': _calculerEmballagesPopulaires(conditionnements),

        // Évolution mensuelle
        'evolutionMensuelle': _calculerEvolutionMensuelle(conditionnements),
      };

      debugPrint('✅ [Conditionnement] Statistiques calculées');
      return stats;
    } catch (e) {
      debugPrint('❌ [Conditionnement] Erreur calcul statistiques: $e');
      return {};
    }
  }

  /// Calcule la répartition par type de florale
  Map<String, dynamic> _calculerRepartitionFlorale(
      List<ConditionnementData> conditionnements) {
    final repartition = <TypeFlorale, Map<String, dynamic>>{};

    for (final conditionnement in conditionnements) {
      final type = conditionnement.lotOrigine.typeFlorale;
      repartition[type] ??= {
        'nombre': 0,
        'quantite': 0.0,
        'valeur': 0.0,
      };

      repartition[type]!['nombre'] += 1;
      repartition[type]!['quantite'] += conditionnement.quantiteConditionnee;
      repartition[type]!['valeur'] += conditionnement.prixTotal;
    }

    return repartition.map((type, data) => MapEntry(type.label, data));
  }

  /// Calcule les emballages les plus populaires
  Map<String, int> _calculerEmballagesPopulaires(
      List<ConditionnementData> conditionnements) {
    final popularite = <String, int>{};

    for (final conditionnement in conditionnements) {
      for (final emballage in conditionnement.emballages) {
        popularite[emballage.type.nom] = (popularite[emballage.type.nom] ?? 0) +
            emballage.nombreUnitesReelles;
      }
    }

    // Trier par popularité
    final sorted = Map.fromEntries(popularite.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)));

    return sorted;
  }

  /// Calcule l'évolution mensuelle
  Map<String, dynamic> _calculerEvolutionMensuelle(
      List<ConditionnementData> conditionnements) {
    final evolutionMensuelle = <String, Map<String, dynamic>>{};

    for (final conditionnement in conditionnements) {
      final moisKey = '${conditionnement.dateConditionnement.year}-'
          '${conditionnement.dateConditionnement.month.toString().padLeft(2, '0')}';

      evolutionMensuelle[moisKey] ??= {
        'nombre': 0,
        'quantite': 0.0,
        'valeur': 0.0,
      };

      evolutionMensuelle[moisKey]!['nombre'] += 1;
      evolutionMensuelle[moisKey]!['quantite'] +=
          conditionnement.quantiteConditionnee;
      evolutionMensuelle[moisKey]!['valeur'] += conditionnement.prixTotal;
    }

    return evolutionMensuelle;
  }

  /// 🔄 SYNCHRONISATION AVEC LES MODULES FILTRAGE ET EXTRACTION
  Future<void> synchroniserDonneesModules() async {
    try {
      debugPrint(
          '🔄 [Conditionnement] Synchronisation avec les autres modules...');

      // Vérifier les lots filtrés récemment mis à jour
      final lotsFiltrageRecents = await _firestore
          .collection('filtrage')
          .where('statutFiltrage', isEqualTo: 'Filtrage total')
          .where('lastModified',
              isGreaterThan: Timestamp.fromDate(
                  DateTime.now().subtract(const Duration(hours: 1))))
          .get();

      debugPrint(
          '📊 [Conditionnement] ${lotsFiltrageRecents.docs.length} lots filtrés récents trouvés');

      // Mettre à jour le cache
      for (final doc in lotsFiltrageRecents.docs) {
        final lot = LotFiltre.fromFirestore(doc);
        _lotsCache[lot.id] = lot;
      }

      // Vérifier l'intégrité des données
      await _verifierIntegriteDonnees();

      debugPrint('✅ [Conditionnement] Synchronisation terminée');
    } catch (e) {
      debugPrint('❌ [Conditionnement] Erreur synchronisation: $e');
    }
  }

  /// Vérifie l'intégrité des données entre les collections
  Future<void> _verifierIntegriteDonnees() async {
    try {
      // Vérifier que tous les conditionnements ont un lot filtrage valide
      final conditionnements =
          await _firestore.collection('conditionnement').get();

      for (final doc in conditionnements.docs) {
        final data = doc.data();
        final lotId = data['lotFiltrageId'];

        if (lotId != null) {
          final lotDoc =
              await _firestore.collection('filtrage').doc(lotId).get();

          if (!lotDoc.exists) {
            debugPrint(
                '⚠️ [Conditionnement] Lot manquant pour conditionnement ${doc.id}: $lotId');
          } else {
            final lotData = lotDoc.data()!;
            if (lotData['statutConditionnement'] != 'Conditionné') {
              debugPrint(
                  '⚠️ [Conditionnement] Statut incohérent pour lot $lotId');

              // Corriger automatiquement
              await _firestore.collection('filtrage').doc(lotId).update({
                'statutConditionnement': 'Conditionné',
                'conditionnementId': doc.id,
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [Conditionnement] Erreur vérification intégrité: $e');
    }
  }

  /// 🗑️ SUPPRESSION D'UN CONDITIONNEMENT (ADMIN SEULEMENT)
  Future<void> supprimerConditionnement(String conditionnementId) async {
    try {
      // Vérifier les permissions
      final userSession = Get.find<UserSession>();
      if (userSession.role != 'admin') {
        throw Exception(
            'Seuls les administrateurs peuvent supprimer un conditionnement');
      }

      debugPrint(
          '🗑️ [Conditionnement] Suppression du conditionnement $conditionnementId...');

      // Récupérer le conditionnement pour avoir l'ID du lot
      final conditionnementDoc = await _firestore
          .collection('conditionnement')
          .doc(conditionnementId)
          .get();

      if (!conditionnementDoc.exists) {
        throw Exception('Conditionnement introuvable');
      }

      final conditionnementData = conditionnementDoc.data()!;
      final lotId = conditionnementData['lotFiltrageId'];

      // Transaction pour garantir la cohérence
      final batch = _firestore.batch();

      // 1. Supprimer le conditionnement
      batch.delete(
          _firestore.collection('conditionnement').doc(conditionnementId));

      // 2. Remettre à jour le statut du lot filtrage
      if (lotId != null) {
        batch.update(_firestore.collection('filtrage').doc(lotId), {
          'statutConditionnement': FieldValue.delete(),
          'dateConditionnement': FieldValue.delete(),
          'quantiteConditionnee': FieldValue.delete(),
          'conditionnementId': FieldValue.delete(),
        });
      }

      await batch.commit();

      // Invalider le cache
      clearCache();

      debugPrint('✅ [Conditionnement] Conditionnement supprimé avec succès');
    } catch (e) {
      debugPrint('❌ [Conditionnement] Erreur suppression: $e');
      rethrow;
    }
  }

  /// 📊 RAPPORT DÉTAILLÉ POUR EXPORT
  Future<Map<String, dynamic>> genererRapportDetaillee({
    DateTime? dateDebut,
    DateTime? dateFin,
    String? siteFilter,
  }) async {
    try {
      debugPrint('📊 [Conditionnement] Génération du rapport détaillé...');

      final conditionnements = await getConditionnements(
        siteFilter: siteFilter,
        dateDebut: dateDebut,
        dateFin: dateFin,
      );

      final rapport = {
        'metadata': {
          'dateGeneration': DateTime.now().toIso8601String(),
          'periode': {
            'debut': dateDebut?.toIso8601String(),
            'fin': dateFin?.toIso8601String(),
          },
          'siteFilter': siteFilter,
          'nombreConditionnements': conditionnements.length,
        },
        'resume': await getStatistiquesConditionnement(
          siteFilter: siteFilter,
          periode: dateDebut,
        ),
        'conditionnements': conditionnements
            .map((c) => {
                  'id': c.id,
                  'date': c.dateConditionnement.toIso8601String(),
                  'lotOrigine': c.lotOrigine.lotOrigine,
                  'site': c.lotOrigine.site,
                  'technicien': c.lotOrigine.technicien,
                  'typeFlorale': c.lotOrigine.typeFlorale.label,
                  'quantiteRecue': c.lotOrigine.quantiteRecue,
                  'quantiteConditionnee': c.quantiteConditionnee,
                  'quantiteRestante': c.quantiteRestante,
                  'pourcentageConditionne': c.pourcentageConditionne,
                  'nbTotalPots': c.nbTotalPots,
                  'prixTotal': c.prixTotal,
                  'emballages': c.emballages
                      .map((e) => {
                            'type': e.type.nom,
                            'nombreSaisi': e.nombreSaisi,
                            'nombreUnitesReelles': e.nombreUnitesReelles,
                            'poidsTotal': e.poidsTotal,
                            'prixTotal': e.prixTotal,
                            'description': e.descriptionMode,
                          })
                      .toList(),
                  'recapitulatif': c.recapitulatifEmballages,
                })
            .toList(),
      };

      debugPrint(
          '✅ [Conditionnement] Rapport généré avec ${conditionnements.length} entrées');
      return rapport;
    } catch (e) {
      debugPrint('❌ [Conditionnement] Erreur génération rapport: $e');
      rethrow;
    }
  }

  /// 🔄 STREAM EN TEMPS RÉEL DES LOTS DISPONIBLES
  Stream<List<LotFiltre>> streamLotsDisponibles({String? siteFilter}) {
    Query query = _firestore
        .collection('filtrage')
        .where('statutFiltrage', isEqualTo: 'Filtrage total');

    if (siteFilter != null) {
      query = query.where('site', isEqualTo: siteFilter);
    }

    return query.snapshots().map((snapshot) {
      final lots = <LotFiltre>[];
      for (final doc in snapshot.docs) {
        try {
          final lot = LotFiltre.fromFirestore(doc);
          if (lot.peutEtreConditionne) {
            lots.add(lot);
          }
        } catch (e) {
          debugPrint('❌ Erreur parsing lot en temps réel ${doc.id}: $e');
        }
      }

      // Trier par date de filtrage
      lots.sort((a, b) => b.dateFiltrage.compareTo(a.dateFiltrage));
      return lots;
    });
  }
}
