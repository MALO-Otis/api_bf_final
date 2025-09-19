import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Service pour générer des cartes avec localisation encerclée
class MapService {
  // Coordonnées de Koudougou (Burkina Faso) pour fallback
  static const double koudougouLatitude = 12.250000;
  static const double koudougouLongitude = -2.366670;

  /// Génère une image de carte avec la localisation encerclée
  static Future<Uint8List> genererCarteAvecLocalisation({
    required double? latitude,
    required double? longitude,
    double? accuracy,
    int width = 600,
    int height = 400,
    int zoom = 15,
  }) async {
    try {
      // Utiliser Koudougou si pas de coordonnées GPS
      final bool isTestLocation = latitude == null || longitude == null;
      final double finalLat = latitude ?? koudougouLatitude;
      final double finalLng = longitude ?? koudougouLongitude;

      print(
          '🗺️ MAP: Génération carte pour ${isTestLocation ? "Koudougou (test)" : "GPS réel"}');
      print('   Coordonnées: $finalLat, $finalLng');

      // Calculer les coordonnées de tuile pour OpenStreetMap
      final tileX = _longitudeToTileX(finalLng, zoom);
      final tileY = _latitudeToTileY(finalLat, zoom);

      // Télécharger plusieurs tuiles pour créer une carte plus large
      final List<List<Uint8List>> tiles = [];
      const int tilesPerSide = 3; // 3x3 tuiles
      const int centerOffset = tilesPerSide ~/ 2;

      for (int y = -centerOffset; y <= centerOffset; y++) {
        final List<Uint8List> row = [];
        for (int x = -centerOffset; x <= centerOffset; x++) {
          final tileData = await _downloadTile(
            tileX + x,
            tileY + y,
            zoom,
          );
          row.add(tileData);
        }
        tiles.add(row);
      }

      // Assembler les tuiles et ajouter le marqueur
      final mapImage = await _assembleTilesWithMarker(
        tiles,
        finalLat,
        finalLng,
        accuracy,
        isTestLocation,
        width,
        height,
        zoom,
        tileX,
        tileY,
      );

      print('✅ MAP: Carte générée avec succès (${mapImage.length} bytes)');
      return mapImage;
    } catch (e) {
      print('❌ MAP: Erreur génération carte: $e');
      // Retourner une image placeholder en cas d'erreur
      return await _generatePlaceholderMap(width, height);
    }
  }

