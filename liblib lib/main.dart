import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'utils/auth_wrapper.dart';
import 'utils/windows_channel_fix.dart';
import 'utils/firebase_windows_fallback.dart';
import 'authentication/login.dart';
import 'authentication/sign_up.dart';
import 'package:flutter/material.dart';
import 'authentication/user_session.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/caisse/pages/espace_caissier_page.dart';
import 'package:apisavana_gestion/screens/dashboard/dashboard.dart';
import 'screens/conditionnement/services/conditionnement_db_service.dart';
import 'package:apisavana_gestion/screens/extraction_page/extraction.dart';
import 'package:apisavana_gestion/screens/filtrage/filtrage_main_page.dart';
import 'screens/vente/utils/logo_loader.dart'; // Initialisation du logo PDF
import 'package:apisavana_gestion/screens/commercialisation/commer_home.dart';
import 'package:apisavana_gestion/screens/conditionnement/condionnement_home.dart';
import 'package:apisavana_gestion/screens/collecte_de_donnes/historiques_collectes.dart';
import 'package:apisavana_gestion/screens/controle_de_donnes/controle_de_donnes_advanced.dart';
import 'package:apisavana_gestion/screens/collecte_de_donnes/nos_collecte_recoltes/nouvelle_collecte_recolte.dart';
// import 'package:apisavana_gestion/screens/collecte_de_donnes/collecte_donnes.dart'; // ANCIEN CODE - DÉSACTIVÉ

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Windows: Configuration spéciale pour éviter les erreurs de canal
  if (defaultTargetPlatform == TargetPlatform.windows) {
    // Attendre que l'engine soit complètement initialisé
    await Future.delayed(const Duration(milliseconds: 200));
  }

  // Lance une app de boot qui initialisera Firebase et les services après le premier frame
  runApp(const BootApp());
}

class ApisavanaApp extends StatelessWidget {
  const ApisavanaApp({super.key});

  // Init now handled entirely in main() for desktop stability

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Apisavana',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        // Police globale définie via pubspec.yaml
        fontFamily: 'OpenSans',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthWrapper(),
      getPages: [
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/dashboard', page: () => const DashboardPage()),
        GetPage(name: '/signup', page: () => const SignupPage()),
        GetPage(
            name: '/collecte', page: () => const NouvelleCollecteRecoltePage()),
        GetPage(
            name: '/nouvelle_collecte_recolte',
            page: () => const NouvelleCollecteRecoltePage()),
        GetPage(
            name: '/historiques_collectes',
            page: () => HistoriquesCollectesPage()),
        GetPage(name: '/controle', page: () => const ControlePageDashboard()),
        GetPage(name: '/extraction', page: () => ExtractionPage()),
        GetPage(name: '/filtrage', page: () => const FiltrageMainPage()),
        GetPage(
            name: '/conditionnement', page: () => ConditionnementHomePage()),
        GetPage(
            name: '/gestion_de_ventes',
            page: () => CommercialisationHomePage()),
        GetPage(name: '/caisse', page: () => const EspaceCaissierPage()),
      ],
    );
  }
}

class BootApp extends StatefulWidget {
  const BootApp({super.key});

  @override
  State<BootApp> createState() => _BootAppState();
}

class _BootAppState extends State<BootApp> {
  Object? _error;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    // Démarrer l'initialisation juste après le premier frame pour garantir que
    // l'engine et les plugins Windows sont entièrement prêts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Windows: Attendre un peu plus longtemps pour éviter les race conditions
      if (defaultTargetPlatform == TargetPlatform.windows) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _initAll();
        });
      } else {
        _initAll();
      }
    });
  }

  Future<void> _initAll() async {
    try {
      // Appliquer les corrections Windows
      await WindowsChannelFix.applyWindowsFixes();

      // Initialisation Firebase avec fallback Windows
      final firebaseSuccess =
          await FirebaseWindowsFallback.initializeWithFallback();

      if (!firebaseSuccess) {
        print('⚠️ Application démarrée sans Firebase (mode dégradé)');
        print('⚠️ Certaines fonctionnalités peuvent être limitées');
      }

      // Attendre un peu après Firebase pour laisser les plugins se stabiliser
      await Future.delayed(const Duration(milliseconds: 300));

      // Locales et assets (après Firebase)
      try {
        await initializeDateFormatting('fr_FR', null);
        print('✅ Locales initialisées');
      } catch (e) {
        print('⚠️ Erreur locales (non critique): $e');
      }

      try {
        await ApiSavanaLogoLoader.ensureLoaded(
            assetPath: 'assets/logo/logo.jpeg');
        print('✅ Logo chargé');
      } catch (e) {
        print('⚠️ Erreur logo (non critique): $e');
      }

      // Services dépendants de Firebase (avec gestion d'erreur)
      if (FirebaseWindowsFallback.isAvailable) {
        try {
          Get.put(UserSession());
          print('✅ UserSession initialisé');
        } catch (e) {
          print('⚠️ Erreur UserSession: $e');
        }

        try {
          Get.put(ConditionnementDbService());
          print('✅ ConditionnementDbService initialisé');
        } catch (e) {
          print('⚠️ Erreur ConditionnementDbService: $e');
        }
      } else {
        print('⚠️ Services Firebase ignorés (Firebase non disponible)');
      }

      if (mounted) setState(() => _ready = true);
      print('✅ Application prête');
    } catch (e) {
      print('❌ Erreur critique lors de l\'initialisation: $e');
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Erreur d\'initialisation',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text('$_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _error = null);
                      _initAll();
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Démarrage d\'Apisavana…'),
              ],
            ),
          ),
        ),
      );
    }

    // App prête
    return const ApisavanaApp();
  }
}
