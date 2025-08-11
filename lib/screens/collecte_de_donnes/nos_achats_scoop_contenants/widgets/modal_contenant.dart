import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/scoop_models.dart';

class ModalContenant extends StatefulWidget {
  final ContenantScoopModel? contenant;

  const ModalContenant({
    super.key,
    this.contenant,
  });

  @override
  State<ModalContenant> createState() => _ModalContenantState();
}

class _ModalContenantState extends State<ModalContenant> {
  final _formKey = GlobalKey<FormState>();

  ContenantType _typeContenant = ContenantType.bidon;
  MielType _typeMiel = MielType.liquide;
  final _poidsController = TextEditingController();
  final _prixController = TextEditingController();
  final _notesController = TextEditingController();

  bool get _isEdit => widget.contenant != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final contenant = widget.contenant!;
      _typeContenant = contenant.typeContenant;
      _typeMiel = contenant.typeMiel;
      _poidsController.text = contenant.poids.toString();
      _prixController.text = contenant.prix.toString();
      _notesController.text = contenant.notes ?? '';
    }
  }

  @override
  void dispose() {
    _poidsController.dispose();
    _prixController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
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
                      color: Colors.amber.shade700,
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

              const SizedBox(height: 24),

              // Type de contenant et type de miel
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Type de contenant *',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<ContenantType>(
                          value: _typeContenant,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.inventory),
                          ),
                          items: ContenantType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type.label),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _typeContenant = value!);
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
                          'Type de miel *',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<MielType>(
                          value: _typeMiel,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.water_drop),
                          ),
                          items: MielType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type.label),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _typeMiel = value!);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Poids et prix
              Row(
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
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*')),
                          ],
                          validator: (value) {
                            if (value?.isEmpty == true) return 'Poids requis';
                            final poids = double.tryParse(value!);
                            if (poids == null || poids <= 0)
                              return 'Poids invalide (> 0)';
                            if (poids > 1000)
                              return 'Poids trop élevé (< 1000 kg)';
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
                            prefixIcon: const Icon(Icons.monetization_on),
                            hintText: '0',
                            suffixText: 'CFA',
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
                    'Notes (optionnel)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.note),
                      hintText: 'Remarques ou informations complémentaires...',
                    ),
                    maxLines: 2,
                    maxLength: 200,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Preview des informations
              Container(
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
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _typeContenant.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _typeMiel.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
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
                    onPressed: _saveContenant,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
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
    );
  }

  void _saveContenant() {
    if (!_formKey.currentState!.validate()) return;

    final contenant = ContenantScoopModel(
      id: widget.contenant?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      typeContenant: _typeContenant,
      typeMiel: _typeMiel,
      poids: double.parse(_poidsController.text),
      prix: double.parse(_prixController.text),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    Navigator.pop(context, contenant);
  }
}
