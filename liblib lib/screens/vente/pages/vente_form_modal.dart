/// 🛒 MODAL DE FORMULAIRE DE VENTE
///
/// Interface pour enregistrer une nouvelle vente

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/vente_models.dart';

class VenteFormModal extends StatefulWidget {
  final Prelevement prelevement;
  final VoidCallback onVenteEnregistree;

  const VenteFormModal({
    super.key,
    required this.prelevement,
    required this.onVenteEnregistree,
  });

  @override
  State<VenteFormModal> createState() => _VenteFormModalState();
}

class _VenteFormModalState extends State<VenteFormModal> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.point_of_sale, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Formulaire de Vente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cette fonctionnalité sera développée prochainement.\n'
              'Elle permettra d\'enregistrer des ventes avec :\n'
              '• Sélection des produits\n'
              '• Informations client\n'
              '• Mode de paiement\n'
              '• Calculs automatiques',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }
}
