import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'conditionnement_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/smart_appbar.dart';
import 'package:flutter/foundation.dart';
import 'services/conditionnement_db_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
/// 🎯 PAGE D'ÉDITION DE CONDITIONNEMENT MODERNE
///
/// Interface simplifiée et fonctionnelle avec calculs en temps réel



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

    // 🔥 DEBUG: Confirmer que nous sommes dans la bonne page
    if (kDebugMode) {
      print('\n🎯🎯🎯 CONDITIONNEMENT EDIT PAGE ULTRA-RÉACTIF CHARGÉ ! 🎯🎯🎯');
      print(
          '📱 Page ConditionnementEditPage avec améliorations ultra-réactives');
      print('✅ Les calculs en temps réel sont actifs !');
      print('✅ Les statistiques par emballage sont activées !');
      print('✅ Interface entièrement opérationnelle dès le départ !');
      print('🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯\n');
    }

    _service = Get.find<ConditionnementDbService>();
    _initializeLot();
    _initializeControllers();
    _setupCalculationListeners();

    // 🚀 NOUVEAU : Initialiser immédiatement les stats pour tous les emballages
    _initializeInitialStats();

    // 👁️‍🗨️ AUTO-CLOSE LISTENER : si un enregistrement est détecté (sécurité supplémentaire)
    bool _autoClosed = false; // variable locale capturée
    ever<String?>(_service.lastSaveId, (id) {
      if (id != null && !_autoClosed && Get.isOverlaysOpen == false) {
        // Si pour une raison quelconque la navigation dans saveConditionnement n'a pas fermé la page
        _autoClosed = true;
        Future.microtask(() {
          if (Get.isOverlaysOpen == false) {
            // Retour latence sécurité si pas déjà effectué
            if (Get.isDialogOpen == true) {
              Get.back();
            }
            if (Get.key.currentContext != null) {
              Get.back(result: {
                'action': 'refresh',
                'type': quantiteRestante.value <= 0.1 ? 'complet' : 'partiel',
                'source': 'listener'
              });
            }
          }
        });
      }
    });
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

  /// 🚀 NOUVELLE MÉTHODE : Initialise les stats dès l'ouverture
  /// Garantit que l'interface est entièrement opérationnelle dès le départ
  void _initializeInitialStats() {
    if (kDebugMode) {
      print('\n🎯 INITIALISATION DES STATS AU DÉMARRAGE 🎯');
      print('💡 Préparation de l\'interface ultra-réactive...');
    }

    // 🔄 Déclencher un premier calcul pour initialiser tous les maximums
    Future.delayed(Duration.zero, () {
      _recalculateAll();

      if (kDebugMode) {
        print('✅ Stats initiales calculées pour tous les emballages !');
        print('📊 Quantité lot: ${lotFiltrage.quantiteRestante} kg');

        // Afficher les maximums initiaux pour chaque emballage
        for (final emballage in EmballagesConfig.emballagesDisponibles) {
          final max = getQuantiteMaxEmballage(emballage.id);
          print(
              '   📦 [${emballage.nom}] Max initial: ${max.toStringAsFixed(0)} unités (${(max * emballage.contenanceKg).toStringAsFixed(1)} kg)');
        }
        print('🎯 INTERFACE 100% OPÉRATIONNELLE ! 🎯\n');
      }
    });
  }

  /// Recalcule tous les totaux
  void _recalculateAll() {
    if (kDebugMode) {
      print('\n🚀 === DÉBUT RECALCUL ULTRA-RÉACTIF ===');
      print('📊 Quantité lot disponible: ${lotFiltrage.quantiteRestante} kg');
    }

    int newTotalUnites = 0;
    double newTotalPoids = 0.0;
    double newTotalPrix = 0.0;

    if (kDebugMode) print('🔍 ÉTAPE 1: Scan de tous les emballages...');

    for (final emballageType in EmballagesConfig.emballagesDisponibles) {
      final controller = controllers[emballageType.id];
      final textValue = controller?.text ?? '';
      final quantity = int.tryParse(textValue) ?? 0;

      if (kDebugMode) {
        print(
            '   📦 [${emballageType.nom}] Texte: "$textValue" → Quantité: $quantity');
      }

      if (controller != null && textValue.isNotEmpty && quantity > 0) {
        // Calculer pour cet emballage
        final unites = emballageType.getNombreUnitesReelles(quantity);
        final poids = emballageType.getPoidsTotal(quantity);
        final prix =
            emballageType.getPrixTotal(quantity, lotFiltrage.typeFlorale);

        newTotalUnites += unites;
        newTotalPoids += poids;
        newTotalPrix += prix;

        if (kDebugMode) {
          print(
              '   ✅ [${emballageType.nom}] COMPTÉ: $quantity unités × ${emballageType.contenanceKg}kg = ${poids.toStringAsFixed(2)}kg');
        }
      } else if (kDebugMode) {
        print('   ⚪ [${emballageType.nom}] IGNORÉ (valeur <= 0)');
      }
    }

    if (kDebugMode) {
      print('🔍 ÉTAPE 2: Mise à jour des totaux globaux...');
      print('   📊 Poids total utilisé: ${newTotalPoids.toStringAsFixed(2)}kg');
      print(
          '   📊 Quantité restante: ${(lotFiltrage.quantiteRestante - newTotalPoids).toStringAsFixed(2)}kg');
    }

    // Mettre à jour les totaux
    totalUnites.value = newTotalUnites;
    totalPoids.value = newTotalPoids;
    totalPrix.value = newTotalPrix;
    quantiteRestante.value = (lotFiltrage.quantiteRestante - newTotalPoids)
        .clamp(0, double.infinity);

    if (kDebugMode) {
      print('🔍 ÉTAPE 3: Recalcul des maximums (automatique via Obx)...');
      print('🎯 === FIN RECALCUL ===\n');
    }

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

  /// 🔍 VÉRIFICATION SI LE LOT EST DÉJÀ CONDITIONNÉ
  Future<bool> _verifierSiLotEstDejaConditionne() async {
    try {
      final existant = await _service.getConditionnementByLotId(lotFiltrage.id);
      return existant != null;
    } catch (e) {
      debugPrint('❌ Erreur vérification lot existant: $e');
      return false;
    }
  }

  /// 🎯 RÉCAPITULATIF COMPLET AVANT ENREGISTREMENT FINAL
  Future<bool> _showRecapitulatifAvantEnregistrement(
      bool dejaCanditionne) async {
    // Préparer les données du récapitulatif
    final emballagesDetails = <Map<String, dynamic>>[];

    for (final entry in selectedEmballages.entries) {
      final emballageType = EmballagesConfig.getEmballageById(entry.key);
      if (emballageType != null && entry.value > 0) {
        final quantite = entry.value;
        final unites = emballageType.getNombreUnitesReelles(quantite);
        final poids = emballageType.getPoidsTotal(quantite);
        final prix =
            emballageType.getPrixTotal(quantite, lotFiltrage.typeFlorale);

        emballagesDetails.add({
          'type': emballageType.nom,
          'icone': emballageType.icone,
          'quantiteSaisie': quantite,
          'unitesReelles': unites,
          'poids': poids,
          'prix': prix,
          'prixUnitaire': emballageType.getPrix(lotFiltrage.typeFlorale),
        });
      }
    }

    final result = await Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🎯 Header du récapitulatif
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        dejaCanditionne
                            ? Colors.orange.shade600
                            : (lotFiltrage.typeFlorale == TypeFlorale.monoFleur
                                ? Colors.orange.shade600
                                : Colors.amber.shade600),
                        dejaCanditionne
                            ? Colors.orange.shade800
                            : (lotFiltrage.typeFlorale == TypeFlorale.monoFleur
                                ? Colors.orange.shade800
                                : Colors.amber.shade800),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        dejaCanditionne
                            ? Icons.update
                            : Icons.fact_check_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dejaCanditionne ? 'Mise à Jour' : 'Récapitulatif Final',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        dejaCanditionne
                            ? 'Ce lot est déjà conditionné - Les nouvelles données remplaceront l\'ancien conditionnement'
                            : 'Vérifiez les informations avant enregistrement',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // 🚨 ALERTE SI LOT DÉJÀ CONDITIONNÉ
                if (dejaCanditionne)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.orange.shade300, width: 2),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange.shade700, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '⚠️ ATTENTION : Lot déjà conditionné',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ce lot a déjà été conditionné. En confirmant, vous remplacerez l\'ancien conditionnement par les nouvelles données ci-dessous.',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 📊 Informations du lot
                      _buildRecapSection(
                        '📦 Informations du Lot',
                        [
                          _buildRecapItem(
                              'Lot d\'origine', lotFiltrage.lotOrigine),
                          _buildRecapItem('Site', lotFiltrage.site),
                          _buildRecapItem('Quantité disponible',
                              '${lotFiltrage.quantiteRestante.toStringAsFixed(2)} kg'),
                          _buildRecapItem('Prédominance florale',
                              lotFiltrage.predominanceFlorale),
                          _buildRecapItem(
                              'Type de miel', lotFiltrage.typeFlorale.label),
                          _buildRecapItem(
                              'Date de conditionnement',
                              DateFormat('dd/MM/yyyy')
                                  .format(dateConditionnement.value!)),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // 🎯 Détails des emballages
                      _buildRecapSection(
                        '🛍️ Emballages sélectionnés',
                        emballagesDetails
                            .map((detail) => Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        detail['icone'],
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              detail['type'],
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              '${detail['quantiteSaisie']} × ${detail['prixUnitaire'].toStringAsFixed(0)} FCFA = ${detail['prix'].toStringAsFixed(0)} FCFA',
                                              style: TextStyle(
                                                  color: Colors.green.shade700,
                                                  fontSize: 12),
                                            ),
                                            Text(
                                              'Poids: ${detail['poids'].toStringAsFixed(2)} kg',
                                              style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),

                      const SizedBox(height: 20),

                      // 📈 Totaux finaux
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.green.shade50,
                              Colors.green.shade100,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '📊 TOTAUX FINAUX',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildTotalRow(
                                'Poids conditionné',
                                '${totalPoids.value.toStringAsFixed(2)} kg',
                                Icons.scale),
                            _buildTotalRow(
                                'Quantité restante',
                                '${quantiteRestante.value.toStringAsFixed(2)} kg',
                                Icons.inventory),
                            _buildTotalRow(
                                'Nombre d\'unités',
                                '${totalUnites.value}',
                                Icons.format_list_numbered),
                            _buildTotalRow(
                                'Prix total',
                                '${totalPrix.value.toStringAsFixed(0)} FCFA',
                                Icons.payments),
                          ],
                        ),
                      ),

                      if (observations.value.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildRecapSection(
                          '📝 Observations',
                          [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Text(
                                observations.value,
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // 🔥 Boutons d'action
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Get.back(result: false),
                          icon: const Icon(Icons.edit),
                          label: const Text('Modifier'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () => Get.back(result: true),
                          icon: Icon(dejaCanditionne
                              ? Icons.update
                              : Icons.check_circle),
                          label: Text(dejaCanditionne
                              ? 'Confirmer & Mettre à Jour'
                              : 'Confirmer & Enregistrer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: dejaCanditionne
                                ? Colors.orange.shade600
                                : Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return result ?? false;
  }

  // 🔧 Helper widgets pour le récapitulatif
  Widget _buildRecapSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildRecapItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
          const Text(' : '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.green.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 ÉTAPE DE VALIDATION FINALE AVANT ENREGISTREMENT
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

    // 🔥 VÉRIFICATION SI LE LOT EST DÉJÀ CONDITIONNÉ
    final dejaCanditionne = await _verifierSiLotEstDejaConditionne();

    // 🔥 NOUVEAU: Afficher le dialogue de récapitulatif avant validation finale
    final confirmation =
        await _showRecapitulatifAvantEnregistrement(dejaCanditionne);
    if (!confirmation) {
      return; // L'utilisateur a annulé
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
      await _service.enregistrerConditionnement(conditionnement);

      // 🚀 NOUVEAU : Déterminer le type de conditionnement pour le feedback
      final estConditionnementComplet =
          quantiteRestante.value <= 0.1; // Tolérance de 100g

      // Feedback de succès adapté selon le type de conditionnement
      if (estConditionnementComplet) {
        // ✅ CONDITIONNEMENT COMPLET
        Get.snackbar(
          dejaCanditionne
              ? 'Mise à jour réussie ! 🔄'
              : 'Conditionnement complet ! 🎉',
          dejaCanditionne
              ? 'Lot ${lotFiltrage.lotOrigine} entièrement mis à jour'
              : 'Lot ${lotFiltrage.lotOrigine} entièrement conditionné et déplacé vers les stocks',
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
          icon: Icon(Icons.check_circle_outline, color: Colors.white),
          duration: const Duration(seconds: 5),
        );
      } else {
        // 🔄 CONDITIONNEMENT PARTIEL
        Get.snackbar(
          'Conditionnement partiel ! 🔄',
          'Lot ${lotFiltrage.lotOrigine} partiellement conditionné\n${quantiteRestante.value.toStringAsFixed(1)} kg restants disponibles',
          backgroundColor: Colors.orange.shade600,
          colorText: Colors.white,
          icon: Icon(Icons.schedule, color: Colors.white),
          duration: const Duration(seconds: 6),
        );
      }

      // 🚀 NAVIGATION CORRIGÉE : Retourner directement à la liste des lots à conditionner
      if (estConditionnementComplet) {
        // Conditionnement complet : retourner et rafraîchir la liste
        Get.back(result: {'action': 'refresh', 'type': 'complet'});
      } else {
        // Conditionnement partiel : retourner et rafraîchir pour voir la quantité mise à jour
        Get.back(result: {'action': 'refresh', 'type': 'partiel'});
      }
    } catch (e) {
      // Message d'erreur amélioré
      Get.snackbar(
        'Erreur d\'enregistrement ❌',
        'Impossible d\'enregistrer le conditionnement: ${e.toString().replaceAll('Exception: ', '')}',
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
        duration: const Duration(seconds: 6),
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

  /// 🚀 CALCUL ULTRA-RÉACTIF du maximum possible pour chaque emballage
  /// Cette méthode implémente exactement la logique demandée par l'utilisateur
  double getQuantiteMaxEmballage(String emballageId) {
    final emballage = EmballagesConfig.emballagesDisponibles
        .firstWhere((e) => e.id == emballageId);

    // 🎯 ÉTAPE 1 : Calculer ce qui est utilisé par TOUS les AUTRES emballages
    double poidsUtiliseParAutres = 0.0;

    if (kDebugMode) {
      print('\n🔥 CALCUL MAX POUR [${emballage.nom}] 🔥');
      print('📦 Quantité totale du lot: ${lotFiltrage.quantiteRestante} kg');
    }

    for (final emballageType in EmballagesConfig.emballagesDisponibles) {
      // ⚠️ IMPORTANT : On exclut l'emballage en cours pour calculer ce qui reste
      if (emballageType.id != emballageId) {
        final controller = controllers[emballageType.id];
        if (controller != null && controller.text.isNotEmpty) {
          final quantity = int.tryParse(controller.text) ?? 0;
          if (quantity > 0) {
            final poidsEmballage = quantity * emballageType.contenanceKg;
            poidsUtiliseParAutres += poidsEmballage;

            if (kDebugMode) {
              print(
                  '   🔍 [${emballageType.nom}] utilise: $quantity × ${emballageType.contenanceKg}kg = ${poidsEmballage.toStringAsFixed(2)} kg');
            }
          }
        }
      }
    }

    // 🎯 ÉTAPE 2 : Calculer le miel restant APRÈS les autres saisies
    final mielRestantPourCetEmballage =
        lotFiltrage.quantiteRestante - poidsUtiliseParAutres;

    if (kDebugMode) {
      print(
          '📊 Total utilisé par autres: ${poidsUtiliseParAutres.toStringAsFixed(2)} kg');
      print(
          '🎯 Miel restant pour [${emballage.nom}]: ${mielRestantPourCetEmballage.toStringAsFixed(2)} kg');
    }

    // 🎯 ÉTAPE 3 : Si plus rien de disponible, retourner 0
    if (mielRestantPourCetEmballage <= 0) {
      if (kDebugMode) {
        print('❌ Plus de miel disponible pour [${emballage.nom}]');
      }
      return 0.0;
    }

    // 🎯 ÉTAPE 4 : Calculer le nombre MAX d'unités possible avec le reste
    final maxUnitesPossibles =
        (mielRestantPourCetEmballage / emballage.contenanceKg).floorToDouble();

    if (kDebugMode) {
      print(
          '✅ MAX POSSIBLE pour [${emballage.nom}]: ${maxUnitesPossibles.toStringAsFixed(0)} unités');
      print(
          '   (${mielRestantPourCetEmballage.toStringAsFixed(2)} kg ÷ ${emballage.contenanceKg}kg = ${maxUnitesPossibles.toStringAsFixed(1)})');
      print('🔥 FIN CALCUL [${emballage.nom}] 🔥\n');
    }

    return maxUnitesPossibles;
  }

  /// Met à jour les calculs (appelé lors des changements)
  void updateCalculations() {
    _recalculateAll();
  }

  /// Obtient un feedback instantané pour un emballage donné
  String getInstantFeedback(String emballageId) {
    final quantiteSaisie = getQuantiteEmballage(emballageId);
    final quantiteMax = getQuantiteMaxEmballage(emballageId);
    final emballage = EmballagesConfig.emballagesDisponibles
        .firstWhere((e) => e.id == emballageId);

    if (quantiteSaisie == 0) {
      return 'Max possible: ${quantiteMax.toInt()} unités (${(quantiteMax * emballage.contenanceKg).toStringAsFixed(1)} kg)';
    } else if (quantiteSaisie <= quantiteMax) {
      final poidsUtilise = quantiteSaisie * emballage.contenanceKg;
      final resteApres = quantiteMax - quantiteSaisie;
      return 'Utilisé: ${poidsUtilise.toStringAsFixed(2)} kg • Reste: ${resteApres.toInt()} unités';
    } else {
      final depassement = quantiteSaisie - quantiteMax;
      return 'DÉPASSEMENT de ${depassement.toInt()} unités (${(depassement * emballage.contenanceKg).toStringAsFixed(2)} kg)';
    }
  }

  /// Obtient la couleur d'état pour un emballage
  Color getStatusColor(String emballageId) {
    final quantiteSaisie = getQuantiteEmballage(emballageId);
    final quantiteMax = getQuantiteMaxEmballage(emballageId);

    if (quantiteSaisie == 0) {
      return Colors.grey.shade400;
    } else if (quantiteSaisie <= quantiteMax) {
      return Colors.green.shade600;
    } else {
      return Colors.red.shade600;
    }
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

    // 🔥 DEBUG UI: Confirmer que nous affichons la bonne page
    if (kDebugMode) {
      print(
          '\n🖥️🖥️🖥️ AFFICHAGE PAGE CONDITIONNEMENT ULTRA-RÉACTIVE ! 🖥️🖥️🖥️');
      print('📱 UI ConditionnementEditPage en cours de rendu');
      print('✅ Interface avec calculs temps réel et statistiques actives !');
    }

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

  /// Construit une ligne d'emballage ultra-réactive avec stats permanentes
  Widget _buildEmballageRow(ConditionnementEditController controller,
      EmballageType emballage, bool isMobile) {
    return Obx(() {
      final quantiteSaisie = controller.getQuantiteEmballage(emballage.id);
      final quantiteMaxDisponible =
          controller.getQuantiteMaxEmballage(emballage.id);
      final isActive = quantiteSaisie > 0;
      final isValid =
          quantiteSaisie <= quantiteMaxDisponible && quantiteSaisie >= 0;

      // 🚀 CALCUL DÉTAILLÉ DU MAXIMUM POSSIBLE (en temps réel)
      final poidsTotalLot = controller.lotFiltrage.quantiteRestante;
      final maxTheorique = poidsTotalLot / emballage.contenanceKg;

      // 🔄 CALCUL DES STATS EN TEMPS RÉEL
      final poidsUtilise = quantiteSaisie * emballage.contenanceKg;
      final prixTotal = emballage.getPrixTotal(
          quantiteSaisie.toInt(), controller.lotFiltrage.typeFlorale);
      final poidsTotalUtiliseParTous = controller.totalPoids.value;
      final restantApresUtilisation = poidsTotalLot - poidsTotalUtiliseParTous;

      // 🎯 INDICATEURS VISUELS ULTRA-CLAIRS
      final hasInput = quantiteSaisie > 0;
      final showWarning = quantiteSaisie > quantiteMaxDisponible;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? (isValid ? Colors.green.shade300 : Colors.red.shade300)
                : Colors.grey.shade200,
            width: isActive ? 2 : 1,
          ),
          color: isActive
              ? (isValid ? Colors.green.shade50 : Colors.red.shade50)
              : Colors.grey.shade50,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color:
                        (isValid ? Colors.green : Colors.red).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Icône avec animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isActive
                        ? (isValid
                            ? Colors.green.shade100
                            : Colors.red.shade100)
                        : Color(int.parse(
                                '0xFF${emballage.couleur.substring(1)}'))
                            .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: isActive
                        ? Border.all(
                            color: isValid
                                ? Colors.green.shade300
                                : Colors.red.shade300,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      emballage.icone,
                      style: TextStyle(
                        fontSize: isActive ? 28 : 24,
                        shadows: isActive
                            ? [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Informations détaillées
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              emballage.nom,
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isValid
                                    ? Colors.green.shade600
                                    : Colors.red.shade600,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isValid ? 'OK' : 'LIMITE!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${emballage.contenanceKg} kg par unité • ${ConditionnementUtils.formatPrix(emballage.getPrix(controller.lotFiltrage.typeFlorale))}',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (emballage.multiplicateur > 1)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: controller
                                .getFloralTypeColor()
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            emballage.modeVenteObligatoire.description,
                            style: TextStyle(
                              fontSize: 10,
                              color: controller.getFloralTypeColor(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Zone de saisie ultra-réactive
                SizedBox(
                  width: isMobile ? 140 : 160,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: controller.controllers[emballage.id],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (value) {
                          if (kDebugMode) {
                            print(
                                '\n🔥🔥🔥 SAISIE ULTRA-RÉACTIVE DÉTECTÉE ! 🔥🔥🔥');
                            print(
                                '🎯 CHAMP MODIFIÉ [${emballage.nom}]: "$value"');
                            print(
                                '📊 AVANT - Emballages sélectionnés: ${controller.selectedEmballages}');
                            print(
                                '✅ Les améliorations ultra-réactives sont ACTIVES !');
                          }

                          final quantite = int.tryParse(value) ?? 0;
                          final quantiteMax =
                              controller.getQuantiteMaxEmballage(emballage.id);

                          // 🔒 BLOCAGE AUTOMATIQUE : Limiter à la quantité maximale
                          final quantiteLimitee = quantite > quantiteMax
                              ? quantiteMax.toInt()
                              : quantite;

                          if (quantiteLimitee != quantite) {
                            // Mettre à jour le champ avec la valeur limitée
                            controller.controllers[emballage.id]?.text =
                                quantiteLimitee.toString();
                            controller.controllers[emballage.id]?.selection =
                                TextSelection.fromPosition(
                              TextPosition(
                                  offset: quantiteLimitee.toString().length),
                            );
                          }

                          if (quantiteLimitee > 0) {
                            controller.selectedEmballages[emballage.id] =
                                quantiteLimitee;
                          } else {
                            controller.selectedEmballages.remove(emballage.id);
                          }

                          if (kDebugMode) {
                            if (quantiteLimitee != quantite) {
                              print(
                                  '🔒 BLOQUÉ: $quantite → $quantiteLimitee (max: ${quantiteMax.toStringAsFixed(1)})');
                            }
                            print(
                                '📊 APRÈS - Emballages sélectionnés: ${controller.selectedEmballages}');
                            print('🔄 Déclenchement updateCalculations()...');
                          }

                          controller.updateCalculations();
                        },
                        decoration: InputDecoration(
                          labelText: hasInput ? 'Quantité saisie' : 'Quantité',
                          // 🆕 HINT DYNAMIQUE : Disparaît quand on saisit, apparaît dans les stats
                          hintText: hasInput
                              ? null
                              : quantiteMaxDisponible > 0
                                  ? 'Max: ${quantiteMaxDisponible.toStringAsFixed(0)} unités'
                                  : 'Non disponible',
                          // 🚫 SUPPRIMÉ : Info maintenant dans les stats permanentes
                          helperText: null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: showWarning
                                  ? Colors.red
                                  : (hasInput
                                      ? Colors.green
                                      : controller.getFloralTypeColor()),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: showWarning
                                  ? Colors.red
                                  : (hasInput
                                      ? Colors.green.shade300
                                      : Colors.grey.shade300),
                              width: hasInput ? 2 : 1,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          suffixIcon: hasInput
                              ? Icon(
                                  showWarning
                                      ? Icons.warning
                                      : Icons.check_circle,
                                  color:
                                      showWarning ? Colors.red : Colors.green,
                                  size: 20,
                                )
                              : Icon(
                                  Icons.edit_outlined,
                                  color: Colors.grey.shade400,
                                  size: 18,
                                ),
                          filled: true,
                          fillColor: showWarning
                              ? Colors.red.shade50
                              : (hasInput
                                  ? Colors.green.shade50
                                  : Colors.grey.shade50),
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 16 : 18,
                          color: isActive
                              ? (isValid
                                  ? Colors.green.shade700
                                  : Colors.red.shade700)
                              : Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Indicateur visuel de disponibilité
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.grey.shade200,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxQuantite =
                                controller.lotFiltrage.quantiteRestante /
                                    emballage.contenanceKg;
                            final pourcentageUtilise = quantiteMaxDisponible > 0
                                ? (maxQuantite - quantiteMaxDisponible) /
                                    maxQuantite
                                : 0.0;
                            final pourcentageSaisi = quantiteMaxDisponible > 0
                                ? quantiteSaisie / maxQuantite
                                : 0.0;

                            return Stack(
                              children: [
                                // Barre utilisée par d'autres emballages
                                if (pourcentageUtilise > 0)
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    bottom: 0,
                                    width: constraints.maxWidth *
                                        pourcentageUtilise.clamp(0.0, 1.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(3),
                                        color: Colors.orange.shade300,
                                      ),
                                    ),
                                  ),
                                // Barre saisie actuelle
                                if (pourcentageSaisi > 0)
                                  Positioned(
                                    left: constraints.maxWidth *
                                        pourcentageUtilise.clamp(0.0, 1.0),
                                    top: 0,
                                    bottom: 0,
                                    width: constraints.maxWidth *
                                        pourcentageSaisi.clamp(
                                            0.0, 1.0 - pourcentageUtilise),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(3),
                                        color: isValid
                                            ? Colors.green.shade400
                                            : Colors.red.shade400,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 🚀 STATISTIQUES PERMANENTES ULTRA-DÉTAILLÉES (toujours visibles)
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasInput
                    ? (showWarning
                        ? Colors.red.shade100
                        : Colors.green.shade100)
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasInput
                      ? (showWarning
                          ? Colors.red.shade300
                          : Colors.green.shade300)
                      : Colors.blue.shade300,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📊 EN-TÊTE DES STATS
                  Row(
                    children: [
                      Icon(
                        hasInput
                            ? (showWarning ? Icons.warning : Icons.analytics)
                            : Icons.info_outline,
                        size: 16,
                        color: hasInput
                            ? (showWarning
                                ? Colors.red.shade600
                                : Colors.green.shade600)
                            : Colors.blue.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          hasInput
                              ? '📊 Impact de votre saisie'
                              : '🎯 Statistiques disponibles',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: hasInput
                                ? (showWarning
                                    ? Colors.red.shade700
                                    : Colors.green.shade700)
                                : Colors.blue.shade700,
                          ),
                        ),
                      ),
                      if (hasInput)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: showWarning ? Colors.red : Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            showWarning ? 'LIMITE!' : 'OK',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 🔥 GRILLE DES STATISTIQUES DÉTAILLÉES
                  Row(
                    children: [
                      // Colonne gauche : Stats principales
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatRow(
                              Icons.scale_outlined,
                              'Max théorique',
                              '${maxTheorique.toStringAsFixed(0)} unités',
                              '(${poidsTotalLot.toStringAsFixed(1)} kg ÷ ${emballage.contenanceKg}kg)',
                              Colors.grey.shade600,
                              9,
                            ),
                            const SizedBox(height: 6),
                            _buildStatRow(
                              Icons.inventory_outlined,
                              'Max actuellement',
                              '${quantiteMaxDisponible.toStringAsFixed(0)} unités',
                              hasInput && poidsUtilise > 0
                                  ? '(après autres saisies)'
                                  : '(avant toute saisie)',
                              hasInput
                                  ? (showWarning
                                      ? Colors.red.shade700
                                      : Colors.green.shade700)
                                  : Colors.blue.shade700,
                              10,
                            ),
                            if (hasInput) ...[
                              const SizedBox(height: 6),
                              _buildStatRow(
                                Icons.edit,
                                'Vous saisissez',
                                '${quantiteSaisie.toStringAsFixed(0)} unités',
                                '= ${poidsUtilise.toStringAsFixed(2)} kg',
                                showWarning
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
                                11,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Séparateur vertical
                      Container(
                        width: 1,
                        height: 80,
                        color: Colors.grey.shade300,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),

                      // Colonne droite : Impact financier et restants
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatRow(
                              Icons.euro_outlined,
                              'Prix unitaire',
                              ConditionnementUtils.formatPrix(emballage
                                  .getPrix(controller.lotFiltrage.typeFlorale)),
                              '${emballage.contenanceKg}kg/unité',
                              Colors.grey.shade600,
                              9,
                            ),
                            if (hasInput) ...[
                              const SizedBox(height: 6),
                              _buildStatRow(
                                Icons.calculate_outlined,
                                'Total prix',
                                ConditionnementUtils.formatPrix(prixTotal),
                                '${quantiteSaisie.toStringAsFixed(0)} × ${ConditionnementUtils.formatPrix(emballage.getPrix(controller.lotFiltrage.typeFlorale))}',
                                showWarning
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
                                10,
                              ),
                              const SizedBox(height: 6),
                              _buildStatRow(
                                Icons.inventory_2_outlined,
                                'Miel restant',
                                '${restantApresUtilisation.toStringAsFixed(1)} kg',
                                'Pour autres emballages',
                                restantApresUtilisation > 0
                                    ? Colors.orange.shade700
                                    : Colors.green.shade700,
                                11,
                              ),
                            ] else ...[
                              const SizedBox(height: 6),
                              _buildStatRow(
                                Icons.help_outline,
                                'Simulez!',
                                'Saisissez une quantité',
                                'pour voir l\'impact',
                                Colors.blue.shade600,
                                10,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Construit le résumé des calculs ultra-réactif
  Widget _buildCalculationSummary(
      ConditionnementEditController controller, bool isMobile) {
    return Obx(() {
      final pourcentageUtilise = controller.lotFiltrage.quantiteRestante > 0
          ? (controller.totalPoids.value /
                  controller.lotFiltrage.quantiteRestante)
              .clamp(0.0, 1.0)
          : 0.0;
      final hasSelections = controller.totalUnites.value > 0;
      final isOverLimit =
          controller.totalPoids.value > controller.lotFiltrage.quantiteRestante;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: hasSelections
                ? (isOverLimit
                    ? [Colors.red.shade50, Colors.red.shade100]
                    : [Colors.green.shade50, Colors.green.shade100])
                : [Colors.grey.shade50, Colors.grey.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: hasSelections
                ? (isOverLimit ? Colors.red.shade300 : Colors.green.shade300)
                : Colors.grey.shade300,
            width: hasSelections ? 3 : 1,
          ),
          boxShadow: hasSelections
              ? [
                  BoxShadow(
                    color: (isOverLimit ? Colors.red : Colors.green)
                        .withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        padding: EdgeInsets.all(isMobile ? 20 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec animation
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasSelections
                        ? (isOverLimit
                            ? Colors.red.shade600
                            : Colors.green.shade600)
                        : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasSelections
                        ? (isOverLimit ? Icons.error : Icons.analytics)
                        : Icons.pie_chart_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Résumé du conditionnement',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasSelections
                            ? '${(pourcentageUtilise * 100).toStringAsFixed(1)}% du lot utilisé'
                            : 'Sélectionnez des emballages pour commencer',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: hasSelections
                              ? (isOverLimit
                                  ? Colors.red.shade700
                                  : Colors.green.shade700)
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasSelections)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isOverLimit
                          ? Colors.red.shade600
                          : Colors.green.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isOverLimit ? 'DÉPASSEMENT!' : 'VALIDE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Barre de progression globale ultra-visuelle
            Container(
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.grey.shade200,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      // Barre de progression
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOut,
                        width: constraints.maxWidth *
                            pourcentageUtilise.clamp(0.0, 1.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            colors: isOverLimit
                                ? [Colors.red.shade400, Colors.red.shade600]
                                : [
                                    Colors.green.shade400,
                                    Colors.green.shade600
                                  ],
                          ),
                        ),
                      ),
                      // Effet de brillance
                      if (hasSelections)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.transparent,
                                  Colors.white.withOpacity(0.3),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Grille des totaux animée
            Row(
              children: [
                Expanded(
                  child: _buildAnimatedSummaryCard(
                    'Unités',
                    controller.totalUnites.value.toString(),
                    Icons.inventory_2,
                    Colors.blue.shade600,
                    hasSelections,
                    isMobile,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAnimatedSummaryCard(
                    'Poids Total',
                    '${controller.totalPoids.value.toStringAsFixed(2)} kg',
                    Icons.scale,
                    Colors.purple.shade600,
                    hasSelections,
                    isMobile,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAnimatedSummaryCard(
                    'Prix Total',
                    ConditionnementUtils.formatPrix(controller.totalPrix.value),
                    Icons.euro,
                    Colors.green.shade600,
                    hasSelections,
                    isMobile,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAnimatedSummaryCard(
                    'Restant',
                    '${controller.quantiteRestante.value.toStringAsFixed(2)} kg',
                    Icons.inventory,
                    controller.quantiteRestante.value > 0
                        ? Colors.orange.shade600
                        : Colors.green.shade600,
                    hasSelections,
                    isMobile,
                  ),
                ),
              ],
            ),

            if (hasSelections) ...[
              const SizedBox(height: 20),

              // Message de validation dynamique
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isOverLimit ? Colors.red.shade100 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOverLimit
                        ? Colors.red.shade300
                        : Colors.green.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOverLimit ? Icons.error : Icons.check_circle,
                      color: isOverLimit
                          ? Colors.red.shade600
                          : Colors.green.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.validationMessage.value,
                            style: TextStyle(
                              color: isOverLimit
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : 16,
                            ),
                          ),
                          if (isOverLimit) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Réduisez les quantités ou retirez des emballages',
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  /// Construit une carte de résumé animée
  Widget _buildAnimatedSummaryCard(String title, String value, IconData icon,
      Color color, bool isActive, bool isMobile) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color.withOpacity(0.5) : Colors.grey.shade200,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? color.withOpacity(0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isActive ? color : Colors.grey.shade400,
              size: isMobile ? 20 : 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: isActive ? color : Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
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

  /// 🔧 Helper : Construit une ligne de statistique ultra-détaillée
  Widget _buildStatRow(IconData icon, String label, String value,
      String subtitle, Color color, double fontSize) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize - 1,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: fontSize - 2,
                  color: color.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
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
