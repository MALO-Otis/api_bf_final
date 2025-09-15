import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';

/// 📜 PAGE HISTORIQUE DES ATTRIBUTIONS
///
/// Page dédiée pour consulter l'historique complet des attributions
class AttributionHistoryPage extends StatefulWidget {
  const AttributionHistoryPage({Key? key}) : super(key: key);

  @override
  State<AttributionHistoryPage> createState() => _AttributionHistoryPageState();
}

class _AttributionHistoryPageState extends State<AttributionHistoryPage> {
  final RxBool _isLoading = true.obs;
  final RxList<ControlAttribution> _attributions = <ControlAttribution>[].obs;
  final RxList<ControlAttribution> _filteredAttributions =
      <ControlAttribution>[].obs;

  AttributionType? _selectedType;
  String? _selectedSite;
  DateTime? _dateDebut;
  DateTime? _dateFin;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _sites = [
    'Koudougou',
    'Bobo-Dioulasso',
    'Ouagadougou',
    'Réo'
  ];

  @override
  void initState() {
    super.initState();
    _loadHistorique();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistorique() async {
    try {
      _isLoading.value = true;

      // TODO: Charger depuis Firestore
      // Simulation de données pour l'instant
      await Future.delayed(const Duration(seconds: 1));

      final mockAttributions = <ControlAttribution>[
        ControlAttribution(
          id: 'attr_1',
          type: AttributionType.extraction,
          natureProduitsAttribues: ProductNature.brut,
          utilisateur: 'Admin',
          listeContenants: ['C001', 'C002'],
          sourceCollecteId: 'collect_1',
          sourceType: 'Récolte',
          siteOrigine: 'Koudougou',
          siteReceveur: 'Bobo-Dioulasso',
          dateCollecte: DateTime.now().subtract(const Duration(days: 5)),
          dateCreation: DateTime.now().subtract(const Duration(days: 3)),
          statut: 'terminé',
          commentaires: 'Attribution normale',
        ),
        ControlAttribution(
          id: 'attr_2',
          type: AttributionType.filtration,
          natureProduitsAttribues: ProductNature.liquide,
          utilisateur: 'Technicien',
          listeContenants: ['C003'],
          sourceCollecteId: 'collect_2',
          sourceType: 'SCOOP',
          siteOrigine: 'Ouagadougou',
          siteReceveur: 'Réo',
          dateCollecte: DateTime.now().subtract(const Duration(days: 10)),
          dateCreation: DateTime.now().subtract(const Duration(days: 8)),
          statut: 'en_cours',
        ),
      ];

      _attributions.assignAll(mockAttributions);
      _applyFilters();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger l\'historique: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void _applyFilters() {
    var filtered = _attributions.where((attribution) {
      // Filtre par type
      if (_selectedType != null && attribution.type != _selectedType) {
        return false;
      }

      // Filtre par site
      if (_selectedSite != null &&
          attribution.siteOrigine != _selectedSite &&
          attribution.siteReceveur != _selectedSite) {
        return false;
      }

      // Filtre par date
      if (_dateDebut != null &&
          attribution.dateCreation.isBefore(_dateDebut!)) {
        return false;
      }
      if (_dateFin != null && attribution.dateCreation.isAfter(_dateFin!)) {
        return false;
      }

      // Filtre par recherche
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        if (!attribution.id.toLowerCase().contains(query) &&
            !attribution.utilisateur.toLowerCase().contains(query) &&
            !attribution.siteOrigine.toLowerCase().contains(query) &&
            !attribution.siteReceveur.toLowerCase().contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Tri par date (plus récent en premier)
    filtered.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));

    _filteredAttributions.assignAll(filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.history, size: 24),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Historique des Attributions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Suivi complet des attributions',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.indigo[600],
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadHistorique,
          tooltip: 'Actualiser',
        ),
        Obx(() => _filteredAttributions.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.file_download),
                onPressed: _exportData,
                tooltip: 'Exporter',
              )
            : const SizedBox()),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par ID, utilisateur, site...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 16),

