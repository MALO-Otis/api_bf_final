// Widget pour afficher l'état des contrôles qualité
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/collecte_models.dart';
import '../models/quality_control_models.dart';
import '../services/quality_control_service.dart';
import '../services/global_refresh_service.dart';

/// Widget qui affiche l'état des contrôles qualité pour une collecte
class QualityControlIndicator extends StatefulWidget {
  final BaseCollecte collecte;
  final bool showDetails;

  const QualityControlIndicator({
    super.key,
    required this.collecte,
    this.showDetails = true,
  });

  @override
  State<QualityControlIndicator> createState() =>
      _QualityControlIndicatorState();
}

class _QualityControlIndicatorState extends State<QualityControlIndicator> {
  late ValueNotifier<int> _refreshKey;
  StreamSubscription<String>? _qualityControlUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _refreshKey = ValueNotifier<int>(0);
    _setupGlobalRefreshListener();
  }

  @override
  void dispose() {
    _refreshKey.dispose();
    _qualityControlUpdateSubscription?.cancel();
    super.dispose();
  }

  /// Configure l'écoute des notifications globales
  void _setupGlobalRefreshListener() {
    final globalRefreshService = GlobalRefreshService();

    _qualityControlUpdateSubscription = globalRefreshService
        .qualityControlUpdatesStream
        .listen((containerCode) {
      if (mounted) {
        if (kDebugMode) {
          print(
              '📢 QualityControlIndicator: Notification contrôle mis à jour - $containerCode');
        }
        _refreshKey.value++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<int>(
      valueListenable: _refreshKey,
      builder: (context, refreshValue, child) {
        return FutureBuilder<Map<String, int>>(
          key: ValueKey('quality_control_indicator_$refreshValue'),
          future: _getControlStats(),
          builder: (context, statsSnapshot) {
            if (statsSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingIndicator(theme);
            }

            final stats = statsSnapshot.data ?? {'total': 0, 'controlled': 0};
            return _buildControlInfo(theme, stats);
          },
        );
      },
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '...',
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlInfo(ThemeData theme, Map<String, int> stats) {
    final total = stats['total'] ?? 0;
    final controlled = stats['controlled'] ?? 0;
    final percentage = total > 0 ? (controlled / total) * 100 : 0.0;

    // Déterminer la couleur en fonction du pourcentage
    Color backgroundColor;
    Color textColor;
    IconData icon;

    if (percentage >= 100) {
      backgroundColor = Colors.green.shade100;
      textColor = Colors.green.shade700;
      icon = Icons.check_circle;
    } else if (percentage >= 80) {
      backgroundColor = Colors.orange.shade100;
      textColor = Colors.orange.shade700;
      icon = Icons.warning;
    } else if (percentage > 0) {
      backgroundColor = Colors.red.shade100;
      textColor = Colors.red.shade700;
      icon = Icons.error;
    } else {
      backgroundColor = theme.colorScheme.surfaceVariant;
      textColor = theme.colorScheme.onSurfaceVariant;
      icon = Icons.pending;
    }

    if (widget.showDetails) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: textColor,
            ),
            const SizedBox(width: 4),
            Text(
              '$controlled/$total contrôlés',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            if (total > 0) ...[
              const SizedBox(width: 4),
              Text(
                '(${percentage.toStringAsFixed(0)}%)',
                style: TextStyle(
                  fontSize: 10,
                  color: textColor.withOpacity(0.8),
                ),
              ),
            ],
          ],
        ),
      );
    } else {
      // Version compacte
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: textColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 10,
          color: textColor,
        ),
      );
    }
  }

  Future<Map<String, int>> _getControlStats() async {
    final qualityService = QualityControlService();

    try {
      // Essayer la nouvelle méthode optimisée qui lit directement depuis les données de collecte
      final optimizedStats =
          qualityService.getControlStatsFromCollecteData(widget.collecte);

      // Si on a des contenants mais aucun contrôlé avec la méthode optimisée,
      // cela peut signifier que les données sont anciennes sans le champ controlInfo
      if (optimizedStats['total']! > 0 && optimizedStats['controlled'] == 0) {
        // Fallback vers l'ancienne méthode pour les données existantes
        final containerCount = widget.collecte.containersCount ?? 0;
        if (containerCount == 0) {
          return {'total': 0, 'controlled': 0};
        }

        final containerCodes = List.generate(containerCount,
            (index) => 'C${(index + 1).toString().padLeft(3, '0')}');

        return await qualityService.getControlStatsForContainers(
            containerCodes, widget.collecte.date);
      }

      return optimizedStats;
    } catch (e) {
      if (kDebugMode) {
        print(
            '⚠️ QualityControlIndicator: Erreur méthode optimisée, fallback vers ancienne méthode: $e');
      }
      // Fallback vers l'ancienne méthode en cas d'erreur
      final containerCount = widget.collecte.containersCount ?? 0;
      if (containerCount == 0) {
        return {'total': 0, 'controlled': 0};
      }

      final containerCodes = List.generate(containerCount,
          (index) => 'C${(index + 1).toString().padLeft(3, '0')}');

      return await qualityService.getControlStatsForContainers(
          containerCodes, widget.collecte.date);
    }
  }
}
