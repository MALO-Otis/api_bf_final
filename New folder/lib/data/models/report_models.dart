import 'package:intl/intl.dart';

/// Types de rapports disponibles
enum TypeRapport {
  statistiques('Rapport Statistiques'),
  recu('Reçu de Collecte');

  const TypeRapport(this.label);
  final String label;
}

/// Types de collectes pour les rapports
enum TypeCollecteRapport {
  recolte('Récoltes'),
  scoopContenants('Achat SCOOP'),
  individuel('Achat Individuel'),
  miellerie('Achat dans miellerie');

  const TypeCollecteRapport(this.label);
  final String label;
}

/// Modèle pour un contenant dans un rapport
class ContenantRapport {
  final String id;
  final String type;
  final String typeMiel;
  final double quantite;
  final double prixUnitaire;
  final double montantTotal;
  final String? notes;
  final String? typeRuche; // Pour récoltes
  final String? predominanceFlorale; // Pour récoltes et individuels
  final String? typeCire; // Pour SCOOP et mielleries
  final String? couleurCire; // Pour SCOOP et mielleries

  ContenantRapport({
    required this.id,
    required this.type,
    required this.typeMiel,
    required this.quantite,
    required this.prixUnitaire,
    required this.montantTotal,
    this.notes,
    this.typeRuche,
    this.predominanceFlorale,
    this.typeCire,
    this.couleurCire,
  });

  /// Créer depuis une collecte de récolte
  factory ContenantRapport.fromRecolte(Map<String, dynamic> contenant) {
    return ContenantRapport(
      id: contenant['id']?.toString() ?? '',
      type: contenant['containerType']?.toString() ?? '',
      typeMiel: 'Miel de récolte',
      quantite: (contenant['weight'] ?? 0.0).toDouble(),
      prixUnitaire: (contenant['unitPrice'] ?? 0.0).toDouble(),
      montantTotal: (contenant['total'] ?? 0.0).toDouble(),
      typeRuche: contenant['hiveType']?.toString(),
    );
  }

  /// Créer depuis une collecte SCOOP
  factory ContenantRapport.fromScoop(Map<String, dynamic> contenant) {
    // Support pour les différents formats de données SCOOP
    final typeContenant = contenant['typeContenant'] ??
        contenant['type_contenant'] ??
        'Non défini';
    final typeMiel =
        contenant['typeMiel'] ?? contenant['type_miel'] ?? 'Non défini';
    final poids = (contenant['poids'] ?? 0.0).toDouble();
    final prix = (contenant['prix'] ?? 0.0).toDouble();

    return ContenantRapport(
      id: contenant['id']?.toString() ?? '',
      type: typeContenant,
      typeMiel: typeMiel,
      quantite: poids,
      prixUnitaire: prix,
      montantTotal: poids * prix,
      notes: contenant['notes']?.toString(),
      typeCire: contenant['typeCire'] ?? contenant['type_cire']?.toString(),
      couleurCire:
          contenant['couleurCire'] ?? contenant['couleur_cire']?.toString(),
    );
  }

  /// Créer depuis une collecte individuelle
  factory ContenantRapport.fromIndividuel(Map<String, dynamic> contenant) {
    return ContenantRapport(
      id: contenant['id']?.toString() ?? '',
      type: contenant['type_contenant']?.toString() ?? '',
      typeMiel: contenant['type_miel']?.toString() ?? '',
      quantite: (contenant['quantite'] ?? 0.0).toDouble(),
      prixUnitaire: (contenant['prix_unitaire'] ?? 0.0).toDouble(),
      montantTotal: (contenant['montant_total'] ?? 0.0).toDouble(),
      notes: contenant['note']?.toString(),
      typeRuche: contenant['type_ruche']?.toString(),
      predominanceFlorale: contenant['predominance_florale']?.toString(),
    );
  }

  /// Créer depuis une collecte miellerie
  factory ContenantRapport.fromMiellerie(Map<String, dynamic> contenant) {
    return ContenantRapport(
      id: contenant['id']?.toString() ?? '',
      type: contenant['type_contenant']?.toString() ?? '',
      typeMiel: contenant['type_collecte']?.toString() ?? '',
      quantite: (contenant['quantite'] ?? 0.0).toDouble(),
      prixUnitaire: (contenant['prix_unitaire'] ?? 0.0).toDouble(),
      montantTotal: (contenant['montant_total'] ?? 0.0).toDouble(),
      notes: contenant['notes']?.toString(),
      typeCire: contenant['type_cire']?.toString(),
      couleurCire: contenant['couleur_cire']?.toString(),
    );
  }
}

/// Modèle pour les données communes d'une collecte
class CollecteRapportData {
  final String id;
  final TypeCollecteRapport typeCollecte;
  final DateTime dateCollecte;
  final String site;
  final String technicienNom;
  final String technicienId;
  final List<ContenantRapport> contenants;
  final double poidsTotal;
  final double montantTotal;
  final String? observations;
  final String collection; // Chemin Firestore

