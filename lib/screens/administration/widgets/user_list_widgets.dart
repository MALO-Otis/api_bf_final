import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_management_models.dart';

/// Widget principal pour afficher la liste des utilisateurs
class UserListWidget extends StatelessWidget {
  final RxList<AppUser> users;
  final bool isLoading;
  final bool isMobile;
  final Function(AppUser) onUserTap;
  final Function(AppUser) onUserEdit;
  final Function(AppUser) onUserToggleStatus;
  final Function(AppUser) onUserChangeRole;
  final Function(AppUser) onUserChangeSite;
  final Function(AppUser) onUserResetPassword;
  final Function(AppUser) onUserDelete;

  const UserListWidget({
    Key? key,
    required this.users,
    required this.isLoading,
    required this.isMobile,
    required this.onUserTap,
    required this.onUserEdit,
    required this.onUserToggleStatus,
    required this.onUserChangeRole,
    required this.onUserChangeSite,
    required this.onUserResetPassword,
    required this.onUserDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (isLoading) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (users.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun utilisateur trouvé',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Essayez de modifier vos filtres',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        color: Colors.white,
        child: isMobile 
            ? _buildMobileList()
            : _buildDesktopTable(),
      );
    });
  }

  Widget _buildMobileList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildMobileUserCard(user);
      },
    );
  }

  Widget _buildMobileUserCard(AppUser user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => onUserTap(user),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec avatar et statut
              Row(
                children: [
                  Stack(
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
                      // Indicateur en ligne
                      if (user.isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.nomComplet,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Badge statut
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: user.isActive ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.isActive ? 'Actif' : 'Inactif',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Informations détaillées
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildInfoChip(
                      Icons.work,
                      user.role,
                      _getRoleColor(user.role),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 1,
                    child: _buildInfoChip(
                      Icons.location_on,
                      user.site,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      Icons.phone,
                      user.telephone,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      user.emailVerified ? Icons.verified : Icons.email,
                      user.emailVerified ? 'Vérifié' : 'Non vérifié',
                      user.emailVerified ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildActionButton(
                      Icons.edit,
                      'Modifier',
                      Colors.blue,
                      () => onUserEdit(user),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildActionButton(
                      user.isActive ? Icons.block : Icons.check_circle,
                      user.isActive ? 'Désactiver' : 'Activer',
                      user.isActive ? Colors.orange : Colors.green,
                      () => onUserToggleStatus(user),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildActionButton(
                      Icons.more_vert,
                      'Plus',
                      Colors.grey,
                      () => _showMobileActionsModal(user),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  void _showMobileActionsModal(AppUser user) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.nomComplet,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionTile(
              Icons.swap_horiz,
              'Changer le rôle',
              () {
                Get.back();
                onUserChangeRole(user);
              },
            ),
            _buildActionTile(
              Icons.location_on,
              'Changer le site',
              () {
                Get.back();
                onUserChangeSite(user);
              },
            ),
            _buildActionTile(
              Icons.lock_reset,
              'Réinitialiser mot de passe',
              () {
                Get.back();
                onUserResetPassword(user);
              },
            ),
            _buildActionTile(
              Icons.delete,
              'Supprimer',
              () {
                Get.back();
                onUserDelete(user);
              },
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onPressed, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.blue,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black,
        ),
      ),
      onTap: onPressed,
    );
  }

  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(Get.context!).size.width,
        ),
        child: DataTable(
          columnSpacing: 16,
          headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
          columns: const [
            DataColumn(label: Text('Utilisateur', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Rôle', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Site', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Dernière connexion', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: users.map((user) => _buildDesktopRow(user)).toList(),
        ),
      ),
    );
  }

  DataRow _buildDesktopRow(AppUser user) {
    return DataRow(
      cells: [
        // Utilisateur
        DataCell(
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
                    backgroundImage: user.photoUrl != null 
                        ? NetworkImage(user.photoUrl!) 
                        : null,
                    child: user.photoUrl == null 
                        ? Text(
                            user.initiales,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getRoleColor(user.role),
                            ),
                          )
                        : null,
                  ),
                  if (user.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.nomComplet,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      user.telephone,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          onTap: () => onUserTap(user),
        ),
        
        // Rôle
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getRoleColor(user.role).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getRoleColor(user.role).withOpacity(0.3)),
            ),
            child: Text(
              user.role,
              style: TextStyle(
                fontSize: 12,
                color: _getRoleColor(user.role),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
        
        // Site
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.blue),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  user.site,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        
        // Statut
        DataCell(
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: user.isActive ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user.isActive ? 'Actif' : 'Inactif',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (user.emailVerified)
                Icon(Icons.verified, size: 16, color: Colors.green)
              else
                Icon(Icons.email, size: 16, color: Colors.orange),
            ],
          ),
        ),
        
        // Email
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              user.email,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
        
        // Dernière connexion
        DataCell(
          Text(
            user.dateLastLogin != null 
                ? _formatDate(user.dateLastLogin!)
                : 'Jamais',
            style: TextStyle(
              color: user.dateLastLogin != null ? Colors.black : Colors.grey,
            ),
          ),
        ),
        
        // Actions
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () => onUserEdit(user),
                tooltip: 'Modifier',
              ),
              IconButton(
                icon: Icon(
                  user.isActive ? Icons.block : Icons.check_circle,
                  size: 18,
                  color: user.isActive ? Colors.orange : Colors.green,
                ),
                onPressed: () => onUserToggleStatus(user),
                tooltip: user.isActive ? 'Désactiver' : 'Activer',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (value) {
                  switch (value) {
                    case 'role':
                      onUserChangeRole(user);
                      break;
                    case 'site':
                      onUserChangeSite(user);
                      break;
                    case 'password':
                      onUserResetPassword(user);
                      break;
                    case 'delete':
                      onUserDelete(user);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'role',
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz, size: 16),
                        SizedBox(width: 8),
                        Text('Changer le rôle'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'site',
                    child: Row(
                      children: [
                        Icon(Icons.location_on, size: 16),
                        SizedBox(width: 8),
                        Text('Changer le site'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'password',
                    child: Row(
                      children: [
                        Icon(Icons.lock_reset, size: 16),
                        SizedBox(width: 8),
                        Text('Réinitialiser mot de passe'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Widget pour les utilisateurs en ligne
class UserOnlineWidget extends StatelessWidget {
  final List<AppUser> onlineUsers;
  final bool isLoading;
  final bool isMobile;

  const UserOnlineWidget({
    Key? key,
    required this.onlineUsers,
    required this.isLoading,
    required this.isMobile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (onlineUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.offline_bolt,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun utilisateur en ligne',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${onlineUsers.length} utilisateur${onlineUsers.length > 1 ? 's' : ''} en ligne',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isMobile ? 1 : 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isMobile ? 4 : 3,
              ),
              itemCount: onlineUsers.length,
              itemBuilder: (context, index) {
                final user = onlineUsers[index];
                return _buildOnlineUserCard(user);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineUserCard(AppUser user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
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
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              user.nomComplet,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              user.role,
              style: TextStyle(
                fontSize: 12,
                color: _getRoleColor(user.role),
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              user.site,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
}
