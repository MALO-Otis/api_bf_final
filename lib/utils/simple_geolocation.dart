import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class SimpleGeolocation {
  static Future<Map<String, dynamic>?> getCurrentLocationPrecise() async {
    try {
      // Verifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'Permission refusee',
            'Acces a la geolocalisation requis pour precision <10m',
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
            icon: const Icon(Icons.error, color: Colors.red),
          );
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'Permission definitivement refusee',
          'Activez la geolocalisation dans les parametres',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          icon: const Icon(Icons.error, color: Colors.red),
        );
        return null;
      }

      // Configuration ultra-precise
      const double STRICT_TARGET = 10.0;
      const double ACCEPTABLE_TARGET = 25.0;
      const int maxAttempts = 8;

      Get.snackbar(
        'GEOLOCALISATION ULTRA-PRECISE',
        'Recherche position <10m...',
        backgroundColor: Colors.blue.shade100,
        colorText: Colors.blue.shade800,
        icon: const Icon(Icons.gps_fixed, color: Colors.blue),
        duration: const Duration(seconds: 3),
      );

      Position? bestPosition;
      int attempts = 0;

      // Boucle ultra-precise
      while (attempts < maxAttempts) {
        attempts++;

        try {
          print('Tentative $attempts/$maxAttempts pour <${STRICT_TARGET}m');

          Get.snackbar(
            'Tentative $attempts/$maxAttempts',
            'Recherche precision <${STRICT_TARGET}m...',
            backgroundColor: Colors.orange.shade100,
            colorText: Colors.orange.shade800,
            icon: const Icon(Icons.location_searching, color: Colors.orange),
            duration: const Duration(seconds: 2),
          );

          LocationAccuracy accuracy = attempts <= 3
              ? LocationAccuracy.bestForNavigation
              : LocationAccuracy.best;

          bool forceNative = attempts > 3;

          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: accuracy,
            timeLimit: Duration(seconds: 120 + (attempts * 30)),
            forceAndroidLocationManager: forceNative,
          );

          double currentAccuracy = position.accuracy;
          print('Tentative $attempts: ${currentAccuracy.toStringAsFixed(1)}m');

          if (bestPosition == null || currentAccuracy < bestPosition.accuracy) {
            bestPosition = position;
          }

          // Succes strict <10m
          if (currentAccuracy < STRICT_TARGET) {
            Get.snackbar(
              'SUCCES ULTRA-PRECIS',
              'Position: ${currentAccuracy.toStringAsFixed(1)}m < ${STRICT_TARGET}m',
              backgroundColor: Colors.green.shade100,
              colorText: Colors.green.shade800,
              icon: const Icon(Icons.check_circle, color: Colors.green),
              duration: const Duration(seconds: 3),
            );
            bestPosition = position;
            break;
          }

          if (attempts < maxAttempts) {
            await Future.delayed(Duration(seconds: attempts <= 4 ? 8 : 12));
          }
        } catch (e) {
          print('Erreur tentative $attempts: $e');
          if (attempts < maxAttempts) {
            await Future.delayed(const Duration(seconds: 5));
          }
        }
      }

      if (bestPosition == null) {
        throw Exception('Impossible d\'obtenir une position GPS');
      }

      double finalAccuracy = bestPosition.accuracy;

      // Messages selon precision
      if (finalAccuracy < STRICT_TARGET) {
        Get.snackbar(
          'PRECISION PARFAITE',
          '${finalAccuracy.toStringAsFixed(1)}m < ${STRICT_TARGET}m - Position absolue',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          icon: const Icon(Icons.gps_fixed, color: Colors.green),
          duration: const Duration(seconds: 4),
        );
      } else if (finalAccuracy < ACCEPTABLE_TARGET) {
        Get.snackbar(
          'PRECISION ACCEPTABLE',
          '${finalAccuracy.toStringAsFixed(1)}m (objectif <${STRICT_TARGET}m non atteint)',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
          icon: const Icon(Icons.warning, color: Colors.orange),
          duration: const Duration(seconds: 4),
        );
      } else {
        Get.snackbar(
          'PRECISION INSUFFISANTE',
          '${finalAccuracy.toStringAsFixed(1)}m > ${ACCEPTABLE_TARGET}m - Tentez a nouveau',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          icon: const Icon(Icons.error, color: Colors.red),
          duration: const Duration(seconds: 5),
        );
      }

      print(
          'FINAL: ${finalAccuracy.toStringAsFixed(1)}m apres $attempts tentatives');

      return {
        'latitude': bestPosition.latitude,
        'longitude': bestPosition.longitude,
        'accuracy': bestPosition.accuracy,
        'timestamp': bestPosition.timestamp,
        'address':
            'Lat: ${bestPosition.latitude.toStringAsFixed(6)}, Lng: ${bestPosition.longitude.toStringAsFixed(6)}',
      };
    } catch (e) {
      print('Erreur geolocalisation: $e');
      Get.snackbar(
        'Erreur geolocalisation',
        'Impossible d\'obtenir position <10m: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
        duration: const Duration(seconds: 4),
      );
      return null;
    }
  }
}
