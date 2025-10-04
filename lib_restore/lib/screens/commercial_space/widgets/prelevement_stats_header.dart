import 'package:flutter/material.dart';
import '../../vente/models/vente_models.dart';

/// 📊 HEADER AVEC STATISTIQUES DES PRÉLÈVEMENTS
class PrelevementStatsHeader extends StatelessWidget {
  final List<Prelevement> prelevements;

  const PrelevementStatsHeader({
    super.key,
    required this.prelevements,
  });

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isExtraSmall = constraints.maxWidth < 480;
        final isSmall = constraints.maxWidth < 768;

        return Container(
          margin: EdgeInsets.all(isExtraSmall ? 16 : 20),
          padding: EdgeInsets.all(isExtraSmall ? 20 : 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header principal
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isExtraSmall ? 16 : 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '📋',
                      style: TextStyle(fontSize: isExtraSmall ? 32 : 40),
                    ),
                  ),
                  SizedBox(width: isExtraSmall ? 16 : 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mes Prélèvements',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isExtraSmall ? 20 : 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: isExtraSmall ? 4 : 8),
                        Text(
                          '${prelevements.length} prélèvement${prelevements.length > 1 ? 's' : ''} au total',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: isExtraSmall ? 14 : 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: isExtraSmall ? 20 : 24),

              // Statistiques
              if (isExtraSmall)
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: _buildStatCard(
                                'En cours',
                                '${stats['enCours']}',
                                Icons.shopping_cart,
                                true)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildStatCard(
                                'Terminés',
                                '${stats['termines']}',
                                Icons.check_circle,
                                true)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _buildStatCard(
                                'Produits',
                                '${stats['produits']}',
                                Icons.inventory_2,
                                true)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildStatCard(
                                'Valeur',
                                '${(stats['valeur'] / 1000000).toStringAsFixed(1)}M',
                                Icons.monetization_on,
                                true)),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                        child: _buildStatCard('En cours', '${stats['enCours']}',
                            Icons.shopping_cart, false)),
                    SizedBox(width: isSmall ? 12 : 16),
                    Expanded(
                        child: _buildStatCard('Terminés',
                            '${stats['termines']}', Icons.check_circle, false)),
                    SizedBox(width: isSmall ? 12 : 16),
                    Expanded(
                        child: _buildStatCard('Produits',
                            '${stats['produits']}', Icons.inventory_2, false)),
                    SizedBox(width: isSmall ? 12 : 16),
                    Expanded(
                        child: _buildStatCard(
                            'Valeur Total',
                            '${(stats['valeur'] / 1000000).toStringAsFixed(1)}M FCFA',
                            Icons.monetization_on,
                            false)),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: isCompact ? 20 : 24),
          SizedBox(height: isCompact ? 6 : 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isCompact ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: isCompact ? 10 : 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateStats() {
    final enCours =
        prelevements.where((p) => p.statut == StatutPrelevement.enCours).length;
    final termines =
        prelevements.where((p) => p.statut == StatutPrelevement.termine).length;
    final produits =
        prelevements.fold<int>(0, (sum, p) => sum + p.produits.length);
    final valeur =
        prelevements.fold<double>(0.0, (sum, p) => sum + p.valeurTotale);

    return {
      'enCours': enCours,
      'termines': termines,
      'produits': produits,
      'valeur': valeur,
    };
  }
}
