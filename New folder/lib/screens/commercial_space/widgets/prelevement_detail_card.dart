import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../vente/models/vente_models.dart';

/// Widget card pour afficher détails d'un prélèvement avec actions
class PrelevementDetailCard extends StatelessWidget {
  final Prelevement prelevement;
  final void Function(Prelevement, String) onAction;
  final List<ProduitPreleve>? produitsRestants;
  final StatutPrelevement? statutDynamique;
  final double? progression;

  const PrelevementDetailCard({
    super.key,
    required this.prelevement,
    required this.onAction,
    this.produitsRestants,
    this.statutDynamique,
    this.progression,
  });

  @override
  Widget build(BuildContext context) {
    final statutEffectif = statutDynamique ?? prelevement.statut;
    final statusColor = _getStatusColor(statutEffectif);
    final statusLabel = _getStatusLabel(statutEffectif);
    final produitsAffiches = produitsRestants ?? prelevement.produits;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Prélèvement ${prelevement.id.split('_').last}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Infos de base
            Text(
              'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(prelevement.datePrelevement)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            Text(
              'Par: ${prelevement.magazinierNom}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 12),

            // Progression si fournie
            if (progression != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Progression', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text('${progression!.toStringAsFixed(1)}%'),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progression! / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
              const SizedBox(height: 12),
            ],

            // Aperçu produits
            Text(
              'Produits (${produitsAffiches.length}):',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: produitsAffiches
                  .take(3)
                  .map((p) => Chip(
                        label: Text('${p.typeEmballage} x${p.quantitePreleve}'),
                        backgroundColor: Colors.blue[50],
                      ))
                  .toList(),
            ),
            if (produitsAffiches.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+${produitsAffiches.length - 3} autres produits',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),

            // Actions (seulement si en cours ou partiel)
            if (statutEffectif == StatutPrelevement.enCours ||
                statutEffectif == StatutPrelevement.partiel) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onAction(prelevement, 'vendre'),
                      child: const Text('Vendre'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onAction(prelevement, 'restituer'),
                      child: const Text('Restituer'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onAction(prelevement, 'perte'),
                      child: const Text('Perte'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(StatutPrelevement statut) {
    switch (statut) {
      case StatutPrelevement.enCours:
        return Colors.blue;
      case StatutPrelevement.partiel:
        return Colors.orange;
      case StatutPrelevement.termine:
        return Colors.green;
      case StatutPrelevement.annule:
        return Colors.red;
    }
  }

  String _getStatusLabel(StatutPrelevement statut) {
    switch (statut) {
      case StatutPrelevement.enCours:
        return 'En cours';
      case StatutPrelevement.partiel:
        return 'Partiel';
      case StatutPrelevement.termine:
        return 'Terminé';
      case StatutPrelevement.annule:
        return 'Annulé';
    }
  }
}