import 'package:flutter/material.dart';

/// Modèle pour les paramètres de l'application
class AppSettings {
  // Paramètres généraux
  final String appName;
  final String appVersion;
  final String organizationName;
  final String contactEmail;
  final String contactPhone;
  final String address;

  // Paramètres système
  final bool enableNotifications;
  final bool enableEmailAlerts;
  final bool enableSMSAlerts;
  final bool enableBackup;
  final int backupFrequencyHours;
  final bool enableDebugMode;
  final bool enableAnalytics;

  // Paramètres de sécurité
  final int sessionTimeoutMinutes;
  final bool requireEmailVerification;
  final bool enableTwoFactorAuth;
  final int passwordMinLength;
  final bool requirePasswordChange;
  final int passwordChangeIntervalDays;
  final int maxLoginAttempts;
  final int lockoutDurationMinutes;

  // Paramètres métier
  final double defaultHoneyPricePerKg;
  final String defaultCurrency;
  final List<String> availableSites;
  final List<String> availableRoles;
  final Map<String, double> honeyPricesByType;
  final int defaultExpirationDays;

  // Paramètres d'interface
  final String theme;
  final String language;
  final bool enableAnimations;
  final bool enableSounds;
  final double fontSize;
  final bool enableDarkMode;

  // Paramètres de rapports
  final bool enableAutoReports;
  final int reportFrequencyDays;
  final List<String> reportRecipients;
  final String reportFormat;

  // Métadonnées
  final DateTime lastUpdated;
  final String updatedBy;

  AppSettings({
    required this.appName,
    required this.appVersion,
    required this.organizationName,
    required this.contactEmail,
    required this.contactPhone,
    required this.address,
    required this.enableNotifications,
    required this.enableEmailAlerts,
    required this.enableSMSAlerts,
    required this.enableBackup,
    required this.backupFrequencyHours,
    required this.enableDebugMode,
    required this.enableAnalytics,
    required this.sessionTimeoutMinutes,
    required this.requireEmailVerification,
    required this.enableTwoFactorAuth,
    required this.passwordMinLength,
    required this.requirePasswordChange,
    required this.passwordChangeIntervalDays,
    required this.maxLoginAttempts,
    required this.lockoutDurationMinutes,
    required this.defaultHoneyPricePerKg,
    required this.defaultCurrency,
    required this.availableSites,
    required this.availableRoles,
    required this.honeyPricesByType,
    required this.defaultExpirationDays,
    required this.theme,
    required this.language,
    required this.enableAnimations,
    required this.enableSounds,
    required this.fontSize,
    required this.enableDarkMode,
    required this.enableAutoReports,
    required this.reportFrequencyDays,
    required this.reportRecipients,
    required this.reportFormat,
    required this.lastUpdated,
    required this.updatedBy,
  });

  factory AppSettings.defaultSettings() {
    return AppSettings(
      appName: 'Apisavana Gestion',
      appVersion: '1.0.0',
      organizationName: 'Apisavana',
      contactEmail: 'contact@apisavana.com',
      contactPhone: '+226 XX XX XX XX',
      address: 'Ouagadougou, Burkina Faso',
      enableNotifications: true,
      enableEmailAlerts: true,
      enableSMSAlerts: false,
      enableBackup: true,
      backupFrequencyHours: 24,
      enableDebugMode: false,
      enableAnalytics: true,
      sessionTimeoutMinutes: 120,
      requireEmailVerification: true,
      enableTwoFactorAuth: false,
      passwordMinLength: 8,
      requirePasswordChange: false,
      passwordChangeIntervalDays: 90,
      maxLoginAttempts: 5,
      lockoutDurationMinutes: 30,
      defaultHoneyPricePerKg: 2500.0,
      defaultCurrency: 'FCFA',
      availableSites: [
        'Ouaga',
        'Koudougou',
        'Bobo',
        'Mangodara',
        'Bagré',
        'Pô'
      ],
      availableRoles: [
        'Admin',
        'Collecteur',
        'Contrôleur',
        'Filtreur',
        'Extracteur',
        'Conditionneur',
        'Magazinier',
        'Commercial'
      ],
      honeyPricesByType: {
        'Toutes fleurs': 2500.0,
        'Acacia': 3000.0,
        'Karité': 2800.0,
        'Eucalyptus': 2700.0,
      },
      defaultExpirationDays: 365,
      theme: 'light',
      language: 'fr',
      enableAnimations: true,
      enableSounds: true,
      fontSize: 14.0,
      enableDarkMode: false,
      enableAutoReports: false,
      reportFrequencyDays: 7,
      reportRecipients: [],
      reportFormat: 'PDF',
      lastUpdated: DateTime.now(),
      updatedBy: 'System',
    );
  }

