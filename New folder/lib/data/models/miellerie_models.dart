import 'package:cloud_firestore/cloud_firestore.dart';

// Modèle pour une Miellerie
class MiellerieModel {
  final String id;
  final String nom;
  final String localite;
  final String cooperativeId;
  final String cooperativeNom;
  final String repondant;
  final String? telephone;
  final String? adresse;
  final DateTime createdAt;

  MiellerieModel({
    required this.id,
    required this.nom,
    required this.localite,
    required this.cooperativeId,
    required this.cooperativeNom,
    required this.repondant,
    this.telephone,
    this.adresse,
    required this.createdAt,
  });

  factory MiellerieModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MiellerieModel(
      id: doc.id,
      nom: data['nom'] ?? '',
      localite: data['localite'] ?? '',
      cooperativeId: data['cooperative_id'] ?? '',
      cooperativeNom: data['cooperative_nom'] ?? '',
      repondant: data['repondant'] ?? '',
      telephone: data['telephone'],
      adresse: data['adresse'],
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'localite': localite,
      'cooperative_id': cooperativeId,
      'cooperative_nom': cooperativeNom,
      'repondant': repondant,
      'telephone': telephone,
      'adresse': adresse,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}

// Types de collecte pour Miellerie (compatible système SCOOP)
enum TypeCollecteMiellerie {
  liquide('Liquide'),
  brute('Brute'), 
  cire('Cire');

  const TypeCollecteMiellerie(this.label);
  final String label;

  static List<String> get typesList =>
      TypeCollecteMiellerie.values.map((e) => e.label).toList();
}

// Types de cire pour Miellerie (comme SCOOP)
enum TypeCireMiellerie {
  brute('Brute'),
  purifiee('Purifiée');

  const TypeCireMiellerie(this.label);
  final String label;

  static List<String> get typesList =>
      TypeCireMiellerie.values.map((e) => e.label).toList();
}

// Couleurs de cire pour Miellerie (comme SCOOP)
enum CouleurCireMiellerie {
  jaune('Jaune'),
  marron('Marron');

  const CouleurCireMiellerie(this.label);
  final String label;

  static List<String> get typesList =>
      CouleurCireMiellerie.values.map((e) => e.label).toList();
}

// Types de contenant pour Miellerie
enum TypeContenantMiellerie {
  bidon('Bidon'),
  pot('Pot'),
  fut('Fût'),
  seau('Seau');

  const TypeContenantMiellerie(this.label);
  final String label;

  static List<String> get typesList =>
      TypeContenantMiellerie.values.map((e) => e.label).toList();
}

// Modèle pour un contenant de collecte Miellerie (compatible système SCOOP)
class ContenantMiellerieModel {
  final String? id; // ID unique pour chaque contenant
  final String typeContenant;
  final String typeCollecte; // Type de miel (Liquide/Brute/Cire)
  final String? typeCire; // Brute/Purifiée (si typeCollecte = Cire)
  final String? couleurCire; // Jaune/Marron (si typeCire = Purifiée)
  final double quantite;
  final double prixUnitaire;
  final double montantTotal;
  final String? notes;

  ContenantMiellerieModel({
    this.id,
    required this.typeContenant,
    required this.typeCollecte,
    this.typeCire,
    this.couleurCire,
    required this.quantite,
    required this.prixUnitaire,
    required this.montantTotal,
    this.notes,
  });

  factory ContenantMiellerieModel.fromMap(Map<String, dynamic> data) {
    return ContenantMiellerieModel(
      id: data['id'],
      typeContenant: data['type_contenant'] ?? '',
      typeCollecte: data['type_collecte'] ?? '',
      typeCire: data['type_cire'],
      couleurCire: data['couleur_cire'],
      quantite: (data['quantite'] ?? 0).toDouble(),
      prixUnitaire: (data['prix_unitaire'] ?? 0).toDouble(),
      montantTotal: (data['montant_total'] ?? 0).toDouble(),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type_contenant': typeContenant,
      'type_collecte': typeCollecte,
      'type_cire': typeCire,
      'couleur_cire': couleurCire,
      'quantite': quantite,
      'prix_unitaire': prixUnitaire,
      'montant_total': montantTotal,
      'notes': notes,
    };
  }