  // Données spécifiques par type
  final String? producteurNom; // Pour individuel
  final String? scoopNom; // Pour SCOOP
  final String? miellerieNom; // Pour miellerie
  final String? cooperativeNom; // Pour SCOOP et miellerie
  final String? repondant; // Pour miellerie
  final String? localite; // Pour miellerie
  final String? periodeCollecte; // Pour SCOOP et récoltes
  final List<String>? predominancesFlorales; // Pour récoltes
  final String? region; // Pour récoltes
  final String? province; // Pour récoltes
  final String? commune; // Pour récoltes
  final String? village; // Pour récoltes

  // Données de géolocalisation
  final Map<String, dynamic>? geolocationData;

  CollecteRapportData({
    required this.id,
    required this.typeCollecte,
    required this.dateCollecte,
    required this.site,
    required this.technicienNom,
    required this.technicienId,
    required this.contenants,
    required this.poidsTotal,
    required this.montantTotal,
    required this.collection,
    this.observations,
    this.producteurNom,
    this.scoopNom,
    this.miellerieNom,
    this.cooperativeNom,
    this.repondant,
    this.localite,
    this.periodeCollecte,
    this.predominancesFlorales,
    this.region,
    this.province,
    this.commune,
    this.village,
    this.geolocationData,
  });

  /// Créer depuis les données de l'historique
  factory CollecteRapportData.fromHistoriqueData(Map<String, dynamic> data) {
    print('📊 RAPPORT: Parsing données historique pour ${data['type']}');
    print('   ID: ${data['id']}');
    print(
        '   Contenants bruts: ${data['contenants']?.runtimeType} - ${data['details']?.runtimeType}');
    // Déterminer le type de collecte
    TypeCollecteRapport typeCollecte;
    switch (data['type']) {
      case 'Récoltes':
        typeCollecte = TypeCollecteRapport.recolte;
        break;
      case 'Achat SCOOP':
        typeCollecte = TypeCollecteRapport.scoopContenants;
        break;
      case 'Achat Individuel':
        typeCollecte = TypeCollecteRapport.individuel;
        break;
      case 'Achat dans miellerie':
        typeCollecte = TypeCollecteRapport.miellerie;
        break;
      default:
        typeCollecte = TypeCollecteRapport.recolte;
    }

    // Créer les contenants selon le type
    List<ContenantRapport> contenants = [];

    // Récupération des contenants selon le type de collecte
    List<dynamic> rawContenants = [];
    switch (typeCollecte) {
      case TypeCollecteRapport.scoopContenants:
        // Pour SCOOP, les contenants peuvent être dans 'details' ou 'contenants'
        rawContenants =
            (data['details'] ?? data['contenants'] ?? []) as List<dynamic>;
        break;
      case TypeCollecteRapport.recolte:
      case TypeCollecteRapport.individuel:
      case TypeCollecteRapport.miellerie:
        // Pour les autres, ils sont dans 'contenants'
        rawContenants =
            (data['contenants'] ?? data['details'] ?? []) as List<dynamic>;
        break;
    }

    print('   📦 Contenants trouvés: ${rawContenants.length}');
    if (rawContenants.isNotEmpty) {
      for (int i = 0; i < rawContenants.length; i++) {
        final contenant = rawContenants[i];
        print('   📦 Contenant $i: ${contenant.runtimeType}');
        if (contenant is Map<String, dynamic>) {
          print('      Clés: ${contenant.keys.toList()}');
          try {
            switch (typeCollecte) {
              case TypeCollecteRapport.recolte:
                contenants.add(ContenantRapport.fromRecolte(contenant));
                break;
              case TypeCollecteRapport.scoopContenants:
                contenants.add(ContenantRapport.fromScoop(contenant));
                break;
              case TypeCollecteRapport.individuel:
                contenants.add(ContenantRapport.fromIndividuel(contenant));
                break;
              case TypeCollecteRapport.miellerie:
                contenants.add(ContenantRapport.fromMiellerie(contenant));
                break;
            }
            print('      ✅ Contenant ${typeCollecte.name} parsé avec succès');
          } catch (e) {
            print('❌ Erreur parsing contenant ${typeCollecte.name}: $e');
            print('   Données: $contenant');
          }
        }
      }
    }

    return CollecteRapportData(
      id: data['id']?.toString() ?? '',
      typeCollecte: typeCollecte,
      dateCollecte: data['date'] ?? DateTime.now(),
      site: data['site']?.toString() ?? '',
      technicienNom: data['technicien_nom']?.toString() ?? '',
      technicienId: data['technicien_id']?.toString() ?? '',
      contenants: contenants,
      poidsTotal:
          (data['totalWeight'] ?? data['poids_total'] ?? 0.0).toDouble(),
      montantTotal:
          (data['totalAmount'] ?? data['montant_total'] ?? 0.0).toDouble(),
      collection: data['collection']?.toString() ?? '',
      observations: data['observations']?.toString(),
      producteurNom: data['producteur_nom']?.toString(),
      scoopNom: data['scoop_name']?.toString() ?? data['scoop_nom']?.toString(),
      miellerieNom: data['miellerie_nom']?.toString(),
      cooperativeNom: data['cooperative_nom']?.toString(),
      repondant: data['repondant']?.toString(),
      localite: data['localite']?.toString(),
      periodeCollecte: data['periode_collecte']?.toString() ??
          data['periodeCollecte']?.toString(),
      predominancesFlorales: _extractPredominancesFlorales(data),
      region: data['region']?.toString(),
      province: data['province']?.toString(),
      commune: data['commune']?.toString(),
      village: data['village']?.toString(),
      geolocationData: data['geolocation_data']
          as Map<String, dynamic>?, // Inclure les données GPS
    );
  }

