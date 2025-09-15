/// 🛒 PAGE DE VENTE POUR LES COMMERCIAUX
///
/// Interface pour les commerciaux : ventes, restitutions, pertes

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../utils/smart_appbar.dart';
import '../../../authentication/user_session.dart';
import '../services/vente_service.dart';
import '../models/vente_models.dart';
import 'vente_form_modal_complete.dart';
import 'restitution_form_modal.dart';
import 'perte_form_modal.dart';

class VenteCommercialPage extends StatefulWidget {
  const VenteCommercialPage({super.key});

  @override
  State<VenteCommercialPage> createState() => _VenteCommercialPageState();
}

class _VenteCommercialPageState extends State<VenteCommercialPage>
    with TickerProviderStateMixin {
  final VenteService _service = VenteService();
  final UserSession _userSession = Get.find<UserSession>();

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Données
  List<Prelevement> _prelevements = [];
  bool _isLoading = true;

  // Onglets
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _fadeController.forward();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final commercialId = _userSession.email ?? 'Commercial_Inconnu';
      final prelevements =
          await _service.getPrelevementsCommercial(commercialId);

      setState(() {
        _prelevements = prelevements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar(
        'Erreur',
        'Impossible de charger vos prélèvements: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final commercialNom = _userSession.email?.split('@')[0] ?? 'Commercial';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: SmartAppBar(
        title: "🛒 Espace Commercial - $commercialNom",
        backgroundColor: const Color(0xFF9C27B0),
        onBackPressed: () => Get.back(),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: isMobile,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_bag), text: 'Mes Prélèvements'),
            Tab(icon: Icon(Icons.point_of_sale), text: 'Vendre'),
            Tab(icon: Icon(Icons.undo), text: 'Restituer'),
            Tab(icon: Icon(Icons.warning), text: 'Déclarer Perte'),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoadingView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPrelevementsTab(isMobile),
                _buildVenteTab(isMobile),
                _buildRestitutionTab(isMobile),
                _buildPerteTab(isMobile),
              ],
            ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 6,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9C27B0)),
          ),
          const SizedBox(height: 24),
          Text(
            'Chargement de vos données...',
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

  Widget _buildPrelevementsTab(bool isMobile) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Column(
            children: [
              _buildPrelevementsHeader(isMobile),
              Expanded(
                child: _buildPrelevementsList(isMobile),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrelevementsHeader(bool isMobile) {
    final prelevementsEnCours = _prelevements
        .where((p) => p.statut == StatutPrelevement.enCours)
        .length;
    final valeurTotale =
        _prelevements.fold(0.0, (sum, p) => sum + p.valeurTotale);
    final produitsTotal =
        _prelevements.fold(0, (sum, p) => sum + p.produits.length);

    return Container(
      margin: EdgeInsets.all(isMobile ? 16 : 24),
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('📋', style: TextStyle(fontSize: 32)),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mes Prélèvements',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Produits attribués pour la vente',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'En cours',
                  prelevementsEnCours.toString(),
                  Icons.shopping_cart,
                  isMobile,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: _buildStatCard(
                  'Valeur totale',
                  VenteUtils.formatPrix(valeurTotale),
                  Icons.attach_money,
                  isMobile,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: _buildStatCard(
                  'Produits',
                  produitsTotal.toString(),
                  Icons.inventory_2,
                  isMobile,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: isMobile ? 20 : 24),
          SizedBox(height: isMobile ? 4 : 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 12 : 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isMobile ? 8 : 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPrelevementsList(bool isMobile) {
    if (_prelevements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucun prélèvement',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Contactez votre gestionnaire pour obtenir des produits',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      itemCount: _prelevements.length,
      itemBuilder: (context, index) {
        final prelevement = _prelevements[index];
        return _buildPrelevementCard(prelevement, isMobile);
      },
    );
  }

  Widget _buildPrelevementCard(Prelevement prelevement, bool isMobile) {
    final statusColor = _getStatusColor(prelevement.statut);
    final statusLabel = _getStatusLabel(prelevement.statut);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.1),
                  statusColor.withOpacity(0.05)
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
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shopping_bag,
                    color: statusColor,
                    size: isMobile ? 20 : 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prélèvement ${prelevement.id.split('_').last}',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy à HH:mm')
                            .format(prelevement.datePrelevement),
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenu
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              children: [
                // Statistiques
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoColumn(
                        'Produits',
                        '${prelevement.produits.length}',
                        Icons.inventory_2,
                        Colors.blue,
                        isMobile,
                      ),
                    ),
                    Container(
                        width: 1, height: 40, color: Colors.grey.shade300),
                    Expanded(
                      child: _buildInfoColumn(
                        'Valeur',
                        VenteUtils.formatPrix(prelevement.valeurTotale),
                        Icons.attach_money,
                        Colors.green,
                        isMobile,
                      ),
                    ),
                    Container(
                        width: 1, height: 40, color: Colors.grey.shade300),
                    Expanded(
                      child: _buildInfoColumn(
                        'Gestionnaire',
                        prelevement.magazinierNom,
                        Icons.person,
                        Colors.orange,
                        isMobile,
                      ),
                    ),
                  ],
                ),

                if (prelevement.observations != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      '💬 ${prelevement.observations!}',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 14,
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Actions
                if (prelevement.statut == StatutPrelevement.enCours)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showVenteModal(prelevement),
                          icon: const Icon(Icons.point_of_sale),
                          label: const Text('Vendre'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 10 : 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showRestitutionModal(prelevement),
                          icon: const Icon(Icons.undo),
                          label: const Text('Restituer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 10 : 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showPerteModal(prelevement),
                          icon: const Icon(Icons.warning),
                          label: const Text('Perte'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 10 : 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(
      String label, String value, IconData icon, Color color, bool isMobile) {
    return Column(
      children: [
        Icon(icon, color: color, size: isMobile ? 16 : 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 10 : 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildVenteTab(bool isMobile) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.point_of_sale, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Effectuer une Vente',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sélectionnez un prélèvement dans l\'onglet précédent',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRestitutionTab(bool isMobile) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.undo, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Restituer des Produits',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sélectionnez un prélèvement dans l\'onglet précédent',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerteTab(bool isMobile) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Déclarer une Perte',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sélectionnez un prélèvement dans l\'onglet précédent',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(StatutPrelevement statut) {
    switch (statut) {
      case StatutPrelevement.enCours:
        return Colors.blue;
      case StatutPrelevement.partiel:
        return Colors.orange;
      case StatutPrelevement.termine:
        return Colors.green;
      case StatutPrelevement.annule:
        return Colors.red;
    }
  }

  String _getStatusLabel(StatutPrelevement statut) {
    switch (statut) {
      case StatutPrelevement.enCours:
        return 'En cours';
      case StatutPrelevement.partiel:
        return 'Partiel';
      case StatutPrelevement.termine:
        return 'Terminé';
      case StatutPrelevement.annule:
        return 'Annulé';
    }
  }

  void _showVenteModal(Prelevement prelevement) {
    Get.dialog(
      VenteFormModalComplete(
        prelevement: prelevement,
        onVenteEnregistree: () {
          _loadData(); // Recharger les données
          _tabController.animateTo(0); // Retourner à l'onglet prélèvements
        },
      ),
      barrierDismissible: false,
    );
  }

  void _showRestitutionModal(Prelevement prelevement) {
    Get.dialog(
      RestitutionFormModal(
        prelevement: prelevement,
        onRestitutionEnregistree: () {
          _loadData(); // Recharger les données
          _tabController.animateTo(0); // Retourner à l'onglet prélèvements
        },
      ),
      barrierDismissible: false,
    );
  }

  void _showPerteModal(Prelevement prelevement) {
    Get.dialog(
      PerteFormModal(
        prelevement: prelevement,
        onPerteEnregistree: () {
          _loadData(); // Recharger les données
          _tabController.animateTo(0); // Retourner à l'onglet prélèvements
        },
      ),
      barrierDismissible: false,
    );
  }
}
