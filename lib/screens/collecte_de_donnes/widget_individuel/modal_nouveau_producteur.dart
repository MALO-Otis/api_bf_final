import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/collecte_geographie_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../data/models/collecte_models.dart';
import '../../../../widgets/geographic_selection_widget.dart';

class ModalNouveauProducteur extends StatefulWidget {
  final String nomSite;
  final Function(ProducteurModel) onProducteurAjoute;

  const ModalNouveauProducteur({
    Key? key,
    required this.nomSite,
    required this.onProducteurAjoute,
  }) : super(key: key);

  @override
  State<ModalNouveauProducteur> createState() => _ModalNouveauProducteurState();
}

class _ModalNouveauProducteurState extends State<ModalNouveauProducteur> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _numeroController = TextEditingController();
  final _nbRuchesTradController = TextEditingController();
  final _nbRuchesModController = TextEditingController();
  final _nomCooperativeController = TextEditingController();

  // Service géographie Firestore
  late CollecteGeographieService _geographieService;

  String _sexeSelectionne = '';
  String _ageSelectionne = '';
  String _appartenanceSelectionnee = '';

  // Variables géographiques simplifiées
  String _regionSelectionnee = '';
  String _provinceSelectionnee = '';
  String _communeSelectionnee = '';
  String _villageSelectionne = '';
  bool _villagePersonnaliseActive = false;
  final TextEditingController _villagePersonnaliseController =
      TextEditingController();

  List<String> _predominancesFloralesSelectionnees = [];

  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _sexes = ['Masculin', 'Féminin'];
  final List<String> _categoriesAge = [
    'Supérieur à 35',
    'Inférieur ou égal à 35'
  ]; // Nouveau
  final List<String> _appartenances = ['Propre', 'Coopérative'];
  final List<String> _predominancesFlorales = [
    'Acacia',
    'Eucalyptus',
    'Karité',
    'Néré',
    'Baobab',
    'Manguier',
    'Citronnier',
    'Moringa',
    'Tamarinier',
    'Kapokier',
    'Cajou',
    'Détarium',
    'Zaaba',
    'Filao',
  ];

  @override
  void initState() {
    super.initState();
    print('[ModalNouveauProducteur] 🚀 Initialisation du widget...');

    // Initialiser le service géographie de façon plus robuste
    try {
      _geographieService = Get.find<CollecteGeographieService>();
      print('[ModalNouveauProducteur] ✅ Service trouvé dans GetX');
    } catch (e) {
      print(
          '[ModalNouveauProducteur] ⚠️  Service non trouvé, injection en cours...');
      // Si le service n'est pas trouvé, on l'injecte ET on force l'initialisation
      final service = CollecteGeographieService();
      Get.put<CollecteGeographieService>(service, permanent: true);
      _geographieService = service;
      print('[ModalNouveauProducteur] ✅ Service injecté avec succès');

      // Forcer l'initialisation manuelle car onInit() pourrait ne pas être appelé
      service.onInit();
    }

    print('[ModalNouveauProducteur] 📊 État initial du service:');
    print('  - isLoading: ${_geographieService.isLoading}');
    print('  - error: "${_geographieService.error}"');
    print('  - regions: ${_geographieService.regions.length}');

    // Forcer le chargement ET attendre un délai pour les logs
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print(
          '[ModalNouveauProducteur] 🔄 PostFrameCallback - Vérification des données...');

      // Attendre un peu pour laisser le temps aux éventuelles données de se charger
      await Future.delayed(Duration(milliseconds: 500));

      print('[ModalNouveauProducteur] 📊 État après délai:');
      print('  - isLoading: ${_geographieService.isLoading}');
      print('  - error: "${_geographieService.error}"');
      print('  - regions: ${_geographieService.regions.length}');

      if (_geographieService.regions.isEmpty && !_geographieService.isLoading) {
        print(
            '[ModalNouveauProducteur] 📡 Déclenchement FORCÉ du chargement des données...');
        await _geographieService.loadGeographieData();

        print('[ModalNouveauProducteur] 📊 État après chargement forcé:');
        print('  - isLoading: ${_geographieService.isLoading}');
        print('  - error: "${_geographieService.error}"');
        print('  - regions: ${_geographieService.regions.length}');
      } else {
        print(
            '[ModalNouveauProducteur] ✅ Données déjà disponibles ou en cours de chargement');
      }
    });
  }

  @override
  void dispose() {
    _nomController.dispose();
    _numeroController.dispose();
    _nbRuchesTradController.dispose();
    _nbRuchesModController.dispose();
    _nomCooperativeController.dispose();
    _villagePersonnaliseController.dispose();
    super.dispose();
  }

  Future<void> _enregistrerProducteur() async {
    print("🟡 _enregistrerProducteur - Début enregistrement");

    if (!_formKey.currentState!.validate()) {
      print("🔴 _enregistrerProducteur - Validation formulaire échoué");
      return;
    }

    // Validation spécifique pour les champs dropdown
    if (_sexeSelectionne.isEmpty) {
      setState(() => _errorMessage = 'Veuillez sélectionner le sexe');
      return;
    }
    if (_ageSelectionne.isEmpty) {
      setState(
          () => _errorMessage = 'Veuillez sélectionner la catégorie d\'âge');
      return;
    }
    if (_appartenanceSelectionnee.isEmpty) {
      setState(() => _errorMessage = 'Veuillez sélectionner l\'appartenance');
      return;
    }
    // Validation Prédominance florale (obligatoire)
    if (_predominancesFloralesSelectionnees.isEmpty) {
      setState(() => _errorMessage =
          'Veuillez sélectionner au moins une prédominance florale');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print(
          "🟡 _enregistrerProducteur - Vérification unicité numéro: ${_numeroController.text.trim()}");

      // SÉCURITÉ CRITIQUE : Vérification unicité du numéro dans la NOUVELLE collection listes_prod
      final existant = await FirebaseFirestore.instance
          .collection('Sites')
          .doc(widget.nomSite)
          .collection('listes_prod')
          .where('numero', isEqualTo: _numeroController.text.trim())
          .get();

      if (existant.docs.isNotEmpty) {
        print(
            "🔴 _enregistrerProducteur - Numéro déjà existant: ${_numeroController.text.trim()}");
        setState(() {
          _errorMessage = 'Ce numéro existe déjà';
          _isLoading = false;
        });
        return;
      }

      print(
          "🟡 _enregistrerProducteur - Numéro unique, création du producteur");

      // SÉCURITÉ CRITIQUE : ID personnalisé avec le numéro pour éviter toute confusion
      final numeroSanitize = _numeroController.text
          .trim()
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final idProducteurPersonnalise = "prod_$numeroSanitize";

      print(
          "🔒 ID PRODUCTEUR PERSONNALISÉ SÉCURISÉ: $idProducteurPersonnalise");

      // VÉRIFICATION ANTI-COLLISION : S'assurer que l'ID personnalisé n'existe pas
      final verificationId = await FirebaseFirestore.instance
          .collection('Sites')
          .doc(widget.nomSite)
          .collection('listes_prod')
          .doc(idProducteurPersonnalise)
          .get();

      if (verificationId.exists) {
        throw Exception(
            "SÉCURITÉ CRITIQUE: ID producteur déjà existant: $idProducteurPersonnalise");
      }

      // VÉRIFICATION ANTI-ÉCRASEMENT : S'assurer qu'on ne touche PAS à la collection utilisateurs
      print("🔒 VÉRIFICATION: Collection 'utilisateurs' ne sera PAS touchée");
      print("🔒 VÉRIFICATION: Écriture uniquement dans 'listes_prod'");

      // Création du producteur avec l'ID personnalisé
      final docRef = FirebaseFirestore.instance
          .collection('Sites')
          .doc(widget.nomSite)
          .collection('listes_prod')
          .doc(idProducteurPersonnalise);

      final nbRuchesTrad = int.tryParse(_nbRuchesTradController.text) ?? 0;
      final nbRuchesMod = int.tryParse(_nbRuchesModController.text) ?? 0;

      print("🟡 _enregistrerProducteur - Données producteur:");
      print("   - ID: ${docRef.id}");
      print("   - Nom: ${_nomController.text.trim()}");
      print("   - Numéro: ${_numeroController.text.trim()}");
      print("   - Sexe: $_sexeSelectionne");
      print("   - Catégorie d'âge: $_ageSelectionne");
      print("   - Appartenance: $_appartenanceSelectionnee");
      print("   - Région: $_regionSelectionnee");
      print("   - Province: $_provinceSelectionnee");
      print("   - Commune: $_communeSelectionnee");
      print(
          "   - Village: ${_villagePersonnaliseActive ? _villagePersonnaliseController.text.trim() : _villageSelectionne}");
      print("   - Ruches trad: $nbRuchesTrad");
      print("   - Ruches mod: $nbRuchesMod");
      print("   - Origines florales: $_predominancesFloralesSelectionnees");

      final producteur = ProducteurModel(
        id: idProducteurPersonnalise, // ID personnalisé sécurisé
        nomPrenom: _nomController.text.trim(),
        numero: _numeroController.text.trim(),
        sexe: _sexeSelectionne,
        age: _ageSelectionne, // Directement la valeur String
        appartenance: _appartenanceSelectionnee,
        cooperative: _appartenanceSelectionnee == 'Coopérative'
            ? _nomCooperativeController.text.trim()
            : '',
        localisation: {
          'region': _regionSelectionnee,
          'province': _provinceSelectionnee,
          'commune': _communeSelectionnee,
          'village': _villagePersonnaliseActive
              ? _villagePersonnaliseController.text.trim()
              : _villageSelectionne,
          'village_personnalise': _villagePersonnaliseActive.toString(),
        },
        nbRuchesTrad: nbRuchesTrad,
        nbRuchesMod: nbRuchesMod,
        totalRuches: nbRuchesTrad + nbRuchesMod,
        originesFlorale: _predominancesFloralesSelectionnees,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      print("🟡 _enregistrerProducteur - Sauvegarde Firestore SÉCURISÉE");
      print(
          "🔒 GARANTIE: Écriture uniquement dans listes_prod/${idProducteurPersonnalise}");

      // ENREGISTREMENT SÉCURISÉ avec vérification finale
      await docRef.set(producteur.toFirestore());

      // VÉRIFICATION POST-ÉCRITURE pour confirmer l'intégrité
      final verificationFinale = await docRef.get();
      if (!verificationFinale.exists) {
        throw Exception("INTÉGRITÉ: Échec de l'enregistrement producteur");
      }

      print("✅ _enregistrerProducteur - Producteur enregistré avec succès");
      widget.onProducteurAjoute(producteur);
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producteur ajouté avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stackTrace) {
      print("🔴 _enregistrerProducteur - Erreur: $e");
      print("🔴 _enregistrerProducteur - Stack trace: $stackTrace");
      setState(() {
        _errorMessage = 'Erreur lors de l\'ajout: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
      ),
      child: Container(
        width: isSmallScreen ? double.infinity : 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          children: [
            // En-tête
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                color: Colors.green[600],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isSmallScreen ? 12 : 16),
                  topRight: Radius.circular(isSmallScreen ? 12 : 16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_add,
                    color: Colors.white,
                    size: isSmallScreen ? 20 : 24,
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  Expanded(
                    child: Text(
                      'Nouveau producteur',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Message d'erreur
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: isSmallScreen ? 12 : 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Formulaire
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  child: Column(
                    children: [
                      // Localisation avec widget unifié
                      _buildSection(
                        'Localisation',
                        Icons.location_on,
                        [
                          GeographicSelectionWidget(
                            selectedRegion: _regionSelectionnee,
                            selectedProvince: _provinceSelectionnee,
                            selectedCommune: _communeSelectionnee,
                            selectedVillage: _villageSelectionne,
                            villagePersonnaliseActive:
                                _villagePersonnaliseActive,
                            villagePersonnalise:
                                _villagePersonnaliseController.text,
                            onRegionChanged: (value) {
                              setState(() {
                                _regionSelectionnee = value ?? '';
                                _provinceSelectionnee = '';
                                _communeSelectionnee = '';
                                _villageSelectionne = '';
                                _villagePersonnaliseActive = false;
                                _villagePersonnaliseController.clear();
                              });
                            },
                            onProvinceChanged: (value) {
                              setState(() {
                                _provinceSelectionnee = value ?? '';
                                _communeSelectionnee = '';
                                _villageSelectionne = '';
                                _villagePersonnaliseActive = false;
                                _villagePersonnaliseController.clear();
                              });
                            },
                            onCommuneChanged: (value) {
                              setState(() {
                                _communeSelectionnee = value ?? '';
                                _villageSelectionne = '';
                                _villagePersonnaliseActive = false;
                                _villagePersonnaliseController.clear();
                              });
                            },
                            onVillageChanged: (value) {
                              setState(() {
                                _villageSelectionne = value ?? '';
                              });
                            },
                            onVillagePersonnaliseToggle: (value) {
                              setState(() {
                                _villagePersonnaliseActive = value;
                                if (!value) {
                                  _villagePersonnaliseController.clear();
                                } else {
                                  _villageSelectionne = '';
                                }
                              });
                            },
                            onVillagePersonnaliseChanged: (value) {
                              _villagePersonnaliseController.text = value;
                            },
                            showRefreshButton: false,
                          ),
                        ],
                        isSmallScreen,
                      ),
                      const SizedBox(height: 20),

                      // Informations personnelles
                      _buildSection(
                        'Informations personnelles',
                        Icons.person,
                        [
                          if (isSmallScreen) ...[
                            // Mobile : colonnes
                            _buildTextField(
                              _nomController,
                              'Nom et prénom *',
                              Icons.person,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Obligatoire' : null,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              _numeroController,
                              'Numéro de téléphone *',
                              Icons.phone,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Obligatoire' : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDropdown(
                                    'Sexe *',
                                    _sexeSelectionne,
                                    _sexes,
                                    (value) => setState(
                                        () => _sexeSelectionne = value!),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDropdown(
                                    'Catégorie d\'âge *',
                                    _ageSelectionne,
                                    _categoriesAge,
                                    (value) => setState(
                                        () => _ageSelectionne = value!),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // Desktop : lignes
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildTextField(
                                    _nomController,
                                    'Nom et prénom *',
                                    Icons.person,
                                    validator: (value) => value?.isEmpty ?? true
                                        ? 'Obligatoire'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    _numeroController,
                                    'Numéro de téléphone *',
                                    Icons.phone,
                                    validator: (value) => value?.isEmpty ?? true
                                        ? 'Obligatoire'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Flexible(
                                  flex: 1,
                                  child: _buildDropdown(
                                    'Sexe *',
                                    _sexeSelectionne,
                                    _sexes,
                                    (value) => setState(
                                        () => _sexeSelectionne = value!),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  flex: 2,
                                  child: _buildDropdown(
                                    'Catégorie d\'âge *',
                                    _ageSelectionne,
                                    _categoriesAge,
                                    (value) => setState(
                                        () => _ageSelectionne = value!),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  flex: 1,
                                  child: _buildDropdown(
                                    'Appartenance *',
                                    _appartenanceSelectionnee,
                                    _appartenances,
                                    (value) => setState(() {
                                      _appartenanceSelectionnee = value!;
                                      if (value != 'Coopérative') {
                                        _nomCooperativeController.clear();
                                      }
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (isSmallScreen) ...[
                            const SizedBox(height: 12),
                            _buildDropdown(
                              'Appartenance *',
                              _appartenanceSelectionnee,
                              _appartenances,
                              (value) => setState(() {
                                _appartenanceSelectionnee = value!;
                                if (value != 'Coopérative') {
                                  _nomCooperativeController.clear();
                                }
                              }),
                            ),
                          ],
                        ],
                        isSmallScreen,
                      ),

                      // Champ nom de coopérative (si Coopérative est sélectionnée)
                      if (_appartenanceSelectionnee == 'Coopérative') ...[
                        const SizedBox(height: 16),
                        _buildSection(
                          'Nom de la coopérative',
                          Icons.groups,
                          [
                            TextFormField(
                              controller: _nomCooperativeController,
                              decoration: InputDecoration(
                                labelText: 'Nom de la coopérative *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.business),
                              ),
                              validator: (value) {
                                if (_appartenanceSelectionnee ==
                                        'Coopérative' &&
                                    (value == null || value.trim().isEmpty)) {
                                  return 'Le nom de la coopérative est obligatoire';
                                }
                                return null;
                              },
                            ),
                          ],
                          isSmallScreen,
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Section Prédominance florale (obligatoire)
                      _buildSection(
                        'Prédominance florale *',
                        Icons.local_florist,
                        [
                          Text(
                            'Sélectionnez au moins une prédominance florale',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _predominancesFlorales.map((predominance) {
                              final isSelected =
                                  _predominancesFloralesSelectionnees
                                      .contains(predominance);
                              return FilterChip(
                                label: Text(
                                  predominance,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _predominancesFloralesSelectionnees
                                          .add(predominance);
                                    } else {
                                      _predominancesFloralesSelectionnees
                                          .remove(predominance);
                                    }
                                  });
                                },
                                backgroundColor: Colors.grey.shade200,
                                selectedColor: Colors.green.shade400,
                                checkmarkColor: Colors.white,
                                elevation: isSelected ? 2 : 0,
                              );
                            }).toList(),
                          ),
                        ],
                        isSmallScreen,
                      ),

                      const SizedBox(height: 20),

                      // Informations apicoles
                      _buildSection(
                        'Informations apicoles',
                        Icons.hive,
                        [
                          if (isSmallScreen) ...[
                            _buildTextField(
                              _nbRuchesTradController,
                              'Nombre de ruches traditionnelles',
                              Icons.hive,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              _nbRuchesModController,
                              'Nombre de ruches modernes',
                              Icons.hive,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    _nbRuchesTradController,
                                    'Nombre de ruches traditionnelles',
                                    Icons.hive,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    _nbRuchesModController,
                                    'Nombre de ruches modernes',
                                    Icons.hive,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                        isSmallScreen,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Boutons d'action
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      child: Text(
                        'Annuler',
                        style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 12 : 16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(isSmallScreen ? 8 : 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _enregistrerProducteur,
                      icon: _isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _isLoading ? 'Enregistrement...' : 'Enregistrer',
                        style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 12 : 16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(isSmallScreen ? 8 : 10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      String titre, IconData icon, List<Widget> children, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isSmallScreen ? 8 : 10),
                topRight: Radius.circular(isSmallScreen ? 8 : 10),
              ),
            ),
            child: Row(
              children: [
                Icon(icon,
                    color: Colors.grey[700], size: isSmallScreen ? 18 : 20),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Text(
                  titre,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 14 : 15,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: isSmallScreen ? 18 : 20),
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isSmallScreen ? 12 : 16,
        ),
        labelStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
      ),
      style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isSmallScreen ? 12 : 16,
        ),
        labelStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
      ),
      style: TextStyle(
        fontSize: isSmallScreen ? 13 : 14,
        color: Colors.black,
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) => label.contains('*') && (value?.isEmpty ?? true)
          ? 'Obligatoire'
          : null,
    );
  }
}
