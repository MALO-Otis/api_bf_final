import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:async';

// Prix automatiques selon la nature du miel
const Map<String, double> prixGrosMilleFleurs = {
  "Stick 20g": 1500,
  "30g": 36000,
  "250g": 950,
  "500g": 1800,
  "1Kg": 3400,
  "720g": 2500,
  "1.5Kg": 4500,
  "7kg": 23000,
};

const Map<String, double> prixGrosMonoFleur = {
  "250g": 1750,
  "500g": 3000,
  "1Kg": 5000,
  "720g": 3500,
  "1.5Kg": 6000,
  "7kg": 34000,
  "Stick 20g": 1500,
  "30g": 36000,
};

class ConditionnementController extends GetxController {
  final dateConditionnement = Rxn<DateTime>();
  final lotOrigine = RxnString();

  // Emballages possibles
  final List<String> typesEmballage = [
    "1.5Kg",
    "1Kg",
    "720g",
    "500g",
    "250g",
    "30g",
    "Stick 20g",
    "7kg"
  ];

  final Map<String, RxBool> emballageSelection = {};
  final Map<String, TextEditingController> nbPotsController = {};

  final RxInt nbTotalPots = 0.obs;
  final RxDouble prixTotal = 0.0.obs;
  final RxMap<String, int> nbPotsParType = <String, int>{}.obs;
  final RxMap<String, double> prixTotalParType = <String, double>{}.obs;

  // Champs issus du lot sélectionné
  final RxDouble quantiteRecue = 0.0.obs;
  final RxDouble quantiteRestante = 0.0.obs;
  final RxString predominanceFlorale = ''.obs;

  // Lots filtrés
  final lotsFiltrage = <Map<String, dynamic>>[].obs;

