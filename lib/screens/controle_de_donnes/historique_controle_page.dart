import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/quality_control_models.dart';
import 'services/quality_control_service.dart';

class HistoriqueControlePage extends StatefulWidget {
  const HistoriqueControlePage({super.key});

  @override
  State<HistoriqueControlePage> createState() => _HistoriqueControlePageState();
}

class _HistoriqueControlePageState extends State<HistoriqueControlePage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final QualityControlService _qualityService = QualityControlService();

  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // État
  bool _isLoading = true;
  List<QualityControlData> _allControls = [];
  List<QualityControlData> _filteredControls = [];
  Map<String, List<QualityControlData>> _groupedControls = {};
  QualityStats _stats = const QualityStats(
    totalControls: 0,
    conformeCount: 0,
    nonConformeCount: 0,
    conformityRate: 0,
    averageWaterContent: 0,
    totalHoneyWeight: 0,
  );

  // Filtres
  String _searchQuery = '';
  ConformityStatus? _selectedStatus;
  HoneyNature? _selectedNature;
  String? _selectedProducer;
  DateTimeRange? _selectedDateRange;
  bool _showFilters = false;

  // Affichage
  bool _isGroupedView =
      true; // Nouvelle option pour basculer entre vue groupée et liste

  // Tri
  String _sortBy = 'date'; // date, producer, status, weight
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Charger toutes les données
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 365));

    _allControls =
        _qualityService.getQualityControlsByDateRange(startDate, endDate);
    _stats =
        _qualityService.getQualityStats(startDate: startDate, endDate: endDate);

    _applyFilters();

    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
    _fadeController.forward();
  }

  Future<void> _clearTestData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer les données fictives'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer toutes les données de test fictives ? '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);

        await _qualityService.clearTestData();

        // Recharger les données après suppression
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Données fictives supprimées avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _applyFilters() {
    _filteredControls = _allControls.where((control) {
      // Recherche textuelle
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!control.producer.toLowerCase().contains(query) &&
            !control.containerCode.toLowerCase().contains(query) &&
            !control.apiaryVillage.toLowerCase().contains(query) &&
            !control.floralPredominance.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Filtre statut
      if (_selectedStatus != null &&
          control.conformityStatus != _selectedStatus) {
        return false;
      }

      // Filtre nature du miel
      if (_selectedNature != null && control.honeyNature != _selectedNature) {
        return false;
      }

      // Filtre producteur
      if (_selectedProducer != null && control.producer != _selectedProducer) {
        return false;
      }

      // Filtre date
      if (_selectedDateRange != null) {
        final date = control.receptionDate;
        if (date.isBefore(_selectedDateRange!.start) ||
            date.isAfter(_selectedDateRange!.end)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Tri
    _filteredControls.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'date':
          comparison = a.receptionDate.compareTo(b.receptionDate);
          break;
        case 'producer':
          comparison = a.producer.compareTo(b.producer);
          break;
        case 'status':
          comparison =
              a.conformityStatus.index.compareTo(b.conformityStatus.index);
          break;
        case 'weight':
          comparison = a.honeyWeight.compareTo(b.honeyWeight);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    // Regroupement par collecte/producteur
    _groupedControls = _groupControlsByProducer(_filteredControls);

    setState(() {});
  }

  Map<String, List<QualityControlData>> _groupControlsByProducer(
      List<QualityControlData> controls) {
    final Map<String, List<QualityControlData>> grouped = {};

    for (final control in controls) {
      final key = '${control.producer} - ${control.apiaryVillage}';
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(control);
    }

    // Trier les groupes par nombre de contrôles (décroissant) puis par nom
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final countComparison =
            grouped[b]!.length.compareTo(grouped[a]!.length);
        if (countComparison != 0) return countComparison;
        return a.compareTo(b);
      });

    final Map<String, List<QualityControlData>> sortedGrouped = {};
    for (final key in sortedKeys) {
      // Trier les contrôles dans chaque groupe par date (plus récent en premier)
      grouped[key]!.sort((a, b) => b.receptionDate.compareTo(a.receptionDate));
      sortedGrouped[key] = grouped[key]!;
    }

    return sortedGrouped;
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _applyFilters();
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Colors.blue.shade700,
                ),
          ),
          child: child!,
        );
      },
    );

    if (range != null) {
      setState(() => _selectedDateRange = range);
      _applyFilters();
    }
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedStatus = null;
      _selectedNature = null;
      _selectedProducer = null;
      _selectedDateRange = null;
      _searchController.clear();
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historique des Contrôles',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            Text(
              _isGroupedView ? 'Groupé par Producteur' : 'Vue Liste',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(_isGroupedView ? Icons.view_list : Icons.group_work),
            onPressed: () => setState(() => _isGroupedView = !_isGroupedView),
            tooltip: _isGroupedView ? 'Vue liste' : 'Vue groupée',
          ),
          IconButton(
            icon:
                Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip:
                _showFilters ? 'Masquer les filtres' : 'Afficher les filtres',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearTestData,
            tooltip: 'Supprimer les données fictives',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
        bottom: _showFilters
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildSearchBar(theme),
                ),
              ),
      ),
      body: _isLoading
          ? _buildLoadingView()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  if (_showFilters) _buildFiltersSection(theme, isMobile),
                  if (!_showFilters)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildSearchBar(theme),
                    ),
                  _buildStatsCards(theme, isMobile),
                  Expanded(
                    child: _isGroupedView
                        ? _buildGroupedView(theme, isMobile, isTablet)
                        : (isMobile
                            ? _buildMobileList(theme)
                            : _buildDesktopContent(theme, isTablet)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement des contrôles qualité...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher par producteur, code, village...',
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildFiltersSection(ThemeData theme, bool isMobile) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Filtres avancés',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text('Effacer'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isMobile)
            ..._buildMobileFilters(theme)
          else
            ..._buildDesktopFilters(theme),
        ],
      ),
    );
  }

  List<Widget> _buildMobileFilters(ThemeData theme) {
    return [
      _buildStatusFilter(),
      const SizedBox(height: 12),
      _buildNatureFilter(),
      const SizedBox(height: 12),
      _buildDateRangeFilter(),
      const SizedBox(height: 12),
      _buildSortOptions(),
    ];
  }

  List<Widget> _buildDesktopFilters(ThemeData theme) {
    return [
      Row(
        children: [
          Expanded(child: _buildStatusFilter()),
          const SizedBox(width: 12),
          Expanded(child: _buildNatureFilter()),
          const SizedBox(width: 12),
          Expanded(child: _buildDateRangeFilter()),
          const SizedBox(width: 12),
          Expanded(child: _buildSortOptions()),
        ],
      ),
    ];
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<ConformityStatus?>(
      value: _selectedStatus,
      decoration: const InputDecoration(
        labelText: 'Statut',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Tous les statuts')),
        DropdownMenuItem(
          value: ConformityStatus.conforme,
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Text('Conforme'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: ConformityStatus.nonConforme,
          child: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              const Text('Non conforme'),
            ],
          ),
        ),
      ],
      onChanged: (value) {
        setState(() => _selectedStatus = value);
        _applyFilters();
      },
    );
  }

  Widget _buildNatureFilter() {
    return DropdownButtonFormField<HoneyNature?>(
      value: _selectedNature,
      decoration: const InputDecoration(
        labelText: 'Nature du miel',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Toutes les natures')),
        const DropdownMenuItem(
          value: HoneyNature.brut,
          child: Text('Brut'),
        ),
        const DropdownMenuItem(
          value: HoneyNature.prefilitre,
          child: Text('Préfiltré'),
        ),
      ],
      onChanged: (value) {
        setState(() => _selectedNature = value);
        _applyFilters();
      },
    );
  }

  Widget _buildDateRangeFilter() {
    return InkWell(
      onTap: _selectDateRange,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Période',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Row(
          children: [
            Icon(Icons.date_range, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedDateRange != null
                    ? '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}'
                    : 'Sélectionner une période',
                style: TextStyle(
                  color: _selectedDateRange != null
                      ? Colors.black
                      : Colors.grey.shade600,
                ),
              ),
            ),
            if (_selectedDateRange != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  setState(() => _selectedDateRange = null);
                  _applyFilters();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOptions() {
    return DropdownButtonFormField<String>(
      value: _sortBy,
      decoration: const InputDecoration(
        labelText: 'Trier par',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: const [
        DropdownMenuItem(value: 'date', child: Text('Date')),
        DropdownMenuItem(value: 'producer', child: Text('Producteur')),
        DropdownMenuItem(value: 'status', child: Text('Statut')),
        DropdownMenuItem(value: 'weight', child: Text('Poids')),
      ],
      onChanged: (value) {
        setState(() => _sortBy = value!);
        _applyFilters();
      },
    );
  }

  Widget _buildStatsCards(ThemeData theme, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: isMobile ? _buildMobileStats() : _buildDesktopStats(),
    );
  }

  Widget _buildMobileStats() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildStatCard(
              _isGroupedView ? 'Producteurs' : 'Total',
              _isGroupedView
                  ? _groupedControls.length.toString()
                  : _stats.totalControls.toString(),
              _isGroupedView ? Icons.people : Icons.science,
              _isGroupedView ? Colors.teal : Colors.blue,
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard(
              'Conformes',
              _stats.conformeCount.toString(),
              Icons.check_circle,
              Colors.green,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildStatCard(
              'Non conformes',
              _stats.nonConformeCount.toString(),
              Icons.cancel,
              Colors.red,
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard(
              'Taux conformité',
              '${_stats.conformityRate.toStringAsFixed(1)}%',
              Icons.trending_up,
              Colors.orange,
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopStats() {
    return Row(
      children: [
        Expanded(
            child: _buildStatCard(
          _isGroupedView ? 'Producteurs' : 'Total Contrôles',
          _isGroupedView
              ? _groupedControls.length.toString()
              : _stats.totalControls.toString(),
          _isGroupedView ? Icons.people : Icons.science,
          _isGroupedView ? Colors.teal : Colors.blue,
        )),
        const SizedBox(width: 16),
        Expanded(
            child: _buildStatCard(
          'Conformes',
          _stats.conformeCount.toString(),
          Icons.check_circle,
          Colors.green,
        )),
        const SizedBox(width: 16),
        Expanded(
            child: _buildStatCard(
          'Non Conformes',
          _stats.nonConformeCount.toString(),
          Icons.cancel,
          Colors.red,
        )),
        const SizedBox(width: 16),
        Expanded(
            child: _buildStatCard(
          'Taux de Conformité',
          '${_stats.conformityRate.toStringAsFixed(1)}%',
          Icons.trending_up,
          Colors.orange,
        )),
        const SizedBox(width: 16),
        Expanded(
            child: _buildStatCard(
          'Poids Total',
          '${_stats.totalHoneyWeight.toStringAsFixed(1)} kg',
          Icons.scale,
          Colors.purple,
        )),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedView(ThemeData theme, bool isMobile, bool isTablet) {
    if (_groupedControls.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _groupedControls.length,
      itemBuilder: (context, index) {
        final producerKey = _groupedControls.keys.elementAt(index);
        final controls = _groupedControls[producerKey]!;
        return _buildProducerGroupCard(producerKey, controls, theme, isMobile);
      },
    );
  }

  Widget _buildMobileList(ThemeData theme) {
    if (_filteredControls.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _filteredControls.length,
      itemBuilder: (context, index) {
        final control = _filteredControls[index];
        return _buildMobileControlCard(control, theme);
      },
    );
  }

  Widget _buildDesktopContent(ThemeData theme, bool isTablet) {
    if (_filteredControls.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            _buildTableHeader(theme),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _filteredControls.length,
                itemBuilder: (context, index) {
                  final control = _filteredControls[index];
                  return _buildTableRow(control, theme, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProducerGroupCard(String producerKey,
      List<QualityControlData> controls, ThemeData theme, bool isMobile) {
    final producer = producerKey.split(' - ')[0];
    final village = producerKey.split(' - ')[1];

    // Calculs pour le groupe
    final totalWeight =
        controls.fold<double>(0, (sum, control) => sum + control.honeyWeight);
    final conformeCount = controls
        .where((c) => c.conformityStatus == ConformityStatus.conforme)
        .length;
    final conformityRate =
        controls.isNotEmpty ? (conformeCount / controls.length) * 100 : 0;
    final avgWaterContent =
        controls.where((c) => c.waterContent != null).isNotEmpty
            ? controls
                    .where((c) => c.waterContent != null)
                    .map((c) => c.waterContent!)
                    .reduce((a, b) => a + b) /
                controls.where((c) => c.waterContent != null).length
            : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.only(bottom: 16),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            '${controls.length}',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          producer,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  village,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _buildGroupStat(Icons.scale,
                    '${totalWeight.toStringAsFixed(1)} kg', Colors.purple),
                _buildGroupStat(
                    Icons.check_circle,
                    '${conformityRate.toStringAsFixed(0)}%',
                    conformityRate >= 80 ? Colors.green : Colors.orange),
                if (avgWaterContent > 0)
                  _buildGroupStat(Icons.water_drop,
                      '${avgWaterContent.toStringAsFixed(1)}%', Colors.blue),
              ],
            ),
          ],
        ),
        children: controls
            .map(
              (control) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: isMobile
                    ? _buildCompactControlCard(control, theme)
                    : _buildDesktopControlRow(control, theme),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildGroupStat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactControlCard(QualityControlData control, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  control.containerCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: QualityControlUtils.getConformityStatusColor(
                          control.conformityStatus)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  control.conformityStatus == ConformityStatus.conforme
                      ? 'Conforme'
                      : 'Non conforme',
                  style: TextStyle(
                    color: QualityControlUtils.getConformityStatusColor(
                        control.conformityStatus),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                DateFormat('dd/MM/yyyy').format(control.receptionDate),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const Spacer(),
              Icon(Icons.scale, size: 12, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '${control.honeyWeight.toStringAsFixed(1)} kg',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              if (control.waterContent != null) ...[
                const SizedBox(width: 12),
                Icon(Icons.water_drop, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${control.waterContent!.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ],
          ),
          if (control.floralPredominance.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.local_florist,
                    size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    control.floralPredominance,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopControlRow(QualityControlData control, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              control.containerCode,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('dd/MM/yyyy').format(control.receptionDate),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${control.honeyWeight.toStringAsFixed(1)} kg',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              control.waterContent != null
                  ? '${control.waterContent!.toStringAsFixed(1)}%'
                  : 'N/A',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              control.floralPredominance,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: QualityControlUtils.getConformityStatusColor(
                        control.conformityStatus)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                control.conformityStatus == ConformityStatus.conforme
                    ? 'Conforme'
                    : 'Non conforme',
                style: TextStyle(
                  color: QualityControlUtils.getConformityStatusColor(
                      control.conformityStatus),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.visibility, size: 16),
              onPressed: () => _showControlDetails(control),
              tooltip: 'Voir les détails',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileControlCard(QualityControlData control, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showControlDetails(control),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: QualityControlUtils.getConformityStatusColor(
                              control.conformityStatus)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          QualityControlUtils.getConformityStatusIcon(
                              control.conformityStatus),
                          size: 16,
                          color: QualityControlUtils.getConformityStatusColor(
                              control.conformityStatus),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          QualityControlUtils.getConformityStatusLabel(
                              control.conformityStatus),
                          style: TextStyle(
                            color: QualityControlUtils.getConformityStatusColor(
                                control.conformityStatus),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('dd/MM/yyyy').format(control.receptionDate),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                control.containerCode,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                control.producer,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildInfoChip(Icons.location_on, control.apiaryVillage),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                      Icons.local_florist, control.floralPredominance),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.scale, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${control.honeyWeight.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.water_drop, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    control.waterContent != null
                        ? '${control.waterContent!.toStringAsFixed(1)}%'
                        : 'N/A',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
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

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildHeaderCell('Code', flex: 1),
          _buildHeaderCell('Producteur', flex: 2),
          _buildHeaderCell('Village', flex: 2),
          _buildHeaderCell('Poids', flex: 1),
          _buildHeaderCell('Eau (%)', flex: 1),
          _buildHeaderCell('Statut', flex: 1),
          _buildHeaderCell('Date', flex: 1),
          const SizedBox(width: 40), // Pour les actions
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildTableRow(
      QualityControlData control, ThemeData theme, int index) {
    final isEven = index % 2 == 0;
    return Container(
      decoration: BoxDecoration(
        color: isEven ? Colors.white : Colors.grey.shade50,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              control.containerCode,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              control.producer,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              control.apiaryVillage,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              '${control.honeyWeight.toStringAsFixed(1)} kg',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              control.waterContent != null
                  ? '${control.waterContent!.toStringAsFixed(1)}%'
                  : 'N/A',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: QualityControlUtils.getConformityStatusColor(
                        control.conformityStatus)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    QualityControlUtils.getConformityStatusIcon(
                        control.conformityStatus),
                    size: 12,
                    color: QualityControlUtils.getConformityStatusColor(
                        control.conformityStatus),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    control.conformityStatus == ConformityStatus.conforme
                        ? 'C'
                        : 'NC',
                    style: TextStyle(
                      color: QualityControlUtils.getConformityStatusColor(
                          control.conformityStatus),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Text(
              DateFormat('dd/MM/yy').format(control.receptionDate),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.visibility, size: 18),
              onPressed: () => _showControlDetails(control),
              tooltip: 'Voir les détails',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun contrôle trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Modifiez vos filtres ou lancez un nouveau contrôle',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showControlDetails(QualityControlData control) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDetailsModal(control),
    );
  }

  Widget _buildDetailsModal(QualityControlData control) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Détails du contrôle',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: _buildDetailedContent(control),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailedContent(QualityControlData control) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Statut principal
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: QualityControlUtils.getConformityStatusColor(
                    control.conformityStatus)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: QualityControlUtils.getConformityStatusColor(
                      control.conformityStatus)
                  .withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                QualityControlUtils.getConformityStatusIcon(
                    control.conformityStatus),
                size: 32,
                color: QualityControlUtils.getConformityStatusColor(
                    control.conformityStatus),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      QualityControlUtils.getConformityStatusLabel(
                          control.conformityStatus),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: QualityControlUtils.getConformityStatusColor(
                            control.conformityStatus),
                      ),
                    ),
                    if (control.nonConformityCause != null)
                      Text(
                        control.nonConformityCause!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Informations générales
        _buildDetailSection(
          'Informations Générales',
          Icons.info_outline,
          [
            _buildDetailRow('Code contenant', control.containerCode),
            _buildDetailRow('Date réception',
                DateFormat('dd/MM/yyyy à HH:mm').format(control.receptionDate)),
            _buildDetailRow('Producteur', control.producer),
            _buildDetailRow('Village du rucher', control.apiaryVillage),
            if (control.controllerName != null)
              _buildDetailRow('Contrôleur', control.controllerName!),
          ],
        ),

        const SizedBox(height: 16),

        // Détails de la collecte
        _buildDetailSection(
          'Détails de la Collecte',
          Icons.hive_outlined,
          [
            _buildDetailRow('Type de ruche', control.hiveType),
            _buildDetailRow('Nature du miel',
                QualityControlUtils.getHoneyNatureLabel(control.honeyNature)),
            _buildDetailRow('Prédominance florale', control.floralPredominance),
            if (control.collectionStartDate != null)
              _buildDetailRow(
                  'Début collecte',
                  DateFormat('dd/MM/yyyy')
                      .format(control.collectionStartDate!)),
            if (control.collectionEndDate != null)
              _buildDetailRow('Fin collecte',
                  DateFormat('dd/MM/yyyy').format(control.collectionEndDate!)),
          ],
        ),

        const SizedBox(height: 16),

        // Détails du contenant
        _buildDetailSection(
          'Contenant & Mesures',
          Icons.scale,
          [
            _buildDetailRow('Type contenant', control.containerType),
            _buildDetailRow('Numéro contenant', control.containerNumber),
            _buildDetailRow(
                'Poids total', '${control.totalWeight.toStringAsFixed(2)} kg'),
            _buildDetailRow('Poids du miel',
                '${control.honeyWeight.toStringAsFixed(2)} kg'),
            _buildDetailRow('Qualité', control.quality),
            if (control.waterContent != null)
              _buildDetailRow('Teneur en eau',
                  '${control.waterContent!.toStringAsFixed(1)}%'),
          ],
        ),

        if (control.observations != null) ...[
          const SizedBox(height: 16),
          _buildDetailSection(
            'Observations',
            Icons.notes,
            [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  control.observations!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDetailSection(
      String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
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
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
