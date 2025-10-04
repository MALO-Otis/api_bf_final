/// 🟫 WIDGETS AMÉLIORÉS POUR L'EXTRACTION
///
/// Collection complète de widgets pour l'interface d'extraction moderne

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';
import '../models/extraction_models_improved.dart';

/// Widget pour afficher les statistiques d'extraction
class ExtractionStatsWidget extends StatelessWidget {
  final RxMap<String, dynamic> stats;
  final bool isLoading;

  const ExtractionStatsWidget({
    Key? key,
    required this.stats,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.brown[600]),
                const SizedBox(width: 8),
                const Text(
                  'Statistiques d\'Extraction',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() => Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Attribués',
                        '${stats['totalAttribues'] ?? 0}',
                        Icons.inventory,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'En Cours',
                        '${stats['enCours'] ?? 0}',
                        Icons.play_circle,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Terminées',
                        '${stats['terminees'] ?? 0}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Urgents',
                        '${stats['urgents'] ?? 0}',
                        Icons.priority_high,
                        Colors.red,
                      ),
                    ),
                  ],
                )),
            const SizedBox(height: 12),
            Obx(() => Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        'Poids Total',
                        '${(stats['poidsTotal'] ?? 0.0).toStringAsFixed(1)} kg',
                        Icons.scale,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoCard(
                        'Rendement Moyen',
                        '${(stats['rendementMoyen'] ?? 0.0).toStringAsFixed(1)}%',
                        Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoCard(
                        'Durée Moyenne',
                        '${stats['dureeMoyenne'] ?? 0} min',
                        Icons.timer,
                      ),
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de carte pour un produit à extraire
class ExtractionCardImproved extends StatelessWidget {
  final ProductControle produit;
  final VoidCallback? onDemarrerExtraction;
  final VoidCallback? onDetails;

  const ExtractionCardImproved({
    Key? key,
    required this.produit,
    this.onDemarrerExtraction,
    this.onDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onDetails,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec code et urgence
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.brown[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      produit.codeContenant,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800],
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (produit.isUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.priority_high,
                              size: 12, color: Colors.red[700]),
                          const SizedBox(width: 2),
                          Text(
                            'URGENT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Informations produit
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                            Icons.person, 'Producteur', produit.producteur),
                        _buildInfoRow(
                            Icons.location_on, 'Village', produit.village),
                        _buildInfoRow(Icons.scale, 'Poids',
                            '${produit.poidsTotal.toStringAsFixed(1)} kg'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                            Icons.inventory_2, 'Nature', produit.nature.name),
                        _buildInfoRow(Icons.star, 'Qualité', produit.qualite),
                        _buildInfoRow(Icons.calendar_today, 'Réception',
                            '${produit.dateReception.day}/${produit.dateReception.month}/${produit.dateReception.year}'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onDemarrerExtraction,
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Démarrer Extraction'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onDetails,
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Détails'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.brown[600],
                      side: BorderSide(color: Colors.brown[300]!),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de carte pour une extraction en cours
class ExtractionProcessCard extends StatelessWidget {
  final ExtractionProcess extraction;
  final VoidCallback? onTerminer;
  final VoidCallback? onSuspendre;
  final VoidCallback? onDetails;

  const ExtractionProcessCard({
    Key? key,
    required this.extraction,
    this.onTerminer,
    this.onSuspendre,
    this.onDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final duree = extraction.dureeEcoulee;
    final heures = duree.inHours;
    final minutes = duree.inMinutes % 60;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onDetails,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec statut
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      extraction.produit.codeContenant,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      extraction.statut.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${heures}h ${minutes}min',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: extraction.isUrgent
                          ? Colors.red[700]
                          : Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Informations
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                            Icons.person, 'Extracteur', extraction.extracteur),
                        _buildInfoRow(
                            Icons.location_on, 'Site', extraction.site),
                        _buildInfoRow(Icons.play_arrow, 'Début',
                            '${extraction.dateDebut.day}/${extraction.dateDebut.month} ${extraction.dateDebut.hour}:${extraction.dateDebut.minute.toString().padLeft(2, '0')}'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(Icons.person_outline, 'Producteur',
                            extraction.produit.producteur),
                        _buildInfoRow(Icons.scale, 'Poids',
                            '${extraction.produit.poidsTotal.toStringAsFixed(1)} kg'),
                        if (extraction.instructions != null)
                          _buildInfoRow(Icons.note, 'Instructions',
                              extraction.instructions!),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onTerminer,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Terminer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onSuspendre,
                      icon: const Icon(Icons.pause, size: 18),
                      label: const Text('Suspendre'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onDetails,
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Détails'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.brown[600],
                      side: BorderSide(color: Colors.brown[300]!),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de carte pour une extraction terminée
class ExtractionResultCard extends StatelessWidget {
  final ExtractionResult result;
  final VoidCallback? onDetails;
  final VoidCallback? onReprocess;

  const ExtractionResultCard({
    Key? key,
    required this.result,
    this.onDetails,
    this.onReprocess,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onDetails,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec résultats
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      result.produit.codeContenant,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          _getRendementColor(result.rendement).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${result.rendement.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getRendementColor(result.rendement),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Informations
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                            Icons.person, 'Extracteur', result.extracteur),
                        _buildInfoRow(Icons.scale, 'Poids initial',
                            '${result.poidsInitial.toStringAsFixed(1)} kg'),
                        _buildInfoRow(Icons.trending_up, 'Rendement',
                            result.evaluationRendement),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(Icons.calendar_today, 'Terminé le',
                            '${result.dateFin.day}/${result.dateFin.month}/${result.dateFin.year}'),
                        _buildInfoRow(Icons.scale_outlined, 'Poids extrait',
                            '${result.poidsExtrait.toStringAsFixed(1)} kg'),
                        _buildInfoRow(Icons.timer, 'Durée',
                            '${result.duree.inHours}h ${result.duree.inMinutes % 60}min'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDetails,
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Voir Détails'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.brown[600],
                        side: BorderSide(color: Colors.brown[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onReprocess,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retraiter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[600],
                      side: BorderSide(color: Colors.blue[300]!),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRendementColor(double rendement) {
    if (rendement >= 90) return Colors.green[700]!;
    if (rendement >= 80) return Colors.green[600]!;
    if (rendement >= 70) return Colors.orange[600]!;
    if (rendement >= 60) return Colors.orange[700]!;
    return Colors.red[600]!;
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
