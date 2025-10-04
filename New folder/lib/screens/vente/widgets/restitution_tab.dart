/// 🔄 ONGLET RESTITUTION
///
/// Interface pour gérer les restitutions de produits :
/// - Restitutions par les commerciaux
/// - Produits invendus
/// - Produits défectueux
/// - Historique des restitutions

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../models/commercial_models.dart';
import '../services/commercial_service.dart';

class RestitutionTab extends StatefulWidget {
  final CommercialService commercialService;

  const RestitutionTab({
    super.key,
    required this.commercialService,
  });

  @override
  State<RestitutionTab> createState() => _RestitutionTabState();
}

class _RestitutionTabState extends State<RestitutionTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final RxList<Map<String, dynamic>> _restitutions = <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _loadRestitutions();
  }

  Future<void> _loadRestitutions() async {
    try {
      _isLoading.value = true;
      // TODO: Charger les vraies restitutions depuis Firestore
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Données mockées pour la démonstration
      _restitutions.value = [
        {
          'id': 'rest_1',
          'commercial': 'YAMEOGO Rose',
          'produit': '1Kg - Lot-272-846',
          'quantite': 5,
          'motif': 'Produits invendus',
          'date': DateTime.now().subtract(const Duration(days: 1)),
          'statut': 'en_attente',
        },
      ];
      
      debugPrint('✅ [RestitutionTab] ${_restitutions.length} restitutions chargées');
    } catch (e) {
      debugPrint('❌ [RestitutionTab] Erreur chargement restitutions: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  void _creerRestitution() {
    // TODO: Implémenter la création de restitution
    Get.snackbar(
      'En développement',
      'Cette fonctionnalité sera bientôt disponible',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creerRestitution,
        icon: const Icon(Icons.assignment_return),
        label: const Text('Nouvelle Restitution'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.assignment_return, size: 32, color: Colors.orange.shade700),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestion des Restitutions',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                Obx(() => Text(
                  '${_restitutions.length} restitutions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade600,
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Obx(() {
      if (_isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_restitutions.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _restitutions.length,
        itemBuilder: (context, index) {
          final restitution = _restitutions[index];
          return _buildRestitutionCard(restitution);
        },
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.assignment_return_outlined,
              size: 50,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune restitution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les restitutions de produits apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestitutionCard(Map<String, dynamic> restitution) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restitution['commercial'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        restitution['produit'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    restitution['statut'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Quantité: ${restitution['quantite']}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Motif: ${restitution['motif']}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Date: ${DateFormat('dd/MM/yyyy à HH:mm').format(restitution['date'])}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

