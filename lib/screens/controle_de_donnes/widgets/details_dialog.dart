// Dialog de détails d'une collecte
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/collecte_models.dart';
import '../models/quality_control_models.dart';
import '../utils/formatters.dart';
import '../services/quality_control_service.dart';
import 'stat_card.dart';
import 'quality_control_form.dart';

class DetailsDialog extends StatelessWidget {
  final bool isOpen;
  final ValueChanged<bool> onOpenChange;
  final Section section;
  final BaseCollecte? item;

  const DetailsDialog({
    super.key,
    required this.isOpen,
    required this.onOpenChange,
    required this.section,
    this.item,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOpen || item == null) return const SizedBox.shrink();

    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final isVerySmall = screenSize.width < 360;

    if (isMobile) {
      // Sur mobile, utiliser un bottom sheet full screen
      return Container(
        height: screenSize.height * 0.9, // 90% de la hauteur d'écran
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Poignée pour indiquer qu'on peut glisser
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildMobileHeader(context, isVerySmall),
            Expanded(
              child: _buildMobileContent(context, isVerySmall),
            ),
            _buildMobileFooter(context, isVerySmall),
          ],
        ),
      );
    } else {
      // Desktop : dialog original
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 840, maxHeight: 600),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              Flexible(
                child: _buildContent(context),
              ),
              _buildFooter(context),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final sectionLabel = Formatters.getSectionLabel(section);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(
            _getSectionIcon(),
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Détails — $sectionLabel',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  Formatters.getTitleForCollecte(section, item!),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => onOpenChange(false),
            icon: const Icon(Icons.close),
            tooltip: 'Fermer',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informations globales
          _buildGlobalInfo(context),

          const SizedBox(height: 20),

          // Statistiques
          _buildStats(context),

          const SizedBox(height: 20),

          // Informations spécifiques selon la section
          _buildSectionSpecificInfo(context),

          const SizedBox(height: 20),

          // Tableau des contenants
          _buildContenantsTable(context),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () => _copyToClipboard(context, item!.id, 'ID collecte'),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copier ID'),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () =>
                _copyToClipboard(context, item!.path, 'Chemin Firestore'),
            icon: const Icon(Icons.link, size: 16),
            label: const Text('Copier chemin'),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => _showNotImplemented(context, 'Export PDF'),
            icon: const Icon(Icons.picture_as_pdf, size: 16),
            label: const Text('Export PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalInfo(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isMobile ? 2 : 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isMobile ? 2.5 : 3.0,
          children: [
            _buildInfoField(context, 'ID', item!.id, copyable: true),
            _buildInfoField(context, 'Site', item!.site),
            _buildInfoField(
                context, 'Date', Formatters.formatDateTime(item!.date)),
            _buildInfoField(context, 'Technicien', item!.technicien ?? '—'),
            _buildInfoField(
                context, 'Statut', Formatters.formatStatut(item!.statut)),
            _buildInfoField(context, 'Chemin', item!.path, copyable: true),
          ],
        );
      },
    );
  }

  Widget _buildInfoField(BuildContext context, String label, String value,
      {bool copyable = false}) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (copyable)
                IconButton(
                  onPressed: () => _copyToClipboard(context, value, label),
                  icon: const Icon(Icons.copy, size: 14),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Copier',
                ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    return StatsRow(
      stats: [
        StatMini(
          label: 'Poids total',
          value: Formatters.formatKg(item!.totalWeight),
          icon: Icons.scale,
          color: Colors.green.shade600,
        ),
        StatMini(
          label: 'Montant total',
          value: Formatters.formatFCFA(item!.totalAmount),
          icon: Icons.attach_money,
          color: Colors.orange.shade600,
        ),
        StatMini(
          label: '#contenants',
          value: Formatters.formatNumber(item!.containersCount),
          icon: Icons.inventory_2,
          color: Colors.blue.shade600,
        ),
      ],
    );
  }

  Widget _buildSectionSpecificInfo(BuildContext context) {
    switch (section) {
      case Section.recoltes:
        if (item is Recolte) {
          return _buildRecoltesInfo(context, item as Recolte);
        }
        break;
      case Section.scoop:
        if (item is Scoop) {
          return _buildScoopInfo(context, item as Scoop);
        }
        break;
      case Section.individuel:
        if (item is Individuel) {
          return _buildIndividuelInfo(context, item as Individuel);
        }
        break;
    }
    return const SizedBox.shrink();
  }

  Widget _buildRecoltesInfo(BuildContext context, Recolte recolte) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations géographiques',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isMobile ? 2 : 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isMobile ? 2.5 : 3.0,
              children: [
                _buildInfoField(context, 'Région', recolte.region ?? '—'),
                _buildInfoField(context, 'Province', recolte.province ?? '—'),
                _buildInfoField(context, 'Commune', recolte.commune ?? '—'),
                _buildInfoField(context, 'Village', recolte.village ?? '—'),
              ],
            );
          },
        ),
        if (recolte.predominancesFlorales?.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          Text(
            'Prédominances florales',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          _buildChips(context, recolte.predominancesFlorales!),
        ],
      ],
    );
  }

  Widget _buildScoopInfo(BuildContext context, Scoop scoop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations SCOOP',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isMobile ? 2 : 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isMobile ? 2.5 : 3.0,
              children: [
                _buildInfoField(context, 'Nom SCOOP', scoop.scoopNom),
                _buildInfoField(
                    context, 'Période', scoop.periodeCollecte ?? '—'),
                _buildInfoField(context, 'Qualité', scoop.qualite ?? '—'),
                _buildInfoField(
                    context, 'Localisation', scoop.localisation ?? '—'),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildIndividuelInfo(BuildContext context, Individuel individuel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations producteur',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isMobile ? 1 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isMobile ? 3.0 : 3.5,
              children: [
                _buildInfoField(
                    context, 'Producteur', individuel.nomProducteur),
                _buildInfoField(
                    context, 'Observations', individuel.observations ?? '—'),
              ],
            );
          },
        ),
        if (individuel.originesFlorales?.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          Text(
            'Origines florales',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          _buildChips(context, individuel.originesFlorales!),
        ],
      ],
    );
  }

  Widget _buildChips(BuildContext context, List<String> items) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Chip(
              label: Text(
                item,
                style: theme.textTheme.labelSmall,
              ),
              backgroundColor: theme.colorScheme.secondaryContainer,
              side: BorderSide.none,
            ),
          )
          .toList(),
    );
  }

  Widget _buildContenantsTable(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contenants',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Table responsive
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return _buildMobileContenantsView(context);
            } else {
              return _buildDesktopContenantsTableWithControl(context);
            }
          },
        ),
      ],
    );
  }

  Widget _buildDesktopContenantsTable(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: _getTableHeaders()
                  .map((header) => Expanded(
                        child: Text(
                          header,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),

          // Lignes de données
          ..._getTableRows().asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: index.isEven
                    ? theme.colorScheme.surface
                    : theme.colorScheme.surfaceVariant.withOpacity(0.2),
                borderRadius: index == _getTableRows().length - 1
                    ? const BorderRadius.vertical(bottom: Radius.circular(8))
                    : null,
              ),
              child: Row(
                children: row
                    .map((cell) => Expanded(
                          child: Text(
                            cell,
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMobileContenantsView(BuildContext context) {
    final theme = Theme.of(context);
    final rows = _getTableRows();

    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'Aucun contenant trouvé',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contenants (${rows.length})',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...rows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          final containerCode = 'C${(index + 1).toString().padLeft(3, '0')}';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header du contenant avec bouton contrôler
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Contenant $containerCode',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () {
                          final qualityService = QualityControlService();
                          final existingControl = qualityService
                              .getQualityControl(containerCode, item!.date);
                          _showQualityControlForm(context, containerCode,
                              existingData: existingControl);
                        },
                        icon: const Icon(Icons.fact_check, size: 16),
                        label: const Text('Contrôler'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 32),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Détails du contenant
                  ..._getTableHeaders().asMap().entries.map((headerEntry) {
                    final headerIndex = headerEntry.key;
                    final header = headerEntry.value;
                    final value =
                        headerIndex < row.length ? row[headerIndex] : '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 90,
                            child: Text(
                              '$header:',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              value,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Status indicateur du contrôle
                  const SizedBox(height: 8),
                  _buildControlStatus(context, containerCode),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  List<String> _getTableHeaders() {
    switch (section) {
      case Section.recoltes:
        return [
          'Type ruche',
          'Type contenant',
          'Poids (kg)',
          'Prix unitaire',
          'Montant'
        ];
      case Section.scoop:
      case Section.individuel:
        return [
          'Type contenant',
          'Type miel',
          'Quantité (kg)',
          'Prix unitaire',
          'Montant'
        ];
    }
  }

  List<List<String>> _getTableRows() {
    if (item == null) return [];

    switch (section) {
      case Section.recoltes:
        if (item is Recolte) {
          final recolte = item as Recolte;
          return recolte.contenants
              .map((c) => [
                    c.hiveType,
                    c.containerType,
                    Formatters.formatKg(c.weight),
                    Formatters.formatFCFA(c.unitPrice),
                    Formatters.formatFCFA(c.total),
                  ])
              .toList();
        }
        break;

      case Section.scoop:
        if (item is Scoop) {
          final scoop = item as Scoop;
          return scoop.contenants
              .map((c) => [
                    c.typeContenant,
                    c.typeMiel,
                    Formatters.formatKg(c.quantite),
                    Formatters.formatFCFA(c.prixUnitaire),
                    Formatters.formatFCFA(c.montantTotal),
                  ])
              .toList();
        }
        break;

      case Section.individuel:
        if (item is Individuel) {
          final individuel = item as Individuel;
          return individuel.contenants
              .map((c) => [
                    c.typeContenant,
                    c.typeMiel,
                    Formatters.formatKg(c.quantite),
                    Formatters.formatFCFA(c.prixUnitaire),
                    Formatters.formatFCFA(c.montantTotal),
                  ])
              .toList();
        }
        break;
    }
    return [];
  }

  IconData _getSectionIcon() {
    switch (section) {
      case Section.recoltes:
        return Icons.agriculture;
      case Section.scoop:
        return Icons.group;
      case Section.individuel:
        return Icons.person;
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label copié dans le presse-papiers')),
      );
    }
  }

  void _showNotImplemented(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature sera bientôt disponible')),
    );
  }

  // Nouvelles fonctions pour mobile
  Widget _buildMobileHeader(BuildContext context, bool isVerySmall) {
    final theme = Theme.of(context);
    final sectionLabel = Formatters.getSectionLabel(section);

    return Container(
      padding: EdgeInsets.all(isVerySmall ? 12 : 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getSectionIcon(),
                      size: 14,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      sectionLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => onOpenChange(false),
                icon: const Icon(Icons.close),
                iconSize: 20,
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.getTitleForCollecte(section, item!),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isVerySmall ? 16 : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.getSubtitleForCollecte(item!),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: isVerySmall ? 12 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileContent(BuildContext context, bool isVerySmall) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isVerySmall ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Métriques principales en grid mobile
          _buildMobileMetrics(context, isVerySmall),

          const SizedBox(height: 16),

          // Informations détaillées
          _buildMobileInfoSection(context, isVerySmall),

          const SizedBox(height: 16),

          // Section spécifique selon le type
          _buildSectionSpecificInfo(context),

          const SizedBox(height: 16),

          // Contenants en format mobile
          if (item != null) _buildMobileContenantsView(context),
        ],
      ),
    );
  }

  Widget _buildMobileFooter(BuildContext context, bool isVerySmall) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(isVerySmall ? 12 : 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Actions principales en mobile
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyToClipboard(
                    context,
                    item!.id,
                    'ID',
                  ),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copier ID'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          if (!isVerySmall) ...[
            const SizedBox(height: 8),
            Text(
              'ID: ${item!.id}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileMetrics(BuildContext context, bool isVerySmall) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMobileStat(
                  context,
                  'Poids total',
                  Formatters.formatKg(item!.totalWeight),
                  Icons.scale,
                  isVerySmall,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMobileStat(
                  context,
                  'Montant total',
                  Formatters.formatFCFA(item!.totalAmount),
                  Icons.attach_money,
                  isVerySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMobileStat(
                  context,
                  'Contenants',
                  '${_getContainerCount(item!)}',
                  Icons.inventory_2,
                  isVerySmall,
                ),
              ),
              Expanded(
                child: _buildMobileStat(
                  context,
                  'Date',
                  Formatters.formatDate(item!.date),
                  Icons.calendar_today,
                  isVerySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStat(BuildContext context, String label, String value,
      IconData icon, bool isVerySmall) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(isVerySmall ? 6 : 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: isVerySmall ? 16 : 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: isVerySmall ? 9 : 10,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isVerySmall ? 11 : 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileInfoSection(BuildContext context, bool isVerySmall) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border:
                Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMobileInfoRow('Site', item!.site, isVerySmall, context),
              _buildMobileInfoRow('Technicien',
                  item!.technicien ?? 'Non défini', isVerySmall, context),
              if (item!.statut != null)
                _buildMobileInfoRow(
                    'Statut',
                    Formatters.formatStatut(item!.statut),
                    isVerySmall,
                    context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileInfoRow(
      String label, String value, bool isVerySmall, BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isVerySmall ? 80 : 100,
            child: Text(
              '$label:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: isVerySmall ? 11 : null,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: isVerySmall ? 11 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthode helper pour obtenir le nombre de contenants
  int _getContainerCount(BaseCollecte item) {
    if (item is Recolte) {
      return item.contenants.length;
    } else if (item is Scoop) {
      return item.contenants.length;
    } else if (item is Individuel) {
      return item.contenants.length;
    }
    return 0;
  }

  // Fonction pour afficher le statut de contrôle d'un contenant
  Widget _buildControlStatus(BuildContext context, String containerCode) {
    final theme = Theme.of(context);
    final qualityService = QualityControlService();

    // Vérifier si le contenant a été contrôlé
    final existingControl =
        qualityService.getQualityControl(containerCode, item!.date);

    if (existingControl != null) {
      // Contenant déjà contrôlé
      final statusColor = QualityControlUtils.getConformityStatusColor(
          existingControl.conformityStatus);
      final statusIcon = QualityControlUtils.getConformityStatusIcon(
          existingControl.conformityStatus);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: statusColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              statusIcon,
              size: 14,
              color: statusColor,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contrôlé le ${Formatters.formatDate(existingControl.createdAt)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    QualityControlUtils.getConformityStatusLabel(
                        existingControl.conformityStatus),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showQualityControlForm(context, containerCode,
                  existingData: existingControl),
              icon: const Icon(Icons.edit, size: 14),
              tooltip: 'Modifier le contrôle',
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      );
    } else {
      // Contenant pas encore contrôlé
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pending_outlined,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              'Pas encore contrôlé',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
  }

  // Fonction pour afficher le formulaire de contrôle qualité
  void _showQualityControlForm(BuildContext context, String containerCode,
      {QualityControlData? existingData}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QualityControlForm(
        collecteItem: item!,
        containerCode: containerCode,
        existingData: existingData,
        onSave: () {
          Navigator.of(context).pop(); // Fermer le formulaire
          // Optionnel: actualiser les données ou afficher un message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                      'Contrôle du contenant $containerCode ${existingData != null ? 'mis à jour' : 'enregistré'}'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        },
        onCancel: () {
          Navigator.of(context).pop(); // Fermer le formulaire
        },
      ),
    );
  }

  // Fonction pour ajouter un bouton contrôler au desktop aussi
  Widget _buildDesktopContenantsTableWithControl(BuildContext context) {
    final theme = Theme.of(context);
    final headers = _getTableHeaders();
    final rows = _getTableRows();

    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun contenant trouvé',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contenants (${rows.length})',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border:
                Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                        width: 80,
                        child: Text('Code',
                            style: TextStyle(fontWeight: FontWeight.w600))),
                    ...headers.map((header) => Expanded(
                          child: Text(header,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        )),
                    const SizedBox(
                        width: 100,
                        child: Text('Actions',
                            style: TextStyle(fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
              // Rows
              ...rows.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                final containerCode =
                    'C${(index + 1).toString().padLeft(3, '0')}';

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            containerCode,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                      ...row.map((cell) => Expanded(child: Text(cell))),
                      SizedBox(
                        width: 100,
                        child: FilledButton.icon(
                          onPressed: () {
                            final qualityService = QualityControlService();
                            final existingControl = qualityService
                                .getQualityControl(containerCode, item!.date);
                            _showQualityControlForm(context, containerCode,
                                existingData: existingControl);
                          },
                          icon: const Icon(Icons.fact_check, size: 14),
                          label: const Text('Contrôler'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: const Size(0, 28),
                            textStyle: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
