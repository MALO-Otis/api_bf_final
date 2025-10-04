import 'dart:async';
import 'stat_card.dart';
import 'package:get/get.dart';
import '../utils/formatters.dart';
import 'quality_control_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/collecte_models.dart';
import 'package:flutter/foundation.dart';
import '../models/quality_control_models.dart';
import '../services/global_refresh_service.dart';
import '../services/firestore_data_service.dart';
import '../services/quality_control_service.dart';
import '../../../authentication/user_session.dart';
import '../../collecte_de_donnes/core/collecte_geographie_service.dart';
// Dialog de détails d'une collecte

class DetailsDialog extends StatefulWidget {
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
  State<DetailsDialog> createState() => _DetailsDialogState();
}

class _DetailsDialogState extends State<DetailsDialog> {
  // Key pour forcer la reconstruction des FutureBuilders
  late ValueNotifier<int> _refreshKey;

  // Subscription pour les notifications globales
  StreamSubscription<String>? _qualityControlUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _refreshKey = ValueNotifier<int>(0);
    _setupGlobalRefreshListener();

    // 🆕 Notifier l'ouverture de l'interface de détails
    if (widget.item != null) {
      GlobalRefreshService().notifyInterfaceSync(
        action: 'collecte_details_opened',
        collecteId: widget.item!.id,
        additionalData: {
          'section': widget.section.name,
        },
      );
    }
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
        print(
            '📢 DetailsDialog: Notification contrôle mis à jour - $containerCode');
        print('🔄 DetailsDialog: Rechargement des données de collecte...');
        _refreshAllData();
      }
    });

    // Écoute les mises à jour de collectes
    globalRefreshService.collecteUpdatesStream.listen((collecteId) {
      if (mounted) {
        print(
            '📢 DetailsDialog: Notification collecte mise à jour - $collecteId');
        print('🔄 DetailsDialog: Rechargement des données de collecte...');
        _refreshAllData();
      }
    });
  }

  // Méthode pour recharger complètement les données de la collecte
  void _refreshAllData() {
    if (mounted) {
      print('🔄 DetailsDialog: Rechargement complet des données de collecte');

      // Force une mise à jour complète via le système de refresh key
      _refreshKey.value++;

      // Notifie le parent pour qu'il recharge aussi ses données
      if (mounted) {
        print('✅ DetailsDialog: Forçage du rebuild du dialog');
        setState(() {
          // Force un rebuild complet du widget
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen || widget.item == null) return const SizedBox.shrink();

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
                    .withValues(alpha: 0.4),
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
    final sectionLabel = Formatters.getSectionLabel(widget.section);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                  Formatters.getTitleForCollecte(widget.section, widget.item!),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => widget.onOpenChange(false),
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
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () =>
                _copyToClipboard(context, widget.item!.id, 'ID collecte'),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copier ID'),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => _copyToClipboard(
                context, widget.item!.path, 'Chemin Firestore'),
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
            _buildInfoField(context, 'ID', widget.item!.id, copyable: true),
            _buildInfoField(context, 'Site', widget.item!.site),
            _buildInfoField(
                context, 'Date', Formatters.formatDateTime(widget.item!.date)),
            _buildInfoField(
                context, 'Technicien', widget.item!.technicien ?? '—'),
            _buildInfoField(context, 'Statut',
                Formatters.formatStatut(widget.item!.statut)),
            _buildInfoField(context, 'Chemin', widget.item!.path,
                copyable: true),
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
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
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
            child: Tooltip(
              message: value,
              child: Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _refreshKey,
      builder: (context, refreshValue, child) {
        return FutureBuilder<Map<String, int>>(
          key: ValueKey(refreshValue), // Force la reconstruction
          future: _getControlStats(),
          builder: (context, snapshot) {
            final controlStats = snapshot.data ??
                {'total': 0, 'controlled': 0, 'uncontrolled': 0};

            return StatsRow(
              stats: [
                StatMini(
                  label: 'Poids total',
                  value: Formatters.formatKg(widget.item!.totalWeight),
                  icon: Icons.scale,
                  color: Colors.green.shade600,
                ),
                StatMini(
                  label: 'Montant total',
                  value: Formatters.formatFCFA(widget.item!.totalAmount),
                  icon: Icons.text_fields,
                  color: Colors.orange.shade600,
                ),
                StatMini(
                  label: 'Contrôlés',
                  value: snapshot.connectionState == ConnectionState.waiting
                      ? '...'
                      : '${controlStats['controlled']}/${controlStats['total']}',
                  icon: Icons.verified,
                  color: Colors.green.shade600,
                ),
                StatMini(
                  label: 'Non contrôlés',
                  value: snapshot.connectionState == ConnectionState.waiting
                      ? '...'
                      : '${controlStats['uncontrolled']}',
                  icon: Icons.pending,
                  color: Colors.orange.shade600,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionSpecificInfo(BuildContext context) {
    switch (widget.section) {
      case Section.recoltes:
        if (widget.item is Recolte) {
          return _buildRecoltesInfo(context, widget.item as Recolte);
        }
        break;
      case Section.scoop:
        if (widget.item is Scoop) {
          return _buildScoopInfo(context, widget.item as Scoop);
        }
        break;
      case Section.individuel:
        if (widget.item is Individuel) {
          return _buildIndividuelInfo(context, widget.item as Individuel);
        }
        break;
      case Section.miellerie:
        if (widget.item is Miellerie) {
          return _buildMiellerieInfo(context, widget.item as Miellerie);
        }
        break;
    }
    return const SizedBox.shrink();
  }

  Widget _buildRecoltesInfo(BuildContext context, Recolte recolte) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section informations géographiques modernisée
        _buildGeographicInfoSection(
          context,
          region: recolte.region,
          province: recolte.province,
          commune: recolte.commune,
          village: recolte.village,
        ),

        if (recolte.predominancesFlorales?.isNotEmpty == true) ...[
          const SizedBox(height: 20),
          Text(
            'Prédominances florales',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          _buildChips(context, recolte.predominancesFlorales!),
        ],
      ],
    );
  }

  Widget _buildScoopInfo(BuildContext context, Scoop scoop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Informations SCOOP
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
              crossAxisCount: isMobile ? 2 : 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isMobile ? 2.5 : 3.0,
              children: [
                _buildInfoField(context, 'Nom SCOOP', scoop.scoopNom),
                _buildInfoField(
                    context, 'Période', scoop.periodeCollecte ?? '—'),
                _buildInfoField(context, 'Qualité', scoop.qualite ?? '—'),
              ],
            );
          },
        ),

        const SizedBox(height: 20),

        // Section informations géographiques comme pour les récoltes
        _buildGeographicInfoSection(
          context,
          region: scoop.region,
          province: scoop.province,
          commune: scoop.commune,
          village: scoop.village,
        ),
      ],
    );
  }

  Widget _buildIndividuelInfo(BuildContext context, Individuel individuel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Informations producteur
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

        const SizedBox(height: 20),

        // Section informations géographiques comme pour les récoltes et SCOOP
        _buildGeographicInfoSection(
          context,
          region: individuel.region,
          province: individuel.province,
          commune: individuel.commune,
          village: individuel.village,
        ),

        if (individuel.originesFlorales?.isNotEmpty == true) ...[
          const SizedBox(height: 20),
          Text(
            'Origines florales',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          _buildChips(context, individuel.originesFlorales!),
        ],
      ],
    );
  }

  Widget _buildMiellerieInfo(BuildContext context, Miellerie miellerie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Informations miellerie
        Text(
          'Informations miellerie',
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
                _buildInfoField(context, 'Collecteur', miellerie.collecteurNom),
                _buildInfoField(context, 'Miellerie', miellerie.miellerieNom),
                _buildInfoField(context, 'Localité', miellerie.localite),
                _buildInfoField(
                    context, 'Coopérative', miellerie.cooperativeNom),
                _buildInfoField(context, 'Répondant', miellerie.repondant),
                _buildInfoField(
                    context, 'Observations', miellerie.observations ?? '—'),
              ],
            );
          },
        ),
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
        ValueListenableBuilder<int>(
          valueListenable: _refreshKey,
          builder: (context, refreshValue, child) {
            return FutureBuilder<Map<String, int>>(
              key: ValueKey(
                  'control_stats_$refreshValue'), // Force la reconstruction
              future: _getControlStats(),
              builder: (context, snapshot) {
                final controlStats =
                    snapshot.data ?? {'controlled': 0, 'uncontrolled': 0};

                return Row(
                  children: [
                    Text(
                      'Contenants',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        snapshot.connectionState == ConnectionState.waiting
                            ? '... contrôlés'
                            : '${controlStats['controlled']} contrôlés',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        snapshot.connectionState == ConnectionState.waiting
                            ? '... non contrôlés'
                            : '${controlStats['uncontrolled']} non contrôlés',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
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

  Widget _buildMobileContenantsView(BuildContext context) {
    final theme = Theme.of(context);
    final rows = _getTableRows();

    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
          final containerCode = _getContainerCodeByIndex(index);

          return _buildMobileContainerCard(
              context, theme, containerCode, row, index);
        }).toList(),
      ],
    );
  }

  List<String> _getTableHeaders() {
    switch (widget.section) {
      case Section.recoltes:
        return [
          'Type ruche',
          'Type contenant',
          'Poids (kg)',
          'Prix unitaire',
          'Montant',
          'Statut Contrôle'
        ];
      case Section.scoop:
      case Section.individuel:
      case Section.miellerie:
        return [
          'Type contenant',
          'Type miel',
          'Quantité (kg)',
          'Prix unitaire',
          'Montant',
          'Statut Contrôle'
        ];
    }
  }

  List<List<String>> _getTableRows() {
    if (widget.item == null) return [];

    switch (widget.section) {
      case Section.recoltes:
        if (widget.item is Recolte) {
          final recolte = widget.item as Recolte;
          return recolte.contenants.asMap().entries.map((entry) {
            final c = entry.value;
            // final containerId = 'C${(index + 1).toString().padLeft(3, '0')}';
            return [
              c.hiveType,
              c.containerType,
              Formatters.formatKg(c.weight),
              Formatters.formatFCFA(c.unitPrice),
              Formatters.formatFCFA(c.total),
              'Vérification...', // Status will be handled by FutureBuilder in display
            ];
          }).toList();
        }
        break;

      case Section.scoop:
        if (widget.item is Scoop) {
          final scoop = widget.item as Scoop;
          return scoop.contenants.asMap().entries.map((entry) {
            final c = entry.value;
            // final containerId = 'C${(index + 1).toString().padLeft(3, '0')}';
            return [
              c.typeContenant,
              c.typeMiel,
              Formatters.formatKg(c.quantite),
              Formatters.formatFCFA(c.prixUnitaire),
              Formatters.formatFCFA(c.montantTotal),
              'Vérification...', // Status will be handled by FutureBuilder in display
            ];
          }).toList();
        }
        break;

      case Section.individuel:
        if (widget.item is Individuel) {
          final individuel = widget.item as Individuel;
          return individuel.contenants.asMap().entries.map((entry) {
            final c = entry.value;
            // final containerId = 'C${(index + 1).toString().padLeft(3, '0')}';
            return [
              c.typeContenant,
              c.typeMiel,
              Formatters.formatKg(c.quantite),
              Formatters.formatFCFA(c.prixUnitaire),
              Formatters.formatFCFA(c.montantTotal),
              'Vérification...', // Status will be handled by FutureBuilder in display
            ];
          }).toList();
        }
        break;

      case Section.miellerie:
        if (widget.item is Miellerie) {
          final miellerie = widget.item as Miellerie;
          return miellerie.contenants.asMap().entries.map((entry) {
            final c = entry.value;
            return [
              c.typeContenant,
              c.typeMiel,
              Formatters.formatKg(c.quantite),
              Formatters.formatFCFA(c.prixUnitaire),
              Formatters.formatFCFA(c.montantTotal),
              'Vérification...', // Status will be handled by FutureBuilder in display
            ];
          }).toList();
        }
        break;
    }
    return [];
  }

  IconData _getSectionIcon() {
    switch (widget.section) {
      case Section.recoltes:
        return Icons.agriculture;
      case Section.scoop:
        return Icons.group;
      case Section.individuel:
        return Icons.person;
      case Section.miellerie:
        return Icons.factory;
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
    final sectionLabel = Formatters.getSectionLabel(widget.section);

    return Container(
      padding: EdgeInsets.all(isVerySmall ? 12 : 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
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
                onPressed: () => widget.onOpenChange(false),
                icon: const Icon(Icons.close),
                iconSize: 20,
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.getTitleForCollecte(widget.section, widget.item!),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isVerySmall ? 16 : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.getSubtitleForCollecte(widget.item!),
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
          if (widget.item != null) _buildMobileContenantsView(context),
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
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
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
                    widget.item!.id,
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
            Tooltip(
              message: widget.item!.id,
              child: Text(
                'ID: ${widget.item!.id}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
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
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                  Formatters.formatKg(widget.item!.totalWeight),
                  Icons.scale,
                  isVerySmall,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMobileStat(
                  context,
                  'Montant total',
                  Formatters.formatFCFA(widget.item!.totalAmount),
                  Icons.text_fields,
                  isVerySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FutureBuilder<Map<String, int>>(
                  future: _getControlStats(),
                  builder: (context, snapshot) {
                    final controlStats =
                        snapshot.data ?? {'controlled': 0, 'total': 0};
                    final value = snapshot.connectionState ==
                            ConnectionState.waiting
                        ? '...'
                        : '${controlStats['controlled']}/${controlStats['total']}';

                    return _buildMobileStat(
                      context,
                      'Contrôlés',
                      value,
                      Icons.verified,
                      isVerySmall,
                    );
                  },
                ),
              ),
              Expanded(
                child: _buildMobileStat(
                  context,
                  'Date',
                  Formatters.formatDate(widget.item!.date),
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
            border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMobileInfoRow(
                  'Site', widget.item!.site, isVerySmall, context),
              _buildMobileInfoRow(
                  'Technicien',
                  widget.item!.technicien ?? 'Non défini',
                  isVerySmall,
                  context),
              if (widget.item!.statut != null)
                _buildMobileInfoRow(
                    'Statut',
                    Formatters.formatStatut(widget.item!.statut),
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
            child: Tooltip(
              message: value,
              child: Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: isVerySmall ? 11 : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fonction pour afficher le statut de contrôle d'un contenant (OPTIMISÉ)
  Widget _buildControlStatus(BuildContext context, String containerCode) {
    final theme = Theme.of(context);
    final qualityService = QualityControlService();

    return ValueListenableBuilder<int>(
      valueListenable: _refreshKey,
      builder: (context, refreshValue, child) {
        // 🆕 RÉCUPÉRER LES DONNÉES FRAÎCHES DEPUIS FIRESTORE
        return FutureBuilder<BaseCollecte?>(
          key: ValueKey('container_status_${containerCode}_$refreshValue'),
          future: _getFreshCollecteData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            final freshItem = snapshot.data ?? widget.item;
            final controlInfo =
                qualityService.getContainerControlInfoFromCollecteData(
                    freshItem, containerCode);

            if (controlInfo?.isControlled == true) {
              // Contenant déjà contrôlé - utiliser les données locales
              final statusColor = controlInfo!.conformityStatus == 'conforme'
                  ? Colors.green
                  : Colors.red;
              final statusIcon = controlInfo.conformityStatus == 'conforme'
                  ? Icons.check_circle
                  : Icons.error;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
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
                            'Contrôlé le ${controlInfo.controlDate != null ? Formatters.formatDate(controlInfo.controlDate!) : 'N/A'}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            controlInfo.conformityStatus == 'conforme'
                                ? 'Conforme'
                                : 'Non conforme',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        // Si besoin de modifier, récupérer les données complètes depuis Firestore
                        final fullControl = await qualityService
                            .getQualityControl(containerCode, widget.item!.date,
                                collecteId: widget.item!.id);
                        _showQualityControlForm(context, containerCode,
                            existingData: fullControl);
                      },
                      icon: const Icon(Icons.edit, size: 14),
                      tooltip: 'Modifier le contrôle',
                      constraints:
                          const BoxConstraints(minWidth: 24, minHeight: 24),
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
                  color: theme.colorScheme.surfaceContainerHighest,
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
          },
        );
      },
    );
  }

  /// Récupère les données fraîches de la collecte depuis Firestore
  Future<BaseCollecte?> _getFreshCollecteData() async {
    if (widget.item == null) return null;

    try {
      final qualityService = QualityControlService();

      // 🆕 FORCER LA RÉCUPÉRATION DEPUIS FIRESTORE
      qualityService.invalidateCollecteCache(widget.item!.id);

      // Récupérer toutes les données fraîches depuis Firestore
      final allCollectes =
          await FirestoreDataService.getCollectesFromFirestore();

      // Trouver la collecte correspondante selon le type
      switch (widget.section) {
        case Section.recoltes:
          final recoltes = allCollectes[Section.recoltes] ?? [];
          return recoltes.cast<Recolte>().firstWhere(
                (r) => r.id == widget.item!.id,
                orElse: () => widget.item as Recolte,
              );
        case Section.scoop:
          final scoops = allCollectes[Section.scoop] ?? [];
          return scoops.cast<Scoop>().firstWhere(
                (s) => s.id == widget.item!.id,
                orElse: () => widget.item as Scoop,
              );
        case Section.individuel:
          final individuels = allCollectes[Section.individuel] ?? [];
          return individuels.cast<Individuel>().firstWhere(
                (i) => i.id == widget.item!.id,
                orElse: () => widget.item as Individuel,
              );
        case Section.miellerie:
          final mielleries = allCollectes[Section.miellerie] ?? [];
          return mielleries.cast<Miellerie>().firstWhere(
                (m) => m.id == widget.item!.id,
                orElse: () => widget.item as Miellerie,
              );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la récupération des données fraîches: $e');
      }
      return widget.item; // Fallback vers les données originales
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
        collecteItem: widget.item!,
        containerCode: containerCode,
        existingData: existingData,
        onSave: () async {
          Navigator.of(context).pop(); // Fermer le formulaire

          // Le rafraîchissement sera automatique grâce aux notifications globales
          // Plus besoin d'appeler manuellement refreshAllData() et _refreshControlStats()

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
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
            border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
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
                final containerCode = _getContainerCodeByIndex(index);

                return _buildDesktopContainerRow(
                    context, theme, containerCode, row);
              }),
            ],
          ),
        ),
      ],
    );
  }

  /// Section moderne des informations géographiques avec codes de localisation
  Widget _buildGeographicInfoSection(
    BuildContext context, {
    String? region,
    String? province,
    String? commune,
    String? village,
  }) {
    final theme = Theme.of(context);

    // Création de la map de localisation pour GeographieData
    final localisation = {
      'region': region ?? '',
      'province': province ?? '',
      'commune': commune ?? '',
      'village': village ?? '',
    };

    // Génération du code moderne avec service Firestore
    final geographieService = Get.find<CollecteGeographieService>();
    final localisationAvecCode =
        geographieService.formatLocationCodeFromMap(localisation);
    final localisationComplete = [region, province, commune, village]
        .where((element) => element != null && element.isNotEmpty)
        .join(' › ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.05),
            theme.colorScheme.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.location_on,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              // Titre: ellipsize pour éviter les débordements horizontaux
              Flexible(
                child: Tooltip(
                  message: 'Informations géographiques',
                  waitDuration: const Duration(milliseconds: 400),
                  child: Text(
                    'Informations géographiques',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (localisationAvecCode.isNotEmpty)
                InkWell(
                  onTap: () => _copyToClipboard(
                      context, localisationAvecCode, 'Code de localisation'),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.copy,
                      color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Grille des informations géographiques (adaptée aux petites largeurs)
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final w = constraints.maxWidth;
              // Sur très petites largeurs, passer en 1 colonne et augmenter la hauteur des tuiles
              final crossCount = !isMobile ? 4 : (w < 360 ? 1 : 2);
              double aspect;
              if (!isMobile) {
                aspect = 3.0;
              } else if (w < 320) {
                aspect = 2.25; // plus de hauteur
              } else if (w < 360) {
                aspect = 2.5;
              } else if (w < 410) {
                aspect = 2.9;
              } else if (w < 480) {
                aspect = 2.5;
              } else {
                aspect = 2.8;
              }

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: aspect,
                children: [
                  _buildInfoField(context, 'Région', region ?? '—'),
                  _buildInfoField(context, 'Province', province ?? '—'),
                  _buildInfoField(context, 'Commune', commune ?? '—'),
                  _buildInfoField(context, 'Village', village ?? '—'),
                ],
              );
            },
          ),

          if (localisationAvecCode.isNotEmpty) ...[
            const SizedBox(height: 16),

            // Code de localisation moderne
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tag,
                        color: theme.colorScheme.primary,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Code: ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          localisationAvecCode.split(' / ').first,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (localisationComplete.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.place,
                          color: theme.colorScheme.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Hiérarchie: ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            localisationComplete,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Construit le bouton de contrôle selon l'état et les permissions
  Widget _buildControlButton(BuildContext context, String containerCode,
      bool isControlled, bool isLoading,
      {bool isDesktop = false}) {
    // Récupérer rôle et site de l'utilisateur
    bool isAdmin = false;
    bool canControl = false;
    try {
      final userSession = Get.find<UserSession>();
      final role = (userSession.role ?? '').toLowerCase();
      final userSite = (userSession.site ?? '').trim();
      isAdmin = role.contains('admin');
      // Les contrôleurs ne peuvent agir que sur leur propre site
      if (!isAdmin && userSite.isNotEmpty) {
        canControl = widget.item != null && widget.item!.site == userSite;
      }
    } catch (_) {
      // Par défaut: aucune permission si la session n'est pas disponible
      isAdmin = false;
      canControl = false;
    }

    final hasPermission = isAdmin || canControl;

    if (isControlled) {
      if (!hasPermission) {
        // Contrôleur: Afficher un message informatif
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                'Contrôlé',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }

      // Admin: Peut modifier le contrôle
      return FilledButton.icon(
        onPressed: () => _handleControlAction(context, containerCode),
        icon: const Icon(Icons.edit, size: 16),
        label: const Text('Modifier'),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size(0, isDesktop ? 28 : 32),
          textStyle: TextStyle(fontSize: isDesktop ? 11 : 12),
        ),
      );
    } else {
      // Non contrôlé: Afficher bouton "Contrôler"
      return FilledButton.icon(
        onPressed: isLoading
            ? null
            : (hasPermission
                ? () => _handleControlAction(context, containerCode)
                : null),
        icon: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.fact_check, size: isDesktop ? 14 : 16),
        label: Text(isLoading ? '...' : 'Contrôler'),
        style: FilledButton.styleFrom(
          padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 8 : 12, vertical: isDesktop ? 4 : 6),
          minimumSize: Size(0, isDesktop ? 28 : 32),
          textStyle: TextStyle(fontSize: isDesktop ? 11 : 12),
        ),
      );
    }
  }

  /// Gère l'action de contrôle (création ou modification)
  void _handleControlAction(BuildContext context, String containerCode) async {
    // Vérifier permissions: admin = OK, contrôleur = même site uniquement
    bool isAdmin = false;
    bool canControl = false;
    try {
      final userSession = Get.find<UserSession>();
      final role = (userSession.role ?? '').toLowerCase();
      final userSite = (userSession.site ?? '').trim();
      isAdmin = role.contains('admin');
      if (!isAdmin && userSite.isNotEmpty) {
        canControl = widget.item != null && widget.item!.site == userSite;
      }
    } catch (_) {
      isAdmin = false;
      canControl = false;
    }

    if (!(isAdmin || canControl)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Vous n\'avez pas l\'autorisation de contrôler ce contenant.'),
          ),
        );
      }
      return;
    }

    final qualityService = QualityControlService();
    final existingControl = await qualityService.getQualityControl(
        containerCode, widget.item!.date,
        collecteId: widget.item!.id);
    _showQualityControlForm(context, containerCode,
        existingData: existingControl);
  }

  /// Construit une carte de contenant pour mobile
  Widget _buildMobileContainerCard(BuildContext context, ThemeData theme,
      String containerCode, List<String> row, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header du contenant avec bouton contrôler (responsive pour très petits écrans)
            LayoutBuilder(
              builder: (context, constraints) {
                final isUltraNarrow = constraints.maxWidth < 340;
                final labelChip = Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Tooltip(
                      message: 'Contenant $containerCode',
                      waitDuration: const Duration(milliseconds: 400),
                      child: Text(
                        'Contenant $containerCode',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                );

                final controlButton = ValueListenableBuilder<int>(
                  valueListenable: _refreshKey,
                  builder: (context, refreshValue, child) {
                    return FutureBuilder<bool>(
                      key: ValueKey(
                          'container_control_${containerCode}_$refreshValue'),
                      future: _isContainerControlled(containerCode),
                      builder: (context, snapshot) {
                        final isControlled = snapshot.data ?? false;
                        final isLoading =
                            snapshot.connectionState == ConnectionState.waiting;
                        return _buildControlButton(
                          context,
                          containerCode,
                          isControlled,
                          isLoading,
                        );
                      },
                    );
                  },
                );

                if (!isUltraNarrow) {
                  // Ligne unique: le label s'ellipsise, le bouton reste visible
                  return Row(
                    children: [
                      labelChip,
                      const SizedBox(width: 8),
                      controlButton,
                    ],
                  );
                }

                // Très petit écran: bouton sur la ligne suivante, aligné à droite
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [labelChip]),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: controlButton,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            // Détails du contenant
            ..._buildContainerDetails(context, theme, row),
            // Status indicateur du contrôle
            const SizedBox(height: 8),
            _buildControlStatus(context, containerCode),
          ],
        ),
      ),
    );
  }

  /// Construit une ligne de contenant pour desktop
  Widget _buildDesktopContainerRow(BuildContext context, ThemeData theme,
      String containerCode, List<String> row) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            child: _buildControlButton(context, containerCode, false, false,
                isDesktop: true),
          ),
        ],
      ),
    );
  }

  /// Construit les détails d'un contenant
  List<Widget> _buildContainerDetails(
      BuildContext context, ThemeData theme, List<String> row) {
    return _getTableHeaders().asMap().entries.map((headerEntry) {
      final headerIndex = headerEntry.key;
      final header = headerEntry.value;
      final value = headerIndex < row.length ? row[headerIndex] : '';

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
              child: Tooltip(
                message: value,
                waitDuration: const Duration(milliseconds: 400),
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  /// Vérifie si un contenant spécifique est contrôlé
  Future<bool> _isContainerControlled(String containerCode) async {
    final qualityService = QualityControlService();

    try {
      // Essayer d'abord de vérifier directement depuis les données de collecte
      final isControlled = qualityService.isContainerControlledFromCollecteData(
          widget.item, containerCode);

      if (isControlled) return true;

      // Fallback: vérifier dans la base de données
      final existingControl = await qualityService.getQualityControl(
          containerCode, widget.item!.date,
          collecteId: widget.item!.id);

      return existingControl != null;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erreur vérification contrôle contenant $containerCode: $e');
      }
      return false;
    }
  }

  /// Retourne les statistiques de contrôle des contenants (OPTIMISÉ avec fallback)
  Future<Map<String, int>> _getControlStats() async {
    final qualityService = QualityControlService();

    try {
      // Essayer la nouvelle méthode optimisée qui lit directement depuis les données de collecte
      final optimizedStats =
          qualityService.getControlStatsFromCollecteData(widget.item);

      // Si on a des contenants mais aucun contrôlé avec la méthode optimisée,
      // cela peut signifier que les données sont anciennes sans le champ controlInfo
      if (optimizedStats['total']! > 0 && optimizedStats['controlled'] == 0) {
        // Fallback vers l'ancienne méthode pour les données existantes
        final containerCodes = _getContainerCodes();
        return await qualityService.getControlStatsForContainers(
            containerCodes, widget.item!.date);
      }

      return optimizedStats;
    } catch (e) {
      if (kDebugMode) {
        print(
            '⚠️ Erreur méthode optimisée, fallback vers ancienne méthode: $e');
      }
      // Fallback vers l'ancienne méthode en cas d'erreur
      final containerCodes = _getContainerCodes();
      return await qualityService.getControlStatsForContainers(
          containerCodes, widget.item!.date);
    }
  }

  /// Obtient la liste des codes de contenants pour cette collecte
  List<String> _getContainerCodes() {
    if (widget.item == null) return [];

    return _getContainersFromItem().map<String>((container) {
      if (container.id != null) return container.id as String;
      return 'UNKNOWN';
    }).toList();
  }

  /// Obtient le code d'un contenant par son index
  String _getContainerCodeByIndex(int index) {
    final containers = _getContainersFromItem();
    if (index < containers.length) {
      final container = containers[index];
      if (container.id != null) return container.id;
    }
    return 'C${(index + 1).toString().padLeft(3, '0')}'; // fallback
  }

  /// Obtient la liste des contenants selon le type d'item
  List<dynamic> _getContainersFromItem() {
    if (widget.item is Recolte) {
      return (widget.item as Recolte).contenants;
    } else if (widget.item is Scoop) {
      return (widget.item as Scoop).contenants;
    } else if (widget.item is Individuel) {
      return (widget.item as Individuel).contenants;
    } else if (widget.item is Miellerie) {
      return (widget.item as Miellerie).contenants;
    }
    return [];
  }
}
