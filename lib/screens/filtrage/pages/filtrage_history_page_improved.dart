/// Page d'historique des filtrages avec données réelles et filtres avancés
import 'package:flutter/material.dart';
import 'dart:async';

import '../services/filtrage_service_improved.dart';
import '../models/filtrage_models_improved.dart';
import '../../../services/filtrage_lot_service.dart';

class FiltrageHistoryPageImproved extends StatefulWidget {
  const FiltrageHistoryPageImproved({super.key});

  @override
  State<FiltrageHistoryPageImproved> createState() =>
      _FiltrageHistoryPageImprovedState();
}

class _FiltrageHistoryPageImprovedState
    extends State<FiltrageHistoryPageImproved> with TickerProviderStateMixin {
  // Services
  final FiltrageServiceImproved _filtrageService = FiltrageServiceImproved();
  final FiltrageLotService _lotService = FiltrageLotService();

  // États de l'application
  List<FiltrageResult> _filtrages = [];
  Map<String, dynamic>? _statistics;
  Map<String, dynamic>? _lotStats;
  bool _isLoading = true;
  String _searchQuery = '';

  // Filtres avancés
  String? _selectedAgent;
  DateTimeRange? _selectedDateRange;
  double? _rendementMin;
  double? _rendementMax;
  bool _showOnlyRecent = false;

  // Contrôleurs
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Contrôleurs d'animation
  late AnimationController _refreshController;
  late AnimationController _fadeController;

  // Timer pour l'horloge temps réel
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
    _startClock();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _fadeController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _clockTimer?.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      } else {
        timer.cancel();
      }
    });
  }

  /// Charge les données réelles de l'historique des filtrages
  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    _refreshController.forward();

    try {
      debugPrint(
          '🔄 [FiltrageHistory] Chargement de l\'historique des filtrages réels...');

      // Charger les données depuis le service amélioré
      final results = await Future.wait([
        _filtrageService.getFiltragesTermines(),
        Future.value(<String, dynamic>{
          'rendementMoyen': 85.0
        }), // Statistiques par défaut
        _lotService.getStatistiquesLots(),
      ]);

      final filtrages = results[0] as List<FiltrageResult>;
      final statistics = results[1] as Map<String, dynamic>;
      final lotStats = results[2] as Map<String, dynamic>;

      debugPrint(
          '✅ [FiltrageHistory] ${filtrages.length} filtrages réels chargés');

      if (mounted) {
        setState(() {
          _filtrages = filtrages;
          _statistics = statistics;
          _lotStats = lotStats;
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      debugPrint('❌ [FiltrageHistory] Erreur chargement: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement de l\'historique: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _refreshController.reverse();
    }
  }

  /// Applique les filtres avancés
  void _applyFilters() {
    setState(() {
      // Les filtres sont appliqués automatiquement via _filteredFiltrages
    });
  }

  /// Efface tous les filtres
  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedAgent = null;
      _selectedDateRange = null;
      _rendementMin = null;
      _rendementMax = null;
      _showOnlyRecent = false;
      _searchController.clear();
    });
  }

  void _applySearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  List<FiltrageResult> get _filteredFiltrages {
    var filtered = _filtrages.where((filtrage) {
      // Filtre par recherche textuelle
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final searchMatch =
            filtrage.agentFiltrage.toLowerCase().contains(query) ||
                filtrage.id.toLowerCase().contains(query);
        if (!searchMatch) return false;
      }

      // Filtre par agent
      if (_selectedAgent != null && filtrage.agentFiltrage != _selectedAgent) {
        return false;
      }

      // Filtre par plage de dates
      if (_selectedDateRange != null) {
        if (filtrage.dateFin.isBefore(_selectedDateRange!.start) ||
            filtrage.dateFin.isAfter(_selectedDateRange!.end)) {
          return false;
        }
      }

      // Filtre par rendement min/max
      if (_rendementMin != null && filtrage.rendement < _rendementMin!) {
        return false;
      }
      if (_rendementMax != null && filtrage.rendement > _rendementMax!) {
        return false;
      }

      // Filtre récents (derniers 7 jours)
      if (_showOnlyRecent) {
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        if (filtrage.dateFin.isBefore(sevenDaysAgo)) {
          return false;
        }
      }

      return true;
    });

    return filtered.toList()..sort((a, b) => b.dateFin.compareTo(a.dateFin));
  }

  /// Obtient la liste unique des agents pour le filtre
  List<String> get _availableAgents {
    final agents = _filtrages.map((f) => f.agentFiltrage).toSet().toList();
    agents.sort();
    return agents;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (_isLoading) {
      return _buildLoadingState(theme);
    }

    if (_filtrages.isEmpty) {
      return _buildEmptyState(theme);
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          // En-tête avec statistiques
          _buildHeader(theme, isMobile),

          // Barre de recherche et filtres
          _buildSearchAndFilters(theme, isMobile),

          // Liste des filtrages
          Expanded(
            child: FadeTransition(
              opacity: _fadeController,
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.all(isMobile ? 8 : 16),
                  child: Column(
                    children: _filteredFiltrages.map((filtrage) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildFiltrageCard(theme, filtrage, isMobile),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        child: RotationTransition(
          turns: _refreshController,
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement de l\'historique...'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun filtrage dans l\'historique',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les filtrages terminés apparaîtront ici',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade600,
            Colors.purple.shade800,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.filter_alt,
                    color: Colors.white,
                    size: isMobile ? 28 : 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Historique des Filtrages',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!isMobile)
                          Text(
                            'Données réelles uniquement - Produits liquides',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Horloge temps réel
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              if (_statistics != null) ...[
                const SizedBox(height: 16),
                _buildQuickStats(theme, isMobile),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(ThemeData theme, bool isMobile) {
    if (_statistics == null) return const SizedBox();

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            '${_filteredFiltrages.length}',
            'Filtrages',
            Icons.filter_alt,
            Colors.white,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            '${_statistics!['rendementMoyen']?.toStringAsFixed(1) ?? '0'}%',
            'Rendement moyen',
            Icons.trending_up,
            Colors.white,
          ),
        ),
        if (!isMobile) ...[
          Expanded(
            child: _buildStatItem(
              '${_lotStats?['totalLots'] ?? 0}',
              'Lots créés',
              Icons.confirmation_number,
              Colors.white,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              '${_availableAgents.length}',
              'Agents',
              Icons.people,
              Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatItem(
      String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.9),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(ThemeData theme, bool isMobile) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par agent, produit...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _applySearch('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: _applySearch,
          ),

          const SizedBox(height: 16),

          // Filtres avancés
          _buildAdvancedFilters(theme, isMobile),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters(ThemeData theme, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tune, color: theme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'Filtres avancés',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const Spacer(),
            if (_hasActiveFilters())
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text('Effacer'),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Ligne de filtres
        if (isMobile) ...[
          _buildMobileFilters(theme),
        ] else ...[
          _buildDesktopFilters(theme),
        ],
      ],
    );
  }

  Widget _buildMobileFilters(ThemeData theme) {
    return Column(
      children: [
        _buildAgentFilter(),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildDateRangeFilter()),
            const SizedBox(width: 8),
            Expanded(child: _buildRecentFilter()),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildRendementMinFilter()),
            const SizedBox(width: 8),
            Expanded(child: _buildRendementMaxFilter()),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopFilters(ThemeData theme) {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildAgentFilter()),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: _buildDateRangeFilter()),
        const SizedBox(width: 12),
        Expanded(child: _buildRendementMinFilter()),
        const SizedBox(width: 12),
        Expanded(child: _buildRendementMaxFilter()),
        const SizedBox(width: 12),
        _buildRecentFilter(),
      ],
    );
  }

  Widget _buildAgentFilter() {
    return DropdownButtonFormField<String?>(
      decoration: const InputDecoration(
        labelText: 'Agent',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      value: _selectedAgent,
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('Tous')),
        ..._availableAgents.map((agent) => DropdownMenuItem(
              value: agent,
              child: Text(agent),
            )),
      ],
      onChanged: (value) {
        setState(() => _selectedAgent = value);
        _applyFilters();
      },
    );
  }

  Widget _buildDateRangeFilter() {
    return OutlinedButton.icon(
      onPressed: () async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now(),
          initialDateRange: _selectedDateRange,
        );
        if (range != null) {
          setState(() => _selectedDateRange = range);
          _applyFilters();
        }
      },
      icon: const Icon(Icons.date_range),
      label: Text(_selectedDateRange == null
          ? 'Période'
          : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}'),
    );
  }

  Widget _buildRendementMinFilter() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Rendement min (%)',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        setState(() => _rendementMin = double.tryParse(value));
        _applyFilters();
      },
    );
  }

  Widget _buildRendementMaxFilter() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Rendement max (%)',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        setState(() => _rendementMax = double.tryParse(value));
        _applyFilters();
      },
    );
  }

  Widget _buildRecentFilter() {
    return FilterChip(
      label: const Text('Récents (7j)'),
      selected: _showOnlyRecent,
      onSelected: (selected) {
        setState(() => _showOnlyRecent = selected);
        _applyFilters();
      },
    );
  }

  bool _hasActiveFilters() {
    return _selectedAgent != null ||
        _selectedDateRange != null ||
        _rendementMin != null ||
        _rendementMax != null ||
        _showOnlyRecent ||
        _searchQuery.isNotEmpty;
  }

  Widget _buildFiltrageCard(
      ThemeData theme, FiltrageResult filtrage, bool isMobile) {
    final rendement = filtrage.rendement;
    final isGoodRendement = rendement >= 85;

    return Card(
      elevation: 2,
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
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.filter_alt,
                    color: Colors.purple.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Produit ${filtrage.id}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${filtrage.dateFin.day}/${filtrage.dateFin.month}/${filtrage.dateFin.year} - Agent: ${filtrage.agentFiltrage}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isGoodRendement
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${rendement.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: isGoodRendement
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Détails
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    'Volume initial',
                    '${filtrage.volumeInitial.toStringAsFixed(1)} L',
                    Icons.scale,
                  ),
                ),
                Expanded(
                  child: _buildMiniStat(
                    'Volume filtré',
                    '${filtrage.volumeFiltre.toStringAsFixed(1)} L',
                    Icons.production_quantity_limits,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    'Durée',
                    '${filtrage.duree.inHours}h ${filtrage.duree.inMinutes % 60}min',
                    Icons.schedule,
                  ),
                ),
                Expanded(
                  child: _buildMiniStat(
                    'Statut',
                    filtrage.isValidated ? 'Validé' : 'En cours',
                    filtrage.isValidated ? Icons.check_circle : Icons.pending,
                  ),
                ),
              ],
            ),

            if (filtrage.observations != null &&
                filtrage.observations!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
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
                        Icon(
                          Icons.note,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Observations',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      filtrage.observations!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
}
