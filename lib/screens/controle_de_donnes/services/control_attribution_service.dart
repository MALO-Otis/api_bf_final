import 'dart:convert';
// import 'dart:math'; // Supprimé - utilisé uniquement pour les données fictives
import 'package:flutter/foundation.dart';
import '../models/attribution_models.dart';
import '../models/collecte_models.dart';
import 'firestore_attribution_service.dart';

/// Service pour la gestion des attributions depuis le module Contrôle
class ControlAttributionService extends ChangeNotifier {
  static final ControlAttributionService _instance =
      ControlAttributionService._internal();
  factory ControlAttributionService() => _instance;
  ControlAttributionService._internal() {
    // Removed automatic mock data generation
    // Call _generateMockData() manually if needed for testing
  }

  // Services
  final FirestoreAttributionService _firestoreService =
      FirestoreAttributionService();

  // Simulation d'une base de données en mémoire (pour la compatibilité)
  final List<ControlAttribution> _attributions = [];
  final List<String> _utilisateurs = [
    'Admin Système',
    'Marie Dupont',
    'Jean-Claude Kaboré',
    'Fatima Ouédraogo',
    'Ibrahim Sawadogo',
    'Aïssata Compaoré',
    'Contrôleur Principal',
  ];

  /// Getters
  List<ControlAttribution> get attributions => List.unmodifiable(_attributions);
  List<String> get utilisateurs => List.unmodifiable(_utilisateurs);

  /// MÉTHODE DÉSACTIVÉE : _generateMockData()
  /// Cette méthode générait automatiquement des données fictives d'attribution
  /// Elle a été désactivée pour éviter la pollution de la base avec des données de test
  /*
  void _generateMockData() {
    _attributions.clear();
    final random = Random();

    // Générer 12-18 attributions fictives
    for (int i = 0; i < 15; i++) {
      final dateAttribution = DateTime.now().subtract(
          Duration(days: random.nextInt(60), hours: random.nextInt(24)));

      final type =
          AttributionType.values[random.nextInt(AttributionType.values.length)];
      final defaultStatus = ControlAttribution.getDefaultStatus(type);

      // Progresser certaines attributions dans le workflow
      AttributionStatus statut = defaultStatus;
      if (random.nextDouble() > 0.3) {
        final allStatuts = AttributionStatus.values
            .where((s) =>
                (type == AttributionType.extraction &&
                    s != AttributionStatus.attribueFiltration) ||
                (type == AttributionType.filtration &&
                    s != AttributionStatus.attribueExtraction))
            .toList();
        statut = allStatuts[random.nextInt(allStatuts.length)];
      }

      // Simuler des IDs de contenants
      final nombreContenants = 1 + random.nextInt(4);
      final contenants = List.generate(nombreContenants,
          (j) => '${type.value}_cont_${i}_${j}_${random.nextInt(1000)}');

      // Déterminer la nature des produits selon le type
      final natureProduitsAttribues = type == AttributionType.extraction
          ? ProductNature.brut
          : ProductNature.liquide;

      final attribution = ControlAttribution(
        id: 'ctrl_attr_${DateTime.now().millisecondsSinceEpoch + i}',
        type: type,
        dateAttribution: dateAttribution,
        utilisateur: _utilisateurs[random.nextInt(_utilisateurs.length)],
        listeContenants: contenants,
        statut: statut,
        commentaires: random.nextBool()
            ? 'Attribution depuis contrôle qualité - ${type.label} - ${natureProduitsAttribues.label}'
            : null,
        sourceCollecteId: 'collecte_${i}_${random.nextInt(1000)}',
        sourceType: ['recoltes', 'scoop', 'individuel'][random.nextInt(3)],
        site: [
          'Ouaga',
          'Koudougou',
          'Bobo',
          'Mangodara',
          'Bagré',
          'Pô'
        ][random.nextInt(6)],
        dateCollecte:
            dateAttribution.subtract(Duration(days: random.nextInt(7))),
        natureProduitsAttribues: natureProduitsAttribues,
        metadata: {
          'priorite': random.nextBool() ? 'urgent' : 'normal',
          'qualiteControlee': true,
          'certificat': 'CERT_${random.nextInt(10000)}',
          'natureOrigine': natureProduitsAttribues.value,
        },
      );

      _attributions.add(attribution);
    }

    // Trier par date décroissante
    _attributions
        .sort((a, b) => b.dateAttribution.compareTo(a.dateAttribution));
    notifyListeners();
  }
  */

