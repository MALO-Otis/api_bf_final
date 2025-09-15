import 'package:get/get.dart';
import 'prelevement_modal.dart';
import '../models/vente_models.dart';
import 'package:flutter/material.dart';
import '../services/vente_service.dart';
import '../../../utils/smart_appbar.dart';
import '../../../authentication/user_session.dart';
/// 🛒 PAGE PRINCIPALE DE GESTION DES VENTES - ADMIN/MAGAZINIER


class VenteAdminPage extends StatefulWidget {
  const VenteAdminPage({super.key});

  @override
  State<VenteAdminPage> createState() => _VenteAdminPageState();
}

class _VenteAdminPageState extends State<VenteAdminPage>
    with TickerProviderStateMixin {
  final VenteService _service = VenteService();
  final UserSession _userSession = Get.find<UserSession>();

  late AnimationController _fadeController;
  late TabController _tabController;
  late AnimationController _selectionController;

  List<ProduitConditionne> _produits = [];
  Map<String, dynamic> _statistiques = {};
  bool _isLoading = true;
  String _searchQuery = '';

  // 🛒 SYSTÈME DE SÉLECTION MULTIPLE
  final Set<String> _produitsSelectionnes = <String>{};
  bool _modeSelection = false;
  bool _selectAllMode = false;

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
    _selectionController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController.forward();
  }

  /// 🛒 GESTION DE LA SÉLECTION MULTIPLE
  void _toggleModeSelection() {
    setState(() {
      _modeSelection = !_modeSelection;
      if (!_modeSelection) {
        _produitsSelectionnes.clear();
        _selectAllMode = false;
        _selectionController.reverse();
      } else {
        _selectionController.forward();
      }
    });
  }

  void _toggleProduitSelection(String produitId) {
    setState(() {
      if (_produitsSelectionnes.contains(produitId)) {
        _produitsSelectionnes.remove(produitId);
      } else {
        _produitsSelectionnes.add(produitId);
      }
      _updateSelectAllMode();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectAllMode) {
        _produitsSelectionnes.clear();
        _selectAllMode = false;
      } else {
        final filteredProduits = _getFilteredProduits();
        _produitsSelectionnes.addAll(filteredProduits.map((p) => p.id));
        _selectAllMode = true;
      }
    });
  }

  void _updateSelectAllMode() {
    final filteredProduits = _getFilteredProduits();
    _selectAllMode = _produitsSelectionnes.length == filteredProduits.length &&
        filteredProduits.isNotEmpty;
  }

  List<ProduitConditionne> _getFilteredProduits() {
    return _produits.where((produit) {
      if (_searchQuery.isNotEmpty) {
        return produit.numeroLot.toLowerCase().contains(_searchQuery) ||
            produit.producteur.toLowerCase().contains(_searchQuery) ||
            produit.village.toLowerCase().contains(_searchQuery) ||
            produit.predominanceFlorale.toLowerCase().contains(_searchQuery) ||
            produit.typeEmballage.toLowerCase().contains(_searchQuery);
      }
      return true;
    }).toList();
  }

  List<ProduitConditionne> get _produitsSelectionnesList {
    return _produits
        .where((p) => _produitsSelectionnes.contains(p.id))
        .toList();
  }

  double get _valeurTotaleSelection {
    return _produitsSelectionnesList.fold(
        0.0, (sum, p) => sum + p.valeurTotale);
  }

  int get _quantiteTotaleSelection {
    return _produitsSelectionnesList.fold(
        0, (sum, p) => sum + p.quantiteDisponible);
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      debugPrint(
          '🔄 [VenteAdminPage] Chargement des données vente (cache + TTL) ...');

      // On ne force pas le refresh pour profiter du TTL (45s) sauf premier appel
      final produits =
          await _service.getProduitsConditionnesTotalement(forceRefresh: false);
      final stats = await _service.getStatistiquesVenteComplete();

      debugPrint('✅ [VenteAdminPage] ${produits.length} produits chargés');

      if (mounted) {
        setState(() {
          _produits = produits;
          _statistiques = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [VenteAdminPage] Erreur chargement: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            'Erreur',
            'Impossible de charger les données: $e',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        });
      }
    }
  }

  /// Affiche une petite fenêtre de diagnostics des caches/performances
  void _showDiagnostics() {
    final age = _service.ageCacheProduits?.inSeconds;
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Diagnostics Vente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Builds produits: ${_service.produitsBuildCount}'),
              Text('Cache taille: ${_service.tailleCacheProduits}'),
              Text('Âge cache: ${age == null ? '—' : '$age s'}'),
              Text(
                  'Conditionnements cumulés: ${_service.conditionnementsAnalysesCumule}'),
              Text('Emballages cumulés: ${_service.emballagesAnalysesCumule}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() => _isLoading = true);
                await _service.getProduitsConditionnesTotalement(
                    forceRefresh: true);
                await _service.getStatistiquesVenteComplete();
                setState(() => _isLoading = false);
              },
              child: const Text('Force Refresh'),
            )
          ],
        );
      },
    );
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
        actions: [
          // Mode sélection multiple
          AnimatedBuilder(
            animation: _selectionController,
            builder: (context, child) {
              return IconButton(
                icon: Icon(_modeSelection ? Icons.close : Icons.checklist),
                onPressed: _toggleModeSelection,
                tooltip:
                    _modeSelection ? 'Annuler sélection' : 'Sélection multiple',
                style: IconButton.styleFrom(
                  backgroundColor:
                      _modeSelection ? Colors.orange.withOpacity(0.2) : null,
                ),
              );
            },
          ),
          // Sélectionner tout
          if (_modeSelection)
            IconButton(
              icon: Icon(_selectAllMode ? Icons.deselect : Icons.select_all),
              onPressed: _toggleSelectAll,
              tooltip:
                  _selectAllMode ? 'Désélectionner tout' : 'Sélectionner tout',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.speed),
            tooltip: 'Diagnostics cache',
            onPressed: _showDiagnostics,
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _diagnosticIntegration,
            tooltip: 'Diagnostic intégration',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2), text: 'Produits'),
            Tab(icon: Icon(Icons.shopping_cart), text: 'Attributions'),
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
                _buildAttributionsTab(isMobile, canManage),
                _buildStatistiquesTab(isMobile),
              ],
            ),
      floatingActionButton: canManage ? _buildFloatingActionButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// 🎯 BOUTON D'ATTRIBUTION INTELLIGENT - COMPTE LOTS ET PRODUITS
  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _selectionController,
      builder: (context, child) {
        // Mode sélection avec produits sélectionnés
        if (_modeSelection && _produitsSelectionnes.isNotEmpty) {
          // Calculer le nombre de lots uniques sélectionnés
          final lotsSelectionnes = <String>{};
          for (final produit in _produitsSelectionnesList) {
            lotsSelectionnes.add(produit.numeroLot);
          }

          final nbProduits = _produitsSelectionnes.length;
          final nbLots = lotsSelectionnes.length;

          // Texte intelligent selon le contexte
          String labelText;
          if (nbLots == 1) {
            labelText =
                '🛒 Attribuer $nbProduits produit${nbProduits > 1 ? 's' : ''} (1 lot)';
          } else {
            labelText =
                '🛒 Attribuer $nbProduits produit${nbProduits > 1 ? 's' : ''} ($nbLots lots)';
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Panier de sélection amélioré
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: _buildPanierSelectionAmeliore(nbProduits, nbLots),
              ),
              const SizedBox(height: 16),
              // BOUTON UNIQUE INTELLIGENT
              FloatingActionButton.extended(
                onPressed: _showAttributionGroupee,
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                elevation: 8,
                icon: const Icon(Icons.shopping_basket),
                label: Text(
                  labelText,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                heroTag: "attribution_intelligente",
              ),
            ],
          );
        }
        // Mode normal - attribution rapide
        else {
          return FloatingActionButton.extended(
            onPressed: () => _showPrelevementModal(),
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            elevation: 6,
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text(
              '➕ Attribution Rapide',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            heroTag: "attribution_rapide",
          );
        }
      },
    );
  }

  /// 🛒 PANIER DE SÉLECTION AMÉLIORÉ AVEC COMPTAGE INTELLIGENT
  Widget _buildPanierSelectionAmeliore(int nbProduits, int nbLots) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.orange.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header avec icône
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shopping_basket,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sélection Active',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '$nbProduits produit${nbProduits > 1 ? 's' : ''} • $nbLots lot${nbLots > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Statistiques détaillées
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPanierStat('📦', '${_quantiteTotaleSelection}', 'unités'),
                const SizedBox(width: 16),
                _buildPanierStat(
                    '💰',
                    '${(_valeurTotaleSelection / 1000).toStringAsFixed(0)}K',
                    'FCFA'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanierStat(String emoji, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: Colors.orange.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.orange.shade600,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement des produits conditionnés...'),
        ],
      ),
    );
  }

  Widget _buildProduitsTab(bool isMobile, bool canManage) {
    return Column(
      children: [
        // Header avec recherche
        Container(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher par lot, producteur...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                onChanged: (value) =>
                    setState(() => _searchQuery = value.toLowerCase()),
              ),
              // Aide contextuelle pour le mode sélection
              if (_modeSelection)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade50, Colors.orange.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.touch_app,
                            color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '🛒 Mode sélection activé • Tapez sur les produits ou ☑️ pour des lots entiers',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: isMobile ? 12.0 : 13.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),
              // Statistiques responsive avec sélection
              _buildStatistiquesResponsives(isMobile),
            ],
          ),
        ),

        // Liste des produits
        Expanded(
          child: _produits.isEmpty
              ? _buildEmptyState()
              : _buildProduitsGrid(isMobile, canManage),
        ),
      ],
    );
  }

  /// 📊 STATISTIQUES ULTRA-RESPONSIVES AVEC MODE SÉLECTION
  Widget _buildStatistiquesResponsives(bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isExtraSmall = constraints.maxWidth < 480;
        final isSmall = constraints.maxWidth < 600;

        // Statistiques de sélection si mode actif
        if (_modeSelection && _produitsSelectionnes.isNotEmpty) {
          // Calculer les lots uniques sélectionnés
          final lotsSelectionnes = <String>{};
          for (final produit in _produitsSelectionnesList) {
            lotsSelectionnes.add(produit.numeroLot);
          }

          return Column(
            children: [
              // Statistiques de sélection
              Container(
                padding: EdgeInsets.all(isExtraSmall ? 12 : 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade100, Colors.orange.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade400, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.shopping_basket,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🛒 Sélection Active',
                                style: TextStyle(
                                  fontSize: isExtraSmall ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                              Text(
                                '${_produitsSelectionnes.length} produits de ${lotsSelectionnes.length} lot${lotsSelectionnes.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: isExtraSmall ? 12 : 13,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Stats sélection responsives
                    _buildStatsRow(
                      isExtraSmall,
                      isSmall,
                      [
                        (
                          'Sélectionnés',
                          '${_produitsSelectionnes.length}',
                          Icons.check_circle,
                          Colors.orange.shade600
                        ),
                        (
                          'Quantité',
                          '${_quantiteTotaleSelection}',
                          Icons.inventory_2,
                          Colors.orange.shade600
                        ),
                        (
                          'Valeur',
                          '${(_valeurTotaleSelection / 1000).toStringAsFixed(0)}K',
                          Icons.monetization_on,
                          Colors.orange.shade600
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Statistiques générales
              _buildStatsGenerales(isExtraSmall, isSmall, isMobile),
            ],
          );
        } else {
          // Mode normal - statistiques générales uniquement
          return _buildStatsGenerales(isExtraSmall, isSmall, isMobile);
        }
      },
    );
  }

  Widget _buildStatsGenerales(bool isExtraSmall, bool isSmall, bool isMobile) {
    final totalProduits = _produits.length;
    final valeurStock = _produits.fold(0.0, (sum, p) => sum + p.valeurTotale);
    final quantiteStock =
        _produits.fold(0, (sum, p) => sum + p.quantiteDisponible);

    return _buildStatsRow(
      isExtraSmall,
      isSmall,
      [
        (
          'Produits',
          '$totalProduits',
          Icons.inventory_2,
          const Color(0xFF1976D2)
        ),
        (
          'Valeur Stock',
          '${(valeurStock / 1000000).toStringAsFixed(1)}M FCFA',
          Icons.monetization_on,
          const Color(0xFF4CAF50)
        ),
        (
          'Quantité',
          '${(quantiteStock / 1000).toStringAsFixed(1)}K',
          Icons.scale,
          const Color(0xFF9C27B0)
        ),
      ],
    );
  }

  Widget _buildStatsRow(bool isExtraSmall, bool isSmall,
      List<(String, String, IconData, Color)> stats) {
    if (isExtraSmall) {
      // Mobile : 2+1 layout
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildStatCardCompact(stats[0].$1, stats[0].$2,
                      stats[0].$3, stats[0].$4, true)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildStatCardCompact(stats[1].$1, stats[1].$2,
                      stats[1].$3, stats[1].$4, true)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            child: _buildStatCardCompact(
                stats[2].$1, stats[2].$2, stats[2].$3, stats[2].$4, true),
          ),
        ],
      );
    } else {
      // Desktop/Tablet : ligne
      return Row(
        children: stats.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < stats.length - 1 ? 12 : 0),
              child: _buildStatCardCompact(
                  stat.$1, stat.$2, stat.$3, stat.$4, isSmall),
            ),
          );
        }).toList(),
      );
    }
  }

  Widget _buildStatCardCompact(
      String title, String value, IconData icon, Color color, bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isCompact ? 24 : 28),
          SizedBox(height: isCompact ? 8 : 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isCompact ? 14 : 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isCompact ? 4 : 6),
          Text(
            title,
            style: TextStyle(
              fontSize: isCompact ? 11 : 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Colors.orange.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun produit conditionné trouvé',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Les produits du module conditionnement\napparaîtront automatiquement ici',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualiser'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _diagnosticIntegration,
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Diagnostic'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Widget _buildProduitsGrid(bool isMobile, bool canManage) {
    final filteredProduits = _getFilteredProduits();

    // Grouper les produits par lot pour un affichage plus organisé
    final produitsParLot = <String, List<ProduitConditionne>>{};
    for (final produit in filteredProduits) {
      produitsParLot.putIfAbsent(produit.numeroLot, () => []).add(produit);
    }

    if (produitsParLot.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Super responsive design avec breakpoints
        final isExtraSmall = constraints.maxWidth < 480;
        final isSmall = constraints.maxWidth < 768;
        final isMedium = constraints.maxWidth < 1024;
        final isLarge = constraints.maxWidth < 1440;

        final padding = isExtraSmall
            ? 8.0
            : isSmall
                ? 12.0
                : isMedium
                    ? 16.0
                    : 20.0;

        return ListView.builder(
          padding: EdgeInsets.all(padding),
          itemCount: produitsParLot.length,
          itemBuilder: (context, index) {
            final lotEntry = produitsParLot.entries.elementAt(index);
            final numeroLot = lotEntry.key;
            final produitsDuLot = lotEntry.value;

            return _buildLotCardResponsive(
              numeroLot,
              produitsDuLot,
              isExtraSmall,
              isSmall,
              isMedium,
              isLarge,
              canManage,
            );
          },
        );
      },
    );
  }

  Widget _buildAttributionsTab(bool isMobile, bool canManage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Attributions de Produits',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les attributions aux commerciaux apparaîtront ici',
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
    final totalProduits = _statistiques['totalProduits'] ?? 0;
    final valeurStock = _statistiques['valeurStock'] ?? 0.0;
    final quantiteStock = _statistiques['quantiteStock'] ?? 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        children: [
          // Header statistiques
          Container(
            padding: EdgeInsets.all(isMobile ? 20 : 28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics, color: Colors.white, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Statistiques en Temps Réel',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Métriques
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isMobile ? 2 : 3,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildStatistiqueCard(
                      icon: Icons.inventory_2,
                      title: 'Produits',
                      value: totalProduits.toString(),
                      subtitle: 'conditionnés',
                      isMobile: isMobile,
                    ),
                    _buildStatistiqueCard(
                      icon: Icons.scale,
                      title: 'Quantité',
                      value: '$quantiteStock',
                      subtitle: 'unités',
                      isMobile: isMobile,
                    ),
                    _buildStatistiqueCard(
                      icon: Icons.monetization_on,
                      title: 'Valeur',
                      value: VenteUtils.formatPrix(valeurStock),
                      subtitle: 'totale',
                      isMobile: isMobile,
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

  Widget _buildStatistiqueCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isMobile ? 24 : 28, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: isMobile ? 9 : 10,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 🔧 DIAGNOSTIC COMPLET DE L'INTÉGRATION CONDITIONNEMENT/VENTE
  Future<void> _diagnosticIntegration() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('🔧 ================================');
      debugPrint('🔧 DIAGNOSTIC INTÉGRATION VENTE');
      debugPrint('🔧 ================================');

      // 1. Vérifier le service conditionnement
      debugPrint('1️⃣ Vérification du ConditionnementDbService...');
      final conditionnementService = _service.conditionnementService;
      debugPrint('   ✅ ConditionnementDbService accessible');

      // 2. Rafraîchir les données
      debugPrint('2️⃣ Rafraîchissement des données conditionnement...');
      await conditionnementService.refreshData();

      // 3. Vérifier les conditionnements
      final conditionnements = conditionnementService.conditionnements;
      debugPrint('3️⃣ Analyse des conditionnements:');
      debugPrint('   📊 Nombre total: ${conditionnements.length}');

      if (conditionnements.isEmpty) {
        debugPrint('   ⚠️ AUCUN CONDITIONNEMENT TROUVÉ');
      } else {
        for (int i = 0; i < conditionnements.length; i++) {
          final cond = conditionnements[i];
          debugPrint('   📦 Conditionnement ${i + 1}:');
          debugPrint('      - ID: ${cond.id}');
          debugPrint('      - Lot: ${cond.lotOrigine.lotOrigine}');
          debugPrint('      - Site: ${cond.lotOrigine.site}');
          debugPrint('      - Date: ${cond.dateConditionnement}');
          debugPrint('      - Emballages: ${cond.emballages.length}');
          debugPrint('      - Quantité: ${cond.quantiteConditionnee} kg');
          debugPrint('      - Prix: ${cond.prixTotal} FCFA');
        }
      }

      // 4. Test de conversion en produits vente
      debugPrint('4️⃣ Test conversion en produits vente...');
      final produits = await _service.getProduitsConditionnesTotalement();
      debugPrint('   📦 Produits générés: ${produits.length}');

      if (produits.isNotEmpty) {
        for (int i = 0; i < produits.length && i < 3; i++) {
          final p = produits[i];
          debugPrint('   🏷️ Produit ${i + 1}:');
          debugPrint('      - Lot: ${p.numeroLot}');
          debugPrint('      - Type: ${p.typeEmballage}');
          debugPrint('      - Stock: ${p.quantiteDisponible}');
          debugPrint('      - Prix: ${p.prixUnitaire} FCFA');
        }
      }

      // 5. Mettre à jour l'interface
      setState(() {
        _produits = produits;
        _isLoading = false;
      });

      debugPrint('🔧 ================================');
      debugPrint('🔧 FIN DIAGNOSTIC');
      debugPrint('🔧 ================================');

      // Message à l'utilisateur
      Get.snackbar(
        'Diagnostic terminé',
        'Conditionnements: ${conditionnements.length}\nProduits vente: ${produits.length}\nVoir console pour détails',
        backgroundColor: Colors.blue.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ ERREUR DANS DIAGNOSTIC: $e');
      debugPrint('📍 Stack trace: $stackTrace');

      setState(() => _isLoading = false);

      Get.snackbar(
        'Erreur diagnostic',
        'Erreur: $e',
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    }
  }

  /// 📦 ATTRIBUTION GROUPÉE
  void _showAttributionGroupee() {
    if (_produitsSelectionnesList.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => PrelevementModal(
        produits: _produitsSelectionnesList,
        onPrelevementCree: () {
          setState(() {
            _produitsSelectionnes.clear();
            _modeSelection = false;
            _selectionController.reverse();
          });
          _loadData();
        },
      ),
      barrierDismissible: false,
    );
  }

  /// 📦 NOUVELLE MÉTHODE POUR CARTE LOT RESPONSIVE
  Widget _buildLotCardResponsive(
    String numeroLot,
    List<ProduitConditionne> produitsDuLot,
    bool isExtraSmall,
    bool isSmall,
    bool isMedium,
    bool isLarge,
    bool canManage,
  ) {
    final quantiteTotale =
        produitsDuLot.fold(0, (sum, p) => sum + p.quantiteDisponible);
    final valeurTotale =
        produitsDuLot.fold(0.0, (sum, p) => sum + p.valeurTotale);
    final premier = produitsDuLot.first;

    final tousSelectionnes =
        produitsDuLot.every((p) => _produitsSelectionnes.contains(p.id));
    final aucunSelectionne =
        produitsDuLot.every((p) => !_produitsSelectionnes.contains(p.id));

    final headerPadding = isExtraSmall
        ? 12.0
        : isSmall
            ? 16.0
            : isMedium
                ? 20.0
                : 24.0;
    final contentPadding = isExtraSmall
        ? 12.0
        : isSmall
            ? 14.0
            : isMedium
                ? 16.0
                : 20.0;
    final titleSize = isExtraSmall
        ? 16.0
        : isSmall
            ? 18.0
            : isMedium
                ? 20.0
                : 22.0;
    final cardHeight = isExtraSmall
        ? 100.0
        : isSmall
            ? 110.0
            : 120.0;
    final emballageWidth = isExtraSmall
        ? 140.0
        : isSmall
            ? 150.0
            : 160.0;

    return Container(
      margin: EdgeInsets.only(bottom: isExtraSmall ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: _modeSelection && !aucunSelectionne
            ? Border.all(color: Colors.orange.shade400, width: 2)
            : null,
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(headerPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _modeSelection && !aucunSelectionne
                    ? [Colors.orange.shade600, Colors.orange.shade400]
                    : [const Color(0xFF1976D2), Colors.blue.shade600],
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
                if (_modeSelection)
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: Checkbox(
                      value: tousSelectionnes
                          ? true
                          : (aucunSelectionne ? false : null),
                      tristate: true,
                      onChanged: (value) => _toggleLotSelection(produitsDuLot),
                      activeColor: Colors.white,
                      checkColor: Colors.orange.shade600,
                      side: const BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                Container(
                  padding: EdgeInsets.all(isExtraSmall ? 12 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    premier.predominanceFlorale.toLowerCase().contains('mono')
                        ? '🌺'
                        : '🍯',
                    style: TextStyle(fontSize: isExtraSmall ? 24 : 28),
                  ),
                ),
                SizedBox(width: isExtraSmall ? 12 : 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.label_important,
                              color: Colors.white,
                              size: isExtraSmall ? 16 : 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lot $numeroLot',
                              style: TextStyle(
                                fontSize: titleSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!isExtraSmall) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade400,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.local_florist,
                                      size: 14, color: Colors.amber.shade800),
                                  const SizedBox(width: 4),
                                  Text(
                                    premier.predominanceFlorale,
                                    style: TextStyle(
                                      fontSize: isExtraSmall ? 10 : 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on,
                                    size: 14, color: Colors.white70),
                                const SizedBox(width: 2),
                                Text(
                                  premier.siteOrigine,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: isExtraSmall ? 11 : 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(contentPadding),
            child: isExtraSmall
                ? Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: _buildLotStatCardResponsive(
                                  'Stock',
                                  '$quantiteTotale',
                                  Icons.inventory_2,
                                  Colors.green.shade600,
                                  isExtraSmall)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _buildLotStatCardResponsive(
                                  'Emballages',
                                  '${produitsDuLot.length}',
                                  Icons.category,
                                  Colors.orange.shade600,
                                  isExtraSmall)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildLotStatCardResponsive(
                          'Valeur',
                          '${valeurTotale.toStringAsFixed(0)} FCFA',
                          Icons.monetization_on,
                          Colors.purple.shade600,
                          isExtraSmall),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                          child: _buildLotStatCardResponsive(
                              'Stock Total',
                              '$quantiteTotale',
                              Icons.inventory_2,
                              Colors.green.shade600,
                              isExtraSmall)),
                      SizedBox(width: isExtraSmall ? 8.0 : 16.0),
                      Expanded(
                          child: _buildLotStatCardResponsive(
                              'Valeur',
                              '${valeurTotale.toStringAsFixed(0)} FCFA',
                              Icons.monetization_on,
                              Colors.purple.shade600,
                              isExtraSmall)),
                      SizedBox(width: isExtraSmall ? 8.0 : 16.0),
                      Expanded(
                          child: _buildLotStatCardResponsive(
                              'Emballages',
                              '${produitsDuLot.length}',
                              Icons.category,
                              Colors.orange.shade600,
                              isExtraSmall)),
                    ],
                  ),
          ),
          Container(
            height: cardHeight,
            padding: EdgeInsets.symmetric(horizontal: contentPadding),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: produitsDuLot.length,
              itemBuilder: (context, index) {
                final produit = produitsDuLot[index];
                final isSelected = _produitsSelectionnes.contains(produit.id);

                return Container(
                  width: emballageWidth,
                  margin: EdgeInsets.only(right: isExtraSmall ? 8 : 12),
                  child: _buildEmballageCard(
                      produit, isSelected, canManage, isExtraSmall),
                );
              },
            ),
          ),
          SizedBox(height: isExtraSmall ? 12 : 16),
        ],
      ),
    );
  }

  Widget _buildEmballageCard(ProduitConditionne produit, bool isSelected,
      bool canManage, bool isExtraSmall) {
    return GestureDetector(
      onTap: _modeSelection ? () => _toggleProduitSelection(produit.id) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(isExtraSmall ? 8 : 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange.shade400 : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (_modeSelection)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    child: Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 16,
                      color: isSelected
                          ? Colors.orange.shade600
                          : Colors.grey.shade400,
                    ),
                  ),
                Text(
                  VenteUtils.getEmojiiForTypeEmballage(produit.typeEmballage),
                  style: TextStyle(fontSize: isExtraSmall ? 14.0 : 16.0),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    produit.typeEmballage,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isExtraSmall ? 11.0 : 13.0,
                      color: isSelected ? Colors.orange.shade800 : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Stock: ${produit.quantiteDisponible}',
              style: TextStyle(
                color:
                    isSelected ? Colors.orange.shade700 : Colors.green.shade700,
                fontWeight: FontWeight.w600,
                fontSize: isExtraSmall ? 10 : 12,
              ),
            ),
            Text(
              '${produit.prixUnitaire.toStringAsFixed(0)} FCFA',
              style: TextStyle(
                color:
                    isSelected ? Colors.orange.shade700 : Colors.blue.shade700,
                fontWeight: FontWeight.w600,
                fontSize: isExtraSmall ? 10 : 12,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _toggleLotSelection(List<ProduitConditionne> produitsDuLot) {
    setState(() {
      final tousSelectionnes =
          produitsDuLot.every((p) => _produitsSelectionnes.contains(p.id));
      if (tousSelectionnes) {
        for (final produit in produitsDuLot) {
          _produitsSelectionnes.remove(produit.id);
        }
      } else {
        for (final produit in produitsDuLot) {
          _produitsSelectionnes.add(produit.id);
        }
      }
      _updateSelectAllMode();
    });
  }

  Widget _buildLotStatCardResponsive(String title, String value, IconData icon,
      Color color, bool isExtraSmall) {
    return Container(
      padding: EdgeInsets.all(isExtraSmall ? 8 : 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isExtraSmall ? 16 : 20),
          SizedBox(height: isExtraSmall ? 4 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isExtraSmall ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isExtraSmall ? 2 : 4),
          Text(
            title,
            style: TextStyle(
              fontSize: isExtraSmall ? 9 : 11,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showPrelevementModal({ProduitConditionne? produitPreselectionne}) {
    showDialog(
      context: context,
      builder: (context) => PrelevementModal(
        produits: _produits,
        produitPreselectionne: produitPreselectionne,
        onPrelevementCree: () {
          _loadData(); // Recharger les données
        },
      ),
      barrierDismissible: false,
    );
  }
}
