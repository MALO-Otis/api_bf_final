import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 📊 WIDGET STATISTIQUES ATTRIBUTION
///
/// Affiche les statistiques en temps réel des produits disponibles pour attribution
class AttributionStatsWidget extends StatelessWidget {
  final RxMap<String, int> stats;
  final bool isLoading;

  const AttributionStatsWidget({
    Key? key,
    required this.stats,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo[600]!,
            Colors.indigo[700]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isLoading ? _buildLoadingState() : _buildStatsContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        SizedBox(width: 12),
        Text(
          'Chargement des statistiques...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsContent() {
    return Obx(() {
      final total = stats['total'] ?? 0;
      final bruts = stats['bruts'] ?? 0;
      final liquides = stats['liquides'] ?? 0;
      final cire = stats['cire'] ?? 0;
      final urgents = stats['urgents'] ?? 0;

      return Column(
        children: [
          // Titre et total
          Row(
            children: [
              const Icon(
                Icons.analytics,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Produits Disponibles',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$total produits prêts pour attribution',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (urgents > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.priority_high,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$urgents urgents',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Statistiques détaillées
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Extraction',
                  bruts.toString(),
                  Icons.science,
                  Colors.brown,
                  total > 0 ? (bruts / total) * 100 : 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Filtrage',
                  liquides.toString(),
                  Icons.water_drop,
                  Colors.blue,
                  total > 0 ? (liquides / total) * 100 : 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Traitement Cire',
                  cire.toString(),
                  Icons.spa,
                  Colors.amber[700]!,
                  total > 0 ? (cire / total) * 100 : 0,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    double percentage,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Icône et valeur
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Label
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Pourcentage
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
