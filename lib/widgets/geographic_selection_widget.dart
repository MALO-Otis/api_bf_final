import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../screens/collecte_de_donnes/core/collecte_geographie_service.dart';

/// Widget réutilisable pour la sélection géographique en cascade
/// Identique au système utilisé dans le module de récolte
class GeographicSelectionWidget extends StatefulWidget {
  final String? selectedRegion;
  final String? selectedProvince;
  final String? selectedCommune;
  final String? selectedVillage;
  final bool villagePersonnaliseActive;
  final String villagePersonnalise;
  final Function(String?) onRegionChanged;
  final Function(String?) onProvinceChanged;
  final Function(String?) onCommuneChanged;
  final Function(String?) onVillageChanged;
  final Function(bool) onVillagePersonnaliseToggle;
  final Function(String) onVillagePersonnaliseChanged;
  final VoidCallback? onRefresh;
  final bool showRefreshButton;
  final Color highlightColor;

  const GeographicSelectionWidget({
    Key? key,
    this.selectedRegion,
    this.selectedProvince,
    this.selectedCommune,
    this.selectedVillage,
    this.villagePersonnaliseActive = false,
    this.villagePersonnalise = '',
    required this.onRegionChanged,
    required this.onProvinceChanged,
    required this.onCommuneChanged,
    required this.onVillageChanged,
    required this.onVillagePersonnaliseToggle,
    required this.onVillagePersonnaliseChanged,
    this.onRefresh,
    this.showRefreshButton = true,
    this.highlightColor = Colors.blue,
  }) : super(key: key);

  @override
  State<GeographicSelectionWidget> createState() =>
      _GeographicSelectionWidgetState();
}

