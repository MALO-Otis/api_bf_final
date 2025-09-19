import 'package:flutter/material.dart';
import '../models/user_management_models.dart';

/// Widget pour les filtres des utilisateurs
class UserFiltersWidget extends StatefulWidget {
  final UserFilters filters;
  final Function(UserFilters) onFiltersChanged;
  final List<String> availableRoles;
  final List<String> availableSites;
  final bool isMobile;

  const UserFiltersWidget({
    Key? key,
    required this.filters,
    required this.onFiltersChanged,
    required this.availableRoles,
    required this.availableSites,
    required this.isMobile,
  }) : super(key: key);

  @override
  State<UserFiltersWidget> createState() => _UserFiltersWidgetState();
}

class _UserFiltersWidgetState extends State<UserFiltersWidget> {
  late TextEditingController _searchController;
  late UserFilters _currentFilters;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.filters.searchTerm);
    _currentFilters = widget.filters;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilters() {
    widget.onFiltersChanged(_currentFilters);
  }

  void _clearFilters() {
    setState(() {
      _currentFilters = _currentFilters.clearFilters();
      _searchController.clear();
    });
    _updateFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Barre de recherche principale
          Padding(
            padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
            child: Column(
              children: [
                // Première ligne : Champ de recherche et boutons
                Row(
                  children: [
                    // Champ de recherche
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Rechercher par nom, email, téléphone...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _currentFilters = _currentFilters
                                          .copyWith(searchTerm: '');
                                    });
                                    _updateFilters();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFF2196F3)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _currentFilters =
                                _currentFilters.copyWith(searchTerm: value);
                          });
                        },
                        onSubmitted: (value) => _updateFilters(),
                      ),
                    ),

                    SizedBox(width: widget.isMobile ? 4 : 8),

                    // Bouton filtres avancés
                    IconButton(
                      icon: Icon(
                        _isExpanded ? Icons.filter_list_off : Icons.filter_list,
                        color: _currentFilters.hasActiveFilters
                            ? const Color(0xFF2196F3)
                            : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      tooltip: 'Filtres avancés',
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.all(widget.isMobile ? 6 : 8),
                    ),

                    // Bouton rechercher (conditionnel selon l'espace)
                    if (!widget.isMobile ||
                        MediaQuery.of(context).size.width > 400)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        child: ElevatedButton(
                          onPressed: _updateFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: widget.isMobile ? 8 : 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: Size(widget.isMobile ? 40 : 100, 44),
                          ),
                          child: widget.isMobile
                              ? const Icon(Icons.search, size: 18)
                              : const Text('Rechercher'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Filtres avancés (collapsible)
          if (_isExpanded) _buildAdvancedFilters(),

          // Indicateurs de filtres actifs
          if (_currentFilters.hasActiveFilters) _buildActiveFiltersChips(),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Container(
      padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtres Avancés',
            style: TextStyle(
              fontSize: widget.isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Première ligne de filtres
          widget.isMobile
              ? Column(
                  children: [
                    _buildRoleFilter(),
                    const SizedBox(height: 12),
                    _buildSiteFilter(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildRoleFilter()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildSiteFilter()),
                  ],
                ),

          const SizedBox(height: 16),

          // Deuxième ligne de filtres
          widget.isMobile
              ? Column(
                  children: [
                    _buildStatusFilter(),
                    const SizedBox(height: 12),
                    _buildEmailVerificationFilter(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildStatusFilter()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildEmailVerificationFilter()),
                  ],
                ),

          const SizedBox(height: 16),

          // Filtres de date
          _buildDateFilters(),

          const SizedBox(height: 16),

          // Tri
          _buildSortOptions(),

          const SizedBox(height: 16),

          // Boutons d'action
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_currentFilters.hasActiveFilters)
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Effacer tout'),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _updateFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Appliquer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilter() {
    return DropdownButtonFormField<String>(
      value: _currentFilters.role,
      decoration: InputDecoration(
        labelText: 'Rôle',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Tous les rôles'),
        ),
        ...widget.availableRoles.map((role) => DropdownMenuItem<String>(
              value: role,
              child: Text(role),
            )),
      ],
      onChanged: (value) {
        setState(() {
          _currentFilters = _currentFilters.copyWith(role: value);
        });
      },
    );
  }

  Widget _buildSiteFilter() {
    return DropdownButtonFormField<String>(
      value: _currentFilters.site,
      decoration: InputDecoration(
        labelText: 'Site',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Tous les sites'),
        ),
        ...widget.availableSites.map((site) => DropdownMenuItem<String>(
              value: site,
              child: Text(site),
            )),
      ],
      onChanged: (value) {
        setState(() {
          _currentFilters = _currentFilters.copyWith(site: value);
        });
      },
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<bool>(
      value: _currentFilters.isActive,
      decoration: InputDecoration(
        labelText: 'Statut',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: const [
        DropdownMenuItem<bool>(
          value: null,
          child: Text('Tous les statuts'),
        ),
        DropdownMenuItem<bool>(
          value: true,
          child: Text('Actifs seulement'),
        ),
        DropdownMenuItem<bool>(
          value: false,
          child: Text('Inactifs seulement'),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _currentFilters = _currentFilters.copyWith(isActive: value);
        });
      },
    );
  }

  Widget _buildEmailVerificationFilter() {
    return DropdownButtonFormField<bool>(
      value: _currentFilters.emailVerified,
      decoration: InputDecoration(
        labelText: 'Email vérifié',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: const [
        DropdownMenuItem<bool>(
          value: null,
          child: Text('Tous'),
        ),
        DropdownMenuItem<bool>(
          value: true,
          child: Text('Vérifiés seulement'),
        ),
        DropdownMenuItem<bool>(
          value: false,
          child: Text('Non vérifiés seulement'),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _currentFilters = _currentFilters.copyWith(emailVerified: value);
        });
      },
    );
  }

  Widget _buildDateFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Période de création',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        widget.isMobile
            ? Column(
                children: [
                  _buildDateField(
                      'Date de début', _currentFilters.dateCreationStart,
                      (date) {
                    setState(() {
                      _currentFilters =
                          _currentFilters.copyWith(dateCreationStart: date);
                    });
                  }),
                  const SizedBox(height: 8),
                  _buildDateField(
                      'Date de fin', _currentFilters.dateCreationEnd, (date) {
                    setState(() {
                      _currentFilters =
                          _currentFilters.copyWith(dateCreationEnd: date);
                    });
                  }),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                        'Date de début', _currentFilters.dateCreationStart,
                        (date) {
                      setState(() {
                        _currentFilters =
                            _currentFilters.copyWith(dateCreationStart: date);
                      });
                    }),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateField(
                        'Date de fin', _currentFilters.dateCreationEnd, (date) {
                      setState(() {
                        _currentFilters =
                            _currentFilters.copyWith(dateCreationEnd: date);
                      });
                    }),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildDateField(
      String label, DateTime? value, Function(DateTime?) onChanged) {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixIcon: value != null
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => onChanged(null),
              )
            : const Icon(Icons.calendar_today),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      controller: TextEditingController(
        text: value != null ? '${value.day}/${value.month}/${value.year}' : '',
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          onChanged(date);
        }
      },
    );
  }

  Widget _buildSortOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tri',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        widget.isMobile
            ? Column(
                children: [
                  DropdownButtonFormField<UserSortField>(
                    value: _currentFilters.sortField,
                    decoration: InputDecoration(
                      labelText: 'Trier par',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    items: UserSortField.values
                        .map((field) => DropdownMenuItem(
                              value: field,
                              child: Text(field.displayName),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _currentFilters =
                              _currentFilters.copyWith(sortField: value);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('Croissant'),
                          value: true,
                          groupValue: _currentFilters.sortAscending,
                          onChanged: (value) {
                            setState(() {
                              _currentFilters = _currentFilters.copyWith(
                                  sortAscending: value);
                            });
                          },
                          dense: true,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('Décroissant'),
                          value: false,
                          groupValue: _currentFilters.sortAscending,
                          onChanged: (value) {
                            setState(() {
                              _currentFilters = _currentFilters.copyWith(
                                  sortAscending: value);
                            });
                          },
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<UserSortField>(
                      value: _currentFilters.sortField,
                      decoration: InputDecoration(
                        labelText: 'Trier par',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      items: UserSortField.values
                          .map((field) => DropdownMenuItem(
                                value: field,
                                child: Text(field.displayName),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _currentFilters =
                                _currentFilters.copyWith(sortField: value);
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<bool>(
                      value: _currentFilters.sortAscending,
                      decoration: InputDecoration(
                        labelText: 'Ordre',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem<bool>(
                          value: true,
                          child: Text('Croissant'),
                        ),
                        DropdownMenuItem<bool>(
                          value: false,
                          child: Text('Décroissant'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _currentFilters =
                                _currentFilters.copyWith(sortAscending: value);
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildActiveFiltersChips() {
    final activeFilters = <Widget>[];

    if (_currentFilters.searchTerm != null &&
        _currentFilters.searchTerm!.isNotEmpty) {
      activeFilters.add(
          _buildFilterChip('Recherche: "${_currentFilters.searchTerm}"', () {
        setState(() {
          _currentFilters = _currentFilters.copyWith(searchTerm: '');
          _searchController.clear();
        });
        _updateFilters();
      }));
    }

    if (_currentFilters.role != null) {
      activeFilters.add(_buildFilterChip('Rôle: ${_currentFilters.role}', () {
        setState(() {
          _currentFilters = _currentFilters.copyWith(role: null);
        });
        _updateFilters();
      }));
    }

    if (_currentFilters.site != null) {
      activeFilters.add(_buildFilterChip('Site: ${_currentFilters.site}', () {
        setState(() {
          _currentFilters = _currentFilters.copyWith(site: null);
        });
        _updateFilters();
      }));
    }

    if (_currentFilters.isActive != null) {
      activeFilters.add(_buildFilterChip(
          'Statut: ${_currentFilters.isActive! ? 'Actif' : 'Inactif'}', () {
        setState(() {
          _currentFilters = _currentFilters.copyWith(isActive: null);
        });
        _updateFilters();
      }));
    }

    if (_currentFilters.emailVerified != null) {
      activeFilters.add(_buildFilterChip(
          'Email: ${_currentFilters.emailVerified! ? 'Vérifié' : 'Non vérifié'}',
          () {
        setState(() {
          _currentFilters = _currentFilters.copyWith(emailVerified: null);
        });
        _updateFilters();
      }));
    }

    if (activeFilters.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Filtres actifs:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Tout effacer'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: activeFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onDelete,
      backgroundColor: const Color(0xFF2196F3).withOpacity(0.1),
      deleteIconColor: const Color(0xFF2196F3),
      labelStyle: const TextStyle(color: Color(0xFF2196F3)),
    );
  }
}
