import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../models/commercial_models.dart';
import '../services/commercial_service.dart';
import '../widgets/statistiques_widgets.dart';

/// 📊 ONGLET STATISTIQUES COMMERCIALES AVANCÉES
///
/// Interface analytique avec graphiques interactifs et métriques approfondies
/// Calculs en temps réel sur de longues périodes avec visualisations optimisées

class StatistiquesTab extends StatefulWidget {
  final CommercialService commercialService;

  const StatistiquesTab({
    super.key,
    required this.commercialService,
  });

  @override
  State<StatistiquesTab> createState() => _StatistiquesTabState();
}

class _StatistiquesTabState extends State<StatistiquesTab>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final Rx<StatistiquesCommerciales?> _statistiques =
      Rx<StatistiquesCommerciales?>(null);
  final RxBool _isLoading = true.obs;
  final RxString _errorMessage = ''.obs;

  // Périodes d'analyse
  final Rx<DateTime> _periodeDebut =
      DateTime.now().subtract(const Duration(days: 30)).obs;
  final Rx<DateTime> _periodeFin = DateTime.now().obs;
  final RxString _periodePredefinie = 'mois'.obs;

  @override
  void initState() {
    super.initState();
    try {
      _initializeControllers();
      _loadStatistiques();
    } catch (e) {
      debugPrint('❌ Erreur initialisation statistiques: $e');
      _errorMessage.value = 'Erreur d\'initialisation: $e';
      _isLoading.value = false;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    try {
      _tabController = TabController(length: 4, vsync: this);

      _fadeController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );

      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOutQuart),
      );

      // Écouter les changements de période de manière sécurisée
      try {
        ever(_periodeDebut, (_) => _loadStatistiques());
        ever(_periodeFin, (_) => _loadStatistiques());
      } catch (e) {
        debugPrint('⚠️ Erreur configuration listeners GetX: $e');
      }

      _fadeController.forward();
    } catch (e) {
      debugPrint('❌ Erreur initialisation contrôleurs: $e');
      rethrow;
    }
  }

  Future<void> _loadStatistiques({bool forceRefresh = false}) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      // TODO: Passer la période au service quand l'API supportera ces paramètres
      final stats = await widget.commercialService
          .calculerStatistiques(forceRefresh: forceRefresh);

      _statistiques.value = stats;
    } catch (e) {
      debugPrint('❌ [StatistiquesTab] Erreur chargement statistiques: $e');
      _errorMessage.value = 'Erreur de chargement des statistiques';
    } finally {
      _isLoading.value = false;
    }
  }

  void _updatePeriodePredefinie(String periode) {
    _periodePredefinie.value = periode;
    final maintenant = DateTime.now();

    switch (periode) {
      case 'semaine':
        _periodeDebut.value = maintenant.subtract(const Duration(days: 7));
        break;
      case 'mois':
        _periodeDebut.value = maintenant.subtract(const Duration(days: 30));
        break;
      case 'trimestre':
        _periodeDebut.value = maintenant.subtract(const Duration(days: 90));
        break;
      case 'semestre':
        _periodeDebut.value = maintenant.subtract(const Duration(days: 180));
        break;
      case 'annee':
        _periodeDebut.value = maintenant.subtract(const Duration(days: 365));
        break;
    }
    _periodeFin.value = maintenant;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        _buildHeader(context),
        _buildPeriodeSelector(context),
        Expanded(
          child: Obx(() => _isLoading.value
              ? _buildLoadingView(context)
              : _errorMessage.value.isNotEmpty
                  ? _buildErrorView(context)
                  : _buildStatistiquesContent(context)),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.analytics,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analyses Commerciales Avancées',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tableau de bord analytique et visualisations interactives',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Bouton de rafraîchissement
          Obx(() => IconButton(
                onPressed: _isLoading.value
                    ? null
                    : () => _loadStatistiques(forceRefresh: true),
                icon: _isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Actualiser les statistiques',
              )),
        ],
      ),
    );
  }

  Widget _buildPeriodeSelector(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
              Icon(Icons.date_range, color: Colors.purple.shade600, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Période d\'analyse',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),

              // Période actuelle
              Obx(() => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${DateFormat('dd/MM/yy').format(_periodeDebut.value)} - ${DateFormat('dd/MM/yy').format(_periodeFin.value)}',
                      style: TextStyle(
                        color: Colors.purple.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )),
            ],
          ),

          const SizedBox(height: 12),

          // Sélecteurs de période
          if (isMobile)
            _buildMobilePeriodeSelector()
          else
            _buildDesktopPeriodeSelector(),
        ],
      ),
    );
  }

  Widget _buildMobilePeriodeSelector() {
    return Column(
      children: [
        // Périodes prédéfinies
        Obx(() => SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildPeriodeChip('semaine', 'Cette semaine'),
                  _buildPeriodeChip('mois', 'Ce mois'),
                  _buildPeriodeChip('trimestre', 'Ce trimestre'),
                  _buildPeriodeChip('semestre', 'Ce semestre'),
                  _buildPeriodeChip('annee', 'Cette année'),
                ],
              ),
            )),

        const SizedBox(height: 12),

        // Sélection personnalisée
        Row(
          children: [
            Expanded(child: _buildDateSelector('Début', _periodeDebut)),
            const SizedBox(width: 12),
            Expanded(child: _buildDateSelector('Fin', _periodeFin)),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopPeriodeSelector() {
    return Row(
      children: [
        // Périodes prédéfinies
        Expanded(
          child: Obx(() => Wrap(
                spacing: 8,
                children: [
                  _buildPeriodeChip('semaine', 'Cette semaine'),
                  _buildPeriodeChip('mois', 'Ce mois'),
                  _buildPeriodeChip('trimestre', 'Ce trimestre'),
                  _buildPeriodeChip('semestre', 'Ce semestre'),
                  _buildPeriodeChip('annee', 'Cette année'),
                ],
              )),
        ),

        const SizedBox(width: 20),

        // Sélection personnalisée
        _buildDateSelector('Début', _periodeDebut),
        const SizedBox(width: 12),
        _buildDateSelector('Fin', _periodeFin),
      ],
    );
  }

  Widget _buildPeriodeChip(String value, String label) {
    return Obx(() => FilterChip(
          label: Text(label),
          selected: _periodePredefinie.value == value,
          onSelected: (selected) {
            if (selected) {
              _updatePeriodePredefinie(value);
            }
          },
          selectedColor: Colors.purple.shade100,
          checkmarkColor: Colors.purple.shade700,
          labelStyle: TextStyle(
            color: _periodePredefinie.value == value
                ? Colors.purple.shade700
                : Colors.grey.shade700,
            fontSize: 12,
          ),
        ));
  }

  Widget _buildDateSelector(String label, Rx<DateTime> dateObs) {
    return SizedBox(
      width: 120,
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: dateObs.value,
            firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
            lastDate: DateTime.now(),
            locale: const Locale('fr', 'FR'),
          );
          if (date != null) {
            dateObs.value = date;
            _periodePredefinie.value = 'personnalisee';
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
              Obx(() => Text(
                    DateFormat('dd/MM/yyyy').format(dateObs.value),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 4,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Calcul des statistiques...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analyse des données commerciales en cours',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage.value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _loadStatistiques(forceRefresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistiquesContent(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Column(
            children: [
              // Métriques principales
              _buildMetriquesPrincipales(context),

              // Onglets détaillés
              Expanded(child: _buildDetailedTabs(context)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetriquesPrincipales(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final stats = _statistiques.value;

    if (stats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: isMobile
          ? _buildMobileMetriques(stats)
          : _buildDesktopMetriques(stats),
    );
  }

  Widget _buildMobileMetriques(StatistiquesCommerciales stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetriqueCard(
                title: 'Lots Totaux',
                value: '${stats.nombreLots}',
                subtitle: 'lots analysés',
                icon: Icons.inventory,
                color: const Color(0xFF2196F3),
                compact: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MetriqueCard(
                title: 'Attributions',
                value: '${stats.nombreAttributions}',
                subtitle: 'au total',
                icon: Icons.assignment,
                color: const Color(0xFF4CAF50),
                compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: MetriqueCard(
                title: 'Taux Attribution',
                value: '${stats.tauxAttribution.toStringAsFixed(1)}%',
                subtitle: 'du stock',
                icon: Icons.pie_chart,
                color: const Color(0xFF9C27B0),
                compact: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MetriqueCard(
                title: 'Valeur Stock',
                value:
                    '${(stats.valeurTotaleStock / 1000000).toStringAsFixed(1)}M',
                subtitle: 'FCFA',
                icon: Icons.monetization_on,
                color: const Color(0xFFFF9800),
                compact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopMetriques(StatistiquesCommerciales stats) {
    return Row(
      children: [
        Expanded(
          child: MetriqueCard(
            title: 'Lots Analysés',
            value: '${stats.nombreLots}',
            subtitle: 'dans la période sélectionnée',
            icon: Icons.inventory,
            color: const Color(0xFF2196F3),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: MetriqueCard(
            title: 'Total Attributions',
            value: '${stats.nombreAttributions}',
            subtitle: 'réalisées',
            icon: Icons.assignment,
            color: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: MetriqueCard(
            title: 'Taux d\'Attribution',
            value: '${stats.tauxAttribution.toStringAsFixed(1)}%',
            subtitle: 'du stock total',
            icon: Icons.pie_chart,
            color: const Color(0xFF9C27B0),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: MetriqueCard(
            title: 'Valeur du Stock',
            value: CommercialUtils.formatPrix(stats.valeurTotaleStock),
            subtitle: 'valeur totale analysée',
            icon: Icons.monetization_on,
            color: const Color(0xFFFF9800),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedTabs(BuildContext context) {
    final stats = _statistiques.value;
    if (stats == null) return const SizedBox.shrink();

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.purple.shade700,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: Colors.purple.shade700,
            tabs: const [
              Tab(
                icon: Icon(Icons.person),
                text: 'Commerciaux',
              ),
              Tab(
                icon: Icon(Icons.location_on),
                text: 'Sites',
              ),
              Tab(
                icon: Icon(Icons.category),
                text: 'Produits',
              ),
              Tab(
                icon: Icon(Icons.show_chart),
                text: 'Tendances',
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Onglet Commerciaux
              PerformancesCommerciaux(
                performancesCommerciaux: stats.performancesCommerciaux,
              ),

              // Onglet Sites
              RepartitionSites(
                repartitionSites: stats.repartitionSites,
              ),

              // Onglet Produits
              RepartitionProduits(
                repartitionEmballages: stats.repartitionEmballages,
                repartitionFlorale: stats.repartitionFlorale,
              ),

              // Onglet Tendances
              TendancesMensuelles(
                tendances: stats.tendancesMensuelles,
                periodeDebut: stats.periodeDebut,
                periodeFin: stats.periodeFin,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
