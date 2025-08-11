// Models pour le module de contrôle de données

/// Types de sections disponibles
enum Section { recoltes, scoop, individuel }

/// Rôles utilisateur
enum Role { admin, controller }

/// Interface de base pour toutes les collectes
abstract class BaseCollecte {
  final String id;
  final String path; // Chemin Firestore
  final String site;
  final DateTime date;
  final String? technicien;
  final String? statut;
  final double? totalWeight;
  final double? totalAmount;
  final int? containersCount;

  BaseCollecte({
    required this.id,
    required this.path,
    required this.site,
    required this.date,
    this.technicien,
    this.statut,
    this.totalWeight,
    this.totalAmount,
    this.containersCount,
  });

  /// Convertit en Map pour l'affichage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'site': site,
      'date': date.toIso8601String(),
      'technicien': technicien,
      'statut': statut,
      'totalWeight': totalWeight,
      'totalAmount': totalAmount,
      'containersCount': containersCount,
    };
  }
}

/// Modèle pour les contenants de récolte
class RecolteContenant {
  final String id;
  final String hiveType;
  final String containerType;
  final double weight;
  final double unitPrice;
  final double total;

  RecolteContenant({
    required this.id,
    required this.hiveType,
    required this.containerType,
    required this.weight,
    required this.unitPrice,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hiveType': hiveType,
      'containerType': containerType,
      'weight': weight,
      'unitPrice': unitPrice,
      'total': total,
    };
  }

  factory RecolteContenant.fromMap(Map<String, dynamic> map) {
    return RecolteContenant(
      id: map['id'] ?? '',
      hiveType: map['hiveType'] ?? '',
      containerType: map['containerType'] ?? '',
      weight: (map['weight'] ?? 0).toDouble(),
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
    );
  }
}

/// Modèle pour les collectes de récolte
class Recolte extends BaseCollecte {
  final String? region;
  final String? province;
  final String? commune;
  final String? village;
  final List<String>? predominancesFlorales;
  final List<RecolteContenant> contenants;

