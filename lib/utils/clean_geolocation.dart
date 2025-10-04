import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

// Fonction de geolocalisation ULTRA-PRECISE sans caracteres UTF-8 corrompus
class CleanGeolocation {
  static Future<Map<String, dynamic>?> getCurrentLocationClean() async {
    try {
      // Configuration ULTRA-PRECISE
      const double STRICT_TARGET = 10.0; // <10m STRICT
      const double ACCEPTABLE_TARGET = 25.0; // Backup
      const int maxAttempts = 3; // 3 tentatives maximum

      // Verifier permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'Permission refusee',
            'Acces geolocalisation requis pour precision <10m',
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
          'Activez geolocalisation dans parametres pour precision <10m',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          icon: const Icon(Icons.error, color: Colors.red),
        );
        return null;
      }

      Get.snackbar(
        'GEOLOCALISATION ULTRA-PRECISE',
        'Recherche position absolue <10m (compatible Google Maps)...',
        backgroundColor: Colors.blue.shade100,
        colorText: Colors.blue.shade800,
        icon: const Icon(Icons.gps_fixed, color: Colors.blue),
        duration: const Duration(seconds: 4),
      );

      Position? bestPosition;
      int attempts = 0;

      // Boucle ultra-precise pour <10m
      while (attempts < maxAttempts) {
        attempts++;

        try {
          print(
              'RECOLTE CLEAN - Tentative $attempts/$maxAttempts pour <${STRICT_TARGET}m');

          Get.snackbar(
            'Tentative $attempts/$maxAttempts',
            'Recherche precision <${STRICT_TARGET}m pour recolte...',
            backgroundColor: Colors.orange.shade100,
            colorText: Colors.orange.shade800,
            icon: const Icon(Icons.location_searching, color: Colors.orange),
            duration: const Duration(seconds: 3),
          );

          LocationAccuracy accuracy;
          bool forceNative;

          if (attempts <= 3) {
            accuracy = LocationAccuracy.bestForNavigation;
            forceNative = false;
          } else if (attempts <= 6) {
            accuracy = LocationAccuracy.best;
            forceNative = true;
          } else {
            accuracy = LocationAccuracy.bestForNavigation;
            forceNative = true;
          }

          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: accuracy,
            timeLimit: Duration(seconds: 120 + (attempts * 30)),
            forceAndroidLocationManager: forceNative,
          );

          double currentAccuracy = position.accuracy;
          print(
              'RECOLTE CLEAN - Tentative $attempts: ${currentAccuracy.toStringAsFixed(1)}m');

          if (bestPosition == null || currentAccuracy < bestPosition.accuracy) {
            bestPosition = position;
          }

          // SUCCES STRICT <10m
          if (currentAccuracy < STRICT_TARGET) {
            Get.snackbar(
              'SUCCES ULTRA-PRECIS !',
              'Recolte: ${currentAccuracy.toStringAsFixed(1)}m < ${STRICT_TARGET}m',
              backgroundColor: Colors.green.shade100,
              colorText: Colors.green.shade800,
              icon: const Icon(Icons.check_circle, color: Colors.green),
              duration: const Duration(seconds: 4),
            );
            bestPosition = position;
            break;
          }

          if (attempts < maxAttempts) {
            await Future.delayed(
                const Duration(seconds: 3)); // 3 secondes entre tentatives
          }
        } catch (e) {
          print('RECOLTE CLEAN - Erreur tentative $attempts: $e');
          if (attempts < maxAttempts) {
            await Future.delayed(
                const Duration(seconds: 3)); // 3 secondes en cas d'erreur
          }
        }
      }

      if (bestPosition == null) {
        throw Exception('Impossible obtenir position GPS');
      }

      double finalAccuracy = bestPosition.accuracy;

      if (finalAccuracy < STRICT_TARGET) {
        Get.snackbar(
          'PRECISION PARFAITE !',
          'Recolte: ${finalAccuracy.toStringAsFixed(1)}m < ${STRICT_TARGET}m',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          icon: const Icon(Icons.gps_fixed, color: Colors.green),
          duration: const Duration(seconds: 5),
        );
      } else if (finalAccuracy < ACCEPTABLE_TARGET) {
        Get.snackbar(
          'PRECISION ACCEPTABLE',
          'Recolte: ${finalAccuracy.toStringAsFixed(1)}m (objectif <${STRICT_TARGET}m non atteint)',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
          icon: const Icon(Icons.warning, color: Colors.orange),
          duration: const Duration(seconds: 5),
        );
      } else {
        Get.snackbar(
          'PRECISION INSUFFISANTE',
          'Recolte: ${finalAccuracy.toStringAsFixed(1)}m > ${ACCEPTABLE_TARGET}m - Tentez a nouveau',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          icon: const Icon(Icons.error, color: Colors.red),
          duration: const Duration(seconds: 6),
        );
      }

      print(
          'RECOLTE CLEAN FINAL: ${finalAccuracy.toStringAsFixed(1)}m apres $attempts tentatives');

      return {
        'latitude': bestPosition.latitude,
        'longitude': bestPosition.longitude,
        'accuracy': bestPosition.accuracy,
        'timestamp': bestPosition.timestamp,
        'address':
            'Lat: ${bestPosition.latitude.toStringAsFixed(6)}, Lng: ${bestPosition.longitude.toStringAsFixed(6)}',
      };
    } catch (e) {
      print('RECOLTE CLEAN - Erreur geolocalisation: $e');
      Get.snackbar(
        'Erreur geolocalisation recolte',
        'Impossible obtenir position <10m: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
        duration: const Duration(seconds: 5),
      );
      return null;
    }
  }
}