  /// Télécharge une tuile OpenStreetMap
  static Future<Uint8List> _downloadTile(int x, int y, int zoom) async {
    try {
      final url = 'https://tile.openstreetmap.org/$zoom/$x/$y.png';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'ApiSavana-Gestion/1.0 (Contact: admin@apisavana.com)',
        },
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Erreur téléchargement tuile: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ MAP: Erreur téléchargement tuile $x,$y,$zoom: $e');
      rethrow;
    }
  }

  /// Convertit longitude en coordonnée de tuile X
  static int _longitudeToTileX(double longitude, int zoom) {
    return ((longitude + 180.0) / 360.0 * (1 << zoom)).floor();
  }

  /// Convertit latitude en coordonnée de tuile Y
  static int _latitudeToTileY(double latitude, int zoom) {
    final latRad = latitude * (math.pi / 180.0);
    return ((1.0 -
                (math.log(math.tan(latRad) + (1.0 / math.cos(latRad))) /
                    math.pi)) /
            2.0 *
            (1 << zoom))
        .floor();
  }

  /// Assemble les tuiles et ajoute le marqueur de localisation
  static Future<Uint8List> _assembleTilesWithMarker(
    List<List<Uint8List>> tiles,
    double latitude,
    double longitude,
    double? accuracy,
    bool isTestLocation,
    int finalWidth,
    int finalHeight,
    int zoom,
    int centerTileX,
    int centerTileY,
  ) async {
    try {
      // Créer un canvas pour assembler la carte
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      const int tileSize = 256;
      const int tilesPerSide = 3;
      final int totalSize = tileSize * tilesPerSide;

      // Dessiner les tuiles
      for (int row = 0; row < tilesPerSide; row++) {
        for (int col = 0; col < tilesPerSide; col++) {
          final tileData = tiles[row][col];
          final codec = await ui.instantiateImageCodec(tileData);
          final frame = await codec.getNextFrame();
          final image = frame.image;

          canvas.drawImage(
            image,
            Offset(col * tileSize.toDouble(), row * tileSize.toDouble()),
            Paint(),
          );
        }
      }

      // Calculer la position du marqueur sur l'image
      final centerPixelX = totalSize / 2;
      final centerPixelY = totalSize / 2;

      // Dessiner le cercle de localisation
      final paint = Paint()
        ..color = isTestLocation ? Colors.orange : Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;

      final fillPaint = Paint()
        ..color = (isTestLocation ? Colors.orange : Colors.red).withOpacity(0.3)
        ..style = PaintingStyle.fill;

      // Cercle de précision si disponible
      if (accuracy != null && accuracy > 0) {
        final accuracyRadius = _metersToPixels(accuracy, latitude, zoom);
        canvas.drawCircle(
          Offset(centerPixelX, centerPixelY),
          accuracyRadius,
          fillPaint,
        );
      }

      // Point central
      canvas.drawCircle(
        Offset(centerPixelX, centerPixelY),
        12.0,
        fillPaint,
      );
      canvas.drawCircle(
        Offset(centerPixelX, centerPixelY),
        12.0,
        paint,
      );

      // Point central plus petit
      final centerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(centerPixelX, centerPixelY),
        4.0,
        centerPaint,
      );

      // Ajouter texte de statut
      final textPainter = TextPainter(
        text: TextSpan(
          text: isTestLocation
              ? 'LOCALISATION TEST\nKoudougou, Burkina Faso'
              : 'LOCALISATION GPS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: const Offset(1, 1),
                blurRadius: 2,
                color: Colors.black.withOpacity(0.8),
              ),
            ],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (totalSize - textPainter.width) / 2,
          20,
        ),
      );

      // Finaliser l'image
      final picture = recorder.endRecording();
      final img = await picture.toImage(totalSize, totalSize);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      // Redimensionner si nécessaire
      if (finalWidth != totalSize || finalHeight != totalSize) {
        return await _resizeImage(
            byteData!.buffer.asUint8List(), finalWidth, finalHeight);
      }

      return byteData!.buffer.asUint8List();
    } catch (e) {
      print('❌ MAP: Erreur assemblage tuiles: $e');
      return await _generatePlaceholderMap(finalWidth, finalHeight);
    }
  }

  /// Convertit des mètres en pixels selon le zoom
  static double _metersToPixels(double meters, double latitude, int zoom) {
    final metersPerPixel =
        156543.03392 * math.cos(latitude * math.pi / 180) / math.pow(2, zoom);
    return meters / metersPerPixel;
  }

  /// Redimensionne une image
  static Future<Uint8List> _resizeImage(
      Uint8List imageData, int width, int height) async {
    try {
      final codec = await ui.instantiateImageCodec(
        imageData,
        targetWidth: width,
        targetHeight: height,
      );
      final frame = await codec.getNextFrame();
      final resizedImage = frame.image;

      final byteData =
          await resizedImage.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } catch (e) {
      print('❌ MAP: Erreur redimensionnement: $e');
      return imageData; // Retourner l'image originale en cas d'erreur
    }
  }

  /// Génère une image placeholder en cas d'erreur
  static Future<Uint8List> _generatePlaceholderMap(
      int width, int height) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Fond gris
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint()..color = Colors.grey.shade300,
      );

      // Texte d'erreur
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'Carte non disponible\nVérifiez votre connexion',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (width - textPainter.width) / 2,
          (height - textPainter.height) / 2,
        ),
      );

      final picture = recorder.endRecording();
      final img = await picture.toImage(width, height);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      return byteData!.buffer.asUint8List();
    } catch (e) {
      print('❌ MAP: Erreur génération placeholder: $e');
      // Retourner une image vide minimale
      return Uint8List(0);
    }
  }

  /// Obtient les coordonnées avec fallback sur Koudougou
  static Map<String, dynamic> getCoordinatesWithFallback(
      Map<String, dynamic>? geolocationData) {
    if (geolocationData != null &&
        geolocationData['latitude'] != null &&
        geolocationData['longitude'] != null) {
      return {
        'latitude': geolocationData['latitude'],
        'longitude': geolocationData['longitude'],
        'accuracy': geolocationData['accuracy'],
        'isTest': false,
        'description': 'Localisation GPS réelle',
      };
    } else {
      return {
        'latitude': koudougouLatitude,
        'longitude': koudougouLongitude,
        'accuracy': null,
        'isTest': true,
        'description': 'Localisation test - Koudougou, Burkina Faso',
      };
    }
  }
}
