/// 🎯 MODÈLES DE DONNÉES POUR LE MODULE CONDITIONNEMENT
///
/// Modèles optimisés pour un workflow de conditionnement moderne
/// avec calculs automatiques et validation stricte

import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum pour les modes de vente
enum VenteMode {
  detail('Détail', 'Vente à l\'unité'),
  paquet('Paquet', 'Paquet de 10'),
  carton('Carton', 'Carton de 200'),
  gros('Gros', 'Vente en gros');

  const VenteMode(this.label, this.description);
  final String label;
  final String description;
}

/// Enum pour les types de florale
enum TypeFlorale {
  monoFleur('Mono-fleur', 'Une seule essence florale'),
  milleFleurs('Mille fleurs', 'Mélange de plusieurs essences'),
  mixte('Mixte', 'Combinaison d\'essences spécifiques');

  const TypeFlorale(this.label, this.description);
  final String label;
  final String description;
}

/// Modèle d'emballage disponible
class EmballageType {
  final String id;
  final String nom;
  final double contenanceKg;
  final double prixUnitaireMilleFleurs;
  final double prixUnitaireMonoFleur;
  final VenteMode modeVenteObligatoire;
  final int multiplicateur; // Pour les paquets/cartons
  final String icone;
  final String couleur;

  const EmballageType({
    required this.id,
    required this.nom,
    required this.contenanceKg,
    required this.prixUnitaireMilleFleurs,
    required this.prixUnitaireMonoFleur,
    required this.modeVenteObligatoire,
    this.multiplicateur = 1,
    required this.icone,
    required this.couleur,
  });

  /// Prix selon le type de florale
  double getPrix(TypeFlorale typeFlorale) {
    switch (typeFlorale) {
      case TypeFlorale.monoFleur:
        return prixUnitaireMonoFleur;
      case TypeFlorale.milleFleurs:
      case TypeFlorale.mixte:
        return prixUnitaireMilleFleurs;
    }
  }

  /// Calcul du nombre d'unités réelles (avec multiplicateur)
  int getNombreUnitesReelles(int nombreSaisi) {
    return nombreSaisi * multiplicateur;
  }

  /// Calcul du poids total
  double getPoidsTotal(int nombreSaisi) {
    return getNombreUnitesReelles(nombreSaisi) * contenanceKg;
  }

  /// Calcul du prix total
  double getPrixTotal(int nombreSaisi, TypeFlorale typeFlorale) {
    return nombreSaisi * getPrix(typeFlorale);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'contenanceKg': contenanceKg,
      'prixUnitaireMilleFleurs': prixUnitaireMilleFleurs,
      'prixUnitaireMonoFleur': prixUnitaireMonoFleur,
      'modeVenteObligatoire': modeVenteObligatoire.label,
      'multiplicateur': multiplicateur,
      'icone': icone,
      'couleur': couleur,
    };
  }
}

