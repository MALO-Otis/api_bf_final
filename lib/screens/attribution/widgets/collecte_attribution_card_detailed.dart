/// 🎯 WIDGET DÉTAILLÉ POUR CARTE D'ATTRIBUTION DE COLLECTE
///
/// Version ultra-détaillée avec TOUS les détails possibles :
/// - Nombre de contenants reçus, contrôlés, non contrôlés
/// - Nombre de conformes, non conformes, attribués, restants
/// - Poids total, poids conformes, poids non conformes
/// - Détails par contenant (code, poids, qualité, statut)
/// - Informations de debug complètes
/// - Logs détaillés pour diagnostic

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../controle_de_donnes/models/collecte_models.dart';
import '../../controle_de_donnes/models/quality_control_models.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart'; // Pour ProductControle
import '../../extraction/models/extraction_models.dart'; // Pour ProductType
import '../services/attribution_collectes_service.dart';

class CollecteAttributionCardDetailed extends StatefulWidget {
  final BaseCollecte collecte;
  final CollecteControlInfo? controlInfo;
  final Function(List<ProductControle>)? onAttributeProducts;
  final VoidCallback? onViewDetails;
  final bool showDebugInfo;

  const CollecteAttributionCardDetailed({
    Key? key,
    required this.collecte,
    required this.controlInfo,
    this.onAttributeProducts,
    this.onViewDetails,
    this.showDebugInfo = true,
  }) : super(key: key);

  @override
  State<CollecteAttributionCardDetailed> createState() =>
      _CollecteAttributionCardDetailedState();
}

