import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../utils/smart_appbar.dart';
import '../models/transaction_commerciale.dart';
import '../../../authentication/user_session.dart';
import '../services/transaction_commerciale_service.dart';

/// 🎯 INTERFACE ADMIN POUR VALIDATION COMPLÈTE DES TRANSACTIONS
///
/// Page permettant à l'admin de :
/// - Voir toutes les transactions terminées (tous sites)
/// - Visualiser les activités détaillées dans des dépliables
/// - Valider ou rejeter les transactions
/// - Superviser l'ensemble du processus commercial

class AdminValidationTransactionsPage extends StatefulWidget {
  const AdminValidationTransactionsPage({super.key});

  @override
  State<AdminValidationTransactionsPage> createState() =>
      _AdminValidationTransactionsPageState();
}

class _AdminValidationTransactionsPageState
    extends State<AdminValidationTransactionsPage>
    with TickerProviderStateMixin {
  
  late final TabController _tabController;
  final TransactionCommercialeService _service = TransactionCommercialeService.instance;
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: SmartAppBar(
        title: '🎯 Validation Admin',
        backgroundColor: const Color(0xFF7C3AED),
        onBackPressed: () => Get.back(),
      ),
      body: Column(
        children: [
          // En-tête avec statistiques générales
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
                _buildTransactionsEnAttente(isMobile),
                _buildTransactionsRecuperees(isMobile),
                _buildTransactionsValidees(isMobile),
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
                    Icon(Icons.trending_up, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'CA Total: ${chiffreAffairesTotal.toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
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
  Widget _buildStatCard(String titre, String valeur, IconData icon, Color couleur) {
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

  /// Onglet des transactions en attente
  Widget _buildTransactionsEnAttente(bool isMobile) {
    return StreamBuilder<List<TransactionCommerciale>>(
      stream: _service.getTransactionsEnAttenteAdmin(),
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
          return _buildMessageVide(
            icon: Icons.pending_actions_outlined,
            titre: 'Aucune transaction en attente',
            message: 'Toutes les transactions ont été traitées.',
            couleur: Colors.grey,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return _buildTransactionExpandableCard(
              transaction, 
              isMobile,
              showRecuperationButton: false,
              showValidationButtons: false,
            );
          },
        );
      },
    );
  }

  /// Onglet des transactions récupérées
  Widget _buildTransactionsRecuperees(bool isMobile) {
    return StreamBuilder<List<TransactionCommerciale>>(
      stream: _service.getTransactionsRecupereesAdmin(),
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
          return _buildMessageVide(
            icon: Icons.fact_check_outlined,
            titre: 'Aucune transaction récupérée',
            message: 'Aucune transaction en attente de validation.',
            couleur: Colors.grey,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return _buildTransactionExpandableCard(
              transaction, 
              isMobile,
              showRecuperationButton: false,
              showValidationButtons: true,
            );
          },
        );
      },
    );
  }

  /// Onglet des transactions validées
  Widget _buildTransactionsValidees(bool isMobile) {
    return StreamBuilder<List<TransactionCommerciale>>(
      stream: _service.getTransactionsValideesAdmin(),
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
          return _buildMessageVide(
            icon: Icons.verified_outlined,
            titre: 'Aucune transaction validée',
            message: 'Aucune transaction validée pour le moment.',
            couleur: Colors.grey,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return _buildTransactionExpandableCard(
              transaction, 
              isMobile,
              showRecuperationButton: false,
              showValidationButtons: false,
            );
          },
        );
      },
    );
  }

  /// Card de transaction avec dépliables pour les activités
  Widget _buildTransactionExpandableCard(
    TransactionCommerciale transaction, 
    bool isMobile, {
    bool showRecuperationButton = false,
    bool showValidationButtons = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // En-tête de la transaction
          _buildTransactionHeader(transaction),
          
          // Activités dépliables
          _buildExpandableActivities(transaction),
          
          // Boutons d'action
          if (showRecuperationButton || showValidationButtons)
            _buildActionButtons(transaction, showValidationButtons),
        ],
      ),
    );
  }

  /// En-tête de la transaction
  Widget _buildTransactionHeader(TransactionCommerciale transaction) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      '${transaction.site} • ${DateFormat('dd/MM/yyyy à HH:mm').format(transaction.dateTerminee!)}',
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
          
          // Résumé financier compact
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _buildFinancialItem(
                      'CA Net',
                      '${transaction.resumeFinancier.chiffreAffairesNet.toStringAsFixed(0)} FCFA',
                      Colors.green,
                    ),
                  ),
                  const VerticalDivider(color: Colors.grey),
                  Expanded(
                    child: _buildFinancialItem(
                      'Crédits',
                      '${transaction.resumeFinancier.totalCredits.toStringAsFixed(0)} FCFA',
                      Colors.orange,
                    ),
                  ),
                  const VerticalDivider(color: Colors.grey),
                  Expanded(
                    child: _buildFinancialItem(
                      'Espèces',
                      '${transaction.resumeFinancier.espece.toStringAsFixed(0)} FCFA',
                      Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
          color: couleur.shade700,
        ),
      ),
    );
  }

  /// Item financier
  Widget _buildFinancialItem(String label, String valeur, Color couleur) {
    return Column(
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

  /// Activités dépliables
  Widget _buildExpandableActivities(TransactionCommerciale transaction) {
    return Column(
      children: [
        // Ventes
        if (transaction.ventes.isNotEmpty)
          _buildExpandableTile(
            titre: 'Ventes (${transaction.ventes.length})',
            icone: Icons.shopping_cart,
            couleur: Colors.green,
            contenu: _buildVentesList(transaction.ventes),
          ),
        
        // Crédits
        if (transaction.credits.isNotEmpty)
          _buildExpandableTile(
            titre: 'Crédits (${transaction.credits.length})',
            icone: Icons.credit_card,
            couleur: Colors.orange,
            contenu: _buildCreditsList(transaction.credits),
          ),
        
        // Restitutions
        if (transaction.restitutions.isNotEmpty)
          _buildExpandableTile(
            titre: 'Restitutions (${transaction.restitutions.length})',
            icone: Icons.keyboard_return,
            couleur: Colors.blue,
            contenu: _buildRestitutionsList(transaction.restitutions),
          ),
        
        // Pertes
        if (transaction.pertes.isNotEmpty)
          _buildExpandableTile(
            titre: 'Pertes (${transaction.pertes.length})',
            icone: Icons.warning,
            couleur: Colors.red,
            contenu: _buildPertesList(transaction.pertes),
          ),
        
        // Quantités d'origine
        _buildExpandableTile(
          titre: 'Quantités d\'origine',
          icone: Icons.inventory,
          couleur: Colors.purple,
          contenu: _buildQuantitesOrigineDetails(transaction.quantitesOrigine),
        ),
      ],
    );
  }

  /// Tile dépliable générique
  Widget _buildExpandableTile({
    required String titre,
    required IconData icone,
    required Color couleur,
    required Widget contenu,
  }) {
    return ExpansionTile(
      leading: Icon(icone, color: couleur),
      title: Text(
        titre,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: couleur.shade700,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: contenu,
        ),
      ],
    );
  }

  /// Liste des ventes
  Widget _buildVentesList(List<VenteDetails> ventes) {
    return Column(
      children: ventes.map((vente) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        vente.produitNom,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '${vente.montantTotal.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Quantité: ${vente.quantite} ${vente.unite}'),
                Text('Prix unitaire: ${vente.prixUnitaire.toStringAsFixed(0)} FCFA'),
                if (vente.typeVente != null)
                  Text('Type: ${vente.typeVente}'),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Liste des crédits
  Widget _buildCreditsList(List<CreditDetails> credits) {
    return Column(
      children: credits.map((credit) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        credit.clientNom,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '${credit.montant.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Contact: ${credit.clientContact}'),
                Text('Date: ${DateFormat('dd/MM/yyyy').format(credit.dateCreation)}'),
                if (credit.motif != null)
                  Text('Motif: ${credit.motif}'),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Liste des restitutions
  Widget _buildRestitutionsList(List<RestitutionDetails> restitutions) {
    return Column(
      children: restitutions.map((restitution) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        restitution.produitNom,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '${restitution.montant.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Quantité: ${restitution.quantite} ${restitution.unite}'),
                Text('Date: ${DateFormat('dd/MM/yyyy').format(restitution.dateRestitution)}'),
                if (restitution.motif != null)
                  Text('Motif: ${restitution.motif}'),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Liste des pertes
  Widget _buildPertesList(List<PerteDetails> pertes) {
    return Column(
      children: pertes.map((perte) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        perte.produitNom,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '${perte.montant.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Quantité: ${perte.quantite} ${perte.unite}'),
                Text('Date: ${DateFormat('dd/MM/yyyy').format(perte.datePerte)}'),
                Text('Motif: ${perte.motif}'),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Détails des quantités d'origine
  Widget _buildQuantitesOrigineDetails(QuantitesOrigine quantites) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quantités et prix d\'origine',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...quantites.quantites.entries.map((entry) {
              final produit = entry.key;
              final details = entry.value as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            produit,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Qté: ${details['quantite']} ${details['unite']}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(details['prixUnitaire'] as double).toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const Divider(),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Valeur totale d\'origine:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${quantites.valeurTotale.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Boutons d'action
  Widget _buildActionButtons(TransactionCommerciale transaction, bool showValidation) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _voirDetailsComplets(transaction),
              icon: const Icon(Icons.visibility),
              label: const Text('Détails complets'),
            ),
          ),
          if (showValidation) ...[
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _rejeterTransaction(transaction),
                icon: const Icon(Icons.close),
                label: const Text('Rejeter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
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

  /// Voir les détails complets
  void _voirDetailsComplets(TransactionCommerciale transaction) {
    Get.dialog(
      _DialogDetailsCompletsTransaction(transaction: transaction),
      barrierDismissible: true,
    );
  }

  /// Valider une transaction
  Future<void> _validerTransaction(TransactionCommerciale transaction) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmer la validation'),
        content: Text(
          'Confirmez-vous la validation de la transaction de ${transaction.commercialNom} ?\n\n'
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
        await _service.validerTransactionAdmin(transaction.id, _userSession.nom ?? 'Admin');
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
    
    final confirm = await Get.dialog<bool>(
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
            onPressed: () => Get.back(result: false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (motifController.text.trim().isNotEmpty) {
                Get.back(result: true);
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

    if (confirm == true && motifController.text.trim().isNotEmpty) {
      try {
        await _service.rejeterTransactionAdmin(
          transaction.id, 
          _userSession.nom ?? 'Admin',
          motifController.text.trim(),
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

/// Dialog pour les détails complets d'une transaction
class _DialogDetailsCompletsTransaction extends StatelessWidget {
  final TransactionCommerciale transaction;

  const _DialogDetailsCompletsTransaction({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Détails complets - ${transaction.commercialNom}',
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
                    _buildSection('Informations générales', [
                      _buildDetailRow('Commercial', transaction.commercialNom),
                      _buildDetailRow('Site', transaction.site),
                      _buildDetailRow('Date terminée', 
                        DateFormat('dd/MM/yyyy à HH:mm').format(transaction.dateTerminee!)),
                      _buildDetailRow('Statut', transaction.statut.toString().split('.').last),
                      if (transaction.observations != null)
                        _buildDetailRow('Observations', transaction.observations!),
                    ]),
                    
                    _buildSection('Résumé financier détaillé', [
                      _buildDetailRow('Total ventes', '${transaction.resumeFinancier.totalVentes.toStringAsFixed(0)} FCFA'),
                      _buildDetailRow('Total crédits', '${transaction.resumeFinancier.totalCredits.toStringAsFixed(0)} FCFA'),
                      _buildDetailRow('Total restitutions', '${transaction.resumeFinancier.totalRestitutions.toStringAsFixed(0)} FCFA'),
                      _buildDetailRow('Total pertes', '${transaction.resumeFinancier.totalPertes.toStringAsFixed(0)} FCFA'),
                      _buildDetailRow('CA Net', '${transaction.resumeFinancier.chiffreAffairesNet.toStringAsFixed(0)} FCFA', isImportant: true),
                      _buildDetailRow('Espèces', '${transaction.resumeFinancier.espece.toStringAsFixed(0)} FCFA'),
                      _buildDetailRow('Mobile Money', '${transaction.resumeFinancier.mobile.toStringAsFixed(0)} FCFA'),
                      _buildDetailRow('Autres paiements', '${transaction.resumeFinancier.autres.toStringAsFixed(0)} FCFA'),
                      _buildDetailRow('Taux de conversion', '${transaction.resumeFinancier.tauxConversion.toStringAsFixed(1)}%'),
                    ]),
                    
                    _buildSection('Historique', [
                      if (transaction.dateRecuperee != null)
                        _buildDetailRow('Récupéré le', DateFormat('dd/MM/yyyy à HH:mm').format(transaction.dateRecuperee!)),
                      if (transaction.dateValidee != null)
                        _buildDetailRow('Validé le', DateFormat('dd/MM/yyyy à HH:mm').format(transaction.dateValidee!)),
                      if (transaction.validePar != null)
                        _buildDetailRow('Validé par', transaction.validePar!),
                      if (transaction.motifRejet != null)
                        _buildDetailRow('Motif rejet', transaction.motifRejet!),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String valeur, {bool isImportant = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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
                color: isImportant ? const Color(0xFF059669) : const Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}