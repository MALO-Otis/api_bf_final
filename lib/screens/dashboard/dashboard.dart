import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:apisavana_gestion/screens/collecte_de_donnes/collecte_donnes.dart';
import 'package:get/get.dart';
import 'package:apisavana_gestion/authentication/user_session.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:apisavana_gestion/authentication/login.dart';
import 'package:apisavana_gestion/screens/collecte_de_donnes/nouvelle_collecte_recolte.dart';

// Color palette
const Color kHighlightColor = Color(0xFFF49101);
const Color kValidationColor = Color(0xFF2D0C0D);

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool isSliderOpen = false;
  bool _isLoading = true;
  Widget? _currentPage;

  @override
  void initState() {
    super.initState();
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
              {"name": "VENTES"},
              {"name": "COLLECTE"},
              {"name": "CONTRÔLE"},
              {"name": "EXTRACTION"},
              {"name": "FILTRAGE"},
              {"name": "CONDITIONNEMENT"},
              {"name": "GESTION DE VENTES"},
              {"name": "RAPPORTS"},
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

  void _navigateTo(String moduleName, {String? subModule}) {
    // Ne ferme le menu que si on ouvre une vraie page (sous-module)
    if (subModule != null) {
      setState(() {
        isSliderOpen = false;
        if (moduleName == 'COLLECTE' && subModule == 'Nouvelle collecte') {
          _currentPage = NouvelleCollecteRecoltePage();
          return;
        }
        switch (moduleName) {
          case 'COLLECTE':
            _currentPage = CollectePage();
            break;
          default:
            _currentPage = null;
        }
      });
    }
    // Si on clique juste sur le module (pour déplier), ne rien faire
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;

    Widget navigationSlider = NavigationSlider(
      isOpen: isDesktop || isSliderOpen,
      onToggle: () => setState(() => isSliderOpen = !isSliderOpen),
      isMobile: isMobile,
      isTablet: isTablet,
      isDesktop: isDesktop,
      onModuleSelected: (moduleName, {subModule}) =>
          _navigateTo(moduleName, subModule: subModule),
    );

    Widget mainContent = _isLoading
        ? DashboardSkeleton(
            isMobile: isMobile,
            isTablet: isTablet,
            isDesktop: isDesktop,
          )
        : (_currentPage ??
            MainDashboardContent(
              isMobile: isMobile,
              isTablet: isTablet,
              isDesktop: isDesktop,
            ));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              children: [
                // Main Content
                Expanded(
                  child: Column(
                    children: [
                      DashboardHeader(
                        onMenuToggle: () =>
                            setState(() => isSliderOpen = !isSliderOpen),
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
            // Overlay for mobile/tablet
            if (!isDesktop)
              AnimatedPositioned(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOut,
                right: isSliderOpen ? 0 : -270,
                top: 0,
                bottom: 0,
                width: 250,
                child: Material(
                  color: Colors.white,
                  elevation: 16,
                  child: navigationSlider,
                ),
              ),
            if (isSliderOpen && !isDesktop)
              // Utilise ModalBarrier pour éviter la fermeture au scroll
              ModalBarrier(
                color: Colors.black.withOpacity(0.3),
                dismissible: true,
                onDismiss: () => setState(() => isSliderOpen = false),
              ),
          ],
        ),
      ),
    );
  }
}

// Header
class DashboardHeader extends StatelessWidget {
  final VoidCallback onMenuToggle;
  final bool isMobile, isTablet;

  const DashboardHeader(
      {required this.onMenuToggle,
      required this.isMobile,
      required this.isTablet,
      Key? key})
      : super(key: key);

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
            horizontal: isMobile ? 8 : 24, vertical: isMobile ? 8 : 14),
        child: Row(
          children: [
            if (isMobile || isTablet)
              IconButton(
                icon: Icon(Icons.menu, color: kHighlightColor, size: 28),
                onPressed: onMenuToggle,
              ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/logo/logo.jpeg', // Correct path
                height: isMobile ? 30 : 44,
                width: isMobile ? 30 : 44,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Dashboard Administrateur",
                      style: TextStyle(
                        fontSize: isMobile ? 15 : 21,
                        fontWeight: FontWeight.bold,
                        color: kHighlightColor,
                      ),
                      overflow: TextOverflow.ellipsis),
                  if (!isMobile)
                    Text("Plateforme de gestion Apisavana",
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ),
            if (!isMobile)
              Row(
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
                  SizedBox(width: 10),
                  Column(
                    children: [
                      Text("Heure",
                          style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Text(hourStr,
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  SizedBox(width: 10),
                  Row(
                    children: [
                      Icon(Icons.circle, color: Colors.green, size: 11),
                      SizedBox(width: 4),
                      Text("Système actif",
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            SizedBox(width: isMobile ? 6 : 12),
            IconButton(
              icon: Stack(
                children: [
                  Icon(Icons.notifications,
                      color: kHighlightColor, size: isMobile ? 18 : 22),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.redAccent,
                      radius: 6,
                      child: Text("3",
                          style: TextStyle(fontSize: 9, color: Colors.white)),
                    ),
                  ),
                ],
              ),
              onPressed: () {},
            ),
            if (!isMobile) ...[
              IconButton(
                  icon: Icon(Icons.refresh, color: Colors.grey[700]),
                  onPressed: () {}),
              IconButton(
                  icon: Icon(Icons.settings, color: Colors.grey[700]),
                  onPressed: () {}),
            ],
            OutlinedButton.icon(
              icon: Icon(Icons.logout, color: Colors.red[400], size: 16),
              label: isMobile
                  ? SizedBox.shrink()
                  : Text("Déconnexion",
                      style: TextStyle(color: Colors.red[400], fontSize: 12)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red[100]!),
                backgroundColor: Colors.red[50],
                padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 5 : 12, vertical: 6),
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

  @override
  Widget build(BuildContext context) {
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
              Text("Vue d'ensemble",
                  style: TextStyle(
                      fontSize: widget.isMobile ? 15 : 19,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 18,
                children: [
                  KPICard(
                      title: "Ventes du mois",
                      value: "€24,500",
                      icon: Icons.shopping_cart,
                      color: kHighlightColor,
                      trend: 12,
                      isPositive: true,
                      isMobile: widget.isMobile),
                  KPICard(
                      title: "Collecte totale",
                      value: "1,240 kg",
                      icon: Icons.local_florist,
                      color: Colors.green,
                      trend: 8,
                      isPositive: true,
                      isMobile: widget.isMobile),
                  KPICard(
                      title: "Stock disponible",
                      value: "3,680 kg",
                      icon: Icons.inventory,
                      color: Colors.orange,
                      trend: 5,
                      isPositive: false,
                      isMobile: widget.isMobile),
                  KPICard(
                      title: "Crédits en attente",
                      value: "€8,900",
                      icon: Icons.credit_card,
                      color: Colors.red,
                      trend: 15,
                      isPositive: false,
                      isMobile: widget.isMobile),
                ],
              ),
            ],
          ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ChartTypeButton(
                      label: "Ligne",
                      icon: Icons.show_chart,
                      selected: selectedChart == 0,
                      onTap: () => setState(() => selectedChart = 0)),
                  ChartTypeButton(
                      label: "Histogramme",
                      icon: Icons.bar_chart,
                      selected: selectedChart == 1,
                      onTap: () => setState(() => selectedChart = 1)),
                  ChartTypeButton(
                      label: "Cercle",
                      icon: Icons.pie_chart,
                      selected: selectedChart == 2,
                      onTap: () => setState(() => selectedChart = 2)),
                  ChartTypeButton(
                      label: "Aire",
                      icon: Icons.area_chart,
                      selected: selectedChart == 3,
                      onTap: () => setState(() => selectedChart = 3)),
                ],
              ),
              SizedBox(height: 8),
              Container(
                height: widget.isMobile ? 170 : 260,
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 2000), // transition 2s
                  child: selectedChart == 0
                      ? LineChartSample(
                          isMobile: widget.isMobile,
                          visibleSeries: visibleSeries,
                          touchedIndex: touchedIndex,
                          onLegendTap: (i) => setState(() {
                            visibleSeries[i] = !visibleSeries[i];
                          }),
                          onTouch: (i) => setState(() => touchedIndex = i),
                          onTouchEnd: () => setState(() => touchedIndex = null),
                        )
                      : selectedChart == 1
                          ? BarChartSample(
                              isMobile: widget.isMobile,
                              visibleSeries: visibleSeries,
                              touchedIndex: touchedIndex,
                              onLegendTap: (i) => setState(() {
                                visibleSeries[i] = !visibleSeries[i];
                              }),
                              onTouch: (i) => setState(() => touchedIndex = i),
                              onTouchEnd: () =>
                                  setState(() => touchedIndex = null),
                            )
                          : selectedChart == 2
                              ? PieChartSample(
                                  touchedIndex: touchedIndex,
                                  onTouch: (i) =>
                                      setState(() => touchedIndex = i),
                                  onTouchEnd: () =>
                                      setState(() => touchedIndex = null),
                                )
                              : AreaChartSample(
                                  isMobile: widget.isMobile,
                                  visibleSeries: visibleSeries,
                                  touchedIndex: touchedIndex,
                                  onLegendTap: (i) => setState(() {
                                    visibleSeries[i] = !visibleSeries[i];
                                  }),
                                  onTouch: (i) =>
                                      setState(() => touchedIndex = i),
                                  onTouchEnd: () =>
                                      setState(() => touchedIndex = null),
                                ),
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
            colors: [color.withOpacity(0.08), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: isMobile ? 19 : 25),
            SizedBox(height: isMobile ? 4 : 8),
            Text(title,
                style: TextStyle(
                    fontSize: isMobile ? 11 : 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500)),
            SizedBox(height: isMobile ? 3 : 7),
            Text(value,
                style: TextStyle(
                    fontSize: isMobile ? 14 : 19, fontWeight: FontWeight.bold)),
            SizedBox(height: 1),
            Row(
              children: [
                Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isPositive ? Colors.green : Colors.red,
                    size: isMobile ? 14 : 16),
                SizedBox(width: 2),
                Text('${trend.abs()}% ',
                    style: TextStyle(
                        color: isPositive ? Colors.green : Colors.red,
                        fontSize: isMobile ? 10 : 12,
                        fontWeight: FontWeight.bold)),
                Text('vs. mois dernier',
                    style: TextStyle(
                        color: Colors.grey[600], fontSize: isMobile ? 9 : 11)),
              ],
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
  const LineChartSample({
    this.isMobile = false,
    required this.visibleSeries,
    this.touchedIndex,
    this.onLegendTap,
    this.onTouch,
    this.onTouchEnd,
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
                              child: Text(months[val.toInt() % 7],
                                  style:
                                      TextStyle(fontSize: isMobile ? 9 : 13)),
                            ))),
              ),
              minY: 0,
              maxY: 10000,
              lineBarsData: [
                if (visibleSeries['ventes']!)
                  LineChartBarData(
                    spots: ventes,
                    isCurved: true,
                    color: kHighlightColor,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                if (visibleSeries['collecte']!)
                  LineChartBarData(
                    spots: collecte,
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
                      return LineTooltipItem(
                        '${series}\nMois: ${months[touched.x.toInt()]}\nValeur: ${touched.y.toInt()} kg',
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
  const BarChartSample({
    this.isMobile = false,
    required this.visibleSeries,
    this.touchedIndex,
    this.onLegendTap,
    this.onTouch,
    this.onTouchEnd,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final data = [
      {'name': 'Jan', 'ventes': 4000.0, 'collecte': 2400.0},
      {'name': 'Fév', 'ventes': 3000.0, 'collecte': 1398.0},
      {'name': 'Mar', 'ventes': 2000.0, 'collecte': 9800.0},
      {'name': 'Avr', 'ventes': 2780.0, 'collecte': 3908.0},
      {'name': 'Mai', 'ventes': 1890.0, 'collecte': 4800.0},
      {'name': 'Juin', 'ventes': 2390.0, 'collecte': 3800.0},
      {'name': 'Juil', 'ventes': 3490.0, 'collecte': 4300.0},
    ];
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
                                  [
                                    'Jan',
                                    'Fév',
                                    'Mar',
                                    'Avr',
                                    'Mai',
                                    'Juin',
                                    'Juil'
                                  ][val.toInt() % 7],
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
                            ? kHighlightColor.withOpacity(0.7)
                            : kHighlightColor,
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(show: false),
                      ),
                    if (visibleSeries[1])
                      BarChartRodData(
                        toY: (data[i]['collecte'] as double),
                        color: isTouched && visibleSeries[1]
                            ? Colors.green.withOpacity(0.7)
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
  const PieChartSample({
    this.touchedIndex,
    this.onTouch,
    this.onTouchEnd,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final pieData = [
      {'name': 'Acacia', 'value': 30.0, 'color': kHighlightColor},
      {'name': 'Lavande', 'value': 25.0, 'color': Colors.deepPurple},
      {'name': 'Tilleul', 'value': 20.0, 'color': Colors.green},
      {'name': 'Châtaignier', 'value': 15.0, 'color': Colors.yellowAccent},
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
  const AreaChartSample({
    this.isMobile = false,
    required this.visibleSeries,
    this.touchedIndex,
    this.onLegendTap,
    this.onTouch,
    this.onTouchEnd,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final data = [
      {'name': 'Jan', 'ventes': 4000.0, 'collecte': 2400.0},
      {'name': 'Fév', 'ventes': 3000.0, 'collecte': 1398.0},
      {'name': 'Mar', 'ventes': 2000.0, 'collecte': 9800.0},
      {'name': 'Avr', 'ventes': 2780.0, 'collecte': 3908.0},
      {'name': 'Mai', 'ventes': 1890.0, 'collecte': 4800.0},
      {'name': 'Juin', 'ventes': 2390.0, 'collecte': 3800.0},
      {'name': 'Juil', 'ventes': 3490.0, 'collecte': 4300.0},
    ];
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
              child: Text(
                  [
                    'Jan',
                    'Fév',
                    'Mar',
                    'Avr',
                    'Mai',
                    'Juin',
                    'Juil'
                  ][val.toInt() % 7],
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
                  FlSpot(i.toDouble(), data[i]['ventes'] as double),
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
                  FlSpot(i.toDouble(), data[i]['collecte'] as double),
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
class AlertsSection extends StatelessWidget {
  final bool isMobile;
  final alerts = const [
    {
      "type": "warning",
      "title": "Stock bas",
      "message": "Miel Acacia: seulement 15 kg restants",
      "timestamp": "Il y a 2 heures",
      "action": "Réapprovisionner"
    },
    {
      "type": "error",
      "title": "Crédit en retard",
      "message": "Client Martin DUPONT: 2,400€ depuis 45 jours",
      "timestamp": "Il y a 3 heures",
      "action": "Relancer"
    },
    {
      "type": "success",
      "title": "Nouvelle commande",
      "message": "Commande #2024-156: 50 kg miel toutes fleurs",
      "timestamp": "Il y a 1 heure",
      "action": "Traiter"
    },
    {
      "type": "info",
      "title": "Extraction terminée",
      "message": "Lot #EXT-2024-089: 120 kg extraits",
      "timestamp": "Il y a 30 minutes",
      "action": "Vérifier"
    },
  ];
  const AlertsSection({required this.isMobile, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconMap = {
      "warning": Icons.warning_amber_rounded,
      "error": Icons.cancel,
      "success": Icons.check_circle,
      "info": Icons.info,
    };
    final colorMap = {
      "warning": Colors.orange,
      "error": Colors.red,
      "success": Colors.green,
      "info": Colors.blue,
    };
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
            Text("Alertes & Notifications",
                style: TextStyle(
                    fontSize: isMobile ? 13 : 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ...alerts.map((alert) {
              final c = colorMap[alert["type"]];
              return Container(
                margin: EdgeInsets.only(bottom: 9),
                decoration: BoxDecoration(
                  color: c!.withOpacity(0.09),
                  border: Border.all(color: c.withOpacity(0.18)),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: ListTile(
                  dense: true,
                  leading: Icon(iconMap[alert["type"]],
                      color: c, size: isMobile ? 18 : 23),
                  title: Text(alert["title"]!,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 12 : 14)),
                  subtitle: Text(alert["message"]!,
                      style: TextStyle(fontSize: isMobile ? 10 : 12)),
                  trailing: alert["action"] != null
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: c.withOpacity(0.13),
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
                          child: Text(alert["action"]!),
                        )
                      : null,
                ),
              );
            }),
            SizedBox(height: 10),
            if (isMobile)
              Center(
                child: OutlinedButton(
                  onPressed: () {},
                  child: Text("Voir toutes les alertes",
                      style: TextStyle(fontSize: isMobile ? 11 : 13)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- TIMELINE/ACTIVITY ---
class ActivityTimeline extends StatelessWidget {
  final bool isMobile;
  final activities = const [
    {
      "type": "vente",
      "title": "Nouvelle vente créée",
      "description":
          "Vente #2024-156 pour 50kg miel toutes fleurs - Client: Boulangerie Martin",
      "user": "Sophie Durand",
      "timestamp": "Il y a 15 minutes",
      "status": "success"
    },
    {
      "type": "collecte",
      "title": "Collecte terminée",
      "description": "Apiculteur Jean MOREAU: 45kg miel acacia collectés",
      "user": "Système",
      "timestamp": "Il y a 1 heure",
      "status": "success"
    },
    {
      "type": "controle",
      "title": "Contrôle qualité en attente",
      "description":
          "Lot #LOT-2024-088 nécessite un contrôle avant mise en stock",
      "user": "Pierre Lefèvre",
      "timestamp": "Il y a 2 heures",
      "status": "pending"
    },
    {
      "type": "extraction",
      "title": "Extraction démarrée",
      "description": "Traitement du lot #EXT-2024-089 - Durée estimée: 3h",
      "user": "Marie Dubois",
      "timestamp": "Il y a 3 heures",
      "status": "pending"
    },
    {
      "type": "system",
      "title": "Sauvegarde automatique",
      "description": "Sauvegarde quotidienne des données effectuée avec succès",
      "user": "Système",
      "timestamp": "Il y a 6 heures",
      "status": "success"
    },
  ];
  const ActivityTimeline({required this.isMobile, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorMap = {
      "success": Colors.green,
      "pending": Colors.orange,
      "error": Colors.red,
    };
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
            Text("Historique des activités",
                style: TextStyle(
                    fontSize: isMobile ? 13 : 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ...activities.map((activity) {
              final c = colorMap[activity["status"]];
              return Container(
                margin: EdgeInsets.only(bottom: 10),
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.access_time,
                      size: 10, color: Colors.grey[600]),
                  title: Text(activity["title"]!,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 12 : 14)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activity["description"]!,
                          style: TextStyle(fontSize: isMobile ? 9 : 11)),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.person, size: 10, color: Colors.grey[600]),
                          SizedBox(width: 2),
                          Text(
                            activity["user"]!,
                            style: TextStyle(
                              fontSize: isMobile ? 8 : 10,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(width: 7),
                          Icon(Icons.access_time,
                              size: 10, color: Colors.grey[600]),
                          SizedBox(width: 2),
                          Text(activity["timestamp"]!,
                              style: TextStyle(
                                  fontSize: isMobile ? 8 : 10,
                                  color: Colors.grey[700])),
                        ],
                      ),
                    ],
                  ),
                  trailing: Chip(
                    backgroundColor: c!.withOpacity(0.15),
                    label: Text(
                      activity["status"] == "success"
                          ? "Terminé"
                          : activity["status"] == "pending"
                              ? "En cours"
                              : "Erreur",
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
                  onPressed: () {},
                  child: Text("Voir l'historique complet",
                      style: TextStyle(fontSize: isMobile ? 11 : 13)),
                ),
              ),
          ],
        ),
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

  // Matrice d'accès module/role
  static const Map<String, List<String>> moduleRoles = {
    'VENTES': [
      'Admin',
      'Magazinier',
      'Gestionnaire Commercial',
      'Commercial',
      'Caissier',
      'Caissière'
    ],
    'COLLECTE': ['Admin', 'Collecteur'],
    'CONTRÔLE': ['Admin', 'Contrôleur', 'Controlleur'],
    'EXTRACTION': ['Admin', 'Extracteur'],
    'FILTRAGE': ['Admin', 'Filtreur'],
    'CONDITIONNEMENT': ['Admin', 'Conditionneur'],
    'GESTION DE VENTES': [
      'Admin',
      'Magazinier',
      'Gestionnaire Commercial',
      'Commercial'
    ],
    'RAPPORTS': ['Admin'],
  };

  List<Map<String, dynamic>> filterModulesByUser(
      List<Map<String, dynamic>> modules, UserSession user) {
    String site = user.site ?? '';
    final role = user.role ?? '';
    // Correction : normalise la casse du site pour la clé
    if (site.isNotEmpty) {
      site = site[0].toUpperCase() + site.substring(1).toLowerCase();
    }
    // Si admin, accès à tout
    if (role.toLowerCase() == 'admin') return modules;
    // Vérifier accès site
    final allowedRoles = siteRoles[site] ?? [];
    if (allowedRoles.contains('Tout') ||
        allowedRoles.contains(role) ||
        allowedRoles.contains(role + 'e')) {
      // Filtrer modules selon le rôle
      return modules.where((m) {
        final allowed = moduleRoles[m['name']] ?? [];
        return allowed.contains(role) ||
            allowed.contains(role + 'e') ||
            allowed.contains('Admin');
      }).toList();
    }
    // Aucun accès si le site ne correspond pas
    return [];
  }

  @override
  Widget build(BuildContext context) {
    // Correction : s'assure que UserSession est bien enregistré dans GetX
    UserSession user;
    try {
      user = Get.find<UserSession>();
    } catch (_) {
      user = Get.put(UserSession());
    }
    final modules = [
      {
        "icon": Icons.trending_up,
        "name": "VENTES",
        "badge": 8,
        "subModules": [
          {"name": "Nouvelle vente"},
          {"name": "Ventes en cours", "badge": 5},
          {"name": "Crédit/Recouvrement", "badge": 3},
          {"name": "Historique ventes"}
        ]
      },
      {
        "icon": Icons.nature,
        "name": "COLLECTE",
        "badge": 5,
        "subModules": [
          {"name": "Nouvelle collecte"},
          {"name": "Récoltes", "badge": 3},
          {"name": "Achats SCOOPS"},
          {"name": "Achats Individuels", "badge": 2}
        ]
      },
      {
        "icon": Icons.security,
        "name": "CONTRÔLE",
        "badge": 5,
        "subModules": [
          {"name": "Contrôles en attente", "badge": 7},
          {"name": "Nouveau contrôle"},
          {"name": "Historique contrôles"}
        ]
      },
      {
        "icon": Icons.bar_chart,
        "name": "RAPPORTS",
      },
      {
        "icon": Icons.layers,
        "name": "EXTRACTION",
        "subModules": [
          {"name": "Nouvelle extraction"},
          {"name": "Lots en cours", "badge": 4},
          {"name": "Extractions terminées"}
        ]
      },
      {
        "name": "FILTRAGE",
        "icon": Icons.filter_alt,
        "subModules": [
          {"name": "Nouveau filtrage"},
          {"name": "En cours de filtrage", "badge": 2},
          {"name": "Filtrage terminé"}
        ]
      },
      {
        "name": "CONDITIONNEMENT",
        "icon": Icons.all_inbox,
        "subModules": [
          {"name": "Nouveau conditionnement"},
          {"name": "Lots disponibles", "badge": 12},
          {"name": "Stock conditionné"}
        ]
      },
      {
        "name": "GESTION DE VENTES",
        "icon": Icons.trending_up,
        "subModules": [
          {"name": "Prélèvements"},
          {"name": "Attribution commerciaux"},
          {"name": "Suivi distributions", "badge": 3}
        ]
      },
    ];
    final filteredModules = filterModulesByUser(modules, user);
    return Material(
      elevation: isDesktop ? 0 : 10,
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            if (!isDesktop)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: kHighlightColor.withOpacity(0.17),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Modules",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(Icons.close, size: 18),
                      onPressed: onToggle,
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: filteredModules.map((module) {
                  return ExpansionTile(
                    leading: Icon(module["icon"] as IconData,
                        color: kHighlightColor),
                    title: Text(module["name"] as String,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: (module["badge"] as int? ?? 0) > 0
                        ? CircleAvatar(
                            radius: 12,
                            backgroundColor: kHighlightColor.withOpacity(0.2),
                            child: Text((module["badge"] as int).toString(),
                                style: TextStyle(
                                    color: kHighlightColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          )
                        : null,
                    children:
                        (module["subModules"] as List<Map<String, dynamic>>? ??
                                [])
                            .map((sub) {
                      return ListTile(
                        onTap: () => onModuleSelected?.call(
                            module["name"] as String,
                            subModule: sub["name"] as String?),
                        title: Text(sub["name"] as String,
                            style: TextStyle(fontSize: 13)),
                        trailing: (sub["badge"] as int? ?? 0) > 0
                            ? CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.green.withOpacity(0.2),
                                child: Text((sub["badge"] as int).toString(),
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              )
                            : null,
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
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
