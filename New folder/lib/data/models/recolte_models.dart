import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour représenter un contenant de récolte
class ContenantRecolteModel {
  final String id;
  final String typeRuche;
  final String typeContenant;
  final double poids;
  final double prixUnitaire;
  final double montantTotal;

  ContenantRecolteModel({
    required this.id,
    required this.typeRuche,
    required this.typeContenant,
    required this.poids,
    required this.prixUnitaire,
    required this.montantTotal,
  });

  factory ContenantRecolteModel.fromMap(Map<String, dynamic> data) {
    return ContenantRecolteModel(
      id: data['id']?.toString() ?? '',
      typeRuche: data['hiveType']?.toString() ?? '',
      typeContenant: data['containerType']?.toString() ?? '',
      poids: (data['weight'] ?? 0.0).toDouble(),
      prixUnitaire: (data['unitPrice'] ?? 0.0).toDouble(),
      montantTotal: (data['total'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'hiveType': typeRuche,
      'containerType': typeContenant,
      'weight': poids,
      'unitPrice': prixUnitaire,
      'total': montantTotal,
    };
  }

  ContenantRecolteModel copyWith({
    String? id,
    String? typeRuche,
    String? typeContenant,
    double? poids,
    double? prixUnitaire,
    double? montantTotal,
  }) {
    return ContenantRecolteModel(
      id: id ?? this.id,
      typeRuche: typeRuche ?? this.typeRuche,
      typeContenant: typeContenant ?? this.typeContenant,
      poids: poids ?? this.poids,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      montantTotal: montantTotal ?? this.montantTotal,
    );
  }
}

/// Modèle pour représenter une récolte complète
class RecolteModel {
  final String id;
  final String site;
  final String region;
  final String province;
  final String commune;
  final String village;
  final String technicienNom;
  final String? technicienTelephone;
  final List<String> predominancesFlorales;
  final List<ContenantRecolteModel> contenants;
  final double poidsTotal;
  final double montantTotal;
  final int nombreContenants;
  final String status;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final Map<String, dynamic>? metadata;

  RecolteModel({
    required this.id,
    required this.site,
    required this.region,
    required this.province,
    required this.commune,
    required this.village,
    required this.technicienNom,
    this.technicienTelephone,
    this.predominancesFlorales = const [],
    required this.contenants,
    required this.poidsTotal,
    required this.montantTotal,
    required this.nombreContenants,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory RecolteModel.fromFirestore(DocumentSnapshot doc) {
    print(
        "🔵 RecolteModel.fromFirestore - Début conversion document: ${doc.id}");

    try {
      final data = doc.data() as Map<String, dynamic>;
      print(
          "🔵 RecolteModel.fromFirestore - Données brutes: ${data.keys.toList()}");

      // Conversion sécurisée des contenants
      List<ContenantRecolteModel> contenantsList = [];
      if (data['contenants'] != null) {
        final contenantsData = data['contenants'] as List<dynamic>;
        contenantsList = contenantsData.map((c) {
          if (c is Map<String, dynamic>) {
            return ContenantRecolteModel.fromMap(c);
          }
          return ContenantRecolteModel(
            id: '',
            typeRuche: '',
            typeContenant: '',
            poids: 0.0,
            prixUnitaire: 0.0,
            montantTotal: 0.0,
          );
        }).toList();
      }

      // Conversion sécurisée des prédominances florales
      List<String> predominancesList = [];
      if (data['predominances_florales'] != null) {
        final predominancesData = data['predominances_florales'];
        if (predominancesData is List) {
          predominancesList = predominancesData
              .map((p) => p?.toString() ?? '')
              .where((p) => p.isNotEmpty)
              .toList();
        }
      }

      final recolte = RecolteModel(
        id: doc.id,
        site: data['site']?.toString() ?? '',
        region: data['region']?.toString() ?? '',
        province: data['province']?.toString() ?? '',
        commune: data['commune']?.toString() ?? '',
        village: data['village']?.toString() ?? '',
        technicienNom: data['technicien_nom']?.toString() ?? '',
        technicienTelephone: data['technicien_telephone']?.toString(),
        predominancesFlorales: predominancesList,
        contenants: contenantsList,
        poidsTotal: (data['totalWeight'] ?? 0.0).toDouble(),
        montantTotal: (data['totalAmount'] ?? 0.0).toDouble(),
        nombreContenants:
            (data['nombreContenants'] ?? contenantsList.length) as int,
        status: data['status']?.toString() ?? 'inconnu',
        createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
        updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
        metadata: data['metadata'] as Map<String, dynamic>?,
      );

      print(
          "✅ RecolteModel.fromFirestore - Conversion réussie: ${recolte.site} - ${recolte.technicienNom}");
      return recolte;
    } catch (e) {
      print("🔴 RecolteModel.fromFirestore - Erreur: $e");
      rethrow;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'site': site,
      'region': region,
      'province': province,
      'commune': commune,
      'village': village,
      'technicien_nom': technicienNom,
      'technicien_telephone': technicienTelephone,
      'predominances_florales': predominancesFlorales,
      'contenants': contenants.map((c) => c.toFirestore()).toList(),
      'totalWeight': poidsTotal,
      'totalAmount': montantTotal,
      'nombreContenants': nombreContenants,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'metadata': metadata,
    };
  }

  RecolteModel copyWith({
    String? id,
    String? site,
    String? region,
    String? province,
    String? commune,
    String? village,
    String? technicienNom,
    String? technicienTelephone,
    List<String>? predominancesFlorales,
    List<ContenantRecolteModel>? contenants,
    double? poidsTotal,
    double? montantTotal,
    int? nombreContenants,
    String? status,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return RecolteModel(
      id: id ?? this.id,
      site: site ?? this.site,
      region: region ?? this.region,
      province: province ?? this.province,
      commune: commune ?? this.commune,
      village: village ?? this.village,
      technicienNom: technicienNom ?? this.technicienNom,
      technicienTelephone: technicienTelephone ?? this.technicienTelephone,
      predominancesFlorales:
          predominancesFlorales ?? this.predominancesFlorales,
      contenants: contenants ?? this.contenants,
      poidsTotal: poidsTotal ?? this.poidsTotal,
      montantTotal: montantTotal ?? this.montantTotal,
      nombreContenants: nombreContenants ?? this.nombreContenants,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Modèle pour les statistiques de récolte structurées
class StatistiquesRecolteModel {
  final String type;
  final Timestamp derniereMiseAJour;
  final Timestamp? periodeDebut;
  final Timestamp periodeFin;
  final ResumeGlobalRecolte resumeGlobal;
  final List<RepartitionTechnicien> repartitionTechniciens;
  final List<TypeContenant> typesContenants;
  final List<TypeRuche> typesRuches;
  final Map<String, dynamic>? derniereRecolte;

  StatistiquesRecolteModel({
    required this.type,
    required this.derniereMiseAJour,
    this.periodeDebut,
    required this.periodeFin,
    required this.resumeGlobal,
    required this.repartitionTechniciens,
    required this.typesContenants,
    required this.typesRuches,
    this.derniereRecolte,
  });

  factory StatistiquesRecolteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return StatistiquesRecolteModel(
      type: data['type']?.toString() ?? 'statistiques_recoltes',
      derniereMiseAJour:
          data['derniere_mise_a_jour'] as Timestamp? ?? Timestamp.now(),
      periodeDebut: data['periode_debut'] as Timestamp?,
      periodeFin: data['periode_fin'] as Timestamp? ?? Timestamp.now(),
      resumeGlobal: ResumeGlobalRecolte.fromMap(data['resume_global'] ?? {}),
      repartitionTechniciens: (data['repartition_techniciens']
                  as List<dynamic>? ??
              [])
          .map((t) => RepartitionTechnicien.fromMap(t as Map<String, dynamic>))
          .toList(),
      typesContenants: (data['types_contenants'] as List<dynamic>? ?? [])
          .map((t) => TypeContenant.fromMap(t as Map<String, dynamic>))
          .toList(),
      typesRuches: (data['types_ruches'] as List<dynamic>? ?? [])
          .map((t) => TypeRuche.fromMap(t as Map<String, dynamic>))
          .toList(),
      derniereRecolte: data['derniere_recolte'] as Map<String, dynamic>?,
    );
  }
}

/// Modèle pour le résumé global des récoltes
class ResumeGlobalRecolte {
  final int nombreRecoltes;
  final double poidsTotalKg;
  final double montantTotalFcfa;
  final double poidsMoyenKg;
  final double montantMoyenFcfa;

  ResumeGlobalRecolte({
    required this.nombreRecoltes,
    required this.poidsTotalKg,
    required this.montantTotalFcfa,
    required this.poidsMoyenKg,
    required this.montantMoyenFcfa,
  });

  factory ResumeGlobalRecolte.fromMap(Map<String, dynamic> data) {
    return ResumeGlobalRecolte(
      nombreRecoltes: (data['nombre_recoltes'] ?? 0) as int,
      poidsTotalKg: (data['poids_total_kg'] ?? 0.0).toDouble(),
      montantTotalFcfa: (data['montant_total_fcfa'] ?? 0.0).toDouble(),
      poidsMoyenKg: (data['poids_moyen_kg'] ?? 0.0).toDouble(),
      montantMoyenFcfa: (data['montant_moyen_fcfa'] ?? 0.0).toDouble(),
    );
  }
}

/// Modèle pour la répartition par technicien
class RepartitionTechnicien {
  final String technicien;
  final int nombreRecoltes;
  final double poidsTotalKg;

  RepartitionTechnicien({
    required this.technicien,
    required this.nombreRecoltes,
    required this.poidsTotalKg,
  });

  factory RepartitionTechnicien.fromMap(Map<String, dynamic> data) {
    return RepartitionTechnicien(
      technicien: data['technicien']?.toString() ?? '',
      nombreRecoltes: (data['nombre_recoltes'] ?? 0) as int,
      poidsTotalKg: (data['poids_total_kg'] ?? 0.0).toDouble(),
    );
  }
}

/// Modèle pour les types de contenant
class TypeContenant {
  final String type;
  final int quantite;

  TypeContenant({
    required this.type,
    required this.quantite,
  });

  factory TypeContenant.fromMap(Map<String, dynamic> data) {
    return TypeContenant(
      type: data['type']?.toString() ?? '',
      quantite: (data['quantite'] ?? 0) as int,
    );
  }
}

/// Modèle pour les types de ruche
class TypeRuche {
  final String type;
  final int quantite;

  TypeRuche({
    required this.type,
    required this.quantite,
  });

  factory TypeRuche.fromMap(Map<String, dynamic> data) {
    return TypeRuche(
      type: data['type']?.toString() ?? '',
      quantite: (data['quantite'] ?? 0) as int,
    );
  }
}
