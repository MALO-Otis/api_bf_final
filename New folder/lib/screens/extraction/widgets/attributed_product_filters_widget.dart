import 'package:flutter/material.dart';
import '../models/attributed_product_models.dart';
import '../services/attributed_products_service.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';

/// Widget pour les filtres des produits attribués

class AttributedProductFiltersWidget extends StatefulWidget {
  final AttributedProductFilters currentFilters;
  final Function(AttributedProductFilters) onFiltersApplied;

  const AttributedProductFiltersWidget({
    super.key,
    required this.currentFilters,
    required this.onFiltersApplied,
  });

  @override
  State<AttributedProductFiltersWidget> createState() =>
      _AttributedProductFiltersWidgetState();
}

class _AttributedProductFiltersWidgetState
    extends State<AttributedProductFiltersWidget> {
  late AttributedProductFilters _filters;
  Map<String, List<String>> _filterOptions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters;
    _loadFilterOptions();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final service = AttributedProductsService();
      final options = await service.getFilterOptions();

      if (mounted) {
        setState(() {
          _filterOptions = options;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des options: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateFilters(AttributedProductFilters newFilters) {
    setState(() {
      _filters = newFilters;
    });
  }

  void _applyFilters() {
    widget.onFiltersApplied(_filters);
    Navigator.of(context).pop();
  }

  void _resetFilters() {
    setState(() {
      _filters = const AttributedProductFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? 400 : 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Filtrer les Produits',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Contenu
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nature du produit
                          _buildNatureFilter(theme),

                          const SizedBox(height: 24),

                          // Localisation
                          _buildLocationFilters(theme),

                          const SizedBox(height: 24),

                          // Attributeur
                          _buildAttributeurFilter(theme),

                          const SizedBox(height: 24),

                          // Statut
                          _buildStatutFilter(theme),

                          const SizedBox(height: 24),

                          // Dates
                          _buildDateFilters(theme),

                          const SizedBox(height: 24),

                          // Poids
                          _buildPoidsFilter(theme),

                          const SizedBox(height: 24),

                          // Options avancées
                          _buildAdvancedOptions(theme),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Réinitialiser'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Appliquer (${_filters.getActiveFiltersCount()})',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNatureFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nature du Produit',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ProductNature.values.map((nature) {
            final isSelected = _filters.natures.contains(nature);
            return FilterChip(
              label: Text(nature.label),
              selected: isSelected,
              onSelected: (selected) {
                final newNatures = List<ProductNature>.from(_filters.natures);
                if (selected) {
                  newNatures.add(nature);
                } else {
                  newNatures.remove(nature);
                }
                _updateFilters(_filters.copyWith(natures: newNatures));
              },
              backgroundColor: _getNatureColor(nature).withOpacity(0.1),
              selectedColor: _getNatureColor(nature).withOpacity(0.3),
              checkmarkColor: _getNatureColor(nature),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationFilters(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Localisation',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Sites d'origine
        if (_filterOptions['sitesOrigine']?.isNotEmpty == true) ...[
          Text(
            'Sites d\'origine',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _filterOptions['sitesOrigine']!.map((site) {
              final isSelected = _filters.sitesOrigine.contains(site);
              return FilterChip(
                label: Text(site),
                selected: isSelected,
                onSelected: (selected) {
                  final newSites = List<String>.from(_filters.sitesOrigine);
                  if (selected) {
                    newSites.add(site);
                  } else {
                    newSites.remove(site);
                  }
                  _updateFilters(_filters.copyWith(sitesOrigine: newSites));
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Villages
        if (_filterOptions['villages']?.isNotEmpty == true) ...[
          Text(
            'Villages',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _filterOptions['villages']!.take(20).map((village) {
                  final isSelected = _filters.villages.contains(village);
                  return FilterChip(
                    label: Text(village),
                    selected: isSelected,
                    onSelected: (selected) {
                      final newVillages = List<String>.from(_filters.villages);
                      if (selected) {
                        newVillages.add(village);
                      } else {
                        newVillages.remove(village);
                      }
                      _updateFilters(_filters.copyWith(villages: newVillages));
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAttributeurFilter(ThemeData theme) {
    if (_filterOptions['attributeurs']?.isEmpty != false) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attributeur',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _filterOptions['attributeurs']!.map((attributeur) {
            final isSelected = _filters.attributeurs.contains(attributeur);
            return FilterChip(
              label: Text(
                attributeur.split(' ').take(2).join(' '), // Prénom + Nom
              ),
              selected: isSelected,
              onSelected: (selected) {
                final newAttributeurs =
                    List<String>.from(_filters.attributeurs);
                if (selected) {
                  newAttributeurs.add(attributeur);
                } else {
                  newAttributeurs.remove(attributeur);
                }
                _updateFilters(
                    _filters.copyWith(attributeurs: newAttributeurs));
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatutFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statut',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PrelevementStatus.values.map((statut) {
            final isSelected = _filters.statuts.contains(statut);
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(statut),
                    size: 16,
                    color: _getStatusColor(statut),
                  ),
                  const SizedBox(width: 4),
                  Text(statut.label),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                final newStatuts =
                    List<PrelevementStatus>.from(_filters.statuts);
                if (selected) {
                  newStatuts.add(statut);
                } else {
                  newStatuts.remove(statut);
                }
                _updateFilters(_filters.copyWith(statuts: newStatuts));
              },
              backgroundColor: _getStatusColor(statut).withOpacity(0.1),
              selectedColor: _getStatusColor(statut).withOpacity(0.3),
              checkmarkColor: _getStatusColor(statut),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateFilters(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Période',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Date d'attribution
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                'Attribution du',
                _filters.dateAttributionFrom,
                (date) => _updateFilters(
                  _filters.copyWith(dateAttributionFrom: date),
                ),
                theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateField(
                'Attribution au',
                _filters.dateAttributionTo,
                (date) => _updateFilters(
                  _filters.copyWith(dateAttributionTo: date),
                ),
                theme,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Date de réception
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                'Réception du',
                _filters.dateReceptionFrom,
                (date) => _updateFilters(
                  _filters.copyWith(dateReceptionFrom: date),
                ),
                theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateField(
                'Réception au',
                _filters.dateReceptionTo,
                (date) => _updateFilters(
                  _filters.copyWith(dateReceptionTo: date),
                ),
                theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? value,
    Function(DateTime?) onChanged,
    ThemeData theme,
  ) {
    return TextFormField(
      decoration: InputDecoration(
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixIcon: value != null
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => onChanged(null),
              )
            : const Icon(Icons.calendar_today),
      ),
      readOnly: true,
      controller: TextEditingController(
        text: value != null ? _formatDate(value) : '',
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 30)),
        );
        if (date != null) {
          onChanged(date);
        }
      },
    );
  }

  Widget _buildPoidsFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Poids (kg)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Poids minimum',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixText: 'kg',
                ),
                keyboardType: TextInputType.number,
                initialValue: _filters.poidsMin?.toString(),
                onChanged: (value) {
                  final poids = double.tryParse(value);
                  _updateFilters(_filters.copyWith(poidsMin: poids));
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Poids maximum',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixText: 'kg',
                ),
                keyboardType: TextInputType.number,
                initialValue: _filters.poidsMax?.toString(),
                onChanged: (value) {
                  final poids = double.tryParse(value);
                  _updateFilters(_filters.copyWith(poidsMax: poids));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvancedOptions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Options Avancées',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          title: const Text('Afficher seulement les produits disponibles'),
          subtitle: const Text('Masquer les produits complètement prélevés'),
          value: _filters.seulementDisponibles ?? false,
          onChanged: (value) {
            _updateFilters(_filters.copyWith(seulementDisponibles: value));
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Color _getNatureColor(ProductNature nature) {
    switch (nature) {
      case ProductNature.brut:
        return Colors.amber;
      case ProductNature.liquide:
        return Colors.lightBlue;
      case ProductNature.filtre:
        return Colors.blue;
      case ProductNature.cire:
        return Colors.orange;
    }
  }

  Color _getStatusColor(PrelevementStatus statut) {
    switch (statut) {
      case PrelevementStatus.enAttente:
        return Colors.orange;
      case PrelevementStatus.enCours:
        return Colors.blue;
      case PrelevementStatus.termine:
        return Colors.green;
      case PrelevementStatus.suspendu:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(PrelevementStatus statut) {
    switch (statut) {
      case PrelevementStatus.enAttente:
        return Icons.schedule;
      case PrelevementStatus.enCours:
        return Icons.play_circle;
      case PrelevementStatus.termine:
        return Icons.check_circle;
      case PrelevementStatus.suspendu:
        return Icons.pause_circle;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
