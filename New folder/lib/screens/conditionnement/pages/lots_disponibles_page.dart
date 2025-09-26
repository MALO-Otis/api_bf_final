import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../conditionnement_edit.dart';
import 'package:flutter/material.dart';
import '../conditionnement_models.dart';
import '../../../utils/smart_appbar.dart';
import '../services/conditionnement_db_service.dart';

/// 📦 PAGE DES LOTS FILTRÉS DISPONIBLES POUR CONDITIONNEMENT
///
/// Affiche tous les lots filtrés avec leurs numéros de lot et permet de lancer le conditionnement
/// Connectée à la base de données Firestore

class LotsDisponiblesPage extends StatefulWidget {
  const LotsDisponiblesPage({super.key});

  @override
  State<LotsDisponiblesPage> createState() => _LotsDisponiblesPageState();
}

class _LotsDisponiblesPageState extends State<LotsDisponiblesPage>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Service de conditionnement
  late ConditionnementDbService _conditionnementService;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeService();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _fadeController.forward();
  }

  void _initializeService() {
    try {
      _conditionnementService = Get.find<ConditionnementDbService>();
    } catch (_) {
      _conditionnementService = Get.put(ConditionnementDbService());
    }
    // 🔁 Ecoute des enregistrements de conditionnement pour mise à jour immédiate de la liste
    ever<String?>(_conditionnementService.lastSaveId, (id) {
      if (id != null) {
        // On force un rebuild pour retirer le lot déjà conditionné
        setState(() {
          // La logique de retrait est déjà faite côté service mais on filtre au cas où
          _conditionnementService.lotsDisponibles
              .removeWhere((lot) => lot.estConditionne);
        });
      }
    });
  }

  List<LotFiltre> get _filteredLots {
    // Toujours exclure les lots déjà conditionnés par sécurité
    final idsConditionnes = _conditionnementService.conditionnements
        .map((c) => c.lotOrigine.id)
        .toSet();
    final lots = _conditionnementService.lotsDisponibles
        .where((l) =>
            !l.estConditionne &&
            l.peutEtreConditionne &&
            !idsConditionnes.contains(l.id))
        .toList();
    if (_searchQuery.isEmpty) return lots;

    return lots.where((lot) {
      return lot.lotOrigine
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          lot.technicien.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          lot.site.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          lot.predominanceFlorale
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: SmartAppBar(
        title: "📦 Lots Filtrés Disponibles",
        backgroundColor: const Color(0xFF2196F3),
        onBackPressed: () => Get.back(),
      ),
      body: Obx(() => _conditionnementService.isLoading
          ? _buildLoadingView()
          : _buildMainContent(isMobile)),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 6,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
          ),
          const SizedBox(height: 24),
          Text(
            'Chargement des lots filtrés...',
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

  Widget _buildMainContent(bool isMobile) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) => Opacity(
        opacity: _fadeAnimation.value,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeaderSection(isMobile)),
            SliverPadding(
              padding: EdgeInsets.only(
                  left: isMobile ? 16 : 24,
                  right: isMobile ? 16 : 24,
                  bottom: 40),
              sliver: _buildLotsListSliver(isMobile),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(bool isMobile) {
    final lotsDisponibles = _filteredLots.length;
    final lotsConditionnes = _conditionnementService.conditionnements.length;
    final quantiteTotale =
        _filteredLots.fold(0.0, (sum, lot) => sum + lot.quantiteRestante);

    return Container(
      margin: EdgeInsets.all(isMobile ? 16 : 24),
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Statistiques
          Row(children: [
            Expanded(
              child: _buildStatCard(
                'Lots disponibles',
                lotsDisponibles.toString(),
                Icons.inventory_2,
                isMobile,
              ),
            ),
            SizedBox(width: isMobile ? 12 : 16),
            Expanded(
              child: _buildStatCard(
                'Déjà conditionnés',
                lotsConditionnes.toString(),
                Icons.check_circle,
                isMobile,
              ),
            ),
            SizedBox(width: isMobile ? 12 : 16),
            Expanded(
              child: _buildStatCard(
                'Quantité restante',
                '${quantiteTotale.toStringAsFixed(1)} kg',
                Icons.scale,
                isMobile,
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // Barre de recherche
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Rechercher par numéro de lot, technicien, site...',
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              hintStyle: const TextStyle(color: Colors.white70),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 20,
                vertical: isMobile ? 12 : 16,
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: isMobile ? 20 : 24),
          SizedBox(height: isMobile ? 4 : 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 12 : 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isMobile ? 8 : 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Ancienne méthode list remplacée par slivers (supprimée)

  SliverList _buildLotsListSliver(bool isMobile) {
    final filteredLots = _filteredLots;
    if (filteredLots.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'Aucun lot filtré disponible'
                        : 'Aucun lot trouvé pour "$_searchQuery"',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        ]),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final lot = filteredLots[index];
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 400 + index * 90),
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 20),
                child: child,
              ),
            ),
            child: _buildLotCard(lot, isMobile),
          );
        },
        childCount: filteredLots.length,
      ),
    );
  }

  Widget _buildLotCard(LotFiltre lot, bool isMobile) {
    final isDisponible = lot.peutEtreConditionne;
    final statusColor = isDisponible ? Colors.green : Colors.orange;
    final statusText = isDisponible ? 'Disponible' : 'Déjà conditionné';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header avec numéro de lot et statut
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.1),
                  statusColor.withOpacity(0.05)
                ],
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '📦',
                    style: TextStyle(fontSize: isMobile ? 20 : 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lot.lotOrigine,
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Filtré le ${DateFormat('dd/MM/yyyy à HH:mm').format(lot.dateFiltrage)}',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenu principal
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              children: [
                // Informations principales
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Technicien',
                        lot.technicien,
                        Icons.person,
                        isMobile,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        'Site',
                        lot.site,
                        Icons.location_on,
                        isMobile,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Florale',
                        lot.predominanceFlorale,
                        Icons.local_florist,
                        isMobile,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        'Type Florale',
                        lot.typeFlorale.label,
                        Icons.local_florist,
                        isMobile,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Métriques de filtrage
                Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMetricItem(
                          'Reçu',
                          '${lot.quantiteRecue.toStringAsFixed(1)} kg',
                          Colors.blue,
                          isMobile,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: _buildMetricItem(
                          'Restant',
                          '${lot.quantiteRestante.toStringAsFixed(1)} kg',
                          Colors.green,
                          isMobile,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: _buildMetricItem(
                          'Expiration',
                          lot.filtrageExpire ? 'Expiré' : 'Valide',
                          lot.filtrageExpire ? Colors.red : Colors.green,
                          isMobile,
                        ),
                      ),
                    ],
                  ),
                ),

                // Informations sur l'expiration
                if (lot.dateExpirationFiltrage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    decoration: BoxDecoration(
                      color: lot.filtrageExpire
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: lot.filtrageExpire
                            ? Colors.red.shade200
                            : Colors.green.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          lot.filtrageExpire
                              ? Icons.warning
                              : Icons.check_circle,
                          size: 16,
                          color: lot.filtrageExpire
                              ? Colors.red.shade600
                              : Colors.green.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          lot.filtrageExpire
                              ? 'Filtrage expiré le ${DateFormat('dd/MM/yyyy').format(DateTime.parse(lot.dateExpirationFiltrage!))}'
                              : 'Valide jusqu\'au ${DateFormat('dd/MM/yyyy').format(DateTime.parse(lot.dateExpirationFiltrage!))}',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            color: lot.filtrageExpire
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        isDisponible ? () => _startConditionnement(lot) : null,
                    icon: Icon(
                      isDisponible ? Icons.play_arrow : Icons.pending_actions,
                      size: isMobile ? 18 : 20,
                    ),
                    label: Text(
                      isDisponible
                          ? 'Démarrer le conditionnement'
                          : 'Déjà conditionné',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDisponible ? const Color(0xFF4CAF50) : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 12 : 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: isDisponible ? 4 : 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
      String label, String value, IconData icon, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: isMobile ? 14 : 16,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 10 : 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMetricItem(
      String label, String value, Color color, bool isMobile) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 10 : 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  void _startConditionnement(LotFiltre lot) {
    // Convertir le modèle LotFiltre vers le format attendu par ConditionnementEditPage
    final lotFiltrageData = lot.toMap();

    Get.to(
      () => ConditionnementEditPage(lotFiltrageData: lotFiltrageData),
      transition: Transition.rightToLeftWithFade,
      duration: const Duration(milliseconds: 300),
    )?.then((result) async {
      // Si le formulaire a signalé un rafraîchissement après enregistrement
      if (result is Map && result['action'] == 'refresh') {
        // Forcer un rechargement complet des données (lots + conditionnements)
        await _conditionnementService.refreshData();
        if (mounted) {
          setState(() {}); // Sécurité : redessiner l'interface
        }
      }
    });
  }
}
