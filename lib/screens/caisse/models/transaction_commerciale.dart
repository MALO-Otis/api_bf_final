import '../../vente/models/vente_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🏪 MODÈLE COMPLET DE TRANSACTION COMMERCIALE
///
/// Structure centralisée pour gérer toutes les transactions d'un commercial
/// incluant ventes, pertes, restitutions, crédits et leur validation

class TransactionCommerciale {
  final String id; // ID unique de la transaction
  final String site;
  final String commercialId;
  final String commercialNom;
  final String prelevementId; // Référence à l'attribution/prélèvement
  final DateTime dateCreation;
  final DateTime? dateTerminee; // Quand le commercial a cliqué "Terminer"
  final DateTime? dateValidation; // Quand l'admin a validé

  // État de la transaction
  final StatutTransactionCommerciale statut;
  final String? validePar; // ID de l'utilisateur qui a validé
  final String? observations;

  // Données financières consolidées
  final ResumeFinancier resumeFinancier;

  // Détails des activités
  final List<VenteDetails> ventes;
  final List<RestitutionDetails> restitutions;
  final List<PerteDetails> pertes;
  final List<CreditDetails> credits;
  final List<PaiementDetails> paiements;

  // Quantités et prix d'origine (pour suivi des marges)
  final QuantitesOrigine quantitesOrigine;

  const TransactionCommerciale({
    required this.id,
    required this.site,
    required this.commercialId,
    required this.commercialNom,
    required this.prelevementId,
    required this.dateCreation,
    this.dateTerminee,
    this.dateValidation,
    required this.statut,
    this.validePar,
    this.observations,
    required this.resumeFinancier,
    required this.ventes,
    required this.restitutions,
    required this.pertes,
    required this.credits,
    required this.paiements,
    required this.quantitesOrigine,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'site': site,
      'commercialId': commercialId,
      'commercialNom': commercialNom,
      'prelevementId': prelevementId,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'dateTerminee':
          dateTerminee != null ? Timestamp.fromDate(dateTerminee!) : null,
      'dateValidation':
          dateValidation != null ? Timestamp.fromDate(dateValidation!) : null,
      'statut': statut.name,
      'validePar': validePar,
      'observations': observations,
      'resumeFinancier': resumeFinancier.toMap(),
      'ventes': ventes.map((v) => v.toMap()).toList(),
      'restitutions': restitutions.map((r) => r.toMap()).toList(),
      'pertes': pertes.map((p) => p.toMap()).toList(),
      'credits': credits.map((c) => c.toMap()).toList(),
      'paiements': paiements.map((p) => p.toMap()).toList(),
      'quantitesOrigine': quantitesOrigine.toMap(),
    };
  }

  factory TransactionCommerciale.fromMap(Map<String, dynamic> map) {
    return TransactionCommerciale(
      id: map['id'] ?? '',
      site: map['site'] ?? '',
      commercialId: map['commercialId'] ?? '',
      commercialNom: map['commercialNom'] ?? '',
      prelevementId: map['prelevementId'] ?? '',
      dateCreation: (map['dateCreation'] as Timestamp).toDate(),
      dateTerminee: (map['dateTerminee'] as Timestamp?)?.toDate(),
      dateValidation: (map['dateValidation'] as Timestamp?)?.toDate(),
      statut: StatutTransactionCommerciale.values.firstWhere(
        (s) => s.name == map['statut'],
        orElse: () => StatutTransactionCommerciale.enCours,
      ),
      validePar: map['validePar'],
      observations: map['observations'],
      resumeFinancier: ResumeFinancier.fromMap(map['resumeFinancier'] ?? {}),
      ventes: (map['ventes'] as List<dynamic>? ?? [])
          .map((v) => VenteDetails.fromMap(v))
          .toList(),
      restitutions: (map['restitutions'] as List<dynamic>? ?? [])
          .map((r) => RestitutionDetails.fromMap(r))
          .toList(),
      pertes: (map['pertes'] as List<dynamic>? ?? [])
          .map((p) => PerteDetails.fromMap(p))
          .toList(),
      credits: (map['credits'] as List<dynamic>? ?? [])
          .map((c) => CreditDetails.fromMap(c))
          .toList(),
      paiements: (map['paiements'] as List<dynamic>? ?? [])
          .map((p) => PaiementDetails.fromMap(p))
          .toList(),
      quantitesOrigine: QuantitesOrigine.fromMap(map['quantitesOrigine'] ?? {}),
    );
  }

