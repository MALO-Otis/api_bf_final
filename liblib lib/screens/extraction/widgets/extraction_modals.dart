import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/extraction_models.dart';

/// Modal pour démarrer une extraction
class StartExtractionModal extends StatefulWidget {
  final ExtractionProduct product;
  final VoidCallback onCancel;
  final Function(Map<String, dynamic>) onConfirm;

  const StartExtractionModal({
    super.key,
    required this.product,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  State<StartExtractionModal> createState() => _StartExtractionModalState();
}

class _StartExtractionModalState extends State<StartExtractionModal> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _tempController = TextEditingController();
  final _humidityController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialiser avec la date/heure actuelles
    final now = DateTime.now();
    _dateController.text =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _timeController.text =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _tempController.dispose();
    _humidityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      _dateController.text =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  void _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      _timeController.text =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  void _handleConfirm() {
    if (_formKey.currentState!.validate()) {
      final data = {
        'date': _dateController.text,
        'time': _timeController.text,
        'temperature': _tempController.text,
        'humidity': _humidityController.text,
        'notes': _notesController.text,
      };
      widget.onConfirm(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: isMobile ? double.infinity : 500,
        margin: EdgeInsets.all(isMobile ? 16 : 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Démarrage d\'Extraction',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Contenu
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informations du produit
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.science, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Produit: ',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    widget.product.nom,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.monitor_weight, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Poids: ',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${widget.product.poidsTotal} kg (${widget.product.quantiteContenants} contenants)',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Formulaire
                      if (isMobile) ...[
                        // Layout mobile (vertical)
                        _buildDateTimeFieldsMobile(theme),
                        const SizedBox(height: 16),
                        _buildEnvironmentFieldsMobile(theme),
                      ] else ...[
                        // Layout desktop (horizontal)
                        _buildDateTimeFieldsDesktop(theme),
                        const SizedBox(height: 16),
                        _buildEnvironmentFieldsDesktop(theme),
                      ],

                      const SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: 'Notes',
                          hintText: 'Ajoutez des notes...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.note_add),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer avec boutons
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onCancel,
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _handleConfirm,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Démarrer l\'Extraction'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
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

  Widget _buildDateTimeFieldsMobile(ThemeData theme) {
    return Column(
      children: [
        TextFormField(
          controller: _dateController,
          decoration: InputDecoration(
            labelText: 'Date début',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.calendar_today),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: _selectDate,
            ),
          ),
          readOnly: true,
          validator: (value) => value?.isEmpty == true ? 'Date requise' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _timeController,
          decoration: InputDecoration(
            labelText: 'Heure début',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.access_time),
            suffixIcon: IconButton(
              icon: const Icon(Icons.schedule),
              onPressed: _selectTime,
            ),
          ),
          readOnly: true,
          validator: (value) => value?.isEmpty == true ? 'Heure requise' : null,
        ),
      ],
    );
  }

  Widget _buildDateTimeFieldsDesktop(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _dateController,
            decoration: InputDecoration(
              labelText: 'Date début',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.calendar_today),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: _selectDate,
              ),
            ),
            readOnly: true,
            validator: (value) =>
                value?.isEmpty == true ? 'Date requise' : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _timeController,
            decoration: InputDecoration(
              labelText: 'Heure début',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.access_time),
              suffixIcon: IconButton(
                icon: const Icon(Icons.schedule),
                onPressed: _selectTime,
              ),
            ),
            readOnly: true,
            validator: (value) =>
                value?.isEmpty == true ? 'Heure requise' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildEnvironmentFieldsMobile(ThemeData theme) {
    return Column(
      children: [
        TextFormField(
          controller: _tempController,
          decoration: InputDecoration(
            labelText: 'Température (°C)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.thermostat),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _humidityController,
          decoration: InputDecoration(
            labelText: 'Humidité (%)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.water_drop),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))
          ],
        ),
      ],
    );
  }

  Widget _buildEnvironmentFieldsDesktop(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _tempController,
            decoration: InputDecoration(
              labelText: 'Température (°C)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.thermostat),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _humidityController,
            decoration: InputDecoration(
              labelText: 'Humidité (%)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.water_drop),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))
            ],
          ),
        ),
      ],
    );
  }
}

/// Modal pour terminer une extraction
class FinishExtractionModal extends StatefulWidget {
  final ExtractionProduct product;
  final VoidCallback onCancel;
  final Function(Map<String, dynamic>) onConfirm;

