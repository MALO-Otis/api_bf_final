import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/admin_reports_service.dart';

/// Dialog d'export des rapports
class ReportsExportDialog extends StatefulWidget {
  final AdminReportsService reportsService;
  final DateTime startDate;
  final DateTime endDate;
  final String selectedSite;

  const ReportsExportDialog({
    Key? key,
    required this.reportsService,
    required this.startDate,
    required this.endDate,
    required this.selectedSite,
  }) : super(key: key);

  @override
  State<ReportsExportDialog> createState() => _ReportsExportDialogState();
}

class _ReportsExportDialogState extends State<ReportsExportDialog> {
  String _selectedFormat = 'json';
  final List<String> _selectedSections = ['resume', 'production', 'commercial'];
  bool _isExporting = false;

  final Map<String, String> _formats = {
    'json': 'JSON',
    'csv': 'CSV',
    'excel': 'Excel',
    'pdf': 'PDF',
  };

  final Map<String, String> _sections = {
    'resume': 'Résumé général',
    'production': 'Données de production',
    'commercial': 'Données commerciales',
    'finances': 'Données financières',
    'performances': 'Indicateurs de performance',
    'activites': 'Activité récente',
  };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                const Icon(Icons.download, color: Color(0xFF2196F3)),
                const SizedBox(width: 8),
                const Text(
                  'Exporter les Rapports',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Informations sur la période
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Période sélectionnée:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                      'Du ${_formatDate(widget.startDate)} au ${_formatDate(widget.endDate)}'),
                  Text(
                      'Site: ${widget.selectedSite == 'all' ? 'Tous les sites' : widget.selectedSite}'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Format d'export
            const Text(
              'Format d\'export:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _formats.entries
                  .map((entry) => ChoiceChip(
                        label: Text(entry.value),
                        selected: _selectedFormat == entry.key,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedFormat = entry.key);
                          }
                        },
                        selectedColor: const Color(0xFF2196F3).withOpacity(0.2),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 20),

            // Sections à inclure
            const Text(
              'Sections à inclure:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: _sections.entries
                  .map((entry) => CheckboxListTile(
                        title: Text(entry.value),
                        value: _selectedSections.contains(entry.key),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedSections.add(entry.key);
                            } else {
                              _selectedSections.remove(entry.key);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                      ))
                  .toList(),
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isExporting ? null : () => Get.back(),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isExporting ? null : _exportData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: _isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Exporter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    if (_selectedSections.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez sélectionner au moins une section',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final result = await widget.reportsService.exportReports(
        format: _selectedFormat,
        startDate: widget.startDate,
        endDate: widget.endDate,
        site: widget.selectedSite,
      );

      if (result['success'] == true) {
        Get.back();
        _showExportSuccess(result['filename']);
      } else {
        Get.snackbar(
          'Erreur',
          result['error'] ?? 'Erreur lors de l\'export',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Une erreur est survenue: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _showExportSuccess(String filename) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Export Réussi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Les rapports ont été exportés avec succès.'),
            const SizedBox(height: 8),
            Text(
              'Fichier: $filename',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange[600], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Dans un environnement réel, le fichier serait téléchargé automatiquement.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// Widgets pour les autres sections des rapports (stubs pour éviter les erreurs)
class ReportsProductionStats extends StatelessWidget {
  final AdminReportsService reportsService;
  final bool isMobile;
  final bool isLoading;

  const ReportsProductionStats({
    Key? key,
    required this.reportsService,
    required this.isMobile,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text('Statistiques de production détaillées...'),
    );
  }
}

class ReportsProductionBySite extends StatelessWidget {
  final AdminReportsService reportsService;
  final bool isMobile;
  final bool isLoading;

  const ReportsProductionBySite({
    Key? key,
    required this.reportsService,
    required this.isMobile,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text('Production détaillée par site...'),
    );
  }
}

class ReportsCommercialStats extends StatelessWidget {
  final AdminReportsService reportsService;
  final bool isMobile;
  final bool isLoading;

  const ReportsCommercialStats({
    Key? key,
    required this.reportsService,
    required this.isMobile,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text('Statistiques commerciales (données de test)...'),
    );
  }
}

class ReportsCommercialCharts extends StatelessWidget {
  final AdminReportsService reportsService;
  final bool isMobile;
  final bool isLoading;

  const ReportsCommercialCharts({
    Key? key,
    required this.reportsService,
    required this.isMobile,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text('Graphiques commerciaux (données de test)...'),
    );
  }
}

class ReportsPerformanceComparisons extends StatelessWidget {
  final AdminReportsService reportsService;
  final bool isMobile;
  final bool isLoading;

  const ReportsPerformanceComparisons({
    Key? key,
    required this.reportsService,
    required this.isMobile,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text('Comparaisons de performances...'),
    );
  }
}

class ReportsObjectivesTracking extends StatelessWidget {
  final AdminReportsService reportsService;
  final bool isMobile;
  final bool isLoading;

  const ReportsObjectivesTracking({
    Key? key,
    required this.reportsService,
    required this.isMobile,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text('Suivi des objectifs...'),
    );
  }
}

class ReportsFinancialStats extends StatelessWidget {
  final AdminReportsService reportsService;
  final bool isMobile;
  final bool isLoading;

  const ReportsFinancialStats({
    Key? key,
    required this.reportsService,
    required this.isMobile,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text('Statistiques financières (données de test)...'),
    );
  }
}

class ReportsFinancialCharts extends StatelessWidget {
  final AdminReportsService reportsService;
  final bool isMobile;
  final bool isLoading;

  const ReportsFinancialCharts({
    Key? key,
    required this.reportsService,
    required this.isMobile,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text('Graphiques financiers (données de test)...'),
    );
  }
}
