import 'package:flutter/material.dart';

/// Widget personnalisé pour afficher l'icône de monnaie depuis les assets
class MoneyIconWidget extends StatelessWidget {
  final double? size;
  final Color? color;

  const MoneyIconWidget({
    super.key,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? 24.0;

    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.asset(
          'assets/logo/money_icone.jpg',
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback en cas d'erreur de chargement de l'image
            return Icon(
              Icons.monetization_on,
              size: iconSize,
              color: color,
            );
          },
        ),
      ),
    );
  }
}

/// Widget simple pour les prefixIcon (sans bordures)
class SimpleMoneyIcon extends StatelessWidget {
  final double? size;

  const SimpleMoneyIcon({
    super.key,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? 20.0;

    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Image.asset(
        'assets/logo/money_icone.jpg',
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback en cas d'erreur de chargement de l'image
          return Icon(
            Icons.monetization_on,
            size: iconSize,
          );
        },
      ),
    );
  }
}
