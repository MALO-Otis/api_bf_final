import '../../controle_de_donnes/models/attribution_models_v2.dart';

/// 🔵 MODÈLES AMÉLIORÉS POUR LE FILTRAGE
///
/// Ces modèles s'intègrent parfaitement avec le nouveau système
/// d'attribution unifié pour une gestion complète des filtrages

/// Statut d'un processus de filtrage
enum FiltrageStatus {
  enAttente('En Attente', 'waiting'),
  enCours('En Cours', 'in_progress'),
  suspendu('Suspendu', 'suspended'),
  termine('Terminé', 'completed'),
  erreur('Erreur', 'error');

  const FiltrageStatus(this.label, this.value);
  final String label;
  final String value;
}

/// Méthodes de filtrage disponibles
enum MethodeFiltrage {
  grossier('Filtrage Grossier', 'coarse'),
  fin('Filtrage Fin', 'fine'),
  ultraFin('Filtrage Ultra-Fin', 'ultra_fine'),
  membrane('Filtrage Membrane', 'membrane'),
  charbon('Filtrage Charbon', 'carbon');

  const MethodeFiltrage(this.label, this.value);
  final String label;
  final String value;
}

/// Niveaux de limpidité
enum NiveauLimpidite {
  trouble('Trouble', 'cloudy'),
  legerementTrouble('Légèrement Trouble', 'slightly_cloudy'),
  clair('Clair', 'clear'),
  cristallin('Cristallin', 'crystal_clear');

  const NiveauLimpidite(this.label, this.value);
  final String label;
  final String value;
}

/// Modèle pour un processus de filtrage en cours
class FiltrageProcess {
  final String id;
  final ProductControle produit;
  final String agentFiltrage;
  final DateTime dateDebut;
  final FiltrageStatus statut;
  final String methodeFiltrage;
  final String? instructions;
  final String? observations;
  final DateTime? dateSuspension;
  final String site;
  final Map<String, dynamic>? parametres;
  final Map<String, dynamic>? metadata;

  const FiltrageProcess({
    required this.id,
    required this.produit,
    required this.agentFiltrage,
    required this.dateDebut,
    required this.statut,
    required this.methodeFiltrage,
    this.instructions,
    this.observations,
    this.dateSuspension,
    required this.site,
    this.parametres,
    this.metadata,
  });

  /// Durée écoulée depuis le début
  Duration get dureeEcoulee => DateTime.now().difference(dateDebut);

  /// Vérifie si le filtrage est urgent (> 3h)
  bool get isUrgent => dureeEcoulee.inHours > 3;

  /// Estime le temps restant basé sur la méthode
  Duration get tempsEstimeRestant {
    switch (methodeFiltrage) {
      case 'Filtrage Grossier':
        return const Duration(minutes: 30);
      case 'Filtrage Fin':
        return const Duration(hours: 1);
      case 'Filtrage Ultra-Fin':
        return const Duration(hours: 2);
      case 'Filtrage Membrane':
        return const Duration(hours: 3);
      case 'Filtrage Charbon':
        return const Duration(hours: 4);
      default:
        return const Duration(hours: 1);
    }
  }

  /// Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'produit': produit.toMap(),
      'agentFiltrage': agentFiltrage,
      'dateDebut': dateDebut.toIso8601String(),
      'statut': statut.value,
      'methodeFiltrage': methodeFiltrage,
      'instructions': instructions,
      'observations': observations,
      'dateSuspension': dateSuspension?.toIso8601String(),
      'site': site,
      'parametres': parametres,
      'metadata': metadata,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// Création depuis Map Firestore
  factory FiltrageProcess.fromMap(Map<String, dynamic> map) {
    return FiltrageProcess(
      id: map['id'] ?? '',
      produit: ProductControle.fromMap(map['produit'] ?? {}),
      agentFiltrage: map['agentFiltrage'] ?? '',
      dateDebut:
          DateTime.parse(map['dateDebut'] ?? DateTime.now().toIso8601String()),
      statut: FiltrageStatus.values.firstWhere(
        (s) => s.value == map['statut'],
        orElse: () => FiltrageStatus.enAttente,
      ),
      methodeFiltrage: map['methodeFiltrage'] ?? '',
      instructions: map['instructions'],
      observations: map['observations'],
      dateSuspension: map['dateSuspension'] != null
          ? DateTime.parse(map['dateSuspension'])
          : null,
      site: map['site'] ?? '',
      parametres: map['parametres'],
      metadata: map['metadata'],
    );
  }

