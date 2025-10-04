import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../utils/smart_appbar.dart';
import '../models/transaction_commerciale.dart';
import '../../../authentication/user_session.dart';
import '../services/transaction_commerciale_service.dart';

/// 🎯 INTERFACE ADMIN SIMPLIFIÉE POUR VALIDATION DES TRANSACTIONS
///
/// Page permettant à l'admin de :
/// - Voir toutes les transactions avec leur statut
/// - Valider ou rejeter les transactions récupérées
/// - Superviser l'ensemble du processus commercial

class AdminValidationSimplifiePage extends StatefulWidget {
  const AdminValidationSimplifiePage({super.key});

  @override
  State<AdminValidationSimplifiePage> createState() =>
      _AdminValidationSimplifieePageState();
}

class _AdminValidationSimplifieePageState
    extends State<AdminValidationSimplifiePage> with TickerProviderStateMixin {
  late final TabController _tabController;
  final TransactionCommercialeService _service =
      TransactionCommercialeService.instance;
  final UserSession _userSession = Get.find<UserSession>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: SmartAppBar(
        title: '🎯 Validation Admin',
        backgroundColor: const Color(0xFF7C3AED),
        onBackPressed: () => Get.back(),
      ),
      body: Column(
        children: [
          // En-tête avec statistiques
          _buildStatistiquesGenerales(),

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
              labelColor: const Color(0xFF7C3AED),
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: const Color(0xFF7C3AED),
              tabs: const [
                Tab(
                  icon: Icon(Icons.pending_actions),
                  text: 'En attente',
                ),
                Tab(
                  icon: Icon(Icons.fact_check),
                  text: 'Récupérées',
                ),
                Tab(
                  icon: Icon(Icons.verified),
                  text: 'Validées',
                ),
              ],
            ),
          ),

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionsListe(
                    StatutTransactionCommerciale.termineEnAttente, false),
                _buildTransactionsListe(
                    StatutTransactionCommerciale.recupereeCaisse, true),
                _buildTransactionsListe(
                    StatutTransactionCommerciale.valideeAdmin, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// En-tête avec statistiques générales
  Widget _buildStatistiquesGenerales() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _service.getStatistiquesAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 100,
            color: Colors.white,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final stats = snapshot.data ?? {};
        final totalTransactions = stats['totalTransactions'] ?? 0;
        final enAttente = stats['enAttente'] ?? 0;
        final recuperees = stats['recuperees'] ?? 0;
        final validees = stats['validees'] ?? 0;
        final chiffreAffairesTotal = stats['chiffreAffairesTotal'] ?? 0.0;

        return Container(
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
                'Vue d\'ensemble - ${_userSession.nom ?? "Admin"}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total',
                      '$totalTransactions',
                      Icons.assignment,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'En attente',
                      '$enAttente',
                      Icons.pending_actions,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Récupérées',
                      '$recuperees',
                      Icons.fact_check,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Validées',
                      '$validees',
                      Icons.verified,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_up, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Text(
                      'CA Total: ${chiffreAffairesTotal.toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Card de statistique
  Widget _buildStatCard(
      String titre, String valeur, IconData icon, Color couleur) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: couleur, size: 20),
          const SizedBox(height: 4),
          Text(
            valeur,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: couleur,
            ),
          ),
          Text(
            titre,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  /// Liste des transactions par statut
  Widget _buildTransactionsListe(
      StatutTransactionCommerciale statut, bool showValidationButtons) {
    Stream<List<TransactionCommerciale>> stream;

    switch (statut) {
      case StatutTransactionCommerciale.termineEnAttente:
        stream = _service.getTransactionsEnAttenteAdmin();
        break;
      case StatutTransactionCommerciale.recupereeCaisse:
        stream = _service.getTransactionsRecupereesAdmin();
        break;
      case StatutTransactionCommerciale.valideeAdmin:
        stream = _service.getTransactionsValideesAdmin();
        break;
      default:
        stream = Stream.value([]);
    }

    return StreamBuilder<List<TransactionCommerciale>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildMessageVide(
            icon: Icons.error,
            titre: 'Erreur',
            message: 'Impossible de charger les transactions.',
            couleur: Colors.red,
          );
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          String message;
          switch (statut) {
            case StatutTransactionCommerciale.termineEnAttente:
              message = 'Aucune transaction en attente.';
              break;
            case StatutTransactionCommerciale.recupereeCaisse:
              message =
                  'Aucune transaction récupérée en attente de validation.';
              break;
            case StatutTransactionCommerciale.valideeAdmin:
              message = 'Aucune transaction validée.';
              break;
            default:
              message = 'Aucune transaction.';
          }

          return _buildMessageVide(
            icon: Icons.assignment_outlined,
            titre: 'Aucune transaction',
            message: message,
            couleur: Colors.grey,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return _buildTransactionCard(transaction, showValidationButtons);
          },
        );
      },
    );
  }

  /// Card de transaction simplifiée
  Widget _buildTransactionCard(
      TransactionCommerciale transaction, bool showValidationButtons) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF7C3AED).withOpacity(0.1),
                  child: Text(
                    transaction.commercialNom.isNotEmpty
                        ? transaction.commercialNom[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Color(0xFF7C3AED),
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
                        '${transaction.site} • ${transaction.dateTerminee != null ? DateFormat('dd/MM/yyyy à HH:mm').format(transaction.dateTerminee!) : "Date non définie"}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatutBadge(transaction.statut),
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
                        child: _buildFinancialItem(
                          'CA Net',
                          '${transaction.resumeFinancier.chiffreAffairesNet.toStringAsFixed(0)} FCFA',
                          Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildFinancialItem(
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
                        child: _buildFinancialItem(
                          'Espèces',
                          '${transaction.resumeFinancier.espece.toStringAsFixed(0)} FCFA',
                          Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _buildFinancialItem(
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
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildActivityChip('${transaction.ventes.length} ventes',
                    Icons.shopping_cart, Colors.green),
                _buildActivityChip('${transaction.credits.length} crédits',
                    Icons.credit_card, Colors.orange),
                _buildActivityChip(
                    '${transaction.restitutions.length} restitutions',
                    Icons.keyboard_return,
                    Colors.blue),
                _buildActivityChip('${transaction.pertes.length} pertes',
                    Icons.warning, Colors.red),
              ],
            ),

            if (showValidationButtons) ...[
              const SizedBox(height: 16),
              // Boutons de validation
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejeterTransaction(transaction),
                      icon: const Icon(Icons.close),
                      label: const Text('Rejeter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _validerTransaction(transaction),
                      icon: const Icon(Icons.check),
                      label: const Text('Valider'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
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

  /// Badge de statut
  Widget _buildStatutBadge(StatutTransactionCommerciale statut) {
    Color couleur;
    String texte;

    switch (statut) {
      case StatutTransactionCommerciale.enCours:
        couleur = Colors.grey;
        texte = 'En cours';
        break;
      case StatutTransactionCommerciale.termineEnAttente:
        couleur = Colors.orange;
        texte = 'En attente';
        break;
      case StatutTransactionCommerciale.recupereeCaisse:
        couleur = Colors.blue;
        texte = 'Récupérée';
        break;
      case StatutTransactionCommerciale.valideeAdmin:
        couleur = Colors.green;
        texte = 'Validée';
        break;
      case StatutTransactionCommerciale.rejetee:
        couleur = Colors.red;
        texte = 'Rejetée';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        texte,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: couleur,
        ),
      ),
    );
  }

  /// Item financier
  Widget _buildFinancialItem(String label, String valeur, Color couleur) {
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

  /// Chip d'activité
  Widget _buildActivityChip(String texte, IconData icon, Color couleur) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: couleur),
          const SizedBox(width: 4),
          Text(
            texte,
            style: TextStyle(
              fontSize: 12,
              color: couleur,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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

  /// Valider une transaction
  Future<void> _validerTransaction(TransactionCommerciale transaction) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmer la validation'),
        content: Text(
          'Confirmez-vous la validation de la transaction de ${transaction.commercialNom} ?\n\n'
          'Montant: ${transaction.resumeFinancier.chiffreAffairesNet.toStringAsFixed(0)} FCFA\n\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.validerTransactionAdmin(
            transaction.id, _userSession.nom ?? 'Admin');
        Get.snackbar(
          '✅ Transaction validée',
          'La transaction de ${transaction.commercialNom} a été validée.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } catch (e) {
        Get.snackbar(
          '❌ Erreur',
          'Impossible de valider la transaction: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  /// Rejeter une transaction
  Future<void> _rejeterTransaction(TransactionCommerciale transaction) async {
    final motifController = TextEditingController();

    final result = await Get.dialog<Map<String, dynamic>>(
      AlertDialog(
        title: const Text('Rejeter la transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Motif du rejet de la transaction de ${transaction.commercialNom} :',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: motifController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Saisissez le motif du rejet...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (motifController.text.trim().isNotEmpty) {
                Get.back(result: {
                  'confirme': true,
                  'motif': motifController.text.trim(),
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );

    if (result != null && result['confirme'] == true) {
      try {
        await _service.rejeterTransactionAdmin(
          transaction.id,
          _userSession.nom ?? 'Admin',
          result['motif'],
        );
        Get.snackbar(
          '🚫 Transaction rejetée',
          'La transaction de ${transaction.commercialNom} a été rejetée.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } catch (e) {
        Get.snackbar(
          '❌ Erreur',
          'Impossible de rejeter la transaction: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }
}
