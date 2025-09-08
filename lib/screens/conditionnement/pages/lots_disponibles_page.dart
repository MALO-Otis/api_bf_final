/// 📦 PAGE DES LOTS FILTRÉS DISPONIBLES POUR CONDITIONNEMENT
///
/// Affiche tous les lots filtrés avec leurs numéros de lot et permet de lancer le conditionnement

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../utils/smart_appbar.dart';
import '../conditionnement_edit.dart';

class LotsDisponiblesPage extends StatefulWidget {
  const LotsDisponiblesPage({super.key});

  @override
  State<LotsDisponiblesPage> createState() => _LotsDisponiblesPageState();
}

class _LotsDisponiblesPageState extends State<LotsDisponiblesPage>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Données de test pour les lots filtrés
  List<LotFiltre> _lotsDisponibles = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadLotsDisponibles();
  }

  @override
  void dispose() {
    _fadeController.dispose();
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

  Future<void> _loadLotsDisponibles() async {
    // Simulation du chargement avec des données de test
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _lotsDisponibles = _generateTestData();
      _isLoading = false;
    });
  }

  List<LotFiltre> _generateTestData() {
    final now = DateTime.now();
    return [
      LotFiltre(
        numeroLot: 'Lot-234-567',
        dateFiltrage: now.subtract(const Duration(days: 2)),
        quantiteRecue: 45.8,
        quantiteFiltree: 42.3,
        rendement: 92.4,
        technologie: 'Automatique',
        producteur: 'Coopérative SANA FAKS',
        village: 'Mabaziga',
        predominanceFlorale: 'Manguier',
        statut: StatutLot.disponible,
        observations: 'Excellent rendement, qualité premium',
      ),
      LotFiltre(
        numeroLot: 'Lot-189-432',
        dateFiltrage: now.subtract(const Duration(days: 1)),
        quantiteRecue: 67.2,
        quantiteFiltree: 61.5,
        rendement: 91.5,
        technologie: 'Manuelle',
        producteur: 'Mr Bako',
        village: 'Kankalbila',
        predominanceFlorale: 'Mille fleurs',
        statut: StatutLot.disponible,
        observations: 'Très bonne qualité, couleur dorée',
      ),
      LotFiltre(
        numeroLot: 'Lot-345-789',
        dateFiltrage: now.subtract(const Duration(hours: 18)),
        quantiteRecue: 38.9,
        quantiteFiltree: 35.1,
        rendement: 90.2,
        technologie: 'Automatique',
        producteur: 'Miellerie Mangodara',
        village: 'Mangodara',
        predominanceFlorale: 'Eucalyptus',
        statut: StatutLot.disponible,
        observations: 'Couleur claire, parfum intense',
      ),
      LotFiltre(
        numeroLot: 'Lot-567-123',
        dateFiltrage: now.subtract(const Duration(hours: 6)),
        quantiteRecue: 52.4,
        quantiteFiltree: 47.8,
        rendement: 91.2,
        technologie: 'Manuelle',
        producteur: 'SCOOP Ramongo',
        village: 'Sitelsanou',
        predominanceFlorale: 'Tamarinier',
        statut: StatutLot.disponible,
        observations: 'Qualité exceptionnelle, goût authentique',
      ),
      LotFiltre(
        numeroLot: 'Lot-890-456',
        dateFiltrage: now.subtract(const Duration(days: 3)),
        quantiteRecue: 71.3,
        quantiteFiltree: 65.9,
        rendement: 92.4,
        technologie: 'Automatique',
        producteur: 'Coopérative Bagré',
        village: 'Bagré',
        predominanceFlorale: 'Karité',
        statut: StatutLot.enConditionnement,
        observations: 'En cours de conditionnement depuis hier',
      ),
    ];
  }

  List<LotFiltre> get _filteredLots {
    if (_searchQuery.isEmpty) return _lotsDisponibles;

    return _lotsDisponibles.where((lot) {
      return lot.numeroLot.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          lot.producteur.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          lot.village.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          lot.predominanceFlorale
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: SmartAppBar(
        title: "📦 Lots Filtrés Disponibles",
        backgroundColor: const Color(0xFF2196F3),
        onBackPressed: () => Get.back(),
      ),
      body: _isLoading ? _buildLoadingView() : _buildMainContent(isMobile),
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
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
          ),
          const SizedBox(height: 24),
          Text(
            'Chargement des lots filtrés...',
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

  Widget _buildMainContent(bool isMobile) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Column(
            children: [
              // Header avec statistiques et recherche
              _buildHeaderSection(isMobile),

              // Liste des lots
              Expanded(
                child: _buildLotsList(isMobile),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(bool isMobile) {
    final lotsDisponibles =
        _filteredLots.where((lot) => lot.statut == StatutLot.disponible).length;
    final lotsEnCours = _filteredLots
        .where((lot) => lot.statut == StatutLot.enConditionnement)
        .length;
    final quantiteTotale = _filteredLots
        .where((lot) => lot.statut == StatutLot.disponible)
        .fold(0.0, (sum, lot) => sum + lot.quantiteFiltree);

    return Container(
      margin: EdgeInsets.all(isMobile ? 16 : 24),
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Statistiques
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Lots disponibles',
                  lotsDisponibles.toString(),
                  Icons.inventory_2,
                  isMobile,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: _buildStatCard(
                  'En conditionnement',
                  lotsEnCours.toString(),
                  Icons.pending_actions,
                  isMobile,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: _buildStatCard(
                  'Quantité totale',
                  '${quantiteTotale.toStringAsFixed(1)} kg',
                  Icons.scale,
                  isMobile,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Barre de recherche
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Rechercher par numéro de lot, producteur, village...',
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              hintStyle: const TextStyle(color: Colors.white70),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 20,
                vertical: isMobile ? 12 : 16,
              ),
            ),
            style: const TextStyle(color: Colors.white),
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

  Widget _buildLotsList(bool isMobile) {
    final filteredLots = _filteredLots;

    if (filteredLots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Aucun lot filtré disponible'
                  : 'Aucun lot trouvé pour "${_searchQuery}"',
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

    return ListView.builder(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      itemCount: filteredLots.length,
      itemBuilder: (context, index) {
        final lot = filteredLots[index];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 600 + (index * 100)),
          tween: Tween(begin: 0, end: 1),
          builder: (context, animationValue, child) {
            return Transform.scale(
              scale: animationValue,
              child: _buildLotCard(lot, isMobile),
            );
          },
        );
      },
    );
  }

  Widget _buildLotCard(LotFiltre lot, bool isMobile) {
    final isDisponible = lot.statut == StatutLot.disponible;
    final statusColor = isDisponible ? Colors.green : Colors.orange;
    final statusText = isDisponible ? 'Disponible' : 'En conditionnement';

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
          // Header avec numéro de lot et statut
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.1),
                  statusColor.withOpacity(0.05)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
                  child: Text(
                    '📦',
                    style: TextStyle(fontSize: isMobile ? 20 : 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lot.numeroLot,
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Filtré le ${DateFormat('dd/MM/yyyy à HH:mm').format(lot.dateFiltrage)}',
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
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
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

          // Contenu principal
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              children: [
                // Informations principales
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Producteur',
                        lot.producteur,
                        Icons.person,
                        isMobile,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        'Village',
                        lot.village,
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
                        lot.predominanceFlorale,
                        Icons.local_florist,
                        isMobile,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        'Technologie',
                        lot.technologie,
                        Icons.build,
                        isMobile,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Métriques de filtrage
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
                        child: _buildMetricItem(
                          'Reçu',
                          '${lot.quantiteRecue.toStringAsFixed(1)} kg',
                          Colors.blue,
                          isMobile,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: _buildMetricItem(
                          'Filtré',
                          '${lot.quantiteFiltree.toStringAsFixed(1)} kg',
                          Colors.green,
                          isMobile,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: _buildMetricItem(
                          'Rendement',
                          '${lot.rendement.toStringAsFixed(1)}%',
                          lot.rendement >= 90 ? Colors.green : Colors.orange,
                          isMobile,
                        ),
                      ),
                    ],
                  ),
                ),

                if (lot.observations.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
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
                            Icon(
                              Icons.notes,
                              size: 16,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Observations',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lot.observations,
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        isDisponible ? () => _startConditionnement(lot) : null,
                    icon: Icon(
                      isDisponible ? Icons.play_arrow : Icons.pending_actions,
                      size: isMobile ? 18 : 20,
                    ),
                    label: Text(
                      isDisponible
                          ? 'Démarrer le conditionnement'
                          : 'Conditionnement en cours',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDisponible ? const Color(0xFF4CAF50) : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 12 : 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: isDisponible ? 4 : 0,
                    ),
                  ),
                ),
              ],
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
            Icon(
              icon,
              size: isMobile ? 14 : 16,
              color: Colors.grey.shade600,
            ),
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

  Widget _buildMetricItem(
      String label, String value, Color color, bool isMobile) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 10 : 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  void _startConditionnement(LotFiltre lot) {
    // Convertir le modèle local vers le modèle attendu par ConditionnementEditPage
    final lotFiltrageData = {
      'id': lot.numeroLot,
      'lot': lot.numeroLot,
      'collecteId': 'COLLECTE_${DateTime.now().millisecondsSinceEpoch}',
      'quantiteFiltree': lot.quantiteFiltree,
      'quantiteRestante': lot.quantiteFiltree,
      'predominanceFlorale': lot.predominanceFlorale,
      'dateFiltrage': lot.dateFiltrage,
      'site': 'Koudougou', // Site par défaut, à adapter selon vos besoins
      'technicien': 'Test Technicien',
    };

    Get.to(
      () => ConditionnementEditPage(lotFiltrageData: lotFiltrageData),
      transition: Transition.rightToLeftWithFade,
      duration: const Duration(milliseconds: 300),
    );
  }
}

// Modèles de données pour les tests
class LotFiltre {
  final String numeroLot;
  final DateTime dateFiltrage;
  final double quantiteRecue;
  final double quantiteFiltree;
  final double rendement;
  final String technologie;
  final String producteur;
  final String village;
  final String predominanceFlorale;
  final StatutLot statut;
  final String observations;

  LotFiltre({
    required this.numeroLot,
    required this.dateFiltrage,
    required this.quantiteRecue,
    required this.quantiteFiltree,
    required this.rendement,
    required this.technologie,
    required this.producteur,
    required this.village,
    required this.predominanceFlorale,
    required this.statut,
    required this.observations,
  });
}

enum StatutLot {
  disponible,
  enConditionnement,
  conditionne,
}
