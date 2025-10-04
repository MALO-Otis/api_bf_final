import 'package:flutter/material.dart';

class BoutonEnregistrement extends StatelessWidget {
  final bool estValide;
  final bool isLoading;
  final VoidCallback onPressed;
  final List<String> champsManquants;

  const BoutonEnregistrement({
    Key? key,
    required this.estValide,
    required this.isLoading,
    required this.onPressed,
    required this.champsManquants,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                boxShadow: estValide
                    ? [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
              ),
              child: ElevatedButton.icon(
                onPressed: estValide && !isLoading ? onPressed : null,
                icon: isLoading
                    ? SizedBox(
                        width: isSmallScreen ? 16 : 20,
                        height: isSmallScreen ? 16 : 20,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        estValide ? Icons.save : Icons.error_outline,
                        size: isSmallScreen ? 20 : 24,
                      ),
                label: Text(
                  isLoading
                      ? 'Enregistrement...'
                      : estValide
                          ? 'Enregistrer la collecte'
                          : 'Compléter les champs requis',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      estValide ? Colors.green[600] : Colors.grey[400],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 16 : 20,
                    horizontal: isSmallScreen ? 20 : 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(isSmallScreen ? 12 : 16),
                  ),
                  elevation: estValide ? 4 : 1,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
