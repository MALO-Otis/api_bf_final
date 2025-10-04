import 'package:cloud_firestore/cloud_firestore.dart';

/// Service pour gérer les statistiques avancées des collectes de récoltes
class StatsRecoltesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Régénère les statistiques avancées pour un site donné
  static Future<void> regenerateAdvancedStats(String site) async {
    try {
      print('🔄 Début régénération stats récoltes pour site: $site');

      // Charger toutes les collectes de récoltes du site
      final collectesSnapshot = await _firestore
          .collection('Sites')
          .doc(site)
          .collection('nos_collectes_recoltes')
          .get();

      print('📊 ${collectesSnapshot.docs.length} collectes trouvées');

      // Variables pour les totaux globaux
      double totalPoids = 0;
      double totalMontant = 0;
      int totalCollectes = 0;
      int totalContenants = 0;
      int totalSots = 0;
      int totalFuts = 0;
      int totalBidons = 0;
      final Set<String> floralesCumulees = {};
      final Set<String> regionsCouvertes = {};

      // Maps pour organiser les données
      final Map<String, Map<String, dynamic>> parMois = {};
      final Map<String, Map<String, dynamic>> regions = {};
      final Map<String, Map<String, dynamic>> techniciens = {};

      // Traiter chaque collecte
      for (final doc in collectesSnapshot.docs) {
        final data = doc.data();
        final collecteId = doc.id;

        // Extraire les données de la collecte
        final double poids = (data['totalWeight'] ?? 0).toDouble();
        final double montant = (data['totalAmount'] ?? 0).toDouble();
        final String regionNom = data['region'] ?? '';
        final String provinceNom = data['province'] ?? '';
        final String communeNom = data['commune'] ?? '';
        final String villageNom = data['village'] ?? '';
        final String technicienNom = data['technicien_nom'] ?? '';
        final String technicienUid = data['technicien_uid'] ?? '';
        final DateTime dateCollecte =
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final String moisKey =
            '${dateCollecte.year}-${dateCollecte.month.toString().padLeft(2, '0')}';
        final List<dynamic> contenants = data['contenants'] ?? [];
        final List<dynamic> florales = data['predominances_florales'] ?? [];

        // Compter les contenants par type
        int sots = 0, futs = 0, bidons = 0;
        for (final contenant in contenants) {
          final typeContenant = contenant['containerType'] ?? '';
          switch (typeContenant) {
            case 'Sot':
              sots++;
              break;
            case 'Fût':
              futs++;
              break;
            case 'Bidon':
              bidons++;
              break;
          }
        }

        // Mettre à jour les totaux globaux
        totalPoids += poids;
        totalMontant += montant;
        totalCollectes++;
        totalContenants += contenants.length;
        totalSots += sots;
        totalFuts += futs;
        totalBidons += bidons;
        if (regionNom.isNotEmpty) regionsCouvertes.add(regionNom);
        floralesCumulees.addAll(florales.cast<String>());

        // Statistiques par mois
        if (!parMois.containsKey(moisKey)) {
          parMois[moisKey] = {
            'mois': moisKey,
            'totalCollectes': 0,
            'totalPoids': 0.0,
            'totalMontant': 0.0,
            'totalContenants': 0,
            'totalSots': 0,
            'totalFuts': 0,
            'totalBidons': 0,
          };
        }
        final moisStats = parMois[moisKey]!;
        moisStats['totalCollectes'] = (moisStats['totalCollectes'] as int) + 1;
        moisStats['totalPoids'] = (moisStats['totalPoids'] as double) + poids;
        moisStats['totalMontant'] =
            (moisStats['totalMontant'] as double) + montant;
        moisStats['totalContenants'] =
            (moisStats['totalContenants'] as int) + contenants.length;
        moisStats['totalSots'] = (moisStats['totalSots'] as int) + sots;
        moisStats['totalFuts'] = (moisStats['totalFuts'] as int) + futs;
        moisStats['totalBidons'] = (moisStats['totalBidons'] as int) + bidons;

        // Statistiques par région
        if (regionNom.isNotEmpty) {
          if (!regions.containsKey(regionNom)) {
            regions[regionNom] = {
              'nom': regionNom,
              'totalCollectes': 0,
              'totalPoids': 0.0,
              'totalMontant': 0.0,
              'totalContenants': 0,
              'provinces': <String>{},
              'floralesDominantes': <String>{},
            };
          }
          final regionStats = regions[regionNom]!;
          regionStats['totalCollectes'] =
              (regionStats['totalCollectes'] as int) + 1;
          regionStats['totalPoids'] =
              (regionStats['totalPoids'] as double) + poids;
          regionStats['totalMontant'] =
              (regionStats['totalMontant'] as double) + montant;
          regionStats['totalContenants'] =
              (regionStats['totalContenants'] as int) + contenants.length;
          if (provinceNom.isNotEmpty)
            (regionStats['provinces'] as Set<String>).add(provinceNom);
          (regionStats['floralesDominantes'] as Set<String>)
              .addAll(florales.cast<String>());
        }

        // Statistiques par technicien
        if (technicienNom.isNotEmpty) {
          if (!techniciens.containsKey(technicienUid)) {
            techniciens[technicienUid] = {
              'nom': technicienNom,
              'uid': technicienUid,
              'totalCollectes': 0,
              'totalPoids': 0.0,
              'totalMontant': 0.0,
              'totalContenants': 0,
              'regionsDesservies': <String>{},
              'collectes': <Map<String, dynamic>>[],
            };
          }
          final techStats = techniciens[technicienUid]!;
          techStats['totalCollectes'] =
              (techStats['totalCollectes'] as int) + 1;
          techStats['totalPoids'] = (techStats['totalPoids'] as double) + poids;
          techStats['totalMontant'] =
              (techStats['totalMontant'] as double) + montant;
          techStats['totalContenants'] =
              (techStats['totalContenants'] as int) + contenants.length;
          if (regionNom.isNotEmpty)
            (techStats['regionsDesservies'] as Set<String>).add(regionNom);

          // Ajouter la collecte à l'historique du technicien
          (techStats['collectes'] as List<Map<String, dynamic>>).add({
            'id': collecteId,
            'date': dateCollecte.toIso8601String(),
            'poids': poids,
            'montant': montant,
            'nombreContenants': contenants.length,
            'region': regionNom,
            'province': provinceNom,
            'commune': communeNom,
            'village': villageNom,
          });
        }
      }

      // Construire la structure finale des statistiques
      final Map<String, dynamic> statistiques = {
        'totauxGlobaux': {
          'totalCollectes': totalCollectes,
          'totalPoids': totalPoids,
          'totalMontant': totalMontant,
          'totalContenants': totalContenants,
          'totalSots': totalSots,
          'totalFuts': totalFuts,
          'totalBidons': totalBidons,
          'floralesCumulees': floralesCumulees.toList()..sort(),
          'regionsCouvertes': regionsCouvertes.toList()..sort(),
        },
        'parMois': parMois.values.toList()
          ..sort(
              (a, b) => (b['mois'] as String).compareTo(a['mois'] as String)),
        'regions': regions.values.map((region) {
          return {
            'nom': region['nom'],
            'totalCollectes': region['totalCollectes'],
            'totalPoids': region['totalPoids'],
            'totalMontant': region['totalMontant'],
            'totalContenants': region['totalContenants'],
            'provinces': (region['provinces'] as Set<String>).toList()..sort(),
            'floralesDominantes':
                (region['floralesDominantes'] as Set<String>).toList()..sort(),
          };
        }).toList()
          ..sort((a, b) => (a['nom'] as String).compareTo(b['nom'] as String)),
        'techniciens': techniciens.values.map((tech) {
          return {
            'nom': tech['nom'],
            'uid': tech['uid'],
            'totalCollectes': tech['totalCollectes'],
            'totalPoids': tech['totalPoids'],
            'totalMontant': tech['totalMontant'],
            'totalContenants': tech['totalContenants'],
            'regionsDesservies':
                (tech['regionsDesservies'] as Set<String>).toList()..sort(),
            'collectes': (tech['collectes'] as List<Map<String, dynamic>>)
              ..sort((a, b) =>
                  (b['date'] as String).compareTo(a['date'] as String)),
          };
        }).toList()
          ..sort((a, b) => (a['nom'] as String).compareTo(b['nom'] as String)),
        'derniereMAJ': FieldValue.serverTimestamp(),
      };

      // Enregistrer les statistiques dans le document statistiques_avancees
      await _firestore
          .collection('Sites')
          .doc(site)
          .collection('nos_collectes_recoltes')
          .doc('statistiques_avancees')
          .set(statistiques);

      print('✅ Statistiques récoltes régénérées pour le site: $site');
      print(
          '📊 Totaux: $totalCollectes collectes, ${totalPoids}kg, ${totalMontant}FCFA');
    } catch (e) {
      print('❌ Erreur lors de la régénération des stats récoltes: $e');
      rethrow;
    }
  }

  /// Sauvegarde une collecte et met à jour les statistiques
  static Future<String> saveCollecteRecolte({
    required String site,
    required Map<String, dynamic> collecteData,
  }) async {
    try {
      print('💾 Début sauvegarde collecte récolte pour site: $site');

      // Générer l'ID personnalisé basé sur la date et le site
      final now = DateTime.now();
      final dateFormatted =
          '${now.day.toString().padLeft(2, '0')}_${now.month.toString().padLeft(2, '0')}_${now.year}';
      String customDocId = 'recolte_Date(${dateFormatted})_$site';

      // Vérifier si le document existe déjà et ajouter un suffixe si nécessaire
      final collectionRef = _firestore
          .collection('Sites')
          .doc(site)
          .collection('nos_collectes_recoltes');

      int counter = 1;
      String finalDocId = customDocId;

      while (true) {
        final docSnapshot = await collectionRef.doc(finalDocId).get();
        if (!docSnapshot.exists) {
          break;
        }
        // Si le document existe, ajouter un suffixe numérique
        finalDocId = '${customDocId}_${counter}';
        counter++;
      }

      print('📝 ID personnalisé final: $finalDocId');

      // Enregistrer la collecte avec l'ID personnalisé
      await collectionRef.doc(finalDocId).set(collecteData);

      print('✅ Collecte enregistrée avec ID: $finalDocId');

      // Régénérer les statistiques avancées
      await regenerateAdvancedStats(site);

      return finalDocId;
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde collecte récolte: $e');
      rethrow;
    }
  }
}
