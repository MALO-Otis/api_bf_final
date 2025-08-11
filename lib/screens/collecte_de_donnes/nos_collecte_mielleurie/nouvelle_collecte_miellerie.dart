import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/miellerie_models.dart';
import '../../../data/services/stats_mielleries_service.dart';
import '../../../authentication/user_session.dart';
import '../historiques_collectes.dart';
import 'widgets/modal_nouvelle_miellerie.dart';

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
  MiellerieModel? _selectedMiellerie;
  Map<String, dynamic>? _selectedCooperative;
  List<ContenantMiellerieModel> _contenants = [];
  bool _isLoading = false;

  // Listes
  List<MiellerieModel> _mielleries = [];
  List<Map<String, dynamic>> _cooperatives = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _addContenant();
  }

  @override
  void dispose() {
    _localiteController.dispose();
    _repondantController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final site = _userSession.site ?? '';
      final futures = await Future.wait([
        StatsMielleriesService.loadMielleriesForSite(site),
        StatsMielleriesService.loadCooperativesForSite(site),
      ]);

      setState(() {
        _mielleries = futures[0] as List<MiellerieModel>;
        _cooperatives = futures[1] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors du chargement des données: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addContenant() {
    setState(() {
      _contenants.add(ContenantMiellerieModel(
        typeContenant: TypeContenantMiellerie.bidon.label,
        typeCollecte: TypeCollecteMiellerie.mielFiltre.label,
        quantite: 0.0,
        prixUnitaire: 0.0,
        montantTotal: 0.0,
      ));
    });
  }

  void _removeContenant(int index) {
    if (_contenants.length > 1) {
      setState(() => _contenants.removeAt(index));
    }
  }

  void _updateContenant(int index, ContenantMiellerieModel contenant) {
    setState(() => _contenants[index] = contenant);
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
    if (_selectedMiellerie == null) {
      Get.snackbar('Erreur', 'Sélectionnez une miellerie');
      return;
    }
    if (_selectedCooperative == null) {
      Get.snackbar('Erreur', 'Sélectionnez une coopérative');
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
        collecteurId: _userSession.uid ?? '',
        collecteurNom: _userSession.nom ?? '',
        miellerieId: _selectedMiellerie!.id,
        miellerieNom: _selectedMiellerie!.nom,
        localite: _localiteController.text.isNotEmpty
            ? _localiteController.text
            : _selectedMiellerie!.localite,
        cooperativeId: _selectedCooperative!['id'],
        cooperativeNom: _selectedCooperative!['nom'],
        repondant: _repondantController.text.isNotEmpty
            ? _repondantController.text
            : _selectedMiellerie!.repondant,
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
      _selectedMiellerie = null;
      _selectedCooperative = null;
      _contenants.clear();
      _addContenant();
    });
  }

  void _showCreateMiellerieModal() {
    showDialog(
      context: context,
      builder: (context) => ModalNouvelleMiellerie(
        cooperatives: _cooperatives,
        onMiellerieCreated: (miellerie) {
          setState(() {
            _mielleries.add(miellerie);
            _selectedMiellerie = miellerie;
            _localiteController.text = miellerie.localite;
            _repondantController.text = miellerie.repondant;
            _selectedCooperative = _cooperatives.firstWhereOrNull(
              (coop) => coop['id'] == miellerie.cooperativeId,
            );
          });
        },
      ),
    );
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
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Date de collecte',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          ),
                                          Text(
                                            DateFormat('dd/MM/yyyy')
                                                .format(_dateCollecte),
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: _userSession.nom ?? '',
                                decoration: const InputDecoration(
                                  labelText: 'Nom du collecteur',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                ),
                                readOnly: true,
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
                              child: DropdownButtonFormField<MiellerieModel>(
                                value: _selectedMiellerie,
                                decoration: const InputDecoration(
                                  labelText: 'Sélectionner une miellerie',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.factory),
                                ),
                                items: _mielleries.map((miellerie) {
                                  return DropdownMenuItem(
                                    value: miellerie,
                                    child: Text(miellerie.nom),
                                  );
                                }).toList(),
                                onChanged: (miellerie) {
                                  setState(() {
                                    _selectedMiellerie = miellerie;
                                    // Auto-remplir la localité et le répondant
                                    _localiteController.text =
                                        miellerie?.localite ?? '';
                                    _repondantController.text =
                                        miellerie?.repondant ?? '';
                                    // Auto-sélectionner la coopérative si possible
                                    if (miellerie != null) {
                                      _selectedCooperative =
                                          _cooperatives.firstWhereOrNull(
                                        (coop) =>
                                            coop['id'] ==
                                            miellerie.cooperativeId,
                                      );
                                    }
                                  });
                                },
                                validator: (value) => value == null
                                    ? 'Sélectionnez une miellerie'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Créer une nouvelle miellerie',
                              icon: const Icon(Icons.add_circle,
                                  color: Colors.indigo),
                              onPressed: () => _showCreateMiellerieModal(),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child:
                                  DropdownButtonFormField<Map<String, dynamic>>(
                                value: _selectedCooperative,
                                decoration: const InputDecoration(
                                  labelText: 'Coopérative',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.group),
                                ),
                                items: _cooperatives.map((coop) {
                                  return DropdownMenuItem(
                                    value: coop,
                                    child: Text(coop['nom']),
                                  );
                                }).toList(),
                                onChanged: (coop) =>
                                    setState(() => _selectedCooperative = coop),
                                validator: (value) => value == null
                                    ? 'Sélectionnez une coopérative'
                                    : null,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Localité et Répondant
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _localiteController,
                                decoration: const InputDecoration(
                                  labelText: 'Localité',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.location_on),
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

                        // Contenants
                        _buildSectionTitle('Contenants collectés'),
                        const SizedBox(height: 16),

                        ..._contenants.asMap().entries.map((entry) {
                          final index = entry.key;
                          final contenant = entry.value;
                          return _buildContenantCard(index, contenant);
                        }).toList(),

                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _addContenant,
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter un contenant'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade600,
                            foregroundColor: Colors.white,
                          ),
                        ),

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
                                : const Text(
                                    'Enregistrer la collecte',
                                    style: TextStyle(fontSize: 16),
                                  ),
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

  Widget _buildContenantCard(int index, ContenantMiellerieModel contenant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Contenant ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_contenants.length > 1)
                  IconButton(
                    onPressed: () => _removeContenant(index),
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: contenant.typeContenant,
                    decoration: const InputDecoration(
                      labelText: 'Type contenant',
                      border: OutlineInputBorder(),
                    ),
                    items: TypeContenantMiellerie.typesList.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _updateContenant(
                            index, contenant.copyWith(typeContenant: value));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: contenant.typeCollecte,
                    decoration: const InputDecoration(
                      labelText: 'Type de collecte',
                      border: OutlineInputBorder(),
                    ),
                    items: TypeCollecteMiellerie.typesList.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _updateContenant(
                            index, contenant.copyWith(typeCollecte: value));
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: contenant.quantite.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Quantité (kg)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final qty = double.tryParse(value) ?? 0.0;
                      final newMontant = qty * contenant.prixUnitaire;
                      _updateContenant(
                        index,
                        contenant.copyWith(
                          quantite: qty,
                          montantTotal: newMontant,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: contenant.prixUnitaire.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Prix unitaire (CFA)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final price = double.tryParse(value) ?? 0.0;
                      final newMontant = contenant.quantite * price;
                      _updateContenant(
                        index,
                        contenant.copyWith(
                          prixUnitaire: price,
                          montantTotal: newMontant,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Montant: ${contenant.montantTotal.toStringAsFixed(2)} CFA',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade800,
              ),
            ),
          ],
        ),
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
                if (_selectedMiellerie != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Miellerie: ${_selectedMiellerie!.nom}'),
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
