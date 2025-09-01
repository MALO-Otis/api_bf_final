import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/attribution_models.dart';
import '../models/collecte_models.dart';
import '../services/control_attribution_service.dart';

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
  final _attributionService = ControlAttributionService();

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
      // case AttributionType.traitementCire:
      //   return _sitesCire;
    }
  }

  void _loadAvailableContenants() {
    _availableContenants =
        _attributionService.getContenantsDisponibles(widget.collecte);
    if (_availableContenants.isNotEmpty) {
      // Sélectionner tous les contenants par défaut
      _selectedContenants = List.from(_availableContenants);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;
    final isMobile = screenWidth < 600;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.all(isMobile ? 16 : 40),
              child: Container(
                width: isDesktop ? 600 : null,
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 600 : double.infinity,
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.type == AttributionType.extraction
              ? [Colors.blue.shade600, Colors.blue.shade800]
              : [Colors.purple.shade600, Colors.purple.shade800],
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
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.type == AttributionType.extraction
                  ? Icons.science
                  : Icons.filter_alt,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attribuer à ${widget.type.label}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Collecte: ${widget.collecte.site} - ${_formatDate(widget.collecte.date)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCollecteInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations de la collecte',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Site', widget.collecte.site),
          _buildInfoRow('Date', _formatDate(widget.collecte.date)),
          if (widget.collecte.technicien != null)
            _buildInfoRow('Technicien', widget.collecte.technicien!),
          _buildInfoRow('Poids total',
              '${widget.collecte.totalWeight?.toStringAsFixed(1) ?? 'N/A'} kg'),
          _buildInfoRow('Montant total',
              '${widget.collecte.totalAmount?.toStringAsFixed(0) ?? 'N/A'} FCFA'),
          _buildInfoRow(
              'Contenants', '${widget.collecte.containersCount ?? 0}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
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
              style: const TextStyle(
                fontWeight: FontWeight.w600,
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
                        Text(site),
                      ],
                    ),
                  );
                }).toList(),
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
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_availableContenants.length} contenants disponibles',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      TextButton(
                        onPressed: _selectAllContenants,
                        child: const Text('Tout sélectionner'),
                      ),
                      TextButton(
                        onPressed: _deselectAllContenants,
                        child: const Text('Tout désélectionner'),
                      ),
                    ],
                  ),
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
                          title: Text(
                            contenantId,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.type == AttributionType.extraction
                ? Colors.blue.shade50
                : Colors.purple.shade50,
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.type == AttributionType.extraction
              ? Colors.blue.shade200
              : Colors.purple.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résumé de l\'attribution',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: widget.type == AttributionType.extraction
                  ? Colors.blue.shade800
                  : Colors.purple.shade800,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(Icons.assignment, 'Type', widget.type.label),
          _buildSummaryRow(Icons.location_city, 'Site receveur',
              _siteReceveur.isEmpty ? 'Non sélectionné' : _siteReceveur),
          _buildSummaryRow(
              Icons.inventory, 'Contenants', '${_selectedContenants.length}'),
          _buildSummaryRow(Icons.person, 'Utilisateur', _utilisateur),
          _buildSummaryRow(
              Icons.access_time, 'Date', _formatDate(DateTime.now())),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: widget.type == AttributionType.extraction
                ? Colors.blue.shade600
                : Colors.purple.shade600,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Annuler'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _validateAndSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.type == AttributionType.extraction
                    ? Colors.blue.shade600
                    : Colors.purple.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text('Attribuer à ${widget.type.label}'),
            ),
          ),
        ],
      ),
    );
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
