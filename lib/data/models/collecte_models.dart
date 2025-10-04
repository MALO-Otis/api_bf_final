import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apisavana_gestion/data/services/localite_codification_service.dart';

class ProducteurModel {
  final String id;
  final String nomPrenom;
  final String numero;
  final String sexe;
  final String age; // Changé de int à String pour plus de flexibilité
  final String appartenance;
  final String cooperative;
  final Map<String, String> localisation; // {region, province, commune}
  final String? codeCollecte; // Code de collecte (XX-XX-XX format)
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
    this.codeCollecte, // Sera généré automatiquement si null
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

      // Génération automatique du code collecte si nécessaire
      String? codeCollecte = data['code_collecte']?.toString();
      if (codeCollecte == null || codeCollecte.isEmpty) {
        final region = localisation['region'] ?? '';
        final province = localisation['province'] ?? '';
        final commune = localisation['commune'] ?? '';

        if (region.isNotEmpty && province.isNotEmpty && commune.isNotEmpty) {
          codeCollecte = LocaliteCodificationService.generateCodeLocalite(
            regionNom: region,
            provinceNom: province,
            communeNom: commune,
          );
          print(
              '🔵 ProducteurModel: Code collecte généré automatiquement: $codeCollecte');
        }
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
        codeCollecte: codeCollecte,
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
    // Génération automatique du code collecte si absent
    String? finalCodeCollecte = codeCollecte;
    if (finalCodeCollecte == null || finalCodeCollecte.isEmpty) {
      final region = localisation['region'] ?? '';
      final province = localisation['province'] ?? '';
      final commune = localisation['commune'] ?? '';

      if (region.isNotEmpty && province.isNotEmpty && commune.isNotEmpty) {
        finalCodeCollecte = LocaliteCodificationService.generateCodeLocalite(
          regionNom: region,
          provinceNom: province,
          communeNom: commune,
        );
        print(
            '🔵 ProducteurModel.toFirestore: Code collecte généré: $finalCodeCollecte');
      }
    }

    return {
      'nomPrenom': nomPrenom,
      'numero': numero,
      'sexe': sexe,
      'age': age,
      'appartenance': appartenance,
      'cooperative': cooperative,
      'localisation': localisation,
      'code_collecte': finalCodeCollecte, // NOUVEAU champ
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
    String? codeCollecte,
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
      codeCollecte: codeCollecte ?? this.codeCollecte,
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
  final String id;
  final String typeRuche;
  final String typeMiel;
  final String typeContenant;
  final double quantite;
  final double prixUnitaire;
  final String predominanceFlorale;
  final String note;

  ContenantModel({
    required this.id,
    required this.typeRuche,
    required this.typeMiel,
    required this.typeContenant,
    required this.quantite,
    required this.prixUnitaire,
    required this.predominanceFlorale,
    this.note = '',
  });

  double get montantTotal => quantite * prixUnitaire;

  factory ContenantModel.fromFirestore(Map<String, dynamic> data) {
    return ContenantModel(
      id: data['id']?.toString() ?? '',
      typeRuche: data['type_ruche']?.toString() ?? '',
      typeMiel: data['type_miel']?.toString() ?? '',
      typeContenant: data['type_contenant']?.toString() ?? '',
      quantite: (data['quantite'] ?? 0.0).toDouble(),
      prixUnitaire: (data['prix_unitaire'] ?? 0.0).toDouble(),
      predominanceFlorale: data['predominance_florale']?.toString() ?? '',
      note: data['note']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'type_ruche': typeRuche,
      'type_miel': typeMiel,
      'type_contenant': typeContenant,
      'quantite': quantite,
      'prix_unitaire': prixUnitaire,
      'montant_total': montantTotal,
      'predominance_florale': predominanceFlorale,
      'note': note,
    };
  }

  ContenantModel copyWith({
    String? id,
    String? typeRuche,
    String? typeMiel,
    String? typeContenant,
    double? quantite,
    double? prixUnitaire,
    String? predominanceFlorale,
    String? note,
  }) {
    return ContenantModel(
      id: id ?? this.id,
      typeRuche: typeRuche ?? this.typeRuche,
      typeMiel: typeMiel ?? this.typeMiel,
      typeContenant: typeContenant ?? this.typeContenant,
      quantite: quantite ?? this.quantite,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      predominanceFlorale: predominanceFlorale ?? this.predominanceFlorale,
      note: note ?? this.note,
    );
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
  final String? codeCollecte; // NOUVEAU: Code de collecte basé sur la localité
  final Map<String, dynamic>? geolocationData;

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
    this.codeCollecte,
    this.geolocationData,
  });

  factory CollecteIndividuelleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    List<ContenantModel> contenants = [];
    if (data['contenants'] != null) {
      contenants = (data['contenants'] as List)
          .map((item) => ContenantModel.fromFirestore(item))
          .toList();
    }

    List<String> originesFlorales = [];
    if (data['originesFlorales'] != null) {
      originesFlorales = List<String>.from(data['originesFlorales']);
    }

    return CollecteIndividuelleModel(
      idCollecte: doc.id,
      dateAchat: data['dateAchat'] ?? Timestamp.now(),
      periodeCollecte: data['periodeCollecte'] ?? '',
      poidsTotal: (data['poidsTotal'] ?? 0.0).toDouble(),
      montantTotal: (data['montantTotal'] ?? 0.0).toDouble(),
      nombreContenants: data['nombreContenants'] ?? 0,
      idProducteur: data['idProducteur'] ?? '',
      nomProducteur: data['nomProducteur'] ?? '',
      contenants: contenants,
      originesFlorales: originesFlorales,
      collecteurId: data['collecteurId'] ?? '',
      collecteurNom: data['collecteurNom'] ?? '',
      observations: data['observations'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      codeCollecte: data['code_collecte'],
      geolocationData: data['geolocationData'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'dateAchat': dateAchat,
      'periodeCollecte': periodeCollecte,
      'poidsTotal': poidsTotal,
      'montantTotal': montantTotal,
      'nombreContenants': nombreContenants,
      'idProducteur': idProducteur,
      'nomProducteur': nomProducteur,
      'contenants': contenants.map((c) => c.toFirestore()).toList(),
      'originesFlorales': originesFlorales,
      'collecteurId': collecteurId,
      'collecteurNom': collecteurNom,
      'observations': observations,
      'createdAt': createdAt,
      'code_collecte': codeCollecte,
      'geolocationData': geolocationData,
    };
  }

  CollecteIndividuelleModel copyWith({
    String? idCollecte,
    Timestamp? dateAchat,
    String? periodeCollecte,
    double? poidsTotal,
    double? montantTotal,
    int? nombreContenants,
    String? idProducteur,
    String? nomProducteur,
    List<ContenantModel>? contenants,
    List<String>? originesFlorales,
    String? collecteurId,
    String? collecteurNom,
    String? observations,
    Timestamp? createdAt,
    String? codeCollecte,
    Map<String, dynamic>? geolocationData,
  }) {
    return CollecteIndividuelleModel(
      idCollecte: idCollecte ?? this.idCollecte,
      dateAchat: dateAchat ?? this.dateAchat,
      periodeCollecte: periodeCollecte ?? this.periodeCollecte,
      poidsTotal: poidsTotal ?? this.poidsTotal,
      montantTotal: montantTotal ?? this.montantTotal,
      nombreContenants: nombreContenants ?? this.nombreContenants,
      idProducteur: idProducteur ?? this.idProducteur,
      nomProducteur: nomProducteur ?? this.nomProducteur,
      contenants: contenants ?? this.contenants,
      originesFlorales: originesFlorales ?? this.originesFlorales,
      collecteurId: collecteurId ?? this.collecteurId,
      collecteurNom: collecteurNom ?? this.collecteurNom,
      observations: observations ?? this.observations,
      createdAt: createdAt ?? this.createdAt,
      codeCollecte: codeCollecte ?? this.codeCollecte,
      geolocationData: geolocationData ?? this.geolocationData,
    );
  }
}
