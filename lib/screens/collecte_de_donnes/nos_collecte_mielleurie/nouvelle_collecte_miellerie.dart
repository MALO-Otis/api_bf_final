import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../historiques_collectes.dart';
import 'widgets/modal_ajout_miellerie.dart';
import '../../../data/models/scoop_models.dart';
import '../../../widgets/money_icon_widget.dart';
import '../../../authentication/user_session.dart';
import '../../../data/models/miellerie_models.dart';
import '../../../data/personnel/personnel_apisavana.dart';
import '../../../data/services/stats_mielleries_service.dart';
import '../../../services/universal_container_id_service.dart';
import '../nos_achats_scoop_contenants/widgets/modal_nouveau_scoop.dart';

class NouvelleCollecteMielleriePage extends StatefulWidget {
  const NouvelleCollecteMielleriePage({super.key});

  @override
  State<NouvelleCollecteMielleriePage> createState() =>
      _NouvelleCollecteMielleriePageState();
}

class _NouvelleCollecteMielleriePageState
    extends State<NouvelleCollecteMielleriePage> {
  final _formKey = GlobalKey<FormState>();
  final UserSession _userSession = Get.find<UserSession>();

  // Controllers
  final _localiteController = TextEditingController();
  final _repondantController = TextEditingController();
  final _observationsController = TextEditingController();

  // Variables
  DateTime _dateCollecte = DateTime.now();
  String? _selectedSiteMiellerie; // Site sélectionné comme miellerie
  String? _selectedCooperativeId;
  List<ContenantMiellerieModel> _contenants = [];
  bool _isLoading = false;
  TechnicienInfo? _selectedCollecteur;

  // Listes
  List<String> _sitesDisponibles = []; // Sites des techniciens comme mielleries
  List<String> _mielleriesDisponibles =
      []; // Mielleries dynamiques depuis la BD
  List<Map<String, dynamic>> _cooperatives = [];

  // NOUVEAU SYSTÈME SCOOP : Variables d'état du formulaire intégré
  final _contenantFormKey = GlobalKey<FormState>();
  String _typeMiel = 'Liquide';
  String? _typeCire;
  String? _couleurCire;
  String _typeContenant = 'Bidon';
  final _poidsController = TextEditingController();
  final _prixController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    // NOUVEAU SYSTÈME SCOOP : Commencer avec une liste vide
    // Initialiser le collecteur avec l'utilisateur connecté
    _selectedCollecteur =
        PersonnelUtils.findTechnicienByName(_userSession.nom ?? '');
  }

  @override
  void dispose() {
    _localiteController.dispose();
    _repondantController.dispose();
    _observationsController.dispose();
    // NOUVEAU SYSTÈME SCOOP : Nettoyage
    _poidsController.dispose();
    _prixController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final site = _userSession.site ?? '';

      // Charger les coopératives et les mielleries dynamiques
      final results = await Future.wait([
        StatsMielleriesService.loadCooperativesForSite(site),
        StatsMielleriesService.loadMiellerieNamesForSite(),
      ]);

      setState(() {
        // NOUVEAU : Utiliser les sites des techniciens comme mielleries
        _sitesDisponibles = List.from(sitesApisavana);
        // NOUVEAU : Ajouter les mielleries dynamiques depuis la BD
        _mielleriesDisponibles = results[1] as List<String>;
        _cooperatives = results[0] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors du chargement des données: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // NOUVEAU SYSTÈME SCOOP : Méthode d'ajout avec validation
  void _saveContenantSCOOP() {
    if (!_contenantFormKey.currentState!.validate()) return;

    // Générer un ID unique pour le contenant
    final containerId =
        'C${(_contenants.length + 1).toString().padLeft(3, '0')}_miellerie';

    final contenant = ContenantMiellerieModel(
      id: containerId,
      typeContenant: _typeContenant,
      typeCollecte: _typeMiel,
      typeCire: _typeMiel == 'Cire' ? _typeCire : null,
      couleurCire: _typeCire == 'Purifiée' ? _couleurCire : null,
      quantite: double.parse(_poidsController.text),
      prixUnitaire: double.parse(_prixController.text),
      montantTotal: double.parse(_poidsController.text) *
          double.parse(_prixController.text),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    setState(() {
      _contenants.add(contenant);
    });

    // Réinitialiser le formulaire
    setState(() {
      _typeMiel = 'Liquide';
      _typeCire = null;
      _couleurCire = null;
      _typeContenant = 'Bidon';
    });
    _poidsController.clear();
    _prixController.clear();
    _notesController.clear();

    Get.snackbar(
      'Contenant ajouté',
      'Le contenant a été ajouté avec succès',
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.check_circle, color: Colors.green),
    );
  }

  void _removeContenant(int index) {
    setState(() => _contenants.removeAt(index));
  }

  /// Gère l'ajout d'une nouvelle miellerie
  void _onMiellerieAdded(String nomMiellerie) {
    setState(() {
      // Ajouter la nouvelle miellerie à la liste
      if (!_mielleriesDisponibles.contains(nomMiellerie)) {
        _mielleriesDisponibles.add(nomMiellerie);
        _mielleriesDisponibles.sort(); // Trier par ordre alphabétique
      }
      // Sélectionner automatiquement la nouvelle miellerie
      _selectedSiteMiellerie = nomMiellerie;
      // Auto-remplir la localité
      _localiteController.text = nomMiellerie;
      // Suggestions de répondant par défaut
      _repondantController.text = 'Responsable $nomMiellerie';
    });
  }

  /// Ouvre le modal d'ajout de miellerie
  void _ouvrirModalAjoutMiellerie() {
    showDialog(
      context: context,
      builder: (context) => ModalAjoutMiellerie(
        onMiellerieAdded: _onMiellerieAdded,
      ),
    );
  }

  double get _poidsTotal {
    return _contenants.fold(0.0, (sum, c) => sum + c.quantite);
  }

  double get _montantTotal {
    return _contenants.fold(0.0, (sum, c) => sum + c.montantTotal);
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateCollecte,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _dateCollecte = date);
    }
  }

  Future<void> _saveCollecte() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSiteMiellerie == null) {
      Get.snackbar('Erreur', 'Sélectionnez une miellerie (site)');
      return;
    }
    if (_selectedCooperativeId == null) {
      Get.snackbar('Erreur', 'Sélectionnez une coopérative');
      return;
    }
    if (_selectedCollecteur == null) {
      Get.snackbar('Erreur', 'Sélectionnez un collecteur');
      return;
    }
    if (_contenants.isEmpty || _contenants.every((c) => c.quantite <= 0)) {
      Get.snackbar('Erreur', 'Ajoutez au moins un contenant avec une quantité');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Générer les IDs universels pour les contenants
      final contenantsAvecIds = await _genererIdsUniversels(_contenants);

      final collecte = CollecteMiellerieModel(
        id: '',
        dateCollecte: _dateCollecte,
        collecteurId: _selectedCollecteur?.nomComplet ?? '',
        collecteurNom: _selectedCollecteur?.nomComplet ?? '',
        miellerieId: _selectedSiteMiellerie!, // ID = nom du site
        miellerieNom: _selectedSiteMiellerie!, // Nom = nom du site
        localite: _localiteController.text.isNotEmpty
            ? _localiteController.text
            : _selectedSiteMiellerie!,
        cooperativeId: _selectedCooperativeId!,
        cooperativeNom: (_cooperatives.firstWhere(
                (c) => c['id'] == _selectedCooperativeId!,
                orElse: () => {'nom': ''})['nom'] as String?) ??
            '',
        repondant: _repondantController.text.isNotEmpty
            ? _repondantController.text
            : 'Responsable $_selectedSiteMiellerie!',
        contenants: contenantsAvecIds,
        poidsTotal: _poidsTotal,
        montantTotal: _montantTotal,
        observations: _observationsController.text,
        site: _userSession.site ?? '',
        createdAt: DateTime.now(),
      );

      await StatsMielleriesService.saveCollecteMiellerie(collecte);

      Get.snackbar(
        'Succès',
        'Collecte Miellerie enregistrée avec succès',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        icon: const Icon(Icons.check_circle, color: Colors.green),
      );

      _resetForm();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de l\'enregistrement: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _localiteController.clear();
    _repondantController.clear();
    _observationsController.clear();
    setState(() {
      _dateCollecte = DateTime.now();
      _selectedSiteMiellerie = null;
      _selectedCooperativeId = null;
      _selectedCollecteur =
          PersonnelUtils.findTechnicienByName(_userSession.nom ?? '');
      _contenants.clear();
      // NOUVEAU SYSTÈME SCOOP : Commencer avec une liste vide
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: const Text(
          'Nouvelle collecte Miellerie',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            tooltip: 'Historique des collectes',
            icon: const Icon(Icons.history),
            onPressed: () => Get.to(() => const HistoriquesCollectesPage()),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetForm,
            tooltip: 'Réinitialiser le formulaire',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête
                        _buildSectionTitle('Informations générales'),
                        const SizedBox(height: 16),

                        // Date et collecteur
                        // Date et collecteur (responsive)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isCompact = constraints.maxWidth < 520;
                            final dateField = InkWell(
                              onTap: _selectDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date de collecte',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_month),
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                ),
                                child: Text(
                                  DateFormat('dd/MM/yyyy')
                                      .format(_dateCollecte),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            );
                            final collecteurField =
                                DropdownButtonFormField<TechnicienInfo>(
                              value: _selectedCollecteur,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Nom du collecteur',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                              ),
                              items: techniciensApisavana.map((technicien) {
                                return DropdownMenuItem<TechnicienInfo>(
                                  value: technicien,
                                  child: Text(
                                    '${technicien.nomComplet} · ${technicien.site}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (technicien) => setState(
                                  () => _selectedCollecteur = technicien),
                              validator: (value) =>
                                  value == null ? 'Collecteur requis' : null,
                            );
                            if (isCompact) {
                              return Column(
                                children: [
                                  dateField,
                                  const SizedBox(height: 12),
                                  collecteurField,
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(child: dateField),
                                const SizedBox(width: 16),
                                Expanded(child: collecteurField),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Sélection Miellerie et Coopérative
                        _buildSectionTitle('Miellerie et Coopérative'),
                        const SizedBox(height: 16),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isCompact = constraints.maxWidth < 520;

                            final miellerieField = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<String>(
                                  value: _selectedSiteMiellerie,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Miellerie (site) *',
                                    hintText: 'Sélectionnez une miellerie',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.factory),
                                    helperText:
                                        'Sites des techniciens + Mielleries ajoutées',
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.always,
                                  ),
                                  items: [
                                    // Sites des techniciens
                                    ..._sitesDisponibles.map((site) {
                                      final techniciensSite =
                                          PersonnelUtils.getTechniciensBySite(
                                              site);
                                      return DropdownMenuItem(
                                        value: site,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              site,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              'Site (${techniciensSite.length} technicien(s))',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    // Mielleries dynamiques
                                    ..._mielleriesDisponibles.map((miellerie) {
                                      return DropdownMenuItem(
                                        value: miellerie,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              miellerie,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              'Miellerie ajoutée',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      Colors.indigo.shade600),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                  selectedItemBuilder: (context) {
                                    final options = <String>[
                                      ..._sitesDisponibles,
                                      ..._mielleriesDisponibles,
                                    ];
                                    return options
                                        .map((v) => Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                v,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ))
                                        .toList();
                                  },
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedSiteMiellerie = value;
                                      _localiteController.text = value ?? '';
                                      if (value != null) {
                                        if (_sitesDisponibles.contains(value)) {
                                          final techniciens = PersonnelUtils
                                              .getTechniciensBySite(value);
                                          if (techniciens.isNotEmpty) {
                                            _repondantController.text =
                                                'Responsable $value';
                                          }
                                        } else {
                                          _repondantController.text =
                                              'Responsable $value';
                                        }
                                      }
                                    });
                                  },
                                  validator: (value) => value == null
                                      ? 'Sélectionnez une miellerie'
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _ouvrirModalAjoutMiellerie,
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Ajouter une miellerie'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo.shade50,
                                      foregroundColor: Colors.indigo.shade700,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );

                            final coopField = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<String>(
                                  value: _cooperatives.any((c) =>
                                          c['id'] == _selectedCooperativeId)
                                      ? _selectedCooperativeId
                                      : null,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Coopérative *',
                                    hintText: 'Sélectionner une coopérative',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.groups),
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.always,
                                  ),
                                  items: _cooperatives.map((coop) {
                                    return DropdownMenuItem<String>(
                                      value: coop['id'] as String,
                                      child: Text(coop['nom'] ?? ''),
                                    );
                                  }).toList(),
                                  onChanged: (id) {
                                    setState(() => _selectedCooperativeId = id);
                                  },
                                  validator: (value) => value == null
                                      ? 'Sélectionnez une coopérative'
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final created =
                                          await showDialog<ScoopModel>(
                                        context: context,
                                        builder: (ctx) => ModalNouveauScoop(
                                            site: _userSession.site ?? ''),
                                      );
                                      await _loadData();
                                      if (created != null) {
                                        setState(() => _selectedCooperativeId =
                                            created.id);
                                      }
                                      Get.snackbar('Info',
                                          'Liste des coopératives mise à jour');
                                    },
                                    icon: const Icon(Icons.group_add, size: 18),
                                    label:
                                        const Text('Ajouter une coopérative'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo.shade50,
                                      foregroundColor: Colors.indigo.shade700,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );

                            if (isCompact) {
                              return Column(
                                children: [
                                  miellerieField,
                                  const SizedBox(height: 12),
                                  coopField,
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(child: miellerieField),
                                const SizedBox(width: 16),
                                Expanded(child: coopField),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Localité et répondant
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isCompact = constraints.maxWidth < 520;
                            final localite = TextFormField(
                              controller: _localiteController,
                              decoration: const InputDecoration(
                                labelText: 'Localité',
                                hintText:
                                    'Ex: Quartier, Secteur, Nom spécifique',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_on),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                              ),
                            );
                            final repondant = TextFormField(
                              controller: _repondantController,
                              decoration: const InputDecoration(
                                labelText: 'Nom du répondant',
                                hintText: 'Ex: Responsable du site',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.badge),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                              ),
                            );
                            if (isCompact) {
                              return Column(
                                children: [
                                  localite,
                                  const SizedBox(height: 12),
                                  repondant,
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(child: localite),
                                const SizedBox(width: 16),
                                Expanded(child: repondant),
                              ],
                            );
                          },
                        ),

                        _buildSectionTitle('Contenants collectés'),
                        const SizedBox(height: 16),

                        // Formulaire d'ajout SCOOP intégré
                        _buildFormulaireAjoutSCOOP(),

                        const SizedBox(height: 20),

                        // Liste des contenants ajoutés
                        ..._contenants.asMap().entries.map((entry) {
                          final index = entry.key;
                          final contenant = entry.value;
                          return _buildContenantCardSimple(index, contenant);
                        }).toList(),

                        const SizedBox(height: 24),

                        // Observations
                        _buildSectionTitle('Observations'),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _observationsController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Observations et remarques',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.notes),
                            hintText:
                                'Qualité du miel, conditions de collecte, etc.',
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Résumé
                        _buildSummaryCard(),

                        const SizedBox(height: 24),

                        // Bouton enregistrer
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveCollecte,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text('Enregistrer la collecte',
                                    style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // NOUVEAU SYSTÈME SCOOP : Formulaire d'ajout intégré
  Widget _buildFormulaireAjoutSCOOP() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Form(
        key: _contenantFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            LayoutBuilder(
              builder: (context, constraints) {
                final canRow = constraints.maxWidth >= 520;
                // Title widget: only wrap with Expanded in Row layout
                final icon = Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 18),
                );
                if (canRow) {
                  return Row(
                    children: [
                      icon,
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ajouter un contenant',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    icon,
                    const SizedBox(height: 8),
                    const Text(
                      'Ajouter un contenant',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // Type de miel
            _buildTypeMielField(),

            // Section cire conditionnelle
            if (_typeMiel == 'Cire') ...[
              const SizedBox(height: 16),
              _buildTypeCireField(),
              if (_typeCire == 'Purifiée') ...[
                const SizedBox(height: 16),
                _buildCouleurCireField(),
              ],
            ],

            const SizedBox(height: 16),

            // Type de contenant
            _buildTypeContenantField(),

            const SizedBox(height: 16),

            // Poids et prix
            _buildPoidsEtPrixFields(),

            const SizedBox(height: 16),

            // Notes
            _buildNotesField(),

            const SizedBox(height: 16),

            // Aperçu
            _buildPreview(),

            const SizedBox(height: 20),

            // Bouton d'ajout
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveContenantSCOOP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Ajouter le contenant',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeMielField() {
    return DropdownButtonFormField<String>(
      value: _typeMiel,
      decoration: const InputDecoration(
        labelText: 'Type de miel',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.water_drop),
      ),
      items: TypeCollecteMiellerie.typesList.map((type) {
        return DropdownMenuItem(value: type, child: Text(type));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _typeMiel = value!;
          _typeCire = null;
          _couleurCire = null;

          // 🆕 Ajuster automatiquement le type de contenant selon le nouveau type de miel
          final typesDisponibles =
              TypeContenantMiellerie.getTypesForMiel(_typeMiel);
          if (!typesDisponibles.contains(_typeContenant)) {
            _typeContenant = typesDisponibles.first;
          }
        });
      },
      validator: (value) =>
          value?.isEmpty ?? true ? 'Type de miel requis' : null,
    );
  }

  Widget _buildTypeCireField() {
    return DropdownButtonFormField<String>(
      value: _typeCire,
      decoration: const InputDecoration(
        labelText: 'Type de cire',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
      ),
      items: TypeCireMiellerie.typesList.map((type) {
        return DropdownMenuItem(value: type, child: Text(type));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _typeCire = value;
          _couleurCire = null;
        });
      },
      validator: (value) =>
          value?.isEmpty ?? true ? 'Type de cire requis' : null,
    );
  }

  Widget _buildCouleurCireField() {
    return DropdownButtonFormField<String>(
      value: _couleurCire,
      decoration: const InputDecoration(
        labelText: 'Couleur de la cire',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.palette),
      ),
      items: CouleurCireMiellerie.typesList.map((couleur) {
        return DropdownMenuItem(value: couleur, child: Text(couleur));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _couleurCire = value;
        });
      },
      validator: (value) =>
          value?.isEmpty ?? true ? 'Couleur de cire requise' : null,
    );
  }

  Widget _buildTypeContenantField() {
    // 🆕 Obtenir les types de contenants disponibles selon le type de miel
    final typesDisponibles = TypeContenantMiellerie.getTypesForMiel(_typeMiel);

    // 🆕 Vérifier si le type actuel est encore valide, sinon prendre le premier disponible
    if (!typesDisponibles.contains(_typeContenant)) {
      _typeContenant = typesDisponibles.first;
    }

    return DropdownButtonFormField<String>(
      value: _typeContenant,
      decoration: const InputDecoration(
        labelText: 'Type de contenant',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.inventory),
      ),
      items: typesDisponibles.map((type) {
        return DropdownMenuItem(value: type, child: Text(type));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _typeContenant = value!;
        });
      },
      validator: (value) =>
          value?.isEmpty ?? true ? 'Type de contenant requis' : null,
    );
  }

  Widget _buildPoidsEtPrixFields() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;
        final poids = TextFormField(
          controller: _poidsController,
          decoration: const InputDecoration(
            labelText: 'Poids (kg)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.scale),
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
          ],
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Poids requis';
            final poids = double.tryParse(value!);
            if (poids == null || poids <= 0) return 'Poids invalide';
            return null;
          },
          onChanged: (value) => setState(() {}),
        );
        final prix = TextFormField(
          controller: _prixController,
          decoration: const InputDecoration(
            labelText: 'Prix unitaire (CFA)',
            border: OutlineInputBorder(),
            prefixIcon: SimpleMoneyIcon(),
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
          ],
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Prix requis';
            final prix = double.tryParse(value!);
            if (prix == null || prix <= 0) return 'Prix invalide';
            return null;
          },
          onChanged: (value) => setState(() {}),
        );
        if (isCompact) {
          return Column(
            children: [
              poids,
              const SizedBox(height: 12),
              prix,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: poids),
            const SizedBox(width: 16),
            Expanded(child: prix),
          ],
        );
      },
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notes (optionnel)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.notes),
        hintText: 'Qualité, observations...',
      ),
      maxLines: 2,
    );
  }

  Widget _buildPreview() {
    final poids = double.tryParse(_poidsController.text) ?? 0.0;
    final prix = double.tryParse(_prixController.text) ?? 0.0;
    final montant = poids * prix;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility, color: Colors.indigo, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Aperçu du contenant',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Chip(
                label: Text(_typeMiel),
                backgroundColor: Colors.orange.shade100,
              ),
              if (_typeCire != null)
                Chip(
                  label: Text(_typeCire!),
                  backgroundColor: Colors.brown.shade100,
                ),
              if (_couleurCire != null)
                Chip(
                  label: Text(_couleurCire!),
                  backgroundColor: Colors.amber.shade100,
                ),
              Chip(
                label: Text(_typeContenant),
                backgroundColor: Colors.blue.shade100,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Montant: ${montant.toStringAsFixed(2)} CFA',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContenantCardSimple(
      int index, ContenantMiellerieModel contenant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Contenant ${index + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _removeContenant(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  label: Text(contenant.typeCollecte),
                  backgroundColor: Colors.orange.shade100,
                ),
                if (contenant.typeCire != null)
                  Chip(
                    label: Text(contenant.typeCire!),
                    backgroundColor: Colors.brown.shade100,
                  ),
                if (contenant.couleurCire != null)
                  Chip(
                    label: Text(contenant.couleurCire!),
                    backgroundColor: Colors.amber.shade100,
                  ),
                Chip(
                  label: Text(contenant.typeContenant),
                  backgroundColor: Colors.blue.shade100,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text('Poids: ${contenant.quantite} kg'),
                ),
                Expanded(
                  child: Text('Prix: ${contenant.prixUnitaire} CFA/kg'),
                ),
                Expanded(
                  child: Text(
                    'Total: ${contenant.montantTotal.toStringAsFixed(2)} CFA',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (contenant.notes?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${contenant.notes!}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.indigo.shade800,
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      color: Colors.indigo.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Résumé de la collecte',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Poids total: ${_poidsTotal.toStringAsFixed(2)} kg'),
                      Text(
                          'Montant total: ${_montantTotal.toStringAsFixed(2)} CFA'),
                      Text('Nombre de contenants: ${_contenants.length}'),
                    ],
                  ),
                ),
                if (_selectedSiteMiellerie != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Miellerie (Site): $_selectedSiteMiellerie'),
                        Text(
                            'Coopérative: ${(_cooperatives.firstWhereOrNull((c) => c['id'] == _selectedCooperativeId)?['nom']) ?? ''}'),
                        Text('Localité: ${_localiteController.text}'),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Génère les IDs universels pour les contenants Miellerie
  Future<List<ContenantMiellerieModel>> _genererIdsUniversels(
    List<ContenantMiellerieModel> contenants,
  ) async {
    try {
      final universalService = UniversalContainerIdService();

      // Récupérer les informations nécessaires pour les Mielleries
      final miellerieNom = _selectedSiteMiellerie ?? 'MIELLERIE_INCONNUE';
      final technicien = _selectedCollecteur?.nomComplet ??
          _userSession.nom ??
          'TECHNICIEN_INCONNU';
      final village = _localiteController.text.isNotEmpty
          ? _localiteController.text
          : (_selectedSiteMiellerie ?? 'VILLAGE_INCONNU');

      // Pour les Mielleries, on utilise le nom de la miellerie comme "producteur"
      final producteur = miellerieNom;

      // Date de la collecte
      final dateCollecte = _dateCollecte;

      // Générer les IDs universels
      final containerIds = await universalService.generateCollecteContainerIds(
        type: CollecteType.miellerie,
        village: village,
        technicien: technicien,
        producteur: producteur,
        dateCollecte: dateCollecte,
        nombreContenants: contenants.length,
      );

      // Créer la liste des contenants avec les nouveaux IDs
      final List<ContenantMiellerieModel> contenantsAvecIds = [];

      for (int i = 0; i < contenants.length; i++) {
        final contenant = contenants[i];
        final nouvelId = containerIds[i];

        // Créer un nouveau contenant avec l'ID universel
        final nouveauContenant = contenant.copyWith(id: nouvelId);
        contenantsAvecIds.add(nouveauContenant);
      }

      print(
          '✅ MIELLERIE: IDs universels générés pour ${contenants.length} contenants');
      print('   🏭 Miellerie: $miellerieNom');
      print('   📍 Village: $village');
      print('   👨‍💼 Technicien: $technicien');
      print(
          '   📅 Date: ${dateCollecte.day}/${dateCollecte.month}/${dateCollecte.year}');

      for (final id in containerIds) {
        print('   📦 $id');
      }

      return contenantsAvecIds;
    } catch (e) {
      print('❌ MIELLERIE: Erreur génération IDs universels: $e');

      // Fallback vers l'ancien système en cas d'erreur
      final List<ContenantMiellerieModel> contenantsFallback = [];

      for (int i = 0; i < contenants.length; i++) {
        final contenant = contenants[i];
        final fallbackId =
            'C${(i + 1).toString().padLeft(4, '0')}_miellerie_fallback_${DateTime.now().millisecondsSinceEpoch}';

        final nouveauContenant = contenant.copyWith(id: fallbackId);
        contenantsFallback.add(nouveauContenant);
      }

      return contenantsFallback;
    }
  }
}
