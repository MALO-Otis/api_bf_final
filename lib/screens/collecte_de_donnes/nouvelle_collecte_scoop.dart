import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/geographe/geographie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/services/localite_codification_service.dart';
import 'package:apisavana_gestion/authentication/user_session.dart';

class NouvelleCollecteScoopPage extends StatefulWidget {
  const NouvelleCollecteScoopPage({Key? key}) : super(key: key);

  @override
  State<NouvelleCollecteScoopPage> createState() =>
      _NouvelleCollecteScoopPageState();
}

class _NouvelleCollecteScoopPageState extends State<NouvelleCollecteScoopPage> {
  // Couleurs du thème
  static const Color kPrimaryColor = Color(0xFFF49101);
  static const Color kAccentColor = Color(0xFF0066CC);

  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _scoopNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _nombreProducteursController = TextEditingController();
  final _notesController = TextEditingController();

  // Données utilisateur
  UserSession? userSession;
  Map<String, dynamic>? currentUserData;
  bool isLoadingUserData = true;

  // Variables de collecte
  DateTime? selectedDate;
  String? selectedSite;
  String? selectedTechnician;
  String? selectedQualite = 'Standard';
  List<Map<String, dynamic>> produits = [];

  // Variables géographiques pour code_collecte
  String? selectedRegion;
  String? selectedProvince;
  String? selectedCommune;
  String? selectedVillage;

  // Listes
  final List<String> qualites = [
    'Excellent',
    'Très bon',
    'Bon',
    'Standard',
    'Passable'
  ];
  final List<String> typesRuche = [
    'Traditionnelle',
    'Moderne',
    'Top Bar',
    'Warré'
  ];
  final List<String> typesProduit = ['Miel', 'Cire', 'Propolis', 'Pollen'];

  // État de chargement
  bool isSaving = false;
  bool isGettingLocation = false;

