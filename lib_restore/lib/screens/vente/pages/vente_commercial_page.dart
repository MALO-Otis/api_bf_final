import 'dart:typed_data';
import 'package:get/get.dart';
import 'perte_form_modal.dart';
import 'package:intl/intl.dart';
import '../utils/receipt_pdf.dart';
import '../models/vente_models.dart';
import 'restitution_form_modal.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'vente_form_modal_complete.dart';
import '../services/vente_service.dart';
import '../models/commercial_models.dart';
import '../../../utils/smart_appbar.dart';
import '../../../authentication/user_session.dart';
import '../../../utils/platform_download_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../vente/controllers/espace_commercial_controller.dart';
// import 'dart:html' as html; // Retiré: non supporté desktop
// ignore: avoid_web_libraries_in_flutter

/// 🛒 PAGE DE VENTE POUR LES COMMERCIAUX
///
/// Interface pour les commerciaux : ventes, restitutions, pertes

// import '../services/vente_service.dart'; // Service direct inutilisé (flux temps réel)

class VenteCommercialPage extends StatefulWidget {
  const VenteCommercialPage({super.key});

  @override
  State<VenteCommercialPage> createState() => _VenteCommercialPageState();
}

class _VenteCommercialPageState extends State<VenteCommercialPage>
    with TickerProviderStateMixin {
  final UserSession _userSession = Get.find<UserSession>();

  // Ancienne liste locale remplacée par les flux temps réel du controller
  bool _isLoading = false;

  // Onglets
  late TabController _tabController;

  late EspaceCommercialController _espaceCtrl;

  @override
  void initState() {
    super.initState();
    // Initialisation / récupération du controller central (temps réel)
    _espaceCtrl = Get.isRegistered<EspaceCommercialController>()
        ? Get.find<EspaceCommercialController>()
        : Get.put(EspaceCommercialController(), permanent: true);
    _tabController = TabController(length: 4, vsync: this);

    // 🎯 CHARGER LES VRAIES ATTRIBUTIONS
    _loadAttributionsData();
  }

  Future<void> _loadAttributionsData() async {
    setState(() => _isLoading = true);
    try {
      await _espaceCtrl.ensureAttributionsLoaded(forceRefresh: true);
      debugPrint('✅ Attributions chargées dans VenteCommercialPage');
    } catch (e) {
      debugPrint('❌ Erreur chargement attributions: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  // _loadData supprimé (remplacé par les listeners temps réel)

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final commercialNom = _userSession.email?.split('@')[0] ?? 'Commercial';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: SmartAppBar(
        title: "Espace Commercial - $commercialNom",
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
                _buildRestitutionsTab(isMobile),
                _buildPertesTab(isMobile),
              ],
            ),
    );
  }

  // Variables de tri et filtrage
  final RxString _sortBy = 'date_desc'.obs;
  final RxString _filterByType = 'tous'.obs;
  final RxString _filterByStatus = 'tous'.obs;
  final RxDouble _minValue = 0.0.obs;
  final RxDouble _maxValue = 1000000.0.obs;

  // ===== Interface ATTRIBUTIONS avec tri avancé =====
  Widget _buildPrelevementsTab(bool isMobile) {
    return Obx(() {
      // 🎯 UTILISER LES VRAIES ATTRIBUTIONS au lieu des prélèvements
      final attributions = _espaceCtrl.attributions;

      debugPrint(
          '🔍 _buildPrelevementsTab: ${attributions.length} attributions disponibles');

      if (attributions.isEmpty) {
        return ListView(
          children: [
            // Options de tri même si vide - maintenant dans le scroll
            _buildSortingOptions(isMobile),
            // Loading indicator ou état vide
            if (_isLoading)
              Container(
                height: MediaQuery.of(context).size.height * 0.6,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.purple),
                      ),
                      SizedBox(height: 16),
                      Text('Chargement des attributions...'),
                    ],
                  ),
                ),
              )
            else
              Container(
                height: MediaQuery.of(context).size.height * 0.6,
                child: _buildEmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'Aucune attribution dans cette section !',
                  message:
                      'Contactez votre gestionnaire commercial pour obtenir des produits.',
                ),
              ),
          ],
        );
      }

      // Appliquer filtres et tri
      final filtered = _applyFiltersAndSort(attributions);

      final valeurTotale =
          filtered.fold<double>(0, (s, a) => s + a.valeurTotale);
      final quantiteTotale =
          filtered.fold<int>(0, (s, a) => s + a.quantiteAttribuee);

      // Utiliser un seul ListView pour que tout défile ensemble
      return ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Options de tri et filtrage
          _buildSortingOptions(isMobile),

          // Statistiques rapides - maintenant dans le scroll
          _buildQuickStats(valeurTotale, quantiteTotale, filtered.length),

          // Liste filtrée et triée - plus besoin d'Expanded
          ...filtered.map(
              (attribution) => _buildAttributionCard(attribution, isMobile)),
        ],
      );
    });
  }

  /// Appliquer filtres et tri sur les attributions
  List<AttributionPartielle> _applyFiltersAndSort(
      List<AttributionPartielle> attributions) {
    var filtered = attributions.where((attribution) {
      // Filtre par type d'emballage
      if (_filterByType.value != 'tous' &&
          attribution.typeEmballage != _filterByType.value) {
        return false;
      }

      // Filtre par valeur
      if (attribution.valeurTotale < _minValue.value ||
          attribution.valeurTotale > _maxValue.value) {
        return false;
      }

      return true;
    }).toList();

    // Appliquer le tri
    switch (_sortBy.value) {
      case 'date_asc':
        filtered.sort((a, b) => a.dateAttribution.compareTo(b.dateAttribution));
        break;
      case 'date_desc':
        filtered.sort((a, b) => b.dateAttribution.compareTo(a.dateAttribution));
        break;
      case 'valeur_asc':
        filtered.sort((a, b) => a.valeurTotale.compareTo(b.valeurTotale));
        break;
      case 'valeur_desc':
        filtered.sort((a, b) => b.valeurTotale.compareTo(a.valeurTotale));
        break;
      case 'quantite_asc':
        filtered
            .sort((a, b) => a.quantiteAttribuee.compareTo(b.quantiteAttribuee));
        break;
      case 'quantite_desc':
        filtered
            .sort((a, b) => b.quantiteAttribuee.compareTo(a.quantiteAttribuee));
        break;
      case 'produit_asc':
        filtered.sort((a, b) => a.typeEmballage.compareTo(b.typeEmballage));
        break;
      case 'produit_desc':
        filtered.sort((a, b) => b.typeEmballage.compareTo(a.typeEmballage));
        break;
    }

    return filtered;
  }

  /// Widget des options de tri et filtrage
  Widget _buildSortingOptions(bool isMobile) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          LayoutBuilder(builder: (context, constraints) {
            final narrow = constraints.maxWidth < 420;
            final resetBtn = TextButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(narrow ? 'Réinit.' : 'Réinitialiser'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.purple[600],
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
                minimumSize: const Size(0, 36),
              ),
            );

            return Row(
              children: [
                Icon(Icons.tune, color: Colors.purple[600], size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Options de Tri & Filtrage',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                resetBtn,
              ],
            );
          }),

          const SizedBox(height: 16),

          if (isMobile)
            _buildMobileSortingOptions()
          else
            _buildDesktopSortingOptions(),
        ],
      ),
    );
  }

  /// Options de tri pour mobile (vertical)
  Widget _buildMobileSortingOptions() {
    return Column(
      children: [
        // Tri par
        _buildSortDropdown(),
        const SizedBox(height: 12),

        // Filtre par type
        _buildTypeFilter(),
        const SizedBox(height: 12),

        // Filtre par valeur
        _buildValueRangeFilter(),
      ],
    );
  }

  /// Options de tri pour desktop (horizontal)
  Widget _buildDesktopSortingOptions() {
    return Row(
      children: [
        // Tri par
        Expanded(child: _buildSortDropdown()),
        const SizedBox(width: 16),

        // Filtre par type
        Expanded(child: _buildTypeFilter()),
        const SizedBox(width: 16),

        // Filtre par valeur
        Expanded(flex: 2, child: _buildValueRangeFilter()),
      ],
    );
  }

  /// Dropdown de tri
  Widget _buildSortDropdown() {
    return Obx(() {
      final isVerySmall = MediaQuery.of(Get.context!).size.width < 380;
      // Libellés compacts pour écrans étroits
      final items = [
        (
          'date_desc',
          isVerySmall ? '📅 Récent → Anc.' : '📅 Date (récent → ancien)'
        ),
        (
          'date_asc',
          isVerySmall ? '📅 Anc. → Récent' : '📅 Date (ancien → récent)'
        ),
        (
          'valeur_desc',
          isVerySmall ? '💰 Valeur ↓' : '💰 Valeur (élevée → faible)'
        ),
        (
          'valeur_asc',
          isVerySmall ? '💰 Valeur ↑' : '💰 Valeur (faible → élevée)'
        ),
        (
          'quantite_desc',
          isVerySmall ? '📦 Qté ↓' : '📦 Quantité (élevée → faible)'
        ),
        (
          'quantite_asc',
          isVerySmall ? '📦 Qté ↑' : '📦 Quantité (faible → élevée)'
        ),
        ('produit_asc', isVerySmall ? '🏷️ Prod A→Z' : '🏷️ Produit (A → Z)'),
        ('produit_desc', isVerySmall ? '🏷️ Prod Z→A' : '🏷️ Produit (Z → A)'),
      ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trier par',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: _sortBy.value,
            isDense: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: items
                .map(
                  (t) => DropdownMenuItem(
                    value: t.$1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(
                        t.$2,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) _sortBy.value = value;
            },
          ),
        ],
      );
    });
  }

  /// Filtre par type de produit
  Widget _buildTypeFilter() {
    return Obx(() {
      // Obtenir les types uniques depuis les attributions
      final types = _espaceCtrl.attributions
          .map((a) => a.typeEmballage)
          .toSet()
          .toList()
        ..sort();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Type de produit',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: _filterByType.value,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              const DropdownMenuItem(
                  value: 'tous', child: Text('🔍 Tous les types')),
              ...types.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text('🏷️ $type'),
                  )),
            ],
            onChanged: (value) {
              if (value != null) _filterByType.value = value;
            },
          ),
        ],
      );
    });
  }

  /// Filtre par plage de valeur
  Widget _buildValueRangeFilter() {
    return Obx(() {
      final maxValueInData = _espaceCtrl.attributions.isEmpty
          ? 1000000.0
          : _espaceCtrl.attributions
              .map((a) => a.valeurTotale)
              .reduce((a, b) => a > b ? a : b);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Plage de valeur (FCFA)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              Text(
                '${NumberFormat.currency(locale: 'fr_FR', symbol: '').format(_minValue.value)} - ${NumberFormat.currency(locale: 'fr_FR', symbol: '').format(_maxValue.value)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.purple[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: RangeValues(
              // Clamp et normalisation pour éviter les assertions Flutter
              _minValue.value.clamp(0, maxValueInData - 0.0001),
              _maxValue.value.clamp(0, maxValueInData),
            ),
            min: 0,
            max: maxValueInData <= 0 ? 1 : maxValueInData,
            divisions: 20,
            activeColor: Colors.purple[600],
            onChanged: (RangeValues values) {
              double start = values.start;
              double end = values.end;
              // Garantir l'ordre et les bornes
              if (end < start) {
                final tmp = start;
                start = end;
                end = tmp;
              }
              // Empêcher une plage vide totale (Flutter assertion quand max==min)
              if (maxValueInData <= 0) {
                start = 0;
                end = 1; // plage minimale artificielle
              }
              // Appliquer clamp final
              _minValue.value = start.clamp(0, maxValueInData);
              _maxValue.value = end.clamp(0, maxValueInData);
            },
          ),
        ],
      );
    });
  }

  /// Statistiques rapides
  Widget _buildQuickStats(
      double valeurTotale, int quantiteTotale, int nombreItems) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[600]!, Colors.purple[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('📦', '$nombreItems', 'Articles'),
          ),
          Container(width: 1, height: 30, color: Colors.white.withOpacity(0.3)),
          Expanded(
            child: _buildStatItem('🔢', '$quantiteTotale', 'Quantité'),
          ),
          Container(width: 1, height: 30, color: Colors.white.withOpacity(0.3)),
          Expanded(
            child: _buildStatItem(
                '💰',
                NumberFormat.currency(locale: 'fr_FR', symbol: '')
                    .format(valeurTotale),
                'FCFA'),
          ),
        ],
      ),
    );
  }

  /// Item de statistique
  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  /// Réinitialiser les filtres
  void _resetFilters() {
    _sortBy.value = 'date_desc';
    _filterByType.value = 'tous';
    _filterByStatus.value = 'tous';
    _minValue.value = 0.0;
    _maxValue.value = 1000000.0;

    Get.snackbar(
      '🔄 Filtres réinitialisés',
      'Tous les filtres ont été remis à zéro',
      backgroundColor: Colors.purple[600],
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  /// 🎯 NOUVEAU HEADER pour les attributions
  // ignore: unused_element
  Widget _buildAttributionsHeader(bool isMobile, int nombreAttributions,
      double valeurTotale, int quantiteTotale) {
    return Container(
      margin: EdgeInsets.all(isMobile ? 16 : 24),
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF9C27B0).withOpacity(.28),
                blurRadius: 18,
                offset: const Offset(0, 8))
          ]),
      child: Column(
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.18),
                  borderRadius: BorderRadius.circular(16)),
              child: const Text('🎯', style: TextStyle(fontSize: 32)),
            ),
            const SizedBox(width: 18),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Mes Attributions',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 18 : 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Produits attribués par le gestionnaire commercial',
                      style: TextStyle(
                          color: Colors.white.withOpacity(.9),
                          fontSize: isMobile ? 12 : 14))
                ]))
          ]),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(
                child: _prelevStatCard('Attributions',
                    nombreAttributions.toString(), Icons.assignment, isMobile)),
            SizedBox(width: isMobile ? 12 : 16),
            Expanded(
                child: _prelevStatCard(
                    'Valeur totale',
                    VenteUtils.formatPrix(valeurTotale),
                    Icons.payments,
                    isMobile)),
            SizedBox(width: isMobile ? 12 : 16),
            Expanded(
                child: _prelevStatCard('Quantité', quantiteTotale.toString(),
                    Icons.inventory_2, isMobile)),
          ])
        ],
      ),
    );
  }

  Widget _prelevStatCard(
      String titre, String valeur, IconData icone, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(.22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(.25))),
      child: Column(children: [
        Icon(icone, color: Colors.white, size: isMobile ? 22 : 26),
        SizedBox(height: isMobile ? 4 : 8),
        Text(valeur,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 12 : 16)),
        Text(titre,
            style:
                TextStyle(color: Colors.white70, fontSize: isMobile ? 9 : 11))
      ]),
    );
  }

  // ignore: unused_element
  Widget _buildPrelevementLegacyCard(Prelevement prelevement, bool isMobile) {
    final dyn = _espaceCtrl.prelevementStatutsDynamiques[prelevement.id] ??
        prelevement.statut;
    final color = _statusColor(dyn);
    return Container(
      margin: EdgeInsets.only(
          left: isMobile ? 16 : 24, right: isMobile ? 16 : 24, bottom: 16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.08),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ]),
      child: Column(children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [color.withOpacity(.10), color.withOpacity(.04)]),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20))),
          child: Row(children: [
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: color.withOpacity(.12),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.shopping_bag,
                    color: color, size: isMobile ? 22 : 24)),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Prélèvement ${prelevement.id.split('_').last}',
                      style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800)),
                  const SizedBox(height: 4),
                  Text(
                      DateFormat('dd/MM/yyyy à HH:mm')
                          .format(prelevement.datePrelevement),
                      style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey.shade600))
                ])),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(12)),
                child: Text(_labelStatut(dyn),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)))
          ]),
        ),
        Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Column(children: [
            Row(children: [
              Expanded(
                  child: _infoCol(
                      'Produits',
                      prelevement.produits.length.toString(),
                      Icons.inventory_2,
                      Colors.blue,
                      isMobile)),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              Expanded(
                  child: _infoCol(
                      'Valeur',
                      VenteUtils.formatPrix(prelevement.valeurTotale),
                      Icons.text_fields,
                      Colors.green,
                      isMobile)),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              Expanded(
                  child: _infoCol('Gestionnaire', prelevement.magazinierNom,
                      Icons.person, Colors.orange, isMobile)),
            ]),
            if (prelevement.observations != null) ...[
              const SizedBox(height: 16),
              Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200)),
                  child: Text('💬 ${prelevement.observations!}',
                      style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic)))
            ],
            const SizedBox(height: 16),
            if (dyn == StatutPrelevement.enCours ||
                dyn == StatutPrelevement.partiel)
              Row(children: [
                Expanded(
                    child: ElevatedButton.icon(
                        onPressed: () => _showVenteModal(prelevement),
                        icon: const Icon(Icons.point_of_sale),
                        label: const Text('Vendre'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white))),
                const SizedBox(width: 8),
                Expanded(
                    child: ElevatedButton.icon(
                        onPressed: () => _showRestitutionModal(prelevement),
                        icon: const Icon(Icons.undo),
                        label: const Text('Restituer'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white))),
                const SizedBox(width: 8),
                Expanded(
                    child: ElevatedButton.icon(
                        onPressed: () => _showPerteModal(prelevement),
                        icon: const Icon(Icons.warning),
                        label: const Text('Perte'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white))),
              ])
          ]),
        )
      ]),
    );
  }

  Widget _infoCol(
      String label, String value, IconData icon, Color color, bool isMobile) {
    return Column(children: [
      Icon(icon, color: color, size: isMobile ? 16 : 20),
      const SizedBox(height: 4),
      Text(value,
          style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800)),
      Text(label,
          style: TextStyle(
              fontSize: isMobile ? 10 : 12, color: Colors.grey.shade600))
    ]);
  }

  Color _statusColor(StatutPrelevement s) {
    switch (s) {
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

  // ===== Ancienne vue produits restants (optionnelle) =====
  // Ancienne vue "produits restants" retirée (peut être réintroduite si besoin)

  String _labelStatut(StatutPrelevement s) {
    switch (s) {
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
  // Fin helpers statut prélèvement

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

  // Anciennes sections prélèvements complètes supprimées (remplacées par _buildPrelevementsRestantsTab)

  Widget _buildVenteTab(bool isMobile) {
    return Obx(() {
      final ventes = _espaceCtrl.ventes; // données temps réel
      if (ventes.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('Aucune vente enregistrée',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              Text(
                'Cliquez sur Vendre dans un prélèvement pour enregistrer la première vente',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      final ventesTriees = ventes.toList()
        ..sort((a, b) => b.dateVente.compareTo(a.dateVente));

      double chiffreAffaires = 0;
      int produitsTotal = 0;
      for (final v in ventesTriees) {
        chiffreAffaires += v.montantTotal;
        produitsTotal +=
            v.produits.fold<int>(0, (s, p) => s + p.quantiteVendue);
      }

      return Column(
        children: [
          _buildHeaderVentes(
              isMobile, chiffreAffaires, produitsTotal, ventesTriees.length),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(isMobile ? 12 : 20),
              itemCount: ventesTriees.length,
              itemBuilder: (ctx, i) =>
                  _buildVenteCard(ventesTriees[i], isMobile),
            ),
          ),
        ],
      );
    });
  }

  // === ONGLET RESTITUTIONS ===
  Widget _buildRestitutionsTab(bool isMobile) {
    return Obx(() {
      final data = _espaceCtrl.restitutions;
      if (data.isEmpty) {
        return _buildEmptyState(
          icon: Icons.assignment_return,
          title: 'Aucune restitution',
          message:
              'Les restitutions apparaîtront ici dès qu\'elles seront enregistrées.',
        );
      }
      final sorted = data.toList()
        ..sort((a, b) => b.dateRestitution.compareTo(a.dateRestitution));
      return ListView.builder(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        itemCount: sorted.length,
        itemBuilder: (c, i) => _buildRestitutionCard(sorted[i], isMobile),
      );
    });
  }

  Widget _buildRestitutionCard(Restitution r, bool isMobile) {
    final date = DateFormat('dd/MM HH:mm').format(r.dateRestitution);
    final produits = r.produits.fold<int>(0, (s, p) => s + p.quantiteRestituee);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        onTap: () => _showRestitutionDetails(r),
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.withOpacity(.12),
          child: const Icon(Icons.assignment_return, color: Colors.indigo),
        ),
        title: Text('${r.commercialNom} • $produits produit(s)',
            style: TextStyle(
                fontSize: isMobile ? 13 : 15, fontWeight: FontWeight.w600)),
        subtitle: Text('$date • ${r.type.name}',
            style: TextStyle(
                fontSize: isMobile ? 11 : 12, color: Colors.grey.shade600)),
        trailing: Text(VenteUtils.formatPrix(r.valeurTotale),
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14)),
      ),
    );
  }

  void _showRestitutionDetails(Restitution r) {
    Get.bottomSheet(SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.assignment_return, color: Colors.indigo),
                const SizedBox(width: 8),
                const Text('Détails Restitution',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                    onPressed: () => Get.back(), icon: const Icon(Icons.close))
              ]),
              const SizedBox(height: 12),
              Text('ID: ${r.id}',
                  style: TextStyle(color: Colors.grey.shade600)),
              Text(
                  'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(r.dateRestitution)}',
                  style: TextStyle(color: Colors.grey.shade600)),
              Text('Commercial: ${r.commercialNom}',
                  style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              const Text('Produits',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              ...r.produits.map((p) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.inventory_2, size: 20),
                    title: Text('${p.typeEmballage}'),
                    subtitle: Text(
                        'Qté: ${p.quantiteRestituee} • Etat: ${p.etatProduit}'),
                    trailing: Text(
                        VenteUtils.formatPrix(
                            p.valeurUnitaire * p.quantiteRestituee),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  )),
              const Divider(height: 28),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                    'Valeur totale: ${VenteUtils.formatPrix(r.valeurTotale)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
              )
            ],
          ),
        ),
      ),
    ));
  }

  // === ONGLET PERTES ===
  Widget _buildPertesTab(bool isMobile) {
    return Obx(() {
      final data = _espaceCtrl.pertes;
      if (data.isEmpty) {
        return _buildEmptyState(
            icon: Icons.report_problem,
            title: 'Aucune perte déclarée',
            message: 'Les pertes apparaîtront ici après déclaration.');
      }
      final sorted = data.toList()
        ..sort((a, b) => b.datePerte.compareTo(a.datePerte));
      return ListView.builder(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        itemCount: sorted.length,
        itemBuilder: (c, i) => _buildPerteCard(sorted[i], isMobile),
      );
    });
  }

  Widget _buildPerteCard(Perte p, bool isMobile) {
    final date = DateFormat('dd/MM HH:mm').format(p.datePerte);
    final produits = p.produits.fold<int>(0, (s, x) => s + x.quantitePerdue);
    final couleur =
        p.estValidee ? const Color(0xFF16A34A) : const Color(0xFFF59E0B);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        onTap: () => _showPerteDetails(p),
        leading: CircleAvatar(
          backgroundColor: couleur.withOpacity(.15),
          child: Icon(Icons.report_problem, color: couleur),
        ),
        title: Text('${p.commercialNom} • $produits perdu(s)',
            style: TextStyle(
                fontSize: isMobile ? 13 : 15, fontWeight: FontWeight.w600)),
        subtitle: Text('$date • ${p.type.name}',
            style: TextStyle(
                fontSize: isMobile ? 11 : 12, color: Colors.grey.shade600)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(VenteUtils.formatPrix(p.valeurTotale),
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: couleur.withOpacity(.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(p.estValidee ? 'Validée' : 'En attente',
                  style: TextStyle(
                      color: couleur,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            )
          ],
        ),
      ),
    );
  }

  void _showPerteDetails(Perte p) {
    Get.bottomSheet(SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.report_problem, color: Colors.redAccent),
                const SizedBox(width: 8),
                const Text('Détails Perte',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                    onPressed: () => Get.back(), icon: const Icon(Icons.close))
              ]),
              const SizedBox(height: 12),
              Text('ID: ${p.id}',
                  style: TextStyle(color: Colors.grey.shade600)),
              Text(
                  'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(p.datePerte)}',
                  style: TextStyle(color: Colors.grey.shade600)),
              Text('Commercial: ${p.commercialNom}',
                  style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              const Text('Produits perdus',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              ...p.produits.map((pr) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.inventory_2, size: 20),
                    title: Text(pr.typeEmballage),
                    subtitle:
                        Text('Qté: ${pr.quantitePerdue} • Motif: ${p.motif}'),
                    trailing: Text(
                        VenteUtils.formatPrix(
                            pr.valeurUnitaire * pr.quantitePerdue),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  )),
              const Divider(height: 28),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                    'Valeur totale: ${VenteUtils.formatPrix(p.valeurTotale)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
              )
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildEmptyState(
      {required IconData icon,
      required String title,
      required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          )
        ],
      ),
    );
  }

  Widget _buildHeaderVentes(
      bool isMobile, double ca, int produits, int nbVentes) {
    return Container(
      margin: EdgeInsets.all(isMobile ? 12 : 20),
      padding: EdgeInsets.all(isMobile ? 18 : 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withOpacity(.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                child: const Icon(Icons.point_of_sale,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mes Ventes',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Historique des ventes enregistrées',
                        style: TextStyle(
                          color: Colors.white.withOpacity(.9),
                          fontSize: isMobile ? 12 : 14,
                        )),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _buildMiniStat('Ventes', nbVentes.toString(),
                      Icons.receipt_long, isMobile)),
              SizedBox(width: isMobile ? 10 : 14),
              Expanded(
                  child: _buildMiniStat('Produits', produits.toString(),
                      Icons.inventory_2, isMobile)),
              SizedBox(width: isMobile ? 10 : 14),
              Expanded(
                  child: _buildMiniStat('Chiffre', VenteUtils.formatPrix(ca),
                      Icons.currency_exchange, isMobile)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMiniStat(
      String label, String value, IconData icon, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: isMobile ? 18 : 22),
          SizedBox(height: isMobile ? 4 : 8),
          Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 12 : 15)),
          Text(label,
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: isMobile ? 9 : 11,
                  fontWeight: FontWeight.w500))
        ],
      ),
    );
  }

  Widget _buildVenteCard(Vente vente, bool isMobile) {
    final montant = VenteUtils.formatPrix(vente.montantTotal);
    final date = DateFormat('dd/MM HH:mm').format(vente.dateVente);
    final produits =
        vente.produits.fold<int>(0, (s, p) => s + p.quantiteVendue);
    final statutColor = _statutColor(vente.statut);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showVenteDetails(vente),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 14 : 18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: statutColor.withOpacity(.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.shopping_cart_checkout,
                    color: statutColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        vente.clientNom.isEmpty
                            ? 'Client Libre'
                            : vente.clientNom,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 14 : 16,
                            color: Colors.grey.shade800)),
                    const SizedBox(height: 4),
                    Text('$produits produit(s) • $date',
                        style: TextStyle(
                            fontSize: isMobile ? 11 : 12,
                            color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(montant,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 13 : 15,
                              color: Colors.grey.shade900)),
                      const SizedBox(width: 6),
                      Tooltip(
                        message: 'Voir Reçu',
                        child: InkWell(
                          onTap: () => _showReceiptDialog(vente),
                          borderRadius: BorderRadius.circular(18),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.receipt_long,
                                size: 18, color: Colors.indigo),
                          ),
                        ),
                      ),
                      Tooltip(
                        message: 'Télécharger (.txt)',
                        child: InkWell(
                          onTap: () => _downloadReceipt(vente),
                          borderRadius: BorderRadius.circular(18),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.download_for_offline,
                                size: 18, color: Colors.blueGrey),
                          ),
                        ),
                      ),
                      Tooltip(
                        message: 'Télécharger (PDF)',
                        child: InkWell(
                          onTap: () => _downloadReceiptPdf(vente),
                          borderRadius: BorderRadius.circular(18),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.picture_as_pdf,
                                size: 18, color: Colors.redAccent),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statutColor.withOpacity(.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statutLabel(vente.statut),
                      style: TextStyle(
                          color: statutColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReceiptDialog(Vente vente) {
    try {
      final recu = _generateReceipt(vente);
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

  String _generateReceipt(Vente vente) {
    final buffer = StringBuffer();
    buffer.writeln('=========== REÇU DE VENTE ===========');
    buffer.writeln('ID Vente   : ${vente.id}');
    buffer.writeln(
        'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(vente.dateVente)}');
    buffer.writeln(
        'Client: ${vente.clientNom.isEmpty ? 'Client Libre' : vente.clientNom}');
    buffer.writeln('Commercial: ${vente.commercialNom}');
    buffer.writeln('-------------------------------------');
    buffer.writeln('Produits:');
    for (final p in vente.produits) {
      buffer.writeln(
          '- ${p.typeEmballage} x${p.quantiteVendue} @${p.prixUnitaire.toStringAsFixed(0)} = ${p.montantTotal.toStringAsFixed(0)}');
    }
    buffer.writeln('-------------------------------------');
    buffer.writeln('Total     : ${vente.montantTotal.toStringAsFixed(0)} FCFA');
    buffer.writeln('Payé      : ${vente.montantPaye.toStringAsFixed(0)} FCFA');
    if (vente.montantRestant > 0) {
      buffer.writeln(
          'CRÉDIT    : ${vente.montantRestant.toStringAsFixed(0)} FCFA');
    } else {
      buffer.writeln('Solde     : 0');
    }
    buffer.writeln('Mode      : ${vente.modePaiement.name}');
    buffer.writeln('Statut    : ${vente.statut.name}');
    if (vente.observations != null && vente.observations!.isNotEmpty) {
      buffer.writeln('Note: ${vente.observations}');
    }
    buffer.writeln('=====================================');
    return buffer.toString();
  }

  void _downloadReceipt(Vente vente) {
    final recu = _generateReceipt(vente);
    final stamp = DateFormat('yyyyMMdd_HHmm').format(vente.dateVente);
    downloadTextCross(recu, fileName: 'recu_${vente.id}_$stamp.txt');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Téléchargement (ou sauvegarde) demandé')));
  }

  Future<void> _downloadReceiptPdf(Vente vente) async {
    try {
      final Uint8List bytes = await buildVenteReceiptPdf(vente);
      final fileName =
          'recu_${vente.id}_${DateFormat('yyyyMMdd_HHmm').format(vente.dateVente)}.pdf';
      await downloadBytesCross(bytes,
          fileName: fileName, mime: 'application/pdf');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('PDF généré (téléchargé si Web, ignoré sinon)')));
    } catch (e) {
      Get.snackbar('Erreur', 'Génération PDF impossible: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void _showVenteDetails(Vente vente) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Text('Détails Vente',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Text('ID: ${vente.id}',
                    style: TextStyle(color: Colors.grey.shade600)),
                Text(
                    'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(vente.dateVente)}',
                    style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 16),
                Text('Produits',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.grey.shade800)),
                const SizedBox(height: 8),
                ...vente.produits.map((p) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.inventory_2, size: 20),
                      title: Text('${p.typeEmballage} (${p.contenanceKg}kg)'),
                      subtitle: Text(
                          'Qté: ${p.quantiteVendue} • PU: ${VenteUtils.formatPrix(p.prixUnitaire)}'),
                      trailing: Text(
                        VenteUtils.formatPrix(p.montantTotal),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )),
                const Divider(height: 30),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Total: ${VenteUtils.formatPrix(vente.montantTotal)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statutColor(StatutVente statut) {
    switch (statut) {
      case StatutVente.payeeEnTotalite:
        return const Color(0xFF16A34A);
      case StatutVente.creditEnAttente:
        return const Color(0xFFF59E0B);
      // StatutVente.creditPartiel n'existe plus dans le nouvel enum -> on ne traite pas ce cas
      case StatutVente.creditRembourse:
        return const Color(0xFF0D9488);
      case StatutVente.annulee:
        return const Color(0xFFDC2626);
    }
  }

  String _statutLabel(StatutVente statut) {
    switch (statut) {
      case StatutVente.payeeEnTotalite:
        return 'Payée';
      case StatutVente.creditEnAttente:
        return 'Crédit';
      // StatutVente.creditPartiel supprimé de l'enum actuel
      case StatutVente.creditRembourse:
        return 'Remboursé';
      case StatutVente.annulee:
        return 'Annulée';
    }
  }

  // Anciennes versions statiques restitution/perte supprimées

  void _showVenteModal(Prelevement prelevement) {
    Get.dialog(
      VenteFormModalComplete(
        prelevement: prelevement,
        onVenteEnregistree: () {
          // Force la mise à jour des quantités restantes
          if (Get.isRegistered<EspaceCommercialController>()) {
            final espaceCtrl = Get.find<EspaceCommercialController>();
            espaceCtrl.forceRecalculQuantites();
          }
          _tabController.animateTo(0); // Retour à l'onglet attributions
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
          _tabController.animateTo(0);
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
          _tabController.animateTo(0);
        },
      ),
      barrierDismissible: false,
    );
  }

  /// Convertit une attribution en prélèvement temporaire pour les modals existants
  Prelevement _convertAttributionToPrelevement(
      AttributionPartielle attribution) {
    // Calculer la quantité restante réelle
    final quantiteRestante = _espaceCtrl.attributionRestant[attribution.id] ??
        (attribution.quantiteAttribuee -
            (_espaceCtrl.attributionConsomme[attribution.id] ?? 0));

    // DEBUG: Afficher les valeurs pour diagnostic
    debugPrint('🔍 CONVERSION ATTRIBUTION -> PRÉLÈVEMENT:');
    debugPrint('  ID: ${attribution.id}');
    debugPrint('  Quantité attribuée: ${attribution.quantiteAttribuee}');
    debugPrint(
        '  Quantité consommée: ${_espaceCtrl.attributionConsomme[attribution.id] ?? 0}');
    debugPrint('  Quantité restante calculée: $quantiteRestante');

    // Créer un produit prélèvé à partir de l'attribution
    final produitPreleve = ProduitPreleve(
      produitId: attribution.lotId,
      numeroLot: attribution.numeroLot,
      typeEmballage: attribution.typeEmballage,
      contenanceKg: attribution.contenanceKg,
      quantitePreleve:
          quantiteRestante, // Utiliser la quantité restante calculée
      prixUnitaire: attribution.prixUnitaire,
      valeurTotale: attribution.prixUnitaire * quantiteRestante,
    );

    // Créer un prélèvement temporaire
    return Prelevement(
      id: '${attribution.id}_prelevement_temp',
      commercialId: attribution.commercialId,
      commercialNom: attribution.commercialNom,
      magazinierId: attribution.gestionnaire,
      magazinierNom: attribution.gestionnaire,
      datePrelevement: attribution.dateAttribution,
      produits: [produitPreleve],
      valeurTotale: produitPreleve.valeurTotale,
      statut: StatutPrelevement.enCours,
      observations: attribution.observations,
    );
  }

  // 🎯 NOUVELLES MÉTHODES pour les attributions
  void _showVenteDialog(AttributionPartielle attribution) {
    // Convertir l'attribution en prélèvement temporaire pour réutiliser le modal existant
    final prelevement = _convertAttributionToPrelevement(attribution);
    Get.dialog(
      VenteFormModalComplete(
        prelevement: prelevement,
        onVenteEnregistree: () {
          _tabController.animateTo(0);
          _espaceCtrl.ensureAttributionsLoaded(forceRefresh: true);
        },
      ),
      barrierDismissible: false,
    );
  }

  void _showRestitutionDialog(AttributionPartielle attribution) {
    // Convertir l'attribution en prélèvement temporaire pour réutiliser le modal existant
    final prelevement = _convertAttributionToPrelevement(attribution);
    Get.dialog(
      RestitutionFormModal(
        prelevement: prelevement,
        onRestitutionEnregistree: () {
          _tabController.animateTo(0);
          _espaceCtrl.ensureAttributionsLoaded(forceRefresh: true);
        },
      ),
      barrierDismissible: false,
    );
  }

  void _showPerteDialog(AttributionPartielle attribution) {
    // Convertir l'attribution en prélèvement temporaire pour réutiliser le modal existant
    final prelevement = _convertAttributionToPrelevement(attribution);
    Get.dialog(
      PerteFormModal(
        prelevement: prelevement,
        onPerteEnregistree: () {
          _tabController.animateTo(0);
          _espaceCtrl.ensureAttributionsLoaded(forceRefresh: true);
        },
      ),
      barrierDismissible: false,
    );
  }

  /// 🎯 NOUVELLE CARD pour afficher une attribution
  Widget _buildAttributionCard(
      AttributionPartielle attribution, bool isMobile) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 8,
      ),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
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
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF9C27B0),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy')
                          .format(attribution.dateAttribution),
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Détails du lot dans un container stylé
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Lot:', attribution.numeroLot, isMobile),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                        'Type:', attribution.typeEmballage, isMobile),
                    const SizedBox(height: 8),
                    _buildDetailRow('Contenance:',
                        '${attribution.contenanceKg} kg', isMobile),
                    const SizedBox(height: 8),
                    Obx(() {
                      final quantiteRestante = _espaceCtrl
                              .attributionRestant[attribution.id] ??
                          (attribution.quantiteAttribuee -
                              (_espaceCtrl
                                      .attributionConsomme[attribution.id] ??
                                  0));
                      final quantiteConsommee =
                          _espaceCtrl.attributionConsomme[attribution.id] ?? 0;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            quantiteRestante > 0
                                ? 'Quantité restante:'
                                : 'Stock épuisé:',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: isMobile ? 12 : 14,
                            ),
                          ),
                          Text(
                            quantiteConsommee > 0
                                ? '$quantiteRestante unités (${quantiteConsommee} vendues)'
                                : '${quantiteRestante} unités',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: quantiteRestante > 0
                                  ? Colors.black87
                                  : Colors.red,
                              fontSize: isMobile ? 12 : 14,
                            ),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                        'Prix unitaire:',
                        VenteUtils.formatPrix(attribution.prixUnitaire),
                        isMobile),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Obx(() {
                      final quantiteRestante = _espaceCtrl
                              .attributionRestant[attribution.id] ??
                          (attribution.quantiteAttribuee -
                              (_espaceCtrl
                                      .attributionConsomme[attribution.id] ??
                                  0));

                      // Calcul de la valeur totale basée sur la quantité restante
                      final valeurTotaleActuelle =
                          quantiteRestante * attribution.prixUnitaire;

                      return _buildDetailRow(
                        'Valeur totale:',
                        VenteUtils.formatPrix(valeurTotaleActuelle),
                        isMobile,
                        isTotal: true,
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Gestionnaire
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Attribué par: ${attribution.gestionnaire}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),

              // Observations si présentes
              if (attribution.observations?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          attribution.observations!,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Boutons d'action
              const SizedBox(height: 16),
              Obx(() {
                final quantiteRestante = _espaceCtrl
                        .attributionRestant[attribution.id] ??
                    (attribution.quantiteAttribuee -
                        (_espaceCtrl.attributionConsomme[attribution.id] ?? 0));

                final stockEpuise = quantiteRestante <= 0;

                // Determine lock status from the lock doc if present
                bool locked = false;
                final lockDoc = _espaceCtrl.attributionsLocks[attribution.id];
                if (lockDoc != null) {
                  final enAttente =
                      (lockDoc['enAttenteValidation'] ?? false) as bool;
                  final dateValidationTs =
                      lockDoc['dateValidation'] as Timestamp?;
                  if (dateValidationTs != null) {
                    final dateValidation = dateValidationTs.toDate();
                    // Hide after 24 hours: consider it not locked (cleared) if older than 24h
                    final expired =
                        DateTime.now().difference(dateValidation).inHours >= 24;
                    locked = enAttente && !expired;
                  } else {
                    locked = enAttente;
                  }
                } else {
                  locked = attribution.enAttenteValidation;
                }

                return Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (stockEpuise || locked)
                            ? null
                            : () => _showVenteDialog(attribution),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (stockEpuise || locked)
                              ? Colors.grey
                              : Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: isMobile ? 12 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(
                          Icons.point_of_sale,
                          size: 18,
                          color: (stockEpuise || locked)
                              ? Colors.grey.shade600
                              : Colors.white,
                        ),
                        label: Text(
                          stockEpuise
                              ? 'Stock épuisé'
                              : locked
                                  ? 'En attente'
                                  : 'Vendre',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            fontWeight: FontWeight.w600,
                            color: (stockEpuise || locked)
                                ? Colors.grey.shade600
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (stockEpuise || locked)
                            ? null
                            : () => _showRestitutionDialog(attribution),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (stockEpuise || locked)
                              ? Colors.grey
                              : Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: isMobile ? 12 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(
                          Icons.undo,
                          size: 18,
                          color: (stockEpuise || locked)
                              ? Colors.grey.shade600
                              : Colors.white,
                        ),
                        label: Text(
                          locked ? 'En attente' : 'Restituer',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            fontWeight: FontWeight.w600,
                            color: (stockEpuise || locked)
                                ? Colors.grey.shade600
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (stockEpuise || locked)
                            ? null
                            : () => _showPerteDialog(attribution),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (stockEpuise || locked)
                              ? Colors.grey
                              : Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: isMobile ? 12 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(
                          Icons.warning,
                          size: 18,
                          color: (stockEpuise || locked)
                              ? Colors.grey.shade600
                              : Colors.white,
                        ),
                        label: Text(
                          locked ? 'En attente' : 'Perte',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            fontWeight: FontWeight.w600,
                            color: (stockEpuise || locked)
                                ? Colors.grey.shade600
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            locked ? null : () => _terminerCloture(attribution),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              locked ? Colors.grey : const Color(0xFF0EA5E9),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: isMobile ? 12 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.flag_circle, size: 18),
                        label: Text(
                          locked ? 'En attente' : 'Terminer',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper pour créer une ligne de détail
  Widget _buildDetailRow(String label, String value, bool isMobile,
      {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: isMobile ? 12 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? const Color(0xFF9C27B0) : Colors.black87,
            fontSize: isMobile ? 12 : 14,
          ),
        ),
      ],
    );
  }
}

extension _TerminerCloture on _VenteCommercialPageState {
  Future<void> _terminerCloture(AttributionPartielle attribution) async {
    final site = _espaceCtrl.selectedSite.value.isNotEmpty
        ? _espaceCtrl.selectedSite.value
        : (_userSession.site ?? '');
    if (site.isEmpty) {
      Get.snackbar(
          'Site manquant', 'Impossible de déterminer le site pour la clôture.');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Terminer et envoyer à la caisse ?'),
        content: const Text(
            'Une clôture sera créée à partir des ventes/restitutions/pertes de cette attribution et envoyée à la caissière pour validation.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.of(c).pop(true),
              child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final prelevementId = '${attribution.id}_prelevement_temp';
      final service = VenteService();
      await service.cloturerAttribution(
        site: site,
        prelevementId: prelevementId,
        commercialId: attribution.commercialId,
        commercialNom: attribution.commercialNom,
      );
      Get.snackbar(
          'Clôture envoyée', 'La caissière verra la clôture pour validation.');
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de créer la clôture: $e');
    }
  }
}
