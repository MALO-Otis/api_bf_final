import 'package:flutter/material.dart';
import '../../../data/models/collecte_models.dart';
import 'package:intl/intl.dart';

/// Widget custom pour le dialogue de confirmation de collecte - VERSION PROFESSIONNELLE
class DialogueConfirmationCollecte extends StatelessWidget {
  final ProducteurModel producteurSelectionne;
  final List<ContenantModel> contenants;
  final double poidsTotal;
  final double montantTotal;
  final String observations;

  const DialogueConfirmationCollecte({
    Key? key,
    required this.producteurSelectionne,
    required this.contenants,
    required this.poidsTotal,
    required this.montantTotal,
    required this.observations,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: isSmallScreen ? screenWidth * 0.95 : screenWidth * 0.7,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 800,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, isSmallScreen),
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildValidationMessage(isSmallScreen),
                      SizedBox(height: isSmallScreen ? 20 : 24),
                      _buildProducteurSection(isSmallScreen),
                      SizedBox(height: isSmallScreen ? 20 : 24),
                      _buildContenantsSection(isSmallScreen),
                      SizedBox(height: isSmallScreen ? 20 : 24),
                      _buildTotauxSection(isSmallScreen),
                      if (observations.isNotEmpty) ...[
                        SizedBox(height: isSmallScreen ? 20 : 24),
                        _buildObservationsSection(isSmallScreen),
                      ],
                      SizedBox(height: isSmallScreen ? 20 : 24),
                      _buildValidationChecks(isSmallScreen),
                      SizedBox(height: isSmallScreen ? 20 : 24),
                      _buildMetadataSection(isSmallScreen),
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      _buildSecurityInfoSection(isSmallScreen),
                    ],
                  ),
                ),
              ),
            ),
            _buildActionButtons(context, isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF49101),
            const Color(0xFFFF9800),
            const Color(0xFFFFA726),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.verified_user,
              color: const Color(0xFFF49101),
              size: isSmallScreen ? 28 : 32,
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vérification finale',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 18 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Confirmer les détails avant enregistrement',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  color: Colors.white,
                  size: isSmallScreen ? 14 : 16,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('HH:mm').format(DateTime.now()),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 11 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationMessage(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: Colors.white,
              size: isSmallScreen ? 16 : 20,
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Collecte validée',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Toutes les informations sont correctes et prêtes pour l\'enregistrement',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProducteurSection(bool isSmallScreen) {
    final localisation = producteurSelectionne.localisation;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person,
                  color: Colors.blue.shade600,
                  size: isSmallScreen ? 20 : 24,
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Text(
                  'INFORMATIONS PRODUCTEUR',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              children: [
                _buildInfoRow('Nom complet', producteurSelectionne.nomPrenom,
                    Icons.badge, isSmallScreen),
                _buildInfoRow('Numéro', producteurSelectionne.numero, Icons.tag,
                    isSmallScreen),
                _buildInfoRow('Sexe', producteurSelectionne.sexe,
                    Icons.person_outline, isSmallScreen),
                _buildInfoRow(
                    'Âge',
                    producteurSelectionne.age.isNotEmpty
                        ? producteurSelectionne.age
                        : 'Non spécifié',
                    Icons.cake,
                    isSmallScreen),
                _buildInfoRow(
                    'Appartenance',
                    producteurSelectionne.appartenance,
                    Icons.group,
                    isSmallScreen),
                if (producteurSelectionne.cooperative.isNotEmpty)
                  _buildInfoRow(
                      'Coopérative',
                      producteurSelectionne.cooperative,
                      Icons.business,
                      isSmallScreen),
                _buildInfoRow(
                    'Ruches traditionnelles',
                    '${producteurSelectionne.nbRuchesTrad}',
                    Icons.hive,
                    isSmallScreen),
                _buildInfoRow(
                    'Ruches modernes',
                    '${producteurSelectionne.nbRuchesMod}',
                    Icons.smart_toy,
                    isSmallScreen),
                _buildInfoRow(
                    'Total ruches',
                    '${producteurSelectionne.totalRuches}',
                    Icons.summarize,
                    isSmallScreen),
                const Divider(),
                _buildLocalisationRow(localisation, isSmallScreen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContenantsSection(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.inventory,
                  color: Colors.orange.shade600,
                  size: isSmallScreen ? 20 : 24,
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Text(
                  'DÉTAIL DES CONTENANTS (${contenants.length})',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              children: contenants.asMap().entries.map((entry) {
                final index = entry.key;
                final contenant = entry.value;
                return _buildContenantCard(contenant, index + 1, isSmallScreen);
              }).toList()
                ..add(_buildContenantsSummary(
                    isSmallScreen)), // Ajout d'un résumé des contenants
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContenantCard(
      ContenantModel contenant, int numero, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Contenant #$numero',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 10 : 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Text(
                  '${contenant.montantTotal.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontSize: isSmallScreen ? 10 : 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Row(
            children: [
              Expanded(
                child: _buildContenantDetail('Type ruche', contenant.typeRuche,
                    Icons.hive, isSmallScreen),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildContenantDetail('Type miel', contenant.typeMiel,
                    Icons.science, isSmallScreen),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _buildContenantDetail('Contenant',
                    contenant.typeContenant, Icons.inventory_2, isSmallScreen),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildContenantDetail(
                    'Prédominance',
                    contenant.predominanceFlorale.isEmpty
                        ? 'Non spécifiée'
                        : contenant.predominanceFlorale,
                    Icons.local_florist,
                    isSmallScreen),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _buildContenantDetail('Quantité',
                    '${contenant.quantite} kg', Icons.scale, isSmallScreen),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildContenantDetail(
                    'Prix unitaire',
                    '${contenant.prixUnitaire.toStringAsFixed(0)} FCFA/kg',
                    Icons.attach_money,
                    isSmallScreen),
              ),
            ],
          ),
          if (contenant.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.note_alt,
                    color: Colors.blue.shade600,
                    size: isSmallScreen ? 14 : 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Note',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 9 : 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        Text(
                          contenant.note,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 11,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotauxSection(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: isSmallScreen ? 24 : 28,
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Text(
                  'TOTAUX DE LA COLLECTE',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Row(
              children: [
                Expanded(
                  child: _buildTotalCard(
                    'Poids total',
                    '${poidsTotal.toStringAsFixed(2)} kg',
                    Icons.scale,
                    Colors.white,
                    isSmallScreen,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: _buildTotalCard(
                    'Montant total',
                    '${montantTotal.toStringAsFixed(0)} FCFA',
                    Icons.monetization_on,
                    Colors.white,
                    isSmallScreen,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Row(
              children: [
                Expanded(
                  child: _buildTotalCard(
                    'Contenants',
                    '${contenants.length}',
                    Icons.inventory,
                    Colors.white,
                    isSmallScreen,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: _buildTotalCard(
                    'Prix moyen',
                    '${(montantTotal / poidsTotal).toStringAsFixed(0)} FCFA/kg',
                    Icons.trending_up,
                    Colors.white,
                    isSmallScreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObservationsSection(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.comment,
                  color: Colors.purple.shade600,
                  size: isSmallScreen ? 20 : 24,
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Text(
                  'OBSERVATIONS',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                observations,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  height: 1.4,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection(bool isSmallScreen) {
    final now = DateTime.now();
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.grey.shade600,
                size: isSmallScreen ? 16 : 18,
              ),
              SizedBox(width: isSmallScreen ? 6 : 8),
              Text(
                'Informations d\'enregistrement',
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          _buildMetadataRow('Date d\'enregistrement',
              DateFormat('dd/MM/yyyy à HH:mm').format(now), isSmallScreen),
          _buildMetadataRow('Période de collecte',
              DateFormat('dd/MM/yyyy').format(now), isSmallScreen),
          _buildMetadataRow(
              'Statut initial', 'Collecte terminée', isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildSecurityInfoSection(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
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
              Icon(
                Icons.security,
                color: Colors.indigo.shade600,
                size: isSmallScreen ? 14 : 16,
              ),
              SizedBox(width: isSmallScreen ? 6 : 8),
              Text(
                'Sécurité et traçabilité',
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          _buildSecurityItem(
              '🔒', 'Données chiffrées lors du stockage', isSmallScreen),
          _buildSecurityItem(
              '📊', 'Mise à jour automatique des statistiques', isSmallScreen),
          _buildSecurityItem(
              '🔍', 'Traçabilité complète de la transaction', isSmallScreen),
          _buildSecurityItem(
              '💾', 'Sauvegarde sécurisée dans Firestore', isSmallScreen),
          SizedBox(height: isSmallScreen ? 4 : 6),
          Text(
            'Cette collecte sera immédiatement enregistrée et contribuera aux statistiques globales du site.',
            style: TextStyle(
              fontSize: isSmallScreen ? 8 : 9,
              color: Colors.indigo.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(String emoji, String text, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 2 : 3),
      child: Row(
        children: [
          Text(
            emoji,
            style: TextStyle(fontSize: isSmallScreen ? 10 : 12),
          ),
          SizedBox(width: isSmallScreen ? 4 : 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isSmallScreen ? 8 : 9,
                color: Colors.indigo.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isSmallScreen) {
    final bool allChecksValid = _areAllValidationsValid();

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Indicateur de statut global
          if (!allChecksValid) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.orange.shade700,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Certaines vérifications nécessitent votre attention. Vous pouvez tout de même enregistrer.',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 11,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Résumé rapide
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickStat('Producteur', producteurSelectionne.nomPrenom,
                    Icons.person, isSmallScreen),
                _buildQuickStat('Contenants', '${contenants.length}',
                    Icons.inventory, isSmallScreen),
                _buildQuickStat('Total', '${montantTotal.toStringAsFixed(0)} F',
                    Icons.monetization_on, isSmallScreen),
              ],
            ),
          ),

          // Boutons d'action
          Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Annuler'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade400),
                    padding:
                        EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: Icon(allChecksValid ? Icons.save : Icons.save_outlined),
                  label: Text(allChecksValid
                      ? 'Enregistrer la collecte'
                      : 'Enregistrer quand même'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: allChecksValid
                        ? Colors.green.shade600
                        : Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding:
                        EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                    elevation: 4,
                    shadowColor: (allChecksValid ? Colors.green : Colors.orange)
                        .withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
      String label, String value, IconData icon, bool isSmallScreen) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.blue.shade600,
          size: isSmallScreen ? 16 : 18,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isSmallScreen ? 10 : 11,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 8 : 9,
            color: Colors.blue.shade600,
          ),
        ),
      ],
    );
  }

  bool _areAllValidationsValid() {
    return producteurSelectionne.nomPrenom.isNotEmpty &&
        producteurSelectionne.numero.isNotEmpty &&
        contenants.isNotEmpty &&
        contenants.every((c) => c.quantite > 0 && c.prixUnitaire > 0) &&
        contenants
            .every((c) => ['Liquide', 'Brute', 'Cire'].contains(c.typeMiel)) &&
        contenants.every((c) => c.typeContenant.isNotEmpty) &&
        montantTotal > 0 &&
        poidsTotal > 0;
  }

  Widget _buildValidationChecks(bool isSmallScreen) {
    // Liste des vérifications effectuées
    final List<Map<String, dynamic>> checks = [
      {
        'label': 'Informations producteur complètes',
        'isValid': producteurSelectionne.nomPrenom.isNotEmpty &&
            producteurSelectionne.numero.isNotEmpty,
        'description': 'Nom, numéro et données essentielles validés'
      },
      {
        'label': 'Contenants valides',
        'isValid': contenants.isNotEmpty &&
            contenants.every((c) => c.quantite > 0 && c.prixUnitaire > 0),
        'description':
            '${contenants.length} contenant(s) avec quantités et prix corrects'
      },
      {
        'label': 'Types de miel conformes',
        'isValid': contenants
            .every((c) => ['Conventionnel', 'Bio'].contains(c.typeMiel)),
        'description':
            'Tous les types de miel sont dans les catégories autorisées'
      },
      {
        'label': 'Types de contenant spécifiés',
        'isValid': contenants.every((c) => c.typeContenant.isNotEmpty),
        'description': 'Tous les contenants ont un type défini'
      },
      {
        'label': 'Calculs financiers cohérents',
        'isValid': montantTotal > 0 && poidsTotal > 0,
        'description':
            'Totaux calculés et cohérents (${montantTotal.toStringAsFixed(0)} FCFA pour ${poidsTotal.toStringAsFixed(2)} kg)'
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified,
                  color: Colors.teal.shade600,
                  size: isSmallScreen ? 20 : 24,
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Text(
                  'VÉRIFICATIONS AUTOMATIQUES',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: checks.every((check) => check['isValid'])
                        ? Colors.green.shade600
                        : Colors.orange.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    checks.every((check) => check['isValid'])
                        ? 'TOUTES VALIDÉES'
                        : 'ATTENTION',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 9 : 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              children: checks
                  .map((check) => _buildValidationCheck(
                        check['label'],
                        check['description'],
                        check['isValid'],
                        isSmallScreen,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationCheck(
      String label, String description, bool isValid, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 10),
      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
      decoration: BoxDecoration(
        color: isValid ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValid ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isValid ? Colors.green.shade600 : Colors.red.shade600,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isValid ? Icons.check : Icons.warning,
              color: Colors.white,
              size: isSmallScreen ? 12 : 14,
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    fontWeight: FontWeight.bold,
                    color:
                        isValid ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 9 : 10,
                    color:
                        isValid ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContenantsSummary(bool isSmallScreen) {
    // Calcul des statistiques des contenants
    final Map<String, int> typesRuches = {};
    final Map<String, int> typesMiel = {};
    final Map<String, int> typesContenant = {};
    final Map<String, double> quantitesParType = {};

    for (final contenant in contenants) {
      // Types de ruches
      typesRuches[contenant.typeRuche] =
          (typesRuches[contenant.typeRuche] ?? 0) + 1;

      // Types de miel
      typesMiel[contenant.typeMiel] = (typesMiel[contenant.typeMiel] ?? 0) + 1;

      // Types de contenant
      typesContenant[contenant.typeContenant] =
          (typesContenant[contenant.typeContenant] ?? 0) + 1;

      // Quantités par type de miel
      quantitesParType[contenant.typeMiel] =
          (quantitesParType[contenant.typeMiel] ?? 0) + contenant.quantite;
    }

    return Container(
      margin: EdgeInsets.only(top: isSmallScreen ? 12 : 16),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade50, Colors.orange.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.summarize,
                color: Colors.orange.shade700,
                size: isSmallScreen ? 16 : 18,
              ),
              SizedBox(width: isSmallScreen ? 6 : 8),
              Text(
                'Résumé de la collecte',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 8 : 10),
          if (typesRuches.isNotEmpty) ...[
            _buildSummaryLine(
                'Types de ruches',
                typesRuches.entries
                    .map((e) => '${e.value}× ${e.key}')
                    .join(', '),
                isSmallScreen),
          ],
          if (typesMiel.isNotEmpty) ...[
            _buildSummaryLine(
                'Types de miel',
                typesMiel.entries.map((e) => '${e.value}× ${e.key}').join(', '),
                isSmallScreen),
          ],
          if (typesContenant.isNotEmpty) ...[
            _buildSummaryLine(
                'Types de contenant',
                typesContenant.entries
                    .map((e) => '${e.value}× ${e.key}')
                    .join(', '),
                isSmallScreen),
          ],
          if (quantitesParType.isNotEmpty) ...[
            _buildSummaryLine(
                'Répartition des quantités',
                quantitesParType.entries
                    .map((e) => '${e.value.toStringAsFixed(1)}kg de ${e.key}')
                    .join(', '),
                isSmallScreen),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String label, String value, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 3 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 11,
                color: Colors.orange.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthodes utilitaires pour construire les widgets répétitifs
  Widget _buildInfoRow(
      String label, String value, IconData icon, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey.shade600,
            size: isSmallScreen ? 14 : 16,
          ),
          SizedBox(width: isSmallScreen ? 6 : 8),
          SizedBox(
            width: isSmallScreen ? 80 : 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalisationRow(
      Map<String, String> localisation, bool isSmallScreen) {
    final localisationComplete = [
      localisation['region'],
      localisation['province'],
      localisation['commune'],
      localisation['village']
    ].where((element) => element != null && element.isNotEmpty).join(' > ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.location_on,
          color: Colors.grey.shade600,
          size: isSmallScreen ? 14 : 16,
        ),
        SizedBox(width: isSmallScreen ? 6 : 8),
        SizedBox(
          width: isSmallScreen ? 80 : 100,
          child: Text(
            'Localisation',
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            localisationComplete.isEmpty
                ? 'Non spécifiée'
                : localisationComplete,
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContenantDetail(
      String label, String value, IconData icon, bool isSmallScreen) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey.shade600,
          size: isSmallScreen ? 12 : 14,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 8 : 9,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmallScreen ? 9 : 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalCard(String label, String value, IconData icon, Color color,
      bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: isSmallScreen ? 20 : 24,
          ),
          SizedBox(height: isSmallScreen ? 4 : 6),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 9 : 10,
              color: color.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 3 : 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: isSmallScreen ? 9 : 10,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 9 : 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
