import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../utils/smart_appbar.dart';
import '../../../authentication/user_session.dart';
import '../../vente/services/vente_service.dart';
import '../../vente/models/vente_models.dart';
import '../widgets/restitution_form_moderne.dart';

/// 🔄 PAGE MES RESTITUTIONS
/// Interface moderne pour gérer les restitutions de produits
class MesRestitutionsPage extends StatefulWidget {
  const MesRestitutionsPage({super.key});

  @override
  State<MesRestitutionsPage> createState() => _MesRestitutionsPageState();
}

class _MesRestitutionsPageState extends State<MesRestitutionsPage>
    with TickerProviderStateMixin {
  final VenteService _service = VenteService();
  final UserSession _userSession = Get.find<UserSession>();

  late AnimationController _fadeController;
  late AnimationController _bounceController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;

  List<Prelevement> _prelevements = [];
  List<dynamic> _restitutions = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Statistiques
  Map<String, dynamic> _stats = {
    'restitutions_total': 0,
    'valeur_restituee': 0.0,
    'produits_restitues': 0,
    'taux_restitution': 0.0,
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
    _bounceController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutQuart),
    );
    _bounceAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _bounceController.forward();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final commercialId = _userSession.email ?? 'Commercial_Inconnu';
      final prelevements =
          await _service.getPrelevementsCommercial(commercialId);

      // Simulation de restitutions
      final restitutionsSimulees = _simulerRestitutions();

      setState(() {
        _prelevements = prelevements;
        _restitutions = restitutionsSimulees;
        _calculerStatistiques();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar(
        'Erreur',
        'Impossible de charger les restitutions: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  List<dynamic> _simulerRestitutions() {
    return List.generate(8, (index) {
      return {
        'id': 'RST_${DateTime.now().millisecondsSinceEpoch}_$index',
        'date': DateTime.now().subtract(Duration(days: index * 3)),
        'prelevement_id': 'PRE_${index + 1}',
        'motif': [
          'Produits non vendus',
          'Date de péremption proche',
          'Demande du client annulée',
          'Défaut de qualité',
          'Surstock',
        ][index % 5],
        'produits': [
          {
            'type': '500g',
            'quantite': 1 + (index % 3),
            'valeur': (1 + (index % 3)) * 3000.0
          },
          {'type': '1kg', 'quantite': 1, 'valeur': 5500.0},
        ],
        'valeur_totale': (1 + (index % 3)) * 3000.0 + 5500.0,
        'statut': index % 4 == 0 ? 'en_attente' : 'acceptee',
        'observations':
            index % 3 == 0 ? 'Produits en bon état, emballage intact' : null,
      };
    });
  }

  void _calculerStatistiques() {
    final restitutionsAcceptees =
        _restitutions.where((r) => r['statut'] == 'acceptee').toList();
    final valeurRestituee = restitutionsAcceptees.fold<double>(
        0.0, (sum, r) => sum + r['valeur_totale']);
    final produitsRestitues = restitutionsAcceptees.fold<int>(0, (sum, r) {
      return sum +
          (r['produits'] as List)
              .fold<int>(0, (pSum, p) => pSum + (p['quantite'] as int));
    });

    setState(() {
      _stats = {
        'restitutions_total': _restitutions.length,
        'valeur_restituee': valeurRestituee,
        'produits_restitues': produitsRestitues,
        'taux_restitution': _prelevements.isNotEmpty
            ? (_restitutions.length / _prelevements.length * 100)
            : 0.0,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF3E8),
      appBar: SmartAppBar(
        title: "🔄 Mes Restitutions",
        backgroundColor: const Color(0xFFF59E0B),
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
                colors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
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
            'Chargement des restitutions...',
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
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _bounceAnimation.value,
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
                  hintText: 'Rechercher une restitution...',
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFFF59E0B)),
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

            // Liste des restitutions
            Expanded(
              child: _restitutions.isEmpty
                  ? _buildEmptyState()
                  : _buildRestitutionsList(isExtraSmall),
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
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.3),
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
                  '🔄',
                  style: TextStyle(fontSize: isExtraSmall ? 32 : 40),
                ),
              ),
              SizedBox(width: isExtraSmall ? 16 : 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mes Restitutions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isExtraSmall ? 20 : 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isExtraSmall ? 4 : 8),
                    Text(
                      '${_stats['restitutions_total']} restitution${_stats['restitutions_total'] > 1 ? 's' : ''} enregistrée${_stats['restitutions_total'] > 1 ? 's' : ''}',
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

          // Statistiques
          if (isExtraSmall)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _buildStatCard(
                            'Total',
                            '${_stats['restitutions_total']}',
                            Icons.undo,
                            true)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildStatCard(
                            'Valeur',
                            '${(_stats['valeur_restituee'] / 1000000).toStringAsFixed(1)}M',
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
                            '${_stats['produits_restitues']}',
                            Icons.inventory_2,
                            true)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildStatCard(
                            'Taux',
                            '${_stats['taux_restitution'].toStringAsFixed(1)}%',
                            Icons.analytics,
                            true)),
                  ],
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                    child: _buildStatCard('Total Restitutions',
                        '${_stats['restitutions_total']}', Icons.undo, false)),
                SizedBox(width: isSmall ? 12 : 16),
                Expanded(
                    child: _buildStatCard(
                        'Valeur Restituée',
                        '${(_stats['valeur_restituee'] / 1000000).toStringAsFixed(1)}M FCFA',
                        Icons.monetization_on,
                        false)),
                SizedBox(width: isSmall ? 12 : 16),
                Expanded(
                    child: _buildStatCard(
                        'Produits Restitués',
                        '${_stats['produits_restitues']}',
                        Icons.inventory_2,
                        false)),
                SizedBox(width: isSmall ? 12 : 16),
                Expanded(
                    child: _buildStatCard(
                        'Taux Restitution',
                        '${_stats['taux_restitution'].toStringAsFixed(1)}%',
                        Icons.analytics,
                        false)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: isCompact ? 20 : 24),
          SizedBox(height: isCompact ? 6 : 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isCompact ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: isCompact ? 10 : 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRestitutionsList(bool isExtraSmall) {
    final restitutionsFiltrees = _restitutions.where((restitution) {
      if (_searchQuery.isEmpty) return true;
      return restitution['motif']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          restitution['id']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();

    return ListView.builder(
      padding: EdgeInsets.all(isExtraSmall ? 16 : 20),
      itemCount: restitutionsFiltrees.length,
      itemBuilder: (context, index) {
        final restitution = restitutionsFiltrees[index];
        return _buildRestitutionCard(restitution, isExtraSmall);
      },
    );
  }

  Widget _buildRestitutionCard(dynamic restitution, bool isExtraSmall) {
    final enAttente = restitution['statut'] == 'en_attente';
    final statusColor =
        enAttente ? const Color(0xFFF59E0B) : const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(isExtraSmall ? 16 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.1),
                  statusColor.withOpacity(0.05),
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
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.undo,
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
                              'Restitution ${restitution['id'].split('_').last}',
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
                              enAttente ? 'En attente' : 'Acceptée',
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
                                .format(restitution['date']),
                            style: TextStyle(
                              fontSize: isExtraSmall ? 12 : 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
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
                // Motif
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.amber.shade700, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Motif de restitution',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              restitution['motif'],
                              style: TextStyle(
                                color: Colors.amber.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Produits restitués
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Produits restitués',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...(restitution['produits'] as List)
                          .map((produit) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${produit['type']} × ${produit['quantite']}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    Text(
                                      VenteUtils.formatPrix(produit['valeur']),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
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

                // Valeur totale
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withOpacity(0.1),
                        statusColor.withOpacity(0.05)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Valeur Totale Restituée',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        VenteUtils.formatPrix(restitution['valeur_totale']),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Observations
                if (restitution['observations'] != null) ...[
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
                        Text(
                          'Observations',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          restitution['observations'],
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
                  const Color(0xFFF59E0B).withOpacity(0.1),
                  const Color(0xFFD97706).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.undo,
              size: 60,
              color: Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune restitution',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos restitutions de produits apparaîtront ici',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showNouvelleRestitution,
      backgroundColor: const Color(0xFFF59E0B),
      icon: const Icon(Icons.add),
      label: const Text('Nouvelle Restitution'),
      elevation: 8,
    );
  }

  void _showNouvelleRestitution() {
    Get.dialog(
      RestitutionFormModerne(
        prelevements: _prelevements
            .where((p) => p.statut == StatutPrelevement.enCours)
            .toList(),
        onRestitutionEnregistree: () {
          _loadData();
          Get.back();
        },
      ),
      barrierDismissible: false,
    );
  }
}