  /// Crée une nouvelle attribution depuis le contrôle
  Future<String> creerAttributionDepuisControle({
    required AttributionType type,
    required ProductNature natureProduitsAttribues,
    required String utilisateur,
    required List<String> listeContenants,
    required String sourceCollecteId,
    required String sourceType,
    required String siteOrigine,
    required String siteReceveur, // NOUVEAU: Site qui reçoit les produits
    required DateTime dateCollecte,
    String? commentaires,
    Map<String, dynamic> metadata = const {},
  }) async {
    // Validation
    if (listeContenants.isEmpty) {
      throw Exception('Au moins un contenant doit être sélectionné');
    }

    // Validation de la cohérence type/nature
    if (type == AttributionType.extraction &&
        natureProduitsAttribues != ProductNature.brut) {
      throw Exception(
          'L\'extraction ne peut être utilisée que pour des produits bruts');
    }

    if (type == AttributionType.filtration &&
        natureProduitsAttribues != ProductNature.liquide) {
      throw Exception(
          'La filtration ne peut être utilisée que pour des produits liquides/filtrés');
    }

    // Vérifier que les contenants ne sont pas déjà attribués
    for (final attribution in _attributions) {
      if (attribution.statut != AttributionStatus.annule) {
        for (final contenantId in listeContenants) {
          if (attribution.listeContenants.contains(contenantId)) {
            throw Exception(
                'Le contenant $contenantId est déjà attribué à une autre attribution');
          }
        }
      }
    }

    // Sauvegarder l'attribution dans Firestore avec la nouvelle structure
    final attributionId = await _firestoreService.sauvegarderAttribution(
      type: type,
      siteReceveur: siteReceveur,
      sourceCollecteId: sourceCollecteId,
      sourceType: sourceType,
      siteOrigine: siteOrigine,
      dateCollecte: dateCollecte,
      listeContenants: listeContenants,
      natureProduitsAttribues: natureProduitsAttribues,
      utilisateur: utilisateur,
      commentaires:
          commentaires?.trim().isEmpty == true ? null : commentaires?.trim(),
      metadata: {
        'createdFromControl': true,
        'nombreContenants': listeContenants.length,
        ...metadata,
      },
    );

    // Créer l'attribution locale pour la compatibilité (optionnel)
    final attribution = ControlAttribution(
      id: attributionId,
      type: type,
      dateAttribution: DateTime.now(),
      utilisateur: utilisateur,
      listeContenants: List.from(listeContenants),
      statut: ControlAttribution.getDefaultStatus(type),
      commentaires:
          commentaires?.trim().isEmpty == true ? null : commentaires?.trim(),
      sourceCollecteId: sourceCollecteId,
      sourceType: sourceType,
      site: siteOrigine,
      dateCollecte: dateCollecte,
      natureProduitsAttribues: natureProduitsAttribues,
      metadata: Map.from(metadata),
    );

    _attributions.insert(0, attribution); // Ajouter en premier
    notifyListeners();

    if (kDebugMode) {
      print('✅ Attribution sauvegardée en Firestore: $attributionId');
      print('📁 Collection: ${_firestoreService.getCollectionName(type)}');
      print('🏢 Site receveur: $siteReceveur');
      print('📦 Contenants: ${listeContenants.length}');
    }

    return attributionId;
  }

