/// 🛒 PAGE PRINCIPALE DE GESTION DES VENTES - ADMIN/MAGAZINIER
///
/// Interface pour les gestionnaires de vente, magaziniers et admins
/// Gestion des produits conditionnés, prélèvements et statistiques

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../utils/smart_appbar.dart';
import '../../../authentication/user_session.dart';
import '../services/vente_service.dart';
import '../models/vente_models.dart';
import 'prelevement_modal.dart';

class VenteAdminPage extends StatefulWidget {
  const VenteAdminPage({super.key});

  @override
  State<VenteAdminPage> createState() => _VenteAdminPageState();
}

class _VenteAdminPageState extends State<VenteAdminPage>
    with TickerProviderStateMixin {
  final VenteService _service = VenteService();
  final UserSession _userSession = Get.find<UserSession>();

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Données
  List<ProduitConditionne> _produits = [];
  Map<String, dynamic> _statistiques = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedLot;
  String? _selectedFlorale;

  // Onglets
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _tabController = TabController(length: 3, vsync: this);
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
      final produits = await _service.getProduitsConditionnes();
      final stats = await _service.getStatistiquesVente();

      setState(() {
        _produits = produits;
        _statistiques = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar(
        'Erreur',
        'Impossible de charger les données: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final userRole = _userSession.role ?? '';
    final canManage =
        ['Admin', 'Magazinier', 'Gestionnaire Commercial'].contains(userRole);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: SmartAppBar(
        title: "🛒 Gestion des Ventes",
        backgroundColor: const Color(0xFF1976D2),
        onBackPressed: () => Get.back(),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2), text: 'Produits'),
            Tab(icon: Icon(Icons.shopping_cart), text: 'Prélèvements'),
            Tab(icon: Icon(Icons.analytics), text: 'Statistiques'),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoadingView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProduitsTab(isMobile, canManage),
                _buildPrelevementsTab(isMobile, canManage),
                _buildStatistiquesTab(isMobile),
              ],
            ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showPrelevementModal(),
              backgroundColor: const Color(0xFF1976D2),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Nouveau Prélèvement'),
            )
          : null,
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
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
          ),
          const SizedBox(height: 24),
          Text(
            'Chargement des données de vente...',
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

  Widget _buildProduitsTab(bool isMobile, bool canManage) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Column(
            children: [
              // Header avec statistiques
              _buildProduitsHeader(isMobile),

              // Filtres
              _buildProduitsFilters(isMobile),

              // Liste des produits
              Expanded(
                child: _buildProduitsGrid(isMobile, canManage),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProduitsHeader(bool isMobile) {
    final produitsDisponibles =
        _produits.where((p) => p.statut == StatutProduit.disponible).length;
    final valeurStock = _produits
        .where((p) => p.statut == StatutProduit.disponible)
        .fold(0.0, (sum, p) => sum + p.valeurTotale);
    final lotsUniques = _produits.map((p) => p.numeroLot).toSet().length;

    return Container(
      margin: EdgeInsets.all(isMobile ? 16 : 24),
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withOpacity(0.3),
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
                child: const Text('🛒', style: TextStyle(fontSize: 32)),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock Produits Conditionnés',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gestion des ventes et prélèvements',
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
                  'Produits',
                  produitsDisponibles.toString(),
                  Icons.inventory_2,
                  isMobile,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: _buildStatCard(
                  'Valeur Stock',
                  VenteUtils.formatPrix(valeurStock),
                  Icons.attach_money,
                  isMobile,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: _buildStatCard(
                  'Lots Uniques',
                  lotsUniques.toString(),
                  Icons.label,
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

  Widget _buildProduitsFilters(bool isMobile) {
    final lotsUniques = _produits.map((p) => p.numeroLot).toSet().toList()
      ..sort();
    final floralesUniques =
        _produits.map((p) => p.predominanceFlorale).toSet().toList()..sort();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Rechercher par lot, producteur, village...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _selectedLot,
                  decoration: InputDecoration(
                    labelText: 'Filtrer par lot',
                    prefixIcon: const Icon(Icons.label),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Tous les lots'),
                    ),
                    ...lotsUniques.map((lot) => DropdownMenuItem<String?>(
                          value: lot,
                          child: Text(lot),
                        )),
                  ],
                  onChanged: (value) => setState(() => _selectedLot = value),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _selectedFlorale,
                  decoration: InputDecoration(
                    labelText: 'Filtrer par florale',
                    prefixIcon: const Icon(Icons.local_florist),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Toutes les florales'),
                    ),
                    ...floralesUniques
                        .map((florale) => DropdownMenuItem<String?>(
                              value: florale,
                              child: Text(florale),
                            )),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedFlorale = value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProduitsGrid(bool isMobile, bool canManage) {
    var produitsAffiches = _produits.where((p) {
      final matchSearch = _searchQuery.isEmpty ||
          p.numeroLot.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.producteur.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.village.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchLot = _selectedLot == null || p.numeroLot == _selectedLot;
      final matchFlorale =
          _selectedFlorale == null || p.predominanceFlorale == _selectedFlorale;

      return matchSearch && matchLot && matchFlorale;
    }).toList();

    if (produitsAffiches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucun produit trouvé',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isMobile ? 1.2 : 1.0,
      ),
      itemCount: produitsAffiches.length,
      itemBuilder: (context, index) {
        final produit = produitsAffiches[index];
        return _buildProduitCard(produit, isMobile, canManage);
      },
    );
  }

  Widget _buildProduitCard(
      ProduitConditionne produit, bool isMobile, bool canManage) {
    final isDisponible = produit.statut == StatutProduit.disponible;
    final statusColor = VenteUtils.getColorForStatut(produit.statut);
    final emoji = VenteUtils.getEmojiiForTypeEmballage(produit.typeEmballage);

    return Container(
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
                  child: Text(emoji,
                      style: TextStyle(fontSize: isMobile ? 20 : 24)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        produit.numeroLot,
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${produit.typeEmballage} - ${produit.contenanceKg}kg',
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
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    VenteUtils.getLibelleStatut(produit.statut),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenu
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Producteur',
                          produit.producteur,
                          Icons.person,
                          isMobile,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoItem(
                          'Village',
                          produit.village,
                          Icons.location_on,
                          isMobile,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Florale',
                          produit.predominanceFlorale,
                          Icons.local_florist,
                          isMobile,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoItem(
                          'Date',
                          DateFormat('dd/MM/yyyy')
                              .format(produit.dateConditionnement),
                          Icons.calendar_today,
                          isMobile,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${produit.quantiteDisponible}',
                                style: TextStyle(
                                  fontSize: isMobile ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDisponible ? Colors.green : Colors.grey,
                                ),
                              ),
                              Text(
                                'Disponible',
                                style: TextStyle(
                                  fontSize: isMobile ? 10 : 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                            width: 1, height: 30, color: Colors.grey.shade300),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                VenteUtils.formatPrix(produit.prixUnitaire),
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              Text(
                                'Prix unitaire',
                                style: TextStyle(
                                  fontSize: isMobile ? 10 : 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                            width: 1, height: 30, color: Colors.grey.shade300),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                VenteUtils.formatPrix(produit.valeurTotale),
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                              Text(
                                'Valeur totale',
                                style: TextStyle(
                                  fontSize: isMobile ? 10 : 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (canManage && isDisponible)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showPrelevementModal(
                            produitPreselectionne: produit),
                        icon: const Icon(Icons.shopping_cart_outlined),
                        label: const Text('Prélever'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 12 : 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
      String label, String value, IconData icon, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: isMobile ? 14 : 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 10 : 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPrelevementsTab(bool isMobile, bool canManage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Prélèvements',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cette section sera développée prochainement',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistiquesTab(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        children: [
          _buildStatistiquesHeader(isMobile),
          const SizedBox(height: 24),
          _buildStatistiquesDetails(isMobile),
        ],
      ),
    );
  }

  Widget _buildStatistiquesHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Statistiques Globales',
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'CA Total',
                  VenteUtils.formatPrix(
                      _statistiques['chiffredAffaire'] ?? 0.0),
                  Icons.attach_money,
                  isMobile,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: _buildStatCard(
                  'Ventes',
                  (_statistiques['totalVentes'] ?? 0).toString(),
                  Icons.shopping_bag,
                  isMobile,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: _buildStatCard(
                  'Prélèvements',
                  (_statistiques['totalPrelevements'] ?? 0).toString(),
                  Icons.shopping_cart,
                  isMobile,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatistiquesDetails(bool isMobile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détails par catégorie',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow(
                'Stock disponible',
                VenteUtils.formatPrix(_statistiques['valeurStock'] ?? 0.0),
                Icons.inventory_2,
                Colors.blue,
                isMobile),
            _buildStatRow(
                'Valeur prélevements',
                VenteUtils.formatPrix(
                    _statistiques['valeurPrelevements'] ?? 0.0),
                Icons.shopping_cart,
                Colors.orange,
                isMobile),
            _buildStatRow(
                'Restitutions',
                VenteUtils.formatPrix(
                    _statistiques['valeurRestitutions'] ?? 0.0),
                Icons.undo,
                Colors.green,
                isMobile),
            _buildStatRow(
                'Pertes déclarées',
                VenteUtils.formatPrix(_statistiques['valeurPertes'] ?? 0.0),
                Icons.warning,
                Colors.red,
                isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
      String label, String value, IconData icon, Color color, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: isMobile ? 16 : 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showPrelevementModal({ProduitConditionne? produitPreselectionne}) {
    Get.dialog(
      PrelevementModal(
        produits: _produits
            .where((p) => p.statut == StatutProduit.disponible)
            .toList(),
        produitPreselectionne: produitPreselectionne,
        onPrelevementCree: () {
          _loadData(); // Recharger les données
        },
      ),
      barrierDismissible: false,
    );
  }
}
