/// Modèles de données pour les rapports administrateur

/// Données principales des rapports
class ReportsData {
  // Production (données réelles)
  final double totalCollecte;
  final double totalControle;
  final double totalExtraction;
  final double totalFiltrage;
  
  // Commercial (données de test)
  final double totalVentes;
  final double chiffresAffaires;
  final int totalClients;
  
  // Financier (données de test)
  final double revenus;
  final double charges;
  final double benefices;
  
  // Données par date
  final Map<String, double> collecteByDate;
  final Map<String, double> controleByDate;
  final Map<String, double> extractionByDate;
  final Map<String, double> filtrageByDate;
  final Map<String, double> venteByDate;
  
  // Données par site
  final Map<String, double> collecteBySite;
  final Map<String, double> controleBySite;
  final Map<String, double> extractionBySite;
  final Map<String, double> filtrageBySite;
  
  // Indicateurs de performance
  final double rendementExtraction;
  final double tauxControleConforme;
  final Map<String, double> evolutionProduction;
  
  // Activité récente
  final List<RecentActivity> recentActivities;
  
  // Métadonnées
  final DateTime startDate;
  final DateTime endDate;
  final String site;

  ReportsData({
    required this.totalCollecte,
    required this.totalControle,
    required this.totalExtraction,
    required this.totalFiltrage,
    required this.totalVentes,
    required this.chiffresAffaires,
    required this.totalClients,
    required this.revenus,
    required this.charges,
    required this.benefices,
    required this.collecteByDate,
    required this.controleByDate,
    required this.extractionByDate,
    required this.filtrageByDate,
    required this.venteByDate,
    required this.collecteBySite,
    required this.controleBySite,
    required this.extractionBySite,
    required this.filtrageBySite,
    required this.rendementExtraction,
    required this.tauxControleConforme,
    required this.evolutionProduction,
    required this.recentActivities,
    required this.startDate,
    required this.endDate,
    required this.site,
  });

  factory ReportsData.empty() {
    final now = DateTime.now();
    return ReportsData(
      totalCollecte: 0,
      totalControle: 0,
      totalExtraction: 0,
      totalFiltrage: 0,
      totalVentes: 0,
      chiffresAffaires: 0,
      totalClients: 0,
      revenus: 0,
      charges: 0,
      benefices: 0,
      collecteByDate: {},
      controleByDate: {},
      extractionByDate: {},
      filtrageByDate: {},
      venteByDate: {},
      collecteBySite: {},
      controleBySite: {},
      extractionBySite: {},
      filtrageBySite: {},
      rendementExtraction: 0,
      tauxControleConforme: 0,
      evolutionProduction: {},
      recentActivities: [],
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now,
      site: 'all',
    );
  }

  // Getters calculés
  double get totalProduction => totalCollecte + totalExtraction + totalFiltrage;
  double get margeNette => benefices / revenus * 100;
  double get panierMoyen => totalVentes > 0 ? chiffresAffaires / totalVentes : 0;
  int get totalTransactions => totalVentes.toInt() + totalControle.toInt();
  
  // Évolution vs période précédente (simulation)
  double get evolutionCollecte => 12.5; // +12.5%
  double get evolutionVentes => 8.3; // +8.3%
  double get evolutionCA => 15.7; // +15.7%
}

/// Activité récente
class RecentActivity {
  final String type;
  final String title;
  final String description;
  final DateTime timestamp;
  final String icon;
  final String color;

