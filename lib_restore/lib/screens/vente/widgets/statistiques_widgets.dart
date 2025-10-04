/// 📊 WIDGETS SPÉCIALISÉS POUR LES STATISTIQUES
///
/// Collection de widgets pour afficher les données analytiques avec graphiques
/// Optimisé pour les performances et la responsivité mobile

import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../models/commercial_models.dart';

// ============================================================================
// 📋 WIDGET MÉTRIQUE PRINCIPALE
// ============================================================================

class MetriqueCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool compact;
  final VoidCallback? onTap;

  const MetriqueCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(compact ? 16 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(compact ? 8 : 12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: compact ? 18 : 24,
                  ),
                ),
                if (onTap != null) ...[
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: color.withOpacity(0.5),
                    size: 14,
                  ),
                ],
              ],
            ),
            SizedBox(height: compact ? 12 : 16),
            Text(
              value,
              style: TextStyle(
                fontSize: compact ? 20 : 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: compact ? 12 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: compact ? 10 : 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 👥 PERFORMANCES DES COMMERCIAUX
// ============================================================================

class PerformancesCommerciaux extends StatelessWidget {
  final Map<String, StatistiquesCommercial> performancesCommerciaux;

  const PerformancesCommerciaux({
    super.key,
    required this.performancesCommerciaux,
  });

  @override
  Widget build(BuildContext context) {
    if (performancesCommerciaux.isEmpty) {
      return _buildEmptyState();
    }

    // Trier par performance décroissante
    final commerciauxTries = performancesCommerciaux.values.toList()
      ..sort(
          (a, b) => b.valeurTotaleAttribuee.compareTo(a.valeurTotaleAttribuee));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: commerciauxTries.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSummaryHeader(commerciauxTries);
        }

        final commercial = commerciauxTries[index - 1];
        final rank = index;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildCommercialCard(commercial, rank),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun commercial avec attribution',
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

  Widget _buildSummaryHeader(List<StatistiquesCommercial> commerciaux) {
    final totalAttributions =
        commerciaux.fold<int>(0, (sum, c) => sum + c.nombreAttributions);
    final totalValeur =
        commerciaux.fold<double>(0, (sum, c) => sum + c.valeurTotaleAttribuee);
    final meilleurCommercial =
        commerciaux.isNotEmpty ? commerciaux.first : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏆 Tableau de Performance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Commerciaux actifs',
                  '${commerciaux.length}',
                  Icons.people,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Total attributions',
                  '$totalAttributions',
                  Icons.assignment,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Valeur attribuée',
                  CommercialUtils.formatPrix(totalValeur),
                  Icons.monetization_on,
                ),
              ),
            ],
          ),
          if (meilleurCommercial != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Meilleur commercial: ${meilleurCommercial.commercialNom}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCommercialCard(StatistiquesCommercial commercial, int rank) {
    final score = CommercialUtils.calculerScorePerformance(commercial);
    final couleurPerf = CommercialUtils.getCouleurPerformance(score);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Classement
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getRankColor(rank),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Avatar et nom
                CircleAvatar(
                  radius: 20,
                  backgroundColor: couleurPerf.withOpacity(0.1),
                  child: Text(
                    commercial.commercialNom.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: couleurPerf,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Score: ${score.toStringAsFixed(1)}/100',
                        style: TextStyle(
                          color: couleurPerf,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Badge performance
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: couleurPerf,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getPerformanceLabel(score),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Métriques détaillées
            Row(
              children: [
                Expanded(
                  child: _buildMetriqueItem(
                    'Attributions',
                    '${commercial.nombreAttributions}',
                    Icons.assignment_turned_in,
                    const Color(0xFF2196F3),
                  ),
                ),
                Expanded(
                  child: _buildMetriqueItem(
                    'Valeur attribuée',
                    '${(commercial.valeurTotaleAttribuee / 1000000).toStringAsFixed(1)}M',
                    Icons.monetization_on,
                    const Color(0xFF4CAF50),
                  ),
                ),
                Expanded(
                  child: _buildMetriqueItem(
                    'Taux conversion',
                    '${commercial.tauxConversion.toStringAsFixed(1)}%',
                    Icons.trending_up,
                    couleurPerf,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Barre de progression performance
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Performance globale',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${score.toStringAsFixed(1)}/100',
                      style: TextStyle(
                        fontSize: 12,
                        color: couleurPerf,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: score / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(couleurPerf),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Or
      case 2:
        return const Color(0xFFC0C0C0); // Argent
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey.shade600;
    }
  }

  String _getPerformanceLabel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Bon';
    if (score >= 40) return 'Moyen';
    return 'Faible';
  }

  Widget _buildMetriqueItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ============================================================================
// 🗺️ RÉPARTITION PAR SITES
// ============================================================================

class RepartitionSites extends StatelessWidget {
  final Map<String, StatistiquesSite> repartitionSites;

  const RepartitionSites({
    super.key,
    required this.repartitionSites,
  });

  @override
  Widget build(BuildContext context) {
    if (repartitionSites.isEmpty) {
      return _buildEmptyState();
    }

    final sites = repartitionSites.values.toList()
      ..sort((a, b) => b.valeurStock.compareTo(a.valeurStock));

    final valeurTotale =
        sites.fold<double>(0, (sum, site) => sum + site.valeurStock);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sites.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSitesHeader(sites, valeurTotale);
        }

        final site = sites[index - 1];
        final pourcentage =
            valeurTotale > 0 ? (site.valeurStock / valeurTotale) * 100 : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildSiteCard(site, pourcentage),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun site avec données',
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

  Widget _buildSitesHeader(List<StatistiquesSite> sites, double valeurTotale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🗺️ Répartition Géographique',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSitesSummaryItem(
                  'Sites actifs',
                  '${sites.length}',
                  Icons.location_on,
                ),
              ),
              Expanded(
                child: _buildSitesSummaryItem(
                  'Lots totaux',
                  '${sites.fold<int>(0, (sum, site) => sum + site.nombreLots)}',
                  Icons.inventory,
                ),
              ),
              Expanded(
                child: _buildSitesSummaryItem(
                  'Valeur totale',
                  CommercialUtils.formatPrix(valeurTotale),
                  Icons.monetization_on,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSitesSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSiteCard(StatistiquesSite site, double pourcentage) {
    final couleur = _getSiteColor(site.site);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: couleur.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.location_on, color: couleur, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        site.site,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${pourcentage.toStringAsFixed(1)}% du total',
                        style: TextStyle(
                          color: couleur,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: couleur,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${site.nombreLots} lots',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Métriques détaillées
            Row(
              children: [
                Expanded(
                  child: _buildSiteMetrique(
                    'Valeur stock',
                    CommercialUtils.formatPrix(site.valeurStock),
                    Icons.inventory,
                    const Color(0xFF4CAF50),
                  ),
                ),
                Expanded(
                  child: _buildSiteMetrique(
                    'Valeur attribuée',
                    CommercialUtils.formatPrix(site.valeurAttribuee),
                    Icons.assignment,
                    const Color(0xFF9C27B0),
                  ),
                ),
                Expanded(
                  child: _buildSiteMetrique(
                    'Taux attribution',
                    '${site.tauxAttribution.toStringAsFixed(1)}%',
                    Icons.pie_chart,
                    couleur,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Barre de progression attribution
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progression attribution',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${site.tauxAttribution.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: couleur,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: site.tauxAttribution / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(couleur),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getSiteColor(String site) {
    // Couleurs associées aux sites
    const couleurs = [
      Color(0xFF2196F3),
      Color(0xFF4CAF50),
      Color(0xFFFF9800),
      Color(0xFF9C27B0),
      Color(0xFFF44336),
      Color(0xFF00BCD4),
    ];

    final index = site.hashCode % couleurs.length;
    return couleurs[index.abs()];
  }

  Widget _buildSiteMetrique(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ============================================================================
// 📦 RÉPARTITION DES PRODUITS
// ============================================================================

class RepartitionProduits extends StatelessWidget {
  final Map<String, StatistiquesEmballage> repartitionEmballages;
  final Map<String, StatistiquesFlorale> repartitionFlorale;

  const RepartitionProduits({
    super.key,
    required this.repartitionEmballages,
    required this.repartitionFlorale,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: Colors.purple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.purple,
            tabs: [
              Tab(text: 'Par Type d\'Emballage'),
              Tab(text: 'Par Prédominance Florale'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildEmballagesTab(),
                _buildFloraleTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmballagesTab() {
    if (repartitionEmballages.isEmpty) {
      return _buildEmptyState('Aucun emballage analysé');
    }

    final emballages = repartitionEmballages.values.toList()
      ..sort((a, b) => b.valeurStock.compareTo(a.valeurStock));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: emballages.length,
      itemBuilder: (context, index) {
        final emballage = emballages[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildEmballageCard(emballage),
        );
      },
    );
  }

  Widget _buildFloraleTab() {
    if (repartitionFlorale.isEmpty) {
      return _buildEmptyState('Aucune prédominance florale analysée');
    }

    final florales = repartitionFlorale.values.toList()
      ..sort((a, b) => b.valeurStock.compareTo(a.valeurStock));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: florales.length,
      itemBuilder: (context, index) {
        final florale = florales[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildFloraleCard(florale),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
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

  Widget _buildEmballageCard(StatistiquesEmballage emballage) {
    final couleur = const Color(0xFF2196F3);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  CommercialUtils.getEmojiEmballage(emballage.typeEmballage),
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emballage.typeEmballage,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${emballage.nombreLots} lots • ${emballage.quantiteStock} unités',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildProduitMetrique(
                    'Stock total',
                    '${emballage.quantiteStock}',
                    Icons.inventory,
                    const Color(0xFF4CAF50),
                  ),
                ),
                Expanded(
                  child: _buildProduitMetrique(
                    'Attribué',
                    '${emballage.quantiteAttribuee}',
                    Icons.assignment,
                    const Color(0xFF9C27B0),
                  ),
                ),
                Expanded(
                  child: _buildProduitMetrique(
                    'Valeur',
                    '${(emballage.valeurStock / 1000000).toStringAsFixed(1)}M',
                    Icons.monetization_on,
                    const Color(0xFFFF9800),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Barre de progression
            if (emballage.quantiteStock > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Attribution',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${((emballage.quantiteAttribuee / emballage.quantiteStock) * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: couleur,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value:
                        emballage.quantiteAttribuee / emballage.quantiteStock,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(couleur),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloraleCard(StatistiquesFlorale florale) {
    final couleur = _getFlowerColor(florale.predominance);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: couleur.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getFlowerEmoji(florale.predominance),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        florale.predominance,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${florale.nombreLots} lots différents',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildProduitMetrique(
                    'Valeur stock',
                    '${(florale.valeurStock / 1000000).toStringAsFixed(1)}M',
                    Icons.inventory,
                    const Color(0xFF4CAF50),
                  ),
                ),
                Expanded(
                  child: _buildProduitMetrique(
                    'Attribué',
                    '${(florale.valeurAttribuee / 1000000).toStringAsFixed(1)}M',
                    Icons.assignment,
                    const Color(0xFF9C27B0),
                  ),
                ),
                Expanded(
                  child: _buildProduitMetrique(
                    'Prix moyen',
                    CommercialUtils.formatPrix(florale.prixMoyenUnitaire),
                    Icons.local_offer,
                    couleur,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProduitMetrique(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getFlowerColor(String florale) {
    switch (florale.toLowerCase()) {
      case 'karité':
        return const Color(0xFF8BC34A);
      case 'néré':
        return const Color(0xFF795548);
      case 'acacia':
        return const Color(0xFFFFEB3B);
      case 'manguier':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF9C27B0);
    }
  }

  String _getFlowerEmoji(String florale) {
    switch (florale.toLowerCase()) {
      case 'karité':
        return '🌰';
      case 'néré':
        return '🌳';
      case 'acacia':
        return '🌿';
      case 'manguier':
        return '🥭';
      case 'eucalyptus':
        return '🌿';
      default:
        return '🌺';
    }
  }
}

// ============================================================================
// 📈 TENDANCES MENSUELLES
// ============================================================================

class TendancesMensuelles extends StatelessWidget {
  final List<TendanceMensuelle> tendances;
  final DateTime periodeDebut;
  final DateTime periodeFin;

  const TendancesMensuelles({
    super.key,
    required this.tendances,
    required this.periodeDebut,
    required this.periodeFin,
  });

  @override
  Widget build(BuildContext context) {
    if (tendances.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTendancesHeader(),
          const SizedBox(height: 20),
          _buildTendancesChart(),
          const SizedBox(height: 20),
          _buildTendancesList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Pas assez de données pour les tendances',
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

  Widget _buildTendancesHeader() {
    final totalAttributions =
        tendances.fold<int>(0, (sum, t) => sum + t.nombreAttributions);
    final totalValeur =
        tendances.fold<double>(0, (sum, t) => sum + t.valeurAttribuee);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFF7931E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📈 Évolution Temporelle',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTendancesSummaryItem(
                  'Période',
                  '${tendances.length} mois',
                  Icons.calendar_today,
                ),
              ),
              Expanded(
                child: _buildTendancesSummaryItem(
                  'Attributions',
                  '$totalAttributions',
                  Icons.assignment,
                ),
              ),
              Expanded(
                child: _buildTendancesSummaryItem(
                  'Valeur totale',
                  CommercialUtils.formatPrix(totalValeur),
                  Icons.monetization_on,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTendancesSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTendancesChart() {
    // Graphique simplifié avec des barres
    final maxValeur = tendances.isEmpty
        ? 1.0
        : tendances.map((t) => t.valeurAttribuee).reduce(math.max);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Évolution mensuelle des attributions',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: tendances.map((tendance) {
                final hauteur = maxValeur > 0
                    ? (tendance.valeurAttribuee / maxValeur) * 120
                    : 0.0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Valeur au-dessus de la barre
                        if (hauteur > 0)
                          Text(
                            '${(tendance.valeurAttribuee / 1000000).toStringAsFixed(1)}M',
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4CAF50),
                            ),
                          ),

                        const SizedBox(height: 4),

                        // Barre
                        Container(
                          height: hauteur,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Label mois
                        Text(
                          tendance.libelleMois,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTendancesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Détails par mois',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        ...tendances.map((tendance) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: _buildTendanceItem(tendance),
            )),
      ],
    );
  }

  Widget _buildTendanceItem(TendanceMensuelle tendance) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tendance.libelleMois,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${tendance.nombreAttributions} attributions',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    CommercialUtils.formatPrix(tendance.valeurAttribuee),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
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
