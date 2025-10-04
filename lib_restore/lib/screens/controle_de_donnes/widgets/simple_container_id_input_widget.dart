import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/universal_container_id_service.dart';
import '../../../authentication/user_session.dart';

/// Widget simplifié pour saisir les IDs de contenants lors du contrôle qualité
/// Le contrôleur saisit seulement le numéro + type + période optionnelle
class SimpleContainerIdInputWidget extends StatefulWidget {
  final Function(String containerId, List<ContainerMatchResult> possibleMatches)
      onContainerIdChanged;
  final String? initialValue;

  const SimpleContainerIdInputWidget({
    super.key,
    required this.onContainerIdChanged,
    this.initialValue,
  });

  @override
  State<SimpleContainerIdInputWidget> createState() =>
      _SimpleContainerIdInputWidgetState();
}

class _SimpleContainerIdInputWidgetState
    extends State<SimpleContainerIdInputWidget> {
  final TextEditingController _fullIdController = TextEditingController();
  final TextEditingController _simpleIdController = TextEditingController();

  final UniversalContainerIdService _universalService =
      UniversalContainerIdService();
  final UserSession _userSession = Get.find<UserSession>();

  String _selectedType = 'IND';
  DateTimeRange? _dateRange;

  bool _useFullId = true;
  bool _isSearching = false;
  List<ContainerMatchResult> _searchResults = [];
  ContainerMatchResult? _selectedMatch;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _fullIdController.text = widget.initialValue!;
      _validateFullId(widget.initialValue!);
    }
  }

  @override
  void dispose() {
    _fullIdController.dispose();
    _simpleIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Identification du contenant',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Sélecteur de mode
            _buildModeSelector(),
            const SizedBox(height: 16),

            // Interface selon le mode
            if (_useFullId) _buildFullIdInput() else _buildSimpleSearch(),
            const SizedBox(height: 16),

            // Résultats de la recherche
            _buildSearchResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(
          child: RadioListTile<bool>(
            title: const Text('ID complet'),
            subtitle: const Text('Si vous connaissez l\'ID exact'),
            value: true,
            groupValue: _useFullId,
            onChanged: (value) => setState(() {
              _useFullId = value!;
              _clearSearch();
            }),
          ),
        ),
        Expanded(
          child: RadioListTile<bool>(
            title: const Text('Recherche simple'),
            subtitle: const Text('Numéro + type + période'),
            value: false,
            groupValue: _useFullId,
            onChanged: (value) => setState(() {
              _useFullId = value!;
              _clearSearch();
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildFullIdInput() {
    return Column(
      children: [
        TextField(
          controller: _fullIdController,
          decoration: InputDecoration(
            labelText: 'ID complet du contenant',
            hintText: 'IND_SAKOINSÉ_JEAN_MARIE_20241215_0001',
            border: const OutlineInputBorder(),
            suffixIcon: _isSearching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => _validateFullId(_fullIdController.text),
                  ),
          ),
          onChanged: (value) {
            setState(() {
              _clearSearch();
            });
          },
          onSubmitted: _validateFullId,
        ),
        const SizedBox(height: 8),
        Text(
          'Format: {TYPE}_{VILLAGE}_{TECHNICIEN}_{PRODUCTEUR}_{DATE}_{NUMERO}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildSimpleSearch() {
    return Column(
      children: [
        // Numéro du contenant
        TextField(
          controller: _simpleIdController,
          decoration: const InputDecoration(
            labelText: 'Numéro du contenant',
            hintText: '0001 ou C0001',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _clearSearch(),
        ),
        const SizedBox(height: 16),

        // Type de collecte et période
        Row(
          children: [
            // Type de collecte
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type collecte',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'REC', child: Text('Récolte')),
                  DropdownMenuItem(value: 'SCO', child: Text('Scoop')),
                  DropdownMenuItem(value: 'IND', child: Text('Individuel')),
                  DropdownMenuItem(value: 'MIE', child: Text('Miellerie')),
                ],
                onChanged: (value) => setState(() {
                  _selectedType = value!;
                  _clearSearch();
                }),
              ),
            ),
            const SizedBox(width: 8),

            // Période de collecte (optionnel)
            Expanded(
              child: InkWell(
                onTap: _selectDateRange,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Période (optionnel)',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _dateRange != null
                        ? '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}'
                        : 'Toute période',
                    style: TextStyle(
                      color: _dateRange != null ? null : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Information pour l'utilisateur
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border.all(color: Colors.blue[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Le système recherchera automatiquement tous les contenants correspondants. '
                  'Vous pourrez ensuite choisir le bon si plusieurs résultats.',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Bouton de recherche
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _canSearch() ? _searchContainers : null,
            icon: _isSearching
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: Text(
                _isSearching ? 'Recherche...' : 'Rechercher les contenants'),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_errorMessage != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          border: Border.all(color: Colors.red[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          border: Border.all(color: Colors.green[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green[600]),
                const SizedBox(width: 8),
                Text(
                  '${_searchResults.length} contenant(s) trouvé(s)',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Liste des résultats
            ...(_searchResults
                .take(5)
                .map((result) => _buildResultItem(result))),

            if (_searchResults.length > 5) ...[
              const SizedBox(height: 8),
              Text(
                'Et ${_searchResults.length - 5} autre(s)...',
                style: TextStyle(
                  color: Colors.green[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildResultItem(ContainerMatchResult result) {
    final isSelected = _selectedMatch == result;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green[100] : Colors.white,
        border: Border.all(
          color: isSelected ? Colors.green[400]! : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        title: Text(
          result.components?.let((c) =>
                  'Village: ${c.village} | Technicien: ${c.technicien} | Producteur: ${c.producteur}') ??
              'ID: ${result.containerId ?? "Inconnu"}',
          style: const TextStyle(fontSize: 13),
        ),
        subtitle: Text(
          'Date: ${result.components?.date ?? "Inconnue"} | Collection: ${result.collecteInfo?.collectionType ?? "Inconnue"}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: Colors.green[600])
            : const Icon(Icons.radio_button_unchecked),
        onTap: () {
          setState(() {
            _selectedMatch = result;
          });
          widget.onContainerIdChanged(result.containerId ?? '', [result]);
        },
      ),
    );
  }

  bool _canSearch() {
    return _simpleIdController.text.trim().isNotEmpty;
  }

  void _clearSearch() {
    setState(() {
      _searchResults.clear();
      _selectedMatch = null;
      _errorMessage = null;
    });
    widget.onContainerIdChanged('', []);
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (range != null) {
      setState(() {
        _dateRange = range;
        _clearSearch();
      });
    }
  }

  Future<void> _validateFullId(String fullId) async {
    if (fullId.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final result = await _universalService.verifyContainerMatch(
        controlId: fullId.trim(),
        site: _userSession.site ?? '',
      );

      setState(() {
        if (result.found) {
          _searchResults = [result];
          _selectedMatch = result;
        } else {
          _searchResults.clear();
          _errorMessage = result.error ?? 'Contenant non trouvé';
        }
      });

      widget.onContainerIdChanged(fullId.trim(), result.found ? [result] : []);
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la validation: $e';
        _searchResults.clear();
      });
      widget.onContainerIdChanged(fullId.trim(), []);
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _searchContainers() async {
    if (!_canSearch()) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _searchResults.clear();
    });

    try {
      // Recherche par pattern dans toutes les collectes
      final results = await _searchContainersByPattern(
        numero: _simpleIdController.text.trim(),
        type: _selectedType,
        dateRange: _dateRange,
      );

      setState(() {
        _searchResults = results;
        if (results.isEmpty) {
          _errorMessage = 'Aucun contenant trouvé avec ces critères';
        } else if (results.length == 1) {
          _selectedMatch = results.first;
          widget.onContainerIdChanged(results.first.containerId ?? '', results);
        }
      });

      if (results.length > 1) {
        widget.onContainerIdChanged(
            '', results); // Plusieurs résultats, l'utilisateur doit choisir
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la recherche: $e';
        _searchResults.clear();
      });
      widget.onContainerIdChanged('', []);
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  /// Recherche des contenants par pattern dans toutes les collectes
  Future<List<ContainerMatchResult>> _searchContainersByPattern({
    required String numero,
    required String type,
    DateTimeRange? dateRange,
  }) async {
    final List<ContainerMatchResult> results = [];

    // Nettoyer le numéro
    String numeroClean = numero.toUpperCase();
    if (numeroClean.startsWith('C')) {
      numeroClean = numeroClean.substring(1);
    }
    numeroClean = numeroClean.padLeft(4, '0');

    // Collections à rechercher selon le type
    final collections = _getCollectionsForType(type);

    for (final collectionName in collections) {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('Sites')
            .doc(_userSession.site)
            .collection(collectionName)
            .get();

        for (final doc in querySnapshot.docs) {
          final data = doc.data();
          final contenants = data['contenants'] as List<dynamic>?;
          final docDate = _extractDateFromDocument(data);

          // Filtrer par date si spécifiée
          if (dateRange != null && docDate != null) {
            if (docDate.isBefore(dateRange.start) ||
                docDate.isAfter(dateRange.end)) {
              continue;
            }
          }

          if (contenants != null) {
            for (int i = 0; i < contenants.length; i++) {
              final contenant = contenants[i] as Map<String, dynamic>;
              final contenantId = contenant['id']?.toString();

              if (contenantId != null &&
                  contenantId.endsWith('_$numeroClean')) {
                // Vérifier le contenant
                final result = await _universalService.verifyContainerMatch(
                  controlId: contenantId,
                  site: _userSession.site ?? '',
                );

                if (result.found) {
                  results.add(result);
                }
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Erreur recherche dans $collectionName: $e');
        }
      }
    }

    return results;
  }

  List<String> _getCollectionsForType(String type) {
    switch (type) {
      case 'REC':
        return ['nos_collectes_recoltes'];
      case 'SCO':
        return ['nos_achats_scoop_contenants'];
      case 'IND':
        return ['nos_achats_individuels'];
      case 'MIE':
        return ['nos_collectes_mielleries'];
      default:
        return [
          'nos_collectes_recoltes',
          'nos_achats_scoop_contenants',
          'nos_achats_individuels',
          'nos_collectes_mielleries',
        ];
    }
  }

  DateTime? _extractDateFromDocument(Map<String, dynamic> data) {
    try {
      // Essayer différents champs de date selon le type de collecte
      final dateFields = [
        'date_achat',
        'date_collecte',
        'dateCollecte',
        'created_at'
      ];

      for (final field in dateFields) {
        if (data[field] != null) {
          if (data[field] is Timestamp) {
            return (data[field] as Timestamp).toDate();
          } else if (data[field] is String) {
            return DateTime.tryParse(data[field]);
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

/// Extension pour simplifier l'usage des nullable
extension NullableExtension<T> on T? {
  R? let<R>(R Function(T) transform) {
    final value = this;
    return value != null ? transform(value) : null;
  }
}