  ContenantMiellerieModel copyWith({
    String? id,
    String? typeContenant,
    String? typeCollecte,
    String? typeCire,
    String? couleurCire,
    double? quantite,
    double? prixUnitaire,
    double? montantTotal,
    String? notes,
  }) {
    return ContenantMiellerieModel(
      id: id ?? this.id,
      typeContenant: typeContenant ?? this.typeContenant,
      typeCollecte: typeCollecte ?? this.typeCollecte,
      typeCire: typeCire ?? this.typeCire,
      couleurCire: couleurCire ?? this.couleurCire,
      quantite: quantite ?? this.quantite,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      montantTotal: montantTotal ?? this.montantTotal,
      notes: notes ?? this.notes,
    );
  }
}

// Modèle principal pour une collecte Miellerie
class CollecteMiellerieModel {
  final String id;
  final DateTime dateCollecte;
  final String collecteurId;
  final String collecteurNom;
  final String miellerieId;
  final String miellerieNom;
  final String localite;
  final String cooperativeId;
  final String cooperativeNom;
  final String repondant;
  final List<ContenantMiellerieModel> contenants;
  final double poidsTotal;
  final double montantTotal;
  final String? observations;
  final String site;
  final DateTime createdAt;
  final String statut;

  CollecteMiellerieModel({
    required this.id,
    required this.dateCollecte,
    required this.collecteurId,
    required this.collecteurNom,
    required this.miellerieId,
    required this.miellerieNom,
    required this.localite,
    required this.cooperativeId,
    required this.cooperativeNom,
    required this.repondant,
    required this.contenants,
    required this.poidsTotal,
    required this.montantTotal,
    this.observations,
    required this.site,
    required this.createdAt,
    this.statut = 'collecte_terminee',
  });

  factory CollecteMiellerieModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CollecteMiellerieModel(
      id: doc.id,
      dateCollecte:
          (data['date_collecte'] as Timestamp?)?.toDate() ?? DateTime.now(),
      collecteurId: data['collecteur_id'] ?? '',
      collecteurNom: data['collecteur_nom'] ?? '',
      miellerieId: data['miellerie_id'] ?? '',
      miellerieNom: data['miellerie_nom'] ?? '',
      localite: data['localite'] ?? '',
      cooperativeId: data['cooperative_id'] ?? '',
      cooperativeNom: data['cooperative_nom'] ?? '',
      repondant: data['repondant'] ?? '',
      contenants: (data['contenants'] as List<dynamic>? ?? [])
          .map(
              (c) => ContenantMiellerieModel.fromMap(c as Map<String, dynamic>))
          .toList(),
      poidsTotal: (data['poids_total'] ?? 0).toDouble(),
      montantTotal: (data['montant_total'] ?? 0).toDouble(),
      observations: data['observations'],
      site: data['site'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      statut: data['statut'] ?? 'collecte_terminee',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date_collecte': Timestamp.fromDate(dateCollecte),
      'collecteur_id': collecteurId,
      'collecteur_nom': collecteurNom,
      'miellerie_id': miellerieId,
      'miellerie_nom': miellerieNom,
      'localite': localite,
      'cooperative_id': cooperativeId,
      'cooperative_nom': cooperativeNom,
      'repondant': repondant,
      'contenants': contenants.map((c) => c.toMap()).toList(),
      'poids_total': poidsTotal,
      'montant_total': montantTotal,
      'observations': observations,
      'site': site,
      'created_at': Timestamp.fromDate(createdAt),
      'statut': statut,
    };
  }
}
