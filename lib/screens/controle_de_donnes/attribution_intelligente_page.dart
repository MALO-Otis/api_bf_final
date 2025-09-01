import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../authentication/user_session.dart';
import 'package:get/get.dart';
import 'models/attribution_models_v2.dart';
import 'models/collecte_models.dart';
import 'services/attribution_service.dart';
import 'services/firestore_data_service.dart';

class AttributionIntelligentePage extends StatefulWidget {
  const AttributionIntelligentePage({super.key});

  @override
  State<AttributionIntelligentePage> createState() =>
      _AttributionIntelligentPageState();
}

class _AttributionIntelligentPageState
    extends State<AttributionIntelligentePage> with TickerProviderStateMixin {
  final AttributionService _attributionService = AttributionService();
  final UserSession _userSession = Get.find<UserSession>();
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // État
  bool _isLoading = true;
  List<CollecteGroup> _collecteGroups = [];
  Set<String> _selectedProductIds = {};

  // Filtres et configuration
  AttributionType _selectedType = AttributionType.extraction;
  SiteAttribution? _selectedSite;
  bool _showOnlyAvailable = true;
  bool _showOnlyConforme = true;
  String _searchQuery = '';

  // Contrôleurs
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _observationsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _searchController.dispose();
    _instructionsController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await _attributionService.initialiserDonnees();
      _refreshData();

      await Future.delayed(const Duration(milliseconds: 500));
      _fadeController.forward();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _refreshData() {
    if (kDebugMode) {
      print('🔄 ATTRIBUTION UI: Actualisation des données...');
      print('   - Type sélectionné: ${_selectedType.label}');
      print('   - Seulement conformes: $_showOnlyConforme');
      print('   - Seulement disponibles: $_showOnlyAvailable');
    }

    final produits = _attributionService.filtrerProduits(
      type: _selectedType,
      seulement_conformes: _showOnlyConforme,
      seulement_disponibles: _showOnlyAvailable,
    );

    if (kDebugMode) {
      print(
          '📊 ATTRIBUTION UI: ${produits.length} produits après filtrage initial');
    }

    final filteredProduits = _searchQuery.isEmpty
        ? produits
        : _attributionService.rechercherProduits(_searchQuery);

    if (kDebugMode) {
      print(
          '🔍 ATTRIBUTION UI: ${filteredProduits.length} produits après recherche');
    }

    final produitsAttributables = filteredProduits
        .where((p) => AttributionUtils.peutEtreAttribue(p, _selectedType))
        .toList();

    if (kDebugMode) {
      print(
          '✅ ATTRIBUTION UI: ${produitsAttributables.length} produits attributables');
    }

    _collecteGroups =
        _attributionService.regrouperParCollecte(produitsAttributables);

    if (kDebugMode) {
      print(
          '📦 ATTRIBUTION UI: ${_collecteGroups.length} groupes de collectes créés');
    }

    // Nettoyer les sélections invalides
    _selectedProductIds
        .removeWhere((id) => !filteredProduits.any((p) => p.id == id));

    setState(() {});
  }

  void _onTypeChanged(AttributionType? type) {
    if (type != null) {
      setState(() {
        _selectedType = type;
        _selectedProductIds.clear();
      });
      _refreshData();
    }
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _refreshData();
  }

  void _toggleProductSelection(String productId) {
    setState(() {
      if (_selectedProductIds.contains(productId)) {
        _selectedProductIds.remove(productId);
      } else {
        _selectedProductIds.add(productId);
      }
    });
  }

  void _toggleGroupSelection(CollecteGroup group) {
    final availableProducts = group.produits
        .where((p) => AttributionUtils.peutEtreAttribue(p, _selectedType))
        .map((p) => p.id)
        .toSet();

    setState(() {
      if (availableProducts.every((id) => _selectedProductIds.contains(id))) {
        // Tout déselectionner
        _selectedProductIds.removeAll(availableProducts);
      } else {
        // Tout sélectionner
        _selectedProductIds.addAll(availableProducts);
      }
    });
  }

  Future<void> _creerAttribution() async {
    if (!_formKey.currentState!.validate() ||
        _selectedSite == null ||
        _selectedProductIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Veuillez remplir tous les champs requis et sélectionner au moins un produit'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final attributionId = await _attributionService.creerAttribution(
        type: _selectedType,
        siteDestination: _selectedSite!,
        produitsIds: _selectedProductIds.toList(),
        attributeurId: _userSession.uid ?? '',
        attributeurNom: _userSession.nom ?? '',
        instructions: _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
        observations: _observationsController.text.trim().isEmpty
            ? null
            : _observationsController.text.trim(),
      );

      Navigator.of(context).pop(); // Fermer loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attribution créée avec succès (ID: $attributionId)'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Voir',
            onPressed: () {
              // Navigation vers les détails de l'attribution
            },
          ),
        ),
      );

      // Réinitialiser le formulaire
      _selectedProductIds.clear();
      _selectedSite = null;
      _instructionsController.clear();
      _observationsController.clear();

      _refreshData();
    } catch (e) {
      Navigator.of(context).pop(); // Fermer loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la création: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // 🔧 SÉCURITÉ: Vérification des contraintes pour éviter les crashes
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Attribution Intelligente',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
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
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildConfigurationHeader(theme, isMobile),
                    if (_selectedProductIds.isNotEmpty)
                      _buildSelectionSummary(theme),
                    Expanded(
                      child: isMobile
                          ? _buildMobileContent(theme)
                          : _buildDesktopContent(theme),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar:
          _selectedProductIds.isNotEmpty ? _buildBottomActionBar(theme) : null,
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(Colors.deepPurple.shade700),
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement des produits contrôlés...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationHeader(ThemeData theme, bool isMobile) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type d'attribution
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.science, color: Colors.deepPurple.shade700),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Type d\'attribution',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 🔧 CORRECTION: Gestion responsivité améliorée
          if (isMobile)
            ..._buildMobileTypeSelector()
          else
            ..._buildDesktopTypeSelector(),

          const SizedBox(height: 16),

          // Filtres et recherche
          if (isMobile) ..._buildMobileFilters() else ..._buildDesktopFilters(),
        ],
      ),
    );
  }

  List<Widget> _buildDesktopTypeSelector() {
    return [
      // 🔧 CORRECTION: Ajout de mainAxisSize pour éviter les contraintes infinies
      Row(
        mainAxisSize: MainAxisSize.min,
        children: AttributionType.values.map((type) {
          final isSelected = _selectedType == type;
          return Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () => _onTypeChanged(type),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AttributionUtils.getCouleurAttribution(type)
                            .withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AttributionUtils.getCouleurAttribution(type)
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        AttributionUtils.getIconeAttribution(type),
                        size: 32,
                        color: isSelected
                            ? AttributionUtils.getCouleurAttribution(type)
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        type.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AttributionUtils.getCouleurAttribution(type)
                              : Colors.grey.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ];
  }

  List<Widget> _buildMobileTypeSelector() {
    return [
      DropdownButtonFormField<AttributionType>(
        value: _selectedType,
        decoration: InputDecoration(
          labelText: 'Type d\'attribution',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: AttributionType.values.map((type) {
          return DropdownMenuItem(
            value: type,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AttributionUtils.getIconeAttribution(type),
                  size: 20,
                  color: AttributionUtils.getCouleurAttribution(type),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(type.label,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        type.description,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: _onTypeChanged,
      ),
    ];
  }

  List<Widget> _buildDesktopFilters() {
    return [
      // 🔧 CORRECTION: Contraintes bornées pour éviter les erreurs de layout
      LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              // Recherche
              SizedBox(
                width: constraints.maxWidth * 0.6,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par code, producteur, village...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(width: 12),

              // Filtres rapides
              SizedBox(
                width: constraints.maxWidth * 0.35,
                child: Row(
                  children: [
                    Flexible(
                      child: CheckboxListTile(
                        title: const Text('Disponibles',
                            style: TextStyle(fontSize: 11)),
                        value: _showOnlyAvailable,
                        onChanged: (value) {
                          setState(() => _showOnlyAvailable = value ?? true);
                          _refreshData();
                        },
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    Flexible(
                      child: CheckboxListTile(
                        title: const Text('Conformes',
                            style: TextStyle(fontSize: 11)),
                        value: _showOnlyConforme,
                        onChanged: (value) {
                          setState(() => _showOnlyConforme = value ?? true);
                          _refreshData();
                        },
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ];
  }

  List<Widget> _buildMobileFilters() {
    return [
      TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onChanged: _onSearchChanged,
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: CheckboxListTile(
              title: const Text('Disponibles', style: TextStyle(fontSize: 13)),
              value: _showOnlyAvailable,
              onChanged: (value) {
                setState(() => _showOnlyAvailable = value ?? true);
                _refreshData();
              },
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
          Expanded(
            child: CheckboxListTile(
              title: const Text('Conformes', style: TextStyle(fontSize: 13)),
              value: _showOnlyConforme,
              onChanged: (value) {
                setState(() => _showOnlyConforme = value ?? true);
                _refreshData();
              },
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildSelectionSummary(ThemeData theme) {
    final selectedProducts = _selectedProductIds
        .map((id) => _collecteGroups
            .expand((g) => g.produits)
            .firstWhere((p) => p.id == id))
        .toList();

    final totalPoids =
        selectedProducts.fold<double>(0.0, (sum, p) => sum + p.poids);

    return Container(
      color: Colors.deepPurple.shade50,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.deepPurple.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_selectedProductIds.length} produit(s) sélectionné(s) • ${totalPoids.toStringAsFixed(1)} kg',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple.shade700,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => setState(() => _selectedProductIds.clear()),
            icon: const Icon(Icons.clear_all),
            label: const Text('Tout désélectionner'),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileContent(ThemeData theme) {
    if (_collecteGroups.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _collecteGroups.length,
      itemBuilder: (context, index) {
        final group = _collecteGroups[index];
        return _buildMobileCollecteCard(group, theme);
      },
    );
  }

  Widget _buildDesktopContent(ThemeData theme) {
    if (_collecteGroups.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _collecteGroups.length,
      itemBuilder: (context, index) {
        final group = _collecteGroups[index];
        return _buildDesktopCollecteCard(group, theme);
      },
    );
  }

  Widget _buildMobileCollecteCard(CollecteGroup group, ThemeData theme) {
    final availableProducts = group.produits
        .where((p) => AttributionUtils.peutEtreAttribue(p, _selectedType))
        .toList();

    if (availableProducts.isEmpty) return const SizedBox.shrink();

    final allSelected =
        availableProducts.every((p) => _selectedProductIds.contains(p.id));
    final someSelected =
        availableProducts.any((p) => _selectedProductIds.contains(p.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Checkbox(
          value: allSelected ? true : (someSelected ? null : false),
          tristate: true,
          onChanged: (value) => _toggleGroupSelection(group),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    AttributionUtils.getCouleurTypeCollecte(group.typeCollecte)
                        .withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                group.typeCollecte.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AttributionUtils.getCouleurTypeCollecte(
                      group.typeCollecte),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                group.producteur,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
                '${group.siteOrigine} • ${DateFormat('dd/MM/yyyy').format(group.dateCollecte)}'),
            Text('${availableProducts.length} produit(s) disponible(s)'),
            const SizedBox(height: 4),
            _buildControlStatusIndicator(group),
          ],
        ),
        children: availableProducts
            .map((produit) => _buildMobileProductTile(produit, theme))
            .toList(),
      ),
    );
  }

  Widget _buildDesktopCollecteCard(CollecteGroup group, ThemeData theme) {
    final availableProducts = group.produits
        .where((p) => AttributionUtils.peutEtreAttribue(p, _selectedType))
        .toList();

    if (availableProducts.isEmpty) return const SizedBox.shrink();

    final allSelected =
        availableProducts.every((p) => _selectedProductIds.contains(p.id));
    final someSelected =
        availableProducts.any((p) => _selectedProductIds.contains(p.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(20),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        leading: Checkbox(
          value: allSelected ? true : (someSelected ? null : false),
          tristate: true,
          onChanged: (value) => _toggleGroupSelection(group),
        ),
        title: Row(
          children: [
            Icon(
              AttributionUtils.getIconeTypeCollecte(group.typeCollecte),
              color:
                  AttributionUtils.getCouleurTypeCollecte(group.typeCollecte),
              size: 24,
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    AttributionUtils.getCouleurTypeCollecte(group.typeCollecte)
                        .withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                group.typeCollecte.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AttributionUtils.getCouleurTypeCollecte(
                      group.typeCollecte),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.producteur,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${group.siteOrigine} • Collecté le ${DateFormat('dd/MM/yyyy').format(group.dateCollecte)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${availableProducts.length} produit(s)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${availableProducts.fold<double>(0.0, (sum, p) => sum + p.poids).toStringAsFixed(1)} kg',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                _buildControlStatusIndicator(group),
              ],
            ),
          ],
        ),
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const SizedBox(width: 40), // Checkbox space
                const Expanded(
                    flex: 2,
                    child: Text('Code',
                        style: TextStyle(fontWeight: FontWeight.w600))),
                const Expanded(
                    flex: 2,
                    child: Text('Village',
                        style: TextStyle(fontWeight: FontWeight.w600))),
                const Expanded(
                    flex: 2,
                    child: Text('Nature',
                        style: TextStyle(fontWeight: FontWeight.w600))),
                const Expanded(
                    flex: 1,
                    child: Text('Poids',
                        style: TextStyle(fontWeight: FontWeight.w600))),
                const Expanded(
                    flex: 2,
                    child: Text('Qualité',
                        style: TextStyle(fontWeight: FontWeight.w600))),
                const Expanded(
                    flex: 2,
                    child: Text('Prédominance',
                        style: TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Products
          ...availableProducts
              .map((produit) => _buildDesktopProductRow(produit, theme)),
        ],
      ),
    );
  }

  Widget _buildMobileProductTile(ProductControle produit, ThemeData theme) {
    final isSelected = _selectedProductIds.contains(produit.id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) => _toggleProductSelection(produit.id),
        contentPadding: const EdgeInsets.all(12),
        title: Row(
          children: [
            // 🆕 Badge du type de collecte
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AttributionUtils.getCouleurTypeCollecte(
                        produit.typeCollecte)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AttributionUtils.getCouleurTypeCollecte(
                      produit.typeCollecte),
                  width: 0.5,
                ),
              ),
              child: Text(
                produit.typeCollecte.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AttributionUtils.getCouleurTypeCollecte(
                      produit.typeCollecte),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Code contenant
            Expanded(
              child: Text(
                produit.codeContenant,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 🆕 Statut de contrôle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: produit.estConforme
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: produit.estConforme ? Colors.green : Colors.orange,
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    produit.estConforme ? Icons.verified : Icons.pending,
                    size: 12,
                    color: produit.estConforme ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    produit.estConforme ? 'Conforme' : 'En attente',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: produit.estConforme
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // 🆕 Ligne 1: Nature et poids
            Row(
              children: [
                Icon(
                  AttributionUtils.getIconeNature(produit.nature),
                  size: 16,
                  color: AttributionUtils.getCouleurNature(produit.nature),
                ),
                const SizedBox(width: 4),
                Text(
                  produit.nature.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AttributionUtils.getCouleurNature(produit.nature),
                  ),
                ),
                const Spacer(),
                Icon(Icons.scale, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${produit.poids.toStringAsFixed(1)} kg',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // 🆕 Ligne 2: Localisation et producteur
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${produit.village} • ${produit.siteOrigine}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // 🆕 Ligne 3: Producteur et collecteur
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    produit.producteur,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // 🆕 Ligne 4: Prédominance florale et qualité
            Row(
              children: [
                Icon(Icons.local_florist,
                    size: 14, color: Colors.amber.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    produit.predominanceFlorale,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 🆕 Qualité
                if (produit.qualite.isNotEmpty &&
                    produit.qualite != 'Non contrôlée') ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      produit.qualite,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            // 🆕 Ligne 5: Date de réception
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Réceptionné le ${DateFormat('dd/MM/yyyy').format(produit.dateReception)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            // 🆕 Affichage des non-conformités
            if (!produit.estConforme && produit.causeNonConformite != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.warning, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      produit.causeNonConformite ?? 'Non conforme',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopProductRow(ProductControle produit, ThemeData theme) {
    final isSelected = _selectedProductIds.contains(produit.id);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.deepPurple.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (value) => _toggleProductSelection(produit.id),
          ),
          Expanded(
            flex: 2,
            child: Text(
              produit.codeContenant,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(produit.village),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  AttributionUtils.getIconeNature(produit.nature),
                  size: 16,
                  color: AttributionUtils.getCouleurNature(produit.nature),
                ),
                const SizedBox(width: 4),
                Text(produit.nature.label),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text('${produit.poids.toStringAsFixed(1)} kg'),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                if (!produit.estConforme) ...[
                  Icon(Icons.warning, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                ],
                Expanded(child: Text(produit.qualite)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              produit.predominanceFlorale,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun produit disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Modifiez vos filtres ou attendez de nouveaux contrôles',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Site de destination
          DropdownButtonFormField<SiteAttribution>(
            value: _selectedSite,
            decoration: InputDecoration(
              labelText: 'Site de destination *',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: SiteAttribution.values.map((site) {
              return DropdownMenuItem(
                value: site,
                child: Text(site.nom),
              );
            }).toList(),
            onChanged: (site) => setState(() => _selectedSite = site),
            validator: (value) => value == null ? 'Site requis' : null,
          ),

          const SizedBox(height: 12),

          // Instructions (optionnel)
          TextFormField(
            controller: _instructionsController,
            decoration: InputDecoration(
              labelText: 'Instructions (optionnel)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            maxLines: 2,
          ),

          const SizedBox(height: 16),

          // Bouton d'action
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _creerAttribution,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.assignment_turned_in),
              label: Text(
                'Créer l\'attribution (${_selectedProductIds.length} produit(s))',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget pour afficher l'état de contrôle d'une collecte
  Widget _buildControlStatusIndicator(CollecteGroup group) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getCollecteControlStatus(group),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 12,
            width: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final status = snapshot.data!;
        final pourcentage = status['pourcentageControle'] as int;
        final totalContenants = status['totalContenants'] as int;
        final contenantsControles = status['contenantsControles'] as int;
        final estTotalementControle = status['estTotalementControle'] as bool;

        Color couleurIndicateur;
        IconData iconeIndicateur;
        String texteStatut;

        if (estTotalementControle) {
          couleurIndicateur = Colors.green;
          iconeIndicateur = Icons.check_circle;
          texteStatut = 'Tous les contenants contrôlés';
        } else if (contenantsControles > 0) {
          couleurIndicateur = Colors.orange;
          iconeIndicateur = Icons.pie_chart;
          texteStatut =
              '$contenantsControles/$totalContenants contrôlés ($pourcentage%)';
        } else {
          couleurIndicateur = Colors.red;
          iconeIndicateur = Icons.error;
          texteStatut = 'Aucun contenant contrôlé';
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconeIndicateur,
              size: 14,
              color: couleurIndicateur,
            ),
            const SizedBox(width: 4),
            Text(
              texteStatut,
              style: TextStyle(
                fontSize: 12,
                color: couleurIndicateur,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Obtient l'état de contrôle d'une collecte
  Future<Map<String, dynamic>> _getCollecteControlStatus(
      CollecteGroup group) async {
    // Trouver la collecte originale dans les données Firestore
    final allCollectes = await FirestoreDataService.getCollectesFromFirestore();

    BaseCollecte? collecteOriginale;
    for (final section in allCollectes.keys) {
      final collectes = allCollectes[section] ?? [];
      for (final collecte in collectes) {
        if (collecte.id == group.collecteId) {
          collecteOriginale = collecte;
          break;
        }
      }
      if (collecteOriginale != null) break;
    }

    if (collecteOriginale != null) {
      return await _attributionService
          .getCollecteControlStatus(collecteOriginale);
    }

    // Fallback si la collecte n'est pas trouvée
    return {
      'totalContenants': group.produits.length,
      'contenantsControles':
          group.produits.length, // Tous les produits affichés sont contrôlés
      'contenantsNonControles': 0,
      'contenantsConformes': group.produits.where((p) => p.estConforme).length,
      'contenantsNonConformes':
          group.produits.where((p) => !p.estConforme).length,
      'estTotalementControle': true,
      'pourcentageControle': 100,
    };
  }
}
