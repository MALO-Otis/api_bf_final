import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:apisavana_gestion/authentication/user_session.dart';
import 'package:apisavana_gestion/data/geographe/geographie.dart';
import 'package:apisavana_gestion/data/personnel/personnel_apisavana.dart';

class EditCollecteRecoltePage extends StatefulWidget {
  final String collecteId;
  final String? collection; // Collection d'origine pour retrouver la collecte
  final String? siteId; // Site ID pour les nouvelles collections

  const EditCollecteRecoltePage({
    Key? key,
    required this.collecteId,
    this.collection,
    this.siteId,
  }) : super(key: key);

  @override
  State<EditCollecteRecoltePage> createState() =>
      _EditCollecteRecoltePageState();
}

class _EditCollecteRecoltePageState extends State<EditCollecteRecoltePage> {
  bool isLoading = true;
  bool isEditingContainer = false;
  int? editingContainerIndex;
  String? statusMessage;

  // Données de la collecte
  Map<String, dynamic>? collecte;
  List<Map<String, dynamic>> containers = [];

  // Données utilisateur et session
  Map<String, dynamic>? currentUserData;
  UserSession? userSession;
  String? currentUserSite;

  // Formulaire contenant
  String? hiveType;
  String? containerType;
  String? weight;
  String? unitPrice;

  // Champs obligatoires de la collecte
  String? selectedSite;
  String? selectedTechnician;
  String? selectedRegion;
  String? selectedProvince;
  String? selectedCommune;
  String? selectedVillage;
  List<String> selectedFlorales = [];

  // Statut collecte
  String? status;
  final List<Map<String, String>> statusOptions = [
    {'value': 'en_attente', 'label': 'En attente'},
    {'value': 'valide', 'label': 'Validé'},
    {'value': 'rejete', 'label': 'Rejeté'},
  ];

  // Vérification du rôle admin
  bool get isAdmin {
    final role = currentUserData?['role']?.toString().toLowerCase();
    return role == 'admin' || role == 'administrateur';
  }

  final List<String> hiveTypes = ['Traditionnel', 'Moderne'];
  final List<String> containerTypes = ['Bidon', 'Seau', 'Fût'];

  // Listes de données géographiques et personnel
  final List<String> sites = sitesApisavana;
  final List<String> regions = regionsBurkina;
  final List<String> techniciens =
      techniciensApisavana.map((t) => t.nomComplet).toList();
  final List<String> florales = predominancesFlorales;

  // Variables pour gérer les dépendances géographiques
  List<String> availableProvinces = [];
  List<String> availableCommunes = [];
  List<String> availableVillages = [];

  // Variable pour gérer l'expansion des détails
  bool _isDetailedSummaryExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  // Initialisation des données utilisateur puis chargement de la collecte
  Future<void> _initializeUserData() async {
    setState(() => isLoading = true);

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
      currentUserSite = currentUserData?['site']?.toString();

      // Récupérer la session utilisateur depuis GetX
      try {
        userSession = Get.find<UserSession>();
        currentUserSite ??= userSession?.site;
      } catch (e) {
        print('UserSession non trouvée dans GetX: $e');
      }

      // Maintenant charger la collecte
      await _loadCollecte();
    } catch (e) {
      print('Erreur lors de l\'initialisation des données utilisateur: $e');
      setState(() {
        statusMessage = 'Erreur lors du chargement des données: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadCollecte() async {
    try {
      DocumentSnapshot? doc;

      // Essayer de charger depuis la nouvelle structure (par site) d'abord
      if (widget.siteId != null || currentUserSite != null) {
        final siteId = widget.siteId ?? currentUserSite!;
        try {
          doc = await FirebaseFirestore.instance
              .collection(siteId)
              .doc('collectes_recolte')
              .collection('collectes_recolte')
              .doc(widget.collecteId)
              .get();

          if (!doc.exists) {
            // Fallback: essayer l'ancienne structure
            doc = await FirebaseFirestore.instance
                .collection('collectes_recolte')
                .doc(widget.collecteId)
                .get();
          }
        } catch (e) {
          // Si erreur avec la nouvelle structure, essayer l'ancienne
          doc = await FirebaseFirestore.instance
              .collection('collectes_recolte')
              .doc(widget.collecteId)
              .get();
        }
      } else {
        // Si pas de site, essayer directement l'ancienne structure
        doc = await FirebaseFirestore.instance
            .collection('collectes_recolte')
            .doc(widget.collecteId)
            .get();
      }

      if (!doc.exists) {
        setState(() {
          statusMessage = 'Collecte introuvable';
          isLoading = false;
        });
        return;
      }

      collecte = doc.data() as Map<String, dynamic>;
      status = collecte!['status'] ?? 'en_attente';
      containers = (collecte!['contenants'] as List?)
              ?.map((c) => Map<String, dynamic>.from(c))
              .toList() ??
          [];

      // Charger les champs obligatoires
      selectedSite = collecte!['site']?.toString();
      selectedTechnician = collecte!['technicien_nom']?.toString();
      selectedRegion = collecte!['region']?.toString();
      selectedProvince = collecte!['province']?.toString();
      selectedCommune = collecte!['commune']?.toString();
      selectedVillage = collecte!['village']?.toString();
      selectedFlorales = (collecte!['predominances_florales'] as List?)
              ?.map((f) => f.toString())
              .toList() ??
          [];

      // Initialiser les listes dépendantes géographiques
      _initializeDependentLists();

      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        statusMessage = 'Erreur lors du chargement: $e';
        isLoading = false;
      });
    }
  }

