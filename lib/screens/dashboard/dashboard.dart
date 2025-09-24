import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apisavana_gestion/authentication/login.dart';
import 'package:apisavana_gestion/authentication/sign_up.dart';
import 'package:apisavana_gestion/services/user_role_service.dart';
import 'package:apisavana_gestion/authentication/user_session.dart';
import 'package:apisavana_gestion/screens/vente/vente_main_page.dart';
import 'package:apisavana_gestion/screens/filtrage/filtrage_main_page.dart';
import 'package:apisavana_gestion/screens/caisse/pages/espace_caissier_page.dart';
import 'package:apisavana_gestion/screens/dashboard/pages/notifications_page.dart';
import 'package:apisavana_gestion/screens/administration/pages/settings_page.dart';
import 'package:apisavana_gestion/screens/conditionnement/condionnement_home.dart';
import 'package:apisavana_gestion/screens/caisse/controllers/caisse_controller.dart';
import 'package:apisavana_gestion/screens/extraction/pages/main_extraction_page.dart';
import 'package:apisavana_gestion/screens/administration/pages/admin_reports_page.dart';
import 'package:apisavana_gestion/screens/collecte_de_donnes/historiques_collectes.dart';
import 'package:apisavana_gestion/screens/administration/pages/user_management_page.dart';
import 'package:apisavana_gestion/screens/conditionnement/conditionnement_main_page.dart';
import 'package:apisavana_gestion/screens/dashboard/controllers/chart_data_controller.dart';
import 'package:apisavana_gestion/screens/conditionnement/pages/stock_conditionne_page.dart';
import 'package:apisavana_gestion/screens/controle_de_donnes/controle_de_donnes_advanced.dart';
import 'package:apisavana_gestion/screens/controle_de_donnes/historique_attribution_page.dart';
import 'package:apisavana_gestion/screens/vente/controllers/espace_commercial_controller.dart';
import 'package:apisavana_gestion/screens/collecte_de_donnes/nouvelle_collecte_individuelle.dart';
import 'package:apisavana_gestion/screens/collecte_de_donnes/nos_collecte_recoltes/nouvelle_collecte_recolte.dart';
import 'package:apisavana_gestion/screens/collecte_de_donnes/nos_collecte_mielleurie/nouvelle_collecte_miellerie.dart';
import 'package:apisavana_gestion/screens/collecte_de_donnes/nos_achats_scoop_contenants/nouvel_achat_scoop_contenants.dart';
// import 'package:apisavana_gestion/screens/collecte_de_donnes/collecte_donnes.dart'; // ANCIEN CODE - DÉSACTIVÉ

// Color palette
const Color kHighlightColor = Color(0xFFF49101);
const Color kValidationColor = Color(0xFF2D0C0D);

// Controller pour la navigation du dashboard
class DashboardController extends GetxController {
  final Rx<Widget?> currentPage = Rx<Widget?>(null);
  final RxBool isSliderOpen = false.obs;

  void navigateTo(String moduleName, {String? subModule}) {
    // DEBUG: Afficher les valeurs reçues
    print(
        '🔍 navigateTo appelé avec: moduleName="$moduleName", subModule="$subModule"');

    // Navigation spéciale pour retour au dashboard
    if (moduleName == 'DASHBOARD') {
      isSliderOpen.value = false;
      currentPage.value = null; // Retourne au dashboard principal
      return;
    }

    // Ne ferme le menu que si on ouvre une vraie page (sous-module)
    if (subModule != null) {
      isSliderOpen.value = false;

      if (moduleName == 'COLLECTE' && subModule == 'Nouvelle collecte') {
        currentPage.value = NouvelleCollecteRecoltePage();
        return;
      }
      if (moduleName == 'COLLECTE' && subModule == 'Historique collectes') {
        currentPage.value = HistoriquesCollectesPage();
        return;
      }
      if (moduleName == 'COLLECTE' && subModule == 'Achats Individuels') {
        currentPage.value = const NouvelleCollecteIndividuellePage();
        return;
      }

      if (moduleName == 'COLLECTE' && subModule == 'Achat Scoop') {
        currentPage.value = const NouvelAchatScoopContenantsPage();
        return;
      }
      if (moduleName == 'COLLECTE' && subModule == 'Collecte Mielleries') {
        currentPage.value = const NouvelleCollecteMielleriePage();
        return;
      }

      // NOUVEAU : Module de contrôle avancé
      if (moduleName == 'CONTRÔLE' && subModule == 'Contrôle avancé') {
        print('✅ Navigation vers Contrôle avancé');
        currentPage.value = const ControlePageDashboard();
        return;
      }
      if (moduleName == 'CONTRÔLE' && subModule == 'Historique contrôles') {
        print('✅ Navigation vers Historique des Contrôles');
        currentPage.value = const HistoriqueAttributionPage();
        return;
      }
      if (moduleName == 'CONTRÔLE' &&
          (subModule == 'Contrôle a gerer' ||
              subModule == 'Contrôles en attente')) {
        print('✅ Navigation vers ${subModule} -> ControlePageDashboard');
        currentPage.value = const ControlePageDashboard();
        return;
      }

      // NOUVEAU : Module d'extraction
      if (moduleName == 'EXTRACTION' && subModule == 'Extraction de données') {
        print('✅ Navigation vers Extraction de données');
        currentPage.value = const MainExtractionPage();
        return;
      }
      if (moduleName == 'EXTRACTION' &&
          (subModule == 'Extractions en cours' ||
              subModule == 'Nouvelle extraction' ||
              subModule == 'Historique extractions' ||
              subModule == 'Rapports qualité')) {
        print('✅ Navigation vers ${subModule} -> MainExtractionPage');
        // Ouvrir directement l'onglet Historique si demandé
        final initialTab = subModule == 'Historique extractions' ? 1 : 0;
        currentPage.value = MainExtractionPage(initialTabIndex: initialTab);
        return;
      }

      // NOUVEAU : Module de filtrage moderne
      if (moduleName == 'FILTRAGE' &&
          (subModule == 'Nouveau filtrage' ||
              subModule == 'En cours de filtrage' ||
              subModule == 'Filtrage terminé' ||
              subModule == 'Historique filtrage')) {
        print('✅ Navigation vers ${subModule} -> FiltrageMainPage');
        final initialTab = subModule == 'Historique filtrage' ? 1 : 0;
        currentPage.value = FiltrageMainPage(initialTabIndex: initialTab);
        return;
      }

      // NOUVEAU : Module de conditionnement avec navigation spécifique
      if (moduleName == 'CONDITIONNEMENT') {
        if (subModule == 'Nouveau conditionnement') {
          print('✅ Navigation vers Nouveau conditionnement');
          currentPage.value = const ConditionnementMainPage();
          return;
        }
        if (subModule == 'Lots disponibles') {
          print('✅ Navigation vers Lots disponibles');
          currentPage.value = const ConditionnementHomePage();
          return;
        }
        if (subModule == 'Stock conditionné') {
          print('✅ Navigation vers Stock conditionné');
          currentPage.value = const StockConditionnePage();
          return;
        }
      }

      // NOUVEAU : Module de gestion de ventes avec navigation spécifique
      if (moduleName == 'GESTION DE VENTES') {
        print('✅ Navigation vers GESTION DE VENTES');
        currentPage.value = const VenteMainPage();
        return;
      }

      // NOUVEAU : Module CAISSE (accès rapide au dashboard caissier)
      if (moduleName == 'CAISSE') {
        // Deux sous-modules proposés pointent pour l'instant vers la même page synthèse
        // Possibilité future: différencier Analyse Paiements avec un paramètre / onglet
        // subModule est non-null dans ce bloc général mais on garde une sécurité simple
        final libelle = subModule.isEmpty ? 'Synthèse' : subModule;
        print('✅ Navigation vers CAISSE -> $libelle');
        currentPage.value = const EspaceCaissierPage();
        return;
      }

      // NOUVEAU : Module ADMINISTRATION (Admin seulement)
      if (moduleName == 'ADMINISTRATION') {
        if (subModule == 'Créer un compte') {
          print('✅ Navigation vers Créer un compte');
          currentPage.value = const SignupPage();
          return;
        } else if (subModule == 'Gestion Utilisateurs') {
          print('✅ Navigation vers Gestion Utilisateurs');
          currentPage.value = const UserManagementPage();
          return;
        } else if (subModule == 'Paramètres Système') {
          print('✅ Navigation vers Paramètres Système');
          currentPage.value = const SettingsPage();
          return;
        } else if (subModule == 'Rapports Admin') {
          print('✅ Navigation vers Rapports Admin');
          currentPage.value = const AdminReportsPage();
          return;
        }
      }

      switch (moduleName) {
        case 'COLLECTE':
          currentPage.value = NouvelleCollecteRecoltePage();
          break;
        case 'CONTRÔLE':
          print('✅ Navigation par défaut vers CONTRÔLE');
          currentPage.value =
              const ControlePageDashboard(); // Nouvelle page de contrôle avancé
          break;
        case 'EXTRACTION':
          print('✅ Navigation par défaut vers EXTRACTION');
          currentPage.value =
              const MainExtractionPage(); // Nouvelle page d'extraction
          break;
        case 'FILTRAGE':
          print('✅ Navigation par défaut vers FILTRAGE');
          currentPage.value =
              const FiltrageMainPage(); // 🆕 NOUVELLE PAGE DE FILTRAGE MODERNE
          break;
        case 'CONDITIONNEMENT':
          print('✅ Navigation par défaut vers CONDITIONNEMENT');
          currentPage.value =
              const ConditionnementMainPage(); // 🆕 PAGE PRINCIPALE DU CONDITIONNEMENT
          break;
        case 'CAISSE':
          print('✅ Navigation par défaut vers CAISSE');
          currentPage.value = const EspaceCaissierPage();
          break;
        default:
          print('❌ Module non géré: $moduleName');
          currentPage.value = null;
      }
    }
    // Si on clique juste sur le module (pour déplier), ne rien faire
  }

