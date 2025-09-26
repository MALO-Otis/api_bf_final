import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/collecte_models.dart';
import 'contenant_card.dart';
import '../../../../widgets/money_icon_widget.dart';

class SectionContenants extends StatefulWidget {
  final List<ContenantModel> contenants;
  final Function(ContenantModel) onAjouterContenant;
  final Function(int) onSupprimerContenant;
  final Function(int, ContenantModel) onModifierContenant;

  const SectionContenants({
    Key? key,
    required this.contenants,
    required this.onAjouterContenant,
    required this.onSupprimerContenant,
    required this.onModifierContenant,
  }) : super(key: key);

  @override
  State<SectionContenants> createState() => _SectionContenantsState();
}

class _SectionContenantsState extends State<SectionContenants> {
  // État du formulaire d'ajout (exactement comme le modal SCOOP)
  final _formKey = GlobalKey<FormState>();

  // Énumérations pour la cire (comme SCOOP)
  static const List<String> _typesMiel = ['Liquide', 'Brute', 'Cire'];
  static const List<String> _typesCire = ['Brute', 'Purifiée'];
  static const List<String> _couleursCire = ['Jaune', 'Marron'];

  // Variables d'état du formulaire
  String _typeMiel = 'Liquide';
  String? _typeCire;
  String? _couleurCire;
  String _typeContenant = 'Bidon';

  /// Retourne les types de contenants disponibles selon le type de miel sélectionné
  List<String> _getAvailableContenantTypes() {
    if (_typeMiel == 'Cire') {
      // 🆕 Pour la cire, seul le sac est autorisé
      return ['Sac'];
    } else {
      // Pour les autres types de miel (Liquide, Brute), tous les contenants sont disponibles
      return ['Bidon', 'Seau', 'Fût'];
    }
  }

