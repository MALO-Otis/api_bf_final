/// 🎯 PAGE D'ÉDITION DE CONDITIONNEMENT MODERNE
///
/// Interface simplifiée et fonctionnelle avec calculs en temps réel

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../utils/smart_appbar.dart';
import 'conditionnement_models.dart';
import 'services/conditionnement_db_service.dart';

class ConditionnementEditController extends GetxController {
  // Données du lot filtré
  final dynamic lotFiltrageData;
  late LotFiltre lotFiltrage;

  // Services
  late ConditionnementDbService _service;

  // État réactif
  final Rxn<DateTime> dateConditionnement = Rxn<DateTime>();
  final RxMap<String, int> selectedEmballages = <String, int>{}.obs;
  final RxMap<String, TextEditingController> controllers =
      <String, TextEditingController>{}.obs;
  final RxString observations = ''.obs;

  // Calculs en temps réel
  final RxInt totalUnites = 0.obs;
  final RxDouble totalPoids = 0.0.obs;
  final RxDouble totalPrix = 0.0.obs;
  final RxDouble quantiteRestante = 0.0.obs;
  final RxBool isValid = false.obs;
  final RxString validationMessage = ''.obs;

  // État de l'interface
  final RxBool isLoading = false.obs;

  // Contrôleur pour les observations
  late TextEditingController observationsController;

  ConditionnementEditController(this.lotFiltrageData);

  @override
  void onInit() {
    super.onInit();
    _service = Get.find<ConditionnementDbService>();
    _initializeLot();
    _initializeControllers();
    _setupCalculationListeners();
  }

  @override
  void onClose() {
    observationsController.dispose();

    // Nettoyer les controllers des emballages
    for (final controller in controllers.values) {
      controller.dispose();
    }

    super.onClose();
  }

  /// Initialise le lot filtré
  void _initializeLot() {
    try {
      // Vérifier que les données ne sont pas nulles
      if (lotFiltrageData == null) {
        throw Exception('Données du lot manquantes');
      }

      // Convertir les données en modèle LotFiltre
      final id = lotFiltrageData['id']?.toString() ??
          'LOT_${DateTime.now().millisecondsSinceEpoch}';
      final lotOrigine = lotFiltrageData['lot']?.toString() ?? id;
      final collecteId = lotFiltrageData['collecteId']?.toString() ??
          'COLLECTE_${DateTime.now().millisecondsSinceEpoch}';

      // Gérer les différents noms de champs pour la quantité
      double quantite = 0.0;
      if (lotFiltrageData['quantiteFiltree'] != null) {
        quantite = (lotFiltrageData['quantiteFiltree'] as num).toDouble();
      } else if (lotFiltrageData['quantiteFiltrée'] != null) {
        quantite = (lotFiltrageData['quantiteFiltrée'] as num).toDouble();
      } else if (lotFiltrageData['quantiteRestante'] != null) {
        quantite = (lotFiltrageData['quantiteRestante'] as num).toDouble();
      }

      final predominanceFlorale =
          lotFiltrageData['predominanceFlorale']?.toString() ?? 'Mille fleurs';
      final site = lotFiltrageData['site']?.toString() ?? 'Site inconnu';
      final technicien =
          lotFiltrageData['technicien']?.toString() ?? 'Technicien inconnu';

      // Gérer la date de filtrage
      DateTime dateFiltrage = DateTime.now();
      if (lotFiltrageData['dateFiltrage'] != null) {
        if (lotFiltrageData['dateFiltrage'] is Timestamp) {
          dateFiltrage =
              (lotFiltrageData['dateFiltrage'] as Timestamp).toDate();
        } else if (lotFiltrageData['dateFiltrage'] is DateTime) {
          dateFiltrage = lotFiltrageData['dateFiltrage'] as DateTime;
        }
      }

      lotFiltrage = LotFiltre(
        id: id,
        lotOrigine: lotOrigine,
        collecteId: collecteId,
        quantiteRecue: quantite,
        quantiteRestante: quantite,
        predominanceFlorale: predominanceFlorale,
        dateFiltrage: dateFiltrage,
        site: site,
        technicien: technicien,
      );

      // Initialiser la quantité restante
      quantiteRestante.value = lotFiltrage.quantiteRestante;

      debugPrint(
          '✅ [Conditionnement] Lot initialisé: ${lotFiltrage.id} - ${lotFiltrage.quantiteRecue}kg');
    } catch (e) {
      debugPrint('❌ [Conditionnement] Erreur initialisation lot: $e');

      // Créer un lot par défaut pour éviter le crash
      lotFiltrage = LotFiltre(
        id: 'LOT_DEFAULT_${DateTime.now().millisecondsSinceEpoch}',
        lotOrigine: 'Lot par défaut',
        collecteId: 'COLLECTE_DEFAULT',
        quantiteRecue: 10.0,
        quantiteRestante: 10.0,
        predominanceFlorale: 'Mille fleurs',
        dateFiltrage: DateTime.now(),
        site: 'Site par défaut',
        technicien: 'Technicien par défaut',
      );

      quantiteRestante.value = lotFiltrage.quantiteRestante;

      // Différer l'affichage du snackbar pour éviter l'erreur GetX
      Future.delayed(Duration.zero, () {
        Get.snackbar(
          'Attention',
          'Données du lot incomplètes. Lot par défaut créé.',
          backgroundColor: Colors.orange.shade600,
          colorText: Colors.white,
        );
      });
    }
  }