class _GeographicSelectionWidgetState extends State<GeographicSelectionWidget> {
  late CollecteGeographieService _geographieService;
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _communes = [];
  List<Map<String, dynamic>> _villages = [];
  bool _isLoading = false;
  final TextEditingController _villagePersonnaliseController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _geographieService = Get.find<CollecteGeographieService>();
    _villagePersonnaliseController.text = widget.villagePersonnalise;
    _updateProvinces();
    _updateCommunes();
    _updateVillages();
  }

  @override
  void didUpdateWidget(GeographicSelectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRegion != widget.selectedRegion) {
      _updateProvinces();
    }
    if (oldWidget.selectedProvince != widget.selectedProvince) {
      _updateCommunes();
    }
    if (oldWidget.selectedCommune != widget.selectedCommune) {
      _updateVillages();
    }
    if (oldWidget.villagePersonnalise != widget.villagePersonnalise) {
      _villagePersonnaliseController.text = widget.villagePersonnalise;
    }
  }

  void _updateProvinces() {
    if (widget.selectedRegion != null) {
      final regionCode =
          _geographieService.getRegionCodeByName(widget.selectedRegion!);
      _provinces = (regionCode?.isNotEmpty == true)
          ? _geographieService.getProvincesForRegion(regionCode!)
          : [];
    } else {
      _provinces = [];
    }
  }

  void _updateCommunes() {
    if (widget.selectedRegion != null && widget.selectedProvince != null) {
      final regionCode =
          _geographieService.getRegionCodeByName(widget.selectedRegion!);
      final provinceCode = (regionCode?.isNotEmpty == true)
          ? _geographieService.getProvinceCodeByName(
              regionCode!, widget.selectedProvince!)
          : null;
      _communes =
          (regionCode?.isNotEmpty == true && provinceCode?.isNotEmpty == true)
              ? _geographieService.getCommunesForProvince(
                  regionCode!, provinceCode!)
              : [];
    } else {
      _communes = [];
    }
  }

  void _updateVillages() {
    if (widget.selectedRegion != null &&
        widget.selectedProvince != null &&
        widget.selectedCommune != null) {
      final regionCode =
          _geographieService.getRegionCodeByName(widget.selectedRegion!);
      final provinceCode = (regionCode?.isNotEmpty == true)
          ? _geographieService.getProvinceCodeByName(
              regionCode!, widget.selectedProvince!)
          : null;
      final communeCode =
          (regionCode?.isNotEmpty == true && provinceCode?.isNotEmpty == true)
              ? _geographieService.getCommuneCodeByName(
                  regionCode!, provinceCode!, widget.selectedCommune!)
              : null;
      _villages = (regionCode?.isNotEmpty == true &&
              provinceCode?.isNotEmpty == true &&
              communeCode?.isNotEmpty == true)
          ? _geographieService.getVillagesForCommune(
              regionCode!, provinceCode!, communeCode!)
          : [];
    } else {
      _villages = [];
    }
  }

  Future<void> _refreshData() async {
    if (widget.onRefresh != null) {
      setState(() => _isLoading = true);
      try {
        widget.onRefresh?.call();
        _updateProvinces();
        _updateCommunes();
        _updateVillages();
        setState(() {});

        Get.snackbar(
          'Actualisation',
          'Données géographiques actualisées avec succès',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          icon: const Icon(Icons.check_circle, color: Colors.green),
          duration: const Duration(seconds: 2),
        );
      } catch (e) {
        Get.snackbar(
          'Erreur',
          'Erreur lors de l\'actualisation: $e',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          icon: const Icon(Icons.error, color: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: widget.highlightColor, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: widget.highlightColor.withOpacity(0.07),
      ),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec titre et bouton refresh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Localisation',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: widget.highlightColor),
              ),
              if (widget.showRefreshButton)
                IconButton(
                  icon: _isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: widget.highlightColor,
                          ),
                        )
                      : Icon(Icons.refresh,
                          color: widget.highlightColor, size: 20),
                  onPressed: _isLoading ? null : _refreshData,
                  tooltip: 'Actualiser les données géographiques',
                  padding: const EdgeInsets.all(4),
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Dropdown Région
          DropdownSearch<String>(
            items: _geographieService.regions.map((r) => r.nom).toList(),
            selectedItem: widget.selectedRegion,
            onChanged: (v) {
              widget.onRegionChanged(v);
              _updateProvinces();
              setState(() {});
            },
            dropdownDecoratorProps: const DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(labelText: 'Région'),
            ),
            popupProps: const PopupProps.menu(showSearchBox: true),
          ),

          const SizedBox(height: 8),

          // Dropdown Province
          DropdownSearch<String>(
            items: _provinces.map((p) => p['nom'].toString()).toList(),
            selectedItem: widget.selectedProvince,
            onChanged: (v) {
              widget.onProvinceChanged(v);
              _updateCommunes();
              setState(() {});
            },
            dropdownDecoratorProps: const DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(labelText: 'Province'),
            ),
            popupProps: const PopupProps.menu(showSearchBox: true),
            enabled: widget.selectedRegion != null,
          ),

          const SizedBox(height: 8),

          // Dropdown Commune
          DropdownSearch<String>(
            items: _communes.map((c) => c['nom'].toString()).toList(),
            selectedItem: widget.selectedCommune,
            onChanged: (v) {
              widget.onCommuneChanged(v);
              _updateVillages();
              setState(() {});
            },
            dropdownDecoratorProps: const DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(labelText: 'Commune'),
            ),
            popupProps: const PopupProps.menu(showSearchBox: true),
            enabled: widget.selectedProvince != null,
          ),

          // Section Village avec option personnalisée
          if (widget.selectedCommune != null) ...[
            const SizedBox(height: 12),

            // Options radio pour village
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Village de la liste',
                        style: TextStyle(fontSize: 14)),
                    value: false,
                    groupValue: widget.villagePersonnaliseActive,
                    onChanged: (value) =>
                        widget.onVillagePersonnaliseToggle(value!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Village non répertorié',
                        style: TextStyle(fontSize: 14)),
                    value: true,
                    groupValue: widget.villagePersonnaliseActive,
                    onChanged: (value) =>
                        widget.onVillagePersonnaliseToggle(value!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Dropdown ou champ texte selon le choix
            if (!widget.villagePersonnaliseActive) ...[
              DropdownSearch<String>(
                items: _villages.map((v) => v['nom'].toString()).toList(),
                selectedItem: widget.selectedVillage,
                onChanged: widget.onVillageChanged,
                dropdownDecoratorProps: const DropDownDecoratorProps(
                  dropdownSearchDecoration:
                      InputDecoration(labelText: 'Village'),
                ),
                popupProps: const PopupProps.menu(showSearchBox: true),
              ),
              if (_villages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${_villages.length} village(s) disponible(s)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ] else ...[
              TextFormField(
                controller: _villagePersonnaliseController,
                decoration: const InputDecoration(
                  labelText: 'Nom du village personnalisé',
                  hintText: 'Saisissez le nom du village',
                ),
                onChanged: widget.onVillagePersonnaliseChanged,
                validator: (value) {
                  if (widget.villagePersonnaliseActive &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Veuillez saisir le nom du village';
                  }
                  return null;
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _villagePersonnaliseController.dispose();
    super.dispose();
  }
}
