import '../../controle_de_donnes/models/quality_control_models.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';

/// Statut du processus de filtrage
enum StatutFiltrage {
  en_attente('En attente', '⏳'),
  en_cours('En cours', '🔄'),
  termine('Terminé', '✅'),
  probleme('Problème', '⚠️');

  const StatutFiltrage(this.label, this.emoji);
  final String label;
  final String emoji;
}

/// Type de tri pour les produits de filtrage
enum FiltrageSort {
  date('Date'),
  poids('Poids'),
  producteur('Producteur'),
  urgence('Urgence');

  const FiltrageSort(this.label);
  final String label;
}

/// Modèle pour un produit en cours de filtrage
class FiltrageProduct {
  final String id;
  final String codeContenant;
  final String typeCollecte;
  final String collecteId;
  final String producteur;
  final String village;
  final ProductNature nature;
  final String typeContenant;
  final double poids;
  final double? teneurEau;
  final String predominanceFlorale;
  final String qualite;
  final DateTime dateReception;
  final DateTime dateCollecte;
  final String collecteur;
  final String siteOrigine;
  final bool estConforme;
  final String? causeNonConformite;
  final String? observations;

  // Spécifique au filtrage
  final StatutFiltrage statutFiltrage;
  final DateTime? dateDebutFiltrage;
  final DateTime? dateFinFiltrage;
  final String? agentFiltrage;
  final double? poidsApresFilrage;
  final String? observationsFiltrage;
  final int priorite; // 1 = haute, 2 = normale, 3 = basse

  const FiltrageProduct({
    required this.id,
    required this.codeContenant,
    required this.typeCollecte,
    required this.collecteId,
    required this.producteur,
    required this.village,
    required this.nature,
    required this.typeContenant,
    required this.poids,
    this.teneurEau,
    required this.predominanceFlorale,
    required this.qualite,
    required this.dateReception,
    required this.dateCollecte,
    required this.collecteur,
    required this.siteOrigine,
    required this.estConforme,
    this.causeNonConformite,
    this.observations,
    this.statutFiltrage = StatutFiltrage.en_attente,
    this.dateDebutFiltrage,
    this.dateFinFiltrage,
    this.agentFiltrage,
    this.poidsApresFilrage,
    this.observationsFiltrage,
    this.priorite = 2,
  });

  /// Crée un produit de filtrage depuis un produit contrôlé
  factory FiltrageProduct.fromProductControle(ProductControle product) {
    return FiltrageProduct(
      id: product.id,
      codeContenant: product.codeContenant,
      typeCollecte: product.typeCollecte,
      collecteId: product.collecteId,
      producteur: product.producteur,
      village: product.village,
      nature: product.nature,
      typeContenant: product.typeContenant,
      poids: product.poids,
      teneurEau: product.teneurEau,
      predominanceFlorale: product.predominanceFlorale,
      qualite: product.qualite,
      dateReception: product.dateReception,
      dateCollecte: product.dateCollecte,
      collecteur: product.collecteur,
      siteOrigine: product.siteOrigine,
      estConforme: product.estConforme,
      causeNonConformite: product.causeNonConformite,
      observations: product.observations,
      priorite: _calculerPriorite(product),
    );
  }

  /// Calcule la priorité basée sur les caractéristiques du produit
  static int _calculerPriorite(ProductControle product) {
    // Haute priorité (1) :
    // - Produits anciens (plus de 30 jours)
    // - Poids élevé (plus de 50kg)
    // - Teneur en eau élevée (plus de 20%)

    final ageInDays = DateTime.now().difference(product.dateReception).inDays;
    final isOld = ageInDays > 30;
    final isHeavy = product.poids > 50;
    final isHighMoisture = (product.teneurEau ?? 0) > 20;

    if (isOld || (isHeavy && isHighMoisture)) {
      return 1; // Haute priorité
    }

    if (isHeavy || isHighMoisture || ageInDays > 14) {
      return 2; // Priorité normale
    }

    return 3; // Basse priorité
  }

  /// Indique si le produit est urgent (haute priorité)
  bool get isUrgent => priorite == 1;

  /// Indique si le produit peut être filtré
  bool get peutEtreFiltrer =>
      estConforme && statutFiltrage == StatutFiltrage.en_attente;

  /// Durée depuis la réception
  Duration get ageDepuisReception => DateTime.now().difference(dateReception);

