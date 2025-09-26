import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../widgets/location_picker.dart';
import '../vente/services/vente_service.dart';

/// Formulaire simplifié pour créer rapidement un client avec localisation
class NewClientQuickFormPage extends StatefulWidget {
  final String site;
  final String currentUserId;
  const NewClientQuickFormPage(
      {super.key, required this.site, required this.currentUserId});

  @override
  State<NewClientQuickFormPage> createState() => _NewClientQuickFormPageState();
}

class _NewClientQuickFormPageState extends State<NewClientQuickFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _boutiqueCtrl = TextEditingController();

  double? latitude;
  double? longitude;
  double? altitude;
  double? precision;

  bool saving = false;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _telephoneCtrl.dispose();
    _boutiqueCtrl.dispose();
    super.dispose();
  }

  Future<void> _openMap() async {
    final result = await Navigator.of(context).push<LocationResult>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: latitude,
          initialLng: longitude,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        latitude = result.latitude;
        longitude = result.longitude;
        altitude = result.altitude;
        precision = result.accuracy;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (latitude == null || longitude == null) {
      Get.snackbar('Localisation', 'Sélectionne la localisation du client.');
      return;
    }
    setState(() => saving = true);
    await VenteService().creerClientRapide(
      nom: _nomCtrl.text.trim(),
      telephone: _telephoneCtrl.text.trim(),
      nomBoutique: _boutiqueCtrl.text.trim(),
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      precision: precision,
    );
    setState(() => saving = false);
    Get.snackbar('Succès', 'Client enregistré');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau client (Rapide)')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nomCtrl,
              decoration: const InputDecoration(labelText: 'Nom du client'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telephoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Téléphone'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _boutiqueCtrl,
              decoration:
                  const InputDecoration(labelText: 'Nom de la boutique'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.redAccent),
              title: latitude != null
                  ? Text(
                      'Lat: ${latitude!.toStringAsFixed(6)}\nLng: ${longitude!.toStringAsFixed(6)}')
                  : const Text('Sélectionner la localisation'),
              subtitle: precision != null
                  ? Text('Précision ~${precision!.toStringAsFixed(1)} m')
                  : null,
              trailing: ElevatedButton.icon(
                  onPressed: _openMap,
                  icon: const Icon(Icons.map),
                  label: const Text('Adresse')),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: saving ? null : _save,
              icon: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: const Text('Enregistrer'),
            )
          ],
        ),
      ),
    );
  }
}

class LocationResult {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  const LocationResult(
      {required this.latitude,
      required this.longitude,
      this.altitude,
      this.accuracy});
}
