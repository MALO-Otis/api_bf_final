import 'package:get/get.dart';
import '../../vente/models/vente_models.dart';
import '../models/transaction_commerciale.dart';
import '../../../authentication/user_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🏪 SERVICE DE GESTION DES TRANSACTIONS COMMERCIALES
///
/// Service centralisé pour gérer le flux complet:
/// Commercial termine → Notification caisse → Validation admin

class TransactionCommercialeService extends GetxService {
  static TransactionCommercialeService get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserSession _userSession = Get.find<UserSession>();

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
    await _firestore
        .collection(_collectionTransactions)
        .doc(transactionId)
        .update({
      'statut': StatutTransactionCommerciale.valideeAdmin.name,
      'validePar': validePar,
      'dateValidation': Timestamp.fromDate(DateTime.now()),
    });

    // Valider tous les éléments individuels
    await _validerElementsTransaction(transactionId);
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
  }

  /// Valide un élément spécifique (vente, restitution, perte, crédit, paiement)
  Future<void> validerElement({
    required String transactionId,
    required String
        elementType, // 'vente', 'restitution', 'perte', 'credit', 'paiement'
    required String elementId,
  }) async {
    final transaction = await _firestore
        .collection(_collectionTransactions)
        .doc(transactionId)
        .get();

    if (!transaction.exists) return;

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
        break;

      // Implémenter pour les autres types d'éléments...
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
    // TODO: Implémenter la validation automatique de tous les éléments
    // Marquer tous les ventes, restitutions, pertes, crédits et paiements comme validés
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
      await _firestore
          .collection(_collectionTransactions)
          .doc(transactionId)
          .update({
        'statut': StatutTransactionCommerciale.valideeAdmin.name,
        'dateValidation': Timestamp.fromDate(DateTime.now()),
        'validePar': adminNom,
      });
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