  // 🚀 OPTIMISATIONS POUR MISE À JOUR RAPIDE ET FLUIDE
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 300);
  final RxBool _isCalculating = false.obs;
  final RxString _lastUpdatedField = ''.obs;

  // Indicateurs visuels pour la réactivité
  bool get isCalculating => _isCalculating.value;
  String get lastUpdatedField => _lastUpdatedField.value;

  @override
  void onInit() {
    super.onInit();
    for (var type in typesEmballage) {
      emballageSelection[type] = false.obs;
      nbPotsController[type] = TextEditingController();

      // 🔥 AMÉLIORATION: Listener optimisé avec debounce
      nbPotsController[type]!.addListener(() => _debouncedRecalcule(type));
    }
    ever(lotOrigine, (_) async {
      await majInfosLot();
      _recalculeImmediat(); // Calcul immédiat pour le changement de lot
    });
    loadLotsFiltrage();
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    for (var controller in nbPotsController.values) {
      controller.dispose();
    }
    super.onClose();
  }

  // Récupère les lots filtrés (statutFiltrage=filtré)
  Future<void> loadLotsFiltrage() async {
    final snap = await FirebaseFirestore.instance
        .collection('filtrage')
        .where('statutFiltrage', isEqualTo: 'filtré')
        .get();
    lotsFiltrage.assignAll(snap.docs.map((e) {
      final data = e.data();
      data['id'] = e.id;
      return data;
    }).toList());
  }

  // Met à jour la quantité reçue et la nature florale en fonction du lot sélectionné
  Future<void> majInfosLot() async {
    final lot =
        lotsFiltrage.firstWhereOrNull((e) => e['id'] == lotOrigine.value);
    quantiteRecue.value =
        (lot?['quantiteFiltre'] ?? lot?['quantiteFiltree'] ?? 0.0) * 1.0;
    predominanceFlorale.value = (lot?['predominanceFlorale'] ?? '').toString();
    _recalcule();
  }

  // Applique les prix selon la nature du lot
  double getPrixAuto(String type) {
    final florale = (predominanceFlorale.value).toLowerCase();
    if (_isMonoFleur(florale)) {
      return prixGrosMonoFleur[type] ?? prixGrosMilleFleurs[type] ?? 0.0;
    } else {
      return prixGrosMilleFleurs[type] ?? 0.0;
    }
  }

  bool _isMonoFleur(String florale) {
    if (florale.contains("mono")) return true;
    if (florale.contains("mille") || florale.contains("mixte")) return false;
    if (florale.contains("+") || florale.contains(",")) return false;
    return florale.trim().isNotEmpty;
  }

  // 🚀 SYSTÈME DE RECALCUL OPTIMISÉ ET FLUIDE

  /// Déclenche un recalcul avec debounce pour éviter les calculs trop fréquents
  void _debouncedRecalcule(String typeEmballage) {
    _lastUpdatedField.value = typeEmballage;

    // Annuler le timer précédent s'il existe
    _debounceTimer?.cancel();

    // Démarrer le calcul avec debounce
    _debounceTimer = Timer(_debounceDuration, () {
      _recalculeImmediat();
    });

    // Afficher immédiatement l'indicateur de calcul
    _isCalculating.value = true;
  }

  /// Recalcul immédiat pour les actions importantes (changement de lot, etc.)
  void _recalculeImmediat() {
    _performCalculations();
  }

  /// Fonction de calcul optimisée avec animation de feedback
  void _performCalculations() {
    _isCalculating.value = true;

    // Effectuer les calculs
    int nbTotal = 0;
    double prixTotalAll = 0.0;
    final Map<String, int> nouveauxNbPotsParType = {};
    final Map<String, double> nouveauxPrixTotalParType = {};

    for (var type in typesEmballage) {
      if (emballageSelection[type]?.value == true) {
        final inputText = nbPotsController[type]!.text.trim();
        final nb = int.tryParse(inputText) ?? 0;

        // Validation en temps réel
        if (nb < 0) {
          nbPotsController[type]!.text = '0';
          continue;
        }

        final prix = getPrixAuto(type);
        nouveauxNbPotsParType[type] = nb;
        nouveauxPrixTotalParType[type] = nb * prix;
        nbTotal += nb;
        prixTotalAll += nb * prix;
      }
    }

    // Mise à jour atomique des valeurs observables
    nbPotsParType.assignAll(nouveauxNbPotsParType);
    prixTotalParType.assignAll(nouveauxPrixTotalParType);
    nbTotalPots.value = nbTotal;
    prixTotal.value = prixTotalAll;
    quantiteRestante.value =
        (quantiteRecue.value - nbTotal).clamp(0, double.infinity);

    // Animation de feedback de fin de calcul
    Future.delayed(const Duration(milliseconds: 100), () {
      _isCalculating.value = false;
      _lastUpdatedField.value = '';
    });
  }

  /// Fonction de recalcul legacy (conservée pour compatibilité)
  void _recalcule() {
    _recalculeImmediat();
  }

  // Enregistrement du conditionnement
  Future<void> enregistrerConditionnement() async {
    if (dateConditionnement.value == null || lotOrigine.value == null) {
      Get.snackbar("Erreur", "Sélectionnez une date et un lot d'origine !");
      return;
    }
    if (nbTotalPots.value <= 0) {
      Get.snackbar("Erreur", "Ajoutez au moins un pot !");
      return;
    }
    final emballages = <Map<String, dynamic>>[];
    for (var type in typesEmballage) {
      if (emballageSelection[type]?.value == true) {
        emballages.add({
          'type': type,
          'nombre': nbPotsParType[type] ?? 0,
          'prixUnitaire': getPrixAuto(type),
          'prixTotal': prixTotalParType[type] ?? 0.0,
        });
      }
    }
    await FirebaseFirestore.instance.collection('conditionnement').add({
      'date': dateConditionnement.value,
      'lotOrigine': lotOrigine.value,
      'predominanceFlorale': predominanceFlorale.value,
      'emballages': emballages,
      'nbTotalPots': nbTotalPots.value,
      'prixTotal': prixTotal.value,
      'quantiteRecue': quantiteRecue.value,
      'quantiteRestante': quantiteRestante.value,
      'createdAt': FieldValue.serverTimestamp(),
    });
    Get.snackbar("Succès", "Conditionnement enregistré !");
    reset();
  }

  void reset() {
    dateConditionnement.value = null;
    lotOrigine.value = null;
    for (var type in typesEmballage) {
      emballageSelection[type]?.value = false;
      nbPotsController[type]?.clear();
    }
    nbTotalPots.value = 0;
    prixTotal.value = 0.0;
    quantiteRecue.value = 0.0;
    quantiteRestante.value = 0.0;
    nbPotsParType.clear();
    prixTotalParType.clear();
    predominanceFlorale.value = '';
  }
}

// ---------- PAGE UI -----------
class ConditionnementPage extends StatelessWidget {
  final ConditionnementController c = Get.put(ConditionnementController());

  ConditionnementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("🧊 Module 4 – Conditionnement"),
        backgroundColor: Colors.amber[700],
      ),
      backgroundColor: Colors.amber[50],
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 700),
            child: Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle("Informations de conditionnement"),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: _datePickerField(
                                        "Date", c.dateConditionnement)),
                                SizedBox(width: 16),
                                Expanded(
                                    child: Obx(() =>
                                        DropdownButtonFormField<String>(
                                          value: c.lotOrigine.value,
                                          decoration: InputDecoration(
                                            labelText:
                                                "Lot d'origine (issu du filtrage)",
                                            prefixIcon:
                                                Icon(Icons.batch_prediction),
                                          ),
                                          items: c.lotsFiltrage
                                              .map((lot) =>
                                                  DropdownMenuItem<String>(
                                                    value: lot['id'].toString(),
                                                    child: Text(
                                                        "Lot #${lot['id']} - ${lot['quantiteFiltre']}kg"),
                                                  ))
                                              .toList(),
                                          onChanged: (v) {
                                            c.lotOrigine.value = v;
                                            c.majInfosLot();
                                          },
                                          validator: (v) => v == null
                                              ? "Sélectionner un lot"
                                              : null,
                                        ))),
                              ],
                            ),
                            Obx(() => c.predominanceFlorale.value.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 12.0),
                                    child: Row(
                                      children: [
                                        Icon(Icons.local_florist,
                                            color: Colors.green, size: 18),
                                        const SizedBox(width: 6),
                                        Text(
                                            "Florale : ${c.predominanceFlorale.value}",
                                            style: const TextStyle(
                                                fontSize: 15,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.green)),
                                      ],
                                    ),
                                  )
                                : SizedBox.shrink()),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 18),
                    _sectionTitle("Type d'emballage et nombre de pots"),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            ...c.typesEmballage
                                .map((type) => Obx(() => AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 2),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: c.lastUpdatedField == type
                                            ? Colors.amber.shade100
                                                .withOpacity(0.7)
                                            : Colors.transparent,
                                        border: c.lastUpdatedField == type
                                            ? Border.all(
                                                color: Colors.amber.shade300,
                                                width: 2)
                                            : null,
                                      ),
                                      child: CheckboxListTile(
                                        title: Row(
                                          children: [
                                            Text(type),
                                            const SizedBox(width: 10),
                                            // 🔥 Indicateur de prix avec animation
                                            AnimatedScale(
                                              scale: c.lastUpdatedField == type
                                                  ? 1.05
                                                  : 1.0,
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              child: Text(
                                                "Prix auto : ${c.getPrixAuto(type).toStringAsFixed(0)} FCFA",
                                                style: TextStyle(
                                                    color: Colors.deepOrange,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13),
                                              ),
                                            ),
                                            // 🔥 Indicateur de calcul en cours
                                            if (c.isCalculating &&
                                                c.lastUpdatedField == type) ...[
                                              const SizedBox(width: 8),
                                              const SizedBox(
                                                width: 12,
                                                height: 12,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(Colors.amber),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        value:
                                            c.emballageSelection[type]?.value ??
                                                false,
                                        onChanged: (v) {
                                          c.emballageSelection[type]?.value =
                                              v ?? false;
                                          c._recalculeImmediat(); // Recalcul immédiat pour la sélection
                                        },
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        secondary: c.emballageSelection[type]
                                                    ?.value ==
                                                true
                                            ? AnimatedContainer(
                                                duration: const Duration(
                                                    milliseconds: 300),
                                                width: 100,
                                                child: TextFormField(
                                                  controller:
                                                      c.nbPotsController[type],
                                                  keyboardType:
                                                      TextInputType.number,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                  ],
                                                  decoration: InputDecoration(
                                                    labelText: "Nb pots",
                                                    isDense: true,
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    // 🔥 Feedback visuel selon l'état
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                      borderSide: BorderSide(
                                                        color: Colors
                                                            .amber.shade600,
                                                        width: 2,
                                                      ),
                                                    ),
                                                    suffixIcon: c
                                                            .nbPotsController[
                                                                type]!
                                                            .text
                                                            .isNotEmpty
                                                        ? Icon(
                                                            Icons.check_circle,
                                                            color: Colors
                                                                .green.shade600,
                                                            size: 18,
                                                          )
                                                        : null,
                                                  ),
                                                ),
                                              )
                                            : null,
                                      ),
                                    )))
                                .toList(),
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Text(
                                "Les prix sont appliqués automatiquement selon la nature florale du lot.",
                                style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.amber[900],
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    _sectionTitle("Quantités"),
                    // 🔥 Carte des quantités avec animations améliorées
                    Card(
                      elevation: c.isCalculating ? 4 : 1,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: c.isCalculating
                              ? Border.all(
                                  color: Colors.amber.shade300, width: 2)
                              : null,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Obx(() => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 🔥 Détails par type d'emballage avec animations
                                  ...c.nbPotsParType.entries.map((e) =>
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 250),
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 3),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          color: c.lastUpdatedField == e.key
                                              ? Colors.green.shade50
                                              : Colors.transparent,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.inventory_2,
                                              size: 16,
                                              color: Colors.amber.shade700,
                                            ),
                                            const SizedBox(width: 8),
                                            Text("${e.key}: ",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            AnimatedDefaultTextStyle(
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              style: TextStyle(
                                                fontSize:
                                                    c.lastUpdatedField == e.key
                                                        ? 15
                                                        : 14,
                                                fontWeight:
                                                    c.lastUpdatedField == e.key
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                color:
                                                    c.lastUpdatedField == e.key
                                                        ? Colors.green.shade800
                                                        : Colors.black,
                                              ),
                                              child: Text("${e.value} pots"),
                                            ),
                                            SizedBox(width: 5),
                                            AnimatedDefaultTextStyle(
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              style: TextStyle(
                                                color: Colors.green[700]!,
                                                fontSize:
                                                    c.lastUpdatedField == e.key
                                                        ? 14
                                                        : 13,
                                                fontWeight:
                                                    c.lastUpdatedField == e.key
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                              ),
                                              child: Text(
                                                " | ${c.prixTotalParType[e.key]?.toStringAsFixed(0) ?? '0'} FCFA",
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),

                                  // Divider avec animation
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    height: 1,
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    color: c.isCalculating
                                        ? Colors.amber.shade300
                                        : Colors.grey.shade300,
                                  ),

                                  // 🔥 Totaux avec animations plus prononcées
                                  _buildQuantityRow(
                                    "Nombre total de pots",
                                    "${c.nbTotalPots.value}",
                                    Icons.shopping_basket,
                                    Colors.blue.shade700,
                                    c.isCalculating,
                                  ),
                                  _buildQuantityRow(
                                    "Prix total",
                                    "${c.prixTotal.value.toStringAsFixed(0)} FCFA",
                                    Icons.payments,
                                    Colors.green.shade700,
                                    c.isCalculating,
                                  ),
                                  _buildQuantityRow(
                                    "Quantité reçue (filtrée)",
                                    "${c.quantiteRecue.value.toStringAsFixed(2)} kg",
                                    Icons.scale,
                                    Colors.orange.shade700,
                                    false,
                                  ),
                                  _buildQuantityRow(
                                    "Quantité restante",
                                    "${c.quantiteRestante.value.toStringAsFixed(2)} kg",
                                    Icons.inventory,
                                    c.quantiteRestante.value > 0
                                        ? Colors.amber.shade700
                                        : Colors.grey.shade600,
                                    c.isCalculating,
                                    isHighlighted: c.quantiteRestante.value > 0,
                                  ),
                                ],
                              )),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.save),
                        label: Text("Enregistrer le conditionnement"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[700]),
                        onPressed: c.nbTotalPots.value > 0
                            ? () async {
                                await c.enregistrerConditionnement();
                              }
                            : null,
                      ),
                    ),
                    SizedBox(height: 22),
                  ],
                )),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          t,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.amber[900]),
        ),
      );

  // 🔥 Widget helper pour les lignes de quantité avec animations
  Widget _buildQuantityRow(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isAnimating, {
    bool isHighlighted = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: isHighlighted ? color.withOpacity(0.1) : Colors.transparent,
        border: isHighlighted
            ? Border.all(color: color.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Row(
        children: [
          AnimatedScale(
            scale: isAnimating ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            "$label : ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontSize: isAnimating ? 16 : 14,
              fontWeight: isAnimating ? FontWeight.bold : FontWeight.normal,
              color: isAnimating ? color : Colors.black87,
            ),
            child: Text(value),
          ),
          if (isAnimating) ...[
            const SizedBox(width: 8),
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _datePickerField(String label, Rxn<DateTime> dateRx) {
    final controller = TextEditingController(
        text: dateRx.value != null
            ? "${dateRx.value!.day}/${dateRx.value!.month}/${dateRx.value!.year}"
            : "Choisir une date");
    return Obx(() {
      if (dateRx.value != null) {
        controller.text =
            "${dateRx.value!.day}/${dateRx.value!.month}/${dateRx.value!.year}";
      } else {
        controller.text = "Choisir une date";
      }
      return InkWell(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: Get.context!,
            initialDate: dateRx.value ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null && picked != dateRx.value) {
            dateRx.value = picked;
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: Icon(Icons.calendar_today),
            border: OutlineInputBorder(),
          ),
          child: Text(
            dateRx.value != null
                ? "${dateRx.value!.day}/${dateRx.value!.month}/${dateRx.value!.year}"
                : "Choisir une date",
            style: TextStyle(
              color: dateRx.value != null ? Colors.black : Colors.grey,
            ),
          ),
        ),
      );
    });
  }
}
