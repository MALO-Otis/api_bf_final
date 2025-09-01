import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/miellerie_models.dart';
import '../../../data/services/stats_mielleries_service.dart';
import '../../../data/personnel/personnel_apisavana.dart';
import '../../../authentication/user_session.dart';
import '../historiques_collectes.dart';

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
  Map<String, dynamic>? _selectedCooperative;
  List<ContenantMiellerieModel> _contenants = [];
  bool _isLoading = false;
  TechnicienInfo? _selectedCollecteur;

  // Listes
  List<String> _sitesDisponibles = []; // Sites des techniciens comme mielleries
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

      // Charger les coopératives
      final cooperatives =
          await StatsMielleriesService.loadCooperativesForSite(site);

      setState(() {
        // NOUVEAU : Utiliser les sites des techniciens comme mielleries
        _sitesDisponibles = List.from(sitesApisavana);
        _cooperatives = cooperatives;
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
    final containerId = 'C${(_contenants.length + 1).toString().padLeft(3, '0')}_miellerie';
    
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
    if (_selectedCooperative == null) {
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
        cooperativeId: _selectedCooperative!['id'],
        cooperativeNom: _selectedCooperative!['nom'],
        repondant: _repondantController.text.isNotEmpty
            ? _repondantController.text
            : 'Responsable $_selectedSiteMiellerie!',
        contenants: _contenants,
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
      _selectedCooperative = null;
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
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _selectDate,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Date de collecte',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.calendar_month),
                                  ),
                                  child: Text(
                                    DateFormat('dd/MM/yyyy')
                                        .format(_dateCollecte),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<TechnicienInfo>(
                                value: _selectedCollecteur,
                                decoration: const InputDecoration(
                                  labelText: 'Nom du collecteur',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                ),
                                items: techniciensApisavana.map((technicien) {
                                  return DropdownMenuItem<TechnicienInfo>(
                                    value: technicien,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          technicien.nomComplet,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'Site: ${technicien.site}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (technicien) {
                                  setState(() {
                                    _selectedCollecteur = technicien;
                                  });
                                },
                                validator: (value) =>
                                    value == null ? 'Collecteur requis' : null,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Sélection Miellerie et Coopérative
                        _buildSectionTitle('Miellerie et Coopérative'),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedSiteMiellerie,
                                decoration: const InputDecoration(
                                  labelText:
                                      'Sélectionner une miellerie (site)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.factory),
                                  helperText:
                                      'Les mielleries correspondent aux sites des techniciens',
                                ),
                                items: _sitesDisponibles.map((site) {
                                  final techniciensSite =
                                      PersonnelUtils.getTechniciensBySite(site);
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
                                          '${techniciensSite.length} technicien(s)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (site) {
                                  setState(() {
                                    _selectedSiteMiellerie = site;
                                    // Auto-remplir la localité
                                    _localiteController.text = site ?? '';
                                    // Suggestions de répondant par défaut
                                    if (site != null) {
                                      final techniciens =
                                          PersonnelUtils.getTechniciensBySite(
                                              site);
                                      if (techniciens.isNotEmpty) {
                                        _repondantController.text =
                                            'Responsable $site';
                                      }
                                    }
                                  });
                                },
                                validator: (value) => value == null
                                    ? 'Sélectionnez une miellerie'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child:
                                  DropdownButtonFormField<Map<String, dynamic>>(
                                value: _selectedCooperative,
                                decoration: const InputDecoration(
                                  labelText: 'Sélectionner coopérative',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.groups),
                                ),
                                items: _cooperatives.map((coop) {
                                  return DropdownMenuItem(
                                    value: coop,
                                    child: Text(coop['nom'] ?? ''),
                                  );
                                }).toList(),
                                onChanged: (coop) {
                                  setState(() => _selectedCooperative = coop);
                                },
                                validator: (value) => value == null
                                    ? 'Sélectionnez une coopérative'
                                    : null,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Localité et répondant
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _localiteController,
                                decoration: const InputDecoration(
                                  labelText: 'Localité',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.location_on),
                                  hintText:
                                      'Auto-rempli depuis le site sélectionné',
                                ),
                                validator: (value) => value?.isEmpty ?? true
                                    ? 'Localité requise'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _repondantController,
                                decoration: const InputDecoration(
                                  labelText: 'Nom du répondant',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.contact_phone),
                                ),
                                validator: (value) => value?.isEmpty ?? true
                                    ? 'Répondant requis'
                                    : null,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // NOUVEAU SYSTÈME SCOOP : Contenants avec formulaire intégré
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Ajouter un contenant',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
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
    return DropdownButtonFormField<String>(
      value: _typeContenant,
      decoration: const InputDecoration(
        labelText: 'Type de contenant',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.inventory),
      ),
      items: TypeContenantMiellerie.typesList.map((type) {
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
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _poidsController,
            decoration: const InputDecoration(
              labelText: 'Poids (kg)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.scale),
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
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _prixController,
            decoration: const InputDecoration(
              labelText: 'Prix unitaire (CFA)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
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
          ),
        ),
      ],
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
                            'Coopérative: ${_selectedCooperative?['nom'] ?? ''}'),
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
}
