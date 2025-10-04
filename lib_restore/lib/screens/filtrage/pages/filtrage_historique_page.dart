/// 📊 PAGE D'HISTORIQUE DES FILTRAGES
///
/// Affiche tous les filtrages effectués avec leurs statistiques

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../utils/smart_appbar.dart';
import '../services/filtrage_historique_service.dart';

class FiltrageHistoriquePage extends StatefulWidget {
  const FiltrageHistoriquePage({super.key});

  @override
  State<FiltrageHistoriquePage> createState() => _FiltrageHistoriquePageState();
}

class _FiltrageHistoriquePageState extends State<FiltrageHistoriquePage> {
  final FiltrageHistoriqueService _service = FiltrageHistoriqueService();

  Map<String, dynamic> _historiqueData = {};
  bool _isLoading = true;
  String? _siteFilter;

  @override
  void initState() {
    super.initState();
    _loadHistorique();
  }

  Future<void> _loadHistorique() async {
    setState(() => _isLoading = true);

    try {
      final data =
          await _service.getHistoriqueFiltrages(siteFilter: _siteFilter);
      setState(() {
        _historiqueData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar(
        'Erreur',
        'Impossible de charger l\'historique: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: SmartAppBar(
        title: "📊 Historique des Filtrages",
        backgroundColor: const Color(0xFF9C27B0),
        onBackPressed: () => Get.back(),
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
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9C27B0)),
          ),
          const SizedBox(height: 24),
          Text(
            'Chargement de l\'historique...',
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
    final filtrages =
        _historiqueData['filtrages'] as List<Map<String, dynamic>>? ?? [];
    final statistiques =
        _historiqueData['statistiques'] as Map<String, dynamic>? ?? {};

    return CustomScrollView(
      slivers: [
        // Header avec statistiques (sticky)
        SliverToBoxAdapter(
          child: _buildHeaderSection(statistiques, isMobile),
        ),

        // Filtre par site (sticky)
        SliverToBoxAdapter(
          child: _buildSiteFilter(isMobile),
        ),

        // Espacement
        const SliverToBoxAdapter(
          child: SizedBox(height: 16),
        ),

        // Liste des filtrages (scrollable)
        _buildFiltragesSliverList(filtrages, isMobile),
      ],
    );
  }

  Widget _buildHeaderSection(Map<String, dynamic> stats, bool isMobile) {
    return Container(
      margin: EdgeInsets.all(isMobile ? 16 : 24),
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Statistiques Globales',
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Filtrages',
                  (stats['totalFiltrages'] ?? 0).toString(),
                  Icons.filter_alt,
                  isMobile,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: _buildStatCard(
                  'Produits Filtrés',
                  (stats['totalProduitsFiltrés'] ?? 0).toString(),
                  Icons.inventory,
                  isMobile,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: _buildStatCard(
                  'Quantité Filtrée',
                  '${(stats['quantiteTotaleFiltree'] ?? 0.0).toStringAsFixed(1)} kg',
                  Icons.scale,
                  isMobile,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: _buildStatCard(
                  'Rendement Moyen',
                  '${(stats['rendementMoyen'] ?? 0.0).toStringAsFixed(1)}%',
                  Icons.trending_up,
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
      String title, String value, IconData icon, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: isMobile ? 20 : 24),
          SizedBox(height: isMobile ? 4 : 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 12 : 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isMobile ? 8 : 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSiteFilter(bool isMobile) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      child: DropdownButtonFormField<String?>(
        value: _siteFilter,
        decoration: InputDecoration(
          labelText: 'Filtrer par site',
          prefixIcon: const Icon(Icons.location_on),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('Tous les sites'),
          ),
          ...[
            'Koudougou',
            'Ouagadougou',
            'Bobo-Dioulasso',
            'Mangodara',
            'Bagre',
            'Pô'
          ].map((site) => DropdownMenuItem<String?>(
                value: site,
                child: Text(site),
              )),
        ],
        onChanged: (value) {
          setState(() {
            _siteFilter = value;
          });
          _loadHistorique();
        },
      ),
    );
  }

  Widget _buildFiltragesSliverList(
      List<Map<String, dynamic>> filtrages, bool isMobile) {
    if (filtrages.isEmpty) {
      return SliverFillRemaining(
        child: Center(
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
                'Aucun filtrage trouvé',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_siteFilter != null) ...[
                const SizedBox(height: 8),
                Text(
                  'pour le site $_siteFilter',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final filtrage = filtrages[index];
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 600 + (index * 100)),
              tween: Tween(begin: 0, end: 1),
              builder: (context, animationValue, child) {
                return Transform.scale(
                  scale: animationValue,
                  child: _buildFiltrageCard(filtrage, isMobile),
                );
              },
            );
          },
          childCount: filtrages.length,
        ),
      ),
    );
  }

  Widget _buildFiltragesList(
      List<Map<String, dynamic>> filtrages, bool isMobile) {
    if (filtrages.isEmpty) {
      return Center(
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
              'Aucun filtrage trouvé',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_siteFilter != null) ...[
              const SizedBox(height: 8),
              Text(
                'pour le site $_siteFilter',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      itemCount: filtrages.length,
      itemBuilder: (context, index) {
        final filtrage = filtrages[index];
        return _buildFiltrageCard(filtrage, isMobile);
      },
    );
  }

  Widget _buildFiltrageCard(Map<String, dynamic> filtrage, bool isMobile) {
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');
    final dateFiltrage = filtrage['dateFiltrage'] as DateTime;
    final produits = filtrage['produitsFiltres'] as List;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header du filtrage
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade50, Colors.purple.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '🧪',
                    style: TextStyle(fontSize: isMobile ? 20 : 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        filtrage['numeroLot'] as String,
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${filtrage['site']} • ${dateFormat.format(dateFiltrage)}',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    filtrage['statut'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenu du filtrage
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              children: [
                // Métriques principales
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'Quantité reçue',
                        '${(filtrage['quantiteTotale'] as double).toStringAsFixed(1)} kg',
                        Colors.blue,
                        isMobile,
                      ),
                    ),
                    Container(
                        width: 1, height: 30, color: Colors.grey.shade300),
                    Expanded(
                      child: _buildMetricItem(
                        'Quantité filtrée',
                        '${(filtrage['quantiteFiltree'] as double).toStringAsFixed(1)} kg',
                        Colors.green,
                        isMobile,
                      ),
                    ),
                    Container(
                        width: 1, height: 30, color: Colors.grey.shade300),
                    Expanded(
                      child: _buildMetricItem(
                        'Rendement',
                        '${(filtrage['rendementFiltrage'] as double).toStringAsFixed(1)}%',
                        Colors.orange,
                        isMobile,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Informations complémentaires
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Technologie',
                        filtrage['technologie'] as String,
                        Icons.build,
                        isMobile,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        'Produits traités',
                        '${filtrage['nombreProduits']} produits',
                        Icons.inventory,
                        isMobile,
                      ),
                    ),
                  ],
                ),

                if ((filtrage['observations'] as String).isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.notes,
                                size: 16, color: Colors.blue.shade600),
                            const SizedBox(width: 8),
                            Text(
                              'Observations',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          filtrage['observations'] as String,
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Liste des produits filtrés
                ExpansionTile(
                  title: Text(
                    'Produits filtrés (${produits.length})',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  leading: const Icon(Icons.list_alt),
                  children: produits.map<Widget>((produit) {
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.purple.shade100,
                        child: Text(
                          '📦',
                          style: TextStyle(fontSize: isMobile ? 12 : 14),
                        ),
                      ),
                      title: Text(
                        produit['codeContenant'] as String,
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${produit['producteur']} • ${(produit['quantiteFiltree'] as double).toStringAsFixed(1)} kg',
                        style: TextStyle(fontSize: isMobile ? 10 : 12),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(produit['rendementProduit'] as double).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: isMobile ? 10 : 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
      String label, String value, Color color, bool isMobile) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 10 : 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoItem(
      String label, String value, IconData icon, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: isMobile ? 14 : 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 10 : 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}
