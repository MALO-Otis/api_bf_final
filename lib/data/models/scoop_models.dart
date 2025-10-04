import '../geographe/geographie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/localite_codification_service.dart';

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
  final String? codeLocalite; // NOUVEAU: Code de localité XX-XX-XX
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
    this.codeLocalite, // Sera généré automatiquement si null
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

    // Génération automatique du code localité si nécessaire
    String? codeLocalite = data['code_localite']?.toString();
    if (codeLocalite == null || codeLocalite.isEmpty) {
      codeLocalite = LocaliteCodificationService.generateCodeLocalite(
        regionNom: data['region']?.toString() ?? '',
        provinceNom: data['province']?.toString() ?? '',
        communeNom: data['commune']?.toString() ?? '',
      );
      print(
          '🔵 ScoopModel: Code localité généré automatiquement: $codeLocalite');
    }

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
      codeLocalite: codeLocalite,
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
    // Génération automatique du code localité si absent
    String? finalCodeLocalite = codeLocalite;
    if (finalCodeLocalite == null || finalCodeLocalite.isEmpty) {
      finalCodeLocalite = LocaliteCodificationService.generateCodeLocalite(
        regionNom: region,
        provinceNom: province,
        communeNom: commune,
      );
      print(
          '🔵 ScoopModel.toFirestore: Code localité généré: $finalCodeLocalite');
    }

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
      'code_localite': finalCodeLocalite, // NOUVEAU champ
      'nbRuchesTrad': nbRuchesTrad,
      'nbRuchesModernes': nbRuchesModernes,
      'nbMembres': nbMembres,
      'nbHommes': nbHommes,
      'nbFemmes': nbFemmes,
      'nbJeunes': nbJeunes,
      // Ajout: sauvegarde de l'effectif âge > 35 ans (calculé)
      'nbPlus35': (nbMembres - nbJeunes),
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

  String get codeLocalisation {
    // Créer une Map pour utiliser GeographieData.formatLocationCodeFromMap
    final Map<String, String> localisationMap = {
      'region': region,
      'province': province,
      'commune': commune,
      'village': village ?? '',
    };
    return GeographieData.formatLocationCodeFromMap(localisationMap);
  }

  String get localisationComplete {
    return '${codeLocalisation} | ${localisation}';
  }

  int get nbVieux => nbMembres - nbJeunes;
}

/// Types de contenants autorisés
enum ContenantType {
  seau('Seau'),
  bidon('Bidon'),
  fut('Fût'),
  sac('Sac');

  const ContenantType(this.label);
  final String label;

  /// Retourne les types de contenants disponibles selon le type de miel
  static List<ContenantType> getTypesForMiel(MielType typeMiel) {
    switch (typeMiel) {
      case MielType.liquide:
        // Pour le miel liquide: Bidon, Fût, Seau
        return [ContenantType.bidon, ContenantType.fut, ContenantType.seau];
      case MielType.brute:
        // Pour le miel brute: Fût, Seau (pas de Bidon)
        return [ContenantType.fut, ContenantType.seau];
      case MielType.cire:
        // Pour la cire, seul le sac est autorisé
        return [ContenantType.sac];
    }
  }
}

/// Types de miel autorisés
enum MielType {
  liquide('Liquide'),
  brute('Brute'),
  cire('Cire');

  const MielType(this.label);
  final String label;
}

/// Types de cire (pour quand le type de miel est 'cire')
enum TypeCire {
  brute('Brute'),
  purifiee('Purifiée');

  const TypeCire(this.label);
  final String label;
}

/// Couleurs de cire (pour quand le type de cire est 'purifiée')
enum CouleurCire {
  jaune('Jaune'),
  marron('Marron');

  const CouleurCire(this.label);
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
  final TypeCire? typeCire; // Quand typeMiel == cire
  final CouleurCire? couleurCire; // Quand typeCire == purifiée

