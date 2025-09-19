import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/report_models.dart';
import '../../../data/services/enhanced_pdf_service.dart';

/// Page de test pour les rapports PDF améliorés
class TestRapportsAmeliores extends StatefulWidget {
  const TestRapportsAmeliores({Key? key}) : super(key: key);

  @override
  State<TestRapportsAmeliores> createState() => _TestRapportsAmeliorésState();
}

class _TestRapportsAmeliorésState extends State<TestRapportsAmeliores> {
  bool _isLoading = false;

  /// Génère un rapport de test avec des données fictives
  RapportStatistiques _genererRapportTest() {
    // Créer des données de test
    final collecte = CollecteRapportData(
      id: 'TEST_001',
      site: 'Site de Test ApiSavana',
      typeCollecte: TypeCollecteRapport.recolte,
      date: DateTime.now(),
      technicienNom: 'Technicien Test',
      nomSource: 'Producteur Test',
      localisation: {
        'region': 'Région Test',
        'departement': 'Département Test',
        'commune': 'Commune Test',
        'quartier': 'Quartier Test',
      },
      observations: 'Test des rapports PDF améliorés',
      contenants: [
        ContenantRapportData(
          type: 'Bidon 25L',
          typeMiel: 'Miel de Fleurs',
          quantite: 22.5,
          prixUnitaire: 2500,
        ),
        ContenantRapportData(
          type: 'Bidon 20L',
          typeMiel: 'Miel d\'Acacia',
          quantite: 18.0,
          prixUnitaire: 3000,
        ),
        ContenantRapportData(
          type: 'Pot 1kg',
          typeMiel: 'Miel de Tournesol',
          quantite: 0.8,
          prixUnitaire: 4000,
        ),
        ContenantRapportData(
          type: 'Bidon 25L',
          typeMiel: 'Miel de Fleurs',
          quantite: 24.0,
          prixUnitaire: 2500,
        ),
      ],
    );

    return RapportStatistiques.generer(collecte);
  }

  /// Génère un reçu de test avec des données fictives
  RecuCollecte _genererRecuTest() {
    final collecte = _genererRapportTest().collecte;
    return RecuCollecte.generer(collecte);
  }

  /// Teste le téléchargement du rapport statistiques
  Future<void> _testerRapportStatistiques() async {
    setState(() => _isLoading = true);
    try {
      final rapport = _genererRapportTest();
      final pdfBytes = await EnhancedPdfService.genererRapportStatistiquesAmeliore(rapport);
      
      await EnhancedPdfService.downloadPdf(
        pdfBytes,
        'test_rapport_stats_${DateTime.now().millisecondsSinceEpoch}.pdf',
        title: 'Test Rapport Statistiques',
        description: 'Test des rapports PDF améliorés - ApiSavana',
      );
      
      Get.snackbar(
        'Succès',
        'Rapport statistiques de test téléchargé !',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors du test: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Teste le téléchargement du reçu de collecte
  Future<void> _testerRecuCollecte() async {
    setState(() => _isLoading = true);
    try {
      final recu = _genererRecuTest();
      final pdfBytes = await EnhancedPdfService.genererRecuCollecteAmeliore(recu);
      
      await EnhancedPdfService.downloadPdf(
        pdfBytes,
        'test_recu_collecte_${DateTime.now().millisecondsSinceEpoch}.pdf',
        title: 'Test Reçu de Collecte',
        description: 'Test des reçus PDF améliorés - ApiSavana',
      );
      
      Get.snackbar(
        'Succès',
        'Reçu de collecte de test téléchargé !',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors du test: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Teste l'impression du rapport
  Future<void> _testerImpressionRapport() async {
    setState(() => _isLoading = true);
    try {
      final rapport = _genererRapportTest();
      final pdfBytes = await EnhancedPdfService.genererRapportStatistiquesAmeliore(rapport);
      
      await EnhancedPdfService.printPdf(
        pdfBytes,
        'Test Rapport Statistiques',
      );
      
      Get.snackbar(
        'Succès',
        'Rapport envoyé à l\'impression !',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        icon: const Icon(Icons.print, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de l\'impression: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Rapports PDF Améliorés'),
        backgroundColor: const Color(0xFFF49101),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF49101), Color(0xFF0066CC)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Icon(Icons.analytics, color: Colors.white, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Test des Rapports PDF Améliorés',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Testez les nouvelles fonctionnalités de génération PDF',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Description
            const Text(
              'Fonctionnalités testées :',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Design moderne avec gradients et couleurs'),
            const Text('• Tableaux parfaits avec alternance de couleurs'),
            const Text('• Graphiques visuels avec barres de progression'),
            const Text('• Téléchargement multiplateforme (Web, Desktop, Mobile)'),
            const Text('• Impression directe système'),

            const SizedBox(height: 24),

            // Boutons de test
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  // Test Rapport Statistiques
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _testerRapportStatistiques,
                      icon: const Icon(Icons.analytics),
                      label: const Text('Tester Rapport Statistiques'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Test Reçu Collecte
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _testerRecuCollecte,
                      icon: const Icon(Icons.receipt),
                      label: const Text('Tester Reçu de Collecte'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Test Impression
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _testerImpressionRapport,
                      icon: const Icon(Icons.print),
                      label: const Text('Tester Impression'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Informations techniques
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ℹ️ Informations',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Les PDFs sont générés avec des données de test'),
                  Text('• Le téléchargement fonctionne sur toutes les plateformes'),
                  Text('• L\'impression utilise le système natif'),
                  Text('• Les designs sont optimisés pour l\'impression A4'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