          // Filtres rapides
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  'Type',
                  _selectedType?.label,
                  () => _showTypeFilter(),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Site',
                  _selectedSite,
                  () => _showSiteFilter(),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Période',
                  _getDateRangeText(),
                  () => _showDateFilter(),
                ),
                const SizedBox(width: 8),
                if (_hasActiveFilters())
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Effacer'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, VoidCallback onTap) {
    return FilterChip(
      label: Text(value != null ? '$label: $value' : label),
      selected: value != null,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.grey[100],
      selectedColor: Colors.indigo[100],
    );
  }

  Widget _buildContent() {
    return Obx(() {
      if (_isLoading.value) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement de l\'historique...'),
            ],
          ),
        );
      }

      if (_filteredAttributions.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredAttributions.length,
        itemBuilder: (context, index) {
          final attribution = _filteredAttributions[index];
          return _buildAttributionCard(attribution);
        },
      );
    });
  }

  Widget _buildAttributionCard(ControlAttribution attribution) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getTypeColor(attribution.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTypeIcon(attribution.type),
                    color: _getTypeColor(attribution.type),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attribution.type.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${attribution.id}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatutColor(attribution.statut).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    attribution.statut.toUpperCase(),
                    style: TextStyle(
                      color: _getStatutColor(attribution.statut),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Détails
            Row(
              children: [
                Expanded(
                  child: _buildDetailColumn(
                      'Utilisateur', attribution.utilisateur),
                ),
                Expanded(
                  child: _buildDetailColumn(
                      'Site Origine', attribution.siteOrigine),
                ),
                Expanded(
                  child: _buildDetailColumn(
                      'Site Receveur', attribution.siteReceveur),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildDetailColumn(
                    'Contenants',
                    '${attribution.listeContenants.length} contenants',
                  ),
                ),
                Expanded(
                  child: _buildDetailColumn(
                    'Date Création',
                    _formatDate(attribution.dateCreation),
                  ),
                ),
                Expanded(
                  child: _buildDetailColumn(
                    'Nature',
                    attribution.natureProduitsAttribues.label,
                  ),
                ),
              ],
            ),

            if (attribution.commentaires != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  attribution.commentaires!,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
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
            Icons.history_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune attribution trouvée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aucune attribution ne correspond aux critères de recherche.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.clear_all),
            label: const Text('Effacer les filtres'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Méthodes utilitaires
  Color _getTypeColor(AttributionType type) {
    switch (type) {
      case AttributionType.extraction:
        return Colors.brown;
      case AttributionType.filtration:
        return Colors.blue;
      case AttributionType.traitementCire:
        return Colors.amber[700]!;
    }
  }

  IconData _getTypeIcon(AttributionType type) {
    switch (type) {
      case AttributionType.extraction:
        return Icons.science;
      case AttributionType.filtration:
        return Icons.water_drop;
      case AttributionType.traitementCire:
        return Icons.spa;
    }
  }

  Color _getStatutColor(String statut) {
    switch (statut.toLowerCase()) {
      case 'attribué':
        return Colors.blue;
      case 'en_cours':
        return Colors.orange;
      case 'terminé':
        return Colors.green;
      case 'annulé':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String? _getDateRangeText() {
    if (_dateDebut != null && _dateFin != null) {
      return '${_formatDate(_dateDebut!)} - ${_formatDate(_dateFin!)}';
    } else if (_dateDebut != null) {
      return 'Depuis ${_formatDate(_dateDebut!)}';
    } else if (_dateFin != null) {
      return 'Jusqu\'au ${_formatDate(_dateFin!)}';
    }
    return null;
  }

  bool _hasActiveFilters() {
    return _selectedType != null ||
        _selectedSite != null ||
        _dateDebut != null ||
        _dateFin != null ||
        _searchController.text.isNotEmpty;
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _selectedSite = null;
      _dateDebut = null;
      _dateFin = null;
      _searchController.clear();
    });
    _applyFilters();
  }

  void _showTypeFilter() {
    Get.dialog(
      SimpleDialog(
        title: const Text('Filtrer par Type'),
        children: [
          ...AttributionType.values.map((type) => SimpleDialogOption(
                onPressed: () {
                  setState(() {
                    _selectedType = _selectedType == type ? null : type;
                  });
                  _applyFilters();
                  Navigator.of(context).pop();
                },
                child: Row(
                  children: [
                    Icon(_getTypeIcon(type), color: _getTypeColor(type)),
                    const SizedBox(width: 12),
                    Text(type.label),
                    if (_selectedType == type) ...[
                      const Spacer(),
                      const Icon(Icons.check, color: Colors.green),
                    ],
                  ],
                ),
              )),
          SimpleDialogOption(
            onPressed: () {
              setState(() => _selectedType = null);
              _applyFilters();
              Navigator.of(context).pop();
            },
            child: const Row(
              children: [
                Icon(Icons.clear, color: Colors.red),
                SizedBox(width: 12),
                Text('Effacer le filtre'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSiteFilter() {
    Get.dialog(
      SimpleDialog(
        title: const Text('Filtrer par Site'),
        children: [
          ..._sites.map((site) => SimpleDialogOption(
                onPressed: () {
                  setState(() {
                    _selectedSite = _selectedSite == site ? null : site;
                  });
                  _applyFilters();
                  Navigator.of(context).pop();
                },
                child: Row(
                  children: [
                    const Icon(Icons.business),
                    const SizedBox(width: 12),
                    Text(site),
                    if (_selectedSite == site) ...[
                      const Spacer(),
                      const Icon(Icons.check, color: Colors.green),
                    ],
                  ],
                ),
              )),
          SimpleDialogOption(
            onPressed: () {
              setState(() => _selectedSite = null);
              _applyFilters();
              Navigator.of(context).pop();
            },
            child: const Row(
              children: [
                Icon(Icons.clear, color: Colors.red),
                SizedBox(width: 12),
                Text('Effacer le filtre'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDateFilter() {
    // TODO: Implémenter le sélecteur de plage de dates
    Get.snackbar(
      'Fonctionnalité à venir',
      'Le filtre par date sera bientôt disponible',
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
    );
  }

  void _exportData() {
    // TODO: Implémenter l'export des données
    Get.snackbar(
      'Export en cours',
      'Les données seront bientôt exportées',
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
    );
  }
}
