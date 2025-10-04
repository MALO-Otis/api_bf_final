import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/vente_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/vente_service.dart';
import '../utils/perte_receipt_pdf.dart';
import '../utils/perte_receipt_text.dart';
import '../../../utils/platform_download_helper.dart';
// import 'dart:html' as html; // retiré pour compatibilité desktop
/// 💔 MODAL DE FORMULAIRE DE DÉCLARATION DE PERTE COMPLET
///
/// Interface complète pour déclarer des pertes de produits

class PerteFormModal extends StatefulWidget {
  final Prelevement prelevement;
  final VoidCallback onPerteEnregistree;

  const PerteFormModal({
    super.key,
    required this.prelevement,
    required this.onPerteEnregistree,
  });

  @override
  State<PerteFormModal> createState() => _PerteFormModalState();
}

class _PerteFormModalState extends State<PerteFormModal> {
  final VenteService _service = VenteService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _motifController = TextEditingController();
  final _observationsController = TextEditingController();

  // État du formulaire
  DateTime _datePerte = DateTime.now();
  TypePerte _typePerte = TypePerte.casse;
  final Map<String, int> _quantitesPerdues = {};
  final Map<String, String> _circonstancesProduits = {};
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
      _quantitesPerdues[produit.produitId] = 0;
      _circonstancesProduits[produit.produitId] = '';
    }
  }

  void _updateQuantite(String produitId, int nouvelleQuantite) {
    setState(() {
      _quantitesPerdues[produitId] = nouvelleQuantite;
      _calculerValeurTotale();
    });
  }

  void _calculerValeurTotale() {
    double total = 0.0;

    for (final produit in widget.prelevement.produits) {
      final quantite = _quantitesPerdues[produit.produitId] ?? 0;
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
        width: isMobile ? double.infinity : 850,
        height: isMobile ? MediaQuery.of(context).size.height * 0.95 : 700,
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
                      const SizedBox(height: 20),
                      _buildWarningSection(isMobile),
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
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.warning,
            color: Colors.red,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Déclaration de Perte',
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
              '📅 Date de la Perte',
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
                    Icon(Icons.calendar_today, color: Colors.red.shade600),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('dd/MM/yyyy à HH:mm').format(_datePerte),
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
              '💔 Type de Perte',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TypePerte>(
              value: _typePerte,
              decoration: InputDecoration(
                labelText: 'Type de perte *',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: TypePerte.values
                  .map((type) => DropdownMenuItem<TypePerte>(
                        value: type,
                        child: Text(_getTypePerteLabel(type)),
                      ))
                  .toList(),
              onChanged: (type) => setState(() => _typePerte = type!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProduitsSection(bool isMobile) {
    final produitsAvecPerte = widget.prelevement.produits
        .where((p) => _quantitesPerdues[p.produitId]! > 0)
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
                  '📦 Sélection des Produits Perdus',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                if (produitsAvecPerte.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${produitsAvecPerte.length} sélectionné${produitsAvecPerte.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Colors.red,
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
            constraints: const BoxConstraints(maxHeight: 350),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              itemCount: widget.prelevement.produits.length,
              itemBuilder: (context, index) {
                final produit = widget.prelevement.produits[index];
                return _buildProduitPerteItem(produit, isMobile);
              },
            ),
          ),
          if (produitsAvecPerte.isNotEmpty) ...[
            const Divider(height: 1),
            _buildRecapPerte(produitsAvecPerte, isMobile),
          ],
        ],
      ),
    );
  }

  Widget _buildProduitPerteItem(ProduitPreleve produit, bool isMobile) {
    final quantitePerdue = _quantitesPerdues[produit.produitId] ?? 0;
    final circonstances = _circonstancesProduits[produit.produitId] ?? '';
    final isSelected = quantitePerdue > 0;
    final emoji = VenteUtils.getEmojiiForTypeEmballage(produit.typeEmballage);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.red.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.red : Colors.grey.shade200,
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
                  color:
                      isSelected ? Colors.red.withOpacity(0.1) : Colors.white,
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
                      color: Colors.red,
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
                      onPressed: quantitePerdue > 0
                          ? () => _updateQuantite(
                              produit.produitId, quantitePerdue - 1)
                          : null,
                      icon: const Icon(Icons.remove),
                      iconSize: 16,
                      style: IconButton.styleFrom(
                        backgroundColor: quantitePerdue > 0
                            ? Colors.red.withOpacity(0.1)
                            : Colors.grey.shade200,
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        initialValue: quantitePerdue.toString(),
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
                      onPressed: quantitePerdue < produit.quantitePreleve
                          ? () => _updateQuantite(
                              produit.produitId, quantitePerdue + 1)
                          : null,
                      icon: const Icon(Icons.add),
                      iconSize: 16,
                      style: IconButton.styleFrom(
                        backgroundColor:
                            quantitePerdue < produit.quantitePreleve
                                ? Colors.red.withOpacity(0.1)
                                : Colors.grey.shade200,
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Circonstances de la perte (si sélectionné)
          if (isSelected) ...[
            const SizedBox(height: 12),
            TextFormField(
              initialValue: circonstances,
              decoration: InputDecoration(
                labelText: 'Circonstances de la perte *',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Décrivez comment la perte s\'est produite...',
                isDense: true,
              ),
              maxLines: 2,
              onChanged: (value) {
                setState(() {
                  _circonstancesProduits[produit.produitId] = value;
                });
              },
              validator: (value) {
                if (isSelected && (value == null || value.trim().isEmpty)) {
                  return 'Les circonstances sont requises pour ce produit';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecapPerte(List<ProduitPreleve> produitsPerdus, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      color: Colors.red.withOpacity(0.05),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Récapitulatif: ${produitsPerdus.length} produit${produitsPerdus.length > 1 ? 's' : ''} perdu${produitsPerdus.length > 1 ? 's' : ''}',
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
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Total quantité: ${produitsPerdus.fold(0, (sum, p) => sum + (_quantitesPerdues[p.produitId] ?? 0))}',
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
        labelText: 'Motif général de la perte *',
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        hintText: 'Expliquez les raisons générales de la perte...',
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
        hintText: 'Commentaires additionnels, mesures préventives...',
      ),
    );
  }

  Widget _buildWarningSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.amber.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ Validation requise',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cette déclaration de perte nécessitera une validation par votre hiérarchie avant d\'être définitivement enregistrée.',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    final produitsPerdus = widget.prelevement.produits
        .where((p) => _quantitesPerdues[p.produitId]! > 0)
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
            onPressed:
                _isLoading || produitsPerdus.isEmpty ? null : _enregistrerPerte,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Déclarer Perte (${VenteUtils.formatPrix(_valeurTotale)})'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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
      initialDate: _datePerte,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_datePerte),
      );

      if (time != null) {
        setState(() {
          _datePerte = DateTime(
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

  String _getTypePerteLabel(TypePerte type) {
    switch (type) {
      case TypePerte.casse:
        return '💥 Casse/Bris';
      case TypePerte.vol:
        return '🔓 Vol';
      case TypePerte.deterioration:
        return '🦠 Détérioration';
      case TypePerte.expiration:
        return '⏰ Expiration';
      case TypePerte.autre:
        return '❓ Autre';
    }
  }

  Future<void> _enregistrerPerte() async {
    if (!_formKey.currentState!.validate()) return;

    final produitsPerdus = widget.prelevement.produits
        .where((p) => _quantitesPerdues[p.produitId]! > 0)
        .toList();

    if (produitsPerdus.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez sélectionner au moins un produit perdu',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Vérifier que toutes les circonstances sont renseignées
    for (final produit in produitsPerdus) {
      final circonstances = _circonstancesProduits[produit.produitId] ?? '';
      if (circonstances.trim().isEmpty) {
        Get.snackbar(
          'Erreur',
          'Veuillez renseigner les circonstances pour tous les produits sélectionnés',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Préparer les produits perdus
      final List<ProduitPerdu> produitsPertesFinal =
          produitsPerdus.map((produit) {
        final quantite = _quantitesPerdues[produit.produitId]!;
        final circonstances = _circonstancesProduits[produit.produitId]!;
        return ProduitPerdu(
          produitId: produit.produitId,
          numeroLot: produit.numeroLot,
          typeEmballage: produit.typeEmballage,
          quantitePerdue: quantite,
          valeurUnitaire: produit.prixUnitaire,
          circonstances: circonstances,
        );
      }).toList();

      // Créer la perte
      final perte = Perte(
        id: 'PERTE_${DateTime.now().millisecondsSinceEpoch}',
        prelevementId: widget.prelevement.id,
        commercialId: widget.prelevement.commercialId,
        commercialNom: widget.prelevement.commercialNom,
        datePerte: _datePerte,
        produits: produitsPertesFinal,
        valeurTotale: _valeurTotale,
        type: _typePerte,
        motif: _motifController.text.trim(),
        observations: _observationsController.text.trim().isNotEmpty
            ? _observationsController.text.trim()
            : null,
        estValidee: false, // Nécessite validation
        validateurId: null,
        dateValidation: null,
      );

      // Enregistrer la perte
      final success = await _service.enregistrerPerte(perte);

      if (success) {
        Get.back();
        widget.onPerteEnregistree();
        // Générer reçu texte
        final recu = buildPerteReceiptText(perte);
        // Copier auto
        await Clipboard.setData(ClipboardData(text: recu));
        // Afficher dialog reçu
        _showPerteReceiptDialog(perte, recu);
      } else {
        Get.snackbar(
          'Erreur',
          'Impossible d\'enregistrer la déclaration de perte. Veuillez réessayer.',
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

  void _showPerteReceiptDialog(Perte perte, String recu) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Reçu Déclaration Perte'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: SelectableText(
              recu,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Fermer')),
          TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: recu));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Reçu copié dans le presse-papiers')));
              },
              child: const Text('Copier')),
          TextButton(
              onPressed: () => _downloadPerteTxt(perte, recu),
              child: const Text('Télécharger .txt')),
          TextButton(
              onPressed: () => _downloadPertePdf(perte),
              child: const Text('Télécharger PDF')),
        ],
      ),
    );
  }

  void _downloadPerteTxt(Perte perte, String recu) {
    final stamp = DateFormat('yyyyMMdd_HHmm').format(perte.datePerte);
    downloadTextCross(recu, fileName: 'recu_perte_${perte.id}_$stamp.txt');
  }

  Future<void> _downloadPertePdf(Perte perte) async {
    try {
      final data = await buildPerteReceiptPdf(perte);
      final stamp = DateFormat('yyyyMMdd_HHmm').format(perte.datePerte);
      await downloadBytesCross(data,
          fileName: 'recu_perte_${perte.id}_$stamp.pdf',
          mime: 'application/pdf');
    } catch (e) {
      Get.snackbar('Erreur', 'PDF non généré: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
