import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../widgets/money_icon_widget.dart';
import '../../../../data/models/collecte_models.dart';
import '../../../../data/personnel/personnel_apisavana.dart';

class ModalContenantIndividuel extends StatefulWidget {
  final ContenantModel? contenant;

  const ModalContenantIndividuel({
    super.key,
    this.contenant,
  });

  @override
  State<ModalContenantIndividuel> createState() =>
      _ModalContenantIndividuelState();
}

// Énumérations pour la gestion de la cire
enum TypeCire { brute, purifiee }

enum CouleurCire { jaune, marron }

class _ModalContenantIndividuelState extends State<ModalContenantIndividuel> {
  final _formKey = GlobalKey<FormState>();

  String _typeRuche = 'Traditionnelle';
  String _typeMiel = 'Liquide';
  String _typeContenant = 'Bidon';
  String _predominanceFlorale = '';
  TypeCire? _typeCire;
  CouleurCire? _couleurCire;
  final _quantiteController = TextEditingController();
  final _prixUnitaireController = TextEditingController();
  final _noteController = TextEditingController();

  bool get _isEdit => widget.contenant != null;

  // Données de prix par contenant depuis Firestore
  final Map<String, int> _prixParContenant = {
    'Bidon': 2000,
    'Fût': 2000,
    'Sac': 2000,
    'Seau': 2500,
  };

  /// Calcule et met à jour le prix unitaire automatiquement selon le type de contenant
  void _updatePrixAutomatique() {
    final prixParKg = _prixParContenant[_typeContenant] ?? 2000;
    // Afficher le prix unitaire (prix par kg) au lieu du prix total
    _prixUnitaireController.text = prixParKg.toString();
  }

  /// Retourne les types de contenants disponibles selon le type de miel
  List<String> _getAvailableContenantTypes() {
    switch (_typeMiel) {
      case 'Liquide':
        // Pour le miel liquide : Bidon, Fût, Seau
        return ['Bidon', 'Fût', 'Seau'];
      case 'Brute':
        // Pour le miel brute : Fût, Seau (pas de Bidon)
        return ['Fût', 'Seau'];
      case 'Cire':
        // Pour la cire, seul le sac est autorisé
        return ['Sac'];
      default:
        return ['Bidon'];
    }
  }

  String _getTypeCireLabel(TypeCire type) {
    switch (type) {
      case TypeCire.brute:
        return 'Brute';
      case TypeCire.purifiee:
        return 'Purifiée';
    }
  }

  String _getCouleurCireLabel(CouleurCire couleur) {
    switch (couleur) {
      case CouleurCire.jaune:
        return 'Jaune';
      case CouleurCire.marron:
        return 'Marron';
    }
  }

