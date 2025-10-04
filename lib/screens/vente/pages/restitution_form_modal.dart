/// 🔄 MODAL DE FORMULAIRE DE RESTITUTION COMPLET
///
/// Interface complète pour enregistrer une restitution de produits

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/vente_models.dart';
import '../services/vente_service.dart';

class RestitutionFormModal extends StatefulWidget {
  final Prelevement prelevement;
  final VoidCallback onRestitutionEnregistree;

  const RestitutionFormModal({
    super.key,
    required this.prelevement,
    required this.onRestitutionEnregistree,
  });

  @override
  State<RestitutionFormModal> createState() => _RestitutionFormModalState();
}

class _RestitutionFormModalState extends State<RestitutionFormModal> {
  final VenteService _service = VenteService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _motifController = TextEditingController();
  final _observationsController = TextEditingController();

  // État du formulaire
  DateTime _dateRestitution = DateTime.now();
  TypeRestitution _typeRestitution = TypeRestitution.invendu;
  final Map<String, int> _quantitesRestituees = {};
  final Map<String, String> _etatsProductes = {};
  bool _isLoading = false;

  // Données calculées
  double _valeurTotale = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeQuantites();
  }

  @override
  void dispose() {
    _motifController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  void _initializeQuantites() {
    // Initialiser toutes les quantités à 0
    for (final produit in widget.prelevement.produits) {
      _quantitesRestituees[produit.produitId] = 0;
      _etatsProductes[produit.produitId] = 'BON';
    }
  }

  void _updateQuantite(String produitId, int nouvelleQuantite) {
    setState(() {
      _quantitesRestituees[produitId] = nouvelleQuantite;
      _calculerValeurTotale();
    });
  }

  void _calculerValeurTotale() {
    double total = 0.0;

    for (final produit in widget.prelevement.produits) {
      final quantite = _quantitesRestituees[produit.produitId] ?? 0;
      total += quantite * produit.prixUnitaire;
    }

    _valeurTotale = total;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: isMobile ? double.infinity : 800,
        height: isMobile ? MediaQuery.of(context).size.height * 0.9 : 650,
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          children: [
            _buildHeader(isMobile),
            const SizedBox(height: 20),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildDateSection(isMobile),
                      const SizedBox(height: 20),
                      _buildTypeSection(isMobile),
                      const SizedBox(height: 20),
                      _buildProduitsSection(isMobile),
                      const SizedBox(height: 20),
                      _buildMotifSection(isMobile),
                      const SizedBox(height: 20),
                      _buildObservationsSection(isMobile),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildFooter(isMobile),
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
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.undo,
            color: Colors.orange,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Restitution de Produits',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                'Prélèvement ${widget.prelevement.id.split('_').last}',
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

  Widget _buildDateSection(bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📅 Date de Restitution',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDate(),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.orange.shade600),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('dd/MM/yyyy à HH:mm').format(_dateRestitution),
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSection(bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔄 Type de Restitution',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TypeRestitution>(
              value: _typeRestitution,
              decoration: InputDecoration(
                labelText: 'Type de restitution *',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: TypeRestitution.values
                  .map((type) => DropdownMenuItem<TypeRestitution>(
                        value: type,
                        child: Text(_getTypeRestitutionLabel(type)),
                      ))
                  .toList(),
              onChanged: (type) => setState(() => _typeRestitution = type!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProduitsSection(bool isMobile) {
    final produitsAvecRestitution = widget.prelevement.produits
        .where((p) => _quantitesRestituees[p.produitId]! > 0)
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
                  '📦 Sélection des Produits à Restituer',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                if (produitsAvecRestitution.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${produitsAvecRestitution.length} sélectionné${produitsAvecRestitution.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              itemCount: widget.prelevement.produits.length,
              itemBuilder: (context, index) {
                final produit = widget.prelevement.produits[index];
                return _buildProduitRestitutionItem(produit, isMobile);
              },
            ),
          ),
          if (produitsAvecRestitution.isNotEmpty) ...[
            const Divider(height: 1),
            _buildRecapRestitution(produitsAvecRestitution, isMobile),
          ],
        ],
      ),
    );
  }

  Widget _buildProduitRestitutionItem(ProduitPreleve produit, bool isMobile) {
    final quantiteRestituee = _quantitesRestituees[produit.produitId] ?? 0;
    final etatProduit = _etatsProductes[produit.produitId] ?? 'BON';
    final isSelected = quantiteRestituee > 0;
    final emoji = VenteUtils.getEmojiiForTypeEmballage(produit.typeEmballage);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color:
            isSelected ? Colors.orange.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.orange : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Emoji et infos produit
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.orange.withOpacity(0.1)
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
                  ],
                ),
              ),

              // Disponible et prix
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${produit.quantitePreleve} prélevé${produit.quantitePreleve > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: isMobile ? 10 : 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    VenteUtils.formatPrix(produit.prixUnitaire),
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // Sélecteur de quantité
              SizedBox(
                width: 120,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: quantiteRestituee > 0
                          ? () => _updateQuantite(
                              produit.produitId, quantiteRestituee - 1)
                          : null,
                      icon: const Icon(Icons.remove),
                      iconSize: 16,
                      style: IconButton.styleFrom(
                        backgroundColor: quantiteRestituee > 0
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.grey.shade200,
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        initialValue: quantiteRestituee.toString(),
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        style: TextStyle(fontSize: isMobile ? 12 : 14),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 8),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          final quantite = int.tryParse(value) ?? 0;
                          if (quantite <= produit.quantitePreleve) {
                            _updateQuantite(produit.produitId, quantite);
                          }
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: quantiteRestituee < produit.quantitePreleve
                          ? () => _updateQuantite(
                              produit.produitId, quantiteRestituee + 1)
                          : null,
                      icon: const Icon(Icons.add),
                      iconSize: 16,
                      style: IconButton.styleFrom(
                        backgroundColor:
                            quantiteRestituee < produit.quantitePreleve
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.grey.shade200,
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // État du produit (si sélectionné)
          if (isSelected) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: etatProduit,
              decoration: InputDecoration(
                labelText: 'État du produit',
                prefixIcon: const Icon(Icons.check_circle),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'BON', child: Text('✅ Bon état')),
                DropdownMenuItem(
                    value: 'ENDOMMAGE', child: Text('⚠️ Endommagé')),
                DropdownMenuItem(value: 'EXPIRE', child: Text('❌ Expiré')),
                DropdownMenuItem(
                    value: 'DEFECTUEUX', child: Text('🔧 Défectueux')),
              ],
              onChanged: (etat) {
                setState(() {
                  _etatsProductes[produit.produitId] = etat!;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecapRestitution(
      List<ProduitPreleve> produitsRestitues, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      color: Colors.orange.withOpacity(0.05),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Récapitulatif: ${produitsRestitues.length} produit${produitsRestitues.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              Text(
                VenteUtils.formatPrix(_valeurTotale),
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Total quantité: ${produitsRestitues.fold(0, (sum, p) => sum + (_quantitesRestituees[p.produitId] ?? 0))}',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMotifSection(bool isMobile) {
    return TextFormField(
      controller: _motifController,
      decoration: InputDecoration(
        labelText: 'Motif de la restitution *',
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        hintText: 'Expliquez la raison de la restitution...',
      ),
      maxLines: 2,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Le motif est requis';
        }
        return null;
      },
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
        hintText: 'Commentaires additionnels...',
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    final produitsRestitues = widget.prelevement.produits
        .where((p) => _quantitesRestituees[p.produitId]! > 0)
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
            onPressed: _isLoading || produitsRestitues.isEmpty
                ? null
                : _enregistrerRestitution,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Enregistrer Restitution (${produitsRestitues.length})'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
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

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateRestitution,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dateRestitution),
      );

      if (time != null) {
        setState(() {
          _dateRestitution = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  String _getTypeRestitutionLabel(TypeRestitution type) {
    switch (type) {
      case TypeRestitution.invendu:
        return '📦 Produits invendus';
      case TypeRestitution.defaut:
        return '⚠️ Défaut produit';
      case TypeRestitution.erreur:
        return '❌ Erreur de prélèvement';
      case TypeRestitution.annulation:
        return '🚫 Annulation vente';
    }
  }

  Future<void> _enregistrerRestitution() async {
    if (!_formKey.currentState!.validate()) return;

    final produitsRestitues = widget.prelevement.produits
        .where((p) => _quantitesRestituees[p.produitId]! > 0)
        .toList();

    if (produitsRestitues.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez sélectionner au moins un produit à restituer',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Préparer les produits restitués
      final List<ProduitRestitue> produitsRestitutionFinal =
          produitsRestitues.map((produit) {
        final quantite = _quantitesRestituees[produit.produitId]!;
        final etat = _etatsProductes[produit.produitId]!;
        return ProduitRestitue(
          produitId: produit.produitId,
          numeroLot: produit.numeroLot,
          typeEmballage: produit.typeEmballage,
          quantiteRestituee: quantite,
          valeurUnitaire: produit.prixUnitaire,
          etatProduit: etat,
        );
      }).toList();

      // Créer la restitution
      final restitution = Restitution(
        id: 'REST_${DateTime.now().millisecondsSinceEpoch}',
        prelevementId: widget.prelevement.id,
        commercialId: widget.prelevement.commercialId,
        commercialNom: widget.prelevement.commercialNom,
        dateRestitution: _dateRestitution,
        produits: produitsRestitutionFinal,
        valeurTotale: _valeurTotale,
        type: _typeRestitution,
        motif: _motifController.text.trim(),
        observations: _observationsController.text.trim().isNotEmpty
            ? _observationsController.text.trim()
            : null,
      );

      // Enregistrer la restitution
      final success = await _service.enregistrerRestitution(restitution);

      if (success) {
        Get.back();
        Get.snackbar(
          'Succès',
          'Restitution enregistrée avec succès pour ${restitution.valeurTotale.toStringAsFixed(0)} FCFA',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        widget.onRestitutionEnregistree();
      } else {
        Get.snackbar(
          'Erreur',
          'Impossible d\'enregistrer la restitution. Veuillez réessayer.',
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
