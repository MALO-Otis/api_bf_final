import 'dart:async';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/vente_models.dart';
import 'package:flutter/material.dart';
import '../models/commercial_models.dart';
import '../services/commercial_service.dart';
import '../../../authentication/user_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/personnel/personnel_apisavana.dart';
import '../../caisse/models/transaction_commerciale.dart';
import '../../caisse/services/transaction_commerciale_service.dart';

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

/// Small widget that shows a countdown and cancels its timer on dispose.
class CountdownBox extends StatefulWidget {
  final DateTime expiry;
  final VoidCallback onCancel;

  const CountdownBox({Key? key, required this.expiry, required this.onCancel})
      : super(key: key);

  @override
  State<CountdownBox> createState() => _CountdownBoxState();
}

class _CountdownBoxState extends State<CountdownBox> {
  Timer? _ticker;
  late Duration _left;

  String format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h.toString().padLeft(2, '0')}h ${m.toString().padLeft(2, '0')}m';
  }

  @override
  void initState() {
    super.initState();
    _computeLeft();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _computeLeft();
      });
      if (_left.isNegative || _left == Duration.zero) {
        _ticker?.cancel();
      }
    });
  }

  void _computeLeft() {
    final left = widget.expiry.difference(DateTime.now());
    _left = left.isNegative ? Duration.zero : left;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.yellow[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hourglass_bottom, size: 16, color: Colors.orange),
          const SizedBox(width: 6),
          Text(format(_left), style: TextStyle(color: Colors.orange[800])),
          const SizedBox(width: 8),
          TextButton(
            onPressed: widget.onCancel,
            child: const Text('Annuler', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
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
  // Track running validation operations (single or complete) by commercial name or element id
  final RxMap<String, bool> _validationRunning = <String, bool>{}.obs;

  // Track active countdowns: map a key (commercial or element id) -> DateTime when validation expires
  final RxMap<String, DateTime> _validationExpiry = <String, DateTime>{}.obs;

  // Periodic refresh timer (cancel in dispose)
  Timer? _refreshTimer;

  // Duration before a validated card is hidden (5 hours as requested)
  final Duration _hideDelay = const Duration(hours: 5);

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadActivitesCommerciaux();

    // 🔧 CORRECTION : Écouter les changements du service commercial
    // Utiliser un Timer pour rafraîchir périodiquement
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && widget.commercialService.attributions.isNotEmpty) {
        _attributions.value = widget.commercialService.attributions;
      }
    });
  }

  /// Small countdown box showing time left until expiry and a cancel button

  @override
  void dispose() {
    // Cancel timers and controllers to avoid callbacks after dispose
    _refreshTimer?.cancel();
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
      final site = Get.find<UserSession>().site ?? '';
      if (site.isEmpty) {
        _ventes.value = [];
        return;
      }

      final snap = await FirebaseFirestore.instance
          .collection('transactions_commerciales')
          .where('site', isEqualTo: site)
          .get();

      // Diagnostic logs for ventes loader
      debugPrint(
          '🔎 [GestionCommerciauxTab] _loadVentes site="$site" snap.docs.length=${snap.docs.length}');
      if (snap.docs.isNotEmpty) {
        try {
          final first = snap.docs.first.data();
          debugPrint(
              '🔎 [GestionCommerciauxTab] _loadVentes first doc keys: ${first.keys.toList()}');
          final ventesRaw = first['ventes'];
          debugPrint(
              '🔎 [GestionCommerciauxTab] _loadVentes first.ventes type=${ventesRaw.runtimeType} valuePreview=${ventesRaw is List ? ventesRaw.length : ventesRaw}');
        } catch (e) {
          debugPrint(
              '🔎 [GestionCommerciauxTab] _loadVentes error reading first doc: $e');
        }
      }

      // If no docs found for this site, sample a few documents without the site filter to help diagnose
      if (snap.docs.isEmpty) {
        try {
          final sample = await FirebaseFirestore.instance
              .collection('transactions_commerciales')
              .limit(5)
              .get();
          debugPrint(
              '🔍 [GestionCommerciauxTab] Sample docs (no site filter) count=${sample.docs.length}');
          for (final d in sample.docs) {
            final m = d.data();
            debugPrint(
                '🔍 [GestionCommerciauxTab] sample doc id=${d.id} site=${m["site"]} keys=${m.keys.toList()}');
          }
        } catch (e) {
          debugPrint(
              '🔍 [GestionCommerciauxTab] error sampling transactions_commerciales: $e');
        }
      }

      final List<Map<String, dynamic>> ventesLoaded = [];
      for (final doc in snap.docs) {
        final data = doc.data();
        final tx = TransactionCommerciale.fromMap(data);
        for (final v in tx.ventes) {
          final produitDesc = v.produits.isNotEmpty
              ? '${v.produits.first.typeEmballage} - ${v.produits.first.numeroLot}'
              : '';
          // Ensure UI keys exist and are numeric to avoid passing null to NumberFormat
          final double prixUnitaire =
              v.produits.isNotEmpty ? v.produits.first.prixUnitaire : 0.0;
          final double totalMontant = v.montantTotal;
          final expiry = v.toMap()['validationExpiry'];
          DateTime? expiryDt;
          if (expiry is Timestamp) expiryDt = expiry.toDate();
          ventesLoaded.add({
            'id': v.id,
            'transactionId': tx.id,
            'commercial': tx.commercialNom,
            'client': v.clientNom,
            'produit': produitDesc,
            'quantite': v.produits.fold<int>(0, (s, p) => s + p.quantiteVendue),
            'prixUnitaire': prixUnitaire,
            'total': totalMontant,
            'montant': totalMontant,
            'date': v.date,
            'statut': v.valideAdmin ||
                    tx.statut == StatutTransactionCommerciale.valideeAdmin
                ? 'Validé'
                : 'En attente',
            'validationExpiry': expiryDt,
          });
        }
      }

      // Fallback: if transactions_commerciales has no docs for this site,
      // try reading the legacy per-site collections under Vente/{site}/ventes
      if (ventesLoaded.isEmpty) {
        try {
          debugPrint(
              '🔁 [GestionCommerciauxTab] Fallback: lecture de Vente/$site/ventes');
          final ventesSnap = await FirebaseFirestore.instance
              .collection('Vente')
              .doc(site)
              .collection('ventes')
              .get();
          for (final d in ventesSnap.docs) {
            final m = d.data();
            // Map Vente -> same map shape used above
            final vModel = Vente.fromMap(m);
            final produitDesc = vModel.produits.isNotEmpty
                ? '${vModel.produits.first.typeEmballage} - ${vModel.produits.first.numeroLot}'
                : '';
            final double prixUnitaireFallback = vModel.produits.isNotEmpty
                ? vModel.produits.first.prixUnitaire
                : 0.0;
            final double totalFallback = vModel.montantTotal;
            DateTime? expiryDt;
            final rawExpiry = m['validationExpiry'];
            if (rawExpiry is Timestamp) expiryDt = rawExpiry.toDate();
            ventesLoaded.add({
              'id': vModel.id,
              'transactionId': m['transactionId'] ?? '',
              'commercial': vModel.commercialNom,
              'client': vModel.clientNom,
              'produit': produitDesc,
              'quantite':
                  vModel.produits.fold<int>(0, (s, p) => s + p.quantiteVendue),
              'prixUnitaire': prixUnitaireFallback,
              'total': totalFallback,
              'montant': totalFallback,
              'date': vModel.dateVente,
              'statut': vModel.statut.name,
              'validationExpiry': expiryDt,
            });
          }
          debugPrint(
              '🔁 [GestionCommerciauxTab] Fallback ventes count=${ventesLoaded.length}');
        } catch (e) {
          debugPrint('🔁 [GestionCommerciauxTab] Erreur fallback ventes: $e');
        }
      }

      _ventes.value = ventesLoaded;
      // Populate _validationExpiry map from loaded ventes
      for (final v in ventesLoaded) {
        final key = v['commercial'] as String? ?? '';
        final expiry = v['validationExpiry'] as DateTime?;
        if (expiry != null && expiry.isAfter(DateTime.now())) {
          // Use commercial name as key so complete-validation hides the commercial
          _validationExpiry[key] = expiry;
        }
      }
      debugPrint(
          '💰 [GestionCommerciauxTab] ${_ventes.length} ventes chargées depuis Firestore');
    } catch (e) {
      debugPrint('❌ [GestionCommerciauxTab] Erreur chargement ventes: $e');
      _ventes.value = [];
    }
  }

  Future<void> _loadRestitutions() async {
    try {
      final site = Get.find<UserSession>().site ?? '';
      if (site.isEmpty) {
        _restitutions.value = [];
        return;
      }

      final snap = await FirebaseFirestore.instance
          .collection('transactions_commerciales')
          .where('site', isEqualTo: site)
          .get();

      // Diagnostic logs for restitutions loader
      debugPrint(
          '🔎 [GestionCommerciauxTab] _loadRestitutions site="$site" snap.docs.length=${snap.docs.length}');
      if (snap.docs.isNotEmpty) {
        try {
          final first = snap.docs.first.data();
          debugPrint(
              '🔎 [GestionCommerciauxTab] _loadRestitutions first doc keys: ${first.keys.toList()}');
          final restRaw = first['restitutions'];
          debugPrint(
              '🔎 [GestionCommerciauxTab] _loadRestitutions first.restitutions type=${restRaw.runtimeType} valuePreview=${restRaw is List ? restRaw.length : restRaw}');
        } catch (e) {
          debugPrint(
              '🔎 [GestionCommerciauxTab] _loadRestitutions error reading first doc: $e');
        }
      }

      if (snap.docs.isEmpty) {
        try {
          final sample = await FirebaseFirestore.instance
              .collection('transactions_commerciales')
              .limit(5)
              .get();
          debugPrint(
              '🔍 [GestionCommerciauxTab] Sample docs (no site filter) count=${sample.docs.length}');
          for (final d in sample.docs) {
            final m = d.data();
            debugPrint(
                '🔍 [GestionCommerciauxTab] sample doc id=${d.id} site=${m["site"]} keys=${m.keys.toList()}');
          }
        } catch (e) {
          debugPrint(
              '🔍 [GestionCommerciauxTab] error sampling transactions_commerciales: $e');
        }
      }

      final List<Map<String, dynamic>> restLoaded = [];
      for (final doc in snap.docs) {
        final data = doc.data();
        final tx = TransactionCommerciale.fromMap(data);
        for (final r in tx.restitutions) {
          DateTime? expiryDt;
          final rawExpiry = r.toMap()['validationExpiry'];
          if (rawExpiry is Timestamp) expiryDt = rawExpiry.toDate();
          restLoaded.add({
            'id': r.id,
            'transactionId': tx.id,
            'commercial': tx.commercialNom,
            'produit': r.numeroLot,
            'quantite': r.quantiteRestituee,
            'raison': r.motif,
            'date': r.date,
            'statut': r.valideAdmin ||
                    tx.statut == StatutTransactionCommerciale.valideeAdmin
                ? 'Acceptée'
                : 'En attente',
            'validationExpiry': expiryDt,
          });
        }
      }

      _restitutions.value = restLoaded;
      // Populate _validationExpiry from restitutions
      for (final r in restLoaded) {
        final key = r['commercial'] as String? ?? '';
        final expiry = r['validationExpiry'] as DateTime?;
        if (expiry != null && expiry.isAfter(DateTime.now())) {
          _validationExpiry[key] = expiry;
        }
      }
      debugPrint(
          '🔄 [GestionCommerciauxTab] ${_restitutions.length} restitutions chargées');
      // Fallback to Vente/{site}/restitutions if none found in transactions_commerciales
      if (restLoaded.isEmpty) {
        try {
          debugPrint(
              '🔁 [GestionCommerciauxTab] Fallback: lecture de Vente/$site/restitutions');
          final restSnap = await FirebaseFirestore.instance
              .collection('Vente')
              .doc(site)
              .collection('restitutions')
              .get();
          for (final d in restSnap.docs) {
            final m = d.data();
            final rModel = Restitution.fromMap(m);
            DateTime? expiryDt;
            final rawExpiry = m['validationExpiry'];
            if (rawExpiry is Timestamp) expiryDt = rawExpiry.toDate();
            restLoaded.add({
              'id': rModel.id,
              'transactionId': m['transactionId'] ?? '',
              'commercial': rModel.commercialNom,
              'produit': rModel.produits.isNotEmpty
                  ? rModel.produits.first.numeroLot
                  : '',
              'quantite': rModel.produits.isNotEmpty
                  ? rModel.produits.first.quantiteRestituee
                  : 0,
              'raison': rModel.motif,
              'date': rModel.dateRestitution,
              'statut': rModel.type.name,
              'validationExpiry': expiryDt,
            });
          }
          _restitutions.value = restLoaded;
          debugPrint(
              '🔁 [GestionCommerciauxTab] Fallback restitutions count=${restLoaded.length}');
        } catch (e) {
          debugPrint(
              '🔁 [GestionCommerciauxTab] Erreur fallback restitutions: $e');
        }
      }
    } catch (e) {
      debugPrint(
          '❌ [GestionCommerciauxTab] Erreur chargement restitutions: $e');
      _restitutions.value = [];
    }
  }

  Future<void> _loadPertes() async {
    try {
      final site = Get.find<UserSession>().site ?? '';
      if (site.isEmpty) {
        _pertes.value = [];
        return;
      }

      final snap = await FirebaseFirestore.instance
          .collection('transactions_commerciales')
          .where('site', isEqualTo: site)
          .get();

      // Diagnostic logs for pertes loader
      debugPrint(
          '🔎 [GestionCommerciauxTab] _loadPertes site="$site" snap.docs.length=${snap.docs.length}');
      if (snap.docs.isNotEmpty) {
        try {
          final first = snap.docs.first.data();
          debugPrint(
              '🔎 [GestionCommerciauxTab] _loadPertes first doc keys: ${first.keys.toList()}');
          final pertesRaw = first['pertes'];
          debugPrint(
              '🔎 [GestionCommerciauxTab] _loadPertes first.pertes type=${pertesRaw.runtimeType} valuePreview=${pertesRaw is List ? pertesRaw.length : pertesRaw}');
        } catch (e) {
          debugPrint(
              '🔎 [GestionCommerciauxTab] _loadPertes error reading first doc: $e');
        }
      }

      if (snap.docs.isEmpty) {
        try {
          final sample = await FirebaseFirestore.instance
              .collection('transactions_commerciales')
              .limit(5)
              .get();
          debugPrint(
              '🔍 [GestionCommerciauxTab] Sample docs (no site filter) count=${sample.docs.length}');
          for (final d in sample.docs) {
            final m = d.data();
            debugPrint(
                '🔍 [GestionCommerciauxTab] sample doc id=${d.id} site=${m["site"]} keys=${m.keys.toList()}');
          }
        } catch (e) {
          debugPrint(
              '🔍 [GestionCommerciauxTab] error sampling transactions_commerciales: $e');
        }
      }

      final List<Map<String, dynamic>> pertesLoaded = [];
      for (final doc in snap.docs) {
        final data = doc.data();
        final tx = TransactionCommerciale.fromMap(data);
        for (final p in tx.pertes) {
          pertesLoaded.add({
            'id': p.id,
            'transactionId': tx.id,
            'commercial': tx.commercialNom,
            'produit': p.numeroLot,
            'quantite': p.quantitePerdue,
            'raison': p.motif,
            'date': p.date,
            'statut': p.valideAdmin ||
                    tx.statut == StatutTransactionCommerciale.valideeAdmin
                ? 'Validée'
                : 'En attente',
          });
        }
      }

      _pertes.value = pertesLoaded;
      debugPrint(
          '📉 [GestionCommerciauxTab] ${_pertes.length} pertes chargées');
      // Fallback to Vente/{site}/pertes if none found in transactions_commerciales
      if (pertesLoaded.isEmpty) {
        try {
          debugPrint(
              '🔁 [GestionCommerciauxTab] Fallback: lecture de Vente/$site/pertes');
          final pertesSnap = await FirebaseFirestore.instance
              .collection('Vente')
              .doc(site)
              .collection('pertes')
              .get();
          for (final d in pertesSnap.docs) {
            final m = d.data();
            final pModel = Perte.fromMap(m);
            pertesLoaded.add({
              'id': pModel.id,
              'transactionId': m['transactionId'] ?? '',
              'commercial': pModel.commercialNom,
              'produit': pModel.produits.isNotEmpty
                  ? pModel.produits.first.numeroLot
                  : '',
              'quantite': pModel.produits.isNotEmpty
                  ? pModel.produits.first.quantitePerdue
                  : 0,
              'raison': pModel.motif,
              'date': pModel.datePerte,
              'statut': pModel.motif,
            });
          }
          _pertes.value = pertesLoaded;
          debugPrint(
              '🔁 [GestionCommerciauxTab] Fallback pertes count=${pertesLoaded.length}');
        } catch (e) {
          debugPrint('🔁 [GestionCommerciauxTab] Erreur fallback pertes: $e');
        }
      }
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

      // Filter out commercials whose expiry has passed (hide after expiry)
      final filtered = commerciaux.where((c) {
        if (!_validationExpiry.containsKey(c)) return true;
        final expiry = _validationExpiry[c]!;
        // if expiry is in the past, hide the commercial
        return DateTime.now().isBefore(expiry);
      }).toList();

      if (filtered.isEmpty) {
        return _buildEmptyState('Aucun commercial trouvé', Icons.people);
      }

      return ListView.builder(
        primary: false,
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final commercial = filtered[index];
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

          // If this commercial has an active expiry, show countdown and cancel
          if (_validationExpiry.containsKey(commercialNom))
            _buildCountdownBox(
              expiry: _validationExpiry[commercialNom]!,
              onCancel: () async {
                try {
                  // cancel all validated legacy items for this commercial by scanning legacy collections
                  final site = Get.find<UserSession>().site ?? '';
                  if (site.isNotEmpty) {
                    final venteSnap = await FirebaseFirestore.instance
                        .collection('Vente')
                        .doc(site)
                        .collection('ventes')
                        .where('commercialNom', isEqualTo: commercialNom)
                        .get();
                    for (final d in venteSnap.docs) {
                      final m = d.data();
                      final vid = d.id;
                      final tid = (m['transactionId'] ?? '') as String;
                      if (tid.trim().isEmpty) {
                        await TransactionCommercialeService.instance
                            .annulerLegacyValidation(
                                site: site,
                                elementType: 'vente',
                                elementId: vid);
                      }
                    }
                    // likewise restitutions and pertes
                    final restSnap = await FirebaseFirestore.instance
                        .collection('Vente')
                        .doc(site)
                        .collection('restitutions')
                        .where('commercialNom', isEqualTo: commercialNom)
                        .get();
                    for (final d in restSnap.docs) {
                      final m = d.data();
                      final rid = d.id;
                      final tid = (m['transactionId'] ?? '') as String;
                      if (tid.trim().isEmpty) {
                        await TransactionCommercialeService.instance
                            .annulerLegacyValidation(
                                site: site,
                                elementType: 'restitution',
                                elementId: rid);
                      }
                    }
                    final perteSnap = await FirebaseFirestore.instance
                        .collection('Vente')
                        .doc(site)
                        .collection('pertes')
                        .where('commercialNom', isEqualTo: commercialNom)
                        .get();
                    for (final d in perteSnap.docs) {
                      final m = d.data();
                      final pid = d.id;
                      final tid = (m['transactionId'] ?? '') as String;
                      if (tid.trim().isEmpty) {
                        await TransactionCommercialeService.instance
                            .annulerLegacyValidation(
                                site: site,
                                elementType: 'perte',
                                elementId: pid);
                      }
                    }
                  }
                } catch (e) {
                  debugPrint('❌ cancel complete validation failed: $e');
                } finally {
                  _validationExpiry.remove(commercialNom);
                  _ventes.refresh();
                  _restitutions.refresh();
                  _pertes.refresh();
                }
              },
            ),

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
                  elementId: vente['id'],
                  elementType: 'vente',
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
                  elementId: restitution['id'],
                  elementType: 'restitution',
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
                  elementId: perte['id'],
                  elementType: 'perte',
                )),
            const SizedBox(height: 16),
          ],

          // Bouton de validation complète
          const Divider(),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Obx(() {
              final running = _validationRunning[commercialNom] == true;
              final hasExpiry = _validationExpiry.containsKey(commercialNom);
              // If validation is running, show spinner and prevent action.
              if (running) {
                return ElevatedButton.icon(
                  onPressed: null,
                  icon: const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      )),
                  label: const Text('Validation en cours...',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }

              // If there's an active expiry (validated recently), lock the button
              if (hasExpiry) {
                return ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.lock, color: Colors.white),
                  label: const Text('Validation verrouillée',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }

              // Default: allow validation
              return ElevatedButton.icon(
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
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownBox({
    required DateTime expiry,
    required VoidCallback onCancel,
  }) {
    return CountdownBox(expiry: expiry, onCancel: onCancel);
  }

  Widget _buildAttributionsTab() {
    return Obx(() {
      if (_attributions.isEmpty) {
        return _buildEmptyState(
            'Aucune attribution trouvée', Icons.assignment_turned_in);
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _attributions.length,
        itemBuilder: (context, index) {
          final attribution = _attributions[index];
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
            .where((v) => v['commercial'] == _selectedCommercial.value)
            .toList();
      }
      if (ventesFiltrees.isEmpty) {
        return _buildEmptyState('Aucune vente trouvée', Icons.shopping_cart);
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
    String? elementId,
    String? elementType,
  }) {
    final isValidated = status == 'Validé';
    final keyId = elementId ?? title + '|' + subtitle + date.toIso8601String();
    final isRunning = _validationRunning[keyId] ?? false;
    final expiry =
        _validationExpiry[keyId] ?? _validationExpiry[elementId ?? ''];

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

          // Bouton de validation or spinner
          if (!isValidated)
            isRunning
                ? const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : TextButton.icon(
                    onPressed: () async {
                      try {
                        if (elementId != null)
                          _validationRunning[elementId] = true;
                        _validationRunning.refresh();
                        onValidate();
                      } finally {
                        if (elementId != null) {
                          _validationRunning.remove(elementId);
                          _validationRunning.refresh();
                        }
                      }
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Valider'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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

          // Per-element countdown + cancel if expiry exists
          if (expiry != null)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: _buildCountdownBox(
                expiry: expiry,
                onCancel: () async {
                  try {
                    final site = Get.find<UserSession>().site ?? '';
                    if (site.isNotEmpty &&
                        elementId != null &&
                        elementType != null) {
                      await TransactionCommercialeService.instance
                          .annulerLegacyValidation(
                              site: site,
                              elementType: elementType,
                              elementId: elementId);
                    }
                  } catch (e) {
                    debugPrint('❌ cancel validation failed: $e');
                    Get.snackbar(
                        'Erreur', 'Impossible d\'annuler la validation');
                  } finally {
                    if (elementId != null) _validationExpiry.remove(elementId);
                    _ventes.refresh();
                    _restitutions.refresh();
                    _pertes.refresh();
                  }
                },
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
              // Prevent double click
              if (_validationRunning[commercialNom] == true) return;
              Get.back();
              _performCompleteValidation(commercialNom);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Obx(() => _validationRunning[commercialNom] == true
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Validation...',
                          style: TextStyle(color: Colors.white))
                    ],
                  )
                : const Text('Valider Tout',
                    style: TextStyle(color: Colors.white))),
          ),
        ],
      ),
    );
  }

  /// Effectuer la validation d'une activité
  void _performValidation(String type, String id, String commercialNom) {
    // Use TransactionCommercialeService to validate an element (mirrors caissier flow)
    () async {
      debugPrint(
          '🔔 [_performValidation] start type=$type id=$id commercial=$commercialNom');
      try {
        final svc = TransactionCommercialeService.instance;
        String? transactionId;

        switch (type) {
          case 'vente':
            final index = _ventes.indexWhere((v) => v['id'] == id);
            if (index != -1) {
              transactionId = _ventes[index]['transactionId'] as String?;
            }
            break;
          case 'restitution':
            final index = _restitutions.indexWhere((r) => r['id'] == id);
            if (index != -1) {
              transactionId = _restitutions[index]['transactionId'] as String?;
            }
            break;
          case 'perte':
            final index = _pertes.indexWhere((p) => p['id'] == id);
            if (index != -1) {
              transactionId = _pertes[index]['transactionId'] as String?;
            }
            break;
        }

        if (transactionId != null && transactionId.isNotEmpty) {
          debugPrint(
              '➡️ [_performValidation] found transactionId=$transactionId for element $id');
          await svc.validerElement(
            transactionId: transactionId,
            elementType: type,
            elementId: id,
          );
          debugPrint(
              '✅ [_performValidation] svc.validerElement completed for transactionId=$transactionId elementId=$id');

          // Update local UI state
          switch (type) {
            case 'vente':
              final i = _ventes.indexWhere((v) => v['id'] == id);
              if (i != -1) {
                _ventes[i]['statut'] = 'Validé';
                _ventes.refresh();
              }
              break;
            case 'restitution':
              final i = _restitutions.indexWhere((r) => r['id'] == id);
              if (i != -1) {
                _restitutions[i]['statut'] = 'Acceptée';
                _restitutions.refresh();
              }
              break;
            case 'perte':
              final i = _pertes.indexWhere((p) => p['id'] == id);
              if (i != -1) {
                _pertes[i]['statut'] = 'Validée';
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

          // Refresh from server to ensure UI matches Firestore state
          unawaited(_loadActivitesCommerciaux());
        } else {
          // Fallback: try to validate the legacy element directly (authoritative write)
          debugPrint(
              '⚠️ [_performValidation] Transaction ID introuvable pour element $id (commercial=$commercialNom) - attempting legacy validation');
          try {
            final site = Get.find<UserSession>().site ?? '';
            if (site.isNotEmpty) {
              await svc.validerLegacyElement(
                site: site,
                elementType: type,
                elementId: id,
                validePar: Get.find<UserSession>().nom ??
                    Get.find<UserSession>().email,
              );
              // Update local UI state
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
                    _restitutions[index]['statut'] = 'Acceptée';
                    _restitutions.refresh();
                  }
                  break;
                case 'perte':
                  final index = _pertes.indexWhere((p) => p['id'] == id);
                  if (index != -1) {
                    _pertes[index]['statut'] = 'Validée';
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
              // Refresh from server
              unawaited(_loadActivitesCommerciaux());
            } else {
              // No site -> fallback to local update
              Get.snackbar('⚠️',
                  'Transaction introuvable — validation locale appliquée');
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
                    _restitutions[index]['statut'] = 'Acceptée';
                    _restitutions.refresh();
                  }
                  break;
                case 'perte':
                  final index = _pertes.indexWhere((p) => p['id'] == id);
                  if (index != -1) {
                    _pertes[index]['statut'] = 'Validée';
                    _pertes.refresh();
                  }
                  break;
              }
            }
          } catch (e) {
            debugPrint('❌ [_performValidation] validerLegacyElement error: $e');
            Get.snackbar('❌', 'Impossible de valider la transaction');
          }
        }
      } catch (e) {
        debugPrint('❌ Erreur validation $type: $e');
        Get.snackbar('❌ Erreur', 'Impossible de valider la $type');
      }
    }();
  }

  /// Effectuer la validation complète
  void _performCompleteValidation(String commercialNom) {
    // Validate all pending activities for a commercial by validating their transactions
    () async {
      // mark running for this commercial
      _validationRunning[commercialNom] = true;
      _validationRunning.refresh();
      try {
        final svc = TransactionCommercialeService.instance;
        final user = Get.find<UserSession>();

        // Collect unique transaction IDs for this commercial
        final Set<String> txIds = {};
        for (final v in _ventes) {
          final tid = v['transactionId'] as String?;
          if (v['commercial'] == commercialNom &&
              tid != null &&
              tid.trim().isNotEmpty) {
            txIds.add(tid);
          }
        }
        for (final r in _restitutions) {
          final tid = r['transactionId'] as String?;
          if (r['commercial'] == commercialNom &&
              tid != null &&
              tid.trim().isNotEmpty) {
            txIds.add(tid);
          }
        }
        for (final p in _pertes) {
          final tid = p['transactionId'] as String?;
          if (p['commercial'] == commercialNom &&
              tid != null &&
              tid.trim().isNotEmpty) {
            txIds.add(tid);
          }
        }

        int validatedCount = 0;
        // Debug: show what we collected
        debugPrint(
            '🔍 [_performCompleteValidation] initial collected txIds: ${txIds.toList()}');

        // If no transaction IDs were collected from local items, try a series
        // of fallback searches to locate canonical transaction docs or
        // transactionId fields stored in legacy per-site collections.
        if (txIds.isEmpty) {
          final site = Get.find<UserSession>().site ?? '';
          debugPrint(
              '🔍 [_performCompleteValidation] txIds empty, attempting broadened fallbacks for site="$site" commercial="$commercialNom"');

          if (site.isNotEmpty) {
            // 1) Try to derive commercialId from attributions cache and query by it
            try {
              String commercialId = '';
              try {
                final match = _attributions.firstWhere(
                    (a) => a.commercialNom == commercialNom,
                    orElse: () => AttributionPartielle(
                        id: '',
                        lotId: '',
                        commercialId: '',
                        commercialNom: '',
                        quantiteAttribuee: 0,
                        valeurUnitaire: 0,
                        valeurTotale: 0,
                        dateAttribution: DateTime.now(),
                        gestionnaire: '',
                        contenanceKg: 0,
                        dateConditionnement: DateTime.now(),
                        numeroLot: '',
                        predominanceFlorale: '',
                        prixUnitaire: 0,
                        quantiteInitiale: 0,
                        quantiteRestante: 0,
                        searchableText: '',
                        siteOrigine: '',
                        statut: '',
                        typeEmballage: '',
                        lastUpdate: DateTime.now()));
                commercialId = match.commercialId;
              } catch (_) {}

              if (commercialId.isNotEmpty) {
                debugPrint(
                    '🔎 [_performCompleteValidation] found commercialId="$commercialId" from attributions, querying transactions_commerciales by commercialId');
                final snapById = await FirebaseFirestore.instance
                    .collection('transactions_commerciales')
                    .where('site', isEqualTo: site)
                    .where('commercialId', isEqualTo: commercialId)
                    .get();
                debugPrint(
                    '🔍 [_performCompleteValidation] query by commercialId returned ${snapById.docs.length} docs');
                for (final d in snapById.docs) {
                  final id = d.id;
                  debugPrint(
                      '   - found tx doc id=${id} keys=${d.data().keys.toList()}');
                  if (id.trim().isNotEmpty) txIds.add(id);
                }
              }
            } catch (e) {
              debugPrint(
                  '⚠️ [_performCompleteValidation] error querying by commercialId: $e');
            }

            // 2) Try query by commercialNom (existing fallback)
            if (txIds.isEmpty) {
              try {
                debugPrint(
                    '🔍 [_performCompleteValidation] querying transactions_commerciales by commercialNom');
                final snapByName = await FirebaseFirestore.instance
                    .collection('transactions_commerciales')
                    .where('site', isEqualTo: site)
                    .where('commercialNom', isEqualTo: commercialNom)
                    .get();
                debugPrint(
                    '🔍 [_performCompleteValidation] query by commercialNom returned ${snapByName.docs.length} docs');
                for (final d in snapByName.docs) {
                  final id = d.id;
                  debugPrint(
                      '   - found tx doc id=${id} keys=${d.data().keys.toList()}');
                  if (id.trim().isNotEmpty) txIds.add(id);
                }
              } catch (e) {
                debugPrint(
                    '⚠️ [_performCompleteValidation] error querying by commercialNom: $e');
              }
            }

            // 3) If still empty, scan legacy per-site collections for transactionId fields
            if (txIds.isEmpty) {
              try {
                debugPrint(
                    '🔎 [_performCompleteValidation] scanning legacy Vente/$site collections for transactionId fields');

                final venteSnap = await FirebaseFirestore.instance
                    .collection('Vente')
                    .doc(site)
                    .collection('ventes')
                    .where('commercialNom', isEqualTo: commercialNom)
                    .get();
                debugPrint(
                    '🔍 [_performCompleteValidation] Vente/$site/ventes matched ${venteSnap.docs.length} docs');
                for (final d in venteSnap.docs) {
                  final m = d.data();
                  final tid = (m['transactionId'] ?? '') as String;
                  debugPrint('   - vente doc id=${d.id} transactionId=${tid}');
                  if (tid.trim().isNotEmpty) txIds.add(tid);
                }

                final restSnap = await FirebaseFirestore.instance
                    .collection('Vente')
                    .doc(site)
                    .collection('restitutions')
                    .where('commercialNom', isEqualTo: commercialNom)
                    .get();
                debugPrint(
                    '🔍 [_performCompleteValidation] Vente/$site/restitutions matched ${restSnap.docs.length} docs');
                for (final d in restSnap.docs) {
                  final m = d.data();
                  final tid = (m['transactionId'] ?? '') as String;
                  debugPrint(
                      '   - restitution doc id=${d.id} transactionId=${tid}');
                  if (tid.trim().isNotEmpty) txIds.add(tid);
                }

                final pertesSnap = await FirebaseFirestore.instance
                    .collection('Vente')
                    .doc(site)
                    .collection('pertes')
                    .where('commercialNom', isEqualTo: commercialNom)
                    .get();
                debugPrint(
                    '🔍 [_performCompleteValidation] Vente/$site/pertes matched ${pertesSnap.docs.length} docs');
                for (final d in pertesSnap.docs) {
                  final m = d.data();
                  final tid = (m['transactionId'] ?? '') as String;
                  debugPrint('   - perte doc id=${d.id} transactionId=${tid}');
                  if (tid.trim().isNotEmpty) txIds.add(tid);
                }
              } catch (e) {
                debugPrint(
                    '⚠️ [_performCompleteValidation] error scanning legacy collections: $e');
              }

              // If still no canonical txIds, validate legacy docs directly
              if (txIds.isEmpty) {
                try {
                  debugPrint(
                      '🔁 [_performCompleteValidation] No txIds found, will validate legacy documents directly for commercial=$commercialNom');

                  final venteSnap2 = await FirebaseFirestore.instance
                      .collection('Vente')
                      .doc(site)
                      .collection('ventes')
                      .where('commercialNom', isEqualTo: commercialNom)
                      .get();
                  for (final d in venteSnap2.docs) {
                    final m = d.data();
                    final vid = d.id;
                    // If this legacy doc has a transactionId, skip (it will be handled above)
                    final tid = (m['transactionId'] ?? '') as String;
                    if (tid.trim().isEmpty) {
                      await svc.validerLegacyElement(
                        site: site,
                        elementType: 'vente',
                        elementId: vid,
                        validePar: Get.find<UserSession>().nom ??
                            Get.find<UserSession>().email,
                      );
                      validatedCount++;
                      // register expiry for this commercial (5h)
                      _validationExpiry[commercialNom] =
                          DateTime.now().add(_hideDelay);
                      _validationExpiry.refresh();
                    }
                  }

                  final restSnap2 = await FirebaseFirestore.instance
                      .collection('Vente')
                      .doc(site)
                      .collection('restitutions')
                      .where('commercialNom', isEqualTo: commercialNom)
                      .get();
                  for (final d in restSnap2.docs) {
                    final m = d.data();
                    final rid = d.id;
                    final tid = (m['transactionId'] ?? '') as String;
                    if (tid.trim().isEmpty) {
                      await svc.validerLegacyElement(
                        site: site,
                        elementType: 'restitution',
                        elementId: rid,
                        validePar: Get.find<UserSession>().nom ??
                            Get.find<UserSession>().email,
                      );
                      validatedCount++;
                      _validationExpiry[commercialNom] =
                          DateTime.now().add(_hideDelay);
                      _validationExpiry.refresh();
                    }
                  }

                  final perteSnap2 = await FirebaseFirestore.instance
                      .collection('Vente')
                      .doc(site)
                      .collection('pertes')
                      .where('commercialNom', isEqualTo: commercialNom)
                      .get();
                  for (final d in perteSnap2.docs) {
                    final m = d.data();
                    final pid = d.id;
                    final tid = (m['transactionId'] ?? '') as String;
                    if (tid.trim().isEmpty) {
                      await svc.validerLegacyElement(
                        site: site,
                        elementType: 'perte',
                        elementId: pid,
                        validePar: Get.find<UserSession>().nom ??
                            Get.find<UserSession>().email,
                      );
                      validatedCount++;
                      _validationExpiry[commercialNom] =
                          DateTime.now().add(_hideDelay);
                      _validationExpiry.refresh();
                    }
                  }
                } catch (e) {
                  debugPrint(
                      '⚠️ [_performCompleteValidation] error validating legacy docs directly: $e');
                }
              }
            }
          } // end if site.isNotEmpty
        }

        debugPrint(
            '🔁 [_performCompleteValidation] final txIds to validate: ${txIds.toList()}');
        for (final txId in txIds) {
          try {
            debugPrint(
                '➡️ [_performCompleteValidation] validating txId=$txId by ${user.nom ?? user.email}');
            await svc.validerTransaction(
                txId, user.nom ?? user.email ?? 'Gestionnaire');
            validatedCount++;
            // register expiry for this commercial (5h) when canonical tx validated
            _validationExpiry[commercialNom] = DateTime.now().add(_hideDelay);
            _validationExpiry.refresh();
            debugPrint('✅ [_performCompleteValidation] validated txId=$txId');
          } catch (e) {
            debugPrint(
                '⚠️ [_performCompleteValidation] Echec validation transaction $txId: $e');
          }
        }

        // Update local UI statuses optimistically
        for (int i = 0; i < _ventes.length; i++) {
          if (_ventes[i]['commercial'] == commercialNom)
            _ventes[i]['statut'] = 'Validé';
        }
        for (int i = 0; i < _restitutions.length; i++) {
          if (_restitutions[i]['commercial'] == commercialNom)
            _restitutions[i]['statut'] = 'Acceptée';
        }
        for (int i = 0; i < _pertes.length; i++) {
          if (_pertes[i]['commercial'] == commercialNom)
            _pertes[i]['statut'] = 'Validée';
        }
        _ventes.refresh();
        _restitutions.refresh();
        _pertes.refresh();

        Get.snackbar(
          '🎉 Validation complète effectuée',
          '$validatedCount transactions validées pour $commercialNom',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.verified, color: Colors.white),
        );

        // Start a timer to hide the commercial card after expiry if set
        if (_validationExpiry.containsKey(commercialNom)) {
          final expiry = _validationExpiry[commercialNom]!;
          // schedule a delayed task to remove the commercial from view after expiry
          Future.delayed(expiry.difference(DateTime.now()), () {
            try {
              // Remove expiry entry and force a refresh; the card building logic should hide cards with expired validations
              _validationExpiry.remove(commercialNom);
              _ventes.refresh();
              _restitutions.refresh();
              _pertes.refresh();
            } catch (_) {}
          });
        }

        // mark not running
        _validationRunning[commercialNom] = false;
        _validationRunning.refresh();

        // Refresh full activities from Firestore to reflect authoritative state
        unawaited(_loadActivitesCommerciaux());
      } catch (e) {
        Get.snackbar(
          '❌ Erreur',
          'Impossible de valider l\'activité complète',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        debugPrint('❌ Erreur validation complète: $e');
      }
    }();
  }
}