  final List<String> _typesRuche = ['Traditionnelle', 'Moderne'];
  final List<String> _typesMiel = ['Liquide', 'Brute', 'Cire'];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final contenant = widget.contenant!;
      _typeRuche = contenant.typeRuche.isNotEmpty
          ? contenant.typeRuche
          : 'Traditionnelle';
      _typeMiel =
          contenant.typeMiel.isNotEmpty ? contenant.typeMiel : 'Liquide';
      _typeContenant = contenant.typeContenant.isNotEmpty
          ? contenant.typeContenant
          : 'Bidon';
      _predominanceFlorale = contenant.predominanceFlorale;
      _quantiteController.text = contenant.quantite.toString();
      _prixUnitaireController.text = contenant.prixUnitaire.toString();
      _noteController.text = contenant.note;
    } else {
      // Initialisation par défaut : Liquide avec Bidon
      _typeMiel = 'Liquide';
      _typeContenant = 'Bidon';
    }

    // Listeners pour calcul automatique du prix
    _quantiteController.addListener(_updatePrixAutomatique);

    // Initialiser le prix automatiquement si ce n'est pas en mode édition
    if (!_isEdit) {
      _updatePrixAutomatique();
    }
  }

  @override
  void dispose() {
    _quantiteController.removeListener(_updatePrixAutomatique);
    _quantiteController.dispose();
    _prixUnitaireController.dispose();
    _noteController.dispose();
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
                        color: Colors.orange.shade600,
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
                    DropdownButtonFormField<String>(
                      value: _typeMiel,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.water_drop),
                      ),
                      items: _typesMiel.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _typeMiel = value!;
                          // Réinitialiser les champs de cire quand on change le type de miel
                          if (_typeMiel != 'Cire') {
                            _typeCire = null;
                            _couleurCire = null;
                          }
                          // Sélectionner automatiquement le type de contenant selon le miel
                          final availableTypes = _getAvailableContenantTypes();
                          _typeContenant = availableTypes.first;
                          // Recalculer le prix avec le nouveau type de contenant
                          _updatePrixAutomatique();
                        });
                      },
                    ),
                  ],
                ),

                // Section spécifique à la cire (si type de miel = cire)
                if (_typeMiel == 'Cire') ...[
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
                            child: Text(_getTypeCireLabel(type)),
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
                          if (_typeMiel == 'Cire' && value == null) {
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
                                  Text(_getCouleurCireLabel(couleur)),
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
                    DropdownButtonFormField<String>(
                      value:
                          _getAvailableContenantTypes().contains(_typeContenant)
                              ? _typeContenant
                              : _getAvailableContenantTypes().first,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.inventory),
                      ),
                      items: _getAvailableContenantTypes().map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
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

                    // Indicateur de prix pour le conteneur sélectionné
                    if (_typeContenant.isNotEmpty &&
                        _prixParContenant.containsKey(_typeContenant))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            'Prix $_typeContenant: ${_prixParContenant[_typeContenant]} CFA/kg',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Type de ruche
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Type de ruche *',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _typeRuche,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.hive),
                      ),
                      items: _typesRuche.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _typeRuche = value!);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Prédominance florale
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prédominance florale *',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _predominanceFlorale.isEmpty
                          ? null
                          : _predominanceFlorale,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.local_florist),
                        hintText: 'Sélectionner une prédominance',
                      ),
                      items: predominancesFlorales.map((florale) {
                        return DropdownMenuItem(
                          value: florale,
                          child: Text(florale),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _predominanceFlorale = value ?? '');
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Prédominance florale requise';
                        }
                        return null;
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Quantité et prix (adapté selon le type de miel)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _typeMiel == 'Cire'
                                ? 'Nombre de sacs *'
                                : 'Quantité (kg) *',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _quantiteController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              prefixIcon: Icon(_typeMiel == 'Cire'
                                  ? Icons.inventory_2
                                  : Icons.scale),
                              hintText: _typeMiel == 'Cire' ? '0' : '0.00',
                              suffixText: _typeMiel == 'Cire' ? 'sacs' : 'kg',
                            ),
                            keyboardType: _typeMiel == 'Cire'
                                ? TextInputType.number
                                : const TextInputType.numberWithOptions(
                                    decimal: true),
                            inputFormatters: _typeMiel == 'Cire'
                                ? [FilteringTextInputFormatter.digitsOnly]
                                : [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*'))
                                  ],
                            validator: (value) {
                              if (value?.isEmpty == true)
                                return _typeMiel == 'Cire'
                                    ? 'Nombre de sacs requis'
                                    : 'Quantité requise';
                              final quantite = double.tryParse(value!);
                              if (quantite == null || quantite <= 0)
                                return _typeMiel == 'Cire'
                                    ? 'Nombre de sacs invalide (> 0)'
                                    : 'Quantité invalide (> 0)';
                              if (_typeMiel == 'Cire' && quantite > 1000)
                                return 'Nombre de sacs trop élevé (< 1000)';
                              if (_typeMiel != 'Cire' && quantite > 1000)
                                return 'Quantité trop élevée (< 1000 kg)';
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
                          Text(
                            _typeMiel == 'Cire'
                                ? 'Prix unitaire (CFA/sac) *'
                                : 'Prix unitaire (CFA/kg) *',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _prixUnitaireController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              prefixIcon: const SimpleMoneyIcon(),
                              hintText: '0',
                              suffixText:
                                  _typeMiel == 'Cire' ? 'CFA/sac' : 'CFA/kg',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            validator: (value) {
                              if (value?.isEmpty == true) return 'Prix requis';
                              final prix = double.tryParse(value!);
                              if (prix == null || prix <= 0)
                                return 'Prix invalide (> 0)';
                              if (prix > 10000000) return 'Prix trop élevé';
                              return null;
                            },
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
                      controller: _noteController,
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
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
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
                          _buildPreviewChip(_typeMiel, Colors.green),
                          if (_typeMiel == 'Cire' && _typeCire != null)
                            _buildPreviewChip(
                                _getTypeCireLabel(_typeCire!), Colors.indigo),
                          if (_typeCire == TypeCire.purifiee &&
                              _couleurCire != null)
                            _buildColorPreviewChip(_couleurCire!),
                          _buildPreviewChip(_typeContenant, Colors.orange),
                          _buildPreviewChip(_typeRuche, Colors.blue),
                          if (_predominanceFlorale.isNotEmpty)
                            _buildPreviewChip(
                                _predominanceFlorale, Colors.purple),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _typeMiel == 'Cire'
                            ? 'Quantité: ${_quantiteController.text.isEmpty ? '0' : _quantiteController.text} sacs • Prix: ${_prixUnitaireController.text.isEmpty ? '0' : _prixUnitaireController.text} CFA/sac'
                            : 'Quantité: ${_quantiteController.text.isEmpty ? '0' : _quantiteController.text} kg • Prix: ${_prixUnitaireController.text.isEmpty ? '0' : _prixUnitaireController.text} CFA/kg',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (_quantiteController.text.isNotEmpty &&
                          _prixUnitaireController.text.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Montant total: ${_calculateMontantTotal()} CFA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
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
                        backgroundColor: Colors.orange.shade600,
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
      ),
    );
  }

  Widget _buildPreviewChip(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color.shade700,
        ),
      ),
    );
  }

  Widget _buildColorPreviewChip(CouleurCire couleur) {
    final color = couleur == CouleurCire.jaune ? Colors.yellow : Colors.brown;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color.shade600,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _getCouleurCireLabel(couleur),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.shade800,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateMontantTotal() {
    final quantite = double.tryParse(_quantiteController.text) ?? 0;
    final prixUnitaire = double.tryParse(_prixUnitaireController.text) ?? 0;
    final montant = quantite * prixUnitaire;
    return montant.toStringAsFixed(0);
  }

  void _saveContenant() {
    if (!_formKey.currentState!.validate()) return;

    final quantite = double.parse(_quantiteController.text);
    final prixUnitaire = double.parse(_prixUnitaireController.text);

    // Générer un ID temporaire - sera remplacé par l'ID correct lors de l'ajout à la liste
    final contenant = ContenantModel(
      id: '', // Sera assigné lors de l'ajout à la liste
      typeRuche: _typeRuche,
      typeMiel: _typeMiel,
      typeContenant: _typeContenant,
      quantite: quantite,
      prixUnitaire: prixUnitaire,
      predominanceFlorale: _predominanceFlorale,
      note: _noteController.text.trim().isEmpty
          ? ''
          : _noteController.text.trim(),
    );

    Navigator.pop(context, contenant);
  }
}
