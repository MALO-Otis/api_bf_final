import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/attribution_collectes_service.dart';
import '../../controle_de_donnes/models/collecte_models.dart';
import '../../controle_de_donnes/models/quality_control_models.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart'; // Pour ProductControle
/// Widget pour afficher une carte de collecte avec ses informations de contrôle
/// et les options d'attribution - VERSION DÉTAILLÉE ET DIAGNOSTIQUE

class CollecteAttributionCard extends StatefulWidget {
  final BaseCollecte collecte;
  final CollecteControlInfo? controlInfo;
  final Function(List<ProductControle>)? onAttributeProducts;
  final VoidCallback? onViewDetails;

  const CollecteAttributionCard({
    Key? key,
    required this.collecte,
    required this.controlInfo,
    this.onAttributeProducts,
    this.onViewDetails,
  }) : super(key: key);

  @override
  State<CollecteAttributionCard> createState() =>
      _CollecteAttributionCardState();
}

class _CollecteAttributionCardState extends State<CollecteAttributionCard> {
  bool _isExpanded = false;
  bool _showDebugInfo = kDebugMode;

  Section _determineSection(BaseCollecte collecte) {
    if (collecte is Recolte) {
      return Section.recoltes;
    } else if (collecte is Scoop) {
      return Section.scoop;
    } else if (collecte is Individuel) {
      return Section.individuel;
    } else {
      return Section.miellerie;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controlInfo == null) {
      return _buildErrorCard(context);
    }

    final info = widget.controlInfo!;
    final section = _determineSection(widget.collecte);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header avec informations principales
          _buildCardHeader(context, info, section),

          // Corps expandable avec détails
          if (_isExpanded) ...[
            const Divider(height: 1),
            _buildExpandedContent(context, info),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.red[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red[300]!),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red[400],
          child: const Icon(Icons.error, color: Colors.white),
        ),
        title: Text(_getCollecteLocation(widget.collecte)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Technicien: ${widget.collecte.technicien ?? "Non spécifié"}'),
            Text(
                'Date: ${DateFormat('dd/MM/yyyy').format(widget.collecte.date)}'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Expanded(child: Text('Données de contrôle non disponibles')),
                ],
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            // Trigger reload
            if (kDebugMode) {
              print('🔄 Tentative de rechargement pour ${widget.collecte.id}');
            }
          },
        ),
      ),
    );
  }

  Widget _buildCardHeader(
      BuildContext context, CollecteControlInfo info, Section section) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });

          if (kDebugMode) {
            print(
                '🎯 Card ${_isExpanded ? "expanded" : "collapsed"} pour collecte ${widget.collecte.id}');
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Première ligne : localisation et status
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: info.statusColor,
                    radius: 24,
                    child: Icon(
                      _getSectionIcon(section),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getCollecteLocation(widget.collecte),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Technicien: ${widget.collecte.technicien ?? "Non spécifié"}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Date: ${DateFormat('dd/MM/yyyy').format(widget.collecte.date)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        section.name.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: info.statusColor,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Barre de progression
              _buildProgressBar(info),

              const SizedBox(height: 8),

              // Statistiques rapides
              _buildQuickStats(info),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(CollecteControlInfo info) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              info.statusSummary,
              style: TextStyle(
                fontSize: 12,
                color: info.statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (info.poidsTotal > 0)
              Text(
                '${info.poidsTotal.toStringAsFixed(1)} kg',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: info.completionPercentage,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(info.statusColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(CollecteControlInfo info) {
    return Row(
      children: [
        _buildQuickStatChip('Total Reçus', '${info.totalContainers}',
            Colors.blue, Icons.inventory),
        const SizedBox(width: 6),
        _buildQuickStatChip('À Contrôler', '${info.totalRestants}',
            Colors.orange, Icons.pending_actions),
        const SizedBox(width: 6),
        _buildQuickStatChip('Attribués', '${info.totalAttribues}',
            Colors.purple, Icons.assignment_turned_in),
        if (info.hasAvailableProducts) ...[
          const SizedBox(width: 6),
          _buildQuickStatChip('Disponibles', '${info.totalDisponibles}',
              Colors.green, Icons.verified),
        ],
      ],
    );
  }

  Widget _buildQuickStatChip(
      String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Column(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context, CollecteControlInfo info) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section des statistiques détaillées
          _buildDetailedStats(info),

          const SizedBox(height: 16),

          // Section des produits disponibles
          _buildProductsSection(info),

          const SizedBox(height: 16),

          // Section de diagnostic et debug (si en mode debug)
          if (_showDebugInfo) ...[
            _buildDebugSection(info),
            const SizedBox(height: 16),
          ],

          // Section des actions
          _buildActionButtons(context, info),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(CollecteControlInfo info) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Statistiques Détaillées',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Grille de statistiques améliorée
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _buildDetailedStatItem('Total Reçus', '${info.totalContainers}',
                  Colors.blue, Icons.inventory),
              _buildDetailedStatItem(
                  'Restant à Contrôler',
                  '${info.totalRestants}',
                  Colors.orange,
                  Icons.pending_actions),
              _buildDetailedStatItem(
                  'Déjà Contrôlés',
                  '${info.controlledContainers}',
                  Colors.green,
                  Icons.fact_check),
              _buildDetailedStatItem('Déjà Attribués', '${info.totalAttribues}',
                  Colors.purple, Icons.assignment_turned_in),
              _buildDetailedStatItem('Conformes Disponibles',
                  '${info.totalDisponibles}', Colors.teal, Icons.verified),
              _buildDetailedStatItem('Non Conformes',
                  '${info.nonConformeCount}', Colors.red, Icons.cancel),
            ],
          ),

          // Section des poids basée sur les contrôles qualité
          if (info.poidsTotal > 0) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[25],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 Poids Enregistrés lors du Contrôle Qualité',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildWeightItem(
                          'Total Contrôlé',
                          info.poidsTotal,
                          Colors.blue[700]!,
                          Icons.scale,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildWeightItem(
                          'Conformes',
                          info.poidsConformes,
                          Colors.green[700]!,
                          Icons.check_circle,
                        ),
                      ),
                    ],
                  ),
                  if (info.poidsNonConformes > 0) ...[
                    const SizedBox(height: 8),
                    _buildWeightItem(
                      'Non Conformes (Rejetés)',
                      info.poidsNonConformes,
                      Colors.red[700]!,
                      Icons.cancel,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedStatItem(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection(CollecteControlInfo info) {
    if (info.conformeCount == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange[50]!, Colors.orange[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[300]!),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aucun produit conforme disponible',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              info.controlledContainers == 0
                  ? 'Les contenants n\'ont pas encore été contrôlés.'
                  : 'Tous les contenants contrôlés sont non conformes.',
              style: TextStyle(
                color: Colors.orange[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.green[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text(
                'Produits Disponibles pour Attribution',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Liste des contenants conformes
          ...info.produitsConformesDisponibles.take(5).map(
                (qualityControl) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _getProductIcon(qualityControl.honeyNature),
                          color: Colors.green[700],
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Code: ${qualityControl.containerCode}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Poids: ${qualityControl.totalWeight.toStringAsFixed(1)} kg (Contrôlé)',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          qualityControl.honeyNature.name.toUpperCase(),
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

          if (info.produitsConformesDisponibles.length > 5) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'et ${info.produitsConformesDisponibles.length - 5} autres produits...',
                style: TextStyle(
                  color: Colors.green[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDebugSection(CollecteControlInfo info) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[50]!, Colors.purple[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.purple[700]),
              const SizedBox(width: 8),
              Text(
                'Informations de Diagnostic (Debug)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                    _showDebugInfo ? Icons.visibility_off : Icons.visibility),
                color: Colors.purple[700],
                iconSize: 16,
                onPressed: () {
                  setState(() {
                    _showDebugInfo = !_showDebugInfo;
                  });
                },
              ),
            ],
          ),
          if (_showDebugInfo) ...[
            const SizedBox(height: 8),
            Text('Collecte ID: ${info.collecteId}',
                style: TextStyle(fontSize: 11, color: Colors.purple[600])),
            Text('Type: ${widget.collecte.runtimeType}',
                style: TextStyle(fontSize: 11, color: Colors.purple[600])),
            Text(
                'Dernière MAJ: ${DateFormat('dd/MM/yyyy HH:mm').format(info.lastUpdated)}',
                style: TextStyle(fontSize: 11, color: Colors.purple[600])),
            Text('Contrôles en DB: ${info.controlsByContainer.length}',
                style: TextStyle(fontSize: 11, color: Colors.purple[600])),
            if (widget.collecte is Scoop) ...[
              const SizedBox(height: 4),
              Text(
                  'Contenants SCOOP déclarés: ${(widget.collecte as Scoop).contenants.length}',
                  style: TextStyle(fontSize: 11, color: Colors.purple[600])),
            ] else if (widget.collecte is Recolte) ...[
              const SizedBox(height: 4),
              Text(
                  'Contenants RECOLTE déclarés: ${(widget.collecte as Recolte).contenants.length}',
                  style: TextStyle(fontSize: 11, color: Colors.purple[600])),
            ] else if (widget.collecte is Individuel) ...[
              const SizedBox(height: 4),
              Text(
                  'Contenants INDIVIDUEL déclarés: ${(widget.collecte as Individuel).contenants.length}',
                  style: TextStyle(fontSize: 11, color: Colors.purple[600])),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, CollecteControlInfo info) {
    return Row(
      children: [
        // Bouton d'attribution
        Expanded(
          child: ElevatedButton.icon(
            onPressed: info.hasAvailableProducts
                ? () {
                    if (kDebugMode) {
                      print(
                          '🎯 Attribution demandée pour ${widget.collecte.id}');
                      print('   ${info.totalDisponibles} produits disponibles');
                    }

                    final produits = info.produitsConformesDisponibles
                        .map((qc) => ProductControle(
                              id: '${widget.collecte.id}_${qc.containerCode}',
                              codeContenant: qc.containerCode,
                              dateReception: widget.collecte.date,
                              producteur: widget.collecte.technicien ?? '',
                              village: _getCollecteLocation(widget.collecte),
                              commune: _getCollecteLocation(widget.collecte),
                              quartier: '',
                              nature: ProductNature.brut,
                              typeContenant: 'Standard',
                              numeroContenant: qc.containerCode,
                              poidsTotal: qc.totalWeight,
                              poidsMiel: qc.totalWeight,
                              qualite: 'Bon',
                              predominanceFlorale: 'Standard',
                              estConforme: true,
                              dateControle: DateTime.now(),
                              siteOrigine:
                                  _getCollecteLocation(widget.collecte),
                              collecteId: widget.collecte.id,
                              typeCollecte:
                                  _determineSection(widget.collecte).toString(),
                              dateCollecte: widget.collecte.date,
                            ))
                        .toList();

                    widget.onAttributeProducts?.call(produits);
                  }
                : null,
            icon: Icon(
              info.hasAvailableProducts
                  ? Icons.assignment_turned_in
                  : Icons.block,
              size: 18,
            ),
            label: Text(
              info.hasAvailableProducts
                  ? 'Attribuer (${info.totalDisponibles})'
                  : 'Aucun produit',
              style: const TextStyle(fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  info.hasAvailableProducts ? Colors.green : Colors.grey[300],
              foregroundColor:
                  info.hasAvailableProducts ? Colors.white : Colors.grey[600],
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Bouton de détails
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onViewDetails ??
                () {
                  if (kDebugMode) {
                    print('📋 Détails demandés pour ${widget.collecte.id}');
                  }
                  // Naviguer vers les détails complets
                },
            icon: const Icon(Icons.info_outline, size: 18),
            label: const Text('Détails', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            ),
          ),
        ),
      ],
    );
  }

  String _getCollecteLocation(BaseCollecte collecte) {
    if (collecte is Recolte) {
      return collecte.village ??
          collecte.commune ??
          collecte.province ??
          collecte.site;
    } else if (collecte is Scoop) {
      return collecte.village ??
          collecte.commune ??
          collecte.localisation ??
          collecte.site;
    } else if (collecte is Individuel) {
      return collecte.village ??
          collecte.commune ??
          collecte.localisation ??
          collecte.site;
    }
    return collecte.site;
  }

  /// Retourne l'icône appropriée pour une section
  IconData _getSectionIcon(Section section) {
    switch (section) {
      case Section.recoltes:
        return Icons.hive;
      case Section.scoop:
        return Icons.water_drop;
      case Section.individuel:
        return Icons.person;
      case Section.miellerie:
        return Icons.factory;
    }
  }

  /// Retourne l'icône appropriée pour un type de produit
  IconData _getProductIcon(HoneyNature nature) {
    switch (nature) {
      case HoneyNature.brut:
        return Icons.science;
      case HoneyNature.prefilitre:
        return Icons.filter_alt;
      case HoneyNature.cire:
        return Icons.build;
    }
  }

  /// Widget pour afficher les informations de poids
  Widget _buildWeightItem(
      String label, double weight, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${weight.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 13,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withOpacity(0.8),
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
