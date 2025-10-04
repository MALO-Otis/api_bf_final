import 'package:flutter/material.dart';
import '../models/attribution_models.dart';

/// Widget d'affichage des statistiques d'attributions
class AttributionStatsWidget extends StatelessWidget {
  final AttributionStats stats;
  final Animation<double> animation;
  final bool isDesktop;

  const AttributionStatsWidget({
    super.key,
    required this.stats,
    required this.animation,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animation.value),
          child: Opacity(
            opacity: animation.value,
            child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(child: _buildMainStatsCard()),
        const SizedBox(width: 16),
        Expanded(child: _buildStatusBreakdownCard()),
        const SizedBox(width: 16),
        Expanded(child: _buildUserBreakdownCard()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildMainStatsCard(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatusBreakdownCard()),
            const SizedBox(width: 16),
            Expanded(child: _buildUserBreakdownCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildMainStatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.purple.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.assignment,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attributions totales',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: stats.totalAttributions),
                        duration: Duration(
                            milliseconds: (800 * animation.value).round()),
                        builder: (context, value, child) {
                          return Text(
                            value.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildQuickStat(
                  'En cours',
                  stats.enCours,
                  Colors.orange.shade400,
                  Icons.hourglass_empty,
                ),
                _buildQuickStat(
                  'Terminées',
                  stats.terminees,
                  Colors.green.shade400,
                  Icons.check_circle,
                ),
                _buildQuickStat(
                  'Annulées',
                  stats.annulees,
                  Colors.red.shade400,
                  Icons.cancel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, int value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: value),
              duration: Duration(milliseconds: (600 * animation.value).round()),
              builder: (context, animatedValue, child) {
                return Text(
                  animatedValue.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBreakdownCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Par statut',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...stats.parStatut.entries.take(4).map((entry) {
              final percentage = stats.totalAttributions > 0
                  ? (entry.value / stats.totalAttributions) * 100
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildProgressItem(
                  entry.key,
                  entry.value,
                  percentage,
                  _getStatusColorByLabel(entry.key),
                ),
              );
            }).toList(),
            if (stats.parStatut.length > 4)
              Text(
                '... et ${stats.parStatut.length - 4} autre(s)',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserBreakdownCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Par utilisateur',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...stats.parUtilisateur.entries.take(4).map((entry) {
              final percentage = stats.totalAttributions > 0
                  ? (entry.value / stats.totalAttributions) * 100
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildProgressItem(
                  entry.key,
                  entry.value,
                  percentage,
                  Colors.blue.shade600,
                ),
              );
            }).toList(),
            if (stats.parUtilisateur.length > 4)
              Text(
                '... et ${stats.parUtilisateur.length - 4} autre(s)',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(
      String label, int value, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$value (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: percentage / 100),
            duration: Duration(milliseconds: (1000 * animation.value).round()),
            builder: (context, animatedValue, child) {
              return LinearProgressIndicator(
                value: animatedValue,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getStatusColorByLabel(String label) {
    switch (label) {
      case 'Attribué Extraction':
        return Colors.blue;
      case 'En cours d\'extraction':
        return Colors.orange;
      case 'Extrait - En attente':
        return Colors.purple;
      case 'Attribué Maturation':
        return Colors.teal;
      case 'En cours de maturation':
        return Colors.indigo;
      case 'Terminé - Maturation':
        return Colors.green;
      case 'Annulé':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
