import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attribution_models.dart';

/// Widget pour les filtres d'attributions
class AttributionFiltersWidget extends StatefulWidget {
  final AttributionFilters filters;
  final Function(AttributionFilters) onFiltersChanged;
  final List<AttributionExtraction> attributions;

  const AttributionFiltersWidget({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
    required this.attributions,
  });

  @override
  State<AttributionFiltersWidget> createState() =>
      _AttributionFiltersWidgetState();
}

class _AttributionFiltersWidgetState extends State<AttributionFiltersWidget> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _showFiltersDialog,
      icon: Stack(
        children: [
          const Icon(Icons.filter_list),
          if (widget.filters.isActive)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      tooltip: 'Filtres',
    );
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => _FiltersDialog(
        filters: widget.filters,
        attributions: widget.attributions,
        onFiltersChanged: widget.onFiltersChanged,
      ),
    );
  }
}

class _FiltersDialog extends StatefulWidget {
  final AttributionFilters filters;
  final List<AttributionExtraction> attributions;
  final Function(AttributionFilters) onFiltersChanged;

  const _FiltersDialog({
    required this.filters,
    required this.attributions,
    required this.onFiltersChanged,
  });

  @override
  State<_FiltersDialog> createState() => _FiltersDialogState();
}

class _FiltersDialogState extends State<_FiltersDialog> {
  late AttributionFilters _tempFilters;
  final _lotController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tempFilters = widget.filters;
    _lotController.text = widget.filters.rechercheLot ?? '';
  }

  @override
  void dispose() {
    _lotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: isDesktop ? 600 : null,
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 600 : MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusFilters(),
                    const SizedBox(height: 24),
                    _buildUserFilters(),
                    const SizedBox(height: 24),
                    _buildDateFilters(),
                    const SizedBox(height: 24),
                    _buildLotSearch(),
                    const SizedBox(height: 24),
                    _buildFilterSummary(),
                  ],
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade600, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: Colors.white, size: 24),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Filtres avancés',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statuts',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AttributionStatus.values.map((status) {
            final isSelected = _tempFilters.statuts.contains(status);
            return FilterChip(
              label: Text(status.label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _tempFilters = _tempFilters.copyWith(
                      statuts: [..._tempFilters.statuts, status],
                    );
                  } else {
                    _tempFilters = _tempFilters.copyWith(
                      statuts: _tempFilters.statuts
                          .where((s) => s != status)
                          .toList(),
                    );
                  }
                });
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: _getStatusColor(status).withOpacity(0.2),
              checkmarkColor: _getStatusColor(status),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUserFilters() {
    final availableUsers =
        widget.attributions.map((a) => a.utilisateur).toSet().toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Utilisateurs',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableUsers.map((user) {
            final isSelected = _tempFilters.utilisateurs.contains(user);
            return FilterChip(
              label: Text(user),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _tempFilters = _tempFilters.copyWith(
                      utilisateurs: [..._tempFilters.utilisateurs, user],
                    );
                  } else {
                    _tempFilters = _tempFilters.copyWith(
                      utilisateurs: _tempFilters.utilisateurs
                          .where((u) => u != user)
                          .toList(),
                    );
                  }
                });
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: Colors.blue.shade100,
              checkmarkColor: Colors.blue.shade600,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Période d\'attribution',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'Date de début',
                value: _tempFilters.dateDebut,
                onChanged: (date) {
                  setState(() {
                    _tempFilters = _tempFilters.copyWith(dateDebut: date);
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                label: 'Date de fin',
                value: _tempFilters.dateFin,
                onChanged: (date) {
                  setState(() {
                    _tempFilters = _tempFilters.copyWith(dateFin: date);
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required Function(DateTime?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            onChanged(date);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today,
                    color: Colors.grey.shade600, size: 18),
                const SizedBox(width: 8),
                Text(
                  value != null
                      ? DateFormat('dd/MM/yyyy').format(value)
                      : 'Sélectionner',
                  style: TextStyle(
                    color:
                        value != null ? Colors.black87 : Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                if (value != null)
                  GestureDetector(
                    onTap: () => onChanged(null),
                    child: Icon(Icons.clear,
                        color: Colors.grey.shade600, size: 18),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLotSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recherche par lot',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _lotController,
          decoration: InputDecoration(
            hintText: 'Numéro de lot ou utilisateur...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          onChanged: (value) {
            setState(() {
              _tempFilters = _tempFilters.copyWith(
                  rechercheLot: value.trim().isEmpty ? null : value.trim());
            });
          },
        ),
      ],
    );
  }

  Widget _buildFilterSummary() {
    final activeFiltersCount = [
      _tempFilters.statuts.isNotEmpty,
      _tempFilters.utilisateurs.isNotEmpty,
      _tempFilters.dateDebut != null,
      _tempFilters.dateFin != null,
      _tempFilters.rechercheLot?.isNotEmpty == true,
    ].where((active) => active).length;

    if (activeFiltersCount == 0) return const SizedBox();

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
          Text(
            'Filtres actifs ($activeFiltersCount)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 8),
          if (_tempFilters.statuts.isNotEmpty)
            Text('• ${_tempFilters.statuts.length} statut(s) sélectionné(s)'),
          if (_tempFilters.utilisateurs.isNotEmpty)
            Text(
                '• ${_tempFilters.utilisateurs.length} utilisateur(s) sélectionné(s)'),
          if (_tempFilters.dateDebut != null)
            Text(
                '• Depuis le ${DateFormat('dd/MM/yyyy').format(_tempFilters.dateDebut!)}'),
          if (_tempFilters.dateFin != null)
            Text(
                '• Jusqu\'au ${DateFormat('dd/MM/yyyy').format(_tempFilters.dateFin!)}'),
          if (_tempFilters.rechercheLot?.isNotEmpty == true)
            Text('• Recherche: "${_tempFilters.rechercheLot}"'),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.clear_all),
            label: const Text('Effacer tout'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _tempFilters = AttributionFilters();
      _lotController.clear();
    });
  }

  void _applyFilters() {
    widget.onFiltersChanged(_tempFilters);
    Navigator.pop(context);
  }

  Color _getStatusColor(AttributionStatus statut) {
    switch (statut) {
      case AttributionStatus.attribueExtraction:
        return Colors.blue;
      case AttributionStatus.enCoursExtraction:
        return Colors.orange;
      case AttributionStatus.extraitEnAttente:
        return Colors.purple;
      case AttributionStatus.attribueMaturation:
        return Colors.teal;
      case AttributionStatus.enCoursMaturation:
        return Colors.indigo;
      case AttributionStatus.termineMaturation:
        return Colors.green;
      case AttributionStatus.annule:
        return Colors.red;
    }
  }
}
