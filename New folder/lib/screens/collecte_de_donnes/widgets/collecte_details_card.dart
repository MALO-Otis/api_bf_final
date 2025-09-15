/// Card de détails modernisée pour les collectes avec codes de localisation
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'localisation_code_widget.dart';

class CollecteDetailsCard extends StatelessWidget {
  final Map<String, dynamic> collecteData;
  final String type; // 'Récoltes', 'SCOOP', 'Individuel'
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CollecteDetailsCard({
    super.key,
    required this.collecteData,
    required this.type,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    return Card(
      elevation: 2,
      margin: EdgeInsets.all(isMobile ? 8 : 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec type et actions
            _buildHeader(context, theme, isMobile),

            const SizedBox(height: 20),

            // Informations générales
            _buildGeneralInfo(context, theme, isMobile),

            const SizedBox(height: 16),

            // Localisation avec codes
            _buildLocalisationSection(context, theme),

            const SizedBox(height: 16),

            // Informations spécifiques selon le type
            _buildSpecificInfo(context, theme, isMobile),

            const SizedBox(height: 16),

            // Statistiques
            _buildStatistics(context, theme, isMobile),

            if (collecteData['observations'] != null &&
                collecteData['observations'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildObservations(context, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isMobile) {
    final typeColor = _getTypeColor(type);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: typeColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getTypeIcon(type),
                color: typeColor,
                size: isMobile ? 14 : 16,
              ),
              const SizedBox(width: 6),
              Text(
                type,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: typeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 11 : 12,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Actions
        if (onEdit != null || onDelete != null) ...[
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: Colors.grey.shade600,
            ),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onEdit?.call();
                  break;
                case 'delete':
                  onDelete?.call();
                  break;
              }
            },
            itemBuilder: (context) => [
              if (onEdit != null)
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ],
                  ),
                ),
              if (onDelete != null)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildGeneralInfo(
      BuildContext context, ThemeData theme, bool isMobile) {
    final date = collecteData['date'];
    String formattedDate = 'Date non définie';

    if (date != null) {
      try {
        final dateTime =
            date is DateTime ? date : DateTime.parse(date.toString());
        formattedDate = DateFormat('dd/MM/yyyy à HH:mm').format(dateTime);
      } catch (e) {
        formattedDate = date.toString();
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            'ID',
            collecteData['id']?.toString() ?? 'Non défini',
            Icons.fingerprint,
            theme,
            isMobile,
            copyable: true,
            context: context,
          ),
          _buildInfoRow(
            'Date',
            formattedDate,
            Icons.calendar_today,
            theme,
            isMobile,
            context: context,
          ),
          if (collecteData['technicien'] != null)
            _buildInfoRow(
              'Technicien',
              collecteData['technicien'].toString(),
              Icons.person,
              theme,
              isMobile,
              context: context,
            ),
          if (collecteData['statut'] != null)
            _buildInfoRow(
              'Statut',
              collecteData['statut'].toString(),
              Icons.info,
              theme,
              isMobile,
              context: context,
            ),
        ],
      ),
    );
  }

  Widget _buildLocalisationSection(BuildContext context, ThemeData theme) {
    final localisation = {
      'region': collecteData['region']?.toString() ?? '',
      'province': collecteData['province']?.toString() ?? '',
      'commune': collecteData['commune']?.toString() ?? '',
      'village': collecteData['village']?.toString() ?? '',
    };

    return LocalisationCodeWidget(
      localisation: localisation,
      showCopyButton: true,
      showHierarchy: true,
      accentColor: _getTypeColor(type),
    );
  }

  Widget _buildSpecificInfo(
      BuildContext context, ThemeData theme, bool isMobile) {
    switch (type) {
      case 'SCOOP':
        return _buildScoopInfo(context, theme, isMobile);
      case 'Récoltes':
        return _buildRecolteInfo(context, theme, isMobile);
      case 'Individuel':
        return _buildIndividuelInfo(context, theme, isMobile);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildScoopInfo(BuildContext context, ThemeData theme, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Informations SCOOP',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (collecteData['scoop_name'] != null)
            _buildInfoRow(
              'SCOOP',
              collecteData['scoop_name'].toString(),
              Icons.business,
              theme,
              isMobile,
              context: context,
            ),
          if (collecteData['periode_collecte'] != null)
            _buildInfoRow(
              'Période',
              collecteData['periode_collecte'].toString(),
              Icons.schedule,
              theme,
              isMobile,
              context: context,
            ),
          if (collecteData['nombre_producteurs'] != null)
            _buildInfoRow(
              'Producteurs',
              '${collecteData['nombre_producteurs']}',
              Icons.group,
              theme,
              isMobile,
              context: context,
            ),
          if (collecteData['qualite'] != null)
            _buildInfoRow(
              'Qualité',
              collecteData['qualite'].toString(),
              Icons.star,
              theme,
              isMobile,
              context: context,
            ),
        ],
      ),
    );
  }