  ContenantScoopModel({
    required this.id,
    required this.typeContenant,
    required this.typeMiel,
    required this.poids,
    required this.prix,
    this.notes,
    this.typeCire,
    this.couleurCire,
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
      typeCire: data['typeCire'] != null
          ? TypeCire.values.firstWhere(
              (type) => type.label == data['typeCire'],
              orElse: () => TypeCire.brute,
            )
          : null,
      couleurCire: data['couleurCire'] != null
          ? CouleurCire.values.firstWhere(
              (couleur) => couleur.label == data['couleurCire'],
              orElse: () => CouleurCire.jaune,
            )
          : null,
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
      'typeCire': typeCire?.label,
      'couleurCire': couleurCire?.label,
    };
  }

  ContenantScoopModel copyWith({
    String? id,
    ContenantType? typeContenant,
    MielType? typeMiel,
    double? poids,
    double? prix,
    String? notes,
    TypeCire? typeCire,
    CouleurCire? couleurCire,
  }) {
    return ContenantScoopModel(
      id: id ?? this.id,
      typeContenant: typeContenant ?? this.typeContenant,
      typeMiel: typeMiel ?? this.typeMiel,
      poids: poids ?? this.poids,
      prix: prix ?? this.prix,
      notes: notes ?? this.notes,
      typeCire: typeCire ?? this.typeCire,
      couleurCire: couleurCire ?? this.couleurCire,
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
  // Champs de géolocalisation
  final Map<String, dynamic>? geolocationData;
  final String? codeLocalite; // NOUVEAU: Code de localité XX-XX-XX

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
    this.geolocationData,
    this.codeLocalite, // Sera généré automatiquement si null depuis le SCOOP
  });

  factory CollecteScoopModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Le code localité peut être récupéré directement ou hérité du SCOOP
    String? codeLocalite = data['code_localite']?.toString();

    return CollecteScoopModel(
      id: doc.id,
      dateAchat: data['date_achat'] != null
          ? (data['date_achat'] as Timestamp).toDate()
          : DateTime.now(), // 🔧 Fallback si null
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
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(), // 🔧 Fallback si null
      statut: data['statut'] ?? 'collecte_terminee',
      geolocationData: data['geolocation_data'] as Map<String, dynamic>?,
      codeLocalite: codeLocalite,
    );
  }

  Map<String, dynamic> toFirestore() {
    final data = {
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
      'code_localite': codeLocalite, // NOUVEAU champ
    };

    // Ajouter les données de géolocalisation si disponibles
    if (geolocationData != null && geolocationData!.isNotEmpty) {
      data['geolocation_data'] = geolocationData!;
    }

    return data;
  }

  int get nombreBidons =>
      contenants.where((c) => c.typeContenant == ContenantType.bidon).length;
  int get nombreSeaux =>
      contenants.where((c) => c.typeContenant == ContenantType.seau).length;

  Set<String> get mielTypes => contenants.map((c) => c.typeMiel.label).toSet();

  /// Retourne la localisation formatée à partir des données GPS
  String get localisationFormatee {
    if (geolocationData == null) return 'Non spécifié';

    final latitude = geolocationData!['latitude'];
    final longitude = geolocationData!['longitude'];
    final accuracy = geolocationData!['accuracy'];

    if (latitude != null && longitude != null) {
      final latStr = latitude.toStringAsFixed(6);
      final lngStr = longitude.toStringAsFixed(6);
      final accuracyStr =
          accuracy != null ? '±${accuracy.toStringAsFixed(1)}m' : '';

      return 'GPS: $latStr, $lngStr $accuracyStr';
    }

    return 'Non spécifié';
  }
}

/// Périodes prédéfinies pour la collecte
class PeriodesCollecte {
  static const List<String> periodes = [
    'La grande Miellé',
    'La Petite miellée',
  ];
}

/// Prédominances florales disponibles - Nettoyées
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
    'Moringa',
    'Cajou',
    'Détarium',
    'Kapokier',
    'Zaaba',
    'Filao',
  ];
}
