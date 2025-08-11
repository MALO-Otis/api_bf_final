/// Statut d'extraction
enum ExtractionStatus {
  enAttente('En attente', 'pending'),
  enCours('En cours', 'in_progress'),
  termine('Terminé', 'completed'),
  suspendu('Suspendu', 'suspended'),
  erreur('Erreur', 'error');

  const ExtractionStatus(this.label, this.value);
  final String label;
  final String value;
}

/// Priorité d'extraction
enum ExtractionPriority {
  normale('Normale', 'normal'),
  urgente('Urgente', 'urgent'),
  differee('Différée', 'deferred');

  const ExtractionPriority(this.label, this.value);
  final String label;
  final String value;
}

/// Type de produit pour extraction
enum ProductType {
  mielBrut('Miel Brut', 'brut'),
  mielCristallise('Miel Cristallisé', 'cristallise'),
  propolis('Propolis', 'propolis'),
  cire('Cire', 'cire');

  const ProductType(this.label, this.value);
  final String label;
  final String value;
}

/// Modèle pour un produit attribué à l'extraction
class ExtractionProduct {
  final String id;
  final String nom;
  final ProductType type;
  final String origine; // Site de collecte
  final String collecteur;
  final DateTime dateAttribution;
  final DateTime? dateExtractionPrevue;
  final int quantiteContenants;
  final double poidsTotal; // en kg
  final ExtractionStatus statut;
  final ExtractionPriority priorite;
  final String? instructions;
  final String? commentaires;
  final Map<String, dynamic> qualite; // Données de qualité du contrôle
  final String attributeurId; // ID du contrôleur qui a attribué
  final String extracteurId; // ID de l'extracteur assigné
  final DateTime? dateDebutExtraction;
  final DateTime? dateFinExtraction;
  final double? rendementExtraction; // % de rendement
  final List<String> problemes; // Problèmes rencontrés
  final Map<String, String> resultats; // Résultats de l'extraction

  ExtractionProduct({
    required this.id,
    required this.nom,
    required this.type,
    required this.origine,
    required this.collecteur,
    required this.dateAttribution,
    this.dateExtractionPrevue,
    required this.quantiteContenants,
    required this.poidsTotal,
    required this.statut,
    required this.priorite,
    this.instructions,
    this.commentaires,
    required this.qualite,
    required this.attributeurId,
    required this.extracteurId,
    this.dateDebutExtraction,
    this.dateFinExtraction,
    this.rendementExtraction,
    this.problemes = const [],
    this.resultats = const {},
  });

  /// Copie avec modifications
  ExtractionProduct copyWith({
    String? id,
    String? nom,
    ProductType? type,
    String? origine,
    String? collecteur,
    DateTime? dateAttribution,
    DateTime? dateExtractionPrevue,
    int? quantiteContenants,
    double? poidsTotal,
    ExtractionStatus? statut,
    ExtractionPriority? priorite,
    String? instructions,
    String? commentaires,
    Map<String, dynamic>? qualite,
    String? attributeurId,
    String? extracteurId,
    DateTime? dateDebutExtraction,
    DateTime? dateFinExtraction,
    double? rendementExtraction,
    List<String>? problemes,
    Map<String, String>? resultats,
  }) {
    return ExtractionProduct(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      type: type ?? this.type,
      origine: origine ?? this.origine,
      collecteur: collecteur ?? this.collecteur,
      dateAttribution: dateAttribution ?? this.dateAttribution,
      dateExtractionPrevue: dateExtractionPrevue ?? this.dateExtractionPrevue,
      quantiteContenants: quantiteContenants ?? this.quantiteContenants,
      poidsTotal: poidsTotal ?? this.poidsTotal,
      statut: statut ?? this.statut,
      priorite: priorite ?? this.priorite,
      instructions: instructions ?? this.instructions,
      commentaires: commentaires ?? this.commentaires,
      qualite: qualite ?? this.qualite,
      attributeurId: attributeurId ?? this.attributeurId,
      extracteurId: extracteurId ?? this.extracteurId,
      dateDebutExtraction: dateDebutExtraction ?? this.dateDebutExtraction,
      dateFinExtraction: dateFinExtraction ?? this.dateFinExtraction,
      rendementExtraction: rendementExtraction ?? this.rendementExtraction,
      problemes: problemes ?? this.problemes,
      resultats: resultats ?? this.resultats,
    );
  }

