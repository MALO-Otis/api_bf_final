/*
/// ⚠️ CODE COMPLÈTEMENT COMMENTÉ - NE PLUS UTILISER ⚠️
/// Ces modals d'attribution ne sont plus utilisés.
/// Le nouveau modal ModernAttributionModal est dans AttributionPageComplete.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';

/// 🎯 MODAL D'ATTRIBUTION
///
/// Modal pour confirmer l'attribution d'un produit à un processus
class AttributionModal extends StatefulWidget {
  final ProductControle produit;
  final AttributionType type;
  final Function(Map<String, dynamic>) onConfirm;

  const AttributionModal({
    Key? key,
    required this.produit,
    required this.type,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<AttributionModal> createState() => _AttributionModalState();
}

class _AttributionModalState extends State<AttributionModal> {
  final _formKey = GlobalKey<FormState>();
  final _siteReceveurController = TextEditingController();
  final _commentairesController = TextEditingController();
  bool _isLoading = false;

  final List<String> _sites = [
    'Koudougou',
    'Bobo-Dioulasso',
    'Ouagadougou',
    'Réo'
  ];

  @override
  void dispose() {
    _siteReceveurController.dispose();
    _commentairesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildProductInfo(),
              const SizedBox(height: 24),
              _buildSiteReceveur(),
              const SizedBox(height: 16),
              _buildCommentaires(),
              const SizedBox(height: 24),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getTypeColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getTypeIcon(),
            color: _getTypeColor(),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attribution ${widget.type.label}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _getTypeDescription(),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
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
    );
  }

  Widget _buildProductInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2, color: Colors.grey[700], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Informations du Produit',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
              'Code Contenant', widget.produit.codeContenant, Icons.qr_code),
          _buildInfoRow('Producteur', widget.produit.producteur, Icons.person),
          _buildInfoRow(
              'Localisation',
              '${widget.produit.village} - ${widget.produit.commune}',
              Icons.location_on),
          _buildInfoRow(
              'Nature Produit', widget.produit.nature.label, Icons.inventory_2),
          const SizedBox(height: 8),
          _buildWeightSection(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, [IconData? icon]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: icon != null ? 100 : 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section des poids basée sur les contrôles qualité
  Widget _buildWeightSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.scale, color: Colors.blue[700], size: 16),
              const SizedBox(width: 6),
              Text(
                'Poids Enregistrés (Contrôle Qualité)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildWeightItem(
                  'Poids Total',
                  widget.produit.poidsTotal,
                  Colors.blue[600]!,
                  Icons.inventory,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildWeightItem(
                  'Poids Miel',
                  widget.produit.poidsMiel,
                  Colors.green[600]!,
                  Icons.water_drop,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '✅ Produit contrôlé et conforme pour attribution',
            style: TextStyle(
              fontSize: 11,
              color: Colors.green[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget pour afficher un élément de poids
  Widget _buildWeightItem(
      String label, double weight, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            '${weight.toStringAsFixed(1)} kg',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSiteReceveur() {
    return DropdownButtonFormField<String>(
      value: _siteReceveurController.text.isEmpty
          ? null
          : _siteReceveurController.text,
      decoration: const InputDecoration(
        labelText: 'Site Receveur',
        prefixIcon: Icon(Icons.business),
        border: OutlineInputBorder(),
      ),
      items: _sites
          .map((site) => DropdownMenuItem(
                value: site,
                child: Text(site),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _siteReceveurController.text = value ?? '';
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez sélectionner un site receveur';
        }
        return null;
      },
    );
  }

  Widget _buildCommentaires() {
    return TextFormField(
      controller: _commentairesController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Commentaires (optionnel)',
        prefixIcon: Icon(Icons.comment),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: _getTypeColor(),
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Attribuer à ${widget.type.label}'),
          ),
        ),
      ],
    );
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await widget.onConfirm({
        'siteReceveur': _siteReceveurController.text,
        'commentaires': _commentairesController.text,
      });

      Navigator.of(context).pop(true);
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de créer l\'attribution: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getTypeColor() {
    switch (widget.type) {
      case AttributionType.extraction:
        return Colors.brown;
      case AttributionType.filtration:
        return Colors.blue;
      case AttributionType.traitementCire:
        return Colors.amber[700]!;
    }
  }

  IconData _getTypeIcon() {
    switch (widget.type) {
      case AttributionType.extraction:
        return Icons.science;
      case AttributionType.filtration:
        return Icons.water_drop;
      case AttributionType.traitementCire:
        return Icons.spa;
    }
  }

  String _getTypeDescription() {
    switch (widget.type) {
      case AttributionType.extraction:
        return 'Processus d\'extraction du miel brut';
      case AttributionType.filtration:
        return 'Processus de filtrage du miel liquide';
      case AttributionType.traitementCire:
        return 'Processus de traitement de la cire';
    }
  }
}

/// 📄 MODAL DÉTAILS PRODUIT
class ProductDetailsDialog extends StatelessWidget {
  final ProductControle produit;

  const ProductDetailsDialog({
    Key? key,
    required this.produit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildDetails(),
            const SizedBox(height: 24),
            _buildCloseButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: produit.natureColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            produit.natureIcon,
            color: produit.natureColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                produit.codeContenant,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Détails du Produit Contrôlé',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildDetailSection('Informations Générales', [
            _buildDetailRow('Code Contenant', produit.codeContenant),
            _buildDetailRow('Producteur', produit.producteur),
            _buildDetailRow('Village', produit.village),
            _buildDetailRow('Commune', produit.commune),
            _buildDetailRow(
                'Date Réception', _formatDate(produit.dateReception)),
          ]),
          const Divider(height: 32),
          _buildDetailSection('Caractéristiques', [
            _buildDetailRow('Nature', produit.nature.label),
            _buildDetailRow('Type Contenant', produit.typeContenant),
            _buildDetailRow('Numéro', produit.numeroContenant),
            _buildDetailRow(
                'Poids Total', '${produit.poidsTotal.toStringAsFixed(2)} kg'),
            _buildDetailRow(
                'Poids Miel', '${produit.poidsMiel.toStringAsFixed(2)} kg'),
          ]),
          const Divider(height: 32),
          _buildDetailSection('Contrôle Qualité', [
            _buildDetailRow('Qualité', produit.qualite),
            _buildDetailRow(
                'Teneur en Eau',
                produit.teneurEau != null
                    ? '${produit.teneurEau!.toStringAsFixed(1)}%'
                    : 'N/A'),
            _buildDetailRow(
                'Prédominance Florale', produit.predominanceFlorale),
            _buildDetailRow(
                'Statut', produit.estConforme ? 'Conforme' : 'Non Conforme'),
            _buildDetailRow('Date Contrôle', _formatDate(produit.dateControle)),
          ]),
          if (produit.observations != null) ...[
            const Divider(height: 32),
            _buildDetailSection('Observations', [
              Text(
                produit.observations!,
                style: const TextStyle(fontSize: 14),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
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
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('Fermer'),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// 📦 MODAL ATTRIBUTION GROUPÉE
class BatchAttributionDialog extends StatefulWidget {
  final List<ProductControle> produits;
  final VoidCallback onAttributionsComplete;

  const BatchAttributionDialog({
    Key? key,
    required this.produits,
    required this.onAttributionsComplete,
  }) : super(key: key);

  @override
  State<BatchAttributionDialog> createState() => _BatchAttributionDialogState();
}

class _BatchAttributionDialogState extends State<BatchAttributionDialog> {
  final List<ProductControle> _selectedProducts = [];
  AttributionType? _selectedType;
  String? _selectedSite;
  final _commentairesController = TextEditingController();
  bool _isLoading = false;

  final List<String> _sites = [
    'Koudougou',
    'Bobo-Dioulasso',
    'Ouagadougou',
    'Réo'
  ];

  @override
  void initState() {
    super.initState();
    _selectedProducts.addAll(widget.produits);
  }

  @override
  void dispose() {
    _commentairesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildTypeSelection(),
            const SizedBox(height: 16),
            _buildSiteSelection(),
            const SizedBox(height: 16),
            _buildCommentaires(),
            const SizedBox(height: 16),
            Expanded(child: _buildProductsList()),
            const SizedBox(height: 24),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.indigo[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.assignment_add,
            color: Colors.indigo[700],
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Attribution Groupée',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_selectedProducts.length} produits sélectionnés',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
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
    );
  }

  Widget _buildTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type d\'Attribution',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: AttributionType.values
              .map((type) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildTypeCard(type),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildTypeCard(AttributionType type) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? _getTypeColor(type).withOpacity(0.1)
              : Colors.grey[50],
          border: Border.all(
            color: isSelected ? _getTypeColor(type) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              _getTypeIcon(type),
              color: isSelected ? _getTypeColor(type) : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              type.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? _getTypeColor(type) : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiteSelection() {
    return DropdownButtonFormField<String>(
      value: _selectedSite,
      decoration: const InputDecoration(
        labelText: 'Site Receveur',
        prefixIcon: Icon(Icons.business),
        border: OutlineInputBorder(),
      ),
      items: _sites
          .map((site) => DropdownMenuItem(
                value: site,
                child: Text(site),
              ))
          .toList(),
      onChanged: (value) => setState(() => _selectedSite = value),
    );
  }

  Widget _buildCommentaires() {
    return TextFormField(
      controller: _commentairesController,
      maxLines: 2,
      decoration: const InputDecoration(
        labelText: 'Commentaires (optionnel)',
        prefixIcon: Icon(Icons.comment),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildProductsList() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _selectedProducts.length == widget.produits.length,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedProducts.clear();
                        _selectedProducts.addAll(widget.produits);
                      } else {
                        _selectedProducts.clear();
                      }
                    });
                  },
                ),
                const Text(
                  'Produits à Attribuer',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.produits.length,
              itemBuilder: (context, index) {
                final produit = widget.produits[index];
                final isSelected = _selectedProducts.contains(produit);
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedProducts.add(produit);
                      } else {
                        _selectedProducts.remove(produit);
                      }
                    });
                  },
                  title: Text(produit.codeContenant),
                  subtitle: Text('${produit.producteur} - ${produit.village}'),
                  secondary: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: produit.natureColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      produit.natureIcon,
                      color: produit.natureColor,
                      size: 16,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _canSubmit() && !_isLoading ? _handleSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[600],
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Attribuer ${_selectedProducts.length} produits'),
          ),
        ),
      ],
    );
  }

  bool _canSubmit() {
    return _selectedType != null &&
        _selectedSite != null &&
        _selectedProducts.isNotEmpty;
  }

  Future<void> _handleSubmit() async {
    // TODO: Implémenter l'attribution groupée
    setState(() => _isLoading = true);

    // Simulation
    await Future.delayed(const Duration(seconds: 2));

    widget.onAttributionsComplete();
    Navigator.of(context).pop();

    Get.snackbar(
      'Attribution Groupée Réussie',
      '${_selectedProducts.length} produits attribués avec succès',
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.check_circle, color: Colors.green),
    );
  }

  Color _getTypeColor(AttributionType type) {
    switch (type) {
      case AttributionType.extraction:
        return Colors.brown;
      case AttributionType.filtration:
        return Colors.blue;
      case AttributionType.traitementCire:
        return Colors.amber[700]!;
    }
  }

  IconData _getTypeIcon(AttributionType type) {
    switch (type) {
      case AttributionType.extraction:
        return Icons.science;
      case AttributionType.filtration:
        return Icons.water_drop;
      case AttributionType.traitementCire:
        return Icons.spa;
    }
  }
}
*/

// ⚠️ Fichier complètement commenté - Le nouveau modal ModernAttributionModal est dans AttributionPageComplete