  /// Copie avec modifications
  FiltrageProduct copyWith({
    String? id,
    String? codeContenant,
    String? typeCollecte,
    String? collecteId,
    String? producteur,
    String? village,
    ProductNature? nature,
    String? typeContenant,
    double? poids,
    double? teneurEau,
    String? predominanceFlorale,
    String? qualite,
    DateTime? dateReception,
    DateTime? dateCollecte,
    String? collecteur,
    String? siteOrigine,
    bool? estConforme,
    String? causeNonConformite,
    String? observations,
    StatutFiltrage? statutFiltrage,
    DateTime? dateDebutFiltrage,
    DateTime? dateFinFiltrage,
    String? agentFiltrage,
    double? poidsApresFilrage,
    String? observationsFiltrage,
    int? priorite,
  }) {
    return FiltrageProduct(
      id: id ?? this.id,
      codeContenant: codeContenant ?? this.codeContenant,
      typeCollecte: typeCollecte ?? this.typeCollecte,
      collecteId: collecteId ?? this.collecteId,
      producteur: producteur ?? this.producteur,
      village: village ?? this.village,
      nature: nature ?? this.nature,
      typeContenant: typeContenant ?? this.typeContenant,
      poids: poids ?? this.poids,
      teneurEau: teneurEau ?? this.teneurEau,
      predominanceFlorale: predominanceFlorale ?? this.predominanceFlorale,
      qualite: qualite ?? this.qualite,
      dateReception: dateReception ?? this.dateReception,
      dateCollecte: dateCollecte ?? this.dateCollecte,
      collecteur: collecteur ?? this.collecteur,
      siteOrigine: siteOrigine ?? this.siteOrigine,
      estConforme: estConforme ?? this.estConforme,
      causeNonConformite: causeNonConformite ?? this.causeNonConformite,
      observations: observations ?? this.observations,
      statutFiltrage: statutFiltrage ?? this.statutFiltrage,
      dateDebutFiltrage: dateDebutFiltrage ?? this.dateDebutFiltrage,
      dateFinFiltrage: dateFinFiltrage ?? this.dateFinFiltrage,
      agentFiltrage: agentFiltrage ?? this.agentFiltrage,
      poidsApresFilrage: poidsApresFilrage ?? this.poidsApresFilrage,
      observationsFiltrage: observationsFiltrage ?? this.observationsFiltrage,
      priorite: priorite ?? this.priorite,
    );
  }

  /// Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codeContenant': codeContenant,
      'typeCollecte': typeCollecte,
      'collecteId': collecteId,
      'producteur': producteur,
      'village': village,
      'nature': nature.name,
      'typeContenant': typeContenant,
      'poids': poids,
      'teneurEau': teneurEau,
      'predominanceFlorale': predominanceFlorale,
      'qualite': qualite,
      'dateReception': dateReception.toIso8601String(),
      'dateCollecte': dateCollecte.toIso8601String(),
      'collecteur': collecteur,
      'siteOrigine': siteOrigine,
      'estConforme': estConforme,
      'causeNonConformite': causeNonConformite,
      'observations': observations,
      'statutFiltrage': statutFiltrage.name,
      'dateDebutFiltrage': dateDebutFiltrage?.toIso8601String(),
      'dateFinFiltrage': dateFinFiltrage?.toIso8601String(),
      'agentFiltrage': agentFiltrage,
      'poidsApresFilrage': poidsApresFilrage,
      'observationsFiltrage': observationsFiltrage,
      'priorite': priorite,
    };
  }

  /// Création depuis Map Firestore
  factory FiltrageProduct.fromMap(Map<String, dynamic> map) {
    return FiltrageProduct(
      id: map['id'] ?? '',
      codeContenant: map['codeContenant'] ?? '',
      typeCollecte: map['typeCollecte'] ?? '',
      collecteId: map['collecteId'] ?? '',
      producteur: map['producteur'] ?? '',
      village: map['village'] ?? '',
      nature: ProductNature.values.firstWhere(
        (e) => e.name == map['nature'],
        orElse: () => ProductNature.brut,
      ),
      typeContenant: map['typeContenant'] ?? '',
      poids: (map['poids'] ?? 0).toDouble(),
      teneurEau: map['teneurEau']?.toDouble(),
      predominanceFlorale: map['predominanceFlorale'] ?? '',
      qualite: map['qualite'] ?? '',
      dateReception: DateTime.parse(map['dateReception']),
      dateCollecte: DateTime.parse(map['dateCollecte']),
      collecteur: map['collecteur'] ?? '',
      siteOrigine: map['siteOrigine'] ?? '',
      estConforme: map['estConforme'] ?? false,
      causeNonConformite: map['causeNonConformite'],
      observations: map['observations'],
      statutFiltrage: StatutFiltrage.values.firstWhere(
        (e) => e.name == map['statutFiltrage'],
        orElse: () => StatutFiltrage.en_attente,
      ),
      dateDebutFiltrage: map['dateDebutFiltrage'] != null
          ? DateTime.parse(map['dateDebutFiltrage'])
          : null,
      dateFinFiltrage: map['dateFinFiltrage'] != null
          ? DateTime.parse(map['dateFinFiltrage'])
          : null,
      agentFiltrage: map['agentFiltrage'],
      poidsApresFilrage: map['poidsApresFilrage']?.toDouble(),
      observationsFiltrage: map['observationsFiltrage'],
      priorite: map['priorite'] ?? 2,
    );
  }
}