  void toggleSlider() {
    isSliderOpen.value = !isSliderOpen.value;
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  late DashboardController _dashboardController;

  @override
  void initState() {
    super.initState();
    // Initialiser le controller
    _dashboardController = Get.put(DashboardController());

    // Initialiser le service de rôles
    Get.put(UserRoleService());

    // Ne pas utiliser MediaQuery ici !
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Affiche un SnackBar listant les modules accessibles
        WidgetsBinding.instance.addPostFrameCallback((_) {
          UserSession user;
          try {
            user = Get.find<UserSession>();
          } catch (_) {
            user = Get.put(UserSession());
          }
          // Récupère la liste des modules accessibles
          final modules = NavigationSlider(
            isOpen: false,
            onToggle: () {},
            isMobile: false,
            isTablet: false,
            isDesktop: false,
          ).filterModulesByUser(
            [
              {"name": "COLLECTE"},
              {"name": "CONTRÔLE"},
              {"name": "EXTRACTION"},
              {"name": "FILTRAGE"},
              {"name": "CONDITIONNEMENT"},
              {"name": "GESTION DE VENTES"},
            ],
            user,
          );
          final moduleNames = modules.map((m) => m["name"]).join(", ");
          final msg = modules.isEmpty
              ? "Aucun module accessible pour votre profil."
              : "Modules accessibles : $moduleNames";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              duration: Duration(seconds: 5),
            ),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(() {
          Widget navigationSlider = NavigationSlider(
            isOpen: isDesktop || _dashboardController.isSliderOpen.value,
            onToggle: _dashboardController.toggleSlider,
            isMobile: isMobile,
            isTablet: isTablet,
            isDesktop: isDesktop,
            onModuleSelected: (moduleName, {subModule}) => _dashboardController
                .navigateTo(moduleName, subModule: subModule),
          );

          Widget mainContent = _isLoading
              ? DashboardSkeleton(
                  isMobile: isMobile,
                  isTablet: isTablet,
                  isDesktop: isDesktop,
                )
              : (_dashboardController.currentPage.value ??
                  MainDashboardContent(
                    isMobile: isMobile,
                    isTablet: isTablet,
                    isDesktop: isDesktop,
                  ));

          return Stack(
            children: [
              Row(
                children: [
                  // Main Content
                  Expanded(
                    child: Column(
                      children: [
                        DashboardHeader(
                          onMenuToggle: _dashboardController.toggleSlider,
                          isMobile: isMobile,
                          isTablet: isTablet,
                        ),
                        Expanded(child: mainContent),
                      ],
                    ),
                  ),
                  // Desktop slider
                  if (isDesktop)
                    SizedBox(
                      width: 270,
                      child: navigationSlider,
                    ),
                ],
              ),
              // Voile sombre DERRIÈRE le sidebar (ordre important!)
              if (_dashboardController.isSliderOpen.value && !isDesktop)
                AnimatedOpacity(
                  opacity: _dashboardController.isSliderOpen.value ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 300),
                  child: GestureDetector(
                    onTap: _dashboardController.toggleSlider,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.4),
                      child: SizedBox.expand(),
                    ),
                  ),
                ),
              // Overlay for mobile/tablet avec animation améliorée - AU-DESSUS du voile
              if (!isDesktop)
                AnimatedPositioned(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: _dashboardController.isSliderOpen.value ? 0 : -270,
                  top: 0,
                  bottom: 0,
                  width: 270,
                  child: navigationSlider,
                ),
            ],
          );
        }),
      ),
    );
  }
}

// Header
class DashboardHeader extends StatefulWidget {
  final VoidCallback onMenuToggle;
  final bool isMobile, isTablet;

  const DashboardHeader(
      {required this.onMenuToggle,
      required this.isMobile,
      required this.isTablet,
      Key? key})
      : super(key: key);

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  bool _isRefreshing = false;

