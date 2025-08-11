import 'package:flutter/material.dart';
import '../../../../data/models/collecte_models.dart';

class SectionResume extends StatelessWidget {
  final List<ContenantModel> contenants;
  final double poidsTotal;
  final double montantTotal;

  const SectionResume({
    Key? key,
    required this.contenants,
    required this.poidsTotal,
    required this.montantTotal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1100),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 50),
          child: Opacity(
            opacity: value,
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                ),
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête de la section
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.summarize,
                            color: Colors.blue.shade600,
                            size: isSmallScreen ? 20 : 24,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 10 : 12),
                        Text(
                          'Résumé de la collecte',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 20),

                    // Statistiques principales
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            Icons.inventory,
                            'Contenants',
                            contenants.isEmpty ? '0' : '${contenants.length}',
                            Colors.orange,
                            isSmallScreen,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Expanded(
                          child: _buildStatCard(
                            Icons.scale,
                            'Poids total',
                            poidsTotal <= 0
                                ? '0.0 kg'
                                : '${poidsTotal.toStringAsFixed(1)} kg',
                            Colors.green,
                            isSmallScreen,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Expanded(
                          child: _buildStatCard(
                            Icons.attach_money,
                            'Montant',
                            montantTotal <= 0
                                ? '0 F'
                                : '${montantTotal.toStringAsFixed(0)} F',
                            Colors.blue,
                            isSmallScreen,
                          ),
                        ),
                      ],
                    ),

                    // Détails des contenants (si présents)
                    if (contenants.isNotEmpty) ...[
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(isSmallScreen ? 8 : 10),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Détails des contenants',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 10),
                            ...contenants.asMap().entries.map((entry) {
                              final index = entry.key;
                              final contenant = entry.value;
                              final sousTotal =
                                  contenant.quantite * contenant.prixUnitaire;

                              return Container(
                                margin: EdgeInsets.only(
                                    bottom: isSmallScreen ? 6 : 8),
                                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isSmallScreen ? 6 : 8,
                                            vertical: isSmallScreen ? 2 : 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade100,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Contenant ${index + 1}',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 10 : 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${sousTotal.toStringAsFixed(0)} FCFA',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 12 : 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: isSmallScreen ? 4 : 6),
                                    Text(
                                      '${contenant.typeMiel} • ${contenant.typeRuche} • ${contenant.quantite} kg × ${contenant.prixUnitaire.toStringAsFixed(0)} FCFA/kg',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 11 : 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    if (contenant
                                        .predominanceFlorale.isNotEmpty) ...[
                                      SizedBox(height: isSmallScreen ? 2 : 3),
                                      Text(
                                        'Prédominance: ${contenant.predominanceFlorale}',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 10 : 11,
                                          color: Colors.orange.shade600,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],

                    // Message si aucun contenant
                    if (contenants.isEmpty) ...[
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius:
                              BorderRadius.circular(isSmallScreen ? 8 : 10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: isSmallScreen ? 32 : 40,
                              color: Colors.grey.shade500,
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 10),
                            Text(
                              'Aucun contenant ajouté',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 4 : 6),
                            Text(
                              'Ajoutez des contenants pour voir le résumé de votre collecte',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 13,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value,
      MaterialColor color, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color.shade600,
            size: isSmallScreen ? 18 : 22,
          ),
          SizedBox(height: isSmallScreen ? 4 : 6),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 11,
              color: color.shade700,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 2 : 3),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: color.shade800,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