  /// Conversion vers Map pour serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'type': type.value,
      'origine': origine,
      'collecteur': collecteur,
      'dateAttribution': dateAttribution.toIso8601String(),
      'dateExtractionPrevue': dateExtractionPrevue?.toIso8601String(),
      'quantiteContenants': quantiteContenants,
      'poidsTotal': poidsTotal,
      'statut': statut.value,
      'priorite': priorite.value,
      'instructions': instructions,
      'commentaires': commentaires,
      'qualite': qualite,
      'attributeurId': attributeurId,
      'extracteurId': extracteurId,
      'dateDebutExtraction': dateDebutExtraction?.toIso8601String(),
      'dateFinExtraction': dateFinExtraction?.toIso8601String(),
      'rendementExtraction': rendementExtraction,
      'problemes': problemes,
      'resultats': resultats,
    };
  }

  /// Création depuis Map
  factory ExtractionProduct.fromMap(Map<String, dynamic> map) {
    return ExtractionProduct(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      type: ProductType.values.firstWhere(
        (t) => t.value == map['type'],
        orElse: () => ProductType.mielBrut,
      ),
      origine: map['origine'] ?? '',
      collecteur: map['collecteur'] ?? '',
      dateAttribution: DateTime.parse(map['dateAttribution']),
      dateExtractionPrevue: map['dateExtractionPrevue'] != null
          ? DateTime.parse(map['dateExtractionPrevue'])
          : null,
      quantiteContenants: map['quantiteContenants'] ?? 0,
      poidsTotal: (map['poidsTotal'] ?? 0.0).toDouble(),
      statut: ExtractionStatus.values.firstWhere(
        (s) => s.value == map['statut'],
        orElse: () => ExtractionStatus.enAttente,
      ),
      priorite: ExtractionPriority.values.firstWhere(
        (p) => p.value == map['priorite'],
        orElse: () => ExtractionPriority.normale,
      ),
      instructions: map['instructions'],
      commentaires: map['commentaires'],
      qualite: Map<String, dynamic>.from(map['qualite'] ?? {}),
      attributeurId: map['attributeurId'] ?? '',
      extracteurId: map['extracteurId'] ?? '',
      dateDebutExtraction: map['dateDebutExtraction'] != null
          ? DateTime.parse(map['dateDebutExtraction'])
          : null,
      dateFinExtraction: map['dateFinExtraction'] != null
          ? DateTime.parse(map['dateFinExtraction'])
          : null,
      rendementExtraction: map['rendementExtraction']?.toDouble(),
      problemes: List<String>.from(map['problemes'] ?? []),
      resultats: Map<String, String>.from(map['resultats'] ?? {}),
    );
  }
}

/// Filtres pour la page d'extraction
class ExtractionFilters {
  final List<ExtractionStatus> statuts;
  final List<ExtractionPriority> priorites;
  final List<ProductType> types;
  final List<String> origines;
  final List<String> extracteurs;
  final DateTime? dateDebutFrom;
  final DateTime? dateDebutTo;
  final DateTime? dateFinFrom;
  final DateTime? dateFinTo;
  final double? poidsMin;
  final double? poidsMax;
  final double? rendementMin;
  final double? rendementMax;
  final String searchQuery;

  ExtractionFilters({
    this.statuts = const [],
    this.priorites = const [],
    this.types = const [],
    this.origines = const [],
    this.extracteurs = const [],
    this.dateDebutFrom,
    this.dateDebutTo,
    this.dateFinFrom,
    this.dateFinTo,
    this.poidsMin,
    this.poidsMax,
    this.rendementMin,
    this.rendementMax,
    this.searchQuery = '',
  });

