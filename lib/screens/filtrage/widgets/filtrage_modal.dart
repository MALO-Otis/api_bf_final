import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/filtered_product_models.dart';
import '../services/filtered_products_service.dart';

/// Modal pour le processus de filtrage d'un produit
class FiltrageModal extends StatefulWidget {
  final FilteredProduct product;
  final VoidCallback? onCompleted;

  const FiltrageModal({
    super.key,
    required this.product,
    this.onCompleted,
  });

  @override
  State<FiltrageModal> createState() => _FiltrageModalState();
}

class _FiltrageModalState extends State<FiltrageModal>
    with TickerProviderStateMixin {
  final FilteredProductsService _service = FilteredProductsService();
  final _formKey = GlobalKey<FormState>();

  late TabController _tabController;
  late FilteredProduct _currentProduct;

  // Contrôleurs de texte
  final _poidsFiltreController = TextEditingController();
  final _observationsController = TextEditingController();
  final _raisonSuspensionController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _tabController = TabController(length: 3, vsync: this);

    // Aller directement à l'onglet approprié selon le statut
    switch (_currentProduct.statut) {
      case FilteredProductStatus.enAttente:
        _tabController.index = 0; // Démarrage
        break;
      case FilteredProductStatus.enCoursTraitement:
        _tabController.index = 1; // Processus
        break;
      case FilteredProductStatus.termine:
      case FilteredProductStatus.suspendu:
        _tabController.index = 2; // Résultats
        break;
    }

    // Pré-remplir les champs si déjà filtré
    if (_currentProduct.poidsFiltre != null) {
      _poidsFiltreController.text =
          _currentProduct.poidsFiltre!.toStringAsFixed(2);
    }
    if (_currentProduct.observations != null) {
      _observationsController.text = _currentProduct.observations!;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _poidsFiltreController.dispose();
    _observationsController.dispose();
    _raisonSuspensionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final isLandscape = screenSize.width > screenSize.height;

    // Calcul adaptatif de la hauteur maximum
    final maxHeightRatio = isLandscape ? 0.95 : 0.9;
    final maxHeight = screenSize.height * maxHeightRatio;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? 400 : 700,
          maxHeight: maxHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête
            Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: _buildHeader(theme, isMobile),
            ),

            // Onglets
            _buildTabBar(theme),

            // Contenu scrollable
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildStartTab(theme, isMobile),
                  _buildProcessTab(theme, isMobile),
                  _buildResultsTab(theme, isMobile),
                ],
              ),
            ),

            // Actions fixes en bas
            Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: _buildActions(theme, isMobile),
            ),
          ],
        ),
      ),
    );
  }

  /// En-tête du modal
  Widget _buildHeader(ThemeData theme, bool isMobile) {
    return Row(
      children: [
        // Icône du produit
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.water_drop,
            color: theme.colorScheme.primary,
            size: isMobile ? 24 : 32,
          ),
        ),

        const SizedBox(width: 16),

        // Informations produit
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtrage du Produit',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 18 : 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currentProduct.codeContenant,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                _currentProduct.producteur,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),

        // Bouton fermer
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.error.withOpacity(0.1),
            foregroundColor: theme.colorScheme.error,
          ),
        ),
      ],
    );
  }

  /// Barre d'onglets
  Widget _buildTabBar(ThemeData theme) {
    return TabBar(
      controller: _tabController,
      labelColor: theme.colorScheme.primary,
      unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
      indicatorColor: theme.colorScheme.primary,
      tabs: const [
        Tab(
          icon: Icon(Icons.play_arrow, size: 20),
          text: 'Démarrage',
        ),
        Tab(
          icon: Icon(Icons.hourglass_bottom, size: 20),
          text: 'Processus',
        ),
        Tab(
          icon: Icon(Icons.assessment, size: 20),
          text: 'Résultats',
        ),
      ],
    );
  }

  /// Onglet de démarrage
  Widget _buildStartTab(ThemeData theme, bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informations du produit
          _buildProductInfo(theme),

          const SizedBox(height: 24),

          // Instructions de démarrage
          _buildStartInstructions(theme),

          const SizedBox(height: 24),

          // Vérifications pré-filtrage
          _buildPreFiltrageChecks(theme),
        ],
      ),
    );
  }

  /// Onglet de processus
  Widget _buildProcessTab(ThemeData theme, bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statut actuel
            _buildCurrentStatus(theme),

            const SizedBox(height: 24),

            // Champ poids filtré
            _buildWeightField(theme),

            const SizedBox(height: 16),

            // Observations
            _buildObservationsField(theme),

            const SizedBox(height: 24),

            // Calculateur de rendement
            _buildYieldCalculator(theme),

            const SizedBox(height: 24),

            // Actions de processus
            _buildProcessActions(theme),
          ],
        ),
      ),
    );
  }

  /// Onglet de résultats
  Widget _buildResultsTab(ThemeData theme, bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Résumé des résultats
          _buildResultsSummary(theme),

          const SizedBox(height: 24),

          // Historique du filtrage
          _buildFiltrageHistory(theme),

          if (_currentProduct.statut == FilteredProductStatus.suspendu) ...[
            const SizedBox(height: 24),
            _buildSuspensionInfo(theme),
          ],
        ],
      ),
    );
  }

  /// Informations du produit
  Widget _buildProductInfo(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations du Produit',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Origine',
                    _currentProduct.origineDescription,
                    Icons.source,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Nature',
                    _currentProduct.nature.label,
                    Icons.category,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Poids Original',
                    '${_currentProduct.poidsOriginal.toStringAsFixed(2)} kg',
                    Icons.scale,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Qualité',
                    _currentProduct.qualite,
                    Icons.star,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Instructions de démarrage
  Widget _buildStartInstructions(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Instructions de Filtrage',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._getFiltrageInstructions().map((instruction) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 6, right: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          instruction,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// Vérifications pré-filtrage
  Widget _buildPreFiltrageChecks(ThemeData theme) {
    final checks = [
      'Équipement de filtrage prêt',
      'Filtres propres et en bon état',
      'Contenants de réception stérilisés',
      'Conditions d\'hygiène respectées',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vérifications Pré-Filtrage',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...checks.map((check) => CheckboxListTile(
                  title: Text(check),
                  value: true, // Pour la démo, toujours coché
                  onChanged: null, // Lecture seule pour la démo
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                )),
          ],
        ),
      ),
    );
  }

  /// Statut actuel
  Widget _buildCurrentStatus(ThemeData theme) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (_currentProduct.statut) {
      case FilteredProductStatus.enAttente:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'En attente de démarrage';
        break;
      case FilteredProductStatus.enCoursTraitement:
        statusColor = Colors.blue;
        statusIcon = Icons.hourglass_bottom;
        statusText = 'Filtrage en cours';
        break;
      case FilteredProductStatus.termine:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Filtrage terminé';
        break;
      case FilteredProductStatus.suspendu:
        statusColor = Colors.red;
        statusIcon = Icons.pause_circle;
        statusText = 'Filtrage suspendu';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Text(
            statusText,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Champ poids filtré
  Widget _buildWeightField(ThemeData theme) {
    return TextFormField(
      controller: _poidsFiltreController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: 'Poids Filtré (kg)',
        hintText: 'Entrez le poids après filtrage',
        prefixIcon: const Icon(Icons.scale),
        suffixText: 'kg',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer le poids filtré';
        }
        final weight = double.tryParse(value);
        if (weight == null || weight <= 0) {
          return 'Poids invalide';
        }
        if (weight > _currentProduct.poidsOriginal) {
          return 'Le poids filtré ne peut pas dépasser le poids original';
        }
        return null;
      },
      onChanged: (value) {
        setState(() {}); // Recalculer le rendement
      },
    );
  }

  /// Champ observations
  Widget _buildObservationsField(ThemeData theme) {
    return TextFormField(
      controller: _observationsController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Observations',
        hintText: 'Notes sur le processus de filtrage...',
        prefixIcon: const Icon(Icons.note),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Calculateur de rendement
  Widget _buildYieldCalculator(ThemeData theme) {
    final poidsSaisi = double.tryParse(_poidsFiltreController.text);
    final rendement = poidsSaisi != null && _currentProduct.poidsOriginal > 0
        ? (poidsSaisi / _currentProduct.poidsOriginal) * 100
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calculateur de Rendement',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Poids Original',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        '${_currentProduct.poidsOriginal.toStringAsFixed(2)} kg',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward, color: theme.colorScheme.primary),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Poids Filtré',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        poidsSaisi != null
                            ? '${poidsSaisi.toStringAsFixed(2)} kg'
                            : '-- kg',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: poidsSaisi != null
                              ? Colors.blue
                              : theme.disabledColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: rendement != null
                    ? (rendement >= 95 ? Colors.green : Colors.orange)
                        .withOpacity(0.1)
                    : theme.disabledColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.trending_up,
                    color: rendement != null
                        ? (rendement >= 95 ? Colors.green : Colors.orange)
                        : theme.disabledColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Rendement: ${rendement?.toStringAsFixed(1) ?? '--'}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: rendement != null
                          ? (rendement >= 95 ? Colors.green : Colors.orange)
                          : theme.disabledColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Actions de processus
  Widget _buildProcessActions(ThemeData theme) {
    if (_currentProduct.statut == FilteredProductStatus.termine) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (_currentProduct.statut ==
            FilteredProductStatus.enCoursTraitement) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _suspendFiltrage,
              icon: const Icon(Icons.pause),
              label: const Text('Suspendre le Filtrage'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_currentProduct.statut == FilteredProductStatus.suspendu) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _resumeFiltrage,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Reprendre le Filtrage'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  /// Résumé des résultats
  Widget _buildResultsSummary(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé du Filtrage',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_currentProduct.poidsFiltre != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildResultItem(
                      'Poids Original',
                      '${_currentProduct.poidsOriginal.toStringAsFixed(2)} kg',
                      Icons.scale,
                    ),
                  ),
                  Expanded(
                    child: _buildResultItem(
                      'Poids Filtré',
                      '${_currentProduct.poidsFiltre!.toStringAsFixed(2)} kg',
                      Icons.water_drop,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_currentProduct.rendementFiltrage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.trending_up, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Rendement: ${_currentProduct.rendementFiltrage!.toStringAsFixed(1)}%',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
            ] else ...[
              Center(
                child: Text(
                  'Aucun résultat disponible',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.disabledColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Historique du filtrage
  Widget _buildFiltrageHistory(ThemeData theme) {
    final events = <Map<String, dynamic>>[];

    // Événement d'attribution
    events.add({
      'icon': Icons.assignment,
      'color': Colors.blue,
      'title': 'Produit attribué au filtrage',
      'subtitle': 'Par ${_currentProduct.attributeur}',
      'date': _currentProduct.dateAttribution,
    });

    // Événement de début si disponible
    if (_currentProduct.dateDebutFiltrage != null) {
      events.add({
        'icon': Icons.play_arrow,
        'color': Colors.green,
        'title': 'Filtrage démarré',
        'subtitle': 'Début du processus de filtrage',
        'date': _currentProduct.dateDebutFiltrage!,
      });
    }

    // Événement de fin si disponible
    if (_currentProduct.dateFinFiltrage != null) {
      events.add({
        'icon': Icons.check_circle,
        'color': Colors.green,
        'title': 'Filtrage terminé',
        'subtitle': _currentProduct.dureeFiltrage != null
            ? 'Durée: ${_formatDuration(_currentProduct.dureeFiltrage!)}'
            : 'Processus terminé',
        'date': _currentProduct.dateFinFiltrage!,
      });
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historique du Filtrage',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...events.map((event) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: event['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          event['icon'],
                          color: event['color'],
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['title'],
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              event['subtitle'],
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatDate(event['date']),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// Information de suspension
  Widget _buildSuspensionInfo(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Filtrage Suspendu',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_currentProduct.observations != null)
              Text(
                'Raison: ${_currentProduct.observations}',
                style: theme.textTheme.bodyMedium,
              )
            else
              Text(
                'Aucune raison spécifiée',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.disabledColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Actions du modal
  Widget _buildActions(ThemeData theme, bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _buildPrimaryAction(theme),
        ),
      ],
    );
  }

  /// Action principale selon l'état
  Widget _buildPrimaryAction(ThemeData theme) {
    switch (_currentProduct.statut) {
      case FilteredProductStatus.enAttente:
        return ElevatedButton.icon(
          onPressed: _isLoading ? null : _startFiltrage,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow),
          label: Text(_isLoading ? 'Démarrage...' : 'Démarrer le Filtrage'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        );

      case FilteredProductStatus.enCoursTraitement:
        return ElevatedButton.icon(
          onPressed: _isLoading ? null : _completeFiltrage,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(_isLoading ? 'Finalisation...' : 'Terminer le Filtrage'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        );

      case FilteredProductStatus.termine:
        return ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.visibility),
          label: const Text('Consulter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        );

      case FilteredProductStatus.suspendu:
        return ElevatedButton.icon(
          onPressed: _isLoading ? null : _resumeFiltrage,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow),
          label: Text(_isLoading ? 'Reprise...' : 'Reprendre'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        );
    }
  }

  /// Démarrer le filtrage
  Future<void> _startFiltrage() async {
    setState(() => _isLoading = true);

    try {
      final updatedProduct = await _service.startFiltrage(_currentProduct.id);
      setState(() {
        _currentProduct = updatedProduct;
        _isLoading = false;
      });

      // Changer d'onglet vers le processus
      _tabController.animateTo(1);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Filtrage démarré avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Terminer le filtrage
  Future<void> _completeFiltrage() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final poidsFiltre = double.parse(_poidsFiltreController.text);
      final observations = _observationsController.text.isEmpty
          ? null
          : _observationsController.text;

      final updatedProduct = await _service.completeFiltrage(
        _currentProduct.id,
        poidsFiltre,
        observations: observations,
      );

      setState(() {
        _currentProduct = updatedProduct;
        _isLoading = false;
      });

      // Changer d'onglet vers les résultats
      _tabController.animateTo(2);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Filtrage terminé avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onCompleted?.call();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Suspendre le filtrage
  Future<void> _suspendFiltrage() async {
    final raison = await _showSuspensionDialog();
    if (raison == null) return;

    setState(() => _isLoading = true);

    try {
      final updatedProduct = await _service.suspendFiltrage(
        _currentProduct.id,
        raison: raison,
      );

      setState(() {
        _currentProduct = updatedProduct;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Filtrage suspendu'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Reprendre le filtrage
  Future<void> _resumeFiltrage() async {
    setState(() => _isLoading = true);

    try {
      final updatedProduct = await _service.resumeFiltrage(_currentProduct.id);
      setState(() {
        _currentProduct = updatedProduct;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Filtrage repris'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Dialog de suspension
  Future<String?> _showSuspensionDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspendre le Filtrage'),
        content: TextField(
          controller: _raisonSuspensionController,
          decoration: const InputDecoration(
            labelText: 'Raison de la suspension',
            hintText: 'Expliquez pourquoi le filtrage est suspendu...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final raison = _raisonSuspensionController.text.trim();
              Navigator.of(context)
                  .pop(raison.isEmpty ? 'Aucune raison spécifiée' : raison);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Suspendre'),
          ),
        ],
      ),
    );
  }

  /// Item d'information
  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Item de résultat
  Widget _buildResultItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  /// Instructions de filtrage selon l'origine
  List<String> _getFiltrageInstructions() {
    if (_currentProduct.estOrigineDuControle) {
      return [
        'Vérifier la qualité du produit liquide contrôlé',
        'Utiliser des filtres fins pour éliminer les impuretés',
        'Maintenir une température constante durant le processus',
        'Contrôler l\'humidité et l\'exposition à la lumière',
        'Effectuer des tests de qualité intermédiaires',
      ];
    } else {
      return [
        'Laisser refroidir le produit extrait avant filtrage',
        'Utiliser un système de filtration en cascade',
        'Surveiller la viscosité durant le processus',
        'Éliminer les résidus de cire et impuretés',
        'Vérifier la transparence et la couleur finale',
      ];
    }
  }

  /// Formate une date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Formate une durée
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}j ${duration.inHours.remainder(24)}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}min';
    } else {
      return '${duration.inMinutes}min';
    }
  }
}