  /// Initialise les contrôleurs de texte
  void _initializeControllers() {
    observationsController = TextEditingController();
    observationsController.addListener(() {
      observations.value = observationsController.text;
    });

    // Créer les contrôleurs pour chaque type d'emballage
    for (final emballageType in EmballagesConfig.emballagesDisponibles) {
      final controller = TextEditingController();
      controller.addListener(() => _recalculateAll());
      controllers[emballageType.id] = controller;
    }
  }

  /// Configure les listeners pour les calculs en temps réel
  void _setupCalculationListeners() {
    // Écouter les changements de date
    dateConditionnement.listen((_) => _validateForm());
  }

  /// Recalcule tous les totaux
  void _recalculateAll() {
    int newTotalUnites = 0;
    double newTotalPoids = 0.0;
    double newTotalPrix = 0.0;

    for (final emballageType in EmballagesConfig.emballagesDisponibles) {
      final controller = controllers[emballageType.id];
      if (controller != null && controller.text.isNotEmpty) {
        final quantity = int.tryParse(controller.text) ?? 0;
        if (quantity > 0) {
          // Calculer pour cet emballage
          final unites = emballageType.getNombreUnitesReelles(quantity);
          final poids = emballageType.getPoidsTotal(quantity);
          final prix =
              emballageType.getPrixTotal(quantity, lotFiltrage.typeFlorale);

          newTotalUnites += unites;
          newTotalPoids += poids;
          newTotalPrix += prix;
        }
      }
    }

    // Mettre à jour les totaux
    totalUnites.value = newTotalUnites;
    totalPoids.value = newTotalPoids;
    totalPrix.value = newTotalPrix;
    quantiteRestante.value = (lotFiltrage.quantiteRestante - newTotalPoids)
        .clamp(0, double.infinity);

    // Valider le formulaire
    _validateForm();
  }

  /// Valide le formulaire en temps réel
  void _validateForm() {
    List<String> errors = [];

    // Vérifier la date
    if (dateConditionnement.value == null) {
      errors.add('Date de conditionnement requise');
    }

    // Vérifier qu'au moins un emballage est sélectionné
    if (selectedEmballages.isEmpty) {
      errors.add('Au moins un emballage doit être sélectionné');
    }

    // Vérifier la quantité conditionnée
    if (totalPoids.value <= 0) {
      errors.add('La quantité conditionnée doit être positive');
    }

    // Validation stricte : écart de 10kg maximum
    final ecart = lotFiltrage.quantiteRecue - totalPoids.value;
    if (ecart < -10.0) {
      errors.add('Quantité dépasse la quantité reçue de plus de 10kg');
    }

    // Mettre à jour l'état de validation
    isValid.value = errors.isEmpty;
    validationMessage.value =
        errors.isNotEmpty ? errors.first : 'Prêt à sauvegarder';
  }

