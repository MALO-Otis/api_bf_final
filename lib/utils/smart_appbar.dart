import 'package:flutter/material.dart';

/// Utility pour gérer les AppBar avec bouton retour conditionnel
/// Évite les crashs sur mobile quand il n'y a pas de page précédente
class SmartAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color? backgroundColor;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final VoidCallback? onBackPressed;
  final String? backTooltip;
  final PreferredSizeWidget? bottom;

  const SmartAppBar({
    Key? key,
    required this.title,
    this.backgroundColor,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.onBackPressed,
    this.backTooltip,
    this.bottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Si un leading personnalisé est fourni, l'utiliser
    if (leading != null) {
      return AppBar(
        title: Text(title),
        backgroundColor: backgroundColor,
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: false,
        bottom: bottom,
      );
    }

    // Vérifier si on peut revenir en arrière
    final bool canPop = Navigator.of(context).canPop();

    // Si on ne peut pas revenir en arrière et qu'aucun callback n'est fourni,
    // ne pas afficher de bouton retour
    if (!canPop && onBackPressed == null && automaticallyImplyLeading) {
      return AppBar(
        title: Text(title),
        backgroundColor: backgroundColor,
        actions: actions,
        automaticallyImplyLeading: false,
        bottom: bottom,
      );
    }

    // Sinon, créer un bouton retour intelligent
    return AppBar(
      title: Text(title),
      backgroundColor: backgroundColor,
      actions: actions,
      automaticallyImplyLeading: false,
      leading: canPop || onBackPressed != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              tooltip: backTooltip ?? 'Retour',
              onPressed: () {
                if (onBackPressed != null) {
                  onBackPressed!();
                } else if (canPop) {
                  Navigator.of(context).pop();
                }
              },
            )
          : null,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}

/// Extension pour simplifier l'usage des AppBar intelligentes
extension SmartAppBarExtension on AppBar {
  /// Crée une AppBar intelligente qui gère automatiquement le bouton retour
  static SmartAppBar smart({
    required String title,
    Color? backgroundColor,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    VoidCallback? onBackPressed,
    String? backTooltip,
    PreferredSizeWidget? bottom,
  }) {
    return SmartAppBar(
      title: title,
      backgroundColor: backgroundColor,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      onBackPressed: onBackPressed,
      backTooltip: backTooltip,
      bottom: bottom,
    );
  }
}

/// Mixin pour faciliter l'utilisation dans les StatefulWidget
mixin SmartAppBarMixin<T extends StatefulWidget> on State<T> {
  /// Crée une AppBar intelligente pour la page courante
  SmartAppBar buildSmartAppBar({
    required String title,
    Color? backgroundColor,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    VoidCallback? onBackPressed,
    String? backTooltip,
    PreferredSizeWidget? bottom,
  }) {
    return SmartAppBar(
      title: title,
      backgroundColor: backgroundColor,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      onBackPressed: onBackPressed,
      backTooltip: backTooltip,
      bottom: bottom,
    );
  }

  /// Vérifie si on peut revenir en arrière de manière sécurisée
  bool canNavigateBack() {
    return Navigator.of(context).canPop();
  }

  /// Navigation sécurisée vers le dashboard
  void navigateToDashboard() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/dashboard',
      (route) => false,
    );
  }

  /// Navigation sécurisée avec vérification
  void navigateBackSafely() {
    if (canNavigateBack()) {
      Navigator.of(context).pop();
    } else {
      navigateToDashboard();
    }
  }
}
