/// 🛒 MODÈLES DE DONNÉES POUR LE MODULE DE VENTE
///
/// Gestion complète des ventes, prélèvements, restitutions et pertes

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// 📦 PRODUIT CONDITIONNÉ DISPONIBLE POUR LA VENTE
class ProduitConditionne {
  final String id;
  final String numeroLot;
  final String codeContenant;
  final String producteur;
  final String village;
  final String siteOrigine;
  final String predominanceFlorale;
  final String typeEmballage;
  final double contenanceKg;
  final int quantiteDisponible;
  final int quantiteInitiale;
  final double prixUnitaire;
  final DateTime dateConditionnement;
  final DateTime dateExpiration;
  final StatutProduit statut;
  final String? observations;

  const ProduitConditionne({
    required this.id,
    required this.numeroLot,
    required this.codeContenant,
    required this.producteur,
    required this.village,
    required this.siteOrigine,
    required this.predominanceFlorale,
    required this.typeEmballage,
    required this.contenanceKg,
    required this.quantiteDisponible,
    required this.quantiteInitiale,
    required this.prixUnitaire,
    required this.dateConditionnement,
    required this.dateExpiration,
    required this.statut,
    this.observations,
  });

  factory ProduitConditionne.fromMap(Map<String, dynamic> map) {
    return ProduitConditionne(
      id: map['id'] ?? '',
      numeroLot: map['numeroLot'] ?? '',
      codeContenant: map['codeContenant'] ?? '',
      producteur: map['producteur'] ?? '',
      village: map['village'] ?? '',
      siteOrigine: map['siteOrigine'] ?? '',
      predominanceFlorale: map['predominanceFlorale'] ?? '',
      typeEmballage: map['typeEmballage'] ?? '',
      contenanceKg: (map['contenanceKg'] ?? 0.0).toDouble(),
      quantiteDisponible: map['quantiteDisponible'] ?? 0,
      quantiteInitiale: map['quantiteInitiale'] ?? 0,
      prixUnitaire: (map['prixUnitaire'] ?? 0.0).toDouble(),
      dateConditionnement:
          (map['dateConditionnement'] as Timestamp?)?.toDate() ??
              DateTime.now(),
      dateExpiration:
          (map['dateExpiration'] as Timestamp?)?.toDate() ?? DateTime.now(),
      statut: StatutProduit.values.firstWhere(
        (s) => s.name == map['statut'],
        orElse: () => StatutProduit.disponible,
      ),
      observations: map['observations'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numeroLot': numeroLot,
      'codeContenant': codeContenant,
      'producteur': producteur,
      'village': village,
      'siteOrigine': siteOrigine,
      'predominanceFlorale': predominanceFlorale,
      'typeEmballage': typeEmballage,
      'contenanceKg': contenanceKg,
      'quantiteDisponible': quantiteDisponible,
      'quantiteInitiale': quantiteInitiale,
      'prixUnitaire': prixUnitaire,
      'dateConditionnement': Timestamp.fromDate(dateConditionnement),
      'dateExpiration': Timestamp.fromDate(dateExpiration),
      'statut': statut.name,
      'observations': observations,
    };
  }

  double get valeurTotale => quantiteDisponible * prixUnitaire;
  double get tauxVente => quantiteInitiale > 0
      ? ((quantiteInitiale - quantiteDisponible) / quantiteInitiale) * 100
      : 0.0;
}

/// 📋 PRÉLÈVEMENT POUR UN COMMERCIAL
class Prelevement {
  final String id;
  final String commercialId;
  final String commercialNom;
  final String magazinierId;
  final String magazinierNom;
  final DateTime datePrelevement;
  final List<ProduitPreleve> produits;
  final double valeurTotale;
  final StatutPrelevement statut;
  final String? observations;
  final DateTime? dateRetour;

  const Prelevement({
    required this.id,
    required this.commercialId,
    required this.commercialNom,
    required this.magazinierId,
    required this.magazinierNom,
    required this.datePrelevement,
    required this.produits,
    required this.valeurTotale,
    required this.statut,
    this.observations,
    this.dateRetour,
  });

