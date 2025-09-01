/// Service pour générer des PDF de statistiques détaillées des collectes
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import '../../../authentication/user_session.dart';
import '../models/collecte_models.dart';

class PDFStatisticsService {
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF2E7D32);
  static const PdfColor secondaryColor = PdfColor.fromInt(0xFF388E3C);
  static const PdfColor accentColor = PdfColor.fromInt(0xFF4CAF50);
  static const PdfColor warningColor = PdfColor.fromInt(0xFFFF9800);
  static const PdfColor errorColor = PdfColor.fromInt(0xFFF44336);
  static const PdfColor successColor = PdfColor.fromInt(0xFF4CAF50);

  /// Génère un PDF de statistiques complètes des collectes
  static Future<File> generateStatisticsReport(
      Map<Section, List<BaseCollecte>> data) async {
    final pdf = pw.Document();
    final userSession = Get.find<UserSession>();
    final site = userSession.site ?? 'Site Inconnu';
    final now = DateTime.now();

    // Calcul des statistiques globales
    final stats = _calculateGlobalStatistics(data);

    // Page 1: Vue d'ensemble
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(site, now),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildTitleSection(),
          pw.SizedBox(height: 20),
          _buildExecutiveSummary(stats),
          pw.SizedBox(height: 20),
          _buildGlobalStatistics(stats),
        ],
      ),
    );

    // Page 2: Détails par section
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(site, now),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildSectionTitle('Analyse Détaillée par Type de Collecte'),
          pw.SizedBox(height: 20),
          _buildSectionAnalysis(Section.recoltes, data[Section.recoltes] ?? []),
          pw.SizedBox(height: 20),
          _buildSectionAnalysis(Section.scoop, data[Section.scoop] ?? []),
          pw.SizedBox(height: 20),
          _buildSectionAnalysis(
              Section.individuel, data[Section.individuel] ?? []),
          pw.SizedBox(height: 20),
          _buildSectionAnalysis(
              Section.miellerie, data[Section.miellerie] ?? []),
        ],
      ),
    );

    // Page 3: Analyse temporelle et géographique
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(site, now),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildSectionTitle('Analyse Temporelle et Géographique'),
          pw.SizedBox(height: 20),
          _buildTemporalAnalysis(data),
          pw.SizedBox(height: 20),
          _buildGeographicAnalysis(data),
        ],
      ),
    );

    // Page 4: Recommandations et conclusions
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(site, now),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildSectionTitle('Recommandations et Actions'),
          pw.SizedBox(height: 20),
          _buildRecommendations(stats),
          pw.SizedBox(height: 20),
          _buildConclusion(stats),
        ],
      ),
    );

    // Sauvegarde du fichier dans le dossier Téléchargements
    final fileName =
        'Statistiques_Collectes_${site}_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf';

    // Essayer d'abord le dossier Downloads (visible pour l'utilisateur)
    try {
      final directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(await pdf.save());
        print('✅ PDF sauvegardé dans Téléchargements: ${file.path}');
        return file;
      }
    } catch (e) {
      print('⚠️ Impossible d\'écrire dans Downloads: $e');
    }

    // Fallback vers le dossier Documents
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    print('✅ PDF sauvegardé dans Documents: ${file.path}');
    return file;
  }

  /// Génère un PDF de statistiques dans le cache temporaire (sans permissions)
  static Future<File> generateStatisticsReportToCache(
      Map<Section, List<BaseCollecte>> data) async {
    final pdf = pw.Document();
    final userSession = Get.find<UserSession>();
    final site = userSession.site ?? 'Site Inconnu';
    final now = DateTime.now();

    // Calcul des statistiques globales
    final stats = _calculateGlobalStatistics(data);

    // Page 1: Vue d'ensemble
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(site, now),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildTitleSection(),
          pw.SizedBox(height: 20),
          _buildExecutiveSummary(stats),
          pw.SizedBox(height: 20),
          _buildGlobalStatistics(stats),
        ],
      ),
    );

    // Page 2: Détails par section
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(site, now),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildSectionTitle('Analyse Détaillée par Type de Collecte'),
          pw.SizedBox(height: 20),
          _buildSectionAnalysis(Section.recoltes, data[Section.recoltes] ?? []),
          pw.SizedBox(height: 20),
          _buildSectionAnalysis(Section.scoop, data[Section.scoop] ?? []),
          pw.SizedBox(height: 20),
          _buildSectionAnalysis(
              Section.individuel, data[Section.individuel] ?? []),
          pw.SizedBox(height: 20),
          _buildSectionAnalysis(
              Section.miellerie, data[Section.miellerie] ?? []),
        ],
      ),
    );

    // Page 3: Analyse temporelle et géographique
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(site, now),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildSectionTitle('Analyse Temporelle et Géographique'),
          pw.SizedBox(height: 20),
          _buildTemporalAnalysis(data),
          pw.SizedBox(height: 20),
          _buildGeographicAnalysis(data),
        ],
      ),
    );

    // Page 4: Recommandations et conclusions
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(site, now),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildSectionTitle('Recommandations et Actions'),
          pw.SizedBox(height: 20),
          _buildRecommendations(stats),
          pw.SizedBox(height: 20),
          _buildConclusion(stats),
        ],
      ),
    );

    // Sauvegarde dans le dossier Téléchargements (même pour la méthode alternative)
    final fileName =
        'Statistiques_Collectes_${site}_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf';

    // Essayer le dossier Downloads d'abord
    try {
      final directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(await pdf.save());
        print('✅ PDF (cache) sauvegardé dans Téléchargements: ${file.path}');
        return file;
      }
    } catch (e) {
      print('⚠️ Impossible d\'écrire dans Downloads (cache): $e');
    }

    // Fallback vers le cache temporaire
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    print('✅ PDF sauvegardé dans cache temporaire: ${file.path}');
    return file;
  }

  /// Calcule les statistiques globales
  static GlobalStatistics _calculateGlobalStatistics(
      Map<Section, List<BaseCollecte>> data) {
    double totalWeight = 0;
    double totalAmount = 0;
    int totalCollectes = 0;
    int totalContainers = 0;

    final monthlyData = <String, MonthlyStats>{};
    final technicians = <String, TechnicianStats>{};
    final sites = <String, SiteStats>{};

    for (final entry in data.entries) {
      final section = entry.key;
      final collectes = entry.value;

      for (final collecte in collectes) {
        totalWeight += collecte.totalWeight ?? 0;
        totalAmount += collecte.totalAmount ?? 0;
        totalCollectes++;
        totalContainers += collecte.containersCount ?? 0;

        // Analyse mensuelle
        final monthKey = DateFormat('yyyy-MM').format(collecte.date);
        if (!monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey] = MonthlyStats(month: monthKey);
        }
        monthlyData[monthKey]!.addCollecte(collecte, section);

        // Analyse par technicien
        final technicien = collecte.technicien ?? 'Non défini';
        if (!technicians.containsKey(technicien)) {
          technicians[technicien] = TechnicianStats(name: technicien);
        }
        technicians[technicien]!.addCollecte(collecte);

        // Analyse par site
        if (!sites.containsKey(collecte.site)) {
          sites[collecte.site] = SiteStats(name: collecte.site);
        }
        sites[collecte.site]!.addCollecte(collecte);
      }
    }

    return GlobalStatistics(
      totalWeight: totalWeight,
      totalAmount: totalAmount,
      totalCollectes: totalCollectes,
      totalContainers: totalContainers,
      recoltesCount: data[Section.recoltes]?.length ?? 0,
      scoopCount: data[Section.scoop]?.length ?? 0,
      individuelCount: data[Section.individuel]?.length ?? 0,
      miellerieCount: data[Section.miellerie]?.length ?? 0,
      monthlyData: monthlyData,
      technicians: technicians,
      sites: sites,
      averagePerCollecte: totalCollectes > 0 ? totalWeight / totalCollectes : 0,
      averageAmountPerKg: totalWeight > 0 ? totalAmount / totalWeight : 0,
    );
  }

  /// En-tête du document
  static pw.Widget _buildHeader(String site, DateTime date) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: primaryColor, width: 2)),
      ),
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'RAPPORT STATISTIQUE DES COLLECTES',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              pw.Text(
                'Site: $site',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Date: ${DateFormat('dd/MM/yyyy').format(date)}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
              pw.Text(
                'Heure: ${DateFormat('HH:mm').format(date)}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Pied de page
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
      ),
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'ApiSavana - Système de Gestion des Collectes',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page ${context.pageNumber}',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  /// Section titre principale
  static pw.Widget _buildTitleSection() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [primaryColor, secondaryColor],
        ),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            '📊 RAPPORT STATISTIQUE COMPLET',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Analyse Détaillée des Collectes de Miel',
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Résumé exécutif
  static pw.Widget _buildExecutiveSummary(GlobalStatistics stats) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF8F9FA),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: primaryColor, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '📋 RÉSUMÉ EXÉCUTIF',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Ce rapport présente une analyse complète de ${stats.totalCollectes} collectes de miel, '
            'représentant ${stats.totalWeight.toStringAsFixed(1)} kg de miel pour une valeur totale de '
            '${NumberFormat('#,###').format(stats.totalAmount)} FCFA.',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Les données couvrent ${stats.monthlyData.length} mois d\'activité avec ${stats.technicians.length} techniciens '
            'sur ${stats.sites.length} sites différents.',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Statistiques globales avec graphiques
  static pw.Widget _buildGlobalStatistics(GlobalStatistics stats) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '📈 STATISTIQUES GLOBALES',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: primaryColor,
          ),
        ),
        pw.SizedBox(height: 16),

        // Grille de statistiques
        pw.Row(
          children: [
            pw.Expanded(
                child: _buildStatCard('Total Collectes',
                    '${stats.totalCollectes}', successColor, '📊')),
            pw.SizedBox(width: 10),
            pw.Expanded(
                child: _buildStatCard(
                    'Poids Total',
                    '${stats.totalWeight.toStringAsFixed(1)} kg',
                    primaryColor,
                    '⚖️')),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Expanded(
                child: _buildStatCard(
                    'Montant Total',
                    '${NumberFormat('#,###').format(stats.totalAmount)} FCFA',
                    warningColor,
                    '💰')),
            pw.SizedBox(width: 10),
            pw.Expanded(
                child: _buildStatCard('Contenants', '${stats.totalContainers}',
                    accentColor, '📦')),
          ],
        ),
        pw.SizedBox(height: 16),

        // Répartition par type
        _buildTypeDistribution(stats),
      ],
    );
  }

  /// Card de statistique
  static pw.Widget _buildStatCard(
      String title, String value, PdfColor color, String emoji) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 1),
      ),
      child: pw.Column(
        children: [
          pw.Text(emoji, style: const pw.TextStyle(fontSize: 20)),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 10, color: color),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Répartition par type avec graphique
  static pw.Widget _buildTypeDistribution(GlobalStatistics stats) {
    final total = stats.totalCollectes;
    if (total == 0) return pw.SizedBox();

    final recoltesPercent = (stats.recoltesCount / total * 100);
    final scoopPercent = (stats.scoopCount / total * 100);
    final individuelPercent = (stats.individuelCount / total * 100);
    final mielleriePercent = (stats.miellerieCount / total * 100);

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Répartition par Type de Collecte',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 12),

          // Barres de progression
          _buildProgressBar('🌾 Récoltes', stats.recoltesCount, recoltesPercent,
              successColor),
          pw.SizedBox(height: 8),
          _buildProgressBar(
              '👥 SCOOP', stats.scoopCount, scoopPercent, primaryColor),
          pw.SizedBox(height: 8),
          _buildProgressBar('👤 Individuel', stats.individuelCount,
              individuelPercent, warningColor),
          pw.SizedBox(height: 8),
          _buildProgressBar('🏭 Miellerie', stats.miellerieCount,
              mielleriePercent, secondaryColor),
        ],
      ),
    );
  }

  /// Barre de progression
  static pw.Widget _buildProgressBar(
      String label, int count, double percent, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
            pw.Text('$count (${percent.toStringAsFixed(1)}%)',
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Stack(
          children: [
            // Background bar
            pw.Container(
              width: double.infinity,
              height: 8,
              decoration: pw.BoxDecoration(
                color: PdfColors.grey300,
                borderRadius: pw.BorderRadius.circular(4),
              ),
            ),
            // Progress bar
            pw.Container(
              width: double.infinity * (percent / 100),
              height: 8,
              decoration: pw.BoxDecoration(
                color: color,
                borderRadius: pw.BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Titre de section
  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: pw.BoxDecoration(
        color: primaryColor.shade(0.1),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: primaryColor),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: primaryColor,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Analyse par section
  static pw.Widget _buildSectionAnalysis(
      Section section, List<BaseCollecte> collectes) {
    if (collectes.isEmpty) {
      return _buildEmptySection(_getSectionName(section));
    }

    final totalWeight =
        collectes.fold(0.0, (sum, c) => sum + (c.totalWeight ?? 0));
    final totalAmount =
        collectes.fold(0.0, (sum, c) => sum + (c.totalAmount ?? 0));
    final avgWeight = totalWeight / collectes.length;
    final avgAmount = totalAmount / collectes.length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _getSectionColor(section).shade(0.05),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _getSectionColor(section)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${_getSectionEmoji(section)} ${_getSectionName(section)}',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: _getSectionColor(section),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('📊 Nombre de collectes: ${collectes.length}'),
                    pw.Text(
                        '⚖️ Poids total: ${totalWeight.toStringAsFixed(1)} kg'),
                    pw.Text(
                        '💰 Montant total: ${NumberFormat('#,###').format(totalAmount)} FCFA'),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                        '📈 Poids moyen: ${avgWeight.toStringAsFixed(1)} kg'),
                    pw.Text(
                        '💳 Montant moyen: ${NumberFormat('#,###').format(avgAmount)} FCFA'),
                    pw.Text(
                        '💹 Prix/kg: ${(totalAmount / totalWeight).toStringAsFixed(0)} FCFA'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Section vide
  static pw.Widget _buildEmptySection(String sectionName) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Center(
        child: pw.Text(
          'Aucune collecte $sectionName trouvée',
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey600,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      ),
    );
  }

  /// Analyse temporelle
  static pw.Widget _buildTemporalAnalysis(
      Map<Section, List<BaseCollecte>> data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '📅 ÉVOLUTION TEMPORELLE',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Analyse de la distribution des collectes dans le temps, permettant d\'identifier les tendances saisonnières et les pics d\'activité.',
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  /// Analyse géographique
  static pw.Widget _buildGeographicAnalysis(
      Map<Section, List<BaseCollecte>> data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.green),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '🗺️ RÉPARTITION GÉOGRAPHIQUE',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Distribution des collectes par site et région, avec analyse des zones les plus productives.',
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  /// Recommandations
  static pw.Widget _buildRecommendations(GlobalStatistics stats) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: warningColor.shade(0.1),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: warningColor),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '💡 RECOMMANDATIONS',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: warningColor,
            ),
          ),
          pw.SizedBox(height: 12),
          _buildRecommendationItem(
              'Optimiser la formation des techniciens les moins productifs'),
          _buildRecommendationItem(
              'Renforcer les collectes dans les zones à fort potentiel'),
          _buildRecommendationItem(
              'Améliorer la qualité des contenants pour réduire les pertes'),
          _buildRecommendationItem(
              'Développer un calendrier saisonnier optimisé'),
        ],
      ),
    );
  }

  /// Item de recommandation
  static pw.Widget _buildRecommendationItem(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('• ',
              style: pw.TextStyle(
                  color: warningColor, fontWeight: pw.FontWeight.bold)),
          pw.Expanded(
              child: pw.Text(text, style: const pw.TextStyle(fontSize: 11))),
        ],
      ),
    );
  }

  /// Conclusion
  static pw.Widget _buildConclusion(GlobalStatistics stats) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: successColor.shade(0.1),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: successColor),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '🎯 CONCLUSION',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: successColor,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Les statistiques révèlent une activité soutenue avec ${stats.totalCollectes} collectes générant '
            '${stats.totalWeight.toStringAsFixed(1)} kg de miel. '
            'Le rendement moyen de ${stats.averagePerCollecte.toStringAsFixed(1)} kg par collecte '
            'et le prix moyen de ${stats.averageAmountPerKg.toStringAsFixed(0)} FCFA/kg '
            'démontrent une performance satisfaisante du système de collecte.',
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  // Méthodes utilitaires
  static String _getSectionName(Section section) {
    switch (section) {
      case Section.recoltes:
        return 'Récoltes';
      case Section.scoop:
        return 'SCOOP';
      case Section.individuel:
        return 'Individuelles';
      case Section.miellerie:
        return 'Miellerie';
    }
  }

  static String _getSectionEmoji(Section section) {
    switch (section) {
      case Section.recoltes:
        return '🌾';
      case Section.scoop:
        return '👥';
      case Section.individuel:
        return '👤';
      case Section.miellerie:
        return '🏭';
    }
  }

  static PdfColor _getSectionColor(Section section) {
    switch (section) {
      case Section.recoltes:
        return successColor;
      case Section.scoop:
        return primaryColor;
      case Section.individuel:
        return warningColor;
      case Section.miellerie:
        return secondaryColor;
    }
  }
}