  /// Copie avec modifications
  TransactionCommerciale copyWith({
    StatutTransactionCommerciale? statut,
    DateTime? dateTerminee,
    DateTime? dateValidation,
    String? validePar,
    String? observations,
  }) {
    return TransactionCommerciale(
      id: id,
      site: site,
      commercialId: commercialId,
      commercialNom: commercialNom,
      prelevementId: prelevementId,
      dateCreation: dateCreation,
      dateTerminee: dateTerminee ?? this.dateTerminee,
      dateValidation: dateValidation ?? this.dateValidation,
      statut: statut ?? this.statut,
      validePar: validePar ?? this.validePar,
      observations: observations ?? this.observations,
      resumeFinancier: resumeFinancier,
      ventes: ventes,
      restitutions: restitutions,
      pertes: pertes,
      credits: credits,
      paiements: paiements,
      quantitesOrigine: quantitesOrigine,
    );
  }
}

/// États possibles d'une transaction commerciale
enum StatutTransactionCommerciale {
  enCours, // Commercial travaille encore dessus
  termineEnAttente, // Commercial a cliqué "Terminer", en attente de validation caisse
  recupereeCaisse, // Caissier a récupéré le prélèvement
  valideeAdmin, // Admin a validé complètement
  rejetee, // Rejetée par l'admin ou la caisse
}

/// Résumé financier consolidé
class ResumeFinancier {
  final double totalVentes;
  final double totalVentesPayees;
  final double totalCredits;
  final double totalRestitutions;
  final double totalPertes;
  final double chiffreAffairesNet; // Ventes - Restitutions - Pertes
  final double espece;
  final double mobile;
  final double autres;
  final double tauxConversion; // Ventes / (Ventes + Restitutions + Pertes)

  const ResumeFinancier({
    required this.totalVentes,
    required this.totalVentesPayees,
    required this.totalCredits,
    required this.totalRestitutions,
    required this.totalPertes,
    required this.chiffreAffairesNet,
    required this.espece,
    required this.mobile,
    required this.autres,
    required this.tauxConversion,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalVentes': totalVentes,
      'totalVentesPayees': totalVentesPayees,
      'totalCredits': totalCredits,
      'totalRestitutions': totalRestitutions,
      'totalPertes': totalPertes,
      'chiffreAffairesNet': chiffreAffairesNet,
      'espece': espece,
      'mobile': mobile,
      'autres': autres,
      'tauxConversion': tauxConversion,
    };
  }

  factory ResumeFinancier.fromMap(Map<String, dynamic> map) {
    return ResumeFinancier(
      totalVentes: (map['totalVentes'] ?? 0.0).toDouble(),
      totalVentesPayees: (map['totalVentesPayees'] ?? 0.0).toDouble(),
      totalCredits: (map['totalCredits'] ?? 0.0).toDouble(),
      totalRestitutions: (map['totalRestitutions'] ?? 0.0).toDouble(),
      totalPertes: (map['totalPertes'] ?? 0.0).toDouble(),
      chiffreAffairesNet: (map['chiffreAffairesNet'] ?? 0.0).toDouble(),
      espece: (map['espece'] ?? 0.0).toDouble(),
      mobile: (map['mobile'] ?? 0.0).toDouble(),
      autres: (map['autres'] ?? 0.0).toDouble(),
      tauxConversion: (map['tauxConversion'] ?? 0.0).toDouble(),
    );
  }
}

/// Détails d'une vente
class VenteDetails {
  final String id;
  final DateTime date;
  final String clientNom;
  final String clientTelephone;
  final List<ProduitVenteDetail> produits;
  final double montantTotal;
  final double montantPaye;
  final double montantRestant;
  final ModePaiement modePaiement;
  final StatutVente statut;
  final bool valideAdmin;

