/// 🎯 MODAL D'ATTRIBUTION MULTIPLE DE PRODUITS
///
/// Interface optimisée pour attribuer plusieurs produits de différents lots à un commercial
/// en une seule opération avec validation en temps réel

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../models/commercial_models.dart';
import '../services/commercial_service.dart';
import 'selecteur_commercial.dart';

class AttributionMultipleModal extends StatefulWidget {
  final List<LotProduit> lotsDisponibles;
  final CommercialService commercialService;
  final VoidCallback onAttributionSuccess;

  const AttributionMultipleModal({
    super.key,
    required this.lotsDisponibles,
    required this.commercialService,
    required this.onAttributionSuccess,
  });

  @override
  State<AttributionMultipleModal> createState() =>
      _AttributionMultipleModalState();
}

class _AttributionMultipleModalState extends State<AttributionMultipleModal>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _motifController = TextEditingController();

  String? _selectedCommercialNom;
  bool _isSubmitting = false;

  // Liste des attributions à effectuer
  final List<AttributionItem> _attributions = [];
  double _valeurTotaleCalculee = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeAttributions();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
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

  void _initializeAttributions() {
    // Initialiser avec les lots disponibles ayant des quantités restantes > 0
    debugPrint(
        '🔧 [AttributionMultiple] Initialisation avec ${widget.lotsDisponibles.length} lots disponibles');

    for (final lot in widget.lotsDisponibles) {
      debugPrint(
          '🔧 [AttributionMultiple] Lot ${lot.typeEmballage}: ${lot.quantiteRestante}/${lot.quantiteInitiale} restantes (ID: ${lot.id})');

      if (lot.quantiteRestante > 0) {
        _attributions.add(AttributionItem(
          lot: lot,
          quantiteAttribuee: 0,
          controller: TextEditingController(),
        ));
        debugPrint(
            '✅ [AttributionMultiple] Lot ${lot.typeEmballage} ajouté pour attribution');
      } else {
        debugPrint(
            '❌ [AttributionMultiple] Lot ${lot.typeEmballage} ignoré (quantité restante: ${lot.quantiteRestante})');
      }
    }

    debugPrint(
        '🔧 [AttributionMultiple] ${_attributions.length} lots prêts pour attribution multiple');

    // Ajouter des listeners pour recalculer la valeur totale
    for (final attribution in _attributions) {
      attribution.controller.addListener(_calculerValeurTotale);
    }
  }

  void _calculerValeurTotale() {
    double total = 0.0;
    for (final attribution in _attributions) {
      final quantite = int.tryParse(attribution.controller.text) ?? 0;
      if (quantite > 0) {
        total += quantite * attribution.lot.prixUnitaire;
      }
    }

    setState(() {
      _valeurTotaleCalculee = total;
    });
  }

  bool get _canSubmit {
    if (_selectedCommercialNom == null ||
        _selectedCommercialNom!.trim().isEmpty) {
      return false;
    }

    if (_isSubmitting) return false;

    // Au moins une attribution doit avoir une quantité > 0
    return _attributions.any((attr) {
      final quantite = int.tryParse(attr.controller.text) ?? 0;
      return quantite > 0 && quantite <= attr.lot.quantiteRestante;
    });
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
      width: isMobile ? MediaQuery.of(context).size.width - 32 : 700,
      height: screenHeight * 0.9,
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
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildCommercialSelection(context),
                    _buildAttributionsSection(context),
                    _buildMotifSection(context),
                  ],
                ),
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
              Icons.assignment_turned_in,
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
                  'Attribution Multiple',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Attribuer plusieurs produits en une fois',
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

  Widget _buildCommercialSelection(BuildContext context) {
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
          const Text(
            'Commercial destinataire',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SelecteurCommercial(
            commercialSelectionne: _selectedCommercialNom,
            onChanged: (nom) {
              debugPrint('🔧 [AttributionMultiple] Commercial changé: $nom');
              setState(() {
                _selectedCommercialNom = nom;
                debugPrint(
                    '🔧 [AttributionMultiple] Commercial mis à jour: $_selectedCommercialNom');
                debugPrint('🔧 [AttributionMultiple] _canSubmit: $_canSubmit');
              });
            },
            hintText: 'Sélectionnez ou saisissez le nom du commercial',
            labelText: null,
          ),
        ],
      ),
    );
  }

  Widget _buildAttributionsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Produits à attribuer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_valeurTotaleCalculee > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Total: ${CommercialUtils.formatPrix(_valeurTotaleCalculee)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Liste des produits disponibles
          ..._attributions
              .map((attribution) => _buildAttributionRow(attribution)),
        ],
      ),
    );
  }

  Widget _buildAttributionRow(AttributionItem attribution) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Informations du lot
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        CommercialUtils.getEmojiEmballage(
                            attribution.lot.typeEmballage),
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lot ${attribution.lot.numeroLot}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${attribution.lot.typeEmballage} • ${attribution.lot.siteOrigine}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    'Disponible: ${attribution.lot.quantiteRestante}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Champ de quantité
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: attribution.controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Quantité',
                  hintText: '0',
                  suffixText: 'unités',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final quantite = int.tryParse(value);
                    if (quantite == null || quantite < 0) {
                      return 'Nombre invalide';
                    }
                    if (quantite > attribution.lot.quantiteRestante) {
                      return 'Dépasse le stock';
                    }
                  }
                  return null;
                },
              ),
            ),

            // Prix
            const SizedBox(width: 8),
            Text(
              CommercialUtils.formatPrix(attribution.lot.prixUnitaire),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotifSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              hintText: 'Raison de cette attribution multiple...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(16),
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _canSubmit
                  ? () {
                      debugPrint(
                          '🔧 [AttributionMultiple] Bouton cliqué - canSubmit: $_canSubmit');
                      debugPrint(
                          '🔧 [AttributionMultiple] Commercial: $_selectedCommercialNom');
                      _submitAttributions();
                    }
                  : null,
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
                      'Attribuer Tout',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAttributions() async {
    if (!_formKey.currentState!.validate() || !_canSubmit) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final commercialId =
          _selectedCommercialNom!.toLowerCase().replaceAll(' ', '_');
      final motif = _motifController.text.trim().isNotEmpty
          ? _motifController.text.trim()
          : null;

      int successCount = 0;
      int totalAttributions = 0;

      // Effectuer toutes les attributions
      debugPrint(
          '🔧 [AttributionMultiple] Début attribution pour ${_attributions.length} lots');

      for (int i = 0; i < _attributions.length; i++) {
        final attribution = _attributions[i];
        final quantite = int.tryParse(attribution.controller.text) ?? 0;

        debugPrint(
            '🔧 [AttributionMultiple] Lot ${i + 1}/${_attributions.length}: ${attribution.lot.typeEmballage} - Quantité saisie: $quantite');

        if (quantite > 0) {
          totalAttributions++;
          debugPrint(
              '🎯 [AttributionMultiple] Attribution ${totalAttributions}: ${attribution.lot.typeEmballage} - $quantite unités');

          final success = await widget.commercialService.attribuerLotCommercial(
            lotId: attribution.lot.id,
            commercialId: commercialId,
            commercialNom: _selectedCommercialNom!,
            quantiteAttribuee: quantite,
            motif: motif,
          );

          if (success) {
            successCount++;
            debugPrint(
                '✅ [AttributionMultiple] Attribution ${totalAttributions} réussie');
          } else {
            debugPrint(
                '❌ [AttributionMultiple] Attribution ${totalAttributions} échouée');
          }
        } else {
          debugPrint(
              '⏭️ [AttributionMultiple] Lot ${attribution.lot.typeEmballage} ignoré (quantité: $quantite)');
        }
      }

      debugPrint(
          '📊 [AttributionMultiple] Résultat: ${successCount}/${totalAttributions} attributions réussies');

      // Animation de succès avant fermeture
      await _scaleController.reverse();

      if (mounted) {
        Navigator.pop(context);

        if (successCount == totalAttributions && totalAttributions > 0) {
          Get.snackbar(
            '✅ Attributions réussies',
            '$successCount/$totalAttributions attributions effectuées à $_selectedCommercialNom',
            backgroundColor: const Color(0xFF4CAF50),
            colorText: Colors.white,
            icon: const Icon(Icons.check_circle, color: Colors.white),
            duration: const Duration(seconds: 4),
            snackPosition: SnackPosition.TOP,
          );
        } else if (successCount > 0) {
          Get.snackbar(
            '⚠️ Attributions partielles',
            '$successCount/$totalAttributions attributions réussies',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            icon: const Icon(Icons.warning, color: Colors.white),
            duration: const Duration(seconds: 4),
            snackPosition: SnackPosition.TOP,
          );
        } else {
          Get.snackbar(
            '❌ Erreur d\'attribution',
            'Aucune attribution n\'a pu être effectuée',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            icon: const Icon(Icons.error, color: Colors.white),
            duration: const Duration(seconds: 4),
            snackPosition: SnackPosition.TOP,
          );
        }

        // Appeler le callback seulement si au moins une attribution a réussi
        if (successCount > 0) {
          debugPrint(
              '🔄 [AttributionMultipleModal] Appel du callback de rafraîchissement');
          widget.onAttributionSuccess();
        }
      }
    } catch (e) {
      debugPrint(
          '❌ [AttributionMultipleModal] Erreur lors des attributions: $e');

      if (mounted) {
        Get.snackbar(
          '❌ Erreur technique',
          'Une erreur est survenue lors des attributions',
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

// Classe helper pour gérer les attributions individuelles
class AttributionItem {
  final LotProduit lot;
  final TextEditingController controller;
  int quantiteAttribuee;

  AttributionItem({
    required this.lot,
    required this.controller,
    this.quantiteAttribuee = 0,
  });
}
