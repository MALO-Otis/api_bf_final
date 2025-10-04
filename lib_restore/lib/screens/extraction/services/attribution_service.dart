import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/attribution_models.dart';
import 'extraction_service.dart';

/// Service pour la gestion des attributions d'extraction/maturation
class AttributionService extends ChangeNotifier {
  static final AttributionService _instance = AttributionService._internal();
  factory AttributionService() => _instance;
  AttributionService._internal() {
    _generateMockData();
  }

  // Simulation d'une base de données en mémoire
  final List<AttributionExtraction> _attributions = [];
  final List<String> _utilisateurs = [
    'Admin Système',
    'Marie Dupont',
    'Jean-Claude Kaboré',
    'Fatima Ouédraogo',
    'Ibrahim Sawadogo',
    'Aïssata Compaoré',
  ];

  /// Getters
  List<AttributionExtraction> get attributions =>
      List.unmodifiable(_attributions);
  List<String> get utilisateurs => List.unmodifiable(_utilisateurs);

  /// Génère des données fictives
  void _generateMockData() {
    _attributions.clear();
    final random = Random();
    final extractionService = ExtractionService();
    final products = extractionService.getAllProducts();

    // Générer 15-25 attributions fictives
    for (int i = 0; i < 20; i++) {
      final dateAttribution = DateTime.now().subtract(
          Duration(days: random.nextInt(30), hours: random.nextInt(24)));

      // Sélectionner 1-5 produits aléatoirement
      final nombreProduits = 1 + random.nextInt(5);
      final produitsSelectiones = <String>[];

      for (int j = 0; j < nombreProduits && j < products.length; j++) {
        final produitAleatoire = products[random.nextInt(products.length)];
        if (!produitsSelectiones.contains(produitAleatoire.id)) {
          produitsSelectiones.add(produitAleatoire.id);
        }
      }

      final attribution = AttributionExtraction(
        id: 'ATTR_${DateTime.now().millisecondsSinceEpoch + i}',
        dateAttribution: dateAttribution,
        utilisateur: _utilisateurs[random.nextInt(_utilisateurs.length)],
        lotId: 'LOT_${2024000 + i + random.nextInt(1000)}',
        listeContenants: produitsSelectiones,
        statut: AttributionStatus
            .values[random.nextInt(AttributionStatus.values.length)],
        commentaires: random.nextBool()
            ? 'Attribution automatique - Qualité contrôlée'
            : null,
        metadata: {
          'priorite': random.nextBool() ? 'urgent' : 'normal',
          'typeExtraction': ['standard', 'premium', 'bio'][random.nextInt(3)],
        },
      );

      _attributions.add(attribution);
    }

    // Trier par date décroissante
    _attributions
        .sort((a, b) => b.dateAttribution.compareTo(a.dateAttribution));
    notifyListeners();
  }

  /// Crée une nouvelle attribution
  Future<String> creerAttribution({
    required String utilisateur,
    required String lotId,
    required List<String> listeContenants,
    String? commentaires,
    Map<String, dynamic> metadata = const {},
  }) async {
    // Validation
    if (lotId.trim().isEmpty) {
      throw Exception('Le numéro de lot est obligatoire');
    }

    if (listeContenants.isEmpty) {
      throw Exception('Au moins un contenant doit être sélectionné');
    }

    // Vérifier que le lot n'existe pas déjà
    if (_attributions
        .any((a) => a.lotId == lotId && a.statut != AttributionStatus.annule)) {
      throw Exception('Le numéro de lot $lotId existe déjà');
    }

    // Vérifier que les contenants ne sont pas déjà attribués
    for (final attribution in _attributions) {
      if (attribution.statut != AttributionStatus.annule) {
        for (final contenantId in listeContenants) {
          if (attribution.listeContenants.contains(contenantId)) {
            throw Exception(
                'Le contenant $contenantId est déjà attribué au lot ${attribution.lotId}');
          }
        }
      }
    }

    // Créer l'attribution
    final attribution = AttributionExtraction(
      id: 'ATTR_${DateTime.now().millisecondsSinceEpoch}',
      dateAttribution: DateTime.now(),
      utilisateur: utilisateur,
      lotId: lotId,
      listeContenants: List.from(listeContenants),
      statut: AttributionStatus.attribueExtraction,
      commentaires:
          commentaires?.trim().isEmpty == true ? null : commentaires?.trim(),
      metadata: Map.from(metadata),
    );

    _attributions.insert(0, attribution); // Ajouter en premier
    notifyListeners();

    // Simulation du délai de sauvegarde
    await Future.delayed(const Duration(milliseconds: 300));
    return attribution.id;
  }

  /// Modifie une attribution existante
  Future<void> modifierAttribution({
    required String attributionId,
    String? lotId,
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

    // Si le lot change, vérifier qu'il n'existe pas déjà
    if (lotId != null && lotId != attribution.lotId) {
      if (_attributions.any((a) =>
          a.lotId == lotId &&
          a.id != attributionId &&
          a.statut != AttributionStatus.annule)) {
        throw Exception('Le numéro de lot $lotId existe déjà');
      }
    }

    // Si les contenants changent, vérifier qu'ils ne sont pas déjà attribués
    if (listeContenants != null) {
      for (final autreAttribution in _attributions) {
        if (autreAttribution.id != attributionId &&
            autreAttribution.statut != AttributionStatus.annule) {
          for (final contenantId in listeContenants) {
            if (autreAttribution.listeContenants.contains(contenantId)) {
              throw Exception(
                  'Le contenant $contenantId est déjà attribué au lot ${autreAttribution.lotId}');
            }
          }
        }
      }
    }

    // Créer la version modifiée
    final attributionModifiee = attribution.copyWith(
      lotId: lotId,
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
          ? 'Attribution annulée'
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
  AttributionExtraction? getAttributionById(String id) {
    try {
      return _attributions.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Récupère les attributions par lot
  List<AttributionExtraction> getAttributionsByLot(String lotId) {
    return _attributions.where((a) => a.lotId == lotId).toList();
  }

  /// Vérifie si un contenant est déjà attribué
  bool contenantEstAttribue(String contenantId) {
    return _attributions.any((a) =>
        a.statut != AttributionStatus.annule &&
        a.listeContenants.contains(contenantId));
  }

  /// Récupère l'attribution d'un contenant
  AttributionExtraction? getAttributionDuContenant(String contenantId) {
    try {
      return _attributions.firstWhere((a) =>
          a.statut != AttributionStatus.annule &&
          a.listeContenants.contains(contenantId));
    } catch (e) {
      return null;
    }
  }

  /// Filtre les attributions
  List<AttributionExtraction> filtrerAttributions(AttributionFilters filtres) {
    var result = List<AttributionExtraction>.from(_attributions);

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
              a.lotId.toLowerCase().contains(recherche) ||
              a.utilisateur.toLowerCase().contains(recherche))
          .toList();
    }

    return result;
  }

  /// Calcule les statistiques
  AttributionStats calculerStatistiques(
      [List<AttributionExtraction>? attributionsPersonnalisees]) {
    final attributions = attributionsPersonnalisees ?? _attributions;
    return AttributionStats.fromAttributions(attributions);
  }

  /// Exporte les données en JSON (pour sauvegarde locale)
  String exporterJson() {
    final data = {
      'attributions': _attributions.map((a) => a.toMap()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
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
        _attributions.add(AttributionExtraction.fromMap(attributionMap));
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

  /// Recharge les données mock
  void rechargerDonneesMock() {
    _generateMockData();
  }
}
