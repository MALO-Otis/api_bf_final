import '../models/quality_vocab.dart';
import 'package:flutter/material.dart';
import '../models/quality_chain_models.dart';
import '../../controle_de_donnes/models/quality_control_models.dart';

class QualityFiltersPanel extends StatelessWidget {
  final QualityFilterState filterState;
  final List<String> availableProductTypes;
  final ValueChanged<QualityFilterState> onFiltersChanged;
  final VoidCallback onResetFilters;

  const QualityFiltersPanel({
    super.key,
    required this.filterState,
    required this.availableProductTypes,
    required this.onFiltersChanged,
    required this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 8),
            blurRadius: 24,
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ],
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_alt_rounded,
                  color: theme.colorScheme.primary, size: 26),
              const SizedBox(width: 12),
              Text(
                'Filtres avancés',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onResetFilters,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Réinitialiser'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 18,
            runSpacing: 18,
            children: [
              _FilterWrapper(
                label: 'Période',
                child: _PeriodButton(
                  range: filterState.period,
                  onSelected: (range) {
                    onFiltersChanged(filterState.copyWith(period: range));
                  },
                ),
              ),
              _FilterWrapper(
                label: 'Étape',
                child: DropdownButtonFormField<QualityChainStep?>(
                  value: filterState.step,
                  decoration: _inputDecoration(theme),
                  items: [
                    const DropdownMenuItem<QualityChainStep?>(
                      value: null,
                      child: Text('Toutes les étapes'),
                    ),
                    ...QualityChainStep.values.map(
                      (step) => DropdownMenuItem<QualityChainStep?>(
                        value: step,
                        child: Row(
                          children: [
                            Icon(step.icon,
                                size: 18, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(step.label),
                          ],
                        ),
                      ),
                    )
                  ],
                  onChanged: (value) {
                    onFiltersChanged(filterState.copyWith(step: value));
                  },
                ),
              ),
              _FilterWrapper(
                label: 'Statut',
                child: DropdownButtonFormField<ConformityStatus?>(
                  value: filterState.conformityStatus,
                  decoration: _inputDecoration(theme),
                  items: const [
                    DropdownMenuItem<ConformityStatus?>(
                      value: null,
                      child: Text('Tous les statuts'),
                    ),
                    DropdownMenuItem<ConformityStatus?>(
                      value: ConformityStatus.conforme,
                      child: Text('Conforme'),
                    ),
                    DropdownMenuItem<ConformityStatus?>(
                      value: ConformityStatus.nonConforme,
                      child: Text('Non conforme'),
                    ),
                  ],
                  onChanged: (value) {
                    onFiltersChanged(filterState.copyWith(
                      conformityStatus: value,
                    ));
                  },
                ),
              ),
              _FilterWrapper(
                label: 'Type de produit',
                child: DropdownButtonFormField<String?>(
                  value: filterState.productType,
                  decoration: _inputDecoration(theme),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Tous les produits'),
                    ),
                    ...availableProductTypes.map(
                      (product) => DropdownMenuItem<String?>(
                        value: product,
                        child: Text(product),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    onFiltersChanged(filterState.copyWith(productType: value));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(ThemeData theme) {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor:
          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}

class _FilterWrapper extends StatelessWidget {
  final String label;
  final Widget child;

  const _FilterWrapper({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final DateTimeRange? range;
  final ValueChanged<DateTimeRange?> onSelected;

  const _PeriodButton({required this.range, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = range == null
        ? 'Toute période'
        : '${range!.start.day.toString().padLeft(2, '0')}/${range!.start.month.toString().padLeft(2, '0')}/${range!.start.year} - '
            '${range!.end.day.toString().padLeft(2, '0')}/${range!.end.month.toString().padLeft(2, '0')}/${range!.end.year}';

    return OutlinedButton.icon(
      onPressed: () async {
        final result = await showDateRangePicker(
          context: context,
          initialDateRange: range,
          firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: theme.copyWith(
                colorScheme: theme.colorScheme.copyWith(
                  primary: theme.colorScheme.primary,
                ),
              ),
              child: child!,
            );
          },
        );
        onSelected(result);
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.calendar_today_rounded, size: 18),
      label: Text(label),
      onLongPress: range == null
          ? null
          : () {
              onSelected(null);
            },
    );
  }
}