  /// Extraire les prédominances florales selon le format
  static List<String>? _extractPredominancesFlorales(
      Map<String, dynamic> data) {
    final predominances =
        data['predominances_florales'] ?? data['predominancesFlorales'];
    if (predominances is List) {
      return predominances.map((p) => p.toString()).toList();
    }
    return null;
  }

  /// Obtenir le nom de la source (producteur, SCOOP, miellerie)
  String get nomSource {
    switch (typeCollecte) {
      case TypeCollecteRapport.recolte:
        return 'Récolte directe';
      case TypeCollecteRapport.scoopContenants:
        return scoopNom ?? 'SCOOP non spécifié';
      case TypeCollecteRapport.individuel:
        return producteurNom ?? 'Producteur non spécifié';
      case TypeCollecteRapport.miellerie:
        return miellerieNom ?? 'Miellerie non spécifiée';
    }
  }

  /// Obtenir la localisation complète
  String get localisationComplete {
    final List<String> parts = [];

    // Ajouter les localisations administratives si disponibles
    if (region != null && region!.isNotEmpty) parts.add(region!);
    if (province != null && province!.isNotEmpty) parts.add(province!);
    if (commune != null && commune!.isNotEmpty) parts.add(commune!);
    if (village != null && village!.isNotEmpty) parts.add(village!);
    if (localite != null && localite!.isNotEmpty && !parts.contains(localite)) {
      parts.add(localite!);
    }

    // Ajouter les coordonnées GPS si disponibles
    if (geolocationData != null) {
      final latitude = geolocationData!['latitude'];
      final longitude = geolocationData!['longitude'];
      final accuracy = geolocationData!['accuracy'];

      if (latitude != null && longitude != null) {
        final latStr = latitude.toStringAsFixed(6);
        final lngStr = longitude.toStringAsFixed(6);
        final accuracyStr =
            accuracy != null ? '±${accuracy.toStringAsFixed(1)}m' : '';

        parts.add('GPS: $latStr, $lngStr $accuracyStr');
      }
    }

    return parts.isNotEmpty ? parts.join(' • ') : 'Localisation non spécifiée';
  }
}

/// Modèle pour un rapport statistiques (entreprise)
class RapportStatistiques {
  final CollecteRapportData collecte;
  final DateTime dateGeneration;
  final String numeroRapport;

  // Statistiques calculées
  final int nombreContenants;
  final Map<String, int> repartitionParType;
  final Map<String, double> repartitionParMiel;
  final double poidsMoyenParContenant;
  final double prixMoyenAuKilo;
  final double rendementEstime;

  RapportStatistiques({
    required this.collecte,
    required this.dateGeneration,
    required this.numeroRapport,
    required this.nombreContenants,
    required this.repartitionParType,
    required this.repartitionParMiel,
    required this.poidsMoyenParContenant,
    required this.prixMoyenAuKilo,
    required this.rendementEstime,
  });