  /// Modifie une attribution existante
  Future<void> modifierAttribution({
    required String attributionId,
    List<String>? listeContenants,
    AttributionStatus? statut,
    String? commentaires,
    required String utilisateurModification,
    Map<String, dynamic>? metadata,
  }) async {
    final index = _attributions.indexWhere((a) => a.id == attributionId);
    if (index == -1) {
      throw Exception('Attribution non trouvée');
    }

    final attribution = _attributions[index];

    // Vérifier si la modification est autorisée
    if (!attribution.peutEtreModifiee) {
      throw Exception('Cette attribution ne peut plus être modifiée');
    }

    // Si les contenants changent, vérifier qu'ils ne sont pas déjà attribués
    if (listeContenants != null) {
      for (final autreAttribution in _attributions) {
        if (autreAttribution.id != attributionId &&
            autreAttribution.statut != AttributionStatus.annule) {
          for (final contenantId in listeContenants) {
            if (autreAttribution.listeContenants.contains(contenantId)) {
              throw Exception(
                  'Le contenant $contenantId est déjà attribué à une autre attribution');
            }
          }
        }
      }
    }

    // Créer la version modifiée
    final attributionModifiee = attribution.copyWith(
      listeContenants: listeContenants,
      statut: statut,
      commentaires:
          commentaires?.trim().isEmpty == true ? null : commentaires?.trim(),
      dateModification: DateTime.now(),
      utilisateurModification: utilisateurModification,
      metadata: metadata,
    );

    _attributions[index] = attributionModifiee;
    notifyListeners();

    // Simulation du délai de sauvegarde
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Annule une attribution
  Future<void> annulerAttribution({
    required String attributionId,
    required String utilisateurAnnulation,
    String? motifAnnulation,
  }) async {
    final index = _attributions.indexWhere((a) => a.id == attributionId);
    if (index == -1) {
      throw Exception('Attribution non trouvée');
    }

    final attribution = _attributions[index];

    // Vérifier si l'annulation est autorisée
    if (!attribution.peutEtreAnnulee) {
      throw Exception('Cette attribution ne peut plus être annulée');
    }

    // Annuler l'attribution
    final attributionAnnulee = attribution.copyWith(
      statut: AttributionStatus.annule,
      commentaires: motifAnnulation?.trim().isEmpty == true
          ? 'Attribution annulée depuis le contrôle'
          : motifAnnulation?.trim(),
      dateModification: DateTime.now(),
      utilisateurModification: utilisateurAnnulation,
    );

    _attributions[index] = attributionAnnulee;
    notifyListeners();

    // Simulation du délai de sauvegarde
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Récupère une attribution par ID
  ControlAttribution? getAttributionById(String id) {
    try {
      return _attributions.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Récupère les attributions par source de collecte
  List<ControlAttribution> getAttributionsBySource(String sourceCollecteId) {
    return _attributions
        .where((a) => a.sourceCollecteId == sourceCollecteId)
        .toList();
  }

  /// Vérifie si une collecte a déjà des attributions
  bool collecteADesAttributions(String sourceCollecteId) {
    return _attributions.any((a) =>
        a.sourceCollecteId == sourceCollecteId &&
        a.statut != AttributionStatus.annule);
  }

  /// Récupère les contenants disponibles pour attribution d'une collecte
  List<String> getContenantsDisponibles(BaseCollecte collecte) {
    // Simuler des contenants basés sur le type de collecte
    final List<String> contenants = [];
    final containersCount = collecte.containersCount ?? 0;

    for (int i = 0; i < containersCount; i++) {
      final contenantId = '${collecte.id}_cont_$i';
      // Vérifier que le contenant n'est pas déjà attribué
      final dejaAttribue = _attributions.any((a) =>
          a.statut != AttributionStatus.annule &&
          a.listeContenants.contains(contenantId));

      if (!dejaAttribue) {
        contenants.add(contenantId);
      }
    }

    return contenants;
  }

  /// Filtre les attributions
  List<ControlAttribution> filtrerAttributions(
      ControlAttributionFilters filtres) {
    var result = List<ControlAttribution>.from(_attributions);

    // Filtre par types
    if (filtres.types.isNotEmpty) {
      result = result.where((a) => filtres.types.contains(a.type)).toList();
    }

    // Filtre par statuts
    if (filtres.statuts.isNotEmpty) {
      result = result.where((a) => filtres.statuts.contains(a.statut)).toList();
    }

    // Filtre par utilisateurs
    if (filtres.utilisateurs.isNotEmpty) {
      result = result
          .where((a) => filtres.utilisateurs.contains(a.utilisateur))
          .toList();
    }

    // Filtre par sites
    if (filtres.sites.isNotEmpty) {
      result = result.where((a) => filtres.sites.contains(a.site)).toList();
    }

    // Filtre par dates
    if (filtres.dateDebut != null) {
      result = result
          .where((a) => a.dateAttribution.isAfter(filtres.dateDebut!))
          .toList();
    }
    if (filtres.dateFin != null) {
      result = result
          .where((a) => a.dateAttribution
              .isBefore(filtres.dateFin!.add(const Duration(days: 1))))
          .toList();
    }

    // Filtre par recherche de lot
    if (filtres.rechercheLot?.isNotEmpty == true) {
      final recherche = filtres.rechercheLot!.toLowerCase();
      result = result
          .where((a) =>
              a.utilisateur.toLowerCase().contains(recherche) ||
              a.site.toLowerCase().contains(recherche) ||
              a.type.label.toLowerCase().contains(recherche) ||
              a.natureProduitsAttribues.label.toLowerCase().contains(recherche))
          .toList();
    }

    return result;
  }

  /// Calcule les statistiques
  ControlAttributionStats calculerStatistiques(
      [List<ControlAttribution>? attributionsPersonnalisees]) {
    final attributions = attributionsPersonnalisees ?? _attributions;
    return ControlAttributionStats.fromAttributions(attributions);
  }

  /// Détermine le type d'attribution suggéré pour une collecte
  AttributionType suggerAttributionType(BaseCollecte collecte) {
    // Logique métier pour suggérer le type d'attribution
    // Basée sur le type de collecte, la qualité, etc.

    if (collecte is Recolte) {
      // Pour les récoltes, suggérer extraction si poids élevé
      if ((collecte.totalWeight ?? 0) > 50) {
        return AttributionType.extraction;
      }
      return AttributionType.filtration;
    } else if (collecte is Scoop) {
      // Pour les SCOOP, privilégier extraction
      return AttributionType.extraction;
    } else {
      // Pour individuelles, privilégier filtration
      return AttributionType.filtration;
    }
  }

  /// Détermine la nature des produits d'une collecte
  ProductNature determineProductNature(BaseCollecte collecte) {
    // Logique pour déterminer si les produits sont bruts ou liquides/filtrés

    if (collecte is Recolte) {
      // Les récoltes contiennent généralement des produits bruts
      return ProductNature.brut;
    } else if (collecte is Scoop) {
      // Les SCOOP peuvent contenir des produits bruts ou déjà traités
      // On suppose bruts par défaut, à confirmer par l'utilisateur
      return ProductNature.brut;
    } else if (collecte is Individuel) {
      // Les collectes individuelles sont souvent déjà transformées
      return ProductNature.liquide;
    }

    // Par défaut : produits bruts
    return ProductNature.brut;
  }

  /// Valide la cohérence entre type d'attribution et nature des produits
  bool validateTypeNatureCoherence(AttributionType type, ProductNature nature) {
    switch (type) {
      case AttributionType.extraction:
        return nature == ProductNature.brut;
      case AttributionType.filtration:
        return nature == ProductNature.liquide;
    }
  }

  /// Exporte les données en JSON (pour sauvegarde locale)
  String exporterJson() {
    final data = {
      'attributions': _attributions.map((a) => a.toMap()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
      'module': 'controle',
    };
    return jsonEncode(data);
  }

  /// Importe les données depuis JSON
  Future<void> importerJson(String jsonData) async {
    try {
      final data = jsonDecode(jsonData);
      final attributionsList = data['attributions'] as List;

      _attributions.clear();
      for (final attributionMap in attributionsList) {
        _attributions.add(ControlAttribution.fromMap(attributionMap));
      }

      // Trier par date décroissante
      _attributions
          .sort((a, b) => b.dateAttribution.compareTo(a.dateAttribution));
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      throw Exception('Erreur lors de l\'importation: $e');
    }
  }

  /// Supprime toutes les données (pour les tests)
  void viderDonnees() {
    _attributions.clear();
    notifyListeners();
  }

  /// MÉTHODE DÉSACTIVÉE : rechargerDonneesMock()
  /// Cette méthode rechargeait les données fictives
  /// Elle a été désactivée pour éviter la pollution de la base avec des données de test
  /*
  void rechargerDonneesMock() {
    _generateMockData();
  }
  */
}