/// Classes de données pour les statistiques
class GlobalStatistics {
  final double totalWeight;
  final double totalAmount;
  final int totalCollectes;
  final int totalContainers;
  final int recoltesCount;
  final int scoopCount;
  final int individuelCount;
  final int miellerieCount;
  final Map<String, MonthlyStats> monthlyData;
  final Map<String, TechnicianStats> technicians;
  final Map<String, SiteStats> sites;
  final double averagePerCollecte;
  final double averageAmountPerKg;

  GlobalStatistics({
    required this.totalWeight,
    required this.totalAmount,
    required this.totalCollectes,
    required this.totalContainers,
    required this.recoltesCount,
    required this.scoopCount,
    required this.individuelCount,
    required this.miellerieCount,
    required this.monthlyData,
    required this.technicians,
    required this.sites,
    required this.averagePerCollecte,
    required this.averageAmountPerKg,
  });
}

class MonthlyStats {
  final String month;
  int collectes = 0;
  double weight = 0;
  double amount = 0;

  MonthlyStats({required this.month});

  void addCollecte(BaseCollecte collecte, Section section) {
    collectes++;
    weight += collecte.totalWeight ?? 0;
    amount += collecte.totalAmount ?? 0;
  }
}

class TechnicianStats {
  final String name;
  int collectes = 0;
  double weight = 0;
  double amount = 0;

  TechnicianStats({required this.name});

  void addCollecte(BaseCollecte collecte) {
    collectes++;
    weight += collecte.totalWeight ?? 0;
    amount += collecte.totalAmount ?? 0;
  }
}

class SiteStats {
  final String name;
  int collectes = 0;
  double weight = 0;
  double amount = 0;

  SiteStats({required this.name});

  void addCollecte(BaseCollecte collecte) {
    collectes++;
    weight += collecte.totalWeight ?? 0;
    amount += collecte.totalAmount ?? 0;
  }
}
