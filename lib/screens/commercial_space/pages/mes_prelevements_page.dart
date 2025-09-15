import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../utils/smart_appbar.dart';
import '../../vente/models/vente_models.dart';
import '../widgets/prelevement_stats_header.dart';
import '../../vente/models/commercial_models.dart';
import '../widgets/prelevement_detail_card_clean.dart';
import '../../vente/controllers/espace_commercial_controller.dart';

// import '../../vente/services/vente_service.dart'; // legacy fetch désactivé (données temps réel via controller)

/// 📋 PAGE MES PRÉLÈVEMENTS
/// Interface moderne pour visualiser et gérer tous les prélèvements attribués
class MesPrelevementsPage extends StatefulWidget {
  const MesPrelevementsPage({super.key});

  @override
  State<MesPrelevementsPage> createState() => _MesPrelevementsPageState();
}

class _MesPrelevementsPageState extends State<MesPrelevementsPage>
    with TickerProviderStateMixin {
  final EspaceCommercialController _commercialController =
    Get.isRegistered<EspaceCommercialController>()
      ? Get.find<EspaceCommercialController>()
      : Get.put(EspaceCommercialController(), permanent: true);

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = true; // only until first controller load
  String _searchQuery = '';
  StatutPrelevement? _filtreStatut;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutQuart),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    // Charger toutes les données (incluant les prélèvements)
    await _commercialController.loadAll(forceRefresh: true);
    // 🎯 VRAIES ATTRIBUTIONS : Charge les attributions depuis Gestion Commercial
    await _commercialController.ensureAttributionsLoaded(forceRefresh: true);
    if (mounted) setState(() => _isLoading = false);
  }

  List<AttributionPartielle> _filteredAttributions() {
    final all = _commercialController.attributions;
    debugPrint('🔍 _filteredAttributions: ${all.length} attributions au total');
    
    final filtered = all.where((attribution) {
      final matchesSearch = _searchQuery.isEmpty ||
          attribution.commercialNom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          attribution.numeroLot.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          attribution.gestionnaire.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();
    
    debugPrint('📋 _filteredAttributions: ${filtered.length} attributions après filtrage');
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: SmartAppBar(
        title: "📋 Mes Prélèvements",
        backgroundColor: const Color(0xFF10B981),
        onBackPressed: () => Get.back(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: Icon(_filtreStatut == null
                ? Icons.filter_list
                : Icons.filter_list_alt),
            onPressed: _showFilterModal,
            tooltip: 'Filtrer',
          ),
        ],
      ),
      body: Obx(() {
        // 🔄 LOADING INDICATOR pendant le chargement
        if (_isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chargement des attributions...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }
        
        final attributions = _filteredAttributions();
        return AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) => Opacity(
            opacity: _fadeAnimation.value,
            child: _buildAttributionsContent(attributions),
          ),
        );
      }),
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
                colors: [const Color(0xFF10B981), const Color(0xFF059669)],
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
            'Chargement de vos prélèvements...',
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

  /// 🎯 NOUVEAU : Affiche les vraies attributions (plus de prélèvements fictifs)
  Widget _buildAttributionsContent(List<AttributionPartielle> attributions) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isExtraSmall = constraints.maxWidth < 480;

        return Column(
          children: [
            // Header avec statistiques
            SlideTransition(
              position: _slideAnimation,
              child: _buildAttributionStatsHeader(attributions),
            ),

            // Barre de recherche
            Container(
              margin: EdgeInsets.all(isExtraSmall ? 16 : 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Rechercher un prélèvement...',
                          prefixIcon: const Icon(Icons.search,
                              color: Color(0xFF10B981)),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () =>
                                      setState(() => _searchQuery = ''),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                        ),
                      ),
                    ),
                  ),
                  if (!isExtraSmall) ...[
                    const SizedBox(width: 12),
                    _buildQuickFilterChips(),
                  ],
                ],
              ),
            ),

            // Quick filters pour mobile
            if (isExtraSmall)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildQuickFilterChips(),
              ),

            // 📋 Liste des attributions
            Expanded(
              child: attributions.isEmpty
                  ? _buildEmptyAttributionsState()
                  : ListView.builder(
                      padding: EdgeInsets.all(isExtraSmall ? 16 : 20),
                      itemCount: attributions.length,
                      itemBuilder: (context, index) {
                        final attribution = attributions[index];
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(0, 0.1 * (index % 3)),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _slideController,
                            curve: Interval(
                              (index * 0.1).clamp(0.0, 1.0),
                              ((index + 1) * 0.1).clamp(0.0, 1.0),
                              curve: Curves.easeOutBack,
                            ),
                          )),
                          child: _buildAttributionCard(attribution),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickFilterChips() {
    final filters = [
      {'label': 'Tous', 'statut': null, 'color': Colors.grey},
      {
        'label': 'En cours',
        'statut': StatutPrelevement.enCours,
        'color': const Color(0xFF3B82F6)
      },
      {
        'label': 'Partiels',
        'statut': StatutPrelevement.partiel,
        'color': const Color(0xFFF59E0B)
      },
      {
        'label': 'Terminés',
        'statut': StatutPrelevement.termine,
        'color': const Color(0xFF10B981)
      },
    ];

    return Row(
      children: filters.map((filter) {
        final isSelected = _filtreStatut == filter['statut'];
        return Container(
          margin: const EdgeInsets.only(right: 8),
          child: FilterChip(
            selected: isSelected,
            label: Text(
              filter['label'] as String,
              style: TextStyle(
                color: isSelected ? Colors.white : (filter['color'] as Color),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            onSelected: (selected) {
              setState(() {
                _filtreStatut =
                    selected ? (filter['statut'] as StatutPrelevement?) : null;
                // filtrage réactif automatique via _filteredReactive()
              });
            },
            selectedColor: filter['color'] as Color,
            backgroundColor: (filter['color'] as Color).withOpacity(0.1),
            side: BorderSide(color: filter['color'] as Color),
            showCheckmark: false,
          ),
        );
      }).toList(),
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
                  const Color(0xFF10B981).withOpacity(0.1),
                  const Color(0xFF059669).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 60,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty || _filtreStatut != null
                ? 'Aucun prélèvement trouvé'
                : 'Aucun prélèvement',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _filtreStatut != null
                ? 'Modifiez vos critères de recherche'
                : 'Contactez votre gestionnaire pour obtenir des produits',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty || _filtreStatut != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _filtreStatut = null;
                  // filtrage réactif automatique
                });
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Effacer les filtres'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFilterModal() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '🔍 Filtres Avancés',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Filtre par statut
            const Text(
              'Statut des prélèvements',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildStatusFilterChip('Tous', null, Colors.grey.shade600),
                _buildStatusFilterChip('En cours', StatutPrelevement.enCours,
                    const Color(0xFF3B82F6)),
                _buildStatusFilterChip('Partiels', StatutPrelevement.partiel,
                    const Color(0xFFF59E0B)),
                _buildStatusFilterChip('Terminés', StatutPrelevement.termine,
                    const Color(0xFF10B981)),
                _buildStatusFilterChip('Annulés', StatutPrelevement.annule,
                    const Color(0xFFEF4444)),
              ],
            ),

            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _filtreStatut =
                            null; // réinitialisation, liste réactive
                      });
                      Get.back();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF10B981)),
                    ),
                    child: const Text(
                      'Réinitialiser',
                      style: TextStyle(color: Color(0xFF10B981)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // rien à recalculer manuellement, liste réactive
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Appliquer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildStatusFilterChip(
      String label, StatutPrelevement? statut, Color color) {
    final isSelected = _filtreStatut == statut;
    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: FontWeight.w600,
        ),
      ),
      onSelected: (selected) {
        setState(() {
          _filtreStatut = selected ? statut : null;
        });
      },
      selectedColor: color,
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color),
      showCheckmark: false,
    );
  }

  void _handlePrelevementAction(Prelevement prelevement, String action) {
    switch (action) {
      case 'vendre':
        // TODO: Naviguer vers la page de vente
        Get.snackbar('Action', 'Redirection vers la vente en cours...');
        break;
      case 'restituer':
        // TODO: Naviguer vers la page de restitution
        Get.snackbar('Action', 'Redirection vers la restitution en cours...');
        break;
      case 'perte':
        // TODO: Naviguer vers la page de déclaration de perte
        Get.snackbar(
            'Action', 'Redirection vers la déclaration de perte en cours...');
        break;
      case 'details':
        _showPrelevementDetails(prelevement);
        break;
    }
  }

  void _showPrelevementDetails(Prelevement prelevement) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '📋 Détails du Prélèvement',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'ID: ${prelevement.id}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Text(
              'Date: ${DateFormat('dd/MM/yyyy à HH:mm').format(prelevement.datePrelevement)}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Text(
              'Produits (${prelevement.produits.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...prelevement.produits
                .map((produit) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  produit.typeEmballage,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Quantité: ${produit.quantitePreleve}',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            VenteUtils.formatPrix(
                                produit.prixUnitaire * produit.quantitePreleve),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ))
                .toList(),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10B981).withOpacity(0.1),
                    const Color(0xFF059669).withOpacity(0.05)
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Valeur Totale',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    VenteUtils.formatPrix(prelevement.valeurTotale),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
            if (prelevement.observations != null) ...[
              const SizedBox(height: 16),
              Text(
                'Observations',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  prelevement.observations!,
                  style: TextStyle(color: Colors.blue.shade700),
                ),
              ),
            ],
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// 📊 Header avec statistiques des attributions
  Widget _buildAttributionStatsHeader(List<AttributionPartielle> attributions) {
    final totalValeur = attributions.fold<double>(0, (sum, a) => sum + a.valeurTotale);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  '${attributions.length}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Text(
                  'Attributions',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  '${totalValeur.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Text(
                  'Valeur totale',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 📋 Card pour afficher une attribution
  Widget _buildAttributionCard(AttributionPartielle attribution) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec nom commercial et date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    attribution.commercialNom,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(attribution.dateAttribution),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Détails du lot
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Lot:', attribution.numeroLot),
                  _buildDetailRow('Type:', attribution.typeEmballage),
                  _buildDetailRow('Contenance:', '${attribution.contenanceKg} kg'),
                  _buildDetailRow('Quantité:', '${attribution.quantiteAttribuee} unités'),
                  _buildDetailRow('Prix unitaire:', '${attribution.prixUnitaire.toStringAsFixed(0)} FCFA'),
                  const Divider(),
                  _buildDetailRow(
                    'Valeur totale:', 
                    '${attribution.valeurTotale.toStringAsFixed(0)} FCFA',
                    isTotal: true,
                  ),
                ],
              ),
            ),
            
            // Gestionnaire
            const SizedBox(height: 8),
            Text(
              'Attribué par: ${attribution.gestionnaire}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            
            // Observations si présentes
            if (attribution.observations?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  attribution.observations!,
                  style: TextStyle(color: Colors.blue.shade700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Helper pour créer une ligne de détail
  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.green : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// État vide pour les attributions
  Widget _buildEmptyAttributionsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune attribution trouvée',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les attributions du gestionnaire commercial apparaîtront ici',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
