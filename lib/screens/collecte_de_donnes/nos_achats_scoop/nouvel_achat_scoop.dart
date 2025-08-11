import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../authentication/user_session.dart';
import '../../../data/services/stats_achats_scoop_service.dart';
import '../historiques_collectes.dart';

class NouvelAchatScoopPage extends StatefulWidget {
  const NouvelAchatScoopPage({super.key});

  @override
  State<NouvelAchatScoopPage> createState() => _NouvelAchatScoopPageState();
}

class _NouvelAchatScoopPageState extends State<NouvelAchatScoopPage> {
  final _formKey = GlobalKey<FormState>();
  final UserSession _userSession = Get.find<UserSession>();

  // Controllers
  final _scoopController = TextEditingController();
  final _periodeController = TextEditingController();
  final _observationsController = TextEditingController();

  // Variables
  DateTime _dateAchat = DateTime.now();
  List<Map<String, dynamic>> _contenants = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addContenant();
  }

  @override
  void dispose() {
    _scoopController.dispose();
    _periodeController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  void _addContenant() {
    setState(() {
      _contenants.add({
        'type_contenant': 'Bidon',
        'type_miel': 'Liquide',
        'quantite': 0.0,
        'prix_unitaire': 0.0,
        'montant_total': 0.0,
      });
    });
  }

  void _removeContenant(int index) {
    setState(() {
      _contenants.removeAt(index);
    });
  }

  double get _poidsTotal {
    return _contenants.fold(0.0, (sum, c) => sum + (c['quantite'] ?? 0.0));
  }

  double get _montantTotal {
    return _contenants.fold(0.0, (sum, c) => sum + (c['montant_total'] ?? 0.0));
  }

  Future<void> _saveAchatScoop() async {
    if (!_formKey.currentState!.validate()) return;
    if (_contenants.isEmpty) {
      Get.snackbar('Erreur', 'Ajoutez au moins un contenant');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'scoop_nom': _scoopController.text,
        'periode_collecte': _periodeController.text,
        'date_achat': Timestamp.fromDate(_dateAchat),
        'contenants': _contenants,
        'poids_total': _poidsTotal,
        'montant_total': _montantTotal,
        'observations': _observationsController.text,
        'collecteur_id': _userSession.uid,
        'collecteur_nom': _userSession.nom,
        'site': _userSession.site,
        'created_at': Timestamp.now(),
        'statut': 'collecte_terminee',
      };

      await FirebaseFirestore.instance
          .collection('Sites')
          .doc(_userSession.site)
          .collection('nos_achats_scoop')
          .add(data);

      // Régénérer les statistiques
      await StatsAchatsScoopService.regenerateAdvancedStats(
          _userSession.site ?? '');

      Get.snackbar(
        'Succès',
        'Achat SCOOP enregistré avec succès',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );

      // Reset du formulaire
      _resetForm();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de l\'enregistrement: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _scoopController.clear();
    _periodeController.clear();
    _observationsController.clear();
    setState(() {
      _dateAchat = DateTime.now();
      _contenants.clear();
      _addContenant();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber.shade50,
      appBar: AppBar(
        title: const Text(
          'Nouvel achat SCOOP',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            tooltip: 'Historique des achats',
            icon: const Icon(Icons.history),
            onPressed: () => Get.to(() => const HistoriquesCollectesPage()),
          ),
        ],
      ),
      body: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  Text(
                    'Informations SCOOP',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nom SCOOP
                  TextFormField(
                    controller: _scoopController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du SCOOP',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Nom requis' : null,
                  ),
                  const SizedBox(height: 16),

                  // Période
                  TextFormField(
                    controller: _periodeController,
                    decoration: const InputDecoration(
                      labelText: 'Période de collecte',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Période requise' : null,
                  ),
                  const SizedBox(height: 24),

                  // Contenants
                  Text(
                    'Contenants',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ..._contenants.asMap().entries.map((entry) {
                    final index = entry.key;
                    final contenant = entry.value;
                    return _buildContenantCard(index, contenant);
                  }).toList(),

                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addContenant,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un contenant'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Observations
                  TextFormField(
                    controller: _observationsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observations',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Résumé
                  Card(
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Résumé',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                              'Poids total: ${_poidsTotal.toStringAsFixed(2)} kg'),
                          Text(
                              'Montant total: ${_montantTotal.toStringAsFixed(2)} CFA'),
                          Text('Nombre de contenants: ${_contenants.length}'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bouton enregistrer
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveAchatScoop,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Enregistrer l\'achat SCOOP',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContenantCard(int index, Map<String, dynamic> contenant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Contenant ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_contenants.length > 1)
                  IconButton(
                    onPressed: () => _removeContenant(index),
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: contenant['type_contenant'],
                    decoration: const InputDecoration(
                      labelText: 'Type contenant',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Bidon', 'Pot'].map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => contenant['type_contenant'] = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: contenant['type_miel'],
                    decoration: const InputDecoration(
                      labelText: 'Type miel',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Liquide', 'Brute', 'Cire'].map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => contenant['type_miel'] = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: contenant['quantite']?.toString() ?? '0',
                    decoration: const InputDecoration(
                      labelText: 'Quantité (kg)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final qty = double.tryParse(value) ?? 0.0;
                      setState(() {
                        contenant['quantite'] = qty;
                        contenant['montant_total'] =
                            qty * (contenant['prix_unitaire'] ?? 0.0);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: contenant['prix_unitaire']?.toString() ?? '0',
                    decoration: const InputDecoration(
                      labelText: 'Prix unitaire (CFA)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final price = double.tryParse(value) ?? 0.0;
                      setState(() {
                        contenant['prix_unitaire'] = price;
                        contenant['montant_total'] =
                            (contenant['quantite'] ?? 0.0) * price;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Montant: ${(contenant['montant_total'] ?? 0.0).toStringAsFixed(2)} CFA',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
