import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/collecte_models.dart';
import '../models/attribution_models_v2.dart';
import '../services/firestore_attribution_service.dart';

/// 🎯 SYSTÈME D'ATTRIBUTION PRINCIPAL - FICHIER ACTIF 🎯
///
/// ✅ CE FICHIER EST LE SYSTÈME D'ATTRIBUTION PRINCIPAL UTILISÉ DANS L'APPLICATION
///
/// Utilisation:
/// - Accessible via les boutons "Attribuer à Extraction" et "Attribuer à Filtration"
/// - Dans les cartes de collecte du module Contrôle de Données
///
/// ⚠️ IMPORTANT:
/// - AttributionPageComplete est désactivé - NE PLUS L'UTILISER
/// - Toutes les modifications d'attribution doivent être faites ICI
///
/// Modal de création d'attribution depuis le module Contrôle
class ControlAttributionModal extends StatefulWidget {
  final BaseCollecte collecte;
  final AttributionType type;

  const ControlAttributionModal({
    super.key,
    required this.collecte,
    required this.type,
  });

  @override
  State<ControlAttributionModal> createState() =>
      _ControlAttributionModalState();
}

class _ControlAttributionModalState extends State<ControlAttributionModal>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _commentairesController = TextEditingController();
  final _attributionService = FirestoreAttributionService();

  // État du formulaire
  String _utilisateur = '';
  String _siteReceveur = ''; // NOUVEAU: Site qui reçoit les produits
  List<String> _selectedContenants = [];
  List<String> _availableContenants = [];

  // Liste des sites disponibles selon le type d'attribution
  final List<String> _sitesExtraction = [
    'Koudougou',
    'Bobo-Dioulasso',
    'Ouagadougou',
    'Banfora',
  ];

  final List<String> _sitesFiltrage = [
    'Koudougou',
    'Bobo-Dioulasso',
    'Ouagadougou',
  ];

  // Animation
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeForm();
    _loadAvailableContenants();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentairesController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  void _initializeForm() {
    // Remplir automatiquement l'utilisateur (simulation)
    _utilisateur =
        'Contrôleur Principal'; // TODO: Récupérer l'utilisateur connecté

    // Initialiser le premier site disponible
    final sitesDisponibles = _getSitesDisponibles();
    if (sitesDisponibles.isNotEmpty) {
      _siteReceveur = sitesDisponibles.first;
    }
  }

  List<String> _getSitesDisponibles() {
    switch (widget.type) {
      case AttributionType.extraction:
        return _sitesExtraction;
      case AttributionType.filtration:
        return _sitesFiltrage;
      case AttributionType.traitementCire:
        return _sitesFiltrage; // Use same sites as filtrage for now
    }
  }

  void _loadAvailableContenants() {
    _availableContenants = _getContenantsDisponibles(widget.collecte);
    if (_availableContenants.isNotEmpty) {
      // Sélectionner tous les contenants par défaut
      _selectedContenants = List.from(_availableContenants);
    }
    setState(() {});
  }

  /// Récupère la liste des contenants disponibles depuis une collecte
  List<String> _getContenantsDisponibles(BaseCollecte collecte) {
    List<String> contenants = [];

    if (collecte is Recolte) {
      for (int i = 0; i < collecte.contenants.length; i++) {
        // Générer un ID unique pour chaque contenant
        contenants.add('${collecte.id}_cont_${i + 1}');
      }
    } else if (collecte is Scoop) {
      for (int i = 0; i < (collecte.containersCount ?? 0); i++) {
        contenants.add('${collecte.id}_scoop_${i + 1}');
      }
    } else if (collecte is Individuel) {
      for (int i = 0; i < (collecte.containersCount ?? 0); i++) {
        contenants.add('${collecte.id}_indiv_${i + 1}');
      }
    } else {
      // Pour les autres types, utiliser le nombre de contenants
      for (int i = 0; i < (collecte.containersCount ?? 0); i++) {
        contenants.add('${collecte.id}_cont_${i + 1}');
      }
    }

    return contenants;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;
    final isDesktop = screenWidth > 800;
    final isMobile = screenWidth < 600;
    // Ultra-compact screens (very small phones or constrained windows): use full-screen modal
    final isFullScreen = screenWidth < 360 || screenHeight < 600;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: isFullScreen
                  ? EdgeInsets.zero
                  : EdgeInsets.all(isMobile ? 16 : 40),
              child: Container(
                width: isDesktop ? 600 : (isFullScreen ? screenWidth : null),
                height: isFullScreen ? screenHeight : null,
                constraints: BoxConstraints(
                  maxWidth: isDesktop
                      ? 600
                      : (isFullScreen ? screenWidth : double.infinity),
                  maxHeight: isFullScreen
                      ? screenHeight
                      : MediaQuery.of(context).size.height * 0.9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isFullScreen ? 0 : 20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize:
                      isFullScreen ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCollecteInfo(),
                              const SizedBox(height: 24),
                              _buildUtilisateurField(),
                              const SizedBox(height: 20),
                              _buildSiteReceveurField(),
                              const SizedBox(height: 20),
                              _buildContenantsSelection(),
                              const SizedBox(height: 20),
                              _buildCommentairesField(),
                              const SizedBox(height: 24),
                              _buildSummary(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 380;
    final ultraCompact = width < 340;
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getTypeGradientColors(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: _getTypeColor().withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: ultraCompact ? 42 : 50,
            height: ultraCompact ? 42 : 50,
            padding: EdgeInsets.all(ultraCompact ? 10 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: Icon(
              _getTypeIcon(),
              color: Colors.white,
              size: ultraCompact ? 20 : 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getTypeEmoji()} Attribution ${widget.type.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isCompact ? 18 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '📦 ${widget.collecte.site} • ${_formatDate(widget.collecte.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isCompact ? 12 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '⚖️ ${widget.collecte.totalWeight?.toStringAsFixed(1) ?? 'N/A'} kg • 📦 ${widget.collecte.containersCount ?? 0} contenants',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: isCompact ? 11 : 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white, size: 24),
              tooltip: 'Fermer',
            ),
          ),
        ],
      ),
    );
  }

  // Nouvelles méthodes helper pour les couleurs et icônes modernes
  List<Color> _getTypeGradientColors() {
    switch (widget.type) {
      case AttributionType.extraction:
        return [const Color(0xFF6D4C41), const Color(0xFF8D6E63)];
      case AttributionType.filtration:
        return [const Color(0xFF1E88E5), const Color(0xFF42A5F5)];
      case AttributionType.traitementCire:
        return [const Color(0xFFF57C00), const Color(0xFFFFB74D)];
    }
  }

  Color _getTypeColor() {
    switch (widget.type) {
      case AttributionType.extraction:
        return const Color(0xFF6D4C41);
      case AttributionType.filtration:
        return const Color(0xFF1E88E5);
      case AttributionType.traitementCire:
        return const Color(0xFFF57C00);
    }
  }

  IconData _getTypeIcon() {
    switch (widget.type) {
      case AttributionType.extraction:
        return Icons.science;
      case AttributionType.filtration:
        return Icons.filter_alt;
      case AttributionType.traitementCire:
        return Icons.cleaning_services;
    }
  }

  String _getTypeEmoji() {
    switch (widget.type) {
      case AttributionType.extraction:
        return '🧪';
      case AttributionType.filtration:
        return '💧';
      case AttributionType.traitementCire:
        return '🜂';
    }
  }

  Widget _buildCollecteInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            _getTypeColor().withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getTypeColor().withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: _getTypeColor().withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getTypeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: _getTypeColor(),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '📋 Détails de la collecte',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _getTypeColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Statistiques principales
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getTypeColor().withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 520;
                final veryNarrow = constraints.maxWidth < 360;
                final itemWidth = veryNarrow
                    ? constraints.maxWidth
                    : (narrow
                        ? (constraints.maxWidth - 8) / 2
                        : (constraints.maxWidth - 24) / 3);
                final children = <Widget>[
                  SizedBox(
                    width: itemWidth,
                    child: _buildStatCard(
                      '⚖️',
                      '${widget.collecte.totalWeight?.toStringAsFixed(1) ?? 'N/A'} kg',
                      'Poids total',
                    ),
                  ),
                  SizedBox(width: narrow ? 8 : 12),
                  SizedBox(
                    width: itemWidth,
                    child: _buildStatCard(
                      '📦',
                      '${widget.collecte.containersCount ?? 0}',
                      'Contenants',
                    ),
                  ),
                  SizedBox(width: narrow ? 8 : 12),
                  SizedBox(
                    width: itemWidth,
                    child: _buildStatCard(
                      '💰',
                      '${widget.collecte.totalAmount?.toStringAsFixed(0) ?? 'N/A'} F',
                      'Montant',
                    ),
                  ),
                ];
                return Wrap(
                  spacing: narrow ? 8 : 12,
                  runSpacing: 8,
                  children: children,
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Informations détaillées
          _buildModernInfoRow(Icons.location_on, 'Site', widget.collecte.site),
          _buildModernInfoRow(
              Icons.calendar_today, 'Date', _formatDate(widget.collecte.date)),
          if (widget.collecte.technicien != null)
            _buildModernInfoRow(
                Icons.person, 'Technicien', widget.collecte.technicien!),

          // Indicateur de qualité si disponible
          if (widget.collecte.totalWeight != null &&
              widget.collecte.totalWeight! > 0)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      color: Colors.green.shade600, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '✅ Collecte prête pour attribution',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getTypeColor().withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _getTypeColor(),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoRow(IconData icon, String label, String value) {
    final isNarrow = MediaQuery.of(context).size.width < 340;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _getTypeColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: _getTypeColor(),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: isNarrow ? 64 : 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilisateurField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Utilisateur',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.person, color: Colors.blue.shade600),
              const SizedBox(width: 12),
              Text(
                _utilisateur,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Automatique',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSiteReceveurField() {
    final sitesDisponibles = _getSitesDisponibles();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Site receveur *',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_city, color: Colors.orange.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Sélectionner le site destinataire',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _siteReceveur.isEmpty ? null : _siteReceveur,
                decoration: InputDecoration(
                  hintText: 'Choisir un site...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                isDense: true,
                isExpanded: true,
                items: sitesDisponibles.map((site) {
                  return DropdownMenuItem<String>(
                    value: site,
                    child: Row(
                      children: [
                        Icon(
                          _getIconForSite(site),
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            site,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                selectedItemBuilder: (context) => sitesDisponibles
                    .map((site) => Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            site,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _siteReceveur = value ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner un site receveur';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Les produits seront transférés vers ce site pour ${widget.type.label.toLowerCase()}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getIconForSite(String site) {
    switch (site.toLowerCase()) {
      case 'koudougou':
        return Icons.factory;
      case 'bobo-dioulasso':
        return Icons.business;
      case 'ouagadougou':
        return Icons.account_balance;
      case 'banfora':
        return Icons.agriculture;
      default:
        return Icons.location_city;
    }
  }

  Widget _buildContenantsSelection() {
    final isCompact = MediaQuery.of(context).size.width < 380;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Contenants à attribuer *',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const Spacer(),
            Text(
              '${_selectedContenants.length}/${_availableContenants.length} sélectionné(s)',
              style: TextStyle(
                color: Colors.blue.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_availableContenants.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade600, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Aucun contenant disponible',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tous les contenants sont déjà attribués',
                  style: TextStyle(color: Colors.orange.shade700),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Header avec actions
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: LayoutBuilder(builder: (context, c) {
                    final narrow = c.maxWidth < 360;
                    final title = Text(
                      '${_availableContenants.length} contenants disponibles',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    );
                    final actions = Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _selectAllContenants,
                          child: const Text('Tout sélectionner'),
                        ),
                        TextButton(
                          onPressed: _deselectAllContenants,
                          child: const Text('Tout désélectionner'),
                        ),
                      ],
                    );
                    if (narrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [title, const SizedBox(height: 8), actions],
                      );
                    }
                    return Row(
                      children: [Expanded(child: title), actions],
                    );
                  }),
                ),
                // Liste des contenants
                Expanded(
                  child: ListView.builder(
                    itemCount: _availableContenants.length,
                    itemBuilder: (context, index) {
                      final contenantId = _availableContenants[index];
                      final isSelected =
                          _selectedContenants.contains(contenantId);

                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.shade50 : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedContenants.add(contenantId);
                              } else {
                                _selectedContenants.remove(contenantId);
                              }
                            });
                          },
                          dense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: isCompact ? 0 : 4),
                          title: Text(
                            contenantId,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            'Contenant ${index + 1} - ${widget.type.label}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          secondary: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.type == AttributionType.extraction
                                  ? Colors.blue.shade100
                                  : Colors.purple.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.type.label,
                              style: TextStyle(
                                color: widget.type == AttributionType.extraction
                                    ? Colors.blue.shade700
                                    : Colors.purple.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_selectedContenants.isEmpty && _availableContenants.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Veuillez sélectionner au moins un contenant',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCommentairesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Commentaires',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _commentairesController,
          maxLines: 3,
          maxLength: 250,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.comment),
            hintText: 'Commentaires sur l\'attribution (optionnel)...',
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    if (_selectedContenants.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getTypeColor().withOpacity(0.08),
            Colors.white,
            _getTypeColor().withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getTypeColor().withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getTypeColor().withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du résumé
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getTypeGradientColors(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.summarize,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '📋 Résumé de l\'attribution',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedContenants.length} produits',
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
          const SizedBox(height: 16),

          // Statistiques visuelles
          LayoutBuilder(
            builder: (context, c) {
              final narrow = c.maxWidth < 420;
              if (narrow) {
                return Column(
                  children: [
                    _buildSummaryCard(
                      _getTypeIcon(),
                      widget.type.label,
                      'Type d\'attribution',
                      _getTypeColor(),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryCard(
                      Icons.inventory_2,
                      '${_selectedContenants.length}',
                      'Contenants',
                      Colors.orange.shade600,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      _getTypeIcon(),
                      widget.type.label,
                      'Type d\'attribution',
                      _getTypeColor(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      Icons.inventory_2,
                      '${_selectedContenants.length}',
                      'Contenants',
                      Colors.orange.shade600,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // Informations détaillées
          _buildModernSummaryRow(
              Icons.location_city,
              'Site receveur',
              _siteReceveur.isEmpty ? 'Non sélectionné' : _siteReceveur,
              _siteReceveur.isEmpty ? Colors.orange : Colors.green),
          _buildModernSummaryRow(
              Icons.person, 'Utilisateur', _utilisateur, Colors.blue),
          _buildModernSummaryRow(Icons.access_time, 'Date d\'attribution',
              _formatDate(DateTime.now()), Colors.purple),

          // Indicateur de statut
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle,
                    color: Colors.green.shade600, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✅ Prêt pour l\'attribution ! Tous les champs sont remplis.',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
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

  Widget _buildSummaryCard(
      IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSummaryRow(
      IconData icon, String label, String value, Color color) {
    final isNarrow = MediaQuery.of(context).size.width < 340;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: isNarrow ? 80 : 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 380;
    return SafeArea(
        top: false,
        child: Container(
          padding:
              EdgeInsets.fromLTRB(24, 16, 24, (viewInsets.bottom > 0) ? 8 : 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                _getTypeColor().withOpacity(0.03),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            border: Border(
              top: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
          ),
          child: LayoutBuilder(builder: (context, c) {
            final narrow = c.maxWidth < 420 || isCompact;
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Annuler'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade400),
                      foregroundColor: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _getTypeGradientColors(),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _getTypeColor().withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _validateAndSubmit,
                      icon: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(_getTypeIcon(), size: 18),
                      label: Text(
                        _isLoading
                            ? 'Attribution en cours...'
                            : '${_getTypeEmoji()} Confirmer Attribution',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Annuler'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade400),
                      foregroundColor: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _getTypeGradientColors(),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _getTypeColor().withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _validateAndSubmit,
                      icon: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(_getTypeIcon(), size: 18),
                      label: Text(
                        _isLoading
                            ? 'Attribution en cours...'
                            : '${_getTypeEmoji()} Confirmer Attribution',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ));
  }

  void _selectAllContenants() {
    setState(() {
      _selectedContenants = List.from(_availableContenants);
    });
  }

  void _deselectAllContenants() {
    setState(() {
      _selectedContenants.clear();
    });
  }

  Future<void> _validateAndSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedContenants.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez sélectionner au moins un contenant',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Déterminer automatiquement la nature selon le type
      final nature = widget.type == AttributionType.extraction
          ? ProductNature.brut
          : ProductNature.liquide;

      await _attributionService.creerAttributionDepuisControle(
        type: widget.type,
        natureProduitsAttribues: nature,
        utilisateur: _utilisateur,
        listeContenants: _selectedContenants,
        sourceCollecteId: widget.collecte.id,
        sourceType: _getSourceType(),
        siteOrigine: widget.collecte.site,
        siteReceveur: _siteReceveur, // NOUVEAU: Site qui reçoit les produits
        dateCollecte: widget.collecte.date,
        commentaires: _commentairesController.text.trim(),
        metadata: {
          'createdFromControl': true,
          'originalPath': widget.collecte.path,
          'totalWeight': widget.collecte.totalWeight,
          'totalAmount': widget.collecte.totalAmount,
          'siteReceveur': _siteReceveur, // Ajouter dans les métadonnées aussi
        },
      );

      Get.snackbar(
        'Attribution créée',
        '${widget.type.label} attribué avec succès',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        icon: const Icon(Icons.check_circle, color: Colors.green),
      );

      Navigator.pop(context, true); // Retourner succès
    } catch (e) {
      Get.snackbar(
        'Erreur',
        e.toString(),
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getSourceType() {
    if (widget.collecte is Recolte) return 'recoltes';
    if (widget.collecte is Scoop) return 'scoop';
    if (widget.collecte is Individuel) return 'individuel';
    return 'unknown';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
