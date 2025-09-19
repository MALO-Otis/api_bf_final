import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service pour la gestion des lots de filtrage
class FiltrageLotService {
  static final FiltrageLotService _instance = FiltrageLotService._internal();
  factory FiltrageLotService() => _instance;
  FiltrageLotService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Génère un numéro de lot unique pour le filtrage
  Future<String> genererNumeroLot([String? siteId]) async {
    try {
      final timestamp = DateTime.now();
      final prefix = 'FILT';
      final datePart =
          '${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}';
      final timePart =
          '${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}';

      // Générer un identifiant unique basé sur timestamp
      final uniqueId = timestamp.millisecondsSinceEpoch
          .toString()
          .substring(7); // Derniers 6 chiffres

      final numeroLot = '${prefix}_${datePart}_${timePart}_$uniqueId';

      debugPrint('✅ Numéro de lot généré: $numeroLot');
      return numeroLot;
    } catch (e) {
      debugPrint('❌ Erreur génération numéro de lot: $e');
      // Fallback simple
      return 'FILT_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Vérifie si un numéro de lot existe déjà
  Future<bool> verifierExistanceLot(String numeroLot, String site) async {
    try {
      final doc = await _firestore
          .collection('Filtrage')
          .doc(site)
          .collection('processus')
          .doc(numeroLot)
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('❌ Erreur vérification existence lot: $e');
      return false;
    }
  }

  /// Obtient les statistiques d'un lot spécifique
  Future<Map<String, dynamic>?> obtenirStatistiquesLot(
      String numeroLot, String site) async {
    try {
      final doc = await _firestore
          .collection('Filtrage')
          .doc(site)
          .collection('processus')
          .doc(numeroLot)
          .get();

      if (doc.exists) {
        final data = doc.data()!;

        // Récupérer aussi les statistiques détaillées
        final statsDoc =
            await doc.reference.collection('statistiques').doc('resume').get();

        return {
          ...data,
          'statistiques': statsDoc.exists ? statsDoc.data() : null,
        };
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur récupération statistiques lot: $e');
      return null;
    }
  }

  /// Obtient les statistiques de plusieurs lots (pour les pages d'historique)
  Future<Map<String, dynamic>> getStatistiquesLots(
      [List<String>? lotIds]) async {
    try {
      debugPrint('📊 Calcul statistiques des lots...');

      // Statistiques par défaut
      final stats = {
        'nombreLotsTotal': 0,
        'quantiteTotaleFiltree': 0.0,
        'rendementMoyen': 0.0,
        'lotsParMois': <String, int>{},
        'technologiesUtilisees': <String, int>{},
        'erreur': null,
      };

      return stats;
    } catch (e) {
      debugPrint('❌ Erreur calcul statistiques lots: $e');
      return {
        'nombreLotsTotal': 0,
        'quantiteTotaleFiltree': 0.0,
        'rendementMoyen': 0.0,
        'lotsParMois': <String, int>{},
        'technologiesUtilisees': <String, int>{},
        'erreur': e.toString(),
      };
    }
  }
}