/// Configuration des emballages disponibles
class EmballagesConfig {
  static const List<EmballageType> emballagesDisponibles = [
    EmballageType(
      id: 'pot_1_5kg',
      nom: '1.5Kg',
      contenanceKg: 1.5,
      prixUnitaireMilleFleurs: 4500,
      prixUnitaireMonoFleur: 6000,
      modeVenteObligatoire: VenteMode.gros,
      icone: '🍯',
      couleur: '#FF8C00',
    ),
    EmballageType(
      id: 'pot_1kg',
      nom: '1Kg',
      contenanceKg: 1.0,
      prixUnitaireMilleFleurs: 3400,
      prixUnitaireMonoFleur: 5000,
      modeVenteObligatoire: VenteMode.gros,
      icone: '🍯',
      couleur: '#FFB347',
    ),
    EmballageType(
      id: 'pot_720g',
      nom: '720g',
      contenanceKg: 0.72,
      prixUnitaireMilleFleurs: 2500,
      prixUnitaireMonoFleur: 3500,
      modeVenteObligatoire: VenteMode.gros,
      icone: '🍯',
      couleur: '#FFDC8C',
    ),
    EmballageType(
      id: 'pot_500g',
      nom: '500g',
      contenanceKg: 0.5,
      prixUnitaireMilleFleurs: 1800,
      prixUnitaireMonoFleur: 3000,
      modeVenteObligatoire: VenteMode.gros,
      icone: '🍯',
      couleur: '#FFE55C',
    ),
    EmballageType(
      id: 'pot_250g',
      nom: '250g',
      contenanceKg: 0.25,
      prixUnitaireMilleFleurs: 950,
      prixUnitaireMonoFleur: 1750,
      modeVenteObligatoire: VenteMode.gros,
      icone: '🍯',
      couleur: '#FFEF94',
    ),
    EmballageType(
      id: 'bidon_7kg',
      nom: '7kg',
      contenanceKg: 7.0,
      prixUnitaireMilleFleurs: 23000,
      prixUnitaireMonoFleur: 34000,
      modeVenteObligatoire: VenteMode.gros,
      icone: '🪣',
      couleur: '#8B4513',
    ),
    EmballageType(
      id: 'stick_20g',
      nom: 'Stick 20g',
      contenanceKg: 0.02,
      prixUnitaireMilleFleurs: 1500, // Prix pour un paquet de 10
      prixUnitaireMonoFleur: 1500,
      modeVenteObligatoire: VenteMode.paquet,
      multiplicateur: 10,
      icone: '🍯',
      couleur: '#FFA500',
    ),
    EmballageType(
      id: 'pot_alveoles_30g',
      nom: 'Pot alvéoles 30g',
      contenanceKg: 0.03,
      prixUnitaireMilleFleurs: 36000, // Prix pour un carton de 200
      prixUnitaireMonoFleur: 36000,
      modeVenteObligatoire: VenteMode.carton,
      multiplicateur: 200,
      icone: '🍯',
      couleur: '#DAA520',
    ),
  ];

