import 'package:flutter/material.dart';
import '../models/extraction_models.dart';

/// Widget de carte pour afficher un produit d'extraction
class ExtractionCard extends StatelessWidget {
  final ExtractionProduct product;
  final VoidCallback? onTap;
  final VoidCallback? onStartExtraction;
  final VoidCallback? onCompleteExtraction;
  final VoidCallback? onSuspendExtraction;
  final bool?
      isDesktopMode; // Nouvelle propriété pour éviter les erreurs de context

  const ExtractionCard({
    super.key,
    required this.product,
    this.onTap,
    this.onStartExtraction,
    this.onCompleteExtraction,
    this.onSuspendExtraction,
    this.isDesktopMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isVerySmall = screenWidth < 480;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 9,
        vertical: 8,
      ),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: BoxConstraints(
            minHeight:
                screenWidth >= 1024 ? 320 : (screenWidth >= 768 ? 280 : 200),
            maxHeight:
                double.infinity, // Pas de limite pour éviter les overflows
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header avec statut et priorité
                _buildHeader(theme, isMobile),

                const SizedBox(height: 8),

                // Informations principales
                _buildMainInfo(theme, isMobile, isVerySmall),

                const SizedBox(height: 8),

                // Métriques
                _buildMetrics(theme, isMobile, isVerySmall),

                if (product.instructions != null ||
                    product.commentaires != null) ...[
                  const SizedBox(height: 8),
                  _buildAdditionalInfo(theme, isMobile),
                ],

                const SizedBox(height: 8),

                // Boutons d'action - toujours visible
                _buildActionButtons(theme, isMobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Header avec statut et priorité
  Widget _buildHeader(ThemeData theme, bool isMobile) {
    // Vérifier si ce produit vient du module contrôle
    final isFromControl = product.qualite['created_from_control'] == true;

    return Row(
      children: [
        // Indicateur module contrôle (si applicable)
        if (isFromControl) ...[
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 6 : 8,
              vertical: isMobile ? 3 : 4,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade700],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.assignment_turned_in,
                  size: isMobile ? 12 : 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  'CONTRÔLE',
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],

        // Statut badge
        _buildStatusBadge(theme, isMobile),

        const SizedBox(width: 5),

        // Priorité badge
        _buildPriorityBadge(theme, isMobile),

        const Spacer(),

        // ID du produit
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 8,
            vertical: isMobile ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            product.id,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  /// Badge de statut
  Widget _buildStatusBadge(ThemeData theme, bool isMobile) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (product.statut) {
      case ExtractionStatus.enAttente:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        icon = Icons.schedule;
        break;
      case ExtractionStatus.enCours:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        icon = Icons.play_circle;
        break;
      case ExtractionStatus.termine:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      case ExtractionStatus.suspendu:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        icon = Icons.pause_circle;
        break;
      case ExtractionStatus.erreur:
        backgroundColor = Colors.red.shade200;
        textColor = Colors.red.shade800;
        icon = Icons.error;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 8,
        vertical: isMobile ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isMobile ? 14 : 14,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            product.statut.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 11 : 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Badge de priorité
  Widget _buildPriorityBadge(ThemeData theme, bool isMobile) {
    if (product.priorite == ExtractionPriority.normale) {
      return const SizedBox.shrink();
    }

    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (product.priorite) {
      case ExtractionPriority.urgente:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        icon = Icons.priority_high;
        break;
      case ExtractionPriority.differee:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        icon = Icons.schedule_send;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 6,
        vertical: isMobile ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isMobile ? 12 : 12,
            color: textColor,
          ),
          const SizedBox(width: 2),
          Text(
            product.priorite.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: isMobile ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Informations principales
  Widget _buildMainInfo(ThemeData theme, bool isMobile, bool isVerySmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nom du produit
        Text(
          product.nom,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 16 : 17,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 8),

        // Informations en ligne ou colonne selon l'espace
        if (isVerySmall)
          _buildMainInfoColumn(theme)
        else
          _buildMainInfoRow(theme, isMobile),
      ],
    );
  }

  /// Informations principales en colonne (très petit écran)
  Widget _buildMainInfoColumn(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoItem(theme, Icons.category, 'Type', product.type.label),
        const SizedBox(height: 2),
        _buildInfoItem(theme, Icons.location_on, 'Origine', product.origine),
        const SizedBox(height: 2),
        _buildInfoItem(theme, Icons.person, 'Collecteur', product.collecteur),
        const SizedBox(height: 2),
        _buildInfoItem(
            theme, Icons.engineering, 'Extracteur', product.extracteurId),
      ],
    );
  }

  /// Informations principales en ligne
  Widget _buildMainInfoRow(ThemeData theme, bool isMobile) {
    final isDesktop = isDesktopMode ?? false;

    if (isDesktop) {
      // Desktop: version compacte en ligne pour éviter les overflows
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompactInfoItem(
              theme, Icons.category, 'Type', product.type.label),
          const SizedBox(height: 3),
          _buildCompactInfoItem(
              theme, Icons.location_on, 'Origine', product.origine),
          const SizedBox(height: 3),
          _buildCompactInfoItem(
              theme, Icons.person, 'Collecteur', product.collecteur),
        ],
      );
    } else {
      // Mobile/Tablette: Wrap normal
      return Wrap(
        spacing: isMobile ? 12 : 14,
        runSpacing: 6,
        children: [
          _buildInfoItem(theme, Icons.category, 'Type', product.type.label),
          _buildInfoItem(theme, Icons.location_on, 'Origine', product.origine),
          _buildInfoItem(theme, Icons.person, 'Collecteur', product.collecteur),
          _buildInfoItem(
              theme, Icons.engineering, 'Extracteur', product.extracteurId),
        ],
      );
    }
  }

  /// Item d'information
  Widget _buildInfoItem(
      ThemeData theme, IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            fontSize: 10,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Item d'information compact pour desktop
  Widget _buildCompactInfoItem(
      ThemeData theme, IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Métriques
  Widget _buildMetrics(ThemeData theme, bool isMobile, bool isVerySmall) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: isVerySmall
          ? _buildMetricsColumn(theme)
          : _buildMetricsRow(theme, isMobile),
    );
  }

  /// Métriques en colonne
  Widget _buildMetricsColumn(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildMetricItem(
                    theme, 'Contenants', '${product.quantiteContenants}')),
            const SizedBox(width: 12),
            Expanded(
                child: _buildMetricItem(theme, 'Poids',
                    '${product.poidsTotal.toStringAsFixed(1)} kg')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildMetricItem(theme, 'Attribution',
                    _formatDate(product.dateAttribution))),
            const SizedBox(width: 12),
            Expanded(
                child: _buildMetricItem(
                    theme,
                    'Rendement',
                    product.rendementExtraction != null
                        ? '${product.rendementExtraction!.toStringAsFixed(1)}%'
                        : 'N/A')),
          ],
        ),
      ],
    );
  }

  /// Métriques en ligne
  Widget _buildMetricsRow(ThemeData theme, bool isMobile) {
    final isDesktop = isDesktopMode ?? false;

    if (isDesktop) {
      // Desktop: métriques compactes en ligne
      return Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          _buildCompactMetric(
              theme, 'Contenants', '${product.quantiteContenants}'),
          _buildCompactMetric(
              theme, 'Poids', '${product.poidsTotal.toStringAsFixed(1)} kg'),
          _buildCompactMetric(
              theme, 'Attribution', _formatDate(product.dateAttribution)),
        ],
      );
    } else {
      // Mobile/Tablette: ligne simple
      return Row(
        children: [
          Expanded(
              child: _buildMetricItem(
                  theme, 'Contenants', '${product.quantiteContenants}')),
          const SizedBox(width: 16),
          Expanded(
              child: _buildMetricItem(theme, 'Poids',
                  '${product.poidsTotal.toStringAsFixed(1)} kg')),
          const SizedBox(width: 16),
          Expanded(
              child: _buildMetricItem(
                  theme, 'Attribution', _formatDate(product.dateAttribution))),
          if (!isMobile) ...[
            const SizedBox(width: 16),
            Expanded(
                child: _buildMetricItem(
                    theme,
                    'Rendement',
                    product.rendementExtraction != null
                        ? '${product.rendementExtraction!.toStringAsFixed(1)}%'
                        : 'N/A')),
          ],
        ],
      );
    }
  }

  /// Item de métrique
  Widget _buildMetricItem(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Métrique compacte pour desktop
  Widget _buildCompactMetric(ThemeData theme, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Informations supplémentaires
  Widget _buildAdditionalInfo(ThemeData theme, bool isMobile) {
    final bool isDesktop = isDesktopMode ?? false;

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product.instructions != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: isDesktop ? 14 : 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  product.instructions!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
        ],
        if (product.instructions != null && product.commentaires != null)
          const SizedBox(height: 8),
        if (product.commentaires != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.comment_outlined,
                size: isDesktop ? 14 : 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  product.commentaires!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
        ],
      ],
    );

    // Sur desktop, rendre la section scrollable pour éviter tout overflow
    if (isDesktop) {
      content = Scrollbar(
        thickness: 4,
        radius: const Radius.circular(8),
        child: SingleChildScrollView(
          child: content,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: content,
    );
  }

  /// Boutons d'action
  Widget _buildActionButtons(ThemeData theme, bool isMobile) {
    final isDesktop = isDesktopMode ?? false;
    final buttons = <Widget>[];

    switch (product.statut) {
      case ExtractionStatus.enAttente:
        buttons.add(
          _buildActionButton(
            theme,
            'Démarrer',
            Icons.play_arrow,
            theme.colorScheme.primary,
            onStartExtraction,
            isMobile,
          ),
        );
        break;

      case ExtractionStatus.enCours:
        buttons.addAll([
          _buildActionButton(
            theme,
            'Terminer',
            Icons.check,
            Colors.green,
            onCompleteExtraction,
            isMobile,
          ),
          SizedBox(width: isDesktop ? 6 : 8),
          _buildActionButton(
            theme,
            'Suspendre',
            Icons.pause,
            Colors.orange,
            onSuspendExtraction,
            isMobile,
          ),
        ]);
        break;

      case ExtractionStatus.suspendu:
        buttons.add(
          _buildActionButton(
            theme,
            'Reprendre',
            Icons.play_arrow,
            theme.colorScheme.primary,
            onStartExtraction,
            isMobile,
          ),
        );
        break;

      default:
        // Pas de boutons pour les statuts terminé et erreur
        break;
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    // Sur desktop, utiliser Wrap pour éviter les overflows
    if (isDesktop) {
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: buttons.where((widget) => widget is! SizedBox).toList(),
      );
    } else {
      return Row(
        children: buttons,
      );
    }
  }

  /// Bouton d'action
  Widget _buildActionButton(
    ThemeData theme,
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed,
    bool isMobile,
  ) {
    final isDesktop = isDesktopMode ?? false;

    if (isDesktop) {
      // Version desktop plus compacte
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          textStyle: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          minimumSize: const Size(80, 32),
        ),
      );
    } else {
      // Version mobile/tablette normale
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: isMobile ? 16 : 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 8 : 12,
          ),
          textStyle: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 12 : 14,
          ),
        ),
      );
    }
  }

  /// Formate une date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Widget de squelette pour le chargement
class ExtractionCardSkeleton extends StatelessWidget {
  const ExtractionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16,
        vertical: 8,
      ),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header skeleton
            Row(
              children: [
                Container(
                  width: 80,
                  height: 24,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 60,
                  height: 20,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 50,
                  height: 24,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Title skeleton
            Container(
              width: double.infinity,
              height: 20,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            const SizedBox(height: 8),

            // Info skeleton
            Row(
              children: [
                Container(
                  width: 100,
                  height: 16,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 80,
                  height: 16,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Metrics skeleton
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            const SizedBox(height: 12),

            // Button skeleton
            Container(
              width: 100,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