  AppSettings copyWith({
    String? appName,
    String? appVersion,
    String? organizationName,
    String? contactEmail,
    String? contactPhone,
    String? address,
    bool? enableNotifications,
    bool? enableEmailAlerts,
    bool? enableSMSAlerts,
    bool? enableBackup,
    int? backupFrequencyHours,
    bool? enableDebugMode,
    bool? enableAnalytics,
    int? sessionTimeoutMinutes,
    bool? requireEmailVerification,
    bool? enableTwoFactorAuth,
    int? passwordMinLength,
    bool? requirePasswordChange,
    int? passwordChangeIntervalDays,
    int? maxLoginAttempts,
    int? lockoutDurationMinutes,
    double? defaultHoneyPricePerKg,
    String? defaultCurrency,
    List<String>? availableSites,
    List<String>? availableRoles,
    Map<String, double>? honeyPricesByType,
    int? defaultExpirationDays,
    String? theme,
    String? language,
    bool? enableAnimations,
    bool? enableSounds,
    double? fontSize,
    bool? enableDarkMode,
    bool? enableAutoReports,
    int? reportFrequencyDays,
    List<String>? reportRecipients,
    String? reportFormat,
    DateTime? lastUpdated,
    String? updatedBy,
  }) {
    return AppSettings(
      appName: appName ?? this.appName,
      appVersion: appVersion ?? this.appVersion,
      organizationName: organizationName ?? this.organizationName,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      address: address ?? this.address,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableEmailAlerts: enableEmailAlerts ?? this.enableEmailAlerts,
      enableSMSAlerts: enableSMSAlerts ?? this.enableSMSAlerts,
      enableBackup: enableBackup ?? this.enableBackup,
      backupFrequencyHours: backupFrequencyHours ?? this.backupFrequencyHours,
      enableDebugMode: enableDebugMode ?? this.enableDebugMode,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      sessionTimeoutMinutes:
          sessionTimeoutMinutes ?? this.sessionTimeoutMinutes,
      requireEmailVerification:
          requireEmailVerification ?? this.requireEmailVerification,
      enableTwoFactorAuth: enableTwoFactorAuth ?? this.enableTwoFactorAuth,
      passwordMinLength: passwordMinLength ?? this.passwordMinLength,
      requirePasswordChange:
          requirePasswordChange ?? this.requirePasswordChange,
      passwordChangeIntervalDays:
          passwordChangeIntervalDays ?? this.passwordChangeIntervalDays,
      maxLoginAttempts: maxLoginAttempts ?? this.maxLoginAttempts,
      lockoutDurationMinutes:
          lockoutDurationMinutes ?? this.lockoutDurationMinutes,
      defaultHoneyPricePerKg:
          defaultHoneyPricePerKg ?? this.defaultHoneyPricePerKg,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      availableSites: availableSites ?? this.availableSites,
      availableRoles: availableRoles ?? this.availableRoles,
      honeyPricesByType: honeyPricesByType ?? this.honeyPricesByType,
      defaultExpirationDays:
          defaultExpirationDays ?? this.defaultExpirationDays,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      enableSounds: enableSounds ?? this.enableSounds,
      fontSize: fontSize ?? this.fontSize,
      enableDarkMode: enableDarkMode ?? this.enableDarkMode,
      enableAutoReports: enableAutoReports ?? this.enableAutoReports,
      reportFrequencyDays: reportFrequencyDays ?? this.reportFrequencyDays,
      reportRecipients: reportRecipients ?? this.reportRecipients,
      reportFormat: reportFormat ?? this.reportFormat,
      lastUpdated: lastUpdated ?? DateTime.now(),
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'appVersion': appVersion,
      'organizationName': organizationName,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'address': address,
      'enableNotifications': enableNotifications,
      'enableEmailAlerts': enableEmailAlerts,
      'enableSMSAlerts': enableSMSAlerts,
      'enableBackup': enableBackup,
      'backupFrequencyHours': backupFrequencyHours,
      'enableDebugMode': enableDebugMode,
      'enableAnalytics': enableAnalytics,
      'sessionTimeoutMinutes': sessionTimeoutMinutes,
      'requireEmailVerification': requireEmailVerification,
      'enableTwoFactorAuth': enableTwoFactorAuth,
      'passwordMinLength': passwordMinLength,
      'requirePasswordChange': requirePasswordChange,
      'passwordChangeIntervalDays': passwordChangeIntervalDays,
      'maxLoginAttempts': maxLoginAttempts,
      'lockoutDurationMinutes': lockoutDurationMinutes,
      'defaultHoneyPricePerKg': defaultHoneyPricePerKg,
      'defaultCurrency': defaultCurrency,
      'availableSites': availableSites,
      'availableRoles': availableRoles,
      'honeyPricesByType': honeyPricesByType,
      'defaultExpirationDays': defaultExpirationDays,
      'theme': theme,
      'language': language,
      'enableAnimations': enableAnimations,
      'enableSounds': enableSounds,
      'fontSize': fontSize,
      'enableDarkMode': enableDarkMode,
      'enableAutoReports': enableAutoReports,
      'reportFrequencyDays': reportFrequencyDays,
      'reportRecipients': reportRecipients,
      'reportFormat': reportFormat,
      'lastUpdated': lastUpdated.toIso8601String(),
      'updatedBy': updatedBy,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      appName: map['appName'] ?? 'Apisavana Gestion',
      appVersion: map['appVersion'] ?? '1.0.0',
      organizationName: map['organizationName'] ?? 'Apisavana',
      contactEmail: map['contactEmail'] ?? 'contact@apisavana.com',
      contactPhone: map['contactPhone'] ?? '+226 XX XX XX XX',
      address: map['address'] ?? 'Ouagadougou, Burkina Faso',
      enableNotifications: map['enableNotifications'] ?? true,
      enableEmailAlerts: map['enableEmailAlerts'] ?? true,
      enableSMSAlerts: map['enableSMSAlerts'] ?? false,
      enableBackup: map['enableBackup'] ?? true,
      backupFrequencyHours: map['backupFrequencyHours'] ?? 24,
      enableDebugMode: map['enableDebugMode'] ?? false,
      enableAnalytics: map['enableAnalytics'] ?? true,
      sessionTimeoutMinutes: map['sessionTimeoutMinutes'] ?? 120,
      requireEmailVerification: map['requireEmailVerification'] ?? true,
      enableTwoFactorAuth: map['enableTwoFactorAuth'] ?? false,
      passwordMinLength: map['passwordMinLength'] ?? 8,
      requirePasswordChange: map['requirePasswordChange'] ?? false,
      passwordChangeIntervalDays: map['passwordChangeIntervalDays'] ?? 90,
      maxLoginAttempts: map['maxLoginAttempts'] ?? 5,
      lockoutDurationMinutes: map['lockoutDurationMinutes'] ?? 30,
      defaultHoneyPricePerKg:
          (map['defaultHoneyPricePerKg'] ?? 2500.0).toDouble(),
      defaultCurrency: map['defaultCurrency'] ?? 'FCFA',
      availableSites: List<String>.from(map['availableSites'] ??
          ['Ouaga', 'Koudougou', 'Bobo', 'Mangodara', 'Bagré', 'Pô']),
      availableRoles: List<String>.from(map['availableRoles'] ??
          [
            'Admin',
            'Collecteur',
            'Contrôleur',
            'Filtreur',
            'Extracteur',
            'Conditionneur',
            'Magazinier',
            'Commercial'
          ]),
      honeyPricesByType: Map<String, double>.from(map['honeyPricesByType'] ??
          {
            'Toutes fleurs': 2500.0,
            'Acacia': 3000.0,
            'Karité': 2800.0,
            'Eucalyptus': 2700.0,
          }),
      defaultExpirationDays: map['defaultExpirationDays'] ?? 365,
      theme: map['theme'] ?? 'light',
      language: map['language'] ?? 'fr',
      enableAnimations: map['enableAnimations'] ?? true,
      enableSounds: map['enableSounds'] ?? true,
      fontSize: (map['fontSize'] ?? 14.0).toDouble(),
      enableDarkMode: map['enableDarkMode'] ?? false,
      enableAutoReports: map['enableAutoReports'] ?? false,
      reportFrequencyDays: map['reportFrequencyDays'] ?? 7,
      reportRecipients: List<String>.from(map['reportRecipients'] ?? []),
      reportFormat: map['reportFormat'] ?? 'PDF',
      lastUpdated: DateTime.parse(
          map['lastUpdated'] ?? DateTime.now().toIso8601String()),
      updatedBy: map['updatedBy'] ?? 'System',
    );
  }
}

