import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditAchatScoopPage extends StatefulWidget {
  final String collecteId;
  final String collection;

  const EditAchatScoopPage({
    super.key,
    required this.collecteId,
    required this.collection,
  });

  @override
  State<EditAchatScoopPage> createState() => _EditAchatScoopPageState();
}

class _EditAchatScoopPageState extends State<EditAchatScoopPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers
  final _scoopController = TextEditingController();
  final _periodeController = TextEditingController();
  final _observationsController = TextEditingController();

  // Variables
  DateTime _dateAchat = DateTime.now();
  List<Map<String, dynamic>> _contenants = [];

  @override
  void initState() {
    super.initState();
    _loadCollecteData();
  }

  @override
  void dispose() {
    _scoopController.dispose();
    _periodeController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  Future<void> _loadCollecteData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .doc('${widget.collection}/${widget.collecteId}')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _scoopController.text = data['scoop_nom'] ?? '';
        _periodeController.text = data['periode_collecte'] ?? '';
        _observationsController.text = data['observations'] ?? '';
        _dateAchat =
            (data['date_achat'] as Timestamp?)?.toDate() ?? DateTime.now();
        _contenants = List<Map<String, dynamic>>.from(data['contenants'] ?? []);
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les données: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final data = {
        'scoop_nom': _scoopController.text,
        'periode_collecte': _periodeController.text,
        'date_achat': Timestamp.fromDate(_dateAchat),
        'contenants': _contenants,
        'poids_total': _poidsTotal,
        'montant_total': _montantTotal,
        'observations': _observationsController.text,
        'updated_at': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .doc('${widget.collection}/${widget.collecteId}')
          .update(data);

      Get.snackbar(
        'Succès',
        'Achat SCOOP modifié avec succès',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );

      Get.back();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de la modification: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  double get _poidsTotal {
    return _contenants.fold(0.0, (sum, c) => sum + (c['quantite'] ?? 0.0));
  }

  double get _montantTotal {
    return _contenants.fold(0.0, (sum, c) => sum + (c['montant_total'] ?? 0.0));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Modification achat SCOOP')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.amber.shade50,
      appBar: AppBar(
        title: const Text(
          'Modifier achat SCOOP',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informations SCOOP
                  Text(
                    'Informations SCOOP',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _scoopController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du SCOOP',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Nom requis' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _periodeController,
                    decoration: const InputDecoration(
                      labelText: 'Période de collecte',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Période requise' : null,
                  ),

                  const SizedBox(height: 24),

                  // Résumé
                  Card(
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Résumé',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                              'Poids total: ${_poidsTotal.toStringAsFixed(2)} kg'),
                          Text(
                              'Montant total: ${_montantTotal.toStringAsFixed(2)} CFA'),
                          Text('Nombre de contenants: ${_contenants.length}'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _observationsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observations',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Boutons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isSaving
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text('Enregistrer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
