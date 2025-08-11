import 'package:cloud_firestore/cloud_firestore.dart';

class ProducteurModel {
  final String id;
  final String nomPrenom;
  final String numero;
  final String sexe;
  final String age; // Changé de int à String pour la catégorie d'âge
  final String appartenance;
  final String cooperative;
  final Map<String, String> localisation;
  final int nbRuchesTrad;
  final int nbRuchesMod;
  final int totalRuches;
  final int nombreCollectes;
  final double poidsTotal;
  final double montantTotal;
  final List<String> originesFlorale;
  final Timestamp? derniereCollecte;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  ProducteurModel({
    required this.id,
    required this.nomPrenom,
    required this.numero,
    required this.sexe,
    required this.age,
    required this.appartenance,
    required this.cooperative,
    required this.localisation,
    required this.nbRuchesTrad,
    required this.nbRuchesMod,
    required this.totalRuches,
    this.nombreCollectes = 0,
    this.poidsTotal = 0.0,
    this.montantTotal = 0.0,
    this.originesFlorale = const [],
    this.derniereCollecte,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProducteurModel.fromFirestore(DocumentSnapshot doc) {
    print(
        "🔵 ProducteurModel.fromFirestore - Début conversion document: ${doc.id}");

    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      print("🔵 ProducteurModel.fromFirestore - Données brutes: $data");

      // Conversion sécurisée de la localisation
      Map<String, String> localisation = {};
      if (data['localisation'] != null) {
        final locData = data['localisation'] as Map<String, dynamic>;
        localisation =
            locData.map((key, value) => MapEntry(key, value?.toString() ?? ''));
      }

      // Conversion sécurisée des origines florales
      List<String> originesFlorale = [];
      if (data['originesFlorale'] != null) {
        originesFlorale = List<String>.from(data['originesFlorale'] as List);
      }

      final producteur = ProducteurModel(
        id: doc.id,
        nomPrenom: data['nomPrenom']?.toString() ?? '',
        numero: data['numero']?.toString() ?? '',
        sexe: data['sexe']?.toString() ?? '',
        age: data['age'] != null ? data['age'].toString() : 'Non spécifié',
        appartenance: data['appartenance']?.toString() ?? '',
        cooperative: data['cooperative']?.toString() ?? '',
        localisation: localisation,
        nbRuchesTrad: (data['nbRuchesTrad'] ?? 0) as int,
        nbRuchesMod: (data['nbRuchesMod'] ?? 0) as int,
        totalRuches: (data['totalRuches'] ?? 0) as int,
        nombreCollectes: (data['nombreCollectes'] ?? 0) as int,
        poidsTotal: (data['poidsTotal'] ?? 0.0).toDouble(),
        montantTotal: (data['montantTotal'] ?? 0.0).toDouble(),
        originesFlorale: originesFlorale,
        derniereCollecte: data['derniereCollecte'] as Timestamp?,
        createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
        updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
      );

      print(
          "✅ ProducteurModel.fromFirestore - Conversion réussie: ${producteur.nomPrenom}");
      return producteur;
    } catch (e) {
      print("🔴 ProducteurModel.fromFirestore - Erreur: $e");
      rethrow;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nomPrenom': nomPrenom,
      'numero': numero,
      'sexe': sexe,
      'age': age,
      'appartenance': appartenance,
      'cooperative': cooperative,
      'localisation': localisation,
      'nbRuchesTrad': nbRuchesTrad,
      'nbRuchesMod': nbRuchesMod,
      'totalRuches': totalRuches,
      'nombreCollectes': nombreCollectes,
      'poidsTotal': poidsTotal,
      'montantTotal': montantTotal,
      'originesFlorale': originesFlorale,
      'derniereCollecte': derniereCollecte,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  ProducteurModel copyWith({
    String? id,
    String? nomPrenom,
    String? numero,
    String? sexe,
    String? age, // Changé de int? à String?
    String? appartenance,
    String? cooperative,
    Map<String, String>? localisation,
    int? nbRuchesTrad,
    int? nbRuchesMod,
    int? totalRuches,
    int? nombreCollectes,
    double? poidsTotal,
    double? montantTotal,
    List<String>? originesFlorale,
    Timestamp? derniereCollecte,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return ProducteurModel(
      id: id ?? this.id,
      nomPrenom: nomPrenom ?? this.nomPrenom,
      numero: numero ?? this.numero,
      sexe: sexe ?? this.sexe,
      age: age ?? this.age,
      appartenance: appartenance ?? this.appartenance,
      cooperative: cooperative ?? this.cooperative,
      localisation: localisation ?? this.localisation,
      nbRuchesTrad: nbRuchesTrad ?? this.nbRuchesTrad,
      nbRuchesMod: nbRuchesMod ?? this.nbRuchesMod,
      totalRuches: totalRuches ?? this.totalRuches,
      nombreCollectes: nombreCollectes ?? this.nombreCollectes,
      poidsTotal: poidsTotal ?? this.poidsTotal,
      montantTotal: montantTotal ?? this.montantTotal,
      originesFlorale: originesFlorale ?? this.originesFlorale,
      derniereCollecte: derniereCollecte ?? this.derniereCollecte,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ContenantModel {
  final String typeRuche;
  final String typeMiel;
  final String typeContenant; // Nouveau champ requis
  final double quantite;
  final double prixUnitaire;
  final String predominanceFlorale;
  final String note; // Nouveau champ pour l'avis sur le contenant

  ContenantModel({
    required this.typeRuche,
    required this.typeMiel,
    required this.typeContenant,
    required this.quantite,
    required this.prixUnitaire,
    required this.predominanceFlorale,
    this.note = '', // Optionnel, valeur par défaut
  });

  // Getter calculé pour le montant total
  double get montantTotal => quantite * prixUnitaire;

  factory ContenantModel.fromFirestore(Map<String, dynamic> data) {
    return ContenantModel(
      typeRuche: data['type_ruche']?.toString() ?? '',
      typeMiel: data['type_miel']?.toString() ?? '',
      typeContenant: data['type_contenant']?.toString() ?? '',
      quantite: (data['quantite'] ?? 0.0).toDouble(),
      prixUnitaire: (data['prix_unitaire'] ?? 0.0).toDouble(),
      predominanceFlorale: data['predominance_florale']?.toString() ?? '',
      note: data['note']?.toString() ?? '', // Nouveau champ
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type_ruche': typeRuche,
      'type_miel': typeMiel,
      'type_contenant': typeContenant,
      'quantite': quantite,
      'prix_unitaire': prixUnitaire,
      'montant_total': montantTotal,
      'predominance_florale': predominanceFlorale,
      'note': note, // Nouveau champ
    };
  }

  ContenantModel copyWith({
    String? typeRuche,
    String? typeMiel,
    String? typeContenant,
    double? quantite,
    double? prixUnitaire,
    String? predominanceFlorale,
    String? note, // Nouveau paramètre
  }) {
    return ContenantModel(
      typeRuche: typeRuche ?? this.typeRuche,
      typeMiel: typeMiel ?? this.typeMiel,
      typeContenant: typeContenant ?? this.typeContenant,
      quantite: quantite ?? this.quantite,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      predominanceFlorale: predominanceFlorale ?? this.predominanceFlorale,
      note: note ?? this.note, // Nouveau champ
    );
  }

  @override
  String toString() {
    return 'ContenantModel(typeRuche: $typeRuche, typeMiel: $typeMiel, typeContenant: $typeContenant, quantite: $quantite, prixUnitaire: $prixUnitaire, montantTotal: $montantTotal, predominanceFlorale: $predominanceFlorale, note: $note)';
  }
}

class CollecteIndividuelleModel {
  final String idCollecte;
  final Timestamp dateAchat;
  final String periodeCollecte;
  final double poidsTotal;
  final double montantTotal;
  final int nombreContenants;
  final String idProducteur;
  final String nomProducteur;
  final List<ContenantModel> contenants;
  final List<String> originesFlorales;
  final String collecteurId;
  final String collecteurNom;
  final String observations;
  final Timestamp createdAt;

  CollecteIndividuelleModel({
    required this.idCollecte,
    required this.dateAchat,
    required this.periodeCollecte,
    required this.poidsTotal,
    required this.montantTotal,
    required this.nombreContenants,
    required this.idProducteur,
    required this.nomProducteur,
    required this.contenants,
    required this.originesFlorales,
    required this.collecteurId,
    required this.collecteurNom,
    required this.observations,
    required this.createdAt,
  });

  factory CollecteIndividuelleModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Conversion des contenants
    List<ContenantModel> contenants = [];
    if (data['contenants'] != null) {
      final contenantsData = data['contenants'] as List;
      contenants = contenantsData
          .map((c) => ContenantModel.fromFirestore(c as Map<String, dynamic>))
          .toList();
    }

    // Conversion des origines florales
    List<String> originesFlorales = [];
    if (data['origines_florales'] != null) {
      originesFlorales = List<String>.from(data['origines_florales'] as List);
    }

    return CollecteIndividuelleModel(
      idCollecte: doc.id,
      dateAchat: data['date_achat'] as Timestamp? ?? Timestamp.now(),
      periodeCollecte: data['periode_collecte']?.toString() ?? '',
      poidsTotal: (data['poids_total'] ?? 0.0).toDouble(),
      montantTotal: (data['montant_total'] ?? 0.0).toDouble(),
      nombreContenants: (data['nombre_contenants'] ?? 0) as int,
      idProducteur: data['id_producteur']?.toString() ?? '',
      nomProducteur: data['nom_producteur']?.toString() ?? '',
      contenants: contenants,
      originesFlorales: originesFlorales,
      collecteurId: data['collecteur_id']?.toString() ?? '',
      collecteurNom: data['collecteur_nom']?.toString() ?? '',
      observations: data['observations']?.toString() ?? '',
      createdAt: data['created_at'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date_achat': dateAchat,
      'periode_collecte': periodeCollecte,
      'poids_total': poidsTotal,
      'montant_total': montantTotal,
      'nombre_contenants': nombreContenants,
      'id_producteur': idProducteur,
      'nom_producteur': nomProducteur,
      'contenants': contenants.map((c) => c.toFirestore()).toList(),
      'origines_florales': originesFlorales,
      'collecteur_id': collecteurId,
      'collecteur_nom': collecteurNom,
      'observations': observations,
      'created_at': createdAt,
    };
  }
}

class StatistiquesProducteurModel {
  final int nombreTotalProducteurs;
  final Map<String, int> producteursParVillage;
  final Map<String, int> collectesParProducteur;
  final Map<String, Map<String, int>> contenantsParType;
  final Map<String, Map<String, double>> prixParTypeMiel;
  final Map<String, Map<String, double>> quantiteParTypeMiel;
  final Map<String, Map<String, double>> montantTotalParType;
  final Timestamp derniereAnalyse;

  StatistiquesProducteurModel({
    required this.nombreTotalProducteurs,
    required this.producteursParVillage,
    required this.collectesParProducteur,
    required this.contenantsParType,
    required this.prixParTypeMiel,
    required this.quantiteParTypeMiel,
    required this.montantTotalParType,
    required this.derniereAnalyse,
  });

  factory StatistiquesProducteurModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return StatistiquesProducteurModel(
      nombreTotalProducteurs: (data['nombre_total_producteurs'] ?? 0) as int,
      producteursParVillage:
          Map<String, int>.from(data['producteurs_par_village'] ?? {}),
      collectesParProducteur:
          Map<String, int>.from(data['collectes_par_producteur'] ?? {}),
      contenantsParType:
          (data['contenants_par_type'] as Map<String, dynamic>? ?? {}).map(
              (key, value) =>
                  MapEntry(key, Map<String, int>.from(value as Map))),
      prixParTypeMiel:
          (data['prix_par_type_miel'] as Map<String, dynamic>? ?? {}).map(
              (key, value) =>
                  MapEntry(key, Map<String, double>.from(value as Map))),
      quantiteParTypeMiel:
          (data['quantite_par_type_miel'] as Map<String, dynamic>? ?? {}).map(
              (key, value) =>
                  MapEntry(key, Map<String, double>.from(value as Map))),
      montantTotalParType:
          (data['montant_total_par_type'] as Map<String, dynamic>? ?? {}).map(
              (key, value) =>
                  MapEntry(key, Map<String, double>.from(value as Map))),
      derniereAnalyse:
          data['derniere_analyse'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre_total_producteurs': nombreTotalProducteurs,
      'producteurs_par_village': producteursParVillage,
      'collectes_par_producteur': collectesParProducteur,
      'contenants_par_type': contenantsParType,
      'prix_par_type_miel': prixParTypeMiel,
      'quantite_par_type_miel': quantiteParTypeMiel,
      'montant_total_par_type': montantTotalParType,
      'derniere_analyse': derniereAnalyse,
    };
  }
}