  /// Simule un processus de rafraîchissement
  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    // Simulation d'un processus de chargement
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isRefreshing = false;
    });

    // Afficher un message de confirmation
    Get.snackbar(
      'Actualisation',
      'Données mises à jour avec succès !',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
    );
  }

  /// Navigation vers la page des paramètres système
  void _navigateToSettings() {
    Get.to(
      () => const SettingsPage(),
      transition: Transition.rightToLeftWithFade,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
    final hourStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    return Material(
      elevation: 1,
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(
            horizontal: widget.isMobile ? 8 : 24,
            vertical: widget.isMobile ? 8 : 14),
        child: Row(
          children: [
            if (widget.isMobile || widget.isTablet)
              IconButton(
                icon: Icon(Icons.menu, color: kHighlightColor, size: 28),
                onPressed: widget.onMenuToggle,
              ),
            Image.asset(
              'assets/logo/logo.jpeg', // Correct path
              height: widget.isMobile ? 40 : 60,
              width: widget.isMobile ? 40 : 60,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      try {
                        final roleService = Get.find<UserRoleService>();
                        return Text(roleService.dashboardTitle,
                            style: TextStyle(
                              fontSize: widget.isMobile ? 15 : 21,
                              fontWeight: FontWeight.bold,
                              color: kHighlightColor,
                            ),
                            overflow: TextOverflow.ellipsis);
                      } catch (e) {
                        return Text("Dashboard Administrateur",
                            style: TextStyle(
                              fontSize: widget.isMobile ? 15 : 21,
                              fontWeight: FontWeight.bold,
                              color: kHighlightColor,
                            ),
                            overflow: TextOverflow.ellipsis);
                      }
                    },
                  ),
                  if (!widget.isMobile)
                    Builder(
                      builder: (context) {
                        try {
                          final roleService = Get.find<UserRoleService>();
                          return Text(roleService.dashboardSubtitle,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600]));
                        } catch (e) {
                          return Text("Plateforme de gestion Apisavana",
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600]));
                        }
                      },
                    ),
                ],
              ),
            ),
            if (!widget.isMobile && !widget.isTablet)
              // Seulement sur desktop pour éviter l'overflow
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      children: [
                        Text("Date",
                            style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text(dateStr,
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    SizedBox(width: 8),
                    Column(
                      children: [
                        Text("Heure",
                            style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text(hourStr,
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.green, size: 10),
                        SizedBox(width: 3),
                        Text("Actif",
                            style: TextStyle(
                                fontSize: 9,
                                color: Colors.green,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
            SizedBox(width: widget.isMobile ? 6 : 12),
            // Notifications bell with live unread count
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: (() {
                final session = Get.find<UserSession>();
                final site = session.site ?? '';
                Query<Map<String, dynamic>> q = FirebaseFirestore.instance
                    .collection('notifications_caisse')
                    .where('statut', isEqualTo: 'non_lue');
                if (site.isNotEmpty) {
                  q = q.where('site', isEqualTo: site);
                }
                return q.snapshots();
              })(),
              builder: (context, snap) {
                final unread = snap.hasData ? snap.data!.size : 0;
                return IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.notifications,
                        color: kHighlightColor,
                        size: widget.isMobile ? 18 : 22,
                      ),
                      if (unread > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: CircleAvatar(
                            backgroundColor: Colors.redAccent,
                            radius: 7,
                            child: Text(
                              unread > 99 ? '99+' : unread.toString(),
                              style: const TextStyle(
                                  fontSize: 9, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () {
                    Get.to(
                      () => const NotificationsPage(),
                      transition: Transition.rightToLeftWithFade,
                      duration: const Duration(milliseconds: 300),
                    );
                  },
                  tooltip: 'Notifications',
                );
              },
            ),
            if (!widget.isMobile) ...[
              IconButton(
                icon: _isRefreshing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.grey[700]!),
                        ),
                      )
                    : Icon(Icons.refresh, color: Colors.grey[700]),
                onPressed: _isRefreshing ? null : _handleRefresh,
                tooltip: 'Actualiser les données',
              ),
              IconButton(
                icon: Icon(Icons.settings, color: Colors.grey[700]),
                onPressed: _navigateToSettings,
                tooltip: 'Paramètres système',
              ),
            ],
            OutlinedButton.icon(
              icon: Icon(Icons.logout, color: Colors.red[400], size: 16),
              label: widget.isMobile
                  ? SizedBox.shrink()
                  : Text("Déconnexion",
                      style: TextStyle(color: Colors.red[400], fontSize: 12)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red[100]!),
                backgroundColor: Colors.red[50],
                padding: EdgeInsets.symmetric(
                    horizontal: widget.isMobile ? 5 : 12, vertical: 6),
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Get.deleteAll(force: true); // Nettoie tous les contrôleurs GetX
                Get.offAll(() => LoginPage());
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Main dashboard
class MainDashboardContent extends StatefulWidget {
  final bool isMobile, isTablet, isDesktop;
  const MainDashboardContent(
      {required this.isMobile,
      required this.isTablet,
      required this.isDesktop,
      Key? key})
      : super(key: key);

  @override
  State<MainDashboardContent> createState() => _MainDashboardContentState();
}

class _MainDashboardContentState extends State<MainDashboardContent> {
  int selectedChart = 0; // 0: Line, 1: Bar, 2: Pie, 3: Area
  // Pour la légende interactive
  List<bool> visibleSeries = [true, true]; // [ventes, collecte]
  int? touchedIndex; // Pour le hover/tap

  // Controllers pour données commerciales / caisse
  CaisseController? _caisseCtrl;
  late UserSession _userSession;
  final NumberFormat _money = NumberFormat('#,##0', 'fr_FR');
  late final ChartDataController _chartData;

  bool get _isWideScopeRole {
    final r = (_userSession.role ?? '').toLowerCase();
    return r == 'admin' ||
        r == 'caissier' ||
        r == 'caissière' ||
        r == 'gestionnaire commercial' ||
        r == 'magazinier';
  }

  String _fmtMoney(double v) => '${_money.format(v)} FCFA';

  Widget _kpiWrap(Widget child) {
    return Container(
      width: widget.isMobile ? 160 : 200,
      margin: EdgeInsets.only(right: 12),
      child: child,
    );
  }

  @override
  void initState() {
    super.initState();
    // Sécuriser l'accès à UserSession
    try {
      _userSession = Get.find<UserSession>();
    } catch (_) {
      _userSession = Get.put(UserSession());
    }
    // S'assurer que les contrôleurs sont disponibles
    // Primes ventes contrôleur pour data sources annexes (non obligatoire ici)
    try {
      if (!Get.isRegistered<EspaceCommercialController>()) {
        Get.put(EspaceCommercialController(), permanent: true);
      }
    } catch (_) {}
    try {
      _caisseCtrl = Get.isRegistered<CaisseController>()
          ? Get.find<CaisseController>()
          : Get.put(CaisseController(), permanent: true);
    } catch (_) {}

    // Chart data controller (agrégation ventes/collecte)
    _chartData = Get.isRegistered<ChartDataController>()
        ? Get.find<ChartDataController>()
        : Get.put(ChartDataController(), permanent: true);

    // Si l'utilisateur est un commercial (hors large scope), filtrer ses KPIs à son activité
    final role = (_userSession.role ?? '').toLowerCase();
    if (!_isWideScopeRole && role == 'commercial' && _caisseCtrl != null) {
      final email = _userSession.email ?? '';
      if (email.isNotEmpty) {
        // Filtrer KPIs pour le commercial courant
        _caisseCtrl!.setCommercial(email);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Unifier le dashboard: on garde la même page pour tous,
    // mais on adapte les KPIs selon le rôle (admin voit tout, autres voient leurs infos principales)
    final EdgeInsets sectionPad = EdgeInsets.symmetric(
        horizontal: widget.isMobile ? 6 : 22,
        vertical: widget.isMobile ? 8 : 18);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // KPIs
        Padding(
          padding: sectionPad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text("Vue d'ensemble",
                      style: TextStyle(
                          fontSize: widget.isMobile ? 15 : 19,
                          fontWeight: FontWeight.bold)),
                  Spacer(),
                  Icon(Icons.swipe_left,
                      size: widget.isMobile ? 16 : 18,
                      color: Colors.grey.shade600),
                  SizedBox(width: 4),
                  Text("Glissez pour voir plus",
                      style: TextStyle(
                          fontSize: widget.isMobile ? 11 : 13,
                          color: Colors.grey.shade600)),
                ],
              ),
              SizedBox(height: 12),
              Container(
                height: widget.isMobile ? 110 : 135,
                child: Obx(() {
                  // S'assurer que les contrôleurs existent
                  final caisse = _caisseCtrl;
                  final role = (_userSession.role ?? '').toLowerCase();
                  final isAdmin = role == 'admin';
                  // Si pas de contrôleur dispo, afficher placeholders légers
                  if (caisse == null) {
                    return ListView(
                      scrollDirection: Axis.horizontal,
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      children: [
                        _kpiWrap(
                          KPICard(
                            title: 'CA Net',
                            value: '--',
                            icon: Icons.payments,
                            color: Colors.indigo,
                            trend: 0,
                            isPositive: true,
                            isMobile: widget.isMobile,
                          ),
                        ),
                        _kpiWrap(
                          KPICard(
                            title: 'Crédits en attente',
                            value: '--',
                            icon: Icons.credit_card,
                            color: Colors.orange,
                            trend: 0,
                            isPositive: false,
                            isMobile: widget.isMobile,
                          ),
                        ),
                        _kpiWrap(
                          KPICard(
                            title: 'CA Espèce',
                            value: '--',
                            icon: Icons.attach_money,
                            color: Colors.green,
                            trend: 0,
                            isPositive: true,
                            isMobile: widget.isMobile,
                          ),
                        ),
                        _kpiWrap(
                          KPICard(
                            title: 'CA Mobile',
                            value: '--',
                            icon: Icons.phone_iphone,
                            color: Colors.blue,
                            trend: 0,
                            isPositive: true,
                            isMobile: widget.isMobile,
                          ),
                        ),
                      ],
                    );
                  }

                  // KPIs par rôle
                  final items = <Widget>[];
                  // Admin: vue générale agrégée
                  if (isAdmin) {
                    items.addAll([
                      _kpiWrap(KPICard(
                        title: 'CA Brut (site)',
                        value: _fmtMoney(caisse.caBrut.value),
                        icon: Icons.shopping_cart,
                        color: kHighlightColor,
                        trend: 0,
                        isPositive: true,
                        isMobile: widget.isMobile,
                      )),
                      _kpiWrap(KPICard(
                        title: 'CA Net (site)',
                        value: _fmtMoney(caisse.caNet.value),
                        icon: Icons.payments,
                        color: Colors.indigo,
                        trend: 0,
                        isPositive: true,
                        isMobile: widget.isMobile,
                      )),
                      _kpiWrap(KPICard(
                        title: 'Crédits en attente',
                        value: _fmtMoney(caisse.creditAttente.value),
                        icon: Icons.credit_card,
                        color: Colors.orange,
                        trend: 0,
                        isPositive: false,
                        isMobile: widget.isMobile,
                      )),
                      _kpiWrap(KPICard(
                        title: 'Crédits remboursés',
                        value: _fmtMoney(caisse.creditRembourse.value),
                        icon: Icons.verified,
                        color: Colors.teal,
                        trend: 0,
                        isPositive: true,
                        isMobile: widget.isMobile,
                      )),
                    ]);
                  } else {
                    // Caissier / Gestionnaire: focus dettes/transactions
                    if (_isWideScopeRole) {
                      items.addAll([
                        _kpiWrap(KPICard(
                          title: 'CA Net (site)',
                          value: _fmtMoney(caisse.caNet.value),
                          icon: Icons.payments,
                          color: Colors.indigo,
                          trend: 0,
                          isPositive: true,
                          isMobile: widget.isMobile,
                        )),
                        _kpiWrap(KPICard(
                          title: 'Crédits en attente',
                          value: _fmtMoney(caisse.creditAttente.value),
                          icon: Icons.report_gmailerrorred,
                          color: Colors.deepOrange,
                          trend: 0,
                          isPositive: false,
                          isMobile: widget.isMobile,
                        )),
                        _kpiWrap(KPICard(
                          title: 'Crédits remboursés',
                          value: _fmtMoney(caisse.creditRembourse.value),
                          icon: Icons.done_all,
                          color: Colors.teal,
                          trend: 0,
                          isPositive: true,
                          isMobile: widget.isMobile,
                        )),
                        _kpiWrap(KPICard(
                          title: 'Cash théorique',
                          value: _fmtMoney(caisse.cashTheorique.value),
                          icon: Icons.account_balance_wallet,
                          color: Colors.green,
                          trend: 0,
                          isPositive: true,
                          isMobile: widget.isMobile,
                        )),
                      ]);
                    } else {
                      // Commercial: ses propres chiffres
                      items.addAll([
                        _kpiWrap(KPICard(
                          title: 'Mes ventes (brut)',
                          value: _fmtMoney(caisse.caBrut.value),
                          icon: Icons.shopping_bag,
                          color: kHighlightColor,
                          trend: 0,
                          isPositive: true,
                          isMobile: widget.isMobile,
                        )),
                        _kpiWrap(KPICard(
                          title: 'Mes crédits en attente',
                          value: _fmtMoney(caisse.creditAttente.value),
                          icon: Icons.credit_card,
                          color: Colors.orange,
                          trend: 0,
                          isPositive: false,
                          isMobile: widget.isMobile,
                        )),
                        _kpiWrap(KPICard(
                          title: 'Ventes en espèces',
                          value: _fmtMoney(caisse.caEspece.value),
                          icon: Icons.attach_money,
                          color: Colors.green,
                          trend: 0,
                          isPositive: true,
                          isMobile: widget.isMobile,
                        )),
                        _kpiWrap(KPICard(
                          title: 'Ventes mobile money',
                          value: _fmtMoney(caisse.caMobile.value),
                          icon: Icons.phone_iphone,
                          color: Colors.blue,
                          trend: 0,
                          isPositive: true,
                          isMobile: widget.isMobile,
                        )),
                      ]);
                    }
                  }

                  return ListView(
                    scrollDirection: Axis.horizontal,
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    children: items,
                  );
                }),
              ),
            ],
          ),
        ),

        // Actions Rapides Admin (seulement pour les administrateurs)
        Builder(
          builder: (context) {
            try {
              final roleService = Get.find<UserRoleService>();
              if (roleService.currentRoleGroup == RoleGroup.admin) {
                return Padding(
                  padding: sectionPad,
                  child: _buildAdminQuickActionsSection(
                      widget.isMobile, widget.isTablet),
                );
              }
            } catch (e) {
              // Si le service n'est pas disponible, ne pas afficher la section
            }
            return const SizedBox.shrink();
          },
        ),

        // Chart
        Padding(
          padding: sectionPad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Analyse des données",
                  style: TextStyle(
                      fontSize: widget.isMobile ? 15 : 19,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 7),
              Container(
                height: widget.isMobile ? 45 : 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: BouncingScrollPhysics(),
                  children: [
                    ChartTypeButton(
                        label: "Ligne",
                        icon: Icons.show_chart,
                        selected: selectedChart == 0,
                        onTap: () => setState(() => selectedChart = 0)),
                    SizedBox(width: 8),
                    ChartTypeButton(
                        label: "Histogramme",
                        icon: Icons.bar_chart,
                        selected: selectedChart == 1,
                        onTap: () => setState(() => selectedChart = 1)),
                    SizedBox(width: 8),
                    ChartTypeButton(
                        label: "Cercle",
                        icon: Icons.pie_chart,
                        selected: selectedChart == 2,
                        onTap: () => setState(() => selectedChart = 2)),
                    SizedBox(width: 8),
                    ChartTypeButton(
                        label: "Aire",
                        icon: Icons.area_chart,
                        selected: selectedChart == 3,
                        onTap: () => setState(() => selectedChart = 3)),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Container(
                height: widget.isMobile ? 170 : 260,
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 2000), // transition 2s
                  child: Obx(() {
                    // Source des données
                    final months = _chartData.months;
                    final ventes = _chartData.ventesMonthly;
                    final collectes = _chartData.collecteMonthly;
                    final hasData = months.isNotEmpty;

                    if (selectedChart == 0) {
                      return LineChartSample(
                        isMobile: widget.isMobile,
                        visibleSeries: visibleSeries,
                        touchedIndex: touchedIndex,
                        onLegendTap: (i) => setState(() {
                          visibleSeries[i] = !visibleSeries[i];
                        }),
                        onTouch: (i) => setState(() => touchedIndex = i),
                        onTouchEnd: () => setState(() => touchedIndex = null),
                        dynamicMonths: hasData ? months.toList() : null,
                        dynamicVentes: hasData ? ventes.toList() : null,
                        dynamicCollecte: hasData ? collectes.toList() : null,
                      );
                    } else if (selectedChart == 1) {
                      return BarChartSample(
                        isMobile: widget.isMobile,
                        visibleSeries: visibleSeries,
                        touchedIndex: touchedIndex,
                        onLegendTap: (i) => setState(() {
                          visibleSeries[i] = !visibleSeries[i];
                        }),
                        onTouch: (i) => setState(() => touchedIndex = i),
                        onTouchEnd: () => setState(() => touchedIndex = null),
                        dynamicMonths: hasData ? months.toList() : null,
                        dynamicVentes: hasData ? ventes.toList() : null,
                        dynamicCollecte: hasData ? collectes.toList() : null,
                      );
                    } else if (selectedChart == 2) {
                      return PieChartSample(
                        touchedIndex: touchedIndex,
                        onTouch: (i) => setState(() => touchedIndex = i),
                        onTouchEnd: () => setState(() => touchedIndex = null),
                        dynamicSlices: _chartData.pieSlices
                            .map((s) => {
                                  'name': s.name,
                                  'value': s.value,
                                  'color': s.color,
                                })
                            .toList(),
                      );
                    } else {
                      return AreaChartSample(
                        isMobile: widget.isMobile,
                        visibleSeries: visibleSeries,
                        touchedIndex: touchedIndex,
                        onLegendTap: (i) => setState(() {
                          visibleSeries[i] = !visibleSeries[i];
                        }),
                        onTouch: (i) => setState(() => touchedIndex = i),
                        onTouchEnd: () => setState(() => touchedIndex = null),
                        dynamicMonths: hasData ? months.toList() : null,
                        dynamicVentes: hasData ? ventes.toList() : null,
                        dynamicCollecte: hasData ? collectes.toList() : null,
                      );
                    }
                  }),
                ),
              ),
              // Légende interactive (sauf Pie)
              if (selectedChart != 2)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => setState(
                            () => visibleSeries[0] = !visibleSeries[0]),
                        child: Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: visibleSeries[0]
                                    ? kHighlightColor
                                    : Colors.grey[300],
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: kHighlightColor, width: 2),
                              ),
                            ),
                            SizedBox(width: 5),
                            Text("Ventes",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: visibleSeries[0]
                                        ? Colors.black
                                        : Colors.grey)),
                          ],
                        ),
                      ),
                      SizedBox(width: 18),
                      GestureDetector(
                        onTap: () => setState(
                            () => visibleSeries[1] = !visibleSeries[1]),
                        child: Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: visibleSeries[1]
                                    ? Colors.green
                                    : Colors.grey[300],
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.green, width: 2),
                              ),
                            ),
                            SizedBox(width: 5),
                            Text("Collecte",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: visibleSeries[1]
                                        ? Colors.black
                                        : Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Alerts and Timeline
        Padding(
          padding: sectionPad,
          child: widget.isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: AlertsSection(isMobile: widget.isMobile)),
                    SizedBox(width: 18),
                    Expanded(
                        child: ActivityTimeline(isMobile: widget.isMobile)),
                  ],
                )
              : Column(
                  children: [
                    AlertsSection(isMobile: widget.isMobile),
                    SizedBox(height: 14),
                    ActivityTimeline(isMobile: widget.isMobile),
                  ],
                ),
        ),
        SizedBox(height: widget.isMobile ? 20 : 32),
      ],
    );
  }

  Widget _buildAdminQuickActionsSection(bool isMobile, bool isTablet) {
    final actions = [
      {
        'title': 'Créer un Compte',
        'subtitle': 'Ajouter un nouvel utilisateur',
        'icon': Icons.person_add,
        'color': const Color(0xFF2196F3),
        'onTap': () => _navigateToCreateAccount(),
      },
      {
        'title': 'Gestion Utilisateurs',
        'subtitle': 'Voir tous les utilisateurs',
        'icon': Icons.people,
        'color': const Color(0xFF4CAF50),
        'onTap': () => _navigateToUserManagement(),
      },
      {
        'title': 'Paramètres Système',
        'subtitle': 'Configuration générale',
        'icon': Icons.settings,
        'color': const Color(0xFFFF9800),
        'onTap': () => _navigateToSystemSettings(),
      },
      {
        'title': 'Rapports Admin',
        'subtitle': 'Statistiques globales',
        'icon': Icons.analytics,
        'color': const Color(0xFF9C27B0),
        'onTap': () => _navigateToAdminReports(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Actions Rapides Admin",
          style: TextStyle(
            fontSize: isMobile ? 15 : 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),

        // Version responsive adaptée selon la taille d'écran
        if (isMobile)
          // Mobile : Liste verticale pour éviter les overflow
          Column(
            children: actions
                .map(
                  (action) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAdminActionCard(action, isMobile),
                  ),
                )
                .toList(),
          )
        else
          // Tablet/Desktop : Grille responsive
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculer le nombre de colonnes selon la largeur disponible
              final double cardWidth = 280; // Largeur minimale d'une carte
              final int crossAxisCount =
                  (constraints.maxWidth / cardWidth).floor().clamp(1, 4);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.8, // Ratio ajusté pour éviter l'overflow
                ),
                itemCount: actions.length,
                itemBuilder: (context, index) {
                  return _buildAdminActionCard(actions[index], false);
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildAdminActionCard(Map<String, dynamic> action, bool isMobile) {
    return InkWell(
      onTap: action['onTap'],
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: isMobile ? 70 : 80,
        ),
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: (action['color'] as Color).withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icône avec taille fixe
            Container(
              width: isMobile ? 40 : 48,
              height: isMobile ? 40 : 48,
              decoration: BoxDecoration(
                color: (action['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                action['icon'],
                color: action['color'],
                size: isMobile ? 20 : 24,
              ),
            ),
            SizedBox(width: isMobile ? 10 : 12),

            // Texte avec gestion de l'overflow
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    action['title'],
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D0C0D),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isMobile ? 2 : 4),
                  Text(
                    action['subtitle'],
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 13,
                      color: Colors.grey[600],
                      height: 1.2,
                    ),
                    maxLines: isMobile ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Flèche avec taille fixe
            Container(
              width: 24,
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Navigation methods for admin actions
  void _navigateToCreateAccount() {
    Get.find<DashboardController>().currentPage.value = const SignupPage();
  }

  void _navigateToUserManagement() {
    Get.find<DashboardController>().currentPage.value =
        const UserManagementPage();
  }

  void _navigateToSystemSettings() {
    Get.find<DashboardController>().currentPage.value = const SettingsPage();
  }

  void _navigateToAdminReports() {
    Get.find<DashboardController>().currentPage.value =
        const AdminReportsPage();
  }
}

// Chart switcher button
class ChartTypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const ChartTypeButton(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 7),
      child: OutlinedButton.icon(
        icon: Icon(icon,
            size: 15, color: selected ? Colors.white : kHighlightColor),
        label: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white : kHighlightColor)),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? kHighlightColor : Colors.white,
          side: BorderSide(color: kHighlightColor),
          minimumSize: Size(0, 28),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onTap,
      ),
    );
  }
}