  Recolte({
    required super.id,
    required super.path,
    required super.site,
    required super.date,
    super.technicien,
    super.statut,
    super.totalWeight,
    super.totalAmount,
    this.region,
    this.province,
    this.commune,
    this.village,
    this.predominancesFlorales,
    required this.contenants,
  }) : super(containersCount: contenants.length);

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'type': 'recoltes',
      'region': region,
      'province': province,
      'commune': commune,
      'village': village,
      'predominancesFlorales': predominancesFlorales,
      'contenants': contenants.map((c) => c.toMap()).toList(),
    });
    return map;
  }

  factory Recolte.fromMap(Map<String, dynamic> map) {
    return Recolte(
      id: map['id'] ?? '',
      path: map['path'] ?? '',
      site: map['site'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      technicien: map['technicien'],
      statut: map['statut'],
      totalWeight: map['totalWeight']?.toDouble(),
      totalAmount: map['totalAmount']?.toDouble(),
      region: map['region'],
      province: map['province'],
      commune: map['commune'],
      village: map['village'],
      predominancesFlorales:
          List<String>.from(map['predominancesFlorales'] ?? []),
      contenants: (map['contenants'] as List<dynamic>? ?? [])
          .map((c) => RecolteContenant.fromMap(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Modèle pour les contenants SCOOP
class ScoopContenant {
  final String typeContenant;
  final String typeMiel;
  final double quantite;
  final double prixUnitaire;
  final double montantTotal;
  final String? predominanceFlorale;

  ScoopContenant({
    required this.typeContenant,
    required this.typeMiel,
    required this.quantite,
    required this.prixUnitaire,
    required this.montantTotal,
    this.predominanceFlorale,
  });

  Map<String, dynamic> toMap() {
    return {
      'typeContenant': typeContenant,
      'typeMiel': typeMiel,
      'quantite': quantite,
      'prixUnitaire': prixUnitaire,
      'montantTotal': montantTotal,
      'predominanceFlorale': predominanceFlorale,
    };
  }

  factory ScoopContenant.fromMap(Map<String, dynamic> map) {
    return ScoopContenant(
      typeContenant: map['typeContenant'] ?? '',
      typeMiel: map['typeMiel'] ?? '',
      quantite: (map['quantite'] ?? 0).toDouble(),
      prixUnitaire: (map['prixUnitaire'] ?? 0).toDouble(),
      montantTotal: (map['montantTotal'] ?? 0).toDouble(),
      predominanceFlorale: map['predominanceFlorale'],
    );
  }
}

/// Modèle pour les collectes SCOOP
class Scoop extends BaseCollecte {
  final String scoopNom;
  final String? periodeCollecte;
  final String? qualite;
  final String? localisation;
  final List<ScoopContenant> contenants;

  Scoop({
    required super.id,
    required super.path,
    required super.site,
    required super.date,
    super.technicien,
    super.statut,
    super.totalWeight,
    super.totalAmount,
    required this.scoopNom,
    this.periodeCollecte,
    this.qualite,
    this.localisation,
    required this.contenants,
  }) : super(containersCount: contenants.length);

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'type': 'scoop',
      'scoopNom': scoopNom,
      'periodeCollecte': periodeCollecte,
      'qualite': qualite,
      'localisation': localisation,
      'contenants': contenants.map((c) => c.toMap()).toList(),
    });
    return map;
  }

  factory Scoop.fromMap(Map<String, dynamic> map) {
    return Scoop(
      id: map['id'] ?? '',
      path: map['path'] ?? '',
      site: map['site'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      technicien: map['technicien'],
      statut: map['statut'],
      totalWeight: map['totalWeight']?.toDouble(),
      totalAmount: map['totalAmount']?.toDouble(),
      scoopNom: map['scoopNom'] ?? '',
      periodeCollecte: map['periodeCollecte'],
      qualite: map['qualite'],
      localisation: map['localisation'],
      contenants: (map['contenants'] as List<dynamic>? ?? [])
          .map((c) => ScoopContenant.fromMap(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Modèle pour les contenants individuels
class IndividuelContenant {
  final String typeContenant;
  final String typeMiel;
  final double quantite;
  final double prixUnitaire;
  final double montantTotal;

  IndividuelContenant({
    required this.typeContenant,
    required this.typeMiel,
    required this.quantite,
    required this.prixUnitaire,
    required this.montantTotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'typeContenant': typeContenant,
      'typeMiel': typeMiel,
      'quantite': quantite,
      'prixUnitaire': prixUnitaire,
      'montantTotal': montantTotal,
    };
  }

  factory IndividuelContenant.fromMap(Map<String, dynamic> map) {
    return IndividuelContenant(
      typeContenant: map['typeContenant'] ?? '',
      typeMiel: map['typeMiel'] ?? '',
      quantite: (map['quantite'] ?? 0).toDouble(),
      prixUnitaire: (map['prixUnitaire'] ?? 0).toDouble(),
      montantTotal: (map['montantTotal'] ?? 0).toDouble(),
    );
  }
}

/// Modèle pour les collectes individuelles
class Individuel extends BaseCollecte {
  final String nomProducteur;
  final List<String>? originesFlorales;
  final String? observations;
  final List<IndividuelContenant> contenants;

  Individuel({
    required super.id,
    required super.path,
    required super.site,
    required super.date,
    super.technicien,
    super.statut,
    super.totalWeight,
    super.totalAmount,
    required this.nomProducteur,
    this.originesFlorales,
    this.observations,
    required this.contenants,
  }) : super(containersCount: contenants.length);

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'type': 'individuel',
      'nomProducteur': nomProducteur,
      'originesFlorales': originesFlorales,
      'observations': observations,
      'contenants': contenants.map((c) => c.toMap()).toList(),
    });
    return map;
  }

  factory Individuel.fromMap(Map<String, dynamic> map) {
    return Individuel(
      id: map['id'] ?? '',
      path: map['path'] ?? '',
      site: map['site'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      technicien: map['technicien'],
      statut: map['statut'],
      totalWeight: map['totalWeight']?.toDouble(),
      totalAmount: map['totalAmount']?.toDouble(),
      nomProducteur: map['nomProducteur'] ?? '',
      originesFlorales: List<String>.from(map['originesFlorales'] ?? []),
      observations: map['observations'],
      contenants: (map['contenants'] as List<dynamic>? ?? [])
          .map((c) => IndividuelContenant.fromMap(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Type union pour toutes les collectes
typedef AnyCollecte = BaseCollecte;

/// Modèle pour les filtres
class CollecteFilters {
  final List<String> sites;
  final String technicien;
  final String statut;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final List<String> florales;
  final double? poidsMin;
  final double? poidsMax;
  final double? montantMin;
  final double? montantMax;
  final int? contMin;
  final int? contMax;

  CollecteFilters({
    this.sites = const [],
    this.technicien = '',
    this.statut = '',
    this.dateFrom,
    this.dateTo,
    this.florales = const [],
    this.poidsMin,
    this.poidsMax,
    this.montantMin,
    this.montantMax,
    this.contMin,
    this.contMax,
  });

  CollecteFilters copyWith({
    List<String>? sites,
    String? technicien,
    String? statut,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? florales,
    double? poidsMin,
    double? poidsMax,
    double? montantMin,
    double? montantMax,
    int? contMin,
    int? contMax,
  }) {
    return CollecteFilters(
      sites: sites ?? this.sites,
      technicien: technicien ?? this.technicien,
      statut: statut ?? this.statut,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      florales: florales ?? this.florales,
      poidsMin: poidsMin ?? this.poidsMin,
      poidsMax: poidsMax ?? this.poidsMax,
      montantMin: montantMin ?? this.montantMin,
      montantMax: montantMax ?? this.montantMax,
      contMin: contMin ?? this.contMin,
      contMax: contMax ?? this.contMax,
    );
  }

  /// Remet à zéro tous les filtres
  CollecteFilters reset() {
    return CollecteFilters();
  }

  /// Vérifie si des filtres sont appliqués
  bool get hasActiveFilters {
    return sites.isNotEmpty ||
        technicien.isNotEmpty ||
        statut.isNotEmpty ||
        dateFrom != null ||
        dateTo != null ||
        florales.isNotEmpty ||
        poidsMin != null ||
        poidsMax != null ||
        montantMin != null ||
        montantMax != null ||
        contMin != null ||
        contMax != null;
  }

  /// Compte le nombre de filtres actifs
  int getActiveFiltersCount() {
    int count = 0;
    if (sites.isNotEmpty) count++;
    if (technicien.isNotEmpty) count++;
    if (statut.isNotEmpty) count++;
    if (dateFrom != null || dateTo != null) count++;
    if (florales.isNotEmpty) count++;
    if (poidsMin != null || poidsMax != null) count++;
    if (montantMin != null || montantMax != null) count++;
    if (contMin != null || contMax != null) count++;
    return count;
  }
}

/// Statistiques calculées pour l'affichage
class CollecteStats {
  final int total;
  final double poids;
  final double montant;
  final int contenants;

  CollecteStats({
    required this.total,
    required this.poids,
    required this.montant,
    required this.contenants,
  });

  factory CollecteStats.empty() {
    return CollecteStats(
      total: 0,
      poids: 0.0,
      montant: 0.0,
      contenants: 0,
    );
  }
}

/// Types de tri disponibles
enum SortKey {
  date,
  site,
  technicien,
  poids,
  montant,
  contenants,
  libelleAsc,
  libelleDesc,
}

extension SortKeyExtension on SortKey {
  String get label {
    switch (this) {
      case SortKey.date:
        return 'Date';
      case SortKey.site:
        return 'Site';
      case SortKey.technicien:
        return 'Technicien';
      case SortKey.poids:
        return 'Poids total';
      case SortKey.montant:
        return 'Montant total';
      case SortKey.contenants:
        return '#contenants';
      case SortKey.libelleAsc:
        return 'Libellés A→Z';
      case SortKey.libelleDesc:
        return 'Libellés Z→A';
    }
  }
}