  final _poidsController = TextEditingController();
  final _prixController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _poidsController.dispose();
    _prixController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 30),
          child: Opacity(
            opacity: value,
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.inventory,
                            color: Colors.orange[600],
                            size: isSmallScreen ? 18 : 22,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Text(
                          'Contenants (${widget.contenants.length})',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),

                    // NOUVEAU : Formulaire d'ajout intégré (comme modal SCOOP)
                    _buildFormulaireAjout(context, isSmallScreen),

                    SizedBox(height: isSmallScreen ? 16 : 20),
                    ...widget.contenants.asMap().entries.map((entry) {
                      final index = entry.key;
                      final contenant = entry.value;
                      return ContenantCard(
                        index: index,
                        contenant: contenant,
                        onSupprimer: widget.contenants.length > 1
                            ? () => widget.onSupprimerContenant(index)
                            : null,
                        onContenantModified: (nouveauContenant) =>
                            widget.onModifierContenant(index, nouveauContenant),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Construit le formulaire d'ajout intégré (exactement comme le modal SCOOP)
  Widget _buildFormulaireAjout(BuildContext context, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Ajouter un contenant',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Type de miel (en premier comme SCOOP)
            _buildTypeMielField(),

            // Section cire conditionnelle
            if (_typeMiel == 'Cire') ...[
              const SizedBox(height: 16),
              _buildTypeCireField(),
              if (_typeCire == 'Purifiée') ...[
                const SizedBox(height: 16),
                _buildCouleurCireField(),
              ],
            ],

            const SizedBox(height: 16),

            // Type de contenant
            _buildTypeContenantField(),

            const SizedBox(height: 16),

            // Poids et prix
            _buildPoidsEtPrixFields(),

            const SizedBox(height: 16),

            // Notes
            _buildNotesField(),

            const SizedBox(height: 16),

            // Preview
            _buildPreview(),

            const SizedBox(height: 16),

            // Bouton d'ajout
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveContenant,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Ajouter ce contenant',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveContenant() {
    if (!_formKey.currentState!.validate()) return;

    // Créer le contenant avec les données adaptées au modèle existant
    final contenantId =
        'C${(widget.contenants.length + 1).toString().padLeft(3, '0')}_individuel';

    final contenant = ContenantModel(
      id: contenantId, // 🆕 ID unique avec suffixe individuel
      typeRuche: 'Traditionnelle', // Valeur par défaut
      typeMiel: _typeMiel,
      typeContenant: _typeContenant,
      quantite: double.parse(_poidsController.text),
      prixUnitaire: double.parse(_prixController.text),
      predominanceFlorale: '', // Nous n'utilisons plus ce champ
      note: _notesController.text.trim().isEmpty
          ? ''
          : _notesController.text.trim(),
    );

    widget.onAjouterContenant(contenant);

    // Réinitialiser le formulaire
    setState(() {
      _typeMiel = 'Liquide';
      _typeCire = null;
      _couleurCire = null;
      _typeContenant = 'Bidon';
    });
    _poidsController.clear();
    _prixController.clear();
    _notesController.clear();
  }

  Widget _buildTypeMielField() {
    return Column(
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
              // 🆕 Si on passe à Cire, forcer le type de contenant à Sac
              if (_typeMiel == 'Cire') {
                _typeContenant = 'Sac';
              }
              // Si on passe à un autre type que Cire, remettre à Bidon par défaut
              else {
                _typeContenant = 'Bidon';
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildTypeCireField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type de cire *',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _typeCire,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.hive),
          ),
          items: _typesCire.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _typeCire = value!;
              // Réinitialiser la couleur si on n'est plus en purifiée
              if (_typeCire != 'Purifiée') {
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
    );
  }

  Widget _buildCouleurCireField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Couleur de la cire *',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _couleurCire,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.palette),
          ),
          items: _couleursCire.map((couleur) {
            return DropdownMenuItem(
              value: couleur,
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: couleur == 'Jaune'
                          ? Colors.yellow.shade600
                          : Colors.brown.shade600,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(couleur),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _couleurCire = value!);
          },
          validator: (value) {
            if (_typeCire == 'Purifiée' && value == null) {
              return 'Couleur de cire requise';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTypeContenantField() {
    final availableTypes = _getAvailableContenantTypes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type de contenant *',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: availableTypes.contains(_typeContenant)
              ? _typeContenant
              : availableTypes.first,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.inventory),
          ),
          items: availableTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _typeContenant = value!);
          },
        ),
        // 🆕 Message informatif pour la cire
        if (_typeMiel == 'Cire') ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pour la cire, seul le sac est disponible',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPoidsEtPrixFields() {
    return Row(
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
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                onChanged: (value) {
                  setState(() {}); // Met à jour l'aperçu en temps réel
                },
                validator: (value) {
                  if (value?.isEmpty == true) return 'Poids requis';
                  final poids = double.tryParse(value!);
                  if (poids == null || poids <= 0)
                    return 'Poids invalide (> 0)';
                  if (poids > 1000) return 'Poids trop élevé (< 1000 kg)';
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
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  setState(() {}); // Met à jour l'aperçu en temps réel
                },
                validator: (value) {
                  if (value?.isEmpty == true) return 'Prix requis';
                  final prix = double.tryParse(value!);
                  if (prix == null || prix <= 0) return 'Prix invalide (> 0)';
                  if (prix > 10000000) return 'Prix trop élevé';
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes (optionnel)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.note),
            hintText: 'Remarques ou informations complémentaires...',
          ),
          maxLines: 2,
          maxLength: 200,
          onChanged: (value) {
            setState(() {}); // Met à jour l'aperçu en temps réel
          },
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Container(
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
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _typeMiel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              if (_typeMiel == 'Cire' && _typeCire != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _typeCire!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              if (_typeCire == 'Purifiée' && _couleurCire != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _couleurCire == 'Jaune'
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
                          color: _couleurCire == 'Jaune'
                              ? Colors.yellow.shade600
                              : Colors.brown.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _couleurCire!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _couleurCire == 'Jaune'
                              ? Colors.yellow.shade800
                              : Colors.brown.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _typeContenant,
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
          Text(
            'Poids: ${_poidsController.text.isEmpty ? '0' : _poidsController.text} kg • Prix: ${_prixController.text.isEmpty ? '0' : _prixController.text} CFA',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
