import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/user_management_models.dart';

/// Widget d'en-tête avec les statistiques principales
class UserStatisticsHeader extends StatelessWidget {
  final UserStatistics statistics;
  final bool isLoading;
  final bool isMobile;

  const UserStatisticsHeader({
    Key? key,
    required this.statistics,
    required this.isLoading,
    required this.isMobile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: isMobile ? 120 : 140,
        color: Colors.white,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Column(
        children: [
          // Statistiques principales
          isMobile
              ? Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildStatCard(
                          'Total', statistics.totalUsers.toString(), 
                          Icons.people, const Color(0xFF2196F3)
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatCard(
                          'Actifs', statistics.activeUsers.toString(), 
                          Icons.check_circle, const Color(0xFF4CAF50)
                        )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard(
                          'Vérifiés', statistics.verifiedUsers.toString(), 
                          Icons.verified, const Color(0xFFFF9800)
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatCard(
                          'En ligne', statistics.onlineUsers.toString(), 
                          Icons.online_prediction, const Color(0xFF9C27B0)
                        )),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildStatCard(
                      'Total Utilisateurs', statistics.totalUsers.toString(), 
                      Icons.people, const Color(0xFF2196F3)
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard(
                      'Utilisateurs Actifs', statistics.activeUsers.toString(), 
                      Icons.check_circle, const Color(0xFF4CAF50)
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard(
                      'Emails Vérifiés', statistics.verifiedUsers.toString(), 
                      Icons.verified, const Color(0xFFFF9800)
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard(
                      'En Ligne', statistics.onlineUsers.toString(), 
                      Icons.online_prediction, const Color(0xFF9C27B0)
                    )),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isMobile ? 20 : 24),
          SizedBox(height: isMobile ? 4 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 18 : 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Widget détaillé des statistiques
class UserStatisticsDetailWidget extends StatelessWidget {
  final UserStatistics statistics;
  final bool isLoading;
  final bool isMobile;

  const UserStatisticsDetailWidget({
    Key? key,
    required this.statistics,
    required this.isLoading,
    required this.isMobile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Répartition par rôle
          _buildSectionTitle('Répartition par Rôle'),
          const SizedBox(height: 16),
          _buildRoleChart(),
          
          const SizedBox(height: 32),
          
          // Répartition par site
          _buildSectionTitle('Répartition par Site'),
          const SizedBox(height: 16),
          _buildSiteChart(),
          
          const SizedBox(height: 32),
          
          // Évolution des inscriptions
          _buildSectionTitle('Évolution des Inscriptions'),
          const SizedBox(height: 16),
          _buildRegistrationChart(),
          
          const SizedBox(height: 32),
          
          // Statistiques détaillées
          _buildSectionTitle('Statistiques Détaillées'),
          const SizedBox(height: 16),
          _buildDetailedStats(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: isMobile ? 16 : 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF2D0C0D),
      ),
    );
  }

  Widget _buildRoleChart() {
    final roleData = statistics.usersByRole.entries
        .where((entry) => entry.value > 0)
        .toList();
    
    if (roleData.isEmpty) {
      return const Center(
        child: Text('Aucune donnée disponible'),
      );
    }

    return Container(
      height: isMobile ? 200 : 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isMobile 
          ? _buildRoleBarChart(roleData)
          : Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildRolePieChart(roleData),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRoleLegend(roleData),
                ),
              ],
            ),
    );
  }

  Widget _buildRolePieChart(List<MapEntry<String, int>> roleData) {
    final colors = [
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFF44336),
      const Color(0xFF00BCD4),
      const Color(0xFF8BC34A),
      const Color(0xFFFFEB3B),
      const Color(0xFF795548),
      const Color(0xFF607D8B),
    ];

    return PieChart(
      PieChartData(
        sections: roleData.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final percentage = (data.value / statistics.totalUsers * 100);
          
          return PieChartSectionData(
            color: colors[index % colors.length],
            value: data.value.toDouble(),
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildRoleLegend(List<MapEntry<String, int>> roleData) {
    final colors = [
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFF44336),
      const Color(0xFF00BCD4),
      const Color(0xFF8BC34A),
      const Color(0xFFFFEB3B),
      const Color(0xFF795548),
      const Color(0xFF607D8B),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: roleData.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${data.key} (${data.value})',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRoleBarChart(List<MapEntry<String, int>> roleData) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: roleData.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble(),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < roleData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      roleData[index].key.length > 8 
                          ? '${roleData[index].key.substring(0, 8)}...'
                          : roleData[index].key,
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
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
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: roleData.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data.value.toDouble(),
                color: const Color(0xFF2196F3),
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSiteChart() {
    final siteData = statistics.usersBySite.entries
        .where((entry) => entry.value > 0)
        .toList();
    
    if (siteData.isEmpty) {
      return const Center(
        child: Text('Aucune donnée disponible'),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: siteData.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble(),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < siteData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        siteData[index].key,
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
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
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: siteData.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data.value.toDouble(),
                  color: const Color(0xFF4CAF50),
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRegistrationChart() {
    final registrationData = statistics.newUsersByMonth.entries.toList();
    
    if (registrationData.isEmpty) {
      return const Center(
        child: Text('Aucune donnée disponible'),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 1,
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
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < registrationData.length) {
                    final monthKey = registrationData[index].key;
                    final parts = monthKey.split('-');
                    if (parts.length == 2) {
                      final month = int.parse(parts[1]);
                      const months = ['', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
                                     'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
                      return Text(
                        months[month],
                        style: const TextStyle(fontSize: 10),
                      );
                    }
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d)),
          ),
          minX: 0,
          maxX: registrationData.length.toDouble() - 1,
          minY: 0,
          maxY: registrationData.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble() + 1,
          lineBarsData: [
            LineChartBarData(
              spots: registrationData.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.value.toDouble());
              }).toList(),
              isCurved: true,
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: const Color(0xFF2196F3),
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2196F3).withOpacity(0.3),
                    const Color(0xFF2196F3).withOpacity(0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStatRow('Total des utilisateurs', statistics.totalUsers.toString(), Icons.people),
          _buildStatRow('Utilisateurs actifs', statistics.activeUsers.toString(), Icons.check_circle),
          _buildStatRow('Utilisateurs inactifs', statistics.inactiveUsers.toString(), Icons.cancel),
          _buildStatRow('Emails vérifiés', statistics.verifiedUsers.toString(), Icons.verified),
          _buildStatRow('Emails non vérifiés', statistics.unverifiedUsers.toString(), Icons.email),
          _buildStatRow('Utilisateurs en ligne', statistics.onlineUsers.toString(), Icons.online_prediction),
          const Divider(),
          _buildStatRow('Taux d\'activation', '${(statistics.activeUsers / statistics.totalUsers * 100).toStringAsFixed(1)}%', Icons.trending_up),
          _buildStatRow('Taux de vérification', '${(statistics.verifiedUsers / statistics.totalUsers * 100).toStringAsFixed(1)}%', Icons.verified_user),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2196F3), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2D0C0D),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2196F3),
            ),
          ),
        ],
      ),
    );
  }
}
