import 'package:flutter/material.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';
import '../services/filtrage_service_improved.dart';
import '../models/filtrage_models_improved.dart';

/// MODIFIÉ: Modal d'action pour gérer le cycle de filtrage d'un produit.
/// Utilise maintenant ProductControle et FiltrageServiceImproved.
class FiltrageModal extends StatefulWidget {
  final ProductControle product;
  final VoidCallback onCompleted;

  const FiltrageModal(
      {super.key, required this.product, required this.onCompleted});

  @override
  State<FiltrageModal> createState() => _FiltrageModalState();
}

class _FiltrageModalState extends State<FiltrageModal> {
  final _service = FiltrageServiceImproved();
  final _poidsFiltreController = TextEditingController();
  final _observationsController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _poidsFiltreController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  // NOTE: Les statuts sont maintenant gérés par `FiltrageProcessus`
  // et non plus par un enum simple sur le produit.
  // On se base sur l'existence d'un processus de filtrage pour ce produit.

  Future<void> _startFiltrage() async {
    setState(() => _isProcessing = true);
    try {
      await _service.demarrerFiltrage(
        produit: widget.product,
        agentFiltrage:
            'Agent Test', // TODO: Remplacer par l'utilisateur connecté
        dateDebut: DateTime.now(),
        methodeFiltrage: 'Filtrage Standard',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Filtrage démarré'), backgroundColor: Colors.green),
      );
      widget.onCompleted();
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _suspendFiltrage() async {
    setState(() => _isProcessing = true);
    try {
      // Créer un processus temporaire pour la suspension
      final processTemp = FiltrageProcess(
        id: 'temp_${widget.product.id}',
        produit: widget.product,
        agentFiltrage: 'Agent Test',
        dateDebut: DateTime.now(),
        statut: FiltrageStatus.enCours,
        methodeFiltrage: 'Standard',
        site: widget.product.siteOrigine,
      );

      await _service.suspendreFiltrage(
        filtrage: processTemp,
        raison: _observationsController.text.trim().isEmpty
            ? 'Suspendu par l\'opérateur'
            : _observationsController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Filtrage suspendu'), backgroundColor: Colors.orange),
      );
      widget.onCompleted();
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _terminerFiltrage() async {
    final poids =
        double.tryParse(_poidsFiltreController.text.replaceAll(',', '.'));
    if (poids == null || poids <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez saisir un poids filtré valide'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      // Créer un processus temporaire pour la finalisation
      final processTemp = FiltrageProcess(
        id: 'temp_${widget.product.id}',
        produit: widget.product,
        agentFiltrage: 'Agent Test',
        dateDebut: DateTime.now(),
        statut: FiltrageStatus.enCours,
        methodeFiltrage: 'Standard',
        site: widget.product.siteOrigine,
      );

      await _service.terminerFiltrage(
        filtrage: processTemp,
        volumeFiltre: poids,
        qualiteFinale: 'Filtré',
        limpidite: 'Clair',
        observations: _observationsController.text.trim().isEmpty
            ? null
            : _observationsController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Filtrage terminé avec succès'),
            backgroundColor: Colors.green),
      );
      widget.onCompleted();
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    // TODO: Déterminer le statut (en attente, en cours) en vérifiant
    // l'existence et le statut d'un `FiltrageProcessus` pour ce produit.
    // Pour l'instant, on se base sur des giả định.
    final isEnCours = p.metadata?['statutFiltrage'] == 'en_cours';
    final isEnAttente = !isEnCours;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.filter_alt, size: 22, color: Colors.purple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filtrage - ${p.codeContenant}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isProcessing
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Détails produit
              _detail('Producteur', p.producteur),
              _detail('Village', p.village),
              _detail(
                  'Poids disponible', '${p.poidsTotal.toStringAsFixed(1)} kg'),
              _detail('Qualité', p.qualite),
              _detail('Origine', p.typeCollecte),
              const Divider(height: 24),

              if (isEnCours || isEnAttente) ...[
                TextField(
                  controller: _poidsFiltreController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Poids filtré (kg)',
                    hintText: 'Ex: 18.5',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _observationsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Observations (optionnel)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Row(
                children: [
                  if (isEnAttente)
                    FilledButton.icon(
                      onPressed: _isProcessing ? null : _startFiltrage,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Démarrer'),
                    ),
                  if (isEnCours) ...[
                    FilledButton.icon(
                      onPressed: _isProcessing ? null : _terminerFiltrage,
                      icon: const Icon(Icons.check),
                      label: const Text('Terminer'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _suspendFiltrage,
                      icon: const Icon(Icons.pause),
                      label: const Text('Suspendre'),
                    ),
                  ],
                  const Spacer(),
                  TextButton(
                    onPressed: _isProcessing
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
              width: 140,
              child: Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14))),
        ],
      ),
    );
  }
}