/// Catégories de paramètres
enum SettingsCategory {
  general,
  system,
  security,
  business,
  interface,
  reports,
}

extension SettingsCategoryExtension on SettingsCategory {
  String get displayName {
    switch (this) {
      case SettingsCategory.general:
        return 'Général';
      case SettingsCategory.system:
        return 'Système';
      case SettingsCategory.security:
        return 'Sécurité';
      case SettingsCategory.business:
        return 'Métier';
      case SettingsCategory.interface:
        return 'Interface';
      case SettingsCategory.reports:
        return 'Rapports';
    }
  }

  IconData get icon {
    switch (this) {
      case SettingsCategory.general:
        return Icons.settings;
      case SettingsCategory.system:
        return Icons.computer;
      case SettingsCategory.security:
        return Icons.security;
      case SettingsCategory.business:
        return Icons.business;
      case SettingsCategory.interface:
        return Icons.palette;
      case SettingsCategory.reports:
        return Icons.analytics;
    }
  }

  Color get color {
    switch (this) {
      case SettingsCategory.general:
        return const Color(0xFF2196F3);
      case SettingsCategory.system:
        return const Color(0xFF4CAF50);
      case SettingsCategory.security:
        return const Color(0xFFF44336);
      case SettingsCategory.business:
        return const Color(0xFFFF9800);
      case SettingsCategory.interface:
        return const Color(0xFF9C27B0);
      case SettingsCategory.reports:
        return const Color(0xFF00BCD4);
    }
  }
}

/// Action de sauvegarde des paramètres
class SettingsSaveResult {
  final bool success;
  final String message;
  final Map<String, String>? errors;

  SettingsSaveResult({
    required this.success,
    required this.message,
    this.errors,
  });
}
