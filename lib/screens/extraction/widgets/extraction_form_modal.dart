import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../authentication/user_session.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';
import '../models/extraction_models_v2.dart';
import '../services/extraction_service_v2.dart';

/// Modal pour le formulaire d'extraction selon le workflow spécifié
class ExtractionFormModal extends StatefulWidget {
  final List<ProductControle> produitsSelectionnes;
  final VoidCallback? onExtractionComplete;

  const ExtractionFormModal({
    super.key,
    required this.produitsSelectionnes,
    this.onExtractionComplete,
  });

  @override
  State<ExtractionFormModal> createState() => _ExtractionFormModalState();
}

class _ExtractionFormModalState extends State<ExtractionFormModal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ExtractionServiceV2 _extractionService = ExtractionServiceV2();

  // Contrôleurs
  final TextEditingController _quantiteExtraiteController =
      TextEditingController();
  final TextEditingController _observationsController = TextEditingController();

  // Variables du formulaire
  DateTime _dateExtraction = DateTime.now();
  TechnologieExtraction _technologieSelectionnee =
      TechnologieExtraction.manuelle;
  bool _isLoading = false;

  // Calculs automatiques
  double get _poidsTotal =>
      widget.produitsSelectionnes.fold(0.0, (sum, p) => sum + p.poidsTotal);
  double get _quantiteExtraite =>
      double.tryParse(_quantiteExtraiteController.text) ?? 0.0;
  double get _residusRestants => _poidsTotal - _quantiteExtraite;
  double get _rendement =>
      _poidsTotal > 0 ? (_quantiteExtraite / _poidsTotal) * 100 : 0;

  @override
  void initState() {
    super.initState();
    // Pré-remplir avec le poids total comme suggestion
    _quantiteExtraiteController.text = _poidsTotal.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _quantiteExtraiteController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 20),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProduitsSection(),
                      const SizedBox(height: 24),
                      _buildFormSection(),
                      const SizedBox(height: 24),
                      _buildCalculsSection(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.science,
            color: Colors.blue.shade700,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Formulaire d\'Extraction',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              Text(
                'Extraction complète des contenants sélectionnés',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildProduitsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  'Contenants Sélectionnés (${widget.produitsSelectionnes.length})',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: widget.produitsSelectionnes.length,
                itemBuilder: (context, index) {
                  final produit = widget.produitsSelectionnes[index];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.green.shade100,
                      child: Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                    ),
                    title: Text(
                      produit.codeContenant,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle:
                        Text('${produit.producteur} • ${produit.village}'),
                    trailing: Text(
                      '${produit.poidsTotal.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Poids Total à Extraire:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  Text(
                    '${_poidsTotal.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
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

  Widget _buildFormSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Informations d\'Extraction',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date d'extraction
            _buildDateField(),
            const SizedBox(height: 16),

            // Technologie
            _buildTechnologieField(),
            const SizedBox(height: 16),

            // Quantité extraite
            _buildQuantiteExtraiteField(),
            const SizedBox(height: 16),

            // Observations
            _buildObservationsField(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date d\'Extraction *',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                Text(
                  '${_dateExtraction.day.toString().padLeft(2, '0')}/'
                  '${_dateExtraction.month.toString().padLeft(2, '0')}/'
                  '${_dateExtraction.year}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTechnologieField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Technologie Utilisée *',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: TechnologieExtraction.values.map((tech) {
            return Expanded(
              child: RadioListTile<TechnologieExtraction>(
                title: Text(tech.label),
                value: tech,
                groupValue: _technologieSelectionnee,
                onChanged: (value) {
                  setState(() {
                    _technologieSelectionnee = value!;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuantiteExtraiteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quantité Réellement Extraite (kg) *',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _quantiteExtraiteController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixText: 'kg',
            hintText: 'Ex: ${_poidsTotal.toStringAsFixed(1)}',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez saisir la quantité extraite';
            }
            final quantite = double.tryParse(value);
            if (quantite == null || quantite <= 0) {
              return 'Quantité invalide';
            }
            if (quantite > _poidsTotal) {
              return 'Quantité supérieure au poids total disponible';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {}); // Recalculer les résidus
          },
        ),
      ],
    );
  }

  Widget _buildObservationsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Observations',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _observationsController,
          maxLines: 3,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: 'Observations sur le processus d\'extraction...',
          ),
        ),
      ],
    );
  }

  Widget _buildCalculsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate, color: Colors.purple.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Calculs Automatiques',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCalculRow(
              'Poids Total Disponible:',
              '${_poidsTotal.toStringAsFixed(1)} kg',
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildCalculRow(
              'Quantité Extraite:',
              '${_quantiteExtraite.toStringAsFixed(1)} kg',
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildCalculRow(
              'Résidus Restants:',
              '${_residusRestants.toStringAsFixed(1)} kg',
              _residusRestants < 0 ? Colors.red : Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildCalculRow(
              'Rendement d\'Extraction:',
              '${_rendement.toStringAsFixed(1)}%',
              _rendement >= 80
                  ? Colors.green
                  : _rendement >= 60
                      ? Colors.orange
                      : Colors.red,
            ),
            if (_residusRestants < 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Attention: La quantité extraite ne peut pas dépasser le poids total disponible.',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCalculRow(String label, String valeur, Color couleur) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(
          valeur,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: couleur,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed:
              _isLoading || _residusRestants < 0 ? null : _procederExtraction,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Procéder à l\'Extraction'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateExtraction,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _dateExtraction = date;
      });
    }
  }

  Future<void> _procederExtraction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userSession = Get.find<UserSession>();
      final extraction = ExtractionData(
        id: _extractionService.genererIdExtraction(),
        siteExtraction: userSession.site ?? 'SiteInconnu',
        extracteur: userSession.nom ?? 'Extracteur',
        dateExtraction: _dateExtraction,
        technologie: _technologieSelectionnee,
        produitsExtraction: widget.produitsSelectionnes,
        quantiteExtraiteReelle: _quantiteExtraite,
        observations: _observationsController.text.trim().isEmpty
            ? null
            : _observationsController.text.trim(),
      );

      // Valider les données
      if (!_extractionService.validerDonneesExtraction(extraction)) {
        throw Exception('Données d\'extraction invalides');
      }

      // Enregistrer l'extraction
      final succes = await _extractionService.enregistrerExtraction(extraction);

      if (succes) {
        if (mounted) {
          Navigator.of(context).pop();
          widget.onExtractionComplete?.call();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Extraction réalisée avec succès !\n'
                      '${extraction.quantiteExtraiteReelle.toStringAsFixed(1)} kg extraits '
                      '(Rendement: ${extraction.rendementExtraction.toStringAsFixed(1)}%)',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        throw Exception('Échec de l\'enregistrement');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Erreur lors de l\'extraction: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
