/// 🟫 MODALES AMÉLIORÉES POUR L'EXTRACTION
///
/// Collection complète de modales pour les interactions d'extraction

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';
import '../models/extraction_models_improved.dart';

/// Modal pour démarrer une extraction améliorée
class StartExtractionModalImproved extends StatefulWidget {
  final ProductControle produit;
  final Function(Map<String, dynamic>) onConfirm;

  const StartExtractionModalImproved({
    Key? key,
    required this.produit,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<StartExtractionModalImproved> createState() =>
      _StartExtractionModalImprovedState();
}

class _StartExtractionModalImprovedState
    extends State<StartExtractionModalImproved> {
  final _formKey = GlobalKey<FormState>();
  final _extracteurController = TextEditingController();
  final _instructionsController = TextEditingController();

  DateTime _dateDebut = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _extracteurController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Row(
              children: [
                Icon(Icons.play_arrow, color: Colors.brown[600], size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Démarrer Extraction',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Produit: ${widget.produit.codeContenant}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Extracteur
                  TextFormField(
                    controller: _extracteurController,
                    decoration: const InputDecoration(
                      labelText: 'Nom de l\'extracteur',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Veuillez saisir le nom de l\'extracteur';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date de début
                  InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date de début',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        '${_dateDebut.day}/${_dateDebut.month}/${_dateDebut.year} ${_dateDebut.hour}:${_dateDebut.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Instructions
                  TextFormField(
                    controller: _instructionsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Instructions spéciales (optionnel)',
                      prefixIcon: Icon(Icons.note),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitForm,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.play_arrow),
                  label: Text(_isSubmitting ? 'Démarrage...' : 'Démarrer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateDebut,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dateDebut),
      );

      if (time != null) {
        setState(() {
          _dateDebut = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await widget.onConfirm({
        'extracteur': _extracteurController.text.trim(),
        'dateDebut': _dateDebut,
        'instructions': _instructionsController.text.trim(),
      });
      Navigator.of(context).pop(true);
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de démarrer l\'extraction: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

/// Modal pour terminer une extraction
class FinishExtractionModalImproved extends StatefulWidget {
  final ExtractionProcess extraction;
  final Function(Map<String, dynamic>) onConfirm;

  const FinishExtractionModalImproved({
    Key? key,
    required this.extraction,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<FinishExtractionModalImproved> createState() =>
      _FinishExtractionModalImprovedState();
}

class _FinishExtractionModalImprovedState
    extends State<FinishExtractionModalImproved> {
  final _formKey = GlobalKey<FormState>();
  final _poidsExtraitController = TextEditingController();
  final _observationsController = TextEditingController();

  String _qualite = 'Excellent';
  bool _isSubmitting = false;

  final List<String> _qualiteOptions = [
    'Excellent',
    'Très Bon',
    'Bon',
    'Acceptable',
    'Médiocre'
  ];

  @override
  void dispose() {
    _poidsExtraitController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duree = widget.extraction.dureeEcoulee;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Terminer Extraction',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Produit: ${widget.extraction.produit.codeContenant}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              'Durée: ${duree.inHours}h ${duree.inMinutes % 60}min',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Poids extrait
                  TextFormField(
                    controller: _poidsExtraitController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Poids extrait (kg)',
                      prefixIcon: const Icon(Icons.scale),
                      border: const OutlineInputBorder(),
                      helperText:
                          'Poids initial: ${widget.extraction.produit.poidsTotal.toStringAsFixed(1)} kg',
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Veuillez saisir le poids extrait';
                      }
                      final poids = double.tryParse(value!);
                      if (poids == null || poids <= 0) {
                        return 'Veuillez saisir un poids valide';
                      }
                      if (poids > widget.extraction.produit.poidsTotal) {
                        return 'Le poids extrait ne peut pas dépasser le poids initial';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Qualité
                  DropdownButtonFormField<String>(
                    value: _qualite,
                    decoration: const InputDecoration(
                      labelText: 'Qualité du résultat',
                      prefixIcon: Icon(Icons.star),
                      border: OutlineInputBorder(),
                    ),
                    items: _qualiteOptions
                        .map((qualite) => DropdownMenuItem(
                              value: qualite,
                              child: Text(qualite),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _qualite = value!),
                  ),
                  const SizedBox(height: 16),

                  // Observations
                  TextFormField(
                    controller: _observationsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observations (optionnel)',
                      prefixIcon: Icon(Icons.note),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Résumé
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Résumé de l\'extraction:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('• Extracteur: ${widget.extraction.extracteur}'),
                  Text(
                      '• Durée totale: ${duree.inHours}h ${duree.inMinutes % 60}min'),
                  if (_poidsExtraitController.text.isNotEmpty)
                    Text(
                        '• Rendement estimé: ${_calculateRendement().toStringAsFixed(1)}%'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitForm,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: Text(_isSubmitting ? 'Finalisation...' : 'Terminer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateRendement() {
    final poidsExtrait = double.tryParse(_poidsExtraitController.text) ?? 0.0;
    final poidsInitial = widget.extraction.produit.poidsTotal;
    return poidsInitial > 0 ? (poidsExtrait / poidsInitial) * 100 : 0.0;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await widget.onConfirm({
        'poidsExtrait': double.parse(_poidsExtraitController.text),
        'qualite': _qualite,
        'observations': _observationsController.text.trim(),
      });
      Navigator.of(context).pop(true);
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de terminer l\'extraction: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

/// Modal pour suspendre une extraction
class SuspendExtractionModal extends StatefulWidget {
  final ExtractionProcess extraction;
  final Function(String) onConfirm;

  const SuspendExtractionModal({
    Key? key,
    required this.extraction,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<SuspendExtractionModal> createState() => _SuspendExtractionModalState();
}

class _SuspendExtractionModalState extends State<SuspendExtractionModal> {
  final _raisonController = TextEditingController();
  String _raisonType = 'Problème technique';
  bool _isSubmitting = false;

  final List<String> _raisonOptions = [
    'Problème technique',
    'Maintenance équipement',
    'Pause déjeuner',
    'Fin de journée',
    'Urgence',
    'Autre'
  ];

  @override
  void dispose() {
    _raisonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Row(
              children: [
                Icon(Icons.pause_circle, color: Colors.orange[600], size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Suspendre Extraction',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Produit: ${widget.extraction.produit.codeContenant}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Type de raison
            DropdownButtonFormField<String>(
              value: _raisonType,
              decoration: const InputDecoration(
                labelText: 'Raison de la suspension',
                prefixIcon: Icon(Icons.info),
                border: OutlineInputBorder(),
              ),
              items: _raisonOptions
                  .map((raison) => DropdownMenuItem(
                        value: raison,
                        child: Text(raison),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _raisonType = value!),
            ),
            const SizedBox(height: 16),

            // Détails
            TextFormField(
              controller: _raisonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Détails (optionnel)',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitForm,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.pause),
                  label: Text(_isSubmitting ? 'Suspension...' : 'Suspendre'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    setState(() => _isSubmitting = true);

    try {
      final raison = _raisonController.text.trim().isNotEmpty
          ? '$_raisonType: ${_raisonController.text.trim()}'
          : _raisonType;

      await widget.onConfirm(raison);
      Navigator.of(context).pop(true);
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de suspendre l\'extraction: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

/// Modal pour l'extraction groupée
class BatchExtractionModal extends StatefulWidget {
  final List<ProductControle> produits;
  final Function(Map<String, dynamic>) onConfirm;

  const BatchExtractionModal({
    Key? key,
    required this.produits,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<BatchExtractionModal> createState() => _BatchExtractionModalState();
}

class _BatchExtractionModalState extends State<BatchExtractionModal> {
  final _extracteurController = TextEditingController();
  final _instructionsController = TextEditingController();
  final Set<String> _selectedProduits = <String>{};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Sélectionner tous les produits par défaut
    _selectedProduits.addAll(widget.produits.map((p) => p.id));
  }

  @override
  void dispose() {
    _extracteurController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Row(
              children: [
                Icon(Icons.playlist_play, color: Colors.brown[600], size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Extraction Groupée',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Extracteur
            TextFormField(
              controller: _extracteurController,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'extracteur',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Instructions
            TextFormField(
              controller: _instructionsController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Instructions générales',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Sélection des produits
            Text(
              'Produits à traiter (${_selectedProduits.length}/${widget.produits.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            // Actions de sélection
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => setState(() {
                    _selectedProduits.addAll(widget.produits.map((p) => p.id));
                  }),
                  icon: const Icon(Icons.select_all),
                  label: const Text('Tout sélectionner'),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _selectedProduits.clear()),
                  icon: const Icon(Icons.deselect),
                  label: const Text('Tout désélectionner'),
                ),
              ],
            ),

            // Liste des produits
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: widget.produits.length,
                  itemBuilder: (context, index) {
                    final produit = widget.produits[index];
                    final isSelected = _selectedProduits.contains(produit.id);

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedProduits.add(produit.id);
                          } else {
                            _selectedProduits.remove(produit.id);
                          }
                        });
                      },
                      title: Text(produit.codeContenant),
                      subtitle: Text(
                          '${produit.producteur} • ${produit.poidsTotal.toStringAsFixed(1)} kg'),
                      secondary: produit.isUrgent
                          ? Icon(Icons.priority_high, color: Colors.red[600])
                          : null,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Résumé
            if (_selectedProduits.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_selectedProduits.length} produit(s) sélectionné(s) • '
                        'Poids total: ${_getTotalWeight().toStringAsFixed(1)} kg',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ||
                          _selectedProduits.isEmpty ||
                          _extracteurController.text.trim().isEmpty
                      ? null
                      : _submitForm,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.play_arrow),
                  label: Text(
                      _isSubmitting ? 'Démarrage...' : 'Démarrer Extraction'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _getTotalWeight() {
    return widget.produits
        .where((p) => _selectedProduits.contains(p.id))
        .fold(0.0, (sum, p) => sum + p.poidsTotal);
  }

  Future<void> _submitForm() async {
    setState(() => _isSubmitting = true);

    try {
      final selectedProducts = widget.produits
          .where((p) => _selectedProduits.contains(p.id))
          .toList();

      await widget.onConfirm({
        'produits': selectedProducts,
        'extracteur': _extracteurController.text.trim(),
        'instructions': _instructionsController.text.trim(),
      });
      Navigator.of(context).pop(true);
    } catch (e) {
      Get.snackbar(
          'Erreur', 'Impossible de démarrer l\'extraction groupée: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

/// Modal simple pour afficher les détails d'un produit
class ProductDetailsModal extends StatelessWidget {
  final ProductControle produit;

  const ProductDetailsModal({
    Key? key,
    required this.produit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Row(
              children: [
                Icon(Icons.info, color: Colors.brown[600], size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Détails du Produit',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Informations détaillées
            _buildDetailRow('Code Contenant', produit.codeContenant),
            _buildDetailRow('Producteur', produit.producteur),
            _buildDetailRow('Village', produit.village),
            _buildDetailRow('Commune', produit.commune),
            _buildDetailRow('Nature', produit.nature.name),
            _buildDetailRow('Type Contenant', produit.typeContenant),
            _buildDetailRow(
                'Poids Total', '${produit.poidsTotal.toStringAsFixed(2)} kg'),
            _buildDetailRow(
                'Poids Miel', '${produit.poidsMiel.toStringAsFixed(2)} kg'),
            _buildDetailRow('Qualité', produit.qualite),
            if (produit.teneurEau != null)
              _buildDetailRow(
                  'Teneur en Eau', '${produit.teneurEau!.toStringAsFixed(1)}%'),
            _buildDetailRow(
                'Prédominance Florale', produit.predominanceFlorale),
            _buildDetailRow('Conforme', produit.estConforme ? 'Oui' : 'Non'),
            if (!produit.estConforme && produit.causeNonConformite != null)
              _buildDetailRow(
                  'Cause Non-Conformité', produit.causeNonConformite!),
            _buildDetailRow('Date de Réception',
                '${produit.dateReception.day}/${produit.dateReception.month}/${produit.dateReception.year}'),
            _buildDetailRow('Date de Contrôle',
                '${produit.dateControle.day}/${produit.dateControle.month}/${produit.dateControle.year}'),
            if (produit.controleur != null)
              _buildDetailRow('Contrôleur', produit.controleur!),
            if (produit.observations != null &&
                produit.observations!.isNotEmpty)
              _buildDetailRow('Observations', produit.observations!),

            const SizedBox(height: 24),

            // Bouton fermer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

/// Modal pour les détails d'un processus d'extraction
class ExtractionProcessDetailsModal extends StatelessWidget {
  final ExtractionProcess extraction;

  const ExtractionProcessDetailsModal({
    Key? key,
    required this.extraction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Colors.orange[600], size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Extraction en Cours',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Code Produit', extraction.produit.codeContenant),
            _buildDetailRow('Extracteur', extraction.extracteur),
            _buildDetailRow('Statut', extraction.statut.label),
            _buildDetailRow('Priorité', extraction.priorite.label),
            _buildDetailRow('Site', extraction.site),
            _buildDetailRow(
                'Début',
                '${extraction.dateDebut.day}/${extraction.dateDebut.month}/${extraction.dateDebut.year} '
                    '${extraction.dateDebut.hour}:${extraction.dateDebut.minute.toString().padLeft(2, '0')}'),
            _buildDetailRow('Durée Écoulée',
                '${extraction.dureeEcoulee.inHours}h ${extraction.dureeEcoulee.inMinutes % 60}min'),
            if (extraction.instructions != null)
              _buildDetailRow('Instructions', extraction.instructions!),
            if (extraction.observations != null)
              _buildDetailRow('Observations', extraction.observations!),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

/// Modal pour les détails d'un résultat d'extraction
class ExtractionResultDetailsModal extends StatelessWidget {
  final ExtractionResult result;

  const ExtractionResultDetailsModal({
    Key? key,
    required this.result,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Résultat d\'Extraction',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Code Produit', result.produit.codeContenant),
            _buildDetailRow('Extracteur', result.extracteur),
            _buildDetailRow('Site', result.site),
            _buildDetailRow('Qualité', result.qualite),
            _buildDetailRow('Poids Initial',
                '${result.poidsInitial.toStringAsFixed(2)} kg'),
            _buildDetailRow('Poids Extrait',
                '${result.poidsExtrait.toStringAsFixed(2)} kg'),
            _buildDetailRow('Rendement',
                '${result.rendement.toStringAsFixed(1)}% (${result.evaluationRendement})'),
            _buildDetailRow(
                'Taux de Perte', '${result.tauxPerte.toStringAsFixed(1)}%'),
            _buildDetailRow('Durée Totale',
                '${result.duree.inHours}h ${result.duree.inMinutes % 60}min'),
            _buildDetailRow(
                'Date Début',
                '${result.dateDebut.day}/${result.dateDebut.month}/${result.dateDebut.year} '
                    '${result.dateDebut.hour}:${result.dateDebut.minute.toString().padLeft(2, '0')}'),
            _buildDetailRow(
                'Date Fin',
                '${result.dateFin.day}/${result.dateFin.month}/${result.dateFin.year} '
                    '${result.dateFin.hour}:${result.dateFin.minute.toString().padLeft(2, '0')}'),
            _buildDetailRow('Validé', result.isValidated ? 'Oui' : 'Non'),
            if (result.observations != null)
              _buildDetailRow('Observations', result.observations!),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

/// Modal pour les statistiques avancées
class AdvancedStatsModal extends StatelessWidget {
  final RxMap<String, dynamic> stats;

  const AdvancedStatsModal({
    Key? key,
    required this.stats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.brown[600], size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Statistiques Avancées',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Obx(() => SingleChildScrollView(
                    child: Column(
                      children: [
                        // Statistiques principales
                        _buildStatsSection('Production', [
                          _buildStatItem('Total Attribués',
                              '${stats['totalAttribues'] ?? 0}'),
                          _buildStatItem(
                              'En Cours', '${stats['enCours'] ?? 0}'),
                          _buildStatItem(
                              'Terminées', '${stats['terminees'] ?? 0}'),
                          _buildStatItem('Urgents', '${stats['urgents'] ?? 0}'),
                        ]),

                        _buildStatsSection('Performance', [
                          _buildStatItem('Poids Total',
                              '${(stats['poidsTotal'] ?? 0.0).toStringAsFixed(1)} kg'),
                          _buildStatItem('Rendement Moyen',
                              '${(stats['rendementMoyen'] ?? 0.0).toStringAsFixed(1)}%'),
                          _buildStatItem('Durée Moyenne',
                              '${stats['dureeMoyenne'] ?? 0} minutes'),
                        ]),
                      ],
                    ),
                  )),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: items),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
