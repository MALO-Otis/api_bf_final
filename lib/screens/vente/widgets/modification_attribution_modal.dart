/// ✏️ MODAL DE MODIFICATION D'ATTRIBUTION
///
/// Interface pour modifier une attribution existante avec validation avancée
/// Permet d'augmenter ou diminuer les quantités attribuées

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/commercial_models.dart';
import '../services/commercial_service.dart';

class ModificationAttributionModal extends StatefulWidget {
  final AttributionPartielle attribution;
  final LotProduit lot;
  final CommercialService commercialService;
  final VoidCallback onModificationSuccess;

  const ModificationAttributionModal({
    super.key,
    required this.attribution,
    required this.lot,
    required this.commercialService,
    required this.onModificationSuccess,
  });

  @override
  State<ModificationAttributionModal> createState() =>
      _ModificationAttributionModalState();
}

class _ModificationAttributionModalState
    extends State<ModificationAttributionModal> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nouvelleQuantiteController = TextEditingController();
  final _motifController = TextEditingController();

  bool _isSubmitting = false;

  // Validation en temps réel
  String? _quantiteError;
  double _nouvelleValeur = 0.0;
  int _differenteQuantite = 0;
  double _differenteValeur = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeForm();
    _initializeListeners();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _nouvelleQuantiteController.dispose();
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

  void _initializeForm() {
    _nouvelleQuantiteController.text =
        widget.attribution.quantiteAttribuee.toString();
    _nouvelleValeur = widget.attribution.valeurTotale;
  }

  void _initializeListeners() {
    _nouvelleQuantiteController.addListener(_onQuantiteChanged);
  }

  void _onQuantiteChanged() {
    final texte = _nouvelleQuantiteController.text;
    if (texte.isEmpty) {
      setState(() {
        _quantiteError = null;
        _nouvelleValeur = 0.0;
        _differenteQuantite = 0;
        _differenteValeur = 0.0;
      });
      return;
    }

    final quantite = int.tryParse(texte);
    if (quantite == null) {
      setState(() {
        _quantiteError = 'Veuillez entrer un nombre valide';
        _nouvelleValeur = 0.0;
        _differenteQuantite = 0;
        _differenteValeur = 0.0;
      });
      return;
    }

    if (quantite <= 0) {
      setState(() {
        _quantiteError = 'La quantité doit être supérieure à zéro';
        _nouvelleValeur = 0.0;
        _differenteQuantite = 0;
        _differenteValeur = 0.0;
      });
      return;
    }

    // Calculer la quantité maximum possible
    final quantiteActuelle = widget.attribution.quantiteAttribuee;
    final stockRestant = widget.lot.quantiteRestante;
    final quantiteMaximum = quantiteActuelle + stockRestant;

    if (quantite > quantiteMaximum) {
      setState(() {
        _quantiteError = 'Quantité maximale possible: $quantiteMaximum unités';
        _nouvelleValeur = 0.0;
        _differenteQuantite = 0;
        _differenteValeur = 0.0;
      });
      return;
    }

    // Tout est valide, calculer les valeurs
    setState(() {
      _quantiteError = null;
      _nouvelleValeur = quantite * widget.attribution.valeurUnitaire;
      _differenteQuantite = quantite - quantiteActuelle;
      _differenteValeur =
          _differenteQuantite * widget.attribution.valeurUnitaire;
    });
  }

  bool get _canSubmit {
    return _nouvelleQuantiteController.text.isNotEmpty &&
        _quantiteError == null &&
        !_isSubmitting &&
        int.tryParse(_nouvelleQuantiteController.text) !=
            widget.attribution.quantiteAttribuee;
  }

  bool get _isIncreasing => _differenteQuantite > 0;
  bool get _isDecreasing => _differenteQuantite < 0;

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

    return Container(
      width: isMobile ? MediaQuery.of(context).size.width - 32 : 550,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          _buildCurrentInfo(context),
          _buildForm(context),
          _buildPreview(context),
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
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
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
              Icons.edit,
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
                  'Modification d\'Attribution',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Ajuster la quantité attribuée',
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

  Widget _buildCurrentInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info commercial
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF2196F3).withOpacity(0.1),
                child: Text(
                  widget.attribution.commercialNom
                      .substring(0, 1)
                      .toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF2196F3),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.attribution.commercialNom,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Attribution du ${DateFormat('dd/MM/yyyy à HH:mm').format(widget.attribution.dateAttribution)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Info lot
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  CommercialUtils.getEmojiEmballage(widget.lot.typeEmballage),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lot ${widget.lot.numeroLot}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${widget.lot.typeEmballage} • ${widget.lot.siteOrigine}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Attribution actuelle
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Quantité Actuelle',
                  '${widget.attribution.quantiteAttribuee} unités',
                  Icons.assignment,
                  const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Valeur Actuelle',
                  CommercialUtils.formatPrix(widget.attribution.valeurTotale),
                  Icons.monetization_on,
                  const Color(0xFF9C27B0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
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
            // Nouvelle quantité
            const Text(
              'Nouvelle quantité',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: _nouvelleQuantiteController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.edit),
                suffixText: 'unités',
                errorText: _quantiteError,
                hintText: 'Nouvelle quantité',
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

            // Informations sur les limites
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Stock restant du lot: ${widget.lot.quantiteRestante} unités\n'
                      'Quantité maximum possible: ${widget.attribution.quantiteAttribuee + widget.lot.quantiteRestante} unités',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Raccourcis pratiques
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildQuantiteShortcut(
                  'Actuel - 10',
                  widget.attribution.quantiteAttribuee - 10,
                ),
                _buildQuantiteShortcut(
                  'Actuel + 10',
                  widget.attribution.quantiteAttribuee + 10,
                ),
                _buildQuantiteShortcut(
                  'Maximum',
                  widget.attribution.quantiteAttribuee +
                      widget.lot.quantiteRestante,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Motif de modification
            const Text(
              'Motif de la modification',
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
                hintText:
                    'Expliquez pourquoi vous modifiez cette attribution...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez expliquer le motif de cette modification';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantiteShortcut(String label, int quantite) {
    if (quantite <= 0 ||
        quantite >
            (widget.attribution.quantiteAttribuee +
                widget.lot.quantiteRestante)) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () {
        _nouvelleQuantiteController.text = quantite.toString();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2196F3).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF2196F3),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    if (_differenteQuantite == 0) return const SizedBox.shrink();

    final isIncrease = _isIncreasing;
    final color =
        isIncrease ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    final icon = isIncrease ? Icons.trending_up : Icons.trending_down;
    final prefix = isIncrease ? '+' : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                isIncrease ? 'Augmentation' : 'Diminution',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$prefix$_differenteQuantite unités',
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Différence quantité',
                      style: TextStyle(
                        color: color.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: color.withOpacity(0.3)),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${prefix}${CommercialUtils.formatPrix(_differenteValeur.abs())}',
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Différence valeur',
                      style: TextStyle(
                        color: color.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'Nouvelle valeur totale',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CommercialUtils.formatPrix(_nouvelleValeur),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
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
              onPressed: _canSubmit ? _submitModification : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
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
                      'Modifier',
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

  Future<void> _submitModification() async {
    if (!_formKey.currentState!.validate() || !_canSubmit) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final nouvelleQuantite = int.parse(_nouvelleQuantiteController.text);

      final success = await widget.commercialService.modifierAttribution(
        attributionId: widget.attribution.id,
        nouvelleQuantite: nouvelleQuantite,
        motif: _motifController.text.trim(),
      );

      if (success) {
        // Animation de succès avant fermeture
        await _scaleController.reverse();

        if (mounted) {
          Navigator.pop(context);

          final isIncrease =
              nouvelleQuantite > widget.attribution.quantiteAttribuee;
          final difference =
              (nouvelleQuantite - widget.attribution.quantiteAttribuee).abs();

          Get.snackbar(
            '✅ Modification réussie',
            isIncrease
                ? '+$difference unités attribuées à ${widget.attribution.commercialNom}'
                : '$difference unités retirées de ${widget.attribution.commercialNom}',
            backgroundColor: const Color(0xFF4CAF50),
            colorText: Colors.white,
            icon: const Icon(Icons.check_circle, color: Colors.white),
            duration: const Duration(seconds: 4),
            snackPosition: SnackPosition.TOP,
          );

          widget.onModificationSuccess();
        }
      } else {
        if (mounted) {
          Get.snackbar(
            '❌ Erreur de modification',
            'Impossible de modifier cette attribution. Vérifiez les quantités disponibles.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            icon: const Icon(Icons.error, color: Colors.white),
            duration: const Duration(seconds: 4),
            snackPosition: SnackPosition.TOP,
          );
        }
      }
    } catch (e) {
      debugPrint(
          '❌ [ModificationAttributionModal] Erreur lors de la modification: $e');

      if (mounted) {
        Get.snackbar(
          '❌ Erreur technique',
          'Une erreur est survenue lors de la modification',
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
