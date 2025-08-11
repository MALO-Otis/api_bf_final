import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../../../data/models/scoop_models.dart';
import '../../../../data/services/stats_scoop_contenants_service.dart';
import '../../../../data/geographe/geographie.dart';

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

  // Sélections géographiques
  String? _selectedRegion;
  String? _selectedProvince;
  String? _selectedCommune;
  String? _selectedVillage;
  String? _selectedArrondissement;
  String? _selectedSecteur;
  String? _selectedQuartier;

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
                    'Nouveau SCOOP',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
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
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom du SCOOP',
                  prefixIcon: Icon(Icons.apartment),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty == true ? 'Nom requis' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _presidentController,
                decoration: const InputDecoration(
                  labelText: 'Nom du président',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty == true ? 'Président requis' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _telephoneController,
          decoration: const InputDecoration(
            labelText: 'Téléphone du président',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
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
        Row(
          children: [
            Expanded(
              child: DropdownSearch<String>(
                items: regionsBurkina,
                selectedItem: _selectedRegion,
                onChanged: (value) {
                  setState(() {
                    _selectedRegion = value;
                    _selectedProvince = null;
                    _selectedCommune = null;
                    _selectedVillage = null;
                    _selectedArrondissement = null;
                    _selectedSecteur = null;
                    _selectedQuartier = null;
                  });
                },
                dropdownDecoratorProps: const DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: 'Région',
                    border: OutlineInputBorder(),
                  ),
                ),
                popupProps: const PopupProps.menu(showSearchBox: true),
                validator: (value) => value == null ? 'Région requise' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownSearch<String>(
                items: _selectedRegion != null
                    ? _getProvincesForRegion(_selectedRegion!)
                    : [],
                selectedItem: _selectedProvince,
                onChanged: (value) {
                  setState(() {
                    _selectedProvince = value;
                    _selectedCommune = null;
                    _selectedVillage = null;
                    _selectedArrondissement = null;
                    _selectedSecteur = null;
                    _selectedQuartier = null;
                  });
                },
                dropdownDecoratorProps: const DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: 'Province',
                    border: OutlineInputBorder(),
                  ),
                ),
                popupProps: const PopupProps.menu(showSearchBox: true),
                validator: (value) => value == null ? 'Province requise' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownSearch<String>(
          items: _selectedProvince != null
              ? _getCommunesForProvince(_selectedProvince!)
              : [],
          selectedItem: _selectedCommune,
          onChanged: (value) {
            setState(() {
              _selectedCommune = value;
              _selectedVillage = null;
              _selectedArrondissement = null;
              _selectedSecteur = null;
              _selectedQuartier = null;
            });
          },
          dropdownDecoratorProps: const DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              labelText: 'Commune',
              border: OutlineInputBorder(),
            ),
          ),
          popupProps: const PopupProps.menu(showSearchBox: true),
          validator: (value) => value == null ? 'Commune requise' : null,
        ),
        const SizedBox(height: 16),
        // Gestion spéciale pour Ouaga/Bobo ou villages classiques
        if (_selectedCommune != null) _buildSpecificLocationFields(),
      ],
    );
  }

  Widget _buildSpecificLocationFields() {
    final isOuagaBobo = _selectedCommune == 'Ouagadougou' ||
        _selectedCommune == 'BOBO-DIOULASSO' ||
        _selectedCommune == 'Bobo-Dioulasso';

    if (isOuagaBobo) {
      return Column(
        children: [
          // Arrondissement, Secteur, Quartier pour Ouaga/Bobo
          DropdownSearch<String>(
            items: _getArrondissementsForCommune(_selectedCommune!),
            selectedItem: _selectedArrondissement,
            onChanged: (value) {
              setState(() {
                _selectedArrondissement = value;
                _selectedSecteur = null;
                _selectedQuartier = null;
              });
            },
            dropdownDecoratorProps: const DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                labelText: 'Arrondissement',
                border: OutlineInputBorder(),
              ),
            ),
            popupProps: const PopupProps.menu(showSearchBox: true),
          ),
          if (_selectedArrondissement != null) ...[
            const SizedBox(height: 16),
            DropdownSearch<String>(
              items: _getSecteursForArrondissement(
                  _selectedCommune!, _selectedArrondissement!),
              selectedItem: _selectedSecteur,
              onChanged: (value) {
                setState(() {
                  _selectedSecteur = value;
                  _selectedQuartier = null;
                });
              },
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: 'Secteur',
                  border: OutlineInputBorder(),
                ),
              ),
              popupProps: const PopupProps.menu(showSearchBox: true),
            ),
          ],
          if (_selectedSecteur != null) ...[
            const SizedBox(height: 16),
            DropdownSearch<String>(
              items:
                  _getQuartiersForSecteur(_selectedCommune!, _selectedSecteur!),
              selectedItem: _selectedQuartier,
              onChanged: (value) => setState(() => _selectedQuartier = value),
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: 'Quartier',
                  border: OutlineInputBorder(),
                ),
              ),
              popupProps: const PopupProps.menu(showSearchBox: true),
            ),
          ],
        ],
      );
    } else {
      // Village pour autres communes
      return DropdownSearch<String>(
        items: _getVillagesForCommune(_selectedCommune!),
        selectedItem: _selectedVillage,
        onChanged: (value) => setState(() => _selectedVillage = value),
        dropdownDecoratorProps: const DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            labelText: 'Village',
            border: OutlineInputBorder(),
          ),
        ),
        popupProps: PopupProps.menu(
          showSearchBox: true,
          emptyBuilder: (context, searchEntry) {
            return ListTile(
              title: Text('Ajouter "$searchEntry" comme village'),
              onTap: () {
                setState(() => _selectedVillage = searchEntry);
                Navigator.of(context).pop();
              },
            );
          },
        ),
      );
    }
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
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _nbRuchesTradController,
                decoration: const InputDecoration(
                  labelText: 'Ruches traditionnelles',
                  prefixIcon: Icon(Icons.grass),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) =>
                    value?.isEmpty == true ? 'Obligatoire' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _nbRuchesModController,
                decoration: const InputDecoration(
                  labelText: 'Ruches modernes',
                  prefixIcon: Icon(Icons.build),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) =>
                    value?.isEmpty == true ? 'Obligatoire' : null,
              ),
            ),
          ],
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
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _nbMembresController,
                decoration: const InputDecoration(
                  labelText: 'Nombre total de membres',
                  prefixIcon: Icon(Icons.group),
                  border: OutlineInputBorder(),
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
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _nbHommesController,
                decoration: const InputDecoration(
                  labelText: 'Hommes',
                  prefixIcon: Icon(Icons.man),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: _updateMembresCalculation,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _nbJeunesController,
                decoration: const InputDecoration(
                  labelText: 'Jeunes (≤ 35 ans)',
                  prefixIcon: Icon(Icons.child_care),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: _updateMembresCalculation,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _nbFemmesController,
                decoration: const InputDecoration(
                  labelText: 'Femmes (calculé)',
                  prefixIcon: Icon(Icons.woman),
                  border: OutlineInputBorder(),
                ),
                enabled: false,
              ),
            ),
          ],
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
    _nbFemmesController.text = nbFemmes > 0 ? nbFemmes.toString() : '0';
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
      final scoop = ScoopModel(
        id: '', // Sera généré par Firestore
        nom: _nomController.text.trim(),
        president: _presidentController.text.trim(),
        telephone: _telephoneController.text.trim(),
        region: _selectedRegion!,
        province: _selectedProvince!,
        commune: _selectedCommune!,
        village: _selectedVillage,
        arrondissement: _selectedArrondissement,
        secteur: _selectedSecteur,
        quartier: _selectedQuartier,
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

  // Méthodes de géographie (similaires à celles du système existant)
  List<String> _getProvincesForRegion(String region) {
    return provincesParRegion[region] ?? [];
  }

  List<String> _getCommunesForProvince(String province) {
    return communesParProvince[province] ?? [];
  }

  List<String> _getVillagesForCommune(String commune) {
    return villagesParCommune[commune] ?? [];
  }

  List<String> _getArrondissementsForCommune(String commune) {
    // Système arrondissement/quartier abandonné
    return [];
  }

  List<String> _getSecteursForArrondissement(
      String commune, String arrondissement) {
    // Système arrondissement/quartier abandonné
    return [];
  }

  List<String> _getQuartiersForSecteur(String commune, String secteur) {
    // Système arrondissement/quartier abandonné
    return [];
  }
}
