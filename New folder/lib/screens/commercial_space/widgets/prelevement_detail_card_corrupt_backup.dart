import 'package:flutter/material.dart';
import '../../vente/models/vente_models.dart';

class PrelevementDetailCard extends StatelessWidget {
  final Prelevement prelevement;
  final void Function(Prelevement, String) onAction;

  const PrelevementDetailCard({super.key, required this.prelevement, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Prélèvement ${prelevement.id.split('_').last}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: prelevement.produits
                  .take(3)
                  .map((p) => Chip(label: Text(p.typeEmballage)))
                  .toList(),
            ),
            if (prelevement.produits.length > 3)
              Text('+${prelevement.produits.length - 3} autres',
                  style: const TextStyle(fontSize: 11, color: Colors.black54)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => onAction(prelevement, 'vendre'),
                        child: const Text('Vendre'))),
                const SizedBox(width: 8),
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => onAction(prelevement, 'restituer'),
                        child: const Text('Restituer'))),
                const SizedBox(width: 8),
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => onAction(prelevement, 'perte'),
                        child: const Text('Perte'))),
              ],
            )
          ],
        ),
      ),
    );
  }
}

                const SizedBox(width: 8),    return LayoutBuilder(  final Function(Prelevement, String) onAction;          ),

                ElevatedButton(

                  onPressed: () => onAction(prelevement, 'perte'),      builder: (context, constraints) {

                  child: const Text('Perte'),

                ),        final isSmall = constraints.maxWidth < 600;  const PrelevementDetailCard({

              ],

            ),

          ],

        ),        return Container(    super.key,  // Produits restants (quantités ajustées). Si fourni, on les affiche à la place des produits initiaux.

      ),

    );          margin: const EdgeInsets.only(bottom: 16),

  }

}          decoration: BoxDecoration(    required this.prelevement,


            color: Colors.white,

            borderRadius: BorderRadius.circular(20),    required this.onAction,  final List<ProduitPreleve>? produitsRestants;          // Barre de progression si progression fournie

            boxShadow: [

              BoxShadow(    this.produitsRestants,

                color: Colors.black.withOpacity(0.08),

                blurRadius: 15,    this.statutDynamique,  // Statut dynamique calculé (partiel / terminé) prioritaire sur prelevement.statut          if (progression != null) ...[

                offset: const Offset(0, 6),

              ),    this.progression,

            ],

            border: Border.all(  });  final StatutPrelevement? statutDynamique;            const SizedBox(height: 16),

              color: statusColor.withOpacity(0.2),

              width: 1.5,

            ),

          ),  @override  // Progression en pourcentage (0-100)            Container(

          child: Column(

            children: [  Widget build(BuildContext context) {

              _buildHeader(statusColor, statusLabel, isSmall),

              _buildContent(isSmall, produitsAffiches),    final statutEffectif = statutDynamique ?? prelevement.statut;  final double? progression;              padding: const EdgeInsets.all(12),

              if (statutEffectif == StatutPrelevement.enCours ||

                  statutEffectif == StatutPrelevement.partiel)    final statusColor = _getStatusColor(statutEffectif);

                _buildActions(isSmall),

            ],    final statusLabel = _getStatusLabel(statutEffectif);              decoration: BoxDecoration(

          ),

        );

      },

    );    return LayoutBuilder(  const PrelevementDetailCard({                color: Colors.blue.shade50,

  }

      builder: (context, constraints) {

  Widget _buildHeader(Color statusColor, String statusLabel, bool isSmall) {

    return Container(        final isSmall = constraints.maxWidth < 600;    super.key,                borderRadius: BorderRadius.circular(12),

      padding: EdgeInsets.all(isSmall ? 16 : 20),

      decoration: BoxDecoration(

        gradient: LinearGradient(

          colors: [        return Container(    required this.prelevement,                border: Border.all(color: Colors.blue.shade200),

            statusColor.withOpacity(0.1),

            statusColor.withOpacity(0.05),          margin: const EdgeInsets.only(bottom: 16),

          ],

          begin: Alignment.topLeft,          decoration: BoxDecoration(    required this.onAction,              ),

          end: Alignment.bottomRight,

        ),            color: Colors.white,

        borderRadius: const BorderRadius.only(

          topLeft: Radius.circular(20),            borderRadius: BorderRadius.circular(20),    this.produitsRestants,              child: Column(

          topRight: Radius.circular(20),

        ),            boxShadow: [

      ),

      child: Row(              BoxShadow(    this.statutDynamique,                crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Container(                color: Colors.black.withOpacity(0.08),

            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(                blurRadius: 15,    this.progression,                children: [

              color: statusColor.withOpacity(0.15),

              borderRadius: BorderRadius.circular(16),                offset: const Offset(0, 6),

              boxShadow: [

                BoxShadow(              ),  });                  Row(

                  color: statusColor.withOpacity(0.2),

                  blurRadius: 8,            ],

                  offset: const Offset(0, 4),

                ),            border: Border.all(                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

              ],

            ),              color: statusColor.withOpacity(0.2),

            child: Icon(

              Icons.shopping_bag,              width: 1.5,  @override                    children: [

              color: statusColor,

              size: isSmall ? 24 : 28,            ),

            ),

          ),          ),  Widget build(BuildContext context) {                      Text(

          const SizedBox(width: 16),

          Expanded(          child: Column(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,            children: [    final statutEffectif = statutDynamique ?? prelevement.statut;                        'Progression',

              children: [

                Row(              // Header avec statut

                  children: [

                    Expanded(              _buildHeader(statusColor, statusLabel, isSmall),    final statusColor = _getStatusColor(statutEffectif);                        style: TextStyle(

                      child: Text(

                        'Prélèvement ${prelevement.id.split('_').last}',

                        style: TextStyle(

                          fontSize: isSmall ? 16 : 18,              // Contenu principal    final statusLabel = _getStatusLabel(statutEffectif);                          fontSize: 14,

                          fontWeight: FontWeight.bold,

                          color: const Color(0xFF1F2937),              _buildContent(isSmall),

                        ),

                      ),                          fontWeight: FontWeight.bold,

                    ),

                    Container(              // Actions

                      padding: const EdgeInsets.symmetric(

                          horizontal: 12, vertical: 6),              if (statutEffectif == StatutPrelevement.enCours ||    return LayoutBuilder(                          color: Colors.blue.shade800,

                      decoration: BoxDecoration(

                        color: statusColor,                  statutEffectif == StatutPrelevement.partiel)

                        borderRadius: BorderRadius.circular(20),

                        boxShadow: [                _buildActions(isSmall),      builder: (context, constraints) {                        ),

                          BoxShadow(

                            color: statusColor.withOpacity(0.3),            ],

                            blurRadius: 8,

                            offset: const Offset(0, 2),          ),        final isSmall = constraints.maxWidth < 600;                      ),

                          ),

                        ],        );

                      ),

                      child: Text(      },                      Text(

                        statusLabel,

                        style: const TextStyle(    );

                          color: Colors.white,

                          fontWeight: FontWeight.bold,  }        return Container(                        '${progression!.toStringAsFixed(1)}%',

                          fontSize: 12,

                        ),

                      ),

                    ),  Widget _buildHeader(Color statusColor, String statusLabel, bool isSmall) {          margin: const EdgeInsets.only(bottom: 16),                        style: TextStyle(

                  ],

                ),    return Container(

                const SizedBox(height: 6),

                Row(      padding: EdgeInsets.all(isSmall ? 16 : 20),          decoration: BoxDecoration(                          fontSize: 14,

                  children: [

                    Icon(      decoration: BoxDecoration(

                      Icons.access_time,

                      size: 16,        gradient: LinearGradient(            color: Colors.white,                          fontWeight: FontWeight.bold,

                      color: Colors.grey.shade600,

                    ),          colors: [

                    const SizedBox(width: 4),

                    Text(            statusColor.withOpacity(0.1),            borderRadius: BorderRadius.circular(20),                          color: Colors.blue.shade800,

                      DateFormat('dd/MM/yyyy à HH:mm')

                          .format(prelevement.datePrelevement),            statusColor.withOpacity(0.05),

                      style: TextStyle(

                        fontSize: isSmall ? 12 : 14,          ],            boxShadow: [                        ),

                        color: Colors.grey.shade600,

                        fontWeight: FontWeight.w500,          begin: Alignment.topLeft,

                      ),

                    ),          end: Alignment.bottomRight,              BoxShadow(                      ),

                  ],

                ),        ),

                const SizedBox(height: 4),

                Row(        borderRadius: const BorderRadius.only(                color: Colors.black.withOpacity(0.08),                    ],

                  children: [

                    Icon(          topLeft: Radius.circular(20),

                      Icons.person,

                      size: 16,          topRight: Radius.circular(20),                blurRadius: 15,                  ),

                      color: Colors.grey.shade600,

                    ),        ),

                    const SizedBox(width: 4),

                    Text(      ),                offset: const Offset(0, 6),                  const SizedBox(height: 8),

                      'Par ${prelevement.magazinierNom}',

                      style: TextStyle(      child: Row(

                        fontSize: isSmall ? 12 : 14,

                        color: Colors.grey.shade600,        children: [              ),                  LinearProgressIndicator(

                        fontWeight: FontWeight.w500,

                      ),          Container(

                    ),

                  ],            padding: const EdgeInsets.all(12),            ],                    value: progression! / 100,

                ),

              ],            decoration: BoxDecoration(

            ),

          ),              color: statusColor.withOpacity(0.15),            border: Border.all(                    backgroundColor: Colors.blue.shade100,

        ],

      ),              borderRadius: BorderRadius.circular(16),

    );

  }              boxShadow: [              color: statusColor.withOpacity(0.2),                    valueColor: AlwaysStoppedAnimation<Color>(



  Widget _buildContent(bool isSmall, List<ProduitPreleve> produits) {                BoxShadow(

    return Padding(

      padding: EdgeInsets.all(isSmall ? 16 : 20),                  color: statusColor.withOpacity(0.2),              width: 1.5,                      progression! >= 100 

      child: Column(

        children: [                  blurRadius: 8,

          // Statistiques principales

          Row(                  offset: const Offset(0, 4),            ),                        ? Colors.green.shade600

            children: [

              Expanded(                ),

                child: _buildInfoColumn(

                  'Produits',              ],          ),                        : progression! >= 50

                  '${produits.length}',

                  Icons.inventory_2,            ),

                  const Color(0xFF3B82F6),

                  isSmall,            child: Icon(          child: Column(                          ? Colors.orange.shade600  

                ),

              ),              Icons.shopping_bag,

              Container(

                width: 1,              color: statusColor,            children: [                          : Colors.blue.shade600

                height: 50,

                color: Colors.grey.shade200,              size: isSmall ? 24 : 28,

                margin: const EdgeInsets.symmetric(horizontal: 16),

              ),            ),              // Header avec statut                    ),

              Expanded(

                child: _buildInfoColumn(          ),

                  'Valeur Totale',

                  VenteUtils.formatPrix(produits          const SizedBox(width: 16),              _buildHeader(statusColor, statusLabel, isSmall),                    minHeight: 6,

                      .fold<double>(0, (sum, p) => sum + p.valeurTotale)),

                  Icons.monetization_on,          Expanded(

                  const Color(0xFF10B981),

                  isSmall,            child: Column(                  ),

                ),

              ),              crossAxisAlignment: CrossAxisAlignment.start,

              Container(

                width: 1,              children: [              // Contenu principal                ],

                height: 50,

                color: Colors.grey.shade200,                Row(

                margin: const EdgeInsets.symmetric(horizontal: 16),

              ),                  children: [              _buildContent(isSmall),              ),

              Expanded(

                child: _buildInfoColumn(                    Expanded(

                  'Quantité',

                  '${produits.fold<int>(0, (sum, p) => sum + p.quantitePreleve)}',                      child: Text(            ),

                  Icons.scale,

                  const Color(0xFFF59E0B),                        'Prélèvement ${prelevement.id.split('_').last}',

                  isSmall,

                ),                        style: TextStyle(              // Actions          ],

              ),

            ],                          fontSize: isSmall ? 16 : 18,

          ),

                          fontWeight: FontWeight.bold,              if (statutEffectif == StatutPrelevement.enCours ||

          // Barre de progression si progression fournie

          if (progression != null) ...[                          color: const Color(0xFF1F2937),

            const SizedBox(height: 16),

            Container(                        ),                  statutEffectif == StatutPrelevement.partiel)          // Aperçu des produitsfinal Function(Prelevement, String) onAction;

              padding: const EdgeInsets.all(12),

              decoration: BoxDecoration(                      ),

                color: Colors.blue.shade50,

                borderRadius: BorderRadius.circular(12),                    ),                _buildActions(isSmall),  // Produits restants (quantités ajustées). Si fourni, on les affiche à la place des produits initiaux.

                border: Border.all(color: Colors.blue.shade200),

              ),                    Container(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,                      padding: const EdgeInsets.symmetric(            ],  final List<ProduitPreleve>? produitsRestants;

                children: [

                  Row(                          horizontal: 12, vertical: 6),

                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [                      decoration: BoxDecoration(          ),  // Statut dynamique calculé (partiel / terminé) prioritaire sur prelevement.statut

                      Text(

                        'Progression',                        color: statusColor,

                        style: TextStyle(

                          fontSize: 14,                        borderRadius: BorderRadius.circular(20),        );  final StatutPrelevement? statutDynamique;

                          fontWeight: FontWeight.bold,

                          color: Colors.blue.shade800,                        boxShadow: [

                        ),

                      ),                          BoxShadow(      },  // Progression en pourcentage (0-100)

                      Text(

                        '${progression!.toStringAsFixed(1)}%',                            color: statusColor.withOpacity(0.3),

                        style: TextStyle(

                          fontSize: 14,                            blurRadius: 8,    );  final double? progression;

                          fontWeight: FontWeight.bold,

                          color: Colors.blue.shade800,                            offset: const Offset(0, 2),

                        ),

                      ),                          ),  }

                    ],

                  ),                        ],

                  const SizedBox(height: 8),

                  LinearProgressIndicator(                      ),  const PrelevementDetailCard({

                    value: progression! / 100,

                    backgroundColor: Colors.blue.shade100,                      child: Text(

                    valueColor: AlwaysStoppedAnimation<Color>(

                        progression! >= 100                        statusLabel,  Widget _buildHeader(Color statusColor, String statusLabel, bool isSmall) {    super.key,

                            ? Colors.green.shade600

                            : progression! >= 50                        style: const TextStyle(

                                ? Colors.orange.shade600

                                : Colors.blue.shade600),                          color: Colors.white,    return Container(    required this.prelevement,

                    minHeight: 6,

                  ),                          fontWeight: FontWeight.bold,

                ],

              ),                          fontSize: 12,      padding: EdgeInsets.all(isSmall ? 16 : 20),    required this.onAction,

            ),

          ],                        ),



          // Aperçu des produits                      ),      decoration: BoxDecoration(    this.produitsRestants,

          const SizedBox(height: 20),

          Container(                    ),

            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(                  ],        gradient: LinearGradient(    this.statutDynamique,

              color: Colors.grey.shade50,

              borderRadius: BorderRadius.circular(16),                ),

              border: Border.all(color: Colors.grey.shade200),

            ),                const SizedBox(height: 6),          colors: [    this.progression,

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,                Row(

              children: [

                Row(                  children: [            statusColor.withOpacity(0.1),  });

                  children: [

                    Icon(Icons.list_alt, size: 18, color: Colors.grey.shade700),                    Icon(

                    const SizedBox(width: 8),

                    Text(                      Icons.access_time,            statusColor.withOpacity(0.05),

                      'Aperçu des produits',

                      style: TextStyle(                      size: 16,

                        fontSize: 14,

                        fontWeight: FontWeight.bold,                      color: Colors.grey.shade600,          ],  @override

                        color: Colors.grey.shade700,

                      ),                    ),

                    ),

                    const Spacer(),                    const SizedBox(width: 4),          begin: Alignment.topLeft,  Widget build(BuildContext context) {

                    GestureDetector(

                      onTap: () => onAction(prelevement, 'details'),                    Text(

                      child: Text(

                        'Voir tout',                      DateFormat('dd/MM/yyyy à HH:mm')          end: Alignment.bottomRight,  final statutEffectif = statutDynamique ?? prelevement.statut;

                        style: TextStyle(

                          fontSize: 12,                          .format(prelevement.datePrelevement),

                          color: Colors.blue.shade600,

                          fontWeight: FontWeight.w600,                      style: TextStyle(        ),  final statusColor = _getStatusColor(statutEffectif);

                        ),

                      ),                        fontSize: isSmall ? 12 : 14,

                    ),

                  ],                        color: Colors.grey.shade600,        borderRadius: const BorderRadius.only(  final statusLabel = _getStatusLabel(statutEffectif);

                ),

                const SizedBox(height: 12),                        fontWeight: FontWeight.w500,

                ...produits

                    .take(3)                      ),          topLeft: Radius.circular(20),

                    .map((produit) => Container(

                          margin: const EdgeInsets.only(bottom: 8),                    ),

                          child: Row(

                            children: [                  ],          topRight: Radius.circular(20),    return LayoutBuilder(

                              Container(

                                width: 8,                ),

                                height: 8,

                                decoration: BoxDecoration(                const SizedBox(height: 4),        ),      builder: (context, constraints) {

                                  color: Colors.blue.shade400,

                                  borderRadius: BorderRadius.circular(4),                Row(

                                ),

                              ),                  children: [      ),        final isSmall = constraints.maxWidth < 600;

                              const SizedBox(width: 12),

                              Expanded(                    Icon(

                                child: Text(

                                  '${produit.typeEmballage} (${produit.quantitePreleve})',                      Icons.person,      child: Row(

                                  style: const TextStyle(fontSize: 13),

                                ),                      size: 16,

                              ),

                              Text(                      color: Colors.grey.shade600,        children: [        return Container(

                                VenteUtils.formatPrix(produit.prixUnitaire *

                                    produit.quantitePreleve),                    ),

                                style: const TextStyle(

                                  fontSize: 13,                    const SizedBox(width: 4),          Container(          margin: const EdgeInsets.only(bottom: 16),

                                  fontWeight: FontWeight.w600,

                                ),                    Text(

                              ),

                            ],                      'Par ${prelevement.magazinierNom}',            padding: const EdgeInsets.all(12),          decoration: BoxDecoration(

                          ),

                        ))                      style: TextStyle(

                    .toList(),

                if (produits.length > 3)                        fontSize: isSmall ? 12 : 14,            decoration: BoxDecoration(            color: Colors.white,

                  Text(

                    '... et ${produits.length - 3} autre${produits.length - 3 > 1 ? 's' : ''} produit${produits.length - 3 > 1 ? 's' : ''}',                        color: Colors.grey.shade600,

                    style: TextStyle(

                      fontSize: 12,                        fontWeight: FontWeight.w500,              color: statusColor.withOpacity(0.15),            borderRadius: BorderRadius.circular(20),

                      color: Colors.grey.shade600,

                      fontStyle: FontStyle.italic,                      ),

                    ),

                  ),                    ),              borderRadius: BorderRadius.circular(16),            boxShadow: [

              ],

            ),                  ],

          ),

                ),              boxShadow: [              BoxShadow(

          // Observations si présentes

          if (prelevement.observations != null &&              ],

              prelevement.observations!.isNotEmpty) ...[

            const SizedBox(height: 16),            ),                BoxShadow(                color: Colors.black.withOpacity(0.08),

            Container(

              width: double.infinity,          ),

              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(        ],                  color: statusColor.withOpacity(0.2),                blurRadius: 15,

                color: Colors.amber.shade50,

                borderRadius: BorderRadius.circular(12),      ),

                border: Border.all(color: Colors.amber.shade200),

              ),    );                  blurRadius: 8,                offset: const Offset(0, 6),

              child: Row(

                crossAxisAlignment: CrossAxisAlignment.start,  }

                children: [

                  Icon(Icons.info_outline,                  offset: const Offset(0, 4),              ),

                      color: Colors.amber.shade700, size: 20),

                  const SizedBox(width: 12),  Widget _buildContent(bool isSmall) {

                  Expanded(

                    child: Column(    return Padding(                ),            ],

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [      padding: EdgeInsets.all(isSmall ? 16 : 20),

                        Text(

                          'Observations',      child: Column(              ],            border: Border.all(

                          style: TextStyle(

                            fontWeight: FontWeight.bold,        children: [

                            color: Colors.amber.shade800,

                            fontSize: 14,          // Statistiques principales            ),              color: statusColor.withOpacity(0.2),

                          ),

                        ),          Row(

                        const SizedBox(height: 4),

                        Text(            children: [            child: Icon(              width: 1.5,

                          prelevement.observations!,

                          style: TextStyle(              Expanded(

                            color: Colors.amber.shade700,

                            fontSize: 13,                child: _buildInfoColumn(              Icons.shopping_bag,            ),

                          ),

                        ),                  'Produits',

                      ],

                    ),                  '${(produitsRestants ?? prelevement.produits).length}',              color: statusColor,          ),

                  ),

                ],                  Icons.inventory_2,

              ),

            ),                  const Color(0xFF3B82F6),              size: isSmall ? 24 : 28,          child: Column(

          ],

        ],                  isSmall,

      ),

    );                ),            ),            children: [

  }

              ),

  Widget _buildActions(bool isSmall) {

    return Container(              Container(          ),              // Header avec statut

      padding: EdgeInsets.all(isSmall ? 16 : 20),

      decoration: BoxDecoration(                width: 1,

        color: Colors.grey.shade50,

        borderRadius: const BorderRadius.only(                height: 50,          const SizedBox(width: 16),              _buildHeader(statusColor, statusLabel, isSmall),

          bottomLeft: Radius.circular(20),

          bottomRight: Radius.circular(20),                color: Colors.grey.shade200,

        ),

      ),                margin: const EdgeInsets.symmetric(horizontal: 16),          Expanded(

      child: isSmall

          ? Column(              ),

              children: [

                Row(              Expanded(            child: Column(              // Contenu principal

                  children: [

                    Expanded(                child: _buildInfoColumn(

                        child: _buildActionButton('Vendre', Icons.point_of_sale,

                            const Color(0xFF10B981), 'vendre')),                  'Valeur Totale',              crossAxisAlignment: CrossAxisAlignment.start,              _buildContent(isSmall),

                    const SizedBox(width: 8),

                    Expanded(                  VenteUtils.formatPrix((produitsRestants ?? prelevement.produits)

                        child: _buildActionButton('Restituer', Icons.undo,

                            const Color(0xFFF59E0B), 'restituer')),                      .fold<double>(0, (sum, p) => sum + p.valeurTotale)),              children: [

                  ],

                ),                  Icons.monetization_on,

                const SizedBox(height: 8),

                SizedBox(                  const Color(0xFF10B981),                Row(              // Actions

                  width: double.infinity,

                  child: _buildActionButton('Déclarer Perte', Icons.warning,                  isSmall,

                      const Color(0xFFEF4444), 'perte'),

                ),                ),                  children: [              if (statutEffectif == StatutPrelevement.enCours ||

              ],

            )              ),

          : Row(

              children: [              Container(                    Expanded(                  statutEffectif == StatutPrelevement.partiel)

                Expanded(

                    child: _buildActionButton('Vendre', Icons.point_of_sale,                width: 1,

                        const Color(0xFF10B981), 'vendre')),

                const SizedBox(width: 12),                height: 50,                      child: Text(                _buildActions(isSmall),

                Expanded(

                    child: _buildActionButton('Restituer', Icons.undo,                color: Colors.grey.shade200,

                        const Color(0xFFF59E0B), 'restituer')),

                const SizedBox(width: 12),                margin: const EdgeInsets.symmetric(horizontal: 16),                        'Prélèvement ${prelevement.id.split('_').last}',            ],

                Expanded(

                    child: _buildActionButton('Déclarer Perte', Icons.warning,              ),

                        const Color(0xFFEF4444), 'perte')),

              ],              Expanded(                        style: TextStyle(          ),

            ),

    );                child: _buildInfoColumn(

  }

                  'Quantité',                          fontSize: isSmall ? 16 : 18,        );

  Widget _buildActionButton(

      String label, IconData icon, Color color, String action) {                  '${(produitsRestants ?? prelevement.produits).fold<int>(0, (sum, p) => sum + p.quantitePreleve)}',

    return ElevatedButton.icon(

      onPressed: () => onAction(prelevement, action),                  Icons.scale,                          fontWeight: FontWeight.bold,      },

      icon: Icon(icon, size: 18),

      label: Text(                  const Color(0xFFF59E0B),

        label,

        style: const TextStyle(fontWeight: FontWeight.w600),                  isSmall,                          color: const Color(0xFF1F2937),    );

      ),

      style: ElevatedButton.styleFrom(                ),

        backgroundColor: color,

        foregroundColor: Colors.white,              ),                        ),  }

        padding: const EdgeInsets.symmetric(vertical: 12),

        shape: RoundedRectangleBorder(            ],

          borderRadius: BorderRadius.circular(12),

        ),          ),                      ),

        elevation: 3,

        shadowColor: color.withOpacity(0.3),

      ),

    );          // Barre de progression si progression fournie                    ),  Widget _buildHeader(Color statusColor, String statusLabel, bool isSmall) {

  }

          if (progression != null) ...[

  Widget _buildInfoColumn(

      String label, String value, IconData icon, Color color, bool isSmall) {            const SizedBox(height: 16),                    Container(    return Container(

    return Column(

      children: [            Container(

        Icon(icon, color: color, size: isSmall ? 24 : 28),

        const SizedBox(height: 8),              padding: const EdgeInsets.all(12),                      padding: const EdgeInsets.symmetric(      padding: EdgeInsets.all(isSmall ? 16 : 20),

        Text(

          value,              decoration: BoxDecoration(

          style: TextStyle(

            fontSize: isSmall ? 16 : 18,                color: Colors.blue.shade50,                          horizontal: 12, vertical: 6),      decoration: BoxDecoration(

            fontWeight: FontWeight.bold,

            color: const Color(0xFF1F2937),                borderRadius: BorderRadius.circular(12),

          ),

          textAlign: TextAlign.center,                border: Border.all(color: Colors.blue.shade200),                      decoration: BoxDecoration(        gradient: LinearGradient(

        ),

        const SizedBox(height: 4),              ),

        Text(

          label,              child: Column(                        color: statusColor,          colors: [

          style: TextStyle(

            fontSize: isSmall ? 11 : 12,                crossAxisAlignment: CrossAxisAlignment.start,

            color: Colors.grey.shade600,

            fontWeight: FontWeight.w500,                children: [                        borderRadius: BorderRadius.circular(20),            statusColor.withOpacity(0.1),

          ),

          textAlign: TextAlign.center,                  Row(

        ),

      ],                    mainAxisAlignment: MainAxisAlignment.spaceBetween,                        boxShadow: [            statusColor.withOpacity(0.05),

    );

  }                    children: [



  Color _getStatusColor(StatutPrelevement statut) {                      Text(                          BoxShadow(          ],

    switch (statut) {

      case StatutPrelevement.enCours:                        'Progression',

        return const Color(0xFF3B82F6);

      case StatutPrelevement.partiel:                        style: TextStyle(                            color: statusColor.withOpacity(0.3),          begin: Alignment.topLeft,

        return const Color(0xFFF59E0B);

      case StatutPrelevement.termine:                          fontSize: 14,

        return const Color(0xFF10B981);

      case StatutPrelevement.annule:                          fontWeight: FontWeight.bold,                            blurRadius: 8,          end: Alignment.bottomRight,

        return const Color(0xFFEF4444);

    }                          color: Colors.blue.shade800,

  }

                        ),                            offset: const Offset(0, 2),        ),

  String _getStatusLabel(StatutPrelevement statut) {

    switch (statut) {                      ),

      case StatutPrelevement.enCours:

        return 'En cours';                      Text(                          ),        borderRadius: const BorderRadius.only(

      case StatutPrelevement.partiel:

        return 'Partiel';                        '${progression!.toStringAsFixed(1)}%',

      case StatutPrelevement.termine:

        return 'Terminé';                        style: TextStyle(                        ],          topLeft: Radius.circular(20),

      case StatutPrelevement.annule:

        return 'Annulé';                          fontSize: 14,

    }

  }                          fontWeight: FontWeight.bold,                      ),          topRight: Radius.circular(20),

}
                          color: Colors.blue.shade800,

                        ),                      child: Text(        ),

                      ),

                    ],                        statusLabel,      ),

                  ),

                  const SizedBox(height: 8),                        style: const TextStyle(      child: Row(

                  LinearProgressIndicator(

                    value: progression! / 100,                          color: Colors.white,        children: [

                    backgroundColor: Colors.blue.shade100,

                    valueColor: AlwaysStoppedAnimation<Color>(                          fontWeight: FontWeight.bold,          Container(

                      progression! >= 100 

                        ? Colors.green.shade600                          fontSize: 12,            padding: const EdgeInsets.all(12),

                        : progression! >= 50

                          ? Colors.orange.shade600                          ),            decoration: BoxDecoration(

                          : Colors.blue.shade600

                    ),                      ),              color: statusColor.withOpacity(0.15),

                    minHeight: 6,

                  ),                    ),              borderRadius: BorderRadius.circular(16),

                ],

              ),                  ],              boxShadow: [

            ),

          ],                ),                BoxShadow(



          // Aperçu des produits                const SizedBox(height: 6),                  color: statusColor.withOpacity(0.2),

          const SizedBox(height: 20),

          Container(                Row(                  blurRadius: 8,

            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(                  children: [                  offset: const Offset(0, 4),

              color: Colors.grey.shade50,

              borderRadius: BorderRadius.circular(16),                    Icon(                ),

              border: Border.all(color: Colors.grey.shade200),

            ),                      Icons.access_time,              ],

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,                      size: 16,            ),

              children: [

                Row(                      color: Colors.grey.shade600,            child: Icon(

                  children: [

                    Icon(Icons.list_alt, size: 18, color: Colors.grey.shade700),                    ),              Icons.shopping_bag,

                    const SizedBox(width: 8),

                    Text(                    const SizedBox(width: 4),              color: statusColor,

                      'Aperçu des produits',

                      style: TextStyle(                    Text(              size: isSmall ? 24 : 28,

                        fontSize: 14,

                        fontWeight: FontWeight.bold,                      DateFormat('dd/MM/yyyy à HH:mm')            ),

                        color: Colors.grey.shade700,

                      ),                          .format(prelevement.datePrelevement),          ),

                    ),

                    const Spacer(),                      style: TextStyle(          const SizedBox(width: 16),

                    GestureDetector(

                      onTap: () => onAction(prelevement, 'details'),                        fontSize: isSmall ? 12 : 14,          Expanded(

                      child: Text(

                        'Voir tout',                        color: Colors.grey.shade600,            child: Column(

                        style: TextStyle(

                          fontSize: 12,                        fontWeight: FontWeight.w500,              crossAxisAlignment: CrossAxisAlignment.start,

                          color: Colors.blue.shade600,

                          fontWeight: FontWeight.w600,                      ),              children: [

                        ),

                      ),                    ),                Row(

                    ),

                  ],                  ],                  children: [

                ),

                const SizedBox(height: 12),                ),                    Expanded(

                ...(produitsRestants ?? prelevement.produits)

                    .take(3)                const SizedBox(height: 4),                      child: Text(

                    .map((produit) => Container(

                          margin: const EdgeInsets.only(bottom: 8),                Row(                        'Prélèvement ${prelevement.id.split('_').last}',

                          child: Row(

                            children: [                  children: [                        style: TextStyle(

                              Container(

                                width: 8,                    Icon(                          fontSize: isSmall ? 16 : 18,

                                height: 8,

                                decoration: BoxDecoration(                      Icons.person,                          fontWeight: FontWeight.bold,

                                  color: Colors.blue.shade400,

                                  borderRadius: BorderRadius.circular(4),                      size: 16,                          color: const Color(0xFF1F2937),

                                ),

                              ),                      color: Colors.grey.shade600,                        ),

                              const SizedBox(width: 12),

                              Expanded(                    ),                      ),

                                child: Text(

                                  '${produit.typeEmballage} (${produit.quantitePreleve})',                    const SizedBox(width: 4),                    ),

                                  style: const TextStyle(fontSize: 13),

                                ),                    Text(                    Container(

                              ),

                              Text(                      'Par ${prelevement.magazinierNom}',                      padding: const EdgeInsets.symmetric(

                                VenteUtils.formatPrix(produit.prixUnitaire *

                                    produit.quantitePreleve),                      style: TextStyle(                          horizontal: 12, vertical: 6),

                                style: const TextStyle(

                                  fontSize: 13,                        fontSize: isSmall ? 12 : 14,                      decoration: BoxDecoration(

                                  fontWeight: FontWeight.w600,

                                ),                        color: Colors.grey.shade600,                        color: statusColor,

                              ),

                            ],                        fontWeight: FontWeight.w500,                        borderRadius: BorderRadius.circular(20),

                          ),

                        ))                      ),                        boxShadow: [

                    .toList(),

                if ((produitsRestants ?? prelevement.produits).length > 3)                    ),                          BoxShadow(

                  Text(

                    '... et ${(produitsRestants ?? prelevement.produits).length - 3} autre${(produitsRestants ?? prelevement.produits).length - 3 > 1 ? 's' : ''} produit${(produitsRestants ?? prelevement.produits).length - 3 > 1 ? 's' : ''}',                  ],                            color: statusColor.withOpacity(0.3),

                    style: TextStyle(

                      fontSize: 12,                ),                            blurRadius: 8,

                      color: Colors.grey.shade600,

                      fontStyle: FontStyle.italic,              ],                            offset: const Offset(0, 2),

                    ),

                  ),            ),                          ),

              ],

            ),          ),                        ],

          ),

        ],                      ),

          // Observations si présentes

          if (prelevement.observations != null &&      ),                      child: Text(

              prelevement.observations!.isNotEmpty) ...[

            const SizedBox(height: 16),    );                        statusLabel,

            Container(

              width: double.infinity,  }                        style: const TextStyle(

              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(                          color: Colors.white,

                color: Colors.amber.shade50,

                borderRadius: BorderRadius.circular(12),  Widget _buildContent(bool isSmall) {                          fontWeight: FontWeight.bold,

                border: Border.all(color: Colors.amber.shade200),

              ),    return Padding(                          fontSize: 12,

              child: Row(

                crossAxisAlignment: CrossAxisAlignment.start,      padding: EdgeInsets.all(isSmall ? 16 : 20),                        ),

                children: [

                  Icon(Icons.info_outline,      child: Column(                      ),

                      color: Colors.amber.shade700, size: 20),

                  const SizedBox(width: 12),        children: [                    ),

                  Expanded(

                    child: Column(          // Statistiques principales                  ],

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [          Row(                ),

                        Text(

                          'Observations',            children: [                const SizedBox(height: 6),

                          style: TextStyle(

                            fontWeight: FontWeight.bold,              Expanded(                Row(

                            color: Colors.amber.shade800,

                            fontSize: 14,                child: _buildInfoColumn(                  children: [

                          ),

                        ),                  'Produits',                    Icon(

                        const SizedBox(height: 4),

                        Text(                  '${(produitsRestants ?? prelevement.produits).length}',                      Icons.access_time,

                          prelevement.observations!,

                          style: TextStyle(                  Icons.inventory_2,                      size: 16,

                            color: Colors.amber.shade700,

                            fontSize: 13,                  const Color(0xFF3B82F6),                      color: Colors.grey.shade600,

                          ),

                        ),                  isSmall,                    ),

                      ],

                    ),                ),                    const SizedBox(width: 4),

                  ),

                ],              ),                    Text(

              ),

            ),              Container(                      DateFormat('dd/MM/yyyy à HH:mm')

          ],

        ],                width: 1,                          .format(prelevement.datePrelevement),

      ),

    );                height: 50,                      style: TextStyle(

  }

                color: Colors.grey.shade200,                        fontSize: isSmall ? 12 : 14,

  Widget _buildActions(bool isSmall) {

    return Container(                margin: const EdgeInsets.symmetric(horizontal: 16),                        color: Colors.grey.shade600,

      padding: EdgeInsets.all(isSmall ? 16 : 20),

      decoration: BoxDecoration(              ),                        fontWeight: FontWeight.w500,

        color: Colors.grey.shade50,

        borderRadius: const BorderRadius.only(              Expanded(                      ),

          bottomLeft: Radius.circular(20),

          bottomRight: Radius.circular(20),                child: _buildInfoColumn(                    ),

        ),

      ),                  'Valeur Totale',                  ],

      child: isSmall

          ? Column(                  VenteUtils.formatPrix((produitsRestants ?? prelevement.produits)                ),

              children: [

                Row(                      .fold<double>(0, (sum, p) => sum + p.valeurTotale)),                const SizedBox(height: 4),

                  children: [

                    Expanded(                  Icons.monetization_on,                Row(

                        child: _buildActionButton('Vendre', Icons.point_of_sale,

                            const Color(0xFF10B981), 'vendre')),                  const Color(0xFF10B981),                  children: [

                    const SizedBox(width: 8),

                    Expanded(                  isSmall,                    Icon(

                        child: _buildActionButton('Restituer', Icons.undo,

                            const Color(0xFFF59E0B), 'restituer')),                ),                      Icons.person,

                  ],

                ),              ),                      size: 16,

                const SizedBox(height: 8),

                SizedBox(              Container(                      color: Colors.grey.shade600,

                  width: double.infinity,

                  child: _buildActionButton('Déclarer Perte', Icons.warning,                width: 1,                    ),

                      const Color(0xFFEF4444), 'perte'),

                ),                height: 50,                    const SizedBox(width: 4),

              ],

            )                color: Colors.grey.shade200,                    Text(

          : Row(

              children: [                margin: const EdgeInsets.symmetric(horizontal: 16),                      'Par ${prelevement.magazinierNom}',

                Expanded(

                    child: _buildActionButton('Vendre', Icons.point_of_sale,              ),                      style: TextStyle(

                        const Color(0xFF10B981), 'vendre')),

                const SizedBox(width: 12),              Expanded(                        fontSize: isSmall ? 12 : 14,

                Expanded(

                    child: _buildActionButton('Restituer', Icons.undo,                child: _buildInfoColumn(                        color: Colors.grey.shade600,

                        const Color(0xFFF59E0B), 'restituer')),

                const SizedBox(width: 12),                  'Quantité',                        fontWeight: FontWeight.w500,

                Expanded(

                    child: _buildActionButton('Déclarer Perte', Icons.warning,                  '${(produitsRestants ?? prelevement.produits).fold<int>(0, (sum, p) => sum + p.quantitePreleve)}',                      ),

                        const Color(0xFFEF4444), 'perte')),

              ],                  Icons.scale,                    ),

            ),

    );                  const Color(0xFFF59E0B),                  ],

  }

                  isSmall,                ),

  Widget _buildActionButton(

      String label, IconData icon, Color color, String action) {                ),              ],

    return ElevatedButton.icon(

      onPressed: () => onAction(prelevement, action),              ),            ),

      icon: Icon(icon, size: 18),

      label: Text(            ],          ),

        label,

        style: const TextStyle(fontWeight: FontWeight.w600),          ),        ],

      ),

      style: ElevatedButton.styleFrom(      ),

        backgroundColor: color,

        foregroundColor: Colors.white,          // Barre de progression si progression fournie    );

        padding: const EdgeInsets.symmetric(vertical: 12),

        shape: RoundedRectangleBorder(          if (progression != null) ...[  }

          borderRadius: BorderRadius.circular(12),

        ),            const SizedBox(height: 16),

        elevation: 3,

        shadowColor: color.withOpacity(0.3),            Container(  Widget _buildContent(bool isSmall) {

      ),

    );              padding: const EdgeInsets.all(12),    return Padding(

  }

              decoration: BoxDecoration(      padding: EdgeInsets.all(isSmall ? 16 : 20),

  Widget _buildInfoColumn(

      String label, String value, IconData icon, Color color, bool isSmall) {                color: Colors.blue.shade50,      child: Column(

    return Column(

      children: [                borderRadius: BorderRadius.circular(12),        children: [

        Icon(icon, color: color, size: isSmall ? 24 : 28),

        const SizedBox(height: 8),                border: Border.all(color: Colors.blue.shade200),          // Statistiques principales

        Text(

          value,              ),          Row(

          style: TextStyle(

            fontSize: isSmall ? 16 : 18,              child: Column(            children: [

            fontWeight: FontWeight.bold,

            color: const Color(0xFF1F2937),                crossAxisAlignment: CrossAxisAlignment.start,              Expanded(

          ),

          textAlign: TextAlign.center,                children: [                child: _buildInfoColumn(

        ),

        const SizedBox(height: 4),                  Row(                  'Produits',

        Text(

          label,                    mainAxisAlignment: MainAxisAlignment.spaceBetween,                  '${prelevement.produits.length}',

          style: TextStyle(

            fontSize: isSmall ? 11 : 12,                    children: [                  Icons.inventory_2,

            color: Colors.grey.shade600,

            fontWeight: FontWeight.w500,                      Text(                  const Color(0xFF3B82F6),

          ),

          textAlign: TextAlign.center,                        'Progression',                  isSmall,

        ),

      ],                        style: TextStyle(                ),

    );

  }                          fontSize: 14,              ),



  Color _getStatusColor(StatutPrelevement statut) {                          fontWeight: FontWeight.bold,              Container(

    switch (statut) {

      case StatutPrelevement.enCours:                          color: Colors.blue.shade800,                width: 1,

        return const Color(0xFF3B82F6);

      case StatutPrelevement.partiel:                        ),                height: 50,

        return const Color(0xFFF59E0B);

      case StatutPrelevement.termine:                      ),                color: Colors.grey.shade200,

        return const Color(0xFF10B981);

      case StatutPrelevement.annule:                      Text(                margin: const EdgeInsets.symmetric(horizontal: 16),

        return const Color(0xFFEF4444);

    }                        '${progression!.toStringAsFixed(1)}%',              ),

  }

                        style: TextStyle(              Expanded(

  String _getStatusLabel(StatutPrelevement statut) {

    switch (statut) {                          fontSize: 14,                child: _buildInfoColumn(

      case StatutPrelevement.enCours:

        return 'En cours';                          fontWeight: FontWeight.bold,                  'Valeur Totale',

      case StatutPrelevement.partiel:

        return 'Partiel';                          color: Colors.blue.shade800,                  VenteUtils.formatPrix(prelevement.valeurTotale),

      case StatutPrelevement.termine:

        return 'Terminé';                        ),                  Icons.monetization_on,

      case StatutPrelevement.annule:

        return 'Annulé';                      ),                  const Color(0xFF10B981),

    }

  }                    ],                  isSmall,

}
                  ),                ),

                  const SizedBox(height: 8),              ),

                  LinearProgressIndicator(              Container(

                    value: progression! / 100,                width: 1,

                    backgroundColor: Colors.blue.shade100,                height: 50,

                    valueColor: AlwaysStoppedAnimation<Color>(                color: Colors.grey.shade200,

                      progression! >= 100                 margin: const EdgeInsets.symmetric(horizontal: 16),

                        ? Colors.green.shade600              ),

                        : progression! >= 50              Expanded(

                          ? Colors.orange.shade600                  child: _buildInfoColumn(

                          : Colors.blue.shade600                  'Quantité',

                    ),                  '${prelevement.produits.fold<int>(0, (sum, p) => sum + p.quantitePreleve)}',

                    minHeight: 6,                  Icons.scale,

                  ),                  const Color(0xFFF59E0B),

                ],                  isSmall,

              ),                ),

            ),              ),

          ],            ],

          ),

          // Aperçu des produits

          const SizedBox(height: 20),          // Aperçu des produits

          Container(          const SizedBox(height: 20),

            padding: const EdgeInsets.all(16),          Container(

            decoration: BoxDecoration(            padding: const EdgeInsets.all(16),

              color: Colors.grey.shade50,            decoration: BoxDecoration(

              borderRadius: BorderRadius.circular(16),              color: Colors.grey.shade50,

              border: Border.all(color: Colors.grey.shade200),              borderRadius: BorderRadius.circular(16),

            ),              border: Border.all(color: Colors.grey.shade200),

            child: Column(            ),

              crossAxisAlignment: CrossAxisAlignment.start,            child: Column(

              children: [              crossAxisAlignment: CrossAxisAlignment.start,

                Row(              children: [

                  children: [                Row(

                    Icon(Icons.list_alt, size: 18, color: Colors.grey.shade700),                  children: [

                    const SizedBox(width: 8),                    Icon(Icons.list_alt, size: 18, color: Colors.grey.shade700),

                    Text(                    const SizedBox(width: 8),

                      'Aperçu des produits',                    Text(

                      style: TextStyle(                      'Aperçu des produits',

                        fontSize: 14,                      style: TextStyle(

                        fontWeight: FontWeight.bold,                        fontSize: 14,

                        color: Colors.grey.shade700,                        fontWeight: FontWeight.bold,

                      ),                        color: Colors.grey.shade700,

                    ),                      ),

                    const Spacer(),                    ),

                    GestureDetector(                    const Spacer(),

                      onTap: () => onAction(prelevement, 'details'),                    GestureDetector(

                      child: Text(                      onTap: () => onAction(prelevement, 'details'),

                        'Voir tout',                      child: Text(

                        style: TextStyle(                        'Voir tout',

                          fontSize: 12,                        style: TextStyle(

                          color: Colors.blue.shade600,                          fontSize: 12,

                          fontWeight: FontWeight.w600,                          color: Colors.blue.shade600,

                        ),                          fontWeight: FontWeight.w600,

                      ),                        ),

                    ),                      ),

                  ],                    ),

                ),                  ],

                const SizedBox(height: 12),                ),

                ...(produitsRestants ?? prelevement.produits)                const SizedBox(height: 12),

                    .take(3)        ...(produitsRestants ?? prelevement.produits)

                    .map((produit) => Container(          .take(3)

                          margin: const EdgeInsets.only(bottom: 8),                    .map((produit) => Container(

                          child: Row(                          margin: const EdgeInsets.only(bottom: 8),

                            children: [                          child: Row(

                              Container(                            children: [

                                width: 8,                              Container(

                                height: 8,                                width: 8,

                                decoration: BoxDecoration(                                height: 8,

                                  color: Colors.blue.shade400,                                decoration: BoxDecoration(

                                  borderRadius: BorderRadius.circular(4),                                  color: Colors.blue.shade400,

                                ),                                  borderRadius: BorderRadius.circular(4),

                              ),                                ),

                              const SizedBox(width: 12),                              ),

                              Expanded(                              const SizedBox(width: 12),

                                child: Text(                              Expanded(

                                  '${produit.typeEmballage} (${produit.quantitePreleve})',                                child: Text(

                                  style: const TextStyle(fontSize: 13),                                  '${produit.typeEmballage} (${produit.quantitePreleve})',

                                ),                                  style: const TextStyle(fontSize: 13),

                              ),                                ),

                              Text(                              ),

                                VenteUtils.formatPrix(produit.prixUnitaire *                              Text(

                                    produit.quantitePreleve),                                VenteUtils.formatPrix(produit.prixUnitaire *

                                style: const TextStyle(                                    produit.quantitePreleve),

                                  fontSize: 13,                                style: const TextStyle(

                                  fontWeight: FontWeight.w600,                                  fontSize: 13,

                                ),                                  fontWeight: FontWeight.w600,

                              ),                                ),

                            ],                              ),

                          ),                            ],

                        ))                          ),

                    .toList(),                        ))

                if ((produitsRestants ?? prelevement.produits).length > 3)                    .toList(),

                  Text(                if ((produitsRestants ?? prelevement.produits).length > 3)

                    '... et ${(produitsRestants ?? prelevement.produits).length - 3} autre${(produitsRestants ?? prelevement.produits).length - 3 > 1 ? 's' : ''} produit${(produitsRestants ?? prelevement.produits).length - 3 > 1 ? 's' : ''}',                  Text(

                    style: TextStyle(                    '... et ${(produitsRestants ?? prelevement.produits).length - 3} autre${(produitsRestants ?? prelevement.produits).length - 3 > 1 ? 's' : ''} produit${(produitsRestants ?? prelevement.produits).length - 3 > 1 ? 's' : ''}',

                      fontSize: 12,                    style: TextStyle(

                      color: Colors.grey.shade600,                      fontSize: 12,

                      fontStyle: FontStyle.italic,                      color: Colors.grey.shade600,

                    ),                      fontStyle: FontStyle.italic,

                  ),                    ),

              ],                  ),

            ),              ],

          ),            ),

          ),

          // Observations si présentes

          if (prelevement.observations != null &&          // Observations si présentes

              prelevement.observations!.isNotEmpty) ...[          if (prelevement.observations != null &&

            const SizedBox(height: 16),              prelevement.observations!.isNotEmpty) ...[

            Container(            const SizedBox(height: 16),

              width: double.infinity,            Container(

              padding: const EdgeInsets.all(16),              width: double.infinity,

              decoration: BoxDecoration(              padding: const EdgeInsets.all(16),

                color: Colors.amber.shade50,              decoration: BoxDecoration(

                borderRadius: BorderRadius.circular(12),                color: Colors.amber.shade50,

                border: Border.all(color: Colors.amber.shade200),                borderRadius: BorderRadius.circular(12),

              ),                border: Border.all(color: Colors.amber.shade200),

              child: Row(              ),

                crossAxisAlignment: CrossAxisAlignment.start,              child: Row(

                children: [                crossAxisAlignment: CrossAxisAlignment.start,

                  Icon(Icons.info_outline,                children: [

                      color: Colors.amber.shade700, size: 20),                  Icon(Icons.info_outline,

                  const SizedBox(width: 12),                      color: Colors.amber.shade700, size: 20),

                  Expanded(                  const SizedBox(width: 12),

                    child: Column(                  Expanded(

                      crossAxisAlignment: CrossAxisAlignment.start,                    child: Column(

                      children: [                      crossAxisAlignment: CrossAxisAlignment.start,

                        Text(                      children: [

                          'Observations',                        Text(

                          style: TextStyle(                          'Observations',

                            fontWeight: FontWeight.bold,                          style: TextStyle(

                            color: Colors.amber.shade800,                            fontWeight: FontWeight.bold,

                            fontSize: 14,                            color: Colors.amber.shade800,

                          ),                            fontSize: 14,

                        ),                          ),

                        const SizedBox(height: 4),                        ),

                        Text(                        const SizedBox(height: 4),

                          prelevement.observations!,                        Text(

                          style: TextStyle(                          prelevement.observations!,

                            color: Colors.amber.shade700,                          style: TextStyle(

                            fontSize: 13,                            color: Colors.amber.shade700,

                          ),                            fontSize: 13,

                        ),                          ),

                      ],                        ),

                    ),                      ],

                  ),                    ),

                ],                  ),

              ),                ],

            ),              ),

          ],            ),

        ],          ],

      ),        ],

    );      ),

  }    );

  }

  Widget _buildActions(bool isSmall) {

    return Container(  Widget _buildActions(bool isSmall) {

      padding: EdgeInsets.all(isSmall ? 16 : 20),    return Container(

      decoration: BoxDecoration(      padding: EdgeInsets.all(isSmall ? 16 : 20),

        color: Colors.grey.shade50,      decoration: BoxDecoration(

        borderRadius: const BorderRadius.only(        color: Colors.grey.shade50,

          bottomLeft: Radius.circular(20),        borderRadius: const BorderRadius.only(

          bottomRight: Radius.circular(20),          bottomLeft: Radius.circular(20),

        ),          bottomRight: Radius.circular(20),

      ),        ),

      child: isSmall      ),

          ? Column(      child: isSmall

              children: [          ? Column(

                Row(              children: [

                  children: [                Row(

                    Expanded(                  children: [

                        child: _buildActionButton('Vendre', Icons.point_of_sale,                    Expanded(

                            const Color(0xFF10B981), 'vendre')),                        child: _buildActionButton('Vendre', Icons.point_of_sale,

                    const SizedBox(width: 8),                            const Color(0xFF10B981), 'vendre')),

                    Expanded(                    const SizedBox(width: 8),

                        child: _buildActionButton('Restituer', Icons.undo,                    Expanded(

                            const Color(0xFFF59E0B), 'restituer')),                        child: _buildActionButton('Restituer', Icons.undo,

                  ],                            const Color(0xFFF59E0B), 'restituer')),

                ),                  ],

                const SizedBox(height: 8),                ),

                SizedBox(                const SizedBox(height: 8),

                  width: double.infinity,                SizedBox(

                  child: _buildActionButton('Déclarer Perte', Icons.warning,                  width: double.infinity,

                      const Color(0xFFEF4444), 'perte'),                  child: _buildActionButton('Déclarer Perte', Icons.warning,

                ),                      const Color(0xFFEF4444), 'perte'),

              ],                ),

            )              ],

          : Row(            )

              children: [          : Row(

                Expanded(              children: [

                    child: _buildActionButton('Vendre', Icons.point_of_sale,                Expanded(

                        const Color(0xFF10B981), 'vendre')),                    child: _buildActionButton('Vendre', Icons.point_of_sale,

                const SizedBox(width: 12),                        const Color(0xFF10B981), 'vendre')),

                Expanded(                const SizedBox(width: 12),

                    child: _buildActionButton('Restituer', Icons.undo,                Expanded(

                        const Color(0xFFF59E0B), 'restituer')),                    child: _buildActionButton('Restituer', Icons.undo,

                const SizedBox(width: 12),                        const Color(0xFFF59E0B), 'restituer')),

                Expanded(                const SizedBox(width: 12),

                    child: _buildActionButton('Déclarer Perte', Icons.warning,                Expanded(

                        const Color(0xFFEF4444), 'perte')),                    child: _buildActionButton('Déclarer Perte', Icons.warning,

              ],                        const Color(0xFFEF4444), 'perte')),

            ),              ],

    );            ),

  }    );

  }

  Widget _buildActionButton(

      String label, IconData icon, Color color, String action) {  Widget _buildActionButton(

    return ElevatedButton.icon(      String label, IconData icon, Color color, String action) {

      onPressed: () => onAction(prelevement, action),    return ElevatedButton.icon(

      icon: Icon(icon, size: 18),      onPressed: () => onAction(prelevement, action),

      label: Text(      icon: Icon(icon, size: 18),

        label,      label: Text(

        style: const TextStyle(fontWeight: FontWeight.w600),        label,

      ),        style: const TextStyle(fontWeight: FontWeight.w600),

      style: ElevatedButton.styleFrom(      ),

        backgroundColor: color,      style: ElevatedButton.styleFrom(

        foregroundColor: Colors.white,        backgroundColor: color,

        padding: const EdgeInsets.symmetric(vertical: 12),        foregroundColor: Colors.white,

        shape: RoundedRectangleBorder(        padding: const EdgeInsets.symmetric(vertical: 12),

          borderRadius: BorderRadius.circular(12),        shape: RoundedRectangleBorder(

        ),          borderRadius: BorderRadius.circular(12),

        elevation: 3,        ),

        shadowColor: color.withOpacity(0.3),        elevation: 3,

      ),        shadowColor: color.withOpacity(0.3),

    );      ),

  }    );

  }

  Widget _buildInfoColumn(

      String label, String value, IconData icon, Color color, bool isSmall) {  Widget _buildInfoColumn(

    return Column(      String label, String value, IconData icon, Color color, bool isSmall) {

      children: [    return Column(

        Icon(icon, color: color, size: isSmall ? 24 : 28),      children: [

        const SizedBox(height: 8),        Icon(icon, color: color, size: isSmall ? 24 : 28),

        Text(        const SizedBox(height: 8),

          value,        Text(

          style: TextStyle(          value,

            fontSize: isSmall ? 16 : 18,          style: TextStyle(

            fontWeight: FontWeight.bold,            fontSize: isSmall ? 16 : 18,

            color: const Color(0xFF1F2937),            fontWeight: FontWeight.bold,

          ),            color: const Color(0xFF1F2937),

          textAlign: TextAlign.center,          ),

        ),          textAlign: TextAlign.center,

        const SizedBox(height: 4),        ),

        Text(        const SizedBox(height: 4),

          label,        Text(

          style: TextStyle(          label,

            fontSize: isSmall ? 11 : 12,          style: TextStyle(

            color: Colors.grey.shade600,            fontSize: isSmall ? 11 : 12,

            fontWeight: FontWeight.w500,            color: Colors.grey.shade600,

          ),            fontWeight: FontWeight.w500,

          textAlign: TextAlign.center,          ),

        ),          textAlign: TextAlign.center,

      ],        ),

    );      ],

  }    );

  }

  Color _getStatusColor(StatutPrelevement statut) {

    switch (statut) {  Color _getStatusColor(StatutPrelevement statut) {

      case StatutPrelevement.enCours:    switch (statut) {

        return const Color(0xFF3B82F6);      case StatutPrelevement.enCours:

      case StatutPrelevement.partiel:        return const Color(0xFF3B82F6);

        return const Color(0xFFF59E0B);      case StatutPrelevement.partiel:

      case StatutPrelevement.termine:        return const Color(0xFFF59E0B);

        return const Color(0xFF10B981);      case StatutPrelevement.termine:

      case StatutPrelevement.annule:        return const Color(0xFF10B981);

        return const Color(0xFFEF4444);      case StatutPrelevement.annule:

    }        return const Color(0xFFEF4444);

  }    }

  }

  String _getStatusLabel(StatutPrelevement statut) {

    switch (statut) {  String _getStatusLabel(StatutPrelevement statut) {

      case StatutPrelevement.enCours:    switch (statut) {

        return 'En cours';      case StatutPrelevement.enCours:

      case StatutPrelevement.partiel:        return 'En cours';

        return 'Partiel';      case StatutPrelevement.partiel:

      case StatutPrelevement.termine:        return 'Partiel';

        return 'Terminé';      case StatutPrelevement.termine:

      case StatutPrelevement.annule:        return 'Terminé';

        return 'Annulé';      case StatutPrelevement.annule:

    }        return 'Annulé';

  }    }

}  }
}
