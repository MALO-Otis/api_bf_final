import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/quality_control_service.dart';
import '../models/quality_control_models.dart';
import '../services/global_refresh_service.dart';
import 'dart:async';

/// Widget optimisé pour afficher l'état des contrôles d'une collecte
/// Utilise l'ID de collecte pour une récupération efficace
class OptimizedControlStatusWidget extends StatefulWidget {
  final String collecteId;
  final int totalContainers;
  final String collecteTitle;

  const OptimizedControlStatusWidget({
    super.key,
    required this.collecteId,
    required this.totalContainers,
    required this.collecteTitle,
  });

  @override
  State<OptimizedControlStatusWidget> createState() =>
      _OptimizedControlStatusWidgetState();
}

class _OptimizedControlStatusWidgetState
    extends State<OptimizedControlStatusWidget> {
  Map<String, dynamic> _controlStats = {};
  bool _isLoading = true;
  StreamSubscription<String>? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    _loadControlStats();
    _setupRefreshListener();
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    super.dispose();
  }

  /// Configure l'écoute des notifications pour mise à jour en temps réel
  void _setupRefreshListener() {
    final globalRefreshService = GlobalRefreshService();

    _refreshSubscription = globalRefreshService.qualityControlUpdatesStream
        .listen((notificationData) {
      if (mounted) {
        if (kDebugMode) {
          print('📢 OptimizedControl: Notification reçue - $notificationData');
        }

        // Vérifier si la notification concerne cette collecte
        if (notificationData.contains(':')) {
          // Format: "collecteId:containerCode"
          final parts = notificationData.split(':');
          if (parts.isNotEmpty && parts[0] == widget.collecteId) {
            if (kDebugMode) {
              print('🎯 Notification pour CETTE collecte ${widget.collecteId}');
            }
            _loadControlStats(); // Recharger uniquement si c'est pour cette collecte
          }
        } else {
          // Notification générale, recharger par sécurité
          if (kDebugMode) {
            print('🔄 Notification générale, rechargement...');
          }
          _loadControlStats();
        }
      }
    });

    // Aussi écouter les notifications de collecte
    globalRefreshService.collecteUpdatesStream.listen((collecteId) {
      if (mounted && collecteId == widget.collecteId) {
        if (kDebugMode) {
          print('📢 Notification collecte pour ${widget.collecteId}');
        }
        _loadControlStats();
      }
    });
  }

  /// Charge les statistiques de contrôle optimisées
  Future<void> _loadControlStats() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final qualityControlService = QualityControlService();

      // 🔄 FORCER L'INVALIDATION DU CACHE avant de charger
      qualityControlService.invalidateCollecteCache(widget.collecteId);

      final stats = await qualityControlService
          .getOptimizedControlStatusForCollecte(widget.collecteId);

      if (mounted) {
        setState(() {
          _controlStats = stats;
          _isLoading = false;
        });
      }

      if (kDebugMode) {
        print('✅ Statistiques RECHARGÉES pour collecte ${widget.collecteId}');
        print('📊 ${stats['totalControls']} contrôles trouvés');
        print('🔄 Cache forcé à se recharger');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors du chargement des stats: $e');
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec titre de la collecte
            Row(
              children: [
                Icon(
                  Icons.inventory_2,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.collecteTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Statistiques de contrôle
            if (!_isLoading) _buildControlStats(),
            if (_isLoading) _buildLoadingIndicator(),

            const SizedBox(height: 12),

            // Liste des contenants avec leur état
            if (!_isLoading) _buildContainersList(),
          ],
        ),
      ),
    );
  }

  /// Construit les statistiques de contrôle
  Widget _buildControlStats() {
    final totalControls = (_controlStats['totalControls'] ?? 0) as int;
    final controlledCount = totalControls;
    final uncontrolledCount = widget.totalContainers - controlledCount;

    return Row(
      children: [
        _buildStatChip(
          label: 'Total',
          value: widget.totalContainers,
          color: Colors.blue,
          icon: Icons.inventory,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          label: 'Contrôlés',
          value: controlledCount,
          color: Colors.green,
          icon: Icons.check_circle,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          label: 'Non contrôlés',
          value: uncontrolledCount,
          color: Colors.orange,
          icon: Icons.pending,
        ),
      ],
    );
  }

  /// Construit un chip de statistique
  Widget _buildStatChip({
    required String label,
    required int value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit l'indicateur de chargement
  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Construit la liste des contenants avec leur état
  Widget _buildContainersList() {
    final controlsByContainer = _controlStats['controlsByContainer']
            as Map<String, QualityControlData>? ??
        {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'État des contenants:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: List.generate(widget.totalContainers, (index) {
            final containerCode = 'C${(index + 1).toString().padLeft(3, '0')}';
            final control = controlsByContainer[containerCode];

            return _buildContainerChip(containerCode, control);
          }),
        ),
      ],
    );
  }

  /// Construit le chip d'un contenant
  Widget _buildContainerChip(
      String containerCode, QualityControlData? control) {
    Color color;
    IconData icon;
    String tooltip;

    if (control != null) {
      if (control.conformityStatus == ConformityStatus.conforme) {
        color = Colors.green;
        icon = Icons.check_circle;
        tooltip = 'Contrôlé - Conforme';
      } else {
        color = Colors.red;
        icon = Icons.error;
        tooltip = 'Contrôlé - Non conforme';
      }
    } else {
      color = Colors.grey;
      icon = Icons.radio_button_unchecked;
      tooltip = 'Non contrôlé';
    }

    return Tooltip(
      message: '$containerCode: $tooltip',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 2),
            Text(
              containerCode,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