  factory Prelevement.fromMap(Map<String, dynamic> map) {
    return Prelevement(
      id: map['id'] ?? '',
      commercialId: map['commercialId'] ?? '',
      commercialNom: map['commercialNom'] ?? '',
      magazinierId: map['magazinierId'] ?? '',
      magazinierNom: map['magazinierNom'] ?? '',
      datePrelevement:
          (map['datePrelevement'] as Timestamp?)?.toDate() ?? DateTime.now(),
      produits: (map['produits'] as List<dynamic>?)
              ?.map((p) => ProduitPreleve.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      valeurTotale: (map['valeurTotale'] ?? 0.0).toDouble(),
      statut: StatutPrelevement.values.firstWhere(
        (s) => s.name == map['statut'],
        orElse: () => StatutPrelevement.enCours,
      ),
      observations: map['observations'],
      dateRetour: (map['dateRetour'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'commercialId': commercialId,
      'commercialNom': commercialNom,
      'magazinierId': magazinierId,
      'magazinierNom': magazinierNom,
      'datePrelevement': Timestamp.fromDate(datePrelevement),
      'produits': produits.map((p) => p.toMap()).toList(),
      'valeurTotale': valeurTotale,
      'statut': statut.name,
      'observations': observations,
      'dateRetour': dateRetour != null ? Timestamp.fromDate(dateRetour!) : null,
    };
  }
}

/// 📦 PRODUIT PRÉLEVÉ DANS UN PRÉLÈVEMENT
class ProduitPreleve {
  final String produitId;
  final String numeroLot;
  final String typeEmballage;
  final double contenanceKg;
  final int quantitePreleve;
  final double prixUnitaire;
  final double valeurTotale;

  const ProduitPreleve({
    required this.produitId,
    required this.numeroLot,
    required this.typeEmballage,
    required this.contenanceKg,
    required this.quantitePreleve,
    required this.prixUnitaire,
    required this.valeurTotale,
  });

  factory ProduitPreleve.fromMap(Map<String, dynamic> map) {
    return ProduitPreleve(
      produitId: map['produitId'] ?? '',
      numeroLot: map['numeroLot'] ?? '',
      typeEmballage: map['typeEmballage'] ?? '',
      contenanceKg: (map['contenanceKg'] ?? 0.0).toDouble(),
      quantitePreleve: map['quantitePreleve'] ?? 0,
      prixUnitaire: (map['prixUnitaire'] ?? 0.0).toDouble(),
      valeurTotale: (map['valeurTotale'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produitId': produitId,
      'numeroLot': numeroLot,
      'typeEmballage': typeEmballage,
      'contenanceKg': contenanceKg,
      'quantitePreleve': quantitePreleve,
      'prixUnitaire': prixUnitaire,
      'valeurTotale': valeurTotale,
    };
  }
}

/// 🛒 VENTE EFFECTUÉE
class Vente {
  final String id;
  final String prelevementId;
  final String commercialId;
  final String commercialNom;
  final String clientId;
  final String clientNom;
  final String? clientTelephone;
  final String? clientAdresse;
  final DateTime dateVente;
  final List<ProduitVendu> produits;
  final double montantTotal;
  final double montantPaye;
  final double montantRestant;
  final ModePaiement modePaiement;
  final StatutVente statut;
  final String? observations;

  const Vente({
    required this.id,
    required this.prelevementId,
    required this.commercialId,
    required this.commercialNom,
    required this.clientId,
    required this.clientNom,
    this.clientTelephone,
    this.clientAdresse,
    required this.dateVente,
    required this.produits,
    required this.montantTotal,
    required this.montantPaye,
    required this.montantRestant,
    required this.modePaiement,
    required this.statut,
    this.observations,
  });

  factory Vente.fromMap(Map<String, dynamic> map) {
    return Vente(
      id: map['id'] ?? '',
      prelevementId: map['prelevementId'] ?? '',
      commercialId: map['commercialId'] ?? '',
      commercialNom: map['commercialNom'] ?? '',
      clientId: map['clientId'] ?? '',
      clientNom: map['clientNom'] ?? '',
      clientTelephone: map['clientTelephone'],
      clientAdresse: map['clientAdresse'],
      dateVente: (map['dateVente'] as Timestamp?)?.toDate() ?? DateTime.now(),
      produits: (map['produits'] as List<dynamic>?)
              ?.map((p) => ProduitVendu.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      montantTotal: (map['montantTotal'] ?? 0.0).toDouble(),
      montantPaye: (map['montantPaye'] ?? 0.0).toDouble(),
      montantRestant: (map['montantRestant'] ?? 0.0).toDouble(),
      modePaiement: ModePaiement.values.firstWhere(
        (m) => m.name == map['modePaiement'],
        orElse: () => ModePaiement.espece,
      ),
      statut: StatutVente.values.firstWhere(
        (s) => s.name == map['statut'],
        orElse: () => StatutVente.terminee,
      ),
      observations: map['observations'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prelevementId': prelevementId,
      'commercialId': commercialId,
      'commercialNom': commercialNom,
      'clientId': clientId,
      'clientNom': clientNom,
      'clientTelephone': clientTelephone,
      'clientAdresse': clientAdresse,
      'dateVente': Timestamp.fromDate(dateVente),
      'produits': produits.map((p) => p.toMap()).toList(),
      'montantTotal': montantTotal,
      'montantPaye': montantPaye,
      'montantRestant': montantRestant,
      'modePaiement': modePaiement.name,
      'statut': statut.name,
      'observations': observations,
    };
  }
}

/// 📦 PRODUIT VENDU DANS UNE VENTE
class ProduitVendu {
  final String produitId;
  final String numeroLot;
  final String typeEmballage;
  final double contenanceKg;
  final int quantiteVendue;
  final double prixUnitaire;
  final double prixVente;
  final double montantTotal;

  const ProduitVendu({
    required this.produitId,
    required this.numeroLot,
    required this.typeEmballage,
    required this.contenanceKg,
    required this.quantiteVendue,
    required this.prixUnitaire,
    required this.prixVente,
    required this.montantTotal,
  });

  factory ProduitVendu.fromMap(Map<String, dynamic> map) {
    return ProduitVendu(
      produitId: map['produitId'] ?? '',
      numeroLot: map['numeroLot'] ?? '',
      typeEmballage: map['typeEmballage'] ?? '',
      contenanceKg: (map['contenanceKg'] ?? 0.0).toDouble(),
      quantiteVendue: map['quantiteVendue'] ?? 0,
      prixUnitaire: (map['prixUnitaire'] ?? 0.0).toDouble(),
      prixVente: (map['prixVente'] ?? 0.0).toDouble(),
      montantTotal: (map['montantTotal'] ?? 0.0).toDouble(),
    );
  }

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
    };
  }
}

/// 🔄 RESTITUTION DE PRODUITS
class Restitution {
  final String id;
  final String prelevementId;
  final String commercialId;
  final String commercialNom;
  final DateTime dateRestitution;
  final List<ProduitRestitue> produits;
  final double valeurTotale;
  final TypeRestitution type;
  final String motif;
  final String? observations;

  const Restitution({
    required this.id,
    required this.prelevementId,
    required this.commercialId,
    required this.commercialNom,
    required this.dateRestitution,
    required this.produits,
    required this.valeurTotale,
    required this.type,
    required this.motif,
    this.observations,
  });

  factory Restitution.fromMap(Map<String, dynamic> map) {
    return Restitution(
      id: map['id'] ?? '',
      prelevementId: map['prelevementId'] ?? '',
      commercialId: map['commercialId'] ?? '',
      commercialNom: map['commercialNom'] ?? '',
      dateRestitution:
          (map['dateRestitution'] as Timestamp?)?.toDate() ?? DateTime.now(),
      produits: (map['produits'] as List<dynamic>?)
              ?.map((p) => ProduitRestitue.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      valeurTotale: (map['valeurTotale'] ?? 0.0).toDouble(),
      type: TypeRestitution.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => TypeRestitution.invendu,
      ),
      motif: map['motif'] ?? '',
      observations: map['observations'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prelevementId': prelevementId,
      'commercialId': commercialId,
      'commercialNom': commercialNom,
      'dateRestitution': Timestamp.fromDate(dateRestitution),
      'produits': produits.map((p) => p.toMap()).toList(),
      'valeurTotale': valeurTotale,
      'type': type.name,
      'motif': motif,
      'observations': observations,
    };
  }
}

/// 📦 PRODUIT RESTITUÉ
class ProduitRestitue {
  final String produitId;
  final String numeroLot;
  final String typeEmballage;
  final int quantiteRestituee;
  final double valeurUnitaire;
  final String etatProduit;

  const ProduitRestitue({
    required this.produitId,
    required this.numeroLot,
    required this.typeEmballage,
    required this.quantiteRestituee,
    required this.valeurUnitaire,
    required this.etatProduit,
  });

  factory ProduitRestitue.fromMap(Map<String, dynamic> map) {
    return ProduitRestitue(
      produitId: map['produitId'] ?? '',
      numeroLot: map['numeroLot'] ?? '',
      typeEmballage: map['typeEmballage'] ?? '',
      quantiteRestituee: map['quantiteRestituee'] ?? 0,
      valeurUnitaire: (map['valeurUnitaire'] ?? 0.0).toDouble(),
      etatProduit: map['etatProduit'] ?? 'BON',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produitId': produitId,
      'numeroLot': numeroLot,
      'typeEmballage': typeEmballage,
      'quantiteRestituee': quantiteRestituee,
      'valeurUnitaire': valeurUnitaire,
      'etatProduit': etatProduit,
    };
  }
}

/// 💔 PERTE DÉCLARÉE
class Perte {
  final String id;
  final String prelevementId;
  final String commercialId;
  final String commercialNom;
  final DateTime datePerte;
  final List<ProduitPerdu> produits;
  final double valeurTotale;
  final TypePerte type;
  final String motif;
  final String? observations;
  final bool estValidee;
  final String? validateurId;
  final DateTime? dateValidation;

  const Perte({
    required this.id,
    required this.prelevementId,
    required this.commercialId,
    required this.commercialNom,
    required this.datePerte,
    required this.produits,
    required this.valeurTotale,
    required this.type,
    required this.motif,
    this.observations,
    required this.estValidee,
    this.validateurId,
    this.dateValidation,
  });

  factory Perte.fromMap(Map<String, dynamic> map) {
    return Perte(
      id: map['id'] ?? '',
      prelevementId: map['prelevementId'] ?? '',
      commercialId: map['commercialId'] ?? '',
      commercialNom: map['commercialNom'] ?? '',
      datePerte: (map['datePerte'] as Timestamp?)?.toDate() ?? DateTime.now(),
      produits: (map['produits'] as List<dynamic>?)
              ?.map((p) => ProduitPerdu.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      valeurTotale: (map['valeurTotale'] ?? 0.0).toDouble(),
      type: TypePerte.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => TypePerte.casse,
      ),
      motif: map['motif'] ?? '',
      observations: map['observations'],
      estValidee: map['estValidee'] ?? false,
      validateurId: map['validateurId'],
      dateValidation: (map['dateValidation'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prelevementId': prelevementId,
      'commercialId': commercialId,
      'commercialNom': commercialNom,
      'datePerte': Timestamp.fromDate(datePerte),
      'produits': produits.map((p) => p.toMap()).toList(),
      'valeurTotale': valeurTotale,
      'type': type.name,
      'motif': motif,
      'observations': observations,
      'estValidee': estValidee,
      'validateurId': validateurId,
      'dateValidation':
          dateValidation != null ? Timestamp.fromDate(dateValidation!) : null,
    };
  }
}

/// 📦 PRODUIT PERDU
class ProduitPerdu {
  final String produitId;
  final String numeroLot;
  final String typeEmballage;
  final int quantitePerdue;
  final double valeurUnitaire;
  final String circonstances;

  const ProduitPerdu({
    required this.produitId,
    required this.numeroLot,
    required this.typeEmballage,
    required this.quantitePerdue,
    required this.valeurUnitaire,
    required this.circonstances,
  });

  factory ProduitPerdu.fromMap(Map<String, dynamic> map) {
    return ProduitPerdu(
      produitId: map['produitId'] ?? '',
      numeroLot: map['numeroLot'] ?? '',
      typeEmballage: map['typeEmballage'] ?? '',
      quantitePerdue: map['quantitePerdue'] ?? 0,
      valeurUnitaire: (map['valeurUnitaire'] ?? 0.0).toDouble(),
      circonstances: map['circonstances'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produitId': produitId,
      'numeroLot': numeroLot,
      'typeEmballage': typeEmballage,
      'quantitePerdue': quantitePerdue,
      'valeurUnitaire': valeurUnitaire,
      'circonstances': circonstances,
    };
  }
}

/// 👤 CLIENT
class Client {
  final String id;
  final String nom;
  final String? telephone;
  final String? email;
  final String? adresse;
  final String? ville;
  final TypeClient type;
  final DateTime dateCreation;
  final double totalAchats;
  final int nombreAchats;
  final bool estActif;

  const Client({
    required this.id,
    required this.nom,
    this.telephone,
    this.email,
    this.adresse,
    this.ville,
    required this.type,
    required this.dateCreation,
    required this.totalAchats,
    required this.nombreAchats,
    required this.estActif,
  });

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      telephone: map['telephone'],
      email: map['email'],
      adresse: map['adresse'],
      ville: map['ville'],
      type: TypeClient.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => TypeClient.particulier,
      ),
      dateCreation:
          (map['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalAchats: (map['totalAchats'] ?? 0.0).toDouble(),
      nombreAchats: map['nombreAchats'] ?? 0,
      estActif: map['estActif'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'telephone': telephone,
      'email': email,
      'adresse': adresse,
      'ville': ville,
      'type': type.name,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'totalAchats': totalAchats,
      'nombreAchats': nombreAchats,
      'estActif': estActif,
    };
  }
}

// ====== ENUMS ======

enum StatutProduit {
  disponible,
  preleve,
  vendu,
  restitue,
  perdu,
  expire,
}

enum StatutPrelevement {
  enCours,
  partiel,
  termine,
  annule,
}

enum ModePaiement {
  espece,
  carte,
  virement,
  cheque,
  mobile,
  credit,
}

enum StatutVente {
  terminee,
  enAttente,
  annulee,
  remboursee,
}

enum TypeRestitution {
  invendu,
  defaut,
  erreur,
  annulation,
}

enum TypePerte {
  casse,
  vol,
  deterioration,
  expiration,
  autre,
}

enum TypeClient {
  particulier,
  professionnel,
  revendeur,
  grossiste,
}

// ====== UTILITAIRES ======

class VenteUtils {
  static String formatPrix(double prix) {
    return '${prix.toStringAsFixed(0)} FCFA';
  }

  static Color getColorForStatut(StatutProduit statut) {
    switch (statut) {
      case StatutProduit.disponible:
        return const Color(0xFF4CAF50);
      case StatutProduit.preleve:
        return const Color(0xFF2196F3);
      case StatutProduit.vendu:
        return const Color(0xFF9C27B0);
      case StatutProduit.restitue:
        return const Color(0xFFFF9800);
      case StatutProduit.perdu:
        return const Color(0xFFF44336);
      case StatutProduit.expire:
        return const Color(0xFF795548);
    }
  }

  static String getLibelleStatut(StatutProduit statut) {
    switch (statut) {
      case StatutProduit.disponible:
        return 'Disponible';
      case StatutProduit.preleve:
        return 'Prélevé';
      case StatutProduit.vendu:
        return 'Vendu';
      case StatutProduit.restitue:
        return 'Restitué';
      case StatutProduit.perdu:
        return 'Perdu';
      case StatutProduit.expire:
        return 'Expiré';
    }
  }

  static String getEmojiiForTypeEmballage(String type) {
    switch (type.toLowerCase()) {
      case '1.5kg':
      case '1kg':
      case '720g':
      case '500g':
      case '250g':
        return '🍯';
      case '7kg':
        return '🪣';
      case 'stick 20g':
        return '🥢';
      case 'pot alvéoles 30g':
      case '30g':
        return '🫙';
      default:
        return '📦';
    }
  }
}