class _CollecteAttributionCardDetailedState
    extends State<CollecteAttributionCardDetailed> {
  bool _isExpanded = false;
  bool _showContainerDetails = false;
  bool _showDebugLogs = kDebugMode;

  @override
  void initState() {
    super.initState();
    _logCardInitialization();
  }

  void _logCardInitialization() {
    if (kDebugMode) {
      print(
          '🎯 [CARD DETAILED] Initialisation carte pour collecte ${widget.collecte.id}');
      print('   - Type: ${widget.collecte.runtimeType}');
      print('   - Site: ${widget.collecte.site}');
      print(
          '   - Date: ${DateFormat('dd/MM/yyyy').format(widget.collecte.date)}');
      print('   - Technicien: ${widget.collecte.technicien ?? "Non défini"}');
      print('   - ControlInfo disponible: ${widget.controlInfo != null}');

      if (widget.controlInfo != null) {
        final info = widget.controlInfo!;
        print('   📊 STATS CONTRÔLE:');
        print('      - Total contenants: ${info.totalContainers}');
        print('      - Contrôlés: ${info.controlledContainers}');
        print('      - Conformes: ${info.conformeCount}');
        print('      - Non conformes: ${info.nonConformeCount}');
        print('      - Restants: ${info.totalRestants}');
        print('      - Attribués: ${info.totalAttribues}');
        print('      - Disponibles: ${info.totalDisponibles}');
        print('      - Poids total: ${info.poidsTotal.toStringAsFixed(2)} kg');
        print(
            '      - Poids conformes: ${info.poidsConformes.toStringAsFixed(2)} kg');
        print(
            '      - Taux contrôle: ${(info.completionPercentage * 100).toStringAsFixed(1)}%');
        print(
            '      - Taux conformité: ${(info.conformityPercentage * 100).toStringAsFixed(1)}%');
      }

      _logCollecteSpecificDetails();
    }
  }

  void _logCollecteSpecificDetails() {
    if (kDebugMode) {
      print('   🔍 DÉTAILS SPÉCIFIQUES PAR TYPE:');

      if (widget.collecte is Recolte) {
        final recolte = widget.collecte as Recolte;
        print('      📦 RÉCOLTE:');
        print('         - Contenants déclarés: ${recolte.contenants.length}');
        print('         - Village: ${recolte.village}');
        print('         - Poids total: ${recolte.totalWeight ?? 0} kg');
        print(
            '         - Ruches types: ${recolte.contenants.map((c) => c.hiveType).toSet().join(", ")}');
        print(
            '         - Types contenants: ${recolte.contenants.map((c) => c.containerType).toSet().join(", ")}');

        // Analyser les contenants individuellement
        for (var i = 0; i < recolte.contenants.length && i < 5; i++) {
          final cont = recolte.contenants[i];
          print(
              '         - Contenant ${i + 1}: ${cont.id}, ${cont.weight}kg, ${cont.containerType}, contrôlé: ${cont.controlInfo.isControlled}');
        }
        if (recolte.contenants.length > 5) {
          print(
              '         ... et ${recolte.contenants.length - 5} autres contenants');
        }
      } else if (widget.collecte is Scoop) {
        final scoop = widget.collecte as Scoop;
        print('      🥄 SCOOP:');
        print('         - Contenants déclarés: ${scoop.contenants.length}');
        print('         - Village: ${scoop.village}');
        print('         - Région: ${scoop.region}');
        print('         - SCOOP nom: ${scoop.scoopNom}');

        double totalQuantite = 0;
        double totalMontant = 0;
        Map<String, int> typesMiel = {};
        Map<String, int> typesContenants = {};

        for (final cont in scoop.contenants) {
          totalQuantite += cont.quantite;
          totalMontant += cont.montantTotal;
          typesMiel[cont.typeMiel] = (typesMiel[cont.typeMiel] ?? 0) + 1;
          typesContenants[cont.typeContenant] =
              (typesContenants[cont.typeContenant] ?? 0) + 1;
        }

        print('         - Quantité totale: ${totalQuantite}kg');
        print('         - Montant total: ${totalMontant}€');
        print('         - Types de miel: ${typesMiel.toString()}');
        print('         - Types de contenants: ${typesContenants.toString()}');

        // Analyser les contenants individuellement
        for (var i = 0; i < scoop.contenants.length && i < 5; i++) {
          final cont = scoop.contenants[i];
          print(
              '         - Contenant ${i + 1}: ${cont.id}, ${cont.quantite}kg, ${cont.typeMiel}, ${cont.montantTotal}€, contrôlé: ${cont.controlInfo.isControlled}');
        }
        if (scoop.contenants.length > 5) {
          print(
              '         ... et ${scoop.contenants.length - 5} autres contenants');
        }
      } else if (widget.collecte is Individuel) {
        final individuel = widget.collecte as Individuel;
        print('      👤 INDIVIDUEL:');
        print(
            '         - Contenants déclarés: ${individuel.contenants.length}');
        print('         - Producteur: ${individuel.nomProducteur}');
        print('         - Village: ${individuel.village}');
        print(
            '         - Origines florales: ${individuel.originesFlorales?.join(", ") ?? "Non défini"}');

        double totalQuantite = 0;
        double totalMontant = 0;

        for (final cont in individuel.contenants) {
          totalQuantite += cont.quantite;
          totalMontant += cont.montantTotal;
        }

        print('         - Quantité totale: ${totalQuantite}kg');
        print('         - Montant total: ${totalMontant}€');

        // Analyser les contenants individuellement
        for (var i = 0; i < individuel.contenants.length && i < 5; i++) {
          final cont = individuel.contenants[i];
          print(
              '         - Contenant ${i + 1}: ${cont.id}, ${cont.quantite}kg, ${cont.typeMiel}, ${cont.montantTotal}€, contrôlé: ${cont.controlInfo.isControlled}');
        }
        if (individuel.contenants.length > 5) {
          print(
              '         ... et ${individuel.contenants.length - 5} autres contenants');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controlInfo == null) {
      return _buildErrorCard(context);
    }

    final info = widget.controlInfo!;
    final section = _determineSection(widget.collecte);

    if (kDebugMode) {
      print('🎨 [CARD DETAILED] Rendering carte pour ${widget.collecte.id}');
      print('   - Section: ${section.name}');
      print('   - Expanded: $_isExpanded');
      print('   - Show containers: $_showContainerDetails');
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: _isExpanded ? 8 : 4,
      shadowColor: info.statusColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: info.statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Header principal
          _buildCardHeader(context, info, section),

          // Contenu expandable
          if (_isExpanded) ...[
            const Divider(height: 1, thickness: 1),
            _buildExpandedContent(context, info),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    if (kDebugMode) {
      print(
          '❌ [CARD DETAILED] Erreur - Pas de ControlInfo pour ${widget.collecte.id}');
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.red[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red[400]!, width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.red[400],
                  radius: 24,
                  child: const Icon(Icons.error, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getCollecteLocation(widget.collecte),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.red[800],
                        ),
                      ),
                      Text(
                        'Technicien: ${widget.collecte.technicien ?? "Non spécifié"}',
                        style: TextStyle(color: Colors.red[600], fontSize: 13),
                      ),
                      Text(
                        'Date: ${DateFormat('dd/MM/yyyy').format(widget.collecte.date)}',
                        style: TextStyle(color: Colors.red[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Données de contrôle non disponibles',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.red[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Impossible de charger les informations de contrôle pour cette collecte. Vérifiez la base de données.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  if (kDebugMode) {
                    print(
                        '🔄 [CARD DETAILED] Tentative rechargement pour ${widget.collecte.id}');
                  }
                  // Trigger reload
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer le chargement'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[700],
                  side: BorderSide(color: Colors.red[400]!),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(
      BuildContext context, CollecteControlInfo info, Section section) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });

          if (kDebugMode) {
            print(
                '🎯 [CARD DETAILED] Card ${_isExpanded ? "expanded" : "collapsed"} pour collecte ${widget.collecte.id}');
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                info.statusColor.withOpacity(0.05),
                info.statusColor.withOpacity(0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Column(
            children: [
              // Première ligne : Avatar, localisation et statut
              Row(
                children: [
                  Hero(
                    tag: 'collecte_avatar_${widget.collecte.id}',
                    child: CircleAvatar(
                      backgroundColor: info.statusColor,
                      radius: 28,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getSectionIcon(section),
                            color: Colors.white,
                            size: 18,
                          ),
                          Text(
                            '${info.conformeCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getCollecteLocation(widget.collecte),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: info.statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: info.statusColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          section.name.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: info.statusColor,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: info.statusColor,
                        size: 24,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Barre de progression avec détails
              _buildProgressSection(info),

              const SizedBox(height: 12),

              // Statistiques principales en badges
              _buildMainStatsBadges(info),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(CollecteControlInfo info) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              info.statusSummary,
              style: TextStyle(
                fontSize: 13,
                color: info.statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                if (info.poidsTotal > 0) ...[
                  Icon(Icons.scale, color: Colors.grey[600], size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${info.poidsTotal.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Double barre de progression
        Column(
          children: [
            // Barre de contrôle
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: info.completionPercentage,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation(
                          info.statusColor.withOpacity(0.7)),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(info.completionPercentage * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    color: info.statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Barre de conformité (si des contrôles existent)
            if (info.controlledContainers > 0) ...[
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: info.conformityPercentage,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation(
                            info.conformityPercentage > 0.8
                                ? Colors.green
                                : info.conformityPercentage > 0.5
                                    ? Colors.orange
                                    : Colors.red),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(info.conformityPercentage * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMainStatsBadges(CollecteControlInfo info) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _buildStatBadge(
            'Reçus', '${info.totalContainers}', Colors.blue, Icons.input),
        _buildStatBadge('Contrôlés', '${info.controlledContainers}',
            Colors.orange, Icons.fact_check),
        _buildStatBadge(
            'Conformes', '${info.conformeCount}', Colors.green, Icons.verified),
        if (info.nonConformeCount > 0)
          _buildStatBadge('Non Conformes', '${info.nonConformeCount}',
              Colors.red, Icons.cancel),
        if (info.totalRestants > 0)
          _buildStatBadge(
              'Restants', '${info.totalRestants}', Colors.grey, Icons.pending),
        if (info.hasAvailableProducts)
          _buildStatBadge('Disponibles', '${info.totalDisponibles}',
              Colors.purple, Icons.assignment_turned_in),
      ],
    );
  }

  Widget _buildStatBadge(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context, CollecteControlInfo info) {
    if (kDebugMode) {
      print(
          '📋 [CARD DETAILED] Affichage contenu expandé pour ${widget.collecte.id}');
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section des statistiques ultra-détaillées
            _buildUltraDetailedStats(info),

            const SizedBox(height: 16),

            // Section des contenants détaillés
            _buildContainersSection(info),

            const SizedBox(height: 16),

            // Section des produits disponibles avec détails complets
            _buildDetailedProductsSection(info),

            const SizedBox(height: 16),

            // Section de diagnostic et logs (si activée)
            if (widget.showDebugInfo) ...[
              _buildDiagnosticSection(info),
              const SizedBox(height: 16),
            ],

            // Section des actions avec détails
            _buildEnhancedActionButtons(context, info),
          ],
        ),
      ),
    );
  }

  Widget _buildUltraDetailedStats(CollecteControlInfo info) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.analytics, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Statistiques Complètes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Grille des statistiques principales
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _buildStatCard('Contenants\nReçus', '${info.totalContainers}',
                  Colors.blue, Icons.inventory, 'Total déclaré'),
              _buildStatCard(
                  'Contenants\nContrôlés',
                  '${info.controlledContainers}',
                  Colors.orange,
                  Icons.fact_check,
                  '${(info.completionPercentage * 100).toStringAsFixed(0)}%'),
              _buildStatCard('Contenants\nRestants', '${info.totalRestants}',
                  Colors.grey, Icons.pending, 'Non contrôlés'),
              _buildStatCard(
                  'Produits\nConformes',
                  '${info.conformeCount}',
                  Colors.green,
                  Icons.verified,
                  '${info.conformeCount > 0 ? (info.conformityPercentage * 100).toStringAsFixed(0) : 0}%'),
              _buildStatCard(
                  'Produits\nNon Conformes',
                  '${info.nonConformeCount}',
                  Colors.red,
                  Icons.cancel,
                  'Rejetés'),
              _buildStatCard(
                  'Produits\nDisponibles',
                  '${info.totalDisponibles}',
                  Colors.purple,
                  Icons.assignment_turned_in,
                  'Pour attribution'),
            ],
          ),

          const SizedBox(height: 16),

          // Statistiques de poids si disponibles
          if (info.poidsTotal > 0) ...[
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.scale, color: Colors.blue[700], size: 18),
                const SizedBox(width: 8),
                Text(
                  'Analyse des Poids',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildWeightCard(
                      'Poids Total', info.poidsTotal, Colors.blue[600]!),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildWeightCard('Poids Conformes',
                      info.poidsConformes, Colors.green[600]!),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildWeightCard('Poids Rejetés',
                      info.poidsNonConformes, Colors.red[600]!),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Graphique de répartition des poids
            _buildWeightDistributionChart(info),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 8,
                color: color.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeightCard(String title, double weight, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${weight.toStringAsFixed(1)} kg',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightDistributionChart(CollecteControlInfo info) {
    if (info.poidsTotal <= 0) return const SizedBox.shrink();

    final conformeRatio =
        info.poidsTotal > 0 ? info.poidsConformes / info.poidsTotal : 0.0;
    final rejecteRatio =
        info.poidsTotal > 0 ? info.poidsNonConformes / info.poidsTotal : 0.0;
    final restantRatio = 1.0 - conformeRatio - rejecteRatio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Répartition des Poids',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.blue[700],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              if (conformeRatio > 0)
                Expanded(
                  flex: (conformeRatio * 100).round(),
                  child: Container(
                    height: 20,
                    color: Colors.green[400],
                    child: Center(
                      child: Text(
                        '${(conformeRatio * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              if (rejecteRatio > 0)
                Expanded(
                  flex: (rejecteRatio * 100).round(),
                  child: Container(
                    height: 20,
                    color: Colors.red[400],
                    child: Center(
                      child: Text(
                        '${(rejecteRatio * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              if (restantRatio > 0)
                Expanded(
                  flex: (restantRatio * 100).round(),
                  child: Container(
                    height: 20,
                    color: Colors.grey[400],
                    child: Center(
                      child: Text(
                        '${(restantRatio * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLegendItem('Conformes', Colors.green[400]!),
            _buildLegendItem('Rejetés', Colors.red[400]!),
            _buildLegendItem('Non contrôlés', Colors.grey[400]!),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildContainersSection(CollecteControlInfo info) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[50]!, Colors.indigo[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo[600],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.inventory_2,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Détail des Contenants (${info.totalContainers})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[800],
                    fontSize: 18,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showContainerDetails = !_showContainerDetails;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _showContainerDetails ? 'Masquer' : 'Afficher',
                      style: TextStyle(color: Colors.indigo[700]),
                    ),
                    Icon(
                      _showContainerDetails
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.indigo[700],
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Résumé des contenants par type
          _buildContainerTypesSummary(),

          const SizedBox(height: 12),

          // Liste détaillée des contenants (si demandée)
          if (_showContainerDetails) ...[
            const Divider(),
            const SizedBox(height: 12),
            _buildDetailedContainersList(info),
          ],
        ],
      ),
    );
  }

  Widget _buildContainerTypesSummary() {
    // Analyser les contenants selon le type de collecte
    final Map<String, int> containerSummary = {};
    final Map<String, int> controlStatusSummary = {};

    if (widget.collecte is Recolte) {
      final recolte = widget.collecte as Recolte;
      for (final cont in recolte.contenants) {
        containerSummary[cont.containerType] =
            (containerSummary[cont.containerType] ?? 0) + 1;
        final status =
            cont.controlInfo.isControlled ? 'Contrôlé' : 'Non contrôlé';
        controlStatusSummary[status] = (controlStatusSummary[status] ?? 0) + 1;
      }
    } else if (widget.collecte is Scoop) {
      final scoop = widget.collecte as Scoop;
      for (final cont in scoop.contenants) {
        containerSummary[cont.typeContenant] =
            (containerSummary[cont.typeContenant] ?? 0) + 1;
        final status =
            cont.controlInfo.isControlled ? 'Contrôlé' : 'Non contrôlé';
        controlStatusSummary[status] = (controlStatusSummary[status] ?? 0) + 1;
      }
    } else if (widget.collecte is Individuel) {
      final individuel = widget.collecte as Individuel;
      for (final cont in individuel.contenants) {
        containerSummary[cont.typeContenant] =
            (containerSummary[cont.typeContenant] ?? 0) + 1;
        final status =
            cont.controlInfo.isControlled ? 'Contrôlé' : 'Non contrôlé';
        controlStatusSummary[status] = (controlStatusSummary[status] ?? 0) + 1;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Types de Contenants',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.indigo[700],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: containerSummary.entries
              .map(
                (entry) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.indigo[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.indigo[300]!),
                  ),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: TextStyle(
                      color: Colors.indigo[800],
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        Text(
          'Statut de Contrôle',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.indigo[700],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: controlStatusSummary.entries
              .map(
                (entry) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: entry.key == 'Contrôlé'
                        ? Colors.green[100]
                        : Colors.orange[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: entry.key == 'Contrôlé'
                          ? Colors.green[300]!
                          : Colors.orange[300]!,
                    ),
                  ),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: TextStyle(
                      color: entry.key == 'Contrôlé'
                          ? Colors.green[800]
                          : Colors.orange[800],
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDetailedContainersList(CollecteControlInfo info) {
    // Construire la liste des contenants avec tous les détails
    final containers = <Widget>[];

    if (widget.collecte is Recolte) {
      final recolte = widget.collecte as Recolte;
      for (var i = 0; i < recolte.contenants.length; i++) {
        final cont = recolte.contenants[i];
        containers.add(_buildContainerDetailCard(
          index: i + 1,
          id: cont.id,
          type: cont.containerType,
          weight: cont.weight,
          hiveType: cont.hiveType,
          isControlled: cont.controlInfo.isControlled,
          conformityStatus: cont.controlInfo.conformityStatus ?? 'Non défini',
          controlDate: cont.controlInfo.controlDate,
          controller: cont.controlInfo.controllerName ?? 'Non défini',
        ));
      }
    } else if (widget.collecte is Scoop) {
      final scoop = widget.collecte as Scoop;
      for (var i = 0; i < scoop.contenants.length; i++) {
        final cont = scoop.contenants[i];
        containers.add(_buildContainerDetailCard(
          index: i + 1,
          id: cont.id,
          type: cont.typeContenant,
          weight: cont.quantite,
          honeyType: cont.typeMiel,
          price: cont.montantTotal,
          unitPrice: cont.prixUnitaire,
          isControlled: cont.controlInfo.isControlled,
          conformityStatus: cont.controlInfo.conformityStatus ?? 'Non défini',
          controlDate: cont.controlInfo.controlDate,
          controller: cont.controlInfo.controllerName ?? 'Non défini',
        ));
      }
    } else if (widget.collecte is Individuel) {
      final individuel = widget.collecte as Individuel;
      for (var i = 0; i < individuel.contenants.length; i++) {
        final cont = individuel.contenants[i];
        containers.add(_buildContainerDetailCard(
          index: i + 1,
          id: cont.id,
          type: cont.typeContenant,
          weight: cont.quantite,
          honeyType: cont.typeMiel,
          price: cont.montantTotal,
          unitPrice: cont.prixUnitaire,
          isControlled: cont.controlInfo.isControlled,
          conformityStatus: cont.controlInfo.conformityStatus ?? 'Non défini',
          controlDate: cont.controlInfo.controlDate,
          controller: cont.controlInfo.controllerName ?? 'Non défini',
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Liste Détaillée des Contenants',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.indigo[700],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        ...containers,
      ],
    );
  }

  Widget _buildContainerDetailCard({
    required int index,
    required String id,
    required String type,
    required double weight,
    String? hiveType,
    String? honeyType,
    double? price,
    double? unitPrice,
    required bool isControlled,
    required String conformityStatus,
    DateTime? controlDate,
    required String controller,
  }) {
    final statusColor = isControlled
        ? (conformityStatus == 'conforme' ? Colors.green : Colors.red)
        : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Première ligne : numéro, ID et statut
          Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.2),
                radius: 16,
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Code: $id',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Type: $type',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isControlled
                          ? (conformityStatus == 'conforme'
                              ? Icons.check_circle
                              : Icons.cancel)
                          : Icons.pending,
                      color: statusColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isControlled
                          ? conformityStatus.toUpperCase()
                          : 'NON CONTRÔLÉ',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Informations détaillées
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                    'Poids', '${weight.toStringAsFixed(1)} kg', Icons.scale),
              ),
              if (hiveType != null)
                Expanded(
                  child: _buildDetailItem('Ruche', hiveType, Icons.home),
                ),
              if (honeyType != null)
                Expanded(
                  child: _buildDetailItem('Miel', honeyType, Icons.water_drop),
                ),
            ],
          ),

          if (price != null || unitPrice != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (unitPrice != null)
                  Expanded(
                    child: _buildDetailItem('Prix/kg',
                        '${unitPrice.toStringAsFixed(0)} €', Icons.euro),
                  ),
                if (price != null)
                  Expanded(
                    child: _buildDetailItem('Total',
                        '${price.toStringAsFixed(0)} FCFA', Icons.text_fields),
                  ),
              ],
            ),
          ],

          if (isControlled) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, color: Colors.grey[600], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Contrôleur: $controller',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 11,
                    ),
                  ),
                ),
                if (controlDate != null) ...[
                  Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(controlDate),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // Méthodes utilitaires
  Section _determineSection(BaseCollecte collecte) {
    if (collecte is Recolte) return Section.recoltes;
    if (collecte is Scoop) return Section.scoop;
    if (collecte is Individuel) return Section.individuel;
    return Section.miellerie;
  }

  IconData _getSectionIcon(Section section) {
    switch (section) {
      case Section.recoltes:
        return Icons.agriculture;
      case Section.scoop:
        return Icons.store;
      case Section.individuel:
        return Icons.person;
      case Section.miellerie:
        return Icons.factory;
    }
  }

  String _getCollecteLocation(BaseCollecte collecte) {
    if (collecte is Recolte) {
      return '${collecte.site} - ${collecte.village ?? "Village non défini"}';
    } else if (collecte is Scoop) {
      return '${collecte.site} - ${collecte.village ?? collecte.localisation ?? "Lieu non défini"}';
    } else if (collecte is Individuel) {
      return '${collecte.site} - ${collecte.village ?? collecte.localisation ?? "Lieu non défini"}';
    }
    return collecte.site;
  }

  Widget _buildDetailedProductsSection(CollecteControlInfo info) {
    if (kDebugMode) {
      print('🎯 [CARD DETAILED] Affichage section produits détaillée');
    }

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
          border: Border.all(color: Colors.orange[300]!, width: 1),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[600],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning_amber,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Aucun Produit Disponible',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.controlledContainers == 0
                        ? 'Les contenants n\'ont pas encore été contrôlés.'
                        : 'Tous les contenants contrôlés sont non conformes.',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Actions recommandées:',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    info.controlledContainers == 0
                        ? '• Effectuer le contrôle qualité des contenants\n• Vérifier la conformité des produits'
                        : '• Revoir les causes de non-conformité\n• Possibilité de retraitement si applicable',
                    style: TextStyle(
                      color: Colors.orange[600],
                      fontSize: 11,
                    ),
                  ),
                ],
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
        border: Border.all(color: Colors.green[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Produits Conformes (${info.conformeCount})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                '${info.poidsConformes.toStringAsFixed(1)} kg',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Répartition par type de produit selon la section
          _buildProductTypeDistribution(info),

          const SizedBox(height: 12),

          // Liste détaillée des produits conformes (limité aux premiers)
          Text(
            'Détail des Produits Conformes',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),

          ...info.produitsConformesDisponibles
              .take(6)
              .map(
                (qualityControl) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green[100]!,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          _getProductIcon(qualityControl.honeyNature),
                          color: Colors.green[700],
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Code: ${qualityControl.containerCode}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        _getQualityColor(qualityControl.quality)
                                            .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    qualityControl.quality,
                                    style: TextStyle(
                                      color: _getQualityColor(
                                          qualityControl.quality),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.scale,
                                    color: Colors.grey[600], size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${qualityControl.totalWeight.toStringAsFixed(1)} kg',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.local_florist,
                                    color: Colors.grey[600], size: 14),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    qualityControl.floralPredominance,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
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
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),

          if (info.produitsConformesDisponibles.length > 6) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  // Afficher tous les produits
                },
                child: Text(
                  'Voir les ${info.produitsConformesDisponibles.length - 6} autres produits',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductTypeDistribution(CollecteControlInfo info) {
    final section = _determineSection(widget.collecte);

    switch (section) {
      case Section.recoltes:
        return _buildProductTypeCard(
          'Produits Bruts',
          'Destinés à l\'extraction',
          info.conformeCount,
          Colors.brown,
          Icons.agriculture,
        );

      case Section.scoop:
        final liquidCount = (info.conformeCount * 0.7).round();
        final cireCount = info.conformeCount - liquidCount;

        return Column(
          children: [
            _buildProductTypeCard(
              'Produits Liquides',
              'Destinés au filtrage',
              liquidCount,
              Colors.blue,
              Icons.water_drop,
            ),
            const SizedBox(height: 8),
            _buildProductTypeCard(
              'Produits Cire',
              'Destinés au traitement',
              cireCount,
              Colors.amber,
              Icons.cake,
            ),
          ],
        );

      case Section.individuel:
      case Section.miellerie:
        return _buildProductTypeCard(
          'Produits Liquides',
          'Destinés au filtrage',
          info.conformeCount,
          Colors.blue,
          Icons.water_drop,
        );
    }
  }

  Widget _buildProductTypeCard(
      String title, String description, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 13,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticSection(CollecteControlInfo info) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[50]!, Colors.purple[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple[600],
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.bug_report, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Diagnostic & Logs',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[800],
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showDebugLogs = !_showDebugLogs;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _showDebugLogs ? 'Masquer' : 'Afficher',
                      style: TextStyle(color: Colors.purple[700]),
                    ),
                    Icon(
                      _showDebugLogs ? Icons.visibility_off : Icons.visibility,
                      color: Colors.purple[700],
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Informations de base toujours visibles
          _buildDiagnosticItem(
              'ID Collecte', info.collecteId, Icons.fingerprint),
          _buildDiagnosticItem(
              'Type', widget.collecte.runtimeType.toString(), Icons.category),
          _buildDiagnosticItem(
              'Dernière MAJ',
              DateFormat('dd/MM/yyyy HH:mm').format(info.lastUpdated),
              Icons.update),
          _buildDiagnosticItem('Contrôles en DB',
              '${info.controlsByContainer.length}', Icons.storage),

          if (_showDebugLogs) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Logs détaillés
            Text(
              'Logs Détaillés',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.purple[700],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLogEntry(
                      'INFO', 'Collecte chargée: ${widget.collecte.id}'),
                  _buildLogEntry(
                      'DEBUG', 'Type: ${widget.collecte.runtimeType}'),
                  _buildLogEntry('DEBUG', 'Site: ${widget.collecte.site}'),
                  _buildLogEntry('DEBUG',
                      'Technicien: ${widget.collecte.technicien ?? "Non défini"}'),
                  _buildLogEntry('STATS',
                      'Total: ${info.totalContainers}, Contrôlés: ${info.controlledContainers}, Conformes: ${info.conformeCount}'),
                  _buildLogEntry('PERF',
                      'Completion: ${(info.completionPercentage * 100).toStringAsFixed(1)}%, Conformité: ${(info.conformityPercentage * 100).toStringAsFixed(1)}%'),
                  if (info.poidsTotal > 0)
                    _buildLogEntry('WEIGHT',
                        'Poids total: ${info.poidsTotal.toStringAsFixed(2)}kg, conformes: ${info.poidsConformes.toStringAsFixed(2)}kg'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiagnosticItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple[600], size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.purple[700],
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.purple[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(String level, String message) {
    final Color levelColor = level == 'INFO'
        ? Colors.green
        : level == 'DEBUG'
            ? Colors.blue
            : level == 'STATS'
                ? Colors.orange
                : level == 'PERF'
                    ? Colors.purple
                    : level == 'WEIGHT'
                        ? Colors.teal
                        : Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
          children: [
            TextSpan(
              text: '[${DateTime.now().toString().substring(11, 19)}] ',
              style: const TextStyle(color: Colors.grey),
            ),
            TextSpan(
              text: '$level ',
              style: TextStyle(color: levelColor, fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: message,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedActionButtons(
      BuildContext context, CollecteControlInfo info) {
    return Column(
      children: [
        // Boutons d'action principaux
        Row(
          children: [
            // Bouton d'attribution
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: info.hasAvailableProducts
                    ? () {
                        if (kDebugMode) {
                          print(
                              '🎯 [CARD DETAILED] Attribution demandée pour ${widget.collecte.id}');
                          print(
                              '   ${info.totalDisponibles} produits disponibles');
                        }

                        // Créer la liste des produits à attribuer
                        final produits = info.produitsConformesDisponibles
                            .map((qc) => ProductControle(
                                  id: '${widget.collecte.id}_${qc.containerCode}',
                                  collecteId: widget.collecte.id,
                                  containerCode: qc.containerCode,
                                  collecteType:
                                      _determineSection(widget.collecte),
                                  localite:
                                      _getCollecteLocation(widget.collecte),
                                  technicien: widget.collecte.technicien ?? '',
                                  dateReception: widget.collecte.date,
                                  productType: _getProductTypeFromSection(
                                      _determineSection(widget.collecte)),
                                  quantity: qc.totalWeight,
                                  qualityControl: qc,
                                  isAttributed: false,
                                ))
                            .toList();

                        widget.onAttributeProducts?.call(produits);
                      }
                    : null,
                icon: Icon(
                  info.hasAvailableProducts
                      ? Icons.assignment_turned_in
                      : Icons.block,
                  size: 20,
                ),
                label: Text(
                  info.hasAvailableProducts
                      ? 'Attribuer (${info.totalDisponibles})'
                      : 'Aucun produit',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: info.hasAvailableProducts
                      ? Colors.green[600]
                      : Colors.grey[400],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
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
                        print(
                            '📋 [CARD DETAILED] Détails demandés pour ${widget.collecte.id}');
                      }
                    },
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('Détails', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                  side: BorderSide(color: Colors.blue[300]!),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Boutons d'action secondaires
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () {
                  // Actualiser les données
                  if (kDebugMode) {
                    print(
                        '🔄 [CARD DETAILED] Actualisation demandée pour ${widget.collecte.id}');
                  }
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Actualiser', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                ),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () {
                  // Exporter les données
                  if (kDebugMode) {
                    print(
                        '📤 [CARD DETAILED] Export demandé pour ${widget.collecte.id}');
                  }
                },
                icon: const Icon(Icons.file_download, size: 16),
                label: const Text('Exporter', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                ),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () {
                  // Afficher l'historique
                  if (kDebugMode) {
                    print(
                        '📜 [CARD DETAILED] Historique demandé pour ${widget.collecte.id}');
                  }
                },
                icon: const Icon(Icons.history, size: 16),
                label: const Text('Historique', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Méthodes utilitaires supplémentaires
  IconData _getProductIcon(HoneyNature nature) {
    switch (nature) {
      case HoneyNature.brut:
        return Icons.agriculture;
      case HoneyNature.prefilitre:
        return Icons.water_drop;
      case HoneyNature.cire:
        return Icons.build;
    }
  }

  Color _getQualityColor(String quality) {
    switch (quality.toLowerCase()) {
      case 'excellent':
      case 'a':
        return Colors.green;
      case 'bon':
      case 'b':
        return Colors.lightGreen;
      case 'moyen':
      case 'c':
        return Colors.orange;
      case 'mauvais':
      case 'd':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  ProductType _getProductTypeFromSection(Section section) {
    switch (section) {
      case Section.recoltes:
        return ProductType.extraction;
      case Section.scoop:
        return ProductType.filtrage;
      case Section.individuel:
        return ProductType.filtrage;
      case Section.miellerie:
        return ProductType.filtrage;
    }
  }
}
