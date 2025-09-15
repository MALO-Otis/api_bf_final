import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../vente/models/vente_models.dart';
import '../../vente/services/vente_service.dart';
import '../../../authentication/user_session.dart';
import '../../vente/controllers/espace_commercial_controller.dart';

/// 🛍️ FORMULAIRE MODERNE DE VENTE
class VenteFormeModerne extends StatefulWidget {
  final List<Prelevement> prelevements;
  final VoidCallback onVenteEnregistree;

  const VenteFormeModerne({
    super.key,
    required this.prelevements,
    required this.onVenteEnregistree,
  });

  @override
  State<VenteFormeModerne> createState() => _VenteFormeModerneState();
}

class _VenteFormeModerneState extends State<VenteFormeModerne> {
  final _formKey = GlobalKey<FormState>();
  final _clientController = TextEditingController();
  final _observationsController = TextEditingController();

  late final EspaceCommercialController _espaceCtrl;
  final VenteService _venteService = VenteService();
  final UserSession _session = Get.find<UserSession>();

  Prelevement? _prelevementSelectionne;
  // Map produitId -> quantité vendue saisie
  final Map<String, int> _quantitesSaisies = {};
  String _modePaiement = 'especes';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _espaceCtrl = Get.find<EspaceCommercialController>();
  }

  @override
  void dispose() {
    _clientController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.point_of_sale,
                      color: Colors.white, size: 28),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Nouvelle Vente',
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
                          labelText: 'Prélèvement à vendre',
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

                      // Nom du client
                      TextFormField(
                        controller: _clientController,
                        decoration: InputDecoration(
                          labelText: 'Nom du client',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Entrez le nom du client';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Mode de paiement
                      DropdownButtonFormField<String>(
                        value: _modePaiement,
                        decoration: InputDecoration(
                          labelText: 'Mode de paiement',
                          prefixIcon: const Icon(Icons.payment),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'especes', child: Text('Espèces')),
                          DropdownMenuItem(
                              value: 'mobile_money',
                              child: Text('Mobile Money')),
                          DropdownMenuItem(
                              value: 'virement',
                              child: Text('Virement bancaire')),
                        ],
                        onChanged: (value) =>
                            setState(() => _modePaiement = value!),
                      ),

                      const SizedBox(height: 16),

                      // Observations
                      TextFormField(
                        controller: _observationsController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Observations (optionnel)',
                          prefixIcon: const Icon(Icons.note),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
                      onPressed: _isLoading ? null : _enregistrerVente,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
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
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.shopping_cart, color: Color(0xFF1D4ED8)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Sélection des produits restants (${restants.length})',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800)),
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
              final maxQte =
                  prod.quantitePreleve; // quantité restante disponible
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
                            if (v == null || v.isEmpty)
                              return null; // champ facultatif produit par produit
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
        Text('Montant estimé: ${VenteUtils.formatPrix(total)}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _enregistrerVente() async {
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
      final produitsVendus = <ProduitVendu>[];
      double montantTotal = 0;

      for (final prod in restants) {
        final q = _quantitesSaisies[prod.produitId];
        if (q == null || q <= 0) continue;
        final montant = prod.prixUnitaire * q;
        final vendu = ProduitVendu(
          produitId: prod.produitId,
          numeroLot: prod.numeroLot,
          typeEmballage: prod.typeEmballage,
          contenanceKg: prod.contenanceKg,
          quantiteVendue: q,
          prixUnitaire: prod.prixUnitaire,
          prixVente: prod
              .prixUnitaire, // pas de remise/unité différente pour l'instant
          montantTotal: montant,
        );
        montantTotal += montant;
        produitsVendus.add(vendu);
      }

      if (produitsVendus.isEmpty) {
        Get.snackbar('Aucun produit', 'Aucune quantité valide sélectionnée',
            backgroundColor: Colors.orange, colorText: Colors.white);
        setState(() => _isLoading = false);
        return;
      }

      final venteId = 'VTE_${DateTime.now().millisecondsSinceEpoch}';
      final commercialId = _session.email ?? 'Commercial_Inconnu';
      final commercialNom =
          commercialId; // fallback simple (pas de prenom/nom disponibles)
      final clientNom = _clientController.text.trim();

      // Statut initial: si paiement complet supposé immédiat -> payeeEnTotalite, sinon crédit en attente (simplification)
      final statut = _modePaiement == 'especes' || _modePaiement == 'virement'
          ? StatutVente.payeeEnTotalite
          : StatutVente.creditEnAttente;

      final vente = Vente(
        id: venteId,
        prelevementId: prelevement.id,
        commercialId: commercialId,
        commercialNom: commercialNom,
        clientId: 'CLIENT_LIBRE',
        clientNom: clientNom,
        produits: produitsVendus,
        montantTotal: montantTotal,
        montantPaye: statut == StatutVente.payeeEnTotalite ? montantTotal : 0,
        montantRestant:
            statut == StatutVente.payeeEnTotalite ? 0 : montantTotal,
        modePaiement: _mapModePaiement(_modePaiement),
        statut: statut,
        dateVente: DateTime.now(),
        observations: _observationsController.text.trim().isEmpty
            ? null
            : _observationsController.text.trim(),
      );

      debugPrint('📝 [VenteForm] Création vente:');
      debugPrint('   🆔 ID: ${vente.id}');
      debugPrint('   👤 CommercialId: ${vente.commercialId}');
      debugPrint('   🏢 UserSession.site: ${_session.site}');
      debugPrint('   📧 UserSession.email: ${_session.email}');

      final ok = await _venteService.enregistrerVente(vente);
      if (!ok) throw 'Echec enregistrement';

      Get.snackbar(
        'Succès',
        'Vente enregistrée (${produitsVendus.length} produits)',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );

      widget.onVenteEnregistree();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'enregistrer la vente: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  ModePaiement _mapModePaiement(String raw) {
    switch (raw) {
      case 'especes':
        return ModePaiement.espece;
      case 'mobile_money':
        return ModePaiement.mobile;
      case 'virement':
        return ModePaiement.virement;
      default:
        return ModePaiement.espece;
    }
  }
}
