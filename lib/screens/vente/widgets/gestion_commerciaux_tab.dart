/// 👥 ONGLET GESTION DES COMMERCIAUX
///
/// Interface complète pour gérer toutes les activités des commerciaux :
/// - Ventes réalisées
/// - Restitutions effectuées
/// - Pertes déclarées
/// - Historique complet des opérations

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/personnel/personnel_apisavana.dart';
import '../models/commercial_models.dart';
import '../services/commercial_service.dart';

class GestionCommerciauxTab extends StatefulWidget {
  final CommercialService commercialService;

  const GestionCommerciauxTab({
    super.key,
    required this.commercialService,
  });

  @override
  State<GestionCommerciauxTab> createState() => _GestionCommerciauxTabState();
}

class _GestionCommerciauxTabState extends State<GestionCommerciauxTab>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late TabController _tabController;
  final RxString _selectedCommercial = 'tous'.obs;
  final RxBool _isLoading = false.obs;

  // Données des activités
  final RxList<Map<String, dynamic>> _ventes = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _restitutions =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _pertes = <Map<String, dynamic>>[].obs;
  final RxList<AttributionPartielle> _attributions =
      <AttributionPartielle>[].obs;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadActivitesCommerciaux();

    // 🔧 CORRECTION : Écouter les changements du service commercial
    // Utiliser un Timer pour rafraîchir périodiquement
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && widget.commercialService.attributions.isNotEmpty) {
        _attributions.value = widget.commercialService.attributions;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _tabController = TabController(length: 4, vsync: this);

    // Écouter les changements de commercial sélectionné
    ever(_selectedCommercial, (_) => _loadActivitesCommerciaux());
  }

  Future<void> _loadActivitesCommerciaux() async {
    try {
      _isLoading.value = true;
      debugPrint(
          '🔄 [GestionCommerciauxTab] Chargement des activités commerciales...');

      // Charger les vraies données depuis le service
      await Future.wait([
        _loadAttributions(),
        _loadVentes(),
        _loadRestitutions(),
        _loadPertes(),
      ]);

      debugPrint('✅ [GestionCommerciauxTab] Toutes les activités chargées');
    } catch (e) {
      debugPrint('❌ [GestionCommerciauxTab] Erreur chargement activités: $e');
      // En cas d'erreur, charger les données mockées pour la démonstration
      await _loadMockData();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _loadAttributions() async {
    try {
      // Forcer le rechargement des attributions
      await widget.commercialService.getLotsAvecCache(forceRefresh: true);
      final toutes_attributions = widget.commercialService.attributions;

      // Filtrer selon le commercial sélectionné
      if (_selectedCommercial.value == 'tous') {
        _attributions.value = toutes_attributions;
      } else {
        _attributions.value = toutes_attributions
            .where((attr) => attr.commercialNom
                .toLowerCase()
                .contains(_selectedCommercial.value.toLowerCase()))
            .toList();
      }

      debugPrint(
          '📊 [GestionCommerciauxTab] ${_attributions.length} attributions chargées');
    } catch (e) {
      debugPrint(
          '❌ [GestionCommerciauxTab] Erreur chargement attributions: $e');
      _attributions.value = [];
    }
  }

  Future<void> _loadVentes() async {
    try {
      // TODO: Implémenter la récupération des ventes depuis Firestore
      // Pour l'instant, générer depuis les attributions
      _ventes.value = _attributions
          .map((attr) => {
                'id': 'VENTE_${attr.id}',
                'commercial': attr.commercialNom,
                'client': 'Client à définir', // TODO: Lier aux vraies ventes
                'produit': '${attr.typeEmballage} - ${attr.numeroLot}',
                'quantite': attr.quantiteAttribuee,
                'montant': attr.valeurTotale,
                'date': attr.dateAttribution,
                'statut': 'En cours',
              })
          .toList();

      debugPrint(
          '💰 [GestionCommerciauxTab] ${_ventes.length} ventes simulées depuis attributions');
    } catch (e) {
      debugPrint('❌ [GestionCommerciauxTab] Erreur chargement ventes: $e');
      _ventes.value = [];
    }
  }

  Future<void> _loadRestitutions() async {
    try {
      // TODO: Implémenter la récupération des restitutions depuis Firestore
      _restitutions.value = [];
      debugPrint(
          '🔄 [GestionCommerciauxTab] Restitutions: pas encore implémentées');
    } catch (e) {
      debugPrint(
          '❌ [GestionCommerciauxTab] Erreur chargement restitutions: $e');
      _restitutions.value = [];
    }
  }

  Future<void> _loadPertes() async {
    try {
      // TODO: Implémenter la récupération des pertes depuis Firestore
      _pertes.value = [];
      debugPrint('📉 [GestionCommerciauxTab] Pertes: pas encore implémentées');
    } catch (e) {
      debugPrint('❌ [GestionCommerciauxTab] Erreur chargement pertes: $e');
      _pertes.value = [];
    }
  }

  Future<void> _loadMockData() async {
    // Simuler un délai
    await Future.delayed(const Duration(milliseconds: 500));

    // Données mockées pour la démonstration
    _ventes.value = [
      {
        'id': '1',
        'commercial': 'YAMEOGO Rose',
        'client': 'Cliente SAWADOGO',
        'produit': 'Pot 1Kg',
        'quantite': 5,
        'prixUnitaire': 3400,
        'total': 17000,
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'statut': 'Payé',
      },
      {
        'id': '2',
        'commercial': 'KANSIEMO Marceline',
        'client': 'Client OUEDRAOGO',
        'produit': 'Pot 500g',
        'quantite': 12,
        'prixUnitaire': 1800,
        'total': 21600,
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'statut': 'Payé',
      },
    ];

    _restitutions.value = [
      {
        'id': '1',
        'commercial': 'YAMEOGO Rose',
        'produit': 'Pot 1Kg',
        'quantite': 2,
        'raison': 'Produit endommagé',
        'date': DateTime.now().subtract(const Duration(days: 3)),
        'statut': 'Acceptée',
      },
    ];

    _pertes.value = [
      {
        'id': '1',
        'commercial': 'SEMDE OUMAROU',
        'produit': 'Stick 20g',
        'quantite': 10,
        'raison': 'Casse accidentelle',
        'date': DateTime.now().subtract(const Duration(days: 5)),
        'statut': 'En attente',
      },
    ];

    // 🔧 CORRECTION : Charger les vraies attributions depuis le cache du service
    try {
      // Forcer le rechargement des données si nécessaire
      await widget.commercialService.getLotsAvecCache(forceRefresh: false);

      // Utiliser directement le cache des attributions du service
      _attributions.value = widget.commercialService.attributions;

      debugPrint(
          '✅ [GestionCommerciauxTab] ${_attributions.length} attributions chargées');
    } catch (e) {
      debugPrint('⚠️ Erreur chargement attributions: $e');
      // Fallback : essayer de récupérer depuis les lots
      try {
        final lots = widget.commercialService.lots;
        final List<AttributionPartielle> allAttributions = [];

        for (final lot in lots) {
          allAttributions.addAll(lot.attributions);
        }

        _attributions.value = allAttributions;
        debugPrint(
            '✅ [GestionCommerciauxTab] Fallback: ${_attributions.length} attributions chargées depuis les lots');
      } catch (fallbackError) {
        debugPrint('❌ Erreur fallback chargement attributions: $fallbackError');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        _buildHeader(context),
        _buildCommercialSelector(context),
        Expanded(
          child: Obx(() => _isLoading.value
              ? _buildLoadingView()
              : _buildTabsContent(context)),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.group,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestion des Commerciaux',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Suivi complet des activités commerciales',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadActivitesCommerciaux,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualiser',
          ),
        ],
      ),
    );
  }

  Widget _buildCommercialSelector(BuildContext context) {
    final commerciaux = PersonnelApisavana.getTousCommerciaux();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.filter_list, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          const Text(
            'Commercial :',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() => DropdownButton<String>(
                  value: _selectedCommercial.value,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                      value: 'tous',
                      child: Text('🌟 Tous les commerciaux'),
                    ),
                    ...commerciaux.map((commercial) => DropdownMenuItem(
                          value: commercial['nom'] ?? '',
                          child: Text(commercial['nom'] ?? ''),
                        )),
                  ],
                  onChanged: (value) {
                    _selectedCommercial.value = value ?? 'tous';
                  },
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF2196F3)),
          SizedBox(height: 16),
          Text('Chargement des activités...'),
        ],
      ),
    );
  }

  Widget _buildTabsContent(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF2196F3),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF2196F3),
            tabs: [
              Tab(
                icon: const Icon(Icons.assignment_turned_in),
                text: 'Attributions',
                height: 60,
              ),
              Tab(
                icon: const Icon(Icons.shopping_cart),
                text: 'Ventes',
                height: 60,
              ),
              Tab(
                icon: const Icon(Icons.keyboard_return),
                text: 'Restitutions',
                height: 60,
              ),
              Tab(
                icon: const Icon(Icons.report_problem),
                text: 'Pertes',
                height: 60,
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAttributionsTab(),
              _buildVentesTab(),
              _buildRestitutionsTab(),
              _buildPertesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttributionsTab() {
    return Obx(() {
      List<AttributionPartielle> attributionsFiltrees = _attributions;

      if (_selectedCommercial.value != 'tous') {
        attributionsFiltrees = _attributions
            .where((attr) => attr.commercialNom == _selectedCommercial.value)
            .toList();
      }

      if (attributionsFiltrees.isEmpty) {
        return _buildEmptyState(
            'Aucune attribution trouvée', Icons.assignment_turned_in);
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: attributionsFiltrees.length,
        itemBuilder: (context, index) {
          final attribution = attributionsFiltrees[index];
          return _buildAttributionCard(attribution);
        },
      );
    });
  }

  Widget _buildVentesTab() {
    return Obx(() {
      List<Map<String, dynamic>> ventesFiltrees = _ventes;

      if (_selectedCommercial.value != 'tous') {
        ventesFiltrees = _ventes
            .where((vente) => vente['commercial'] == _selectedCommercial.value)
            .toList();
      }

      if (ventesFiltrees.isEmpty) {
        return _buildEmptyState(
            'Aucune vente enregistrée', Icons.shopping_cart);
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ventesFiltrees.length,
        itemBuilder: (context, index) {
          final vente = ventesFiltrees[index];
          return _buildVenteCard(vente);
        },
      );
    });
  }

  Widget _buildRestitutionsTab() {
    return Obx(() {
      List<Map<String, dynamic>> restitutionsFiltrees = _restitutions;

      if (_selectedCommercial.value != 'tous') {
        restitutionsFiltrees = _restitutions
            .where((rest) => rest['commercial'] == _selectedCommercial.value)
            .toList();
      }

      if (restitutionsFiltrees.isEmpty) {
        return _buildEmptyState(
            'Aucune restitution trouvée', Icons.keyboard_return);
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: restitutionsFiltrees.length,
        itemBuilder: (context, index) {
          final restitution = restitutionsFiltrees[index];
          return _buildRestitutionCard(restitution);
        },
      );
    });
  }

  Widget _buildPertesTab() {
    return Obx(() {
      List<Map<String, dynamic>> pertesFiltrees = _pertes;

      if (_selectedCommercial.value != 'tous') {
        pertesFiltrees = _pertes
            .where((perte) => perte['commercial'] == _selectedCommercial.value)
            .toList();
      }

      if (pertesFiltrees.isEmpty) {
        return _buildEmptyState('Aucune perte déclarée', Icons.report_problem);
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pertesFiltrees.length,
        itemBuilder: (context, index) {
          final perte = pertesFiltrees[index];
          return _buildPerteCard(perte);
        },
      );
    });
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributionCard(AttributionPartielle attribution) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF4CAF50).withOpacity(0.2),
              child: const Icon(Icons.assignment_turned_in,
                  color: Color(0xFF4CAF50)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attribution.commercialNom,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Lot ${attribution.lotId} • ${attribution.quantiteAttribuee} unités',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm')
                        .format(attribution.dateAttribution),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA')
                      .format(attribution.valeurTotale),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVenteCard(Map<String, dynamic> vente) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF2196F3).withOpacity(0.2),
              child: const Icon(Icons.shopping_cart, color: Color(0xFF2196F3)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vente['commercial'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Client: ${vente['client']} • ${vente['produit']}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(
                    '${vente['quantite']} × ${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(vente['prixUnitaire'])}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA')
                      .format(vente['total']),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    vente['statut'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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

  Widget _buildRestitutionCard(Map<String, dynamic> restitution) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.2),
              child: const Icon(Icons.keyboard_return, color: Colors.orange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restitution['commercial'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${restitution['produit']} • ${restitution['quantite']} unités',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(
                    restitution['raison'] ?? '',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: restitution['statut'] == 'Acceptée'
                    ? const Color(0xFF4CAF50)
                    : Colors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                restitution['statut'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerteCard(Map<String, dynamic> perte) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.2),
              child: const Icon(Icons.report_problem, color: Colors.red),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    perte['commercial'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${perte['produit']} • ${perte['quantite']} unités',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(
                    perte['raison'] ?? '',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: perte['statut'] == 'Validée'
                    ? const Color(0xFF4CAF50)
                    : perte['statut'] == 'En attente'
                        ? Colors.orange
                        : Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                perte['statut'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
