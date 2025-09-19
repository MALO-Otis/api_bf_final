/// Widget moderne pour l'affichage des codes de localisation
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/geographe/geographie.dart';

class LocalisationCodeWidget extends StatelessWidget {
  final Map<String, String> localisation;
  final bool showCopyButton;
  final bool showHierarchy;
  final bool compact;
  final Color? accentColor;

  const LocalisationCodeWidget({
    super.key,
    required this.localisation,
    this.showCopyButton = true,
    this.showHierarchy = true,
    this.compact = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? theme.colorScheme.primary;

    final localisationAvecCode =
        GeographieData.formatLocationCodeFromMap(localisation);

    final localisationComplete = [
      localisation['region'],
      localisation['province'],
      localisation['commune'],
      localisation['village']
    ].where((element) => element != null && element.isNotEmpty).join(' › ');

    if (localisationAvecCode.isEmpty && localisationComplete.isEmpty) {
      return _buildEmptyState(theme);
    }

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(0.05),
            accent.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec icône et titre
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.location_on,
                  color: accent,
                  size: compact ? 16 : 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Localisation',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: accent,
                    fontSize: compact ? 12 : 14,
                  ),
                ),
              ),
              if (showCopyButton && localisationAvecCode.isNotEmpty)
                _buildCopyButton(context, localisationAvecCode, accent),
            ],
          ),

          const SizedBox(height: 12),

          // Code de localisation
          if (localisationAvecCode.isNotEmpty) ...[
            _buildCodeSection(context, localisationAvecCode, accent),
            if (showHierarchy && localisationComplete.isNotEmpty)
              const SizedBox(height: 8),
          ],

          // Hiérarchie complète
          if (showHierarchy && localisationComplete.isNotEmpty)
            _buildHierarchySection(context, localisationComplete, accent),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_off,
            color: Colors.grey.shade500,
            size: compact ? 14 : 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Localisation non spécifiée',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
              fontSize: compact ? 11 : 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeSection(BuildContext context, String code, Color accent) {
    final theme = Theme.of(context);

    // Séparer le code des noms
    final parts = code.split(' / ');
    final codesPart = parts.isNotEmpty ? parts[0] : '';
    final namesPart = parts.length > 1 ? parts[1] : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Code numérique
          if (codesPart.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.tag,
                  color: accent,
                  size: compact ? 12 : 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'Code: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: compact ? 10 : 11,
                  ),
                ),
                Expanded(
                  child: Text(
                    codesPart,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: accent,
                      fontFamily: 'monospace',
                      fontSize: compact ? 12 : 14,
                    ),
                  ),
                ),
              ],
            ),
            if (namesPart.isNotEmpty) const SizedBox(height: 4),
          ],

          // Noms
          if (namesPart.isNotEmpty)
            Row(
              children: [
                Icon(
                  Icons.place,
                  color: accent,
                  size: compact ? 12 : 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'Lieu: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: compact ? 10 : 11,
                  ),
                ),
                Expanded(
                  child: Text(
                    namesPart.replaceAll('-', ' › '),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                      fontSize: compact ? 11 : 12,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHierarchySection(
      BuildContext context, String hierarchy, Color accent) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.03),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_tree,
            color: Colors.grey.shade600,
            size: compact ? 12 : 14,
          ),
          const SizedBox(width: 6),
          Text(
            'Hiérarchie: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
              fontSize: compact ? 10 : 11,
            ),
          ),
          Expanded(
            child: Text(
              hierarchy,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
                fontSize: compact ? 10 : 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyButton(BuildContext context, String text, Color accent) {
    return InkWell(
      onTap: () => _copyToClipboard(context, text),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.copy,
          color: accent.withOpacity(0.7),
          size: compact ? 14 : 16,
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              'Code de localisation copié',
              style: TextStyle(fontSize: compact ? 12 : 14),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
  }
}

/// Widget compact pour l'affichage en ligne
class LocalisationCodeCompact extends StatelessWidget {
  final Map<String, String> localisation;
  final Color? textColor;
  final double? fontSize;

  const LocalisationCodeCompact({
    super.key,
    required this.localisation,
    this.textColor,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localisationAvecCode =
        GeographieData.formatLocationCodeFromMap(localisation);

    if (localisationAvecCode.isEmpty) {
      return Text(
        'Localisation non spécifiée',
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.grey.shade500,
          fontStyle: FontStyle.italic,
          fontSize: fontSize ?? 11,
        ),
      );
    }

    // Séparer le code des noms pour un affichage plus compact
    final parts = localisationAvecCode.split(' / ');
    final codesPart = parts.isNotEmpty ? parts[0] : '';
    final namesPart = parts.length > 1 ? parts[1] : '';

    return RichText(
      text: TextSpan(
        children: [
          if (codesPart.isNotEmpty) ...[
            TextSpan(
              text: codesPart,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor ?? theme.colorScheme.primary,
                fontFamily: 'monospace',
                fontSize: fontSize ?? 11,
              ),
            ),
            if (namesPart.isNotEmpty)
              TextSpan(
                text: ' • ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade400,
                  fontSize: fontSize ?? 11,
                ),
              ),
          ],
          if (namesPart.isNotEmpty)
            TextSpan(
              text: namesPart.replaceAll('-', ' › '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor ?? Colors.grey.shade700,
                fontSize: fontSize ?? 11,
              ),
            ),
        ],
      ),
    );
  }
}
