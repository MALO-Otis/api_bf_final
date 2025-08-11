import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/collecte_models.dart';

/// Widget custom pour afficher et modifier un contenant dans la collecte
class ContenantCard extends StatefulWidget {
  final int index;
  final ContenantModel contenant;
  final VoidCallback? onSupprimer;
  final Function(ContenantModel) onContenantModified;

  const ContenantCard({
    Key? key,
    required this.index,
    required this.contenant,
    this.onSupprimer,
    required this.onContenantModified,
  }) : super(key: key);

  @override
  State<ContenantCard> createState() => _ContenantCardState();
}

class _ContenantCardState extends State<ContenantCard> {
  late ContenantModel _contenant;

  final _quantiteController = TextEditingController();
  final _prixController = TextEditingController();
  final _noteController =
      TextEditingController(); // Nouveau contrôleur pour la note

  // Listes des options disponibles
  final List<String> _typesRuche = ['Traditionnelle', 'Moderne'];
  final List<String> _typesMiel = ['Liquide', 'Brute', 'Cire'];
  final List<String> _typesContenant = ['Bidon', 'Pot'];
  final List<String> _predominancesFlorales = [
    'Acacia',
    'Eucalyptus',
    'Karité',
    'Néré',
    'Baobab',
    'Manguier',
    'Citronnier',
    'Fleurs sauvages',
    'Mixte'
  ];

  @override
  void initState() {
    super.initState();
    _contenant = widget.contenant;
    _quantiteController.text =
        _contenant.quantite > 0 ? _contenant.quantite.toString() : '';
    _prixController.text =
        _contenant.prixUnitaire > 0 ? _contenant.prixUnitaire.toString() : '';
    _noteController.text =
        _contenant.note; // Initialiser avec la note existante
  }

  @override
  void dispose() {
    _quantiteController.dispose();
    _prixController.dispose();
    _noteController.dispose(); // Nettoyer le nouveau contrôleur
    super.dispose();
  }

  void _updateContenant({
    String? typeRuche,
    String? typeMiel,
    String? typeContenant,
    double? quantite,
    double? prixUnitaire,
    String? predominanceFlorale,
    String? note, // Nouveau paramètre
  }) {
    setState(() {
      _contenant = _contenant.copyWith(
        typeRuche: typeRuche,
        typeMiel: typeMiel,
        typeContenant: typeContenant,
        quantite: quantite,
        prixUnitaire: prixUnitaire,
        predominanceFlorale: predominanceFlorale,
        note: note, // Nouveau champ
      );
    });
    widget.onContenantModified(_contenant);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Card(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec numéro et bouton supprimer
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 10,
                    vertical: isSmallScreen ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    'Contenant ${widget.index + 1}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
                const Spacer(),
                if (widget.onSupprimer != null)
                  IconButton(
                    onPressed: widget.onSupprimer,
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red[600],
                      size: isSmallScreen ? 20 : 24,
                    ),
                    tooltip: 'Supprimer ce contenant',
                  ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),

            // Ligne 1: Type de ruche et Type de miel
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Type de ruche *',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 6),
                      Container(
                        height: isSmallScreen ? 40 : 48,
                        padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 8 : 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _contenant.typeRuche.isEmpty
                                ? null
                                : _contenant.typeRuche,
                            hint: Text(
                              'Sélectionner',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            isExpanded: true,
                            items: _typesRuche.map((type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(
                                  type,
                                  style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                _updateContenant(typeRuche: value);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Type de miel *',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 6),
                      Container(
                        height: isSmallScreen ? 40 : 48,
                        padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 8 : 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _contenant.typeMiel.isEmpty
                                ? null
                                : _contenant.typeMiel,
                            hint: Text(
                              'Sélectionner',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            isExpanded: true,
                            items: _typesMiel.map((type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(
                                  type,
                                  style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                _updateContenant(typeMiel: value);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),

            // Ligne 2: Type de contenant
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Type de contenant *',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 4 : 6),
                Container(
                  height: isSmallScreen ? 40 : 48,
                  padding:
                      EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _contenant.typeContenant.isEmpty
                          ? null
                          : _contenant.typeContenant,
                      hint: Text(
                        'Sélectionner le type de contenant',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      isExpanded: true,
                      items: _typesContenant.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(
                            type,
                            style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _updateContenant(typeContenant: value);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),

            // Ligne 3: Quantité et Prix unitaire
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantité (kg) *',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 6),
                      TextFormField(
                        controller: _quantiteController,
                        decoration: InputDecoration(
                          hintText: '0.0',
                          hintStyle:
                              TextStyle(fontSize: isSmallScreen ? 12 : 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 8 : 12,
                            vertical: isSmallScreen ? 8 : 12,
                          ),
                          suffixText: 'kg',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*')),
                        ],
                        style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                        onChanged: (value) {
                          final quantite = double.tryParse(value) ?? 0.0;
                          _updateContenant(quantite: quantite);
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prix unitaire (FCFA/kg) *',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 6),
                      TextFormField(
                        controller: _prixController,
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle:
                              TextStyle(fontSize: isSmallScreen ? 12 : 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 8 : 12,
                            vertical: isSmallScreen ? 8 : 12,
                          ),
                          suffixText: 'FCFA',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                        onChanged: (value) {
                          final prix = double.tryParse(value) ?? 0.0;
                          _updateContenant(prixUnitaire: prix);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),

            // Ligne 4: Prédominance florale
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prédominance florale',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 4 : 6),
                Container(
                  height: isSmallScreen ? 40 : 48,
                  padding:
                      EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _contenant.predominanceFlorale.isEmpty
                          ? null
                          : _contenant.predominanceFlorale,
                      hint: Text(
                        'Sélectionner (optionnel)',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      isExpanded: true,
                      items: _predominancesFlorales.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(
                            type,
                            style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        _updateContenant(predominanceFlorale: value ?? '');
                      },
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),

            // Ligne 5: Note sur le contenant (nouveau champ)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Note sur le contenant',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 4 : 6),
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'Votre avis sur ce contenant (optionnel)',
                    hintStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 12,
                      vertical: isSmallScreen ? 8 : 12,
                    ),
                    prefixIcon: Icon(
                      Icons.note_alt_outlined,
                      size: isSmallScreen ? 18 : 22,
                    ),
                  ),
                  maxLines: 2,
                  maxLength: 200,
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                  onChanged: (value) {
                    _updateContenant(note: value);
                  },
                ),
              ],
            ),

            // Affichage du montant total calculé
            if (_contenant.quantite > 0 && _contenant.prixUnitaire > 0) ...[
              SizedBox(height: isSmallScreen ? 12 : 16),
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calculate,
                      color: Colors.green[600],
                      size: isSmallScreen ? 16 : 20,
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Text(
                      'Montant total: ',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[800],
                      ),
                    ),
                    Text(
                      '${_contenant.montantTotal.toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
