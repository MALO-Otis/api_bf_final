import 'package:flutter/material.dart';
import '../../../../data/models/collecte_models.dart';
import 'contenant_card.dart';

class SectionContenants extends StatelessWidget {
  final List<ContenantModel> contenants;
  final VoidCallback onAjouterContenant;
  final Function(int) onSupprimerContenant;
  final Function(int, ContenantModel) onModifierContenant;

  const SectionContenants({
    Key? key,
    required this.contenants,
    required this.onAjouterContenant,
    required this.onSupprimerContenant,
    required this.onModifierContenant,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 30),
          child: Opacity(
            opacity: value,
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.inventory,
                            color: Colors.orange[600],
                            size: isSmallScreen ? 18 : 22,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Text(
                          'Contenants (${contenants.length})',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: onAjouterContenant,
                            icon: Icon(
                              Icons.add_circle,
                              color: Colors.green[600],
                              size: isSmallScreen ? 24 : 28,
                            ),
                            tooltip: 'Ajouter un contenant',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    ...contenants.asMap().entries.map((entry) {
                      final index = entry.key;
                      final contenant = entry.value;
                      return ContenantCard(
                        index: index,
                        contenant: contenant,
                        onSupprimer: contenants.length > 1
                            ? () => onSupprimerContenant(index)
                            : null,
                        onContenantModified: (nouveauContenant) =>
                            onModifierContenant(index, nouveauContenant),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