  const VenteDetails({
    required this.id,
    required this.date,
    required this.clientNom,
    required this.clientTelephone,
    required this.produits,
    required this.montantTotal,
    required this.montantPaye,
    required this.montantRestant,
    required this.modePaiement,
    required this.statut,
    required this.valideAdmin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'clientNom': clientNom,
      'clientTelephone': clientTelephone,
      'produits': produits.map((p) => p.toMap()).toList(),
      'montantTotal': montantTotal,
      'montantPaye': montantPaye,
      'montantRestant': montantRestant,
      'modePaiement': modePaiement.name,
      'statut': statut.name,
      'valideAdmin': valideAdmin,
    };
  }

  factory VenteDetails.fromMap(Map<String, dynamic> map) {
    return VenteDetails(
      id: map['id'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      clientNom: map['clientNom'] ?? '',
      clientTelephone: map['clientTelephone'] ?? '',
      produits: (map['produits'] as List<dynamic>? ?? [])
          .map((p) => ProduitVenteDetail.fromMap(p))
          .toList(),
      montantTotal: (map['montantTotal'] ?? 0.0).toDouble(),
      montantPaye: (map['montantPaye'] ?? 0.0).toDouble(),
      montantRestant: (map['montantRestant'] ?? 0.0).toDouble(),
      modePaiement: ModePaiement.values.firstWhere(
        (m) => m.name == map['modePaiement'],
        orElse: () => ModePaiement.espece,
      ),
      statut: StatutVente.values.firstWhere(
        (s) => s.name == map['statut'],
        orElse: () => StatutVente.creditEnAttente,
      ),
      valideAdmin: map['valideAdmin'] ?? false,
    );
  }
}

/// Détail d'un produit dans une vente
class ProduitVenteDetail {
  final String produitId;
  final String numeroLot;
  final String typeEmballage;
  final double contenanceKg;
  final int quantiteVendue;
  final double prixUnitaire;
  final double prixVente;
  final double montantTotal;
  final double prixOrigineMiel; // Prix d'achat du miel brut

  const ProduitVenteDetail({
    required this.produitId,
    required this.numeroLot,
    required this.typeEmballage,
    required this.contenanceKg,
    required this.quantiteVendue,
    required this.prixUnitaire,
    required this.prixVente,
    required this.montantTotal,
    required this.prixOrigineMiel,
  });

  Map<String, dynamic> toMap() {
    return {
      'produitId': produitId,
      'numeroLot': numeroLot,
      'typeEmballage': typeEmballage,
      'contenanceKg': contenanceKg,
      'quantiteVendue': quantiteVendue,
      'prixUnitaire': prixUnitaire,
      'prixVente': prixVente,
      'montantTotal': montantTotal,
      'prixOrigineMiel': prixOrigineMiel,
    };
  }

  factory ProduitVenteDetail.fromMap(Map<String, dynamic> map) {
    return ProduitVenteDetail(
      produitId: map['produitId'] ?? '',
      numeroLot: map['numeroLot'] ?? '',
      typeEmballage: map['typeEmballage'] ?? '',
      contenanceKg: (map['contenanceKg'] ?? 0.0).toDouble(),
      quantiteVendue: map['quantiteVendue'] ?? 0,
      prixUnitaire: (map['prixUnitaire'] ?? 0.0).toDouble(),
      prixVente: (map['prixVente'] ?? 0.0).toDouble(),
      montantTotal: (map['montantTotal'] ?? 0.0).toDouble(),
      prixOrigineMiel: (map['prixOrigineMiel'] ?? 0.0).toDouble(),
    );
  }

  /// Calcul de la marge
  double get marge => montantTotal - (prixOrigineMiel * quantiteVendue);
  double get tauxMarge => prixOrigineMiel > 0
      ? (marge / (prixOrigineMiel * quantiteVendue)) * 100
      : 0;
}

/// Détails d'une restitution
class RestitutionDetails {
  final String id;
  final DateTime date;
  final String numeroLot;
  final String typeEmballage;
  final int quantiteRestituee;
  final double poidsRestitue;
  final String motif;
  final bool valideAdmin;