  void _startEditContainer(int idx) {
    final c = containers[idx];
    setState(() {
      editingContainerIndex = idx;
      hiveType = c['hiveType'];
      containerType = c['containerType'];
      weight = c['weight'].toString();
      unitPrice = c['unitPrice'].toString();
      isEditingContainer = true;
    });
  }

  void _addNewContainer() {
    setState(() {
      editingContainerIndex = null;
      hiveType = null;
      containerType = null;
      weight = null;
      unitPrice = null;
      isEditingContainer = true;
    });
  }

  // Affiche le formulaire d'ajout/édition de contenant dans un dialogue pop-up
  Future<void> _showContainerDialog({bool isEdit = false}) async {
    final theme = Theme.of(context);
    String? localHiveType = hiveType;
    String? localContainerType = containerType;
    String? localWeight = weight;
    String? localUnitPrice = unitPrice;
    String title = isEdit ? 'Modifier le contenant' : 'Ajouter un contenant';
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = MediaQuery.of(context).size.width < 500;
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isSmallScreen ? double.infinity : 500,
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(title,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),

                      // Layout responsive pour les dropdowns
                      if (isSmallScreen) ...[
                        // Layout vertical pour mobile
                        DropdownButtonFormField<String>(
                          value: hiveTypes.contains(localHiveType)
                              ? localHiveType
                              : null,
                          decoration:
                              const InputDecoration(labelText: 'Type de ruche'),
                          items: hiveTypes
                              .map((t) =>
                                  DropdownMenuItem(value: t, child: Text(t)))
                              .toList(),
                          onChanged: (v) => localHiveType = v,
                          validator: (v) => v == null ? 'Champ requis' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: containerTypes.contains(localContainerType)
                              ? localContainerType
                              : null,
                          decoration: const InputDecoration(
                              labelText: 'Type de contenant'),
                          items: containerTypes
                              .map((t) =>
                                  DropdownMenuItem(value: t, child: Text(t)))
                              .toList(),
                          onChanged: (v) => localContainerType = v,
                          validator: (v) => v == null ? 'Champ requis' : null,
                        ),
                      ] else ...[
                        // Layout horizontal pour tablette/desktop
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: hiveTypes.contains(localHiveType)
                                    ? localHiveType
                                    : null,
                                decoration: const InputDecoration(
                                    labelText: 'Type de ruche'),
                                items: hiveTypes
                                    .map((t) => DropdownMenuItem(
                                        value: t, child: Text(t)))
                                    .toList(),
                                onChanged: (v) => localHiveType = v,
                                validator: (v) =>
                                    v == null ? 'Champ requis' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value:
                                    containerTypes.contains(localContainerType)
                                        ? localContainerType
                                        : null,
                                decoration: const InputDecoration(
                                    labelText: 'Type de contenant'),
                                items: containerTypes
                                    .map((t) => DropdownMenuItem(
                                        value: t, child: Text(t)))
                                    .toList(),
                                onChanged: (v) => localContainerType = v,
                                validator: (v) =>
                                    v == null ? 'Champ requis' : null,
                              ),
                            ),
                          ],
                        ),
                      ],

                      SizedBox(height: isSmallScreen ? 12 : 16),

                      // Layout responsive pour les champs numériques
                      if (isSmallScreen) ...[
                        // Layout vertical pour mobile
                        TextFormField(
                          initialValue: localWeight,
                          decoration:
                              const InputDecoration(labelText: 'Poids (kg)'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => localWeight = v,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: localUnitPrice,
                          decoration: const InputDecoration(
                              labelText: 'Prix unitaire (FCFA)'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => localUnitPrice = v,
                        ),
                      ] else ...[
                        // Layout horizontal pour tablette/desktop
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: localWeight,
                                decoration: const InputDecoration(
                                    labelText: 'Poids (kg)'),
                                keyboardType: TextInputType.number,
                                onChanged: (v) => localWeight = v,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: localUnitPrice,
                                decoration: const InputDecoration(
                                    labelText: 'Prix unitaire (FCFA)'),
                                keyboardType: TextInputType.number,
                                onChanged: (v) => localUnitPrice = v,
                              ),
                            ),
                          ],
                        ),
                      ],

                      SizedBox(height: isSmallScreen ? 12 : 16),

                      if (localWeight != null &&
                          localUnitPrice != null &&
                          localWeight!.isNotEmpty &&
                          localUnitPrice!.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Montant calculé: ${((double.tryParse(localWeight!) ?? 0) * (double.tryParse(localUnitPrice!) ?? 0)).toStringAsFixed(2)} FCFA',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // Boutons responsifs
                      if (isSmallScreen) ...[
                        // Layout vertical pour mobile
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Validation
                              if (localHiveType == null ||
                                  localContainerType == null ||
                                  localWeight == null ||
                                  localUnitPrice == null ||
                                  localWeight!.isEmpty ||
                                  localUnitPrice!.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Veuillez remplir tous les champs du contenant.'),
                                        backgroundColor: Colors.red));
                                return;
                              }
                              final double? w = double.tryParse(localWeight!);
                              final double? up =
                                  double.tryParse(localUnitPrice!);
                              if (w == null ||
                                  up == null ||
                                  w <= 0 ||
                                  up <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Valeurs numériques invalides.'),
                                        backgroundColor: Colors.red));
                                return;
                              }
                              setState(() {
                                hiveType = localHiveType;
                                containerType = localContainerType;
                                weight = localWeight;
                                unitPrice = localUnitPrice;
                              });
                              _saveContainer();
                              Navigator.of(context).pop();
                            },
                            child: Text(isEdit ? 'Modifier' : 'Ajouter'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              _cancelEditContainer();
                              Navigator.of(context).pop();
                            },
                            child: const Text('Annuler'),
                          ),
                        ),
                      ] else ...[
                        // Layout horizontal pour tablette/desktop
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  // Validation
                                  if (localHiveType == null ||
                                      localContainerType == null ||
                                      localWeight == null ||
                                      localUnitPrice == null ||
                                      localWeight!.isEmpty ||
                                      localUnitPrice!.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Veuillez remplir tous les champs du contenant.'),
                                            backgroundColor: Colors.red));
                                    return;
                                  }
                                  final double? w =
                                      double.tryParse(localWeight!);
                                  final double? up =
                                      double.tryParse(localUnitPrice!);
                                  if (w == null ||
                                      up == null ||
                                      w <= 0 ||
                                      up <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Valeurs numériques invalides.'),
                                            backgroundColor: Colors.red));
                                    return;
                                  }
                                  setState(() {
                                    hiveType = localHiveType;
                                    containerType = localContainerType;
                                    weight = localWeight;
                                    unitPrice = localUnitPrice;
                                  });
                                  _saveContainer();
                                  Navigator.of(context).pop();
                                },
                                child: Text(isEdit ? 'Modifier' : 'Ajouter'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  _cancelEditContainer();
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Annuler'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Ajout d'un badge coloré pour le statut
  Widget _statusBadge(String? status) {
    Color color;
    String label;
    switch (status) {
      case 'en_attente':
        color = Colors.orange;
        label = 'En attente';
        break;
      case 'valide':
        color = Colors.green;
        label = 'Validé';
        break;
      case 'rejete':
        color = Colors.red;
        label = 'Rejeté';
        break;
      default:
        color = Colors.grey;
        label = status ?? '';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  void _deleteContainer(int idx) {
    setState(() {
      final c = containers[idx];
      containers.removeAt(idx);
      isEditingContainer = false;
      editingContainerIndex = null;
      collecte ??= {};
      collecte!['logs'] = (collecte!['logs'] ?? [])
        ..add({
          'action': 'Suppression',
          'user': 'Utilisateur',
          'date': DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
          'details':
              'Contenant supprimé (${c['hiveType']} - ${c['containerType']})',
        });
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Contenant supprimé'), backgroundColor: Colors.red));
  }

  void _saveContainer() {
    if (hiveType == null ||
        containerType == null ||
        weight == null ||
        unitPrice == null ||
        weight!.isEmpty ||
        unitPrice!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veuillez remplir tous les champs du contenant.'),
          backgroundColor: Colors.red));
      return;
    }
    final double? w = double.tryParse(weight!);
    final double? up = double.tryParse(unitPrice!);
    if (w == null || up == null || w <= 0 || up <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Valeurs numériques invalides.'),
          backgroundColor: Colors.red));
      return;
    }
    final double amount = w * up;
    final newContainer = {
      'hiveType': hiveType,
      'containerType': containerType,
      'weight': w,
      'unitPrice': up,
      'total': amount,
      'log': {
        'action': editingContainerIndex != null ? 'Modification' : 'Ajout',
        'user': 'Utilisateur',
        'date': DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
        'details':
            '${editingContainerIndex != null ? 'Contenant modifié' : 'Nouveau contenant ajouté'}',
      }
    };
    setState(() {
      if (editingContainerIndex != null) {
        containers[editingContainerIndex!] = newContainer;
      } else {
        containers.add(newContainer);
      }
      isEditingContainer = false;
      editingContainerIndex = null;
      hiveType = null;
      containerType = null;
      weight = null;
      unitPrice = null;
      // Ajout du log dans collecte['logs']
      collecte ??= {};
      collecte!['logs'] = (collecte!['logs'] ?? [])..add(newContainer['log']);
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(editingContainerIndex != null
            ? 'Contenant modifié.'
            : 'Contenant ajouté.'),
        backgroundColor: Colors.green));
  }

  void _cancelEditContainer() {
    setState(() {
      isEditingContainer = false;
      editingContainerIndex = null;
      hiveType = null;
      containerType = null;
      weight = null;
      unitPrice = null;
    });
  }

  Future<void> _saveCollecte() async {
    if (collecte == null) return;

    // Validation stricte de tous les champs obligatoires
    List<String> erreurs = [];

    if (containers.isEmpty) {
      erreurs.add('Au moins un contenant est requis');
    }

    if (selectedSite == null || selectedSite!.isEmpty) {
      erreurs.add('Le site est obligatoire');
    }

    if (selectedTechnician == null || selectedTechnician!.isEmpty) {
      erreurs.add('Le technicien est obligatoire');
    }

    if (selectedRegion == null || selectedRegion!.isEmpty) {
      erreurs.add('La région est obligatoire');
    }

    if (selectedProvince == null || selectedProvince!.isEmpty) {
      erreurs.add('La province est obligatoire');
    }

    if (selectedCommune == null || selectedCommune!.isEmpty) {
      erreurs.add('La commune est obligatoire');
    }

    if (selectedVillage == null || selectedVillage!.isEmpty) {
      erreurs.add('Le village/localité est obligatoire');
    }

    if (selectedFlorales.isEmpty) {
      erreurs.add('Au moins une prédominance florale est obligatoire');
    }

    // Afficher les erreurs s'il y en a
    if (erreurs.isNotEmpty) {
      setState(() {
        statusMessage = 'Erreurs à corriger :\n• ${erreurs.join('\n• ')}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreurs de validation :\n• ${erreurs.join('\n• ')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Préparer les données mises à jour
      final updatedData = {
        'site': selectedSite!,
        'region': selectedRegion!,
        'province': selectedProvince!,
        'commune': selectedCommune!,
        'village': selectedVillage!,
        'technicien_nom': selectedTechnician!,
        'predominances_florales': selectedFlorales,
        'contenants': containers,
        'status': status,
        'totalWeight': containers.fold<double>(0.0,
            (double sum, c) => sum + ((c['weight'] ?? 0) as num).toDouble()),
        'totalAmount': containers.fold<double>(0.0,
            (double sum, c) => sum + ((c['total'] ?? 0) as num).toDouble()),
        'modifie_le': FieldValue.serverTimestamp(),
        'modifie_par': user.uid,
      };

      // Déterminer quelle collection utiliser pour la sauvegarde
      DocumentReference docRef;

      // Essayer de sauvegarder dans la nouvelle structure (par site) d'abord
      if (widget.siteId != null || currentUserSite != null) {
        final siteId = widget.siteId ?? currentUserSite!;
        try {
          docRef = FirebaseFirestore.instance
              .collection(siteId)
              .doc('collectes_recolte')
              .collection('collectes_recolte')
              .doc(widget.collecteId);

          // Vérifier si le document existe dans la nouvelle structure
          final docSnapshot = await docRef.get();
          if (docSnapshot.exists) {
            // Mettre à jour dans la nouvelle structure
            await docRef.update(updatedData);
          } else {
            // Fallback: mettre à jour dans l'ancienne structure
            await FirebaseFirestore.instance
                .collection('collectes_recolte')
                .doc(widget.collecteId)
                .update(updatedData);
          }
        } catch (e) {
          // Si erreur avec la nouvelle structure, utiliser l'ancienne
          await FirebaseFirestore.instance
              .collection('collectes_recolte')
              .doc(widget.collecteId)
              .update(updatedData);
        }
      } else {
        // Si pas de site, utiliser directement l'ancienne structure
        await FirebaseFirestore.instance
            .collection('collectes_recolte')
            .doc(widget.collecteId)
            .update(updatedData);
      }

      setState(() {
        statusMessage = null;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Collecte mise à jour avec succès !'),
        backgroundColor: Colors.green,
      ));
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        isLoading = false;
        statusMessage = 'Erreur lors de la sauvegarde: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Construit un résumé détaillé et expansible de la collecte
  Widget _buildDetailedSummary(ThemeData theme) {
    final totalWeight =
        containers.fold<double>(0, (sum, c) => sum + (c['weight'] ?? 0));
    final totalAmount =
        containers.fold<double>(0, (sum, c) => sum + (c['total'] ?? 0));

    // Groupement par type de ruche et contenant
    final Map<String, List<Map<String, dynamic>>> groupedByHive = {};
    final Map<String, List<Map<String, dynamic>>> groupedByContainer = {};

    for (var container in containers) {
      final hiveType = container['hiveType'] ?? 'Non spécifié';
      final containerType = container['containerType'] ?? 'Non spécifié';

      groupedByHive.putIfAbsent(hiveType, () => []).add(container);
      groupedByContainer.putIfAbsent(containerType, () => []).add(container);
    }

    // Calculs de statistiques
    final avgWeight =
        containers.isNotEmpty ? totalWeight / containers.length : 0.0;
    final avgUnitPrice = containers.isNotEmpty
        ? containers.fold<double>(0, (sum, c) => sum + (c['unitPrice'] ?? 0)) /
            containers.length
        : 0.0;
    final avgAmount =
        containers.isNotEmpty ? totalAmount / containers.length : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Résumé de la collecte',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(_isDetailedSummaryExpanded
                      ? Icons.expand_less
                      : Icons.expand_more),
                  onPressed: () => setState(() =>
                      _isDetailedSummaryExpanded = !_isDetailedSummaryExpanded),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Résumé de base (toujours visible)
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _summaryChip('Contenants', '${containers.length}',
                    Icons.inventory_2, Colors.blue),
                _summaryChip(
                    'Poids total',
                    '${totalWeight.toStringAsFixed(2)} kg',
                    Icons.scale,
                    Colors.green),
                _summaryChip(
                    'Montant total',
                    '${totalAmount.toStringAsFixed(0)} FCFA',
                    Icons.attach_money,
                    Colors.orange),
              ],
            ),

            // Détails expansibles avec animation
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _isDetailedSummaryExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: _buildExpandedSummaryDetails(theme, groupedByHive,
                  groupedByContainer, avgWeight, avgUnitPrice, avgAmount),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour afficher les détails expansibles
  Widget _buildExpandedSummaryDetails(
      ThemeData theme,
      Map<String, List<Map<String, dynamic>>> groupedByHive,
      Map<String, List<Map<String, dynamic>>> groupedByContainer,
      double avgWeight,
      double avgUnitPrice,
      double avgAmount) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),

          // Statistiques moyennes
          Text('Statistiques moyennes',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _summaryChip('Poids moyen', '${avgWeight.toStringAsFixed(2)} kg',
                  Icons.balance, Colors.teal),
              _summaryChip(
                  'Prix unitaire moyen',
                  '${avgUnitPrice.toStringAsFixed(0)} FCFA',
                  Icons.price_check,
                  Colors.purple),
              _summaryChip(
                  'Montant moyen',
                  '${avgAmount.toStringAsFixed(0)} FCFA',
                  Icons.analytics,
                  Colors.indigo),
            ],
          ),

          const SizedBox(height: 16),

          // Détails par type de ruche
          Text('Répartition par type de ruche',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...groupedByHive.entries.map((entry) {
            final hiveType = entry.key;
            final containers = entry.value;
            final totalWeightByHive = containers.fold<double>(
                0, (sum, c) => sum + (c['weight'] ?? 0));
            final totalAmountByHive =
                containers.fold<double>(0, (sum, c) => sum + (c['total'] ?? 0));

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border(left: BorderSide(width: 4, color: Colors.blue)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$hiveType (${containers.length} contenants)',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Text('Poids: ${totalWeightByHive.toStringAsFixed(2)} kg',
                          style: const TextStyle(fontSize: 12)),
                      Text(
                          'Montant: ${totalAmountByHive.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 16),

          // Détails par type de contenant
          Text('Répartition par type de contenant',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...groupedByContainer.entries.map((entry) {
            final containerType = entry.key;
            final containers = entry.value;
            final totalWeightByContainer = containers.fold<double>(
                0, (sum, c) => sum + (c['weight'] ?? 0));
            final totalAmountByContainer =
                containers.fold<double>(0, (sum, c) => sum + (c['total'] ?? 0));
            final avgWeightByContainer = containers.isNotEmpty
                ? totalWeightByContainer / containers.length
                : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border(left: BorderSide(width: 4, color: Colors.green)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$containerType (${containers.length} unités)',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Text(
                          'Poids total: ${totalWeightByContainer.toStringAsFixed(2)} kg',
                          style: const TextStyle(fontSize: 12)),
                      Text(
                          'Poids moyen: ${avgWeightByContainer.toStringAsFixed(2)} kg',
                          style: const TextStyle(fontSize: 12)),
                      Text(
                          'Montant: ${totalAmountByContainer.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),

          if (containers.length > 5) ...[
            const SizedBox(height: 16),
            Text('Analyse détaillée (${containers.length} contenants)',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border(left: BorderSide(width: 4, color: Colors.amber)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Collecte importante détectée',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Text('Types de ruches: ${groupedByHive.keys.length}',
                          style: const TextStyle(fontSize: 12)),
                      Text(
                          'Types de contenants: ${groupedByContainer.keys.length}',
                          style: const TextStyle(fontSize: 12)),
                      Text(
                          'Diversité: ${(groupedByHive.keys.length * groupedByContainer.keys.length)} combinaisons',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Widget helper pour créer des chips de résumé
  Widget _summaryChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style:
                      TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
              Text(value,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  // Méthodes pour mettre à jour les listes dépendantes
  void _updateAvailableProvinces(String? region) {
    if (region != null && provincesParRegion.containsKey(region)) {
      availableProvinces = provincesParRegion[region]!;
      selectedProvince = null;
      selectedCommune = null;
      selectedVillage = null;
      availableCommunes = [];
      availableVillages = [];
    } else {
      availableProvinces = [];
      selectedProvince = null;
      selectedCommune = null;
      selectedVillage = null;
      availableCommunes = [];
      availableVillages = [];
    }
  }

  void _updateAvailableCommunes(String? province) {
    if (province != null && communesParProvince.containsKey(province)) {
      availableCommunes = communesParProvince[province]!;
      selectedCommune = null;
      selectedVillage = null;
      availableVillages = [];
    } else {
      availableCommunes = [];
      selectedCommune = null;
      selectedVillage = null;
      availableVillages = [];
    }
  }

  void _updateAvailableVillages(String? commune) {
    if (commune != null && villagesParCommune.containsKey(commune)) {
      availableVillages = villagesParCommune[commune]!;
      selectedVillage = null;
    } else {
      availableVillages = [];
      selectedVillage = null;
    }
  }

  // Initialiser les listes dépendantes lors du chargement des données
  void _initializeDependentLists() {
    if (selectedRegion != null) {
      _updateAvailableProvinces(selectedRegion);
      if (selectedProvince != null) {
        _updateAvailableCommunes(selectedProvince);
        if (selectedCommune != null) {
          _updateAvailableVillages(selectedCommune);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Modifier la collecte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: isLoading ? null : _saveCollecte,
            tooltip: 'Sauvegarder',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : collecte == null
              ? Center(child: Text(statusMessage ?? 'Erreur'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(
                      MediaQuery.of(context).size.width < 600 ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Infos générales
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: EdgeInsets.all(
                              MediaQuery.of(context).size.width < 600
                                  ? 12
                                  : 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Informations générales',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),

                              // Message d'erreur si présent
                              if (statusMessage != null)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.red.shade300),
                                  ),
                                  child: Text(statusMessage!,
                                      style: TextStyle(
                                          color: Colors.red.shade700)),
                                ),

                              // Site et Technicien
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  if (constraints.maxWidth < 600) {
                                    // Layout vertical pour mobile
                                    return Column(
                                      children: [
                                        _buildEditableDropdown(
                                          label: 'Site *',
                                          value: selectedSite,
                                          items: sites,
                                          onChanged: (value) => setState(
                                              () => selectedSite = value),
                                        ),
                                        const SizedBox(height: 12),
                                        _buildEditableDropdown(
                                          label: 'Technicien *',
                                          value: selectedTechnician,
                                          items: techniciens,
                                          onChanged: (value) => setState(
                                              () => selectedTechnician = value),
                                        ),
                                      ],
                                    );
                                  } else {
                                    // Layout horizontal pour tablette/desktop
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: _buildEditableDropdown(
                                            label: 'Site *',
                                            value: selectedSite,
                                            items: sites,
                                            onChanged: (value) => setState(
                                                () => selectedSite = value),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildEditableDropdown(
                                            label: 'Technicien *',
                                            value: selectedTechnician,
                                            items: techniciens,
                                            onChanged: (value) => setState(() =>
                                                selectedTechnician = value),
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 16),

                              // Région et Province
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  if (constraints.maxWidth < 600) {
                                    // Layout vertical pour mobile
                                    return Column(
                                      children: [
                                        _buildEditableDropdown(
                                          label: 'Région *',
                                          value: selectedRegion,
                                          items: regions,
                                          onChanged: (value) => setState(() {
                                            selectedRegion = value;
                                            _updateAvailableProvinces(value);
                                          }),
                                        ),
                                        const SizedBox(height: 12),
                                        _buildEditableDropdown(
                                          label: 'Province *',
                                          value: selectedProvince,
                                          items: availableProvinces,
                                          onChanged: (value) => setState(() {
                                            selectedProvince = value;
                                            _updateAvailableCommunes(value);
                                          }),
                                        ),
                                      ],
                                    );
                                  } else {
                                    // Layout horizontal pour tablette/desktop
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: _buildEditableDropdown(
                                            label: 'Région *',
                                            value: selectedRegion,
                                            items: regions,
                                            onChanged: (value) => setState(() {
                                              selectedRegion = value;
                                              _updateAvailableProvinces(value);
                                            }),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildEditableDropdown(
                                            label: 'Province *',
                                            value: selectedProvince,
                                            items: availableProvinces,
                                            onChanged: (value) => setState(() {
                                              selectedProvince = value;
                                              _updateAvailableCommunes(value);
                                            }),
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 16),

                              // Commune et Village
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  if (constraints.maxWidth < 600) {
                                    // Layout vertical pour mobile
                                    return Column(
                                      children: [
                                        _buildEditableDropdown(
                                          label: 'Commune *',
                                          value: selectedCommune,
                                          items: availableCommunes,
                                          onChanged: (value) => setState(() {
                                            selectedCommune = value;
                                            _updateAvailableVillages(value);
                                          }),
                                        ),
                                        const SizedBox(height: 12),
                                        _buildEditableDropdown(
                                          label: 'Village/Localité *',
                                          value: selectedVillage,
                                          items: availableVillages,
                                          onChanged: (value) => setState(
                                              () => selectedVillage = value),
                                        ),
                                      ],
                                    );
                                  } else {
                                    // Layout horizontal pour tablette/desktop
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: _buildEditableDropdown(
                                            label: 'Commune *',
                                            value: selectedCommune,
                                            items: availableCommunes,
                                            onChanged: (value) => setState(() {
                                              selectedCommune = value;
                                              _updateAvailableVillages(value);
                                            }),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildEditableDropdown(
                                            label: 'Village/Localité *',
                                            value: selectedVillage,
                                            items: availableVillages,
                                            onChanged: (value) => setState(
                                                () => selectedVillage = value),
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 16),

                              // Prédominances florales
                              _buildEditableMultiSelect(
                                label: 'Prédominances florales *',
                                selectedValues: selectedFlorales,
                                availableValues: florales,
                                onChanged: (values) =>
                                    setState(() => selectedFlorales = values),
                              ),
                              const SizedBox(height: 16),

                              // Date de collecte (lecture seule)
                              _infoField(
                                  'Date de collecte',
                                  collecte!['createdAt'] != null
                                      ? DateFormat('dd/MM/yyyy').format(
                                          (collecte!['createdAt'] as Timestamp)
                                              .toDate())
                                      : ''),
                              const SizedBox(height: 16),

                              // Statut
                              Row(
                                children: [
                                  Text('Statut : ',
                                      style: theme.textTheme.bodyMedium),
                                  if (isAdmin)
                                    DropdownButton<String>(
                                      value: status,
                                      items: statusOptions
                                          .map((s) => DropdownMenuItem(
                                              value: s['value'],
                                              child: Text(s['label']!)))
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => status = v),
                                    )
                                  else
                                    _statusBadge(status),
                                  const SizedBox(width: 8),
                                  _statusBadge(status),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.width < 600
                              ? 12
                              : 16),
                      // Résumé détaillé
                      _buildDetailedSummary(theme),
                      SizedBox(
                          height: MediaQuery.of(context).size.width < 600
                              ? 16
                              : 20),
                      // Liste des contenants
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: EdgeInsets.all(
                              MediaQuery.of(context).size.width < 600
                                  ? 12
                                  : 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Titre et bouton ajouter responsive
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  if (constraints.maxWidth < 500) {
                                    // Layout vertical pour petits écrans
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Contenants de la collecte',
                                            style: theme.textTheme.titleMedium),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            icon:
                                                const Icon(Icons.add, size: 20),
                                            label: const Text(
                                                'Ajouter un contenant'),
                                            onPressed: () {
                                              _addNewContainer();
                                              _showContainerDialog(
                                                  isEdit: false);
                                            },
                                          ),
                                        ),
                                      ],
                                    );
                                  } else {
                                    // Layout horizontal pour écrans plus larges
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                              'Contenants de la collecte',
                                              style:
                                                  theme.textTheme.titleMedium),
                                        ),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.add, size: 20),
                                          label: const Text('Ajouter'),
                                          onPressed: () {
                                            _addNewContainer();
                                            _showContainerDialog(isEdit: false);
                                          },
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              if (containers.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.inventory_2_outlined,
                                          size: 48,
                                          color: Colors.grey.shade400),
                                      const SizedBox(height: 8),
                                      Text(
                                          'Aucun contenant dans cette collecte',
                                          style: TextStyle(
                                              color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                              ...List.generate(containers.length, (idx) {
                                final c = containers[idx];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      if (constraints.maxWidth < 500) {
                                        // Card compacte pour mobile
                                        return Card(
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 16,
                                                      child: Text('${idx + 1}',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      12)),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            '${c['hiveType']} - ${c['containerType']}',
                                                            style:
                                                                const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 4),
                                                          Text(
                                                            'Poids: ${c['weight']} kg',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey
                                                                  .shade600,
                                                            ),
                                                          ),
                                                          Text(
                                                            'Prix: ${c['unitPrice']} FCFA/kg',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey
                                                                  .shade600,
                                                            ),
                                                          ),
                                                          Text(
                                                            'Total: ${((c['weight'] ?? 0) * (c['unitPrice'] ?? 0)).toStringAsFixed(0)} FCFA',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  Colors.green,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child:
                                                          OutlinedButton.icon(
                                                        icon: const Icon(
                                                            Icons.edit,
                                                            size: 16),
                                                        label: const Text(
                                                            'Modifier',
                                                            style: TextStyle(
                                                                fontSize: 12)),
                                                        onPressed: () {
                                                          _startEditContainer(
                                                              idx);
                                                          _showContainerDialog(
                                                              isEdit: true);
                                                        },
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child:
                                                          OutlinedButton.icon(
                                                        icon: const Icon(
                                                            Icons.delete,
                                                            size: 16,
                                                            color: Colors.red),
                                                        label: const Text(
                                                            'Supprimer',
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .red)),
                                                        onPressed: () =>
                                                            _deleteContainer(
                                                                idx),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      } else {
                                        // ListTile standard pour écrans plus larges
                                        return Card(
                                          child: ListTile(
                                            leading: CircleAvatar(
                                                child: Text('${idx + 1}')),
                                            title: Text(
                                                '${c['hiveType']} - ${c['containerType']}'),
                                            subtitle: Text(
                                                'Poids: ${c['weight']} kg | Prix unitaire: ${c['unitPrice']} FCFA'),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit,
                                                      color: Colors.blue),
                                                  onPressed: () {
                                                    _startEditContainer(idx);
                                                    _showContainerDialog(
                                                        isEdit: true);
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete,
                                                      color: Colors.red),
                                                  onPressed: () =>
                                                      _deleteContainer(idx),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.width < 600
                              ? 16
                              : 20),
                      // Historique des modifications
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: EdgeInsets.all(
                              MediaQuery.of(context).size.width < 600
                                  ? 12
                                  : 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Historique des modifications',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              // Exemple de logs (à remplacer par des logs Firestore si disponibles)
                              if ((collecte?['logs'] as List?)?.isNotEmpty ??
                                  false)
                                ...List.generate(
                                    (collecte!['logs'] as List).length, (i) {
                                  final log = collecte!['logs'][i];
                                  return ListTile(
                                    leading: const Icon(Icons.history,
                                        color: Colors.amber),
                                    title: Text(log['action'] ?? ''),
                                    subtitle: Text(
                                        '${log['user'] ?? ''} • ${log['date'] ?? ''}\n${log['details'] ?? ''}'),
                                  );
                                })
                              else
                                const Text('Aucune modification enregistrée.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _infoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child:
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  // Widget pour créer un dropdown éditable
  Widget _buildEditableDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: isRequired && (value == null || value.isEmpty)
                    ? Colors.red.shade300
                    : Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<String>(
            value: items.contains(value) ? value : null,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hintText: 'Sélectionner $label',
              hintStyle: TextStyle(color: Colors.grey[400]),
            ),
            items: items
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item, style: const TextStyle(fontSize: 14)),
                    ))
                .toList(),
            onChanged: onChanged,
            validator: isRequired
                ? (value) => value == null || value.isEmpty
                    ? 'Ce champ est obligatoire'
                    : null
                : null,
          ),
        ),
      ],
    );
  }

  // Widget pour créer un chip multiselect éditable
  Widget _buildEditableMultiSelect({
    required String label,
    required List<String> selectedValues,
    required List<String> availableValues,
    required ValueChanged<List<String>> onChanged,
    bool isRequired = true,
  }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: isRequired && selectedValues.isEmpty
                    ? Colors.red.shade300
                    : Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedValues.isNotEmpty)
                Wrap(
                  spacing: isSmallScreen ? 4 : 8,
                  runSpacing: 4,
                  children: selectedValues
                      .map((value) => Chip(
                            label: Text(value,
                                style: TextStyle(
                                    fontSize: isSmallScreen ? 10 : 12)),
                            deleteIcon: Icon(Icons.close,
                                size: isSmallScreen ? 16 : 18),
                            onDeleted: () {
                              final newList = List<String>.from(selectedValues);
                              newList.remove(value);
                              onChanged(newList);
                            },
                            backgroundColor: Colors.blue.shade100,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ))
                      .toList(),
                )
              else
                Text('Aucune sélection',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: isSmallScreen ? 4 : 8,
                runSpacing: 4,
                children: availableValues
                    .where((value) => !selectedValues.contains(value))
                    .map((value) => ActionChip(
                          label: Text(value,
                              style:
                                  TextStyle(fontSize: isSmallScreen ? 10 : 12)),
                          onPressed: () {
                            final newList = List<String>.from(selectedValues);
                            newList.add(value);
                            onChanged(newList);
                          },
                          backgroundColor: Colors.grey.shade200,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
