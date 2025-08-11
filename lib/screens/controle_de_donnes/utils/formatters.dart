// Utilitaires de formatage pour le module de contrôle
import 'package:intl/intl.dart';
import '../models/collecte_models.dart';

class Formatters {
  static final NumberFormat _numberFormat = NumberFormat('#,##0', 'fr_FR');
  static final NumberFormat _decimalFormat = NumberFormat('#,##0.0', 'fr_FR');
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
  static final DateFormat _dateTimeFormat =
      DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

  /// Formate un montant en FCFA
  static String formatFCFA(double? amount) {
    if (amount == null) return '—';
    return '${_numberFormat.format(amount)} FCFA';
  }

  /// Formate un poids en kg
  static String formatKg(double? weight) {
    if (weight == null) return '—';
    return '${_decimalFormat.format(weight)} kg';
  }

  /// Formate une date
  static String formatDate(DateTime? date) {
    if (date == null) return '—';
    return _dateFormat.format(date);
  }

  /// Formate une date avec l'heure
  static String formatDateTime(DateTime? date) {
    if (date == null) return '—';
    return _dateTimeFormat.format(date);
  }

  /// Formate un nombre simple
  static String formatNumber(int? number) {
    if (number == null) return '—';
    return _numberFormat.format(number);
  }

  /// Obtient le titre d'une collecte selon sa section
  static String getTitleForCollecte(Section section, BaseCollecte collecte) {
    switch (section) {
      case Section.recoltes:
        return collecte.site;
      case Section.scoop:
        return (collecte as Scoop).scoopNom;
      case Section.individuel:
        return (collecte as Individuel).nomProducteur;
    }
  }

  /// Obtient le sous-titre d'une collecte
  static String getSubtitleForCollecte(BaseCollecte collecte) {
    final date = formatDate(collecte.date);
    final technicien = collecte.technicien ?? '—';
    return '$date • $technicien';
  }

  /// Obtient les chips d'information pour une collecte
  static List<String> getChipsForCollecte(
      Section section, BaseCollecte collecte) {
    switch (section) {
      case Section.recoltes:
        final recolte = collecte as Recolte;
        final groups = <String, int>{};
        for (final contenant in recolte.contenants) {
          groups[contenant.hiveType] = (groups[contenant.hiveType] ?? 0) + 1;
        }
        final entries = groups.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return entries.take(3).map((e) => '${e.key} ×${e.value}').toList();

      case Section.scoop:
        final scoop = collecte as Scoop;
        final groups = <String, int>{};
        for (final contenant in scoop.contenants) {
          groups[contenant.typeMiel] = (groups[contenant.typeMiel] ?? 0) + 1;
        }
        final entries = groups.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return entries.take(3).map((e) => '${e.key} ×${e.value}').toList();

      case Section.individuel:
        final individuel = collecte as Individuel;
        return (individuel.originesFlorales ?? []).take(3).toList();
    }
  }

  /// Obtient le label pour une section
  static String getSectionLabel(Section section) {
    switch (section) {
      case Section.recoltes:
        return 'Récoltes';
      case Section.scoop:
        return 'SCOOP';
      case Section.individuel:
        return 'Individuel';
    }
  }

  /// Obtient la couleur de badge pour une section
  static String getBadgeClass(Section section) {
    switch (section) {
      case Section.recoltes:
        return 'badge-recoltes';
      case Section.scoop:
        return 'badge-scoop';
      case Section.individuel:
        return 'badge-individuel';
    }
  }

  /// Génère un nom de fichier pour l'export
  static String generateFileName(
      Section section, String? site, DateTime date, String suffix) {
    final siteStr = site?.replaceAll(' ', '_') ?? 'multi';
    final dateStr = DateFormat('yyyyMMdd').format(date);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sectionStr = section.name;

    return '${sectionStr}_${siteStr}_${dateStr}_${suffix}_$timestamp.csv';
  }

  /// Convertit les données en CSV
  static String toCsv(List<List<dynamic>> rows) {
    return rows.map((row) {
      return row.map((cell) {
        final cellStr = cell.toString();
        // Échapper les guillemets doubles
        final escaped = cellStr.replaceAll('"', '""');
        return '"$escaped"';
      }).join(',');
    }).join('\n');
  }

  /// Prépare les données d'une collecte pour l'export CSV
  static List<dynamic> prepareCollecteForCsv(
      Section section, BaseCollecte collecte) {
    return [
      collecte.id,
      getSectionLabel(section),
      collecte.site,
      formatDate(collecte.date),
      collecte.technicien ?? '—',
      collecte.totalWeight ?? 0,
      collecte.totalAmount ?? 0,
      collecte.containersCount ?? 0,
    ];
  }

  /// Obtient les en-têtes CSV standards
  static List<String> getCsvHeaders() {
    return [
      'ID',
      'Section',
      'Site',
      'Date',
      'Technicien',
      'Poids (kg)',
      'Montant (FCFA)',
      '#Contenants',
    ];
  }

  /// Formate un statut pour l'affichage
  static String formatStatut(String? statut) {
    if (statut == null || statut.isEmpty) return '—';

    switch (statut.toLowerCase()) {
      case 'en_attente':
        return 'En attente';
      case 'collecte_terminee':
        return 'Terminée';
      case 'brouillon':
        return 'Brouillon';
      default:
        return statut;
    }
  }

  /// Obtient la couleur pour un statut
  static String getStatutColor(String? statut) {
    if (statut == null || statut.isEmpty) return 'gray';

    switch (statut.toLowerCase()) {
      case 'en_attente':
        return 'orange';
      case 'collecte_terminee':
        return 'green';
      case 'brouillon':
        return 'blue';
      default:
        return 'gray';
    }
  }

  /// Tronque un texte à la longueur spécifiée
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  /// Capitalise la première lettre d'un texte
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Formate une liste de chaînes pour l'affichage
  static String formatStringList(List<String>? list,
      {String separator = ', ', int? maxItems}) {
    if (list == null || list.isEmpty) return '—';

    final itemsToShow = maxItems != null ? list.take(maxItems).toList() : list;
    final result = itemsToShow.join(separator);

    if (maxItems != null && list.length > maxItems) {
      final remaining = list.length - maxItems;
      return '$result (+$remaining)';
    }

    return result;
  }
}
