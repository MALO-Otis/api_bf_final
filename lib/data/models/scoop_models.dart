import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour un SCOOP (coopérative)
class ScoopModel {
  final String id;
  final String nom;
  final String president;
  final String telephone;
  final String region;
  final String province;
  final String commune;
  final String? village;
  final String? arrondissement;
  final String? secteur;
  final String? quartier;
  final int nbRuchesTrad;
  final int nbRuchesModernes;
  final int nbMembres;
  final int nbHommes;
  final int nbFemmes;
  final int nbJeunes;
  final List<String> predominanceFlorale;
  final DateTime? createdAt;

  ScoopModel({
    required this.id,
    required this.nom,
    required this.president,
    required this.telephone,
    required this.region,
    required this.province,
    required this.commune,
    this.village,
    this.arrondissement,
    this.secteur,
    this.quartier,
    required this.nbRuchesTrad,
    required this.nbRuchesModernes,
    required this.nbMembres,
    required this.nbHommes,
    required this.nbFemmes,
    required this.nbJeunes,
    required this.predominanceFlorale,
    this.createdAt,
  });

  factory ScoopModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScoopModel(
      id: doc.id,
      nom: data['nom'] ?? '',
      president: data['president'] ?? '',
      telephone: data['telephone'] ?? '',
      region: data['region'] ?? '',
      province: data['province'] ?? '',
      commune: data['commune'] ?? '',
      village: data['village'],
      arrondissement: data['arrondissement'],
      secteur: data['secteur'],
      quartier: data['quartier'],
      nbRuchesTrad: data['nbRuchesTrad'] ?? 0,
      nbRuchesModernes: data['nbRuchesModernes'] ?? 0,
      nbMembres: data['nbMembres'] ?? 0,
      nbHommes: data['nbHommes'] ?? 0,
      nbFemmes: data['nbFemmes'] ?? 0,
      nbJeunes: data['nbJeunes'] ?? 0,
      predominanceFlorale: List<String>.from(data['predominanceFlorale'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'president': president,
      'telephone': telephone,
      'region': region,
      'province': province,
      'commune': commune,
      'village': village,
      'arrondissement': arrondissement,
      'secteur': secteur,
      'quartier': quartier,
      'nbRuchesTrad': nbRuchesTrad,
      'nbRuchesModernes': nbRuchesModernes,
      'nbMembres': nbMembres,
      'nbHommes': nbHommes,
      'nbFemmes': nbFemmes,
      'nbJeunes': nbJeunes,
      'predominanceFlorale': predominanceFlorale,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  String get localisation {
    final List<String> parts = [region, province, commune];
    if (village != null) parts.add(village!);
    if (arrondissement != null) parts.add(arrondissement!);
    if (secteur != null) parts.add(secteur!);
    if (quartier != null) parts.add(quartier!);
    return parts.join(', ');
  }

  int get nbVieux => nbMembres - nbJeunes;
}

/// Types de contenants autorisés
enum ContenantType {
  bidon('Bidon'),
  pot('Pot');

  const ContenantType(this.label);
  final String label;
}

/// Types de miel autorisés
enum MielType {
  liquide('Liquide'),
  brute('Brute'),
  cire('Cire');

  const MielType(this.label);
  final String label;
}

/// Modèle pour un contenant de miel
class ContenantScoopModel {
  final String id;
  final ContenantType typeContenant;
  final MielType typeMiel;
  final double poids;
  final double prix;
  final String? notes;

  ContenantScoopModel({
    required this.id,
    required this.typeContenant,
    required this.typeMiel,
    required this.poids,
    required this.prix,
    this.notes,
  });

  factory ContenantScoopModel.fromMap(Map<String, dynamic> data) {
    return ContenantScoopModel(
      id: data['id'] ?? '',
      typeContenant: ContenantType.values.firstWhere(
        (type) => type.label == data['typeContenant'],
        orElse: () => ContenantType.bidon,
      ),
      typeMiel: MielType.values.firstWhere(
        (type) => type.label == data['typeMiel'],
        orElse: () => MielType.liquide,
      ),
      poids: (data['poids'] ?? 0).toDouble(),
      prix: (data['prix'] ?? 0).toDouble(),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'typeContenant': typeContenant.label,
      'typeMiel': typeMiel.label,
      'poids': poids,
      'prix': prix,
      'notes': notes,
    };
  }

  ContenantScoopModel copyWith({
    String? id,
    ContenantType? typeContenant,
    MielType? typeMiel,
    double? poids,
    double? prix,
    String? notes,
  }) {
    return ContenantScoopModel(
      id: id ?? this.id,
      typeContenant: typeContenant ?? this.typeContenant,
      typeMiel: typeMiel ?? this.typeMiel,
      poids: poids ?? this.poids,
      prix: prix ?? this.prix,
      notes: notes ?? this.notes,
    );
  }
}

/// Modèle pour une collecte SCOOP avec contenants
class CollecteScoopModel {
  final String id;
  final DateTime dateAchat;
  final String periodeCollecte;
  final String scoopId;
  final String scoopNom;
  final List<ContenantScoopModel> contenants;
  final double poidsTotal;
  final double montantTotal;
  final String observations;
  final String collecteurId;
  final String collecteurNom;
  final String site;
  final DateTime createdAt;
  final String statut;

  CollecteScoopModel({
    required this.id,
    required this.dateAchat,
    required this.periodeCollecte,
    required this.scoopId,
    required this.scoopNom,
    required this.contenants,
    required this.poidsTotal,
    required this.montantTotal,
    required this.observations,
    required this.collecteurId,
    required this.collecteurNom,
    required this.site,
    required this.createdAt,
    this.statut = 'collecte_terminee',
  });

  factory CollecteScoopModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CollecteScoopModel(
      id: doc.id,
      dateAchat: (data['date_achat'] as Timestamp).toDate(),
      periodeCollecte: data['periode_collecte'] ?? '',
      scoopId: data['scoop_id'] ?? '',
      scoopNom: data['scoop_nom'] ?? '',
      contenants: (data['contenants'] as List<dynamic>? ?? [])
          .map((c) => ContenantScoopModel.fromMap(c as Map<String, dynamic>))
          .toList(),
      poidsTotal: (data['poids_total'] ?? 0).toDouble(),
      montantTotal: (data['montant_total'] ?? 0).toDouble(),
      observations: data['observations'] ?? '',
      collecteurId: data['collecteur_id'] ?? '',
      collecteurNom: data['collecteur_nom'] ?? '',
      site: data['site'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      statut: data['statut'] ?? 'collecte_terminee',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date_achat': Timestamp.fromDate(dateAchat),
      'periode_collecte': periodeCollecte,
      'scoop_id': scoopId,
      'scoop_nom': scoopNom,
      'contenants': contenants.map((c) => c.toFirestore()).toList(),
      'poids_total': poidsTotal,
      'montant_total': montantTotal,
      'nombre_contenants': contenants.length,
      'collecteur_id': collecteurId,
      'collecteur_nom': collecteurNom,
      'site': site,
      'observations': observations,
      'created_at': Timestamp.fromDate(createdAt),
      'statut': statut,
    };
  }

  int get nombreBidons =>
      contenants.where((c) => c.typeContenant == ContenantType.bidon).length;
  int get nombrePots =>
      contenants.where((c) => c.typeContenant == ContenantType.pot).length;

  Set<String> get mielTypes => contenants.map((c) => c.typeMiel.label).toSet();
}

/// Périodes prédéfinies pour la collecte
class PeriodesCollecte {
  static const List<String> periodes = [
    'La grande Miellé',
    'La Petite miellée',
  ];
}

/// Prédominances florales disponibles
class PredominancesFlorale {
  static const List<String> types = [
    'Karité',
    'Néré',
    'Acacia',
    'Manguier',
    'Eucalyptus',
    'Tamarinier',
    'Baobab',
    'Citronnier',
    'Fleurs sauvages',
    'Multifloral',
  ];
}
