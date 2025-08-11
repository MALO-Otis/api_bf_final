import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/scoop_models.dart';
import '../../../data/services/stats_scoop_contenants_service.dart';
import '../../../authentication/user_session.dart';
import '../historiques_collectes.dart';
import 'widgets/section_scoop.dart';
import 'widgets/section_periode.dart';
import 'widgets/section_contenants.dart';
import 'widgets/section_observations.dart';
import 'widgets/section_resume.dart';

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
    'SCOOP',
    'Période',
    'Contenants',
    'Observations',
    'Résumé'
  ];

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
      case 0: // SCOOP
        return true;
      case 1: // Période
        return _selectedScoop != null;
      case 2: // Contenants
        return _selectedScoop != null && _selectedPeriode.isNotEmpty;
      case 3: // Observations
        return _selectedScoop != null &&
            _selectedPeriode.isNotEmpty &&
            _contenants.isNotEmpty;
      case 4: // Résumé
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
      case 1:
        message = 'Veuillez d\'abord sélectionner un SCOOP';
        break;
      case 2:
        message = 'Veuillez d\'abord sélectionner un SCOOP et une période';
        break;
      case 3:
      case 4:
        message = 'Veuillez d\'abord compléter toutes les étapes précédentes';
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
      final collecte = CollecteScoopModel(
        id: '', // Sera généré par Firestore
        dateAchat: DateTime.now(),
        periodeCollecte: _selectedPeriode,
        scoopId: _selectedScoop!.id,
        scoopNom: _selectedScoop!.nom,
        contenants: _contenants,
        poidsTotal: _totals['poids']!,
        montantTotal: _totals['montant']!,
        observations: _observations,
        collecteurId: _userSession.uid ?? '',
        collecteurNom: _userSession.nom ?? '',
        site: _userSession.site ?? '',
        createdAt: DateTime.now(),
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
}
