import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apisavana_gestion/utils/role_utils.dart';
import 'package:apisavana_gestion/authentication/login.dart';
import 'package:apisavana_gestion/authentication/user_session.dart';
import 'package:apisavana_gestion/screens/dashboard/dashboard.dart';
import 'package:apisavana_gestion/services/push_notifications_service.dart';

/// Wrapper d'authentification qui gère :
/// - La persistance de session utilisateur
/// - La redirection automatique selon l'état de connexion
/// - La vérification et mise à jour des données utilisateur
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  /// Vérifie l'état d'authentification et redirige en conséquence
  Future<void> _checkAuthState() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

      // Vérifier si un utilisateur est déjà connecté
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        // Aucun utilisateur connecté, rediriger vers la page de login
        _redirectToLogin();
        return;
      }

      // Utilisateur trouvé, récupérer ses données depuis Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        // Document utilisateur inexistant, déconnecter et rediriger vers login
        await FirebaseAuth.instance.signOut();
        _redirectToLogin();
        return;
      }

      final userData = userDoc.data()!;

      // Normaliser les données utilisateur
      String normalizedSite = '';
      if ((userData['site'] ?? '').toString().isNotEmpty) {
        String s = userData['site'];
        normalizedSite = s[0].toUpperCase() + s.substring(1).toLowerCase();
      }

      final roles = extractNormalizedRoles(userData['role']);

      // Mettre à jour ou créer la session utilisateur
      UserSession userSession;
      try {
        userSession = Get.find<UserSession>();
      } catch (_) {
        userSession = Get.put(UserSession(), permanent: true);
      }

      userSession.setUser(
        uid: currentUser.uid,
        roles: roles,
        nom: userData['nom'] ?? '',
        email: userData['email'] ?? '',
        site: normalizedSite,
        photoUrl: userData['photoUrl'],
      );

      // Ensure the device token document is updated with fresh uid/site
      await PushNotificationsService.instance.resyncTokenMetadata();

      // Rediriger vers le dashboard
      _redirectToDashboard();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Erreur lors de la vérification de la session : $e';
        _isLoading = false;
      });

      // En cas d'erreur, attendre 3 secondes puis rediriger vers login
      await Future.delayed(const Duration(seconds: 3));
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    if (mounted) {
      setState(() => _isLoading = false);
      // Reporter la navigation après la phase de build pour éviter les erreurs setState()
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Get.offAll(() => const LoginPage());
        }
      });
    }
  }

  void _redirectToDashboard() {
    if (mounted) {
      setState(() => _isLoading = false);
      // Reporter la navigation après la phase de build pour éviter les erreurs setState()
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Get.offAll(() => const DashboardPage());
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF8F0), Color(0xFFF49101), Color(0xFF2D0C0D)],
              stops: [0.1, 0.5, 1.0],
            ),
          ),
          child: Center(
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur de Session',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage ?? 'Une erreur inattendue s\'est produite',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Redirection vers la page de connexion...',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Écran de chargement pendant la vérification
    if (_isLoading) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF8F0), Color(0xFFF49101), Color(0xFF2D0C0D)],
              stops: [0.1, 0.5, 1.0],
            ),
          ),
          child: Center(
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/logo/logo.jpeg',
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ApiSavana',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF49101),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Vérification de la session...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFF49101)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // En pratique, on ne devrait presque jamais voir ceci car la navigation est déclenchée.
    return const SizedBox.shrink();
  }
}
