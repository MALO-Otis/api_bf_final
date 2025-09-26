/// 📋 MODAL DE CRÉATION D'ATTRIBUTION
///
/// Interface pour créer une nouvelle attribution de produits pour un commercial

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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Breakpoints responsive ultra-précis
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final isExtraSmall = screenWidth < 480;
        final isSmall = screenWidth < 768;
        final isMedium = screenWidth < 1024;

        // Calcul intelligent des dimensions
        double dialogWidth;
        double dialogHeight;

        if (isExtraSmall) {
          dialogWidth = screenWidth * 0.95;
          dialogHeight = screenHeight * 0.92;
        } else if (isSmall) {
          dialogWidth = screenWidth * 0.90;
          dialogHeight = screenHeight * 0.88;
        } else if (isMedium) {
          dialogWidth = 750;
          dialogHeight = screenHeight * 0.85;
        } else {
          dialogWidth = 850;
          dialogHeight = 650;
        }

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isExtraSmall ? 16 : 20),
          ),
          child: Container(
            width: dialogWidth,
            height: dialogHeight,
            padding: EdgeInsets.all(isExtraSmall
                ? 16
                : isSmall
                    ? 20
                    : 24),
            child: Column(
              children: [
                _buildHeader(isExtraSmall, isSmall, isMedium),
                SizedBox(height: isExtraSmall ? 16 : 20),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildCommercialSection(
                              isExtraSmall, isSmall, isMedium),
                          SizedBox(height: isExtraSmall ? 16 : 20),
                          SizedBox(
                            height: isExtraSmall
                                ? dialogHeight * 0.45
                                : isSmall
                                    ? dialogHeight * 0.48
                                    : dialogHeight * 0.50,
                            child: _buildProduitsSection(
                                isExtraSmall, isSmall, isMedium),
                          ),
                          SizedBox(height: isExtraSmall ? 16 : 20),
                          _buildObservationsSection(
                              isExtraSmall, isSmall, isMedium),
                          SizedBox(height: isExtraSmall ? 16 : 20),
                          _buildFooter(isExtraSmall, isSmall, isMedium),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isExtraSmall, bool isSmall, bool isMedium) {
    return Container(
      padding: EdgeInsets.all(isExtraSmall ? 12 : 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isExtraSmall ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isExtraSmall ? 8 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.add_shopping_cart,
              color: Colors.white,
              size: isExtraSmall ? 20 : 24,
            ),
          ),
          SizedBox(width: isExtraSmall ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExtraSmall ? 'Attribution' : 'Nouvelle Attribution',
                  style: TextStyle(
                    fontSize: isExtraSmall
                        ? 16
                        : isSmall
                            ? 18
                            : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (!isExtraSmall)
                  Text(
                    'Attribuer des produits à un commercial',
                    style: TextStyle(
                      fontSize: isExtraSmall
                          ? 11
                          : isSmall
                              ? 12
                              : 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close, color: Colors.white),
            iconSize: isExtraSmall ? 20 : 24,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommercialSection(
      bool isExtraSmall, bool isSmall, bool isMedium) {
    return Card(
      elevation: isExtraSmall ? 3 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isExtraSmall ? 12 : 16),
      ),
      child: Container(
        padding: EdgeInsets.all(isExtraSmall
            ? 12
            : isSmall
                ? 16
                : 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isExtraSmall ? 12 : 16),
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isExtraSmall ? 8 : 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.person,
                    color: const Color(0xFF1976D2),
                    size: isExtraSmall ? 18 : 20,
                  ),
                ),
                SizedBox(width: isExtraSmall ? 8 : 12),
                Expanded(
                  child: Text(
                    isExtraSmall ? 'Commercial' : 'Informations Commercial',
                    style: TextStyle(
                      fontSize: isExtraSmall
                          ? 14
                          : isSmall
                              ? 15
                              : 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1976D2),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isExtraSmall ? 12 : 16),

            // Layout adaptatif pour les champs
            if (isExtraSmall || isSmall)
              Column(
                children: [
                  TextFormField(
                    controller: _commercialNomController,
                    decoration: InputDecoration(
                      labelText: 'Nom du commercial *',
                      prefixIcon:
                          Icon(Icons.person, size: isExtraSmall ? 20 : 24),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF1976D2), width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: isExtraSmall ? 12 : 16,
                        horizontal: 16,
                      ),
                    ),
                    style: TextStyle(fontSize: isExtraSmall ? 14 : 16),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le nom du commercial est requis';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: isExtraSmall ? 12 : 16),
                  TextFormField(
                    initialValue: _commercialId,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'ID Commercial',
                      prefixIcon:
                          Icon(Icons.badge, size: isExtraSmall ? 20 : 24),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: isExtraSmall ? 12 : 16,
                        horizontal: 16,
                      ),
                    ),
                    style: TextStyle(fontSize: isExtraSmall ? 14 : 16),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _commercialNomController,
                      decoration: InputDecoration(
                        labelText: 'Nom du commercial *',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF1976D2), width: 2),
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

  Widget _buildProduitsSection(bool isExtraSmall, bool isSmall, bool isMedium) {
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
            padding: EdgeInsets.all(isExtraSmall
                ? 12
                : isSmall
                    ? 16
                    : 20),
            child: Row(
              children: [
                Text(
                  isExtraSmall ? '📦 Produits' : '📦 Sélection des Produits',
                  style: TextStyle(
                    fontSize: isExtraSmall
                        ? 14
                        : isSmall
                            ? 15
                            : 16,
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
              padding: EdgeInsets.all(isExtraSmall
                  ? 12
                  : isSmall
                      ? 16
                      : 20),
              itemCount: produitsDisponibles.length,
              itemBuilder: (context, index) {
                final produit = produitsDisponibles[index];
                return _buildProduitItem(
                    produit, isExtraSmall, isSmall, isMedium);
              },
            ),
          ),
          if (produitsSelectionnes.isNotEmpty) ...[
            const Divider(height: 1),
            _buildRecapitulatif(
                produitsSelectionnes, isExtraSmall, isSmall, isMedium),
          ],
        ],
      ),
    );
  }

  Widget _buildProduitItem(ProduitConditionne produit, bool isExtraSmall,
      bool isSmall, bool isMedium) {
    final quantiteSelectionnee = _quantitesSelectionnees[produit.id] ?? 0;
    final isSelected = quantiteSelectionnee > 0;
    final emoji = VenteUtils.getEmojiiForTypeEmballage(produit.typeEmballage);
    final valeurTotaleItem = quantiteSelectionnee * produit.prixUnitaire;

    return Card(
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? const Color(0xFF1976D2) : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(isExtraSmall
            ? 8
            : isSmall
                ? 12
                : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    const Color(0xFF1976D2).withOpacity(0.05),
                    const Color(0xFF1976D2).withOpacity(0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Column(
          children: [
            // Ligne principale avec infos produit
            Row(
              children: [
                // Emoji et infos produit
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1976D2).withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1976D2).withOpacity(0.3)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              produit.numeroLot,
                              style: TextStyle(
                                fontSize: isExtraSmall
                                    ? 14
                                    : isSmall
                                        ? 15
                                        : 17,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? const Color(0xFF1976D2)
                                    : Colors.grey.shade800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${produit.quantiteDisponible} disp.',
                              style: TextStyle(
                                fontSize: isExtraSmall
                                    ? 9
                                    : isSmall
                                        ? 10
                                        : 12,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${produit.typeEmballage} - ${produit.contenanceKg}kg',
                        style: TextStyle(
                          fontSize: isExtraSmall
                              ? 12
                              : isSmall
                                  ? 13
                                  : 15,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${produit.producteur} - ${produit.village}',
                              style: TextStyle(
                                fontSize: isExtraSmall
                                    ? 10
                                    : isSmall
                                        ? 11
                                        : 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              VenteUtils.formatPrix(produit.prixUnitaire),
                              style: TextStyle(
                                fontSize: isExtraSmall
                                    ? 10
                                    : isSmall
                                        ? 11
                                        : 13,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Sélecteur de quantité et récapitulatif
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantité à attribuer',
                        style: TextStyle(
                          fontSize: isExtraSmall
                              ? 10
                              : isSmall
                                  ? 11
                                  : 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          IconButton(
                            onPressed: quantiteSelectionnee > 0
                                ? () => _updateQuantite(
                                    produit.id, quantiteSelectionnee - 1)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                            iconSize: 20,
                            style: IconButton.styleFrom(
                              backgroundColor: quantiteSelectionnee > 0
                                  ? const Color(0xFF1976D2).withOpacity(0.1)
                                  : Colors.grey.shade200,
                              minimumSize: const Size(36, 36),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 40,
                              child: TextFormField(
                                initialValue: quantiteSelectionnee.toString(),
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                style: TextStyle(
                                  fontSize: isExtraSmall
                                      ? 12
                                      : isSmall
                                          ? 14
                                          : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: isSelected
                                          ? const Color(0xFF1976D2)
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF1976D2),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  isDense: true,
                                  filled: true,
                                  fillColor: isSelected
                                      ? const Color(0xFF1976D2)
                                          .withOpacity(0.05)
                                      : Colors.white,
                                ),
                                onChanged: (value) {
                                  final quantite = int.tryParse(value) ?? 0;
                                  if (quantite <= produit.quantiteDisponible) {
                                    _updateQuantite(produit.id, quantite);
                                  }
                                },
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: quantiteSelectionnee <
                                    produit.quantiteDisponible
                                ? () => _updateQuantite(
                                    produit.id, quantiteSelectionnee + 1)
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                            iconSize: 20,
                            style: IconButton.styleFrom(
                              backgroundColor: quantiteSelectionnee <
                                      produit.quantiteDisponible
                                  ? const Color(0xFF1976D2).withOpacity(0.1)
                                  : Colors.grey.shade200,
                              minimumSize: const Size(36, 36),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF1976D2).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Valeur totale',
                          style: TextStyle(
                            fontSize: isExtraSmall
                                ? 9
                                : isSmall
                                    ? 10
                                    : 12,
                            color: const Color(0xFF1976D2),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          VenteUtils.formatPrix(valeurTotaleItem),
                          style: TextStyle(
                            fontSize: isExtraSmall
                                ? 12
                                : isSmall
                                    ? 14
                                    : 16,
                            color: const Color(0xFF1976D2),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecapitulatif(List<ProduitConditionne> produitsSelectionnes,
      bool isExtraSmall, bool isSmall, bool isMedium) {
    final valeurTotale = produitsSelectionnes.fold(0.0, (sum, produit) {
      final quantite = _quantitesSelectionnees[produit.id] ?? 0;
      return sum + (quantite * produit.prixUnitaire);
    });

    return Container(
      padding: EdgeInsets.all(isExtraSmall
          ? 14
          : isSmall
              ? 16
              : 20),
      color: const Color(0xFF1976D2).withOpacity(0.05),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Récapitulatif: ${produitsSelectionnes.length} produit${produitsSelectionnes.length > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: isExtraSmall
                    ? 12
                    : isSmall
                        ? 14
                        : 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Text(
            VenteUtils.formatPrix(valeurTotale),
            style: TextStyle(
              fontSize: isExtraSmall
                  ? 14
                  : isSmall
                      ? 16
                      : 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1976D2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObservationsSection(
      bool isExtraSmall, bool isSmall, bool isMedium) {
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

  Widget _buildFooter(bool isExtraSmall, bool isSmall, bool isMedium) {
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
              padding: EdgeInsets.symmetric(
                  vertical: isExtraSmall
                      ? 12
                      : isSmall
                          ? 14
                          : 16),
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
                : Text('Créer Attribution (${produitsSelectionnes.length})'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                  vertical: isExtraSmall
                      ? 12
                      : isSmall
                          ? 14
                          : 16),
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
          'Attribution créée avec succès pour ${_commercialNomController.text}',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        widget.onPrelevementCree();
      } else {
        Get.snackbar(
          'Erreur',
          'Impossible de créer l\'attribution. Veuillez réessayer.',
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
