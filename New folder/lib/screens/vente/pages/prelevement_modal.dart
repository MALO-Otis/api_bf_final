/// 📋 MODAL DE CRÉATION DE PRÉLÈVEMENT
///
/// Interface pour créer un nouveau prélèvement pour un commercial

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../services/vente_service.dart';
import '../models/vente_models.dart';

class PrelevementModal extends StatefulWidget {
  final List<ProduitConditionne> produits;
  final ProduitConditionne? produitPreselectionne;
  final VoidCallback onPrelevementCree;

  const PrelevementModal({
    super.key,
    required this.produits,
    this.produitPreselectionne,
    required this.onPrelevementCree,
  });

  @override
  State<PrelevementModal> createState() => _PrelevementModalState();
}

class _PrelevementModalState extends State<PrelevementModal> {
  final VenteService _service = VenteService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _commercialNomController = TextEditingController();
  final _observationsController = TextEditingController();

  // Données
  String _commercialId = '';
  final Map<String, int> _quantitesSelectionnees = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _generateCommercialId();

    // Présélectionner un produit si fourni
    if (widget.produitPreselectionne != null) {
      _quantitesSelectionnees[widget.produitPreselectionne!.id] = 1;
    }
  }

  @override
  void dispose() {
    _commercialNomController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  void _generateCommercialId() {
    final now = DateTime.now();
    _commercialId = 'COM_${now.millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: isMobile ? double.infinity : 800,
        height: isMobile ? MediaQuery.of(context).size.height * 0.9 : 600,
        padding: EdgeInsets.all(isMobile ? 20 : 24),
        child: Column(
          children: [
            _buildHeader(isMobile),
            const SizedBox(height: 20),
            Expanded(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildCommercialSection(isMobile),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _buildProduitsSection(isMobile),
                    ),
                    const SizedBox(height: 20),
                    _buildObservationsSection(isMobile),
                    const SizedBox(height: 20),
                    _buildFooter(isMobile),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1976D2).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.add_shopping_cart,
            color: Color(0xFF1976D2),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nouveau Prélèvement',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                'Attribuer des produits à un commercial',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.close),
          color: Colors.grey.shade600,
        ),
      ],
    );
  }

  Widget _buildCommercialSection(bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '👤 Informations Commercial',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _commercialNomController,
                    decoration: InputDecoration(
                      labelText: 'Nom du commercial *',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le nom du commercial est requis';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _commercialId,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'ID Commercial',
                      prefixIcon: const Icon(Icons.badge),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProduitsSection(bool isMobile) {
    final produitsDisponibles = widget.produits;
    final produitsSelectionnes = produitsDisponibles
        .where((p) =>
            _quantitesSelectionnees.containsKey(p.id) &&
            _quantitesSelectionnees[p.id]! > 0)
        .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Row(
              children: [
                Text(
                  '📦 Sélection des Produits',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                if (produitsSelectionnes.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${produitsSelectionnes.length} sélectionné${produitsSelectionnes.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Color(0xFF1976D2),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              itemCount: produitsDisponibles.length,
              itemBuilder: (context, index) {
                final produit = produitsDisponibles[index];
                return _buildProduitItem(produit, isMobile);
              },
            ),
          ),
          if (produitsSelectionnes.isNotEmpty) ...[
            const Divider(height: 1),
            _buildRecapitulatif(produitsSelectionnes, isMobile),
          ],
        ],
      ),
    );
  }

  Widget _buildProduitItem(ProduitConditionne produit, bool isMobile) {
    final quantiteSelectionnee = _quantitesSelectionnees[produit.id] ?? 0;
    final isSelected = quantiteSelectionnee > 0;
    final emoji = VenteUtils.getEmojiiForTypeEmballage(produit.typeEmballage);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF1976D2).withOpacity(0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF1976D2) : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Emoji et infos produit
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1976D2).withOpacity(0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produit.numeroLot,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${produit.typeEmballage} - ${produit.contenanceKg}kg',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '${produit.producteur} - ${produit.village}',
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          // Disponible et prix
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${produit.quantiteDisponible} disponible${produit.quantiteDisponible > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: isMobile ? 10 : 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                VenteUtils.formatPrix(produit.prixUnitaire),
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // Sélecteur de quantité
          Container(
            width: 120,
            child: Row(
              children: [
                IconButton(
                  onPressed: quantiteSelectionnee > 0
                      ? () =>
                          _updateQuantite(produit.id, quantiteSelectionnee - 1)
                      : null,
                  icon: const Icon(Icons.remove),
                  iconSize: 16,
                  style: IconButton.styleFrom(
                    backgroundColor: quantiteSelectionnee > 0
                        ? const Color(0xFF1976D2).withOpacity(0.1)
                        : Colors.grey.shade200,
                    minimumSize: const Size(32, 32),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: quantiteSelectionnee.toString(),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(fontSize: isMobile ? 12 : 14),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      final quantite = int.tryParse(value) ?? 0;
                      if (quantite <= produit.quantiteDisponible) {
                        _updateQuantite(produit.id, quantite);
                      }
                    },
                  ),
                ),
                IconButton(
                  onPressed: quantiteSelectionnee < produit.quantiteDisponible
                      ? () =>
                          _updateQuantite(produit.id, quantiteSelectionnee + 1)
                      : null,
                  icon: const Icon(Icons.add),
                  iconSize: 16,
                  style: IconButton.styleFrom(
                    backgroundColor:
                        quantiteSelectionnee < produit.quantiteDisponible
                            ? const Color(0xFF1976D2).withOpacity(0.1)
                            : Colors.grey.shade200,
                    minimumSize: const Size(32, 32),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecapitulatif(
      List<ProduitConditionne> produitsSelectionnes, bool isMobile) {
    final valeurTotale = produitsSelectionnes.fold(0.0, (sum, produit) {
      final quantite = _quantitesSelectionnees[produit.id] ?? 0;
      return sum + (quantite * produit.prixUnitaire);
    });

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      color: const Color(0xFF1976D2).withOpacity(0.05),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Récapitulatif: ${produitsSelectionnes.length} produit${produitsSelectionnes.length > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Text(
            VenteUtils.formatPrix(valeurTotale),
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1976D2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObservationsSection(bool isMobile) {
    return TextFormField(
      controller: _observationsController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Observations (optionnel)',
        prefixIcon: const Icon(Icons.note),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        hintText: 'Commentaires ou instructions particulières...',
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    final produitsSelectionnes = widget.produits
        .where((p) =>
            _quantitesSelectionnees.containsKey(p.id) &&
            _quantitesSelectionnees[p.id]! > 0)
        .toList();

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Get.back(),
            child: const Text('Annuler'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading || produitsSelectionnes.isEmpty
                ? null
                : _creerPrelevement,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Créer Prélèvement (${produitsSelectionnes.length})'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _updateQuantite(String produitId, int nouvelleQuantite) {
    setState(() {
      if (nouvelleQuantite <= 0) {
        _quantitesSelectionnees.remove(produitId);
      } else {
        _quantitesSelectionnees[produitId] = nouvelleQuantite;
      }
    });
  }

  Future<void> _creerPrelevement() async {
    if (!_formKey.currentState!.validate()) return;

    final produitsSelectionnes = widget.produits
        .where((p) =>
            _quantitesSelectionnees.containsKey(p.id) &&
            _quantitesSelectionnees[p.id]! > 0)
        .toList();

    if (produitsSelectionnes.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez sélectionner au moins un produit',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Préparer les données des produits sélectionnés
      final List<Map<String, dynamic>> produitsData =
          produitsSelectionnes.map((produit) {
        final quantite = _quantitesSelectionnees[produit.id]!;
        return {
          'produitId': produit.id,
          'numeroLot': produit.numeroLot,
          'typeEmballage': produit.typeEmballage,
          'contenanceKg': produit.contenanceKg,
          'quantitePreleve': quantite,
          'prixUnitaire': produit.prixUnitaire,
        };
      }).toList();

      // Créer le prélèvement
      final success = await _service.creerPrelevement(
        commercialId: _commercialId,
        commercialNom: _commercialNomController.text.trim(),
        produitsSelectionnes: produitsData,
        observations: _observationsController.text.trim().isNotEmpty
            ? _observationsController.text.trim()
            : null,
      );

      if (success) {
        Get.back();
        Get.snackbar(
          'Succès',
          'Prélèvement créé avec succès pour ${_commercialNomController.text}',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        widget.onPrelevementCree();
      } else {
        Get.snackbar(
          'Erreur',
          'Impossible de créer le prélèvement. Veuillez réessayer.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Une erreur est survenue: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