  /// Sélectionne une date
  Future<void> selectDate() async {
    final date = await Get.dialog<DateTime>(
      DatePickerDialog(
        initialDate: dateConditionnement.value ?? DateTime.now(),
        firstDate: DateTime.now().subtract(const Duration(days: 30)),
        lastDate: DateTime.now().add(const Duration(days: 30)),
      ),
    );

    if (date != null) {
      dateConditionnement.value = date;
    }
  }

  /// Sauvegarde le conditionnement
  Future<void> saveConditionnement() async {
    if (!isValid.value) {
      Get.snackbar(
        'Validation échouée',
        validationMessage.value,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
      return;
    }

    isLoading.value = true;

    try {
      // Créer la liste des emballages sélectionnés
      final emballagesSelectionnes = <EmballageSelectionne>[];

      for (final entry in selectedEmballages.entries) {
        final emballageType = EmballagesConfig.getEmballageById(entry.key);
        if (emballageType != null) {
          emballagesSelectionnes.add(EmballageSelectionne(
            type: emballageType,
            nombreSaisi: entry.value,
            typeFlorale: lotFiltrage.typeFlorale,
          ));
        }
      }

      // Créer l'objet de conditionnement
      final conditionnement = ConditionnementData(
        id: '', // Sera généré par Firestore
        dateConditionnement: dateConditionnement.value!,
        lotOrigine: lotFiltrage,
        emballages: emballagesSelectionnes,
        quantiteConditionnee: totalPoids.value,
        quantiteRestante: quantiteRestante.value,
        prixTotal: totalPrix.value,
        nbTotalPots: totalUnites.value,
        createdAt: DateTime.now(),
        observations: observations.value.isNotEmpty ? observations.value : null,
      );

      // Sauvegarder
      final conditionnementId =
          await _service.enregistrerConditionnement(conditionnement);

      // Feedback de succès
      Get.snackbar(
        'Succès ! 🎉',
        'Conditionnement enregistré avec l\'ID: $conditionnementId',
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        duration: const Duration(seconds: 4),
      );

      // Retourner à la page d'accueil
      Get.back();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'enregistrer le conditionnement: $e',
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Réinitialise le formulaire
  void resetForm() {
    dateConditionnement.value = null;
    selectedEmballages.clear();
    observations.value = '';
    observationsController.clear();

    for (final controller in controllers.values) {
      controller.clear();
    }

    _recalculateAll();
  }

  /// Obtient la couleur du type de florale
  Color getFloralTypeColor() {
    switch (lotFiltrage.typeFlorale) {
      case TypeFlorale.monoFleur:
        return const Color(0xFFFF6B35);
      case TypeFlorale.milleFleurs:
        return const Color(0xFFF7931E);
      case TypeFlorale.mixte:
        return const Color(0xFFFFD23F);
    }
  }

  /// Obtient l'icône du type de florale
  String getFloralTypeIcon() {
    return ConditionnementUtils.iconesByFlorale[lotFiltrage.typeFlorale] ??
        '🍯';
  }

  /// Obtient la quantité saisie pour un emballage
  double getQuantiteEmballage(String emballageId) {
    final text = controllers[emballageId]?.text ?? '';
    return double.tryParse(text) ?? 0.0;
  }

  /// Calcule la quantité maximale prélevable pour un emballage
  double getQuantiteMaxEmballage(String emballageId) {
    final emballage = EmballagesConfig.emballagesDisponibles
        .firstWhere((e) => e.id == emballageId);

    // Calculer la quantité déjà utilisée par TOUS les autres emballages (sauf celui en cours)
    double quantiteUtilisee = 0.0;
    for (final emballageType in EmballagesConfig.emballagesDisponibles) {
      if (emballageType.id != emballageId) {
        final controller = controllers[emballageType.id];
        if (controller != null && controller.text.isNotEmpty) {
          final quantity = int.tryParse(controller.text) ?? 0;
          if (quantity > 0) {
            quantiteUtilisee += quantity * emballageType.contenanceKg;
          }
        }
      }
    }

    // Calculer la quantité disponible restante
    final quantiteDisponible = lotFiltrage.quantiteRestante - quantiteUtilisee;

    // Si la quantité disponible est négative ou nulle, retourner 0
    if (quantiteDisponible <= 0) {
      return 0.0;
    }

    // Calculer le nombre maximum d'unités de cet emballage possible
    final maxUnites =
        (quantiteDisponible / emballage.contenanceKg).floorToDouble();

    return maxUnites;
  }

  /// Met à jour les calculs (appelé lors des changements)
  void updateCalculations() {
    _recalculateAll();
  }

  /// Calcule le reste disponible pour un emballage spécifique
  double _calculateRestantPourEmballage(
      String emballageId, double quantiteSaisie) {
    final emballage = EmballagesConfig.emballagesDisponibles
        .firstWhere((e) => e.id == emballageId);

    // Calculer la quantité déjà utilisée par TOUS les autres emballages
    double quantiteUtilisee = 0.0;
    for (final emballageType in EmballagesConfig.emballagesDisponibles) {
      if (emballageType.id != emballageId) {
        final controller = controllers[emballageType.id];
        if (controller != null && controller.text.isNotEmpty) {
          final quantity = int.tryParse(controller.text) ?? 0;
          if (quantity > 0) {
            quantiteUtilisee += quantity * emballageType.contenanceKg;
          }
        }
      }
    }

    // Ajouter la quantité de l'emballage actuel
    quantiteUtilisee += quantiteSaisie * emballage.contenanceKg;

    // Calculer le reste
    final reste = lotFiltrage.quantiteRestante - quantiteUtilisee;

    return reste >= 0 ? reste : 0.0;
  }
}

class ConditionnementEditPage extends StatelessWidget {
  final dynamic lotFiltrageData;

  const ConditionnementEditPage({super.key, required this.lotFiltrageData});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ConditionnementEditController(lotFiltrageData));
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(controller),
      body: Obx(() => _buildBody(context, controller, theme, isMobile)),
      bottomNavigationBar: Obx(() => _buildBottomBar(controller, isMobile)),
    );
  }

