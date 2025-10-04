import 'package:get/get.dart';
import 'widgets/section_scoop.dart';
import 'widgets/section_resume.dart';
import 'widgets/section_periode.dart';
import 'package:flutter/material.dart';
import '../historiques_collectes.dart';
import 'widgets/section_contenants.dart';
import 'widgets/section_observations.dart';
import '../../../utils/clean_geolocation.dart';
import '../../../data/models/scoop_models.dart';
import '../../../authentication/user_session.dart';
import '../../../services/universal_container_id_service.dart';
import '../../../data/services/stats_scoop_contenants_service.dart';

class NouvelAchatScoopContenantsPage extends StatefulWidget {
  const NouvelAchatScoopContenantsPage({super.key});

  @override
  State<NouvelAchatScoopContenantsPage> createState() =>
      _NouvelAchatScoopContenantsPageState();
}

class _NouvelAchatScoopContenantsPageState
    extends State<NouvelAchatScoopContenantsPage>
    with SingleTickerProviderStateMixin {
  // Navigation
  late TabController _tabController;
  int _currentStep = 0;

  // État du formulaire
  ScoopModel? _selectedScoop;
  String _selectedPeriode = '';
  List<ContenantScoopModel> _contenants = [];
  String _observations = '';
  bool _isLoading = false;

  // UserSession
  final UserSession _userSession = Get.find<UserSession>();

  // Liste des étapes
  final List<String> _steps = [
    'Géolocalisation',
    'SCOOP',
    'Période',
    'Contenants',
    'Observations',
    'Résumé'
  ];

  // Données de géolocalisation
  Map<String, dynamic>? _geolocationData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _steps.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentStep = _tabController.index;
      });
    }
  }

  // Validation des étapes pour empêcher le scroll non autorisé
  bool _isStepEnabled(int stepIndex) {
    switch (stepIndex) {
      case 0: // Géolocalisation (maintenant en première position)
        return true;
      case 1: // SCOOP
        return true;
      case 2: // Période
        return _selectedScoop != null;
      case 3: // Contenants
        return _selectedScoop != null && _selectedPeriode.isNotEmpty;
      case 4: // Observations
        return _selectedScoop != null &&
            _selectedPeriode.isNotEmpty &&
            _contenants.isNotEmpty;
      case 5: // Résumé
        return _selectedScoop != null &&
            _selectedPeriode.isNotEmpty &&
            _contenants.isNotEmpty;
      default:
        return false;
    }
  }

  void _showValidationMessage(int targetStep) {
    String message = '';
    switch (targetStep) {
      case 2:
        message = 'Veuillez d\'abord sélectionner un SCOOP';
        break;
      case 3:
        message = 'Veuillez d\'abord sélectionner un SCOOP et une période';
        break;
      case 4:
      case 5:
        message =
            'Veuillez d\'abord sélectionner un SCOOP, une période et ajouter des contenants';
        break;
    }

    Get.snackbar(
      'Étape non disponible',
      message,
      backgroundColor: Colors.orange.shade100,
      colorText: Colors.orange.shade800,
      icon: const Icon(Icons.warning, color: Colors.orange),
      duration: const Duration(seconds: 2),
    );
  }

  // Calcul des totaux
  Map<String, double> get _totals {
    final poids = _contenants.fold<double>(0, (sum, c) => sum + c.poids);
    final montant = _contenants.fold<double>(0, (sum, c) => sum + c.prix);
    return {'poids': poids, 'montant': montant};
  }

  // Validation par étape
  Map<String, bool> get _canContinue {
    return {
      'scoop': _selectedScoop != null,
      'periode': _selectedPeriode.isNotEmpty,
      'contenants': _contenants.isNotEmpty,
      'observations': true,
      'resume': true,
    };
  }

  // Navigation
  void _goToStep(int step) {
    if (step >= 0 && step < _steps.length) {
      _tabController.animateTo(step);
    }
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      _goToStep(_currentStep + 1);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  // Sauvegarde
  Future<void> _saveCollecte() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      // Générer les IDs universels pour les contenants
      final contenantsAvecIds = await _genererIdsUniversels(_contenants);

      final collecte = CollecteScoopModel(
        id: '', // Sera généré par Firestore
        dateAchat: DateTime.now(),
        periodeCollecte: _selectedPeriode,
        scoopId: _selectedScoop!.id,
        scoopNom: _selectedScoop!.nom,
        contenants: contenantsAvecIds,
        poidsTotal: _totals['poids']!,
        montantTotal: _totals['montant']!,
        observations: _observations,
        collecteurId: _userSession.uid ?? '',
        collecteurNom: _userSession.nom ?? '',
        site: _userSession.site ?? '',
        createdAt: DateTime.now(),
        geolocationData: _geolocationData, // Inclure les données GPS
      );

      await StatsScoopContenantsService.saveCollecteScoop(collecte);

      Get.snackbar(
        'Succès',
        'Achat SCOOP enregistré avec succès',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        icon: const Icon(Icons.check_circle, color: Colors.green),
      );

      // Reset du formulaire
      _resetForm();
      _goToStep(0);
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de l\'enregistrement: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateForm() {
    if (_selectedScoop == null) {
      Get.snackbar('Champs manquants', 'Sélectionnez un SCOOP');
      _goToStep(0);
      return false;
    }
    if (_selectedPeriode.isEmpty) {
      Get.snackbar('Champs manquants', 'Sélectionnez une période');
      _goToStep(1);
      return false;
    }
    if (_contenants.isEmpty) {
      Get.snackbar('Champs manquants', 'Ajoutez au moins un contenant');
      _goToStep(2);
      return false;
    }
    return true;
  }

  void _resetForm() {
    setState(() {
      _selectedScoop = null;
      _selectedPeriode = '';
      _contenants.clear();
      _observations = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber.shade50,
      appBar: AppBar(
        title: const Text(
          'Nouvel achat SCOOP - Contenants',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            tooltip: 'Historique des achats',
            icon: const Icon(Icons.history),
            onPressed: () => Get.to(() => const HistoriquesCollectesPage()),
          ),
        ],
      ),
      body: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Indicateur de progression
            _buildProgressIndicator(),

            const SizedBox(height: 24),

            // Contenu principal avec onglets
            Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    // En-tête avec onglets
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        onTap: (index) {
                          if (!_isStepEnabled(index)) {
                            // Empêcher le changement d'onglet
                            _tabController.animateTo(_currentStep);
                            _showValidationMessage(index);
                            return;
                          }
                        },
                        tabs: _steps.asMap().entries.map((entry) {
                          final index = entry.key;
                          final step = entry.value;
                          final isEnabled = _isStepEnabled(index);

                          return Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentStep == index
                                        ? Colors.amber.shade700
                                        : isEnabled
                                            ? Colors.amber.shade400
                                            : Colors.grey.shade300,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  step,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isEnabled
                                        ? Colors.black87
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        labelColor: Colors.black87,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.amber.shade700,
                        isScrollable: true,
                      ),
                    ),

                    // Contenu des onglets
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildGeolocationSection(),
                          _buildScoopSection(),
                          _buildPeriodeSection(),
                          _buildContenantsSection(),
                          _buildObservationsSection(),
                          _buildResumeSection(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parcours guidé',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / _steps.length,
                  backgroundColor: Colors.grey.shade300,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.amber.shade700),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_currentStep + 1}/${_steps.length}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Poids total: ${_totals['poids']?.toStringAsFixed(2)} kg • Montant total: ${_totals['montant']?.toStringAsFixed(2)} CFA',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoopSection() {
    return SectionScoop(
      selectedScoop: _selectedScoop,
      onScoopSelected: (scoop) => setState(() => _selectedScoop = scoop),
      onNext: _canContinue['scoop']! ? _nextStep : null,
    );
  }

  Widget _buildPeriodeSection() {
    return SectionPeriode(
      selectedPeriode: _selectedPeriode,
      onPeriodeSelected: (periode) =>
          setState(() => _selectedPeriode = periode),
      onNext: _canContinue['periode']! ? _nextStep : null,
      onPrevious: _previousStep,
    );
  }

  Widget _buildContenantsSection() {
    return SectionContenants(
      contenants: _contenants,
      onContenantsChanged: (contenants) =>
          setState(() => _contenants = contenants),
      totals: _totals,
      onNext: _canContinue['contenants']! ? _nextStep : null,
      onPrevious: _previousStep,
    );
  }

  Widget _buildObservationsSection() {
    return SectionObservations(
      observations: _observations,
      onObservationsChanged: (obs) => setState(() => _observations = obs),
      onNext: _nextStep,
      onPrevious: _previousStep,
    );
  }

  Widget _buildGeolocationSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Géolocalisation',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Obtenez votre position GPS actuelle',
                      style: TextStyle(color: Colors.grey.shade600),
                      softWrap: true,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Bouton de géolocalisation
          Center(
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade400,
                    Colors.green.shade400,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _getCurrentLocation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _geolocationData == null
                              ? Icons.my_location
                              : Icons.location_on,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _geolocationData == null
                            ? 'Obtenir ma position'
                            : 'Position obtenue ✓',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _geolocationData == null
                            ? 'Cliquez pour récupérer votre localisation GPS'
                            : 'Cliquez pour mettre à jour',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
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
            const SizedBox(height: 32),

            // Affichage des données de géolocalisation
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
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
                        'Position GPS obtenue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Grille des informations GPS
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                    children: [
                      _buildLocationCard(
                        'Latitude',
                        _geolocationData!['latitude'].toStringAsFixed(6),
                        Icons.north,
                        Colors.blue.shade600,
                        Colors.blue.shade50,
                      ),
                      _buildLocationCard(
                        'Longitude',
                        _geolocationData!['longitude'].toStringAsFixed(6),
                        Icons.east,
                        Colors.orange.shade600,
                        Colors.orange.shade50,
                      ),
                      _buildLocationCard(
                        'Précision',
                        '${_geolocationData!['accuracy'].toStringAsFixed(1)} m',
                        Icons.center_focus_strong,
                        Colors.purple.shade600,
                        Colors.purple.shade50,
                      ),
                      _buildLocationCard(
                        'Horodatage',
                        _formatTimestamp(_geolocationData!['timestamp']),
                        Icons.access_time,
                        Colors.green.shade600,
                        Colors.green.shade50,
                      ),
                    ],
                  ),

                  if (_geolocationData!['address'] != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.location_city, color: Colors.red.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Adresse détectée',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        _geolocationData!['address'],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Boutons de navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _previousStep,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _nextStep,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Suivant'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(String title, String value, IconData icon,
      Color iconColor, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
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
    return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} à ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }

  Future<void> _getCurrentLocation() async {
    // Utilisation de CleanGeolocation pour éviter les erreurs UTF-8
    final position = await CleanGeolocation.getCurrentLocationClean();

    if (position != null) {
      setState(() {
        _geolocationData = {
          'latitude': position['latitude'],
          'longitude': position['longitude'],
          'accuracy': position['accuracy'],
          'timestamp': position['timestamp'],
          'address':
              'Lat: ${position['latitude'].toStringAsFixed(6)}, Lng: ${position['longitude'].toStringAsFixed(6)}',
        };
      });

      Get.snackbar(
        'Position obtenue !',
        'Géolocalisation réussie avec une précision de ${position['accuracy'].toStringAsFixed(1)} m',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        icon: const Icon(Icons.check_circle, color: Colors.green),
      );
    } else {
      Get.snackbar(
        'Erreur de géolocalisation',
        'Impossible d\'obtenir votre position',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    }
  }

  Widget _buildResumeSection() {
    return SectionResume(
      scoop: _selectedScoop,
      periode: _selectedPeriode,
      contenants: _contenants,
      observations: _observations,
      totals: _totals,
      isLoading: _isLoading,
      onSave: _saveCollecte,
      onPrevious: _previousStep,
    );
  }

  /// Génère les IDs universels pour les contenants Scoop
  Future<List<ContenantScoopModel>> _genererIdsUniversels(
    List<ContenantScoopModel> contenants,
  ) async {
    try {
      final universalService = UniversalContainerIdService();

      // Récupérer les informations nécessaires pour les Scoop
      final scoopNom = _selectedScoop?.nom ?? 'SCOOP_INCONNU';
      final technicien = _userSession.nom ?? 'TECHNICIEN_INCONNU';
      final village = _selectedScoop?.village ?? 'VILLAGE_INCONNU';

      // Pour les Scoop, on utilise le nom du Scoop comme "producteur"
      final producteur = scoopNom;

      // Date de la collecte (date actuelle)
      final dateCollecte = DateTime.now();

      // Générer les IDs universels
      final containerIds = await universalService.generateCollecteContainerIds(
        type: CollecteType.scoop,
        village: village,
        technicien: technicien,
        producteur: producteur,
        dateCollecte: dateCollecte,
        nombreContenants: contenants.length,
      );

      // Créer la liste des contenants avec les nouveaux IDs
      final List<ContenantScoopModel> contenantsAvecIds = [];

      for (int i = 0; i < contenants.length; i++) {
        final contenant = contenants[i];
        final nouvelId = containerIds[i];

        // Créer un nouveau contenant avec l'ID universel
        final nouveauContenant = contenant.copyWith(id: nouvelId);
        contenantsAvecIds.add(nouveauContenant);
      }

      print(
          '✅ SCOOP: IDs universels générés pour ${contenants.length} contenants');
      print('   🏢 Scoop: $scoopNom');
      print('   📍 Village: $village');
      print('   👨‍💼 Technicien: $technicien');
      print(
          '   📅 Date: ${dateCollecte.day}/${dateCollecte.month}/${dateCollecte.year}');

      for (final id in containerIds) {
        print('   📦 $id');
      }

      return contenantsAvecIds;
    } catch (e) {
      print('❌ SCOOP: Erreur génération IDs universels: $e');

      // Fallback vers l'ancien système en cas d'erreur
      final List<ContenantScoopModel> contenantsFallback = [];

      for (int i = 0; i < contenants.length; i++) {
        final contenant = contenants[i];
        final fallbackId =
            'C${(i + 1).toString().padLeft(4, '0')}_scoop_fallback_${DateTime.now().millisecondsSinceEpoch}';

        final nouveauContenant = contenant.copyWith(id: fallbackId);
        contenantsFallback.add(nouveauContenant);
      }

      return contenantsFallback;
    }
  }
}
