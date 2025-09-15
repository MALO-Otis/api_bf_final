import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/report_models.dart';
import '../../../data/services/reports_service.dart';
import '../../../data/services/enhanced_pdf_service.dart';

/// Modal pour afficher et gérer les rapports d'une collecte
class RapportModal extends StatefulWidget {
  final Map<String, dynamic> collecteData;

  const RapportModal({
    super.key,
    required this.collecteData,
  });

  @override
  State<RapportModal> createState() => _RapportModalState();
}

class _RapportModalState extends State<RapportModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  CollecteRapportData? _collecteRapport;
  RapportStatistiques? _rapportStats;
  RecuCollecte? _recuCollecte;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      print(
          '🔄 RAPPORT: Initialisation des données pour ${widget.collecteData['type']}');
      print('   Données brutes: ${widget.collecteData.keys.toList()}');
      _collecteRapport =
          CollecteRapportData.fromHistoriqueData(widget.collecteData);
      print(
          '✅ RAPPORT: Données de collecte initialisées - ${_collecteRapport!.contenants.length} contenants');
    } catch (e) {
      print('❌ RAPPORT: Erreur initialisation données: $e');
      Get.snackbar(
          'Erreur', 'Impossible de charger les données de collecte: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _genererRapportStatistiques() async {
    if (_collecteRapport == null) return;

    setState(() => _isLoading = true);
    try {
      _rapportStats =
          await ReportsService.genererRapportStatistiques(_collecteRapport!);
      setState(() {});
      Get.snackbar(
        'Succès',
        'Rapport statistiques généré avec succès',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de la génération du rapport: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _genererRecuCollecte() async {
    if (_collecteRapport == null) return;

    setState(() => _isLoading = true);
    try {
      _recuCollecte =
          await ReportsService.genererRecuCollecte(_collecteRapport!);
      setState(() {});
      Get.snackbar(
        'Succès',
        'Reçu de collecte généré avec succès',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de la génération du reçu: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exporterPdfStatistiques() async {
    if (_rapportStats == null) return;

    setState(() => _isLoading = true);
    try {
      final pdfBytes =
          await EnhancedPdfService.genererRapportStatistiquesAmeliore(
              _rapportStats!);
      final filename = 'rapport_stats_${_rapportStats!.numeroRapport}.pdf';

      await EnhancedPdfService.downloadPdf(
        pdfBytes,
        filename,
        title: 'Rapport Statistiques ${_rapportStats!.numeroRapport}',
        description:
            'Rapport de collecte ApiSavana - ${_rapportStats!.collecte.site}',
      );

      Get.snackbar(
        'Succès',
        'PDF téléchargé avec succès !',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.download_done, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors du téléchargement: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exporterPdfRecu() async {
    if (_recuCollecte == null) return;

    setState(() => _isLoading = true);
    try {
      final pdfBytes =
          await EnhancedPdfService.genererRecuCollecteAmeliore(_recuCollecte!);
      final filename = 'recu_collecte_${_recuCollecte!.numeroRecu}.pdf';

      await EnhancedPdfService.downloadPdf(
        pdfBytes,
        filename,
        title: 'Reçu de Collecte ${_recuCollecte!.numeroRecu}',
        description:
            'Reçu officiel de collecte ApiSavana - ${_recuCollecte!.collecte.site}',
      );

      Get.snackbar(
        'Succès',
        'Reçu PDF téléchargé avec succès !',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.download_done, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors du téléchargement: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _imprimerRapportStatistiques() async {
    if (_rapportStats == null) return;

    setState(() => _isLoading = true);
    try {
      final pdfBytes =
          await EnhancedPdfService.genererRapportStatistiquesAmeliore(
              _rapportStats!);
      await EnhancedPdfService.printPdf(
        pdfBytes,
        'Rapport Statistiques ${_rapportStats!.numeroRapport}',
      );

      Get.snackbar(
        'Succès',
        'Document envoyé à l\'impression',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        icon: const Icon(Icons.print, color: Colors.white),
        duration: const Duration(seconds: 2),
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

  Future<void> _imprimerRecuCollecte() async {
    if (_recuCollecte == null) return;

    setState(() => _isLoading = true);
    try {
      final pdfBytes =
          await EnhancedPdfService.genererRecuCollecteAmeliore(_recuCollecte!);
      await EnhancedPdfService.printPdf(
        pdfBytes,
        'Reçu de Collecte ${_recuCollecte!.numeroRecu}',
      );

      Get.snackbar(
        'Succès',
        'Reçu envoyé à l\'impression',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        icon: const Icon(Icons.print, color: Colors.white),
        duration: const Duration(seconds: 2),
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
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // En-tête
            _buildHeader(),
            const SizedBox(height: 16),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: Colors.orange,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.orange,
              tabs: const [
                Tab(
                  icon: Icon(Icons.analytics),
                  text: 'Rapport Statistiques',
                ),
                Tab(
                  icon: Icon(Icons.receipt),
                  text: 'Reçu de Collecte',
                ),
              ],
            ),

            // Contenu
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRapportStatistiquesTab(),
                        _buildRecuCollecteTab(),
                      ],
                    ),
            ),

            // Actions
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF49101), Color(0xFFFF6B35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.analytics,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'RAPPORTS DE COLLECTE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Téléchargement • Impression • Partage',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          if (_collecteRapport != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Collecte ${_collecteRapport!.typeCollecte.label}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ID: ${_collecteRapport!.id}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRapportStatistiquesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bouton génération
          if (_rapportStats == null)
            Center(
              child: ElevatedButton.icon(
                onPressed: _genererRapportStatistiques,
                icon: const Icon(Icons.analytics),
                label: const Text('Générer Rapport Statistiques'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            )
          else ...[
            // Aperçu du rapport
            _buildRapportStatistiquesPreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildRapportStatistiquesPreview() {
    if (_rapportStats == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête du rapport
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              Text(
                'RAPPORT STATISTIQUES',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'N° ${_rapportStats!.numeroRapport}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue.shade600,
                ),
              ),
              Text(
                'Généré le ${_rapportStats!.dateGenerationFormatee}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Statistiques principales
        _buildStatistiquesGrid(),

        const SizedBox(height: 16),

        // Répartitions
        _buildRepartitionsSection(),

        const SizedBox(height: 16),

        // Actions améliorées
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _exporterPdfStatistiques,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Télécharger PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _imprimerRapportStatistiques,
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Imprimer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _genererRapportStatistiques(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Régénérer le rapport'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatistiquesGrid() {
    if (_rapportStats == null) return const SizedBox();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _buildStatCard(
          'Contenants',
          '${_rapportStats!.nombreContenants}',
          Icons.inventory,
          Colors.green,
        ),
        _buildStatCard(
          'Poids Total',
          _rapportStats!.collecte.poidsFormatte,
          Icons.scale,
          Colors.orange,
        ),
        _buildStatCard(
          'Montant Total',
          _rapportStats!.collecte.montantFormatte,
          Icons.text_fields,
          Colors.purple,
        ),
        _buildStatCard(
          'Prix Moyen/kg',
          _rapportStats!.prixMoyenFormatte,
          Icons.trending_up,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepartitionsSection() {
    if (_rapportStats == null) return const SizedBox();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildRepartitionCard(
            'Répartition par Type',
            _rapportStats!.repartitionParType.entries
                .map((e) => '${e.key}: ${e.value}')
                .toList(),
            Colors.teal,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildRepartitionCard(
            'Répartition par Miel (kg)',
            _rapportStats!.repartitionParMiel.entries
                .map((e) => '${e.key}: ${e.value.toStringAsFixed(2)}')
                .toList(),
            Colors.indigo,
          ),
        ),
      ],
    );
  }

  Widget _buildRepartitionCard(String title, List<String> items, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $item',
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRecuCollecteTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bouton génération
          if (_recuCollecte == null)
            Center(
              child: ElevatedButton.icon(
                onPressed: _genererRecuCollecte,
                icon: const Icon(Icons.receipt),
                label: const Text('Générer Reçu de Collecte'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            )
          else ...[
            // Aperçu du reçu
            _buildRecuCollectePreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildRecuCollectePreview() {
    if (_recuCollecte == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête du reçu
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            children: [
              Text(
                'REÇU DE COLLECTE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'N° ${_recuCollecte!.numeroRecu}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green.shade600,
                ),
              ),
              Text(
                'Émis le ${_recuCollecte!.dateGenerationFormatee}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Informations de collecte
        _buildInfosCollecteSection(),

        const SizedBox(height: 16),

        // Totaux
        _buildTotauxSection(),

        const SizedBox(height: 16),

        // Message
        _buildMessageSection(),

        const SizedBox(height: 16),

        // Actions améliorées
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _exporterPdfRecu,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Télécharger PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _imprimerRecuCollecte,
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Imprimer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _genererRecuCollecte(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Régénérer le reçu'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfosCollecteSection() {
    if (_recuCollecte == null) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INFORMATIONS DE COLLECTE',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Date:', _recuCollecte!.collecte.dateFormatee),
          _buildInfoRow('Type:', _recuCollecte!.collecte.typeCollecte.label),
          _buildInfoRow('Source:', _recuCollecte!.collecte.nomSource),
          _buildInfoRow('Technicien:', _recuCollecte!.collecte.technicienNom),
          _buildInfoRow(
              'Localisation:', _recuCollecte!.collecte.localisationComplete),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotauxSection() {
    if (_recuCollecte == null) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              const Text(
                'POIDS TOTAL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _recuCollecte!.collecte.poidsFormatte,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          Column(
            children: [
              const Text(
                'MONTANT TOTAL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _recuCollecte!.collecte.montantFormatte,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageSection() {
    if (_recuCollecte == null) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          const Text(
            '💝 MESSAGE DE REMERCIEMENT',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _recuCollecte!.messageRemerciement,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
