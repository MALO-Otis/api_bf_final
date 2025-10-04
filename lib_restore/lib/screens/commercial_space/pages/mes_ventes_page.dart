import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/smart_appbar.dart';
import '../widgets/vente_form_moderne.dart';
import '../../vente/models/vente_models.dart';
import '../../vente/services/vente_service.dart';
import '../../../authentication/user_session.dart';
import '../../../utils/platform_download_helper.dart';
import '../../vente/controllers/espace_commercial_controller.dart';
// import 'dart:html' as html; // retiré pour build desktop
// ignore: avoid_web_libraries_in_flutter
// NEW: Controller import for realtime ventes

/// 💰 PAGE MES VENTES
/// Interface moderne pour gérer toutes les ventes effectuées
class MesVentesPage extends StatefulWidget {
  const MesVentesPage({super.key});

  @override
  State<MesVentesPage> createState() => _MesVentesPageState();
}

class _MesVentesPageState extends State<MesVentesPage>
    with TickerProviderStateMixin {
  final VenteService _service = VenteService();
  final UserSession _userSession = Get.find<UserSession>();
  // NEW: Reference to commercial space controller (realtime data)
  late final EspaceCommercialController _espaceCtrl;

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  List<Prelevement> _prelevements = [];
  // Legacy simulated ventes list - will be removed after full migration.
  List<dynamic> _ventes =
      []; // TODO remove after migration to _espaceCtrl.ventes
  bool _isLoading = true;
  String _searchQuery = '';

  // Statistiques
  Map<String, dynamic> _stats = {
    'ventes_total': 0,
    'ca_mensuel': 0.0,
    'ca_annuel': 0.0,
    'produits_vendus': 0,
    'clients_actifs': 0,
    'moyenne_panier': 0.0,
  }; // LEGACY (sera supprimé après migration complète)

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Initialize controller (create it if not exists)
    if (!Get.isRegistered<EspaceCommercialController>()) {
      Get.put(EspaceCommercialController(), permanent: true);
    }
    _espaceCtrl = Get.find<EspaceCommercialController>();
    _loadData(); // temporary until simulation removed
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutQuart),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final commercialId = _userSession.email ?? 'Commercial_Inconnu';
      final prelevements =
          await _service.getPrelevementsCommercial(commercialId);

      // TODO: Charger les vraies ventes depuis la base de données
      final ventesSimulees = _simulerVentes(prelevements);

      setState(() {
        _prelevements = prelevements;
        _ventes = ventesSimulees;
        _calculerStatistiques();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar(
        'Erreur',
        'Impossible de charger vos ventes: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  List<dynamic> _simulerVentes(List<Prelevement> prelevements) {
    // Simulation de ventes pour la démonstration
    return List.generate(15, (index) {
      return {
        'id': 'VTE_${DateTime.now().millisecondsSinceEpoch}_$index',
        'date': DateTime.now().subtract(Duration(days: index * 2)),
        'client': 'Client ${index + 1}',
        'produits': [
          {
            'type': '500g',
            'quantite': 2 + (index % 3),
            'prix_unitaire': 3000.0
          },
          {'type': '1kg', 'quantite': 1 + (index % 2), 'prix_unitaire': 5500.0},
        ],
        'montant_total':
            (2 + (index % 3)) * 3000.0 + (1 + (index % 2)) * 5500.0,
        'statut': index % 4 == 0 ? 'remboursee' : 'validee',
        'mode_paiement': ['especes', 'mobile_money', 'virement'][index % 3],
      };
    });
  }

  void _calculerStatistiques() {
    final ventesValides =
        _ventes.where((v) => v['statut'] == 'validee').toList();
    final caMensuel =
        ventesValides.fold<double>(0.0, (sum, v) => sum + v['montant_total']);
    final produitsVendus = ventesValides.fold<int>(0, (sum, v) {
      return sum +
          (v['produits'] as List)
              .fold<int>(0, (pSum, p) => pSum + (p['quantite'] as int));
    });

    setState(() {
      _stats = {
        'ventes_total': ventesValides.length,
        'ca_mensuel': caMensuel,
        'ca_annuel': caMensuel * 12, // Estimation
        'produits_vendus': produitsVendus,
        'clients_actifs': ventesValides.map((v) => v['client']).toSet().length,
        'moyenne_panier':
            ventesValides.isNotEmpty ? caMensuel / ventesValides.length : 0.0,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: SmartAppBar(
        title: "💰 Mes Ventes",
        backgroundColor: const Color(0xFF3B82F6),
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
                colors: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
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
            'Chargement de vos ventes...',
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
    return Obx(() {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isExtraSmall = constraints.maxWidth < 480;
          final isSmall = constraints.maxWidth < 768;

          final realVentes = _espaceCtrl.ventes;
          final stats = _computeRealtimeStats(realVentes);
          final showingLegacy = realVentes.isEmpty && _ventes.isNotEmpty;
          final ventesAffichees =
              showingLegacy ? _ventes : _filteredRealtimeVentes(realVentes);

          return Column(
            children: [
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: _buildStatsHeader(isExtraSmall, isSmall, stats),
                  );
                },
              ),
              Container(
                margin: EdgeInsets.all(isExtraSmall ? 16 : 20),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Rechercher une vente...',
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF3B82F6)),
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                  ),
                ),
              ),
              Expanded(
                child: ventesAffichees.isEmpty
                    ? _buildEmptyState()
                    : _buildVentesListDynamic(
                        isExtraSmall, ventesAffichees, showingLegacy),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildStatsHeader(
      bool isExtraSmall, bool isSmall, Map<String, dynamic> stats) {
    return Container(
      margin: EdgeInsets.all(isExtraSmall ? 16 : 20),
      padding: EdgeInsets.all(isExtraSmall ? 20 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
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
                  '💰',
                  style: TextStyle(fontSize: isExtraSmall ? 32 : 40),
                ),
              ),
              SizedBox(width: isExtraSmall ? 16 : 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mes Ventes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isExtraSmall ? 20 : 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isExtraSmall ? 4 : 8),
                    Text(
                      '${stats['ventes_total']} vente${stats['ventes_total'] > 1 ? 's' : ''} réalisée${stats['ventes_total'] > 1 ? 's' : ''}',
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
                            'CA Mensuel',
                            '${(stats['ca_mensuel'] / 1000000).toStringAsFixed(1)}M',
                            Icons.trending_up,
                            true)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildStatCard(
                            'Ventes',
                            '${stats['ventes_total']}',
                            Icons.point_of_sale,
                            true)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _buildStatCard(
                            'Produits',
                            '${stats['produits_vendus']}',
                            Icons.inventory_2,
                            true)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildStatCard('Clients',
                            '${stats['clients_actifs']}', Icons.people, true)),
                  ],
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                    child: _buildStatCard(
                        'CA Mensuel',
                        '${(stats['ca_mensuel'] / 1000000).toStringAsFixed(1)}M FCFA',
                        Icons.trending_up,
                        false)),
                SizedBox(width: isSmall ? 12 : 16),
                Expanded(
                    child: _buildStatCard(
                        'Ventes Total',
                        '${stats['ventes_total']}',
                        Icons.point_of_sale,
                        false)),
                SizedBox(width: isSmall ? 12 : 16),
                Expanded(
                    child: _buildStatCard(
                        'Produits Vendus',
                        '${stats['produits_vendus']}',
                        Icons.inventory_2,
                        false)),
                SizedBox(width: isSmall ? 12 : 16),
                Expanded(
                    child: _buildStatCard('Clients Actifs',
                        '${stats['clients_actifs']}', Icons.people, false)),
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

  // Legacy list builder removed (now using _buildVentesListDynamic directly)

  // NEW dynamic list builder (renamed to avoid clash with legacy signature above)
  Widget _buildVentesListDynamic(
      bool isExtraSmall, List<dynamic> ventesSource, bool legacy) {
    final venteFiltrees = ventesSource.where((vente) {
      if (_searchQuery.isEmpty) return true;
      // For real model (Vente) adapt property access
      if (!legacy && vente is Vente) {
        return (vente.clientNom
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            vente.id.toLowerCase().contains(_searchQuery.toLowerCase()));
      }
      // legacy map
      return (vente['client'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          (vente['id'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();

    return ListView.builder(
      padding: EdgeInsets.all(isExtraSmall ? 16 : 20),
      itemCount: venteFiltrees.length,
      itemBuilder: (context, index) {
        final vente = venteFiltrees[index];
        return _buildVenteCard(vente, isExtraSmall, legacy: legacy);
      },
    );
  }

  // Compute stats from realtime ventes list
  Map<String, dynamic> _computeRealtimeStats(List<Vente> ventes) {
    if (ventes.isEmpty) return _stats; // fallback until legacy removed
    final valides = ventes
        .where((v) => v.statut.estSolde || v.statut.estCreditActif)
        .toList();
    double caMensuel = 0;
    int produitsVendus = 0;
    final clients = <String>{};
    for (final v in valides) {
      caMensuel += v.montantTotal;
      for (final p in v.produits) {
        produitsVendus += p.quantiteVendue;
      }
      if (v.clientNom.isNotEmpty) clients.add(v.clientNom);
    }
    return {
      'ventes_total': valides.length,
      'ca_mensuel': caMensuel,
      'ca_annuel': caMensuel * 12,
      'produits_vendus': produitsVendus,
      'clients_actifs': clients.length,
      'moyenne_panier': valides.isNotEmpty ? caMensuel / valides.length : 0.0,
    };
  }

  // Filter realtime ventes with search query
  List<dynamic> _filteredRealtimeVentes(List<Vente> source) {
    if (_searchQuery.isEmpty) return source;
    final q = _searchQuery.toLowerCase();
    return source
        .where((v) =>
            v.clientNom.toLowerCase().contains(q) ||
            v.id.toLowerCase().contains(q))
        .toList();
  }

  Widget _buildVenteCard(dynamic vente, bool isExtraSmall,
      {bool legacy = false}) {
    // Map legacy fields to new model semantics
    bool isCreditRembourse;
    String client;
    DateTime date;
    List produits;
    double montantTotal;
    String modePaiement;
    String statutLabel;
    if (!legacy && vente is Vente) {
      isCreditRembourse = vente.statut == StatutVente.creditRembourse ||
          vente.statut == StatutVente.payeeEnTotalite;
      client = vente.clientNom;
      date = vente.dateVente;
      produits = vente.produits
          .map((p) => {
                'type': p.typeEmballage,
                'quantite': p.quantiteVendue,
                'prix_unitaire': p.prixUnitaire,
              })
          .toList();
      montantTotal = vente.montantTotal;
      modePaiement = vente.modePaiement.name;
      statutLabel = vente.statut.label;
    } else {
      isCreditRembourse =
          (vente['statut'] == 'remboursee' || vente['statut'] == 'validee');
      client = vente['client'];
      date = vente['date'];
      produits = vente['produits'];
      montantTotal = (vente['montant_total'] as num).toDouble();
      modePaiement = vente['mode_paiement'];
      statutLabel = isCreditRembourse ? 'Validée' : 'Crédit';
    }
    final statusColor =
        isCreditRembourse ? const Color(0xFF10B981) : const Color(0xFFEF4444);

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
                    Icons.receipt,
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
                              client,
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
                              statutLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Reçu',
                            child: IconButton(
                              icon: const Icon(Icons.picture_as_pdf,
                                  size: 20, color: Colors.black54),
                              onPressed: () =>
                                  _showReceiptForVente(vente, legacy: legacy),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Tooltip(
                            message: 'Télécharger (.txt)',
                            child: IconButton(
                              icon: const Icon(Icons.download_for_offline,
                                  size: 20, color: Colors.blueGrey),
                              onPressed: () =>
                                  _downloadReceipt(vente, legacy: legacy),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('dd/MM/yyyy à HH:mm').format(date),
                        style: TextStyle(
                          fontSize: isExtraSmall ? 12 : 14,
                          color: Colors.grey.shade600,
                        ),
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
              children: [
                // Produits vendus
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
                        'Produits vendus',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...produits
                          .map((produit) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade400,
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
                                      VenteUtils.formatPrix(
                                          produit['prix_unitaire'] *
                                              produit['quantite']),
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

                // Total et mode de paiement
                Row(
                  children: [
                    Expanded(
                      child: Container(
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
                              'Montant Total',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              VenteUtils.formatPrix(montantTotal),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        Icon(
                          _getPaymentIcon(modePaiement),
                          color: Colors.grey.shade600,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getPaymentLabel(modePaiement),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
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

  void _showReceiptForVente(dynamic vente, {required bool legacy}) {
    try {
      String recu;
      if (!legacy && vente is Vente) {
        recu = _service.generateReceipt(vente);
      } else {
        // Construire un modèle minimal depuis la map legacy
        final produits = (vente['produits'] as List)
            .map((p) =>
                '- ${p['type']} x${p['quantite']} @${(p['prix_unitaire'] as num).toStringAsFixed(0)} = ${((p['prix_unitaire'] as num) * (p['quantite'] as num)).toStringAsFixed(0)}')
            .join('\n');
        final montantTotal = (vente['montant_total'] as num).toDouble();
        recu = [
          '=========== REÇU DE VENTE (Legacy) ===========',
          'ID: ${vente['id']}',
          'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(vente['date'])}',
          'Client: ${vente['client']}',
          '-------------------------------------',
          'Produits:',
          produits,
          '-------------------------------------',
          'Montant Total : ${montantTotal.toStringAsFixed(0)} FCFA',
          'Mode Paiement: ${vente['mode_paiement']}',
          'Statut       : ${vente['statut']}',
          '====================================='
        ].join('\n');
      }
      Clipboard.setData(ClipboardData(text: recu));
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Reçu de Vente'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: SelectableText(
                recu,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Fermer')),
            TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: recu));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Reçu copié dans le presse-papiers')));
                },
                child: const Text('Copier')),
          ],
        ),
      );
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de générer le reçu: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void _downloadReceipt(dynamic vente, {required bool legacy}) {
    String recu;
    if (!legacy && vente is Vente) {
      recu = _service.generateReceipt(vente);
    } else {
      final produits = (vente['produits'] as List)
          .map((p) =>
              '- ${p['type']} x${p['quantite']} @${(p['prix_unitaire'] as num).toStringAsFixed(0)} = ${((p['prix_unitaire'] as num) * (p['quantite'] as num)).toStringAsFixed(0)}')
          .join('\n');
      final montantTotal = (vente['montant_total'] as num).toDouble();
      recu = [
        '=========== REÇU DE VENTE (Legacy) ===========',
        'ID: ${vente['id']}',
        'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(vente['date'])}',
        'Client: ${vente['client']}',
        '-------------------------------------',
        'Produits:',
        produits,
        '-------------------------------------',
        'Montant Total : ${montantTotal.toStringAsFixed(0)} FCFA',
        'Mode Paiement: ${vente['mode_paiement']}',
        'Statut       : ${vente['statut']}',
        '====================================='
      ].join('\n');
    }
    final fileName =
        'recu_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.txt';
    downloadTextCross(recu, fileName: fileName);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Téléchargement (ou sauvegarde) demandé')));
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
                  const Color(0xFF3B82F6).withOpacity(0.1),
                  const Color(0xFF1D4ED8).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.point_of_sale,
              size: 60,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune vente enregistrée',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez à enregistrer vos ventes',
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
      onPressed: _showNouvelleVente,
      backgroundColor: const Color(0xFF3B82F6),
      icon: const Icon(Icons.add),
      label: const Text('Nouvelle Vente'),
      elevation: 8,
    );
  }

  void _showNouvelleVente() {
    Get.dialog(
      VenteFormeModerne(
        prelevements: _prelevements
            .where((p) => p.statut == StatutPrelevement.enCours)
            .toList(),
        onVenteEnregistree: () {
          _loadData();
          Get.back();
        },
      ),
      barrierDismissible: false,
    );
  }

  IconData _getPaymentIcon(String mode) {
    switch (mode) {
      case 'especes':
        return Icons.money;
      case 'mobile_money':
        return Icons.phone_android;
      case 'virement':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  String _getPaymentLabel(String mode) {
    switch (mode) {
      case 'especes':
        return 'Espèces';
      case 'mobile_money':
        return 'Mobile Money';
      case 'virement':
        return 'Virement';
      default:
        return 'Autre';
    }
  }
}