  /// Générer un rapport statistiques depuis une collecte
  factory RapportStatistiques.generer(CollecteRapportData collecte) {
    final dateGeneration = DateTime.now();
    final numeroRapport =
        _genererNumeroRapport(collecte, dateGeneration, 'STAT');

    // Calculer les statistiques
    final nombreContenants = collecte.contenants.length;

    // Répartition par type de contenant
    final Map<String, int> repartitionParType = {};
    for (final contenant in collecte.contenants) {
      repartitionParType[contenant.type] =
          (repartitionParType[contenant.type] ?? 0) + 1;
    }

    // Répartition par type de miel (en poids)
    final Map<String, double> repartitionParMiel = {};
    for (final contenant in collecte.contenants) {
      repartitionParMiel[contenant.typeMiel] =
          (repartitionParMiel[contenant.typeMiel] ?? 0.0) + contenant.quantite;
    }

    // Calculs moyens
    final poidsMoyenParContenant =
        nombreContenants > 0 ? collecte.poidsTotal / nombreContenants : 0.0;
    final prixMoyenAuKilo = collecte.poidsTotal > 0
        ? collecte.montantTotal / collecte.poidsTotal
        : 0.0;

    // Rendement estimé (exemple : basé sur le type de collecte)
    double rendementEstime = 0.0;
    switch (collecte.typeCollecte) {
      case TypeCollecteRapport.recolte:
        rendementEstime = collecte.poidsTotal * 0.85; // 85% de rendement
        break;
      case TypeCollecteRapport.scoopContenants:
      case TypeCollecteRapport.individuel:
      case TypeCollecteRapport.miellerie:
        rendementEstime = collecte.poidsTotal * 0.92; // 92% de rendement
        break;
    }

    return RapportStatistiques(
      collecte: collecte,
      dateGeneration: dateGeneration,
      numeroRapport: numeroRapport,
      nombreContenants: nombreContenants,
      repartitionParType: repartitionParType,
      repartitionParMiel: repartitionParMiel,
      poidsMoyenParContenant: poidsMoyenParContenant,
      prixMoyenAuKilo: prixMoyenAuKilo,
      rendementEstime: rendementEstime,
    );
  }
}

/// Modèle pour un reçu de collecte (producteur/source)
class RecuCollecte {
  final CollecteRapportData collecte;
  final DateTime dateGeneration;
  final String numeroRecu;
  final String messageRemerciement;

  RecuCollecte({
    required this.collecte,
    required this.dateGeneration,
    required this.numeroRecu,
    required this.messageRemerciement,
  });

  /// Générer un reçu depuis une collecte
  factory RecuCollecte.generer(CollecteRapportData collecte) {
    final dateGeneration = DateTime.now();
    final numeroRecu = _genererNumeroRapport(collecte, dateGeneration, 'RECU');

    // Message personnalisé selon le type
    String messageRemerciement;
    switch (collecte.typeCollecte) {
      case TypeCollecteRapport.recolte:
        messageRemerciement =
            'Merci pour votre excellente récolte de miel. Votre production contribue à la qualité de nos produits.';
        break;
      case TypeCollecteRapport.scoopContenants:
        messageRemerciement =
            'Nous remercions la coopérative ${collecte.scoopNom} pour cette livraison de qualité.';
        break;
      case TypeCollecteRapport.individuel:
        messageRemerciement =
            'Merci ${collecte.producteurNom} pour votre confiance et la qualité de votre miel.';
        break;
      case TypeCollecteRapport.miellerie:
        messageRemerciement =
            'Nous remercions la miellerie ${collecte.miellerieNom} pour cette collaboration fructueuse.';
        break;
    }

    return RecuCollecte(
      collecte: collecte,
      dateGeneration: dateGeneration,
      numeroRecu: numeroRecu,
      messageRemerciement: messageRemerciement,
    );
  }
}

/// Générer un numéro unique pour les rapports
String _genererNumeroRapport(
    CollecteRapportData collecte, DateTime date, String prefix) {
  final dateFormat = DateFormat('yyyyMMdd');
  final timeFormat = DateFormat('HHmmss');
  final dateStr = dateFormat.format(date);
  final timeStr = timeFormat.format(date);
  final siteCode = collecte.site
      .toUpperCase()
      .replaceAll(' ', '')
      .substring(0, 3.clamp(0, collecte.site.length));
  final typeCode = collecte.typeCollecte.name.toUpperCase().substring(0, 3);

  return '$prefix-$siteCode-$typeCode-$dateStr-$timeStr';
}

/// Extensions utiles pour le formatage
extension CollecteRapportExtensions on CollecteRapportData {
  String get dateFormatee =>
      DateFormat('dd/MM/yyyy à HH:mm').format(dateCollecte);
  String get poidsFormatte => '${poidsTotal.toStringAsFixed(2)} kg';
  String get montantFormatte => '${montantTotal.toStringAsFixed(0)} FCFA';
}

extension RapportStatistiquesExtensions on RapportStatistiques {
  String get dateGenerationFormatee =>
      DateFormat('dd/MM/yyyy à HH:mm').format(dateGeneration);
  String get poidsMoyenFormatte =>
      '${poidsMoyenParContenant.toStringAsFixed(2)} kg';
  String get prixMoyenFormatte =>
      '${prixMoyenAuKilo.toStringAsFixed(0)} FCFA/kg';
  String get rendementFormatte => '${rendementEstime.toStringAsFixed(2)} kg';
}

extension RecuCollecteExtensions on RecuCollecte {
  String get dateGenerationFormatee =>
      DateFormat('dd/MM/yyyy à HH:mm').format(dateGeneration);
}
