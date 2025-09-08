import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/admin_reports_service.dart';

/// Widget graphique de production
class ReportsProductionChart extends StatelessWidget {
  final AdminReportsService reportsService;
  final bool isLoading;

  const ReportsProductionChart({
    Key? key,
    required this.reportsService,
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
              const Icon(Icons.trending_up, color: Color(0xFF4CAF50)),
              const SizedBox(width: 8),
              const Text(
                'Évolution Production',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D0C0D),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${data.evolutionCollecte.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Graphique
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 20,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300],
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300],
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final dates = data.collecteByDate.keys.toList();
                        if (value.toInt() >= 0 &&
                            value.toInt() < dates.length) {
                          return Text(
                            dates[value.toInt()],
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}kg',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: const Color(0xff37434d)),
                ),
                minX: 0,
                maxX: (data.collecteByDate.length - 1).toDouble(),
                minY: 0,
                maxY: _getMaxValue([
                      data.collecteByDate.values,
                      data.extractionByDate.values,
                      data.filtrageByDate.values,
                    ]) *
                    1.2,
                lineBarsData: [
                  // Collecte
                  LineChartBarData(
                    spots: _createSpots(data.collecteByDate),
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4CAF50).withOpacity(0.3),
                          const Color(0xFF4CAF50).withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Extraction
                  LineChartBarData(
                    spots: _createSpots(data.extractionByDate),
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                  ),
                  // Filtrage
                  LineChartBarData(
                    spots: _createSpots(data.filtrageByDate),
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Légende
          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem('Collecte', const Color(0xFF4CAF50)),
              _buildLegendItem('Extraction', const Color(0xFF2196F3)),
              _buildLegendItem('Filtrage', const Color(0xFFFF9800)),
            ],
          ),
        ],
      ),
    );
  }

  List<FlSpot> _createSpots(Map<String, double> data) {
    final entries = data.entries.toList();
    return entries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();
  }

  double _getMaxValue(List<Iterable<double>> dataSets) {
    double max = 0;
    for (final dataSet in dataSets) {
      for (final value in dataSet) {
        if (value > max) max = value;
      }
    }
    return max;
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

/// Widget graphique des ventes
class ReportsSalesChart extends StatelessWidget {
  final AdminReportsService reportsService;
  final bool isLoading;

  const ReportsSalesChart({
    Key? key,
    required this.reportsService,
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
              const Icon(Icons.shopping_cart, color: Color(0xFF2196F3)),
              const SizedBox(width: 8),
              const Text(
                'Ventes (TEST)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D0C0D),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'DONNÉES TEST',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Graphique en barres
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxValue(data.venteByDate.values) * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final dates = data.venteByDate.keys.toList();
                        if (value.toInt() >= 0 &&
                            value.toInt() < dates.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              dates[value.toInt()],
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                    ),
                  ),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _createBarGroups(data.venteByDate),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Statistiques - Layout responsive
          LayoutBuilder(
            builder: (context, constraints) {
              // Si l'espace est suffisant, utiliser une Row, sinon une Column
              if (constraints.maxWidth >= 400) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(
                        child: _buildStatItem(
                            'Total Ventes', '${data.totalVentes.toInt()}')),
                    Flexible(
                        child: _buildStatItem('CA Moyen/Jour',
                            '${(data.chiffresAffaires / data.venteByDate.length).toStringAsFixed(0)} FCFA')),
                    Flexible(
                        child: _buildStatItem('Panier Moyen',
                            '${data.panierMoyen.toStringAsFixed(0)} FCFA')),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildStatItem(
                        'Total Ventes', '${data.totalVentes.toInt()}'),
                    const SizedBox(height: 8),
                    _buildStatItem('CA Moyen/Jour',
                        '${(data.chiffresAffaires / data.venteByDate.length).toStringAsFixed(0)} FCFA'),
                    const SizedBox(height: 8),
                    _buildStatItem('Panier Moyen',
                        '${data.panierMoyen.toStringAsFixed(0)} FCFA'),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _createBarGroups(Map<String, double> data) {
    final entries = data.entries.toList();
    return entries.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.value,
            color: const Color(0xFF2196F3),
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();
  }

  double _getMaxValue(Iterable<double> values) {
    if (values.isEmpty) return 10;
    return values.reduce((a, b) => a > b ? a : b);
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2196F3),
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ],
    );
  }
}

/// Widget des graphiques de production détaillés
class ReportsProductionCharts extends StatelessWidget {
  final AdminReportsService reportsService;
  final bool isMobile;
  final bool isLoading;

  const ReportsProductionCharts({
    Key? key,
    required this.reportsService,
    required this.isMobile,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 400,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final data = reportsService.reportsData;

    return Column(
      children: [
        // Graphique par site
        Container(
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
                  const Icon(Icons.location_on, color: Color(0xFF4CAF50)),
                  const SizedBox(width: 8),
                  Text(
                    'Production par Site',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D0C0D),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Graphique en secteurs
              SizedBox(
                height: 250,
                child: Row(
                  children: [
                    // Graphique
                    Expanded(
                      flex: 2,
                      child: PieChart(
                        PieChartData(
                          sections: _createPieSections(data.collecteBySite),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),

                    // Légende
                    if (!isMobile)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildPieLegend(data.collecteBySite),
                        ),
                      ),
                  ],
                ),
              ),

              // Légende mobile
              if (isMobile) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: _buildPieLegend(data.collecteBySite),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Graphique de rendement
        Container(
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
                  const Icon(Icons.speed, color: Color(0xFFFF9800)),
                  const SizedBox(width: 8),
                  Text(
                    'Rendement par Étape',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D0C0D),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Barres de progression
              _buildRendementBar('Collecte → Extraction', data.totalCollecte,
                  data.totalExtraction),
              const SizedBox(height: 12),
              _buildRendementBar('Extraction → Filtrage', data.totalExtraction,
                  data.totalFiltrage),
              const SizedBox(height: 12),
              _buildRendementBar('Collecte → Filtrage (Global)',
                  data.totalCollecte, data.totalFiltrage),
            ],
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _createPieSections(Map<String, double> data) {
    final colors = [
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFF44336),
      const Color(0xFF00BCD4),
    ];

    final total = data.values.fold(0.0, (sum, value) => sum + value);

    return data.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final dataEntry = entry.value;
      final percentage = total > 0 ? (dataEntry.value / total * 100) : 0;

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: dataEntry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<Widget> _buildPieLegend(Map<String, double> data) {
    final colors = [
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFF44336),
      const Color(0xFF00BCD4),
    ];

    return data.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final dataEntry = entry.value;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: colors[index % colors.length],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${dataEntry.key} (${dataEntry.value.toStringAsFixed(1)}kg)',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildRendementBar(String title, double input, double output) {
    final rendement = input > 0 ? (output / input) * 100 : 0;
    final color = rendement >= 80
        ? Colors.green
        : rendement >= 60
            ? Colors.orange
            : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            Text(
              '${rendement.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: (rendement / 100).clamp(0.0, 1.0),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        const SizedBox(height: 4),
        Text(
          '${input.toStringAsFixed(1)}kg → ${output.toStringAsFixed(1)}kg',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
