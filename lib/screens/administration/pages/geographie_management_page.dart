import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/geographie_models.dart';
import '../services/geographie_management_service.dart';
import '../../../controllers/geographie_management_controller.dart';

class GeographieManagementPage extends StatefulWidget {
  const GeographieManagementPage({super.key});

  @override
  State<GeographieManagementPage> createState() =>
      _GeographieManagementPageState();
}

class _GeographieManagementPageState extends State<GeographieManagementPage> {
  late final GeographieManagementService _service;
  late final GeographieManagementController _controller;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _service = Get.isRegistered<GeographieManagementService>()
        ? Get.find<GeographieManagementService>()
        : Get.put(GeographieManagementService());

    _controller = Get.isRegistered<GeographieManagementController>()
        ? Get.find<GeographieManagementController>()
        : Get.put(GeographieManagementController());
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des données géographiques'),
        actions: [
          Obx(() {
            final pending = _controller.hasPendingChanges.value;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: !pending
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        avatar: const Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: Colors.orange,
                        ),
                        backgroundColor:
                            colorScheme.secondaryContainer.withOpacity(0.6),
                        label: const Text(
                          'Modifications non sauvegardées',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
            );
          }),
          IconButton(
            tooltip: 'Options avancées',
            icon: const Icon(Icons.menu_open),
            onPressed: () => _showDataOptions(context),
          ),
        ],
      ),
      body: Obx(() {
        final regions = _controller.regions;
        final isLoading = _controller.isLoading.value;

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (regions.isEmpty)
                    _buildEmptyStateCard(theme, colorScheme)
                  else ...[
                    _buildSearchBar(theme, colorScheme),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        children: regions
                            .asMap()
                            .entries
                            .map(
                              (entry) => _buildRegionCard(
                                context,
                                entry.key,
                                entry.value,
                                theme,
                                colorScheme,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isLoading)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 3),
              ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: _promptAddRegion,
        tooltip: 'Ajouter une région',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyStateCard(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.public_off,
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune donnée géographique',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Commencez par ajouter une région',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _promptAddRegion,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une région'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, ColorScheme colorScheme) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Rechercher...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  });
                },
                icon: const Icon(Icons.clear),
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildRegionCard(
    BuildContext context,
    int regionIndex,
    GeoRegion region,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const Icon(Icons.public),
        title: Text(region.nom),
        subtitle: Text('${region.provincesCount} provinces'),
        children: [
          ...region.provinces.asMap().entries.map(
                (provinceEntry) => _buildProvinceCard(
                  context,
                  regionIndex,
                  provinceEntry.key,
                  provinceEntry.value,
                  theme,
                  colorScheme,
                ),
              ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => _promptAddProvince(regionIndex),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter province'),
                ),
                TextButton.icon(
                  onPressed: () => _promptEditRegion(regionIndex, region.nom),
                  icon: const Icon(Icons.edit),
                  label: const Text('Modifier'),
                ),
                TextButton.icon(
                  onPressed: () =>
                      _confirmDeleteRegion(regionIndex, region.nom),
                  icon: const Icon(Icons.delete),
                  label: const Text('Supprimer'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProvinceCard(
    BuildContext context,
    int regionIndex,
    int provinceIndex,
    GeoProvince province,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: const Icon(Icons.location_city),
        title: Text(province.nom),
        subtitle: Text('${province.communesCount} communes'),
        children: [
          ...province.communes.asMap().entries.map(
                (communeEntry) => _buildCommuneCard(
                  context,
                  regionIndex,
                  provinceIndex,
                  communeEntry.key,
                  communeEntry.value,
                  theme,
                  colorScheme,
                ),
              ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () =>
                      _promptAddCommune(regionIndex, provinceIndex),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter commune'),
                ),
                TextButton.icon(
                  onPressed: () => _promptEditProvince(
                      regionIndex, provinceIndex, province.nom),
                  icon: const Icon(Icons.edit),
                  label: const Text('Modifier'),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDeleteProvince(
                      regionIndex, provinceIndex, province.nom),
                  icon: const Icon(Icons.delete),
                  label: const Text('Supprimer'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommuneCard(
    BuildContext context,
    int regionIndex,
    int provinceIndex,
    int communeIndex,
    GeoCommune commune,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
      child: ExpansionTile(
        leading: const Icon(Icons.apartment),
        title: Text(commune.nom),
        subtitle: Text('${commune.villagesCount} villages'),
        children: [
          ...commune.villages.asMap().entries.map(
                (villageEntry) => ListTile(
                  leading: const Icon(Icons.home_work_outlined),
                  title: Text(villageEntry.value.nom),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _promptEditVillage(
                          regionIndex,
                          provinceIndex,
                          communeIndex,
                          villageEntry.key,
                          villageEntry.value.nom,
                        ),
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        onPressed: () => _confirmDeleteVillage(
                          regionIndex,
                          provinceIndex,
                          communeIndex,
                          villageEntry.key,
                          villageEntry.value.nom,
                        ),
                        icon: const Icon(Icons.delete),
                      ),
                    ],
                  ),
                ),
              ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => _promptAddVillage(
                      regionIndex, provinceIndex, communeIndex),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter village'),
                ),
                TextButton.icon(
                  onPressed: () => _promptEditCommune(
                      regionIndex, provinceIndex, communeIndex, commune.nom),
                  icon: const Icon(Icons.edit),
                  label: const Text('Modifier'),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDeleteCommune(
                      regionIndex, provinceIndex, communeIndex, commune.nom),
                  icon: const Icon(Icons.delete),
                  label: const Text('Supprimer'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDataOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.save),
            title: const Text('Sauvegarder'),
            onTap: () {
              Navigator.pop(context);
              _controller.saveData();
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Actualiser'),
            onTap: () {
              Navigator.pop(context);
              _controller.refreshData();
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Exporter JSON'),
            onTap: () {
              Navigator.pop(context);
              _showExportDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('Importer JSON'),
            onTap: () {
              Navigator.pop(context);
              _showImportDialog();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showExportDialog() async {
    final data = _controller.exportData();
    final formatted = const JsonEncoder.withIndent('  ').convert(data);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Export JSON'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: SelectableText(formatted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: formatted));
                Get.snackbar(
                  'Export',
                  'JSON copié dans le presse-papiers',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              child: const Text('Copier'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showImportDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const _ImportDataDialog();
      },
    );
  }

  Future<void> _executeMutation({
    required Future<bool> Function() action,
    required String successMessage,
    String? operationLabel,
    Map<String, dynamic>? context,
  }) async {
    final label = operationLabel ?? 'mutation';
    final contextDetails = context != null && context.isNotEmpty
        ? context.entries.map((e) => '${e.key}=${e.value}').join(', ')
        : null;

    if (contextDetails != null) {
      Get.log('[GeographiePage] start:$label | $contextDetails');
    } else {
      Get.log('[GeographiePage] start:$label');
    }

    final success = await action();

    if (success) {
      Get.log('[GeographiePage] success:$label');
      Get.snackbar(
        'Succès',
        successMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      final message =
          _controller.error.value ?? 'Opération impossible pour le moment.';
      Get.log(
        '[GeographiePage] failure:$label | message=$message',
        isError: true,
      );
      Get.snackbar(
        'Erreur',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<String?> _askForName({
    required String title,
    required String label,
    String? initialValue,
  }) async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _NameInputDialog(
          title: title,
          label: label,
          initialValue: initialValue,
        );
      },
    );
  }

  Future<bool> _confirmDeletion({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // Region operations
  Future<void> _promptAddRegion() async {
    final name = await _askForName(
      title: 'Nouvelle région',
      label: 'Nom de la région',
    );
    if (name == null) return;

    await _executeMutation(
      action: () => _controller.addRegion(name),
      successMessage: 'Région ajoutée (à sauvegarder).',
      operationLabel: 'addRegion',
      context: {'name': name},
    );
  }

  Future<void> _promptEditRegion(int index, String currentName) async {
    final name = await _askForName(
      title: 'Renommer la région',
      label: 'Nom de la région',
      initialValue: currentName,
    );
    if (name == null || name == currentName) return;

    await _executeMutation(
      action: () => _controller.updateRegion(index, name),
      successMessage: 'Région mise à jour (pensez à sauvegarder).',
      operationLabel: 'updateRegion',
      context: {'index': index, 'name': name},
    );
  }

  Future<void> _confirmDeleteRegion(int index, String name) async {
    final confirmed = await _confirmDeletion(
      title: 'Supprimer la région',
      message:
          'Voulez-vous vraiment supprimer la région "$name" et toutes ses subdivisions ?',
    );
    if (!confirmed) return;

    await _executeMutation(
      action: () => _controller.deleteRegion(index),
      successMessage: 'Région supprimée (en attente de sauvegarde).',
      operationLabel: 'deleteRegion',
      context: {'index': index, 'name': name},
    );
  }

  // Province operations
  Future<void> _promptAddProvince(int regionIndex) async {
    final name = await _askForName(
      title: 'Nouvelle province',
      label: 'Nom de la province',
    );
    if (name == null) return;

    await _executeMutation(
      action: () => _controller.addProvince(regionIndex, name),
      successMessage: 'Province ajoutée (à sauvegarder).',
    );
  }

  Future<void> _promptEditProvince(
      int regionIndex, int provinceIndex, String currentName) async {
    final name = await _askForName(
      title: 'Renommer la province',
      label: 'Nom de la province',
      initialValue: currentName,
    );
    if (name == null || name == currentName) return;

    await _executeMutation(
      action: () =>
          _controller.updateProvince(regionIndex, provinceIndex, name),
      successMessage: 'Province mise à jour (pensez à sauvegarder).',
    );
  }

  Future<void> _confirmDeleteProvince(
      int regionIndex, int provinceIndex, String name) async {
    final confirmed = await _confirmDeletion(
      title: 'Supprimer la province',
      message:
          'Voulez-vous vraiment supprimer la province "$name" et toutes ses communes ?',
    );
    if (!confirmed) return;

    await _executeMutation(
      action: () => _controller.deleteProvince(regionIndex, provinceIndex),
      successMessage: 'Province supprimée (en attente de sauvegarde).',
    );
  }

  // Commune operations
  Future<void> _promptAddCommune(int regionIndex, int provinceIndex) async {
    final name = await _askForName(
      title: 'Nouvelle commune',
      label: 'Nom de la commune',
    );
    if (name == null) return;

    await _executeMutation(
      action: () => _controller.addCommune(regionIndex, provinceIndex, name),
      successMessage: 'Commune ajoutée (à sauvegarder).',
    );
  }

  Future<void> _promptEditCommune(
    int regionIndex,
    int provinceIndex,
    int communeIndex,
    String currentName,
  ) async {
    final name = await _askForName(
      title: 'Renommer la commune',
      label: 'Nom de la commune',
      initialValue: currentName,
    );
    if (name == null || name == currentName) return;

    await _executeMutation(
      action: () => _controller.updateCommune(
        regionIndex,
        provinceIndex,
        communeIndex,
        name,
      ),
      successMessage: 'Commune mise à jour (à sauvegarder).',
    );
  }

  Future<void> _confirmDeleteCommune(
    int regionIndex,
    int provinceIndex,
    int communeIndex,
    String name,
  ) async {
    final confirmed = await _confirmDeletion(
      title: 'Supprimer la commune',
      message:
          'Les villages associés à "$name" seront également supprimés. Continuer ?',
    );
    if (!confirmed) return;

    await _executeMutation(
      action: () => _controller.deleteCommune(
        regionIndex,
        provinceIndex,
        communeIndex,
      ),
      successMessage: 'Commune supprimée (en attente de sauvegarde).',
    );
  }

  // Village operations
  Future<void> _promptAddVillage(
      int regionIndex, int provinceIndex, int communeIndex) async {
    final name = await _askForName(
      title: 'Nouveau village',
      label: 'Nom du village',
    );
    if (name == null) return;

    await _executeMutation(
      action: () => _controller.addVillage(
        regionIndex,
        provinceIndex,
        communeIndex,
        name,
      ),
      successMessage: 'Village ajouté (à sauvegarder).',
    );
  }

  Future<void> _promptEditVillage(
    int regionIndex,
    int provinceIndex,
    int communeIndex,
    int villageIndex,
    String currentName,
  ) async {
    final name = await _askForName(
      title: 'Renommer le village',
      label: 'Nom du village',
      initialValue: currentName,
    );
    if (name == null || name == currentName) return;

    await _executeMutation(
      action: () => _controller.updateVillage(
        regionIndex,
        provinceIndex,
        communeIndex,
        villageIndex,
        name,
      ),
      successMessage: 'Village mis à jour (à sauvegarder).',
    );
  }

  Future<void> _confirmDeleteVillage(
    int regionIndex,
    int provinceIndex,
    int communeIndex,
    int villageIndex,
    String name,
  ) async {
    final confirmed = await _confirmDeletion(
      title: 'Supprimer le village',
      message: 'Supprimer le village "$name" ?',
    );
    if (!confirmed) return;

    await _executeMutation(
      action: () => _controller.deleteVillage(
        regionIndex,
        provinceIndex,
        communeIndex,
        villageIndex,
      ),
      successMessage: 'Village supprimé (en attente de sauvegarde).',
    );
  }
}

class _NameInputDialog extends StatefulWidget {
  final String title;
  final String label;
  final String? initialValue;

  const _NameInputDialog({
    required this.title,
    required this.label,
    this.initialValue,
  });

  @override
  State<_NameInputDialog> createState() => _NameInputDialogState();
}

class _NameInputDialogState extends State<_NameInputDialog> {
  late final TextEditingController _textController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_textController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 300,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _textController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: widget.label,
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez saisir un nom valide';
              }
              return null;
            },
            onFieldSubmitted: (_) => _submit(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Valider'),
        ),
      ],
    );
  }
}

class _ImportDataDialog extends StatefulWidget {
  const _ImportDataDialog();

  @override
  State<_ImportDataDialog> createState() => _ImportDataDialogState();
}

class _ImportDataDialogState extends State<_ImportDataDialog> {
  late final TextEditingController _textController;
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _importData() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    try {
      final decoded = jsonDecode(_textController.text);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'Le JSON doit contenir un objet racine.',
        );
      }

      // Close dialog first
      Navigator.of(context).pop();

      // Get controller and import data
      final controller = Get.find<GeographieManagementController>();
      final success = await controller.importData(
        Map<String, dynamic>.from(decoded),
      );

      if (!success) {
        final message = controller.error.value ??
            'Importation échouée. Vérifiez le format.';
        Get.snackbar(
          'Erreur',
          message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'JSON invalide : $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Importer un JSON'),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Collez un JSON exporté ou respectant la structure officielle.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _textController,
                maxLines: 12,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '{ "regions": [...] }',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez coller un JSON valide';
                  }
                  return null;
                },
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _importData,
          child: const Text('Importer'),
        ),
      ],
    );
  }
}