  RecentActivity({
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.icon,
    required this.color,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

/// KPI (Key Performance Indicator)
class KPI {
  final String title;
  final String value;
  final String subtitle;
  final String icon;
  final String color;
  final double? trend;
  final bool isPositiveTrend;
  final String? unit;

  KPI({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.trend,
    this.isPositiveTrend = true,
    this.unit,
  });

  String get trendText {
    if (trend == null) return '';
    final sign = isPositiveTrend ? '+' : '';
    return '$sign${trend!.toStringAsFixed(1)}%';
  }
}

/// Données pour les graphiques
class ChartData {
  final String label;
  final double value;
  final String color;
  final DateTime? date;

  ChartData({
    required this.label,
    required this.value,
    required this.color,
    this.date,
  });
}

/// Objectif vs Réalisation
class ObjectiveTracking {
  final String title;
  final double target;
  final double actual;
  final String unit;
  final String period;

  ObjectiveTracking({
    required this.title,
    required this.target,
    required this.actual,
    required this.unit,
    required this.period,
  });

  double get percentage => target > 0 ? (actual / target) * 100 : 0;
  bool get isAchieved => actual >= target;
  double get gap => target - actual;
}

/// Comparaison de performances
class PerformanceComparison {
  final String metric;
  final double currentValue;
  final double previousValue;
  final String unit;
  final String period;

  PerformanceComparison({
    required this.metric,
    required this.currentValue,
    required this.previousValue,
    required this.unit,
    required this.period,
  });

  double get changePercentage {
    if (previousValue == 0) return 0;
    return ((currentValue - previousValue) / previousValue) * 100;
  }

  bool get isImprovement => currentValue > previousValue;
  double get changeValue => currentValue - previousValue;
}

/// Données d'export
class ExportData {
  final String format;
  final Map<String, dynamic> data;
  final String filename;
  final DateTime generatedAt;

  ExportData({
    required this.format,
    required this.data,
    required this.filename,
    required this.generatedAt,
  });
}

/// Filtre de rapport
class ReportFilter {
  final DateTime startDate;
  final DateTime endDate;
  final String site;
  final List<String> modules;
  final String groupBy; // day, week, month
  final bool includeInactive;

  ReportFilter({
    required this.startDate,
    required this.endDate,
    required this.site,
    required this.modules,
    this.groupBy = 'day',
    this.includeInactive = false,
  });

  ReportFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? site,
    List<String>? modules,
    String? groupBy,
    bool? includeInactive,
  }) {
    return ReportFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      site: site ?? this.site,
      modules: modules ?? this.modules,
      groupBy: groupBy ?? this.groupBy,
      includeInactive: includeInactive ?? this.includeInactive,
    );
  }
}

/// Alerte de performance
class PerformanceAlert {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final String metric;
  final double threshold;
  final double currentValue;
  final DateTime timestamp;
  final bool isResolved;

  PerformanceAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.metric,
    required this.threshold,
    required this.currentValue,
    required this.timestamp,
    this.isResolved = false,
  });

  double get deviationPercentage {
    if (threshold == 0) return 0;
    return ((currentValue - threshold) / threshold) * 100;
  }
}

enum AlertSeverity { low, medium, high, critical }

extension AlertSeverityExtension on AlertSeverity {
  String get displayName {
    switch (this) {
      case AlertSeverity.low:
        return 'Faible';
      case AlertSeverity.medium:
        return 'Moyen';
      case AlertSeverity.high:
        return 'Élevé';
      case AlertSeverity.critical:
        return 'Critique';
    }
  }

  String get color {
    switch (this) {
      case AlertSeverity.low:
        return '#4CAF50';
      case AlertSeverity.medium:
        return '#FF9800';
      case AlertSeverity.high:
        return '#F44336';
      case AlertSeverity.critical:
        return '#D32F2F';
    }
  }
}

/// Tendance de données
class DataTrend {
  final List<ChartData> data;
  final double slope;
  final double correlation;
  final String direction;

  DataTrend({
    required this.data,
    required this.slope,
    required this.correlation,
    required this.direction,
  });

  bool get isIncreasing => slope > 0;
  bool get isStrongTrend => correlation.abs() > 0.7;
  
  String get trendDescription {
    if (correlation.abs() < 0.3) return 'Stable';
    if (isIncreasing) {
      return isStrongTrend ? 'Forte hausse' : 'Hausse modérée';
    } else {
      return isStrongTrend ? 'Forte baisse' : 'Baisse modérée';
    }
  }
}
