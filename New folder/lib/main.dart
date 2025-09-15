// import 'package:apisavana_gestion/screens/collecte_de_donnes/collecte_donnes.dart'; // ANCIEN CODE - DÉSACTIVÉ
import 'package:apisavana_gestion/screens/collecte_de_donnes/nos_collecte_recoltes/nouvelle_collecte_recolte.dart';
import 'package:apisavana_gestion/screens/collecte_de_donnes/historiques_collectes.dart';
import 'package:apisavana_gestion/screens/commercialisation/commer_home.dart';
import 'package:apisavana_gestion/screens/conditionnement/condionnement_home.dart';
import 'package:apisavana_gestion/screens/controle_de_donnes/controle_de_donnes_advanced.dart';
import 'package:apisavana_gestion/screens/dashboard/dashboard.dart';
import 'package:apisavana_gestion/screens/extraction_page/extraction.dart';
import 'package:apisavana_gestion/screens/filtrage/filtrage_main_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'authentication/login.dart';
import 'authentication/sign_up.dart';
import 'authentication/user_session.dart';
import 'utils/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCQVVqssk1aMPh5cgJi2a3XAqFJ2_cOXPc",
      authDomain: "apisavana-bf-226.firebaseapp.com",
      projectId: "apisavana-bf-226",
      storageBucket: "apisavana-bf-226.firebasestorage.app",
      messagingSenderId: "955408721623",
      appId: "1:955408721623:web:e78c39e6801db32545b292",
      measurementId: "G-NH4D0Q9NTS",
    ),
  );

  await initializeDateFormatting('fr_FR', null);

  Get.put(UserSession());

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
        fontFamily: 'Montserrat',
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
      ],
    );
  }
}
