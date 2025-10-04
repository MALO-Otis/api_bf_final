/// 👤 SÉLECTEUR COMMERCIAL AVANCÉ
///
/// Widget intelligent permettant de sélectionner un commercial depuis une liste
/// organisée par zone OU de saisir un nom personnalisé
/// Offre une expérience utilisateur optimale avec recherche et suggestions

import 'package:flutter/material.dart';
import '../../../data/personnel/personnel_apisavana.dart';

class SelecteurCommercial extends StatefulWidget {
  final String? commercialSelectionne;
  final ValueChanged<String?> onChanged;
  final String? labelText;
  final String? hintText;
  final bool required;
  final bool enabled;

  const SelecteurCommercial({
    super.key,
    this.commercialSelectionne,
    required this.onChanged,
    this.labelText = 'Commercial',
    this.hintText = 'Sélectionnez ou saisissez un commercial',
    this.required = true,
    this.enabled = true,
  });

  @override
  State<SelecteurCommercial> createState() => _SelecteurCommercialState();
}

class _SelecteurCommercialState extends State<SelecteurCommercial> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _showSuggestions = false;
  List<Map<String, String>> _suggestions = [];
  String? _commercialSelectionne;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _commercialSelectionne = widget.commercialSelectionne;

    // Initialiser le contrôleur avec le nom sélectionné
    if (_commercialSelectionne != null) {
      _controller.text = _commercialSelectionne!;
    }

    _focusNode.addListener(_onFocusChanged);
    _updateSuggestions('');
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _updateSuggestions(_controller.text);
      setState(() {
        _showSuggestions = true;
      });
    } else {
      // Délai plus long pour permettre la sélection
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _showSuggestions = false;
          });
        }
      });
    }
  }

  void _updateSuggestions(String query) {
    final allCommerciaux = PersonnelApisavana.getTousCommerciaux();

    if (query.isEmpty) {
      _suggestions = List.from(allCommerciaux);
    } else {
      final queryLower = query.toLowerCase();
      _suggestions = allCommerciaux.where((commercial) {
        final nom = commercial['nom']?.toLowerCase() ?? '';
        final zone = commercial['zone']?.toLowerCase() ?? '';
        return nom.contains(queryLower) || zone.contains(queryLower);
      }).toList();
    }

    // Limiter à 8 suggestions pour éviter la surcharge UI
    if (_suggestions.length > 8) {
      _suggestions = _suggestions.take(8).toList();
    }
  }

  void _onTextChanged(String value) {
    _updateSuggestions(value);
    setState(() {
      _showSuggestions = value.isNotEmpty || _focusNode.hasFocus;
    });

    // Notifier le changement
    _commercialSelectionne = value.isEmpty ? null : value;
    widget.onChanged(_commercialSelectionne);
  }

  void _selectCommercial(String nom) {
    _controller.text = nom;
    _commercialSelectionne = nom;
    _focusNode.unfocus();

    setState(() {
      _showSuggestions = false;
    });

    widget.onChanged(_commercialSelectionne);
  }

  Widget _buildSuggestionsList() {
    if (!_showSuggestions || _suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Organiser par zones
    final Map<String, List<Map<String, String>>> commerciauxParZone = {};
    for (final commercial in _suggestions) {
      final zone = commercial['zone'] ?? 'Autres';
      commerciauxParZone.putIfAbsent(zone, () => []).add(commercial);
    }

    return Card(
      elevation: 8,
      margin: const EdgeInsets.only(top: 4),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.business_center_outlined,
                      size: 16,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Commerciaux APISAVANA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Commerciaux par zone
              ...commerciauxParZone.entries.map((entry) {
                final zone = entry.key;
                final commerciauxZone = entry.value;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // En-tête de zone
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      color: Colors.grey.shade50,
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            zone.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Liste des commerciaux de cette zone
                    ...commerciauxZone.map((commercial) {
                      final nom = commercial['nom'] ?? '';
                      final telephone = commercial['telephone'] ?? '';

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            debugPrint('🔧 Sélection commercial: $nom');
                            _selectCommercial(nom);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nom,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (telephone.isNotEmpty)
                                        Text(
                                          telephone,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 12,
                                  color: Colors.grey.shade400,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }),

              // Option saisie libre si pas de correspondance exacte
              if (_controller.text.isNotEmpty &&
                  !_suggestions.any((c) =>
                      c['nom']?.toLowerCase() ==
                      _controller.text.toLowerCase())) ...[
                const Divider(height: 1),
                InkWell(
                  onTap: () => _selectCommercial(_controller.text),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.orange.shade100,
                          child: Icon(
                            Icons.add,
                            size: 16,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Utiliser "${_controller.text}"',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Ajouter ce commercial personnalisé',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.person_add,
                          size: 16,
                          color: Colors.orange.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Champ de saisie
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          onChanged: _onTextChanged,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.person_search),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_controller.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _controller.clear();
                      _commercialSelectionne = null;
                      widget.onChanged(null);
                      _updateSuggestions('');
                    },
                    icon: const Icon(Icons.clear),
                    iconSize: 20,
                  ),
                IconButton(
                  onPressed: () {
                    if (_showSuggestions) {
                      _focusNode.unfocus();
                    } else {
                      _focusNode.requestFocus();
                    }
                  },
                  icon: Icon(_showSuggestions
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down),
                  iconSize: 20,
                ),
              ],
            ),
            border: const OutlineInputBorder(),
          ),
          validator: widget.required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez sélectionner ou saisir un commercial';
                  }
                  return null;
                }
              : null,
        ),

        // Liste des suggestions
        _buildSuggestionsList(),
      ],
    );
  }
}

/// Widget simplifié pour sélection rapide uniquement dans la liste
class SelecteurCommercialRapide extends StatelessWidget {
  final String? commercialSelectionne;
  final ValueChanged<String?> onChanged;
  final String? labelText;
  final bool enabled;

  const SelecteurCommercialRapide({
    super.key,
    this.commercialSelectionne,
    required this.onChanged,
    this.labelText = 'Commercial',
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: commercialSelectionne,
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: const Icon(Icons.business_center_outlined),
        border: const OutlineInputBorder(),
      ),
      isExpanded: true,
      items: [
        // Option vide
        const DropdownMenuItem<String>(
          value: null,
          child: Text(
            'Sélectionnez un commercial...',
            style: TextStyle(color: Colors.grey),
          ),
        ),

        // Commerciaux groupés par zone
        ...PersonnelApisavana.getZonesCommerciales().expand((zone) {
          final commerciauxZone = PersonnelApisavana.getCommerciauxByZone(zone);

          return [
            // En-tête de zone (non sélectionnable)
            DropdownMenuItem<String>(
              enabled: false,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  zone.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ),

            // Commerciaux de cette zone
            ...commerciauxZone.map((commercial) {
              final nom = commercial['nom'] ?? '';

              return DropdownMenuItem<String>(
                value: nom,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    nom,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              );
            }),
          ];
        }),
      ],
    );
  }
}
