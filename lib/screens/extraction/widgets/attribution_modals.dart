import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/attribution_models.dart';
import '../models/extraction_models.dart';

/// Modal de création/modification d'attribution
class AttributionFormModal extends StatefulWidget {
  final AttributionExtraction? attribution;
  final List<ExtractionProduct> availableProducts;
  final List<String> utilisateurs;

  const AttributionFormModal({
    super.key,
    this.attribution,
    required this.availableProducts,
    required this.utilisateurs,
  });

  @override
  State<AttributionFormModal> createState() => _AttributionFormModalState();
}

class _AttributionFormModalState extends State<AttributionFormModal>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs
  final _lotController = TextEditingController();
  final _commentairesController = TextEditingController();

  // État du formulaire
  String? _selectedUtilisateur;
  List<String> _selectedProductIds = [];
  AttributionStatus _selectedStatut = AttributionStatus.attribueExtraction;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  bool get _isEdit => widget.attribution != null;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeForm();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _lotController.dispose();
    _commentairesController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  void _initializeForm() {
    if (_isEdit) {
      final attribution = widget.attribution!;
      _lotController.text = attribution.lotId;
      _selectedUtilisateur = attribution.utilisateur;
      _selectedProductIds = List.from(attribution.listeContenants);
      _selectedStatut = attribution.statut;
      _commentairesController.text = attribution.commentaires ?? '';
    } else {
      _selectedUtilisateur =
          widget.utilisateurs.isNotEmpty ? widget.utilisateurs.first : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _slideAnimation.value)),
          child: Opacity(
            opacity: _slideAnimation.value,
            child: Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: isDesktop ? 700 : null,
                constraints: BoxConstraints(
                  maxWidth:
                      isDesktop ? 700 : MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildUtilisateurField(),
                              const SizedBox(height: 20),
                              _buildLotField(),
                              const SizedBox(height: 20),
                              if (_isEdit) ...[
                                _buildStatutField(),
                                const SizedBox(height: 20),
                              ],
                              _buildProductSelection(),
                              const SizedBox(height: 20),
                              _buildCommentairesField(),
                              const SizedBox(height: 20),
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
          colors: [Colors.blue.shade600, Colors.purple.shade600],
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
              _isEdit ? Icons.edit : Icons.add,
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
                  _isEdit ? 'Modifier l\'attribution' : 'Nouvelle attribution',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isEdit
                      ? 'Lot ${widget.attribution!.lotId}'
                      : 'Créer une nouvelle attribution',
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

  Widget _buildUtilisateurField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Utilisateur *',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedUtilisateur,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.person),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: widget.utilisateurs.map((utilisateur) {
            return DropdownMenuItem(
              value: utilisateur,
              child: Text(utilisateur),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedUtilisateur = value);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez sélectionner un utilisateur';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLotField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Numéro de lot *',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _lotController,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.qr_code),
            hintText: 'Ex: LOT_2024001',
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9_-]')),
            LengthLimitingTextInputFormatter(20),
          ],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le numéro de lot est obligatoire';
            }
            if (value.trim().length < 3) {
              return 'Le numéro de lot doit contenir au moins 3 caractères';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStatutField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statut',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<AttributionStatus>(
          value: _selectedStatut,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.flag),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: AttributionStatus.values.map((statut) {
            return DropdownMenuItem(
              value: statut,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getStatusColor(statut),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(statut.label),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedStatut = value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildProductSelection() {
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
              '${_selectedProductIds.length} sélectionné(s)',
              style: TextStyle(
                color: Colors.blue.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: widget.availableProducts.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Aucun contenant disponible',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.availableProducts.length,
                  itemBuilder: (context, index) {
                    final product = widget.availableProducts[index];
                    final isSelected = _selectedProductIds.contains(product.id);

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
                              _selectedProductIds.add(product.id);
                            } else {
                              _selectedProductIds.remove(product.id);
                            }
                          });
                        },
                        title: Text(
                          product.nom,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          '${product.type.label} - ${product.poidsTotal}kg - ${product.origine}',
                        ),
                        secondary: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getProductStatusColor(product.statut),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product.statut.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (_selectedProductIds.isEmpty)
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
          maxLength: 200,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.comment),
            hintText: 'Commentaires ou instructions spéciales...',
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    if (_selectedProductIds.isEmpty) return const SizedBox();

    final selectedProducts = widget.availableProducts
        .where((p) => _selectedProductIds.contains(p.id))
        .toList();

    final totalPoids =
        selectedProducts.fold<double>(0, (sum, p) => sum + p.poidsTotal);
    final totalContenants = selectedProducts.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Résumé de l\'attribution',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.inventory, color: Colors.blue.shade600, size: 18),
              const SizedBox(width: 8),
              Text(
                  '$totalContenants contenant(s) - ${totalPoids.toStringAsFixed(1)} kg'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.person, color: Colors.green.shade600, size: 18),
              const SizedBox(width: 8),
              Text('Attribué à: ${_selectedUtilisateur ?? "Non sélectionné"}'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.qr_code, color: Colors.orange.shade600, size: 18),
              const SizedBox(width: 8),
              Text(
                  'Lot: ${_lotController.text.isEmpty ? "Non défini" : _lotController.text}'),
            ],
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
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _validateAndSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(_isEdit ? 'Modifier' : 'Créer'),
          ),
        ],
      ),
    );
  }

  void _validateAndSave() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProductIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un contenant'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = {
      'utilisateur': _selectedUtilisateur!,
      'lotId': _lotController.text.trim(),
      'listeContenants': _selectedProductIds,
      'statut': _selectedStatut,
      'commentaires': _commentairesController.text.trim(),
      'metadata': {
        'totalContenants': _selectedProductIds.length,
        'dateCreation': DateTime.now().toIso8601String(),
      },
    };

    Navigator.pop(context, result);
  }

  Color _getStatusColor(AttributionStatus statut) {
    switch (statut) {
      case AttributionStatus.attribueExtraction:
        return Colors.blue;
      case AttributionStatus.enCoursExtraction:
        return Colors.orange;
      case AttributionStatus.extraitEnAttente:
        return Colors.purple;
      case AttributionStatus.attribueMaturation:
        return Colors.teal;
      case AttributionStatus.enCoursMaturation:
        return Colors.indigo;
      case AttributionStatus.termineMaturation:
        return Colors.green;
      case AttributionStatus.annule:
        return Colors.red;
    }
  }

  Color _getProductStatusColor(ExtractionStatus statut) {
    switch (statut) {
      case ExtractionStatus.enAttente:
        return Colors.grey;
      case ExtractionStatus.enCours:
        return Colors.orange;
      case ExtractionStatus.termine:
        return Colors.green;
      case ExtractionStatus.suspendu:
        return Colors.red;
      case ExtractionStatus.erreur:
        return Colors.deepOrange;
    }
  }
}
