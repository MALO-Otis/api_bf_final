/// 📊 ONGLET STATISTIQUES SIMPLIFIÉ
///
/// Version robuste sans complexité GetX pour éviter les erreurs

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/commercial_models.dart';
import '../services/commercial_service.dart';

class StatistiquesSimple extends StatefulWidget {
  final CommercialService commercialService;

  const StatistiquesSimple({
    super.key,
    required this.commercialService,
  });

  @override
  State<StatistiquesSimple> createState() => _StatistiquesSimpleState();
}

class _StatistiquesSimpleState extends State<StatistiquesSimple> {
  bool _isLoading = true;
  String _errorMessage = '';
  StatistiquesCommerciales? _statistiques;

  @override
  void initState() {
    super.initState();
    _loadStatistiques();
  }

  Future<void> _loadStatistiques() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // 🔧 CORRECTION : Rafraîchir les données avant de calculer les statistiques
      await widget.commercialService.rafraichirDonnees();
      final stats = await widget.commercialService.calculerStatistiques();

      if (mounted) {
        setState(() {
          _statistiques = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement statistiques: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur de chargement des statistiques';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingView();
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorView();
    }

    if (_statistiques == null) {
      return _buildEmptyView();
    }

    return _buildStatisticsView();
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
          ),
          SizedBox(height: 16),
          Text(
            'Chargement des statistiques...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadStatistiques,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Aucune statistique disponible',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Métriques principales
          _buildMetriquesSection(),
          const SizedBox(height: 24),

          // Répartition par sites
          _buildSitesSection(),
          const SizedBox(height: 24),

          // Performance des commerciaux
          _buildCommerciauxSection(),
        ],
      ),
    );
  }

  Widget _buildMetriquesSection() {
    final stats = _statistiques!;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Color(0xFF4CAF50)),
                SizedBox(width: 8),
                Text(
                  'Métriques Principales',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetriqueItem(
                    'Lots Disponibles',
                    '${stats.nombreLots}',
                    Icons.inventory,
                    const Color(0xFF2196F3),
                  ),
                ),
                Expanded(
                  child: _buildMetriqueItem(
                    'Attributions',
                    '${stats.nombreAttributions}',
                    Icons.assignment,
                    const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetriqueItem(
                    'Valeur Stock',
                    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA')
                        .format(stats.valeurTotaleStock),
                    Icons.account_balance_wallet,
                    const Color(0xFFFF9800),
                  ),
                ),
                Expanded(
                  child: _buildMetriqueItem(
                    'Taux Attribution',
                    '${stats.tauxAttribution.toStringAsFixed(1)}%',
                    Icons.trending_up,
                    const Color(0xFF9C27B0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetriqueItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSitesSection() {
    final stats = _statistiques!;

    if (stats.repartitionSites.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on, color: Color(0xFF4CAF50)),
                SizedBox(width: 8),
                Text(
                  'Répartition par Sites',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...stats.repartitionSites.entries.map((entry) {
              final site = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            site.site,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${site.nombreLots} lots',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA')
                              .format(site.valeurStock),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        Text(
                          '${site.tauxAttribution.toStringAsFixed(1)}% attribué',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCommerciauxSection() {
    final stats = _statistiques!;

    if (stats.performancesCommerciaux.isEmpty) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.person, color: Color(0xFF4CAF50)),
                  SizedBox(width: 8),
                  Text(
                    'Performance des Commerciaux',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune attribution commerciale pour le moment',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, color: Color(0xFF4CAF50)),
                SizedBox(width: 8),
                Text(
                  'Performance des Commerciaux',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...stats.performancesCommerciaux.entries.map((entry) {
              final commercial = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF4CAF50).withOpacity(0.2),
                      child: Text(
                        commercial.commercialNom.isNotEmpty
                            ? commercial.commercialNom[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            commercial.commercialNom,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${commercial.nombreAttributions} attributions',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA')
                          .format(commercial.valeurTotaleAttribuee),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
