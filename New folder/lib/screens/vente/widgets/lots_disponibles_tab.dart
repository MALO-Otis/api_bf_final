import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../models/commercial_models.dart';
import '../widgets/attribution_modal.dart';
import '../services/commercial_service.dart';
import '../widgets/attribution_multiple_modal.dart';

/// 📦 ONGLET LOTS DISPONIBLES - AFFICHAGE UNIQUEMENT DES RESTES
///
/// Interface optimisée montrant seulement les produits avec quantité restante > 0
/// Masque automatiquement les lots complètement attribués

class LotsDisponiblesTab extends StatefulWidget {
  final CommercialService commercialService;
  final RxString searchText;
  final VoidCallback onLotsUpdated;

  const LotsDisponiblesTab({
    super.key,
    required this.commercialService,
    required this.searchText,
    required this.onLotsUpdated,
  });

  @override
  State<LotsDisponiblesTab> createState() => _LotsDisponiblesTabState();
}

class _LotsDisponiblesTabState extends State<LotsDisponiblesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final RxList<LotProduit> _lotsFiltres = <LotProduit>[].obs;
  final RxBool _isFiltering = false.obs;
  final RxString _currentSiteFilter = 'all'.obs;
  final RxString _currentTypeFilter = 'all'.obs;
  final RxString _currentStatutFilter = 'all'.obs;

  @override
  void initState() {
    super.initState();
    _initializeFilters();
  }

  void _initializeFilters() {
    // Écouter les changements de recherche
    ever(widget.searchText, (_) => _applyFilters());
    ever(_currentSiteFilter, (_) => _applyFilters());
    ever(_currentTypeFilter, (_) => _applyFilters());
    ever(_currentStatutFilter, (_) => _applyFilters());

    // Appliquer les filtres initiaux
    _applyFilters();
  }

  void _applyFilters() {
    _isFiltering.value = true;

    try {
      List<LotProduit> lots = widget.commercialService.lots;

      // ✅ RÈGLE PRINCIPALE: Ne montrer QUE les lots avec quantité restante > 0
      lots = lots.where((lot) => lot.quantiteRestante > 0).toList();

      // Filtrage par texte de recherche
      final searchTerm = widget.searchText.value.toLowerCase().trim();
      if (searchTerm.isNotEmpty) {
        lots = lots.where((lot) {
          return lot.numeroLot.toLowerCase().contains(searchTerm) ||
              lot.siteOrigine.toLowerCase().contains(searchTerm) ||
              lot.typeEmballage.toLowerCase().contains(searchTerm) ||
              lot.predominanceFlorale.toLowerCase().contains(searchTerm);
        }).toList();
      }

      // Filtrage par site
      if (_currentSiteFilter.value != 'all') {
        lots = lots
            .where((lot) => lot.siteOrigine == _currentSiteFilter.value)
            .toList();
      }

      // Filtrage par type d'emballage
      if (_currentTypeFilter.value != 'all') {
        lots = lots
            .where((lot) => lot.typeEmballage == _currentTypeFilter.value)
            .toList();
      }

      // Filtrage par statut (exclure les lots complètement attribués)
      if (_currentStatutFilter.value != 'all') {
        final StatutLot? statut = StatutLot.values
            .firstWhereOrNull((s) => s.name == _currentStatutFilter.value);
        if (statut != null) {
          lots = lots.where((lot) => lot.statut == statut).toList();
        }
      }

      // Trier par urgence (proche expiration en premier) puis par date
      lots.sort((a, b) {
        // Priorité aux lots proches de l'expiration
        if (a.estProcheExpiration && !b.estProcheExpiration) return -1;
        if (!a.estProcheExpiration && b.estProcheExpiration) return 1;

        // Sinon trier par date de conditionnement (plus récent en premier)
        return b.dateConditionnement.compareTo(a.dateConditionnement);
      });

      _lotsFiltres.assignAll(lots);
    } catch (e) {
      debugPrint('❌ [LotsDisponiblesTab] Erreur filtrage: $e');
      _lotsFiltres.clear();
    } finally {
      _isFiltering.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        _buildFiltersRow(context),
        Expanded(
          child: Obx(() => _isFiltering.value
              ? _buildLoadingView()
              : _buildLotsList(context)),
        ),
      ],
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
          // Header avec info importante et bouton attribution multiple
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Seuls les lots avec stock disponible sont affichés',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Bouton Attribution Multiple
              ElevatedButton.icon(
                onPressed: () => _ouvrirAttributionMultiple(),
                icon: const Icon(Icons.assignment_turned_in, size: 16),
                label: Text(isMobile ? 'Multiple' : 'Attribution Multiple'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 2,
                ),
              ),

              const SizedBox(width: 12),

              Obx(() => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_lotsFiltres.length} lots',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )),
            ],
          ),

          const SizedBox(height: 16),

          // Filtres
          if (isMobile)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildSiteFilter()),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTypeFilter()),
                  ],
                ),
                const SizedBox(height: 8),
                _buildStatutFilter(),
              ],
            )
          else
            Row(
              children: [
                Expanded(flex: 2, child: _buildSiteFilter()),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _buildTypeFilter()),
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

  Widget _buildSiteFilter() {
    final sites = widget.commercialService.lots
        .where((lot) => lot.quantiteRestante > 0)
        .map((lot) => lot.siteOrigine)
        .toSet()
        .toList()
      ..sort();

    return Obx(() => DropdownButtonFormField<String>(
          value: _currentSiteFilter.value,
          decoration: InputDecoration(
            labelText: 'Site',
            prefixIcon: const Icon(Icons.location_on, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            const DropdownMenuItem(value: 'all', child: Text('Tous les sites')),
            ...sites.map((site) => DropdownMenuItem(
                  value: site,
                  child: Text(site),
                )),
          ],
          onChanged: (value) => _currentSiteFilter.value = value ?? 'all',
        ));
  }

  Widget _buildTypeFilter() {
    final types = widget.commercialService.lots
        .where((lot) => lot.quantiteRestante > 0)
        .map((lot) => lot.typeEmballage)
        .toSet()
        .toList()
      ..sort();

    return Obx(() => DropdownButtonFormField<String>(
          value: _currentTypeFilter.value,
          decoration: InputDecoration(
            labelText: 'Type',
            prefixIcon: const Icon(Icons.category, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            const DropdownMenuItem(value: 'all', child: Text('Tous types')),
            ...types.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                )),
          ],
          onChanged: (value) => _currentTypeFilter.value = value ?? 'all',
        ));
  }

  Widget _buildStatutFilter() {
    return Obx(() => DropdownButtonFormField<String>(
          value: _currentStatutFilter.value,
          decoration: InputDecoration(
            labelText: 'Statut',
            prefixIcon: const Icon(Icons.flag, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Tous statuts')),
            DropdownMenuItem(value: 'disponible', child: Text('Disponible')),
            DropdownMenuItem(
                value: 'partielAttribue',
                child: Text('Partiellement attribué')),
          ],
          onChanged: (value) => _currentStatutFilter.value = value ?? 'all',
        ));
  }

  Widget _buildClearFiltersButton() {
    return ElevatedButton.icon(
      onPressed: () {
        _currentSiteFilter.value = 'all';
        _currentTypeFilter.value = 'all';
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
            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF1976D2)),
          ),
          const SizedBox(height: 16),
          Text(
            'Filtrage en cours...',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildLotsList(BuildContext context) {
    if (_lotsFiltres.isEmpty) {
      return _buildEmptyState();
    }

    final isMobile = MediaQuery.of(context).size.width < 600;

    // ⚠️ Important: primary:false pour éviter de partager le PrimaryScrollController
    // avec le NestedScrollView parent (sinon erreur ScrollController attaché 2 fois)
    return ListView.builder(
      primary: false,
      padding: const EdgeInsets.all(16),
      itemCount: _lotsFiltres.length,
      itemBuilder: (context, index) {
        final lot = _lotsFiltres[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildLotCard(context, lot, isMobile),
        );
      },
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
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun lot disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tous les lots sont soit épuisés soit complètement attribués.\nIls apparaîtront dans l\'onglet "Attributions".',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                widget.commercialService.rafraichirToutesLesDonnees(),
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLotCard(BuildContext context, LotProduit lot, bool isMobile) {
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
              // Header avec statut et badges
              Row(
                children: [
                  // Badge emoji selon le type
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

                  // Badge urgence si proche expiration
                  if (lot.estProcheExpiration)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning,
                              size: 14, color: Colors.orange.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Expire bientôt',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Badge statut
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

              // Informations détaillées
              if (isMobile)
                _buildMobileDetails(lot)
              else
                _buildDesktopDetails(lot),

              const SizedBox(height: 16),

              // Barre de progression attribution
              _buildProgressBar(lot),

              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showLotDetails(context, lot),
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Utiliser Attribution Multiple',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildMobileDetails(LotProduit lot) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                'Disponible',
                '${lot.quantiteRestante} unités',
                Icons.inventory,
                const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailItem(
                'Valeur',
                CommercialUtils.formatPrix(lot.valeurRestante),
                Icons.monetization_on,
                const Color(0xFF2196F3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                'Prix/unité',
                CommercialUtils.formatPrix(lot.prixUnitaire),
                Icons.local_offer,
                const Color(0xFF9C27B0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailItem(
                'Expiration',
                DateFormat('dd/MM/yyyy').format(lot.dateExpiration),
                Icons.schedule,
                lot.estProcheExpiration ? Colors.orange : Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopDetails(LotProduit lot) {
    return Row(
      children: [
        Expanded(
          child: _buildDetailItem(
            'Stock disponible',
            '${lot.quantiteRestante} unités',
            Icons.inventory,
            const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDetailItem(
            'Valeur restante',
            CommercialUtils.formatPrix(lot.valeurRestante),
            Icons.monetization_on,
            const Color(0xFF2196F3),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDetailItem(
            'Prix unitaire',
            CommercialUtils.formatPrix(lot.prixUnitaire),
            Icons.local_offer,
            const Color(0xFF9C27B0),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDetailItem(
            'Date d\'expiration',
            DateFormat('dd/MM/yyyy').format(lot.dateExpiration),
            Icons.schedule,
            lot.estProcheExpiration ? Colors.orange : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(
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

  Widget _buildProgressBar(LotProduit lot) {
    final pourcentage = lot.pourcentageAttribution;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Attribution: ${pourcentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${lot.quantiteAttribuee}/${lot.quantiteInitiale} attribués',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: pourcentage / 100,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            pourcentage > 80
                ? Colors.red
                : pourcentage > 50
                    ? Colors.orange
                    : const Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }

  void _showLotDetails(BuildContext context, LotProduit lot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails du Lot ${lot.numeroLot}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Numéro de lot', lot.numeroLot),
              _buildDetailRow('Site d\'origine', lot.siteOrigine),
              _buildDetailRow('Type d\'emballage', lot.typeEmballage),
              _buildDetailRow('Prédominance florale', lot.predominanceFlorale),
              _buildDetailRow('Contenance', '${lot.contenanceKg} kg'),
              _buildDetailRow('Prix unitaire',
                  CommercialUtils.formatPrix(lot.prixUnitaire)),
              _buildDetailRow(
                  'Quantité initiale', '${lot.quantiteInitiale} unités'),
              _buildDetailRow(
                  'Quantité attribuée', '${lot.quantiteAttribuee} unités'),
              _buildDetailRow(
                  'Quantité restante', '${lot.quantiteRestante} unités'),
              _buildDetailRow('Valeur restante',
                  CommercialUtils.formatPrix(lot.valeurRestante)),
              _buildDetailRow('Date conditionnement',
                  DateFormat('dd/MM/yyyy').format(lot.dateConditionnement)),
              _buildDetailRow('Date expiration',
                  DateFormat('dd/MM/yyyy').format(lot.dateExpiration)),
              _buildDetailRow(
                  'Statut', CommercialUtils.getLibelleStatut(lot.statut)),
              if (lot.observations?.isNotEmpty == true)
                _buildDetailRow('Observations', lot.observations!),
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

  void _showAttributionModal(BuildContext context, LotProduit lot) {
    showDialog(
      context: context,
      builder: (context) => AttributionModal(
        lot: lot,
        commercialService: widget.commercialService,
        onAttributionSuccess: () {
          _applyFilters();
          widget.onLotsUpdated();
        },
      ),
    );
  }

  void _ouvrirAttributionMultiple() {
    // Vérifier qu'il y a des lots disponibles
    final lotsDisponibles = widget.commercialService.lots
        .where((lot) => lot.quantiteRestante > 0)
        .toList();

    if (lotsDisponibles.isEmpty) {
      Get.snackbar(
        '⚠️ Aucun lot disponible',
        'Il n\'y a aucun lot avec des quantités restantes pour l\'attribution multiple',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        icon: const Icon(Icons.warning, color: Colors.white),
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AttributionMultipleModal(
        lotsDisponibles: lotsDisponibles,
        commercialService: widget.commercialService,
        onAttributionSuccess: () {
          debugPrint(
              '🔄 [LotsDisponiblesTab] Rafraîchissement après attribution multiple');
          _applyFilters(); // Rafraîchir la liste filtrée
          widget
              .onLotsUpdated(); // Notifier le parent pour recharger les données
        },
      ),
    );
  }
}