  /// Copie avec modifications
  ExtractionFilters copyWith({
    List<ExtractionStatus>? statuts,
    List<ExtractionPriority>? priorites,
    List<ProductType>? types,
    List<String>? origines,
    List<String>? extracteurs,
    DateTime? dateDebutFrom,
    DateTime? dateDebutTo,
    DateTime? dateFinFrom,
    DateTime? dateFinTo,
    double? poidsMin,
    double? poidsMax,
    double? rendementMin,
    double? rendementMax,
    String? searchQuery,
  }) {
    return ExtractionFilters(
      statuts: statuts ?? this.statuts,
      priorites: priorites ?? this.priorites,
      types: types ?? this.types,
      origines: origines ?? this.origines,
      extracteurs: extracteurs ?? this.extracteurs,
      dateDebutFrom: dateDebutFrom ?? this.dateDebutFrom,
      dateDebutTo: dateDebutTo ?? this.dateDebutTo,
      dateFinFrom: dateFinFrom ?? this.dateFinFrom,
      dateFinTo: dateFinTo ?? this.dateFinTo,
      poidsMin: poidsMin ?? this.poidsMin,
      poidsMax: poidsMax ?? this.poidsMax,
      rendementMin: rendementMin ?? this.rendementMin,
      rendementMax: rendementMax ?? this.rendementMax,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Réinitialiser tous les filtres
  ExtractionFilters clear() {
    return ExtractionFilters();
  }

  /// Compte le nombre de filtres actifs
  int getActiveFiltersCount() {
    int count = 0;
    if (statuts.isNotEmpty) count++;
    if (priorites.isNotEmpty) count++;
    if (types.isNotEmpty) count++;
    if (origines.isNotEmpty) count++;
    if (extracteurs.isNotEmpty) count++;
    if (dateDebutFrom != null || dateDebutTo != null) count++;
    if (dateFinFrom != null || dateFinTo != null) count++;
    if (poidsMin != null || poidsMax != null) count++;
    if (rendementMin != null || rendementMax != null) count++;
    if (searchQuery.isNotEmpty) count++;
    return count;
  }

  /// Vérifie si des filtres sont appliqués
  bool get hasActiveFilters => getActiveFiltersCount() > 0;
}

/// Statistiques d'extraction
class ExtractionStats {
  final int totalProduits;
  final int enAttente;
  final int enCours;
  final int termines;
  final int suspendus;
  final int erreurs;
  final double poidsTotal;
  final double rendementMoyen;
  final int produitsUrgents;
  final Duration tempsExtractionMoyen;

  ExtractionStats({
    required this.totalProduits,
    required this.enAttente,
    required this.enCours,
    required this.termines,
    required this.suspendus,
    required this.erreurs,
    required this.poidsTotal,
    required this.rendementMoyen,
    required this.produitsUrgents,
    required this.tempsExtractionMoyen,
  });

  /// Calcule les statistiques à partir d'une liste de produits
  factory ExtractionStats.fromProducts(List<ExtractionProduct> products) {
    final total = products.length;
    final enAttente =
        products.where((p) => p.statut == ExtractionStatus.enAttente).length;
    final enCours =
        products.where((p) => p.statut == ExtractionStatus.enCours).length;
    final termines =
        products.where((p) => p.statut == ExtractionStatus.termine).length;
    final suspendus =
        products.where((p) => p.statut == ExtractionStatus.suspendu).length;
    final erreurs =
        products.where((p) => p.statut == ExtractionStatus.erreur).length;
    final poidsTotal = products.fold(0.0, (sum, p) => sum + p.poidsTotal);
    final urgents =
        products.where((p) => p.priorite == ExtractionPriority.urgente).length;

    // Calcul du rendement moyen
    final produitsAvecRendement =
        products.where((p) => p.rendementExtraction != null).toList();
    final rendementMoyen = produitsAvecRendement.isEmpty
        ? 0.0
        : produitsAvecRendement.fold(
                0.0, (sum, p) => sum + p.rendementExtraction!) /
            produitsAvecRendement.length;

    // Calcul du temps moyen d'extraction
    final produitsTermines = products
        .where((p) =>
            p.statut == ExtractionStatus.termine &&
            p.dateDebutExtraction != null &&
            p.dateFinExtraction != null)
        .toList();

    Duration tempsMoyen = Duration.zero;
    if (produitsTermines.isNotEmpty) {
      final dureeTotal = produitsTermines.fold(
          0,
          (sum, p) =>
              sum +
              p.dateFinExtraction!
                  .difference(p.dateDebutExtraction!)
                  .inMinutes);
      tempsMoyen =
          Duration(minutes: (dureeTotal / produitsTermines.length).round());
    }

    return ExtractionStats(
      totalProduits: total,
      enAttente: enAttente,
      enCours: enCours,
      termines: termines,
      suspendus: suspendus,
      erreurs: erreurs,
      poidsTotal: poidsTotal,
      rendementMoyen: rendementMoyen,
      produitsUrgents: urgents,
      tempsExtractionMoyen: tempsMoyen,
    );
  }
}
