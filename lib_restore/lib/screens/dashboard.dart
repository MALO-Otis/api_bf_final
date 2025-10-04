import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DateTime _currentTime;
  late final timer;
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  String _selectedChart = 'line';
  Map<String, bool> _openSections = {
    'collecte': true,
    'controle': false,
    'extraction': false,
    'filtrage': false,
    'conditionnement': false,
    'gestion': false,
    'ventes': true,
    // 'rapports': false, // module rapports supprimé
  };

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    timer = Stream.periodic(const Duration(seconds: 1)).listen((_) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String formatDate(DateTime date) {
    return DateFormat.yMMMMEEEEd('fr_FR').format(date);
  }

  String formatTime(DateTime date) {
    return DateFormat.Hms('fr_FR').format(date);
  }

  // --- Données statiques pour le dashboard ---
  final List<Map<String, dynamic>> kpis = [
    {
      'title': 'Ventes',
      'value': '€47,328',
      'change': '+12.3%',
      'icon': Icons.shopping_cart,
      'color': Colors.orange,
      'description': 'Ce mois',
    },
    {
      'title': 'Collecte',
      'value': '2,847 kg',
      'change': '+8.7%',
      'icon': Icons.science,
      'color': Colors.green,
      'description': 'Cette semaine',
    },
    {
      'title': 'Stock',
      'value': '12,394 kg',
      'change': '-2.1%',
      'icon': Icons.inventory,
      'color': Colors.amber,
      'description': 'Total disponible',
    },
    {
      'title': 'Crédits',
      'value': '€8,921',
      'change': '+5.4%',
      'icon': Icons.credit_card,
      'color': Colors.red,
      'description': 'À recouvrer',
    },
  ];

  final List<Map<String, dynamic>> alerts = [
    {
      'type': 'warning',
      'title': 'Stock faible',
      'message': "Miel d'acacia: seulement 45kg restants",
      'time': 'Il y a 2h',
      'icon': Icons.warning_amber_rounded,
      'color': Colors.orange,
    },
    {
      'type': 'destructive',
      'title': 'Crédit en retard',
      'message': 'Client Dupont - Échéance dépassée de 15 jours',
      'time': 'Il y a 3h',
      'icon': Icons.error_outline,
      'color': Colors.red,
    },
    {
      'type': 'success',
      'title': 'Nouvelle commande',
      'message': 'Commande #3452 - 150kg miel toutes fleurs',
      'time': 'Il y a 5h',
      'icon': Icons.check_circle_outline,
      'color': Colors.green,
    },
  ];

  final List<Map<String, String>> recentActivity = [
    {
      'action': 'Collecte SCOOP - Rucher des Pins',
      'time': '09:15',
      'user': 'Marie D.'
    },
    {
      'action': 'Validation contrôle qualité - Lot #A240801',
      'time': '08:42',
      'user': 'Jean M.'
    },
    {
      'action': 'Nouveau conditionnement - 500 pots 250g',
      'time': '08:15',
      'user': 'Sarah L.'
    },
    {
      'action': 'Vente comptoir - Client particulier',
      'time': '07:58',
      'user': 'Pierre R.'
    },
    {
      'action': 'Extraction terminée - Lot #E240731',
      'time': '07:30',
      'user': 'Antoine B.'
    },
  ];

  final List<Map<String, dynamic>> navigationModules = [
    {
      'key': 'collecte',
      'title': 'COLLECTE',
      'icon': Icons.science,
      'badge': 3,
      'subItems': [
        {'name': 'Nouvelle collecte', 'active': false},
        {'name': 'Récoltes', 'active': true},
        {'name': 'Achats SCOOPS', 'active': false},
        {'name': 'Achats Individuels', 'active': false},
      ],
    },
    {
      'key': 'controle',
      'title': 'CONTRÔLE',
      'icon': Icons.check_circle_outline,
      'badge': 8,
      'subItems': [
        {'name': 'Contrôles en attente', 'active': false},
        {'name': 'Nouveau contrôle', 'active': false},
        {'name': 'Historique contrôles', 'active': false},
      ],
    },
    {
      'key': 'extraction',
      'title': 'EXTRACTION',
      'icon': Icons.show_chart,
      'badge': 0,
      'subItems': [
        {'name': 'Nouvelle extraction', 'active': false},
        {'name': 'Lots en cours', 'active': false},
        {'name': 'Extractions terminées', 'active': false},
      ],
    },
    {
      'key': 'filtrage',
      'title': 'FILTRAGE',
      'icon': Icons.filter_alt,
      'badge': 2,
      'subItems': [
        {'name': 'Nouveau filtrage', 'active': false},
        {'name': 'En cours de filtrage', 'active': false},
        {'name': 'Filtrage terminé', 'active': false},
      ],
    },
    {
      'key': 'conditionnement',
      'title': 'CONDITIONNEMENT',
      'icon': Icons.inventory,
      'badge': 5,
      'subItems': [
        {'name': 'Nouveau conditionnement', 'active': false},
        {'name': 'Lots disponibles', 'active': false},
        {'name': 'Stock conditionné', 'active': false},
      ],
    },
    {
      'key': 'gestion',
      'title': 'GESTION DE VENTES',
      'icon': Icons.trending_up,
      'badge': 12,
      'subItems': [
        {'name': 'Prélèvements', 'active': false},
        {'name': 'Attribution commerciaux', 'active': false},
        {'name': 'Suivi distributions', 'active': false},
      ],
    },
    // Module RAPPORTS retiré du sidebar
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 900;
            return Row(
              children: [
                if (isDesktop) _buildSidebar(context, isDesktop),
                Expanded(
                  child: Column(
                    children: [
                      _buildHeader(context),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildKpiSection(),
                              const SizedBox(height: 32),
                              _buildChartsSection(),
                              const SizedBox(height: 32),
                              _buildAlertsSection(),
                              const SizedBox(height: 32),
                              _buildActivitySection(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: const Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/logo/logo.jpeg',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Apisavana',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Dashboard Administrateur',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatDate(_currentTime),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    formatTime(_currentTime),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, bool isDesktop) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: const Border(left: BorderSide(color: Color(0xFFE0E0E0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(-2, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un module...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
              onChanged: (v) => setState(() => _searchTerm = v),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: navigationModules
                  .where((module) =>
                      module['title']
                          .toLowerCase()
                          .contains(_searchTerm.toLowerCase()) ||
                      (module['subItems'] as List).any((item) => item['name']
                          .toLowerCase()
                          .contains(_searchTerm.toLowerCase())))
                  .map((module) => _buildSidebarModule(module))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarModule(Map<String, dynamic> module) {
    final isOpen = _openSections[module['key']] ?? false;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      elevation: isOpen ? 4 : 1,
      child: ExpansionTile(
        leading: Icon(module['icon'], color: Colors.orange),
        title: Row(
          children: [
            Expanded(
                child: Text(module['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold))),
            if (module['badge'] > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${module['badge']}',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
          ],
        ),
        initiallyExpanded: isOpen,
        onExpansionChanged: (open) {
          setState(() {
            _openSections[module['key']] = open;
          });
        },
        children: [
          ...((module['subItems'] as List).map((item) => ListTile(
                title: Text(item['name'],
                    style: TextStyle(
                        fontWeight: item['active']
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: item['active'] ? Colors.orange : null)),
                dense: true,
                contentPadding: const EdgeInsets.only(left: 32, right: 8),
                onTap: () {},
              ))),
        ],
      ),
    );
  }

  Widget _buildKpiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Indicateurs Clés',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: kpis
                  .map((kpi) => Container(
                        width: isWide
                            ? (constraints.maxWidth / 4) - 16
                            : constraints.maxWidth,
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(kpi['icon'],
                                        color: kpi['color'], size: 32),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: kpi['color'],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(kpi['change'],
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(kpi['value'],
                                    style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(kpi['title'],
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(height: 2),
                                Text(kpi['description'],
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildChartsSection() {
    // Placeholder graphique, à remplacer par un vrai graphique si besoin
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Analyses Graphiques',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Row(
              children: [
                _buildChartTypeButton('line', Icons.show_chart, 'Ligne'),
                const SizedBox(width: 8),
                _buildChartTypeButton('bar', Icons.bar_chart, 'Histogramme'),
                const SizedBox(width: 8),
                _buildChartTypeButton('pie', Icons.pie_chart, 'Cercle'),
                const SizedBox(width: 8),
                _buildChartTypeButton('area', Icons.area_chart, 'Aires'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            height: 220,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, size: 64, color: Colors.orange),
                const SizedBox(height: 8),
                Text(
                    'Graphique ${_selectedChart == 'line' ? 'Ligne' : _selectedChart == 'bar' ? 'Histogramme' : _selectedChart == 'pie' ? 'Cercle' : 'Aires'}',
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 4),
                const Text('Données dynamiques en temps réel',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartTypeButton(String key, IconData icon, String label) {
    final isSelected = _selectedChart == key;
    return OutlinedButton.icon(
      onPressed: () => setState(() => _selectedChart = key),
      icon: Icon(icon,
          color: isSelected ? Colors.white : Colors.orange, size: 18),
      label: Text(label,
          style: TextStyle(color: isSelected ? Colors.white : Colors.orange)),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? Colors.orange : Colors.white,
        side: BorderSide(color: Colors.orange),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Alertes & Notifications',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Column(
          children: alerts
              .map((alert) => Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading:
                          Icon(alert['icon'], color: alert['color'], size: 32),
                      title: Text(alert['title'],
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(alert['message']),
                          Text(alert['time'],
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      trailing: Icon(Icons.open_in_new, color: Colors.orange),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Activité Récente',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: recentActivity
                  .map((activity) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(activity['action'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500))),
                            Text(activity['user'] ?? '',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            const SizedBox(width: 12),
                            Text(activity['time'] ?? '',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
