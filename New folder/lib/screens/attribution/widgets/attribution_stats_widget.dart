import 'package:get/get.dart';
import 'package:flutter/material.dart';

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

      return LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          final isVeryNarrow = constraints.maxWidth < 420;

          return Column(
            children: [
              // Titre et total
              Row(
                children: [
                  if (!isVeryNarrow)
                    const Icon(
                      Icons.analytics,
                      color: Colors.white,
                      size: 24,
                    ),
                  if (!isVeryNarrow) const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isVeryNarrow ? 'Produits' : 'Produits Disponibles',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isNarrow ? 16 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          isVeryNarrow
                              ? '$total prêts'
                              : '$total produits prêts pour attribution',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (urgents > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[600],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isVeryNarrow)
                            const Icon(
                              Icons.priority_high,
                              color: Colors.white,
                              size: 16,
                            ),
                          if (!isVeryNarrow) const SizedBox(width: 4),
                          Text(
                            isVeryNarrow ? '$urgents!' : '$urgents urgents',
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
              isVeryNarrow
                  ? Column(
                      children: [
                        _buildStatCard(
                          'Extraction',
                          bruts.toString(),
                          Icons.science,
                          Colors.brown,
                          total > 0 ? (bruts / total) * 100 : 0,
                          isCompact: true,
                          isMobile: true,
                        ),
                        const SizedBox(height: 6),
                        _buildStatCard(
                          'Filtrage',
                          liquides.toString(),
                          Icons.water_drop,
                          Colors.blue,
                          total > 0 ? (liquides / total) * 100 : 0,
                          isCompact: true,
                          isMobile: true,
                        ),
                        const SizedBox(height: 6),
                        _buildStatCard(
                          'Cire',
                          cire.toString(),
                          Icons.spa,
                          Colors.amber[700]!,
                          total > 0 ? (cire / total) * 100 : 0,
                          isCompact: true,
                          isMobile: true,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Flexible(
                          child: _buildStatCard(
                            'Extraction',
                            bruts.toString(),
                            Icons.science,
                            Colors.brown,
                            total > 0 ? (bruts / total) * 100 : 0,
                            isCompact: isNarrow,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: _buildStatCard(
                            'Filtrage',
                            liquides.toString(),
                            Icons.water_drop,
                            Colors.blue,
                            total > 0 ? (liquides / total) * 100 : 0,
                            isCompact: isNarrow,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: _buildStatCard(
                            isVeryNarrow ? 'Cire' : 'Traitement Cire',
                            cire.toString(),
                            Icons.spa,
                            Colors.amber[700]!,
                            total > 0 ? (cire / total) * 100 : 0,
                            isCompact: isNarrow,
                          ),
                        ),
                      ],
                    ),
            ],
          );
        },
      );
    });
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    double percentage, {
    bool isCompact = false,
    bool isMobile = false,
  }) {
    return Container(
      padding: EdgeInsets.all(
        isMobile ? 10 : (isCompact ? 12 : 16),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isMobile ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: isMobile
          ? // Mobile layout - horizontal organization for better space usage
          Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${percentage.toStringAsFixed(0)}%)',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            )
          : // Desktop/tablet layout - vertical organization
          Column(
              children: [
                // Icône et valeur
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isCompact ? 6 : 8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: isCompact ? 16 : 20,
                      ),
                    ),
                    SizedBox(width: isCompact ? 6 : 8),
                    Flexible(
                      child: Text(
                        value,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isCompact ? 20 : 24,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isCompact ? 6 : 8),

                // Label
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isCompact ? 10 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isCompact ? 2 : 4),

                // Pourcentage
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: isCompact ? 8 : 10,
                  ),
                ),
              ],
            ),
    );
  }
}
