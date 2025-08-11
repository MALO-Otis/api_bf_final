import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:apisavana_gestion/data/geographe/geographie.dart';
import 'package:apisavana_gestion/data/personnel/personnel_apisavana.dart';
import 'package:apisavana_gestion/authentication/user_session.dart';
import 'package:apisavana_gestion/utils/smart_appbar.dart';

// Modèle pour un contenant de récolte
class HarvestContainer {
  String id;
  String hiveType;
  String containerType;
  double weight;
  double unitPrice;

  HarvestContainer({
    required this.id,
    required this.hiveType,
    required this.containerType,
    required this.weight,
    required this.unitPrice,
  });

  double get total => weight * unitPrice;
}

// Modèle pour les infos du site et du technicien
class SiteInfo {
  final String siteName;
  final String technicianName;
  // Ajout des champs région, province, commune, village pour Firestore
  final String region;
  final String province;
  final String commune;
  final String village;
  SiteInfo({
    required this.siteName,
    required this.technicianName,
    this.region = '',
    this.province = '',
    this.commune = '',
    this.village = '',
  });
}

class NouvelleCollecteRecoltePage extends StatefulWidget {
  final bool showBackToHistory;
  final VoidCallback? onBackToHistory;
  const NouvelleCollecteRecoltePage(
      {Key? key, this.showBackToHistory = false, this.onBackToHistory})
      : super(key: key);

  @override
  State<NouvelleCollecteRecoltePage> createState() =>
      _NouvelleCollecteRecoltePageState();
}