  /// Construit l'AppBar
  PreferredSizeWidget _buildAppBar(ConditionnementEditController controller) {
    return SmartAppBar(
      title: "🧊 Conditionnement - Lot ${controller.lotFiltrage.lotOrigine}",
      backgroundColor: controller.getFloralTypeColor(),
      onBackPressed: () {
        if (controller.selectedEmballages.isNotEmpty) {
          Get.dialog(
            AlertDialog(
              title: const Text('Confirmer la sortie'),
              content:
                  const Text('Vos modifications seront perdues. Continuer ?'),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () {
                    Get.back(); // Fermer le dialog
                    Get.back(); // Retourner à la page précédente
                  },
                  child: const Text('Confirmer'),
                ),
              ],
            ),
          );
        } else {
          Get.back();
        }
      },
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: controller.resetForm,
          tooltip: 'Réinitialiser',
        ),
      ],
    );
  }

  /// Construit le corps principal
  Widget _buildBody(
      BuildContext context,
      ConditionnementEditController controller,
      ThemeData theme,
      bool isMobile) {
    if (controller.isLoading.value) {
      return _buildLoadingView();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec informations du lot
          _buildHeader(controller, isMobile),

          const SizedBox(height: 24),

          // Sélection de date
          _buildDateSection(controller, isMobile),

          const SizedBox(height: 24),

          // Sélection des emballages
          _buildEmballageSection(controller, isMobile),

          const SizedBox(height: 24),

          // Résumé des calculs
          _buildCalculationSummary(controller, isMobile),

          const SizedBox(height: 24),

          // Observations
          _buildObservationsSection(controller, isMobile),

          const SizedBox(height: 80), // Espace pour le bottom bar
        ],
      ),
    );
  }

  /// Construit la vue de chargement
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 6,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 24),
          Text(
            'Enregistrement en cours...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit l'en-tête avec informations du lot
  Widget _buildHeader(ConditionnementEditController controller, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            controller.getFloralTypeColor(),
            controller.getFloralTypeColor().withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: controller.getFloralTypeColor().withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Row(
          children: [
            // Icône du type de florale
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                controller.getFloralTypeIcon(),
                style: const TextStyle(fontSize: 32),
              ),
            ),

            const SizedBox(width: 20),

            // Informations du lot
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lot ${controller.lotFiltrage.lotOrigine}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.lotFiltrage.predominanceFlorale,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: isMobile ? 14 : 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.scale,
                          color: Colors.white.withOpacity(0.9), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${controller.lotFiltrage.quantiteRecue.toStringAsFixed(1)} kg disponibles',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la section de sélection de date
  Widget _buildDateSection(
      ConditionnementEditController controller, bool isMobile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date de conditionnement',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => InkWell(
                  onTap: controller.selectDate,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: controller.dateConditionnement.value != null
                            ? controller.getFloralTypeColor()
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      color: controller.dateConditionnement.value != null
                          ? controller.getFloralTypeColor().withOpacity(0.1)
                          : Colors.grey.shade50,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: controller.dateConditionnement.value != null
                              ? controller.getFloralTypeColor()
                              : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            controller.dateConditionnement.value != null
                                ? DateFormat('EEEE dd MMMM yyyy', 'fr').format(
                                    controller.dateConditionnement.value!)
                                : 'Sélectionner une date',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color:
                                  controller.dateConditionnement.value != null
                                      ? controller.getFloralTypeColor()
                                      : Colors.grey.shade500,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: controller.dateConditionnement.value != null
                              ? controller.getFloralTypeColor()
                              : Colors.grey.shade500,
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// Construit la section des emballages
  Widget _buildEmballageSection(
      ConditionnementEditController controller, bool isMobile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sélection des emballages',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),

            // Liste des emballages
            ...EmballagesConfig.emballagesDisponibles
                .map((emballage) =>
                    _buildEmballageRow(controller, emballage, isMobile))
                .toList(),
          ],
        ),
      ),
    );
  }

  /// Construit une ligne d'emballage
  Widget _buildEmballageRow(ConditionnementEditController controller,
      EmballageType emballage, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Icône et info
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Color(int.parse('0xFF${emballage.couleur.substring(1)}'))
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                emballage.icone,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Nom et détails
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emballage.nom,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${emballage.contenanceKg} kg • ${ConditionnementUtils.formatPrix(emballage.getPrix(controller.lotFiltrage.typeFlorale))}',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (emballage.multiplicateur > 1)
                  Text(
                    emballage.modeVenteObligatoire.description,
                    style: TextStyle(
                      fontSize: 10,
                      color: controller.getFloralTypeColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

          // Champ de quantité amélioré
          SizedBox(
            width: isMobile ? 120 : 140,
            child: Obx(() {
              final quantite = controller.getQuantiteEmballage(emballage.id);
              final quantiteMax =
                  controller.getQuantiteMaxEmballage(emballage.id);
              final isValid = quantite <= quantiteMax && quantite >= 0;

              return Column(
                children: [
                  TextFormField(
                    controller: controller.controllers[emballage.id],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      final quantite = double.tryParse(value) ?? 0.0;
                      if (quantite > 0) {
                        controller.selectedEmballages[emballage.id] =
                            quantite.toInt();
                      } else {
                        controller.selectedEmballages.remove(emballage.id);
                      }
                      controller.updateCalculations();
                    },
                    decoration: InputDecoration(
                      labelText: 'Quantité',
                      hintText: 'Max: $quantiteMax',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isValid
                              ? controller.getFloralTypeColor()
                              : Colors.red,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.red, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: quantite > 0
                          ? Icon(
                              isValid ? Icons.check_circle : Icons.error,
                              color: isValid ? Colors.green : Colors.red,
                              size: 20,
                            )
                          : null,
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 14 : 16,
                    ),
                  ),
                  if (quantite > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Restant: ${controller._calculateRestantPourEmballage(emballage.id, quantite).toStringAsFixed(1)} kg',
                      style: TextStyle(
                        fontSize: 10,
                        color: isValid
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Construit le résumé des calculs
  Widget _buildCalculationSummary(
      ConditionnementEditController controller, bool isMobile) {
    return Obx(() => Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: controller.isValid.value
                  ? Colors.green.shade300
                  : Colors.orange.shade300,
              width: 2,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: controller.isValid.value
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(15),
            ),
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      controller.isValid.value
                          ? Icons.check_circle
                          : Icons.warning,
                      color: controller.isValid.value
                          ? Colors.green.shade600
                          : Colors.orange.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Résumé du conditionnement',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Grille des totaux compacte
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactSummaryCard(
                        'Unités',
                        controller.totalUnites.value.toString(),
                        Icons.inventory_2,
                        Colors.blue.shade600,
                        isMobile,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactSummaryCard(
                        'Poids',
                        '${controller.totalPoids.value.toStringAsFixed(1)} kg',
                        Icons.scale,
                        Colors.purple.shade600,
                        isMobile,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactSummaryCard(
                        'Prix',
                        ConditionnementUtils.formatPrix(
                            controller.totalPrix.value),
                        Icons.attach_money,
                        Colors.green.shade600,
                        isMobile,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactSummaryCard(
                        'Reste',
                        '${controller.quantiteRestante.value.toStringAsFixed(1)} kg',
                        Icons.inventory,
                        controller.quantiteRestante.value > 0
                            ? Colors.orange.shade600
                            : Colors.green.shade600,
                        isMobile,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Message de validation
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: controller.isValid.value
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: controller.isValid.value
                          ? Colors.green.shade300
                          : Colors.orange.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        controller.isValid.value
                            ? Icons.check_circle
                            : Icons.info,
                        color: controller.isValid.value
                            ? Colors.green.shade600
                            : Colors.orange.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.validationMessage.value,
                          style: TextStyle(
                            color: controller.isValid.value
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  /// Construit une carte de résumé
  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: isMobile ? 16 : 20),
          SizedBox(height: isMobile ? 4 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 8 : 10,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Construit une carte de résumé compacte
  Widget _buildCompactSummaryCard(
      String title, String value, IconData icon, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 6 : 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: isMobile ? 14 : 16),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 7 : 8,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Construit la section d'observations
  Widget _buildObservationsSection(
      ConditionnementEditController controller, bool isMobile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Observations (optionnel)',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.observationsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ajoutez des notes ou commentaires...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: controller.getFloralTypeColor(),
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la barre de navigation inférieure
  Widget _buildBottomBar(
      ConditionnementEditController controller, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton réinitialiser
          Expanded(
            child: OutlinedButton.icon(
              onPressed: controller.resetForm,
              icon: const Icon(Icons.refresh),
              label: const Text('Réinitialiser'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Bouton enregistrer
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: controller.isValid.value && !controller.isLoading.value
                  ? controller.saveConditionnement
                  : null,
              icon: controller.isLoading.value
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(
                controller.isLoading.value
                    ? 'Enregistrement...'
                    : 'Enregistrer',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: controller.getFloralTypeColor(),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
                padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
                elevation: controller.isValid.value ? 4 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
