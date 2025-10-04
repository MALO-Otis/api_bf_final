import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service pour récupérer l'historique des filtrages
class FiltrageHistoriqueService {
  static final FiltrageHistoriqueService _instance =
      FiltrageHistoriqueService._internal();
  factory FiltrageHistoriqueService() => _instance;
  FiltrageHistoriqueService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sites disponibles
  final List<String> sites = [
    'Koudougou',
    'Ouagadougou',
    'Bobo-Dioulasso',
    'Mangodara',
    'Bagre',
    'Pô'
  ];

  /// Récupère l'historique complet des filtrages avec statistiques
  Future<Map<String, dynamic>> getHistoriqueFiltrages({String? siteFilter}) async {
    try {
      debugPrint('📊 ===== RÉCUPÉRATION HISTORIQUE FILTRAGES =====');
      debugPrint('   🎯 Site filter: ${siteFilter ?? "Tous"}');
      
      final List<Map<String, dynamic>> filtrages = [];
      final Map<String, dynamic> statistiques = {
        'totalFiltrages': 0,
        'totalProduitsFiltrés': 0,
        'quantiteTotaleFiltree': 0.0,
        'quantiteTotaleRecue': 0.0,
        'rendementMoyen': 0.0,
        'repartitionParSite': <String, int>{},
        'repartitionParTechnologie': <String, int>{},
        'repartitionParMois': <String, int>{},
      };

      final sitesToCheck = siteFilter != null ? [siteFilter] : sites;

      for (final site in sitesToCheck) {
        debugPrint('   📍 Analyse du site: $site');
        
        final filtrageSnapshot = await _firestore
            .collection('Filtrage')
            .doc(site)
            .collection('processus')
            .orderBy('dateFiltrage', descending: true)
            .get();

        debugPrint('      ✅ ${filtrageSnapshot.docs.length} filtrages trouvés');

        for (final doc in filtrageSnapshot.docs) {
          final data = doc.data();
          
          // Récupérer les produits filtrés
          final produitsSnapshot = await doc.reference
              .collection('produits_filtres')
              .get();

          final filtrage = {
            'id': doc.id,
            'numeroLot': data['numeroLot'] ?? doc.id,
            'site': site,
            'utilisateur': data['utilisateur'] ?? 'Inconnu',
            'dateFiltrage': (data['dateFiltrage'] as Timestamp?)?.toDate() ?? DateTime.now(),
            'dateCreation': (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
            'technologie': data['technologie'] ?? 'Manuelle',
            'statut': data['statut'] ?? 'termine',
            
            // Quantités
            'quantiteTotale': (data['quantiteTotale'] ?? 0.0).toDouble(),
            'quantiteFiltree': (data['quantiteFiltree'] ?? 0.0).toDouble(),
            'residusRestants': (data['residusRestants'] ?? 0.0).toDouble(),
            'rendementFiltrage': (data['rendementFiltrage'] ?? 0.0).toDouble(),
            
            // Compteurs
            'nombreProduits': data['nombreProduits'] ?? produitsSnapshot.docs.length,
            'observations': data['observations'] ?? '',
            
            // Détails des produits
            'produitsFiltres': produitsSnapshot.docs.map((produitDoc) {
              final produitData = produitDoc.data();
              return {
                'id': produitDoc.id,
                'codeContenant': produitData['codeContenant'] ?? '',
                'producteur': produitData['producteur'] ?? '',
                'poidsInitial': (produitData['poidsInitial'] ?? 0.0).toDouble(),
                'quantiteFiltree': (produitData['quantiteFiltree'] ?? 0.0).toDouble(),
                'residusProduit': (produitData['residusProduit'] ?? 0.0).toDouble(),
                'rendementProduit': (produitData['rendementProduit'] ?? 0.0).toDouble(),
                'ordreTraitement': produitData['ordreTraitement'] ?? 0,
                'donneesOriginales': produitData['donneesOriginales'] ?? {},
              };
            }).toList(),
          };

          filtrages.add(filtrage);

          // Mise à jour des statistiques
          statistiques['totalFiltrages'] = (statistiques['totalFiltrages'] as int) + 1;
          statistiques['totalProduitsFiltrés'] = 
              (statistiques['totalProduitsFiltrés'] as int) + (filtrage['nombreProduits'] as int);
          statistiques['quantiteTotaleFiltree'] = 
              (statistiques['quantiteTotaleFiltree'] as double) + (filtrage['quantiteFiltree'] as double);
          statistiques['quantiteTotaleRecue'] = 
              (statistiques['quantiteTotaleRecue'] as double) + (filtrage['quantiteTotale'] as double);

          // Répartition par site
          final repartitionSite = statistiques['repartitionParSite'] as Map<String, int>;
          repartitionSite[site] = (repartitionSite[site] ?? 0) + 1;

          // Répartition par technologie
          final repartitionTech = statistiques['repartitionParTechnologie'] as Map<String, int>;
          final tech = filtrage['technologie'] as String;
          repartitionTech[tech] = (repartitionTech[tech] ?? 0) + 1;

          // Répartition par mois
          final repartitionMois = statistiques['repartitionParMois'] as Map<String, int>;
          final date = filtrage['dateFiltrage'] as DateTime;
          final moisCle = '${date.year}-${date.month.toString().padLeft(2, '0')}';
          repartitionMois[moisCle] = (repartitionMois[moisCle] ?? 0) + 1;
        }
      }

      // Calcul du rendement moyen
      if (statistiques['quantiteTotaleRecue'] > 0) {
        statistiques['rendementMoyen'] = 
            (statistiques['quantiteTotaleFiltree'] as double) / 
            (statistiques['quantiteTotaleRecue'] as double) * 100;
      }

      debugPrint('✅ Historique récupéré: ${filtrages.length} filtrages');
      debugPrint('   📊 Quantité totale filtrée: ${statistiques['quantiteTotaleFiltree']} kg');
      debugPrint('   📈 Rendement moyen: ${(statistiques['rendementMoyen'] as double).toStringAsFixed(1)}%');
      debugPrint('==============================================');

      return {
        'filtrages': filtrages,
        'statistiques': statistiques,
      };
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur récupération historique filtrages: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return {
        'filtrages': <Map<String, dynamic>>[],
        'statistiques': {
          'totalFiltrages': 0,
          'totalProduitsFiltrés': 0,
          'quantiteTotaleFiltree': 0.0,
          'quantiteTotaleRecue': 0.0,
          'rendementMoyen': 0.0,
          'repartitionParSite': <String, int>{},
          'repartitionParTechnologie': <String, int>{},
          'repartitionParMois': <String, int>{},
        },
      };
    }
  }

  /// Récupère les détails d'un filtrage spécifique
  Future<Map<String, dynamic>?> getDetailsFiltrage(String site, String numeroLot) async {
    try {
      debugPrint('🔍 Récupération détails filtrage: $site/$numeroLot');

      final filtrageDoc = await _firestore
          .collection('Filtrage')
          .doc(site)
          .collection('processus')
          .doc(numeroLot)
          .get();

      if (!filtrageDoc.exists) {
        debugPrint('❌ Filtrage non trouvé: $site/$numeroLot');
        return null;
      }

      final data = filtrageDoc.data()!;

      // Récupérer les produits filtrés
      final produitsSnapshot = await filtrageDoc.reference
          .collection('produits_filtres')
          .orderBy('ordreTraitement')
          .get();

      // Récupérer les statistiques
      final statsSnapshot = await filtrageDoc.reference
          .collection('statistiques')
          .doc('resume')
          .get();

      final details = {
        'id': filtrageDoc.id,
        'numeroLot': data['numeroLot'] ?? filtrageDoc.id,
        'site': site,
        'utilisateur': data['utilisateur'] ?? 'Inconnu',
        'dateFiltrage': (data['dateFiltrage'] as Timestamp?)?.toDate() ?? DateTime.now(),
        'dateCreation': (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
        'technologie': data['technologie'] ?? 'Manuelle',
        'statut': data['statut'] ?? 'termine',
        
        // Quantités
        'quantiteTotale': (data['quantiteTotale'] ?? 0.0).toDouble(),
        'quantiteFiltree': (data['quantiteFiltree'] ?? 0.0).toDouble(),
        'residusRestants': (data['residusRestants'] ?? 0.0).toDouble(),
        'rendementFiltrage': (data['rendementFiltrage'] ?? 0.0).toDouble(),
        
        // Compteurs et observations
        'nombreProduits': data['nombreProduits'] ?? produitsSnapshot.docs.length,
        'observations': data['observations'] ?? '',
        'version': data['version'] ?? '1.0',
        
        // Produits filtrés détaillés
        'produitsFiltres': produitsSnapshot.docs.map((produitDoc) {
          final produitData = produitDoc.data();
          return {
            'id': produitDoc.id,
            'codeContenant': produitData['codeContenant'] ?? '',
            'producteur': produitData['producteur'] ?? '',
            'poidsInitial': (produitData['poidsInitial'] ?? 0.0).toDouble(),
            'quantiteFiltree': (produitData['quantiteFiltree'] ?? 0.0).toDouble(),
            'residusProduit': (produitData['residusProduit'] ?? 0.0).toDouble(),
            'rendementProduit': (produitData['rendementProduit'] ?? 0.0).toDouble(),
            'ordreTraitement': produitData['ordreTraitement'] ?? 0,
            'dateTraitement': (produitData['dateTraitement'] as Timestamp?)?.toDate(),
            'donneesOriginales': produitData['donneesOriginales'] ?? {},
          };
        }).toList(),
        
        // Statistiques détaillées si disponibles
        'statistiquesDetaillees': statsSnapshot.exists ? statsSnapshot.data() : null,
      };

      debugPrint('✅ Détails filtrage récupérés: ${details['numeroLot']}');
      return details;
    } catch (e) {
      debugPrint('❌ Erreur récupération détails filtrage: $e');
      return null;
    }
  }

  /// Récupère les statistiques globales de filtrage
  Future<Map<String, dynamic>> getStatistiquesGlobales({String? siteFilter}) async {
    try {
      debugPrint('📊 Calcul statistiques globales filtrage...');
      
      final historique = await getHistoriqueFiltrages(siteFilter: siteFilter);
      final statistiques = historique['statistiques'] as Map<String, dynamic>;
      final filtrages = historique['filtrages'] as List<Map<String, dynamic>>;

      // Calculs supplémentaires
      final now = DateTime.now();
      final filtragesCeMois = filtrages.where((f) {
        final date = f['dateFiltrage'] as DateTime;
        return date.year == now.year && date.month == now.month;
      }).length;

      final filtragesToday = filtrages.where((f) {
        final date = f['dateFiltrage'] as DateTime;
        return date.year == now.year && 
               date.month == now.month && 
               date.day == now.day;
      }).length;

      // Meilleur rendement
      double meilleurRendement = 0.0;
      String? meilleurLot;
      for (final filtrage in filtrages) {
        final rendement = filtrage['rendementFiltrage'] as double;
        if (rendement > meilleurRendement) {
          meilleurRendement = rendement;
          meilleurLot = filtrage['numeroLot'] as String;
        }
      }

      return {
        ...statistiques,
        'filtragesCeMois': filtragesCeMois,
        'filtragesToday': filtragesToday,
        'meilleurRendement': meilleurRendement,
        'meilleurLot': meilleurLot,
        'dernierFiltrage': filtrages.isNotEmpty 
            ? (filtrages.first['dateFiltrage'] as DateTime)
            : null,
      };
    } catch (e) {
      debugPrint('❌ Erreur calcul statistiques globales: $e');
      return {};
    }
  }
}
