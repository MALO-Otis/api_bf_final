import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../../vente/models/vente_models.dart';
import '../models/transaction_commerciale.dart';
import '../../../authentication/user_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🏪 SERVICE DE GESTION DES TRANSACTIONS COMMERCIALES
///
/// Service centralisé pour gérer le flux complet:
/// Commercial termine → Notification caisse → Validation admin

class TransactionCommercialeService extends GetxService {
  // Make the instance getter resilient: if the service isn't registered yet,
  // create and register it so callers don't get a hard exception depending
  // on initialization order elsewhere in the app.
  static TransactionCommercialeService get instance {
    try {
      return Get.find<TransactionCommercialeService>();
    } catch (_) {
      final svc = TransactionCommercialeService._internal();
      try {
        Get.put<TransactionCommercialeService>(svc);
      } catch (_) {}
      return svc;
    }
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final UserSession _userSession;

  // Private named constructor used by the resilient instance getter
  TransactionCommercialeService._internal() {
    // Ensure a UserSession exists; if not registered, create a default one.
    if (Get.isRegistered<UserSession>()) {
      _userSession = Get.find<UserSession>();
    } else {
      _userSession = Get.put(UserSession());
    }
  }

  // Default constructor used when registering normally
  TransactionCommercialeService() : this._internal();

  // Collections
  static const String _collectionTransactions = 'transactions_commerciales';
  static const String _collectionNotifications = 'notifications_caisse';

  // ========== CRÉATION ET TERMINER TRANSACTION ==========

  /// Créé une transaction commerciale quand le commercial clique "Terminer"
  Future<TransactionCommerciale> terminerTransactionCommerciale({
    required String site,
    required String commercialId,
    required String commercialNom,
    required String prelevementId,
    String? observations,
  }) async {
    try {
      // 1. Récupérer toutes les données du prélèvement
      final donnees = await _recupererDonneesPrelevement(site, prelevementId);

      // 2. Créer la transaction
      final transaction = TransactionCommerciale(
        id: _genererIdTransaction(),
        site: site,
        commercialId: commercialId,
        commercialNom: commercialNom,
        prelevementId: prelevementId,
        dateCreation: DateTime.now(),
        dateTerminee: DateTime.now(),
        statut: StatutTransactionCommerciale.termineEnAttente,
        observations: observations,
        resumeFinancier: donnees.resumeFinancier,
        ventes: donnees.ventes,
        restitutions: donnees.restitutions,
        pertes: donnees.pertes,
        credits: donnees.credits,
        paiements: donnees.paiements,
        quantitesOrigine: donnees.quantitesOrigine,
      );

      // 3. Sauvegarder la transaction
      await _firestore
          .collection(_collectionTransactions)
          .doc(transaction.id)
          .set(transaction.toMap());

      // Marquer le prélèvement comme en attente et créer un verrou d'attribution
      try {
        await _firestore
            .collection('Vente')
            .doc(transaction.site)
            .collection('prelevements')
            .doc(transaction.prelevementId)
            .set({'enAttenteValidation': true}, SetOptions(merge: true));

        final attributionId =
            transaction.prelevementId.replaceAll('_prelevement_temp', '');
        await _firestore
            .collection('Vente')
            .doc(transaction.site)
            .collection('locks_attributions')
            .doc(attributionId)
            .set({
          'enAttenteValidation': true,
          'prelevementId': transaction.prelevementId,
          'date': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        // ignore missing prelevement
        print('⚠️ Impossible de marquer prelevement en attente: $e');
      }

      // 4. Créer la notification pour la caisse
      await _creerNotificationCaisse(transaction);

      print('✅ Transaction ${transaction.id} terminée et envoyée à la caisse');

      return transaction;
    } catch (e) {
      print('❌ Erreur terminer transaction: $e');
      rethrow;
    }
  }

  /// Récupère toutes les données associées à un prélèvement
  Future<_DonneesPrelevement> _recupererDonneesPrelevement(
      String site, String prelevementId) async {
    // Récupérer les ventes
    final ventesSnap = await _firestore
        .collection('Vente')
        .doc(site)
        .collection('ventes')
        .where('prelevementId', isEqualTo: prelevementId)
        .get();

    final ventes = ventesSnap.docs
        .map((doc) => _mapperVenteToDetails(Vente.fromMap(doc.data())))
        .toList();

    // Récupérer les restitutions
    final restitutionsSnap = await _firestore
        .collection('Vente')
        .doc(site)
        .collection('restitutions')
        .where('prelevementId', isEqualTo: prelevementId)
        .get();

    final restitutions = restitutionsSnap.docs
        .map((doc) => _mapperRestitutionToDetails(doc.data()))
        .toList();

    // Récupérer les pertes
    final pertesSnap = await _firestore
        .collection('Vente')
        .doc(site)
        .collection('pertes')
        .where('prelevementId', isEqualTo: prelevementId)
        .get();

    final pertes = pertesSnap.docs
        .map((doc) => _mapperPerteToDetails(doc.data()))
        .toList();

    // Calculer les données financières
    final resumeFinancier =
        _calculerResumeFinancier(ventes, restitutions, pertes);

    // Récupérer les crédits (basés sur les ventes)
    final credits = _extraireCreditsDeMesVentes(ventes);

    // Récupérer les paiements
    final paiements = _extrairePaiementsDeMesVentes(ventes);

    // Calculer les quantités d'origine
    final quantitesOrigine =
        await _calculerQuantitesOrigine(site, prelevementId);

    return _DonneesPrelevement(
      resumeFinancier: resumeFinancier,
      ventes: ventes,
      restitutions: restitutions,
      pertes: pertes,
      credits: credits,
      paiements: paiements,
      quantitesOrigine: quantitesOrigine,
    );
  }

  /// Créer une notification pour la caisse
  Future<void> _creerNotificationCaisse(
      TransactionCommerciale transaction) async {
    final notification = {
      'id': 'NOTIF_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'prelevement_termine',
      'site': transaction.site,
      'commercialId': transaction.commercialId,
      'commercialNom': transaction.commercialNom,
      'transactionId': transaction.id,
      'prelevementId': transaction.prelevementId,
      'dateCreation': Timestamp.fromDate(DateTime.now()),
      'titre': 'Prélèvement terminé - ${transaction.commercialNom}',
      'message':
          'Le commercial ${transaction.commercialNom} a terminé son prélèvement. Montant: ${transaction.resumeFinancier.chiffreAffairesNet.toStringAsFixed(0)} FCFA',
      'statut': 'non_lue',
      'priorite': 'normale',
      'donnees': {
        'totalVentes': transaction.resumeFinancier.totalVentes,
        'totalCredits': transaction.resumeFinancier.totalCredits,
        'totalRestitutions': transaction.resumeFinancier.totalRestitutions,
        'totalPertes': transaction.resumeFinancier.totalPertes,
        'chiffreAffairesNet': transaction.resumeFinancier.chiffreAffairesNet,
      }
    };

    await _firestore
        .collection(_collectionNotifications)
        .doc(notification['id'] as String)
        .set(notification);
  }

  // ========== GESTION CAISSE ==========

  /// Récupère les transactions en attente pour un site (caissier)
  Stream<List<TransactionCommerciale>> getTransactionsEnAttentePourSite(
      String site) {
    return _firestore
        .collection(_collectionTransactions)
        .where('site', isEqualTo: site)
        .where('statut',
            isEqualTo: StatutTransactionCommerciale.termineEnAttente.name)
        .orderBy('dateTerminee', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionCommerciale.fromMap(doc.data()))
            .toList());
  }

  /// Récupère les notifications caisse pour un site
  Stream<List<Map<String, dynamic>>> getNotificationsCaisse(String site) {
    return _firestore
        .collection(_collectionNotifications)
        .where('site', isEqualTo: site)
        .where('statut', isEqualTo: 'non_lue')
        .orderBy('dateCreation', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  /// Marque une transaction comme récupérée par la caisse
  Future<void> marquerRecupereeParCaisse(String transactionId) async {
    await _firestore
        .collection(_collectionTransactions)
        .doc(transactionId)
        .update({
      'statut': StatutTransactionCommerciale.recupereeCaisse.name,
      'dateRecuperationCaisse': Timestamp.fromDate(DateTime.now()),
    });

    // Marquer les notifications associées comme lues
    final notifs = await _firestore
        .collection(_collectionNotifications)
        .where('transactionId', isEqualTo: transactionId)
        .get();

    for (final doc in notifs.docs) {
      await doc.reference.update({'statut': 'lue'});
    }
  }

  // ========== GESTION ADMIN ==========

  /// Récupère toutes les transactions pour l'admin (tous sites)
  Stream<List<TransactionCommerciale>> getToutesTransactionsPourAdmin() {
    return _firestore
        .collection(_collectionTransactions)
        .orderBy('dateCreation', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionCommerciale.fromMap(doc.data()))
            .toList());
  }

  /// Récupère les transactions d'un commercial spécifique
  Stream<List<TransactionCommerciale>> getTransactionsParCommercial(
      String commercialId) {
    return _firestore
        .collection(_collectionTransactions)
        .where('commercialId', isEqualTo: commercialId)
        .orderBy('dateCreation', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionCommerciale.fromMap(doc.data()))
            .toList());
  }

  /// Valide complètement une transaction (admin)
  Future<void> validerTransaction(
      String transactionId, String validePar) async {
    debugPrint(
        '🔔 [validerTransaction] called transactionId=$transactionId validePar=$validePar');
    if (transactionId.trim().isEmpty) {
      debugPrint('⚠️ [validerTransaction] empty transactionId, skipping');
      return;
    }

    await _firestore
        .collection(_collectionTransactions)
        .doc(transactionId)
        .update({
      'statut': StatutTransactionCommerciale.valideeAdmin.name,
      'validePar': validePar,
      'dateValidation': Timestamp.fromDate(DateTime.now()),
      // Persist a soft-hide expiry so clients can hide validated transactions
      // for a limited time even after reload. Use a default of 5 hours here
      // to match existing UI behaviour. Clients may choose a different
      // duration if needed by writing their own field overrides.
      'validationExpiry':
          Timestamp.fromDate(DateTime.now().add(Duration(hours: 5))),
      // Also persist a 24h expiry intended for the Espace commercial page
      'validationExpiryEspace':
          Timestamp.fromDate(DateTime.now().add(Duration(hours: 24))),
    });

    // Valider tous les éléments individuels
    await _validerElementsTransaction(transactionId);

    // Déverrouiller l'attribution et le prélèvement liés
    final txnDoc = await _firestore
        .collection(_collectionTransactions)
        .doc(transactionId)
        .get();
    if (txnDoc.exists) {
      final data = txnDoc.data()!;
      final site = data['site'] as String? ?? '';
      final prelevementId = data['prelevementId'] as String? ?? '';
      final attributionId = prelevementId.replaceAll('_prelevement_temp', '');
      if (site.isNotEmpty && prelevementId.isNotEmpty) {
        try {
          await _firestore
              .collection('Vente')
              .doc(site)
              .collection('prelevements')
              .doc(prelevementId)
              .set({'enAttenteValidation': false}, SetOptions(merge: true));
        } catch (_) {}
        try {
          await _firestore
              .collection('Vente')
              .doc(site)
              .collection('locks_attributions')
              .doc(attributionId)
              .set({'enAttenteValidation': false}, SetOptions(merge: true));
        } catch (_) {}
      }
    }
  }

  Future<void> _clearLocksForSiteAndPrelevement(
      String site, String prelevementId) async {
    final attributionId = prelevementId.replaceAll('_prelevement_temp', '');
    try {
      await _firestore
          .collection('Vente')
          .doc(site)
          .collection('prelevements')
          .doc(prelevementId)
          .set({'enAttenteValidation': false}, SetOptions(merge: true));
    } catch (_) {}
    try {
      await _firestore
          .collection('Vente')
          .doc(site)
          .collection('locks_attributions')
          .doc(attributionId)
          .set({'enAttenteValidation': false}, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Valide directement un élément stocké dans les collections legacy
  /// (Vente/{site}/ventes | restitutions | pertes) lorsque
  /// il n'existe pas de document canonique dans `transactions_commerciales`.
  ///
  /// This will:
  /// - mark the legacy element as validated (statut / valideAdmin / dateValidation)
  /// - write dateValidation / enAttenteValidation on the related prelevement
  ///   and locks_attributions documents if a prelevementId / attributionId exists
  Future<void> validerLegacyElement({
    required String site,
    required String elementType, // 'vente' | 'restitution' | 'perte'
    required String elementId,
    String? validePar,
    // Optional expiry duration for the soft-hide UX. Defaults to 5 hours to
    // preserve existing behaviour. Callers can pass Duration(hours: 24)
    // when they want a 24h expiry (e.g. Espace commercial page).
    Duration? expiryDuration,
  }) async {
    debugPrint(
        '\ud83d\udd14 [validerLegacyElement] site=$site elementType=$elementType elementId=$elementId');

    if (site.trim().isEmpty) {
      debugPrint('\u26a0\ufe0f [validerLegacyElement] empty site, skipping');
      return;
    }

    final collectionName = switch (elementType) {
      'vente' => 'ventes',
      'restitution' => 'restitutions',
      'perte' => 'pertes',
      _ => null
    };

    if (collectionName == null) {
      debugPrint(
          '\u26a0\ufe0f [validerLegacyElement] unknown elementType=$elementType');
      return;
    }

    try {
      final docRef = _firestore
          .collection('Vente')
          .doc(site)
          .collection(collectionName)
          .doc(elementId);

      final snap = await docRef.get();
      if (!snap.exists) {
        debugPrint(
            '\u26a0\ufe0f [validerLegacyElement] legacy doc not found: $collectionName/$elementId');
        return;
      }

      final nowTs = Timestamp.fromDate(DateTime.now());
      final expiryDur = expiryDuration ?? const Duration(hours: 5);
      final expiryTs = Timestamp.fromDate(DateTime.now().add(expiryDur));
      // expiry specifically intended for the Espace commercial page
      // (24 hours). We persist both so different UIs can pick the
      // appropriate duration.
      final expiryEspaceTs =
          Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24)));

      // Prepare patch depending on type
      final Map<String, dynamic> update = {
        'valideAdmin': true,
        'dateValidation': nowTs,
        // Persist per-legacy-element validation expiries so the UI can
        // reconstruct hide timers after a refresh. 'validationExpiry' is
        // the shorter default (5h) and 'validationExpiryEspace' is 24h.
        'validationExpiry': expiryTs,
        'validationExpiryEspace': expiryEspaceTs,
      };

      // Set a human-friendly status field if present in legacy docs
      switch (elementType) {
        case 'vente':
          update['statut'] = 'Validé';
          break;
        case 'restitution':
          update['statut'] = 'Acceptée';
          break;
        case 'perte':
          update['statut'] = 'Validée';
          break;
      }
      if (validePar != null && validePar.trim().isNotEmpty) {
        update['validePar'] = validePar;
      }

      await docRef.set(update, SetOptions(merge: true));
      debugPrint(
          '\u2705 [validerLegacyElement] legacy element updated: $collectionName/$elementId');

      // Read legacy doc data to find potential prelevement/attribution ids
      final data = snap.data() as Map<String, dynamic>;
      final prelevementId = (data['prelevementId'] ?? '') as String? ?? '';

      // Also try to find a canonical transaction linked to the same prelevementId
      // and mark the corresponding element as validated so UI that prefers
      // `transactions_commerciales` shows the correct state after refresh.
      try {
        if (prelevementId.trim().isNotEmpty) {
          final txSnap = await _firestore
              .collection(_collectionTransactions)
              .where('site', isEqualTo: site)
              .where('prelevementId', isEqualTo: prelevementId)
              .get();
          for (final txDoc in txSnap.docs) {
            final txRef = txDoc.reference;
            final txData = txDoc.data();
            try {
              final tx = TransactionCommerciale.fromMap(txData);
              bool changed = false;

              if (elementType == 'vente') {
                final ventes = tx.ventes.map((v) {
                  if (v.id == elementId && v.valideAdmin != true) {
                    changed = true;
                    return VenteDetails(
                      id: v.id,
                      date: v.date,
                      clientNom: v.clientNom,
                      clientTelephone: v.clientTelephone,
                      produits: v.produits,
                      montantTotal: v.montantTotal,
                      montantPaye: v.montantPaye,
                      montantRestant: v.montantRestant,
                      modePaiement: v.modePaiement,
                      statut: v.statut,
                      valideAdmin: true,
                    ).toMap();
                  }
                  return v.toMap();
                }).toList();
                if (changed) {
                  final now = DateTime.now();
                  final expiryDefault = Timestamp.fromDate(now.add(expiryDur));
                  final expiryEspace =
                      Timestamp.fromDate(now.add(const Duration(hours: 24)));
                  final ventesWithExpiry = ventes.map((m) {
                    final mm = Map<String, dynamic>.from(m);
                    if (mm['id'] == elementId) {
                      mm['validationExpiry'] = expiryDefault;
                      mm['validationExpiryEspace'] = expiryEspace;
                    }
                    return mm;
                  }).toList();
                  await txRef.set(
                      {'ventes': ventesWithExpiry}, SetOptions(merge: true));
                }
              } else if (elementType == 'restitution') {
                final restitutions = tx.restitutions.map((r) {
                  if (r.id == elementId && r.valideAdmin != true) {
                    changed = true;
                    return RestitutionDetails(
                      id: r.id,
                      date: r.date,
                      numeroLot: r.numeroLot,
                      typeEmballage: r.typeEmballage,
                      quantiteRestituee: r.quantiteRestituee,
                      poidsRestitue: r.poidsRestitue,
                      motif: r.motif,
                      valideAdmin: true,
                    ).toMap();
                  }
                  return r.toMap();
                }).toList();
                if (changed) {
                  final now = DateTime.now();
                  final expiryDefault = Timestamp.fromDate(now.add(expiryDur));
                  final expiryEspace =
                      Timestamp.fromDate(now.add(const Duration(hours: 24)));
                  final restWithExpiry = restitutions.map((m) {
                    final mm = Map<String, dynamic>.from(m);
                    if (mm['id'] == elementId) {
                      mm['validationExpiry'] = expiryDefault;
                      mm['validationExpiryEspace'] = expiryEspace;
                    }
                    return mm;
                  }).toList();
                  await txRef.set({'restitutions': restWithExpiry},
                      SetOptions(merge: true));
                }
              } else if (elementType == 'perte') {
                final pertes = tx.pertes.map((p) {
                  if (p.id == elementId && p.valideAdmin != true) {
                    changed = true;
                    return PerteDetails(
                      id: p.id,
                      date: p.date,
                      numeroLot: p.numeroLot,
                      typeEmballage: p.typeEmballage,
                      quantitePerdue: p.quantitePerdue,
                      poidsPerdu: p.poidsPerdu,
                      motif: p.motif,
                      valeurPerte: p.valeurPerte,
                      valideAdmin: true,
                    ).toMap();
                  }
                  return p.toMap();
                }).toList();
                if (changed) {
                  final now = DateTime.now();
                  final expiryDefault = Timestamp.fromDate(now.add(expiryDur));
                  final expiryEspace =
                      Timestamp.fromDate(now.add(const Duration(hours: 24)));
                  final pertesWithExpiry = pertes.map((m) {
                    final mm = Map<String, dynamic>.from(m);
                    if (mm['id'] == elementId) {
                      mm['validationExpiry'] = expiryDefault;
                      mm['validationExpiryEspace'] = expiryEspace;
                    }
                    return mm;
                  }).toList();
                  await txRef.set(
                      {'pertes': pertesWithExpiry}, SetOptions(merge: true));
                }
              }
            } catch (e) {
              debugPrint(
                  '\u26a0\ufe0f [validerLegacyElement] canonical tx update failed: $e');
            }
          }
        }
      } catch (e) {
        debugPrint(
            '\u26a0\ufe0f [validerLegacyElement] error updating canonical tx: $e');
      }
      // Try to clear corresponding prelevement/lock if IDs exist in legacy doc
      String attributionId = '';
      if (prelevementId.trim().isNotEmpty) {
        // Derive attributionId as older code expects (strip suffix if present)
        attributionId = prelevementId.replaceAll('_prelevement_temp', '');
      } else if ((data['attributionId'] ?? '').toString().isNotEmpty) {
        attributionId = (data['attributionId'] ?? '').toString();
      }

      if (prelevementId.trim().isNotEmpty) {
        try {
          await _firestore
              .collection('Vente')
              .doc(site)
              .collection('prelevements')
              .doc(prelevementId)
              .set({'dateValidation': nowTs, 'enAttenteValidation': false},
                  SetOptions(merge: true));
        } catch (_) {}
      }

      if (attributionId.trim().isNotEmpty) {
        try {
          await _firestore
              .collection('Vente')
              .doc(site)
              .collection('locks_attributions')
              .doc(attributionId)
              .set({'dateValidation': nowTs, 'enAttenteValidation': false},
                  SetOptions(merge: true));
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('\u274c [validerLegacyElement] error: $e');
      rethrow;
    }
  }

  /// Annule une validation appliquée sur un élément legacy (ventes/restitutions/pertes)
  /// Revert: sets valideAdmin = false, removes dateValidation and resets prelevement/lock flags
  Future<void> annulerLegacyValidation({
    required String site,
    required String elementType,
    required String elementId,
  }) async {
    debugPrint(
        '\u26a0\ufe0f [annulerLegacyValidation] site=$site elementType=$elementType elementId=$elementId');

    final collectionName = switch (elementType) {
      'vente' => 'ventes',
      'restitution' => 'restitutions',
      'perte' => 'pertes',
      _ => null
    };

    if (collectionName == null) return;

    try {
      final docRef = _firestore
          .collection('Vente')
          .doc(site)
          .collection(collectionName)
          .doc(elementId);

      final snap = await docRef.get();
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;

      // Revert fields on legacy element
      final Map<String, dynamic> update = {
        'valideAdmin': false,
        'statut': 'En attente',
        'dateValidation': FieldValue.delete(),
        // Remove persisted expiry when undoing
        'validationExpiry': FieldValue.delete(),
        'validationExpiryEspace': FieldValue.delete(),
      };

      await docRef.set(update, SetOptions(merge: true));

      // Revert prelevement/lock if referenced
      final prelevementId = (data['prelevementId'] ?? '') as String? ?? '';
      String attributionId = '';
      if (prelevementId.trim().isNotEmpty) {
        attributionId = prelevementId.replaceAll('_prelevement_temp', '');
      } else if ((data['attributionId'] ?? '').toString().isNotEmpty) {
        attributionId = (data['attributionId'] ?? '').toString();
      }

      if (prelevementId.trim().isNotEmpty) {
        try {
          await _firestore
              .collection('Vente')
              .doc(site)
              .collection('prelevements')
              .doc(prelevementId)
              .set({
            'dateValidation': FieldValue.delete(),
            'enAttenteValidation': true
          }, SetOptions(merge: true));
        } catch (_) {}
      }

      if (attributionId.trim().isNotEmpty) {
        try {
          await _firestore
              .collection('Vente')
              .doc(site)
              .collection('locks_attributions')
              .doc(attributionId)
              .set({
            'dateValidation': FieldValue.delete(),
            'enAttenteValidation': true
          }, SetOptions(merge: true));
        } catch (_) {}
      }
      debugPrint(
          '\u2705 [annulerLegacyValidation] reverted legacy element $collectionName/$elementId');
    } catch (e) {
      debugPrint('\u274c [annulerLegacyValidation] error: $e');
      rethrow;
    }
  }

  /// Annule une validation sur une transaction canonique et ses éléments
  Future<void> annulerTransactionValidation(String transactionId) async {
    debugPrint(
        '\u26a0\ufe0f [annulerTransactionValidation] txId=$transactionId');
    if (transactionId.trim().isEmpty) return;

    try {
      final txRef =
          _firestore.collection('transactions_commerciales').doc(transactionId);
      final snap = await txRef.get();
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final site = (data['site'] ?? '') as String;
      final prelevementId = (data['prelevementId'] ?? '') as String? ?? '';

      // Reset transaction-level fields and remove persisted expiry
      await txRef.set({
        'statut': 'enAttente',
        'dateValidation': FieldValue.delete(),
        'validationExpiry': FieldValue.delete(),
      }, SetOptions(merge: true));

      // Reset element-level valideAdmin flags inside arrays and remove per-element expiry
      try {
        final tx = TransactionCommerciale.fromMap(data);
        final ventesReset = tx.ventes.map((v) {
          final m = {...v.toMap()};
          m.remove('validationExpiry');
          m.remove('validationExpiryEspace');
          m['valideAdmin'] = false;
          return m;
        }).toList();
        final restReset = tx.restitutions.map((r) {
          final m = {...r.toMap()};
          m.remove('validationExpiry');
          m.remove('validationExpiryEspace');
          m['valideAdmin'] = false;
          return m;
        }).toList();
        final pertesReset = tx.pertes.map((p) {
          final m = {...p.toMap()};
          m.remove('validationExpiry');
          m.remove('validationExpiryEspace');
          m['valideAdmin'] = false;
          return m;
        }).toList();

        await txRef.set({
          'ventes': ventesReset,
          'restitutions': restReset,
          'pertes': pertesReset,
        }, SetOptions(merge: true));
      } catch (_) {}

      // Revert prelevement/lock if present
      if (prelevementId.trim().isNotEmpty && site.trim().isNotEmpty) {
        try {
          await _firestore
              .collection('Vente')
              .doc(site)
              .collection('prelevements')
              .doc(prelevementId)
              .set({
            'dateValidation': FieldValue.delete(),
            'enAttenteValidation': true
          }, SetOptions(merge: true));
        } catch (_) {}

        try {
          // attribution id might be stored on prelevement or transaction data
          final attributionId = (data['attributionId'] ?? '') as String? ?? '';
          if (attributionId.trim().isNotEmpty) {
            await _firestore
                .collection('Vente')
                .doc(site)
                .collection('locks_attributions')
                .doc(attributionId)
                .set({
              'dateValidation': FieldValue.delete(),
              'enAttenteValidation': true
            }, SetOptions(merge: true));
          }
        } catch (_) {}
      }

      debugPrint(
          '\u2705 [annulerTransactionValidation] reverted transaction $transactionId');
    } catch (e) {
      debugPrint('\u274c [annulerTransactionValidation] error: $e');
      rethrow;
    }
  }

  /// Rejette une transaction
  Future<void> rejeterTransaction(
      String transactionId, String raisonRejet) async {
    await _firestore
        .collection(_collectionTransactions)
        .doc(transactionId)
        .update({
      'statut': StatutTransactionCommerciale.rejetee.name,
      'validePar': _userSession.nom ?? 'Admin',
      'dateValidation': Timestamp.fromDate(DateTime.now()),
      'observations': raisonRejet,
    });

    // Déverrouiller également pour permettre une nouvelle soumission
    final txnDoc = await _firestore
        .collection(_collectionTransactions)
        .doc(transactionId)
        .get();
    if (txnDoc.exists) {
      final data = txnDoc.data()!;
      final site = data['site'] as String? ?? '';
      final prelevementId = data['prelevementId'] as String? ?? '';
      if (site.isNotEmpty && prelevementId.isNotEmpty) {
        await _clearLocksForSiteAndPrelevement(site, prelevementId);
      }
    }
  }

  /// Valide un élément spécifique (vente, restitution, perte, crédit, paiement)
  Future<void> validerElement({
    required String transactionId,
    required String
        elementType, // 'vente', 'restitution', 'perte', 'credit', 'paiement'
    required String elementId,
  }) async {
    debugPrint(
        '🔔 [validerElement] called transactionId=$transactionId elementType=$elementType elementId=$elementId');

    if (transactionId.trim().isEmpty) {
      debugPrint('⚠️ [validerElement] empty transactionId, skipping');
      return;
    }

    final transaction = await _firestore
        .collection(_collectionTransactions)
        .doc(transactionId)
        .get();

    if (!transaction.exists) {
      debugPrint(
          '⚠️ [validerElement] transaction not found for id=$transactionId');
      return;
    }

    final data = transaction.data()!;
    final transactionObj = TransactionCommerciale.fromMap(data);

    // Mettre à jour l'élément spécifique
    switch (elementType) {
      case 'vente':
        final ventes = transactionObj.ventes.map((v) {
          if (v.id == elementId) {
            return VenteDetails(
              id: v.id,
              date: v.date,
              clientNom: v.clientNom,
              clientTelephone: v.clientTelephone,
              produits: v.produits,
              montantTotal: v.montantTotal,
              montantPaye: v.montantPaye,
              montantRestant: v.montantRestant,
              modePaiement: v.modePaiement,
              statut: v.statut,
              valideAdmin: true,
            );
          }
          return v;
        }).toList();

        await _firestore
            .collection(_collectionTransactions)
            .doc(transactionId)
            .update({'ventes': ventes.map((v) => v.toMap()).toList()});
        debugPrint(
            '✅ [validerElement] vente $elementId marked validated in transaction $transactionId');
        break;

      case 'restitution':
        final restitutions = transactionObj.restitutions.map((r) {
          if (r.id == elementId) {
            return RestitutionDetails(
              id: r.id,
              date: r.date,
              numeroLot: r.numeroLot,
              typeEmballage: r.typeEmballage,
              quantiteRestituee: r.quantiteRestituee,
              poidsRestitue: r.poidsRestitue,
              motif: r.motif,
              valideAdmin: true,
            );
          }
          return r;
        }).toList();

        await _firestore
            .collection(_collectionTransactions)
            .doc(transactionId)
            .update(
                {'restitutions': restitutions.map((r) => r.toMap()).toList()});
        debugPrint(
            '✅ [validerElement] restitution $elementId marked validated in transaction $transactionId');
        break;

      case 'perte':
        final pertes = transactionObj.pertes.map((p) {
          if (p.id == elementId) {
            return PerteDetails(
              id: p.id,
              date: p.date,
              numeroLot: p.numeroLot,
              typeEmballage: p.typeEmballage,
              quantitePerdue: p.quantitePerdue,
              poidsPerdu: p.poidsPerdu,
              motif: p.motif,
              valeurPerte: p.valeurPerte,
              valideAdmin: true,
            );
          }
          return p;
        }).toList();

        await _firestore
            .collection(_collectionTransactions)
            .doc(transactionId)
            .update({'pertes': pertes.map((p) => p.toMap()).toList()});
        debugPrint(
            '✅ [validerElement] perte $elementId marked validated in transaction $transactionId');
        break;

      // Implémentations basiques pour credit / paiement : marquer valideAdmin si présent
      case 'credit':
        final credits = transactionObj.credits.map((c) {
          if (c.id == elementId) {
            return CreditDetails(
              id: c.id,
              venteId: c.venteId,
              dateCredit: c.dateCredit,
              dateRemboursement: c.dateRemboursement,
              montantCredit: c.montantCredit,
              montantRembourse: c.montantRembourse,
              montantRestant: c.montantRestant,
              statut: c.statut,
              clientNom: c.clientNom,
              valideAdmin: true,
            );
          }
          return c;
        }).toList();

        await _firestore
            .collection(_collectionTransactions)
            .doc(transactionId)
            .update({'credits': credits.map((c) => c.toMap()).toList()});
        debugPrint(
            '✅ [validerElement] credit $elementId marked validated in transaction $transactionId');
        break;

      case 'paiement':
        final paiements = transactionObj.paiements.map((p) {
          if (p.id == elementId) {
            return PaiementDetails(
              id: p.id,
              venteId: p.venteId,
              creditId: p.creditId,
              date: p.date,
              montant: p.montant,
              mode: p.mode,
              reference: p.reference,
              valideAdmin: true,
            );
          }
          return p;
        }).toList();

        await _firestore
            .collection(_collectionTransactions)
            .doc(transactionId)
            .update({'paiements': paiements.map((p) => p.toMap()).toList()});
        debugPrint(
            '✅ [validerElement] paiement $elementId marked validated in transaction $transactionId');
        break;

      default:
        // Unknown type: do nothing
        debugPrint('⚠️ [validerElement] unknown elementType=$elementType');
        break;
    }
  }

  // ========== UTILITAIRES PRIVÉES ==========

  String _genererIdTransaction() {
    return 'TXN_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Mapper une Vente vers VenteDetails
  VenteDetails _mapperVenteToDetails(Vente vente) {
    return VenteDetails(
      id: vente.id,
      date: vente.dateVente,
      clientNom: vente.clientNom,
      clientTelephone: vente.clientTelephone ?? '',
      produits: vente.produits
          .map((p) => ProduitVenteDetail(
                produitId: p.produitId,
                numeroLot: p.numeroLot,
                typeEmballage: p.typeEmballage,
                contenanceKg: p.contenanceKg,
                quantiteVendue: p.quantiteVendue,
                prixUnitaire: p.prixUnitaire,
                prixVente: p.prixVente,
                montantTotal: p.montantTotal,
                prixOrigineMiel:
                    0, // À calculer depuis les données d'attribution
              ))
          .toList(),
      montantTotal: vente.montantTotal,
      montantPaye: vente.montantPaye,
      montantRestant: vente.montantRestant,
      modePaiement: vente.modePaiement,
      statut: vente.statut,
      valideAdmin: false,
    );
  }

  /// Mapper une restitution vers RestitutionDetails
  RestitutionDetails _mapperRestitutionToDetails(Map<String, dynamic> data) {
    return RestitutionDetails(
      id: data['id'] ?? '',
      date: (data['dateRestitution'] as Timestamp).toDate(),
      numeroLot: data['numeroLot'] ?? '',
      typeEmballage: data['typeEmballage'] ?? '',
      quantiteRestituee: data['quantiteRestituee'] ?? 0,
      poidsRestitue: (data['poidsRestitue'] ?? 0.0).toDouble(),
      motif: data['motif'] ?? '',
      valideAdmin: false,
    );
  }

  /// Mapper une perte vers PerteDetails
  PerteDetails _mapperPerteToDetails(Map<String, dynamic> data) {
    return PerteDetails(
      id: data['id'] ?? '',
      date: (data['datePerte'] as Timestamp).toDate(),
      numeroLot: data['numeroLot'] ?? '',
      typeEmballage: data['typeEmballage'] ?? '',
      quantitePerdue: data['quantitePerdue'] ?? 0,
      poidsPerdu: (data['poidsPerdu'] ?? 0.0).toDouble(),
      motif: data['motif'] ?? '',
      valeurPerte: (data['valeurPerte'] ?? 0.0).toDouble(),
      valideAdmin: false,
    );
  }

  /// Calculer le résumé financier
  ResumeFinancier _calculerResumeFinancier(
    List<VenteDetails> ventes,
    List<RestitutionDetails> restitutions,
    List<PerteDetails> pertes,
  ) {
    double totalVentes = 0;
    double totalVentesPayees = 0;
    double totalCredits = 0;
    double espece = 0;
    double mobile = 0;
    double autres = 0;

    for (final vente in ventes) {
      totalVentes += vente.montantTotal;
      totalVentesPayees += vente.montantPaye;
      totalCredits += vente.montantRestant;

      switch (vente.modePaiement) {
        case ModePaiement.espece:
          espece += vente.montantPaye;
          break;
        case ModePaiement.mobile:
          mobile += vente.montantPaye;
          break;
        default:
          autres += vente.montantPaye;
      }
    }

    final totalRestitutions =
        restitutions.fold<double>(0, (sum, r) => sum + r.poidsRestitue);
    final totalPertes = pertes.fold<double>(0, (sum, p) => sum + p.valeurPerte);
    final chiffreAffairesNet = totalVentes - totalRestitutions - totalPertes;
    final tauxConversion = (totalVentes + totalRestitutions + totalPertes) > 0
        ? (totalVentes / (totalVentes + totalRestitutions + totalPertes)) * 100
        : 0.0;

    return ResumeFinancier(
      totalVentes: totalVentes,
      totalVentesPayees: totalVentesPayees,
      totalCredits: totalCredits,
      totalRestitutions: totalRestitutions,
      totalPertes: totalPertes,
      chiffreAffairesNet: chiffreAffairesNet,
      espece: espece,
      mobile: mobile,
      autres: autres,
      tauxConversion: tauxConversion,
    );
  }

  /// Extraire les crédits des ventes
  List<CreditDetails> _extraireCreditsDeMesVentes(List<VenteDetails> ventes) {
    return ventes
        .where((v) => v.montantRestant > 0)
        .map((v) => CreditDetails(
              id: 'CREDIT_${v.id}',
              venteId: v.id,
              dateCredit: v.date,
              montantCredit: v.montantRestant,
              montantRembourse: 0,
              montantRestant: v.montantRestant,
              statut: StatutCredit.enAttente,
              clientNom: v.clientNom,
              valideAdmin: false,
            ))
        .toList();
  }

  /// Extraire les paiements des ventes
  List<PaiementDetails> _extrairePaiementsDeMesVentes(
      List<VenteDetails> ventes) {
    return ventes
        .where((v) => v.montantPaye > 0)
        .map((v) => PaiementDetails(
              id: 'PAY_${v.id}',
              venteId: v.id,
              date: v.date,
              montant: v.montantPaye,
              mode: v.modePaiement,
              valideAdmin: false,
            ))
        .toList();
  }

  /// Calculer les quantités d'origine
  Future<QuantitesOrigine> _calculerQuantitesOrigine(
      String site, String prelevementId) async {
    // TODO: Récupérer les données d'attribution originale
    // Pour l'instant, retourner des valeurs par défaut
    return const QuantitesOrigine(
      poidsOriginalAttribue: 100,
      valeurOriginaleMiel: 50000,
      poidsVendu: 80,
      poidsRestitue: 10,
      poidsPerdu: 5,
      poidsRestant: 5,
    );
  }

  /// Valider tous les éléments d'une transaction
  Future<void> _validerElementsTransaction(String transactionId) async {
    debugPrint(
        '🔔 [_validerElementsTransaction] start for transactionId=$transactionId');

    if (transactionId.trim().isEmpty) {
      debugPrint(
          '⚠️ [_validerElementsTransaction] empty transactionId, skipping');
      return;
    }

    final txnRef =
        _firestore.collection(_collectionTransactions).doc(transactionId);
    final txnSnap = await txnRef.get();
    if (!txnSnap.exists) {
      debugPrint(
          '⚠️ [_validerElementsTransaction] transaction not found for id=$transactionId');
      return;
    }
    final txn = TransactionCommerciale.fromMap(txnSnap.data()!);
    final expiryTs =
        Timestamp.fromDate(DateTime.now().add(const Duration(hours: 5)));

    // Construire versions validées
    final ventesValides = txn.ventes
        .map((v) => VenteDetails(
              id: v.id,
              date: v.date,
              clientNom: v.clientNom,
              clientTelephone: v.clientTelephone,
              produits: v.produits,
              montantTotal: v.montantTotal,
              montantPaye: v.montantPaye,
              montantRestant: v.montantRestant,
              modePaiement: v.modePaiement,
              statut: v.statut,
              valideAdmin: true,
            ).toMap())
        .toList();

    final restitutionsValides = txn.restitutions
        .map((r) => RestitutionDetails(
              id: r.id,
              date: r.date,
              numeroLot: r.numeroLot,
              typeEmballage: r.typeEmballage,
              quantiteRestituee: r.quantiteRestituee,
              poidsRestitue: r.poidsRestitue,
              motif: r.motif,
              valideAdmin: true,
            ).toMap())
        .toList();

    final pertesValides = txn.pertes
        .map((p) => PerteDetails(
              id: p.id,
              date: p.date,
              numeroLot: p.numeroLot,
              typeEmballage: p.typeEmballage,
              quantitePerdue: p.quantitePerdue,
              poidsPerdu: p.poidsPerdu,
              motif: p.motif,
              valeurPerte: p.valeurPerte,
              valideAdmin: true,
            ).toMap())
        .toList();

    // Ensure each element contains the validation expiry timestamp so UIs
    // can persist hide timers between reloads.
    for (final m in ventesValides) {
      m['validationExpiry'] = expiryTs;
      m['validationExpiryEspace'] =
          Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24)));
    }
    for (final m in restitutionsValides) {
      m['validationExpiry'] = expiryTs;
      m['validationExpiryEspace'] =
          Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24)));
    }
    for (final m in pertesValides) {
      m['validationExpiry'] = expiryTs;
      m['validationExpiryEspace'] =
          Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24)));
    }

    final creditsValides = txn.credits
        .map((c) => CreditDetails(
              id: c.id,
              venteId: c.venteId,
              dateCredit: c.dateCredit,
              dateRemboursement: c.dateRemboursement,
              montantCredit: c.montantCredit,
              montantRembourse: c.montantRembourse,
              montantRestant: c.montantRestant,
              statut: c.statut,
              clientNom: c.clientNom,
              valideAdmin: true,
            ).toMap())
        .toList();

    final paiementsValides = txn.paiements
        .map((p) => PaiementDetails(
              id: p.id,
              venteId: p.venteId,
              creditId: p.creditId,
              date: p.date,
              montant: p.montant,
              mode: p.mode,
              reference: p.reference,
              valideAdmin: true,
            ).toMap())
        .toList();

    // Mettre à jour la transaction
    await txnRef.update({
      'ventes': ventesValides,
      'restitutions': restitutionsValides,
      'pertes': pertesValides,
      'credits': creditsValides,
      'paiements': paiementsValides,
    });

    debugPrint(
        '✅ [_validerElementsTransaction] all elements marked validated for $transactionId');

    // Écrire la dateValidation sur le lock d'attribution (si présent)
    try {
      final site = txn.site;
      final prelevementId = txn.prelevementId;
      if (site.isNotEmpty && prelevementId.isNotEmpty) {
        final attributionId = prelevementId.replaceAll('_prelevement_temp', '');
        final lockRef = _firestore
            .collection('Vente')
            .doc(site)
            .collection('locks_attributions')
            .doc(attributionId);
        await lockRef.set({
          'enAttenteValidation': false,
          'dateValidation': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Also clear prelevement flag
        await _firestore
            .collection('Vente')
            .doc(site)
            .collection('prelevements')
            .doc(prelevementId)
            .set({
          'enAttenteValidation': false,
          'dateValidation': FieldValue.serverTimestamp()
        }, SetOptions(merge: true));

        debugPrint(
            '✅ [_validerElementsTransaction] wrote dateValidation to lock $attributionId (site=$site) and prelevement $prelevementId');
      }
    } catch (e) {
      debugPrint(
          '⚠️ [_validerElementsTransaction] failed to update lock/prelevement: $e');
    }
  }

  /// Admin - Obtenir les statistiques générales
  Stream<Map<String, dynamic>> getStatistiquesAdmin() {
    return _firestore
        .collection(_collectionTransactions)
        .snapshots()
        .map((snapshot) {
      int totalTransactions = snapshot.docs.length;
      int enAttente = 0;
      int recuperees = 0;
      int validees = 0;
      double chiffreAffairesTotal = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final statut = data['statut'] as String? ?? '';
        final resume = data['resumeFinancier'] as Map<String, dynamic>? ?? {};

        switch (statut) {
          case 'termineEnAttente':
            enAttente++;
            break;
          case 'recupereeCaisse':
            recuperees++;
            break;
          case 'valideeAdmin':
            validees++;
            break;
        }

        chiffreAffairesTotal +=
            (resume['chiffreAffairesNet'] ?? 0.0).toDouble();
      }

      return {
        'totalTransactions': totalTransactions,
        'enAttente': enAttente,
        'recuperees': recuperees,
        'validees': validees,
        'chiffreAffairesTotal': chiffreAffairesTotal,
      };
    });
  }

  /// Admin - Obtenir toutes les transactions en attente
  Stream<List<TransactionCommerciale>> getTransactionsEnAttenteAdmin() {
    return _firestore
        .collection(_collectionTransactions)
        .where('statut',
            isEqualTo: StatutTransactionCommerciale.termineEnAttente.name)
        .orderBy('dateTerminee', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionCommerciale.fromMap(doc.data()))
            .toList());
  }

  /// Admin - Obtenir toutes les transactions récupérées
  Stream<List<TransactionCommerciale>> getTransactionsRecupereesAdmin() {
    return _firestore
        .collection(_collectionTransactions)
        .where('statut',
            isEqualTo: StatutTransactionCommerciale.recupereeCaisse.name)
        .orderBy('dateRecuperationCaisse', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionCommerciale.fromMap(doc.data()))
            .toList());
  }

  /// Admin - Obtenir toutes les transactions validées
  Stream<List<TransactionCommerciale>> getTransactionsValideesAdmin() {
    return _firestore
        .collection(_collectionTransactions)
        .where('statut',
            isEqualTo: StatutTransactionCommerciale.valideeAdmin.name)
        .orderBy('dateValidation', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionCommerciale.fromMap(doc.data()))
            .toList());
  }

  /// Admin - Valider une transaction
  Future<void> validerTransactionAdmin(
      String transactionId, String adminNom) async {
    try {
      if (transactionId.trim().isEmpty) {
        print(
            '⚠️ validerTransactionAdmin called with empty transactionId, skipping');
        return;
      }

      await _firestore
          .collection(_collectionTransactions)
          .doc(transactionId)
          .update({
        'statut': StatutTransactionCommerciale.valideeAdmin.name,
        'dateValidation': Timestamp.fromDate(DateTime.now()),
        'validePar': adminNom,
      });

      // Déverrouiller l'attribution liée
      final txnDoc = await _firestore
          .collection(_collectionTransactions)
          .doc(transactionId)
          .get();
      if (txnDoc.exists) {
        final data = txnDoc.data()!;
        final site = data['site'] as String? ?? '';
        final prelevementId = data['prelevementId'] as String? ?? '';
        if (site.isNotEmpty && prelevementId.isNotEmpty) {
          await _clearLocksForSiteAndPrelevement(site, prelevementId);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Admin - Rejeter une transaction
  Future<void> rejeterTransactionAdmin(
      String transactionId, String adminNom, String motif) async {
    try {
      await _firestore
          .collection(_collectionTransactions)
          .doc(transactionId)
          .update({
        'statut': StatutTransactionCommerciale.rejetee.name,
        'dateRejet': Timestamp.fromDate(DateTime.now()),
        'rejetePar': adminNom,
        'motifRejet': motif,
      });

      // Déverrouiller également pour permettre corrections
      final txnDoc = await _firestore
          .collection(_collectionTransactions)
          .doc(transactionId)
          .get();
      if (txnDoc.exists) {
        final data = txnDoc.data()!;
        final site = data['site'] as String? ?? '';
        final prelevementId = data['prelevementId'] as String? ?? '';
        if (site.isNotEmpty && prelevementId.isNotEmpty) {
          await _clearLocksForSiteAndPrelevement(site, prelevementId);
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}

/// Données temporaires pour construction de transaction
class _DonneesPrelevement {
  final ResumeFinancier resumeFinancier;
  final List<VenteDetails> ventes;
  final List<RestitutionDetails> restitutions;
  final List<PerteDetails> pertes;
  final List<CreditDetails> credits;
  final List<PaiementDetails> paiements;
  final QuantitesOrigine quantitesOrigine;

  _DonneesPrelevement({
    required this.resumeFinancier,
    required this.ventes,
    required this.restitutions,
    required this.pertes,
    required this.credits,
    required this.paiements,
    required this.quantitesOrigine,
  });
}
