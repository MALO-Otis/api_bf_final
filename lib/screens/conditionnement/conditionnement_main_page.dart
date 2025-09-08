/// 🧊 PAGE PRINCIPALE DU MODULE CONDITIONNEMENT
///
/// Hub central avec navigation vers tous les sous-modules

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/smart_appbar.dart';
import 'condionnement_home.dart';
import 'conditionnement_models.dart';
import 'services/conditionnement_service.dart';
import 'pages/stock_conditionne_page.dart';
import 'pages/lots_disponibles_page.dart';

class ConditionnementMainPage extends StatefulWidget {
  const ConditionnementMainPage({super.key});

  @override
  State<ConditionnementMainPage> createState() =>
      _ConditionnementMainPageState();
}

class _ConditionnementMainPageState extends State<ConditionnementMainPage>
    with TickerProviderStateMixin {
  final ConditionnementService _service = ConditionnementService();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Données de statistiques
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadStatistics();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    // Démarrer les animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await _service.getStatistiquesConditionnement();
      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: SmartAppBar(
        title: "🧊 Module Conditionnement",
        backgroundColor: const Color(0xFF2E7D32),
        onBackPressed: () => Get.offAllNamed('/dashboard'),
      ),
      body: _isLoading ? _buildLoadingView() : _buildMainContent(isMobile),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 6,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 24),
          Text(
            'Chargement du module...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isMobile) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec statistiques
                  _buildHeaderSection(isMobile),

                  const SizedBox(height: 32),

                  // Navigation vers les sous-modules
                  _buildSubModulesGrid(isMobile),

                  const SizedBox(height: 32),

                  // Activité récente
                  _buildRecentActivity(isMobile),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '🧊',
                  style: TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Module Conditionnement',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 20 : 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gestion complète du conditionnement des lots filtrés',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Statistiques en temps réel
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Lots disponibles',
                  _statistics['lotsDisponibles']?.toString() ?? '0',
                  Icons.inventory_2,
                  Colors.white,
                  isMobile,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: _buildStatCard(
                  'Conditionnés',
                  _statistics['lotsConditionnes']?.toString() ?? '0',
                  Icons.check_circle,
                  Colors.white,
                  isMobile,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: _buildStatCard(
                  'Valeur totale',
                  ConditionnementUtils.formatPrix(
                      _statistics['valeurTotaleConditionnee'] ?? 0),
                  Icons.attach_money,
                  Colors.white,
                  isMobile,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isMobile ? 20 : 24),
          SizedBox(height: isMobile ? 4 : 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: isMobile ? 12 : 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: TextStyle(
              color: color.withOpacity(0.9),
              fontSize: isMobile ? 8 : 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubModulesGrid(bool isMobile) {
    final subModules = [
      {
        'title': 'Nouveau Conditionnement',
        'subtitle': 'Démarrer un nouveau conditionnement',
        'icon': Icons.add_box,
        'color': const Color(0xFF4CAF50),
        'gradient': [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
        'action': () => _navigateToNouveauConditionnement(),
        'badge': null,
      },
      {
        'title': 'Lots Disponibles',
        'subtitle': 'Lots filtrés prêts pour conditionnement',
        'icon': Icons.inventory,
        'color': const Color(0xFF2196F3),
        'gradient': [const Color(0xFF2196F3), const Color(0xFF42A5F5)],
        'action': () => _navigateToLotsDisponibles(),
        'badge': _statistics['lotsDisponibles']?.toString(),
      },
      {
        'title': 'Stock Conditionné',
        'subtitle': 'Consulter le stock déjà conditionné',
        'icon': Icons.warehouse,
        'color': const Color(0xFF9C27B0),
        'gradient': [const Color(0xFF9C27B0), const Color(0xFFBA68C8)],
        'action': () => _navigateToStockConditionne(),
        'badge': _statistics['lotsConditionnes']?.toString(),
      },
      {
        'title': 'Rapports & Analytics',
        'subtitle': 'Statistiques et rapports détaillés',
        'icon': Icons.analytics,
        'color': const Color(0xFFFF9800),
        'gradient': [const Color(0xFFFF9800), const Color(0xFFFFB74D)],
        'action': () => _navigateToRapports(),
        'badge': null,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fonctionnalités',
          style: TextStyle(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 1 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isMobile ? 3.5 : 2.5,
          ),
          itemCount: subModules.length,
          itemBuilder: (context, index) {
            final module = subModules[index];
            return _buildSubModuleCard(module, isMobile, index);
          },
        ),
      ],
    );
  }

  Widget _buildSubModuleCard(
      Map<String, dynamic> module, bool isMobile, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0, end: 1),
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: animationValue,
          child: Card(
            elevation: 8,
            shadowColor: (module['color'] as Color).withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: InkWell(
              onTap: module['action'],
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: module['gradient'] as List<Color>,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              module['icon'] as IconData,
                              color: Colors.white,
                              size: isMobile ? 20 : 24,
                            ),
                          ),
                          const Spacer(),
                          if (module['badge'] != null && module['badge'] != '0')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Text(
                                module['badge'].toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        module['title'] as String,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        module['subtitle'] as String,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Accéder',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isMobile ? 12 : 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: isMobile ? 16 : 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activité récente',
          style: TextStyle(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              children: [
                _buildActivityItem(
                  'Nouveau lot conditionné',
                  'Lot 2024-001 - 45kg de miel mille fleurs',
                  '2 heures',
                  Icons.check_circle,
                  Colors.green,
                  isMobile,
                ),
                const Divider(),
                _buildActivityItem(
                  'Lot filtré disponible',
                  'Lot 2024-005 - 38kg prêt pour conditionnement',
                  '5 heures',
                  Icons.inventory,
                  Colors.blue,
                  isMobile,
                ),
                const Divider(),
                _buildActivityItem(
                  'Rapport généré',
                  'Rapport mensuel du conditionnement',
                  '1 jour',
                  Icons.analytics,
                  Colors.orange,
                  isMobile,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time,
      IconData icon, Color color, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: isMobile ? 16 : 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Il y a $time',
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _navigateToNouveauConditionnement() {
    Get.to(
      () => const ConditionnementHomePage(),
      transition: Transition.rightToLeftWithFade,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _navigateToLotsDisponibles() {
    Get.to(
      () => const LotsDisponiblesPage(),
      transition: Transition.rightToLeftWithFade,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _navigateToStockConditionne() {
    Get.to(
      () => const StockConditionnePage(),
      transition: Transition.rightToLeftWithFade,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _navigateToRapports() {
    // TODO: Créer la page de rapports
    Get.snackbar(
      'En développement',
      'La page Rapports & Analytics sera bientôt disponible',
      backgroundColor: Colors.orange.shade600,
      colorText: Colors.white,
      icon: const Icon(Icons.construction, color: Colors.white),
    );
  }
}
