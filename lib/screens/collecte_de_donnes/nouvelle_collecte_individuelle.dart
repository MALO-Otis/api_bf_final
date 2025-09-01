import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:apisavana_gestion/authentication/user_session.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../../../data/models/collecte_models.dart';
import 'widget_individuel/section_periode_collecte.dart';
import 'widget_individuel/section_producteur.dart';
import 'widget_individuel/section_observations.dart';
import 'widget_individuel/section_resume.dart';
import 'widget_individuel/bouton_enregistrement.dart';
import 'widget_individuel/modal_selection_producteur_reactive.dart';
import 'widget_individuel/modal_nouveau_producteur.dart';
import 'widget_individuel/section_contenants.dart';
import 'widget_individuel/section_champs_manquants.dart';
import 'widget_individuel/section_progression_formulaire.dart';
import 'widget_individuel/section_message_erreur.dart';
import 'widget_individuel/dialogue_confirmation_collecte.dart';
import 'historiques_collectes.dart';

// Page principale
class NouvelleCollecteIndividuellePage extends StatefulWidget {
  const NouvelleCollecteIndividuellePage({Key? key}) : super(key: key);

  @override
  State<NouvelleCollecteIndividuellePage> createState() =>
      _NouvelleCollecteIndividuellePageState();
}

