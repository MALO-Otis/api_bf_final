import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/scoop_models.dart';
import '../../core/collecte_geographie_service.dart';
import '../../../../widgets/geographic_selection_widget.dart';
import '../../../../data/services/stats_scoop_contenants_service.dart';

class ModalNouveauScoop extends StatefulWidget {
  final String site;

  const ModalNouveauScoop({
    super.key,
    required this.site,
  });

  @override
  State<ModalNouveauScoop> createState() => _ModalNouveauScoopState();
}

class _ModalNouveauScoopState extends State<ModalNouveauScoop> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Contrôleurs de texte
  final _nomController = TextEditingController();
  final _presidentController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _nbRuchesTradController = TextEditingController(text: '0');
  final _nbRuchesModController = TextEditingController(text: '0');
  final _nbMembresController = TextEditingController(text: '1');
  final _nbHommesController = TextEditingController(text: '0');
  final _nbFemmesController = TextEditingController(text: '0');
  final _nbJeunesController = TextEditingController(text: '0');
  final _nbPlus35Controller = TextEditingController(text: '0');
  final _villagePersonnaliseController = TextEditingController();

  // Sélections géographiques
  String? _selectedRegion;
  String? _selectedProvince;
  String? _selectedCommune;
  String? _selectedVillage;
  bool _villagePersonnaliseActive = false;

  // Prédominances florales sélectionnées
  List<String> _selectedPredominances = [];

  @override
  void dispose() {
    _nomController.dispose();
    _presidentController.dispose();
    _telephoneController.dispose();
    _nbRuchesTradController.dispose();
    _nbRuchesModController.dispose();
    _nbMembresController.dispose();
    _nbHommesController.dispose();
    _nbFemmesController.dispose();
    _nbJeunesController.dispose();
    _nbPlus35Controller.dispose();
    _villagePersonnaliseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_business, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Nouvelle SCOOP',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                // Bouton de rafraîchissement géographique
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.blue),
                  onPressed: () async {
                    try {
                      // Rafraîchir les données géographiques
                      final geographieService =
                          Get.find<CollecteGeographieService>();
                      await geographieService.refreshData();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Données géographiques rafraîchies'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Erreur lors du rafraîchissement: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  tooltip: 'Rafraîchir les données géographiques',
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Formulaire
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoGeneralesSection(),
                      const SizedBox(height: 24),
                      _buildLocalisationSection(),
                      const SizedBox(height: 24),
                      _buildRuchesSection(),
                      const SizedBox(height: 24),
                      _buildMembresSection(),
                      const SizedBox(height: 24),
                      _buildPredominanceSection(),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

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
                  onPressed: _isLoading ? null : _saveScoop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enregistrer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGeneralesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations générales',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 420;
            final left = TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: 'Nom de la SCOOP',
                prefixIcon: Icon(Icons.apartment),
                border: OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                hintText: 'Saisir le nom de la SCOOP',
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Nom requis' : null,
            );
            final right = TextFormField(
              controller: _presidentController,
              decoration: const InputDecoration(
                labelText: 'Nom du président',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                hintText: 'Saisir le nom du président',
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Président requis' : null,
            );
            if (isCompact) {
              return Column(
                  children: [left, const SizedBox(height: 12), right]);
            }
            return Row(children: [
              Expanded(child: left),
              const SizedBox(width: 16),
              Expanded(child: right)
            ]);
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _telephoneController,
          decoration: const InputDecoration(
            labelText: 'Téléphone du président',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            hintText: '8 chiffres',
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value?.isEmpty == true) return 'Téléphone requis';
            if (value!.length != 8) return 'Le téléphone doit avoir 8 chiffres';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLocalisationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Localisation',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        GeographicSelectionWidget(
          selectedRegion: _selectedRegion,
          selectedProvince: _selectedProvince,
          selectedCommune: _selectedCommune,
          selectedVillage: _selectedVillage,
          villagePersonnaliseActive: _villagePersonnaliseActive,
          villagePersonnalise: _villagePersonnaliseController.text,
          onRegionChanged: (value) {
            setState(() {
              _selectedRegion = value;
              _selectedProvince = null;
              _selectedCommune = null;
              _selectedVillage = null;
            });
          },
          onProvinceChanged: (value) {
            setState(() {
              _selectedProvince = value;
              _selectedCommune = null;
              _selectedVillage = null;
            });
          },
          onCommuneChanged: (value) {
            setState(() {
              _selectedCommune = value;
              _selectedVillage = null;
            });
          },
          onVillageChanged: (value) {
            setState(() {
              _selectedVillage = value;
            });
          },
          onVillagePersonnaliseToggle: (value) {
            setState(() {
              _villagePersonnaliseActive = value;
              if (!value) {
                _villagePersonnaliseController.clear();
              } else {
                _selectedVillage = null;
              }
            });
          },
          onVillagePersonnaliseChanged: (value) {
            _villagePersonnaliseController.text = value;
          },
          showRefreshButton:
              false, // Le bouton de rafraîchissement est dans l'en-tête
        ),
      ],
    );
  }

  Widget _buildRuchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ruches',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 420;
            final first = TextFormField(
              controller: _nbRuchesTradController,
              decoration: const InputDecoration(
                labelText: 'Ruches traditionnelles',
                prefixIcon: Icon(Icons.grass),
                border: OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                hintText: 'Nombre',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) =>
                  value?.isEmpty == true ? 'Obligatoire' : null,
            );
            final second = TextFormField(
              controller: _nbRuchesModController,
              decoration: const InputDecoration(
                labelText: 'Ruches modernes',
                prefixIcon: Icon(Icons.build),
                border: OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                hintText: 'Nombre',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) =>
                  value?.isEmpty == true ? 'Obligatoire' : null,
            );
            if (isCompact) {
              return Column(
                children: [
                  first,
                  const SizedBox(height: 12),
                  second,
                ],
              );
            }
            return Row(children: [
              Expanded(child: first),
              const SizedBox(width: 16),
              Expanded(child: second)
            ]);
          },
        ),
      ],
    );
  }

  Widget _buildMembresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Membres',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 420;
            final left = TextFormField(
              controller: _nbMembresController,
              decoration: const InputDecoration(
                labelText: 'Nombre total de membres',
                prefixIcon: Icon(Icons.group),
                border: OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                hintText: 'Nombre',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value?.isEmpty == true) return 'Obligatoire';
                final nb = int.tryParse(value!) ?? 0;
                if (nb <= 0) return 'Doit être > 0';
                return null;
              },
              onChanged: _updateMembresCalculation,
            );
            final right = TextFormField(
              controller: _nbHommesController,
              decoration: const InputDecoration(
                labelText: 'Hommes',
                prefixIcon: Icon(Icons.man),
                border: OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                hintText: 'Nombre',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: _updateMembresCalculation,
            );
            if (isCompact) {
              return Column(
                  children: [left, const SizedBox(height: 12), right]);
            }
            return Row(children: [
              Expanded(child: left),
              const SizedBox(width: 16),
              Expanded(child: right)
            ]);
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 420;
            final left = TextFormField(
              controller: _nbJeunesController,
              decoration: const InputDecoration(
                labelText: 'Âge ≤ 35 ans',
                prefixIcon: Icon(Icons.child_care),
                border: OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                hintText: 'Nombre',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: _updateMembresCalculation,
            );
            final right = TextFormField(
              controller: _nbFemmesController,
              decoration: const InputDecoration(
                labelText: 'Femmes (calculé)',
                prefixIcon: Icon(Icons.woman),
                border: OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                hintText: 'Auto-calculé',
              ),
              enabled: false,
            );
            if (isCompact) {
              return Column(
                  children: [left, const SizedBox(height: 12), right]);
            }
            return Row(children: [
              Expanded(child: left),
              const SizedBox(width: 16),
              Expanded(child: right)
            ]);
          },
        ),
        const SizedBox(height: 16),
        // Âge > 35 ans (auto)
        TextFormField(
          controller: _nbPlus35Controller,
          decoration: const InputDecoration(
            labelText: 'Âge > 35 ans (calculé)',
            prefixIcon: Icon(Icons.elderly),
            border: OutlineInputBorder(),
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          enabled: false,
        ),
      ],
    );
  }

  Widget _buildPredominanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prédominance florale',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PredominancesFlorale.types.map((type) {
            final isSelected = _selectedPredominances.contains(type);
            return FilterChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedPredominances.add(type);
                  } else {
                    _selectedPredominances.remove(type);
                  }
                });
              },
              selectedColor: Colors.amber.shade200,
            );
          }).toList(),
        ),
        if (_selectedPredominances.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Sélectionnez au moins une prédominance florale',
              style: TextStyle(color: Colors.red.shade600, fontSize: 12),
            ),
          ),
      ],
    );
  }

  void _updateMembresCalculation(String value) {
    final nbTotal = int.tryParse(_nbMembresController.text) ?? 0;
    final nbHommes = int.tryParse(_nbHommesController.text) ?? 0;
    final nbFemmes = nbTotal - nbHommes;
    final nbJeunes = int.tryParse(_nbJeunesController.text) ?? 0;
    final nbPlus35 = nbTotal - nbJeunes;
    _nbFemmesController.text = nbFemmes > 0 ? nbFemmes.toString() : '0';
    _nbPlus35Controller.text = nbPlus35 > 0 ? nbPlus35.toString() : '0';
  }

  Future<void> _saveScoop() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPredominances.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Sélectionnez au moins une prédominance florale')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Déterminer le village final (liste ou personnalisé)
      final villageFinal = _villagePersonnaliseActive
          ? _villagePersonnaliseController.text.trim()
          : _selectedVillage;

      final scoop = ScoopModel(
        id: '', // Sera généré par Firestore
        nom: _nomController.text.trim(),
        president: _presidentController.text.trim(),
        telephone: _telephoneController.text.trim(),
        region: _selectedRegion!,
        province: _selectedProvince!,
        commune: _selectedCommune!,
        village: villageFinal,
        arrondissement: null, // Plus utilisé
        secteur: null, // Plus utilisé
        quartier: null, // Plus utilisé
        nbRuchesTrad: int.parse(_nbRuchesTradController.text),
        nbRuchesModernes: int.parse(_nbRuchesModController.text),
        nbMembres: int.parse(_nbMembresController.text),
        nbHommes: int.parse(_nbHommesController.text),
        nbFemmes: int.parse(_nbFemmesController.text),
        nbJeunes: int.parse(_nbJeunesController.text),
        predominanceFlorale: _selectedPredominances,
        createdAt: DateTime.now(),
      );

      final scoopId =
          await StatsScoopContenantsService.createScoop(scoop, widget.site);
      final scoopWithId = ScoopModel(
        id: scoopId,
        nom: scoop.nom,
        president: scoop.president,
        telephone: scoop.telephone,
        region: scoop.region,
        province: scoop.province,
        commune: scoop.commune,
        village: scoop.village,
        arrondissement: scoop.arrondissement,
        secteur: scoop.secteur,
        quartier: scoop.quartier,
        nbRuchesTrad: scoop.nbRuchesTrad,
        nbRuchesModernes: scoop.nbRuchesModernes,
        nbMembres: scoop.nbMembres,
        nbHommes: scoop.nbHommes,
        nbFemmes: scoop.nbFemmes,
        nbJeunes: scoop.nbJeunes,
        predominanceFlorale: scoop.predominanceFlorale,
        createdAt: scoop.createdAt,
      );

      Navigator.pop(context, scoopWithId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
