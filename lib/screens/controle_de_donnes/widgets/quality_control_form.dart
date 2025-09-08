// Formulaire de contrôle qualité du miel
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/quality_control_models.dart';
import '../models/collecte_models.dart';
import '../utils/formatters.dart';
import '../services/quality_control_service.dart';
import '../../filtrage/widgets/visual_container_id_widget.dart';
import '../../../services/universal_container_id_service.dart';

class QualityControlForm extends StatefulWidget {
  final BaseCollecte collecteItem;
  final String containerCode;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final QualityControlData? existingData;

  const QualityControlForm({
    super.key,
    required this.collecteItem,
    required this.containerCode,
    required this.onSave,
    required this.onCancel,
    this.existingData,
  });

  @override
  State<QualityControlForm> createState() => _QualityControlFormState();
}

class _QualityControlFormState extends State<QualityControlForm> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controllers pour les champs de texte
  late final TextEditingController _producerController;
  late final TextEditingController _villageController;
  late final TextEditingController _hiveTypeController;
  late final TextEditingController _containerTypeController;
  late final TextEditingController _containerNumberController;
  late final TextEditingController _totalWeightController;
  late final TextEditingController _honeyWeightController;
  late final TextEditingController _qualityController;
  late final TextEditingController _waterContentController;
  late final TextEditingController _floralPredominanceController;
  late final TextEditingController _nonConformityCauseController;
  late final TextEditingController _observationsController;
  late final TextEditingController _controllerNameController;

  // Variables d'état
  DateTime _receptionDate = DateTime.now();
  DateTime? _collectionStartDate;
  DateTime? _collectionEndDate;
  HoneyNature _honeyNature = HoneyNature.brut;
  ConformityStatus _conformityStatus = ConformityStatus.conforme;

  // Nouveau système d'ID universel
  String _validatedContainerId = '';
  List<ContainerMatchResult> _possibleMatches = [];

  // Variables pour le widget avancé
  String _containerNature = '';
  String _numeroCode = '';
  bool _isContainerValid = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadExistingData();
  }

  void _initializeControllers() {
    _producerController = TextEditingController();
    _villageController = TextEditingController();
    _hiveTypeController = TextEditingController();
    _containerTypeController = TextEditingController();
    _containerNumberController = TextEditingController();
    _totalWeightController = TextEditingController();
    _honeyWeightController = TextEditingController();
    _qualityController = TextEditingController();
    _waterContentController = TextEditingController();
    _floralPredominanceController = TextEditingController();
    _nonConformityCauseController = TextEditingController();
    _observationsController = TextEditingController();
    _controllerNameController = TextEditingController();
  }

  void _loadExistingData() {
    if (widget.existingData != null) {
      final data = widget.existingData!;
      _producerController.text = data.producer;
      _villageController.text = data.apiaryVillage;
      _hiveTypeController.text = data.hiveType;
      _containerTypeController.text = data.containerType;
      _containerNumberController.text = data.containerNumber;
      _totalWeightController.text = data.totalWeight.toString();
      _honeyWeightController.text = data.honeyWeight.toString();
      _qualityController.text = data.quality;
      _waterContentController.text = data.waterContent?.toString() ?? '';
      _floralPredominanceController.text = data.floralPredominance;
      _nonConformityCauseController.text = data.nonConformityCause ?? '';
      _observationsController.text = data.observations ?? '';
      _controllerNameController.text = data.controllerName ?? '';

      _receptionDate = data.receptionDate;
      _collectionStartDate = data.collectionStartDate;
      _collectionEndDate = data.collectionEndDate;
      _honeyNature = data.honeyNature;
      _conformityStatus = data.conformityStatus;
    } else {
      // Pré-remplir avec les données de la collecte
      _producerController.text = widget.collecteItem.technicien ?? '';
      _villageController.text = widget.collecteItem.site;
      _containerNumberController.text = widget.containerCode;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _producerController.dispose();
    _villageController.dispose();
    _hiveTypeController.dispose();
    _containerTypeController.dispose();
    _containerNumberController.dispose();
    _totalWeightController.dispose();
    _honeyWeightController.dispose();
    _qualityController.dispose();
    _waterContentController.dispose();
    _floralPredominanceController.dispose();
    _nonConformityCauseController.dispose();
    _observationsController.dispose();
    _controllerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final isVerySmall = screenSize.width < 360;

    return Container(
      height: screenSize.height * 0.95,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Poignée et header
          _buildHeader(context, theme, isMobile, isVerySmall),

          // Corps du formulaire
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormFields(context, theme, isMobile, isVerySmall),
                  ],
                ),
              ),
            ),
          ),

          // Footer avec actions
          _buildFooter(context, theme, isMobile),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, ThemeData theme, bool isMobile, bool isVerySmall) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Poignée pour indiquer qu'on peut glisser
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.fact_check,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: isMobile ? 20 : 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contrôle Qualité',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 18 : 22,
                      ),
                    ),
                    Text(
                      'Contenant ${widget.containerCode}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: isMobile ? 13 : 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields(
      BuildContext context, ThemeData theme, bool isMobile, bool isVerySmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 1: Informations générales
        _buildSection(
          context,
          'Informations générales',
          Icons.info_outline,
          [
            _buildDateField(
              'Date de réception',
              _receptionDate,
              (date) => setState(() => _receptionDate = date),
              isMobile,
            ),
            const SizedBox(height: 16),
            if (isMobile && isVerySmall) ...[
              _buildTextField(
                'Producteur ou groupement',
                _producerController,
                'Nom du producteur',
                isMobile,
                isRequired: true,
                isReadOnly:
                    true, // 🔒 Verrouillé - auto-rempli depuis les données de collecte
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Village apicole',
                _villageController,
                'Nom du village',
                isMobile,
                isRequired: true,
                isReadOnly:
                    true, // 🔒 Verrouillé - auto-rempli depuis les données de collecte
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Producteur ou groupement',
                      _producerController,
                      'Nom du producteur',
                      isMobile,
                      isRequired: true,
                      isReadOnly:
                          true, // 🔒 Verrouillé - auto-rempli depuis les données de collecte
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      'Village apicole',
                      _villageController,
                      'Nom du village',
                      isMobile,
                      isRequired: true,
                      isReadOnly:
                          true, // 🔒 Verrouillé - auto-rempli depuis les données de collecte
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _buildTextField(
              'Type de ruche',
              _hiveTypeController,
              'Ex: Langstroth, Kenyane...',
              isMobile,
              isRequired: true,
            ),
          ],
          isMobile,
        ),

        const SizedBox(height: 24),

        // Section 1.5: Identification VISUELLE du contenant (AMÉLIORÉ)
        VisualContainerIdWidget(
          onContainerChanged:
              (containerId, containerNature, numeroCode, isValid) {
            setState(() {
              _validatedContainerId = containerId;
              _containerNature = containerNature;
              _numeroCode = numeroCode;
              _isContainerValid = isValid;

              // Auto-remplir seulement le numéro code (synchronisé)
              _containerNumberController.text = numeroCode;

              // Le champ "Contenant du miel" reste libre à la saisie utilisateur
            });
          },
          initialContainerId:
              widget.containerCode.isNotEmpty ? widget.containerCode : null,
        ),

        const SizedBox(height: 24),

        // Section 2: Période de collecte
        _buildSection(
          context,
          'Période de collecte',
          Icons.date_range,
          [
            if (isMobile && isVerySmall) ...[
              _buildDateField(
                'Du',
                _collectionStartDate,
                (date) => setState(() => _collectionStartDate = date),
                isMobile,
                isOptional: true,
              ),
              const SizedBox(height: 16),
              _buildDateField(
                'Au',
                _collectionEndDate,
                (date) => setState(() => _collectionEndDate = date),
                isMobile,
                isOptional: true,
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      'Du',
                      _collectionStartDate,
                      (date) => setState(() => _collectionStartDate = date),
                      isMobile,
                      isOptional: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateField(
                      'Au',
                      _collectionEndDate,
                      (date) => setState(() => _collectionEndDate = date),
                      isMobile,
                      isOptional: true,
                    ),
                  ),
                ],
              ),
            ],
          ],
          isMobile,
        ),

        const SizedBox(height: 24),

        // Section 3: Nature et contenant
        _buildSection(
          context,
          'Nature et contenant',
          Icons.inventory_2,
          [
            _buildHoneyNatureSelector(theme, isMobile),
            const SizedBox(height: 16),
            // ⚠️ MISE À JOUR: Champs synchronisés automatiquement avec l'ID ci-dessus
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.orange.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seul le champ "Numéro (code)" est automatiquement synchronisé avec '
                      'l\'identifiant du contenant. Le champ "Contenant du miel" est libre à votre saisie.',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Affichage informatif des valeurs extraites (utilise les variables)
            if (_containerNature.isNotEmpty || _numeroCode.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  'Valeurs extraites: ${_containerNature.isNotEmpty ? "Nature: $_containerNature" : ""}'
                  '${_numeroCode.isNotEmpty ? " | Code: $_numeroCode" : ""}',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (isMobile && isVerySmall) ...[
              _buildTextField(
                'Contenant du miel',
                _containerTypeController,
                'Type de contenant',
                isMobile,
                isRequired: true,
                isReadOnly:
                    false, // ✏️ Modifiable à la demande de l'utilisateur
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Numéro (code) *',
                _containerNumberController,
                'Code du contenant (synchronisé)',
                isMobile,
                isRequired: true,
                isReadOnly: true, // 🔒 Verrouillé - synchronisé avec l'ID
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Contenant du miel',
                      _containerTypeController,
                      'Type de contenant',
                      isMobile,
                      isRequired: true,
                      isReadOnly:
                          false, // ✏️ Modifiable à la demande de l'utilisateur
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      'Numéro (code) *',
                      _containerNumberController,
                      'Code du contenant (synchronisé)',
                      isMobile,
                      isRequired: true,
                      isReadOnly: true, // 🔒 Verrouillé - synchronisé avec l'ID
                    ),
                  ),
                ],
              ),
            ],
          ],
          isMobile,
        ),

        const SizedBox(height: 24),

        // Section 4: Poids et mesures
        _buildSection(
          context,
          'Poids et mesures',
          Icons.scale,
          [
            if (isMobile && isVerySmall) ...[
              _buildNumberField(
                'Poids de l\'ensemble (miel + contenant)',
                _totalWeightController,
                'kg',
                isMobile,
                isRequired: true,
              ),
              const SizedBox(height: 16),
              _buildNumberField(
                'Poids du miel',
                _honeyWeightController,
                'kg',
                isMobile,
                isRequired: true,
              ),
              const SizedBox(height: 16),
              _buildNumberField(
                'Teneur en eau',
                _waterContentController,
                '%',
                isMobile,
                isOptional: true,
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                      'Poids de l\'ensemble',
                      _totalWeightController,
                      'kg',
                      isMobile,
                      isRequired: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildNumberField(
                      'Poids du miel',
                      _honeyWeightController,
                      'kg',
                      isMobile,
                      isRequired: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildNumberField(
                'Teneur en eau',
                _waterContentController,
                '%',
                isMobile,
                isOptional: true,
              ),
            ],
          ],
          isMobile,
        ),

        const SizedBox(height: 24),

        // Section 5: Qualité
        _buildSection(
          context,
          'Qualité et conformité',
          Icons.verified,
          [
            _buildTextField(
              'Qualité',
              _qualityController,
              'Description de la qualité',
              isMobile,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Prédominance florale',
              _floralPredominanceController,
              'Ex: Acacia, Tournesol...',
              isMobile,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            _buildConformitySelector(theme, isMobile),
            const SizedBox(height: 16),
            if (_conformityStatus == ConformityStatus.nonConforme) ...[
              _buildTextField(
                'Cause de la non-conformité',
                _nonConformityCauseController,
                'Précisez la cause',
                isMobile,
                isRequired: true,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
            ],
          ],
          isMobile,
        ),

        const SizedBox(height: 24),

        // Section 6: Observations
        _buildSection(
          context,
          'Observations',
          Icons.notes,
          [
            _buildTextField(
              'Observations / Actions',
              _observationsController,
              'Notes additionnelles...',
              isMobile,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Nom du contrôleur',
              _controllerNameController,
              'Votre nom',
              isMobile,
              isRequired: true,
            ),
          ],
          isMobile,
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
    bool isMobile,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: isMobile ? 18 : 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint,
    bool isMobile, {
    bool isRequired = false,
    bool isOptional = false,
    int maxLines = 1,
    bool isReadOnly = false, // 🆕 Nouveau paramètre pour verrouiller les champs
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: isMobile ? 12 : 14,
                ),
            children: [
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              if (isOptional)
                TextSpan(
                  text: ' (optionnel)',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: isMobile ? 10 : 12,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: isReadOnly, // 🆕 Mode lecture seule
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            color: isReadOnly
                ? Colors.grey[600]
                : null, // 🆕 Couleur grisée si verrouillé
          ),
          decoration: InputDecoration(
            hintText: isReadOnly
                ? 'Champ auto-rempli (verrouillé)'
                : hint, // 🆕 Hint adapté
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 16,
            ),
            isDense: isMobile,
            filled: isReadOnly, // 🆕 Fond coloré si verrouillé
            fillColor:
                isReadOnly ? Colors.grey[100] : null, // 🆕 Couleur de fond
            prefixIcon: isReadOnly
                ? Icon(Icons.lock_outline, size: 16, color: Colors.grey[600])
                : null, // 🆕 Icône cadenas
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ce champ est requis';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildNumberField(
    String label,
    TextEditingController controller,
    String unit,
    bool isMobile, {
    bool isRequired = false,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: isMobile ? 12 : 14,
                ),
            children: [
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              if (isOptional)
                TextSpan(
                  text: ' (optionnel)',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: isMobile ? 10 : 12,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(fontSize: isMobile ? 14 : 16),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            suffixText: unit,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 16,
            ),
            isDense: isMobile,
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ce champ est requis';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Valeur numérique invalide';
                  }
                  return null;
                }
              : (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      double.tryParse(value) == null) {
                    return 'Valeur numérique invalide';
                  }
                  return null;
                },
        ),
      ],
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? value,
    ValueChanged<DateTime> onChanged,
    bool isMobile, {
    bool isOptional = false,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: isMobile ? 12 : 14,
            ),
            children: [
              if (isOptional)
                TextSpan(
                  text: ' (optionnel)',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: isMobile ? 10 : 12,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              onChanged(date);
            }
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 16,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null
                        ? Formatters.formatDate(value)
                        : 'Sélectionner une date',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: value != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: isMobile ? 16 : 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHoneyNatureSelector(ThemeData theme, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nature du miel',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: isMobile ? 12 : 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: HoneyNature.values.map((nature) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: RadioListTile<HoneyNature>(
                  title: Text(
                    QualityControlUtils.getHoneyNatureLabel(nature),
                    style: TextStyle(fontSize: isMobile ? 13 : 14),
                  ),
                  value: nature,
                  groupValue: _honeyNature,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _honeyNature = value);
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildConformitySelector(ThemeData theme, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conformité *',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: isMobile ? 12 : 14,
          ),
        ),
        const SizedBox(height: 8),
        ...ConformityStatus.values.map((status) {
          final color = QualityControlUtils.getConformityStatusColor(status);
          final icon = QualityControlUtils.getConformityStatusIcon(status);

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: RadioListTile<ConformityStatus>(
              title: Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 8),
                  Text(
                    QualityControlUtils.getConformityStatusLabel(status),
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              value: status,
              groupValue: _conformityStatus,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _conformityStatus = value);
                }
              },
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, ThemeData theme, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onCancel,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 12 : 16,
                ),
              ),
              child: Text(
                'Annuler',
                style: TextStyle(fontSize: isMobile ? 14 : 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _saveForm,
              icon: const Icon(Icons.save),
              label: Text(
                'Enregistrer le contrôle',
                style: TextStyle(fontSize: isMobile ? 14 : 16),
              ),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 12 : 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      // Validation de l'ID de contenant
      if (_validatedContainerId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Veuillez identifier un contenant valide avant de sauvegarder'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 🆕 Validation obligatoire de l'existence du contenant
      if (!_isContainerValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Le contenant doit être recherché et validé avant l\'enregistrement. '
                    'Cliquez sur "Rechercher le contenant" pour vérifier son existence.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 6),
          ),
        );
        return;
      }

      // ✅ Si on vient d'un autre widget qui fournit des correspondances possibles,
      // vérifier qu'au moins une correspondance est trouvée. Sinon, si la validation
      // visuelle a déjà confirmé le contenant, ne pas bloquer sur une liste vide.
      if (_possibleMatches.isNotEmpty &&
          !_possibleMatches.any((m) => m.found)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Le contenant identifié n\'a pas été trouvé dans les collectes'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_possibleMatches.length > 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Plusieurs contenants correspondent. Veuillez en sélectionner un spécifiquement.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Validation supplémentaire
      if (_conformityStatus == ConformityStatus.nonConforme &&
          _nonConformityCauseController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez préciser la cause de non-conformité'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Créer l'objet de données avec l'ID validé
        final qualityData = QualityControlData(
          containerCode: _validatedContainerId, // 🆕 Utiliser l'ID validé
          receptionDate: _receptionDate,
          producer: _producerController.text.trim(),
          apiaryVillage: _villageController.text.trim(),
          hiveType: _hiveTypeController.text.trim(),
          collectionStartDate: _collectionStartDate,
          collectionEndDate: _collectionEndDate,
          honeyNature: _honeyNature,
          containerType: _containerTypeController.text.trim(),
          containerNumber: _containerNumberController.text.trim(),
          totalWeight: double.parse(_totalWeightController.text),
          honeyWeight: double.parse(_honeyWeightController.text),
          quality: _qualityController.text.trim(),
          waterContent: _waterContentController.text.isNotEmpty
              ? double.parse(_waterContentController.text)
              : null,
          floralPredominance: _floralPredominanceController.text.trim(),
          conformityStatus: _conformityStatus,
          nonConformityCause: _conformityStatus == ConformityStatus.nonConforme
              ? _nonConformityCauseController.text.trim()
              : null,
          observations: _observationsController.text.trim().isNotEmpty
              ? _observationsController.text.trim()
              : null,
          createdAt: DateTime.now(),
          controllerName: _controllerNameController.text.trim(),
        );

        // Sauvegarder avec le service en incluant l'ID de la collecte
        final success = await QualityControlService().saveQualityControl(
          qualityData,
          collecteId: widget.collecteItem.id,
        );

        // Fermer le dialog de chargement
        if (mounted) Navigator.of(context).pop();

        if (success) {
          // Feedback utilisateur de succès
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      QualityControlUtils.getConformityStatusIcon(
                          _conformityStatus),
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Contrôle enregistré avec succès!'),
                          Text(
                            'Statut: ${QualityControlUtils.getConformityStatusLabel(_conformityStatus)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: QualityControlUtils.getConformityStatusColor(
                    _conformityStatus),
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Voir',
                  textColor: Colors.white,
                  onPressed: () {
                    // Optionnel: afficher les détails du contrôle
                  },
                ),
              ),
            );
          }

          widget.onSave();
        } else {
          // Feedback utilisateur d'erreur
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Erreur lors de la sauvegarde'),
                  ],
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        // Fermer le dialog de chargement
        if (mounted) Navigator.of(context).pop();

        // Afficher l'erreur
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Erreur: $e')),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
