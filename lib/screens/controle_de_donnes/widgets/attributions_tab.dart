import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/attribution_models.dart';
import '../services/control_attribution_service.dart';

/// Onglet des attributions dans le module Contrôle
class AttributionsTab extends StatefulWidget {
  const AttributionsTab({super.key});

  @override
  State<AttributionsTab> createState() => _AttributionsTabState();
}

class _AttributionsTabState extends State<AttributionsTab> {
  final ControlAttributionService _service = ControlAttributionService();
  final TextEditingController _searchController = TextEditingController();

  List<ControlAttribution> _filteredAttributions = [];
  ControlAttributionFilters _filters = ControlAttributionFilters();
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _service.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _loadData() {
    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _applyFilters();
        setState(() => _isLoading = false);
      }
    });
  }

  void _onServiceChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = _service.filtrerAttributions(_filters);

    // Appliquer la recherche textuelle
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((attribution) =>
              attribution.utilisateur.toLowerCase().contains(query) ||
              attribution.site.toLowerCase().contains(query) ||
              attribution.type.label.toLowerCase().contains(query) ||
              attribution.natureProduitsAttribues.label
                  .toLowerCase()
                  .contains(query))
          .toList();
    }

    setState(() {
      _filteredAttributions = filtered;
    });
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1000;
    final isMobile = screenWidth < 600;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Column(
        children: [
          // Header avec stats
          _buildStatsHeader(),
          const SizedBox(height: 16),

          // Barre de recherche
          _buildSearchBar(),
          const SizedBox(height: 16),

          // Liste des attributions
          Expanded(
            child: _filteredAttributions.isEmpty
                ? _buildEmptyState()
                : _buildAttributionsList(isDesktop, isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    final stats = _service.calculerStatistiques(_filteredAttributions);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade600,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.assignment, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attributions depuis Contrôle',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Gestion des attributions vers Extraction et Filtration',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(
                  'Total', stats.totalAttributions.toString(), Colors.indigo),
              _buildStatItem(
                  'Extractions', stats.extractions.toString(), Colors.blue),
              _buildStatItem(
                  'Filtrations', stats.filtrations.toString(), Colors.purple),
              _buildStatItem(
                  'En cours', stats.enCours.toString(), Colors.orange),
              _buildStatItem(
                  'Terminées', stats.terminees.toString(), Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: (color as MaterialColor).shade700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Rechercher par utilisateur, site, type...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: _showFiltersDialog,
          icon: Stack(
            children: [
              const Icon(Icons.filter_list),
              if (_filters.isActive)
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
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune attribution trouvée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filters.isActive
                ? 'Essayez de modifier vos filtres'
                : 'Les attributions apparaîtront ici',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributionsList(bool isDesktop, bool isMobile) {
    if (isDesktop) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
        ),
        itemCount: _filteredAttributions.length,
        itemBuilder: (context, index) {
          return _buildAttributionCard(_filteredAttributions[index]);
        },
      );
    } else {
      return ListView.builder(
        itemCount: _filteredAttributions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildAttributionCard(_filteredAttributions[index]),
          );
        },
      );
    }
  }

  Widget _buildAttributionCard(ControlAttribution attribution) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showAttributionDetails(attribution),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTypeColor(attribution.type),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      attribution.type.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          _getStatusColor(attribution.statut).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(attribution.statut)
                            .withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      attribution.statut.label,
                      style: TextStyle(
                        color: _getStatusColor(attribution.statut),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Attribution Info
              Text(
                '${attribution.type.label} - ${attribution.natureProduitsAttribues.label}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Info
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    attribution.site,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.inventory, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${attribution.listeContenants.length} contenant(s)',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Utilisateur et date
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      attribution.utilisateur,
                      style: TextStyle(color: Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd/MM/yyyy')
                        .format(attribution.dateAttribution),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(AttributionType type) {
    switch (type) {
      case AttributionType.extraction:
        return Colors.blue.shade600;
      case AttributionType.filtration:
        return Colors.purple.shade600;
    }
  }

  Color _getStatusColor(AttributionStatus statut) {
    switch (statut) {
      case AttributionStatus.attribueExtraction:
        return Colors.blue;
      case AttributionStatus.attribueFiltration:
        return Colors.purple;
      case AttributionStatus.enCoursTraitement:
        return Colors.orange;
      case AttributionStatus.traiteEnAttente:
        return Colors.teal;
      case AttributionStatus.termine:
        return Colors.green;
      case AttributionStatus.annule:
        return Colors.red;
    }
  }

  void _showAttributionDetails(ControlAttribution attribution) {
    showDialog(
      context: context,
      builder: (context) => _AttributionDetailsDialog(attribution: attribution),
    );
  }

  void _showFiltersDialog() {
    // Placeholder pour les filtres
    Get.snackbar(
      'Filtres',
      'Filtres avancés bientôt disponibles',
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
    );
  }
}

/// Dialog des détails d'attribution
class _AttributionDetailsDialog extends StatelessWidget {
  final ControlAttribution attribution;

  const _AttributionDetailsDialog({required this.attribution});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getTypeColor(attribution.type),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    attribution.type == AttributionType.extraction
                        ? Icons.science
                        : Icons.filter_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attribution ${attribution.type.label}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${attribution.type.label} - ${attribution.natureProduitsAttribues.label}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Détails
            _buildDetailRow('Site', attribution.site),
            _buildDetailRow('Utilisateur', attribution.utilisateur),
            _buildDetailRow(
                'Date d\'attribution',
                DateFormat('dd/MM/yyyy HH:mm')
                    .format(attribution.dateAttribution)),
            _buildDetailRow('Statut', attribution.statut.label),
            _buildDetailRow(
                'Contenants', '${attribution.listeContenants.length}'),
            _buildDetailRow('Source', attribution.sourceType),

            if (attribution.commentaires?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              const Text(
                'Commentaires',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(attribution.commentaires!),
              ),
            ],

            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer'),
                ),
                const SizedBox(width: 16),
                if (attribution.peutEtreAnnulee)
                  ElevatedButton(
                    onPressed: () => _confirmCancel(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Annuler'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(AttributionType type) {
    switch (type) {
      case AttributionType.extraction:
        return Colors.blue.shade600;
      case AttributionType.filtration:
        return Colors.purple.shade600;
    }
  }

  void _confirmCancel(BuildContext context) {
    Navigator.pop(context);
    Get.snackbar(
      'Annulation',
      'Fonctionnalité d\'annulation bientôt disponible',
      backgroundColor: Colors.orange.shade100,
      colorText: Colors.orange.shade800,
    );
  }
}
