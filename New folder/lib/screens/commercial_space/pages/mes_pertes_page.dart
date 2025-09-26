import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../utils/smart_appbar.dart';
import '../../../authentication/user_session.dart';
import '../../vente/services/vente_service.dart';
import '../../vente/models/vente_models.dart';
import '../widgets/perte_form_moderne.dart';

/// ⚠️ PAGE MES PERTES
/// Interface moderne pour déclarer et gérer les pertes de produits
class MesPertesPage extends StatefulWidget {
  const MesPertesPage({super.key});

  @override
  State<MesPertesPage> createState() => _MesPertesPageState();
}

class _MesPertesPageState extends State<MesPertesPage>
    with TickerProviderStateMixin {
  final VenteService _service = VenteService();
  final UserSession _userSession = Get.find<UserSession>();

  late AnimationController _fadeController;
  late AnimationController _shakeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;

  List<Prelevement> _prelevements = [];
  List<dynamic> _pertes = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Statistiques
  Map<String, dynamic> _stats = {
    'pertes_total': 0,
    'valeur_perdue': 0.0,
    'produits_perdus': 0,
    'taux_perte': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutQuart),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _shakeController.forward();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final commercialId = _userSession.email ?? 'Commercial_Inconnu';
      final prelevements =
          await _service.getPrelevementsCommercial(commercialId);

      // Simulation de pertes
      final pertesSimulees = _simulerPertes();

      setState(() {
        _prelevements = prelevements;
        _pertes = pertesSimulees;
        _calculerStatistiques();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar(
        'Erreur',
        'Impossible de charger les déclarations de pertes: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  List<dynamic> _simulerPertes() {
    return List.generate(5, (index) {
      return {
        'id': 'PRT_${DateTime.now().millisecondsSinceEpoch}_$index',
        'date': DateTime.now().subtract(Duration(days: index * 5)),
        'prelevement_id': 'PRE_${index + 1}',
        'cause': [
          'Casse accidentelle',
          'Vol/disparition',
          'Détérioration transport',
          'Péremption',
          'Défaut de stockage',
        ][index % 5],
        'produits': [
          {
            'type': '500g',
            'quantite': 1 + (index % 2),
            'valeur': (1 + (index % 2)) * 3000.0
          },
          if (index % 3 == 0) {'type': '1kg', 'quantite': 1, 'valeur': 5500.0},
        ],
        'valeur_totale':
            (1 + (index % 2)) * 3000.0 + (index % 3 == 0 ? 5500.0 : 0.0),
        'statut': index % 3 == 0 ? 'en_cours_validation' : 'validee',
        'photo_evidence': index % 4 == 0,
        'observations': 'Incident survenu lors du ${[
          'transport',
          'stockage',
          'manutention',
          'exposition'
        ][index % 4]}',
      };
    });
  }

  void _calculerStatistiques() {
    final valeurPerdue =
        _pertes.fold<double>(0.0, (sum, p) => sum + p['valeur_totale']);
    final produitsPerdus = _pertes.fold<int>(0, (sum, p) {
      return sum +
          (p['produits'] as List)
              .fold<int>(0, (pSum, prod) => pSum + (prod['quantite'] as int));
    });

    setState(() {
      _stats = {
        'pertes_total': _pertes.length,
        'valeur_perdue': valeurPerdue,
        'produits_perdus': produitsPerdus,
        'taux_perte': _prelevements.isNotEmpty
            ? (_pertes.length / _prelevements.length * 100)
            : 0.0,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF2F2),
      appBar: SmartAppBar(
        title: "⚠️ Mes Pertes",
        backgroundColor: const Color(0xFFEF4444),
        onBackPressed: () => Get.back(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingView()
          : AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: _buildContent(),
                );
              },
            ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chargement des déclarations...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isExtraSmall = constraints.maxWidth < 480;
        final isSmall = constraints.maxWidth < 768;

        return Column(
          children: [
            // Header avec statistiques
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    _shakeAnimation.value > 0.5
                        ? 2 * (_shakeAnimation.value - 0.5)
                        : 0,
                    0,
                  ),
                  child: _buildStatsHeader(isExtraSmall, isSmall),
                );
              },
            ),

            // Barre de recherche
            Container(
              margin: EdgeInsets.all(isExtraSmall ? 16 : 20),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Rechercher une déclaration...',
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFFEF4444)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),

            // Liste des pertes
            Expanded(
              child: _pertes.isEmpty
                  ? _buildEmptyState()
                  : _buildPertesList(isExtraSmall),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsHeader(bool isExtraSmall, bool isSmall) {
    return Container(
      margin: EdgeInsets.all(isExtraSmall ? 16 : 20),
      padding: EdgeInsets.all(isExtraSmall ? 20 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header principal
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isExtraSmall ? 16 : 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '⚠️',
                  style: TextStyle(fontSize: isExtraSmall ? 32 : 40),
                ),
              ),
              SizedBox(width: isExtraSmall ? 16 : 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mes Déclarations de Pertes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isExtraSmall ? 18 : 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isExtraSmall ? 4 : 8),
                    Text(
                      '${_stats['pertes_total']} déclaration${_stats['pertes_total'] > 1 ? 's' : ''} enregistrée${_stats['pertes_total'] > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isExtraSmall ? 14 : 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: isExtraSmall ? 20 : 24),

          // Statistiques d'alerte
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Impact des Pertes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (isExtraSmall)
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: _buildStatCard(
                                  'Total',
                                  '${_stats['pertes_total']}',
                                  Icons.report_problem,
                                  true)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _buildStatCard(
                                  'Valeur',
                                  '${(_stats['valeur_perdue'] / 1000).toStringAsFixed(1)}K',
                                  Icons.monetization_on,
                                  true)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: _buildStatCard(
                                  'Produits',
                                  '${_stats['produits_perdus']}',
                                  Icons.inventory_2,
                                  true)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _buildStatCard(
                                  'Taux',
                                  '${_stats['taux_perte'].toStringAsFixed(1)}%',
                                  Icons.trending_down,
                                  true)),
                        ],
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                          child: _buildStatCard(
                              'Total Pertes',
                              '${_stats['pertes_total']}',
                              Icons.report_problem,
                              false)),
                      SizedBox(width: isSmall ? 12 : 16),
                      Expanded(
                          child: _buildStatCard(
                              'Valeur Perdue',
                              '${(_stats['valeur_perdue'] / 1000).toStringAsFixed(1)}K FCFA',
                              Icons.monetization_on,
                              false)),
                      SizedBox(width: isSmall ? 12 : 16),
                      Expanded(
                          child: _buildStatCard(
                              'Produits Perdus',
                              '${_stats['produits_perdus']}',
                              Icons.inventory_2,
                              false)),
                      SizedBox(width: isSmall ? 12 : 16),
                      Expanded(
                          child: _buildStatCard(
                              'Taux de Perte',
                              '${_stats['taux_perte'].toStringAsFixed(1)}%',
                              Icons.trending_down,
                              false)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: isCompact ? 16 : 20),
          SizedBox(height: isCompact ? 4 : 6),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isCompact ? 14 : 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: isCompact ? 9 : 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPertesList(bool isExtraSmall) {
    final pertesFiltrees = _pertes.where((perte) {
      if (_searchQuery.isEmpty) return true;
      return perte['cause']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          perte['id']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();

    return ListView.builder(
      padding: EdgeInsets.all(isExtraSmall ? 16 : 20),
      itemCount: pertesFiltrees.length,
      itemBuilder: (context, index) {
        final perte = pertesFiltrees[index];
        return _buildPerteCard(perte, isExtraSmall);
      },
    );
  }

  Widget _buildPerteCard(dynamic perte, bool isExtraSmall) {
    final enCours = perte['statut'] == 'en_cours_validation';
    final statusColor =
        enCours ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
    final hasPhoto = perte['photo_evidence'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Header avec alerte
          Container(
            padding: EdgeInsets.all(isExtraSmall ? 16 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.15),
                  statusColor.withOpacity(0.08),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.report_problem,
                    color: statusColor,
                    size: isExtraSmall ? 24 : 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Perte ${perte['id'].split('_').last}',
                              style: TextStyle(
                                fontSize: isExtraSmall ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              enCours ? 'En validation' : 'Validée',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd/MM/yyyy à HH:mm')
                                .format(perte['date']),
                            style: TextStyle(
                              fontSize: isExtraSmall ? 12 : 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (hasPhoto) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.camera_alt,
                                size: 16, color: Colors.green.shade600),
                            const SizedBox(width: 4),
                            Text(
                              'Photo jointe',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contenu
          Padding(
            padding: EdgeInsets.all(isExtraSmall ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cause de la perte
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red.shade700, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cause de la perte',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              perte['cause'],
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Produits perdus
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.remove_shopping_cart,
                              color: Colors.grey.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Produits perdus',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...(perte['produits'] as List)
                          .map((produit) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade400,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${produit['type']} × ${produit['quantite']}',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    Text(
                                      VenteUtils.formatPrix(produit['valeur']),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Valeur perdue (mise en évidence)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade100, Colors.red.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade300, width: 2),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.monetization_on_outlined,
                          color: Colors.red.shade700, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        'Valeur Totale Perdue',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        VenteUtils.formatPrix(perte['valeur_totale']),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                ),

                // Observations
                if (perte['observations'] != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.note_alt,
                                color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Détails de l\'incident',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          perte['observations'],
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade100,
                  Colors.green.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.check_circle,
              size: 60,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune perte déclarée',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Excellent ! Vous n\'avez aucune perte à déclarer',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showNouvellePerte,
      backgroundColor: const Color(0xFFEF4444),
      icon: const Icon(Icons.add),
      label: const Text('Déclarer une Perte'),
      elevation: 8,
    );
  }

  void _showNouvellePerte() {
    Get.dialog(
      PerteFormModerne(
        prelevements: _prelevements
            .where((p) => p.statut == StatutPrelevement.enCours)
            .toList(),
        onPerteEnregistree: () {
          _loadData();
          Get.back();
        },
      ),
      barrierDismissible: false,
    );
  }
}
