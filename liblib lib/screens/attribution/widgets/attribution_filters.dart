import 'package:flutter/material.dart';
import '../../controle_de_donnes/models/attribution_models_v2.dart';

/// 🔍 WIDGET DE FILTRES AVANCÉS POUR L'ATTRIBUTION
///
/// Bottom sheet avec tous les filtres disponibles pour affiner
/// la recherche de produits disponibles pour attribution
class AttributionFiltersWidget extends StatefulWidget {
  final AttributionFilters currentFilters;
  final Function(AttributionFilters) onFiltersChanged;

  const AttributionFiltersWidget({
    Key? key,
    required this.currentFilters,
    required this.onFiltersChanged,
  }) : super(key: key);

  @override
  State<AttributionFiltersWidget> createState() =>
      _AttributionFiltersWidgetState();
}

class _AttributionFiltersWidgetState extends State<AttributionFiltersWidget> {
  late AttributionFilters _filters;

  final List<String> _sites = [
    'Koudougou',
    'Bobo-Dioulasso',
    'Ouagadougou',
    'Réo'
  ];
  final List<String> _qualites = [
    'Excellent',
    'Très Bon',
    'Bon',
    'Moyen',
    'Passable'
  ];

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSiteFilter(),
                  const SizedBox(height: 24),
                  _buildNatureFilter(),
                  const SizedBox(height: 24),
                  _buildQualiteFilter(),
                  const SizedBox(height: 24),
                  _buildDateRangeFilter(),
                  const SizedBox(height: 24),
                  _buildUrgentFilter(),
                ],
              ),
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.indigo[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(Icons.tune, color: Colors.indigo[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Filtres Avancés',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[700],
              ),
            ),
          ),
          TextButton(
            onPressed: _resetFilters,
            child: Text(
              'Réinitialiser',
              style: TextStyle(color: Colors.indigo[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiteFilter() {
    return _buildFilterSection(
      'Site d\'Origine',
      Icons.business,
      Column(
        children: _sites
            .map((site) => CheckboxListTile(
                  title: Text(site),
                  value: _filters.site == site,
                  onChanged: (value) {
                    setState(() {
                      _filters = _filters.copyWith(
                        site: value == true ? site : null,
                      );
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildNatureFilter() {
    return _buildFilterSection(
      'Nature du Produit',
      Icons.category,
      Column(
        children: ProductNature.values
            .map((nature) => CheckboxListTile(
                  title: Text(nature.label),
                  subtitle: Text(_getNatureDescription(nature)),
                  value: _filters.nature == nature,
                  onChanged: (value) {
                    setState(() {
                      _filters = _filters.copyWith(
                        nature: value == true ? nature : null,
                      );
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(
                    _getNatureIcon(nature),
                    color: _getNatureColor(nature),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildQualiteFilter() {
    return _buildFilterSection(
      'Qualité',
      Icons.star,
      Column(
        children: _qualites
            .map((qualite) => CheckboxListTile(
                  title: Text(qualite),
                  value: _filters.qualite == qualite,
                  onChanged: (value) {
                    setState(() {
                      _filters = _filters.copyWith(
                        qualite: value == true ? qualite : null,
                      );
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(
                    Icons.star,
                    color: _getQualiteColor(qualite),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    return _buildFilterSection(
      'Période de Réception',
      Icons.date_range,
      Column(
        children: [
          // Date de début
          ListTile(
            title: const Text('Date de début'),
            subtitle: Text(_filters.dateDebut?.toString().substring(0, 10) ??
                'Non définie'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDate(context, true),
            contentPadding: EdgeInsets.zero,
          ),

          // Date de fin
          ListTile(
            title: const Text('Date de fin'),
            subtitle: Text(
                _filters.dateFin?.toString().substring(0, 10) ?? 'Non définie'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDate(context, false),
            contentPadding: EdgeInsets.zero,
          ),

          // Bouton pour effacer les dates
          if (_filters.dateDebut != null || _filters.dateFin != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _filters = _filters.copyWith(
                      dateDebut: null,
                      dateFin: null,
                    );
                  });
                },
                child: const Text('Effacer les dates'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUrgentFilter() {
    return _buildFilterSection(
      'Priorité',
      Icons.priority_high,
      SwitchListTile(
        title: const Text('Produits urgents uniquement'),
        subtitle: const Text('Produits reçus il y a plus de 7 jours'),
        value: _filters.urgentOnly ?? false,
        onChanged: (value) {
          setState(() {
            _filters = _filters.copyWith(urgentOnly: value);
          });
        },
        secondary: Icon(
          Icons.priority_high,
          color: Colors.red[600],
        ),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildFilterSection(String title, IconData icon, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Annuler'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                widget.onFiltersChanged(_filters);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Appliquer les filtres'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_filters.dateDebut ?? DateTime.now())
          : (_filters.dateFin ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _filters = _filters.copyWith(dateDebut: picked);
        } else {
          _filters = _filters.copyWith(dateFin: picked);
        }
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _filters = const AttributionFilters();
    });
  }

  String _getNatureDescription(ProductNature nature) {
    switch (nature) {
      case ProductNature.brut:
        return 'Pour extraction';
      case ProductNature.liquide:
        return 'Pour filtrage';
      case ProductNature.cire:
        return 'Pour traitement cire';
      case ProductNature.filtre:
        return 'Déjà filtré';
    }
  }

  IconData _getNatureIcon(ProductNature nature) {
    switch (nature) {
      case ProductNature.brut:
        return Icons.science;
      case ProductNature.liquide:
        return Icons.water_drop;
      case ProductNature.cire:
        return Icons.spa;
      case ProductNature.filtre:
        return Icons.filter_alt;
    }
  }

  Color _getNatureColor(ProductNature nature) {
    switch (nature) {
      case ProductNature.brut:
        return Colors.brown;
      case ProductNature.liquide:
        return Colors.blue;
      case ProductNature.cire:
        return Colors.amber[700]!;
      case ProductNature.filtre:
        return Colors.green;
    }
  }

  Color _getQualiteColor(String qualite) {
    switch (qualite) {
      case 'Excellent':
        return Colors.green[700]!;
      case 'Très Bon':
        return Colors.green[500]!;
      case 'Bon':
        return Colors.orange[600]!;
      case 'Moyen':
        return Colors.orange[400]!;
      case 'Passable':
        return Colors.red[400]!;
      default:
        return Colors.grey[600]!;
    }
  }
}

/// 🔍 MODÈLE POUR LES FILTRES D'ATTRIBUTION
class AttributionFilters {
  final String? site;
  final ProductNature? nature;
  final bool? urgentOnly;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String? qualite;

  const AttributionFilters({
    this.site,
    this.nature,
    this.urgentOnly,
    this.dateDebut,
    this.dateFin,
    this.qualite,
  });

  bool matches(ProductControle produit) {
    if (site != null && produit.siteOrigine != site) return false;
    if (nature != null && produit.nature != nature) return false;
    if (urgentOnly == true && !produit.isUrgent) return false;
    if (dateDebut != null && produit.dateReception.isBefore(dateDebut!))
      return false;
    if (dateFin != null && produit.dateReception.isAfter(dateFin!))
      return false;
    if (qualite != null && produit.qualite != qualite) return false;
    return true;
  }

  AttributionFilters copyWith({
    String? site,
    ProductNature? nature,
    bool? urgentOnly,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? qualite,
  }) {
    return AttributionFilters(
      site: site ?? this.site,
      nature: nature ?? this.nature,
      urgentOnly: urgentOnly ?? this.urgentOnly,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      qualite: qualite ?? this.qualite,
    );
  }
}

/// Extension pour les filtres d'attribution
extension AttributionFiltersExtension on AttributionFilters {
  /// Compte le nombre de filtres actifs
  int get activeFiltersCount {
    int count = 0;
    if (site != null) count++;
    if (nature != null) count++;
    if (urgentOnly == true) count++;
    if (dateDebut != null) count++;
    if (dateFin != null) count++;
    if (qualite != null) count++;
    return count;
  }

  /// Vérifie si des filtres sont actifs
  bool get hasActiveFilters => activeFiltersCount > 0;

  /// Génère un résumé textuel des filtres actifs
  String get filtersSummary {
    final parts = <String>[];

    if (site != null) parts.add('Site: $site');
    if (nature != null) parts.add('Nature: ${nature!.label}');
    if (qualite != null) parts.add('Qualité: $qualite');
    if (urgentOnly == true) parts.add('Urgents uniquement');
    if (dateDebut != null || dateFin != null) {
      String dateRange = 'Période: ';
      if (dateDebut != null)
        dateRange += 'du ${dateDebut!.toString().substring(0, 10)}';
      if (dateFin != null)
        dateRange += ' au ${dateFin!.toString().substring(0, 10)}';
      parts.add(dateRange);
    }

    return parts.join(' • ');
  }
}
