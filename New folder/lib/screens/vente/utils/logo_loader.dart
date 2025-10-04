import 'dart:typed_data';
import 'apisavana_pdf_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Charge et met en cache le logo pour les PDF ApiSavana.
/// A appeler une seule fois (ex: dans main() après WidgetsFlutterBinding.ensureInitialized()).
class ApiSavanaLogoLoader {
  static bool _initialized = false;
  static Uint8List? _bytes;

  /// Essaie plusieurs chemins possibles (JPEG / PNG / variations casse) pour simplifier l'intégration.
  static const List<String> _candidatePaths = [
    'assets/logo/logo.jpeg',
    'assets/logo/logo.jpg',
    'assets/logo/logo.PNG',
    'assets/logo/logo.png',
    'assets/logo/apisavana_logo.jpg',
    'assets/logo/apisavana_logo.png',
  ];

  /// Charge le logo si ce n'est déjà fait. Fournir un chemin explicite si souhaité.
  /// En mode debug, des logs détaillent chaque tentative.
  static Future<void> ensureLoaded({String? assetPath}) async {
    if (_initialized && _bytes != null) return;
    final List<String> tries = [
      if (assetPath != null) assetPath,
      ..._candidatePaths,
    ];
    if (kDebugMode)
      debugPrint('[LogoLoader] Tentatives de chargement: ${tries.join(', ')}');
    for (final path in tries) {
      try {
        final data = await rootBundle.load(path);
        _bytes = data.buffer.asUint8List();
        ApiSavanaPdfService.setLogo(_bytes!);
        _initialized = true;
        if (kDebugMode)
          debugPrint('[LogoLoader] Logo chargé avec succès: $path');
        break;
      } catch (e) {
        if (kDebugMode) debugPrint('[LogoLoader] Échec chargement $path -> $e');
      }
    }
    assert(_bytes != null,
        'Aucun logo n\'a pu être chargé. Vérifiez assets/logo/ et pubspec.yaml.');
  }

  /// Permet de recharger dynamiquement un nouveau logo (ex: changement via UI admin).
  static Future<bool> reload(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      _bytes = data.buffer.asUint8List();
      ApiSavanaPdfService.setLogo(_bytes!);
      _initialized = true;
      if (kDebugMode) debugPrint('[LogoLoader] Reload réussi: $assetPath');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[LogoLoader] Reload échec ($assetPath): $e');
      return false;
    }
  }

  /// Indique si un logo est présent en mémoire.
  static bool get hasLogo => _bytes != null;
}