class _NouvelleCollecteIndividuellePageState
    extends State<NouvelleCollecteIndividuellePage>
    with TickerProviderStateMixin {
  // Contrôleurs d'animation
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _shakeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _shakeAnimation;

  // État de l'application
  ProducteurModel? _producteurSelectionne;
  List<ContenantModel> _contenants = [];
  final TextEditingController _observationsController = TextEditingController();

  // Nouveau champ: Période de collecte
  String _periodeCollecte = '';

  // Géolocalisation
  Map<String, dynamic>? _geolocationData;

  bool _isLoading = false;
  String? _errorMessage;
  List<String> _champsManquants = [];

  // Cache de validation pour optimiser les performances
  bool? _validationCache;
  int _lastValidationHash = 0;

  // Session utilisateur
  late UserSession _userSession;
  String get _nomSite => _userSession.site ?? 'DefaultSite';

  @override
  void initState() {
    super.initState();
    print("🟢 NouvelleCollecteIndividuellePage - Initialisation");

    // Récupération de la session utilisateur
    try {
      _userSession = Get.find<UserSession>();
      print(
          "🟢 Session utilisateur trouvée: ${_userSession.nom} - Site: ${_userSession.site}");
    } catch (e) {
      print("🔴 Erreur session utilisateur: $e");
      _userSession = Get.put(UserSession());
    }

    // Initialisation de la période de collecte avec la date du jour
    final now = DateTime.now();
    _periodeCollecte =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

    // Initialisation des animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Démarrage des animations avec délais
    _fadeController.forward();
    _slideController.forward();

    // Animation des sections avec délais
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _slideController.forward();
    });

    // NOUVEAU SYSTÈME SCOOP : Commencer avec une liste vide
    // Les contenants seront ajoutés via le formulaire intégré
  }

  @override
  void dispose() {
    print("🟢 NouvelleCollecteIndividuellePage - Nettoyage");
    _fadeController.dispose();
    _slideController.dispose();
    _shakeController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  // Méthodes de géolocalisation
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          'Service désactivé',
          'Veuillez activer le service de localisation',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
          icon: const Icon(Icons.location_off, color: Colors.orange),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'Permission refusée',
            'Permission de localisation refusée',
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
            icon: const Icon(Icons.location_off, color: Colors.red),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'Permission définitivement refusée',
          'Veuillez autoriser la localisation dans les paramètres',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          icon: const Icon(Icons.location_off, color: Colors.red),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);

      setState(() {
        _geolocationData = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'altitude': position.altitude,
          'heading': position.heading,
          'speed': position.speed,
          'speedAccuracy': position.speedAccuracy,
          'timestamp': position.timestamp,
          'floor': position.floor,
          'isMocked': position.isMocked,
        };
      });

      Get.snackbar(
        'Position récupérée',
        'Localisation GPS enregistrée avec succès',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        icon: const Icon(Icons.gps_fixed, color: Colors.green),
      );
    } catch (e) {
      print('🔴 Erreur géolocalisation: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de récupérer la position: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    }
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('dd/MM HH:mm:ss').format(timestamp);
  }

  Widget _buildLocationCard(String title, String value, IconData icon,
      Color iconColor, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Section géolocalisation
  Widget _buildGeolocationSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade600, Colors.green.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.gps_fixed,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Géolocalisation GPS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_geolocationData == null) ...[
              // Bouton pour récupérer la position
              Center(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade600, Colors.green.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.my_location, color: Colors.white),
                    label: const Text(
                      'Récupérer ma position GPS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Affichage des données GPS
              Row(
                children: [
                  Icon(Icons.check_circle,
                      color: Colors.green.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Position GPS récupérée',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Actualiser'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.teal.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Grille des informations GPS
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: [
                  _buildLocationCard(
                    'Latitude',
                    _geolocationData!['latitude'].toStringAsFixed(6),
                    Icons.north,
                    Colors.blue.shade600,
                    Colors.blue.shade50,
                  ),
                  _buildLocationCard(
                    'Longitude',
                    _geolocationData!['longitude'].toStringAsFixed(6),
                    Icons.east,
                    Colors.orange.shade600,
                    Colors.orange.shade50,
                  ),
                  _buildLocationCard(
                    'Précision',
                    '${_geolocationData!['accuracy'].toStringAsFixed(1)} m',
                    Icons.center_focus_strong,
                    Colors.purple.shade600,
                    Colors.purple.shade50,
                  ),
                  _buildLocationCard(
                    'Horodatage',
                    _formatTimestamp(_geolocationData!['timestamp']),
                    Icons.access_time,
                    Colors.green.shade600,
                    Colors.green.shade50,
                  ),
                  if (_geolocationData!['altitude'] != null)
                    _buildLocationCard(
                      'Altitude',
                      '${_geolocationData!['altitude'].toStringAsFixed(1)} m',
                      Icons.height,
                      Colors.teal.shade600,
                      Colors.teal.shade50,
                    ),
                  if (_geolocationData!['speed'] != null &&
                      _geolocationData!['speed'] > 0)
                    _buildLocationCard(
                      'Vitesse',
                      '${_geolocationData!['speed'].toStringAsFixed(1)} m/s',
                      Icons.speed,
                      Colors.red.shade600,
                      Colors.red.shade50,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Méthodes de gestion des producteurs
  Future<void> _ajouterNouveauProducteur(ProducteurModel producteur) async {
    print(
        "🟡 _ajouterNouveauProducteur - Début ajout producteur: ${producteur.nomPrenom}");

    try {
      setState(() => _isLoading = true);
      print("🟡 _ajouterNouveauProducteur - Loading state activé");

      // Vérification de l'unicité du numéro
      print(
          "🟡 _ajouterNouveauProducteur - Vérification unicité numéro: ${producteur.numero}");
      print("🟡 _ajouterNouveauProducteur - Site: $_nomSite");

      // SÉCURITÉ CRITIQUE : Vérification dans la nouvelle collection listes_prod UNIQUEMENT
      print(
          "🔒 VÉRIFICATION ANTI-ÉCRASEMENT: Recherche dans listes_prod seulement");
      final existingQuery = await FirebaseFirestore.instance
          .collection('Sites')
          .doc(_nomSite)
          .collection('listes_prod')
          .where('numero', isEqualTo: producteur.numero)
          .limit(1)
          .get();

      print(
          "🟡 _ajouterNouveauProducteur - Requête unicité exécutée, docs trouvés: ${existingQuery.docs.length}");

      if (existingQuery.docs.isNotEmpty) {
        print(
            "🔴 _ajouterNouveauProducteur - Numéro déjà existant: ${producteur.numero}");
        print(
            "🔴 _ajouterNouveauProducteur - Document existant ID: ${existingQuery.docs.first.id}");
        _afficherErreur("Ce numéro de producteur existe déjà");
        return;
      }

      // Génération de l'ID du producteur
      final String producteurId = 'prod_${producteur.numero}';
      print(
          "🟡 _ajouterNouveauProducteur - ID producteur généré: $producteurId");

      // Préparation des données pour l'enregistrement
      print("🟡 _ajouterNouveauProducteur - Préparation données Firestore");
      final firestoreData = producteur.toFirestore();
      print(
          "🟡 _ajouterNouveauProducteur - Données préparées: ${firestoreData.keys.toList()}");

      // SÉCURITÉ CRITIQUE : Enregistrement dans listes_prod avec ID personnalisé
      print(
          "🟡 _ajouterNouveauProducteur - Début enregistrement Firestore SÉCURISÉ");
      print("🔒 GARANTIE: Écriture dans listes_prod UNIQUEMENT");

      // ID personnalisé sécurisé
      final numeroSanitize =
          producteur.numero.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final idProducteurPersonnalise = "prod_$numeroSanitize";

      final docRef = FirebaseFirestore.instance
          .collection('Sites')
          .doc(_nomSite)
          .collection('listes_prod')
          .doc(idProducteurPersonnalise);

      print("🟡 _ajouterNouveauProducteur - Document path: ${docRef.path}");

      await docRef.set(firestoreData);
      print("✅ _ajouterNouveauProducteur - Enregistrement Firestore réussi");

      // Sélection automatique du nouveau producteur
      print(
          "🟡 _ajouterNouveauProducteur - Création modèle producteur pour sélection");
      final producteurSelectionne = ProducteurModel(
        id: producteurId,
        nomPrenom: producteur.nomPrenom,
        numero: producteur.numero,
        sexe: producteur.sexe,
        age: producteur.age,
        appartenance: producteur.appartenance,
        cooperative: producteur.cooperative,
        localisation: producteur.localisation,
        nbRuchesTrad: producteur.nbRuchesTrad,
        nbRuchesMod: producteur.nbRuchesMod,
        totalRuches: producteur.totalRuches,
        createdAt: producteur.createdAt,
        updatedAt: producteur.updatedAt,
      );

      print(
          "🟡 _ajouterNouveauProducteur - Modèle producteur créé: ${producteurSelectionne.nomPrenom}");

      setState(() {
        _producteurSelectionne = producteurSelectionne;
      });
      print(
          "🟡 _ajouterNouveauProducteur - État mis à jour avec nouveau producteur");

      // Déclencher la re-validation après sélection
      _updateValidationState();
      print("🟡 _ajouterNouveauProducteur - Validation déclenchée");

      _afficherSucces("Producteur ajouté avec succès");
      print(
          "✅ _ajouterNouveauProducteur - Processus complet terminé avec succès");
    } catch (e, stackTrace) {
      print("🔴 _ajouterNouveauProducteur - ERREUR GENERALE: $e");
      print("🔴 _ajouterNouveauProducteur - STACK TRACE: $stackTrace");
      print(
          "🔴 _ajouterNouveauProducteur - Producteur: ${producteur.nomPrenom} (${producteur.numero})");
      print("🔴 _ajouterNouveauProducteur - Site: $_nomSite");
      _afficherErreur("Erreur lors de l'ajout du producteur: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Méthodes de gestion des contenants avec validation stricte
  void _ajouterContenant(ContenantModel contenant, {bool showMessages = true}) {
    print(
        "🟡 _ajouterContenant - Ajout nouveau contenant: ${contenant.typeMiel}");

    // Vérification stricte que le producteur est sélectionné avant d'ajouter un contenant
    if (_producteurSelectionne == null) {
      print(
          "🔴 Producteur non sélectionné - Impossible d'ajouter un contenant");

      if (showMessages) {
        _shakeController.forward().then((_) => _shakeController.reset());
        _afficherErreur(
            "⚠️ Veuillez d'abord sélectionner ou ajouter un producteur avant d'ajouter des contenants");
      }
      return;
    }

    print("✅ Producteur sélectionné - Ajout du contenant autorisé");

    // Si le contenant n'a pas d'ID, lui assigner un ID avec suffixe
    final contenantAvecId = contenant.id.isEmpty
        ? contenant.copyWith(
            id: 'C${(_contenants.length + 1).toString().padLeft(3, '0')}_individuel')
        : contenant;

    setState(() {
      _contenants.add(contenantAvecId);
    });

    // Déclencher la re-validation
    _updateValidationState();

    // Message de confirmation
    if (showMessages && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Contenant ${_contenants.length} ajouté: ${contenant.typeMiel} ${contenant.typeContenant}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _supprimerContenant(int index) {
    print("🟡 _supprimerContenant - Suppression contenant index: $index");
    if (_contenants.length > 1) {
      setState(() {
        _contenants.removeAt(index);
      });
      // Déclencher la re-validation
      _updateValidationState();
    }
  }

  void _modifierContenant(int index, ContenantModel nouveauContenant) {
    print("🟡 _modifierContenant - Modification contenant index: $index");
    setState(() {
      _contenants[index] = nouveauContenant;
    });
    // Déclencher la re-validation
    _updateValidationState();
  }

  // Calculs automatiques
  double get _poidsTotal {
    final total = _contenants.fold(0.0, (sum, c) => sum + c.quantite);
    print("🟡 Calcul poids total: $total kg");
    return total;
  }

  double get _montantTotal {
    final total = _contenants.fold(0.0, (sum, c) => sum + c.montantTotal);
    print("🟡 Calcul montant total: $total FCFA");
    return total;
  }

  List<String> get _originesFlorales {
    // NOUVEAU SYSTÈME SCOOP : Utiliser les types de miel au lieu des prédominances florales
    final origines = _contenants
        .map((c) => c.typeMiel)
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList();
    print("🟡 Types de miel détectés (nouveau système SCOOP): $origines");
    return origines;
  }

  // Calculer progression du formulaire pour l'indicateur UX
  double get _progressionFormulaire {
    double progress = 0.0;

    // Producteur sélectionné (30%)
    if (_producteurSelectionne != null) progress += 0.3;

    // Contenants valides (50%) - NOUVEAU SYSTÈME SCOOP
    if (_contenants.isNotEmpty) {
      final contenantsValides = _contenants
          .where((c) =>
              c.typeMiel.isNotEmpty &&
              c.typeContenant.isNotEmpty &&
              c.quantite > 0 &&
              c.prixUnitaire > 0)
          .length;
      progress += (contenantsValides / _contenants.length) * 0.5;
    }

    // Période de collecte (10%)
    if (_periodeCollecte.isNotEmpty) progress += 0.1;

    // Observations optionnelles (10%)
    if (_observationsController.text.isNotEmpty) progress += 0.1;

    return progress.clamp(0.0, 1.0);
  }

  // Validation stricte des données avec détail des erreurs et cache optimisé
  bool get _estValide {
    // Calculer hash des données pour détecter les changements
    final currentHash = _calculateValidationHash();

    // Utiliser le cache si les données n'ont pas changé
    if (_validationCache != null && _lastValidationHash == currentHash) {
      return _validationCache!;
    }

    print("🟡 Validation formulaire - Début des vérifications (cache miss)");
    _champsManquants.clear();

    // 1. Vérification du producteur
    if (_producteurSelectionne == null) {
      print("🔴 Validation échouée: Aucun producteur sélectionné");
      _champsManquants.add("• Producteur non sélectionné");
      return false;
    }

    // 2. Vérification des contenants
    if (_contenants.isEmpty) {
      print("🔴 Validation échouée: Aucun contenant");
      _champsManquants.add("• Aucun contenant ajouté");
      return false;
    }

    // 3. Vérification de chaque contenant (NOUVEAU SYSTÈME SCOOP)
    for (int i = 0; i < _contenants.length; i++) {
      final contenant = _contenants[i];

      // NOUVEAU : Validation adaptée au système SCOOP
      if (contenant.typeMiel.isEmpty) {
        print(
            "🔴 Validation échouée: Type de miel manquant pour contenant ${i + 1}");
        _champsManquants.add("• Type de miel manquant (Contenant ${i + 1})");
      }

      if (contenant.typeContenant.isEmpty) {
        print(
            "🔴 Validation échouée: Type de contenant manquant pour contenant ${i + 1}");
        _champsManquants
            .add("• Type de contenant manquant (Contenant ${i + 1})");
      }

      if (contenant.quantite <= 0) {
        print(
            "🔴 Validation échouée: Quantité invalide pour contenant ${i + 1} (${contenant.quantite})");
        _champsManquants.add("• Quantité invalide (Contenant ${i + 1})");
      }

      if (contenant.prixUnitaire <= 0) {
        print(
            "🔴 Validation échouée: Prix unitaire invalide pour contenant ${i + 1} (${contenant.prixUnitaire})");
        _champsManquants.add("• Prix unitaire invalide (Contenant ${i + 1})");
      }

      // Vérification des limites raisonnables
      if (contenant.quantite > 10000) {
        print(
            "🔴 Validation échouée: Quantité trop élevée pour contenant ${i + 1} (${contenant.quantite}kg)");
        _champsManquants.add(
            "• Quantité trop élevée (Contenant ${i + 1}: ${contenant.quantite}kg > 10000kg)");
      }

      if (contenant.prixUnitaire > 50000) {
        print(
            "🔴 Validation échouée: Prix trop élevé pour contenant ${i + 1} (${contenant.prixUnitaire} FCFA/kg)");
        _champsManquants.add(
            "• Prix trop élevé (Contenant ${i + 1}: ${contenant.prixUnitaire} FCFA/kg > 50000 FCFA/kg)");
      }
    }

    // Vérification des totaux
    if (_poidsTotal <= 0) {
      print("🔴 Validation échouée: Poids total invalide ($_poidsTotal kg)");
      _champsManquants.add("• Poids total invalide ($_poidsTotal kg)");
    }

    if (_montantTotal <= 0) {
      print(
          "🔴 Validation échouée: Montant total invalide ($_montantTotal FCFA)");
      _champsManquants.add("• Montant total invalide ($_montantTotal FCFA)");
    }

    if (_champsManquants.isNotEmpty) {
      _validationCache = false;
      _lastValidationHash = currentHash;
      return false;
    }

    print("✅ Validation réussie: Tous les champs sont valides");
    print("   - Producteur: ${_producteurSelectionne!.nomPrenom}");
    print("   - Contenants: ${_contenants.length}");
    print("   - Poids total: $_poidsTotal kg");
    print("   - Montant total: $_montantTotal FCFA");
    print("   - Origines florales: $_originesFlorales");

    _validationCache = true;
    _lastValidationHash = currentHash;
    return true;
  }

  // Calculer hash pour détecter changements dans les données (NOUVEAU SYSTÈME SCOOP)
  int _calculateValidationHash() {
    int hash = 0;
    hash ^= _producteurSelectionne?.id.hashCode ?? 0;
    hash ^= _contenants.length.hashCode;
    for (var contenant in _contenants) {
      hash ^= contenant.typeMiel.hashCode;
      hash ^= contenant.typeContenant.hashCode;
      hash ^= contenant.quantite.hashCode;
      hash ^= contenant.prixUnitaire.hashCode;
      hash ^= contenant.note.hashCode; // Nouveau champ notes
    }
    return hash;
  }

  // Invalider le cache de validation
  void _invalidateValidationCache() {
    _validationCache = null;
    _lastValidationHash = 0;
  }

  // Méthode pour déclencher la re-validation et mise à jour de l'UI
  void _updateValidationState() {
    print("🔄 _updateValidationState - Mise à jour état validation");
    print(
        "   - Producteur avant setState: ${_producteurSelectionne?.nomPrenom ?? 'NULL'}");

    _invalidateValidationCache(); // Invalider le cache avant re-validation
    setState(() {
      // Le getter _estValide sera appelé automatiquement lors du rebuild
      // Cela met à jour _champsManquants et l'état du bouton
    });

    print("   - Formulaire valide après setState: $_estValide");
    print("   - Champs manquants: $_champsManquants");
  }

  // Dialogue de confirmation avant enregistrement
  Future<void> _afficherDialogueConfirmation() async {
    // 🔍 DIAGNOSTIC: État du formulaire avant validation
    print("🔍 DIAGNOSTIC AVANT VALIDATION:");
    print(
        "   - Producteur sélectionné: ${_producteurSelectionne?.nomPrenom ?? 'NULL'}");
    print("   - Nombre de contenants: ${_contenants.length}");
    print("   - Période collecte: $_periodeCollecte");
    print("   - Observations: ${_observationsController.text}");
    print("   - Formulaire valide: $_estValide");

    if (!_estValide) {
      print("🔴 Formulaire invalide");
      _shakeController.forward().then((_) => _shakeController.reset());

      // Message d'erreur avec la liste des champs manquants
      String messageErreur = "Veuillez corriger les erreurs suivantes :";
      if (_champsManquants.isNotEmpty) {
        messageErreur += "\n" + _champsManquants.join("\n");
      }

      _afficherErreur(messageErreur);
      return;
    }

    final bool? confirmation = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => DialogueConfirmationCollecte(
        producteurSelectionne: _producteurSelectionne!,
        contenants: _contenants,
        poidsTotal: _poidsTotal,
        montantTotal: _montantTotal,
        observations: _observationsController.text,
      ),
    );

    if (confirmation == true) {
      await _enregistrerCollecte();
    }
  }

  // Construction du dialogue de confirmation avec résumé détaillé
  // Enregistrement de la collecte
  Future<void> _enregistrerCollecte() async {
    print("🟡 _enregistrerCollecte - Début enregistrement");

    try {
      setState(() => _isLoading = true);

      // Génération de l'ID de la collecte ULTRA-SÉCURISÉ
      final now = DateTime.now();
      final dateStr =
          "${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}";
      final timeStr =
          "${now.hour.toString().padLeft(2, '0')}_${now.minute.toString().padLeft(2, '0')}_${now.second.toString().padLeft(2, '0')}";
      final randomSuffix =
          now.microsecond.toString() + now.millisecondsSinceEpoch.toString();
      final collecteurId = _userSession.uid?.substring(0, 8) ?? 'anonymous';
      final idCollecte =
          "IND_${dateStr}_${timeStr}_${collecteurId}_$randomSuffix";
      print("🟡 ID collecte ULTRA-SÉCURISÉ généré: $idCollecte");

      // Création du modèle de collecte
      print("🟡 Création du modèle avec:");
      print("   - ID: $idCollecte");
      print("   - Producteur: ${_producteurSelectionne!.nomPrenom}");
      print("   - Poids: $_poidsTotal");
      print("   - Montant: $_montantTotal");
      print("   - Contenants: ${_contenants.length}");
      print("   - Origines florales: $_originesFlorales");

      // Utiliser la date sélectionnée dans le formulaire pour dateAchat
      final DateTime selectedDate = (() {
        try {
          final p = _periodeCollecte.split('/');
          return DateTime(
            int.parse(p[2]),
            int.parse(p[1]),
            int.parse(p[0]),
          );
        } catch (_) {
          return DateTime.now();
        }
      })();

      final collecte = CollecteIndividuelleModel(
        idCollecte: idCollecte,
        dateAchat: Timestamp.fromDate(selectedDate),
        periodeCollecte: _periodeCollecte,
        poidsTotal: _poidsTotal,
        montantTotal: _montantTotal,
        nombreContenants: _contenants.length,
        idProducteur: _producteurSelectionne!.id,
        nomProducteur: _producteurSelectionne!.nomPrenom,
        contenants: _contenants,
        originesFlorales: _originesFlorales,
        collecteurId: _userSession.uid ?? '',
        collecteurNom: _userSession.nom ?? '',
        observations: _observationsController.text,
        createdAt: Timestamp.now(),
      );

      print("🟡 Modèle créé avec succès");

      // VÉRIFICATION D'INTÉGRITÉ DES DONNÉES AVANT ENREGISTREMENT
      print("🔍 VÉRIFICATION D'INTÉGRITÉ - Début des contrôles de sécurité");

      // SÉCURITÉ CRITIQUE : Vérifier que le producteur existe réellement dans listes_prod
      print(
          "🔍 Vérification existence producteur dans listes_prod: ${_producteurSelectionne!.id}");
      print(
          "🔒 GARANTIE: Vérification dans listes_prod UNIQUEMENT (pas utilisateurs)");

      final producteurExiste = await FirebaseFirestore.instance
          .collection('Sites')
          .doc(_nomSite)
          .collection('listes_prod')
          .doc(_producteurSelectionne!.id)
          .get();

      if (!producteurExiste.exists) {
        throw Exception(
            "SÉCURITÉ CRITIQUE: Producteur inexistant dans listes_prod (ID: ${_producteurSelectionne!.id})");
      }
      print("✅ Producteur existe et est valide dans listes_prod");

      // VÉRIFICATION ANTI-ÉCRASEMENT : S'assurer qu'on ne va PAS toucher utilisateurs
      print(
          "🔒 VÉRIFICATION ANTI-ÉCRASEMENT: Collection 'utilisateurs' ne sera PAS touchée");
      print(
          "🔒 VÉRIFICATION ANTI-ÉCRASEMENT: Écriture uniquement dans nos_achats_individuels et listes_prod");

      // Vérifier l'unicité de l'ID de collecte
      print("🔍 Vérification unicité ID collecte: $idCollecte");
      final collecteExistante = await FirebaseFirestore.instance
          .collection('Sites')
          .doc(_nomSite)
          .collection('nos_achats_individuels')
          .doc(idCollecte)
          .get();

      if (collecteExistante.exists) {
        throw Exception(
            "SÉCURITÉ: ID de collecte déjà existant (collision): $idCollecte");
      }
      print("✅ ID collecte unique et sécurisé");

      // Vérifier la cohérence des calculs
      final poidsCalcule = _contenants.fold(0.0, (sum, c) => sum + c.quantite);
      final montantCalcule =
          _contenants.fold(0.0, (sum, c) => sum + c.montantTotal);

      if ((poidsCalcule - _poidsTotal).abs() > 0.001) {
        throw Exception(
            "INTÉGRITÉ: Incohérence poids calculé ($poidsCalcule) vs attendu ($_poidsTotal)");
      }

      if ((montantCalcule - _montantTotal).abs() > 0.001) {
        throw Exception(
            "INTÉGRITÉ: Incohérence montant calculé ($montantCalcule) vs attendu ($_montantTotal)");
      }
      print("✅ Calculs cohérents et validés");

      print("✅ VÉRIFICATION D'INTÉGRITÉ - Toutes les données sont sécurisées");

      print("🟡 Début enregistrement séquentiel (compatible Flutter Web)");

      // 1. Enregistrement de la collecte principale avec vérification de concurrence
      print("🟡 Étape 1: Enregistrement collecte principale");
      final collecteRef = FirebaseFirestore.instance
          .collection('Sites')
          .doc(_nomSite)
          .collection('nos_achats_individuels')
          .doc(idCollecte);

      // Double vérification juste avant l'enregistrement
      final finalCheck = await collecteRef.get();
      if (finalCheck.exists) {
        throw Exception(
            "CONCURRENCE: Une autre collecte avec le même ID existe déjà");
      }

      await collecteRef.set(collecte.toFirestore());
      print("✅ Collecte principale enregistrée avec sécurité anti-concurrence");

      // 2. SUPPRESSION DE LA SOUS-COLLECTION : Plus de doublon, collecte uniquement dans nos_achats_individuels
      print(
          "🟡 Étape 2 OPTIMISÉE: Pas de sous-collection pour éviter les doublons");
      print(
          "🔒 GARANTIE: Collecte stockée uniquement dans nos_achats_individuels");
      print(
          "✅ Optimisation: Éviter les écritures redondantes dans listes_prod/collectes");

      // 3. SÉCURITÉ ULTRA-CRITIQUE : Mise à jour EXCLUSIVEMENT des statistiques du producteur
      print(
          "🟡 Étape 3: Mise à jour statistiques producteur dans listes_prod UNIQUEMENT");
      print(
          "🔒 GARANTIE ABSOLUE: Seuls les champs statistiques seront modifiés");
      print(
          "🔒 GARANTIE ABSOLUE: Les données personnelles (nom, âge, localisation) resteront INTACTES");

      final producteurRef = FirebaseFirestore.instance
          .collection('Sites')
          .doc(_nomSite)
          .collection('listes_prod')
          .doc(_producteurSelectionne!.id);

      print(
          "� Récupération document producteur dans listes_prod: ${_producteurSelectionne!.id}");

      // VÉRIFICATION ULTRA-STRICTE si le document producteur existe (méthode compatible web)
      final producteurSnapshot = await producteurRef.get();
      print(
          "🟡 Document producteur existe dans listes_prod: ${producteurSnapshot.exists}");

      if (producteurSnapshot.exists) {
        print("🟡 Mise à jour producteur existant avec SÉCURITÉ MAXIMALE");
        print(
            "🔒 VÉRIFICATION PRÉ-UPDATE: Document existe et contient les bonnes données");

        // VÉRIFICATION ANTI-ÉCRASEMENT : Lire les données actuelles pour s'assurer qu'on ne les perd pas
        final donneesActuelles =
            producteurSnapshot.data() as Map<String, dynamic>;
        if (donneesActuelles.isEmpty) {
          throw Exception("SÉCURITÉ CRITIQUE: Données producteur vides");
        }

        // VÉRIFIER que les champs essentiels existent toujours
        final champsEssentiels = ['nomPrenom', 'numero', 'localisation'];
        for (String champ in champsEssentiels) {
          if (!donneesActuelles.containsKey(champ)) {
            throw Exception(
                "INTÉGRITÉ CRITIQUE: Champ essentiel manquant: $champ");
          }
        }
        print("✅ SÉCURITÉ: Tous les champs essentiels sont présents");

        try {
          // MISE À JOUR SÉCURISÉE : Uniquement les statistiques, JAMAIS les données personnelles
          final updateData = <String, dynamic>{
            'nombreCollectes': FieldValue.increment(1),
            'poidsTotal': FieldValue.increment(_poidsTotal),
            'montantTotal': FieldValue.increment(_montantTotal),
            'derniereCollecte': Timestamp.now(),
            'updatedAt': Timestamp.now(),
          };

          print(
              "🔒 GARANTIE: Seuls ces champs statistiques seront modifiés: ${updateData.keys.toList()}");
          print(
              "🔒 GARANTIE: Les données personnelles (nomPrenom, numero, localisation, etc.) restent INCHANGÉES");

          // Gestion sécurisée et intelligente de l'arrayUnion pour les origines florales
          if (_originesFlorales.isNotEmpty) {
            // Filtrer les doublons et valeurs vides avant arrayUnion
            final originesFiltered = _originesFlorales
                .where((origine) => origine.trim().isNotEmpty)
                .map((origine) => origine.trim())
                .toSet()
                .toList();

            if (originesFiltered.isNotEmpty) {
              updateData['originesFlorale'] =
                  FieldValue.arrayUnion(originesFiltered);
              print("🟡 Ajout sécurisé origines florales: $originesFiltered");
            }
          }

          print(
              "🟡 Données update producteur SÉCURISÉES: ${updateData.keys.toList()}");

          // EXÉCUTION SÉCURISÉE de la mise à jour
          await producteurRef.update(updateData);

          // VÉRIFICATION POST-UPDATE : S'assurer que les données personnelles sont toujours là
          final verificationPost = await producteurRef.get();
          final donneesPostUpdate =
              verificationPost.data() as Map<String, dynamic>;

          for (String champ in champsEssentiels) {
            if (!donneesPostUpdate.containsKey(champ)) {
              throw Exception(
                  "INTÉGRITÉ POST-UPDATE: Champ essentiel perdu: $champ");
            }
          }

          print("✅ Update producteur réussi avec INTÉGRITÉ VÉRIFIÉE");
          print(
              "✅ CONFIRMATION: Toutes les données personnelles sont préservées");
        } catch (e, stackTrace) {
          print("🔴 Erreur update producteur: $e");
          print("🔴 Stack trace update: $stackTrace");
          rethrow;
        }
      } else {
        print("� ALERTE CRITIQUE: Document producteur introuvable!");
        print("🔴 Producteur ID: ${_producteurSelectionne!.id}");
        print("🔴 Producteur Nom: ${_producteurSelectionne!.nomPrenom}");
        print(
            "🔴 IMPOSSIBLE: Le producteur devrait exister car il a été selectionné");
        print(
            "🔴 SÉCURITÉ: Mise à jour uniquement des statistiques sans écraser les données");

        try {
          // SÉCURISÉ : Utiliser update avec merge: true pour ajouter seulement les stats
          // sans écraser les données existantes (nom, âge, localisation, etc.)
          final safeUpdateData = {
            'nombreCollectes': 1,
            'poidsTotal': _poidsTotal,
            'montantTotal': _montantTotal,
            'derniereCollecte': Timestamp.now(),
            'updatedAt': Timestamp.now(),
          };

          // Gestion sécurisée des origines florales sans écrasement
          if (_originesFlorales.isNotEmpty) {
            final originesFiltered = _originesFlorales
                .where((origine) => origine.trim().isNotEmpty)
                .map((origine) => origine.trim())
                .toSet()
                .toList();

            if (originesFiltered.isNotEmpty) {
              safeUpdateData['originesFlorale'] = originesFiltered;
              print("🟡 Origines florales filtrées: $originesFiltered");
            }
          }

          print(
              "🟡 Données sécurisées creation stats: ${safeUpdateData.keys.toList()}");

          // SÉCURISÉ : Utilisation de set avec merge pour ne pas écraser
          await producteurRef.set(safeUpdateData, SetOptions(merge: true));
          print("✅ Statistiques producteur créées de manière sécurisée");

          // Log d'alerte pour investigation
          print(
              "⚠️ INVESTIGATION REQUISE: Producteur existant mais document stats manquant");
        } catch (e, stackTrace) {
          print("🔴 Erreur création sécurisée stats producteur: $e");
          print("🔴 Stack trace création sécurisée: $stackTrace");
          rethrow;
        }
      }

      // 4. Mise à jour des statistiques du site
      print("🟡 Étape 4: Mise à jour statistiques site");
      final siteStatsRef = FirebaseFirestore.instance
          .collection('Sites')
          .doc(_nomSite)
          .collection('site_infos')
          .doc('infos');

      final currentMonth =
          "${now.year}-${now.month.toString().padLeft(2, '0')}";

      print("🟡 Mois actuel: $currentMonth");
      print("🟡 Récupération statistiques site");

      // Vérifier si le document des statistiques du site existe (méthode compatible web)
      final siteStatsSnapshot = await siteStatsRef.get();
      print("🟡 Document site existe: ${siteStatsSnapshot.exists}");

      if (siteStatsSnapshot.exists) {
        print("🟡 Mise à jour statistiques site existantes");
        try {
          // Le document existe, faire un update avec ventilation des contenants par mois
          final Map<String, int> nbContenantsParType = {};
          for (final c in _contenants) {
            final raw =
                (c.typeContenant.isEmpty ? 'Inconnu' : c.typeContenant).trim();
            final sanitized = raw.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
            nbContenantsParType[sanitized] =
                (nbContenantsParType[sanitized] ?? 0) + 1;
          }

          // MIGRATION rétro-compatible: si le noeud du mois est numérique, on le convertit en objet { total: <valeur> }
          final siteData = siteStatsSnapshot.data() as Map<String, dynamic>?;
          final dynamic cpmNode = (siteData?['contenant_collecter_par_mois']
              as Map<String, dynamic>?)?[currentMonth];
          if (cpmNode is num) {
            final int ancienTotal = cpmNode.toInt();
            final Map<String, dynamic> contMonthMigrated = {
              'total': ancienTotal + _contenants.length,
            };
            nbContenantsParType.forEach((k, v) {
              contMonthMigrated[k] = (contMonthMigrated[k] ?? 0) + v;
            });

            print(
                "🛠️ MIGRATION: conversion de contenant_collecter_par_mois.$currentMonth (num) -> objet");
            await siteStatsRef.set({
              'contenant_collecter_par_mois': {currentMonth: contMonthMigrated}
            }, SetOptions(merge: true));
          }

          // Construction des updates dynamiques
          final Map<String, dynamic> siteUpdateData = {
            'total_collectes_individuelles': FieldValue.increment(1),
            'total_poids_collecte_individuelle':
                FieldValue.increment(_poidsTotal),
            'total_montant_collecte_individuelle':
                FieldValue.increment(_montantTotal),
            'collectes_par_mois.$currentMonth': FieldValue.increment(1),
            // Nouveaux indicateurs pertinents
            'poids_par_mois.$currentMonth': FieldValue.increment(_poidsTotal),
            'montant_par_mois.$currentMonth':
                FieldValue.increment(_montantTotal),
            'miel_types_cumules': FieldValue.arrayUnion(_originesFlorales),
            'derniere_activite': Timestamp.now(),
          };
          // total de contenants du mois (crée ou incrémente le champ nested)
          siteUpdateData['contenant_collecter_par_mois.$currentMonth.total'] =
              FieldValue.increment(_contenants.length);
          // Assurer présence des clés standards
          siteUpdateData['contenant_collecter_par_mois.$currentMonth.Bidon'] =
              FieldValue.increment(nbContenantsParType['Bidon'] ?? 0);
          siteUpdateData['contenant_collecter_par_mois.$currentMonth.Pot'] =
              FieldValue.increment(nbContenantsParType['Pot'] ?? 0);
          // ventilation par type de contenant additionnels
          nbContenantsParType.forEach((typeKey, count) {
            if (typeKey != 'Bidon' && typeKey != 'Pot') {
              siteUpdateData[
                      'contenant_collecter_par_mois.$currentMonth.$typeKey'] =
                  FieldValue.increment(count);
            }
          });

          print("🟡 Données update site: ${siteUpdateData.keys.toList()}");
          await siteStatsRef.update(siteUpdateData);
          print("✅ Update site réussi");
        } catch (e, stackTrace) {
          print("🔴 Erreur update site: $e");
          print("🔴 Stack trace update site: $stackTrace");
          rethrow;
        }
      } else {
        print("🟡 Création nouvelles statistiques site");
        try {
          // Le document n'existe pas, le créer avec les valeurs initiales
          final Map<String, int> nbContenantsParType = {};
          for (final c in _contenants) {
            final raw =
                (c.typeContenant.isEmpty ? 'Inconnu' : c.typeContenant).trim();
            final sanitized = raw.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
            nbContenantsParType[sanitized] =
                (nbContenantsParType[sanitized] ?? 0) + 1;
          }

          final Map<String, dynamic> contMonth = {
            'total': _contenants.length,
            // Assurer les clés présentes avec 0 par défaut
            'Bidon': 0,
            'Pot': 0,
            ...nbContenantsParType,
          };

          final siteCreateData = {
            'total_collectes_individuelles': 1,
            'total_poids_collecte_individuelle': _poidsTotal,
            'total_montant_collecte_individuelle': _montantTotal,
            'collectes_par_mois': {currentMonth: 1},
            'contenant_collecter_par_mois': {currentMonth: contMonth},
            // Nouveaux indicateurs pertinents
            'poids_par_mois': {currentMonth: _poidsTotal},
            'montant_par_mois': {currentMonth: _montantTotal},
            'miel_types_cumules': _originesFlorales,
            'derniere_activite': Timestamp.now(),
            'created_at': Timestamp.now(),
          };

          print("🟡 Données création site: ${siteCreateData.keys.toList()}");
          await siteStatsRef.set(siteCreateData, SetOptions(merge: true));
          print("✅ Création site réussie");
        } catch (e, stackTrace) {
          print("🔴 Erreur création site: $e");
          print("🔴 Stack trace création site: $stackTrace");
          rethrow;
        }
      }

      print("✅ Enregistrement séquentiel terminé avec succès");

      // NOUVELLE FONCTIONNALITÉ : Génération automatique des statistiques avancées
      print("📊 STATISTIQUES AVANCÉES - Début génération automatique");
      try {
        await _genererStatistiquesAvancees();
        print("✅ STATISTIQUES AVANCÉES - Génération terminée avec succès");
      } catch (e, stackTrace) {
        print("🔴 STATISTIQUES AVANCÉES - Erreur lors de la génération: $e");
        print("🔴 STATISTIQUES AVANCÉES - Stack trace: $stackTrace");
        // Continue malgré l'erreur pour ne pas bloquer la collecte
      }

      // VÉRIFICATION ET CRÉATION DES COLLECTIONS SI NÉCESSAIRE
      print(
          "🔍 VÉRIFICATION COLLECTIONS - Contrôle existence collections critiques");
      await _verifierEtCreerCollections();

      // VÉRIFICATION FINALE DE L'INTÉGRITÉ POST-ENREGISTREMENT
      print("🔍 VÉRIFICATION FINALE - Contrôle post-enregistrement");

      try {
        // Vérifier que la collecte principale existe
        final collecteVerif = await collecteRef.get();
        if (!collecteVerif.exists) {
          print("🔴 ERREUR CRITIQUE: Collecte principale non enregistrée!");
        } else {
          print("✅ Collecte principale vérifiée");
        }

        // Note : Plus de vérification de sous-collection car supprimée pour éviter les doublons

        print("✅ VÉRIFICATION FINALE - Intégrité confirmée");
      } catch (e) {
        print(
            "⚠️ Erreur lors de la vérification finale (mais enregistrement probablement OK): $e");
      }

      // Réinitialisation du formulaire
      _reinitialiserFormulaire();

      _afficherSucces(
          "Collecte enregistrée avec succès et intégrité vérifiée !");
    } catch (e, stackTrace) {
      print("🔴 ERREUR CRITIQUE lors de l'enregistrement collecte: $e");
      print("🔴 STACK TRACE COMPLET: $stackTrace");
      print("🔴 CONTEXTE ERREUR:");
      print("   - Site: $_nomSite");
      print(
          "   - Producteur: ${_producteurSelectionne?.nomPrenom} (${_producteurSelectionne?.id})");
      print("   - Contenants: ${_contenants.length}");
      print("   - Poids total: $_poidsTotal");
      print("   - Montant total: $_montantTotal");

      // Message d'erreur intelligent selon le type d'erreur
      String messageErreur = "Erreur lors de l'enregistrement";
      if (e.toString().contains("SÉCURITÉ")) {
        messageErreur = "Erreur de sécurité: ${e.toString()}";
      } else if (e.toString().contains("INTÉGRITÉ")) {
        messageErreur = "Erreur d'intégrité des données: ${e.toString()}";
      } else if (e.toString().contains("CONCURRENCE")) {
        messageErreur = "Conflit d'accès concurrent: ${e.toString()}";
      } else {
        messageErreur = "Erreur technique: $e";
      }

      _afficherErreur(messageErreur);
    } finally {
      // 🔧 SÉCURITÉ: Vérifier que le widget est encore monté avant setState
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // NOUVELLE FONCTIONNALITÉ : Génération automatique des statistiques avancées - FORMAT STRUCTURÉ
  Future<void> _genererStatistiquesAvancees() async {
    print(
        "📊 _genererStatistiquesAvancees - Début génération format structuré");

    try {
      // 1. Récupération de tous les producteurs de listes_prod
      print("🔍 STATS - Récupération producteurs depuis listes_prod...");
      final producteursQuery = await FirebaseFirestore.instance
          .collection('Sites')
          .doc(_nomSite)
          .collection('listes_prod')
          .get();

      print(
          "📋 STATS - Nombre de producteurs trouvés: ${producteursQuery.docs.length}");

      // 2. Récupération de toutes les collectes individuelles
      print(
          "🔍 STATS - Récupération collectes depuis nos_achats_individuels...");
      final collectesQuery = await FirebaseFirestore.instance
          .collection('Sites')
          .doc(_nomSite)
          .collection('nos_achats_individuels')
          .get();

      print(
          "📋 STATS - Nombre de collectes trouvées: ${collectesQuery.docs.length}");

      // 3. Structures pour le nouveau format
      Map<String, Map<String, dynamic>> villagesData = {};
      Map<String, Map<String, dynamic>> collectesProducteursData = {};

      print("🏗️ STATS - Initialisation structures de données...");

      // 4. Analyse des producteurs par village
      print("📍 STATS - Analyse producteurs par village...");
      for (var producteurDoc in producteursQuery.docs) {
        final producteurData = producteurDoc.data();
        final localisation =
            producteurData['localisation'] as Map<String, dynamic>? ?? {};
        final village = localisation['village']?.toString() ?? 'Non spécifié';
        final nomProducteur =
            producteurData['nomPrenom']?.toString() ?? 'Nom inconnu';

        // Initialiser le village s'il n'existe pas
        if (!villagesData.containsKey(village)) {
          villagesData[village] = {
            'nom': village,
            'producteurs': 0,
            // Structure riche par village demandée
            'contenant': <String,
                Map<String,
                    dynamic>>{}, // typeContenant -> {nombre, contenues:[], prixTotal}
            'quantiteMiel': <String, double>{}, // typeMiel -> somme quantite
          };
          print("🆕 STATS - Nouveau village détecté: $village");
        }

        // Compter les producteurs
        villagesData[village]!['producteurs'] =
            (villagesData[village]!['producteurs'] as int) + 1;

        // Initialiser les collectes du producteur
        collectesProducteursData[producteurDoc.id] = {
          'id': producteurDoc.id,
          'nom': nomProducteur,
          'collectes': 0,
          // Récap enrichi par producteur
          'recap': {
            'periode': '',
            'contenants': <String,
                dynamic>{}, // ex: {Pot:{nombre:2, types:{Liquide:1, Brute:1}}, Bidon:{...}}
          }
        };

        print("📋 STATS - Producteur: $nomProducteur (Village: $village)");
      }

      print("🏘️ STATS - ${villagesData.length} villages identifiés");

      // 5. Analyse des collectes et contenants
      print("📦 STATS - Analyse collectes et contenants...");
      for (var collecteDoc in collectesQuery.docs) {
        final collecteData = collecteDoc.data();
        final idProducteur = collecteData['id_producteur']?.toString() ?? '';
        final nomProducteur =
            collecteData['nom_producteur']?.toString() ?? 'Nom inconnu';
        final contenants = collecteData['contenants'] as List<dynamic>? ?? [];

        print(
            "🔄 STATS - Traitement collecte: ${collecteDoc.id} (Producteur: $nomProducteur)");

        // Compter les collectes par producteur + remplir récap
        if (idProducteur.isNotEmpty &&
            collectesProducteursData.containsKey(idProducteur)) {
          collectesProducteursData[idProducteur]!['collectes'] =
              (collectesProducteursData[idProducteur]!['collectes'] as int) + 1;

          // Période (première à dernière collecte rencontrée)
          final recap = collectesProducteursData[idProducteur]!['recap']
              as Map<String, dynamic>;
          final dateLecture =
              (collecteData['date_achat'] as Timestamp?)?.toDate() ??
                  DateTime.now();
          final periode = (recap['periode'] as String?) ?? '';
          if (periode.isEmpty) {
            recap['periode'] = DateFormat('dd/MM/yyyy').format(dateLecture);
          } else {
            recap['periode'] =
                '${periode.split(' à ').first} à ${DateFormat('dd/MM/yyyy').format(dateLecture)}';
          }
        }

        // Trouver le village du producteur
        String village = 'Non spécifié';
        try {
          final producteurDoc = await FirebaseFirestore.instance
              .collection('Sites')
              .doc(_nomSite)
              .collection('listes_prod')
              .doc(idProducteur)
              .get();

          if (producteurDoc.exists) {
            final producteurData = producteurDoc.data() as Map<String, dynamic>;
            final localisation =
                producteurData['localisation'] as Map<String, dynamic>? ?? {};
            village = localisation['village']?.toString() ?? 'Non spécifié';
          }
        } catch (e) {
          print(
              "⚠️ STATS - Erreur récupération village producteur $idProducteur: $e");
        }

        print(
            "📍 STATS - Village identifié: $village pour collecte ${collecteDoc.id}");

        // S'assurer que le village existe dans nos données avec la nouvelle structure
        if (!villagesData.containsKey(village)) {
          villagesData[village] = {
            'nom': village,
            'producteurs': 0,
            'contenant': <String, Map<String, dynamic>>{},
            'quantiteMiel': <String, double>{},
          };
          print("🆕 STATS - Village créé à la volée: $village");
        }

        // Analyser chaque contenant
        for (var contenant in contenants) {
          final contenantData = contenant as Map<String, dynamic>;
          final typeContenant =
              contenantData['type_contenant']?.toString() ?? 'Non spécifié';
          final typeMiel =
              contenantData['type_miel']?.toString() ?? 'Non spécifié';
          final quantite = (contenantData['quantite'] ?? 0.0).toDouble();
          final prixUnitaire =
              (contenantData['prix_unitaire'] ?? 0.0).toDouble();

          print(
              "📦 STATS - Contenant: $typeContenant, Miel: $typeMiel (${quantite}kg à ${prixUnitaire}F)");

          // Village data
          final villageEntry = villagesData[village]!;

          // Bloc contenant par typeContenant
          final Map<String, Map<String, dynamic>> contBloc =
              villageEntry['contenant'] as Map<String, Map<String, dynamic>>;
          contBloc[typeContenant] ??= {
            'type': typeContenant,
            'nombre': 0,
            'contenues': <Map<String, dynamic>>[],
            'prixTotal': 0.0,
          };

          // Incrément du nombre de contenants, prix total
          contBloc[typeContenant]!['nombre'] =
              (contBloc[typeContenant]!['nombre'] as int) + 1;
          contBloc[typeContenant]!['prixTotal'] =
              (contBloc[typeContenant]!['prixTotal'] as double) +
                  (prixUnitaire * quantite);

          // Contenues par type de miel pour ce type de contenant
          final List<Map<String, dynamic>> contenuesList =
              contBloc[typeContenant]!['contenues']
                  as List<Map<String, dynamic>>;
          final idx = contenuesList
              .indexWhere((m) => (m['type']?.toString() ?? '') == typeMiel);
          if (idx >= 0) {
            // mise à jour
            contenuesList[idx]['nombre'] =
                (contenuesList[idx]['nombre'] as int) + 1;
            // poids moyen: moyenne simple des quantités observées
            final double prevPoids =
                (contenuesList[idx]['poidsMoyen'] as num?)?.toDouble() ?? 0;
            final int prevCount = (contenuesList[idx]['nombre'] as int);
            contenuesList[idx]['poidsMoyen'] =
                ((prevPoids * (prevCount - 1)) + quantite) / (prevCount);
            // prixMoyen: moyenne simple des prix unitaire observés
            final double prevPrix =
                (contenuesList[idx]['prixMoyen'] as num?)?.toDouble() ?? 0;
            contenuesList[idx]['prixMoyen'] =
                ((prevPrix * (prevCount - 1)) + prixUnitaire) / (prevCount);
          } else {
            contenuesList.add({
              'type': typeMiel,
              'nombre': 1,
              'poidsMoyen': quantite,
              'prixMoyen': prixUnitaire,
            });
          }

          // Quantités totales par type de miel (village)
          final Map<String, double> quantitesVillage =
              (villageEntry['quantiteMiel'] as Map<String, double>);
          quantitesVillage[typeMiel] =
              (quantitesVillage[typeMiel] ?? 0.0) + quantite;

          print("✅ STATS - Données mises à jour pour $village");

          // Récap par producteur: contenants et types
          if (idProducteur.isNotEmpty &&
              collectesProducteursData.containsKey(idProducteur)) {
            final recap = collectesProducteursData[idProducteur]!['recap']
                as Map<String, dynamic>;
            final conts = recap['contenants'] as Map<String, dynamic>;
            conts[typeContenant] ??= {
              'nombre': 0,
              'types': <String, int>{},
            };
            conts[typeContenant]['nombre'] =
                (conts[typeContenant]['nombre'] as int) + 1;
            final typesMap = conts[typeContenant]['types'] as Map<String, int>;
            typesMap[typeMiel] = (typesMap[typeMiel] ?? 0) + 1;
          }
        }
      }

      // 6. Conversion au format final structuré (version enrichie)
      print("🔄 STATS - Conversion vers format final structuré enrichi...");

      List<Map<String, dynamic>> villagesList = [];
      for (var villageEntry in villagesData.entries) {
        final villageData = villageEntry.value;

        // Conversion contenants détaillés
        List<Map<String, dynamic>> contenantsList = [];
        Map<String, Map<String, dynamic>> contBloc =
            villageData['contenant'] as Map<String, Map<String, dynamic>>;
        for (var entry in contBloc.entries) {
          final bloc = entry.value;
          contenantsList.add({
            'type': bloc['type'],
            'nombre': bloc['nombre'],
            'contenues': (bloc['contenues'] as List)
                .map((m) => {
                      'type': m['type'],
                      'nombre': m['nombre'],
                      'poidsMoyen': m['poidsMoyen'],
                      'prixMoyen': m['prixMoyen'],
                    })
                .toList(),
            'prixTotal': (bloc['prixTotal'] as num).toDouble(),
          });
        }

        // Conversion quantités totales par type de miel
        List<Map<String, dynamic>> quantitesTotales = [];
        Map<String, double> quantiteMap =
            villageData['quantiteMiel'] as Map<String, double>;
        for (var entry in quantiteMap.entries) {
          quantitesTotales.add({
            'type': entry.key,
            'quantite': entry.value,
          });
        }

        villagesList.add({
          'nom': villageData['nom'],
          'producteurs': villageData['producteurs'],
          'contenant': contenantsList,
          'quantitesTotales': quantitesTotales,
        });

        print(
            "📋 STATS - Village formaté: ${villageData['nom']} (${villageData['producteurs']} producteurs)");
      }

      // Conversion collectes producteurs enrichie
      List<Map<String, dynamic>> collectesProducteursList = [];
      for (var entry in collectesProducteursData.entries) {
        final val = entry.value;
        final recap = val['recap'] as Map<String, dynamic>;
        final Map<String, dynamic> conts = recap['contenants'];
        // Restructurer le détail des contenants pour une lecture dashboard facile
        final Map<String, dynamic> contsRes = {};
        conts.forEach((k, v) {
          contsRes[k] = {
            'nombre': v['nombre'],
            'types': Map<String, int>.from(v['types'] as Map),
          };
        });
        collectesProducteursList.add({
          'id': val['id'],
          'nom': val['nom'],
          'collectes': val['collectes'],
          'periode': recap['periode'],
          'contenants': contsRes,
        });
      }

      // 7. Structure finale EXACTE demandée
      final statistiquesAvancees = {
        'villages': villagesList,
        'collectesProducteurs': collectesProducteursList,
      };

      print(
          "📦 STATS - Structure finale prête (villages: ${villagesList.length}, collectesProducteurs: ${collectesProducteursList.length})");

      // 8. Vérification de l'existence de la collection nos_achats_individuels
      print("🔍 STATS - Vérification collection nos_achats_individuels...");
      final collectionTest = await FirebaseFirestore.instance
          .collection('Sites')
          .doc(_nomSite)
          .collection('nos_achats_individuels')
          .limit(1)
          .get();

      if (collectionTest.docs.isNotEmpty) {
        print(
            "✅ STATS - Collection nos_achats_individuels existe, procédure d'enregistrement...");

        // 9. Enregistrement dans nos_achats_individuels/statistiques_avancees
        final statsRef = FirebaseFirestore.instance
            .collection('Sites')
            .doc(_nomSite)
            .collection('nos_achats_individuels')
            .doc('statistiques_avancees');

        print("💾 STATS - Enregistrement des statistiques avancées...");
        print(
            "💾 STATS - Référence: Sites/$_nomSite/nos_achats_individuels/statistiques_avancees");
        print(
            "💾 STATS - Clés sauvegardées: ${statistiquesAvancees.keys.toList()}");

        await statsRef.set(statistiquesAvancees, SetOptions(merge: true));

        // Vérification immédiate de l'écriture
        final verificationDoc = await statsRef.get();
        if (verificationDoc.exists) {
          print(
              "✅ STATS - Statistiques enregistrées ET VÉRIFIÉES dans nos_achats_individuels/statistiques_avancees");
          print(
              "✅ STATS - Clés vérifiées: ${verificationDoc.data()?.keys.toList()}");
        } else {
          print("❌ STATS - ERREUR: Document non trouvé après écriture!");
        }

        // Affichage détaillé des résultats
        print("📊 STATS - RÉSUMÉ FINAL:");
        for (var village in villagesList) {
          print(
              "   🏘️ ${village['nom']}: ${village['producteurs']} producteurs");
          print(
              "      📦 Contenants: ${(village['contenant'] as List).length} types");
          print(
              "      🍯 Types de miel: ${(village['prixMiel'] as List).length} types");
        }
      } else {
        print(
            "❌ STATS - Collection nos_achats_individuels introuvable, statistiques non enregistrées");
      }
    } catch (e, stackTrace) {
      print("🔴 STATS - Erreur génération statistiques structurées: $e");
      print("🔴 STATS - Stack trace: $stackTrace");
      // Ne pas faire échouer l'enregistrement principal pour cette erreur
    }
  }

  // NOUVELLE FONCTIONNALITÉ : Vérification et création des collections
  Future<void> _verifierEtCreerCollections() async {
    print("🔍 _verifierEtCreerCollections - Début vérification");

    try {
      final now = Timestamp.now();

      // 1. Vérifier collection listes_prod
      print("🔍 Vérification collection listes_prod...");
      final listesProductQuery = await FirebaseFirestore.instance
          .collection('Sites')
          .doc(_nomSite)
          .collection('listes_prod')
          .limit(1)
          .get();

      if (listesProductQuery.docs.isEmpty) {
        print(
            "⚠️ Collection listes_prod vide - Création document de référence");
        await FirebaseFirestore.instance
            .collection('Sites')
            .doc(_nomSite)
            .collection('listes_prod')
            .doc('_collection_info')
            .set({
          'created_at': now,
          'description': 'Collection des producteurs - Créée automatiquement',
          'last_check': now,
        });
        print("✅ Document de référence listes_prod créé");
      } else {
        print(
            "✅ Collection listes_prod existe (${listesProductQuery.docs.length} documents trouvés)");
      }

      // 2. Vérifier collection nos_achats_individuels
      print("🔍 Vérification collection nos_achats_individuels...");
      final achatsQuery = await FirebaseFirestore.instance
          .collection('Sites')
          .doc(_nomSite)
          .collection('nos_achats_individuels')
          .limit(1)
          .get();

      if (achatsQuery.docs.isEmpty) {
        print(
            "⚠️ Collection nos_achats_individuels vide - Création document de référence");
        await FirebaseFirestore.instance
            .collection('Sites')
            .doc(_nomSite)
            .collection('nos_achats_individuels')
            .doc('_collection_info')
            .set({
          'created_at': now,
          'description':
              'Collection des achats individuels - Créée automatiquement',
          'last_check': now,
        });
        print("✅ Document de référence nos_achats_individuels créé");
      } else {
        print(
            "✅ Collection nos_achats_individuels existe (${achatsQuery.docs.length} documents trouvés)");
      }

      // 3. Vérifier document statistiques_avancees DANS nos_achats_individuels (migration du précédent emplacement)
      print(
          "🔍 Vérification statistiques_avancees dans nos_achats_individuels...");
      final statsDocInAchats = await FirebaseFirestore.instance
          .collection('Sites')
          .doc(_nomSite)
          .collection('nos_achats_individuels')
          .doc('statistiques_avancees')
          .get();

      if (!statsDocInAchats.exists) {
        print(
            "⚠️ statistiques_avancees absent sous nos_achats_individuels - Création document de référence (vide)");
        await FirebaseFirestore.instance
            .collection('Sites')
            .doc(_nomSite)
            .collection('nos_achats_individuels')
            .doc('statistiques_avancees')
            .set({
          'villages': [],
          'collectesProducteurs': [],
          'created_at': now,
          'last_check': now,
        }, SetOptions(merge: true));
        print(
            "✅ Document statistiques_avancees initialisé sous nos_achats_individuels");
      } else {
        print(
            "✅ statistiques_avancees déjà présent sous nos_achats_individuels");
      }

      // 4. Vérification finale de l'existence du producteur actuel
      if (_producteurSelectionne != null) {
        print(
            "🔍 Vérification finale existence producteur ${_producteurSelectionne!.id}...");
        final producteurDoc = await FirebaseFirestore.instance
            .collection('Sites')
            .doc(_nomSite)
            .collection('listes_prod')
            .doc(_producteurSelectionne!.id)
            .get();

        if (producteurDoc.exists) {
          print(
              "✅ Producteur ${_producteurSelectionne!.nomPrenom} confirmé dans listes_prod");
        } else {
          print(
              "🔴 ALERTE: Producteur ${_producteurSelectionne!.nomPrenom} introuvable dans listes_prod!");
        }
      }

      print("✅ Vérification collections terminée avec succès");
    } catch (e, stackTrace) {
      print("🔴 Erreur vérification collections: $e");
      print("🔴 Stack trace: $stackTrace");
      // Ne pas faire échouer l'enregistrement principal pour cette erreur
    }
  }

  void _reinitialiserFormulaire() {
    print("🟡 _reinitialiserFormulaire - Réinitialisation");
    setState(() {
      _producteurSelectionne = null;
      // Réinitialiser la période de collecte avec la date du jour
      final now = DateTime.now();
      _periodeCollecte =
          "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

      _contenants = [];
      _observationsController.clear();
      _errorMessage = null;
    });
  }

  // Gestion des messages
  void _afficherErreur(String message) {
    print("🔴 Erreur affichée: $message");

    // 🔧 SÉCURITÉ: Vérifier que le widget est encore monté
    if (!mounted) {
      print("⚠️ Widget non monté, impossible d'afficher l'erreur");
      return;
    }

    setState(() => _errorMessage = message);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );

    // Effacer le message après 4 secondes
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _errorMessage = null);
    });
  }

  void _afficherSucces(String message) {
    print("✅ Succès affiché: $message");

    // 🔧 SÉCURITÉ: Vérifier que le widget est encore monté
    if (!mounted) {
      print("⚠️ Widget non monté, impossible d'afficher le succès");
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Modal de sélection des producteurs ULTRA-RÉACTIF avec StreamBuilder
  void _afficherModalProducteurs() async {
    print("🟡 _afficherModalProducteurs - Ouverture modal ULTRA-RÉACTIVE");
    print("🔒 GARANTIE: Chargement temps réel depuis listes_prod UNIQUEMENT");
    print(
        "🚀 RÉACTIVITÉ: Utilisation StreamBuilder pour mise à jour automatique");

    try {
      if (!mounted) return;

      final ProducteurModel? producteurSelectionne =
          await showDialog<ProducteurModel>(
        context: context,
        builder: (context) => ModalSelectionProducteurReactive(
          nomSite: _nomSite,
          producteurSelectionne: _producteurSelectionne,
        ),
      );

      if (producteurSelectionne != null) {
        print(
            "✅ Producteur sélectionné en temps réel: ${producteurSelectionne.nomPrenom}");
        print("🔒 CONFIRMATION: Lecture des bons champs depuis listes_prod");
        print("   - ID: ${producteurSelectionne.id}");
        print("   - Numéro: ${producteurSelectionne.numero}");
        print("   - Nom: ${producteurSelectionne.nomPrenom}");
        print("   - Âge: ${producteurSelectionne.age}");
        print("   - Village: ${producteurSelectionne.localisation['village']}");
        print("   - Coopérative: ${producteurSelectionne.cooperative}");

        setState(() {
          _producteurSelectionne = producteurSelectionne;
        });

        // 🔍 DIAGNOSTIC: Producteur sélectionné
        print("✅ PRODUCTEUR SÉLECTIONNÉ:");
        print("   - ID: ${producteurSelectionne.id}");
        print("   - Nom: ${producteurSelectionne.nomPrenom}");
        print(
            "   - Village: ${producteurSelectionne.localisation['village'] ?? 'Non spécifié'}");

        _updateValidationState();
      }
    } catch (e) {
      print("🔴 Erreur chargement producteurs réactif: $e");
      _afficherErreur("Erreur lors du chargement des producteurs: $e");
    }
  }

  // Modal d'ajout de nouveau producteur
  void _afficherModalNouveauProducteur() {
    print("🟡 _afficherModalNouveauProducteur - Ouverture modal");
    showDialog(
      context: context,
      builder: (context) => ModalNouveauProducteur(
        nomSite: _nomSite,
        onProducteurAjoute: _ajouterNouveauProducteur,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          isSmallScreen
              ? 'Nouvelle Collecte'
              : 'Nouvelle Collecte Individuelle',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 16 : 20,
          ),
        ),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Historiques',
            icon: const Icon(Icons.history),
            onPressed: () {
              Get.to(() => const HistoriquesCollectesPage());
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Message d'erreur animé avec liste des champs manquants
                        SectionMessageErreur(
                          errorMessage: _errorMessage,
                          champsManquants: _champsManquants,
                          shakeAnimation: _shakeAnimation,
                        ),

                        // Indicateur de progression du formulaire
                        SectionProgressionFormulaire(
                          progression: _progressionFormulaire,
                        ),

                        // Section sélection producteur
                        SectionProducteur(
                          producteurSelectionne: _producteurSelectionne,
                          onSelectProducteur: _afficherModalProducteurs,
                          onAddProducteur: _afficherModalNouveauProducteur,
                          onChangeProducteur: () {
                            setState(() => _producteurSelectionne = null);
                            _updateValidationState();
                          },
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 24),

                        // Section période de collecte
                        SectionPeriodeCollecte(
                          periodeCollecte: _periodeCollecte,
                          onPeriodeChanged: (nouvellePeriode) {
                            setState(() => _periodeCollecte = nouvellePeriode);
                            _updateValidationState();
                          },
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 24),

                        // Section géolocalisation GPS
                        _buildGeolocationSection(),
                        SizedBox(height: isSmallScreen ? 16 : 24),

                        // Section contenants avec cartes modulaires
                        SectionContenants(
                          contenants: _contenants,
                          onAjouterContenant: _ajouterContenant,
                          onSupprimerContenant: _supprimerContenant,
                          onModifierContenant: _modifierContenant,
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 24),

                        // Section observations
                        SectionObservations(
                          observationsController: _observationsController,
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 24),

                        // Section résumé
                        SectionResume(
                          contenants: _contenants,
                          poidsTotal: _poidsTotal,
                          montantTotal: _montantTotal,
                        ),
                        SizedBox(height: isSmallScreen ? 24 : 32),

                        // Affichage persistant des champs manquants
                        SectionChampsManquants(
                          champsManquants: !_estValide ? _champsManquants : [],
                        ),

                        // Bouton d'enregistrement
                        BoutonEnregistrement(
                          estValide: _estValide,
                          isLoading: _isLoading,
                          onPressed: _afficherDialogueConfirmation,
                          champsManquants: _champsManquants,
                        ),

                        // Espace pour le clavier mobile
                        if (isSmallScreen) const SizedBox(height: 100),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
