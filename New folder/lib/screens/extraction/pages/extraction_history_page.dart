import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/extraction_models_v2.dart';
import '../services/extraction_service_v2.dart';
import '../../../authentication/user_session.dart';

/// Page pour l'historique des extractions avec statistiques
class ExtractionHistoryPage extends StatefulWidget {
  const ExtractionHistoryPage({super.key});

  @override
  State<ExtractionHistoryPage> createState() => _ExtractionHistoryPageState();
}

class _ExtractionHistoryPageState extends State<ExtractionHistoryPage>
    with TickerProviderStateMixin {
  final ExtractionServiceV2 _service = ExtractionServiceV2();

  // État de l'application
  List<ExtractionData> _extractions = [];
  ExtractionStatistics? _statistics;
  bool _isLoading = true;
  String _searchQuery = '';

  // Contrôleurs d'animation
  late AnimationController _refreshController;
  late AnimationController _scrollButtonController;

  // Contrôleurs de texte et scroll
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Timer pour l'horloge temps réel
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

  // État du scroll pour les boutons de navigation
  bool _showScrollButtons = false;
  bool _isNearTop = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
    _startClock();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _scrollButtonController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _clockTimer?.cancel();
    super.dispose();
  }

  void _initializeAnimations() {
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scrollButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Écouter le scroll pour les boutons de navigation
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted)
      return; // ✅ CORRECTION: Vérifier si le widget est encore monté

    final offset = _scrollController.offset;

    // Afficher les boutons après 100px de scroll
    final shouldShow = offset > 100;
    // Détecter si on est près du haut (dans les premiers 200px)
    final nearTop = offset < 200;

    if (shouldShow != _showScrollButtons || nearTop != _isNearTop) {
      setState(() {
        _showScrollButtons = shouldShow;
        _isNearTop = nearTop;
      });

      if (shouldShow) {
        _scrollButtonController.forward();
      } else {
        _scrollButtonController.reverse();
      }
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      } else {
        // ✅ CORRECTION: Annuler le timer si le widget est détruit
        timer.cancel();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _refreshController.forward();

    try {
      final userSession = Get.find<UserSession>();
      final site = userSession.site ?? 'Koudougou';

      debugPrint('🔄 [Historique] Chargement des extractions pour site: $site');

      // Charger extractions et statistiques en parallèle
      final results = await Future.wait([
        _service.getExtractionsPourSite(site),
        _service.getStatistiquesPourSite(site),
      ]);

      _extractions = results[0] as List<ExtractionData>;
      _statistics = results[1] as ExtractionStatistics?;

      // Appliquer la recherche
      _applySearch();

      debugPrint('✅ [Historique] ${_extractions.length} extractions chargées');
    } catch (e) {
      debugPrint('❌ [Historique] Erreur chargement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _refreshController.reverse();
      }
    }
  }

  void _applySearch() {
    // Implémentation future pour filtrer les extractions
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? _buildLoadingState()
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  controller: _scrollController,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      children: [
                        // ✅ En-tête maintenant scrollable
                        _buildHeader(theme),

                        // Statistiques si disponibles
                        if (_statistics != null) _buildStatisticsCards(theme),
                        const SizedBox(height: 16),

                        // Barre de recherche
                        _buildSearchBar(theme),
                        const SizedBox(height: 16),

                        // Liste des extractions ou état vide
                        _extractions.isEmpty
                            ? Container(
                                height: 300,
                                child: _buildEmptyState(),
                              )
                            : Column(
                                children: _extractions.map((extraction) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      left: 16,
                                      right: 16,
                                      bottom: 12,
                                    ),
                                    child: _buildExtractionCard(extraction),
                                  );
                                }).toList(),
                              ),

                        // Espacement final pour éviter que le FAB cache le contenu
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Boutons de navigation (haut/bas) - apparaissent lors du scroll
          if (_showScrollButtons) ...[
            ScaleTransition(
              scale: _scrollButtonController,
              child: FloatingActionButton(
                heroTag: 'fab-scroll-navigation',
                mini: true,
                onPressed: _isNearTop ? _scrollToBottom : _scrollToTop,
                backgroundColor:
                    theme.colorScheme.secondary.withValues(alpha: 0.9),
                child: Icon(
                  _isNearTop
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_up,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Bouton de refresh principal
          FloatingActionButton(
            heroTag: 'fab-refresh-history',
            onPressed: _loadData,
            backgroundColor: theme.colorScheme.primary,
            child: RotationTransition(
              turns: _refreshController,
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historique des Extractions',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Suivi et statistiques des extractions réalisées',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(ThemeData theme) {
    final stats = _statistics!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Extractions',
              '${stats.totalExtractions}',
              Icons.science,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Quantité Totale',
              '${stats.quantiteTotaleExtraite.toStringAsFixed(1)} kg',
              Icons.scale,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Rendement Moyen',
              '${stats.rendementMoyen.toStringAsFixed(1)}%',
              Icons.trending_up,
              stats.rendementMoyen >= 80 ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher par extracteur, date...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: theme.cardColor,
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _applySearch();
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement de l\'historique...'),
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
            Icons.history,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune extraction dans l\'historique',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les extractions réalisées apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // Cette méthode n'est plus nécessaire car on utilise maintenant
  // une Column avec les extractions dans le SingleChildScrollView

  Widget _buildExtractionCard(ExtractionData extraction) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showExtractionDetails(extraction),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatutColor(extraction.statut)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      extraction.statut.label,
                      style: TextStyle(
                        color: _getStatutColor(extraction.statut),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(extraction.dateExtraction),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Informations principales
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Extracteur: ${extraction.extracteur}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Technologie: ${extraction.technologie.label}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${extraction.quantiteExtraiteReelle.toStringAsFixed(1)} kg',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade600,
                          ),
                        ),
                        Text(
                          'extraits',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Statistiques
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniStat('${extraction.nombreContenants} contenants',
                      Icons.inventory_2),
                  _buildMiniStat(
                      '${extraction.rendementExtraction.toStringAsFixed(1)}%',
                      Icons.trending_up),
                  _buildMiniStat(
                      '${extraction.residusRestants.toStringAsFixed(1)} kg résidus',
                      Icons.delete_outline),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String text, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Color _getStatutColor(StatutExtraction statut) {
    switch (statut) {
      case StatutExtraction.terminee:
        return Colors.green;
      case StatutExtraction.en_cours:
        return Colors.blue;
      case StatutExtraction.annulee:
        return Colors.red;
    }
  }

  void _showExtractionDetails(ExtractionData extraction) {
    showDialog(
      context: context,
      builder: (context) => _ExtractionDetailsDialog(extraction: extraction),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Dialog pour afficher les détails d'une extraction
class _ExtractionDetailsDialog extends StatelessWidget {
  final ExtractionData extraction;

  const _ExtractionDetailsDialog({required this.extraction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Icon(Icons.science, color: Colors.green.shade600, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Détails de l\'Extraction',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${extraction.id}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informations générales
                    _buildDetailSection(
                      'Informations Générales',
                      Icons.info_outline,
                      [
                        _buildDetailRow('Extracteur', extraction.extracteur),
                        _buildDetailRow('Site', extraction.siteExtraction),
                        _buildDetailRow('Date d\'extraction',
                            _formatDate(extraction.dateExtraction)),
                        _buildDetailRow(
                            'Technologie', extraction.technologie.label),
                        _buildDetailRow('Statut', extraction.statut.label),
                        if (extraction.observations != null)
                          _buildDetailRow(
                              'Observations', extraction.observations!),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Quantités
                    _buildDetailSection(
                      'Quantités et Rendement',
                      Icons.scale,
                      [
                        _buildDetailRow('Poids total disponible',
                            '${extraction.poidsTotal.toStringAsFixed(1)} kg'),
                        _buildDetailRow('Quantité extraite',
                            '${extraction.quantiteExtraiteReelle.toStringAsFixed(1)} kg'),
                        _buildDetailRow('Résidus restants',
                            '${extraction.residusRestants.toStringAsFixed(1)} kg'),
                        _buildDetailRow('Rendement',
                            '${extraction.rendementExtraction.toStringAsFixed(1)}%'),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Produits extraits
                    _buildDetailSection(
                      'Produits Extraits (${extraction.nombreContenants})',
                      Icons.inventory_2,
                      extraction.produitsExtraction
                          .map((produit) => _buildProductRow(produit))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(
      String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.green.shade600, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(dynamic produit) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              produit.codeContenant,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text('${produit.producteur} • ${produit.village}'),
                ),
                Text(
                  '${produit.poidsTotal.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
