import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/user_management_models.dart';
import '../services/user_management_service.dart';

/// Widget des statistiques des utilisateurs
class UserStatisticsWidget extends StatelessWidget {
  final UserManagementService userService;
  final bool isMobile;

  const UserStatisticsWidget({
    Key? key,
    required this.userService,
    required this.isMobile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (userService.isLoadingStats) {
        return Container(
          height: isMobile ? 200 : 120,
          child: const Center(child: CircularProgressIndicator()),
        );
      }

      final stats = userService.statistics;
      final statsCards = _buildStatsCards(stats);

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: isMobile
            ? _buildMobileStats(statsCards)
            : _buildDesktopStats(statsCards),
      );
    });
  }

  Widget _buildMobileStats(List<Widget> statsCards) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: statsCards[0]),
            const SizedBox(width: 8),
            Expanded(child: statsCards[1]),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: statsCards[2]),
            const SizedBox(width: 8),
            Expanded(child: statsCards[3]),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: statsCards[4]),
            const SizedBox(width: 8),
            Expanded(child: statsCards[5]),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopStats(List<Widget> statsCards) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: statsCards[0]),
            const SizedBox(width: 16),
            Expanded(child: statsCards[1]),
            const SizedBox(width: 16),
            Expanded(child: statsCards[2]),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: statsCards[3]),
            const SizedBox(width: 16),
            Expanded(child: statsCards[4]),
            const SizedBox(width: 16),
            Expanded(child: statsCards[5]),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildStatsCards(UserStatistics stats) {
    return [
      _buildStatCard(
        title: 'Total Utilisateurs',
        value: stats.totalUsers.toString(),
        icon: Icons.people,
        color: Colors.blue,
        subtitle: 'Utilisateurs enregistrés',
      ),
      _buildStatCard(
        title: 'Utilisateurs Actifs',
        value: stats.activeUsers.toString(),
        icon: Icons.person,
        color: Colors.green,
        subtitle: _formatPercentage(stats.activeUsers, stats.totalUsers),
      ),
      _buildStatCard(
        title: 'Emails Vérifiés',
        value: stats.verifiedUsers.toString(),
        icon: Icons.verified_user,
        color: Colors.orange,
        subtitle: _formatPercentage(stats.verifiedUsers, stats.totalUsers),
      ),
      _buildStatCard(
        title: 'Nouveaux ce Mois',
        value: stats.newUsersByMonth.values
            .fold(0, (sum, count) => sum + count)
            .toString(),
        icon: Icons.person_add,
        color: Colors.purple,
        subtitle: 'Inscriptions récentes',
      ),
      _buildStatCard(
        title: 'Par Rôle',
        value: stats.usersByRole.length.toString(),
        icon: Icons.work,
        color: Colors.teal,
        subtitle: 'Rôles différents',
      ),
      _buildStatCard(
        title: 'Par Site',
        value: stats.usersBySite.length.toString(),
        icon: Icons.location_on,
        color: Colors.red,
        subtitle: 'Sites différents',
      ),
    ];
  }

  String _formatPercentage(int part, int total) {
    if (total <= 0) {
      return '0% du total';
    }
    final percentage = (part / total * 100).clamp(0, 100).toStringAsFixed(1);
    return '$percentage% du total';
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D0C0D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
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
