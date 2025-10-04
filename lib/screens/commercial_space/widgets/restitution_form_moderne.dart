import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../vente/models/vente_models.dart';
import '../../vente/services/vente_service.dart';
import '../../../authentication/user_session.dart';
import '../../vente/controllers/espace_commercial_controller.dart';

/// 🔄 FORMULAIRE MODERNE DE RESTITUTION
class RestitutionFormModerne extends StatefulWidget {
  final List<Prelevement> prelevements;
  final VoidCallback onRestitutionEnregistree;

  const RestitutionFormModerne({
    super.key,
    required this.prelevements,
    required this.onRestitutionEnregistree,
  });

  @override
  State<RestitutionFormModerne> createState() => _RestitutionFormModerneState();
}

class _RestitutionFormModerneState extends State<RestitutionFormModerne> {
  final _formKey = GlobalKey<FormState>();
  final _observationsController = TextEditingController();

  late final EspaceCommercialController _espaceCtrl;
  final VenteService _venteService = VenteService();
  final UserSession _session = Get.find<UserSession>();

  Prelevement? _prelevementSelectionne;
  // Map produitId -> quantité restituée saisie
  final Map<String, int> _quantitesSaisies = {};
  String _motif = 'Produits non vendus';
  bool _isLoading = false;

  final List<String> _motifs = [
    'Produits non vendus',
    'Date de péremption proche',
    'Demande du client annulée',
    'Défaut de qualité',
    'Surstock',
    'Transport défaillant',
    'Autre motif',
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
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.undo, color: Colors.white, size: 28),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Nouvelle Restitution',
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
                          labelText: 'Prélèvement à restituer',
                          prefixIcon: const Icon(Icons.shopping_bag),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
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

                      // Motif de restitution
                      DropdownButtonFormField<String>(
                        value: _motif,
                        decoration: InputDecoration(
                          labelText: 'Motif de restitution',
                          prefixIcon: const Icon(Icons.info_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _motifs.map((motif) {
                          return DropdownMenuItem(
                              value: motif, child: Text(motif));
                        }).toList(),
                        onChanged: (value) => setState(() => _motif = value!),
                      ),

                      const SizedBox(height: 16),

                      // Observations
                      TextFormField(
                        controller: _observationsController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Observations détaillées',
                          hintText:
                              'Décrivez l\'état des produits, les raisons de la restitution...',
                          prefixIcon: const Icon(Icons.note),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez ajouter des observations';
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
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _enregistrerRestitution,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Enregistrer'),
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
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.undo, color: Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Sélection des produits à restituer (${restants.length})',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800)),
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
        Text('Valeur restituée: ${VenteUtils.formatPrix(total)}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _enregistrerRestitution() async {
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
      final produitsRestitues = <ProduitRestitue>[];
      double valeurTotale = 0;

      for (final prod in restants) {
        final q = _quantitesSaisies[prod.produitId];
        if (q == null || q <= 0) continue;
        final restitue = ProduitRestitue(
          produitId: prod.produitId,
          numeroLot: prod.numeroLot,
          typeEmballage: prod.typeEmballage,
          quantiteRestituee: q,
          valeurUnitaire: prod.prixUnitaire,
          etatProduit: 'Bon état', // simplification
        );
        valeurTotale += prod.prixUnitaire * q;
        produitsRestitues.add(restitue);
      }

      if (produitsRestitues.isEmpty) {
        Get.snackbar('Aucun produit', 'Aucune quantité valide sélectionnée',
            backgroundColor: Colors.orange, colorText: Colors.white);
        setState(() => _isLoading = false);
        return;
      }

      final restitutionId = 'REST_${DateTime.now().millisecondsSinceEpoch}';
      final commercialId = _session.email ?? 'Commercial_Inconnu';
      final commercialNom = commercialId;

      final restitution = Restitution(
        id: restitutionId,
        prelevementId: prelevement.id,
        commercialId: commercialId,
        commercialNom: commercialNom,
        dateRestitution: DateTime.now(),
        produits: produitsRestitues,
        valeurTotale: valeurTotale,
        type: TypeRestitution.invendu, // mapping selon motif si besoin
        motif: _motif,
        observations: _observationsController.text.trim().isEmpty
            ? null
            : _observationsController.text.trim(),
      );

      final ok = await _venteService.enregistrerRestitution(restitution);
      if (!ok) throw 'Echec enregistrement';

      Get.snackbar(
        'Succès',
        'Restitution enregistrée (${produitsRestitues.length} produits)',
        backgroundColor: const Color(0xFFF59E0B),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );

      widget.onRestitutionEnregistree();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'enregistrer la restitution: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
