import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:get/get.dart';
import 'package:apisavana_gestion/authentication/user_session.dart';
import 'package:apisavana_gestion/utils/smart_appbar.dart';
import 'nos_collecte_recoltes/edit_collecte_recolte.dart';
import 'nos_collecte_recoltes/nouvelle_collecte_recolte.dart';
import 'nouvelle_collecte_scoop.dart';
import 'nouvelle_collecte_individuelle.dart' hide SizedBox;
import 'nos_collectes_individuels/edit_collecte_individuelle.dart';
import 'nos_achats_scoop/nouvel_achat_scoop.dart';
import 'nos_achats_scoop/edit_achat_scoop.dart';
import '../dashboard/dashboard.dart';
import 'nos_achats_scoop_contenants/nouvel_achat_scoop_contenants.dart';
import 'nos_collecte_mielleurie/nouvelle_collecte_miellerie.dart';

class HistoriquesCollectesPage extends StatefulWidget {
  const HistoriquesCollectesPage({Key? key}) : super(key: key);

  @override
  State<HistoriquesCollectesPage> createState() =>
      _HistoriquesCollectesPageState();
}

class _HistoriquesCollectesPageState extends State<HistoriquesCollectesPage>
    with TickerProviderStateMixin {
  // Types de collectes
  static const List<String> typesCollectes = [
    'Tous',
    'Récoltes',
    'Achat SCOOP',
    'Achat Individuel',
    'Achat dans miellerie'
  ];

  // Données utilisateur
  UserSession? userSession;
  Map<String, dynamic>? currentUserData;
  bool isLoadingUserData = true;

  // État actuel
  String selectedType = 'Tous';
  List<Map<String, dynamic>> collectes = [];
  List<Map<String, dynamic>> collectesFiltered = [];
  bool isLoading = false;
  String? searchQuery;

  // Filtres avancés
  String? filterSite;
  String? filterTechnician;
  String? filterStatus;
  DateTimeRange? filterDateRange;

  // Listes pour les filtres
  List<String> availableSites = [];
  List<String> availableTechnicians = [];
  List<String> availableStatuses = ['en_attente', 'valide', 'rejete'];

  // Palette couleurs
  static const Color kPrimaryColor = Color(0xFFF49101);
  static const Color kAccentColor = Color(0xFF0066CC);

  // Contrôleurs d'animation
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Contrôleur de recherche
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeUserData();
    _searchController.addListener(_onSearchChanged);
  }

  // Initialisation des données utilisateur
  Future<void> _initializeUserData() async {
    setState(() => isLoadingUserData = true);

    try {
      // Récupérer l'utilisateur connecté
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer les données de l'utilisateur depuis Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('Données utilisateur non trouvées');
      }

      currentUserData = userDoc.data()!;

      // Récupérer la session utilisateur depuis GetX
      try {
        userSession = Get.find<UserSession>();
      } catch (e) {
        // Si la session n'existe pas encore, la créer
        print('Session utilisateur non trouvée, création...');
      }

      // Charger les collectes
      await _loadCollectes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Erreur lors du chargement des données utilisateur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoadingUserData = false);
    }
  }

  void _initAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimationController.forward();
    _slideAnimationController.forward();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchController.text.trim().toLowerCase();
      _applyFilters();
    });
  }

  Future<void> _loadCollectes() async {
    setState(() => isLoading = true);

    try {
      // Récupérer le site de l'utilisateur
      final userSite = currentUserData?['site'] ?? userSession?.site;

      if (userSite == null || userSite.isEmpty) {
        throw Exception('Site utilisateur non défini');
      }

      final List<Map<String, dynamic>> allCollectes = [];

      // 1. Charger les collectes de récolte depuis la collection du site
      await _loadCollectesRecolte(userSite, allCollectes);

      // 2. Charger les collectes SCOOP
      await _loadCollectesSCOOP(userSite, allCollectes);

      // 3. Charger les collectes Individuelles
      await _loadCollectesIndividuel(userSite, allCollectes);

      // 4. Charger les collectes Miellerie
      await _loadCollectesMiellerie(userSite, allCollectes);

      // Extraire les sites, techniciens distincts pour les filtres
      final sites = <String>{userSite}; // Seul le site de l'utilisateur
      final technicians = <String>{};

      for (final collecte in allCollectes) {
        if (collecte['technicien_nom'] != null &&
            collecte['technicien_nom'].toString().isNotEmpty) {
          technicians.add(collecte['technicien_nom'].toString());
        }
      }

      setState(() {
        collectes = allCollectes;
        availableSites = sites.toList()..sort();
        availableTechnicians = technicians.toList()..sort();
        _applyFilters();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Charger les collectes de récolte
  Future<void> _loadCollectesRecolte(
      String userSite, List<Map<String, dynamic>> allCollectes) async {
    try {
      final recoltesSnapshot = await FirebaseFirestore.instance
          .collection(userSite) // Collection nommée selon le site
          .doc('collectes_recolte') // Document principal
          .collection('collectes_recolte') // Sous-collection
          .orderBy('createdAt', descending: true)
          .get();

      for (final doc in recoltesSnapshot.docs) {
        final data = doc.data();
        allCollectes.add({
          'id': doc.id,
          'type': 'Récoltes',
          'collection': '$userSite/collectes_recolte/collectes_recolte',
          'date': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'site': data['site'] ?? userSite,
          'technicien_nom': data['technicien_nom'] ?? '',
          'totalWeight': data['totalWeight'] ?? 0,
          'totalAmount': data['totalAmount'] ?? 0,
          'status': data['status'] ?? 'en_attente',
          'contenants': data['contenants'] ?? [],
          'region': data['region'] ?? '',
          'province': data['province'] ?? '',
          'commune': data['commune'] ?? '',
          'village': data['village'] ?? '',
          'predominances_florales': data['predominances_florales'] ?? [],
          ...data,
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des récoltes depuis $userSite : $e');

      // Fallback : essayer de charger depuis l'ancienne collection globale
      try {
        final recoltesSnapshot = await FirebaseFirestore.instance
            .collection('collectes_recolte')
            .where('site', isEqualTo: userSite)
            .orderBy('createdAt', descending: true)
            .get();

        for (final doc in recoltesSnapshot.docs) {
          final data = doc.data();
          allCollectes.add({
            'id': doc.id,
            'type': 'Récoltes',
            'collection': 'collectes_recolte',
            'date':
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            'site': data['site'] ?? userSite,
            'technicien_nom': data['technicien_nom'] ?? '',
            'totalWeight': data['totalWeight'] ?? 0,
            'totalAmount': data['totalAmount'] ?? 0,
            'status': data['status'] ?? 'en_attente',
            'contenants': data['contenants'] ?? [],
            'region': data['region'] ?? '',
            'province': data['province'] ?? '',
            'commune': data['commune'] ?? '',
            'village': data['village'] ?? '',
            'predominances_florales': data['predominances_florales'] ?? [],
            ...data,
          });
        }
      } catch (fallbackError) {
        print('Erreur fallback récoltes : $fallbackError');
      }
    }
  }

  // Charger les collectes SCOOP
  Future<void> _loadCollectesSCOOP(
      String userSite, List<Map<String, dynamic>> allCollectes) async {
    try {
      // Nouveau chemin prioritaire
      try {
        final snap = await FirebaseFirestore.instance
            .collection('Sites')
            .doc(userSite)
            .collection('nos_achats_scoop')
            .orderBy('created_at', descending: true)
            .get();
        for (final doc in snap.docs) {
          final data = doc.data();
          allCollectes.add({
            'id': doc.id,
            'type': 'Achat SCOOP',
            'collection': 'Sites/$userSite/nos_achats_scoop',
            'date': (data['date_achat'] as Timestamp?)?.toDate() ??
                (data['created_at'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            'site': userSite,
            'technicien_nom': data['collecteur_nom'] ?? '',
            'scoop_name': data['scoop_nom'] ?? '',
            'totalWeight': data['poids_total'] ?? 0,
            'totalAmount': data['montant_total'] ?? 0,
            'status': data['statut'] ?? 'collecte_terminee',
            'details': data['contenants'] ?? [],
            ...data,
          });
        }
      } catch (e) {
        print('Erreur chargement nos_achats_scoop: $e');
        // Anciens chemins fallback
        try {
          final scoopSnapshot = await FirebaseFirestore.instance
              .collection(userSite)
              .doc('collectes_scoop')
              .collection('collectes_scoop')
              .orderBy('createdAt', descending: true)
              .get();

          for (final doc in scoopSnapshot.docs) {
            final data = doc.data();
            allCollectes.add({
              'id': doc.id,
              'type': 'Achat SCOOP',
              'collection': '$userSite/collectes_scoop/collectes_scoop',
              'date':
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'site': data['site'] ?? userSite,
              'technicien_nom':
                  data['technicien_nom'] ?? data['nom_technicien'] ?? '',
              'scoop_name': data['scoop_name'] ?? data['nom_scoop'] ?? '',
              'totalWeight':
                  data['totalWeight'] ?? data['quantite_totale'] ?? 0,
              'totalAmount': data['totalAmount'] ?? data['montant_total'] ?? 0,
              'status': data['status'] ?? 'en_attente',
              'details': data['details'] ?? data['produits'] ?? [],
              ...data,
            });
          }
        } catch (e2) {
          print('Erreur chargement SCOOP (legacy 1): $e2');
          final collectesSnapshot = await FirebaseFirestore.instance
              .collection('collectes')
              .where('site', isEqualTo: userSite)
              .where('type', isEqualTo: 'achat')
              .get();

          for (final doc in collectesSnapshot.docs) {
            final data = doc.data();
            final scoopSubcollection =
                await doc.reference.collection('SCOOP').limit(1).get();
            if (scoopSubcollection.docs.isNotEmpty) {
              final scoopData = scoopSubcollection.docs.first.data();
              allCollectes.add({
                'id': doc.id,
                'type': 'Achat SCOOP',
                'collection': 'collectes',
                'date': (data['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                'site': data['site'] ?? userSite,
                'technicien_nom': data['technicien_nom'] ?? '',
                'scoop_name': scoopData['nomScoops'] ?? '',
                'totalWeight': scoopData['quantite_totale'] ?? 0,
                'totalAmount': scoopData['montant_total'] ?? 0,
                'status': data['status'] ?? 'en_attente',
                'details': scoopData['details'] ?? [],
                ...data,
                ...scoopData,
              });
            }
          }
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des collectes SCOOP : $e');
    }
  }

  // Charger les collectes Individuelles
  Future<void> _loadCollectesIndividuel(
      String userSite, List<Map<String, dynamic>> allCollectes) async {
    try {
      // Charger depuis la nouvelle structure : Sites/{nomSite}/nos_achats_individuels
      try {
        final individuelSnapshot = await FirebaseFirestore.instance
            .collection('Sites')
            .doc(userSite)
            .collection('nos_achats_individuels')
            .orderBy('created_at', descending: true)
            .get();

        for (final doc in individuelSnapshot.docs) {
          final data = doc.data();
          allCollectes.add({
            'id': doc.id,
            'type': 'Achat Individuel',
            'collection': 'Sites/$userSite/nos_achats_individuels',
            'date': (data['created_at'] as Timestamp?)?.toDate() ??
                (data['date_achat'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            'site': userSite,
            'technicien_nom': data['collecteur_nom'] ?? '',
            'producteur_nom': data['nom_producteur'] ?? '',
            'totalWeight': data['poids_total'] ?? 0,
            'totalAmount': data['montant_total'] ?? 0,
            'status': data['statut'] ?? 'collecte_terminee',
            'details': data['contenants'] ?? [],
            'origines_florales': data['origines_florales'] ?? [],
            'nombre_contenants': data['nombre_contenants'] ?? 0,
            'observations': data['observations'] ?? '',
            ...data,
          });
        }
      } catch (e) {
        print('Erreur chargement Individuel depuis Sites/$userSite : $e');

        // Fallback : ancienne structure
        try {
          final individuelSnapshot = await FirebaseFirestore.instance
              .collection(userSite)
              .doc('collectes_individuel')
              .collection('collectes_individuel')
              .orderBy('createdAt', descending: true)
              .get();

          for (final doc in individuelSnapshot.docs) {
            final data = doc.data();
            allCollectes.add({
              'id': doc.id,
              'type': 'Achat Individuel',
              'collection':
                  '$userSite/collectes_individuel/collectes_individuel',
              'date':
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'site': data['site'] ?? userSite,
              'technicien_nom':
                  data['technicien_nom'] ?? data['nom_technicien'] ?? '',
              'producteur_nom':
                  data['producteur_nom'] ?? data['nom_producteur'] ?? '',
              'totalWeight':
                  data['totalWeight'] ?? data['quantite_totale'] ?? 0,
              'totalAmount': data['totalAmount'] ?? data['montant_total'] ?? 0,
              'status': data['status'] ?? 'en_attente',
              'details': data['details'] ?? data['produits'] ?? [],
              ...data,
            });
          }
        } catch (fallbackError) {
          print('Erreur fallback collectes individuelles : $fallbackError');
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des collectes Individuelles : $e');
    }
  }

  // Charger les collectes Miellerie
  Future<void> _loadCollectesMiellerie(
      String userSite, List<Map<String, dynamic>> allCollectes) async {
    try {
      // Essayer depuis la collection du site d'abord
      try {
        final miellerieSnapshot = await FirebaseFirestore.instance
            .collection(userSite)
            .doc('collectes_miellerie')
            .collection('collectes_miellerie')
            .orderBy('createdAt', descending: true)
            .get();

        for (final doc in miellerieSnapshot.docs) {
          final data = doc.data();
          allCollectes.add({
            'id': doc.id,
            'type': 'Achat dans miellerie',
            'collection': '$userSite/collectes_miellerie/collectes_miellerie',
            'date':
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            'site': data['site'] ?? userSite,
            'technicien_nom':
                data['technicien_nom'] ?? data['nom_technicien'] ?? '',
            'miellerie_nom':
                data['miellerie_nom'] ?? data['nom_miellerie'] ?? '',
            'totalWeight': data['totalWeight'] ?? data['quantite_totale'] ?? 0,
            'totalAmount': data['totalAmount'] ?? data['montant_total'] ?? 0,
            'status': data['status'] ?? 'en_attente',
            'details': data['details'] ?? data['produits'] ?? [],
            ...data,
          });
        }
      } catch (e) {
        print('Erreur chargement Miellerie depuis $userSite : $e');

        // Fallback : essayer depuis une collection globale si elle existe
        try {
          final miellerieSnapshot = await FirebaseFirestore.instance
              .collection('collectes_miellerie')
              .where('site', isEqualTo: userSite)
              .orderBy('createdAt', descending: true)
              .get();

          for (final doc in miellerieSnapshot.docs) {
            final data = doc.data();
            allCollectes.add({
              'id': doc.id,
              'type': 'Achat dans miellerie',
              'collection': 'collectes_miellerie',
              'date':
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'site': data['site'] ?? userSite,
              'technicien_nom': data['technicien_nom'] ?? '',
              'miellerie_nom': data['miellerie_nom'] ?? '',
              'totalWeight': data['totalWeight'] ?? 0,
              'totalAmount': data['totalAmount'] ?? 0,
              'status': data['status'] ?? 'en_attente',
              'details': data['details'] ?? [],
              ...data,
            });
          }
        } catch (fallbackError) {
          print('Erreur fallback miellerie : $fallbackError');
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des collectes Miellerie : $e');
    }
  }

  // Méthode pour rafraîchir les données en temps réel
  Future<void> _refreshData() async {
    if (!isLoadingUserData) {
      await _loadCollectes();
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(collectes);

    // Filtre par type
    if (selectedType != 'Tous') {
      filtered = filtered.where((c) => c['type'] == selectedType).toList();
    }

    // Filtre par site
    if (filterSite != null && filterSite!.isNotEmpty) {
      filtered = filtered.where((c) => c['site'] == filterSite).toList();
    }

    // Filtre par technicien
    if (filterTechnician != null && filterTechnician!.isNotEmpty) {
      filtered = filtered
          .where((c) => c['technicien_nom'] == filterTechnician)
          .toList();
    }

    // Filtre par statut
    if (filterStatus != null && filterStatus!.isNotEmpty) {
      filtered = filtered.where((c) => c['status'] == filterStatus).toList();
    }

    // Filtre par recherche textuelle
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      filtered = filtered.where((c) {
        final searchableText = [
          c['site']?.toString() ?? '',
          c['technicien_nom']?.toString() ?? '',
          c['type']?.toString() ?? '',
          c['status']?.toString() ?? '',
        ].join(' ').toLowerCase();
        return searchableText.contains(searchQuery!);
      }).toList();
    }

    // Filtre par plage de dates
    if (filterDateRange != null) {
      filtered = filtered.where((c) {
        final date = c['date'] as DateTime?;
        if (date == null) return false;
        return date.isAfter(
                filterDateRange!.start.subtract(const Duration(days: 1))) &&
            date.isBefore(filterDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    setState(() {
      collectesFiltered = filtered;
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    // Afficher un indicateur de chargement pendant l'initialisation
    if (isLoadingUserData) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: SmartAppBar(
          title: 'Historiques des collectes',
          backgroundColor: kPrimaryColor,
          onBackPressed: () =>
              Get.offAllNamed('/dashboard'), // Retour explicite au dashboard
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
              ),
              SizedBox(height: 16),
              Text('Chargement des données utilisateur...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: kPrimaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildHeader(),
                  _buildFilters(),
                  _buildCollectesList(),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return SmartAppBar(
      title: 'Historiques des collectes',
      backgroundColor: _HistoriquesCollectesPageState.kPrimaryColor,
      onBackPressed: () =>
          Get.offAllNamed('/dashboard'), // Retour explicite au dashboard
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _refreshData,
          tooltip: 'Actualiser',
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showAdvancedFilters,
          tooltip: 'Filtres avancés',
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            kPrimaryColor,
            kPrimaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Statistiques rapides
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total',
                    collectes.length.toString(),
                    Icons.inventory,
                    Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Filtrées',
                    collectesFiltered.length.toString(),
                    Icons.filter_list,
                    Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'En attente',
                    collectes
                        .where((c) => c['status'] == 'en_attente')
                        .length
                        .toString(),
                    Icons.pending,
                    Colors.orange.shade100,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Barre de recherche
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher par site, technicien...',
                  prefixIcon: const Icon(Icons.search, color: kPrimaryColor),
                  suffixIcon: searchQuery != null && searchQuery!.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: kPrimaryColor, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _HistoriquesCollectesPageState.kPrimaryColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: kPrimaryColor.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Types de collectes
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: typesCollectes.length,
              itemBuilder: (context, index) {
                final type = typesCollectes[index];
                final isSelected = selectedType == type;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(
                      type,
                      style: TextStyle(
                        color: isSelected ? Colors.white : kPrimaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selectedType = type;
                        _applyFilters();
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: kPrimaryColor,
                    side: BorderSide(color: kPrimaryColor),
                    elevation: isSelected ? 4 : 0,
                    shadowColor: kPrimaryColor.withOpacity(0.3),
                  ),
                );
              },
            ),
          ),

          // Filtres actifs
          if (_hasActiveFilters()) ...[
            const SizedBox(height: 12),
            _buildActiveFilters(),
          ],
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return filterSite != null ||
        filterTechnician != null ||
        filterStatus != null ||
        filterDateRange != null;
  }

  Widget _buildActiveFilters() {
    return Container(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (filterSite != null)
            _buildActiveFilterChip('Site: $filterSite', () {
              setState(() {
                filterSite = null;
                _applyFilters();
              });
            }),
          if (filterTechnician != null)
            _buildActiveFilterChip('Technicien: $filterTechnician', () {
              setState(() {
                filterTechnician = null;
                _applyFilters();
              });
            }),
          if (filterStatus != null)
            _buildActiveFilterChip('Statut: ${_getStatusLabel(filterStatus!)}',
                () {
              setState(() {
                filterStatus = null;
                _applyFilters();
              });
            }),
          if (filterDateRange != null)
            _buildActiveFilterChip(
              'Période: ${DateFormat('dd/MM').format(filterDateRange!.start)} - ${DateFormat('dd/MM').format(filterDateRange!.end)}',
              () {
                setState(() {
                  filterDateRange = null;
                  _applyFilters();
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onRemove,
        backgroundColor: kAccentColor.withOpacity(0.1),
        side: BorderSide(color: kAccentColor.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildCollectesList() {
    if (isLoading) {
      return Container(
        height: 300,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement des collectes...'),
            ],
          ),
        ),
      );
    }

    if (collectesFiltered.isEmpty) {
      return Container(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune collecte trouvée',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Modifiez vos filtres ou créez une nouvelle collecte',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle collecte'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _HistoriquesCollectesPageState.kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed('/nouvelle_collecte_recolte');
                },
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: collectesFiltered.length,
      itemBuilder: (context, index) {
        final collecte = collectesFiltered[index];
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOutCubic,
          child: _buildCollecteCard(collecte, index),
        );
      },
    );
  }

  Widget _buildCollecteCard(Map<String, dynamic> collecte, int index) {
    final type = collecte['type'] ?? '';
    final isAchat = type.contains('Achat');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Header avec type et statut
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getTypeGradient(type),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getTypeIcon(type),
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy à HH:mm')
                                .format(collecte['date']),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(collecte['status']),
                  ],
                ),
              ),

              // Contenu principal
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Informations principales
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoRow(
                            Icons.location_on,
                            'Site',
                            collecte['site'] ?? 'Non défini',
                          ),
                        ),
                        Expanded(
                          child: _buildInfoRow(
                            Icons.person,
                            'Technicien',
                            collecte['technicien_nom'] ?? 'Non défini',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Métriques
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildMetricItem(
                              'Poids total',
                              '${collecte['totalWeight']?.toStringAsFixed(1) ?? '0'} kg',
                              Icons.scale,
                              Colors.blue,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey.shade300,
                          ),
                          Expanded(
                            child: _buildMetricItem(
                              'Montant',
                              '${(collecte['totalAmount'] ?? 0).toStringAsFixed(0)} FCFA',
                              Icons.attach_money,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Informations spécifiques au type d'achat
                    if (isAchat) ...[
                      const SizedBox(height: 12),
                      _buildAchatSpecificInfo(collecte),
                    ],

                    const SizedBox(height: 16),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.visibility),
                            label: const Text('Détails'),
                            onPressed: () =>
                                _showCollecteDetails(context, collecte),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kAccentColor,
                              side: BorderSide(color: kAccentColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text('Modifier'),
                            onPressed: () => _editCollecte(collecte),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kPrimaryColor,
                              side: BorderSide(color: kPrimaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          color: Colors.red,
                          onPressed: () => _deleteCollecte(collecte),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getTypeGradient(String type) {
    switch (type) {
      case 'Récoltes':
        return [Colors.green.shade600, Colors.green.shade400];
      case 'Achat SCOOP':
        return [Colors.blue.shade600, Colors.blue.shade400];
      case 'Achat Individuel':
        return [Colors.orange.shade600, Colors.orange.shade400];
      case 'Achat dans miellerie':
        return [Colors.purple.shade600, Colors.purple.shade400];
      default:
        return [Colors.grey.shade600, Colors.grey.shade400];
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Récoltes':
        return Icons.eco;
      case 'Achat SCOOP':
        return Icons.group;
      case 'Achat Individuel':
        return Icons.person;
      case 'Achat dans miellerie':
        return Icons.store;
      default:
        return Icons.inventory;
    }
  }

  Widget _buildStatusChip(String? status) {
    final color = _getStatusColor(status);
    final label = _getStatusLabel(status ?? '');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildAchatSpecificInfo(Map<String, dynamic> collecte) {
    final type = collecte['type'];

    if (type == 'Achat SCOOP') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          children: [
            _buildInfoRow(
              Icons.group,
              'SCOOP',
              collecte['scoop_name'] ?? 'Non défini',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    Icons.people,
                    'Producteurs',
                    '${collecte['nombre_producteurs'] ?? 0}',
                  ),
                ),
                Expanded(
                  child: _buildInfoRow(
                    Icons.star,
                    'Qualité',
                    collecte['qualite'] ?? 'Standard',
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (type == 'Achat Individuel') {
      final originesFlorales =
          collecte['origines_florales'] as List<dynamic>? ?? [];
      final nombreContenants = collecte['nombre_contenants'] ?? 0;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              Icons.person,
              'Producteur',
              collecte['producteur_nom'] ?? 'Non défini',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    Icons.inventory,
                    'Contenants',
                    '$nombreContenants',
                  ),
                ),
                Expanded(
                  child: _buildInfoRow(
                    Icons.local_florist,
                    'Origines',
                    '${originesFlorales.length}',
                  ),
                ),
              ],
            ),
            if (originesFlorales.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Origines florales:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: originesFlorales
                    .take(3)
                    .map(
                      (origine) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Text(
                          origine.toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              if (originesFlorales.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+ ${originesFlorales.length - 3} autre(s)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
            if (collecte['observations'] != null &&
                collecte['observations'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.note,
                'Observations',
                collecte['observations'].toString(),
              ),
            ],
          ],
        ),
      );
    } else if (type == 'Achat dans miellerie') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Column(
          children: [
            _buildInfoRow(
              Icons.store,
              'Miellerie',
              collecte['miellerie_nom'] ?? 'Non défini',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.location_on,
              'Adresse',
              collecte['miellerie_adresse'] ?? 'Non défini',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    Icons.inventory,
                    'Type',
                    collecte['type_achat'] ?? 'Stock',
                  ),
                ),
                Expanded(
                  child: _buildInfoRow(
                    Icons.star,
                    'Qualité',
                    collecte['qualite'] ?? 'Standard',
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        _showNewCollecteMenu();
      },
      backgroundColor: _HistoriquesCollectesPageState.kPrimaryColor,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text(
        'Nouvelle collecte',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  // Afficher le menu de sélection du type de collecte
  void _showNewCollecteMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choisir le type de collecte',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                _buildCollecteTypeOption(
                  icon: Icons.eco,
                  title: 'Collecte Récolte',
                  description: 'Collecte directe de miel chez les producteurs',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _navigateInDashboard('COLLECTE',
                        subModule: 'Nouvelle collecte');
                  },
                ),
                const SizedBox(height: 12),
                _buildCollecteTypeOption(
                  icon: Icons.person,
                  title: 'Achat Individuel',
                  description: 'Achat de miel chez un producteur individuel',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    _navigateInDashboard('COLLECTE',
                        subModule: 'Achats Individuels');
                  },
                ),
                const SizedBox(height: 12),
                _buildCollecteTypeOption(
                  icon: Icons.inventory,
                  title: 'Achat SCOOP - Contenants',
                  description: 'Achat de miel SCOOP par contenants détaillés',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _navigateInDashboard('COLLECTE',
                        subModule: 'Achats SCOOPS - Contenants');
                  },
                ),
                const SizedBox(height: 12),
                _buildCollecteTypeOption(
                  icon: Icons.factory,
                  title: 'Collecte Miellerie',
                  description:
                      'Collecte de miel auprès d\'une miellerie coopérative',
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.pop(context);
                    _navigateInDashboard('COLLECTE',
                        subModule: 'Collecte Mielleries');
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Option de type de collecte
  Widget _buildCollecteTypeOption({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // Méthodes pour les actions
  void _showAdvancedFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildAdvancedFiltersSheet(),
    );
  }

  Widget _buildAdvancedFiltersSheet() {
    String? localFilterSite = filterSite;
    String? localFilterTechnician = filterTechnician;
    String? localFilterStatus = filterStatus;
    DateTimeRange? localFilterDateRange = filterDateRange;

    return StatefulBuilder(
      builder: (context, setModalState) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.filter_list, color: kPrimaryColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Filtres avancés',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Filtre par site
                    DropdownSearch<String>(
                      items: availableSites,
                      selectedItem: localFilterSite,
                      onChanged: (v) {
                        setModalState(() => localFilterSite = v);
                      },
                      dropdownDecoratorProps: const DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: 'Filtrer par site',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      popupProps: const PopupProps.menu(showSearchBox: true),
                      clearButtonProps: const ClearButtonProps(isVisible: true),
                    ),
                    const SizedBox(height: 16),

                    // Filtre par technicien
                    DropdownSearch<String>(
                      items: availableTechnicians,
                      selectedItem: localFilterTechnician,
                      onChanged: (v) {
                        setModalState(() => localFilterTechnician = v);
                      },
                      dropdownDecoratorProps: const DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: 'Filtrer par technicien',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      popupProps: const PopupProps.menu(showSearchBox: true),
                      clearButtonProps: const ClearButtonProps(isVisible: true),
                    ),
                    const SizedBox(height: 16),

                    // Filtre par statut
                    DropdownButtonFormField<String?>(
                      value: localFilterStatus,
                      decoration: const InputDecoration(
                        labelText: 'Filtrer par statut',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Tous les statuts'),
                        ),
                        const DropdownMenuItem<String?>(
                          value: 'en_attente',
                          child: Text('En attente'),
                        ),
                        const DropdownMenuItem<String?>(
                          value: 'valide',
                          child: Text('Validé'),
                        ),
                        const DropdownMenuItem<String?>(
                          value: 'rejete',
                          child: Text('Rejeté'),
                        ),
                      ],
                      onChanged: (v) {
                        setModalState(() => localFilterStatus = v);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Boutons d'action
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                localFilterSite = null;
                                localFilterTechnician = null;
                                localFilterStatus = null;
                                localFilterDateRange = null;
                              });
                            },
                            child: const Text('Réinitialiser'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                filterSite = localFilterSite;
                                filterTechnician = localFilterTechnician;
                                filterStatus = localFilterStatus;
                                filterDateRange = localFilterDateRange;
                                _applyFilters();
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Appliquer'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCollecteDetails(
      BuildContext context, Map<String, dynamic> collecte) {
    showDialog(
      context: context,
      builder: (context) {
        final isMobile = MediaQuery.of(context).size.width < 420;
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 24, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700, maxHeight: 720),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Icon(_getTypeIcon(collecte['type']),
                        color: _HistoriquesCollectesPageState.kPrimaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Détails - ${collecte['type']}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: kPrimaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Contenu des détails
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailItem('ID', collecte['id']),
                        _buildDetailItem('Type', collecte['type']),
                        _buildDetailItem(
                            'Date',
                            DateFormat('dd/MM/yyyy à HH:mm')
                                .format(collecte['date'])),
                        _buildDetailItem('Site', collecte['site']),
                        _buildDetailItem(
                            'Technicien', collecte['technicien_nom']),
                        _buildDetailItem(
                            'Poids total', '${collecte['totalWeight']} kg'),
                        _buildDetailItem(
                            'Montant total', '${collecte['totalAmount']} FCFA'),
                        _buildDetailItem(
                            'Statut', _getStatusLabel(collecte['status'])),

                        // Informations spécifiques selon le type
                        if (collecte['type'] == 'Récoltes') ...[
                          const SizedBox(height: 16),
                          Text('Informations géographiques',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: kPrimaryColor)),
                          const SizedBox(height: 8),
                          _buildDetailItem('Région', collecte['region']),
                          _buildDetailItem('Province', collecte['province']),
                          _buildDetailItem('Commune', collecte['commune']),
                          _buildDetailItem('Village', collecte['village']),
                          if (collecte['predominances_florales'] != null &&
                              collecte['predominances_florales']
                                  .isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text('Prédominances florales',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: kPrimaryColor)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: (collecte['predominances_florales']
                                      as List)
                                  .map((f) => Chip(
                                        label: Text(f.toString(),
                                            style:
                                                const TextStyle(fontSize: 12)),
                                        backgroundColor:
                                            Colors.green.withOpacity(0.2),
                                      ))
                                  .toList(),
                            ),
                          ],
                          if (collecte['contenants'] != null &&
                              collecte['contenants'].isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text('Contenants',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: kPrimaryColor)),
                            const SizedBox(height: 8),
                            ...((collecte['contenants'] as List)
                                .asMap()
                                .entries
                                .map((entry) {
                              final idx = entry.key;
                              final contenant = entry.value;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text('${idx + 1}'),
                                    backgroundColor:
                                        kPrimaryColor.withOpacity(0.1),
                                  ),
                                  title: Text(
                                      '${contenant['hiveType']} - ${contenant['containerType']}'),
                                  subtitle: Text(
                                      '${contenant['weight']} kg à ${contenant['unitPrice']} FCFA/kg'),
                                  trailing: Text('${contenant['total']} FCFA',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                              );
                            }).toList()),
                          ],
                        ],
                        if (collecte['type'] == 'Achat SCOOP') ...[
                          const SizedBox(height: 16),
                          Text('Informations SCOOP',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: kPrimaryColor)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              children: [
                                _buildDetailItem('SCOOP',
                                    collecte['scoop_name'] ?? 'Non défini'),
                                _buildDetailItem(
                                    'Période',
                                    collecte['periode_collecte'] ??
                                        'Non définie'),
                                if (collecte['nombre_producteurs'] != null)
                                  _buildDetailItem('Producteurs',
                                      '${collecte['nombre_producteurs']}'),
                                if (collecte['qualite'] != null)
                                  _buildDetailItem(
                                      'Qualité', collecte['qualite']),
                                if (collecte['region'] != null ||
                                    collecte['province'] != null ||
                                    collecte['commune'] != null) ...[
                                  const Divider(),
                                  Text('Localisation',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade700,
                                      )),
                                  const SizedBox(height: 8),
                                  if (collecte['region'] != null)
                                    _buildDetailItem(
                                        'Région', collecte['region']),
                                  if (collecte['province'] != null)
                                    _buildDetailItem(
                                        'Province', collecte['province']),
                                  if (collecte['commune'] != null)
                                    _buildDetailItem(
                                        'Commune', collecte['commune']),
                                  if (collecte['village'] != null)
                                    _buildDetailItem(
                                        'Village', collecte['village']),
                                ],
                              ],
                            ),
                          ),
                          if (collecte['contenants'] != null &&
                              collecte['contenants'].isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                                'Contenants (${collecte['contenants'].length})',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: kPrimaryColor)),
                            const SizedBox(height: 8),
                            ...((collecte['contenants'] as List)
                                .asMap()
                                .entries
                                .map((entry) {
                              final idx = entry.key;
                              final contenant = entry.value;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        kPrimaryColor.withOpacity(0.1),
                                    child: Text('${idx + 1}'),
                                  ),
                                  title: Text(
                                      '${contenant['type_contenant'] ?? 'N/A'} - ${contenant['type_miel'] ?? 'N/A'}'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          'Quantité: ${contenant['quantite'] ?? 0} kg'),
                                      Text(
                                          'Prix unitaire: ${contenant['prix_unitaire'] ?? 0} CFA/kg'),
                                      if (contenant['predominance_florale'] !=
                                              null &&
                                          contenant['predominance_florale']
                                              .toString()
                                              .isNotEmpty)
                                        Text(
                                            'Florale: ${contenant['predominance_florale']}'),
                                    ],
                                  ),
                                  trailing: Text(
                                    '${contenant['montant_total'] ?? (contenant['quantite'] ?? 0) * (contenant['prix_unitaire'] ?? 0)} CFA',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              );
                            }).toList()),
                          ],
                        ],
                        if (collecte['type'] == 'Achat Individuel') ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person,
                                        color: Colors.orange),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        collecte['producteur_nom'] ??
                                            'Producteur inconnu',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if ((collecte['origines_florales']
                                            as List<dynamic>?)
                                        ?.isNotEmpty ==
                                    true) ...[
                                  Text('Origines florales',
                                      style: TextStyle(
                                          color: kPrimaryColor,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: (collecte['origines_florales']
                                            as List<dynamic>)
                                        .map((e) => Chip(
                                              label: Text(e.toString()),
                                              backgroundColor:
                                                  Colors.orange.shade100,
                                            ))
                                        .toList(),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                LayoutBuilder(builder: (context, cs) {
                                  final compact =
                                      cs.maxWidth < 340; // très petit mobile
                                  if (compact) {
                                    return Column(
                                      children: [
                                        _buildMetricItem(
                                            'Contenants',
                                            '${collecte['nombre_contenants'] ?? 0}',
                                            Icons.inventory,
                                            Colors.orange),
                                        const SizedBox(height: 6),
                                        _buildMetricItem(
                                            'Poids',
                                            '${(collecte['totalWeight'] ?? 0).toStringAsFixed(1)} kg',
                                            Icons.scale,
                                            Colors.blue),
                                        const SizedBox(height: 6),
                                        _buildMetricItem(
                                            'Montant',
                                            '${(collecte['totalAmount'] ?? 0).toStringAsFixed(0)} FCFA',
                                            Icons.attach_money,
                                            Colors.green),
                                      ],
                                    );
                                  }
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: _buildMetricItem(
                                            'Contenants',
                                            '${collecte['nombre_contenants'] ?? 0}',
                                            Icons.inventory,
                                            Colors.orange),
                                      ),
                                      Container(
                                          width: 1,
                                          height: 32,
                                          color: Colors.orange.shade200),
                                      Expanded(
                                        child: _buildMetricItem(
                                            'Poids',
                                            '${(collecte['totalWeight'] ?? 0).toStringAsFixed(1)} kg',
                                            Icons.scale,
                                            Colors.blue),
                                      ),
                                      Container(
                                          width: 1,
                                          height: 32,
                                          color: Colors.orange.shade200),
                                      Expanded(
                                        child: _buildMetricItem(
                                            'Montant',
                                            '${(collecte['totalAmount'] ?? 0).toStringAsFixed(0)} FCFA',
                                            Icons.attach_money,
                                            Colors.green),
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('Contenants',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: kPrimaryColor)),
                          const SizedBox(height: 6),
                          Builder(builder: (context) {
                            final details =
                                (collecte['details'] as List<dynamic>? ??
                                    const []);
                            double sommeMontant = 0;
                            double sommePoids = 0;
                            for (final d in details) {
                              final m = d as Map<String, dynamic>;
                              final qte = (m['quantite'] ?? m['weight'] ?? 0)
                                  .toDouble();
                              final pu =
                                  (m['prix_unitaire'] ?? m['unitPrice'] ?? 0)
                                      .toDouble();
                              final mt = (m['montant_total'] ??
                                      m['total'] ??
                                      (qte * pu))
                                  .toDouble();
                              sommePoids += qte;
                              sommeMontant += mt;
                            }
                            return Column(
                              children: [
                                // Sur mobile étroit, afficher chaque ligne en carte compacte
                                if (MediaQuery.of(context).size.width <
                                    360) ...[
                                  ...details.map((raw) {
                                    final m = raw as Map<String, dynamic>;
                                    final typeCont = m['type_contenant'] ??
                                        m['containerType'] ??
                                        '';
                                    final typeMiel =
                                        m['type_miel'] ?? m['honeyType'] ?? '';
                                    final qte =
                                        (m['quantite'] ?? m['weight'] ?? 0)
                                            .toDouble();
                                    final pu = (m['prix_unitaire'] ??
                                            m['unitPrice'] ??
                                            0)
                                        .toDouble();
                                    final mt = (m['montant_total'] ??
                                            m['total'] ??
                                            (qte * pu))
                                        .toDouble();
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        title: Text('$typeCont • $typeMiel'),
                                        subtitle: Text(
                                            '${qte.toStringAsFixed(1)} kg  •  ${pu.toStringAsFixed(0)} FCFA/kg'),
                                        trailing: Text(
                                            '${mt.toStringAsFixed(0)} FCFA',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700)),
                                      ),
                                    );
                                  }).toList(),
                                ] else ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: const [
                                        Expanded(
                                            flex: 2,
                                            child: Text('Contenant',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600))),
                                        Expanded(
                                            flex: 2,
                                            child: Text('Type de miel',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600))),
                                        Expanded(
                                            child: Text('Qté (kg)',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600))),
                                        Expanded(
                                            child: Text('PU',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600))),
                                        Expanded(
                                            child: Text('Montant',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600))),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ...details.map((raw) {
                                    final m = raw as Map<String, dynamic>;
                                    final typeCont = m['type_contenant'] ??
                                        m['containerType'] ??
                                        '';
                                    final typeMiel =
                                        m['type_miel'] ?? m['honeyType'] ?? '';
                                    final qte =
                                        (m['quantite'] ?? m['weight'] ?? 0)
                                            .toDouble();
                                    final pu = (m['prix_unitaire'] ??
                                            m['unitPrice'] ??
                                            0)
                                        .toDouble();
                                    final mt = (m['montant_total'] ??
                                            m['total'] ??
                                            (qte * pu))
                                        .toDouble();
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 12),
                                      margin: const EdgeInsets.only(bottom: 4),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                              color: Colors.grey.shade200),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                              flex: 2,
                                              child: Text(typeCont.toString())),
                                          Expanded(
                                              flex: 2,
                                              child: Text(typeMiel.toString())),
                                          Expanded(
                                              child:
                                                  Text(qte.toStringAsFixed(1))),
                                          Expanded(
                                              child:
                                                  Text(pu.toStringAsFixed(0))),
                                          Expanded(
                                              child: Text(mt.toStringAsFixed(0),
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600))),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ],
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value ?? 'Non défini'),
          ),
        ],
      ),
    );
  }

  // Méthode pour naviguer dans le dashboard
  void _navigateInDashboard(String moduleName, {String? subModule}) {
    try {
      final dashboardController = Get.find<DashboardController>();
      dashboardController.navigateTo(moduleName, subModule: subModule);
    } catch (e) {
      // Fallback si le controller n'est pas trouvé
      print('DashboardController non trouvé, navigation par Get.to');
      if (moduleName == 'COLLECTE') {
        if (subModule == 'Nouvelle collecte') {
          Get.to(() => NouvelleCollecteRecoltePage());
        } else if (subModule == 'Achats Individuels') {
          Get.to(() => const NouvelleCollecteIndividuellePage());
        } else if (subModule == 'Achats SCOOPS') {
          Get.to(() => const NouvelAchatScoopPage());
        } else if (subModule == 'Achats SCOOPS - Contenants') {
          Get.to(() => const NouvelAchatScoopContenantsPage());
        } else if (subModule == 'Collecte Mielleries') {
          Get.to(() => const NouvelleCollecteMielleriePage());
        }
      }
    }
  }

  void _editCollecte(Map<String, dynamic> collecte) {
    if (collecte['type'] == 'Récoltes') {
      Get.to(() => EditCollecteRecoltePage(collecteId: collecte['id']));
    } else if (collecte['type'] == 'Achat Individuel') {
      final docPath =
          'Sites/${collecte['site']}/nos_achats_individuels/${collecte['id']}';
      Get.to(() => EditCollecteIndividuellePage(documentPath: docPath));
    } else if (collecte['type'] == 'Achat SCOOP') {
      Get.to(() => EditAchatScoopPage(
            collecteId: collecte['id'],
            collection: collecte['collection'] ??
                'Sites/${collecte['site']}/nos_achats_scoop',
          ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'La modification de ce type de collecte n\'est pas encore disponible'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _deleteCollecte(Map<String, dynamic> collecte) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer cette collecte de type "${collecte['type']}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDelete(collecte);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(Map<String, dynamic> collecte) async {
    try {
      final collection = collecte['collection'] ?? 'collectes_recolte';
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(collecte['id'])
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Collecte supprimée avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      _loadCollectes(); // Recharger la liste
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Méthodes utilitaires pour les statuts
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'en_attente':
        return Colors.orange;
      case 'valide':
        return Colors.green;
      case 'rejete':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'en_attente':
        return 'En attente';
      case 'valide':
        return 'Validé';
      case 'rejete':
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }
}
