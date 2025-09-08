/// Modal de formulaire pour le processus de filtrage
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controle_de_donnes/models/attribution_models_v2.dart';
import '../../../services/filtrage_service_complete.dart';

class FiltrageFormModal extends StatefulWidget {
  final List<ProductControle> produitsSelectionnes;
  final VoidCallback onFiltrageComplete;

  const FiltrageFormModal({
    super.key,
    required this.produitsSelectionnes,
    required this.onFiltrageComplete,
  });

  @override
  State<FiltrageFormModal> createState() => _FiltrageFormModalState();
}

class _FiltrageFormModalState extends State<FiltrageFormModal> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs de saisie
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _numeroLotController = TextEditingController();
  final TextEditingController _quantiteFiltrageController =
      TextEditingController();
  final TextEditingController _observationsController = TextEditingController();

  // Variables du formulaire
  String _technologie = 'Manuelle';
  double _quantiteTotale = 0.0;
  double _quantiteFiltree = 0.0;
  double _residusRestants = 0.0;
  double _rendementFiltrage = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _numeroLotController.dispose();
    _quantiteFiltrageController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    // Initialiser la date d'aujourd'hui
    final now = DateTime.now();
    _dateController.text =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    // Générer automatiquement le numéro de lot au format Lot-XXX-XXX
    _numeroLotController.text = _generateLotNumber();

    // Calculer la quantité totale disponible
    _quantiteTotale =
        widget.produitsSelectionnes.fold(0.0, (sum, p) => sum + p.poidsTotal);

    setState(() {});
  }

  /// Génère un numéro de lot au format Lot-XXX-XXX
  String _generateLotNumber() {
    final now = DateTime.now();

    // Utiliser la date et l'heure pour générer des chiffres uniques
    final part1 = now.millisecondsSinceEpoch.toString().substring(7, 10);
    final part2 = (now.millisecond + now.second * 10)
        .toString()
        .padLeft(3, '0')
        .substring(0, 3);

    return 'Lot-$part1-$part2';
  }

  void _calculateResidues() {
    if (_quantiteFiltree > 0 && _quantiteTotale > 0) {
      _residusRestants = _quantiteTotale - _quantiteFiltree;
      _rendementFiltrage = (_quantiteFiltree / _quantiteTotale) * 100;
    } else {
      _residusRestants = _quantiteTotale;
      _rendementFiltrage = 0.0;
    }
    setState(() {});
  }

  Future<void> _processFiltrage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('🔄 [Filtrage] Début du processus de filtrage');

      // Utiliser le numéro de lot du formulaire
      String numeroLot = _numeroLotController.text.trim();

      debugPrint('   📦 Produits: ${widget.produitsSelectionnes.length}');
      debugPrint(
          '   ⚖️ Quantité totale: ${_quantiteTotale.toStringAsFixed(1)} kg');
      debugPrint(
          '   🔍 Quantité filtrée: ${_quantiteFiltree.toStringAsFixed(1)} kg');
      debugPrint('   📊 Rendement: ${_rendementFiltrage.toStringAsFixed(1)}%');
      debugPrint('   🗑️ Résidus: ${_residusRestants.toStringAsFixed(1)} kg');
      debugPrint('   🛠️ Technologie: $_technologie');
      debugPrint('   🏷️ Numéro de lot: $numeroLot');

      // Enregistrer en base de données avec le service complet
      final filtrageService = FiltrageServiceComplete();
      final success = await filtrageService.enregistrerFiltrage(
        produitsSelectionnes: widget.produitsSelectionnes,
        numeroLot: numeroLot,
        dateFiltrage: DateTime.now(),
        technologie: _technologie,
        quantiteTotale: _quantiteTotale,
        quantiteFiltree: _quantiteFiltree,
        residusRestants: _residusRestants,
        rendementFiltrage: _rendementFiltrage,
        observations: _observationsController.text.trim(),
      );

      if (!success) {
        throw Exception('Échec de l\'enregistrement en base de données');
      }

      debugPrint(
          '✅ [Filtrage] Processus terminé avec succès et enregistré en base');

      if (mounted) {
        Navigator.of(context).pop();
        widget.onFiltrageComplete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Filtrage enregistré avec succès !\n${_quantiteFiltree.toStringAsFixed(1)} kg filtrés avec un rendement de ${_rendementFiltrage.toStringAsFixed(1)}%\nLot: $numeroLot',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [Filtrage] Erreur lors de l\'enregistrement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'enregistrement du filtrage: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
            // En-tête
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.filter_alt,
                    color: Colors.purple.shade600,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Processus de Filtrage',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                      Text(
                        '${widget.produitsSelectionnes.length} produits sélectionnés',
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
            ),

            const SizedBox(height: 24),

            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Résumé des produits
                      _buildProductsSummary(theme),

                      const SizedBox(height: 24),

                      // Formulaire de filtrage
                      _buildFiltrageForm(theme),

                      const SizedBox(height: 24),

                      // Calculs automatiques
                      _buildCalculations(theme),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _processFiltrage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.filter_alt, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Lancer le Filtrage',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSummary(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2, color: Colors.purple.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Produits à Filtrer',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Liste des produits
          ...widget.produitsSelectionnes.map((product) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.purple.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${product.codeContenant} - ${product.producteur}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${product.poidsTotal.toStringAsFixed(1)} kg',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.purple.shade600,
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 12),

          // Total
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.scale, color: Colors.purple.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Quantité totale disponible',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_quantiteTotale.toStringAsFixed(1)} kg',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltrageForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paramètres de Filtrage',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        // Date
        TextFormField(
          controller: _dateController,
          decoration: const InputDecoration(
            labelText: 'Date de filtrage',
            prefixIcon: Icon(Icons.calendar_today),
            border: OutlineInputBorder(),
          ),
          readOnly: true,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now().add(const Duration(days: 7)),
            );
            if (date != null) {
              _dateController.text =
                  '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez sélectionner une date';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Numéro de lot
        TextFormField(
          controller: _numeroLotController,
          decoration: InputDecoration(
            labelText: 'Numéro de lot',
            prefixIcon: const Icon(Icons.qr_code_2),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _numeroLotController.text = _generateLotNumber();
              },
              tooltip: 'Générer un nouveau numéro',
            ),
            helperText: 'Format: Lot-XXX-XXX (généré automatiquement)',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Le numéro de lot est requis';
            }
            if (!RegExp(r'^Lot-\d{3}-\d{3}$').hasMatch(value)) {
              return 'Format invalide (attendu: Lot-XXX-XXX)';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Technologie
        DropdownButtonFormField<String>(
          value: _technologie,
          decoration: const InputDecoration(
            labelText: 'Technologie utilisée',
            prefixIcon: Icon(Icons.build),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Manuelle', child: Text('Filtrage Manuel')),
            DropdownMenuItem(value: 'Machine', child: Text('Filtrage Machine')),
            DropdownMenuItem(value: 'Mixte', child: Text('Filtrage Mixte')),
          ],
          onChanged: (value) {
            setState(() => _technologie = value!);
          },
        ),

        const SizedBox(height: 16),

        // Quantité filtrée
        TextFormField(
          controller: _quantiteFiltrageController,
          decoration: InputDecoration(
            labelText: 'Quantité réellement filtrée (kg)',
            prefixIcon: const Icon(Icons.filter_alt),
            border: const OutlineInputBorder(),
            suffixText: 'kg',
            helperText:
                'Max: ${_quantiteTotale.toStringAsFixed(1)} kg disponibles',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          onChanged: (value) {
            final quantite = double.tryParse(value) ?? 0.0;
            setState(() {
              _quantiteFiltree = quantite;
              _calculateResidues();
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez saisir la quantité filtrée';
            }
            final quantite = double.tryParse(value);
            if (quantite == null || quantite <= 0) {
              return 'Quantité invalide';
            }
            if (quantite > _quantiteTotale) {
              return 'Quantité supérieure au disponible';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Observations
        TextFormField(
          controller: _observationsController,
          decoration: const InputDecoration(
            labelText: 'Observations (optionnel)',
            prefixIcon: Icon(Icons.notes),
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          maxLength: 200,
        ),
      ],
    );
  }

  Widget _buildCalculations(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate, color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Calculs Automatiques',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Résidus
          Row(
            children: [
              Icon(Icons.delete_outline,
                  color: Colors.orange.shade600, size: 18),
              const SizedBox(width: 8),
              Text(
                'Résidus restants:',
                style: theme.textTheme.bodyMedium,
              ),
              const Spacer(),
              Text(
                '${_residusRestants.toStringAsFixed(1)} kg',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Rendement
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: _rendementFiltrage >= 70
                    ? Colors.green.shade600
                    : Colors.orange.shade600,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Rendement de filtrage:',
                style: theme.textTheme.bodyMedium,
              ),
              const Spacer(),
              Text(
                '${_rendementFiltrage.toStringAsFixed(1)}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _rendementFiltrage >= 70
                      ? Colors.green.shade600
                      : Colors.orange.shade600,
                ),
              ),
            ],
          ),

          if (_rendementFiltrage > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _rendementFiltrage >= 70
                    ? Colors.green.shade100
                    : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _rendementFiltrage >= 70
                        ? Icons.check_circle
                        : Icons.warning,
                    color: _rendementFiltrage >= 70
                        ? Colors.green.shade600
                        : Colors.orange.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _rendementFiltrage >= 70
                          ? 'Excellent rendement de filtrage !'
                          : 'Rendement faible, vérifiez le processus',
                      style: TextStyle(
                        fontSize: 12,
                        color: _rendementFiltrage >= 70
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
