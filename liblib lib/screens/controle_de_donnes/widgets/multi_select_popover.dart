// Widget de sélection multiple avec popover
import 'package:flutter/material.dart';

class MultiSelectPopover extends StatelessWidget {
  final String label;
  final List<String> options;
  final List<String> values;
  final ValueChanged<List<String>> onChange;
  final String? placeholder;
  final IconData? icon;

  const MultiSelectPopover({
    super.key,
    required this.label,
    required this.options,
    required this.values,
    required this.onChange,
    this.placeholder,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedLabel = values.isEmpty
        ? (placeholder ?? 'Tous')
        : '${values.length} sélectionné${values.length > 1 ? 's' : ''}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
        ],
        PopupMenuButton<String>(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border:
                  Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8),
              color: theme.colorScheme.surface,
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    selectedLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: values.isEmpty
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          itemBuilder: (context) => [
            // Option "Tout sélectionner/déselectionner"
            PopupMenuItem<String>(
              value: '__select_all__',
              child: Row(
                children: [
                  Icon(
                    values.length == options.length
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    values.length == options.length
                        ? 'Tout désélectionner'
                        : 'Tout sélectionner',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            if (options.isNotEmpty) const PopupMenuDivider(),

            // Options individuelles
            ...options.map((option) {
              final isSelected = values.contains(option);
              return CheckedPopupMenuItem<String>(
                value: option,
                checked: isSelected,
                child: Text(
                  option,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),

            if (values.isNotEmpty) ...[
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: '__clear__',
                child: Row(
                  children: [
                    Icon(
                      Icons.clear,
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Effacer',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          onSelected: (String value) {
            switch (value) {
              case '__select_all__':
                if (values.length == options.length) {
                  onChange([]);
                } else {
                  onChange(List.from(options));
                }
                break;
              case '__clear__':
                onChange([]);
                break;
              default:
                final newValues = List<String>.from(values);
                if (newValues.contains(value)) {
                  newValues.remove(value);
                } else {
                  newValues.add(value);
                }
                onChange(newValues);
                break;
            }
          },
        ),
      ],
    );
  }
}

/// Version simplifiée pour les cas simples
class SimpleMultiSelect extends StatelessWidget {
  final List<String> options;
  final List<String> values;
  final ValueChanged<List<String>> onChange;
  final String? hint;

  const SimpleMultiSelect({
    super.key,
    required this.options,
    required this.values,
    required this.onChange,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return MultiSelectPopover(
      label: '',
      options: options,
      values: values,
      onChange: onChange,
      placeholder: hint,
    );
  }
}

/// Widget d'affichage des éléments sélectionnés sous forme de chips
class SelectedItemsChips extends StatelessWidget {
  final List<String> items;
  final ValueChanged<String>? onRemove;
  final int? maxVisible;
  final String? moreText;

  const SelectedItemsChips({
    super.key,
    required this.items,
    this.onRemove,
    this.maxVisible,
    this.moreText,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final itemsToShow = maxVisible != null && items.length > maxVisible!
        ? items.take(maxVisible!).toList()
        : items;
    final hasMore = maxVisible != null && items.length > maxVisible!;

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        ...itemsToShow.map((item) => Chip(
              label: Text(
                item,
                style: theme.textTheme.labelSmall,
              ),
              onDeleted: onRemove != null ? () => onRemove!(item) : null,
              deleteIcon: const Icon(Icons.close, size: 16),
              backgroundColor: theme.colorScheme.primaryContainer,
              side: BorderSide.none,
            )),
        if (hasMore)
          Chip(
            label: Text(
              moreText ?? '+${items.length - maxVisible!}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            backgroundColor: theme.colorScheme.surfaceVariant,
            side: BorderSide.none,
          ),
      ],
    );
  }
}

/// Composant combiné avec affichage des sélections
class MultiSelectWithChips extends StatelessWidget {
  final String label;
  final List<String> options;
  final List<String> values;
  final ValueChanged<List<String>> onChange;
  final String? placeholder;
  final IconData? icon;
  final int? maxChipsVisible;

  const MultiSelectWithChips({
    super.key,
    required this.label,
    required this.options,
    required this.values,
    required this.onChange,
    this.placeholder,
    this.icon,
    this.maxChipsVisible = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MultiSelectPopover(
          label: label,
          options: options,
          values: values,
          onChange: onChange,
          placeholder: placeholder,
          icon: icon,
        ),
        if (values.isNotEmpty) ...[
          const SizedBox(height: 8),
          SelectedItemsChips(
            items: values,
            maxVisible: maxChipsVisible,
            onRemove: (item) {
              final newValues = List<String>.from(values);
              newValues.remove(item);
              onChange(newValues);
            },
          ),
        ],
      ],
    );
  }
}
