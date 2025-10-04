import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/user_management_models.dart';
import '../services/user_management_service.dart';
import 'package:apisavana_gestion/utils/role_utils.dart';

/// Widget pour afficher l'historique des actions utilisateurs
class UserActionsWidget extends StatelessWidget {
  final List<UserAction> actions;
  final bool isLoading;
  final bool isMobile;

  const UserActionsWidget({
    Key? key,
    required this.actions,
    required this.isLoading,
    required this.isMobile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 400,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
              ),
              SizedBox(height: 16),
              Text('Chargement de l\'historique...'),
            ],
          ),
        ),
      );
    }

    if (actions.isEmpty) {
      return Container(
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune action récente',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Les actions des utilisateurs apparaîtront ici',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header avec statistiques rapides
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF2196F3).withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.analytics, color: Colors.white, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historique des Actions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${actions.length} actions récentes',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Temps réel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Filtres rapides
        Container(
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip('Toutes', true),
              _buildFilterChip('Créations', false),
              _buildFilterChip('Modifications', false),
              _buildFilterChip('Suppressions', false),
              _buildFilterChip('Connexions', false),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Liste des actions
        Expanded(
          child: Container(
            color: Colors.white,
            child: ListView.separated(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              itemCount: actions.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final action = actions[index];
                return _buildActionCard(action);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(UserAction action) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec type d'action et timestamp
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getActionColor(action.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    action.type.icon,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.type.displayName,
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: _getActionColor(action.type),
                        ),
                      ),
                      Text(
                        _formatTimestamp(action.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isMobile)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getActionColor(action.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      action.type.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getActionColor(action.type),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              action.description,
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                color: const Color(0xFF2D0C0D),
              ),
            ),

            const SizedBox(height: 8),

            // Informations sur l'admin
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Par: ${action.adminEmail}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),

            // Détails des changements (si disponibles)
            if (action.oldValues != null || action.newValues != null)
              _buildChangeDetails(action),
          ],
        ),
      ),
    );
  }

  Widget _buildChangeDetails(UserAction action) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Détails des modifications:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          if (action.oldValues != null && action.newValues != null)
            ...action.newValues!.keys.map((key) {
              final oldValue = action.oldValues?[key];
              final newValue = action.newValues![key];

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        '$key:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (oldValue != null)
                            Text(
                              '• Ancien: $oldValue',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red[600],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            '• Nouveau: $newValue',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList()
          else if (action.newValues != null)
            ...action.newValues!.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${entry.key}:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${entry.value}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2D0C0D),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Color _getActionColor(UserActionType type) {
    switch (type) {
      case UserActionType.created:
        return Colors.green;
      case UserActionType.updated:
        return Colors.blue;
      case UserActionType.activated:
        return Colors.green;
      case UserActionType.deactivated:
        return Colors.orange;
      case UserActionType.roleChanged:
        return Colors.purple;
      case UserActionType.siteChanged:
        return Colors.indigo;
      case UserActionType.passwordReset:
        return Colors.amber;
      case UserActionType.emailVerified:
        return Colors.teal;
      case UserActionType.emailResent:
        return Colors.tealAccent;
      case UserActionType.passwordGenerated:
        return Colors.amberAccent;
      case UserActionType.accessGranted:
        return Colors.lightGreen;
      case UserActionType.accessRevoked:
        return Colors.deepOrange;
      case UserActionType.deleted:
        return Colors.red;
      case UserActionType.other:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} à ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Color(0xFF2196F3),
            fontWeight: FontWeight.w500,
          ),
        ),
        selected: isSelected,
        selectedColor: Color(0xFF2196F3),
        backgroundColor: Colors.grey[100],
        checkmarkColor: Colors.white,
        onSelected: (selected) {
          // TODO: Implémenter le filtrage
        },
      ),
    );
  }
}

/// Modal pour créer un nouvel utilisateur
class CreateUserModal extends StatefulWidget {
  final List<String> availableRoles;
  final List<String> availableSites;
  final VoidCallback onUserCreated;

  const CreateUserModal({
    Key? key,
    required this.availableRoles,
    required this.availableSites,
    required this.onUserCreated,
  }) : super(key: key);

  @override
  State<CreateUserModal> createState() => _CreateUserModalState();
}