// KPI Card
class KPICard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  final int trend;
  final bool isPositive;
  final bool isMobile;
  const KPICard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    required this.isPositive,
    required this.isMobile,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: isMobile ? 135 : 180,
        height: isMobile ? 100 : 190,
        padding: EdgeInsets.all(isMobile ? 10 : 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.08), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: isMobile ? 18 : 24),
            SizedBox(height: isMobile ? 3 : 6),
            Flexible(
              child: Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: isMobile ? 10 : 12,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500)),
            ),
            SizedBox(height: isMobile ? 2 : 5),
            Flexible(
              child: Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: isMobile ? 13 : 18,
                      fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 1),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isPositive ? Colors.green : Colors.red,
                      size: isMobile ? 13 : 15),
                  SizedBox(width: 2),
                  Flexible(
                    child: Text('${trend.abs()}% ',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: isPositive ? Colors.green : Colors.red,
                            fontSize: isMobile ? 9 : 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Text('vs. mois dernier',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: isMobile ? 9 : 11)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- CHARTS (fl_chart) ---

class LineChartSample extends StatefulWidget {
  final bool isMobile;
  final List<bool> visibleSeries;
  final int? touchedIndex;
  final void Function(int)? onLegendTap;
  final void Function(int)? onTouch;
  final VoidCallback? onTouchEnd;
  // Dynamic data (optional). When provided, replaces placeholder arrays
  final List<String>? dynamicMonths;
  final List<double>? dynamicVentes;
  final List<double>? dynamicCollecte;
  const LineChartSample({
    this.isMobile = false,
    required this.visibleSeries,
    this.touchedIndex,
    this.onLegendTap,
    this.onTouch,
    this.onTouchEnd,
    this.dynamicMonths,
    this.dynamicVentes,
    this.dynamicCollecte,
    super.key,
  });

  @override
  State<LineChartSample> createState() => _LineChartSampleState();
}

class _LineChartSampleState extends State<LineChartSample> {
  Map<String, bool> visibleSeries = {
    'ventes': true,
    'collecte': true,
  };
  FlSpot? selectedSpot;
  String? selectedSeries;
  int? touchedIndex;

  final List<FlSpot> ventes = [
    FlSpot(0, 4000),
    FlSpot(1, 3000),
    FlSpot(2, 2000),
    FlSpot(3, 2780),
    FlSpot(4, 1890),
    FlSpot(5, 2390),
    FlSpot(6, 3490),
  ];
  final List<FlSpot> collecte = [
    FlSpot(0, 2400),
    FlSpot(1, 1398),
    FlSpot(2, 9800),
    FlSpot(3, 3908),
    FlSpot(4, 4800),
    FlSpot(5, 3800),
    FlSpot(6, 4300),
  ];
  final List<String> months = [
    'Jan',
    'Fév',
    'Mar',
    'Avr',
    'Mai',
    'Juin',
    'Juil'
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = widget.isMobile;
    return Column(
      children: [
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                  show: true,
                  horizontalInterval: 5000,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.grey[300], strokeWidth: 1)),
              borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey[300]!, width: 1)),
              // Correction: FlTitlesData expects 'topTitles', 'rightTitles', 'bottomTitles', 'leftTitles'
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5000,
                        reservedSize: isMobile ? 22 : 30)),
                bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (val, _) => Padding(
                              padding: const EdgeInsets.only(top: 3.0),
                              child: Text(
                                  (widget.dynamicMonths ?? months)[val.toInt() %
                                      (widget.dynamicMonths?.length ??
                                          months.length)],
                                  style:
                                      TextStyle(fontSize: isMobile ? 9 : 13)),
                            ))),
              ),
              minY: 0,
              maxY: 10000,
              lineBarsData: [
                if (visibleSeries['ventes']!)
                  LineChartBarData(
                    spots: (widget.dynamicVentes != null)
                        ? List.generate(
                            widget.dynamicVentes!.length,
                            (i) => FlSpot(i.toDouble(),
                                widget.dynamicVentes![i].toDouble()))
                        : ventes,
                    isCurved: true,
                    color: kHighlightColor,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                if (visibleSeries['collecte']!)
                  LineChartBarData(
                    spots: (widget.dynamicCollecte != null)
                        ? List.generate(
                            widget.dynamicCollecte!.length,
                            (i) => FlSpot(i.toDouble(),
                                widget.dynamicCollecte![i].toDouble()))
                        : collecte,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 2,
                    dotData: FlDotData(show: true),
                  ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipRoundedRadius: 10,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((touched) {
                      final series =
                          touched.barIndex == 0 ? 'Ventes' : 'Collecte';
                      final labels = widget.dynamicMonths ?? months;
                      return LineTooltipItem(
                        '${series}\nMois: ${labels[touched.x.toInt() % labels.length]}\nValeur: ${touched.y.toInt()}',
                        TextStyle(
                          color: touched.barIndex == 0
                              ? kHighlightColor
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 11 : 14,
                        ),
                      );
                    }).toList();
                  },
                ),
                handleBuiltInTouches: true,
                touchCallback: (event, response) {
                  if (event is FlTapUpEvent &&
                      response != null &&
                      response.lineBarSpots != null &&
                      response.lineBarSpots!.isNotEmpty) {
                    final spot = response.lineBarSpots!.first;
                    setState(() {
                      selectedSpot = spot;
                      selectedSeries =
                          spot.barIndex == 0 ? 'ventes' : 'collecte';
                      touchedIndex = spot.x.toInt();
                    });
                  } else if (event is FlLongPressEnd ||
                      event is FlPanEndEvent) {
                    setState(() {
                      selectedSpot = null;
                      selectedSeries = null;
                      touchedIndex = null;
                    });
                  }
                },
              ),
            ),
          ),
        ),
        // Légende interactive
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => setState(() =>
                    visibleSeries['ventes'] = !(visibleSeries['ventes']!)),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: visibleSeries['ventes']!
                            ? kHighlightColor
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: kHighlightColor, width: 1.5),
                      ),
                    ),
                    SizedBox(width: 5),
                    Text('Ventes',
                        style: TextStyle(
                            color: kHighlightColor,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              SizedBox(width: 18),
              GestureDetector(
                onTap: () => setState(() =>
                    visibleSeries['collecte'] = !(visibleSeries['collecte']!)),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: visibleSeries['collecte']!
                            ? Colors.green
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: Colors.green, width: 1.5),
                      ),
                    ),
                    SizedBox(width: 5),
                    Text('Collecte',
                        style: TextStyle(
                            color: Colors.green, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BarChartSample extends StatelessWidget {
  final bool isMobile;
  final List<bool> visibleSeries;
  final int? touchedIndex;
  final void Function(int)? onLegendTap;
  final void Function(int)? onTouch;
  final VoidCallback? onTouchEnd;
  final List<String>? dynamicMonths;
  final List<double>? dynamicVentes;
  final List<double>? dynamicCollecte;
  const BarChartSample({
    this.isMobile = false,
    required this.visibleSeries,
    this.touchedIndex,
    this.onLegendTap,
    this.onTouch,
    this.onTouchEnd,
    this.dynamicMonths,
    this.dynamicVentes,
    this.dynamicCollecte,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final defaultData = [
      {'name': 'Jan', 'ventes': 4000.0, 'collecte': 2400.0},
      {'name': 'Fév', 'ventes': 3000.0, 'collecte': 1398.0},
      {'name': 'Mar', 'ventes': 2000.0, 'collecte': 9800.0},
      {'name': 'Avr', 'ventes': 2780.0, 'collecte': 3908.0},
      {'name': 'Mai', 'ventes': 1890.0, 'collecte': 4800.0},
      {'name': 'Juin', 'ventes': 2390.0, 'collecte': 3800.0},
      {'name': 'Juil', 'ventes': 3490.0, 'collecte': 4300.0},
    ];
    final data = (dynamicMonths != null &&
            dynamicVentes != null &&
            dynamicCollecte != null)
        ? List.generate(
            dynamicMonths!.length,
            (i) => {
                  'name': dynamicMonths![i],
                  'ventes': (i < dynamicVentes!.length)
                      ? dynamicVentes![i].toDouble()
                      : 0.0,
                  'collecte': (i < dynamicCollecte!.length)
                      ? dynamicCollecte![i].toDouble()
                      : 0.0,
                })
        : defaultData;
    return Column(
      children: [
        Expanded(
          child: BarChart(
            BarChartData(
              gridData: FlGridData(
                  show: true,
                  horizontalInterval: 5000,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.grey[300], strokeWidth: 1)),
              borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey[300]!, width: 1)),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: isMobile ? 17 : 25,
                        interval: 5000)),
                bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (val, _) => Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(
                                  data[val.toInt() % data.length]['name']
                                      as String,
                                  style:
                                      TextStyle(fontSize: isMobile ? 9 : 13)),
                            ))),
              ),
              barGroups: List.generate(data.length, (i) {
                final isTouched = touchedIndex == i;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    if (visibleSeries[0])
                      BarChartRodData(
                        toY: (data[i]['ventes'] as double),
                        color: isTouched && visibleSeries[0]
                            ? kHighlightColor.withValues(alpha: 0.7)
                            : kHighlightColor,
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(show: false),
                      ),
                    if (visibleSeries[1])
                      BarChartRodData(
                        toY: (data[i]['collecte'] as double),
                        color: isTouched && visibleSeries[1]
                            ? Colors.green.withValues(alpha: 0.7)
                            : Colors.green,
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(show: false),
                      ),
                  ],
                );
              }),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipRoundedRadius: 10,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final idx = group.x.toInt();
                    final label = data[idx]['name'];
                    final value = rodIndex == 0
                        ? data[idx]['ventes']
                        : data[idx]['collecte'];
                    return BarTooltipItem(
                      '${rodIndex == 0 ? "Ventes" : "Collecte"}\n$label: ${(value as double).toStringAsFixed(0)}',
                      TextStyle(
                        color: rodIndex == 0 ? kHighlightColor : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                handleBuiltInTouches: false,
                touchCallback: (event, response) {
                  if (event is FlTapUpEvent ||
                      event is FlLongPressEnd ||
                      event is FlPanEndEvent) {
                    if (onTouchEnd != null) onTouchEnd!();
                  } else if (response != null && response.spot != null) {
                    final idx = response.spot!.touchedBarGroupIndex;
                    if (onTouch != null) onTouch!(idx);
                  }
                },
              ),
              // swapAnimationDuration: Duration(milliseconds: 2000), // SUPPRIMÉ car non supporté
            ),
          ),
        ),
        // Légende interactive
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => onLegendTap?.call(0),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: visibleSeries[0]
                            ? kHighlightColor
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: kHighlightColor, width: 1.5),
                      ),
                    ),
                    SizedBox(width: 5),
                    Text('Ventes',
                        style: TextStyle(
                            color: kHighlightColor,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              SizedBox(width: 18),
              GestureDetector(
                onTap: () => onLegendTap?.call(1),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color:
                            visibleSeries[1] ? Colors.green : Colors.grey[300],
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: Colors.green, width: 1.5),
                      ),
                    ),
                    SizedBox(width: 5),
                    Text('Collecte',
                        style: TextStyle(
                            color: Colors.green, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PieChartSample extends StatelessWidget {
  final int? touchedIndex;
  final void Function(int)? onTouch;
  final VoidCallback? onTouchEnd;
  final List<Map<String, Object>>? dynamicSlices; // {name, value, color}
  const PieChartSample({
    this.touchedIndex,
    this.onTouch,
    this.onTouchEnd,
    this.dynamicSlices,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final pieData = (dynamicSlices != null && dynamicSlices!.isNotEmpty)
        ? dynamicSlices!
        : [
            {'name': 'Acacia', 'value': 30.0, 'color': kHighlightColor},
            {'name': 'Lavande', 'value': 25.0, 'color': Colors.deepPurple},
            {'name': 'Tilleul', 'value': 20.0, 'color': Colors.green},
            {
              'name': 'Châtaignier',
              'value': 15.0,
              'color': Colors.yellowAccent
            },
            {'name': 'Autres', 'value': 10.0, 'color': Colors.orange},
          ];
    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: List.generate(pieData.length, (i) {
                final isTouched = touchedIndex == i;
                final item = pieData[i];
                final double radius = isTouched ? 60 : 50;
                return PieChartSectionData(
                  value: item['value'] as double,
                  color: item['color'] as Color,
                  title: '${item['name']}\n${item['value']}%',
                  radius: radius,
                  titleStyle: TextStyle(
                    fontSize: isTouched ? 14 : 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  titlePositionPercentageOffset: 0.6,
                );
              }),
              centerSpaceRadius: 30,
              sectionsSpace: 1,
              borderData: FlBorderData(show: false),
              pieTouchData: PieTouchData(
                enabled: true,
                touchCallback: (event, response) {
                  if (event is FlTapUpEvent &&
                      response != null &&
                      response.touchedSection != null) {
                    onTouch?.call(response.touchedSection!.touchedSectionIndex);
                  } else if (event is FlLongPressEnd ||
                      event is FlPanEndEvent) {
                    onTouchEnd?.call();
                  }
                },
              ),
            ),
            duration: Duration(milliseconds: 1200),
          ),
        ),
        // Légende
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Wrap(
            spacing: 14,
            children: List.generate(pieData.length, (i) {
              final item = pieData[i];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: item['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(item['name'] as String, style: TextStyle(fontSize: 11)),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class AreaChartSample extends StatelessWidget {
  final bool isMobile;
  final List<bool> visibleSeries;
  final int? touchedIndex;
  final void Function(int)? onLegendTap;
  final void Function(int)? onTouch;
  final VoidCallback? onTouchEnd;
  final List<String>? dynamicMonths;
  final List<double>? dynamicVentes;
  final List<double>? dynamicCollecte;
  const AreaChartSample({
    this.isMobile = false,
    required this.visibleSeries,
    this.touchedIndex,
    this.onLegendTap,
    this.onTouch,
    this.onTouchEnd,
    this.dynamicMonths,
    this.dynamicVentes,
    this.dynamicCollecte,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final defaultData = [
      {'name': 'Jan', 'ventes': 4000.0, 'collecte': 2400.0},
      {'name': 'Fév', 'ventes': 3000.0, 'collecte': 1398.0},
      {'name': 'Mar', 'ventes': 2000.0, 'collecte': 9800.0},
      {'name': 'Avr', 'ventes': 2780.0, 'collecte': 3908.0},
      {'name': 'Mai', 'ventes': 1890.0, 'collecte': 4800.0},
      {'name': 'Juin', 'ventes': 2390.0, 'collecte': 3800.0},
      {'name': 'Juil', 'ventes': 3490.0, 'collecte': 4300.0},
    ];
    final data = (dynamicMonths != null &&
            dynamicVentes != null &&
            dynamicCollecte != null)
        ? List.generate(
            dynamicMonths!.length,
            (i) => {
                  'name': dynamicMonths![i],
                  'ventes': (i < dynamicVentes!.length)
                      ? dynamicVentes![i].toDouble()
                      : 0.0,
                  'collecte': (i < dynamicCollecte!.length)
                      ? dynamicCollecte![i].toDouble()
                      : 0.0,
                })
        : defaultData;
    return LineChart(
      LineChartData(
        gridData: FlGridData(
            show: true,
            horizontalInterval: 5000,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.grey[300], strokeWidth: 1)),
        borderData: FlBorderData(
            show: true, border: Border.all(color: Colors.grey[300]!, width: 1)),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: isMobile ? 18 : 25,
                  interval: 5000)),
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (val, _) => Padding(
              padding: const EdgeInsets.only(top: 3.0),
              child: Text(data[val.toInt() % data.length]['name'] as String,
                  style: TextStyle(fontSize: isMobile ? 9 : 13)),
            ),
          )),
        ),
        minY: 0,
        maxY: 11000,
        lineBarsData: [
          if (visibleSeries[0])
            LineChartBarData(
              spots: [
                for (int i = 0; i < data.length; i++)
                  FlSpot(i.toDouble(), (data[i]['ventes'] as double)),
              ],
              isCurved: true,
              color: kHighlightColor,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  final isActive = touchedIndex == index;
                  return FlDotCirclePainter(
                    radius: isActive ? 6 : 4,
                    color: isActive ? kHighlightColor : Colors.white,
                    strokeColor: kHighlightColor,
                    strokeWidth: isActive ? 3 : 2,
                  );
                },
              ),
              belowBarData: BarAreaData(show: false),
            ),
          if (visibleSeries[1])
            LineChartBarData(
              spots: [
                for (int i = 0; i < data.length; i++)
                  FlSpot(i.toDouble(), (data[i]['collecte'] as double)),
              ],
              isCurved: true,
              color: Colors.green,
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  final isActive = touchedIndex == index;
                  return FlDotCirclePainter(
                    radius: isActive ? 6 : 4,
                    color: isActive ? Colors.green : Colors.white,
                    strokeColor: Colors.green,
                    strokeWidth: isActive ? 3 : 2,
                  );
                },
              ),
              belowBarData: BarAreaData(show: false),
            ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 10,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                final label = data[idx]['name'];
                final value = spot.barIndex == 0
                    ? data[idx]['ventes']
                    : data[idx]['collecte'];
                return LineTooltipItem(
                  '${spot.barIndex == 0 ? "Ventes" : "Collecte"}\n$label: ${(value as double).toStringAsFixed(0)}',
                  TextStyle(
                    color: spot.barIndex == 0 ? kHighlightColor : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: false,
          touchCallback: (event, response) {
            if (event is FlTapUpEvent ||
                event is FlLongPressEnd ||
                event is FlPanEndEvent) {
              if (onTouchEnd != null) onTouchEnd!();
            } else if (response != null &&
                response.lineBarSpots != null &&
                response.lineBarSpots!.isNotEmpty) {
              final idx = response.lineBarSpots!.first.x.toInt();
              if (onTouch != null) onTouch!(idx);
            }
          },
        ),
      ),
      duration: Duration(milliseconds: 2000),
    );
  }
}