  const RestitutionDetails({
    required this.id,
    required this.date,
    required this.numeroLot,
    required this.typeEmballage,
    required this.quantiteRestituee,
    required this.poidsRestitue,
    required this.motif,
    required this.valideAdmin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'numeroLot': numeroLot,
      'typeEmballage': typeEmballage,
      'quantiteRestituee': quantiteRestituee,
      'poidsRestitue': poidsRestitue,
      'motif': motif,
      'valideAdmin': valideAdmin,
    };
  }

  factory RestitutionDetails.fromMap(Map<String, dynamic> map) {
    return RestitutionDetails(
      id: map['id'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      numeroLot: map['numeroLot'] ?? '',
      typeEmballage: map['typeEmballage'] ?? '',
      quantiteRestituee: map['quantiteRestituee'] ?? 0,
      poidsRestitue: (map['poidsRestitue'] ?? 0.0).toDouble(),
      motif: map['motif'] ?? '',
      valideAdmin: map['valideAdmin'] ?? false,
    );
  }
}

/// Détails d'une perte
class PerteDetails {
  final String id;
  final DateTime date;
  final String numeroLot;
  final String typeEmballage;
  final int quantitePerdue;
  final double poidsPerdu;
  final String motif;
  final double valeurPerte; // Valeur estimée de la perte
  final bool valideAdmin;

  const PerteDetails({
    required this.id,
    required this.date,
    required this.numeroLot,
    required this.typeEmballage,
    required this.quantitePerdue,
    required this.poidsPerdu,
    required this.motif,
    required this.valeurPerte,
    required this.valideAdmin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'numeroLot': numeroLot,
      'typeEmballage': typeEmballage,
      'quantitePerdue': quantitePerdue,
      'poidsPerdu': poidsPerdu,
      'motif': motif,
      'valeurPerte': valeurPerte,
      'valideAdmin': valideAdmin,
    };
  }

  factory PerteDetails.fromMap(Map<String, dynamic> map) {
    return PerteDetails(
      id: map['id'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      numeroLot: map['numeroLot'] ?? '',
      typeEmballage: map['typeEmballage'] ?? '',
      quantitePerdue: map['quantitePerdue'] ?? 0,
      poidsPerdu: (map['poidsPerdu'] ?? 0.0).toDouble(),
      motif: map['motif'] ?? '',
      valeurPerte: (map['valeurPerte'] ?? 0.0).toDouble(),
      valideAdmin: map['valideAdmin'] ?? false,
    );
  }
}

/// Détails d'un crédit
class CreditDetails {
  final String id;
  final String venteId; // Référence à la vente concernée
  final DateTime dateCredit;
  final DateTime? dateRemboursement;
  final double montantCredit;
  final double montantRembourse;
  final double montantRestant;
  final StatutCredit statut;
  final String clientNom;
  final bool valideAdmin;

  const CreditDetails({
    required this.id,
    required this.venteId,
    required this.dateCredit,
    this.dateRemboursement,
    required this.montantCredit,
    required this.montantRembourse,
    required this.montantRestant,
    required this.statut,
    required this.clientNom,
    required this.valideAdmin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'venteId': venteId,
      'dateCredit': Timestamp.fromDate(dateCredit),
      'dateRemboursement': dateRemboursement != null
          ? Timestamp.fromDate(dateRemboursement!)
          : null,
      'montantCredit': montantCredit,
      'montantRembourse': montantRembourse,
      'montantRestant': montantRestant,
      'statut': statut.name,
      'clientNom': clientNom,
      'valideAdmin': valideAdmin,
    };
  }