  Widget _buildRecolteInfo(
      BuildContext context, ThemeData theme, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.agriculture, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Informations Récolte',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (collecteData['periode_collecte'] != null)
            _buildInfoRow(
              'Période',
              collecteData['periode_collecte'].toString(),
              Icons.calendar_month,
              theme,
              isMobile,
              context: context,
            ),
          if (collecteData['type_recolte'] != null)
            _buildInfoRow(
              'Type de récolte',
              collecteData['type_recolte'].toString(),
              Icons.category,
              theme,
              isMobile,
              context: context,
            ),
        ],
      ),
    );
  }

  Widget _buildIndividuelInfo(
      BuildContext context, ThemeData theme, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Informations Producteur',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (collecteData['producteur_nom'] != null)
            _buildInfoRow(
              'Producteur',
              collecteData['producteur_nom'].toString(),
              Icons.account_circle,
              theme,
              isMobile,
              context: context,
            ),
          if (collecteData['periode_collecte'] != null)
            _buildInfoRow(
              'Période',
              collecteData['periode_collecte'].toString(),
              Icons.schedule,
              theme,
              isMobile,
              context: context,
            ),
        ],
      ),
    );
  }

  Widget _buildStatistics(
      BuildContext context, ThemeData theme, bool isMobile) {
    final stats = [
      {
        'label': 'Poids total',
        'value': _formatWeight(collecteData['poids_total']),
        'icon': Icons.scale,
        'color': Colors.blue,
      },
      {
        'label': 'Montant total',
        'value': _formatAmount(collecteData['montant_total']),
        'icon': Icons.attach_money,
        'color': Colors.green,
      },
      {
        'label': 'Contenants',
        'value': '${collecteData['nombre_contenants'] ?? 0}',
        'icon': Icons.inventory,
        'color': Colors.orange,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.05),
            theme.colorScheme.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Statistiques',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: stats
                .map((stat) => Expanded(
                      child: _buildStatCard(
                        stat['label'] as String,
                        stat['value'] as String,
                        stat['icon'] as IconData,
                        stat['color'] as Color,
                        theme,
                        isMobile,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color,
      ThemeData theme, bool isMobile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isMobile ? 18 : 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: isMobile ? 12 : 14,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: isMobile ? 9 : 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildObservations(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note, color: Colors.grey.shade700, size: 18),
              const SizedBox(width: 8),
              Text(
                'Observations',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            collecteData['observations'].toString(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      String label, String value, IconData icon, ThemeData theme, bool isMobile,
      {bool copyable = false, BuildContext? context}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.grey.shade600,
            size: isMobile ? 14 : 16,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: isMobile ? 80 : 100,
            child: Text(
              '$label:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontSize: isMobile ? 11 : 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: isMobile ? 11 : 12,
              ),
            ),
          ),
          if (copyable && context != null)
            InkWell(
              onTap: () => _copyToClipboard(context, value),
              child: Icon(
                Icons.copy,
                color: Colors.grey.shade500,
                size: 14,
              ),
            ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    // Implementation identique à LocalisationCodeWidget
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'SCOOP':
        return Colors.blue;
      case 'Récoltes':
        return Colors.green;
      case 'Individuel':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'SCOOP':
        return Icons.groups;
      case 'Récoltes':
        return Icons.agriculture;
      case 'Individuel':
        return Icons.person;
      default:
        return Icons.category;
    }
  }

  String _formatWeight(dynamic weight) {
    if (weight == null) return '0,00 kg';
    try {
      final value = weight is double ? weight : double.parse(weight.toString());
      return '${value.toStringAsFixed(2)} kg';
    } catch (e) {
      return '$weight kg';
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0 FCFA';
    try {
      final value = amount is double ? amount : double.parse(amount.toString());
      return '${NumberFormat('#,###').format(value.round())} FCFA';
    } catch (e) {
      return '$amount FCFA';
    }
  }
}
