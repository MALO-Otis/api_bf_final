import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/admin_reports_service.dart';
import '../models/admin_reports_models.dart';

/// Widget principal des KPIs du dashboard
class ReportsDashboardKPIs extends StatelessWidget {
  final AdminReportsService reportsService;
  final bool isMobile;
  final bool isLoading;

  const ReportsDashboardKPIs({
    Key? key,
    required this.reportsService,
    required this.isMobile,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: isMobile ? 200 : 120,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final data = reportsService.reportsData;
    final kpis = _buildKPIs(data);

    return Container(
      child: isMobile ? _buildMobileKPIs(kpis) : _buildDesktopKPIs(kpis),
    );
  }

  List<KPI> _buildKPIs(ReportsData data) {
    return [
      KPI(
        title: 'Production Totale',
        value: '${data.totalProduction.toStringAsFixed(1)}',
        subtitle: 'kg de miel traité',
        icon: '🍯',
        color: '#4CAF50',
        trend: data.evolutionCollecte,
        unit: 'kg',
      ),
      KPI(
        title: 'Chiffre d\'Affaires',
        value: _formatCurrency(data.chiffresAffaires),
        subtitle: 'FCFA générés',
        icon: '💰',
        color: '#2196F3',
        trend: data.evolutionCA,
        unit: 'FCFA',
      ),
      KPI(
        title: 'Rendement',
        value: '${data.rendementExtraction.toStringAsFixed(1)}%',
        subtitle: 'extraction/collecte',
        icon: '⚡',
        color: '#FF9800',
        trend: 3.2,
      ),
      KPI(
        title: 'Qualité',
        value: '${data.tauxControleConforme.toStringAsFixed(1)}%',
        subtitle: 'contrôles conformes',
        icon: '✅',
        color: '#9C27B0',
        trend: 1.8,
      ),
      KPI(
        title: 'Ventes',
        value: '${data.totalVentes.toInt()}',
        subtitle: 'transactions',
        icon: '🛒',
        color: '#F44336',
        trend: data.evolutionVentes,
        unit: 'ventes',
      ),
      KPI(
        title: 'Clients Actifs',
        value: '${data.totalClients}',
        subtitle: 'clients uniques',
        icon: '👥',
        color: '#00BCD4',
        trend: 5.4,
      ),
    ];
  }

  Widget _buildMobileKPIs(List<KPI> kpis) {
    return Column(
      children: [
        // Première ligne - KPIs principaux
        Row(
          children: [
            Expanded(child: _buildKPICard(kpis[0], isMobile: true)),
            const SizedBox(width: 8),
            Expanded(child: _buildKPICard(kpis[1], isMobile: true)),
          ],
        ),
        const SizedBox(height: 8),
        // Deuxième ligne
        Row(
          children: [
            Expanded(child: _buildKPICard(kpis[2], isMobile: true)),
            const SizedBox(width: 8),
            Expanded(child: _buildKPICard(kpis[3], isMobile: true)),
          ],
        ),
        const SizedBox(height: 8),
        // Troisième ligne
        Row(
          children: [
            Expanded(child: _buildKPICard(kpis[4], isMobile: true)),
            const SizedBox(width: 8),
            Expanded(child: _buildKPICard(kpis[5], isMobile: true)),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopKPIs(List<KPI> kpis) {
    return Column(
      children: [
        // Première ligne - KPIs principaux
        Row(
          children: [
            Expanded(child: _buildKPICard(kpis[0])),
            const SizedBox(width: 16),
            Expanded(child: _buildKPICard(kpis[1])),
            const SizedBox(width: 16),
            Expanded(child: _buildKPICard(kpis[2])),
          ],
        ),
        const SizedBox(height: 16),
        // Deuxième ligne
        Row(
          children: [
            Expanded(child: _buildKPICard(kpis[3])),
            const SizedBox(width: 16),
            Expanded(child: _buildKPICard(kpis[4])),
            const SizedBox(width: 16),
            Expanded(child: _buildKPICard(kpis[5])),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard(KPI kpi, {bool isMobile = false}) {
    final color = _hexToColor(kpi.color);

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec icône et tendance
          Row(
            children: [
              Text(
                kpi.icon,
                style: TextStyle(fontSize: isMobile ? 20 : 24),
              ),
              const Spacer(),
              if (kpi.trend != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: kpi.isPositiveTrend
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        kpi.isPositiveTrend
                            ? Icons.trending_up
                            : Icons.trending_down,
                        size: 12,
                        color: kpi.isPositiveTrend ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        kpi.trendText,
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              kpi.isPositiveTrend ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Valeur principale
          Text(
            kpi.value,
            style: TextStyle(
              fontSize: isMobile ? 20 : 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(height: 4),

          // Titre
          Text(
            kpi.title,
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D0C0D),
            ),
          ),

          const SizedBox(height: 2),

          // Sous-titre
          Text(
            kpi.subtitle,
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }
}

/// Widget de l'activité récente
class ReportsRecentActivity extends StatelessWidget {
  final AdminReportsService reportsService;
  final bool isMobile;
  final bool isLoading;

  const ReportsRecentActivity({
    Key? key,
    required this.reportsService,
    required this.isMobile,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 300,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final activities = reportsService.reportsData.recentActivities;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              const Icon(Icons.timeline, color: Color(0xFF2196F3)),
              const SizedBox(width: 8),
              Text(
                'Activité Récente',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D0C0D),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showAllActivities(),
                child: const Text('Voir tout'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Liste des activités
          if (activities.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Aucune activité récente',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Column(
              children: activities
                  .take(5)
                  .map((activity) => _buildActivityItem(activity))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(RecentActivity activity) {
    final color = _hexToColor(activity.color);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            width: 3,
            color: color,
          ),
        ),
      ),
      child: Row(
        children: [
          // Icône
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                activity.icon,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Contenu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Timestamp
          Text(
            activity.timeAgo,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _showAllActivities() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 600,
          height: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // En-tête
              Row(
                children: [
                  const Icon(Icons.timeline, color: Color(0xFF2196F3)),
                  const SizedBox(width: 8),
                  const Text(
                    'Toute l\'activité',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),

              const Divider(),

              // Liste complète
              Expanded(
                child: ListView.builder(
                  itemCount: reportsService.reportsData.recentActivities.length,
                  itemBuilder: (context, index) {
                    final activity =
                        reportsService.reportsData.recentActivities[index];
                    return _buildActivityItem(activity);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }
}

/// Widget des indicateurs de performance
class ReportsPerformanceIndicators extends StatelessWidget {
  final AdminReportsService reportsService;
  final bool isMobile;
  final bool isLoading;

  const ReportsPerformanceIndicators({
    Key? key,
    required this.reportsService,
    required this.isMobile,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 200,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final data = reportsService.reportsData;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              const Icon(Icons.speed, color: Color(0xFF2196F3)),
              const SizedBox(width: 8),
              Text(
                'Indicateurs de Performance',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D0C0D),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Indicateurs
          isMobile
              ? Column(
                  children: [
                    _buildPerformanceIndicator(
                      'Rendement Extraction',
                      data.rendementExtraction,
                      85.0, // Objectif
                      '%',
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildPerformanceIndicator(
                      'Taux Conformité',
                      data.tauxControleConforme,
                      90.0, // Objectif
                      '%',
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildPerformanceIndicator(
                      'Marge Nette',
                      data.margeNette,
                      25.0, // Objectif
                      '%',
                      Colors.orange,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildPerformanceIndicator(
                        'Rendement Extraction',
                        data.rendementExtraction,
                        85.0, // Objectif
                        '%',
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPerformanceIndicator(
                        'Taux Conformité',
                        data.tauxControleConforme,
                        90.0, // Objectif
                        '%',
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPerformanceIndicator(
                        'Marge Nette',
                        data.margeNette,
                        25.0, // Objectif
                        '%',
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicator(
    String title,
    double value,
    double target,
    String unit,
    Color color,
  ) {
    final percentage = target > 0 ? (value / target) * 100 : 0;
    final isGood = value >= target;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre et valeur
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                '${value.toStringAsFixed(1)}$unit',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Barre de progression
          LinearProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              isGood ? Colors.green : Colors.orange,
            ),
          ),

          const SizedBox(height: 4),

          // Objectif
          Text(
            'Objectif: ${target.toStringAsFixed(1)}$unit',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
