import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../utils/smart_appbar.dart';
import '../models/transaction_commerciale.dart';
import '../../../authentication/user_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/transaction_commerciale_service.dart';

/// 🏦 INTERFACE CAISSE POUR RÉCUPÉRATION DES PRÉLÈVEMENTS
///
/// Page permettant au caissier de :
/// - Voir les notifications de transactions terminées par les commerciaux
/// - Récupérer les prélèvements des commerciaux du même site
/// - Visualiser les détails des transactions

class CaisseRecuperationPrelevementsPage extends StatefulWidget {
  const CaisseRecuperationPrelevementsPage({super.key});

  @override
  State<CaisseRecuperationPrelevementsPage> createState() =>
      _CaisseRecuperationPrelevementsPageState();
}

class _CaisseRecuperationPrelevementsPageState
    extends State<CaisseRecuperationPrelevementsPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  final TransactionCommercialeService _service =
      TransactionCommercialeService.instance;
  final UserSession _userSession = Get.find<UserSession>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final userSite = _userSession.site ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: SmartAppBar(
        title: '🏦 Récupération Prélèvements',
        backgroundColor: const Color(0xFF0EA5E9),
        onBackPressed: () => Get.back(),
      ),
      body: Column(
        children: [
          // En-tête avec informations du site
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Site: ${userSite.isNotEmpty ? userSite : "Non défini"}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Caissier: ${_userSession.nom ?? "Non défini"}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Onglets
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF0EA5E9),
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: const Color(0xFF0EA5E9),
              tabs: const [
                Tab(
                  icon: Icon(Icons.notifications_active),
                  text: 'Notifications',
                ),
                Tab(
                  icon: Icon(Icons.assignment_turned_in),
                  text: 'Prélèvements',
                ),
              ],
            ),
          ),

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationsTab(userSite, isMobile),
                _buildPrelevementsTab(userSite, isMobile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Onglet des notifications
  Widget _buildNotificationsTab(String site, bool isMobile) {
    if (site.isEmpty) {
      return _buildMessageVide(
        icon: Icons.warning,
        titre: 'Site non défini',
        message: 'Impossible d\'afficher les notifications sans site assigné.',
        couleur: Colors.orange,
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.getNotificationsCaisse(site),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildMessageVide(
            icon: Icons.error,
            titre: 'Erreur',
            message: 'Impossible de charger les notifications.',
            couleur: Colors.red,
          );
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return _buildMessageVide(
            icon: Icons.notifications_off,
            titre: 'Aucune notification',
            message: 'Aucun prélèvement terminé pour le moment.',
            couleur: Colors.grey,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return _buildNotificationCard(notification, isMobile);
          },
        );
      },
    );
  }

  /// Onglet des prélèvements en attente
  Widget _buildPrelevementsTab(String site, bool isMobile) {
    if (site.isEmpty) {
      return _buildMessageVide(
        icon: Icons.warning,
        titre: 'Site non défini',
        message: 'Impossible d\'afficher les prélèvements sans site assigné.',
        couleur: Colors.orange,
      );
    }

    return StreamBuilder<List<TransactionCommerciale>>(
      stream: _service.getTransactionsEnAttentePourSite(site),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildMessageVide(
            icon: Icons.error,
            titre: 'Erreur',
            message: 'Impossible de charger les prélèvements.',
            couleur: Colors.red,
          );
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return _buildMessageVide(
            icon: Icons.assignment_turned_in_outlined,
            titre: 'Aucun prélèvement',
            message: 'Aucun prélèvement en attente de récupération.',
            couleur: Colors.grey,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return _buildTransactionCard(transaction, isMobile);
          },
        );
      },
    );
  }

  /// Card d'une notification
  Widget _buildNotificationCard(
      Map<String, dynamic> notification, bool isMobile) {
    final dateCreation = (notification['dateCreation'] as Timestamp).toDate();
    final donnees = notification['donnees'] as Map<String, dynamic>? ?? {};

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.assignment_turned_in,
                    color: Color(0xFF0EA5E9),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['titre'] ?? 'Notification',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy à HH:mm').format(dateCreation),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              notification['message'] ?? '',
              style: const TextStyle(fontSize: 14),
            ),
            if (donnees.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildInfoChip(
                      'Ventes',
                      '${(donnees['totalVentes'] ?? 0).toStringAsFixed(0)} FCFA',
                      Colors.green),
                  _buildInfoChip(
                      'Crédits',
                      '${(donnees['totalCredits'] ?? 0).toStringAsFixed(0)} FCFA',
                      Colors.orange),
                  if (donnees['totalRestitutions'] != null &&
                      donnees['totalRestitutions'] > 0)
                    _buildInfoChip(
                        'Restitutions',
                        '${donnees['totalRestitutions'].toStringAsFixed(0)} FCFA',
                        Colors.blue),
                  if (donnees['totalPertes'] != null &&
                      donnees['totalPertes'] > 0)
                    _buildInfoChip(
                        'Pertes',
                        '${donnees['totalPertes'].toStringAsFixed(0)} FCFA',
                        Colors.red),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Card d'une transaction
  Widget _buildTransactionCard(
      TransactionCommerciale transaction, bool isMobile) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec commercial et date
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF0EA5E9).withOpacity(0.1),
                  child: Text(
                    transaction.commercialNom.isNotEmpty
                        ? transaction.commercialNom[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Color(0xFF0EA5E9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.commercialNom,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Terminé le ${DateFormat('dd/MM/yyyy à HH:mm').format(transaction.dateTerminee!)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'En attente',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Résumé financier
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Résumé financier',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildResumeItem(
                          'CA Net',
                          '${transaction.resumeFinancier.chiffreAffairesNet.toStringAsFixed(0)} FCFA',
                          Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildResumeItem(
                          'Crédits',
                          '${transaction.resumeFinancier.totalCredits.toStringAsFixed(0)} FCFA',
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildResumeItem(
                          'Espèces',
                          '${transaction.resumeFinancier.espece.toStringAsFixed(0)} FCFA',
                          Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _buildResumeItem(
                          'Mobile',
                          '${transaction.resumeFinancier.mobile.toStringAsFixed(0)} FCFA',
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Compteurs d'activités
            Row(
              children: [
                _buildActivityCounter(
                  'Ventes',
                  transaction.ventes.length,
                  Icons.shopping_cart,
                ),
                const SizedBox(width: 16),
                _buildActivityCounter(
                  'Restitutions',
                  transaction.restitutions.length,
                  Icons.keyboard_return,
                ),
                const SizedBox(width: 16),
                _buildActivityCounter(
                  'Pertes',
                  transaction.pertes.length,
                  Icons.warning,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () => _voirDetails(transaction),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Voir détails'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () => _recupererPrelevement(transaction),
                    icon: const Icon(Icons.check),
                    label: const Text('Récupérer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Widget pour item de résumé
  Widget _buildResumeItem(String label, String valeur, Color couleur) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          valeur,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: couleur,
          ),
        ),
      ],
    );
  }

  /// Widget pour compteur d'activité
  Widget _buildActivityCounter(String label, int count, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 4),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget pour chip d'information
  Widget _buildInfoChip(String label, String valeur, Color couleur) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $valeur',
        style: TextStyle(
          fontSize: 12,
          color: couleur.withOpacity(0.8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Widget message vide
  Widget _buildMessageVide({
    required IconData icon,
    required String titre,
    required String message,
    required Color couleur,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: couleur.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              titre,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: couleur,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Voir les détails d'une transaction
  void _voirDetails(TransactionCommerciale transaction) {
    Get.dialog(
      _DialogDetailsTransaction(transaction: transaction),
      barrierDismissible: true,
    );
  }

  /// Récupérer un prélèvement
  Future<void> _recupererPrelevement(TransactionCommerciale transaction) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmer la récupération'),
        content: Text(
          'Confirmez-vous la récupération du prélèvement de ${transaction.commercialNom} ?\n\n'
          'Montant net: ${transaction.resumeFinancier.chiffreAffairesNet.toStringAsFixed(0)} FCFA',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.marquerRecupereeParCaisse(transaction.id);
        Get.snackbar(
          '✅ Prélèvement récupéré',
          'Le prélèvement de ${transaction.commercialNom} a été récupéré.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } catch (e) {
        Get.snackbar(
          '❌ Erreur',
          'Impossible de récupérer le prélèvement: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }
}

/// Dialog pour afficher les détails d'une transaction
class _DialogDetailsTransaction extends StatelessWidget {
  final TransactionCommerciale transaction;

  const _DialogDetailsTransaction({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Détails - ${transaction.commercialNom}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informations générales
                    _buildSectionTitle('Informations générales'),
                    _buildInfoRow('Commercial', transaction.commercialNom),
                    _buildInfoRow('Site', transaction.site),
                    _buildInfoRow(
                        'Date terminée',
                        DateFormat('dd/MM/yyyy à HH:mm')
                            .format(transaction.dateTerminee!)),
                    if (transaction.observations != null)
                      _buildInfoRow('Observations', transaction.observations!),

                    const SizedBox(height: 20),

                    // Résumé financier
                    _buildSectionTitle('Résumé financier'),
                    _buildInfoRow('Total ventes',
                        '${transaction.resumeFinancier.totalVentes.toStringAsFixed(0)} FCFA'),
                    _buildInfoRow('Crédits',
                        '${transaction.resumeFinancier.totalCredits.toStringAsFixed(0)} FCFA'),
                    _buildInfoRow('Restitutions',
                        '${transaction.resumeFinancier.totalRestitutions.toStringAsFixed(0)} FCFA'),
                    _buildInfoRow('Pertes',
                        '${transaction.resumeFinancier.totalPertes.toStringAsFixed(0)} FCFA'),
                    _buildInfoRow('CA Net',
                        '${transaction.resumeFinancier.chiffreAffairesNet.toStringAsFixed(0)} FCFA',
                        isImportant: true),

                    const SizedBox(height: 20),

                    // Répartition des paiements
                    _buildSectionTitle('Répartition des paiements'),
                    _buildInfoRow('Espèces',
                        '${transaction.resumeFinancier.espece.toStringAsFixed(0)} FCFA'),
                    _buildInfoRow('Mobile Money',
                        '${transaction.resumeFinancier.mobile.toStringAsFixed(0)} FCFA'),
                    _buildInfoRow('Autres',
                        '${transaction.resumeFinancier.autres.toStringAsFixed(0)} FCFA'),

                    const SizedBox(height: 20),

                    // Statistiques
                    _buildSectionTitle('Statistiques'),
                    _buildInfoRow(
                        'Nombre de ventes', '${transaction.ventes.length}'),
                    _buildInfoRow('Nombre de restitutions',
                        '${transaction.restitutions.length}'),
                    _buildInfoRow(
                        'Nombre de pertes', '${transaction.pertes.length}'),
                    _buildInfoRow('Taux de conversion',
                        '${transaction.resumeFinancier.tauxConversion.toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String valeur,
      {bool isImportant = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: isImportant ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valeur,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isImportant ? FontWeight.bold : FontWeight.normal,
                color: isImportant
                    ? const Color(0xFF059669)
                    : const Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
