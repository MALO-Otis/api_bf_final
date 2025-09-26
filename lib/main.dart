import 'package:get/get.dart';
import 'firebase_options.dart';
import 'utils/auth_wrapper.dart';
import 'authentication/login.dart';
import 'authentication/sign_up.dart';
import 'package:flutter/material.dart';
import 'authentication/user_session.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/push_notifications_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
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
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Important: configure Firestore BEFORE any Firestore usage (services, listeners...)
  // Mitigation for Firestore JS 11.9.x INTERNAL ASSERTION on some hosts (e.g., Vercel):
  // - Disable persistence on web
  // - Auto-detect long polling (falls back when WebChannel/WebSockets are blocked)
  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
      // Force long polling to avoid WebChannel/WebSocket issues on some hosts
      webExperimentalForceLongPolling: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  await initializeDateFormatting('fr_FR', null);

  // Chargement du logo pour les PDF (doit précéder toute génération de PDF)
  // Fournir le chemin exact si nécessaire, sinon il testera les candidats.
  await ApiSavanaLogoLoader.ensureLoaded(assetPath: 'assets/logo/logo.jpeg');

  // Initialiser les services
  Get.put(UserSession());
  Get.put(ConditionnementDbService());

  // Init push notifications (FCM)
  await PushNotificationsService.instance.init();

  runApp(const ApisavanaApp());
}

class ApisavanaApp extends StatelessWidget {
  const ApisavanaApp({super.key});

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
      // Utilisation de l'AuthWrapper comme page d'accueil
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
