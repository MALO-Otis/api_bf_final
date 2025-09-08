import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_management_models.dart';
import '../services/user_management_service.dart';
import '../widgets/user_statistics_widgets.dart';
import '../widgets/user_list_widgets.dart';
import '../widgets/user_filters_widgets.dart';
import '../widgets/user_actions_widgets.dart';
import '../../../utils/smart_appbar.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({Key? key}) : super(key: key);

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserManagementService _userService = Get.put(UserManagementService());

  final RxList<AppUser> _users = <AppUser>[].obs;
  final Rx<UserStatistics> _statistics = UserStatistics.empty().obs;
  final RxList<UserAction> _recentActions = <UserAction>[].obs;
  final Rx<UserFilters> _filters = UserFilters().obs;
  final RxBool _isLoading = true.obs; // Commencer en mode loading
  final RxBool _isLoadingStats = true.obs; // Commencer en mode loading
  final RxBool _hasInitialized =
      false.obs; // Nouveau flag pour savoir si on a initialisé

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!_hasInitialized.value) {
      _isLoading.value = true;
      _isLoadingStats.value = true;
    }

    try {
      // Charger les utilisateurs et statistiques en parallèle
      final futures = await Future.wait([
        _userService.getUsers(filters: _filters.value),
        _userService.getUserStatistics(),
        _userService.getRecentActions(limit: 50),
      ]);

      _users.value = futures[0] as List<AppUser>;
      _statistics.value = futures[1] as UserStatistics;
      _recentActions.value = futures[2] as List<UserAction>;

      if (!_hasInitialized.value) {
        _hasInitialized.value = true;
      }
    } catch (e) {
      // Seulement afficher l'erreur si on a déjà initialisé (pour éviter l'erreur rouge au début)
      if (_hasInitialized.value) {
        Get.snackbar(
          'Erreur',
          'Impossible de charger les données: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } else {
        print('Erreur de chargement initial: $e');
      }
    } finally {
      _isLoading.value = false;
      _isLoadingStats.value = false;
    }
  }

  Future<void> _applyFilters(UserFilters newFilters) async {
    _filters.value = newFilters;
    _isLoading.value = true;

    try {
      final users = await _userService.getUsers(filters: newFilters);
      _users.value = users;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'appliquer les filtres: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: SmartAppBar(
        title: "Gestion des Utilisateurs",
        onBackPressed: () => Get.back(),
        actions: [
          // Bouton refresh
          IconButton(
            icon: Obx(() => _isLoading.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh)),
            onPressed: _isLoading.value ? null : _refreshData,
            tooltip: 'Actualiser',
          ),
          // Bouton export
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportUsers,
            tooltip: 'Exporter',
          ),
          // Bouton nouvel utilisateur
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _showCreateUserModal,
              icon: const Icon(Icons.person_add, size: 18),
              label: Text(isMobile ? '' : 'Nouvel utilisateur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistiques en haut
          Obx(() => UserStatisticsHeader(
                statistics: _statistics.value,
                isLoading: _isLoadingStats.value,
                isMobile: isMobile,
              )),

          // Onglets
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF2196F3),
              labelColor: const Color(0xFF2196F3),
              unselectedLabelColor: Colors.grey[600],
              tabs: [
                Tab(
                  icon: const Icon(Icons.people, size: 20),
                  text: isMobile ? '' : 'Utilisateurs',
                ),
                Tab(
                  icon: const Icon(Icons.analytics, size: 20),
                  text: isMobile ? '' : 'Statistiques',
                ),
                Tab(
                  icon: const Icon(Icons.history, size: 20),
                  text: isMobile ? '' : 'Historique',
                ),
                Tab(
                  icon: const Icon(Icons.online_prediction, size: 20),
                  text: isMobile ? '' : 'En ligne',
                ),
              ],
            ),
          ),

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Onglet Utilisateurs
                _buildUsersTab(isMobile, isTablet),

                // Onglet Statistiques
                _buildStatisticsTab(isMobile, isTablet),

                // Onglet Historique
                _buildHistoryTab(isMobile, isTablet),

                // Onglet Utilisateurs en ligne
                _buildOnlineUsersTab(isMobile, isTablet),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab(bool isMobile, bool isTablet) {
    return Column(
      children: [
        // Filtres
        UserFiltersWidget(
          filters: _filters.value,
          onFiltersChanged: _applyFilters,
          availableRoles: _userService.availableRoles,
          availableSites: _userService.availableSites,
          isMobile: isMobile,
        ),

        // Liste des utilisateurs
        Expanded(
          child: Obx(() => UserListWidget(
                users: _users,
                isLoading: _isLoading.value,
                isMobile: isMobile,
                onUserTap: _showUserDetails,
                onUserEdit: _showEditUserModal,
                onUserToggleStatus: _toggleUserStatus,
                onUserChangeRole: _showChangeRoleModal,
                onUserChangeSite: _showChangeSiteModal,
                onUserResetPassword: _resetUserPassword,
                onUserDelete: _deleteUser,
              )),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab(bool isMobile, bool isTablet) {
    return Obx(() => UserStatisticsDetailWidget(
          statistics: _statistics.value,
          isLoading: _isLoadingStats.value,
          isMobile: isMobile,
        ));
  }

  Widget _buildHistoryTab(bool isMobile, bool isTablet) {
    return Obx(() => UserActionsWidget(
          actions: _recentActions,
          isLoading: _isLoading.value,
          isMobile: isMobile,
        ));
  }

  Widget _buildOnlineUsersTab(bool isMobile, bool isTablet) {
    return Obx(() {
      final onlineUsers = _users.where((user) => user.isOnline).toList();
      return UserOnlineWidget(
        onlineUsers: onlineUsers,
        isLoading: _isLoading.value,
        isMobile: isMobile,
      );
    });
  }

  // Actions des utilisateurs
  void _showCreateUserModal() {
    Get.dialog(
      CreateUserModal(
        availableRoles: _userService.availableRoles,
        availableSites: _userService.availableSites,
        onUserCreated: () {
          _refreshData();
          Get.back();
        },
      ),
      barrierDismissible: false,
    );
  }

  void _showUserDetails(AppUser user) {
    Get.dialog(
      UserDetailsModal(
        user: user,
        onUserUpdated: _refreshData,
      ),
    );
  }

  void _showEditUserModal(AppUser user) {
    Get.dialog(
      EditUserModal(
        user: user,
        availableRoles: _userService.availableRoles,
        availableSites: _userService.availableSites,
        onUserUpdated: () {
          _refreshData();
          Get.back();
        },
      ),
      barrierDismissible: false,
    );
  }

  void _toggleUserStatus(AppUser user) {
    Get.dialog(
      AlertDialog(
        title: Text(
            user.isActive ? 'Désactiver utilisateur' : 'Activer utilisateur'),
        content: Text(user.isActive
            ? 'Êtes-vous sûr de vouloir désactiver ${user.nomComplet} ?'
            : 'Êtes-vous sûr de vouloir activer ${user.nomComplet} ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final success =
                  await _userService.toggleUserStatus(user.id, !user.isActive);
              if (success) {
                Get.snackbar(
                  'Succès',
                  'Statut de l\'utilisateur mis à jour',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
                _refreshData();
              } else {
                Get.snackbar(
                  'Erreur',
                  'Impossible de mettre à jour le statut',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isActive ? Colors.orange : Colors.green,
            ),
            child: Text(user.isActive ? 'Désactiver' : 'Activer'),
          ),
        ],
      ),
    );
  }

  void _showChangeRoleModal(AppUser user) {
    Get.dialog(
      ChangeRoleModal(
        user: user,
        availableRoles: _userService.availableRoles,
        onRoleChanged: () {
          _refreshData();
          Get.back();
        },
      ),
    );
  }

  void _showChangeSiteModal(AppUser user) {
    Get.dialog(
      ChangeSiteModal(
        user: user,
        availableSites: _userService.availableSites,
        onSiteChanged: () {
          _refreshData();
          Get.back();
        },
      ),
    );
  }

  void _resetUserPassword(AppUser user) {
    Get.dialog(
      AlertDialog(
        title: const Text('Réinitialiser mot de passe'),
        content: Text('Envoyer un email de réinitialisation à ${user.email} ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final success = await _userService.resetUserPassword(user.email);
              if (success) {
                Get.snackbar(
                  'Succès',
                  'Email de réinitialisation envoyé',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } else {
                Get.snackbar(
                  'Erreur',
                  'Impossible d\'envoyer l\'email',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  void _deleteUser(AppUser user) {
    Get.dialog(
      AlertDialog(
        title: const Text('Supprimer utilisateur'),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer ${user.nomComplet} ?\n\n'
            'Cette action désactivera le compte mais conservera les données.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final success = await _userService.deleteUser(user.id);
              if (success) {
                Get.snackbar(
                  'Succès',
                  'Utilisateur supprimé',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
                _refreshData();
              } else {
                Get.snackbar(
                  'Erreur',
                  'Impossible de supprimer l\'utilisateur',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _exportUsers() async {
    try {
      final data = await _userService.exportUsers();
      // Ici vous pourriez implémenter l'export vers CSV ou Excel
      Get.snackbar(
        'Export',
        'Données exportées (${data.length} utilisateurs)',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'exporter les données',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
