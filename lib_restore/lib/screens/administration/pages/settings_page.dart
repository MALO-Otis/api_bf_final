import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/settings_models.dart';
import '../widgets/settings_widgets.dart';
import '../../../utils/smart_appbar.dart';
import '../services/settings_service.dart';
import '../services/metier_settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SettingsService _settingsService = Get.put(SettingsService());
  final MetierSettingsService _metierService = Get.put(MetierSettingsService());

  final RxInt _selectedCategoryIndex = 0.obs;
  final List<SettingsCategory> _categories = SettingsCategory.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      _selectedCategoryIndex.value = _tabController.index;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: SmartAppBar(
        title: "⚙️ Paramètres Système",
        onBackPressed: () => _handleBackPress(),
        actions: [
          // Bouton de sauvegarde
          Obx(() {
            final hasChanges = _settingsService.hasUnsavedChanges ||
                _metierService.hasUnsavedChanges;
            final isSaving =
                _settingsService.isLoading || _metierService.isLoading;

            return hasChanges
                ? Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : _saveSettings,
                      icon: isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save, size: 18),
                      label: Text(isMobile ? '' : 'Sauvegarder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }),

          // Menu d'actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: ListTile(
                  leading: Icon(Icons.restore, color: Colors.orange),
                  title: Text('Réinitialiser'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download, color: Colors.blue),
                  title: Text('Exporter'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.upload, color: Colors.green),
                  title: Text('Importer'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'history',
                child: ListTile(
                  leading: Icon(Icons.history, color: Colors.purple),
                  title: Text('Historique'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'stats',
                child: ListTile(
                  leading: Icon(Icons.analytics, color: Colors.teal),
                  title: Text('Statistiques'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (_settingsService.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Chargement des paramètres...'),
              ],
            ),
          );
        }

        return Column(
          children: [
            // En-tête avec informations système
            _buildSystemInfoHeader(isMobile),

            // Navigation par catégories
            if (isMobile)
              _buildMobileCategorySelector()
            else
              _buildDesktopCategoryTabs(),

            // Contenu des paramètres
            Expanded(
              child: isMobile ? _buildMobileContent() : _buildDesktopContent(),
            ),
          ],
        );
      }),

      // Bouton d'aide flottant
      floatingActionButton: FloatingActionButton(
        onPressed: _showHelp,
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.help_outline, color: Colors.white),
      ),
    );
  }

  Widget _buildSystemInfoHeader(bool isMobile) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Row(
        children: [
          // Logo/Icône système
          Container(
            width: isMobile ? 50 : 60,
            height: isMobile ? 50 : 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.settings,
              color: Colors.white,
              size: 30,
            ),
          ),

          const SizedBox(width: 16),

          // Informations système
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _settingsService.settings.appName,
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D0C0D),
                  ),
                ),
                Text(
                  'Version ${_settingsService.settings.appVersion}',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Dernière mise à jour: ${_formatDate(_settingsService.settings.lastUpdated)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Indicateur de statut
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Système actif',
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCategorySelector() {
    return Container(
      height: 60,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return Obx(() => Container(
                margin: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: _selectedCategoryIndex.value == index,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(category.icon, size: 16),
                      const SizedBox(width: 6),
                      Text(category.displayName),
                    ],
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      _selectedCategoryIndex.value = index;
                      _tabController.animateTo(index);
                    }
                  },
                  selectedColor: category.color.withOpacity(0.2),
                  checkmarkColor: category.color,
                ),
              ));
        },
      ),
    );
  }

  Widget _buildDesktopCategoryTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: const Color(0xFF2196F3),
        labelColor: const Color(0xFF2196F3),
        unselectedLabelColor: Colors.grey[600],
        tabs: _categories
            .map((category) => Tab(
                  icon: Icon(category.icon, size: 20),
                  text: category.displayName,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildMobileContent() {
    return TabBarView(
      controller: _tabController,
      children: _categories
          .map((category) => SettingsCategoryContent(
                category: category,
                isMobile: true,
                settings: _settingsService.settings,
                onSettingsChanged: _onSettingsChanged,
              ))
          .toList(),
    );
  }

  Widget _buildDesktopContent() {
    return Row(
      children: [
        // Sidebar avec navigation
        Container(
          width: 250,
          color: Colors.white,
          child: Column(
            children: [
              // Liste des catégories
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return Obx(() => Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          child: ListTile(
                            selected: _selectedCategoryIndex.value == index,
                            selectedTileColor: category.color.withOpacity(0.1),
                            leading: Icon(
                              category.icon,
                              color: _selectedCategoryIndex.value == index
                                  ? category.color
                                  : Colors.grey[600],
                            ),
                            title: Text(
                              category.displayName,
                              style: TextStyle(
                                color: _selectedCategoryIndex.value == index
                                    ? category.color
                                    : Colors.grey[800],
                                fontWeight:
                                    _selectedCategoryIndex.value == index
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                            ),
                            onTap: () {
                              _selectedCategoryIndex.value = index;
                              _tabController.animateTo(index);
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ));
                  },
                ),
              ),

              // Informations de sauvegarde
              Obx(() => _settingsService.hasUnsavedChanges
                  ? Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning,
                              color: Colors.orange[600], size: 16),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Modifications non sauvegardées',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink()),
            ],
          ),
        ),

        // Contenu principal
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _categories
                .map((category) => SettingsCategoryContent(
                      category: category,
                      isMobile: false,
                      settings: _settingsService.settings,
                      onSettingsChanged: _onSettingsChanged,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  void _onSettingsChanged(AppSettings newSettings) {
    _settingsService.updateSettings(newSettings);
  }

  Future<void> _saveSettings() async {
    final List<String> successMessages = [];
    final List<String> errorMessages = [];

    SettingsSaveResult? settingsResult;
    if (_settingsService.hasUnsavedChanges) {
      settingsResult =
          await _settingsService.saveSettings(_settingsService.settings);
      if (settingsResult.success) {
        successMessages.add(settingsResult.message);
      } else {
        errorMessages.add(settingsResult.message);
        if (settingsResult.errors != null) {
          _showValidationErrors(settingsResult.errors!);
        }
      }
    }

    MetierSaveResult? metierResult;
    if (_metierService.hasUnsavedChanges) {
      metierResult = await _metierService.saveMetierSettings();
      if (metierResult.success) {
        successMessages.add(metierResult.message);
      } else {
        errorMessages.add(metierResult.message);
      }
    }

    if (successMessages.isNotEmpty && errorMessages.isEmpty) {
      Get.snackbar(
        'Succès',
        successMessages.join('\n'),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } else if (errorMessages.isNotEmpty) {
      Get.snackbar(
        successMessages.isNotEmpty ? 'Partiel' : 'Erreur',
        [
          if (successMessages.isNotEmpty) successMessages.join('\n'),
          errorMessages.join('\n'),
        ].where((element) => element.isNotEmpty).join('\n\n'),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor:
            successMessages.isNotEmpty ? Colors.orange : Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  void _showValidationErrors(Map<String, String> errors) {
    Get.dialog(
      AlertDialog(
        title: const Text('Erreurs de validation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: errors.entries
              .map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('• ${entry.value}'),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'reset':
        _showResetDialog();
        break;
      case 'export':
        _exportSettings();
        break;
      case 'import':
        _importSettings();
        break;
      case 'history':
        _showHistory();
        break;
      case 'stats':
        _showStats();
        break;
    }
  }

  void _showResetDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Réinitialiser les paramètres'),
        content: const Text(
          'Êtes-vous sûr de vouloir réinitialiser tous les paramètres aux valeurs par défaut ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final result = await _settingsService.resetToDefaults();
              Get.snackbar(
                result.success ? 'Succès' : 'Erreur',
                result.message,
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: result.success ? Colors.green : Colors.red,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }

  void _exportSettings() {
    _settingsService.exportSettings();
    // Simulation d'export
    Get.snackbar(
      'Export réussi',
      'Paramètres exportés avec succès',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void _importSettings() {
    // Simulation d'import
    Get.snackbar(
      'Import',
      'Fonctionnalité d\'import en développement',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  void _showHistory() {
    Get.dialog(
      SettingsHistoryDialog(settingsService: _settingsService),
    );
  }

  void _showStats() {
    Get.dialog(
      SettingsStatsDialog(settingsService: _settingsService),
    );
  }

  void _showHelp() {
    Get.dialog(
      const SettingsHelpDialog(),
    );
  }

  void _handleBackPress() {
    if (_settingsService.hasUnsavedChanges) {
      Get.dialog(
        AlertDialog(
          title: const Text('Modifications non sauvegardées'),
          content: const Text(
            'Vous avez des modifications non sauvegardées. Voulez-vous les sauvegarder avant de quitter ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back(); // Fermer le dialog
                Get.back(); // Retour à la page précédente
              },
              child: const Text('Ignorer'),
            ),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Get.back(); // Fermer le dialog
                await _saveSettings();
                Get.back(); // Retour à la page précédente
              },
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      );
    } else {
      Get.back();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
