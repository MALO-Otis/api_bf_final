import 'package:flutter/material.dart';
import '../services/extraction_attribution_service.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';

/// Modal pour attribuer des produits extraits au filtrage
class ExtractionAttributionModal extends StatefulWidget {
  final List<Map<String, dynamic>> produitsDisponibles;
  final String extracteurId;
  final String extracteurNom;
  final VoidCallback? onCompleted;

  const ExtractionAttributionModal({
    super.key,
    required this.produitsDisponibles,
    required this.extracteurId,
    required this.extracteurNom,
    this.onCompleted,
  });

  @override
  State<ExtractionAttributionModal> createState() =>
      _ExtractionAttributionModalState();
}

class _ExtractionAttributionModalState
    extends State<ExtractionAttributionModal> {
  final ExtractionAttributionService _service = ExtractionAttributionService();
  final _formKey = GlobalKey<FormState>();
  final _instructionsController = TextEditingController();
  final _observationsController = TextEditingController();

  SiteAttribution _selectedSite = SiteAttribution.koudougou;
  ExtractionAttributionType _selectedType =
      ExtractionAttributionType.filtration;
  final Set<String> _selectedProduits = <String>{};
  bool _isLoading = false;

  @override
  void dispose() {
    _instructionsController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? 400 : 700,
          maxHeight: screenSize.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête
            _buildHeader(theme, isMobile),

            // Contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informations extracteur
                      _buildExtracteurInfo(theme),

                      const SizedBox(height: 24),

                      // Sélection du type et site
                      _buildTypeAndSiteSelection(theme),

                      const SizedBox(height: 24),

                      // Sélection des produits
                      _buildProduitSelection(theme),

                      const SizedBox(height: 24),

                      // Instructions et observations
                      _buildInstructionsAndObservations(theme),

                      const SizedBox(height: 24),

                      // Résumé
                      _buildResume(theme),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            _buildActions(theme, isMobile),
          ],
        ),
      ),
    );
  }

  /// En-tête du modal
  Widget _buildHeader(ThemeData theme, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.assignment_turned_in,
            color: Colors.white,
            size: isMobile ? 24 : 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attribution pour Filtrage',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 18 : 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Attribuer des produits extraits aux filtreurs',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Informations extracteur
  Widget _buildExtracteurInfo(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.person,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Extracteur',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    widget.extracteurNom,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Text(
                'Extracteur',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sélection type et site
  Widget _buildTypeAndSiteSelection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Destination de l\'Attribution',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<ExtractionAttributionType>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Type d\'Attribution',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ExtractionAttributionType.values
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(type.label),
                              Text(
                                type.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<SiteAttribution>(
                value: _selectedSite,
                decoration: InputDecoration(
                  labelText: 'Site de Destination',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: SiteAttribution.values
                    .map((site) => DropdownMenuItem(
                          value: site,
                          child: Text(site.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSite = value);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Sélection des produits
  Widget _buildProduitSelection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Sélection des Produits',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedProduits.length ==
                      widget.produitsDisponibles.length) {
                    _selectedProduits.clear();
                  } else {
                    _selectedProduits.addAll(
                      widget.produitsDisponibles.map((p) => p['id'] as String),
                    );
                  }
                });
              },
              child: Text(
                _selectedProduits.length == widget.produitsDisponibles.length
                    ? 'Tout désélectionner'
                    : 'Tout sélectionner',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (widget.produitsDisponibles.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.disabledColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: theme.disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun produit extrait disponible',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.disabledColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Les produits extraits prêts pour le filtrage apparaîtront ici',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.disabledColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              itemCount: widget.produitsDisponibles.length,
              itemBuilder: (context, index) {
                final produit = widget.produitsDisponibles[index];
                final isSelected = _selectedProduits.contains(produit['id']);

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedProduits.add(produit['id']);
                      } else {
                        _selectedProduits.remove(produit['id']);
                      }
                    });
                  },
                  title: Text(
                    produit['codeContenant'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${produit['producteur']} - ${produit['village']}'),
                      Text(
                        '${produit['poidsExtrait']} kg - ${produit['qualite']} - ${produit['predominanceFlorale']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  secondary: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${produit['poidsExtrait']} kg',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
            ),
          ),
      ],
    );
  }

  /// Instructions et observations
  Widget _buildInstructionsAndObservations(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instructions et Observations',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _instructionsController,
          decoration: InputDecoration(
            labelText: 'Instructions pour le filtreur',
            hintText:
                'Instructions spécifiques pour le processus de filtrage...',
            prefixIcon: const Icon(Icons.description),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _observationsController,
          decoration: InputDecoration(
            labelText: 'Observations (optionnel)',
            hintText: 'Observations particulières sur les produits...',
            prefixIcon: const Icon(Icons.note),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  /// Résumé de l'attribution
  Widget _buildResume(ThemeData theme) {
    final poidsTotal = _selectedProduits.fold<double>(0.0, (sum, produitId) {
      final produit = widget.produitsDisponibles.firstWhere(
        (p) => p['id'] == produitId,
        orElse: () => {'poidsExtrait': 0.0},
      );
      return sum + (produit['poidsExtrait'] as double? ?? 0.0);
    });

    return Card(
      color: theme.colorScheme.primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Résumé de l\'Attribution',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildResumeItem(
                    'Type',
                    _selectedType.label,
                    Icons.category,
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildResumeItem(
                    'Destination',
                    _selectedSite.name,
                    Icons.location_on,
                    theme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildResumeItem(
                    'Produits',
                    '${_selectedProduits.length}',
                    Icons.inventory_2,
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildResumeItem(
                    'Poids Total',
                    '${poidsTotal.toStringAsFixed(2)} kg',
                    Icons.scale,
                    theme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Item de résumé
  Widget _buildResumeItem(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Actions du modal
  Widget _buildActions(ThemeData theme, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
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
            child: ElevatedButton.icon(
              onPressed: _isLoading || _selectedProduits.isEmpty
                  ? null
                  : _creerAttribution,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.assignment_turned_in),
              label:
                  Text(_isLoading ? 'Attribution...' : 'Créer l\'Attribution'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Créer l'attribution
  Future<void> _creerAttribution() async {
    if (!_formKey.currentState!.validate() || _selectedProduits.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _service.creerAttribution(
        type: _selectedType.value, // Convertir enum en string
        siteDestination: _selectedSite.value, // Convertir enum en string
        produitsExtraitsIds: _selectedProduits.toList(),
        extracteurId: widget.extracteurId,
        extracteurNom: widget.extracteurNom,
        instructions: _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
        observations: _observationsController.text.trim().isEmpty
            ? null
            : _observationsController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Attribution créée avec succès: ${_selectedProduits.length} produits attribués pour ${_selectedType.label}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop();
        widget.onCompleted?.call();
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
