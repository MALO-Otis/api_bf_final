import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/scoop_models.dart';
import '../../../../widgets/money_icon_widget.dart';

class ModalContenant extends StatefulWidget {
  final ContenantScoopModel? contenant;

  const ModalContenant({
    super.key,
    this.contenant,
  });

  @override
  State<ModalContenant> createState() => _ModalContenantState();
}

class _ModalContenantState extends State<ModalContenant> {
  final _formKey = GlobalKey<FormState>();

  ContenantType _typeContenant = ContenantType.bidon;
  MielType _typeMiel = MielType.liquide;
  TypeCire? _typeCire;
  CouleurCire? _couleurCire;
  final _poidsController = TextEditingController();
  final _prixController = TextEditingController();
  final _notesController = TextEditingController();

  bool get _isEdit => widget.contenant != null;

  // Données de prix par contenant depuis Firestore
  final Map<ContenantType, int> _prixParContenant = {
    ContenantType.bidon: 2000,
    ContenantType.fut: 2000,
    ContenantType.sac: 2000,
    ContenantType.seau: 2500,
  };

  /// Met à jour le prix unitaire automatiquement selon le type de contenant
  void _updatePrixAutomatique() {
    final prixParKg = _prixParContenant[_typeContenant] ?? 2000;
    _prixController.text = prixParKg.toString();
  }

