import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../models/commercial_models.dart';
import '../services/commercial_service.dart';
import '../widgets/modification_attribution_modal.dart';

/// 🎯 ONGLET ATTRIBUTIONS - VUE DÉTAILLÉE ET MODIFICATION
///
/// Interface complète pour visualiser et modifier les attributions existantes
/// Inclut les lots complètement attribués masqués de l'onglet produits

class AttributionsTab extends StatefulWidget {
  final CommercialService commercialService;
  final RxString searchText;
  final VoidCallback onAttributionsUpdated;

  const AttributionsTab({
    super.key,
    required this.commercialService,
    required this.searchText,
    required this.onAttributionsUpdated,
  });

  @override
  State<AttributionsTab> createState() => _AttributionsTabState();
}

class _AttributionsTabState extends State<AttributionsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final RxList<LotProduit> _lotsAvecAttributions = <LotProduit>[].obs;
  final RxList<AttributionPartielle> _attributionsFiltrees =
      <AttributionPartielle>[].obs;
  final RxBool _isFiltering = false.obs;
  final RxString _currentCommercialFilter = 'all'.obs;
  final RxString _currentStatutFilter = 'all'.obs;
  final RxString _viewMode = 'attributions'.obs; // 'attributions' ou 'lots'

  // Note: Les statistiques sont maintenant précalculées dans le service

  @override
  void initState() {
    super.initState();
    _initializeFilters();

    // 🔧 CORRECTION : Les statistiques sont précalculées automatiquement dans le service
    Future.delayed(const Duration(milliseconds: 100), () {
      widget.commercialService.rafraichirDonnees();
    });
  }

  void _initializeFilters() {
    // Écouter les changements
    ever(widget.searchText, (_) => _applyFilters());
    ever(_currentCommercialFilter, (_) => _applyFilters());
    ever(_currentStatutFilter, (_) => _applyFilters());
    ever(_viewMode, (_) => _applyFilters());

    // Appliquer les filtres initiaux
    _applyFilters();
  }

  // Note: Les statistiques sont maintenant précalculées dans le service

  void _applyFilters() {
    _isFiltering.value = true;

    try {
      if (_viewMode.value == 'lots') {
        _filterLots();
      } else {
        _filterAttributions();
      }

      // Note: Les statistiques sont précalculées dans le service
    } catch (e) {
      debugPrint('❌ [AttributionsTab] Erreur filtrage: $e');
      _attributionsFiltrees.clear();
      _lotsAvecAttributions.clear();
    } finally {
      _isFiltering.value = false;
    }
  }

  // Méthode supprimée car les statistiques sont précalculées dans le service

  void _filterLots() {
    List<LotProduit> lots = widget.commercialService.lots
        .where((lot) =>
            lot.attributions.isNotEmpty) // Seulement les lots avec attributions
        .toList();

    // Filtrage par texte de recherche
    final searchTerm = widget.searchText.value.toLowerCase().trim();
    if (searchTerm.isNotEmpty) {
      lots = lots.where((lot) {
        return lot.numeroLot.toLowerCase().contains(searchTerm) ||
            lot.siteOrigine.toLowerCase().contains(searchTerm) ||
            lot.typeEmballage.toLowerCase().contains(searchTerm) ||
            lot.attributions.any((attr) =>
                attr.commercialNom.toLowerCase().contains(searchTerm));
      }).toList();
    }

    // Filtrage par commercial
    if (_currentCommercialFilter.value != 'all') {
      lots = lots
          .where((lot) => lot.attributions.any(
              (attr) => attr.commercialId == _currentCommercialFilter.value))
          .toList();
    }

    // Filtrage par statut
    if (_currentStatutFilter.value != 'all') {
      final StatutLot? statut = StatutLot.values
          .firstWhereOrNull((s) => s.name == _currentStatutFilter.value);
      if (statut != null) {
        lots = lots.where((lot) => lot.statut == statut).toList();
      }
    }

    // Trier par date d'attribution la plus récente
    lots.sort((a, b) {
      final dateA = a.attributions.isEmpty
          ? DateTime(2000)
          : a.attributions.map((attr) => attr.dateAttribution).reduce(
              (latest, current) => current.isAfter(latest) ? current : latest);
      final dateB = b.attributions.isEmpty
          ? DateTime(2000)
          : b.attributions.map((attr) => attr.dateAttribution).reduce(
              (latest, current) => current.isAfter(latest) ? current : latest);
      return dateB.compareTo(dateA);
    });

    _lotsAvecAttributions.assignAll(lots);
  }

  void _filterAttributions() {
    List<AttributionPartielle> attributions =
        widget.commercialService.attributions;

    // Filtrage par texte de recherche
    final searchTerm = widget.searchText.value.toLowerCase().trim();
    if (searchTerm.isNotEmpty) {
      attributions = attributions.where((attr) {
        return attr.commercialNom.toLowerCase().contains(searchTerm) ||
            attr.lotId.toLowerCase().contains(searchTerm);
      }).toList();
    }

    // Filtrage par commercial
    if (_currentCommercialFilter.value != 'all') {
      attributions = attributions
          .where((attr) => attr.commercialId == _currentCommercialFilter.value)
          .toList();
    }

    // Trier par date d'attribution (plus récente en premier)
    attributions.sort((a, b) => b.dateAttribution.compareTo(a.dateAttribution));

    _attributionsFiltrees.assignAll(attributions);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        _buildHeader(context),
        _buildFiltersRow(context),
        Expanded(
          child: Obx(() => _isFiltering.value
              ? _buildLoadingView()
              : _buildContent(context)),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.assignment, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestion des Attributions',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Consultez et modifiez toutes les attributions, y compris les lots complètement attribués',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Switch pour changer de mode d'affichage
          Obx(() => SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'attributions',
                    label: Text('Par Attribution'),
                    icon: Icon(Icons.list, size: 16),
                  ),
                  ButtonSegment<String>(
                    value: 'lots',
                    label: Text('Par Lot'),
                    icon: Icon(Icons.inventory, size: 16),
                  ),
                ],
                selected: {_viewMode.value},
                onSelectionChanged: (Set<String> newSelection) {
                  _viewMode.value = newSelection.first;
                },
                style: SegmentedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  foregroundColor: Colors.white,
                  selectedBackgroundColor: Colors.white,
                  selectedForegroundColor: const Color(0xFF2196F3),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFiltersRow(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
          // 🚀 OPTIMISATION : Statistiques précalculées instantanées
          Obx(() => Row(
                children: [
                  _buildQuickStat(
                    'Attributions',
                    '${widget.commercialService.nombreAttributionsObs.value}',
                    Icons.assignment_turned_in,
                    const Color(0xFF4CAF50),
                  ),
                  const SizedBox(width: 16),
                  _buildQuickStat(
                    'Lots attribués',
                    '${widget.commercialService.nombreLotsAttribuesObs.value}',
                    Icons.inventory,
                    const Color(0xFF2196F3),
                  ),
                  const SizedBox(width: 16),
                  _buildQuickStat(
                    'Valeur totale',
                    CommercialUtils.formatPrix(
                        widget.commercialService.valeurTotaleObs.value),
                    Icons.monetization_on,
                    const Color(0xFF9C27B0),
                  ),
                ],
              )),

          const SizedBox(height: 16),

          // Filtres
          if (isMobile)
            Column(
              children: [
                _buildCommercialFilter(),
                const SizedBox(height: 8),
                _buildStatutFilter(),
              ],
            )
          else
            Row(
              children: [
                Expanded(flex: 2, child: _buildCommercialFilter()),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _buildStatutFilter()),
                const SizedBox(width: 12),
                _buildClearFiltersButton(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommercialFilter() {
    final commerciaux = widget.commercialService.attributions
        .map((attr) => MapEntry(attr.commercialId, attr.commercialNom))
        .toSet()
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return Obx(() => DropdownButtonFormField<String>(
          value: _currentCommercialFilter.value,
          decoration: InputDecoration(
            labelText: 'Commercial',
            prefixIcon: const Icon(Icons.person, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            const DropdownMenuItem(
                value: 'all', child: Text('Tous les commerciaux')),
            ...commerciaux.map((commercial) => DropdownMenuItem(
                  value: commercial.key,
                  child: Text(commercial.value),
                )),
          ],
          onChanged: (value) => _currentCommercialFilter.value = value ?? 'all',
        ));
  }

  Widget _buildStatutFilter() {
    return Obx(() => DropdownButtonFormField<String>(
          value: _currentStatutFilter.value,
          decoration: InputDecoration(
            labelText: 'Statut du lot',
            prefixIcon: const Icon(Icons.flag, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Tous statuts')),
            DropdownMenuItem(
                value: 'partielAttribue',
                child: Text('Partiellement attribué')),
            DropdownMenuItem(
                value: 'completAttribue', child: Text('Complètement attribué')),
          ],
          onChanged: (value) => _currentStatutFilter.value = value ?? 'all',
        ));
  }

  Widget _buildClearFiltersButton() {
    return ElevatedButton.icon(
      onPressed: () {
        _currentCommercialFilter.value = 'all';
        _currentStatutFilter.value = 'all';
        widget.searchText.value = '';
      },
      icon: const Icon(Icons.clear_all, size: 16),
      label: const Text('Réinitialiser'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF2196F3)),
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement des attributions...',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Obx(() {
      if (_viewMode.value == 'lots') {
        return _buildLotsView(context);
      } else {
        return _buildAttributionsView(context);
      }
    });
  }

  Widget _buildAttributionsView(BuildContext context) {
    if (_attributionsFiltrees.isEmpty) {
      return _buildEmptyState('Aucune attribution trouvée');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _attributionsFiltrees.length,
      itemBuilder: (context, index) {
        final attribution = _attributionsFiltrees[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildAttributionCard(context, attribution),
        );
      },
    );
  }

  Widget _buildLotsView(BuildContext context) {
    if (_lotsAvecAttributions.isEmpty) {
      return _buildEmptyState('Aucun lot avec attribution trouvé');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _lotsAvecAttributions.length,
      itemBuilder: (context, index) {
        final lot = _lotsAvecAttributions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildLotAvecAttributionsCard(context, lot),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Icon(
            Icons.assignment_outlined,
            size: 40,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Les attributions que vous créerez apparaîtront ici',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ));
  }

  Widget _buildAttributionCard(
      BuildContext context, AttributionPartielle attribution) {
    // Trouver le lot correspondant
    final lot = widget.commercialService.lots
        .firstWhereOrNull((l) => l.id == attribution.lotId);

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.blue.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.assignment_ind,
                      color: const Color(0xFF2196F3),
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 12),

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
                          'Attribution du ${DateFormat('dd/MM/yyyy à HH:mm').format(attribution.dateAttribution)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Badge valeur
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      CommercialUtils.formatPrix(attribution.valeurTotale),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Informations du lot si disponible
              if (lot != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '📦 Lot ${lot.numeroLot}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  CommercialUtils.getCouleurStatut(lot.statut),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              CommercialUtils.getLibelleStatut(lot.statut),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${lot.typeEmballage} • ${lot.siteOrigine} • ${lot.predominanceFlorale}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Détails de l'attribution
              Row(
                children: [
                  Expanded(
                    child: _buildAttributionDetail(
                      'Quantité attribuée',
                      '${attribution.quantiteAttribuee} unités',
                      Icons.inventory,
                      const Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAttributionDetail(
                      'Prix unitaire',
                      CommercialUtils.formatPrix(attribution.valeurUnitaire),
                      Icons.local_offer,
                      const Color(0xFF9C27B0),
                    ),
                  ),
                ],
              ),

              // Modifications si il y en a
              if (attribution.dateDerniereModification != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16, color: Colors.orange.shade700),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Modifiée le ${DateFormat('dd/MM/yyyy à HH:mm').format(attribution.dateDerniereModification!)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showAttributionDetails(context, attribution, lot),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Détails'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade600,
                        side: BorderSide(color: Colors.blue.shade600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showModificationModal(context, attribution, lot),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () =>
                        _showDeleteConfirmation(context, attribution),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Supprimer',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLotAvecAttributionsCard(BuildContext context, LotProduit lot) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header du lot
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CommercialUtils.getCouleurStatut(lot.statut)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      CommercialUtils.getEmojiEmballage(lot.typeEmballage),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lot ${lot.numeroLot}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${lot.typeEmballage} • ${lot.siteOrigine}',
                          style: TextStyle(
                            fontSize: 13,
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
                      color: CommercialUtils.getCouleurStatut(lot.statut),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      CommercialUtils.getLibelleStatut(lot.statut),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Résumé du lot
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${lot.quantiteInitiale}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Initial',
                            style: TextStyle(
                              fontSize: 11,
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
                            '${lot.quantiteAttribuee}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                          Text(
                            'Attribué',
                            style: TextStyle(
                              fontSize: 11,
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
                            '${lot.quantiteRestante}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: lot.quantiteRestante > 0
                                  ? const Color(0xFF4CAF50)
                                  : Colors.red,
                            ),
                          ),
                          Text(
                            'Restant',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Liste des attributions
              Text(
                'Attributions (${lot.attributions.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              ...lot.attributions
                  .map((attribution) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  const Color(0xFF2196F3).withOpacity(0.1),
                              child: Text(
                                attribution.commercialNom
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF2196F3),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    attribution.commercialNom,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${attribution.quantiteAttribuee} unités • ${CommercialUtils.formatPrix(attribution.valeurTotale)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              DateFormat('dd/MM')
                                  .format(attribution.dateAttribution),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            PopupMenuButton(
                              icon: const Icon(Icons.more_vert, size: 16),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'details',
                                  child: const Row(
                                    children: [
                                      Icon(Icons.visibility, size: 16),
                                      SizedBox(width: 8),
                                      Text('Détails'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'edit',
                                  child: const Row(
                                    children: [
                                      Icon(Icons.edit, size: 16),
                                      SizedBox(width: 8),
                                      Text('Modifier'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: const Row(
                                    children: [
                                      Icon(Icons.delete,
                                          size: 16, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Supprimer'),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                switch (value) {
                                  case 'details':
                                    _showAttributionDetails(
                                        context, attribution, lot);
                                    break;
                                  case 'edit':
                                    _showModificationModal(
                                        context, attribution, lot);
                                    break;
                                  case 'delete':
                                    _showDeleteConfirmation(
                                        context, attribution);
                                    break;
                                }
                              },
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttributionDetail(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAttributionDetails(
      BuildContext context, AttributionPartielle attribution, LotProduit? lot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails de l\'attribution'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Commercial', attribution.commercialNom),
              _buildDetailRow('Quantité attribuée',
                  '${attribution.quantiteAttribuee} unités'),
              _buildDetailRow('Valeur unitaire',
                  CommercialUtils.formatPrix(attribution.valeurUnitaire)),
              _buildDetailRow('Valeur totale',
                  CommercialUtils.formatPrix(attribution.valeurTotale)),
              _buildDetailRow(
                  'Date attribution',
                  DateFormat('dd/MM/yyyy à HH:mm')
                      .format(attribution.dateAttribution)),
              _buildDetailRow('Gestionnaire', attribution.gestionnaire),
              if (attribution.dateDerniereModification != null) ...[
                _buildDetailRow(
                    'Dernière modification',
                    DateFormat('dd/MM/yyyy à HH:mm')
                        .format(attribution.dateDerniereModification!)),
                if (attribution.motifModification?.isNotEmpty == true)
                  _buildDetailRow(
                      'Motif modification', attribution.motifModification!),
              ],
              if (lot != null) ...[
                const Divider(),
                Text('Informations du lot',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDetailRow('Numéro lot', lot.numeroLot),
                _buildDetailRow('Type emballage', lot.typeEmballage),
                _buildDetailRow('Site origine', lot.siteOrigine),
                _buildDetailRow(
                    'Prédominance florale', lot.predominanceFlorale),
                _buildDetailRow(
                    'Statut', CommercialUtils.getLibelleStatut(lot.statut)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const Text(' : '),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showModificationModal(
      BuildContext context, AttributionPartielle attribution, LotProduit? lot) {
    if (lot == null) {
      Get.snackbar(
        'Erreur',
        'Impossible de modifier cette attribution car le lot correspondant est introuvable',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ModificationAttributionModal(
        attribution: attribution,
        lot: lot,
        commercialService: widget.commercialService,
        onModificationSuccess: () {
          _applyFilters();
          widget.onAttributionsUpdated();
        },
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, AttributionPartielle attribution) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voulez-vous vraiment supprimer cette attribution ?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Commercial : ${attribution.commercialNom}'),
                  Text('Quantité : ${attribution.quantiteAttribuee} unités'),
                  Text(
                      'Valeur : ${CommercialUtils.formatPrix(attribution.valeurTotale)}'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '⚠️ Cette action remettra les produits en stock disponible.',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final success =
                  await widget.commercialService.supprimerAttribution(
                attribution.id,
                motif: 'Suppression manuelle depuis l\'interface',
              );

              if (success) {
                Get.snackbar(
                  '✅ Attribution supprimée',
                  'Les produits ont été remis en stock',
                  backgroundColor: const Color(0xFF4CAF50),
                  colorText: Colors.white,
                );
                _applyFilters();
                widget.onAttributionsUpdated();
              } else {
                Get.snackbar(
                  'Erreur',
                  'Impossible de supprimer cette attribution',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