class _NouvelleCollecteRecoltePageState
    extends State<NouvelleCollecteRecoltePage> with SmartAppBarMixin {
  // Session utilisateur et infos dynamiques
  UserSession? userSession;
  Map<String, dynamic>? currentUserData;
  bool isLoadingUserData = true;

  // Liste dynamique des contenants
  List<HarvestContainer> containers = [];

  // Contrôleurs pour le formulaire d'ajout/édition
  final _formKey = GlobalKey<FormState>();
  String? hiveType;
  String? containerType;
  double? weight;
  double? unitPrice;
  String? editingId;

  // Feedback utilisateur
  String? statusMessage;
  bool isSubmitting = false;

  // Historique local (affiché après enregistrement)
  List<Map<String, dynamic>> history = [];

  // Historique Firestore (multi-utilisateur)
  List<Map<String, dynamic>> firestoreHistory = [];
  bool isLoadingHistory = false;

  // Filtres pour l'historique Firestore
  String? filterSite;
  String? filterTechnician;
  List<String> availableSites = [];
  List<String> availableTechnicians = [];

  // Palette couleurs
  static const Color kHighlightColor = Color(0xFFF49101);
  static const Color kValidationColor = Color(0xFF2D0C0D);

  // Calculs dynamiques
  double get totalWeight => containers.fold(0, (sum, c) => sum + c.weight);
  double get totalAmount => containers.fold(0, (sum, c) => sum + c.total);

  // Champs pour la sélection dynamique de la localité et du technicien
  String? selectedRegion;
  String? selectedProvince;
  String? selectedCommune;
  String? selectedVillage;
  String? selectedSite;
  String? selectedTechnician;
  List<String> selectedFlorales = [];

  // Variables pour les techniciens filtrés par site
  List<TechnicienInfo> availableTechniciensForSite = [];

  // Contrôleurs pour mise à jour automatique
  final TextEditingController technicianController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  // Initialisation des données utilisateur depuis Firestore
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
      userSession = Get.find<UserSession>();

      // Initialiser les valeurs par défaut depuis les données utilisateur
      selectedSite = currentUserData!['site'] ?? userSession?.site;
      selectedTechnician =
          '${currentUserData!['prenom'] ?? ''} ${currentUserData!['nom'] ?? ''}'
              .trim();

      // Charger les techniciens disponibles pour le site
      if (selectedSite != null) {
        _loadTechniciansForSite(selectedSite);
      }

      // Charger l'historique Firestore
      await fetchFirestoreHistory();
    } catch (e) {
      setState(() {
        statusMessage =
            'Erreur lors du chargement des données utilisateur : $e';
      });
    } finally {
      setState(() => isLoadingUserData = false);
    }
  }

  void _loadTechniciansForSite(String? site) {
    if (site != null) {
      availableTechniciensForSite = PersonnelUtils.getTechniciensBySite(site);
      // Si le technicien actuel n'est pas dans la liste des techniciens du site, on le reset
      if (selectedTechnician != null) {
        final techExists = availableTechniciensForSite
            .any((t) => t.nomComplet == selectedTechnician);
        if (!techExists) {
          selectedTechnician = null;
        }
      }
    } else {
      availableTechniciensForSite = [];
      selectedTechnician = null;
    }
  }

  @override
  void dispose() {
    technicianController.dispose();
    // Réinitialisation complète à la sortie de la page (seulement si le widget est encore monté)
    if (mounted) {
      _resetFormState();
    }
    super.dispose();
  }

  // Méthode pour gérer la navigation de retour avec réinitialisation
  void _handleBackNavigation() {
    if (mounted) {
      _resetFormState();
    }
    // Retour explicite au dashboard comme les autres pages du sidebar
    Get.offAllNamed('/dashboard');
  }

  Future<void> fetchFirestoreHistory() async {
    setState(() => isLoadingHistory = true);
    try {
      // Si nous avons des données utilisateur, récupérer depuis la collection du site
      if (currentUserData != null && selectedSite != null) {
        Query query = FirebaseFirestore.instance
            .collection(selectedSite!) // Collection nommée selon le site
            .doc('collectes_recolte') // Document principal
            .collection('collectes_recolte') // Sous-collection
            .orderBy('createdAt', descending: true)
            .limit(50);

        if (filterTechnician != null && filterTechnician!.isNotEmpty) {
          query = query.where('technicien_nom', isEqualTo: filterTechnician);
        }

        final snapshot = await query.get();
        firestoreHistory = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'date': (data['createdAt'] as Timestamp?)?.toDate(),
            'site': data['site'] ?? '',
            'totalWeight': data['totalWeight'] ?? 0,
            'totalAmount': data['totalAmount'] ?? 0,
            'status': data['status'] ?? '',
            'technicien_nom': data['technicien_nom'] ?? '',
            'contenants': data['contenants'] ?? [],
          };
        }).toList();

        // Récupérer les techniciens distincts pour les filtres
        final allTechs = <String>{};
        for (final h in firestoreHistory) {
          if ((h['technicien_nom'] ?? '').isNotEmpty)
            allTechs.add(h['technicien_nom']);
        }
        availableTechnicians = allTechs.toList()..sort();
        availableSites = [selectedSite!]; // Seul le site de l'utilisateur
      } else {
        // Fallback : charger depuis l'ancienne collection globale
        Query query = FirebaseFirestore.instance
            .collection('collectes_recolte')
            .orderBy('createdAt', descending: true)
            .limit(50);
        if (filterSite != null && filterSite!.isNotEmpty) {
          query = query.where('site', isEqualTo: filterSite);
        }
        if (filterTechnician != null && filterTechnician!.isNotEmpty) {
          query = query.where('technicien_nom', isEqualTo: filterTechnician);
        }
        final snapshot = await query.get();
        firestoreHistory = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'date': (data['createdAt'] as Timestamp?)?.toDate(),
            'site': data['site'] ?? '',
            'totalWeight': data['totalWeight'] ?? 0,
            'totalAmount': data['totalAmount'] ?? 0,
            'status': data['status'] ?? '',
            'technicien_nom': data['technicien_nom'] ?? '',
            'contenants': data['contenants'] ?? [],
          };
        }).toList();

        // Récupération des sites et techniciens distincts pour les filtres
        final allSites = <String>{};
        final allTechs = <String>{};
        for (final h in firestoreHistory) {
          if ((h['site'] ?? '').isNotEmpty) allSites.add(h['site']);
          if ((h['technicien_nom'] ?? '').isNotEmpty)
            allTechs.add(h['technicien_nom']);
        }
        availableSites = allSites.toList()..sort();
        availableTechnicians = allTechs.toList()..sort();
      }
    } catch (e) {
      // Gestion d'erreur silencieuse pour éviter les blocages
      print('Erreur lors du chargement de l\'historique : $e');
    }
    setState(() => isLoadingHistory = false);
  }

  // Ajout ou édition d'un contenant avec validation stricte
  void addOrEditContainer() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Validation stricte supplémentaire
      if (hiveType == null || hiveType!.isEmpty) {
        setState(() {
          statusMessage = 'Le type de ruche est obligatoire.';
        });
        return;
      }

      if (containerType == null || containerType!.isEmpty) {
        setState(() {
          statusMessage = 'Le type de contenant est obligatoire.';
        });
        return;
      }

      if (weight == null || weight! <= 0) {
        setState(() {
          statusMessage = 'Le poids doit être supérieur à 0.';
        });
        return;
      }

      if (unitPrice == null || unitPrice! <= 0) {
        setState(() {
          statusMessage = 'Le prix unitaire doit être supérieur à 0.';
        });
        return;
      }

      setState(() {
        if (editingId != null) {
          // Edition
          final idx = containers.indexWhere((c) => c.id == editingId);
          if (idx != -1) {
            containers[idx] = HarvestContainer(
              id: editingId!,
              hiveType: hiveType!,
              containerType: containerType!,
              weight: weight!,
              unitPrice: unitPrice!,
            );
          }
          editingId = null;
        } else {
          // Ajout
          containers.add(HarvestContainer(
            id: UniqueKey().toString(),
            hiveType: hiveType!,
            containerType: containerType!,
            weight: weight!,
            unitPrice: unitPrice!,
          ));
        }
        // Reset champs
        hiveType = null;
        containerType = null;
        weight = null;
        unitPrice = null;
        statusMessage = null; // Effacer le message d'erreur
      });
    }
  }

  // Suppression d'un contenant
  void removeContainer(String id) {
    setState(() {
      containers.removeWhere((c) => c.id == id);
    });
  }

  // Pré-remplir le formulaire pour édition
  void editContainer(HarvestContainer c) {
    setState(() {
      editingId = c.id;
      hiveType = c.hiveType;
      containerType = c.containerType;
      weight = c.weight;
      unitPrice = c.unitPrice;
    });
  }

  // Validation stricte et soumission avec enregistrement Firestore
  void submitHarvest() async {
    // Validation stricte de tous les champs obligatoires
    List<String> erreurs = [];

    if (containers.isEmpty) {
      erreurs.add('Ajoutez au moins un contenant');
    }

    if (selectedSite == null || selectedSite!.isEmpty) {
      erreurs.add('Sélectionnez un site');
    }

    if (selectedTechnician == null || selectedTechnician!.isEmpty) {
      erreurs.add('Sélectionnez un technicien');
    }

    if (selectedRegion == null || selectedRegion!.isEmpty) {
      erreurs.add('Sélectionnez une région');
    }

    if (selectedProvince == null || selectedProvince!.isEmpty) {
      erreurs.add('Sélectionnez une province');
    }

    if (selectedCommune == null || selectedCommune!.isEmpty) {
      erreurs.add('Sélectionnez une commune');
    }

    if (selectedVillage == null || selectedVillage!.isEmpty) {
      erreurs.add('Sélectionnez un village/localité');
    }

    if (selectedFlorales.isEmpty) {
      erreurs.add('Sélectionnez au moins une prédominance florale');
    }

    if (currentUserData == null) {
      erreurs.add('Données utilisateur non chargées');
    }

    // Afficher les erreurs s'il y en a
    if (erreurs.isNotEmpty) {
      setState(() {
        statusMessage = 'Erreurs à corriger :\n• ${erreurs.join('\n• ')}';
      });
      return;
    }

    setState(() {
      isSubmitting = true;
      statusMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Données de la collecte
      final collecteData = {
        'site': selectedSite!,
        'region': selectedRegion!,
        'province': selectedProvince!,
        'commune': selectedCommune!,
        'village': selectedVillage!,
        'technicien_nom': selectedTechnician!,
        'technicien_uid': user.uid,
        'utilisateur_nom':
            '${currentUserData!['prenom'] ?? ''} ${currentUserData!['nom'] ?? ''}'
                .trim(),
        'utilisateur_email': currentUserData!['email'] ?? '',
        'predominances_florales': selectedFlorales,
        'contenants': containers
            .map((c) => {
                  'hiveType': c.hiveType,
                  'containerType': c.containerType,
                  'weight': c.weight,
                  'unitPrice': c.unitPrice,
                  'total': c.total,
                })
            .toList(),
        'totalWeight': totalWeight,
        'totalAmount': totalAmount,
        'status': 'en_attente',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Enregistrement dans la collection du site avec sous-collection
      final docRef = await FirebaseFirestore.instance
          .collection(selectedSite!) // Collection nommée selon le site
          .doc('collectes_recolte') // Document principal
          .collection('collectes_recolte') // Sous-collection
          .add(collecteData);

      // Mise à jour du document principal pour s'assurer qu'il existe
      await FirebaseFirestore.instance
          .collection(selectedSite!)
          .doc('collectes_recolte')
          .set({
        'derniere_mise_a_jour': FieldValue.serverTimestamp(),
        'total_collectes': FieldValue.increment(1),
      }, SetOptions(merge: true));

      // Ajout à l'historique local
      setState(() {
        isSubmitting = false;
        statusMessage = 'Collecte enregistrée avec succès !';
        history.insert(0, {
          'id': docRef.id,
          'date': DateTime.now(),
          'site': selectedSite!,
          'technicien_nom': selectedTechnician!,
          'totalWeight': totalWeight,
          'totalAmount': totalAmount,
          'status': 'en_attente',
          'contenants': containers
              .map((c) => {
                    'hiveType': c.hiveType,
                    'containerType': c.containerType,
                    'weight': c.weight,
                    'unitPrice': c.unitPrice,
                    'total': c.total,
                  })
              .toList(),
        });
      });

      // Réinitialisation complète de l'état après enregistrement
      _resetFormState();

      // Recharger l'historique
      await fetchFirestoreHistory();
    } catch (e) {
      setState(() {
        isSubmitting = false;
        statusMessage = 'Erreur lors de l\'enregistrement : $e';
      });
    }
  }

  // Méthode pour réinitialiser complètement l'état du formulaire
  void _resetFormState() {
    if (!mounted) return; // Éviter setState si le widget n'est plus monté

    setState(() {
      // Réinitialiser les contenants
      containers.clear();

      // Réinitialiser les champs du formulaire
      hiveType = null;
      containerType = null;
      weight = null;
      unitPrice = null;
      editingId = null;

      // Réinitialiser les prédominances florales
      selectedFlorales.clear();

      // Garder la sélection de site et technicien pour faciliter la prochaine saisie
      // mais réinitialiser la géographie
      selectedRegion = null;
      selectedProvince = null;
      selectedCommune = null;
      selectedVillage = null;

      // Réinitialiser les messages
      statusMessage = null;
    });
  }

  // Utilitaire pour compter les contenants par type
  Map<String, int> countContainers(List<dynamic> contenants) {
    int pots = 0;
    int futs = 0;
    for (final c in contenants) {
      final type =
          c is Map ? c['containerType'] : (c as HarvestContainer).containerType;
      if (type == 'Pôt') pots++;
      if (type == 'Fût') futs++;
    }
    return {'Pôt': pots, 'Fût': futs};
  }

  String? _getTechnicienDisplayName(String nomComplet) {
    final tech = availableTechniciensForSite.firstWhere(
        (t) => t.nomComplet == nomComplet,
        orElse: () =>
            TechnicienInfo(nom: '', prenom: '', site: '', telephone: ''));
    if (tech.nom.isEmpty) return null;
    return '${tech.nomComplet} - ${tech.telephone}';
  }

  @override
  Widget build(BuildContext context) {
    // Afficher un indicateur de chargement pendant l'initialisation
    if (isLoadingUserData) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Nouvelle collecte récolte'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kHighlightColor),
              ),
              SizedBox(height: 16),
              Text('Chargement des données utilisateur...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: buildSmartAppBar(
        title: 'Nouvelle collecte récolte',
        onBackPressed: _handleBackNavigation,
        actions: widget.showBackToHistory
            ? [
                IconButton(
                  icon: const Icon(Icons.history),
                  tooltip: 'Retour à l\'historique',
                  onPressed: widget.onBackToHistory,
                ),
              ]
            : null,
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: kHighlightColor,
                  ),
                  child: Text('Apisavana',
                      style: TextStyle(color: Colors.white, fontSize: 24)),
                ),
                ListTile(
                  leading: Icon(Icons.dashboard, color: kHighlightColor),
                  title: Text('Retour au Dashboard'),
                  onTap: () {
                    _resetFormState(); // Réinitialiser avant de quitter
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacementNamed('/dashboard');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildFormCard()),
                      const SizedBox(width: 24),
                      Expanded(child: _buildContainersCard()),
                    ],
                  )
                : Column(
                    children: [
                      _buildFormCard(),
                      const SizedBox(height: 24),
                      _buildContainersCard(),
                    ],
                  ),
          );
        },
      ),
    );
  }

  // Card formulaire d'ajout/édition
  Widget _buildFormCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Section Localité ---
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: kHighlightColor, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                  color: kHighlightColor.withOpacity(0.07),
                ),
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Localisation',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: kHighlightColor)),
                    const SizedBox(height: 8),
                    DropdownSearch<String>(
                      items: regionsBurkina,
                      selectedItem: selectedRegion,
                      onChanged: (v) {
                        setState(() {
                          selectedRegion = v;
                          selectedProvince = null;
                          selectedCommune = null;
                          selectedVillage = null;
                        });
                      },
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration:
                            InputDecoration(labelText: 'Région'),
                      ),
                      popupProps: PopupProps.menu(showSearchBox: true),
                    ),
                    const SizedBox(height: 8),
                    DropdownSearch<String>(
                      items: selectedRegion != null
                          ? provincesParRegion[selectedRegion!] ?? []
                          : [],
                      selectedItem: selectedProvince,
                      onChanged: (v) {
                        setState(() {
                          selectedProvince = v;
                          selectedCommune = null;
                          selectedVillage = null;
                        });
                      },
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration:
                            InputDecoration(labelText: 'Province'),
                      ),
                      popupProps: PopupProps.menu(showSearchBox: true),
                    ),
                    const SizedBox(height: 8),
                    DropdownSearch<String>(
                      items: selectedProvince != null
                          ? communesParProvince[selectedProvince!] ?? []
                          : [],
                      selectedItem: selectedCommune,
                      onChanged: (v) {
                        setState(() {
                          selectedCommune = v;
                          selectedVillage = null;
                        });
                      },
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration:
                            InputDecoration(labelText: 'Commune'),
                      ),
                      popupProps: PopupProps.menu(showSearchBox: true),
                    ),
                    const SizedBox(height: 8),
                    DropdownSearch<String>(
                      items: selectedCommune != null
                          ? (villagesParCommune[selectedCommune!] ?? [])
                          : [],
                      selectedItem: selectedVillage,
                      onChanged: (v) => setState(() => selectedVillage = v),
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration:
                            InputDecoration(labelText: 'Village/Localité'),
                      ),
                      popupProps: PopupProps.menu(showSearchBox: true),
                    ),
                  ],
                ),
              ),
              // --- Section Site ---
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.blue.withOpacity(0.07),
                ),
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Site de collecte',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: Colors.blue)),
                    const SizedBox(height: 8),
                    DropdownSearch<String>(
                      items: sitesApisavana,
                      selectedItem: selectedSite,
                      onChanged: (v) {
                        setState(() {
                          selectedSite = v;
                          selectedTechnician =
                              null; // Reset technician selection
                          _loadTechniciansForSite(v);
                        });
                      },
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration:
                            InputDecoration(labelText: 'Sélectionner un site'),
                      ),
                      popupProps: PopupProps.menu(showSearchBox: true),
                    ),
                  ],
                ),
              ),
              // --- Section Technicien ---
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: kValidationColor, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                  color: kValidationColor.withOpacity(0.07),
                ),
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Technicien',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: kValidationColor)),
                    const SizedBox(height: 8),
                    if (availableTechniciensForSite.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Aucun technicien disponible pour ce site',
                                style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (availableTechniciensForSite.isNotEmpty)
                      DropdownSearch<String>(
                        items: availableTechniciensForSite
                            .map((t) => '${t.nomComplet} - ${t.telephone}')
                            .toList(),
                        selectedItem: selectedTechnician != null
                            ? _getTechnicienDisplayName(selectedTechnician!)
                            : null,
                        onChanged: (v) {
                          if (v != null) {
                            // Extraire le nom complet (avant le tiret)
                            final nomComplet = v.split(' - ')[0];
                            setState(() => selectedTechnician = nomComplet);
                          }
                        },
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration:
                              InputDecoration(labelText: 'Nom du technicien'),
                        ),
                        popupProps: PopupProps.menu(showSearchBox: true),
                      ),
                  ],
                ),
              ),
              // --- Section Prédominance florale ---
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.green.withOpacity(0.07),
                ),
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Prédominance florale',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: Colors.green)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 150, // Hauteur fixe pour le scroll
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: predominancesFlorales.map((florale) {
                            final selected = selectedFlorales.contains(florale);
                            return FilterChip(
                              label: Text(
                                florale,
                                style: TextStyle(fontSize: 12),
                              ),
                              selected: selected,
                              selectedColor: Colors.green.withOpacity(0.3),
                              backgroundColor: Colors.grey.withOpacity(0.1),
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    selectedFlorales.add(florale);
                                  } else {
                                    selectedFlorales.remove(florale);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    if (selectedFlorales.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Sélectionnées: ${selectedFlorales.length}',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // --- Section Infos collecte (auto-remplie) ---
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: kHighlightColor, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: kHighlightColor.withOpacity(0.1),
                ),
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Résumé de la collecte',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                color: kHighlightColor,
                                fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: ValueKey(
                                selectedSite), // Force rebuild when site changes
                            initialValue: selectedSite ?? '',
                            decoration: const InputDecoration(
                              labelText: 'Site',
                              border: OutlineInputBorder(),
                            ),
                            enabled: false,
                            maxLines: 1,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            key: ValueKey(
                                selectedTechnician), // Force rebuild when technician changes
                            initialValue: selectedTechnician ?? '',
                            decoration: const InputDecoration(
                              labelText: 'Technicien',
                              border: OutlineInputBorder(),
                            ),
                            enabled: false,
                            maxLines: 1,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (selectedRegion != null ||
                        selectedProvince != null ||
                        selectedCommune != null ||
                        selectedVillage != null) ...[
                      Text('Localisation :',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: kHighlightColor)),
                      const SizedBox(height: 4),
                      Text(
                        '${selectedRegion ?? ''}, ${selectedProvince ?? ''}, ${selectedCommune ?? ''}, ${selectedVillage ?? ''}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (selectedFlorales.isNotEmpty) ...[
                      Text('Prédominances florales :',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: kHighlightColor)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: selectedFlorales
                            .map((f) => Chip(
                                  label: Text(f,
                                      style: const TextStyle(fontSize: 12)),
                                  backgroundColor:
                                      Colors.green.withOpacity(0.2),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 32),
              Text(
                  editingId == null
                      ? 'Ajouter un contenant'
                      : 'Modifier le contenant',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: kHighlightColor),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: DropdownButtonFormField<String>(
                    value: hiveType,
                    decoration:
                        const InputDecoration(labelText: 'Type de ruche *'),
                    items: [
                      DropdownMenuItem(
                          value: 'Traditionnelle',
                          child: Text('Traditionnelle',
                              overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: 'Moderne',
                          child:
                              Text('Moderne', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => setState(() => hiveType = v),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Champ obligatoire *' : null,
                  )),
                  const SizedBox(width: 16),
                  Expanded(
                      child: DropdownButtonFormField<String>(
                    value: containerType,
                    decoration:
                        const InputDecoration(labelText: 'Type de contenant *'),
                    items: [
                      DropdownMenuItem(
                          value: 'Pôt',
                          child: Text('Pôt', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: 'Fût',
                          child: Text('Fût', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => setState(() => containerType = v),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Champ obligatoire *' : null,
                  )),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: TextFormField(
                    initialValue: weight?.toString(),
                    decoration:
                        const InputDecoration(labelText: 'Poids (kg) *'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                    ],
                    onSaved: (v) => weight = double.tryParse(v ?? ''),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Champ obligatoire *';
                      final val = double.tryParse(v);
                      if (val == null || val <= 0)
                        return 'Poids invalide (doit être > 0)';
                      return null;
                    },
                    maxLines: 1,
                    style: const TextStyle(overflow: TextOverflow.ellipsis),
                  )),
                  const SizedBox(width: 16),
                  Expanded(
                      child: TextFormField(
                    initialValue: unitPrice?.toString(),
                    decoration: const InputDecoration(
                        labelText: 'Prix unitaire (FCFA) *'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                    ],
                    onSaved: (v) => unitPrice = double.tryParse(v ?? ''),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Champ obligatoire *';
                      final val = double.tryParse(v);
                      if (val == null || val <= 0)
                        return 'Prix invalide (doit être > 0)';
                      return null;
                    },
                    maxLines: 1,
                    style: const TextStyle(overflow: TextOverflow.ellipsis),
                  )),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: Icon(editingId == null ? Icons.add : Icons.save,
                        color: Colors.white),
                    label: Text(editingId == null ? 'Ajouter' : 'Enregistrer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kHighlightColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: addOrEditContainer,
                  ),
                  if (editingId != null) ...[
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => setState(() {
                        editingId = null;
                        hiveType = null;
                        containerType = null;
                        weight = null;
                        unitPrice = null;
                      }),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kValidationColor,
                        side: BorderSide(color: kValidationColor),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ]
                ],
              ),
              if (statusMessage != null) ...[
                const SizedBox(height: 16),
                Text(statusMessage!, style: TextStyle(color: Colors.red)),
              ]
            ],
          ),
        ),
      ),
    );
  }

  // Card liste des contenants et totaux
  Widget _buildContainersCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: kHighlightColor, size: 24),
                const SizedBox(width: 8),
                Text('Contenants saisis',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: kHighlightColor,
                          fontWeight: FontWeight.bold,
                        )),
              ],
            ),
            const SizedBox(height: 16),
            if (containers.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: const Text(
                  'Aucun contenant ajouté.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            if (containers.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: containers.length,
                  itemBuilder: (context, idx) {
                    final c = containers[idx];
                    return Container(
                      decoration: BoxDecoration(
                        border: idx < containers.length - 1
                            ? Border(
                                bottom: BorderSide(color: Colors.grey.shade200))
                            : null,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: kHighlightColor.withOpacity(0.1),
                          child: Text('${idx + 1}',
                              style: TextStyle(
                                  color: kHighlightColor,
                                  fontWeight: FontWeight.bold)),
                        ),
                        title: Text('${c.hiveType} - ${c.containerType}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                            'Poids: ${c.weight} kg  |  Prix unitaire: ${c.unitPrice} FCFA',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.green.withOpacity(0.3)),
                              ),
                              child: Text('${c.total.toStringAsFixed(0)} FCFA',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => editContainer(c),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => removeContainer(c.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
            // Totaux dans une section encadrée
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kValidationColor.withOpacity(0.05),
                    kValidationColor.withOpacity(0.1)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: kValidationColor.withOpacity(0.3), width: 2),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total poids:',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: kValidationColor,
                                  )),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: kValidationColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${totalWeight.toStringAsFixed(2)} kg',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: kValidationColor,
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Montant total:',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: kValidationColor,
                                  )),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Text('${totalAmount.toStringAsFixed(0)} FCFA',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.green,
                            )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Bouton de finalisation amélioré
            Center(
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: isSubmitting
                      ? null
                      : LinearGradient(
                          colors: [
                            kHighlightColor,
                            kHighlightColor.withOpacity(0.8)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: isSubmitting
                      ? null
                      : [
                          BoxShadow(
                            color: kHighlightColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isSubmitting ? Colors.grey : Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                  ),
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ))
                      : const Icon(Icons.check_circle,
                          size: 24, color: Colors.white),
                  label: Text(
                    isSubmitting
                        ? 'Enregistrement...'
                        : 'Finaliser la collecte',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: isSubmitting ? null : submitHarvest,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (history.isNotEmpty) ...[
              Text('Historique local (session)',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                itemBuilder: (context, idx) {
                  final h = history[idx];
                  final pots = h['contenants']
                          ?.where((c) => c['containerType'] == 'Pôt')
                          .length ??
                      0;
                  final futs = h['contenants']
                          ?.where((c) => c['containerType'] == 'Fût')
                          .length ??
                      0;
                  return ListTile(
                    leading: const Icon(Icons.history),
                    title: Text('Site: \'${h['site']}\'',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                        'Poids: ${h['totalWeight']} kg | Montant: ${h['totalAmount']} FCFA\nPôt: $pots  Fût: $futs',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    trailing: Text(h['status'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
            // Bouton pour voir l'historique dans un BottomSheet
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.history, color: Colors.white),
                label: const Text(
                  'Voir les historiques',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                onPressed: () => _showHistoryBottomSheet(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Afficher l'historique dans un BottomSheet
  void _showHistoryBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header du BottomSheet
              Row(
                children: [
                  Icon(Icons.history, color: kHighlightColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Historique Firestore',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: kHighlightColor,
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

              // Filtres site/technicien
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: filterSite,
                      decoration: const InputDecoration(
                        labelText: 'Filtrer par site',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: '',
                          child: Text('Tous les sites'),
                        ),
                        ...availableSites.map((s) => DropdownMenuItem<String>(
                              value: s,
                              child: Text(s),
                            ))
                      ],
                      onChanged: (v) {
                        setModalState(() {
                          filterSite = (v != null && v.isNotEmpty) ? v : null;
                        });
                        setState(() {
                          filterSite = (v != null && v.isNotEmpty) ? v : null;
                        });
                        fetchFirestoreHistory();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: filterTechnician,
                      decoration: const InputDecoration(
                        labelText: 'Filtrer par technicien',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: '',
                          child: Text('Tous les techniciens'),
                        ),
                        ...availableTechnicians
                            .map((t) => DropdownMenuItem<String>(
                                  value: t,
                                  child:
                                      Text(t, overflow: TextOverflow.ellipsis),
                                ))
                      ],
                      onChanged: (v) {
                        setModalState(() {
                          filterTechnician =
                              (v != null && v.isNotEmpty) ? v : null;
                        });
                        setState(() {
                          filterTechnician =
                              (v != null && v.isNotEmpty) ? v : null;
                        });
                        fetchFirestoreHistory();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Bouton refresh
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Actualiser'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kHighlightColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    onPressed: () => fetchFirestoreHistory(),
                  ),
                  const Spacer(),
                  if (firestoreHistory.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${firestoreHistory.length} collectes',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Liste des historiques
              Expanded(
                child: isLoadingHistory
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Chargement des données...'),
                          ],
                        ),
                      )
                    : firestoreHistory.isEmpty
                        ? Center(
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
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Modifiez les filtres ou actualisez',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: firestoreHistory.length,
                            itemBuilder: (context, idx) {
                              final h = firestoreHistory[idx];
                              final pots = h['contenants']
                                      ?.where(
                                          (c) => c['containerType'] == 'Pôt')
                                      .length ??
                                  0;
                              final futs = h['contenants']
                                      ?.where(
                                          (c) => c['containerType'] == 'Fût')
                                      .length ??
                                  0;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.cloud_done,
                                      color: Colors.green,
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    'Site: ${h['site']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        'Technicien: ${h['technicien_nom']}',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.blue.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${h['totalWeight']} kg',
                                              style: TextStyle(
                                                color: Colors.blue.shade700,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.green.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${h['totalAmount']} FCFA',
                                              style: TextStyle(
                                                color: Colors.green.shade700,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Contenants: $pots Pôt(s), $futs Fût(s)',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(h['status'])
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _getStatusColor(h['status'])
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        child: Text(
                                          _getStatusLabel(h['status']),
                                          style: TextStyle(
                                            color: _getStatusColor(h['status']),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (h['date'] != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          '${h['date']}'.split(' ')[0],
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              // Bouton pour aller vers la page complète des historiques
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_full, color: Colors.white),
                  label: const Text(
                    'Voir la page complète des historiques',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kHighlightColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Fermer le BottomSheet
                    Navigator.pushNamed(context, '/historiques_collectes');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  String _getStatusLabel(String? status) {
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
