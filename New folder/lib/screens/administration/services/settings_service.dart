import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/settings_models.dart';
import '../../../authentication/user_session.dart';

class SettingsService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserSession _userSession = Get.find<UserSession>();

  /// Collection des paramètres
  CollectionReference get _settingsCollection =>
      _firestore.collection('settings');

  /// Document des paramètres de l'application
  DocumentReference get _appSettingsDoc =>
      _settingsCollection.doc('app_settings');

  /// Paramètres observables
  final Rx<AppSettings> _settings = AppSettings.defaultSettings().obs;
  final RxBool _isLoading = false.obs;
  final RxBool _hasUnsavedChanges = false.obs;

  // Getters
  AppSettings get settings => _settings.value;
  bool get isLoading => _isLoading.value;
  bool get hasUnsavedChanges => _hasUnsavedChanges.value;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  /// Charger les paramètres depuis Firestore
  Future<void> loadSettings() async {
    _isLoading.value = true;
    try {
      final doc = await _appSettingsDoc.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _settings.value = AppSettings.fromMap(data);
      } else {
        // Créer les paramètres par défaut
        await _createDefaultSettings();
      }
      _hasUnsavedChanges.value = false;
    } catch (e) {
      print('Erreur lors du chargement des paramètres: $e');
      // Utiliser les paramètres par défaut en cas d'erreur
      _settings.value = AppSettings.defaultSettings();
    } finally {
      _isLoading.value = false;
    }
  }

  /// Créer les paramètres par défaut dans Firestore
  Future<void> _createDefaultSettings() async {
    final defaultSettings = AppSettings.defaultSettings();
    await _appSettingsDoc.set(defaultSettings.toMap());
    _settings.value = defaultSettings;
  }

  /// Sauvegarder les paramètres
  Future<SettingsSaveResult> saveSettings(AppSettings newSettings) async {
    try {
      _isLoading.value = true;

      // Valider les paramètres
      final validation = _validateSettings(newSettings);
      if (!validation.success) {
        return validation;
      }

      // Mettre à jour avec les métadonnées
      final updatedSettings = newSettings.copyWith(
        lastUpdated: DateTime.now(),
        updatedBy: _userSession.email ?? 'Unknown',
      );

      // Sauvegarder dans Firestore
      await _appSettingsDoc.set(updatedSettings.toMap());

      // Mettre à jour localement
      _settings.value = updatedSettings;
      _hasUnsavedChanges.value = false;

      // Logger l'action
      await _logSettingsChange(newSettings);

      return SettingsSaveResult(
        success: true,
        message: 'Paramètres sauvegardés avec succès',
      );
    } catch (e) {
      return SettingsSaveResult(
        success: false,
        message: 'Erreur lors de la sauvegarde: $e',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Valider les paramètres avant sauvegarde
  SettingsSaveResult _validateSettings(AppSettings settings) {
    Map<String, String> errors = {};

    // Validation des champs obligatoires
    if (settings.appName.trim().isEmpty) {
      errors['appName'] = 'Le nom de l\'application est requis';
    }
    if (settings.organizationName.trim().isEmpty) {
      errors['organizationName'] = 'Le nom de l\'organisation est requis';
    }
    if (settings.contactEmail.trim().isEmpty) {
      errors['contactEmail'] = 'L\'email de contact est requis';
    } else if (!GetUtils.isEmail(settings.contactEmail)) {
      errors['contactEmail'] = 'Format d\'email invalide';
    }

    // Validation des valeurs numériques
    if (settings.sessionTimeoutMinutes < 5 ||
        settings.sessionTimeoutMinutes > 1440) {
      errors['sessionTimeoutMinutes'] =
          'Le timeout doit être entre 5 et 1440 minutes';
    }
    if (settings.passwordMinLength < 6 || settings.passwordMinLength > 50) {
      errors['passwordMinLength'] =
          'La longueur du mot de passe doit être entre 6 et 50 caractères';
    }
    if (settings.maxLoginAttempts < 1 || settings.maxLoginAttempts > 20) {
      errors['maxLoginAttempts'] =
          'Le nombre de tentatives doit être entre 1 et 20';
    }
    if (settings.defaultHoneyPricePerKg <= 0) {
      errors['defaultHoneyPricePerKg'] = 'Le prix du miel doit être positif';
    }

    // Validation des listes
    if (settings.availableSites.isEmpty) {
      errors['availableSites'] = 'Au moins un site doit être défini';
    }
    if (settings.availableRoles.isEmpty) {
      errors['availableRoles'] = 'Au moins un rôle doit être défini';
    }

    return SettingsSaveResult(
      success: errors.isEmpty,
      message: errors.isEmpty
          ? 'Validation réussie'
          : 'Erreurs de validation détectées',
      errors: errors.isEmpty ? null : errors,
    );
  }

  /// Marquer comme modifié
  void markAsChanged() {
    _hasUnsavedChanges.value = true;
  }

  /// Mettre à jour les paramètres localement
  void updateSettings(AppSettings newSettings) {
    _settings.value = newSettings;
    _hasUnsavedChanges.value = true;
  }

  /// Réinitialiser aux paramètres par défaut
  Future<SettingsSaveResult> resetToDefaults() async {
    try {
      final defaultSettings = AppSettings.defaultSettings().copyWith(
        updatedBy: _userSession.email ?? 'System',
      );

      return await saveSettings(defaultSettings);
    } catch (e) {
      return SettingsSaveResult(
        success: false,
        message: 'Erreur lors de la réinitialisation: $e',
      );
    }
  }

  /// Exporter les paramètres
  Map<String, dynamic> exportSettings() {
    return _settings.value.toMap();
  }

  /// Importer les paramètres
  Future<SettingsSaveResult> importSettings(
      Map<String, dynamic> settingsData) async {
    try {
      final importedSettings = AppSettings.fromMap(settingsData);
      return await saveSettings(importedSettings);
    } catch (e) {
      return SettingsSaveResult(
        success: false,
        message: 'Erreur lors de l\'importation: $e',
      );
    }
  }

  /// Logger les changements de paramètres
  Future<void> _logSettingsChange(AppSettings newSettings) async {
    try {
      await _firestore.collection('settings_history').add({
        'userId': _userSession.uid ?? '',
        'userEmail': _userSession.email ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'action': 'settings_updated',
        'changes': _detectChanges(_settings.value, newSettings),
      });
    } catch (e) {
      print('Erreur lors du logging des changements: $e');
    }
  }

  /// Détecter les changements entre deux configurations
  Map<String, Map<String, dynamic>> _detectChanges(
      AppSettings old, AppSettings newSettings) {
    Map<String, Map<String, dynamic>> changes = {};

    final oldMap = old.toMap();
    final newMap = newSettings.toMap();

    for (String key in newMap.keys) {
      if (oldMap[key] != newMap[key]) {
        changes[key] = {
          'old': oldMap[key],
          'new': newMap[key],
        };
      }
    }

    return changes;
  }

  /// Tester la connectivité email
  Future<bool> testEmailConnection() async {
    try {
      // Simulation d'un test de connexion email
      await Future.delayed(const Duration(seconds: 2));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Tester la sauvegarde
  Future<bool> testBackup() async {
    try {
      // Simulation d'un test de sauvegarde
      await Future.delayed(const Duration(seconds: 3));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Obtenir les statistiques d'utilisation
  Future<Map<String, dynamic>> getUsageStats() async {
    try {
      // Simulation de statistiques d'utilisation
      return {
        'totalUsers': 25,
        'activeUsers': 18,
        'totalCollections': 156,
        'totalExtractions': 134,
        'totalSales': 89,
        'systemUptime': '99.8%',
        'lastBackup': DateTime.now().subtract(const Duration(hours: 6)),
        'diskUsage': 45.6, // Pourcentage
        'memoryUsage': 23.4, // Pourcentage
      };
    } catch (e) {
      return {};
    }
  }

  /// Obtenir l'historique des changements
  Future<List<Map<String, dynamic>>> getSettingsHistory(
      {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('settings_history')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      print('Erreur lors du chargement de l\'historique: $e');
      return [];
    }
  }
}
