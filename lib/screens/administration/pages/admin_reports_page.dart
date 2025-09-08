import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/smart_appbar.dart';
import '../services/admin_reports_service.dart';
import '../widgets/reports_dashboard_widgets.dart';
import '../widgets/reports_charts_widgets.dart';
import '../widgets/reports_export_widgets.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({Key? key}) : super(key: key);

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminReportsService _reportsService = Get.put(AdminReportsService());

  final RxBool _isLoading = false.obs;
  final RxString _selectedPeriod = 'month'.obs;
  final RxString _selectedSite = 'all'.obs;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadReportsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReportsData() async {
    _isLoading.value = true;
    try {
      await _reportsService.loadAllReports(
        startDate: _startDate,
        endDate: _endDate,
        site: _selectedSite.value,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les rapports: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _refreshData() async {
    await _loadReportsData();
  }

  void _updateDateRange(DateTime start, DateTime end) {
    setState(() {
      _startDate = start;
      _endDate = end;
    });
    _loadReportsData();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: SmartAppBar(
        title: "📊 Rapports Administrateur",
        onBackPressed: () => Get.back(),
        actions: [
          // Bouton refresh
          Obx(() => IconButton(
                icon: _isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onPressed: _isLoading.value ? null : _refreshData,
                tooltip: 'Actualiser',
              )),

          // Bouton export
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _showExportOptions,
            tooltip: 'Exporter',
          ),

          // Bouton paramètres période
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _showDateRangePicker,
            tooltip: 'Période',
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête avec statistiques générales et filtres
          _buildHeaderSection(isMobile, isTablet),

          // Onglets
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: const Color(0xFF2196F3),
              labelColor: const Color(0xFF2196F3),
              unselectedLabelColor: Colors.grey[600],
              tabs: [
                Tab(
                  icon: const Icon(Icons.dashboard, size: 20),
                  text: isMobile ? '' : 'Vue d\'ensemble',
                ),
                Tab(
                  icon: const Icon(Icons.local_florist, size: 20),
                  text: isMobile ? '' : 'Production',
                ),
                Tab(
                  icon: const Icon(Icons.shopping_cart, size: 20),
                  text: isMobile ? '' : 'Commercial',
                ),
                Tab(
                  icon: const Icon(Icons.analytics, size: 20),
                  text: isMobile ? '' : 'Performances',
                ),
                Tab(
                  icon: const Icon(Icons.pie_chart, size: 20),
                  text: isMobile ? '' : 'Finances',
                ),
              ],
            ),
          ),

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Vue d'ensemble
                _buildOverviewTab(isMobile, isTablet),

                // Production
                _buildProductionTab(isMobile, isTablet),

                // Commercial
                _buildCommercialTab(isMobile, isTablet),

                // Performances
                _buildPerformanceTab(isMobile, isTablet),

                // Finances
                _buildFinancesTab(isMobile, isTablet),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(bool isMobile, bool isTablet) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Column(
        children: [
          // Filtres de période et site
          Row(
            children: [
              // Sélecteur de période
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Obx(() => DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPeriod.value,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                                value: 'week', child: Text('Cette semaine')),
                            DropdownMenuItem(
                                value: 'month', child: Text('Ce mois')),
                            DropdownMenuItem(
                                value: 'quarter', child: Text('Ce trimestre')),
                            DropdownMenuItem(
                                value: 'year', child: Text('Cette année')),
                            DropdownMenuItem(
                                value: 'custom', child: Text('Personnalisé')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              _selectedPeriod.value = value;
                              _updatePeriod(value);
                            }
                          },
                        ),
                      )),
                ),
              ),

              const SizedBox(width: 16),

              // Sélecteur de site
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Obx(() => DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSite.value,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                                value: 'all', child: Text('Tous les sites')),
                            DropdownMenuItem(
                                value: 'Ouaga', child: Text('Ouagadougou')),
                            DropdownMenuItem(
                                value: 'Koudougou', child: Text('Koudougou')),
                            DropdownMenuItem(
                                value: 'Bobo', child: Text('Bobo-Dioulasso')),
                            DropdownMenuItem(
                                value: 'Mangodara', child: Text('Mangodara')),
                            DropdownMenuItem(
                                value: 'Bagre', child: Text('Bagré')),
                            DropdownMenuItem(value: 'Pô', child: Text('Pô')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              _selectedSite.value = value;
                              _loadReportsData();
                            }
                          },
                        ),
                      )),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Période affichée
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: Color(0xFF2196F3)),
                const SizedBox(width: 8),
                Text(
                  'Du ${_formatDate(_startDate)} au ${_formatDate(_endDate)}',
                  style: const TextStyle(
                    color: Color(0xFF2196F3),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(bool isMobile, bool isTablet) {
    return Obx(() => SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KPIs principaux
              ReportsDashboardKPIs(
                reportsService: _reportsService,
                isMobile: isMobile,
                isLoading: _isLoading.value,
              ),

              const SizedBox(height: 24),

              // Graphiques principaux - Layout responsive
              LayoutBuilder(
                builder: (context, constraints) {
                  // Utiliser une Row seulement si on a assez d'espace (minimum 1000px)
                  final useHorizontalLayout = constraints.maxWidth >= 1000;

                  if (useHorizontalLayout) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex:
                              3, // Plus d'espace pour le graphique de production
                          child: ReportsProductionChart(
                            reportsService: _reportsService,
                            isLoading: _isLoading.value,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2, // Moins d'espace pour le graphique de ventes
                          child: ReportsSalesChart(
                            reportsService: _reportsService,
                            isLoading: _isLoading.value,
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Layout vertical pour les écrans plus petits
                    return Column(
                      children: [
                        ReportsProductionChart(
                          reportsService: _reportsService,
                          isLoading: _isLoading.value,
                        ),
                        const SizedBox(height: 16),
                        ReportsSalesChart(
                          reportsService: _reportsService,
                          isLoading: _isLoading.value,
                        ),
                      ],
                    );
                  }
                },
              ),

              const SizedBox(height: 24),

              // Activité récente
              ReportsRecentActivity(
                reportsService: _reportsService,
                isMobile: isMobile,
                isLoading: _isLoading.value,
              ),
            ],
          ),
        ));
  }

  Widget _buildProductionTab(bool isMobile, bool isTablet) {
    return Obx(() => SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistiques de production
              ReportsProductionStats(
                reportsService: _reportsService,
                isMobile: isMobile,
                isLoading: _isLoading.value,
              ),

              const SizedBox(height: 24),

              // Graphiques de production
              ReportsProductionCharts(
                reportsService: _reportsService,
                isMobile: isMobile,
                isLoading: _isLoading.value,
              ),

              const SizedBox(height: 24),

              // Détails par site
              ReportsProductionBySite(
                reportsService: _reportsService,
                isMobile: isMobile,
                isLoading: _isLoading.value,
              ),
            ],
          ),
        ));
  }

  Widget _buildCommercialTab(bool isMobile, bool isTablet) {
    return Obx(() => SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Note sur les données de test
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '⚠️ Données commerciales de test - Module en développement',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Statistiques commerciales
              ReportsCommercialStats(
                reportsService: _reportsService,
                isMobile: isMobile,
                isLoading: _isLoading.value,
              ),

              const SizedBox(height: 24),

              // Graphiques commerciaux
              ReportsCommercialCharts(
                reportsService: _reportsService,
                isMobile: isMobile,
                isLoading: _isLoading.value,
              ),
            ],
          ),
        ));
  }

  Widget _buildPerformanceTab(bool isMobile, bool isTablet) {
    return Obx(() => SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indicateurs de performance
              ReportsPerformanceIndicators(
                reportsService: _reportsService,
                isMobile: isMobile,
                isLoading: _isLoading.value,
              ),

              const SizedBox(height: 24),

              // Comparaisons périodes
              ReportsPerformanceComparisons(
                reportsService: _reportsService,
                isMobile: isMobile,
                isLoading: _isLoading.value,
              ),

              const SizedBox(height: 24),

              // Objectifs vs Réalisations
              ReportsObjectivesTracking(
                reportsService: _reportsService,
                isMobile: isMobile,
                isLoading: _isLoading.value,
              ),
            ],
          ),
        ));
  }

  Widget _buildFinancesTab(bool isMobile, bool isTablet) {
    return Obx(() => SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Note sur les données de test
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '⚠️ Données financières de test - Module en développement',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Statistiques financières
              ReportsFinancialStats(
                reportsService: _reportsService,
                isMobile: isMobile,
                isLoading: _isLoading.value,
              ),

              const SizedBox(height: 24),

              // Graphiques financiers
              ReportsFinancialCharts(
                reportsService: _reportsService,
                isMobile: isMobile,
                isLoading: _isLoading.value,
              ),
            ],
          ),
        ));
  }

  void _updatePeriod(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'week':
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
        break;
      case 'month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case 'quarter':
        final quarterStart =
            DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
        _startDate = quarterStart;
        _endDate = now;
        break;
      case 'year':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = now;
        break;
      case 'custom':
        _showDateRangePicker();
        return;
    }
    _loadReportsData();
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF2196F3),
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _updateDateRange(picked.start, picked.end);
    }
  }

  void _showExportOptions() {
    Get.dialog(
      ReportsExportDialog(
        reportsService: _reportsService,
        startDate: _startDate,
        endDate: _endDate,
        selectedSite: _selectedSite.value,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
