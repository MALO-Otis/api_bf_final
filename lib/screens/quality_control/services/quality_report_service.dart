import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/quality_vocab.dart';
import 'package:share_plus/share_plus.dart';
import '../models/quality_chain_models.dart';
import 'package:path_provider/path_provider.dart';
import '../../controle_de_donnes/models/quality_control_models.dart';

class QualityReportResult {
  final bool success;
  final String message;

  const QualityReportResult({required this.success, required this.message});
}

class QualityReportService {
  const QualityReportService();

  Future<QualityReportResult> exportLotsToCsv({
    required List<QualityLotSnapshot> lots,
    QualitySummaryMetrics? summary,
  }) async {
    if (lots.isEmpty) {
      return const QualityReportResult(
        success: false,
        message: 'Aucun lot à exporter.',
      );
    }

    try {
      final now = DateTime.now();
      final dateFormat = DateFormat('dd/MM/yyyy');
      final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
      final buffer = StringBuffer()
        ..writeln(
            'Rapport Contrôle Qualité;Généré le;${dateTimeFormat.format(now)}')
        ..writeln('')
        ..writeln(
            'Lot;Produit;Date référence;Statut;Teneur eau;Pollen perdu total;Résidus moyens;Étapes conformes;Étapes non conformes;Observations');

      for (final lot in lots) {
        final overallStatus = lot.overallStatus();
        final statusLabel =
            QualityControlUtils.getConformityStatusLabel(overallStatus);
        final latestWater = lot.latestWaterContent;
        final pollenTotal = lot.metricsByStep.values
            .map((metrics) => metrics.pollenLostKg ?? 0)
            .fold<double>(0, (sum, value) => sum + value);
        final residueValues = lot.metricsByStep.values
            .map((metrics) => metrics.residuePercent)
            .whereType<double>()
            .toList(growable: false);
        final residueAverage = residueValues.isEmpty
            ? null
            : residueValues.reduce((a, b) => a + b) / residueValues.length;

        final conformSteps = <String>[];
        final nonConformSteps = <String>[];
        final observations = <String>[];

        lot.metricsByStep.forEach((step, metrics) {
          final label = step.label;
          if (metrics.isConform) {
            conformSteps.add(label);
          } else {
            nonConformSteps.add(label);
          }
          if (metrics.observation != null &&
              metrics.observation!.trim().isNotEmpty) {
            observations
                .add('$label: ${metrics.observation!.replaceAll(';', ',')}');
          }
        });

        final row = [
          lot.lotCode,
          lot.productType,
          dateFormat.format(lot.referenceDate),
          statusLabel,
          latestWater != null ? '${latestWater.toStringAsFixed(1)}%' : '',
          pollenTotal == 0 ? '' : '${pollenTotal.toStringAsFixed(2)} kg',
          residueAverage == null ? '' : '${residueAverage.toStringAsFixed(1)}%',
          conformSteps.join(' | '),
          nonConformSteps.join(' | '),
          observations.join(' / '),
        ].map(_sanitizeCsv).join(';');

        buffer.writeln(row);
      }

      if (summary != null) {
        buffer
          ..writeln('')
          ..writeln('Synthèse;')
          ..writeln('Lots totaux;${summary.totalLots}')
          ..writeln('Lots conformes;${summary.conformLots}')
          ..writeln('Lots non conformes;${summary.nonConformLots}')
          ..writeln(
              'Taux conformité;${(summary.conformityRate * 100).toStringAsFixed(1)}%')
          ..writeln(
              'Teneur eau moyenne;${summary.averageWaterContent.toStringAsFixed(1)}%')
          ..writeln(
              'Résidus moyens;${summary.averageResiduePercent.toStringAsFixed(1)}%')
          ..writeln(
              'Pollen perdu total;${summary.totalPollenLostKg.toStringAsFixed(2)} kg');
      }

      final directory = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
      final filePath =
          '${directory.path}/rapport_controle_qualite_$timestamp.csv';
      final file = File(filePath);
      await file.writeAsString(buffer.toString(), encoding: utf8);

      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType: 'text/csv',
            name: 'rapport_controle_qualite_$timestamp.csv',
          ),
        ],
        text: 'Rapport du module Contrôle Qualité',
      );

      return const QualityReportResult(
        success: true,
        message: 'Rapport exporté dans vos partages.',
      );
    } catch (e) {
      return QualityReportResult(
        success: false,
        message: "Erreur lors de l'export: $e",
      );
    }
  }

  String _sanitizeCsv(String value) {
    final sanitized = value.replaceAll('\n', ' ').replaceAll('\r', ' ').trim();
    if (sanitized.contains(';') || sanitized.contains('"')) {
      final escaped = sanitized.replaceAll('"', '""');
      return '"$escaped"';
    }
    return sanitized;
  }
}