  const FinishExtractionModal({
    super.key,
    required this.product,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  State<FinishExtractionModal> createState() => _FinishExtractionModalState();
}

class _FinishExtractionModalState extends State<FinishExtractionModal> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _yieldController = TextEditingController();
  final _waterController = TextEditingController();
  final _tempController = TextEditingController();
  final _notesController = TextEditingController();

  String _quality = 'A+';
  String _color = 'Ambre clair';
  final List<String> _selectedIssues = [];

  final List<String> _availableIssues = [
    'Cristallisation excessive',
    'Température dépassée',
    'Contamination détectée',
    'Équipement défaillant',
  ];

  void _toggleIssue(String issue) {
    setState(() {
      if (_selectedIssues.contains(issue)) {
        _selectedIssues.remove(issue);
      } else {
        _selectedIssues.add(issue);
      }
    });
  }

  void _handleConfirm(bool validate) {
    if (_formKey.currentState!.validate()) {
      final data = {
        'quantity': _quantityController.text,
        'yield': _yieldController.text,
        'quality': _quality,
        'water': _waterController.text,
        'temperature': _tempController.text,
        'color': _color,
        'issues': _selectedIssues,
        'notes': _notesController.text,
        'validate': validate,
      };
      widget.onConfirm(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: isMobile ? double.infinity : 600,
        height: MediaQuery.of(context).size.height * 0.9,
        margin: EdgeInsets.all(isMobile ? 8 : 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Finalisation d\'Extraction',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Résultats
                      _buildSectionTitle(
                          theme, Icons.bar_chart, 'RÉSULTATS D\'EXTRACTION'),
                      const SizedBox(height: 16),

                      if (isMobile)
                        _buildResultsFieldsMobile(theme)
                      else
                        _buildResultsFieldsDesktop(theme),

                      const SizedBox(height: 24),

                      // Section Contrôles Qualité
                      _buildSectionTitle(
                          theme, Icons.science, 'CONTRÔLES QUALITÉ'),
                      const SizedBox(height: 16),

                      if (isMobile)
                        _buildQualityFieldsMobile(theme)
                      else
                        _buildQualityFieldsDesktop(theme),

                      const SizedBox(height: 24),

                      // Section Problèmes
                      _buildSectionTitle(
                          theme, Icons.warning, 'PROBLÈMES RENCONTRÉS'),
                      const SizedBox(height: 16),
                      _buildIssuesSection(theme, isMobile),

                      const SizedBox(height: 24),

                      // Observations
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: 'Observations',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.note_add),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer avec boutons
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: isMobile
                  ? Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: widget.onCancel,
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _handleConfirm(false),
                            icon: const Icon(Icons.save),
                            label: const Text('Sauvegarder'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _handleConfirm(true),
                            icon: const Icon(Icons.check),
                            label: const Text('Valider'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onCancel,
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _handleConfirm(false),
                            icon: const Icon(Icons.save),
                            label: const Text('Sauvegarder'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _handleConfirm(true),
                            icon: const Icon(Icons.check),
                            label: const Text('Valider'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
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

  Widget _buildSectionTitle(ThemeData theme, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildResultsFieldsMobile(ThemeData theme) {
    return Column(
      children: [
        TextFormField(
          controller: _quantityController,
          decoration: InputDecoration(
            labelText: 'Quantité extraite (kg)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.monitor_weight),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
          ],
          validator: (value) =>
              value?.isEmpty == true ? 'Quantité requise' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _yieldController,
          decoration: InputDecoration(
            labelText: 'Rendement (%)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.trending_up),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))
          ],
          validator: (value) =>
              value?.isEmpty == true ? 'Rendement requis' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _quality,
          decoration: InputDecoration(
            labelText: 'Qualité finale',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.star),
          ),
          items: ['A+', 'A', 'B', 'C']
              .map((quality) => DropdownMenuItem(
                    value: quality,
                    child: Text(quality),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _quality = value!),
        ),
      ],
    );
  }

  Widget _buildResultsFieldsDesktop(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantité extraite (kg)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.monitor_weight),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                ],
                validator: (value) =>
                    value?.isEmpty == true ? 'Quantité requise' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _yieldController,
                decoration: InputDecoration(
                  labelText: 'Rendement (%)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.trending_up),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))
                ],
                validator: (value) =>
                    value?.isEmpty == true ? 'Rendement requis' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _quality,
                decoration: InputDecoration(
                  labelText: 'Qualité finale',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.star),
                ),
                items: ['A+', 'A', 'B', 'C']
                    .map((quality) => DropdownMenuItem(
                          value: quality,
                          child: Text(quality),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _quality = value!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQualityFieldsMobile(ThemeData theme) {
    return Column(
      children: [
        TextFormField(
          controller: _waterController,
          decoration: InputDecoration(
            labelText: 'Teneur en eau (%)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.water_drop),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _tempController,
          decoration: InputDecoration(
            labelText: 'Température finale (°C)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.thermostat),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _color,
          decoration: InputDecoration(
            labelText: 'Couleur',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.palette),
          ),
          items: ['Ambre clair', 'Ambre', 'Foncé']
              .map((color) => DropdownMenuItem(
                    value: color,
                    child: Text(color),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _color = value!),
        ),
      ],
    );
  }

  Widget _buildQualityFieldsDesktop(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _waterController,
            decoration: InputDecoration(
              labelText: 'Teneur en eau (%)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.water_drop),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _tempController,
            decoration: InputDecoration(
              labelText: 'Température finale (°C)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.thermostat),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _color,
            decoration: InputDecoration(
              labelText: 'Couleur',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.palette),
            ),
            items: ['Ambre clair', 'Ambre', 'Foncé']
                .map((color) => DropdownMenuItem(
                      value: color,
                      child: Text(color),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _color = value!),
          ),
        ),
      ],
    );
  }

  Widget _buildIssuesSection(ThemeData theme, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sélectionnez les problèmes rencontrés:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (isMobile)
            Column(
              children: _availableIssues
                  .map(
                    (issue) => CheckboxListTile(
                      title: Text(issue, style: theme.textTheme.bodySmall),
                      value: _selectedIssues.contains(issue),
                      onChanged: (value) => _toggleIssue(issue),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                  .toList(),
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: _availableIssues
                  .map(
                    (issue) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: _selectedIssues.contains(issue),
                          onChanged: (value) => _toggleIssue(issue),
                        ),
                        Text(issue, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
