import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../controllers/geographie_management_controller.dart';
import '../screens/administration/pages/geographie_management_page.dart';
import '../screens/administration/services/geographie_management_service.dart';

class GeographieManagementWidget extends StatelessWidget {
  const GeographieManagementWidget({Key? key}) : super(key: key);

  // Couleur primaire du thème
  static const Color primaryColor = Color(0xFFF49101);

  // Initialiser les services si nécessaire
  void _ensureServicesInitialized() {
    try {
      Get.find<GeographieManagementController>();
    } catch (e) {
      // Les services ne sont pas encore initialisés, les créer
      Get.put(GeographieManagementService());
      Get.put(GeographieManagementController());
    }
  }

  @override
  Widget build(BuildContext context) {
    // S'assurer que les services sont initialisés
    _ensureServicesInitialized();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor,
                  primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.public,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gestion Géographique',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gérez les régions, provinces, communes et villages de la plateforme',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Boutons d'action rapide
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Ligne de boutons principaux
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.settings,
                        label: 'Gestion Complète',
                        subtitle: 'Interface complète',
                        color: primaryColor,
                        onTap: () => _openFullManagement(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.add_location,
                        label: 'Ajout Rapide',
                        subtitle: 'Ajouter des données',
                        color: Colors.green,
                        onTap: () => _showQuickAddDialog(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Ligne de boutons secondaires
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.search,
                        label: 'Rechercher',
                        subtitle: 'Trouver une localité',
                        color: Colors.blue,
                        onTap: () => _showSearchDialog(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.analytics,
                        label: 'Statistiques',
                        subtitle: 'Vue d\'ensemble',
                        color: Colors.orange,
                        onTap: () => _showStatisticsDialog(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Aperçu rapide des données
          _buildQuickOverview(),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickOverview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.dashboard,
                color: primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Aperçu Rapide',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Indicateurs rapides
          Row(
            children: [
              Expanded(
                child: _buildQuickStat('17', 'Régions', Icons.map, Colors.blue),
              ),
              Expanded(
                child: _buildQuickStat(
                    '45+', 'Provinces', Icons.location_city, Colors.green),
              ),
              Expanded(
                child: _buildQuickStat(
                    '100+', 'Communes', Icons.business, Colors.orange),
              ),
              Expanded(
                child: _buildQuickStat(
                    '1000+', 'Villages', Icons.home, Colors.purple),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Actions rapides
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openFullManagement(),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Ouvrir la gestion'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showQuickAddDialog(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Ajout rapide'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
      String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _openFullManagement() {
    Get.to(
      () => const GeographieManagementPage(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _showQuickAddDialog() {
    final controller = Get.find<GeographieManagementController>();

    // Dialogue de raccourci pour ajouter une région rapidement
    final nameController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Ajouter une région'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la région',
                hintText: 'Ex: Nouvelle Région (ANCIEN NOM)',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Text(
              'Vous pouvez utiliser l\'interface complète pour plus d\'options.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final success = await controller.addRegion(name);
                if (success) {
                  Get.back();
                  Get.snackbar(
                    'Succès',
                    'Région "$name" ajoutée avec succès',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                }
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Rechercher une localité'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Rechercher',
                  hintText: 'Nom de région, province, commune ou village',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  // La recherche sera mise à jour en temps réel dans l'interface complète
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Utilisez l\'interface complète pour des résultats de recherche détaillés.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Fermer'),
          ),
          FilledButton(
            onPressed: () {
              Get.back();
              _openFullManagement();
            },
            child: const Text('Interface complète'),
          ),
        ],
      ),
    );
  }

  void _showStatisticsDialog() {
    final controller = Get.find<GeographieManagementController>();
    final stats = controller.getStatistics();

    Get.dialog(
      AlertDialog(
        title: const Text('Statistiques Géographiques'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Données actuellement chargées :',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildStatRow(
                'Régions', stats['regions']?.toString() ?? '0', Icons.map),
            _buildStatRow('Provinces', stats['provinces']?.toString() ?? '0',
                Icons.location_city),
            _buildStatRow('Communes', stats['communes']?.toString() ?? '0',
                Icons.business),
            _buildStatRow(
                'Villages', stats['villages']?.toString() ?? '0', Icons.home),
            const SizedBox(height: 16),
            Obx(() {
              final hasPending = controller.hasPendingChanges.value;
              if (hasPending) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Modifications non sauvegardées',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Fermer'),
          ),
          FilledButton(
            onPressed: () {
              Get.back();
              _openFullManagement();
            },
            child: const Text('Interface complète'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: primaryColor),
          const SizedBox(width: 8),
          Text('$label: '),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
