import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:apisavana_gestion/data/geographe/geographie.dart';

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
  const NouvelleCollecteRecoltePage({Key? key}) : super(key: key);

  @override
  State<NouvelleCollecteRecoltePage> createState() =>
      _NouvelleCollecteRecoltePageState();
}

class _NouvelleCollecteRecoltePageState
    extends State<NouvelleCollecteRecoltePage> {
  // Exemple d'infos site/technicien (à remplacer par la session réelle)
  final SiteInfo siteInfo = SiteInfo(
    siteName: 'Koudougou',
    technicianName: 'Otis Malo',
    region: 'Centre-Ouest',
    province: 'Boulkiemdé',
    commune: 'Koudougou',
    village: 'Koudougou',
  );

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
  String? selectedArrondissement;
  String? selectedSecteur;
  String? selectedQuartier;
  String? selectedTechnician;
  List<String> selectedFlorales = [];

  // Liste des techniciens (à adapter selon la source réelle)
  final List<String> techniciens = [
    'Otis Malo',
    'Abdoulaye Sawadogo',
    'Fatou Traoré',
    'Autre...'
  ];

  // Liste des prédominances florales (à adapter selon la source réelle)
  final List<String> flores = [
    'Karité',
    'Néré',
    'Acacia',
    'Manguier',
    'Tournesol',
    'Coton',
    'Autres'
  ];

  @override
  void initState() {
    super.initState();
    fetchFirestoreHistory();
  }

  Future<void> fetchFirestoreHistory() async {
    setState(() => isLoadingHistory = true);
    try {
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
    } catch (e) {
      // Optionally handle error
    }
    setState(() => isLoadingHistory = false);
  }

  // Ajout ou édition d'un contenant
  void addOrEditContainer() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
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

  // Validation et soumission (Firestore intégré)
  void submitHarvest() async {
    if (containers.isEmpty) {
      setState(() {
        statusMessage = 'Ajoutez au moins un contenant.';
      });
      return;
    }
    setState(() {
      isSubmitting = true;
      statusMessage = null;
    });
    try {
      final doc =
          await FirebaseFirestore.instance.collection('collectes_recolte').add({
        'site': siteInfo.siteName,
        'region': siteInfo.region,
        'province': siteInfo.province,
        'commune': siteInfo.commune,
        'village': siteInfo.village,
        'technicien_nom': siteInfo.technicianName,
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
        'status': 'en_attente', // Statut par défaut
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Ajout à l'historique local
      setState(() {
        isSubmitting = false;
        statusMessage = 'Collecte enregistrée avec succès !';
        history.insert(0, {
          'id': doc.id,
          'date': DateTime.now(),
          'site': siteInfo.siteName,
          'totalWeight': totalWeight,
          'totalAmount': totalAmount,
          'status': 'en_attente', // Statut par défaut
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
        containers.clear();
      });
    } catch (e) {
      setState(() {
        isSubmitting = false;
        statusMessage = 'Erreur lors de l\'enregistrement : $e';
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle collecte - Récolte')),
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
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacementNamed('/dashboard');
                  },
                ),
                // ... tu peux ajouter d'autres entrées ici si besoin ...
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
                          selectedArrondissement = null;
                          selectedSecteur = null;
                          selectedQuartier = null;
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
                          selectedArrondissement = null;
                          selectedSecteur = null;
                          selectedQuartier = null;
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
                          selectedArrondissement = null;
                          selectedSecteur = null;
                          selectedQuartier = null;
                        });
                      },
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration:
                            InputDecoration(labelText: 'Commune'),
                      ),
                      popupProps: PopupProps.menu(showSearchBox: true),
                    ),
                    const SizedBox(height: 8),
                    if (selectedCommune == 'Ouagadougou' ||
                        selectedCommune == 'Bobo-Dioulasso') ...[
                      DropdownSearch<String>(
                        items: [], // Remplir avec ArrondissementsParCommune[selectedCommune] si dispo
                        selectedItem: selectedArrondissement,
                        onChanged: (v) {
                          setState(() {
                            selectedArrondissement = v;
                            selectedSecteur = null;
                            selectedQuartier = null;
                          });
                        },
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration:
                              InputDecoration(labelText: 'Arrondissement'),
                        ),
                        popupProps: PopupProps.menu(showSearchBox: true),
                      ),
                      const SizedBox(height: 8),
                      DropdownSearch<String>(
                        items: [], // Remplir avec secteursParArrondissement[...] si dispo
                        selectedItem: selectedSecteur,
                        onChanged: (v) {
                          setState(() {
                            selectedSecteur = v;
                            selectedQuartier = null;
                          });
                        },
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration:
                              InputDecoration(labelText: 'Secteur'),
                        ),
                        popupProps: PopupProps.menu(showSearchBox: true),
                      ),
                      const SizedBox(height: 8),
                      DropdownSearch<String>(
                        items: [], // Remplir avec QuartierParSecteur[...] si dispo
                        selectedItem: selectedQuartier,
                        onChanged: (v) => setState(() => selectedQuartier = v),
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration:
                              InputDecoration(labelText: 'Quartier'),
                        ),
                        popupProps: PopupProps.menu(showSearchBox: true),
                      ),
                    ] else ...[
                      DropdownSearch<String>(
                        items: selectedCommune != null
                            ? (villagesParCommune[selectedCommune!] ?? [])
                            : [],
                        selectedItem: selectedVillage,
                        onChanged: (v) => setState(() => selectedVillage = v),
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration:
                              InputDecoration(labelText: 'Village'),
                        ),
                        popupProps: PopupProps.menu(showSearchBox: true),
                      ),
                    ],
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
                    DropdownSearch<String>(
                      items: techniciens,
                      selectedItem: selectedTechnician,
                      onChanged: (v) => setState(() => selectedTechnician = v),
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
                    Wrap(
                      spacing: 8,
                      children: flores.map((florale) {
                        final selected = selectedFlorales.contains(florale);
                        return FilterChip(
                          label: Text(florale),
                          selected: selected,
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
                  ],
                ),
              ),
              // --- Section Infos site (existante) ---
              Text('Infos site',
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
                      child: TextFormField(
                    initialValue: siteInfo.siteName,
                    decoration: const InputDecoration(labelText: 'Site'),
                    enabled: false,
                    maxLines: 1,
                    style: const TextStyle(overflow: TextOverflow.ellipsis),
                  )),
                  const SizedBox(width: 16),
                  Expanded(
                      child: TextFormField(
                    initialValue: siteInfo.technicianName,
                    decoration: const InputDecoration(labelText: 'Technicien'),
                    enabled: false,
                    maxLines: 1,
                    style: const TextStyle(overflow: TextOverflow.ellipsis),
                  )),
                ],
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
                        const InputDecoration(labelText: 'Type de ruche'),
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
                    validator: (v) => v == null ? 'Champ requis' : null,
                  )),
                  const SizedBox(width: 16),
                  Expanded(
                      child: DropdownButtonFormField<String>(
                    value: containerType,
                    decoration:
                        const InputDecoration(labelText: 'Type de contenant'),
                    items: [
                      DropdownMenuItem(
                          value: 'Pôt',
                          child: Text('Pôt', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: 'Fût',
                          child: Text('Fût', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => setState(() => containerType = v),
                    validator: (v) => v == null ? 'Champ requis' : null,
                  )),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: TextFormField(
                    initialValue: weight?.toString(),
                    decoration: const InputDecoration(labelText: 'Poids (kg)'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                    ],
                    onSaved: (v) => weight = double.tryParse(v ?? ''),
                    validator: (v) {
                      final val = double.tryParse(v ?? '');
                      if (val == null || val <= 0) return 'Poids invalide';
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
                        labelText: 'Prix unitaire (FCFA)'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                    ],
                    onSaved: (v) => unitPrice = double.tryParse(v ?? ''),
                    validator: (v) {
                      final val = double.tryParse(v ?? '');
                      if (val == null || val < 0) return 'Prix invalide';
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
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contenants saisis',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (containers.isEmpty) const Text('Aucun contenant ajouté.'),
            if (containers.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: containers.length,
                itemBuilder: (context, idx) {
                  final c = containers[idx];
                  return Card(
                    color: Colors.grey[50],
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text('${c.hiveType} - ${c.containerType}',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          'Poids: 	${c.weight} kg  |  Prix unitaire: ${c.unitPrice} FCFA',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${c.total.toStringAsFixed(0)} FCFA',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
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
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total poids:',
                    style: Theme.of(context).textTheme.bodyLarge),
                Text('${totalWeight.toStringAsFixed(2)} kg',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Montant total:',
                    style: Theme.of(context).textTheme.bodyLarge),
                Text('${totalAmount.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                icon: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: const Text('Finaliser la collecte'),
                onPressed: isSubmitting ? null : submitHarvest,
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
            Text('Historique Firestore (multi-utilisateur)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            // Filtres site/technicien
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: filterSite,
                    decoration:
                        const InputDecoration(labelText: 'Filtrer par site'),
                    items: [
                      DropdownMenuItem<String>(
                          value: '', child: Text('Tous les sites')),
                      ...availableSites.map((s) =>
                          DropdownMenuItem<String>(value: s, child: Text(s)))
                    ],
                    onChanged: (v) => setState(() {
                      filterSite = (v != null && v.isNotEmpty) ? v : null;
                      fetchFirestoreHistory();
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: filterTechnician,
                    decoration: const InputDecoration(
                        labelText: 'Filtrer par technicien'),
                    items: [
                      DropdownMenuItem<String>(
                          value: '',
                          child: Text(
                            'Tous les techniciens',
                            style: TextStyle(
                                overflow: TextOverflow.ellipsis, fontSize: 11),
                          )),
                      ...availableTechnicians.map((t) =>
                          DropdownMenuItem<String>(value: t, child: Text(t)))
                    ],
                    onChanged: (v) => setState(() {
                      filterTechnician = (v != null && v.isNotEmpty) ? v : null;
                      fetchFirestoreHistory();
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isLoadingHistory)
              const Center(child: CircularProgressIndicator()),
            if (!isLoadingHistory && firestoreHistory.isEmpty)
              const Text('Aucune collecte trouvée.'),
            if (!isLoadingHistory && firestoreHistory.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: firestoreHistory.length,
                itemBuilder: (context, idx) {
                  final h = firestoreHistory[idx];
                  final pots = h['contenants']
                          ?.where((c) => c['containerType'] == 'Pôt')
                          .length ??
                      0;
                  final futs = h['contenants']
                          ?.where((c) => c['containerType'] == 'Fût')
                          .length ??
                      0;
                  return ListTile(
                    leading: const Icon(Icons.cloud_done, color: Colors.green),
                    title: Text('Site: \'${h['site']}\'',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                        'Poids: ${h['totalWeight']} kg | Montant: ${h['totalAmount']} FCFA\nTechnicien: ${h['technicien_nom']}\nPôt: $pots  Fût: $futs',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(h['status'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (h['date'] != null)
                          Text('${h['date']}'.split(' ')[0],
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Rafraîchir l\'historique Firestore'),
              onPressed: fetchFirestoreHistory,
            ),
          ],
        ),
      ),
    );
  }
}
