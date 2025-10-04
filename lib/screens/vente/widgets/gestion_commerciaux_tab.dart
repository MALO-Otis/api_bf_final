import 'dart:async';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../models/commercial_models.dart';
import '../services/commercial_service.dart';
import '../../../data/personnel/personnel_apisavana.dart';

/// 👥 ONGLET GESTION DES COMMERCIAUX
///
/// Interface complète pour gérer toutes les activités des commerciaux :
/// - Ventes réalisées
/// - Restitutions effectuées
/// - Pertes déclarées
/// - Historique complet des opérations

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

  // État des cards dépliables
  final RxMap<String, bool> _expandedCards = <String, bool>{}.obs;

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
    _tabController = TabController(length: 5, vsync: this);

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
            isScrollable: true,
            labelColor: const Color(0xFF2196F3),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF2196F3),
            tabs: [
              Tab(
                icon: const Icon(Icons.people),
                text: 'Commerciaux',
                height: 60,
              ),
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
              _buildCommerciauxTab(),
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

  /// Onglet des commerciaux avec cards dépliables
  Widget _buildCommerciauxTab() {
    return Obx(() {
      // Obtenir la liste unique des commerciaux depuis les attributions
      final commerciaux = _getUniqueCommerciaux();

      if (commerciaux.isEmpty) {
        return _buildEmptyState('Aucun commercial trouvé', Icons.people);
      }

      return ListView.builder(
        primary: false,
        padding: const EdgeInsets.all(16),
        itemCount: commerciaux.length,
        itemBuilder: (context, index) {
          final commercial = commerciaux[index];
          return _buildExpandableCommercialCard(commercial);
        },
      );
    });
  }

  /// Obtenir la liste unique des commerciaux
  List<String> _getUniqueCommerciaux() {
    final Set<String> commerciauxSet = <String>{};

    // Ajouter depuis les attributions
    for (final attribution in _attributions) {
      commerciauxSet.add(attribution.commercialNom);
    }

    // Ajouter depuis les ventes
    for (final vente in _ventes) {
      commerciauxSet.add(vente['commercial'] as String);
    }

    // Ajouter depuis les restitutions
    for (final restitution in _restitutions) {
      commerciauxSet.add(restitution['commercial'] as String);
    }

    // Ajouter depuis les pertes
    for (final perte in _pertes) {
      commerciauxSet.add(perte['commercial'] as String);
    }

    return commerciauxSet.toList()..sort();
  }

  /// Card dépliable pour chaque commercial
  Widget _buildExpandableCommercialCard(String commercialNom) {
    final isExpanded = _expandedCards[commercialNom] ?? false;

    // Calculer les statistiques du commercial
    final attributions =
        _attributions.where((a) => a.commercialNom == commercialNom).toList();
    final ventes =
        _ventes.where((v) => v['commercial'] == commercialNom).toList();
    final restitutions =
        _restitutions.where((r) => r['commercial'] == commercialNom).toList();
    final pertes =
        _pertes.where((p) => p['commercial'] == commercialNom).toList();

    final totalAttributions = attributions.length;
    final totalVentes = ventes.length;

    final valeurTotaleAttributions =
        attributions.fold(0.0, (sum, a) => sum + a.valeurTotale);

    // Calculer le statut global
    final bool hasActivitePendante =
        ventes.any((v) => v['statut'] != 'Validé') ||
            restitutions.any((r) => r['statut'] != 'Validé') ||
            pertes.any((p) => p['statut'] != 'Validé');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header de la card
          InkWell(
            onTap: () {
              _expandedCards[commercialNom] = !isExpanded;
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2196F3).withOpacity(0.8),
                    const Color(0xFF1976D2).withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  // Avatar du commercial
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 24,
                    child: Text(
                      commercialNom.isNotEmpty
                          ? commercialNom[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Informations du commercial
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          commercialNom,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalAttributions attributions • $totalVentes ventes',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA')
                              .format(valeurTotaleAttributions),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Badge de statut
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasActivitePendante
                          ? Colors.orange[100]
                          : Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      hasActivitePendante ? 'En attente' : 'Validé',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: hasActivitePendante
                            ? Colors.orange[800]
                            : Colors.green[800],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Icône d'expansion
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenu dépliable
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: isExpanded ? null : 0,
            child: isExpanded
                ? _buildExpandedContent(
                    commercialNom, attributions, ventes, restitutions, pertes)
                : null,
          ),
        ],
      ),
    );
  }

  /// Contenu dépliable de la card
  Widget _buildExpandedContent(
    String commercialNom,
    List<AttributionPartielle> attributions,
    List<Map<String, dynamic>> ventes,
    List<Map<String, dynamic>> restitutions,
    List<Map<String, dynamic>> pertes,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistiques rapides
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Attributions', '${attributions.length}',
                    Icons.assignment_turned_in, Colors.blue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard('Ventes', '${ventes.length}',
                    Icons.shopping_cart, Colors.green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard('Restitutions', '${restitutions.length}',
                    Icons.keyboard_return, Colors.orange),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard('Pertes', '${pertes.length}',
                    Icons.report_problem, const Color(0xFF1976D2)),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Sections détaillées
          if (ventes.isNotEmpty) ...[
            _buildSectionHeader(
                'Ventes Effectuées', Icons.shopping_cart, Colors.green),
            const SizedBox(height: 8),
            ...ventes.map((vente) => _buildActivityItem(
                  title: '${vente['produit']} x${vente['quantite']}',
                  subtitle:
                      'Client: ${vente['client']} • ${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(vente['total'])}',
                  date: vente['date'] as DateTime,
                  status: vente['statut'] as String,
                  onValidate: () =>
                      _validateActivity('vente', vente['id'], commercialNom),
                )),
            const SizedBox(height: 16),
          ],

          if (restitutions.isNotEmpty) ...[
            _buildSectionHeader('Demandes de Restitution',
                Icons.keyboard_return, Colors.orange),
            const SizedBox(height: 8),
            ...restitutions.map((restitution) => _buildActivityItem(
                  title:
                      '${restitution['produit']} x${restitution['quantite']}',
                  subtitle: 'Motif: ${restitution['motif']}',
                  date: restitution['date'] as DateTime,
                  status: restitution['statut'] as String,
                  onValidate: () => _validateActivity(
                      'restitution', restitution['id'], commercialNom),
                )),
            const SizedBox(height: 16),
          ],

          if (pertes.isNotEmpty) ...[
            _buildSectionHeader('Déclarations de Pertes', Icons.report_problem,
                const Color(0xFF1976D2)),
            const SizedBox(height: 8),
            ...pertes.map((perte) => _buildActivityItem(
                  title: '${perte['produit']} x${perte['quantite']}',
                  subtitle: 'Motif: ${perte['motif']}',
                  date: perte['date'] as DateTime,
                  status: perte['statut'] as String,
                  onValidate: () =>
                      _validateActivity('perte', perte['id'], commercialNom),
                )),
            const SizedBox(height: 16),
          ],

          // Bouton de validation complète
          const Divider(),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _validateCompleteActivity(commercialNom),
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text(
                'Valider l\'Activité Complète',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
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
              backgroundColor: const Color(0xFF1976D2).withOpacity(0.15),
              child: const Icon(Icons.report_problem, color: Color(0xFF1976D2)),
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

  /// Widget pour les cartes de statistiques
  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Header pour les sections
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Item d'activité avec bouton de validation
  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required DateTime date,
    required String status,
    required VoidCallback onValidate,
  }) {
    final isValidated = status == 'Validé';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValidated ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValidated ? Colors.green[200]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          // Icône de statut
          Icon(
            isValidated ? Icons.check_circle : Icons.pending,
            color: isValidated ? Colors.green : Colors.orange,
            size: 20,
          ),

          const SizedBox(width: 12),

          // Informations
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy à HH:mm').format(date),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Bouton de validation
          if (!isValidated)
            TextButton.icon(
              onPressed: onValidate,
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Valider'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Validé',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Valider une activité individuelle
  void _validateActivity(String type, String id, String commercialNom) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text('Validation ${type.toUpperCase()}'),
          ],
        ),
        content: Text(
          'Êtes-vous sûr de vouloir valider cette ${type} pour ${commercialNom} ?\n\n'
          'Cette action confirmera que l\'opération a été vérifiée et approuvée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _performValidation(type, id, commercialNom);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Valider', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Valider l'activité complète d'un commercial
  void _validateCompleteActivity(String commercialNom) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.verified, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Validation Complète'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Validation complète pour ${commercialNom}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cette action va valider TOUTES les activités en attente :',
            ),
            const SizedBox(height: 8),
            Text('• Toutes les ventes non validées',
                style: TextStyle(color: Colors.grey[600])),
            Text('• Toutes les restitutions en attente',
                style: TextStyle(color: Colors.grey[600])),
            Text('• Toutes les déclarations de pertes',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cette action est irréversible',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _performCompleteValidation(commercialNom);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Valider Tout',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Effectuer la validation d'une activité
  void _performValidation(String type, String id, String commercialNom) {
    try {
      // Mettre à jour le statut selon le type
      switch (type) {
        case 'vente':
          final index = _ventes.indexWhere((v) => v['id'] == id);
          if (index != -1) {
            _ventes[index]['statut'] = 'Validé';
            _ventes.refresh();
          }
          break;
        case 'restitution':
          final index = _restitutions.indexWhere((r) => r['id'] == id);
          if (index != -1) {
            _restitutions[index]['statut'] = 'Validé';
            _restitutions.refresh();
          }
          break;
        case 'perte':
          final index = _pertes.indexWhere((p) => p['id'] == id);
          if (index != -1) {
            _pertes[index]['statut'] = 'Validé';
            _pertes.refresh();
          }
          break;
      }

      Get.snackbar(
        '✅ Validation effectuée',
        '${type.toUpperCase()} validée pour ${commercialNom}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // TODO: Sauvegarder en base de données
      debugPrint('✅ ${type.toUpperCase()} validée: $id pour $commercialNom');
    } catch (e) {
      Get.snackbar(
        '❌ Erreur',
        'Impossible de valider la ${type}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      debugPrint('❌ Erreur validation ${type}: $e');
    }
  }

  /// Effectuer la validation complète
  void _performCompleteValidation(String commercialNom) {
    try {
      int validatedCount = 0;

      // Valider toutes les ventes du commercial
      for (int i = 0; i < _ventes.length; i++) {
        if (_ventes[i]['commercial'] == commercialNom &&
            _ventes[i]['statut'] != 'Validé') {
          _ventes[i]['statut'] = 'Validé';
          validatedCount++;
        }
      }

      // Valider toutes les restitutions du commercial
      for (int i = 0; i < _restitutions.length; i++) {
        if (_restitutions[i]['commercial'] == commercialNom &&
            _restitutions[i]['statut'] != 'Validé') {
          _restitutions[i]['statut'] = 'Validé';
          validatedCount++;
        }
      }

      // Valider toutes les pertes du commercial
      for (int i = 0; i < _pertes.length; i++) {
        if (_pertes[i]['commercial'] == commercialNom &&
            _pertes[i]['statut'] != 'Validé') {
          _pertes[i]['statut'] = 'Validé';
          validatedCount++;
        }
      }

      // Rafraîchir les listes
      _ventes.refresh();
      _restitutions.refresh();
      _pertes.refresh();

      Get.snackbar(
        '🎉 Validation complète effectuée',
        '$validatedCount activités validées pour $commercialNom',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.verified, color: Colors.white),
      );

      // TODO: Sauvegarder en base de données
      debugPrint(
          '🎉 Validation complète effectuée pour $commercialNom: $validatedCount activités');
    } catch (e) {
      Get.snackbar(
        '❌ Erreur',
        'Impossible de valider l\'activité complète',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      debugPrint('❌ Erreur validation complète: $e');
    }
  }
}