  // Données de géolocalisation
  Map<String, dynamic>? _geolocationData;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
    selectedDate = DateTime.now();
    _addNewProduit(); // Ajouter un premier produit
  }

  @override
  void dispose() {
    _scoopNameController.dispose();
    _locationController.dispose();
    _nombreProducteursController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Initialisation des données utilisateur
  Future<void> _initializeUserData() async {
    setState(() => isLoadingUserData = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('Données utilisateur non trouvées');
      }

      currentUserData = userDoc.data()!;

      try {
        userSession = Get.find<UserSession>();
      } catch (e) {
        print('UserSession non trouvée dans GetX: $e');
      }

      // Initialiser les valeurs par défaut
      selectedSite = currentUserData?['site'] ?? userSession?.site;
      selectedTechnician = currentUserData?['nom'] ?? userSession?.nom;
    } catch (e) {
      print('Erreur lors de l\'initialisation des données utilisateur: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des données: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoadingUserData = false);
      }
    }
  }

  // Ajouter un nouveau produit
  void _addNewProduit() {
    setState(() {
      produits.add({
        'typeRuche': '',
        'typeProduit': '',
        'quantiteAcceptee': 0.0,
        'quantiteRejetee': 0.0,
        'prixUnitaire': 0.0,
        'sousTotal': 0.0,
      });
    });
  }

  // Supprimer un produit
  void _removeProduit(int index) {
    setState(() {
      if (produits.length > 1) {
        produits.removeAt(index);
      }
    });
  }

  // Calculer le sous-total pour un produit
  void _calculateSousTotal(int index) {
    final produit = produits[index];
    final quantite = (produit['quantiteAcceptee'] ?? 0.0) as double;
    final prix = (produit['prixUnitaire'] ?? 0.0) as double;
    final sousTotal = quantite * prix;

    setState(() {
      produits[index]['sousTotal'] = sousTotal;
    });
  }

  // Calculer les totaux
  Map<String, double> _calculateTotals() {
    double totalWeight = 0.0;
    double totalAmount = 0.0;
    double totalRejected = 0.0;

    for (final produit in produits) {
      totalWeight += (produit['quantiteAcceptee'] ?? 0.0) as double;
      totalRejected += (produit['quantiteRejetee'] ?? 0.0) as double;
      totalAmount += (produit['sousTotal'] ?? 0.0) as double;
    }

    return {
      'totalWeight': totalWeight,
      'totalAmount': totalAmount,
      'totalRejected': totalRejected,
    };
  }

  // Réinitialiser le formulaire
  void _resetForm() {
    setState(() {
      _scoopNameController.clear();
      _locationController.clear();
      _nombreProducteursController.clear();
      _notesController.clear();
      selectedDate = DateTime.now();
      selectedQualite = 'Standard';
      selectedRegion = null;
      selectedProvince = null;
      selectedCommune = null;
      selectedVillage = null;
      produits.clear();
      _geolocationData = null;
      _addNewProduit();
    });
  }

  // Méthodes pour obtenir les données géographiques
  List<String> _getRegions() {
    return GeographieData.regionsBurkina
        .map((region) => region['nom'] as String)
        .toList();
  }

  List<String> _getProvinces(String? regionNom) {
    if (regionNom == null) return [];

    // Trouver le code de la région
    final region = GeographieData.regionsBurkina
        .firstWhere((r) => r['nom'] == regionNom, orElse: () => {});

    if (region.isEmpty) return [];

    final regionCode = region['code'];
    final provinces = GeographieData.provincesParRegion[regionCode] ?? [];

    return provinces.map((province) => province['nom'] as String).toList();
  }

  List<String> _getCommunes(String? regionNom, String? provinceNom) {
    if (regionNom == null || provinceNom == null) return [];

    // Trouver le code de la région
    final region = GeographieData.regionsBurkina
        .firstWhere((r) => r['nom'] == regionNom, orElse: () => {});

    if (region.isEmpty) return [];

    final regionCode = region['code'];

    // Trouver le code de la province
    final provinces = GeographieData.provincesParRegion[regionCode] ?? [];
    final province =
        provinces.firstWhere((p) => p['nom'] == provinceNom, orElse: () => {});

    if (province.isEmpty) return [];

    final provinceCode = province['code'];
    final communes =
        GeographieData.communesParProvince['$regionCode-$provinceCode'] ?? [];

    return communes.map((commune) => commune['nom'] as String).toList();
  }

  // Obtenir la géolocalisation GPS
  Future<void> _getCurrentLocation() async {
    setState(() => isGettingLocation = true);

    try {
      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permission de géolocalisation refusée');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Permission de géolocalisation définitivement refusée. Activez-la dans les paramètres.');
      }

      // Obtenir la position GPS
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String address =
          'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';

      setState(() {
        _geolocationData = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'altitude': position.altitude,
          'heading': position.heading,
          'speed': position.speed,
          'timestamp': position.timestamp,
          'address': address,
        };
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Position GPS obtenue avec une précision de ${position.accuracy.toStringAsFixed(1)} m',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Erreur géolocalisation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de géolocalisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => isGettingLocation = false);
    }
  }

  // Sauvegarder la collecte
  Future<void> _saveCollecte() async {
    print("🟡 _saveCollecte - Début enregistrement collecte SCOOP");

    if (!_formKey.currentState!.validate()) {
      print("🔴 _saveCollecte - Validation formulaire échoué");
      return;
    }

    // Vérifier que tous les produits sont valides
    print("🟡 _saveCollecte - Vérification des ${produits.length} produits");
    for (int i = 0; i < produits.length; i++) {
      final produit = produits[i];
      if (produit['typeRuche'].isEmpty ||
          produit['typeProduit'].isEmpty ||
          (produit['quantiteAcceptee'] ?? 0.0) <= 0) {
        print("🔴 _saveCollecte - Produit ${i + 1} invalide: $produit");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Veuillez compléter tous les champs du produit ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => isSaving = true);

    try {
      print("🟡 _saveCollecte - Récupération utilisateur");
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("🔴 _saveCollecte - Utilisateur non connecté");
        throw Exception('Utilisateur non connecté');
      }
      print("🟡 _saveCollecte - Utilisateur: ${user.uid}");

      final userSite = currentUserData?['site'] ?? userSession?.site;
      if (userSite == null || userSite.isEmpty) {
        print("🔴 _saveCollecte - Site utilisateur non défini");
        throw Exception('Site utilisateur non défini');
      }
      print("🟡 _saveCollecte - Site: $userSite");

      final totals = _calculateTotals();
      print("🟡 _saveCollecte - Totaux calculés:");
      print("   - Poids total: ${totals['totalWeight']} kg");
      print("   - Montant total: ${totals['totalAmount']} FCFA");
      print("   - Total rejeté: ${totals['totalRejected']} kg");

      print("🟡 _saveCollecte - Préparation données collecte");
      print("🟡 _saveCollecte - SCOOP: ${_scoopNameController.text.trim()}");
      print(
          "🟡 _saveCollecte - Localisation: ${_locationController.text.trim()}");
      print("🟡 _saveCollecte - Technicien: $selectedTechnician");
      print("🟡 _saveCollecte - Date: $selectedDate");
      print("🟡 _saveCollecte - Qualité: $selectedQualite");

      // Génération automatique du Code_Collecte basé sur la localité de la SCOOP
      String? codeCollecte;
      if (selectedRegion != null &&
          selectedProvince != null &&
          selectedCommune != null) {
        codeCollecte = LocaliteCodificationService.generateCodeLocalite(
          regionNom: selectedRegion!,
          provinceNom: selectedProvince!,
          communeNom: selectedCommune!,
        );
        print('🏷️ DEBUG: Code_Collecte généré pour SCOOP: $codeCollecte');
      } else {
        print(
            '⚠️ DEBUG: Localisation SCOOP incomplète - code_collecte sera null');
      }

      final collecteData = {
        'type': 'Achat SCOOP',
        'scoop_name': _scoopNameController.text.trim(),
        'localisation': _locationController.text.trim(),
        'site': userSite,
        // Informations géographiques structurées
        'region': selectedRegion,
        'province': selectedProvince,
        'commune': selectedCommune,
        'village': selectedVillage,
        // NOUVEAU: Code_Collecte basé sur la localité de la SCOOP
        'code_collecte': codeCollecte,
        'technicien_nom': selectedTechnician ?? '',
        'technicien_uid': user.uid,
        'date_collecte': Timestamp.fromDate(selectedDate!),
        'nombre_producteurs':
            int.tryParse(_nombreProducteursController.text) ?? 0,
        'qualite': selectedQualite,
        'notes': _notesController.text.trim(),
        'produits': produits,
        'totalWeight': totals['totalWeight'],
        'totalAmount': totals['totalAmount'],
        'totalRejected': totals['totalRejected'],
        'status': 'en_attente',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        // 🆕 Données de géolocalisation GPS
        if (_geolocationData != null) 'geolocationData': _geolocationData,
      };

      print(
          "🟡 _saveCollecte - Données préparées: ${collecteData.keys.toList()}");
      print("🟡 _saveCollecte - Début sauvegarde Firestore");

      // Enregistrer dans la collection du site
      final docRef = await FirebaseFirestore.instance
          .collection(userSite)
          .doc('collectes_scoop')
          .collection('collectes_scoop')
          .add(collecteData);

      print("✅ _saveCollecte - Collecte SCOOP enregistrée avec succès");
      print("🟡 _saveCollecte - ID document: ${docRef.id}");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collecte SCOOP enregistrée avec succès'),
            backgroundColor: Colors.green,
          ),
        );

        // Réinitialiser le formulaire
        _resetForm();

        // Retourner à la page précédente
        Navigator.of(context).pop();
      }
    } catch (e, stackTrace) {
      print("🔴 _saveCollecte - ERREUR: $e");
      print("🔴 _saveCollecte - STACK TRACE: $stackTrace");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'enregistrement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingUserData) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Nouvelle collecte SCOOP'),
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle collecte SCOOP'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetForm,
            tooltip: 'Réinitialiser',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Informations de base
            _buildSectionCard(
              title: 'Informations de base',
              icon: Icons.info,
              children: [
                _buildTextField(
                  controller: _scoopNameController,
                  label: 'Nom de la SCOOP',
                  icon: Icons.group,
                  validator: (value) =>
                      value?.isEmpty == true ? 'Nom de la SCOOP requis' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _locationController,
                  label: 'Localisation',
                  icon: Icons.location_on,
                  validator: (value) =>
                      value?.isEmpty == true ? 'Localisation requise' : null,
                ),
                const SizedBox(height: 16),
                _buildDatePicker(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _nombreProducteursController,
                        label: 'Nombre de producteurs',
                        icon: Icons.people,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty == true) return 'Nombre requis';
                          final number = int.tryParse(value!);
                          if (number == null || number <= 0)
                            return 'Nombre invalide';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdownField<String>(
                        value: selectedQualite,
                        label: 'Qualité',
                        icon: Icons.star,
                        items: qualites,
                        onChanged: (value) =>
                            setState(() => selectedQualite = value),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Section géographique pour Code_Collecte
            _buildSectionCard(
              title: 'Localisation géographique (Code collecte)',
              icon: Icons.map,
              children: [
                _buildDropdownField<String>(
                  value: selectedRegion,
                  label: 'Région',
                  icon: Icons.public,
                  items: _getRegions(),
                  onChanged: (value) {
                    setState(() {
                      selectedRegion = value;
                      selectedProvince = null; // Reset province
                      selectedCommune = null; // Reset commune
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdownField<String>(
                  value: selectedProvince,
                  label: 'Province',
                  icon: Icons.location_city,
                  items: _getProvinces(selectedRegion),
                  onChanged: (value) {
                    setState(() {
                      selectedProvince = value;
                      selectedCommune = null; // Reset commune
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdownField<String>(
                  value: selectedCommune,
                  label: 'Commune',
                  icon: Icons.location_on,
                  items: _getCommunes(selectedRegion, selectedProvince),
                  onChanged: (value) {
                    setState(() {
                      selectedCommune = value;
                    });
                  },
                ),
                if (selectedRegion != null &&
                    selectedProvince != null &&
                    selectedCommune != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: kPrimaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.qr_code, color: kPrimaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Code collecte : ${LocaliteCodificationService.generateCodeLocalite(
                                    regionNom: selectedRegion!,
                                    provinceNom: selectedProvince!,
                                    communeNom: selectedCommune!,
                                  ) ?? 'Non disponible'}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Produits
            _buildSectionCard(
              title: 'Produits collectés',
              icon: Icons.inventory,
              children: [
                ...List.generate(
                    produits.length, (index) => _buildProduitCard(index)),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _addNewProduit,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un produit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Résumé
            _buildSummaryCard(),

            const SizedBox(height: 20),

            // 🆕 Section Géolocalisation GPS
            _buildGeolocationSection(),

            const SizedBox(height: 20),

            // Notes
            _buildSectionCard(
              title: 'Notes additionnelles',
              icon: Icons.note,
              children: [
                _buildTextField(
                  controller: _notesController,
                  label: 'Notes (optionnel)',
                  icon: Icons.edit,
                  maxLines: 3,
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _saveCollecte,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Enregistrer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: kPrimaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String label,
    required IconData icon,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(item.toString()),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now().add(const Duration(days: 30)),
        );
        if (date != null) {
          setState(() => selectedDate = date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date de collecte',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kPrimaryColor, width: 2),
          ),
        ),
        child: Text(
          selectedDate != null
              ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
              : 'Sélectionner une date',
        ),
      ),
    );
  }

  Widget _buildProduitCard(int index) {
    final produit = produits[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Produit ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (produits.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeProduit(index),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField<String>(
                    value: produit['typeRuche'].isEmpty
                        ? null
                        : produit['typeRuche'],
                    label: 'Type de ruche',
                    icon: Icons.home,
                    items: typesRuche,
                    onChanged: (value) {
                      setState(() {
                        produits[index]['typeRuche'] = value ?? '';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdownField<String>(
                    value: produit['typeProduit'].isEmpty
                        ? null
                        : produit['typeProduit'],
                    label: 'Type de produit',
                    icon: Icons.inventory_2,
                    items: typesProduit,
                    onChanged: (value) {
                      setState(() {
                        produits[index]['typeProduit'] = value ?? '';
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: produit['quantiteAcceptee'].toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantité acceptée (kg)',
                      prefixIcon: const Icon(Icons.scale),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      final quantite = double.tryParse(value) ?? 0.0;
                      setState(() {
                        produits[index]['quantiteAcceptee'] = quantite;
                        _calculateSousTotal(index);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: produit['quantiteRejetee'].toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantité rejetée (kg)',
                      prefixIcon: const Icon(Icons.remove_circle),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      final quantite = double.tryParse(value) ?? 0.0;
                      setState(() {
                        produits[index]['quantiteRejetee'] = quantite;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: produit['prixUnitaire'].toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Prix unitaire (FCFA/kg)',
                      prefixIcon: const Icon(Icons.text_fields),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      final prix = double.tryParse(value) ?? 0.0;
                      setState(() {
                        produits[index]['prixUnitaire'] = prix;
                        _calculateSousTotal(index);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Sous-total (FCFA)',
                      prefixIcon: const Icon(Icons.calculate),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '${(produit['sousTotal'] ?? 0.0).toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totals = _calculateTotals();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              kPrimaryColor.withOpacity(0.1),
              kAccentColor.withOpacity(0.1)
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Résumé de la collecte',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Poids total accepté',
                    '${totals['totalWeight']!.toStringAsFixed(1)} kg',
                    Icons.scale,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Poids total rejeté',
                    '${totals['totalRejected']!.toStringAsFixed(1)} kg',
                    Icons.remove_circle,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryItem(
              'Montant total',
              '${totals['totalAmount']!.toStringAsFixed(0)} FCFA',
              Icons.text_fields,
              kPrimaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
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
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // 🆕 Section Géolocalisation GPS
  Widget _buildGeolocationSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  'Géolocalisation GPS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bouton de géolocalisation
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade400,
                    Colors.green.shade400,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: isGettingLocation ? null : _getCurrentLocation,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isGettingLocation)
                          const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _geolocationData == null
                                  ? Icons.my_location
                                  : Icons.location_on,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          isGettingLocation
                              ? 'Obtention de la position...'
                              : _geolocationData == null
                                  ? 'Obtenir ma position GPS'
                                  : 'Position GPS obtenue ✓',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            if (_geolocationData != null) ...[
              const SizedBox(height: 16),

              // Affichage des données GPS
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Données GPS enregistrées',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Grille des informations GPS
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 3,
                      children: [
                        _buildGPSInfoCard(
                          'Latitude',
                          _geolocationData!['latitude'].toStringAsFixed(6),
                          Icons.north,
                        ),
                        _buildGPSInfoCard(
                          'Longitude',
                          _geolocationData!['longitude'].toStringAsFixed(6),
                          Icons.east,
                        ),
                        _buildGPSInfoCard(
                          'Précision',
                          '${_geolocationData!['accuracy'].toStringAsFixed(1)} m',
                          Icons.center_focus_strong,
                        ),
                        _buildGPSInfoCard(
                          'Horodatage',
                          _formatTimestamp(_geolocationData!['timestamp']),
                          Icons.access_time,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            if (_geolocationData == null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'La géolocalisation GPS est recommandée pour tracer précisément le lieu de collecte.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGPSInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey.shade600, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'N/A';
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
