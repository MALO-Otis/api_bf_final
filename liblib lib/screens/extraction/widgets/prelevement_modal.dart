/// Modal pour effectuer un prélèvement
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/attributed_product_models.dart';
import '../services/attributed_products_service.dart';

class PrelevementModal extends StatefulWidget {
  final AttributedProduct product;
  final VoidCallback? onPrelevementCreated;

  const PrelevementModal({
    super.key,
    required this.product,
    this.onPrelevementCreated,
  });

  @override
  State<PrelevementModal> createState() => _PrelevementModalState();
}

class _PrelevementModalState extends State<PrelevementModal>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final AttributedProductsService _service = AttributedProductsService();

  // Contrôleurs
  final _poidsController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _humiditeController = TextEditingController();
  final _observationsController = TextEditingController();

  // Variables d'état
  PrelevementType _typePrelevement = PrelevementType.partiel;
  String _methodeExtraction = 'Centrifugation';
  bool _isSubmitting = false;
  double? _poidsCalcule;
  late AnimationController _calculatorController;
  late Animation<double> _calculatorAnimation;

  // Validation en temps réel
  String? _poidsError;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeForm();
  }

  @override
  void dispose() {
    _calculatorController.dispose();
    _poidsController.dispose();
    _temperatureController.dispose();
    _humiditeController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _calculatorController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _calculatorAnimation = CurvedAnimation(
      parent: _calculatorController,
      curve: Curves.easeInOut,
    );
  }

  void _initializeForm() {
    // Initialiser avec la température ambiante
    _temperatureController.text = '25.0';
    _humiditeController.text = '45.0';

    // Écouter les changements de poids
    _poidsController.addListener(_validatePoids);
  }

  void _validatePoids() {
    final text = _poidsController.text;
    if (text.isEmpty) {
      setState(() => _poidsError = null);
      return;
    }

    final poids = double.tryParse(text);
    if (poids == null) {
      setState(() => _poidsError = 'Veuillez entrer un nombre valide');
      return;
    }

    if (poids <= 0) {
      setState(() => _poidsError = 'Le poids doit être positif');
      return;
    }

    if (poids > widget.product.poidsDisponible) {
      setState(() => _poidsError =
          'Poids supérieur au disponible (${widget.product.poidsDisponible.toStringAsFixed(2)} kg)');
      return;
    }

    setState(() {
      _poidsError = null;
      _poidsCalcule = poids;
    });

    // Déterminer automatiquement le type si proche du total
    if (poids >= widget.product.poidsDisponible * 0.95) {
      setState(() => _typePrelevement = PrelevementType.total);
    }
  }

  void _setPrelevementType(PrelevementType type) {
    setState(() {
      _typePrelevement = type;
      if (type == PrelevementType.total) {
        _poidsController.text =
            widget.product.poidsDisponible.toStringAsFixed(2);
      }
    });
  }

  void _showCalculator() {
    _calculatorController.forward();
    showDialog(
      context: context,
      builder: (context) => _CalculatorDialog(
        produit: widget.product,
        onPoidsCalcule: (poids) {
          _poidsController.text = poids.toStringAsFixed(2);
          _calculatorController.reverse();
        },
      ),
    );
  }

  Future<void> _submitPrelevement() async {
    if (!_formKey.currentState!.validate() || _poidsError != null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final poids = double.parse(_poidsController.text);
      final temperature = double.tryParse(_temperatureController.text);
      final humidite = double.tryParse(_humiditeController.text);

      await _service.effectuerPrelevement(
        productId: widget.product.id,
        type: _typePrelevement,
        poidsPreleve: poids,
        extracteur:
            'Utilisateur Connecte', // A remplacer par l'utilisateur reel
        methodeExtraction: _methodeExtraction,
        temperatreExtraction: temperature,
        humiditeRelative: humidite,
        observations: _observationsController.text.trim().isNotEmpty
            ? _observationsController.text.trim()
            : null,
        conditionsExtraction: {
          'equipement': _getEquipmentForMethod(_methodeExtraction),
          'ventilation': 'Bonne',
          'proprete': 'Conforme',
        },
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onPrelevementCreated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Prelevement de ${poids.toStringAsFixed(2)} kg effectue avec succes',
                ),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getEquipmentForMethod(String method) {
    switch (method) {
      case 'Centrifugation':
        return 'Centrifugeuse électrique';
      case 'Décantation':
        return 'Bacs de décantation';
      case 'Pressage':
        return 'Presse hydraulique';
      case 'Filtration':
        return 'Système de filtration';
      default:
        return 'Équipement standard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final isLandscape = screenSize.width > screenSize.height;

    // Calcul adaptatif de la hauteur maximum
    final maxHeightRatio = isLandscape ? 0.95 : 0.9;
    final maxHeight = screenSize.height * maxHeightRatio;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? 400 : 600,
          maxHeight: maxHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: _buildHeader(theme),
            ),

            // Contenu scrollable
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informations du produit
                      _buildProductInfo(theme),

                      const SizedBox(height: 24),

                      // Type de prélèvement
                      _buildTypeSelection(theme),

                      const SizedBox(height: 24),

                      // Poids à prélever
                      _buildPoidsSection(theme),

                      const SizedBox(height: 24),

                      // Méthode d'extraction
                      _buildMethodeSection(theme),

                      const SizedBox(height: 24),

                      // Conditions d'extraction
                      _buildConditionsSection(theme),

                      const SizedBox(height: 24),

                      // Observations
                      _buildObservationsSection(theme),

                      const SizedBox(height: 24),

                      // Résumé
                      _buildSummary(theme),

                      // Espace en bas pour éviter que le contenu soit coupé
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // Actions - fixes en bas, hors du scroll
            Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: _buildActions(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.science,
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nouveau Prélèvement',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Extraction de produit pour traitement',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
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

  Widget _buildProductInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.inventory_2,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Produit à Prélever',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Code contenant', widget.product.codeContenant, theme),
          _buildInfoRow('Producteur', widget.product.producteur, theme),
          _buildInfoRow(
              'Village',
              '${widget.product.village} (${widget.product.siteOrigine})',
              theme),
          _buildInfoRow('Nature', widget.product.nature.label, theme),
          _buildInfoRow('Poids disponible',
              '${widget.product.poidsDisponible.toStringAsFixed(2)} kg', theme,
              bold: true),
          if (widget.product.prelevements.isNotEmpty)
            _buildInfoRow('Prélèvements précédents',
                '${widget.product.prelevements.length}', theme),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de Prélèvement',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: RadioListTile<PrelevementType>(
                title: const Text('Partiel'),
                subtitle: const Text('Une partie du contenant'),
                value: PrelevementType.partiel,
                groupValue: _typePrelevement,
                onChanged: (value) => _setPrelevementType(value!),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<PrelevementType>(
                title: const Text('Total'),
                subtitle: const Text('Tout le contenant'),
                value: PrelevementType.total,
                groupValue: _typePrelevement,
                onChanged: (value) => _setPrelevementType(value!),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPoidsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Poids a Prelever',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            ScaleTransition(
              scale: _calculatorAnimation,
              child: IconButton(
                onPressed: _showCalculator,
                icon: const Icon(Icons.calculate),
                tooltip: 'Calculateur de poids',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _poidsController,
          decoration: InputDecoration(
            labelText: 'Poids (kg)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            suffixText: 'kg',
            errorText: _poidsError,
            helperText:
                'Disponible: ${widget.product.poidsDisponible.toStringAsFixed(2)} kg',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer le poids à prélever';
            }
            return _poidsError; // Utilise la validation en temps réel
          },
        ),

        // Barre de progression visuelle
        if (_poidsCalcule != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progression',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(_poidsCalcule! / widget.product.poidsOriginal * 100).toStringAsFixed(1)}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _poidsCalcule! / widget.product.poidsOriginal,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reste après prélèvement: ${(widget.product.poidsDisponible - _poidsCalcule!).toStringAsFixed(2)} kg',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMethodeSection(ThemeData theme) {
    const methodes = [
      'Centrifugation',
      'Décantation',
      'Pressage',
      'Filtration',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Méthode d\'Extraction',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _methodeExtraction,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: methodes
              .map((methode) => DropdownMenuItem(
                    value: methode,
                    child: Row(
                      children: [
                        Icon(
                          _getMethodIcon(methode),
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(methode),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() => _methodeExtraction = value!);
          },
        ),
      ],
    );
  }

  Widget _buildConditionsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conditions d\'Extraction',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _temperatureController,
                decoration: InputDecoration(
                  labelText: 'Température',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixText: '°C',
                  prefixIcon: const Icon(Icons.thermostat),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final temp = double.tryParse(value);
                    if (temp == null) return 'Température invalide';
                    if (temp < 15 || temp > 45) {
                      return 'Température hors plage (15-45°C)';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _humiditeController,
                decoration: InputDecoration(
                  labelText: 'Humidité',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixText: '%',
                  prefixIcon: const Icon(Icons.water_drop),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final humidity = double.tryParse(value);
                    if (humidity == null) return 'Humidité invalide';
                    if (humidity < 0 || humidity > 100) {
                      return 'Humidité hors plage (0-100%)';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildObservationsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Observations (Optionnel)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _observationsController,
          decoration: InputDecoration(
            hintText: 'Notes sur le prélèvement, qualité observée...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLines: 3,
          maxLength: 200,
        ),
      ],
    );
  }

  Widget _buildSummary(ThemeData theme) {
    if (_poidsCalcule == null) return const SizedBox.shrink();

    final poidsRestant = widget.product.poidsDisponible - _poidsCalcule!;
    final pourcentagePreleve =
        (_poidsCalcule! / widget.product.poidsOriginal) * 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.summarize,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Résumé du Prélèvement',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Poids prélevé',
                  '${_poidsCalcule!.toStringAsFixed(2)} kg',
                  Icons.scale,
                  theme.colorScheme.primary,
                  theme,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Poids restant',
                  '${poidsRestant.toStringAsFixed(2)} kg',
                  Icons.inventory,
                  poidsRestant > 0.01 ? Colors.green : Colors.orange,
                  theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Type',
                  _typePrelevement.label,
                  _typePrelevement == PrelevementType.total
                      ? Icons.select_all
                      : Icons.gradient,
                  theme.colorScheme.secondary,
                  theme,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Progression',
                  '${pourcentagePreleve.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  pourcentagePreleve >= 95
                      ? Colors.green
                      : theme.colorScheme.primary,
                  theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitPrelevement,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.science, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _typePrelevement == PrelevementType.total
                            ? 'Effectuer Prelevement Total'
                            : 'Effectuer Prelevement Partiel',
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  IconData _getMethodIcon(String method) {
    switch (method) {
      case 'Centrifugation':
        return Icons.refresh;
      case 'Décantation':
        return Icons.layers;
      case 'Pressage':
        return Icons.compress;
      case 'Filtration':
        return Icons.filter_alt;
      default:
        return Icons.science;
    }
  }
}

/// Dialog calculatrice pour le poids
class _CalculatorDialog extends StatefulWidget {
  final AttributedProduct produit;
  final Function(double) onPoidsCalcule;

  const _CalculatorDialog({
    required this.produit,
    required this.onPoidsCalcule,
  });

  @override
  State<_CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<_CalculatorDialog> {
  final _pourcentageController = TextEditingController();
  double? _poidsCalcule;

  @override
  void dispose() {
    _pourcentageController.dispose();
    super.dispose();
  }

  void _calculatePoids() {
    final pourcentage = double.tryParse(_pourcentageController.text);
    if (pourcentage != null && pourcentage >= 0 && pourcentage <= 100) {
      setState(() {
        _poidsCalcule = (widget.produit.poidsDisponible * pourcentage) / 100;
      });
    } else {
      setState(() => _poidsCalcule = null);
    }
  }

  void _applyCalculation() {
    if (_poidsCalcule != null) {
      widget.onPoidsCalcule(_poidsCalcule!);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Icon(
                  Icons.calculate,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Calculateur de Poids',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Information du produit
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Poids disponible: ${widget.produit.poidsDisponible.toStringAsFixed(2)} kg',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Calcul par pourcentage
            TextFormField(
              controller: _pourcentageController,
              decoration: InputDecoration(
                labelText: 'Pourcentage à prélever',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixText: '%',
                helperText: 'Entrez un pourcentage entre 0 et 100',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              onChanged: (_) => _calculatePoids(),
            ),

            const SizedBox(height: 16),

            // Boutons de pourcentage rapide
            Wrap(
              spacing: 8,
              children: [25, 50, 75, 100]
                  .map(
                    (percentage) => OutlinedButton(
                      onPressed: () {
                        _pourcentageController.text = percentage.toString();
                        _calculatePoids();
                      },
                      child: Text('$percentage%'),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 16),

            // Résultat
            if (_poidsCalcule != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Poids calculé:',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      '${_poidsCalcule!.toStringAsFixed(2)} kg',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Reste: ${(widget.produit.poidsDisponible - _poidsCalcule!).toStringAsFixed(2)} kg',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyCalculation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Utiliser'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
