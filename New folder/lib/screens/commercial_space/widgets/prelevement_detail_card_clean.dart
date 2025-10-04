import 'package:flutter/material.dart';
import '../../vente/models/vente_models.dart';


/// Widget propre reconstruit: affiche un prélèvement avec statut dynamique,
/// produits restants (facultatif) et barre de progression.
class PrelevementDetailCardClean extends StatelessWidget {
  final Prelevement prelevement;
  final void Function(Prelevement, String) onAction;
  final List<ProduitPreleve>? produitsRestants;
  final StatutPrelevement?
      statutDynamique; // prioritaire sur prelevement.statut
  final double? progression; // 0-100

  const PrelevementDetailCardClean({
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
    final statusColor = _statusColor(statutEffectif, progression);
    final statusLabel = _statusLabel(statutEffectif, progression);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prélèvement ${_shortId(prelevement.id)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: -4,
                        children: [
                          _StatusChip(color: statusColor, label: statusLabel),
                          if (progression != null)
                            _StatusChip(
                              color: Colors.blueGrey.shade700,
                              label: '${progression!.toStringAsFixed(1)}%',
                            ),
                          _StatusChip(
                            color: Colors.indigo.shade400,
                            label: '${prelevement.produits.length} prod.',
                          ),
                          if (produitsRestants != null)
                            _StatusChip(
                              color: Colors.orange.shade400,
                              label: '${produitsRestants!.length} restants',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) => onAction(prelevement, v),
                  itemBuilder: (c) => const [
                    PopupMenuItem(value: 'vendre', child: Text('Vendre')),
                    PopupMenuItem(value: 'restituer', child: Text('Restituer')),
                    PopupMenuItem(value: 'perte', child: Text('Perte')),
                  ],
                ),
              ],
            ),
            if (progression != null) ...[
              const SizedBox(height: 12),
              _ProgressBar(
                value: (progression!).clamp(0, 100) / 100,
                color: statusColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _shortId(String id) {
    final parts = id.split('_');
    return parts.isNotEmpty ? parts.last : id;
  }

  Color _statusColor(StatutPrelevement statut, double? prog) {
    if ((prog ?? 0) >= 100) return const Color(0xFF10B981); // vert
    switch (statut) {
      case StatutPrelevement.enCours:
        return const Color(0xFF3B82F6); // bleu
      case StatutPrelevement.partiel:
        return const Color(0xFFF59E0B); // orange
      case StatutPrelevement.termine:
        return const Color(0xFF10B981); // vert
      case StatutPrelevement.annule:
        return const Color(0xFF6B7280); // gris
    }
  }

  String _statusLabel(StatutPrelevement statut, double? prog) {
    if ((prog ?? 0) >= 100) return 'Terminé';
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

class _StatusChip extends StatelessWidget {
  final Color color;
  final String label;
  const _StatusChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: color.darken(),
          letterSpacing: .2,
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value; // 0-1
  final Color color;
  const _ProgressBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        minHeight: 10,
        value: value.clamp(0, 1),
        backgroundColor: color.withOpacity(.15),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

// Petite extension utilitaire pour assombrir légèrement une couleur.
extension _ColorUtils on Color {
  Color darken([double amount = .18]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