  factory CreditDetails.fromMap(Map<String, dynamic> map) {
    return CreditDetails(
      id: map['id'] ?? '',
      venteId: map['venteId'] ?? '',
      dateCredit: (map['dateCredit'] as Timestamp).toDate(),
      dateRemboursement: (map['dateRemboursement'] as Timestamp?)?.toDate(),
      montantCredit: (map['montantCredit'] ?? 0.0).toDouble(),
      montantRembourse: (map['montantRembourse'] ?? 0.0).toDouble(),
      montantRestant: (map['montantRestant'] ?? 0.0).toDouble(),
      statut: StatutCredit.values.firstWhere(
        (s) => s.name == map['statut'],
        orElse: () => StatutCredit.enAttente,
      ),
      clientNom: map['clientNom'] ?? '',
      valideAdmin: map['valideAdmin'] ?? false,
    );
  }
}

/// États d'un crédit
enum StatutCredit {
  enAttente, // Crédit accordé, en attente de remboursement
  partiel, // Partiellement remboursé
  rembourse, // Complètement remboursé
  annule, // Annulé/effacé
}

/// Détails d'un paiement
class PaiementDetails {
  final String id;
  final String? venteId; // null si c'est un remboursement de crédit
  final String? creditId; // null si c'est un paiement de vente
  final DateTime date;
  final double montant;
  final ModePaiement mode;
  final String? reference; // Numéro de transaction mobile money
  final bool valideAdmin;

  const PaiementDetails({
    required this.id,
    this.venteId,
    this.creditId,
    required this.date,
    required this.montant,
    required this.mode,
    this.reference,
    required this.valideAdmin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'venteId': venteId,
      'creditId': creditId,
      'date': Timestamp.fromDate(date),
      'montant': montant,
      'mode': mode.name,
      'reference': reference,
      'valideAdmin': valideAdmin,
    };
  }

  factory PaiementDetails.fromMap(Map<String, dynamic> map) {
    return PaiementDetails(
      id: map['id'] ?? '',
      venteId: map['venteId'],
      creditId: map['creditId'],
      date: (map['date'] as Timestamp).toDate(),
      montant: (map['montant'] ?? 0.0).toDouble(),
      mode: ModePaiement.values.firstWhere(
        (m) => m.name == map['mode'],
        orElse: () => ModePaiement.espece,
      ),
      reference: map['reference'],
      valideAdmin: map['valideAdmin'] ?? false,
    );
  }
}

/// Quantités et prix d'origine pour suivi des marges
class QuantitesOrigine {
  final double poidsOriginalAttribue; // Poids total attribué au commercial
  final double valeurOriginaleMiel; // Valeur d'achat du miel brut
  final double poidsVendu;
  final double poidsRestitue;
  final double poidsPerdu;
  final double poidsRestant; // Non encore traité

  const QuantitesOrigine({
    required this.poidsOriginalAttribue,
    required this.valeurOriginaleMiel,
    required this.poidsVendu,
    required this.poidsRestitue,
    required this.poidsPerdu,
    required this.poidsRestant,
  });

  Map<String, dynamic> toMap() {
    return {
      'poidsOriginalAttribue': poidsOriginalAttribue,
      'valeurOriginaleMiel': valeurOriginaleMiel,
      'poidsVendu': poidsVendu,
      'poidsRestitue': poidsRestitue,
      'poidsPerdu': poidsPerdu,
      'poidsRestant': poidsRestant,
    };
  }

  factory QuantitesOrigine.fromMap(Map<String, dynamic> map) {
    return QuantitesOrigine(
      poidsOriginalAttribue: (map['poidsOriginalAttribue'] ?? 0.0).toDouble(),
      valeurOriginaleMiel: (map['valeurOriginaleMiel'] ?? 0.0).toDouble(),
      poidsVendu: (map['poidsVendu'] ?? 0.0).toDouble(),
      poidsRestitue: (map['poidsRestitue'] ?? 0.0).toDouble(),
      poidsPerdu: (map['poidsPerdu'] ?? 0.0).toDouble(),
      poidsRestant: (map['poidsRestant'] ?? 0.0).toDouble(),
    );
  }

  /// Calculs dérivés
  double get tauxUtilisation => poidsOriginalAttribue > 0
      ? ((poidsVendu + poidsRestitue + poidsPerdu) / poidsOriginalAttribue) *
          100
      : 0;

  double get tauxConversion => (poidsVendu + poidsRestitue + poidsPerdu) > 0
      ? (poidsVendu / (poidsVendu + poidsRestitue + poidsPerdu)) * 100
      : 0;
}
