/// 🎯 MODAL D'ATTRIBUTION DE PRODUITS À UN COMMERCIAL
///
/// Interface optimisée pour attribuer rapidement une quantité d'un lot à un commercial
/// Validation en temps réel et feedback immédiat

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../models/commercial_models.dart';
import '../services/commercial_service.dart';
import 'selecteur_commercial.dart';

class AttributionModal extends StatefulWidget {
  final LotProduit lot;
  final CommercialService commercialService;
  final VoidCallback onAttributionSuccess;

  const AttributionModal({
    super.key,
    required this.lot,
    required this.commercialService,
    required this.onAttributionSuccess,
  });

  @override
  State<AttributionModal> createState() => _AttributionModalState();
}

class _AttributionModalState extends State<AttributionModal>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _quantiteController = TextEditingController();
  final _motifController = TextEditingController();

  String? _selectedCommercialNom;
  bool _isSubmitting = false;

  // Validation en temps réel
  String? _quantiteError;
  double _valeurCalculee = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeListeners();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _quantiteController.dispose();
    _motifController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _scaleController.forward();
    _fadeController.forward();
  }

  void _initializeListeners() {
    _quantiteController.addListener(_onQuantiteChanged);
  }

  void _onQuantiteChanged() {
    final texte = _quantiteController.text;
    if (texte.isEmpty) {
      setState(() {
        _quantiteError = null;
        _valeurCalculee = 0.0;
      });
      return;
    }

    final quantite = int.tryParse(texte);
    if (quantite == null) {
      setState(() {
        _quantiteError = 'Veuillez entrer un nombre valide';
        _valeurCalculee = 0.0;
      });
      return;
    }

    if (quantite <= 0) {
      setState(() {
        _quantiteError = 'La quantité doit être supérieure à zéro';
        _valeurCalculee = 0.0;
      });
      return;
    }

    if (quantite > widget.lot.quantiteRestante) {
      setState(() {
        _quantiteError =
            'Quantité supérieure au stock disponible (${widget.lot.quantiteRestante})';
        _valeurCalculee = 0.0;
      });
      return;
    }

    setState(() {
      _quantiteError = null;
      _valeurCalculee = quantite * widget.lot.prixUnitaire;
    });
  }

  bool get _canSubmit {
    return _selectedCommercialNom != null &&
        _selectedCommercialNom!.trim().isNotEmpty &&
        _quantiteController.text.isNotEmpty &&
        _quantiteError == null &&
        !_isSubmitting;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _fadeAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: _buildDialogContent(context),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: isMobile ? MediaQuery.of(context).size.width - 32 : 500,
      height: screenHeight * 0.9, // Limite la hauteur à 90% de l'écran
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildLotInfo(context),
                  _buildForm(context),
                ],
              ),
            ),
          ),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.assignment,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attribution de Produits',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Attribuer des produits à un commercial',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Fermer',
          ),
        ],
      ),
    );
  }

  Widget _buildLotInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                CommercialUtils.getEmojiEmballage(widget.lot.typeEmballage),
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lot ${widget.lot.numeroLot}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.lot.typeEmballage} • ${widget.lot.siteOrigine}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      widget.lot.predominanceFlorale,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: CommercialUtils.getCouleurStatut(widget.lot.statut),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  CommercialUtils.getLibelleStatut(widget.lot.statut),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Informations détaillées
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Stock Disponible',
                  '${widget.lot.quantiteRestante} unités',
                  Icons.inventory,
                  const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Prix Unitaire',
                  CommercialUtils.formatPrix(widget.lot.prixUnitaire),
                  Icons.local_offer,
                  const Color(0xFF2196F3),
                ),
              ),
            ],
          ),

          // Alerte si proche expiration
          if (widget.lot.estProcheExpiration) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ce lot arrive bientôt à expiration. Priorité à l\'attribution !',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
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
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sélection du commercial
            const Text(
              'Commercial destinataire',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            SelecteurCommercial(
              commercialSelectionne: _selectedCommercialNom,
              onChanged: (nom) {
                debugPrint('🔧 [Attribution] Commercial changé: $nom');
                setState(() {
                  _selectedCommercialNom = nom;
                  debugPrint(
                      '🔧 [Attribution] Commercial mis à jour: $_selectedCommercialNom');
                  debugPrint('🔧 [Attribution] _canSubmit: $_canSubmit');
                });
              },
              hintText: 'Sélectionnez ou saisissez le nom du commercial',
              labelText: null, // On a déjà le label au-dessus
            ),

            const SizedBox(height: 20),

            // Quantité à attribuer
            const Text(
              'Quantité à attribuer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: _quantiteController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.inventory),
                suffixText: 'unités',
                hintText: 'Ex: 50',
                errorText: _quantiteError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer une quantité';
                }
                return _quantiteError;
              },
            ),

            // Raccourcis de quantité
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildQuantiteShortcut(
                    '25%', (widget.lot.quantiteRestante * 0.25).round()),
                _buildQuantiteShortcut(
                    '50%', (widget.lot.quantiteRestante * 0.5).round()),
                _buildQuantiteShortcut(
                    '75%', (widget.lot.quantiteRestante * 0.75).round()),
                _buildQuantiteShortcut('Tout', widget.lot.quantiteRestante),
              ],
            ),

            const SizedBox(height: 20),

            // Aperçu de la valeur
            if (_valeurCalculee > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Valeur de l\'attribution',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CommercialUtils.formatPrix(_valeurCalculee),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Motif (optionnel)
            const Text(
              'Motif (optionnel)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: _motifController,
              maxLines: 3,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.note_add),
                hintText: 'Raison de cette attribution...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantiteShortcut(String label, int quantite) {
    if (quantite <= 0) return const SizedBox.shrink();

    return InkWell(
      onTap: () {
        _quantiteController.text = quantite.toString();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
        ),
        child: Text(
          '$label ($quantite)',
          style: const TextStyle(
            color: Color(0xFF4CAF50),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey.shade400),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Annuler',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _canSubmit ? _submitAttribution : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Attribuer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAttribution() async {
    if (!_formKey.currentState!.validate() || !_canSubmit) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final quantite = int.parse(_quantiteController.text);

      // Générer un ID commercial basé sur le nom (ou utiliser le nom directement)
      final commercialId =
          _selectedCommercialNom!.toLowerCase().replaceAll(' ', '_');

      final success = await widget.commercialService.attribuerLotCommercial(
        lotId: widget.lot.id,
        commercialId: commercialId,
        commercialNom: _selectedCommercialNom!,
        quantiteAttribuee: quantite,
        motif: _motifController.text.trim().isNotEmpty
            ? _motifController.text.trim()
            : null,
      );

      if (success) {
        // Animation de succès avant fermeture
        await _scaleController.reverse();

        if (mounted) {
          Navigator.pop(context);

          Get.snackbar(
            '✅ Attribution réussie',
            '$quantite unités attribuées à $_selectedCommercialNom',
            backgroundColor: const Color(0xFF4CAF50),
            colorText: Colors.white,
            icon: const Icon(Icons.check_circle, color: Colors.white),
            duration: const Duration(seconds: 4),
            snackPosition: SnackPosition.TOP,
          );

          widget.onAttributionSuccess();
        }
      } else {
        if (mounted) {
          Get.snackbar(
            '❌ Erreur d\'attribution',
            'Impossible d\'attribuer ces produits. Vérifiez les quantités disponibles.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            icon: const Icon(Icons.error, color: Colors.white),
            duration: const Duration(seconds: 4),
            snackPosition: SnackPosition.TOP,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [AttributionModal] Erreur lors de l\'attribution: $e');

      if (mounted) {
        Get.snackbar(
          '❌ Erreur technique',
          'Une erreur est survenue lors de l\'attribution',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.error, color: Colors.white),
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.TOP,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
