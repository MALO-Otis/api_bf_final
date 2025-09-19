import 'package:flutter/material.dart';

/// Widget custom pour afficher les messages d'erreur avec animation et liste des champs manquants
class SectionMessageErreur extends StatelessWidget {
  final String? errorMessage;
  final List<String> champsManquants;
  final Animation<double> shakeAnimation;

  const SectionMessageErreur({
    Key? key,
    required this.errorMessage,
    required this.champsManquants,
    required this.shakeAnimation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    if (errorMessage == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(shakeAnimation.value * 10, 0),
          child: Container(
            margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              border: Border.all(color: Colors.red[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.error,
                      color: Colors.red[600],
                      size: isSmallScreen ? 20 : 24,
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Expanded(
                      child: Text(
                        errorMessage!.split('\n')[0],
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: isSmallScreen ? 13 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                // Liste des champs manquants si disponible
                if (champsManquants.isNotEmpty) ...[
                  SizedBox(height: isSmallScreen ? 8 : 10),
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                    decoration: BoxDecoration(
                      color: Colors.red[25],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Actions requises :",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 12 : 13,
                            color: Colors.red[800],
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 4 : 6),
                        ...champsManquants
                            .map((champ) => Padding(
                                  padding: EdgeInsets.only(
                                      bottom: isSmallScreen ? 2 : 3),
                                  child: Text(
                                    champ,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 11 : 12,
                                      color: Colors.red[700],
                                    ),
                                  ),
                                ))
                            .toList(),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