  /// Crée une copie avec des modifications
  FiltrageProcess copyWith({
    String? id,
    ProductControle? produit,
    String? agentFiltrage,
    DateTime? dateDebut,
    FiltrageStatus? statut,
    String? methodeFiltrage,
    String? instructions,
    String? observations,
    DateTime? dateSuspension,
    String? site,
    Map<String, dynamic>? parametres,
    Map<String, dynamic>? metadata,
  }) {
    return FiltrageProcess(
      id: id ?? this.id,
      produit: produit ?? this.produit,
      agentFiltrage: agentFiltrage ?? this.agentFiltrage,
      dateDebut: dateDebut ?? this.dateDebut,
      statut: statut ?? this.statut,
      methodeFiltrage: methodeFiltrage ?? this.methodeFiltrage,
      instructions: instructions ?? this.instructions,
      observations: observations ?? this.observations,
      dateSuspension: dateSuspension ?? this.dateSuspension,
      site: site ?? this.site,
      parametres: parametres ?? this.parametres,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Modèle pour le résultat d'un filtrage terminé
class FiltrageResult {
  final String id;
  final ProductControle produit;
  final String agentFiltrage;
  final DateTime dateDebut;
  final DateTime dateFin;
  final Duration duree;
  final double volumeInitial;
  final double volumeFiltre;
  final double rendement; // Pourcentage
  final String methodeFiltrage;
  final String qualiteFinale;
  final String limpidite;
  final String? observations;
  final String site;
  final Map<String, dynamic>? analyses;
  final bool isValidated;
  final double? teneurEauFinale;
  final String? couleur;

  const FiltrageResult({
    required this.id,
    required this.produit,
    required this.agentFiltrage,
    required this.dateDebut,
    required this.dateFin,
    required this.duree,
    required this.volumeInitial,
    required this.volumeFiltre,
    required this.rendement,
    required this.methodeFiltrage,
    required this.qualiteFinale,
    required this.limpidite,
    this.observations,
    required this.site,
    this.analyses,
    this.isValidated = false,
    this.teneurEauFinale,
    this.couleur,
  });

  /// Calcule le taux de perte
  double get tauxPerte => volumeInitial > 0
      ? ((volumeInitial - volumeFiltre) / volumeInitial) * 100
      : 0.0;

  /// Évalue la qualité du rendement
  String get evaluationRendement {
    if (rendement >= 95) return 'Excellent';
    if (rendement >= 90) return 'Très Bon';
    if (rendement >= 85) return 'Bon';
    if (rendement >= 80) return 'Acceptable';
    return 'Faible';
  }

  /// Évalue l'efficacité globale
  String get efficaciteGlobale {
    final scoreRendement = rendement >= 90
        ? 3
        : rendement >= 85
            ? 2
            : 1;
    final scoreQualite = qualiteFinale == 'Excellent'
        ? 3
        : qualiteFinale == 'Très Bon'
            ? 2
            : 1;
    final scoreLimpidite = limpidite == 'Cristallin'
        ? 3
        : limpidite == 'Clair'
            ? 2
            : 1;
    final scoreDuree = duree.inHours <= 2
        ? 3
        : duree.inHours <= 4
            ? 2
            : 1;

    final scoreTotal =
        (scoreRendement + scoreQualite + scoreLimpidite + scoreDuree) / 4;

    if (scoreTotal >= 2.5) return 'Excellente';
    if (scoreTotal >= 2.0) return 'Très Bonne';
    if (scoreTotal >= 1.5) return 'Bonne';
    return 'À Améliorer';
  }

  /// Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'produit': produit.toMap(),
      'agentFiltrage': agentFiltrage,
      'dateDebut': dateDebut.toIso8601String(),
      'dateFin': dateFin.toIso8601String(),
      'dureeMinutes': duree.inMinutes,
      'volumeInitial': volumeInitial,
      'volumeFiltre': volumeFiltre,
      'rendement': rendement,
      'tauxPerte': tauxPerte,
      'methodeFiltrage': methodeFiltrage,
      'qualiteFinale': qualiteFinale,
      'limpidite': limpidite,
      'observations': observations,
      'site': site,
      'analyses': analyses,
      'isValidated': isValidated,
      'teneurEauFinale': teneurEauFinale,
      'couleur': couleur,
      'efficaciteGlobale': efficaciteGlobale,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// Création depuis Map Firestore
  factory FiltrageResult.fromMap(Map<String, dynamic> map) {
    return FiltrageResult(
      id: map['id'] ?? '',
      produit: ProductControle.fromMap(map['produit'] ?? {}),
      agentFiltrage: map['agentFiltrage'] ?? '',
      dateDebut:
          DateTime.parse(map['dateDebut'] ?? DateTime.now().toIso8601String()),
      dateFin:
          DateTime.parse(map['dateFin'] ?? DateTime.now().toIso8601String()),
      duree: Duration(minutes: map['dureeMinutes'] ?? 0),
      volumeInitial: (map['volumeInitial'] as num?)?.toDouble() ?? 0.0,
      volumeFiltre: (map['volumeFiltre'] as num?)?.toDouble() ?? 0.0,
      rendement: (map['rendement'] as num?)?.toDouble() ?? 0.0,
      methodeFiltrage: map['methodeFiltrage'] ?? '',
      qualiteFinale: map['qualiteFinale'] ?? '',
      limpidite: map['limpidite'] ?? '',
      observations: map['observations'],
      site: map['site'] ?? '',
      analyses: map['analyses'],
      isValidated: map['isValidated'] ?? false,
      teneurEauFinale: (map['teneurEauFinale'] as num?)?.toDouble(),
      couleur: map['couleur'],
    );
  }

  /// Crée une copie avec des modifications
  FiltrageResult copyWith({
    String? id,
    ProductControle? produit,
    String? agentFiltrage,
    DateTime? dateDebut,
    DateTime? dateFin,
    Duration? duree,
    double? volumeInitial,
    double? volumeFiltre,
    double? rendement,
    String? methodeFiltrage,
    String? qualiteFinale,
    String? limpidite,
    String? observations,
    String? site,
    Map<String, dynamic>? analyses,
    bool? isValidated,
    double? teneurEauFinale,
    String? couleur,
  }) {
    return FiltrageResult(
      id: id ?? this.id,
      produit: produit ?? this.produit,
      agentFiltrage: agentFiltrage ?? this.agentFiltrage,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      duree: duree ?? this.duree,
      volumeInitial: volumeInitial ?? this.volumeInitial,
      volumeFiltre: volumeFiltre ?? this.volumeFiltre,
      rendement: rendement ?? this.rendement,
      methodeFiltrage: methodeFiltrage ?? this.methodeFiltrage,
      qualiteFinale: qualiteFinale ?? this.qualiteFinale,
      limpidite: limpidite ?? this.limpidite,
      observations: observations ?? this.observations,
      site: site ?? this.site,
      analyses: analyses ?? this.analyses,
      isValidated: isValidated ?? this.isValidated,
      teneurEauFinale: teneurEauFinale ?? this.teneurEauFinale,
      couleur: couleur ?? this.couleur,
    );
  }
}

/// Modèle pour les statistiques de filtrage
class FiltrageStats {
  final int totalAttribues;
  final int enCours;
  final int termines;
  final int suspendus;
  final double volumeTotal;
  final double volumeFiltre;
  final double rendementMoyen;
  final Duration dureeMoyenne;
  final int urgents;
  final Map<String, int> parAgentFiltrage;
  final Map<String, int> parMethode;
  final Map<String, int> parQualite;
  final Map<String, int> parLimpidite;

  const FiltrageStats({
    required this.totalAttribues,
    required this.enCours,
    required this.termines,
    required this.suspendus,
    required this.volumeTotal,
    required this.volumeFiltre,
    required this.rendementMoyen,
    required this.dureeMoyenne,
    required this.urgents,
    required this.parAgentFiltrage,
    required this.parMethode,
    required this.parQualite,
    required this.parLimpidite,
  });

  /// Taux de completion
  double get tauxCompletion =>
      totalAttribues > 0 ? (termines / totalAttribues) * 100 : 0.0;

  /// Efficacité globale du filtrage
  String get efficaciteGlobale {
    if (tauxCompletion >= 95 && rendementMoyen >= 90) return 'Excellente';
    if (tauxCompletion >= 90 && rendementMoyen >= 85) return 'Très Bonne';
    if (tauxCompletion >= 80 && rendementMoyen >= 80) return 'Bonne';
    if (tauxCompletion >= 70 && rendementMoyen >= 75) return 'Acceptable';
    return 'À Améliorer';
  }

  /// Conversion vers Map
  Map<String, dynamic> toMap() {
    return {
      'totalAttribues': totalAttribues,
      'enCours': enCours,
      'termines': termines,
      'suspendus': suspendus,
      'volumeTotal': volumeTotal,
      'volumeFiltre': volumeFiltre,
      'rendementMoyen': rendementMoyen,
      'dureeMoyenneMinutes': dureeMoyenne.inMinutes,
      'urgents': urgents,
      'tauxCompletion': tauxCompletion,
      'efficaciteGlobale': efficaciteGlobale,
      'parAgentFiltrage': parAgentFiltrage,
      'parMethode': parMethode,
      'parQualite': parQualite,
      'parLimpidite': parLimpidite,
    };
  }
}

/// Filtres pour les filtrages
class FiltrageFilters {
  final String? agentFiltrage;
  final FiltrageStatus? statut;
  final String? methodeFiltrage;
  final String? qualiteFinale;
  final String? limpidite;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final double? rendementMin;
  final double? rendementMax;
  final bool? urgentOnly;
  final String? searchQuery;

  const FiltrageFilters({
    this.agentFiltrage,
    this.statut,
    this.methodeFiltrage,
    this.qualiteFinale,
    this.limpidite,
    this.dateDebut,
    this.dateFin,
    this.rendementMin,
    this.rendementMax,
    this.urgentOnly,
    this.searchQuery,
  });

  /// Vérifie si un processus correspond aux filtres
  bool matchesProcess(FiltrageProcess process) {
    if (agentFiltrage != null && process.agentFiltrage != agentFiltrage)
      return false;
    if (statut != null && process.statut != statut) return false;
    if (methodeFiltrage != null && process.methodeFiltrage != methodeFiltrage)
      return false;
    if (dateDebut != null && process.dateDebut.isBefore(dateDebut!))
      return false;
    if (urgentOnly == true && !process.isUrgent) return false;

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      if (!process.produit.producteur.toLowerCase().contains(query) &&
          !process.produit.codeContenant.toLowerCase().contains(query) &&
          !process.agentFiltrage.toLowerCase().contains(query)) {
        return false;
      }
    }

    return true;
  }

  /// Vérifie si un résultat correspond aux filtres
  bool matchesResult(FiltrageResult result) {
    if (agentFiltrage != null && result.agentFiltrage != agentFiltrage)
      return false;
    if (methodeFiltrage != null && result.methodeFiltrage != methodeFiltrage)
      return false;
    if (qualiteFinale != null && result.qualiteFinale != qualiteFinale)
      return false;
    if (limpidite != null && result.limpidite != limpidite) return false;
    if (dateDebut != null && result.dateFin.isBefore(dateDebut!)) return false;
    if (dateFin != null && result.dateFin.isAfter(dateFin!)) return false;
    if (rendementMin != null && result.rendement < rendementMin!) return false;
    if (rendementMax != null && result.rendement > rendementMax!) return false;

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      if (!result.produit.producteur.toLowerCase().contains(query) &&
          !result.produit.codeContenant.toLowerCase().contains(query) &&
          !result.agentFiltrage.toLowerCase().contains(query)) {
        return false;
      }
    }

    return true;
  }

  /// Compte le nombre de filtres actifs
  int get activeFiltersCount {
    int count = 0;
    if (agentFiltrage != null) count++;
    if (statut != null) count++;
    if (methodeFiltrage != null) count++;
    if (qualiteFinale != null) count++;
    if (limpidite != null) count++;
    if (dateDebut != null) count++;
    if (dateFin != null) count++;
    if (rendementMin != null) count++;
    if (rendementMax != null) count++;
    if (urgentOnly == true) count++;
    if (searchQuery?.isNotEmpty == true) count++;
    return count;
  }

  /// Crée une copie avec des modifications
  FiltrageFilters copyWith({
    String? agentFiltrage,
    FiltrageStatus? statut,
    String? methodeFiltrage,
    String? qualiteFinale,
    String? limpidite,
    DateTime? dateDebut,
    DateTime? dateFin,
    double? rendementMin,
    double? rendementMax,
    bool? urgentOnly,
    String? searchQuery,
  }) {
    return FiltrageFilters(
      agentFiltrage: agentFiltrage ?? this.agentFiltrage,
      statut: statut ?? this.statut,
      methodeFiltrage: methodeFiltrage ?? this.methodeFiltrage,
      qualiteFinale: qualiteFinale ?? this.qualiteFinale,
      limpidite: limpidite ?? this.limpidite,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      rendementMin: rendementMin ?? this.rendementMin,
      rendementMax: rendementMax ?? this.rendementMax,
      urgentOnly: urgentOnly ?? this.urgentOnly,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