/// Modèle pour les filtres de la page de filtrage
class FiltrageFilters {
  final String searchQuery;
  final List<String> selectedTypes;
  final List<StatutFiltrage> selectedStatuses;
  final List<String> selectedSites;
  final List<ProductNature> selectedNatures;
  final bool showOnlyUrgent;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final FiltrageSort sortBy;
  final bool sortAscending;

  const FiltrageFilters({
    this.searchQuery = '',
    this.selectedTypes = const [],
    this.selectedStatuses = const [],
    this.selectedSites = const [],
    this.selectedNatures = const [],
    this.showOnlyUrgent = false,
    this.dateDebut,
    this.dateFin,
    this.sortBy = FiltrageSort.date,
    this.sortAscending = false,
  });

  /// Indique s'il y a des filtres actifs
  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      selectedTypes.isNotEmpty ||
      selectedStatuses.isNotEmpty ||
      selectedSites.isNotEmpty ||
      selectedNatures.isNotEmpty ||
      showOnlyUrgent ||
      dateDebut != null ||
      dateFin != null;

  /// Copie avec modifications
  FiltrageFilters copyWith({
    String? searchQuery,
    List<String>? selectedTypes,
    List<StatutFiltrage>? selectedStatuses,
    List<String>? selectedSites,
    List<ProductNature>? selectedNatures,
    bool? showOnlyUrgent,
    DateTime? dateDebut,
    DateTime? dateFin,
    FiltrageSort? sortBy,
    bool? sortAscending,
  }) {
    return FiltrageFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTypes: selectedTypes ?? this.selectedTypes,
      selectedStatuses: selectedStatuses ?? this.selectedStatuses,
      selectedSites: selectedSites ?? this.selectedSites,
      selectedNatures: selectedNatures ?? this.selectedNatures,
      showOnlyUrgent: showOnlyUrgent ?? this.showOnlyUrgent,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

/// Résultat du processus de filtrage
class FiltrageResult {
  final String productId;
  final DateTime dateDebut;
  final DateTime dateFin;
  final String agentFiltrage;
  final double poidsInitial;
  final double poidsFinal;
  final String? observations;
  final bool succes;
  final String? probleme;

  const FiltrageResult({
    required this.productId,
    required this.dateDebut,
    required this.dateFin,
    required this.agentFiltrage,
    required this.poidsInitial,
    required this.poidsFinal,
    this.observations,
    required this.succes,
    this.probleme,
  });

  /// Calcule le taux de perte
  double get tauxPerte =>
      poidsInitial > 0 ? ((poidsInitial - poidsFinal) / poidsInitial) * 100 : 0;

  /// Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'dateDebut': dateDebut.toIso8601String(),
      'dateFin': dateFin.toIso8601String(),
      'agentFiltrage': agentFiltrage,
      'poidsInitial': poidsInitial,
      'poidsFinal': poidsFinal,
      'observations': observations,
      'succes': succes,
      'probleme': probleme,
      'tauxPerte': tauxPerte,
    };
  }

  /// Création depuis Map Firestore
  factory FiltrageResult.fromMap(Map<String, dynamic> map) {
    return FiltrageResult(
      productId: map['productId'] ?? '',
      dateDebut: DateTime.parse(map['dateDebut']),
      dateFin: DateTime.parse(map['dateFin']),
      agentFiltrage: map['agentFiltrage'] ?? '',
      poidsInitial: (map['poidsInitial'] ?? 0).toDouble(),
      poidsFinal: (map['poidsFinal'] ?? 0).toDouble(),
      observations: map['observations'],
      succes: map['succes'] ?? false,
      probleme: map['probleme'],
    );
  }
}
