import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'pages/mes_ventes_page.dart';
import 'pages/mes_pertes_page.dart';
import 'package:flutter/material.dart';
import '../../utils/smart_appbar.dart';
import 'package:flutter/foundation.dart';
import 'pages/mes_prelevements_page.dart';
import 'pages/mes_restitutions_page.dart';
import '../vente/models/vente_models.dart';
import '../vente/services/vente_service.dart';
import '../../authentication/user_session.dart';
import '../caisse/pages/espace_caissier_page.dart';
import '../vente/controllers/espace_commercial_controller.dart';

/// 🏪 ESPACE COMMERCIAL ULTRA-MODERNE
/// Dashboard principal pour les commerciaux avec navigation vers toutes les fonctionnalités
class CommercialDashboard extends StatefulWidget {
  const CommercialDashboard({super.key});

  @override
  State<CommercialDashboard> createState() => _CommercialDashboardState();
}

class _CommercialDashboardState extends State<CommercialDashboard>
    with TickerProviderStateMixin {
  final VenteService _service = VenteService();
  final UserSession _userSession = Get.find<UserSession>();

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Données du dashboard
  Map<String, dynamic> _stats = {
    'prelevements_actifs': 0,
    'ventes_mois': 0,
    'chiffre_affaires': 0.0,
    'restitutions_mois': 0,
    'pertes_mois': 0,
    'taux_conversion': 0.0,
  };

  List<Prelevement> _prelevementsRecents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // ⚡ IMPORTANT: Initialiser le controller central dès l'entrée dans l'espace commercial
    if (!Get.isRegistered<EspaceCommercialController>()) {
      Get.put(EspaceCommercialController(), permanent: true);
      debugPrint(
          '🔧 [CommercialDashboard] EspaceCommercialController initialisé');
    }

    _initializeAnimations();
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutQuart),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final commercialId = _userSession.email ?? 'Commercial_Inconnu';

      // Charger les prélèvements
      final prelevements =
          await _service.getPrelevementsCommercial(commercialId);

      // Calculer les statistiques
      final prelevementsActifs = prelevements
          .where((p) => p.statut == StatutPrelevement.enCours)
          .length;
      final valeurTotale =
          prelevements.fold(0.0, (sum, p) => sum + p.valeurTotale);

      setState(() {
        _prelevementsRecents = prelevements.take(3).toList();
        _stats = {
          'prelevements_actifs': prelevementsActifs,
          'ventes_mois': 24, // TODO: Calculer depuis les vraies données
          'chiffre_affaires':
              valeurTotale * 0.7, // Estimation basée sur les prélèvements
          'restitutions_mois': 2,
          'pertes_mois': 1,
          'taux_conversion': prelevementsActifs > 0 ? 85.5 : 0.0,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar(
        'Erreur',
        'Impossible de charger les données: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final commercialNom = _userSession.email?.split('@')[0] ?? 'Commercial';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: SmartAppBar(
        title: "🏪 Espace Commercial",
        backgroundColor: const Color(0xFF6366F1),
        onBackPressed: () => Get.back(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingView()
          : AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: _buildDashboardContent(commercialNom),
                );
              },
            ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF6366F1), Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chargement de votre espace commercial...',
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

  Widget _buildDashboardContent(String commercialNom) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isExtraSmall = constraints.maxWidth < 480;
        final isSmall = constraints.maxWidth < 768;
        final isMedium = constraints.maxWidth < 1024;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isExtraSmall
              ? 16
              : isSmall
                  ? 20
                  : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header de bienvenue
              _buildWelcomeHeader(commercialNom, isExtraSmall, isSmall),
              SizedBox(height: isExtraSmall ? 24 : 32),

              // KPIs principaux
              _buildKPISection(isExtraSmall, isSmall, isMedium),
              SizedBox(height: isExtraSmall ? 24 : 32),

              // Navigation vers les pages principales
              _buildNavigationSection(isExtraSmall, isSmall, isMedium),
              SizedBox(height: isExtraSmall ? 24 : 32),

              // Activité récente
              _buildActivitySection(isExtraSmall, isSmall),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader(
      String commercialNom, bool isExtraSmall, bool isSmall) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: EdgeInsets.all(isExtraSmall ? 20 : 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1),
                  const Color(0xFF8B5CF6),
                  const Color(0xFFA855F7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '👋',
                    style: TextStyle(fontSize: isExtraSmall ? 32 : 40),
                  ),
                ),
                SizedBox(width: isExtraSmall ? 16 : 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour $commercialNom !',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isExtraSmall
                              ? 20
                              : isSmall
                                  ? 24
                                  : 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: isExtraSmall ? 4 : 8),
                      Text(
                        'Gérez vos ventes et prélèvements en toute simplicité',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isExtraSmall ? 14 : 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: isExtraSmall ? 8 : 12),
                      Text(
                        DateFormat('EEEE d MMMM yyyy', 'fr_FR')
                            .format(DateTime.now()),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: isExtraSmall ? 12 : 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKPISection(bool isExtraSmall, bool isSmall, bool isMedium) {
    final kpis = [
      {
        'title': 'Prélèvements Actifs',
        'value': '${_stats['prelevements_actifs']}',
        'subtitle': 'En cours de vente',
        'icon': Icons.shopping_bag,
        'color': const Color(0xFF10B981),
        'trend': '+2 cette semaine',
      },
      {
        'title': 'Ventes ce mois',
        'value': '${_stats['ventes_mois']}',
        'subtitle': 'Transactions',
        'icon': Icons.point_of_sale,
        'color': const Color(0xFF3B82F6),
        'trend': '+15% vs mois dernier',
      },
      {
        'title': 'Chiffre d\'Affaires',
        'value':
            '${(_stats['chiffre_affaires'] / 1000000).toStringAsFixed(1)}M',
        'subtitle': 'FCFA ce mois',
        'icon': Icons.trending_up,
        'color': const Color(0xFFF59E0B),
        'trend': '+8.5%',
      },
      {
        'title': 'Taux de Conversion',
        'value': '${_stats['taux_conversion'].toStringAsFixed(1)}%',
        'subtitle': 'Performance',
        'icon': Icons.analytics,
        'color': const Color(0xFF8B5CF6),
        'trend': 'Excellent',
      },
    ];

    if (isExtraSmall) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildKPICard(kpis[0], true)),
              const SizedBox(width: 12),
              Expanded(child: _buildKPICard(kpis[1], true)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildKPICard(kpis[2], true)),
              const SizedBox(width: 12),
              Expanded(child: _buildKPICard(kpis[3], true)),
            ],
          ),
        ],
      );
    } else {
      return Row(
        children: kpis.asMap().entries.map((entry) {
          final index = entry.key;
          final kpi = entry.value;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < kpis.length - 1 ? 16 : 0),
              child: _buildKPICard(kpi, false),
            ),
          );
        }).toList(),
      );
    }
  }

  Widget _buildKPICard(Map<String, dynamic> kpi, bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: (kpi['color'] as Color).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 8 : 12),
                decoration: BoxDecoration(
                  color: (kpi['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  kpi['icon'] as IconData,
                  color: kpi['color'] as Color,
                  size: isCompact ? 20 : 24,
                ),
              ),
              if (!isCompact) const Spacer(),
              if (!isCompact)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    kpi['trend'] as String,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: isCompact ? 12 : 16),
          Text(
            kpi['value'] as String,
            style: TextStyle(
              fontSize: isCompact ? 20 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            kpi['title'] as String,
            style: TextStyle(
              fontSize: isCompact ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            kpi['subtitle'] as String,
            style: TextStyle(
              fontSize: isCompact ? 10 : 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationSection(
      bool isExtraSmall, bool isSmall, bool isMedium) {
    final actions = [
      {
        'title': 'Mes Prélèvements',
        'subtitle': 'Produits attribués pour la vente',
        'icon': Icons.shopping_bag,
        'color': const Color(0xFF10B981),
        'gradient': [const Color(0xFF10B981), const Color(0xFF059669)],
        'onTap': () => Get.to(() => const MesPrelevementsPage()),
      },
      {
        'title': 'Mes Ventes',
        'subtitle': 'Enregistrer et suivre les ventes',
        'icon': Icons.point_of_sale,
        'color': const Color(0xFF3B82F6),
        'gradient': [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
        'onTap': () => Get.to(() => const MesVentesPage()),
      },
      {
        'title': 'Mes Restitutions',
        'subtitle': 'Retourner des produits non vendus',
        'icon': Icons.undo,
        'color': const Color(0xFFF59E0B),
        'gradient': [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        'onTap': () => Get.to(() => const MesRestitutionsPage()),
      },
      {
        'title': 'Déclarer des Pertes',
        'subtitle': 'Signaler des produits perdus/abîmés',
        'icon': Icons.warning,
        'color': const Color(0xFFEF4444),
        'gradient': [const Color(0xFFEF4444), const Color(0xFFDC2626)],
        'onTap': () => Get.to(() => const MesPertesPage()),
      },
      {
        'title': 'Espace Caissier',
        'subtitle': 'Synthèse & finances',
        'icon': Icons.account_balance,
        'color': const Color(0xFF0EA5E9),
        'gradient': [const Color(0xFF0EA5E9), const Color(0xFF0369A1)],
        'onTap': () => Get.to(() => const EspaceCaissierPage()),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🚀 Actions Principales',
          style: TextStyle(
            fontSize: isExtraSmall ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: isExtraSmall ? 16 : 20),
        if (isExtraSmall || isSmall)
          Column(
            children: actions
                .map((action) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: _buildActionCard(action, true),
                    ))
                .toList(),
          )
        else
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMedium ? 2 : 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isMedium ? 1.2 : 1.0,
            children: actions
                .map((action) => _buildActionCard(action, false))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action, bool isHorizontal) {
    return GestureDetector(
      onTap: action['onTap'] as VoidCallback,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: action['gradient'] as List<Color>,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (action['color'] as Color).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: isHorizontal
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      action['icon'] as IconData,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action['title'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          action['subtitle'] as String,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      action['icon'] as IconData,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    action['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action['subtitle'] as String,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildActivitySection(bool isExtraSmall, bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📋 Activité Récente',
          style: TextStyle(
            fontSize: isExtraSmall ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: isExtraSmall ? 16 : 20),
        if (_prelevementsRecents.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune activité récente',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vos prélèvements et activités apparaîtront ici',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: _prelevementsRecents.asMap().entries.map((entry) {
                final index = entry.key;
                final prelevement = entry.value;
                final isLast = index == _prelevementsRecents.length - 1;

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.shopping_bag,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prélèvement ${prelevement.id.split('_').last}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${prelevement.produits.length} produits • ${VenteUtils.formatPrix(prelevement.valeurTotale)}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM').format(prelevement.datePrelevement),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
