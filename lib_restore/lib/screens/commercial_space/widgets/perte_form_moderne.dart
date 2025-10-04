import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../vente/models/vente_models.dart';
import '../../vente/services/vente_service.dart';
import '../../../authentication/user_session.dart';
import '../../vente/controllers/espace_commercial_controller.dart';

/// ⚠️ FORMULAIRE MODERNE DE DÉCLARATION DE PERTE
class PerteFormModerne extends StatefulWidget {
  final List<Prelevement> prelevements;
  final VoidCallback onPerteEnregistree;

  const PerteFormModerne({
    super.key,
    required this.prelevements,
    required this.onPerteEnregistree,
  });

  @override
  State<PerteFormModerne> createState() => _PerteFormModerneState();
}

class _PerteFormModerneState extends State<PerteFormModerne> {
  final _formKey = GlobalKey<FormState>();
  final _observationsController = TextEditingController();

  late final EspaceCommercialController _espaceCtrl;
  final VenteService _venteService = VenteService();
  final UserSession _session = Get.find<UserSession>();

  Prelevement? _prelevementSelectionne;
  // Map produitId -> quantité perdue saisie
  final Map<String, int> _quantitesSaisies = {};
  String _cause = 'Casse accidentelle';
  bool _photoJointe = false;
  bool _isLoading = false;

  final List<String> _causes = [
    'Casse accidentelle',
    'Vol/disparition',
    'Détérioration transport',
    'Péremption',
    'Défaut de stockage',
    'Dommage climatique',
    'Défaut de manipulation',
    'Incident technique',
    'Autre cause',
  ];

  @override
  void initState() {
    super.initState();
    _espaceCtrl = Get.find<EspaceCommercialController>();
  }

  @override
  void dispose() {
    _observationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header avec alerte
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.warning,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Déclaration de Perte',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.white.withOpacity(0.9), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Déclarez rapidement toute perte ou incident sur vos produits',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Contenu
            Flexible(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Sélection du prélèvement
                      DropdownButtonFormField<Prelevement>(
                        value: _prelevementSelectionne,
                        decoration: InputDecoration(
                          labelText: 'Prélèvement concerné',
                          prefixIcon: const Icon(Icons.shopping_bag,
                              color: Color(0xFFEF4444)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFEF4444), width: 2),
                          ),
                        ),
                        items: widget.prelevements.map((prelevement) {
                          return DropdownMenuItem(
                            value: prelevement,
                            child: Text(
                                '${prelevement.id.split('_').last} (${prelevement.produits.length} produits)'),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() {
                          _prelevementSelectionne = value;
                          _quantitesSaisies.clear();
                        }),
                        validator: (value) => value == null
                            ? 'Sélectionnez un prélèvement'
                            : null,
                      ),

                      const SizedBox(height: 16),

                      // Cause de la perte
                      DropdownButtonFormField<String>(
                        value: _cause,
                        decoration: InputDecoration(
                          labelText: 'Cause de la perte',
                          prefixIcon: const Icon(Icons.error_outline,
                              color: Color(0xFFEF4444)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFEF4444), width: 2),
                          ),
                        ),
                        items: _causes.map((cause) {
                          return DropdownMenuItem(
                              value: cause, child: Text(cause));
                        }).toList(),
                        onChanged: (value) => setState(() => _cause = value!),
                      ),

                      const SizedBox(height: 16),

