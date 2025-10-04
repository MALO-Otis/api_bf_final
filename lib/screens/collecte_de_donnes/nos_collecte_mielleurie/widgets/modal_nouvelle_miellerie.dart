import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/miellerie_models.dart';
import '../../../../data/services/stats_mielleries_service.dart';
import '../../../../authentication/user_session.dart';

class ModalNouvelleMiellerie extends StatefulWidget {
  final List<Map<String, dynamic>> cooperatives;
  final Function(MiellerieModel) onMiellerieCreated;

  const ModalNouvelleMiellerie({
    super.key,
    required this.cooperatives,
    required this.onMiellerieCreated,
  });

  @override
  State<ModalNouvelleMiellerie> createState() => _ModalNouvelleMiellerieState();
}

class _ModalNouvelleMiellerieState extends State<ModalNouvelleMiellerie> {
  final _formKey = GlobalKey<FormState>();
  final UserSession _userSession = Get.find<UserSession>();
  bool _isLoading = false;

  // Controllers
  final _nomController = TextEditingController();
  final _localiteController = TextEditingController();
  final _repondantController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();

  // Variables
  Map<String, dynamic>? _selectedCooperative;

  @override
  void dispose() {
    _nomController.dispose();
    _localiteController.dispose();
    _repondantController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  Future<void> _createMiellerie() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCooperative == null) {
      Get.snackbar('Erreur', 'Sélectionnez une coopérative');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final miellerie = MiellerieModel(
        id: '',
        nom: _nomController.text,
        localite: _localiteController.text,
        cooperativeId: _selectedCooperative!['id'],
        cooperativeNom: _selectedCooperative!['nom'],
        repondant: _repondantController.text,
        telephone: _telephoneController.text.isEmpty
            ? null
            : _telephoneController.text,
        adresse:
            _adresseController.text.isEmpty ? null : _adresseController.text,
        createdAt: DateTime.now(),
      );

      final miellerieId = await StatsMielleriesService.createMiellerie(
          miellerie, _userSession.site ?? '');

      final createdMiellerie = miellerie.copyWith(id: miellerieId);
      widget.onMiellerieCreated(createdMiellerie);

      Get.snackbar(
        'Succès',
        'Miellerie "${miellerie.nom}" créée avec succès',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );

      Navigator.of(context).pop();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de la création: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nouvelle Miellerie',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade800,
              ),
            ),
            const SizedBox(height: 20),

            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Nom de la miellerie
                      TextFormField(
                        controller: _nomController,
                        decoration: const InputDecoration(
                          labelText: 'Nom de la miellerie *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.factory),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Nom requis' : null,
                      ),
                      const SizedBox(height: 16),

                      // Coopérative
                      DropdownButtonFormField<Map<String, dynamic>>(
                        value: _selectedCooperative,
                        decoration: const InputDecoration(
                          labelText: 'Coopérative *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.group),
                        ),
                        items: widget.cooperatives.map((coop) {
                          return DropdownMenuItem(
                            value: coop,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  coop['nom'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                if (coop['region'] != null &&
                                    coop['region'].isNotEmpty)
                                  Text(
                                    '${coop['region']} - ${coop['commune'] ?? ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (coop) =>
                            setState(() => _selectedCooperative = coop),
                        validator: (value) => value == null
                            ? 'Sélectionnez une coopérative'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Localité et Répondant
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _localiteController,
                              decoration: const InputDecoration(
                                labelText: 'Localité *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_on),
                              ),
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'Localité requise'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _repondantController,
                              decoration: const InputDecoration(
                                labelText: 'Répondant *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'Répondant requis'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Téléphone et Adresse (optionnels)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _telephoneController,
                              decoration: const InputDecoration(
                                labelText: 'Téléphone',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _adresseController,
                              decoration: const InputDecoration(
                                labelText: 'Adresse',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.home),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Boutons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createMiellerie,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Créer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Extension pour copyWith sur MiellerieModel
extension MiellerieModelExtension on MiellerieModel {
  MiellerieModel copyWith({
    String? id,
    String? nom,
    String? localite,
    String? cooperativeId,
    String? cooperativeNom,
    String? repondant,
    String? telephone,
    String? adresse,
    DateTime? createdAt,
  }) {
    return MiellerieModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      localite: localite ?? this.localite,
      cooperativeId: cooperativeId ?? this.cooperativeId,
      cooperativeNom: cooperativeNom ?? this.cooperativeNom,
      repondant: repondant ?? this.repondant,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