class _CreateUserModalState extends State<CreateUserModal> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();

  String? _selectedRole;
  String? _selectedSite;
  bool _isLoading = false;
  bool _showPassword = false;

  final UserManagementService _userService = Get.find<UserManagementService>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _emailController.clear();
    _passwordController.clear();
    _nomController.clear();
    _prenomController.clear();
    _telephoneController.clear();
    setState(() {
      _selectedRole = null;
      _selectedSite = null;
      _showPassword = false;
    });
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null || _selectedSite == null) {
      Get.snackbar(
        'Erreur',
        'Veuillez sélectionner un rôle et un site',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Vérifier si l'email existe déjà
      final emailExists =
          await _userService.emailExists(_emailController.text.trim());
      if (emailExists) {
        Get.snackbar(
          'Erreur',
          'Un utilisateur avec cet email existe déjà',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final success = await _userService.createUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        telephone: _telephoneController.text.trim(),
        role: _selectedRole!,
        site: _selectedSite!,
      );

      if (success) {
        _clearForm(); // Vider les champs du formulaire
        Get.snackbar(
          'Succès',
          'Utilisateur créé avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        widget.onUserCreated();
      } else {
        Get.snackbar(
          'Erreur',
          'Impossible de créer l\'utilisateur',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Une erreur est survenue: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: isMobile ? null : 500,
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.9, // Maximum 90% de la hauteur de l'écran
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête fixe
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  const Icon(Icons.person_add, color: Color(0xFF2196F3)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Créer un nouvel utilisateur',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),

            // Contenu scrollable
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Formulaire
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'L\'email est requis';
                          }
                          if (!GetUtils.isEmail(value)) {
                            return 'Email invalide';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe *',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_showPassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                          ),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                        ),
                        obscureText: !_showPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Le mot de passe est requis';
                          }
                          if (value.length < 6) {
                            return 'Le mot de passe doit contenir au moins 6 caractères';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _prenomController,
                              decoration: const InputDecoration(
                                labelText: 'Prénom *',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Le prénom est requis';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _nomController,
                              decoration: const InputDecoration(
                                labelText: 'Nom *',
                                prefixIcon: Icon(Icons.person_outline),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Le nom est requis';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _telephoneController,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone *',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Le téléphone est requis';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedRole,
                              decoration: const InputDecoration(
                                labelText: 'Rôle *',
                                prefixIcon: Icon(Icons.work),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                              ),
                              items: widget.availableRoles
                                  .map((role) => DropdownMenuItem(
                                        value: role,
                                        child: Text(role),
                                      ))
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedRole = value),
                              validator: (value) {
                                if (value == null) {
                                  return 'Le rôle est requis';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedSite,
                              decoration: const InputDecoration(
                                labelText: 'Site *',
                                prefixIcon: Icon(Icons.location_on),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                              ),
                              items: widget.availableSites
                                  .map((site) => DropdownMenuItem(
                                        value: site,
                                        child: Text(site),
                                      ))
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedSite = value),
                              validator: (value) {
                                if (value == null) {
                                  return 'Le site est requis';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Boutons fixes en bas
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Get.back(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _createUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Créer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal pour afficher les détails d'un utilisateur
class UserDetailsModal extends StatelessWidget {
  final AppUser user;
  final VoidCallback onUserUpdated;

  const UserDetailsModal({
    Key? key,
    required this.user,
    required this.onUserUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: isMobile ? null : 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(
                          user.initiales,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getRoleColor(user.role),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.nomComplet,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: user.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    user.isActive ? 'Actif' : 'Inactif',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Informations détaillées
            _buildInfoSection('Informations personnelles', [
              _buildInfoRow(Icons.person, 'Nom complet', user.nomComplet),
              _buildInfoRow(Icons.email, 'Email', user.email),
              _buildInfoRow(Icons.phone, 'Téléphone', user.telephone),
            ]),

            const SizedBox(height: 16),

            _buildInfoSection('Informations professionnelles', [
              _buildInfoRow(Icons.work, 'Rôle', user.role),
              _buildInfoRow(Icons.location_on, 'Site', user.site),
            ]),

            const SizedBox(height: 16),

            _buildInfoSection('Statut du compte', [
              _buildInfoRow(
                user.isActive ? Icons.check_circle : Icons.cancel,
                'Statut',
                user.isActive ? 'Actif' : 'Inactif',
                color: user.isActive ? Colors.green : Colors.red,
              ),
              _buildInfoRow(
                user.emailVerified ? Icons.verified : Icons.email,
                'Email vérifié',
                user.emailVerified ? 'Oui' : 'Non',
                color: user.emailVerified ? Colors.green : Colors.orange,
              ),
              _buildInfoRow(
                user.isOnline ? Icons.online_prediction : Icons.offline_bolt,
                'En ligne',
                user.isOnline ? 'Oui' : 'Non',
                color: user.isOnline ? Colors.green : Colors.grey,
              ),
            ]),

            const SizedBox(height: 16),

            _buildInfoSection('Dates importantes', [
              _buildInfoRow(Icons.calendar_today, 'Créé le',
                  _formatDate(user.dateCreation)),
              _buildInfoRow(
                Icons.login,
                'Dernière connexion',
                user.dateLastLogin != null
                    ? _formatDate(user.dateLastLogin!)
                    : 'Jamais',
              ),
            ]),

            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Fermer'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    Get.back();
                    _showUserHistory();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Voir l\'historique'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2196F3),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? const Color(0xFF2D0C0D),
                fontWeight: color != null ? FontWeight.w500 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserHistory() {
    // Implémenter l'affichage de l'historique de l'utilisateur
    Get.dialog(
      UserHistoryModal(userId: user.id),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFF2196F3);
      case 'collecteur':
        return const Color(0xFF4CAF50);
      case 'contrôleur':
      case 'controlleur':
        return const Color(0xFFFF9800);
      case 'extracteur':
        return const Color(0xFF9C27B0);
      case 'filtreur':
        return const Color(0xFFE91E63);
      case 'conditionneur':
        return const Color(0xFF00BCD4);
      case 'magazinier':
        return const Color(0xFF8BC34A);
      case 'gestionnaire commercial':
        return const Color(0xFFFFEB3B);
      case 'commercial':
        return const Color(0xFF795548);
      case 'caissier':
        return const Color(0xFF607D8B);
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Modal pour l'historique d'un utilisateur spécifique
class UserHistoryModal extends StatefulWidget {
  final String userId;

  const UserHistoryModal({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<UserHistoryModal> createState() => _UserHistoryModalState();
}

class _UserHistoryModalState extends State<UserHistoryModal> {
  final UserManagementService _userService = Get.find<UserManagementService>();
  List<UserAction> _actions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserActions();
  }

  Future<void> _loadUserActions() async {
    try {
      final actions = await _userService.getUserActions(widget.userId);
      setState(() {
        _actions = actions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar(
        'Erreur',
        'Impossible de charger l\'historique',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: isMobile ? null : 700,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // En-tête
            Row(
              children: [
                const Icon(Icons.history, color: Color(0xFF2196F3)),
                const SizedBox(width: 8),
                const Text(
                  'Historique de l\'utilisateur',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Contenu
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _actions.isEmpty
                      ? const Center(
                          child: Text('Aucun historique disponible'),
                        )
                      : UserActionsWidget(
                          actions: _actions,
                          isLoading: false,
                          isMobile: isMobile,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modals pour éditer un utilisateur, changer le rôle, changer le site
class EditUserModal extends StatefulWidget {
  final AppUser user;
  final List<String> availableRoles;
  final List<String> availableSites;
  final VoidCallback onUserUpdated;

  const EditUserModal({
    Key? key,
    required this.user,
    required this.availableRoles,
    required this.availableSites,
    required this.onUserUpdated,
  }) : super(key: key);

  @override
  State<EditUserModal> createState() => _EditUserModalState();
}

class _EditUserModalState extends State<EditUserModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _telephoneController;

  late String _selectedRole;
  late String _selectedSite;
  bool _isLoading = false;

  final UserManagementService _userService = Get.find<UserManagementService>();

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.user.nom);
    _prenomController = TextEditingController(text: widget.user.prenom);
    _telephoneController = TextEditingController(text: widget.user.telephone);
    _selectedRole = widget.user.role;
    _selectedSite = widget.user.site;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updates = <String, dynamic>{};

      if (_nomController.text.trim() != widget.user.nom) {
        updates['nom'] = _nomController.text.trim();
      }

      if (_prenomController.text.trim() != widget.user.prenom) {
        updates['prenom'] = _prenomController.text.trim();
      }

      if (_telephoneController.text.trim() != widget.user.telephone) {
        updates['telephone'] = _telephoneController.text.trim();
      }

      if (_selectedRole != widget.user.role) {
        final normalizedPrimary =
            primaryRoleFrom(_selectedRole) ?? _selectedRole.trim();
        final updatedRoles = <String>[];

        if (normalizedPrimary.isNotEmpty) {
          updatedRoles.add(normalizedPrimary);
        }

        for (final role in widget.user.secondaryRoles) {
          if (!updatedRoles.contains(role)) {
            updatedRoles.add(role);
          }
        }

        if (updatedRoles.isEmpty) {
          updatedRoles.add(_selectedRole);
        }

        updates['role'] = updatedRoles;
      }

      if (_selectedSite != widget.user.site) {
        updates['site'] = _selectedSite;
      }

      if (updates.isEmpty) {
        Get.snackbar(
          'Information',
          'Aucune modification détectée',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final success = await _userService.updateUser(widget.user.id, updates);

      if (success) {
        Get.snackbar(
          'Succès',
          'Utilisateur mis à jour avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        widget.onUserUpdated();
      } else {
        Get.snackbar(
          'Erreur',
          'Impossible de mettre à jour l\'utilisateur',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Une erreur est survenue: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: isMobile ? null : 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  const Icon(Icons.edit, color: Color(0xFF2196F3)),
                  const SizedBox(width: 8),
                  Text(
                    'Modifier ${widget.user.nomComplet}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Email (lecture seule)
              TextFormField(
                initialValue: widget.user.email,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                style: TextStyle(color: Colors.grey[600]),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _prenomController,
                      decoration: const InputDecoration(
                        labelText: 'Prénom *',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le prénom est requis';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom *',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le nom est requis';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _telephoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone *',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le téléphone est requis';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Rôle *',
                        prefixIcon: Icon(Icons.work),
                        border: OutlineInputBorder(),
                      ),
                      items: widget.availableRoles
                          .map((role) => DropdownMenuItem(
                                value: role,
                                child: Text(role),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedRole = value!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSite,
                      decoration: const InputDecoration(
                        labelText: 'Site *',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                      items: widget.availableSites
                          .map((site) => DropdownMenuItem(
                                value: site,
                                child: Text(site),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedSite = value!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Boutons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Get.back(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Sauvegarder'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal pour changer le rôle
class ChangeRoleModal extends StatefulWidget {
  final AppUser user;
  final List<String> availableRoles;
  final VoidCallback onRoleChanged;

  const ChangeRoleModal({
    Key? key,
    required this.user,
    required this.availableRoles,
    required this.onRoleChanged,
  }) : super(key: key);

  @override
  State<ChangeRoleModal> createState() => _ChangeRoleModalState();
}

class _ChangeRoleModalState extends State<ChangeRoleModal> {
  late String _selectedRole;
  bool _isLoading = false;

  final UserManagementService _userService = Get.find<UserManagementService>();

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
  }

  Future<void> _changeRole() async {
    if (_selectedRole == widget.user.role) {
      Get.snackbar(
        'Information',
        'Le rôle sélectionné est identique au rôle actuel',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success =
          await _userService.changeUserRole(widget.user.id, _selectedRole);

      if (success) {
        Get.snackbar(
          'Succès',
          'Rôle modifié avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        widget.onRoleChanged();
      } else {
        Get.snackbar(
          'Erreur',
          'Impossible de modifier le rôle',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Une erreur est survenue: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          const Icon(Icons.swap_horiz, color: Color(0xFF2196F3)),
          const SizedBox(width: 8),
          const Text('Changer le rôle'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Utilisateur: ${widget.user.nomComplet}'),
          const SizedBox(height: 8),
          Text('Rôle actuel: ${widget.user.role}'),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: const InputDecoration(
              labelText: 'Nouveau rôle',
              border: OutlineInputBorder(),
            ),
            items: widget.availableRoles
                .map((role) => DropdownMenuItem(
                      value: role,
                      child: Text(role),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedRole = value!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Get.back(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _changeRole,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Changer'),
        ),
      ],
    );
  }
}

/// Modal pour changer le site
class ChangeSiteModal extends StatefulWidget {
  final AppUser user;
  final List<String> availableSites;
  final VoidCallback onSiteChanged;

  const ChangeSiteModal({
    Key? key,
    required this.user,
    required this.availableSites,
    required this.onSiteChanged,
  }) : super(key: key);

  @override
  State<ChangeSiteModal> createState() => _ChangeSiteModalState();
}

class _ChangeSiteModalState extends State<ChangeSiteModal> {
  late String _selectedSite;
  bool _isLoading = false;

  final UserManagementService _userService = Get.find<UserManagementService>();

  @override
  void initState() {
    super.initState();
    _selectedSite = widget.user.site;
  }

  Future<void> _changeSite() async {
    if (_selectedSite == widget.user.site) {
      Get.snackbar(
        'Information',
        'Le site sélectionné est identique au site actuel',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success =
          await _userService.changeUserSite(widget.user.id, _selectedSite);

      if (success) {
        Get.snackbar(
          'Succès',
          'Site modifié avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        widget.onSiteChanged();
      } else {
        Get.snackbar(
          'Erreur',
          'Impossible de modifier le site',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Une erreur est survenue: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          const Icon(Icons.location_on, color: Color(0xFF2196F3)),
          const SizedBox(width: 8),
          const Text('Changer le site'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Utilisateur: ${widget.user.nomComplet}'),
          const SizedBox(height: 8),
          Text('Site actuel: ${widget.user.site}'),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedSite,
            decoration: const InputDecoration(
              labelText: 'Nouveau site',
              border: OutlineInputBorder(),
            ),
            items: widget.availableSites
                .map((site) => DropdownMenuItem(
                      value: site,
                      child: Text(site),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedSite = value!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Get.back(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _changeSite,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Changer'),
        ),
      ],
    );
  }
}