                      // Photo d'évidence
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _photoJointe
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _photoJointe
                                ? Colors.green.shade300
                                : Colors.orange.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _photoJointe
                                  ? Icons.camera_alt
                                  : Icons.add_a_photo,
                              color: _photoJointe
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Photo d\'évidence',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _photoJointe
                                          ? Colors.green.shade800
                                          : Colors.orange.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _photoJointe
                                        ? 'Photo ajoutée avec succès'
                                        : 'Recommandé pour justifier la perte',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _photoJointe
                                          ? Colors.green.shade600
                                          : Colors.orange.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() => _photoJointe = !_photoJointe);
                                Get.snackbar(
                                  _photoJointe
                                      ? 'Photo ajoutée'
                                      : 'Photo retirée',
                                  _photoJointe
                                      ? 'La photo d\'évidence a été ajoutée'
                                      : 'La photo d\'évidence a été retirée',
                                  backgroundColor: _photoJointe
                                      ? Colors.green
                                      : Colors.orange,
                                  colorText: Colors.white,
                                  duration: const Duration(seconds: 2),
                                );
                              },
                              icon: Icon(
                                  _photoJointe ? Icons.check : Icons.camera_alt,
                                  size: 16),
                              label: Text(_photoJointe ? 'Ajoutée' : 'Ajouter'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _photoJointe
                                    ? Colors.green
                                    : const Color(0xFFEF4444),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Observations détaillées
                      TextFormField(
                        controller: _observationsController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Description détaillée de l\'incident',
                          hintText:
                              'Décrivez les circonstances, l\'état des produits, les causes exactes...',
                          prefixIcon: const Icon(Icons.note_add,
                              color: Color(0xFFEF4444)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFEF4444), width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez décrire l\'incident en détail';
                          }
                          if (value.trim().length < 20) {
                            return 'Description trop courte (minimum 20 caractères)';
                          }
                          return null;
                        },
                      ),

                      if (_prelevementSelectionne != null) ...[
                        const SizedBox(height: 20),
                        _buildProduitsSelection(),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                      ),
                      child: const Text('Annuler',
                          style: TextStyle(color: Color(0xFFEF4444))),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _enregistrerPerte,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.report_problem, size: 18),
                                const SizedBox(width: 8),
                                const Text('Déclarer la Perte',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProduitsSelection() {
    final restants =
        _espaceCtrl.prelevementProduitsRestants[_prelevementSelectionne!.id] ??
            [];
    if (restants.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('Aucun produit restant sur ce prélèvement',
            style: TextStyle(color: Colors.red.shade700)),
      );
    }
    double total = 0;
    for (final p in restants) {
      final q = _quantitesSaisies[p.produitId] ?? 0;
      total += q * p.prixUnitaire;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.report_problem, color: Color(0xFFEF4444)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Sélection des produits perdus (${restants.length})',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            itemCount: restants.length,
            itemBuilder: (ctx, i) {
              final prod = restants[i];
              final maxQte = prod.quantitePreleve;
              final current = _quantitesSaisies[prod.produitId] ?? 0;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${prod.typeEmballage} (${prod.contenanceKg}kg)',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(
                                'Restant: $maxQte  •  PU: ${VenteUtils.formatPrix(prod.prixUnitaire)}'),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: TextFormField(
                          initialValue: current == 0 ? '' : current.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Qté',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final n = int.tryParse(v) ?? 0;
                            setState(() {
                              if (n <= 0) {
                                _quantitesSaisies.remove(prod.produitId);
                              } else if (n <= maxQte) {
                                _quantitesSaisies[prod.produitId] = n;
                              }
                            });
                          },
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            final n = int.tryParse(v);
                            if (n == null) return 'Nombre';
                            if (n <= 0) return ' >0';
                            if (n > maxQte) return 'Max $maxQte';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text('Valeur perdue: ${VenteUtils.formatPrix(total)}',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
      ],
    );
  }

  Future<void> _enregistrerPerte() async {
    if (!_formKey.currentState!.validate()) return;
    if (_prelevementSelectionne == null) return;
    if (_quantitesSaisies.isEmpty) {
      Get.snackbar('Quantités requises',
          'Sélectionnez au moins un produit avec une quantité > 0',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prelevement = _prelevementSelectionne!;
      final restants =
          _espaceCtrl.prelevementProduitsRestants[prelevement.id] ?? [];
      final produitsPerdus = <ProduitPerdu>[];
      double valeurTotale = 0;

      for (final prod in restants) {
        final q = _quantitesSaisies[prod.produitId];
        if (q == null || q <= 0) continue;
        final perdu = ProduitPerdu(
          produitId: prod.produitId,
          numeroLot: prod.numeroLot,
          typeEmballage: prod.typeEmballage,
          quantitePerdue: q,
          valeurUnitaire: prod.prixUnitaire,
          circonstances: _cause,
        );
        valeurTotale += prod.prixUnitaire * q;
        produitsPerdus.add(perdu);
      }

      if (produitsPerdus.isEmpty) {
        Get.snackbar('Aucun produit', 'Aucune quantité valide sélectionnée',
            backgroundColor: Colors.orange, colorText: Colors.white);
        setState(() => _isLoading = false);
        return;
      }

      final perteId = 'PTE_${DateTime.now().millisecondsSinceEpoch}';
      final commercialId = _session.email ?? 'Commercial_Inconnu';
      final commercialNom = commercialId;

      final perte = Perte(
        id: perteId,
        prelevementId: prelevement.id,
        commercialId: commercialId,
        commercialNom: commercialNom,
        datePerte: DateTime.now(),
        produits: produitsPerdus,
        valeurTotale: valeurTotale,
        type: TypePerte.casse, // mapping selon cause si besoin
        motif: _cause,
        observations: _observationsController.text.trim().isEmpty
            ? null
            : _observationsController.text.trim(),
        estValidee: false,
        validateurId: null,
        dateValidation: null,
      );

      final ok = await _venteService.enregistrerPerte(perte);
      if (!ok) throw 'Echec enregistrement';

      Get.snackbar(
        'Déclaration enregistrée',
        'Déclaration de perte transmise (${produitsPerdus.length} produits)',
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.report_problem, color: Colors.white),
      );

      widget.onPerteEnregistree();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'enregistrer la déclaration: $e',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