// Alerts section
class AlertsSection extends StatefulWidget {
  final bool isMobile;
  const AlertsSection({required this.isMobile, Key? key}) : super(key: key);

  @override
  State<AlertsSection> createState() => _AlertsSectionState();
}

class _AlertsSectionState extends State<AlertsSection> {
  Query<Map<String, dynamic>> _buildBaseQuery() {
    // Utiliser la vraie collection des notifications caisse et éviter les erreurs d'index
    // Structure: notifications_caisse (cf. TransactionCommercialeService)
    // Champs: id, type, site, commercialId, commercialNom, transactionId,
    //         prelevementId, dateCreation(Timestamp), titre, message, statut, priorite, donnees
    Query<Map<String, dynamic>> q =
        FirebaseFirestore.instance.collection('notifications_caisse');
    try {
      final user = Get.find<UserSession>();
      if ((user.site ?? '').isNotEmpty) {
        // Equality filter seul pour éviter de nécessiter un index composite
        q = q.where('site', isEqualTo: user.site);
      }
    } catch (_) {}
    // On n'applique pas orderBy ici pour éviter les erreurs d'index composites runtime.
    // Le tri sera fait côté client sur le champ 'dateCreation' si présent.
    return q;
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'success':
        return Colors.green;
      case 'info':
      default:
        return Colors.blue;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'error':
        return Icons.cancel;
      case 'success':
        return Icons.check_circle;
      case 'info':
      default:
        return Icons.info;
    }
  }

  String _formatRelativeTime(dynamic ts) {
    try {
      DateTime when;
      if (ts is Timestamp) {
        when = ts.toDate();
      } else if (ts is int) {
        when = DateTime.fromMillisecondsSinceEpoch(ts);
      } else if (ts is String) {
        // already a human string like "Il y a 2h"
        return ts;
      } else {
        return '';
      }
      final now = DateTime.now();
      final diff = now.difference(when);
      if (diff.inSeconds < 60) return 'Il y a ${diff.inSeconds}s';
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
      if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
      return '${when.day.toString().padLeft(2, '0')}/${when.month.toString().padLeft(2, '0')}/${when.year}';
    } catch (_) {
      return '';
    }
  }

  void _openAlertsModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final baseQuery = _buildBaseQuery();
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
              horizontal: widget.isMobile ? 12 : 80, vertical: 24),
          child: _AlertsPaginatedList(
            baseQuery: baseQuery,
            typeColor: _typeColor,
            typeIcon: _typeIcon,
            formatTime: _formatRelativeTime,
            isMobile: widget.isMobile,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = widget.isMobile;
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 8 : 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Alertes & Notifications",
              style: TextStyle(
                  fontSize: isMobile ? 13 : 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _buildBaseQuery().limit(8).snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                if (snap.hasError) {
                  return Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Impossible de charger les alertes',
                            style: TextStyle(
                                fontSize: isMobile ? 11 : 12,
                                color: Colors.red.shade700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                // Trier côté client par dateCreation desc si dispo
                final docs =
                    List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                        snap.data?.docs ?? []);
                docs.sort((a, b) {
                  final ta = a.data()['dateCreation'] ?? a.data()['timestamp'];
                  final tb = b.data()['dateCreation'] ?? b.data()['timestamp'];
                  DateTime da;
                  DateTime db;
                  if (ta is Timestamp) {
                    da = ta.toDate();
                  } else if (ta is int) {
                    da = DateTime.fromMillisecondsSinceEpoch(ta);
                  } else {
                    da = DateTime.fromMillisecondsSinceEpoch(0);
                  }
                  if (tb is Timestamp) {
                    db = tb.toDate();
                  } else if (tb is int) {
                    db = DateTime.fromMillisecondsSinceEpoch(tb);
                  } else {
                    db = DateTime.fromMillisecondsSinceEpoch(0);
                  }
                  return db.compareTo(da);
                });
                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_none, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Aucune alerte pour le moment',
                            style: TextStyle(
                                fontSize: isMobile ? 11 : 12,
                                color: Colors.grey[700]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    ...docs.take(4).map((d) {
                      final data = d.data();
                      final type = (data['type'] ?? 'info').toString();
                      final title =
                          (data['titre'] ?? data['title'] ?? 'Notification')
                              .toString();
                      final msg = (data['message'] ?? '').toString();
                      final action = (data['action'] ?? '').toString();
                      final ts = data['dateCreation'] ?? data['timestamp'];
                      final c = _typeColor(type);
                      return Container(
                        margin: EdgeInsets.only(bottom: 9),
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.09),
                          border: Border.all(color: c.withValues(alpha: 0.18)),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Icon(_typeIcon(type),
                              color: c, size: isMobile ? 18 : 23),
                          title: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: isMobile ? 12 : 14),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: isMobile ? 10 : 12),
                              ),
                              SizedBox(height: 2),
                              Text(
                                _formatRelativeTime(ts),
                                style: TextStyle(
                                    fontSize: isMobile ? 9 : 10,
                                    color: Colors.grey[700]),
                              ),
                            ],
                          ),
                          trailing: (action.isNotEmpty)
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: c.withValues(alpha: 0.13),
                                    foregroundColor: c,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(7)),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 5),
                                    textStyle: TextStyle(
                                        fontSize: isMobile ? 9 : 11,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  onPressed: () {},
                                  child: Text(action,
                                      overflow: TextOverflow.ellipsis),
                                )
                              : null,
                        ),
                      );
                    }),
                    SizedBox(height: 10),
                    if (isMobile)
                      Center(
                        child: OutlinedButton(
                          onPressed: _openAlertsModal,
                          child: Text("Voir toutes les alertes",
                              style: TextStyle(fontSize: isMobile ? 11 : 13)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertsPaginatedList extends StatefulWidget {
  final Query<Map<String, dynamic>> baseQuery;
  final Color Function(String) typeColor;
  final IconData Function(String) typeIcon;
  final String Function(dynamic) formatTime;
  final bool isMobile;
  const _AlertsPaginatedList({
    required this.baseQuery,
    required this.typeColor,
    required this.typeIcon,
    required this.formatTime,
    required this.isMobile,
  });

  @override
  State<_AlertsPaginatedList> createState() => _AlertsPaginatedListState();
}

class _AlertsPaginatedListState extends State<_AlertsPaginatedList> {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _items = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  bool _loading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchMore();
  }

  Future<void> _fetchMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      Query<Map<String, dynamic>> q = widget.baseQuery.limit(20);
      if (_lastDoc != null) q = q.startAfterDocument(_lastDoc!);
      final snap = await q.get();
      if (mounted) {
        if (snap.docs.isNotEmpty) {
          _lastDoc = snap.docs.last;
          _items.addAll(snap.docs);
        }
        if (snap.docs.length < 20) _hasMore = false;
        setState(() {});
      }
    } catch (e) {
      // ignore errors in modal, keep graceful
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = widget.isMobile;
    return SizedBox(
      width: isMobile ? double.infinity : 720,
      height: isMobile ? MediaQuery.of(context).size.height * 0.8 : 520,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(Icons.notifications, color: kHighlightColor),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Toutes les alertes',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 14 : 16)),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ],
            ),
          ),
          Divider(height: 1),
          Expanded(
            child: _items.isEmpty && _loading
                ? Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('Aucune alerte trouvée',
                              style: TextStyle(color: Colors.grey[700])),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.all(12),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final data = _items[index].data();
                          final type = (data['type'] ?? 'info').toString();
                          final title =
                              (data['titre'] ?? data['title'] ?? 'Notification')
                                  .toString();
                          final msg = (data['message'] ?? '').toString();
                          final action = (data['action'] ?? '').toString();
                          final ts = data['dateCreation'] ?? data['timestamp'];
                          final c = widget.typeColor(type);
                          return Container(
                            decoration: BoxDecoration(
                              color: c.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: c.withValues(alpha: 0.18)),
                            ),
                            child: ListTile(
                              leading: Icon(widget.typeIcon(type), color: c),
                              title: Text(title,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(msg,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  SizedBox(height: 2),
                                  Text(widget.formatTime(ts),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[700])),
                                ],
                              ),
                              trailing: action.isNotEmpty
                                  ? OutlinedButton(
                                      onPressed: () {},
                                      child: Text(action,
                                          overflow: TextOverflow.ellipsis),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
          ),
          if (_hasMore)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.center,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _fetchMore,
                  icon: _loading
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.expand_more),
                  label: Text('Charger plus'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- TIMELINE/ACTIVITY ---
class ActivityTimeline extends StatefulWidget {
  final bool isMobile;
  const ActivityTimeline({required this.isMobile, Key? key}) : super(key: key);

  @override
  State<ActivityTimeline> createState() => _ActivityTimelineState();
}

class _ActivityTimelineState extends State<ActivityTimeline> {
  Query<Map<String, dynamic>> _buildBaseQuery() {
    // Utiliser la source réelle d'activités: transactions commerciales (module Caisse)
    // On évite orderBy ici pour ne pas nécessiter d'index composite; tri côté client.
    Query<Map<String, dynamic>> q =
        FirebaseFirestore.instance.collection('transactions_commerciales');
    try {
      final user = Get.find<UserSession>();
      if ((user.site ?? '').isNotEmpty) {
        q = q.where('site', isEqualTo: user.site);
      }
    } catch (_) {}
    return q;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatRelativeTime(dynamic ts) {
    try {
      DateTime when;
      if (ts is Timestamp) {
        when = ts.toDate();
      } else if (ts is int) {
        when = DateTime.fromMillisecondsSinceEpoch(ts);
      } else if (ts is String) {
        return ts;
      } else {
        return '';
      }
      final now = DateTime.now();
      final diff = now.difference(when);
      if (diff.inSeconds < 60) return 'Il y a ${diff.inSeconds}s';
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
      if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
      return '${when.day.toString().padLeft(2, '0')}/${when.month.toString().padLeft(2, '0')}/${when.year}';
    } catch (_) {
      return '';
    }
  }

  void _openActivitiesModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final baseQuery = _buildBaseQuery();
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
              horizontal: widget.isMobile ? 12 : 80, vertical: 24),
          child: _ActivitiesPaginatedList(
            baseQuery: baseQuery,
            isMobile: widget.isMobile,
            formatTime: _formatRelativeTime,
            statusColor: _statusColor,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = widget.isMobile;
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 8 : 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Historique des activités",
              style: TextStyle(
                  fontSize: isMobile ? 13 : 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _buildBaseQuery().limit(5).snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                if (snap.hasError) {
                  return Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Impossible de charger l\'historique',
                            style: TextStyle(
                                fontSize: isMobile ? 11 : 12,
                                color: Colors.red.shade700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                // Trier côté client par date desc (dateCreation, sinon dateTerminee, sinon timestamp)
                final docs =
                    List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                        snap.data?.docs ?? []);
                docs.sort((a, b) {
                  DateTime parse(dynamic v, Map<String, dynamic> all) {
                    final primary = v ?? all['timestamp'];
                    if (primary is Timestamp) return primary.toDate();
                    if (primary is int) {
                      return DateTime.fromMillisecondsSinceEpoch(primary);
                    }
                    if (all['dateTerminee'] is Timestamp) {
                      return (all['dateTerminee'] as Timestamp).toDate();
                    }
                    return DateTime.fromMillisecondsSinceEpoch(0);
                  }

                  final da = a.data();
                  final db = b.data();
                  final ta = parse(da['dateCreation'], da);
                  final tb = parse(db['dateCreation'], db);
                  return tb.compareTo(ta);
                });
                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(Icons.history, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Aucune activité récente',
                            style: TextStyle(
                                fontSize: isMobile ? 11 : 12,
                                color: Colors.grey[700]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    ...docs.map((d) {
                      final data = d.data();
                      final commercial =
                          (data['commercialNom'] ?? '').toString();
                      final titre = commercial.isNotEmpty
                          ? 'Transaction de $commercial'
                          : 'Transaction commerciale';
                      final resume =
                          data['resumeFinancier'] as Map<String, dynamic>?;
                      String caStr = '';
                      if (resume != null) {
                        final ca = resume['chiffreAffairesNet'];
                        if (ca != null) caStr = ca.toString();
                      }
                      final desc = caStr.isNotEmpty
                          ? 'Chiffre d\'affaires net: $caStr FCFA'
                          : '';
                      final utilisateur =
                          (data['validePar'] ?? data['site'] ?? '').toString();
                      final raw = (data['statut'] ?? '').toString();
                      String status;
                      switch (raw) {
                        case 'termine_en_attente':
                        case 'termineEnAttente':
                        case 'recupereeCaisse':
                        case 'recuperee_caisse':
                          status = 'pending';
                          break;
                        case 'valideeAdmin':
                        case 'validee_admin':
                          status = 'success';
                          break;
                        case 'rejetee':
                          status = 'error';
                          break;
                        default:
                          status = 'success';
                      }
                      final ts = data['dateCreation'] ??
                          data['dateTerminee'] ??
                          data['timestamp'];
                      final c = _statusColor(status);
                      return Container(
                        margin: EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.access_time,
                              size: 10, color: Colors.grey[600]),
                          title: Text(
                            titre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: isMobile ? 12 : 14),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                desc,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: isMobile ? 9 : 11),
                              ),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.person,
                                      size: 10, color: Colors.grey[600]),
                                  SizedBox(width: 2),
                                  Flexible(
                                    child: Text(
                                      utilisateur,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: isMobile ? 8 : 10,
                                          color: Colors.grey[700]),
                                    ),
                                  ),
                                  SizedBox(width: 7),
                                  Icon(Icons.access_time,
                                      size: 10, color: Colors.grey[600]),
                                  SizedBox(width: 2),
                                  Flexible(
                                    child: Text(
                                      _formatRelativeTime(ts),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: isMobile ? 8 : 10,
                                          color: Colors.grey[700]),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Chip(
                            backgroundColor: c.withValues(alpha: 0.15),
                            label: Text(
                              status == 'success'
                                  ? 'Validée'
                                  : status == 'pending'
                                      ? 'En cours'
                                      : 'Rejetée',
                              style: TextStyle(
                                  color: c,
                                  fontSize: isMobile ? 9 : 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    }),
                    if (isMobile)
                      Center(
                        child: OutlinedButton(
                          onPressed: _openActivitiesModal,
                          child: Text("Voir l'historique complet",
                              style: TextStyle(fontSize: isMobile ? 11 : 13)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivitiesPaginatedList extends StatefulWidget {
  final Query<Map<String, dynamic>> baseQuery;
  final bool isMobile;
  final String Function(dynamic) formatTime;
  final Color Function(String) statusColor;
  const _ActivitiesPaginatedList({
    required this.baseQuery,
    required this.isMobile,
    required this.formatTime,
    required this.statusColor,
  });

  @override
  State<_ActivitiesPaginatedList> createState() =>
      _ActivitiesPaginatedListState();
}

class _ActivitiesPaginatedListState extends State<_ActivitiesPaginatedList> {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _items = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  bool _loading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchMore();
  }

  Future<void> _fetchMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      Query<Map<String, dynamic>> q = widget.baseQuery.limit(25);
      if (_lastDoc != null) q = q.startAfterDocument(_lastDoc!);
      final snap = await q.get();
      if (mounted) {
        if (snap.docs.isNotEmpty) {
          _lastDoc = snap.docs.last;
          _items.addAll(snap.docs);
        }
        if (snap.docs.length < 25) _hasMore = false;
        setState(() {});
      }
    } catch (e) {
      // ignore errors in modal
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = widget.isMobile;
    return SizedBox(
      width: isMobile ? double.infinity : 760,
      height: isMobile ? MediaQuery.of(context).size.height * 0.8 : 540,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(Icons.history, color: kHighlightColor),
                SizedBox(width: 8),
                Expanded(
                  child: Text("Historique complet",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 14 : 16)),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ],
            ),
          ),
          Divider(height: 1),
          Expanded(
            child: _items.isEmpty && _loading
                ? Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text("Aucune activité trouvée",
                              style: TextStyle(color: Colors.grey[700])),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.all(12),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final data = _items[index].data();
                          final commercial =
                              (data['commercialNom'] ?? '').toString();
                          final title = commercial.isNotEmpty
                              ? 'Transaction de $commercial'
                              : 'Transaction commerciale';
                          final resume =
                              data['resumeFinancier'] as Map<String, dynamic>?;
                          String caStr = '';
                          if (resume != null) {
                            final ca = resume['chiffreAffairesNet'];
                            if (ca != null) caStr = ca.toString();
                          }
                          final desc = caStr.isNotEmpty
                              ? 'Chiffre d\'affaires net: $caStr FCFA'
                              : '';
                          final user = (data['validePar'] ?? data['site'] ?? '')
                              .toString();
                          final raw = (data['statut'] ?? '').toString();
                          String status;
                          switch (raw) {
                            case 'termine_en_attente':
                            case 'termineEnAttente':
                            case 'recupereeCaisse':
                            case 'recuperee_caisse':
                              status = 'pending';
                              break;
                            case 'valideeAdmin':
                            case 'validee_admin':
                              status = 'success';
                              break;
                            case 'rejetee':
                              status = 'error';
                              break;
                            default:
                              status = 'success';
                          }
                          final ts = data['dateCreation'] ??
                              data['dateTerminee'] ??
                              data['timestamp'];
                          final c = widget.statusColor(status);
                          return Container(
                            decoration: BoxDecoration(
                              color: c.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: c.withValues(alpha: 0.18)),
                            ),
                            child: ListTile(
                              leading: Icon(Icons.timeline, color: c),
                              title: Text(title,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(desc,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.person,
                                          size: 12, color: Colors.grey[700]),
                                      SizedBox(width: 4),
                                      Flexible(
                                        child: Text(user,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[800])),
                                      ),
                                      SizedBox(width: 10),
                                      Icon(Icons.access_time,
                                          size: 12, color: Colors.grey[700]),
                                      SizedBox(width: 4),
                                      Flexible(
                                        child: Text(widget.formatTime(ts),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[800])),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              trailing: Chip(
                                label: Text(status == 'success'
                                    ? 'Validée'
                                    : status == 'pending'
                                        ? 'En cours'
                                        : 'Rejetée'),
                                backgroundColor: c.withValues(alpha: 0.15),
                                labelStyle: TextStyle(
                                    color: c, fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          if (_hasMore)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.center,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _fetchMore,
                  icon: _loading
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.expand_more),
                  label: Text('Charger plus'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Navigation Slider
class NavigationSlider extends StatelessWidget {
  final bool isOpen, isMobile, isTablet, isDesktop;
  final VoidCallback onToggle;
  final Function(String module, {String? subModule})? onModuleSelected;
  const NavigationSlider({
    required this.isOpen,
    required this.onToggle,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
    this.onModuleSelected,
    Key? key,
  }) : super(key: key);

  // Matrice d'accès site/role
  static const Map<String, List<String>> siteRoles = {
    'Ouaga': [
      'Magazinier',
      'Commercial',
      'Gestionnaire Commercial',
      'Caissier',
      'Caissière'
    ],
    'Koudougou': ['Tout'],
    'Bobo': ['Tout'],
    'Mangodara': ['Collecteur', 'Contrôleur', 'Controlleur'],
    'Bagre': [
      'Collecteur',
      'Contrôleur',
      'Controlleur',
      'Filtreur',
      'Commercialisation',
      'Caissier'
    ],
    'Pô': ['Tout'],
  };

  // Matrice d'accès module/role - ACCÈS STRICT PAR RÔLE
  static const Map<String, List<String>> moduleRoles = {
    // 🔒 COLLECTEUR : Seulement COLLECTE
    'COLLECTE': ['Admin', 'Collecteur'],

    // 🔒 CONTRÔLEUR : Seulement CONTRÔLE, FILTRAGE, EXTRACTION
    'CONTRÔLE': ['Admin', 'Contrôleur', 'Controlleur'],
    'FILTRAGE': [
      'Admin',
      'Contrôleur',
      'Controlleur',
      'Filtreur',
      'Extracteur'
    ],
    'EXTRACTION': [
      'Admin',
      'Contrôleur',
      'Controlleur',
      'Filtreur',
      'Extracteur'
    ],

    // 🔒 EXTRACTEUR : Seulement FILTRAGE, EXTRACTION
    // 🔒 FILTREUR : Seulement FILTRAGE, EXTRACTION
    // (Déjà inclus dans les lignes ci-dessus)

    // 🔒 CONDITIONNEUR : Seulement CONDITIONNEMENT
    'CONDITIONNEMENT': ['Admin', 'Conditionneur'],

    // 🔒 GESTION DE VENTES : Rôles commerciaux uniquement
    'GESTION DE VENTES': [
      'Admin',
      'Magazinier',
      'Gestionnaire Commercial',
      'Commercial',
      'Caissier',
      'Caissière'
    ],

    // 🔒 CAISSE : Accès dédié aux rôles financiers / commerciaux élargis
    'CAISSE': [
      'Admin',
      'Gestionnaire Commercial',
      'Caissier',
      'Caissière',
      'Commercial'
    ],

    // (VENTES module supprimé du sidebar)

    // 🔒 ADMINISTRATION : Admin uniquement
    'ADMINISTRATION': ['Admin'],
  };

  List<Map<String, dynamic>> filterModulesByUser(
      List<Map<String, dynamic>> modules, UserSession user) {
    final role = user.role ?? '';

    debugPrint('🔍 [FilterModules] Utilisateur: $role (Site: ${user.site})');

    // Si admin, accès à tout
    if (role.toLowerCase() == 'admin') {
      debugPrint('✅ [FilterModules] Admin détecté - Accès à tous les modules');
      return modules;
    }

    // 📋 AFFICHER LES RÈGLES D'ACCÈS PAR RÔLE
    debugPrint('📋 [FilterModules] Règles d\'accès par rôle:');
    debugPrint('   🔒 Collecteur → COLLECTE uniquement');
    debugPrint('   🔒 Contrôleur → CONTRÔLE, FILTRAGE, EXTRACTION');
    debugPrint('   🔒 Extracteur → FILTRAGE, EXTRACTION uniquement');
    debugPrint('   🔒 Filtreur → FILTRAGE, EXTRACTION uniquement');
    debugPrint('   🔒 Conditionneur → CONDITIONNEMENT uniquement');
    debugPrint('   🔒 Commercial/Caissier → GESTION DE VENTES');
    debugPrint('   🔒 Admin → TOUS les modules');

    // 🔒 FILTRAGE UNIQUEMENT PAR RÔLE (indépendamment du site)
    final filteredModules = modules.where((m) {
      final moduleName = m['name'] as String;
      final allowed = moduleRoles[moduleName] ?? [];

      final hasAccess = allowed.contains(role) || allowed.contains(role + 'e');

      debugPrint(
          '🔍 [FilterModules] Module $moduleName: $hasAccess (Rôles autorisés: $allowed)');
      return hasAccess;
    }).toList();

    debugPrint(
        '✅ [FilterModules] Modules filtrés: ${filteredModules.map((m) => m['name']).join(", ")}');
    return filteredModules;
  }

  @override
  Widget build(BuildContext context) {
    UserSession user;
    try {
      user = Get.find<UserSession>();
    } catch (_) {
      user = Get.put(UserSession());
    }
    final modules = [
      {
        "icon": Icons.nature,
        "name": "COLLECTE",
        "subModules": [
          {"name": "Récoltes", "icon": Icons.agriculture},
          {"name": "Achat Scoop", "icon": Icons.inventory_2},
          {"name": "Achats Individuels", "icon": Icons.person},
          {"name": "Collecte Mielleries", "icon": Icons.factory}
        ]
      },
      {
        "icon": Icons.security,
        "name": "CONTRÔLE",
        "subModules": [
          {"name": "Nouveau contrôle"},
          {"name": "Historique contrôles"}
        ]
      },
      {
        "icon": Icons.science,
        "name": "EXTRACTION",
        "subModules": [
          {"name": "Nouvelle extraction"},
          {"name": "Historique extractions"}
        ]
      },
      {
        "name": "FILTRAGE",
        "icon": Icons.filter_alt,
        "subModules": [
          {"name": "Nouveau filtrage"},
          {"name": "Historique filtrage"}
        ]
      },
      {
        "name": "CONDITIONNEMENT",
        "icon": Icons.all_inbox,
        "subModules": [
          {"name": "Nouveau conditionnement"},
          {"name": "Stock conditionné"}
        ]
      },
      {
        "name": "GESTION DE VENTES",
        "icon": Icons.trending_up,
        "subModules": [
          {"name": "Nouvelle vente"},
          {"name": "Historique ventes"}
        ]
      },
      {
        "name": "CAISSE",
        "icon": Icons.account_balance,
        "subModules": [
          {"name": "Synthèse Caisse"},
          {"name": "Analyse Paiements"}
        ]
      },
      {
        "name": "ADMINISTRATION",
        "icon": Icons.admin_panel_settings,
        "subModules": [
          {"name": "Créer un compte", "icon": Icons.person_add},
          {"name": "Gestion Utilisateurs", "icon": Icons.people},
          {"name": "Paramètres Système", "icon": Icons.settings},
          {"name": "Rapports Admin", "icon": Icons.analytics}
        ]
      },
    ];

    // 🔒 FILTRAGE DES MODULES PAR RÔLE UTILISATEUR
    final filteredModules = filterModulesByUser(modules, user);

    debugPrint('🔍 [Sidebar] Utilisateur: ${user.role} (${user.site})');
    debugPrint('🔍 [Sidebar] Total modules disponibles: ${modules.length}');
    debugPrint(
        '🔍 [Sidebar] Modules accessibles après filtrage: ${filteredModules.length}');
    debugPrint(
        '🔍 [Sidebar] Modules accessibles: ${filteredModules.map((m) => m["name"]).join(", ")}');

    // 🚨 VÉRIFICATION CRITIQUE : Si aucun module accessible, afficher un message
    if (filteredModules.isEmpty) {
      debugPrint(
          '❌ [Sidebar] ATTENTION: Aucun module accessible pour ${user.role} (${user.site})');
    }

    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      width: isOpen
          ? (isMobile ? MediaQuery.of(context).size.width * 0.85 : 280)
          : 0,
      child: isOpen
          ? ClipRRect(
              borderRadius: isMobile
                  ? BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    )
                  : BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.orange.shade50,
                      Colors.white,
                      Colors.orange.shade50,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header moderne avec animation
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kHighlightColor, Colors.orange.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.2),
                                child:
                                    Icon(Icons.dashboard, color: Colors.white),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Navigation',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Apisavana Dashboard',
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isMobile || isTablet)
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.white),
                                  onPressed: onToggle,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 🔒 Indicateur de filtrage par rôle
                    if (user.role?.toLowerCase() != 'admin')
                      Container(
                        margin:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: Colors.orange.shade700,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Accès limité: ${filteredModules.length}/${modules.length} modules',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Bouton retour au dashboard avec design moderne
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: () {
                                if (isMobile || isTablet) onToggle();
                                if (onModuleSelected != null) {
                                  onModuleSelected!('DASHBOARD',
                                      subModule: null);
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(15),
                                  border:
                                      Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.home,
                                        color: Colors.blue.shade600),
                                    SizedBox(width: 12),
                                    Text(
                                      'Retour au dashboard',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Bouton de création de compte supprimé
                        ],
                      ),
                    ),

                    // Liste des modules avec animations
                    Expanded(
                      child: filteredModules.isEmpty
                          ? _buildNoAccessMessage()
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              itemCount: filteredModules.length,
                              itemBuilder: (context, index) {
                                final module = filteredModules[index];
                                return TweenAnimationBuilder<double>(
                                  duration: Duration(
                                      milliseconds: 300 + (index * 100)),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  builder: (context, value, child) {
                                    return Transform.translate(
                                      offset: Offset(50 * (1 - value), 0),
                                      child: Opacity(
                                        opacity: value,
                                        child: _buildModuleCard(module),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            )
          : SizedBox.shrink(),
    );
  }

  Widget _buildNoAccessMessage() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Aucun module accessible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Votre rôle ne vous donne accès à aucun module sur ce site.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Text(
              'Contactez votre administrateur pour obtenir les permissions nécessaires.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(Map<String, dynamic> module) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: ThemeData().copyWith(dividerColor: Colors.transparent),
          child: GestureDetector(
            // Empêche la propagation des événements vers le parent
            onTap: () {
              // Ne rien faire ici, laisse l'ExpansionTile gérer les clics
            },
            child: ExpansionTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              backgroundColor: Colors.white.withValues(alpha: 0.7),
              collapsedBackgroundColor: Colors.white.withValues(alpha: 0.5),
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kHighlightColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  module["icon"] as IconData,
                  color: kHighlightColor,
                  size: 20,
                ),
              ),
              title: Text(
                module["name"] as String,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if ((module["badge"] as int? ?? 0) > 0)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade500,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (module["badge"] as int).toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  SizedBox(width: 8),
                  Icon(Icons.expand_more),
                ],
              ),
              children:
                  (module["subModules"] as List<Map<String, dynamic>>? ?? [])
                      .map((sub) {
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      // DEBUG: clic côté sidebar
                      try {
                        final moduleName = module["name"] as String?;
                        final subName = sub["name"] as String?;
                        print(
                            '🟡 Sidebar tap -> module="$moduleName", subModule="$subName"');
                      } catch (_) {}
                      // Seulement fermer le sidebar lors de la sélection d'un sous-module
                      if (isMobile || isTablet) onToggle();
                      onModuleSelected?.call(
                        module["name"] as String,
                        subModule: sub["name"] as String?,
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: kHighlightColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              sub["name"] as String,
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          if ((sub["badge"] as int? ?? 0) > 0)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade500,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                (sub["badge"] as int).toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// Skeleton Loader
class DashboardSkeleton extends StatelessWidget {
  final bool isMobile, isTablet, isDesktop;
  const DashboardSkeleton(
      {required this.isMobile,
      required this.isTablet,
      required this.isDesktop,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 6 : 22, vertical: isMobile ? 8 : 18),
          child: Row(
            children: List.generate(
                4,
                (i) => Expanded(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 6),
                        height: isMobile ? 80 : 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 6 : 22, vertical: isMobile ? 8 : 18),
          child: Container(
            height: isMobile ? 120 : 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 6 : 22, vertical: isMobile ? 8 : 18),
          child: Column(
            children: List.generate(
                2,
                (i) => Container(
                      margin: EdgeInsets.only(bottom: 12),
                      height: isMobile ? 60 : 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    )),
          ),
        ),
      ],
    );
  }
}