  /// Obtient un emballage par son ID
  static EmballageType? getEmballageById(String id) {
    try {
      return emballagesDisponibles.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// Modèle pour un emballage sélectionné dans le conditionnement
class EmballageSelectionne {
  final EmballageType type;
  final int nombreSaisi;
  final TypeFlorale typeFlorale;

  const EmballageSelectionne({
    required this.type,
    required this.nombreSaisi,
    required this.typeFlorale,
  });

  /// Nombre d'unités réelles (avec multiplicateur)
  int get nombreUnitesReelles => type.getNombreUnitesReelles(nombreSaisi);

  /// Poids total de cet emballage
  double get poidsTotal => type.getPoidsTotal(nombreSaisi);

  /// Prix total de cet emballage
  double get prixTotal => type.getPrixTotal(nombreSaisi, typeFlorale);

  /// Description du mode de vente
  String get descriptionMode {
    switch (type.modeVenteObligatoire) {
      case VenteMode.paquet:
        return 'Paquet ($nombreSaisi × 10 = $nombreUnitesReelles sticks)';
      case VenteMode.carton:
        return 'Carton ($nombreSaisi × 200 = $nombreUnitesReelles pots)';
      case VenteMode.gros:
        return 'Gros ($nombreUnitesReelles unités)';
      case VenteMode.detail:
        return 'Détail ($nombreUnitesReelles unités)';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.nom,
      'typeId': type.id,
      'mode': type.modeVenteObligatoire.label,
      'nombreSaisi': nombreSaisi,
      'nombreUnitesReelles': nombreUnitesReelles,
      'contenanceKg': type.contenanceKg,
      'prixUnitaire': type.getPrix(typeFlorale),
      'prixTotal': prixTotal,
      'poidsTotal': poidsTotal,
      'description': descriptionMode,
    };
  }
}

/// Modèle principal pour un lot filtré disponible au conditionnement
class LotFiltre {
  final String id;
  final String lotOrigine;
  final String collecteId;
  final double quantiteRecue;
  final double quantiteRestante;
  final String predominanceFlorale;
  final DateTime dateFiltrage;
  final String? dateExpirationFiltrage;
  final bool estConditionne;
  final DateTime? dateConditionnement;
  final String site;
  final String technicien;

  const LotFiltre({
    required this.id,
    required this.lotOrigine,
    required this.collecteId,
    required this.quantiteRecue,
    required this.quantiteRestante,
    required this.predominanceFlorale,
    required this.dateFiltrage,
    this.dateExpirationFiltrage,
    this.estConditionne = false,
    this.dateConditionnement,
    required this.site,
    required this.technicien,
  });

  /// Détermine le type de florale
  TypeFlorale get typeFlorale {
    final florale = predominanceFlorale.toLowerCase();
    if (florale.contains('mono') ||
        (!florale.contains('mille') &&
            !florale.contains('mixte') &&
            !florale.contains('+') &&
            !florale.contains(',') &&
            florale.trim().isNotEmpty)) {
      return TypeFlorale.monoFleur;
    } else if (florale.contains('mille')) {
      return TypeFlorale.milleFleurs;
    } else {
      return TypeFlorale.mixte;
    }
  }

  /// Vérifie si le filtrage a expiré (par défaut 30 jours)
  bool get filtrageExpire {
    if (dateExpirationFiltrage != null) {
      return DateTime.now().isAfter(DateTime.parse(dateExpirationFiltrage!));
    }
    // Par défaut, expire après 30 jours
    return DateTime.now().difference(dateFiltrage).inDays > 30;
  }

  /// Peut être conditionné
  bool get peutEtreConditionne {
    return !estConditionne && !filtrageExpire && quantiteRestante > 0;
  }

  factory LotFiltre.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LotFiltre(
      id: doc.id,
      lotOrigine: data['lot']?.toString() ?? '',
      collecteId: data['collecteId']?.toString() ?? '',
      quantiteRecue:
          (data['quantiteFiltree'] ?? data['quantiteFiltrée'] ?? 0).toDouble(),
      quantiteRestante: (data['quantiteRestante'] ?? 0).toDouble(),
      predominanceFlorale:
          data['predominanceFlorale']?.toString() ?? 'Mille fleurs',
      dateFiltrage:
          (data['dateFiltrage'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateExpirationFiltrage: data['dateExpirationFiltrage']?.toString(),
      estConditionne: data['statutConditionnement'] == 'Conditionné',
      dateConditionnement:
          (data['dateConditionnement'] as Timestamp?)?.toDate(),
      site: data['site']?.toString() ?? '',
      technicien: data['technicien']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lotOrigine': lotOrigine,
      'collecteId': collecteId,
      'quantiteRecue': quantiteRecue,
      'quantiteRestante': quantiteRestante,
      'predominanceFlorale': predominanceFlorale,
      'dateFiltrage': Timestamp.fromDate(dateFiltrage),
      'dateExpirationFiltrage': dateExpirationFiltrage,
      'estConditionne': estConditionne,
      'dateConditionnement': dateConditionnement != null
          ? Timestamp.fromDate(dateConditionnement!)
          : null,
      'site': site,
      'technicien': technicien,
    };
  }
}

/// Modèle principal pour un conditionnement complet
class ConditionnementData {
  final String id;
  final DateTime dateConditionnement;
  final LotFiltre lotOrigine;
  final List<EmballageSelectionne> emballages;
  final double quantiteConditionnee;
  final double quantiteRestante;
  final double prixTotal;
  final int nbTotalPots;
  final DateTime createdAt;
  final String? observations;

  const ConditionnementData({
    required this.id,
    required this.dateConditionnement,
    required this.lotOrigine,
    required this.emballages,
    required this.quantiteConditionnee,
    required this.quantiteRestante,
    required this.prixTotal,
    required this.nbTotalPots,
    required this.createdAt,
    this.observations,
  });

  /// Validation stricte : quantité conditionnée ≤ quantité reçue (écart ≤ 10kg)
  bool get estValide {
    final ecart = lotOrigine.quantiteRecue - quantiteConditionnee;
    return ecart >= -10.0 && ecart <= lotOrigine.quantiteRecue;
  }

  /// Pourcentage de conditionnement
  double get pourcentageConditionne {
    if (lotOrigine.quantiteRecue == 0) return 0;
    return (quantiteConditionnee / lotOrigine.quantiteRecue * 100)
        .clamp(0, 100);
  }

  /// Récapitulatif par type d'emballage
  Map<String, int> get recapitulatifEmballages {
    final recap = <String, int>{};
    for (final emb in emballages) {
      recap[emb.type.nom] =
          (recap[emb.type.nom] ?? 0) + emb.nombreUnitesReelles;
    }
    return recap;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(dateConditionnement),
      'lotFiltrageId': lotOrigine.id,
      'collecteId': lotOrigine.collecteId,
      'lotOrigine': lotOrigine.lotOrigine,
      'predominanceFlorale': lotOrigine.predominanceFlorale,
      'quantiteRecue': lotOrigine.quantiteRecue,
      'quantiteConditionnee': quantiteConditionnee,
      'quantiteRestante': quantiteRestante,
      'emballages': emballages.map((e) => e.toMap()).toList(),
      'nbTotalPots': nbTotalPots,
      'prixTotal': prixTotal,
      'createdAt': Timestamp.fromDate(createdAt),
      'observations': observations,
      'typeFlorale': lotOrigine.typeFlorale.label,
      'site': lotOrigine.site,
      'technicien': lotOrigine.technicien,
    };
  }

  factory ConditionnementData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Reconstruction du lot (données minimales)
    final lotOrigine = LotFiltre(
      id: data['lotFiltrageId'] ?? '',
      lotOrigine: data['lotOrigine'] ?? '',
      collecteId: data['collecteId'] ?? '',
      quantiteRecue: (data['quantiteRecue'] ?? 0).toDouble(),
      quantiteRestante: (data['quantiteRestante'] ?? 0).toDouble(),
      predominanceFlorale: data['predominanceFlorale'] ?? '',
      dateFiltrage: DateTime.now(), // Placeholder
      site: data['site'] ?? '',
      technicien: data['technicien'] ?? '',
      estConditionne: true,
    );

    // Reconstruction des emballages
    final emballagesList = (data['emballages'] as List<dynamic>? ?? []);
    final emballages = <EmballageSelectionne>[];

    for (final embData in emballagesList) {
      final typeId = embData['typeId'] ?? embData['type'];
      final emballageType = EmballagesConfig.getEmballageById(typeId);
      if (emballageType != null) {
        emballages.add(EmballageSelectionne(
          type: emballageType,
          nombreSaisi: embData['nombreSaisi'] ?? 0,
          typeFlorale: lotOrigine.typeFlorale,
        ));
      }
    }

    return ConditionnementData(
      id: doc.id,
      dateConditionnement: (data['date'] as Timestamp).toDate(),
      lotOrigine: lotOrigine,
      emballages: emballages,
      quantiteConditionnee: (data['quantiteConditionnee'] ?? 0).toDouble(),
      quantiteRestante: (data['quantiteRestante'] ?? 0).toDouble(),
      prixTotal: (data['prixTotal'] ?? 0).toDouble(),
      nbTotalPots: data['nbTotalPots'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      observations: data['observations'],
    );
  }
}

/// Utilitaires pour le conditionnement
class ConditionnementUtils {
  /// Couleurs par type de florale
  static const Map<TypeFlorale, String> couleursByFlorale = {
    TypeFlorale.monoFleur: '#FF6B35',
    TypeFlorale.milleFleurs: '#F7931E',
    TypeFlorale.mixte: '#FFD23F',
  };

  /// Icônes par type de florale
  static const Map<TypeFlorale, String> iconesByFlorale = {
    TypeFlorale.monoFleur: '🌺',
    TypeFlorale.milleFleurs: '🌻',
    TypeFlorale.mixte: '🌼',
  };

  /// Formatage des prix
  static String formatPrix(double prix) {
    return '${prix.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        )} FCFA';
  }

  /// Formatage des quantités
  static String formatQuantite(double quantite) {
    return '${quantite.toStringAsFixed(2)} kg';
  }

  /// Validation des données de conditionnement
  static List<String> validerConditionnement(
      ConditionnementData conditionnement) {
    final erreurs = <String>[];

    if (conditionnement.emballages.isEmpty) {
      erreurs.add('Au moins un emballage doit être sélectionné');
    }

    if (conditionnement.quantiteConditionnee <= 0) {
      erreurs.add('La quantité conditionnée doit être positive');
    }

    if (!conditionnement.estValide) {
      erreurs.add(
          'La quantité conditionnée dépasse la quantité reçue de plus de 10kg');
    }

    if (conditionnement.prixTotal <= 0) {
      erreurs.add('Le prix total doit être positif');
    }

    return erreurs;
  }
}
