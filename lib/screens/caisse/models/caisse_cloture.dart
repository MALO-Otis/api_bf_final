import '../../vente/models/vente_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Clôture envoyée par un commercial à la caissière pour validation
class CaisseCloture {
  final String id; // doc id
  final String site;
  final String commercialId;
  final String commercialNom;
  final String
      prelevementId; // ou attribution id utilisé comme prélevement virtuel
  final DateTime dateCreation;

  // Totaux
  final double totalVentes;
  final double totalPayes;
  final double totalCredits; // ventes crédit en attente
  final double totalRestitutions;
  final double totalPertes;

  // Détails simplifiés (snapshots à la création)
  final List<CaisseVenteResume> ventes;
  final List<CaisseRestitutionResume> restitutions;
  final List<CaissePerteResume> pertes;

  final ClotureStatut statut;
  final String? validePar;
  final DateTime? dateValidation;

  const CaisseCloture({
    required this.id,
    required this.site,
    required this.commercialId,
    required this.commercialNom,
    required this.prelevementId,
    required this.dateCreation,
    required this.totalVentes,
    required this.totalPayes,
    required this.totalCredits,
    required this.totalRestitutions,
    required this.totalPertes,
    required this.ventes,
    required this.restitutions,
    required this.pertes,
    required this.statut,
    this.validePar,
    this.dateValidation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'site': site,
      'commercialId': commercialId,
      'commercialNom': commercialNom,
      'prelevementId': prelevementId,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'totalVentes': totalVentes,
      'totalPayes': totalPayes,
      'totalCredits': totalCredits,
      'totalRestitutions': totalRestitutions,
      'totalPertes': totalPertes,
      'ventes': ventes.map((v) => v.toMap()).toList(),
      'restitutions': restitutions.map((r) => r.toMap()).toList(),
      'pertes': pertes.map((p) => p.toMap()).toList(),
      'statut': statut.name,
      'validePar': validePar,
      'dateValidation':
          dateValidation != null ? Timestamp.fromDate(dateValidation!) : null,
    };
  }

  factory CaisseCloture.fromMap(Map<String, dynamic> map) {
    return CaisseCloture(
      id: map['id'] ?? '',
      site: map['site'] ?? '',
      commercialId: map['commercialId'] ?? '',
      commercialNom: map['commercialNom'] ?? '',
      prelevementId: map['prelevementId'] ?? '',
      dateCreation:
          (map['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalVentes: (map['totalVentes'] ?? 0.0).toDouble(),
      totalPayes: (map['totalPayes'] ?? 0.0).toDouble(),
      totalCredits: (map['totalCredits'] ?? 0.0).toDouble(),
      totalRestitutions: (map['totalRestitutions'] ?? 0.0).toDouble(),
      totalPertes: (map['totalPertes'] ?? 0.0).toDouble(),
      ventes: (map['ventes'] as List<dynamic>? ?? [])
          .map((e) => CaisseVenteResume.fromMap(e))
          .toList(),
      restitutions: (map['restitutions'] as List<dynamic>? ?? [])
          .map((e) => CaisseRestitutionResume.fromMap(e))
          .toList(),
      pertes: (map['pertes'] as List<dynamic>? ?? [])
          .map((e) => CaissePerteResume.fromMap(e))
          .toList(),
      statut: ClotureStatut.values.firstWhere(
        (s) => s.name == map['statut'],
        orElse: () => ClotureStatut.en_attente,
      ),
      validePar: map['validePar'],
      dateValidation: (map['dateValidation'] as Timestamp?)?.toDate(),
    );
  }
}

enum ClotureStatut { en_attente, validee }

class CaisseVenteResume {
  final String id;
  final DateTime date;
  final double montantTotal;
  final double montantPaye;
  final double montantRestant;
  final ModePaiement modePaiement;
  final StatutVente statut;

  const CaisseVenteResume({
    required this.id,
    required this.date,
    required this.montantTotal,
    required this.montantPaye,
    required this.montantRestant,
    required this.modePaiement,
    required this.statut,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': Timestamp.fromDate(date),
        'montantTotal': montantTotal,
        'montantPaye': montantPaye,
        'montantRestant': montantRestant,
        'modePaiement': modePaiement.name,
        'statut': statut.name,
      };

  factory CaisseVenteResume.fromMap(Map<String, dynamic> map) =>
      CaisseVenteResume(
        id: map['id'] ?? '',
        date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        montantTotal: (map['montantTotal'] ?? 0.0).toDouble(),
        montantPaye: (map['montantPaye'] ?? 0.0).toDouble(),
        montantRestant: (map['montantRestant'] ?? 0.0).toDouble(),
        modePaiement: ModePaiement.values.firstWhere(
          (m) => m.name == map['modePaiement'],
          orElse: () => ModePaiement.espece,
        ),
        statut: StatutVente.values.firstWhere(
          (s) => s.name == map['statut'],
          orElse: () => StatutVente.payeeEnTotalite,
        ),
      );
}

class CaisseRestitutionResume {
  final String id;
  final DateTime date;
  final double valeurTotale;

  const CaisseRestitutionResume({
    required this.id,
    required this.date,
    required this.valeurTotale,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': Timestamp.fromDate(date),
        'valeurTotale': valeurTotale,
      };

  factory CaisseRestitutionResume.fromMap(Map<String, dynamic> map) =>
      CaisseRestitutionResume(
        id: map['id'] ?? '',
        date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        valeurTotale: (map['valeurTotale'] ?? 0.0).toDouble(),
      );
}

class CaissePerteResume {
  final String id;
  final DateTime date;
  final double valeurTotale;

  const CaissePerteResume({
    required this.id,
    required this.date,
    required this.valeurTotale,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': Timestamp.fromDate(date),
        'valeurTotale': valeurTotale,
      };

  factory CaissePerteResume.fromMap(Map<String, dynamic> map) =>
      CaissePerteResume(
        id: map['id'] ?? '',
        date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        valeurTotale: (map['valeurTotale'] ?? 0.0).toDouble(),
      );
}
