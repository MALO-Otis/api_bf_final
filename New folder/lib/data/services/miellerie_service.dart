import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/miellerie_models.dart';
import '../../authentication/user_session.dart';

class MiellerieService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection Firestore pour les mielleries
  static const String _collectionName = 'mielleries';

  /// Ajoute une nouvelle miellerie en base de données
  static Future<String> addMiellerie({
    required String nom,
    required String localite,
    String? telephone,
    String? adresse,
    String? notes,
  }) async {
    try {
      final userSession = Get.find<UserSession>();
      final userSite = userSession.site ?? '';

      if (userSite.isEmpty) {
        throw Exception('Aucun site utilisateur trouvé');
      }

      // Vérifier si la miellerie existe déjà
      final existingMiellerie = await _checkMiellerieExists(nom, userSite);
      if (existingMiellerie) {
        throw Exception('Une miellerie avec ce nom existe déjà');
      }

      // Créer le document de la miellerie
      final miellerieData = {
        'nom': nom.trim(),
        'localite': localite.trim(),
        'telephone': telephone?.trim(),
        'adresse': adresse?.trim(),
        'notes': notes?.trim(),
        'site': userSite,
        'created_at': Timestamp.fromDate(DateTime.now()),
        'created_by': userSession.nom ?? 'Utilisateur inconnu',
        'is_active': true,
      };

      // Ajouter à la collection globale des mielleries
      final docRef =
          await _firestore.collection(_collectionName).add(miellerieData);

      // Ajouter aussi dans la collection du site pour faciliter les requêtes
      await _firestore
          .collection('Sites')
          .doc(userSite)
          .collection('mielleries')
          .doc(docRef.id)
          .set(miellerieData);

      print('✅ Miellerie ajoutée avec succès: $nom (ID: ${docRef.id})');
      return docRef.id;
    } catch (e) {
      print('❌ Erreur ajout miellerie: $e');
      rethrow;
    }
  }

  /// Récupère toutes les mielleries pour le site de l'utilisateur
  static Future<List<MiellerieModel>> getMielleriesForSite() async {
    try {
      final userSession = Get.find<UserSession>();
      final userSite = userSession.site ?? '';

      if (userSite.isEmpty) {
        throw Exception('Aucun site utilisateur trouvé');
      }

      // Récupérer depuis la collection du site
      final querySnapshot = await _firestore
          .collection('Sites')
          .doc(userSite)
          .collection('mielleries')
          .where('is_active', isEqualTo: true)
          .orderBy('nom')
          .get();

      final mielleries = querySnapshot.docs
          .map((doc) => MiellerieModel.fromFirestore(doc))
          .toList();

      print('✅ ${mielleries.length} mielleries chargées pour $userSite');
      return mielleries;
    } catch (e) {
      print('❌ Erreur chargement mielleries: $e');
      rethrow;
    }
  }

  /// Récupère les noms des mielleries pour le site (pour les dropdowns)
  static Future<List<String>> getMiellerieNamesForSite() async {
    try {
      final mielleries = await getMielleriesForSite();
      return mielleries.map((m) => m.nom).toList();
    } catch (e) {
      print('❌ Erreur chargement noms mielleries: $e');
      return [];
    }
  }

  /// Vérifie si une miellerie existe déjà
  static Future<bool> _checkMiellerieExists(String nom, String site) async {
    try {
      final querySnapshot = await _firestore
          .collection('Sites')
          .doc(site)
          .collection('mielleries')
          .where('nom', isEqualTo: nom.trim())
          .where('is_active', isEqualTo: true)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Erreur vérification existence miellerie: $e');
      return false;
    }
  }

  /// Met à jour une miellerie existante
  static Future<void> updateMiellerie({
    required String id,
    required String nom,
    required String localite,
    String? telephone,
    String? adresse,
    String? notes,
  }) async {
    try {
      final userSession = Get.find<UserSession>();
      final userSite = userSession.site ?? '';

      if (userSite.isEmpty) {
        throw Exception('Aucun site utilisateur trouvé');
      }

      final updateData = {
        'nom': nom.trim(),
        'localite': localite.trim(),
        'telephone': telephone?.trim(),
        'adresse': adresse?.trim(),
        'notes': notes?.trim(),
        'updated_at': Timestamp.fromDate(DateTime.now()),
        'updated_by': userSession.nom ?? 'Utilisateur inconnu',
      };

      // Mettre à jour dans la collection du site
      await _firestore
          .collection('Sites')
          .doc(userSite)
          .collection('mielleries')
          .doc(id)
          .update(updateData);

      // Mettre à jour aussi dans la collection globale
      await _firestore.collection(_collectionName).doc(id).update(updateData);

      print('✅ Miellerie mise à jour: $nom');
    } catch (e) {
      print('❌ Erreur mise à jour miellerie: $e');
      rethrow;
    }
  }

  /// Désactive une miellerie (soft delete)
  static Future<void> deleteMiellerie(String id) async {
    try {
      final userSession = Get.find<UserSession>();
      final userSite = userSession.site ?? '';

      if (userSite.isEmpty) {
        throw Exception('Aucun site utilisateur trouvé');
      }

      final updateData = {
        'is_active': false,
        'deleted_at': Timestamp.fromDate(DateTime.now()),
        'deleted_by': userSession.nom ?? 'Utilisateur inconnu',
      };

      // Désactiver dans la collection du site
      await _firestore
          .collection('Sites')
          .doc(userSite)
          .collection('mielleries')
          .doc(id)
          .update(updateData);

      // Désactiver aussi dans la collection globale
      await _firestore.collection(_collectionName).doc(id).update(updateData);

      print('✅ Miellerie désactivée: $id');
    } catch (e) {
      print('❌ Erreur suppression miellerie: $e');
      rethrow;
    }
  }

  /// Recherche des mielleries par nom
  static Future<List<MiellerieModel>> searchMielleries(String query) async {
    try {
      final userSession = Get.find<UserSession>();
      final userSite = userSession.site ?? '';

      if (userSite.isEmpty) {
        throw Exception('Aucun site utilisateur trouvé');
      }

      final querySnapshot = await _firestore
          .collection('Sites')
          .doc(userSite)
          .collection('mielleries')
          .where('is_active', isEqualTo: true)
          .where('nom', isGreaterThanOrEqualTo: query)
          .where('nom', isLessThan: query + 'z')
          .orderBy('nom')
          .get();

      return querySnapshot.docs
          .map((doc) => MiellerieModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur recherche mielleries: $e');
      return [];
    }
  }
}

