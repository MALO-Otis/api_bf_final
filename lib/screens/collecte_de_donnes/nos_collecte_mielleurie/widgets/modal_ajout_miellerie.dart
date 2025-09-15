import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/services/stats_mielleries_service.dart';

class ModalAjoutMiellerie extends StatefulWidget {
  final Function(String) onMiellerieAdded;

  const ModalAjoutMiellerie({
    super.key,
    required this.onMiellerieAdded,
  });

  @override
  State<ModalAjoutMiellerie> createState() => _ModalAjoutMiellerieState();
}

class _ModalAjoutMiellerieState extends State<ModalAjoutMiellerie> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _localiteController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nomController.dispose();
    _localiteController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _ajouterMiellerie() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await StatsMielleriesService.createMiellerie(
        nom: _nomController.text.trim(),
        localite: _localiteController.text.trim(),
        telephone: _telephoneController.text.trim().isEmpty
            ? null
            : _telephoneController.text.trim(),
        adresse: _adresseController.text.trim().isEmpty
            ? null
            : _adresseController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      // Notifier le parent que la miellerie a été ajoutée
      widget.onMiellerieAdded(_nomController.text.trim());

      Get.snackbar(
        'Succès',
        'Miellerie ajoutée avec succès',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        icon: const Icon(Icons.check_circle, color: Colors.green),
      );

      Navigator.pop(context);
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de l\'ajout de la miellerie: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
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
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
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
                        color: Colors.indigo.shade700,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.factory,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Ajouter une nouvelle miellerie',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Nom de la miellerie
                TextFormField(
                  controller: _nomController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la miellerie *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.factory),
                    hintText: 'Ex: Miellerie de Koudougou',
                  ),
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'Le nom de la miellerie est requis';
                    }
                    if (value!.trim().length < 3) {
                      return 'Le nom doit contenir au moins 3 caractères';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Localité
                TextFormField(
                  controller: _localiteController,
                  decoration: const InputDecoration(
                    labelText: 'Localité *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                    hintText: 'Ex: Koudougou, Centre-Ouest',
                  ),
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'La localité est requise';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Téléphone
                TextFormField(
                  controller: _telephoneController,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone (optionnel)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                    hintText: 'Ex: 70 12 34 56',
                  ),
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 16),

                // Adresse
                TextFormField(
                  controller: _adresseController,
                  decoration: const InputDecoration(
                    labelText: 'Adresse (optionnel)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home),
                    hintText: 'Ex: Secteur 1, Koudougou',
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optionnel)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                    hintText: 'Informations complémentaires...',
                  ),
                  maxLines: 2,
                  maxLength: 200,
                ),

                const SizedBox(height: 20),

                // Aperçu
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.indigo.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.visibility,
                              color: Colors.indigo, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Aperçu de la miellerie',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nom: ${_nomController.text.isEmpty ? 'Non renseigné' : _nomController.text}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Localité: ${_localiteController.text.isEmpty ? 'Non renseignée' : _localiteController.text}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (_telephoneController.text.isNotEmpty)
                        Text(
                          'Téléphone: ${_telephoneController.text}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Boutons d'action
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _ajouterMiellerie,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Ajouter la miellerie'),
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
}