  // 🔧 Calcul du montant total en temps réel
  double get _montantTotal {
    final poids = double.tryParse(_poidsController.text) ?? 0.0;
    final prix = double.tryParse(_prixController.text) ?? 0.0;
    return poids * prix;
  }

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final contenant = widget.contenant!;
      _typeContenant = contenant.typeContenant;
      _typeMiel = contenant.typeMiel;
      _typeCire = contenant.typeCire;
      _couleurCire = contenant.couleurCire;
      _poidsController.text = contenant.poids.toString();
      _prixController.text = contenant.prix.toString();
      _notesController.text = contenant.notes ?? '';
    } else {
      // Initialisation par défaut : Liquide avec Bidon
      _typeMiel = MielType.liquide;
      _typeContenant = ContenantType.bidon;
    }

    // 🔧 Listeners pour mise à jour en temps réel des totaux et prix automatique
    _poidsController.addListener(_updateTotals);
    _prixController.addListener(_updateTotals);

    // Initialiser le prix automatiquement si ce n'est pas en mode édition
    if (!_isEdit) {
      _updatePrixAutomatique();
    }
  }

  void _updateTotals() {
    setState(() {
      // Force rebuild pour mettre à jour l'aperçu des totaux
    });
  }

  /// Retourne les types de contenants disponibles selon le type de miel sélectionné
  List<ContenantType> _getAvailableContenantTypes() {
    // 🆕 Utiliser la méthode statique de l'enum pour obtenir les types disponibles
    return ContenantType.getTypesForMiel(_typeMiel);
  }

  @override
  void dispose() {
    // 🔧 Supprimer les listeners avant dispose
    _poidsController.removeListener(_updateTotals);
    _prixController.removeListener(_updateTotals);
    _poidsController.removeListener(_updatePrixAutomatique);

    _poidsController.dispose();
    _prixController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isEdit ? Icons.edit : Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _isEdit
                              ? 'Modifier un contenant'
                              : 'Ajouter un contenant',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Type de miel (en premier maintenant)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Type de miel *',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<MielType>(
                        value: _typeMiel,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.water_drop),
                        ),
                        items: MielType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _typeMiel = value!;
                            // Réinitialiser les champs de cire quand on change le type de miel
                            if (_typeMiel != MielType.cire) {
                              _typeCire = null;
                              _couleurCire = null;
                            }
                            // Sélectionner automatiquement le type de contenant selon le miel
                            final availableTypes =
                                ContenantType.getTypesForMiel(_typeMiel);
                            _typeContenant = availableTypes
                                .first; // Prendre le premier disponible
                            // Recalculer le prix avec le nouveau type de contenant
                            _updatePrixAutomatique();
                          });
                        },
                      ),
                    ],
                  ),

                  // Section spécifique à la cire (si type de miel = cire)
                  if (_typeMiel == MielType.cire) ...[
                    const SizedBox(height: 16),

                    // Type de cire
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Type de cire *',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<TypeCire>(
                          value: _typeCire,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.hive),
                          ),
                          items: TypeCire.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type.label),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _typeCire = value!;
                              // Réinitialiser la couleur si on n'est plus en purifiée
                              if (_typeCire != TypeCire.purifiee) {
                                _couleurCire = null;
                              }
                            });
                          },
                          validator: (value) {
                            if (_typeMiel == MielType.cire && value == null) {
                              return 'Type de cire requis';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    // Couleur de cire (si type cire = purifiée)
                    if (_typeCire == TypeCire.purifiee) ...[
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Couleur de la cire *',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<CouleurCire>(
                            value: _couleurCire,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              prefixIcon: const Icon(Icons.palette),
                            ),
                            items: CouleurCire.values.map((couleur) {
                              return DropdownMenuItem(
                                value: couleur,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: couleur == CouleurCire.jaune
                                            ? Colors.yellow.shade600
                                            : Colors.brown.shade600,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.grey.shade400),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(couleur.label),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _couleurCire = value!);
                            },
                            validator: (value) {
                              if (_typeCire == TypeCire.purifiee &&
                                  value == null) {
                                return 'Couleur de cire requise';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ],
                  ],

                  const SizedBox(height: 16),

                  // Type de contenant
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Type de contenant *',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<ContenantType>(
                        value: _typeContenant,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.inventory),
                          helperText: _typeMiel == MielType.cire
                              ? 'Les cires sont uniquement contenues dans des sacs'
                              : 'Seau, Bidon, Fût disponibles pour les autres types de miel',
                        ),
                        items: _getAvailableContenantTypes().map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _typeContenant = value!;
                            // Recalculer le prix quand on change le type de contenant
                            _updatePrixAutomatique();
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Poids et prix
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Poids (kg) *',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _poidsController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                prefixIcon: const Icon(Icons.scale),
                                hintText: '0.00',
                                suffixText: 'kg',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*')),
                              ],
                              validator: (value) {
                                if (value?.isEmpty == true)
                                  return 'Poids requis';
                                final poids = double.tryParse(value!);
                                if (poids == null || poids <= 0)
                                  return 'Poids invalide (> 0)';
                                if (poids > 1000)
                                  return 'Poids trop élevé (< 1000 kg)';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Prix (CFA) *',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _prixController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                prefixIcon: const SimpleMoneyIcon(),
                                hintText: '0',
                                suffixText: 'CFA',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (value) {
                                if (value?.isEmpty == true)
                                  return 'Prix requis';
                                final prix = double.tryParse(value!);
                                if (prix == null || prix <= 0)
                                  return 'Prix invalide (> 0)';
                                if (prix > 10000000) return 'Prix trop élevé';
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            // Affichage du prix unitaire selon le type de contenant
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Text(
                                'Prix ${_typeContenant.label}: ${_prixParContenant[_typeContenant]} CFA/kg',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Notes
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notes *',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.note),
                          hintText:
                              'Remarques ou informations complémentaires...',
                        ),
                        maxLines: 2,
                        maxLength: 200,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Les notes sont obligatoires';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Preview des informations
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aperçu',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _typeMiel.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                            if (_typeMiel == MielType.cire && _typeCire != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _typeCire!.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            if (_typeCire == TypeCire.purifiee &&
                                _couleurCire != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _couleurCire == CouleurCire.jaune
                                      ? Colors.yellow.shade100
                                      : Colors.brown.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _couleurCire == CouleurCire.jaune
                                            ? Colors.yellow.shade600
                                            : Colors.brown.shade600,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.grey.shade400),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _couleurCire!.label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _couleurCire == CouleurCire.jaune
                                            ? Colors.yellow.shade800
                                            : Colors.brown.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _typeContenant.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Poids: ${_poidsController.text.isEmpty ? '0' : _poidsController.text} kg • Prix unitaire: ${_prixController.text.isEmpty ? '0' : _prixController.text} CFA/kg',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Montant total: ${_montantTotal.toStringAsFixed(0)} CFA',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Boutons d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _saveContenant,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: Text(_isEdit ? 'Mettre à jour' : 'Ajouter'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  void _saveContenant() {
    if (!_formKey.currentState!.validate()) return;

    final contenant = ContenantScoopModel(
      id: widget.contenant?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      typeContenant: _typeContenant,
      typeMiel: _typeMiel,
      poids: double.parse(_poidsController.text),
      prix: double.parse(_prixController.text),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      typeCire: _typeMiel == MielType.cire ? _typeCire : null,
      couleurCire: _typeCire == TypeCire.purifiee ? _couleurCire : null,
    );

    Navigator.pop(context, contenant);
  }
}
