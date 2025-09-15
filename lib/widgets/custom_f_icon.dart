import 'package:flutter/material.dart';

/// Widget personnalisé pour afficher une icône "F" stylisée comme symbole du franc CFA
class CustomFIcon extends StatelessWidget {
  final double? size;
  final Color? color;

  const CustomFIcon({
    super.key,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? 24.0;
    final iconColor =
        color ?? Theme.of(context).iconTheme.color ?? Colors.black;

    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: CustomPaint(
        painter: FIconPainter(iconColor),
      ),
    );
  }
}

/// Peintre personnalisé pour dessiner l'icône "F" stylisée
class FIconPainter extends CustomPainter {
  final Color color;

  FIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;

    final width = size.width;
    final height = size.height;

    // Ajuster les proportions pour que l'icône soit bien centrée
    final scale = (width * 0.8) / 24.0; // Facteur d'échelle basé sur la taille
    final offsetX = width * 0.1; // Décalage horizontal pour centrer
    final offsetY = height * 0.1; // Décalage vertical pour centrer

    final path = Path();

    // Dessiner le "F" stylisé avec une barre horizontale supplémentaire (comme le symbole du franc)
    // Barre verticale principale
    path.moveTo(offsetX + 2 * scale, offsetY + 2 * scale);
    path.lineTo(offsetX + 2 * scale, offsetY + 22 * scale);

    // Barre horizontale du haut
    path.moveTo(offsetX + 2 * scale, offsetY + 2 * scale);
    path.lineTo(offsetX + 18 * scale, offsetY + 2 * scale);

    // Barre horizontale du milieu
    path.moveTo(offsetX + 2 * scale, offsetY + 10 * scale);
    path.lineTo(offsetX + 14 * scale, offsetY + 10 * scale);

    // Barre horizontale du bas (caractéristique du symbole franc)
    path.moveTo(offsetX + 2 * scale, offsetY + 16 * scale);
    path.lineTo(offsetX + 12 * scale, offsetY + 16 * scale);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is FIconPainter && oldDelegate.color != color;
  }
}

/// Extension pour faciliter l'utilisation de l'icône F
extension FIconExtension on IconData {
  static const IconData franc = IconData(0xe900, fontFamily: 'CustomF');
}

/// Widget d'icône F simple utilisant du texte
class SimpleFIcon extends StatelessWidget {
  final double? size;
  final Color? color;

  const SimpleFIcon({
    super.key,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? 24.0;
    final iconColor =
        color ?? Theme.of(context).iconTheme.color ?? Colors.black;

    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: iconColor, width: 1.5),
      ),
      child: Center(
        child: Text(
          'F',
          style: TextStyle(
            color: iconColor,
            fontSize: iconSize * 0.6,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

/// Icône F simple pour les prefixIcon (sans container)
class FIcon extends StatelessWidget {
  final double? size;
  final Color? color;

  const FIcon({
    super.key,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? 24.0;
    final iconColor =
        color ?? Theme.of(context).iconTheme.color ?? Colors.black;

    return Icon(
      Icons.text_fields, // Utilise une icône de texte comme base
      size: iconSize,
      color: iconColor,
    );
  }
}
