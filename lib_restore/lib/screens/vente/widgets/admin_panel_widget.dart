/// 👤 PANNEAU D'ADMINISTRATION COMMERCIAL
///
/// Interface pour les administrateurs permettant de :
/// - Voir tous les commerciaux et leurs attributions
/// - Impersonifier un commercial
/// - Gérer les attributions en tant qu'admin

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../services/commercial_service.dart';

class AdminPanelWidget extends StatefulWidget {
  final CommercialService commercialService;

  const AdminPanelWidget({
    super.key,
    required this.commercialService,
  });

  @override
  State<AdminPanelWidget> createState() => _AdminPanelWidgetState();
}

class _AdminPanelWidgetState extends State<AdminPanelWidget> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Vérifier les permissions
      if (!widget.commercialService.estAdmin) {
        return _buildAccessDenied();
      }

      return Column(
        children: [
          _buildAdminHeader(),
          _buildImpersonificationPanel(),
          if (widget.commercialService.estEnModeImpersonification)
            _buildImpersonificationBanner(),
          const SizedBox(height: 16),
          Expanded(child: _buildCommerciauxList()),
        ],
      );
    });
  }

  Widget _buildAccessDenied() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.admin_panel_settings_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Accès Administrateur Requis',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous n\'avez pas les permissions nécessaires pour accéder à cette section.',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.admin_panel_settings,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panneau d\'Administration',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Gestion avancée des commerciaux et attributions',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.commercialService.roleUtilisateur.name.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpersonificationPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_pin, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Impersonification Commercial',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Sélectionnez un commercial pour agir en son nom et gérer ses attributions.',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() => DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Choisir un commercial',
                  prefixIcon: const Icon(Icons.person, size: 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                value: widget.commercialService.estEnModeImpersonification
                    ? widget.commercialService.contexteImpersonification
                        ?.commercialId
                    : null,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('-- Mode Administrateur --'),
                  ),
                  ...widget.commercialService.commerciauxDisponibles.map(
                    (commercial) => DropdownMenuItem(
                      value: commercial['id'],
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              (commercial['nom'] as String).isNotEmpty
                                  ? (commercial['nom'] as String)[0]
                                      .toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  commercial['nom'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Site: ${commercial['site']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => _handleImpersonificationChange(value),
              )),
        ],
      ),
    );
  }

  Widget _buildImpersonificationBanner() {
    final contexte = widget.commercialService.contexteImpersonification!;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🎭 Mode Impersonification Actif',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                Text(
                  'Vous agissez en tant que: ${contexte.commercialNom}',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _arreterImpersonification(),
            child: const Text('Arrêter'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommerciauxList() {
    return Obx(() {
      final commerciaux = widget.commercialService.commerciauxDisponibles;
      if (commerciaux.isEmpty) {
        return _buildEmptyCommerciauxList();
      }

      return ListView.builder(
        itemCount: commerciaux.length,
        itemBuilder: (context, index) {
          final commercial = commerciaux[index];
          return _buildCommercialCard(commercial);
        },
      );
    });
  }

  Widget _buildEmptyCommerciauxList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun commercial disponible',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommercialCard(Map<String, dynamic> commercial) {
    // Calculer les statistiques du commercial
    final attributionsCommercial = widget.commercialService.attributions
        .where((attr) => attr.commercialNom == commercial['nom'])
        .toList();

    final totalAttributions = attributionsCommercial.length;
    final valeurTotale = attributionsCommercial.fold(
        0.0, (sum, attr) => sum + attr.valeurTotale);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    (commercial['nom'] as String).isNotEmpty
                        ? (commercial['nom'] as String)[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        commercial['nom'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Site: ${commercial['site']}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.commercialService.permissions
                        ?.peutImpersonifierCommercial ==
                    true)
                  ElevatedButton.icon(
                    onPressed: () => _impersonifierCommercial(
                      commercial['id'] as String,
                      commercial['nom'] as String,
                    ),
                    icon: const Icon(Icons.person_pin, size: 16),
                    label: const Text('Impersonifier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Attributions',
                    '$totalAttributions',
                    Icons.assignment_turned_in,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Valeur totale',
                    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA')
                        .format(valeurTotale),
                    Icons.monetization_on,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
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
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _handleImpersonificationChange(String? commercialId) async {
    if (commercialId == null) {
      // Arrêter l'impersonification
      await _arreterImpersonification();
    } else {
      // Démarrer l'impersonification
      final commercial = widget.commercialService.commerciauxDisponibles
          .firstWhere((c) => c['id'] == commercialId);
      await _impersonifierCommercial(commercialId, commercial['nom'] as String);
    }
  }

  Future<void> _impersonifierCommercial(
      String commercialId, String commercialNom) async {
    final success = await widget.commercialService.impersonifierCommercial(
      commercialId,
      commercialNom,
    );

    if (success) {
      Get.snackbar(
        '🎭 Impersonification Active',
        'Vous agissez maintenant en tant que $commercialNom',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        duration: const Duration(seconds: 3),
      );
    } else {
      Get.snackbar(
        'Erreur',
        'Impossible de démarrer l\'impersonification',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  Future<void> _arreterImpersonification() async {
    final success = await widget.commercialService.arreterImpersonification();

    if (success) {
      Get.snackbar(
        '✅ Impersonification Arrêtée',
        'Retour au mode administrateur',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        duration: const Duration(seconds: 2),
      );
    }
  }
}
