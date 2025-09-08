import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/settings_models.dart';
import '../services/settings_service.dart';

/// Widget principal pour le contenu d'une catégorie de paramètres
class SettingsCategoryContent extends StatelessWidget {
  final SettingsCategory category;
  final bool isMobile;
  final AppSettings settings;
  final Function(AppSettings) onSettingsChanged;

  const SettingsCategoryContent({
    Key? key,
    required this.category,
    required this.isMobile,
    required this.settings,
    required this.onSettingsChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la catégorie
          _buildCategoryHeader(),
          const SizedBox(height: 24),

          // Contenu spécifique à chaque catégorie
          _buildCategoryContent(),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: category.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: category.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: category.color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(category.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getCategoryDescription(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryContent() {
    switch (category) {
      case SettingsCategory.general:
        return _buildGeneralSettings();
      case SettingsCategory.system:
        return _buildSystemSettings();
      case SettingsCategory.security:
        return _buildSecuritySettings();
      case SettingsCategory.business:
        return _buildBusinessSettings();
      case SettingsCategory.interface:
        return _buildInterfaceSettings();
      case SettingsCategory.reports:
        return _buildReportsSettings();
    }
  }

  Widget _buildGeneralSettings() {
    return Column(
      children: [
        _buildSettingsCard(
          title: 'Informations de l\'application',
          children: [
            _buildTextField(
              label: 'Nom de l\'application',
              value: settings.appName,
              onChanged: (value) =>
                  _updateSettings(settings.copyWith(appName: value)),
            ),
            _buildTextField(
              label: 'Version',
              value: settings.appVersion,
              onChanged: (value) =>
                  _updateSettings(settings.copyWith(appVersion: value)),
            ),
            _buildTextField(
              label: 'Organisation',
              value: settings.organizationName,
              onChanged: (value) =>
                  _updateSettings(settings.copyWith(organizationName: value)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: 'Contact',
          children: [
            _buildTextField(
              label: 'Email de contact',
              value: settings.contactEmail,
              onChanged: (value) =>
                  _updateSettings(settings.copyWith(contactEmail: value)),
              keyboardType: TextInputType.emailAddress,
            ),
            _buildTextField(
              label: 'Téléphone',
              value: settings.contactPhone,
              onChanged: (value) =>
                  _updateSettings(settings.copyWith(contactPhone: value)),
              keyboardType: TextInputType.phone,
            ),
            _buildTextField(
              label: 'Adresse',
              value: settings.address,
              onChanged: (value) =>
                  _updateSettings(settings.copyWith(address: value)),
              maxLines: 2,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSystemSettings() {
    return Column(
      children: [
        _buildSettingsCard(
          title: 'Notifications',
          children: [
            _buildSwitchTile(
              title: 'Notifications push',
              subtitle: 'Recevoir des notifications sur l\'appareil',
              value: settings.enableNotifications,
              onChanged: (value) => _updateSettings(
                  settings.copyWith(enableNotifications: value)),
            ),
            _buildSwitchTile(
              title: 'Alertes par email',
              subtitle: 'Envoyer des alertes importantes par email',
              value: settings.enableEmailAlerts,
              onChanged: (value) =>
                  _updateSettings(settings.copyWith(enableEmailAlerts: value)),
            ),
            _buildSwitchTile(
              title: 'Alertes par SMS',
              subtitle: 'Envoyer des alertes critiques par SMS',
              value: settings.enableSMSAlerts,
              onChanged: (value) =>
                  _updateSettings(settings.copyWith(enableSMSAlerts: value)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: 'Sauvegarde et maintenance',
          children: [
            _buildSwitchTile(
              title: 'Sauvegarde automatique',
              subtitle: 'Effectuer des sauvegardes régulières',
              value: settings.enableBackup,
              onChanged: (value) =>
                  _updateSettings(settings.copyWith(enableBackup: value)),
            ),
            _buildNumberField(
              label: 'Fréquence de sauvegarde (heures)',
              value: settings.backupFrequencyHours.toDouble(),
              onChanged: (value) => _updateSettings(
                  settings.copyWith(backupFrequencyHours: value.toInt())),
              min: 1,
              max: 168,
            ),
            _buildSwitchTile(
              title: 'Mode débogage',
              subtitle: 'Activer les logs détaillés (développement uniquement)',
              value: settings.enableDebugMode,
              onChanged: (value) =>
                  _updateSettings(settings.copyWith(enableDebugMode: value)),
            ),
            _buildSwitchTile(
              title: 'Analytiques',
              subtitle: 'Collecter des données d\'usage anonymes',
              value: settings.enableAnalytics,
              onChanged: (value) =>
                  _updateSettings(settings.copyWith(enableAnalytics: value)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: 'Actions système',
          children: [
            _buildActionButton(
              title: 'Tester la connexion email',
              subtitle: 'Vérifier la configuration email',
              icon: Icons.email,
              color: Colors.blue,
              onPressed: _testEmailConnection,
            ),
            _buildActionButton(
              title: 'Effectuer une sauvegarde',
              subtitle: 'Lancer une sauvegarde manuelle',
              icon: Icons.backup,
              color: Colors.green,
              onPressed: _performBackup,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecuritySettings() {
    return Column(
      children: [
        _buildSettingsCard(
          title: 'Authentification',
          children: [
            _buildNumberField(
              label: 'Timeout de session (minutes)',
              value: settings.sessionTimeoutMinutes.toDouble(),
              onChanged: (value) => _updateSettings(
                  settings.copyWith(sessionTimeoutMinutes: value.toInt())),
              min: 5,
              max: 1440,
            ),
            _buildSwitchTile(
              title: 'Vérification email obligatoire',
              subtitle: 'Exiger la vérification email pour nouveaux comptes',
              value: settings.requireEmailVerification,
              onChanged: (value) => _updateSettings(
                  settings.copyWith(requireEmailVerification: value)),
            ),
            _buildSwitchTile(
              title: 'Authentification à deux facteurs',
              subtitle: 'Activer 2FA pour tous les utilisateurs',
              value: settings.enableTwoFactorAuth,
              onChanged: (value) => _updateSettings(
                  settings.copyWith(enableTwoFactorAuth: value)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: 'Politique des mots de passe',
          children: [
            _buildNumberField(
              label: 'Longueur minimale du mot de passe',
              value: settings.passwordMinLength.toDouble(),
              onChanged: (value) => _updateSettings(
                  settings.copyWith(passwordMinLength: value.toInt())),
              min: 6,
              max: 50,
            ),
            _buildSwitchTile(
              title: 'Changement de mot de passe obligatoire',
              subtitle: 'Forcer le changement périodique',
              value: settings.requirePasswordChange,
              onChanged: (value) => _updateSettings(
                  settings.copyWith(requirePasswordChange: value)),
            ),
            if (settings.requirePasswordChange)
              _buildNumberField(
                label: 'Intervalle de changement (jours)',
                value: settings.passwordChangeIntervalDays.toDouble(),
                onChanged: (value) => _updateSettings(settings.copyWith(
                    passwordChangeIntervalDays: value.toInt())),
                min: 30,
                max: 365,
              ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: 'Protection contre les intrusions',
          children: [
            _buildNumberField(
              label: 'Nombre max de tentatives de connexion',
              value: settings.maxLoginAttempts.toDouble(),
              onChanged: (value) => _updateSettings(
                  settings.copyWith(maxLoginAttempts: value.toInt())),
              min: 1,
              max: 20,
            ),
            _buildNumberField(
              label: 'Durée de verrouillage (minutes)',
              value: settings.lockoutDurationMinutes.toDouble(),
              onChanged: (value) => _updateSettings(
                  settings.copyWith(lockoutDurationMinutes: value.toInt())),
              min: 5,
              max: 1440,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBusinessSettings() {
    return Column(
      children: [
        _buildSettingsCard(
          title: 'Tarification',
          children: [
            _buildNumberField(
              label: 'Prix par défaut du miel (FCFA/kg)',
              value: settings.defaultHoneyPricePerKg,
              onChanged: (value) => _updateSettings(
                  settings.copyWith(defaultHoneyPricePerKg: value)),
              min: 100,
              max: 10000,
              isDecimal: true,
            ),
            _buildDropdownField(
              label: 'Devise par défaut',
              value: settings.defaultCurrency,
              items: ['FCFA', 'EUR', 'USD'],
              onChanged: (value) =>
                  _updateSettings(settings.copyWith(defaultCurrency: value)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: 'Prix par type de miel',
          children: settings.honeyPricesByType.entries
              .map((entry) => _buildNumberField(
                    label: '${entry.key} (FCFA/kg)',
                    value: entry.value,
                    onChanged: (value) {
                      final newPrices =
                          Map<String, double>.from(settings.honeyPricesByType);
                      newPrices[entry.key] = value;
                      _updateSettings(
                          settings.copyWith(honeyPricesByType: newPrices));
                    },
                    min: 100,
                    max: 10000,
                    isDecimal: true,
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: 'Configuration métier',
          children: [
            _buildNumberField(
              label: 'Durée d\'expiration par défaut (jours)',
              value: settings.defaultExpirationDays.toDouble(),
              onChanged: (value) => _updateSettings(
                  settings.copyWith(defaultExpirationDays: value.toInt())),
              min: 30,
              max: 1095,
            ),
            _buildChipList(
              label: 'Sites disponibles',
              items: settings.availableSites,
              onItemsChanged: (items) =>
                  _updateSettings(settings.copyWith(availableSites: items)),
            ),
            _buildChipList(
              label: 'Rôles disponibles',
              items: settings.availableRoles,
              onItemsChanged: (items) =>
                  _updateSettings(settings.copyWith(availableRoles: items)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInterfaceSettings() {
    return Column(
      children: [
        _buildSettingsCard(
          title: 'Apparence',
          children: [
            _buildDropdownField(
              label: 'Thème',
              value: settings.theme,
              items: ['light', 'dark', 'auto'],
              itemLabels: {
                'light': 'Clair',
                'dark': 'Sombre',
                'auto': 'Automatique'
              },
              onChanged: (value) =>
                  _updateSettings(settings.copyWith(theme: value)),
            ),
            _buildSwitchTile(
              title: 'Mode sombre',
              subtitle: 'Utiliser le thème sombre',
              value: settings.enableDarkMode,
              onChanged: (value) =>
                  _updateSettings(settings.copyWith(enableDarkMode: value)),
            ),
            _buildSliderField(
              label: 'Taille de police',
              value: settings.fontSize,
              onChanged: (value) =>
                  _updateSettings(settings.copyWith(fontSize: value)),
              min: 10,
              max: 20,
              divisions: 10,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: 'Expérience utilisateur',
          children: [
            _buildSwitchTile(
              title: 'Animations',
              subtitle: 'Activer les animations d\'interface',
              value: settings.enableAnimations,
              onChanged: (value) =>
                  _updateSettings(settings.copyWith(enableAnimations: value)),
            ),
            _buildSwitchTile(
              title: 'Sons',
              subtitle: 'Jouer des sons pour les notifications',
              value: settings.enableSounds,
              onChanged: (value) =>
                  _updateSettings(settings.copyWith(enableSounds: value)),
            ),
            _buildDropdownField(
              label: 'Langue',
              value: settings.language,
              items: ['fr', 'en'],
              itemLabels: {'fr': 'Français', 'en': 'English'},
              onChanged: (value) =>
                  _updateSettings(settings.copyWith(language: value)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportsSettings() {
    return Column(
      children: [
        _buildSettingsCard(
          title: 'Rapports automatiques',
          children: [
            _buildSwitchTile(
              title: 'Génération automatique',
              subtitle: 'Générer des rapports périodiques',
              value: settings.enableAutoReports,
              onChanged: (value) =>
                  _updateSettings(settings.copyWith(enableAutoReports: value)),
            ),
            if (settings.enableAutoReports) ...[
              _buildNumberField(
                label: 'Fréquence (jours)',
                value: settings.reportFrequencyDays.toDouble(),
                onChanged: (value) => _updateSettings(
                    settings.copyWith(reportFrequencyDays: value.toInt())),
                min: 1,
                max: 365,
              ),
              _buildDropdownField(
                label: 'Format de rapport',
                value: settings.reportFormat,
                items: ['PDF', 'Excel', 'CSV'],
                onChanged: (value) =>
                    _updateSettings(settings.copyWith(reportFormat: value)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: 'Destinataires des rapports',
          children: [
            _buildChipList(
              label: 'Emails des destinataires',
              items: settings.reportRecipients,
              onItemsChanged: (items) =>
                  _updateSettings(settings.copyWith(reportRecipients: items)),
              isEmail: true,
            ),
          ],
        ),
      ],
    );
  }

  // Widgets helper

  Widget _buildSettingsCard(
      {required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required Function(String) onChanged,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required double value,
    required Function(double) onChanged,
    required double min,
    required double max,
    bool isDecimal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: isDecimal ? value.toString() : value.toInt().toString(),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        keyboardType: TextInputType.number,
        onChanged: (text) {
          final parsedValue = isDecimal
              ? double.tryParse(text)
              : double.tryParse(text)?.toInt()?.toDouble();
          if (parsedValue != null && parsedValue >= min && parsedValue <= max) {
            onChanged(parsedValue);
          }
        },
      ),
    );
  }

  Widget _buildSliderField({
    required String label,
    required double value,
    required Function(double) onChanged,
    required double min,
    required double max,
    required int divisions,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: value.toStringAsFixed(0),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
    Map<String, String>? itemLabels,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(itemLabels?[item] ?? item),
                ))
            .toList(),
        onChanged: (newValue) {
          if (newValue != null) onChanged(newValue);
        },
      ),
    );
  }

  Widget _buildChipList({
    required String label,
    required List<String> items,
    required Function(List<String>) onItemsChanged,
    bool isEmail = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...items.map((item) => Chip(
                    label: Text(item),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      final newItems = List<String>.from(items);
                      newItems.remove(item);
                      onItemsChanged(newItems);
                    },
                  )),
              ActionChip(
                label: const Text('Ajouter'),
                avatar: const Icon(Icons.add, size: 16),
                onPressed: () =>
                    _showAddItemDialog(label, items, onItemsChanged, isEmail),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onPressed,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  void _showAddItemDialog(String label, List<String> currentItems,
      Function(List<String>) onItemsChanged, bool isEmail) {
    final controller = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('Ajouter $label'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: isEmail ? 'exemple@email.com' : 'Nouveau élément',
          ),
          keyboardType:
              isEmail ? TextInputType.emailAddress : TextInputType.text,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty && !currentItems.contains(text)) {
                if (!isEmail || GetUtils.isEmail(text)) {
                  final newItems = List<String>.from(currentItems);
                  newItems.add(text);
                  onItemsChanged(newItems);
                  Get.back();
                } else {
                  Get.snackbar('Erreur', 'Format d\'email invalide');
                }
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _updateSettings(AppSettings newSettings) {
    onSettingsChanged(newSettings);
  }

  void _testEmailConnection() async {
    Get.dialog(
      const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Test en cours...'),
          ],
        ),
      ),
    );

    final service = Get.find<SettingsService>();
    final result = await service.testEmailConnection();

    Get.back(); // Fermer le dialog de chargement

    Get.snackbar(
      result ? 'Succès' : 'Échec',
      result
          ? 'Connexion email réussie'
          : 'Impossible de se connecter au serveur email',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: result ? Colors.green : Colors.red,
      colorText: Colors.white,
    );
  }

  void _performBackup() async {
    Get.dialog(
      const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Sauvegarde en cours...'),
          ],
        ),
      ),
    );

    final service = Get.find<SettingsService>();
    final result = await service.testBackup();

    Get.back(); // Fermer le dialog de chargement

    Get.snackbar(
      result ? 'Succès' : 'Échec',
      result
          ? 'Sauvegarde effectuée avec succès'
          : 'Erreur lors de la sauvegarde',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: result ? Colors.green : Colors.red,
      colorText: Colors.white,
    );
  }

  String _getCategoryDescription() {
    switch (category) {
      case SettingsCategory.general:
        return 'Informations générales de l\'application';
      case SettingsCategory.system:
        return 'Configuration système et notifications';
      case SettingsCategory.security:
        return 'Paramètres de sécurité et authentification';
      case SettingsCategory.business:
        return 'Configuration métier et tarification';
      case SettingsCategory.interface:
        return 'Personnalisation de l\'interface';
      case SettingsCategory.reports:
        return 'Configuration des rapports automatiques';
    }
  }
}

/// Dialog pour l'historique des paramètres
class SettingsHistoryDialog extends StatelessWidget {
  final SettingsService settingsService;

  const SettingsHistoryDialog({
    Key? key,
    required this.settingsService,
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
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Color(0xFF9C27B0)),
                const SizedBox(width: 8),
                const Text(
                  'Historique des modifications',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: settingsService.getSettingsHistory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Aucun historique disponible'),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final item = snapshot.data![index];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF9C27B0),
                          child:
                              Icon(Icons.edit, color: Colors.white, size: 16),
                        ),
                        title: Text(
                            'Modification par ${item['userEmail'] ?? 'Inconnu'}'),
                        subtitle: Text(
                            '${item['changes']?.length ?? 0} paramètres modifiés'),
                        trailing: Text(
                          item['timestamp']?.toDate().toString() ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog pour les statistiques système
class SettingsStatsDialog extends StatelessWidget {
  final SettingsService settingsService;

  const SettingsStatsDialog({
    Key? key,
    required this.settingsService,
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
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Color(0xFF00BCD4)),
                const SizedBox(width: 8),
                const Text(
                  'Statistiques système',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: settingsService.getUsageStats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: Text('Impossible de charger les statistiques'),
                    );
                  }

                  final stats = snapshot.data!;

                  return GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildStatCard('Utilisateurs totaux',
                          '${stats['totalUsers']}', Icons.people, Colors.blue),
                      _buildStatCard(
                          'Utilisateurs actifs',
                          '${stats['activeUsers']}',
                          Icons.people_alt,
                          Colors.green),
                      _buildStatCard(
                          'Collectes totales',
                          '${stats['totalCollections']}',
                          Icons.local_florist,
                          Colors.orange),
                      _buildStatCard(
                          'Extractions totales',
                          '${stats['totalExtractions']}',
                          Icons.science,
                          Colors.purple),
                      _buildStatCard('Ventes totales', '${stats['totalSales']}',
                          Icons.shopping_cart, Colors.red),
                      _buildStatCard(
                          'Uptime système',
                          '${stats['systemUptime']}',
                          Icons.computer,
                          Colors.teal),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog d'aide
class SettingsHelpDialog extends StatelessWidget {
  const SettingsHelpDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.help, color: Color(0xFF2196F3)),
                const SizedBox(width: 8),
                const Text(
                  'Aide - Paramètres',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const Divider(),
            const Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guide d\'utilisation des paramètres',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '• Général: Configurez les informations de base de votre application\n'
                      '• Système: Gérez les notifications et sauvegardes\n'
                      '• Sécurité: Définissez les politiques de sécurité\n'
                      '• Métier: Configurez les prix et paramètres métier\n'
                      '• Interface: Personnalisez l\'apparence\n'
                      '• Rapports: Automatisez la génération de rapports\n\n'
                      'N\'oubliez pas de sauvegarder vos modifications !',
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Support technique',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Pour toute assistance technique, contactez:\n'
                      '📧 support@apisavana.com\n'
                      '📞 +226 XX XX XX XX',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
