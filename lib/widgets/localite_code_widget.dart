import 'package:flutter/material.dart';
import '../data/services/localite_codification_service.dart';

/// Widget exemple pour l'affichage automatique du code localité
class LocaliteCodeWidget extends StatelessWidget {
  final String? region;
  final String? province;
  final String? commune;
  final bool showFullCode;
  final TextStyle? style;

  const LocaliteCodeWidget({
    Key? key,
    this.region,
    this.province,
    this.commune,
    this.showFullCode = true,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (region == null || province == null || commune == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Code: Non calculé',
          style: style ??
              TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
        ),
      );
    }

    final codeLocalite = LocaliteCodificationService.generateCodeLocalite(
      regionNom: region!,
      provinceNom: province!,
      communeNom: commune!,
    );

    if (codeLocalite == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Code: Erreur de génération',
          style: style ??
              TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                'Code: $codeLocalite',
                style: style ??
                    TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
              ),
            ],
          ),
          if (showFullCode) ...[
            const SizedBox(height: 4),
            Text(
              LocaliteCodificationService.formatCodeForDisplay(codeLocalite),
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Mixin pour ajouter la génération automatique de code localité dans les formulaires
mixin LocaliteCodeMixin {
  /// Génère automatiquement un code localité à partir des champs du formulaire
  String? generateCodeLocaliteFromForm({
    required String? region,
    required String? province,
    required String? commune,
  }) {
    if (region == null || province == null || commune == null) {
      return null;
    }

    return LocaliteCodificationService.generateCodeLocalite(
      regionNom: region,
      provinceNom: province,
      communeNom: commune,
    );
  }

  /// Valide qu'un code localité correspond aux sélections géographiques
  bool validateCodeLocaliteWithForm({
    required String codeLocalite,
    required String? region,
    required String? province,
    required String? commune,
  }) {
    if (region == null || province == null || commune == null) {
      return false;
    }

    final expectedCode = LocaliteCodificationService.generateCodeLocalite(
      regionNom: region,
      provinceNom: province,
      communeNom: commune,
    );

    return expectedCode == codeLocalite;
  }

  /// Mise à jour automatique du code lors du changement de localisation
  void onLocationChanged({
    required Function(String?) onCodeUpdate,
    String? region,
    String? province,
    String? commune,
  }) {
    final newCode = generateCodeLocaliteFromForm(
      region: region,
      province: province,
      commune: commune,
    );
    onCodeUpdate(newCode);
  }
}

/// Exemple d'utilisation dans un formulaire de récolte
class ExempleFormulaireRecolte extends StatefulWidget {
  @override
  _ExempleFormulaireRecolteState createState() =>
      _ExempleFormulaireRecolteState();
}

class _ExempleFormulaireRecolteState extends State<ExempleFormulaireRecolte>
    with LocaliteCodeMixin {
  String? _selectedRegion;
  String? _selectedProvince;
  String? _selectedCommune;
  String? _codeLocalite;

  final List<String> _regions = [
    'Kadiogo (CENTRE)',
    'Guiriko (HAUTS-BASSINS)',
    'Nando (CENTRE-OUEST)',
    'Bankui (BOUCLE DU MOUHOUN)',
  ];

  Map<String, List<String>> _provinces = {
    'Kadiogo (CENTRE)': ['Kadiogo'],
    'Guiriko (HAUTS-BASSINS)': ['Houet', 'Tuy'],
    'Nando (CENTRE-OUEST)': ['Boulkiemdé', 'Sanguié'],
    'Bankui (BOUCLE DU MOUHOUN)': ['Balé', 'Banwa', 'Mouhoun'],
  };

  Map<String, List<String>> _communes = {
    'Kadiogo': ['Ouagadougou', 'Saaba'],
    'Houet': ['Bobo-Dioulasso', 'Satiri'],
    'Boulkiemdé': ['Koudougou', 'Nanoro'],
    'Balé': ['Bagassi', 'Boromo'],
  };

  void _onRegionChanged(String? region) {
    setState(() {
      _selectedRegion = region;
      _selectedProvince = null;
      _selectedCommune = null;
    });
    _updateCodeLocalite();
  }

  void _onProvinceChanged(String? province) {
    setState(() {
      _selectedProvince = province;
      _selectedCommune = null;
    });
    _updateCodeLocalite();
  }

  void _onCommuneChanged(String? commune) {
    setState(() {
      _selectedCommune = commune;
    });
    _updateCodeLocalite();
  }

  void _updateCodeLocalite() {
    onLocationChanged(
      onCodeUpdate: (code) {
        setState(() {
          _codeLocalite = code;
        });
      },
      region: _selectedRegion,
      province: _selectedProvince,
      commune: _selectedCommune,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exemple - Formulaire Récolte'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Localisation de la récolte',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Sélection Région
            DropdownButtonFormField<String>(
              value: _selectedRegion,
              decoration: const InputDecoration(
                labelText: 'Région',
                border: OutlineInputBorder(),
              ),
              items: _regions.map((region) {
                return DropdownMenuItem(
                  value: region,
                  child: Text(region),
                );
              }).toList(),
              onChanged: _onRegionChanged,
            ),
            const SizedBox(height: 16),

            // Sélection Province
            DropdownButtonFormField<String>(
              value: _selectedProvince,
              decoration: const InputDecoration(
                labelText: 'Province',
                border: OutlineInputBorder(),
              ),
              items: _selectedRegion != null
                  ? (_provinces[_selectedRegion!] ?? []).map((province) {
                      return DropdownMenuItem(
                        value: province,
                        child: Text(province),
                      );
                    }).toList()
                  : [],
              onChanged: _onProvinceChanged,
            ),
            const SizedBox(height: 16),

            // Sélection Commune
            DropdownButtonFormField<String>(
              value: _selectedCommune,
              decoration: const InputDecoration(
                labelText: 'Commune',
                border: OutlineInputBorder(),
              ),
              items: _selectedProvince != null
                  ? (_communes[_selectedProvince!] ?? []).map((commune) {
                      return DropdownMenuItem(
                        value: commune,
                        child: Text(commune),
                      );
                    }).toList()
                  : [],
              onChanged: _onCommuneChanged,
            ),
            const SizedBox(height: 24),

            // Affichage automatique du code localité
            const Text(
              'Code de localité (généré automatiquement)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            LocaliteCodeWidget(
              region: _selectedRegion,
              province: _selectedProvince,
              commune: _selectedCommune,
              showFullCode: true,
            ),

            const SizedBox(height: 24),
            if (_codeLocalite != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations de sauvegarde',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ce code sera automatiquement sauvegardé avec la récolte :',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'code_localite: "$_codeLocalite"',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.w500,
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
