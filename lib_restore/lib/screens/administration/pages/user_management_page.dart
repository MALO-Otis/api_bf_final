import 'dart:math' as math;
import 'package:get/get.dart';
import 'user_actions_page.dart';
import 'package:flutter/material.dart';
import '../../../utils/smart_appbar.dart';
import '../widgets/user_list_widgets.dart';
import '../widgets/user_filters_widgets.dart';
import '../widgets/user_actions_widgets.dart';
import '../models/user_management_models.dart';
import '../widgets/user_statistics_widgets.dart';
import '../services/user_management_service.dart';
import 'package:apisavana_gestion/authentication/sign_up.dart';

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
  final RxBool _isLoading = false.obs; // Commencer en mode normal
  final RxBool _isLoadingStats = false.obs; // Commencer en mode normal
  final RxBool _hasInitialized =
      false.obs; // Flag pour savoir si on a initialisé
  final RxBool _isRefreshing = false.obs; // Flag pour le refresh
  final RxSet<String> _roleUpdatesInProgress = <String>{}.obs;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Initialiser avec un petit délai pour éviter l'affichage d'erreur rouge
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Éviter les loaders multiples simultanés (sauf pour refresh)
    if (_isLoading.value && !_isRefreshing.value) return;

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
      // Seulement afficher l'erreur si on a déjà initialisé
      if (_hasInitialized.value) {
        Get.snackbar(
          'Erreur',
          'Impossible de charger les données: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } else {
        // Log silencieux pour la première fois
        debugPrint('Erreur de chargement initial: $e');
      }
    } finally {
      _isLoading.value = false;
      _isLoadingStats.value = false;
      _isRefreshing.value = false;
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
    try {
      _isRefreshing.value = true;
      print('🔄 Début du rafraîchissement...');
      await _loadData();
      print('✅ Rafraîchissement terminé');
    } catch (e) {
      print('❌ Erreur lors du rafraîchissement: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de rafraîchir les données: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isRefreshing.value = false;
    }
  }

  Future<void> _handleAddRole(AppUser user, String role) async {
    if (role.isEmpty) return;
    _roleUpdatesInProgress.add(user.id);
    _roleUpdatesInProgress.refresh();
    try {
      final success = await _userService.addRoleToUser(user.id, role);
      if (success) {
        final updatedRoles = List<String>.from(user.roles)..add(role);
        _updateUserRolesLocally(user.id, updatedRoles);
        final stats = await _userService.getUserStatistics();
        _statistics.value = stats;
        Get.snackbar(
          'Rôle ajouté',
          '$role a été ajouté à ${user.nomComplet}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green[600],
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Ajout impossible',
          'Le rôle n\'a pas pu être ajouté. Réessayez.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange[600],
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'ajouter le rôle: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[600],
        colorText: Colors.white,
      );
    } finally {
      _roleUpdatesInProgress.remove(user.id);
      _roleUpdatesInProgress.refresh();
    }
  }

  Future<void> _handleRemoveRole(AppUser user, String role) async {
    if (role.isEmpty) return;
    _roleUpdatesInProgress.add(user.id);
    _roleUpdatesInProgress.refresh();
    try {
      final success = await _userService.removeRoleFromUser(user.id, role);
      if (success) {
        final updatedRoles = List<String>.from(user.roles)..remove(role);
        _updateUserRolesLocally(user.id, updatedRoles);
        final stats = await _userService.getUserStatistics();
        _statistics.value = stats;
        Get.snackbar(
          'Rôle retiré',
          '$role a été retiré de ${user.nomComplet}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blueGrey[700],
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Retrait impossible',
          'Le rôle n\'a pas pu être retiré. Réessayez.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange[600],
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de retirer le rôle: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[600],
        colorText: Colors.white,
      );
    } finally {
      _roleUpdatesInProgress.remove(user.id);
      _roleUpdatesInProgress.refresh();
    }
  }

  void _updateUserRolesLocally(String userId, List<String> newRoles) {
    final index = _users.indexWhere((user) => user.id == userId);
    if (index == -1) return;
    _users[index] = _users[index].copyWith(roles: newRoles);
    _users.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Obx(() => Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: SmartAppBar(
            title: "Gestion des Utilisateurs",
            onBackPressed: () => Get.back(),
            actions: [
              IconButton(
                icon: (_isLoading.value || _isRefreshing.value)
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.refresh),
                onPressed: (_isLoading.value || _isRefreshing.value)
                    ? null
                    : _refreshData,
                tooltip: 'Actualiser',
              ),
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: _exportUsers,
                tooltip: 'Exporter',
              ),
              IconButton(
                icon: const Icon(Icons.bug_report),
                onPressed: _testDatabaseConnection,
                tooltip: 'Tester la base de données',
              ),
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
          body: RefreshIndicator(
            onRefresh: _refreshData,
            color: const Color(0xFF2196F3),
            child: NestedScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  // Statistiques fixes en haut
                  SliverToBoxAdapter(
                    child: Obx(() => _hasInitialized.value
                        ? UserStatisticsWidget(
                            userService: _userService,
                            isMobile: isMobile,
                          )
                        : Container(
                            height: 150,
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF2196F3)),
                              ),
                            ),
                          )),
                  ),
                  // Onglets fixes
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        indicatorColor: const Color(0xFF2196F3),
                        labelColor: const Color(0xFF2196F3),
                        unselectedLabelColor: Colors.grey[600],
                        isScrollable: isMobile,
                        tabs: [
                          Tab(
                            icon: const Icon(Icons.people, size: 20),
                            text: isMobile ? 'Users' : 'Utilisateurs',
                          ),
                          Tab(
                            icon: const Icon(Icons.security, size: 20),
                            text: isMobile ? 'Rôles' : 'Gestion des rôles',
                          ),
                          Tab(
                            icon: const Icon(Icons.analytics, size: 20),
                            text: isMobile ? 'Stats' : 'Statistiques',
                          ),
                          Tab(
                            icon: const Icon(Icons.history, size: 20),
                            text: isMobile ? 'Hist.' : 'Historique',
                          ),
                          Tab(
                            icon: const Icon(Icons.online_prediction, size: 20),
                            text: isMobile ? 'Live' : 'En ligne',
                          ),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // Onglet Utilisateurs
                  _buildUsersTab(isMobile, isTablet),

                  // Onglet Gestion des rôles
                  _buildRolesTab(isMobile, isTablet),

                  // Onglet Statistiques
                  _buildStatisticsTab(isMobile, isTablet),

                  // Onglet Historique
                  _buildHistoryTab(isMobile, isTablet),

                  // Onglet Utilisateurs en ligne
                  _buildOnlineUsersTab(isMobile, isTablet),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildUsersTab(bool isMobile, bool isTablet) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Filtres
        SliverToBoxAdapter(
          child: UserFiltersWidget(
            filters: _filters.value,
            onFiltersChanged: _applyFilters,
            availableRoles: _userService.availableRoles,
            availableSites: _userService.availableSites,
            isMobile: isMobile,
          ),
        ),

        // Liste des utilisateurs
        SliverToBoxAdapter(
          child: Obx(() => _hasInitialized.value
              ? Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  child: UserListWidget(
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
                    onResendVerificationEmail: _resendVerificationEmail,
                    onToggleAccess: _toggleUserAccess,
                  ),
                )
              : Container(
                  height: 400,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                    ),
                  ),
                )),
        ),

        // Espace supplémentaire pour éviter le blocage en bas
        const SliverPadding(
          padding: EdgeInsets.only(bottom: 100),
        ),
      ],
    );
  }

  Widget _buildRolesTab(bool isMobile, bool isTablet) {
    return Obx(() {
      if (!_hasInitialized.value) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
          ),
        );
      }

      final users = _users.toList();
      if (_isLoading.value && users.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
          ),
        );
      }

      if (users.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'Aucun utilisateur disponible',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Créez un utilisateur ou modifiez vos filtres.',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 1,
              color: Colors.blueGrey[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF0D47A1)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gestion centralisée des rôles',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Consultez les rôles attribués à chaque utilisateur, ajoutez-les en un clic et retirez les accès obsolètes.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blueGrey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _isRefreshing.value ? null : _refreshData,
                      icon: _isRefreshing.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: const Text('Actualiser'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _buildRolesContent(users, isMobile),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRolesContent(List<AppUser> users, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactLayout = isMobile || constraints.maxWidth < 900;

        if (isCompactLayout) {
          return Scrollbar(
            radius: const Radius.circular(12),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final user = users[index];
                final isUpdating = _roleUpdatesInProgress.contains(user.id);
                final availableForUser = _userService.availableRoles
                    .where((role) => !user.roles.contains(role))
                    .toList();

                return _buildRoleManagementCard(
                  user: user,
                  availableRoles: availableForUser,
                  isUpdating: isUpdating,
                );
              },
            ),
          );
        }

        return Scrollbar(
          radius: const Radius.circular(12),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Scrollbar(
              radius: const Radius.circular(12),
              notificationPredicate: (notification) => notification.depth == 1,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: math.max(constraints.maxWidth, 960),
                  ),
                  child: DataTable(
                    columnSpacing: 32,
                    headingRowColor:
                        MaterialStateProperty.all(const Color(0xFFE3F2FD)),
                    dataRowMinHeight: 72,
                    dataRowMaxHeight: 220,
                    columns: const [
                      DataColumn(label: Text('Utilisateur')),
                      DataColumn(label: Text('Site')),
                      DataColumn(label: Text('Rôles assignés')),
                      DataColumn(label: Text('Ajouter un rôle')),
                    ],
                    rows: users.map((user) {
                      final isUpdating =
                          _roleUpdatesInProgress.contains(user.id);
                      final availableForUser = _userService.availableRoles
                          .where((role) => !user.roles.contains(role))
                          .toList();
                      return DataRow(
                        cells: [
                          DataCell(SizedBox(
                            width: 260,
                            child: _buildRoleUserCell(user),
                          )),
                          DataCell(_buildSiteBadge(user.site)),
                          DataCell(SizedBox(
                            width: 320,
                            child: _buildAssignedRolesCell(user, isUpdating),
                          )),
                          DataCell(SizedBox(
                            width: 320,
                            child: _buildAvailableRolesCell(
                              user,
                              availableForUser,
                              isUpdating,
                            ),
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleManagementCard({
    required AppUser user,
    required List<String> availableRoles,
    required bool isUpdating,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserAvatar(user),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              user.nomComplet,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildSiteBadge(user.site),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user.email,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      if (user.telephone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.telephone,
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Rôles assignés',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey[800],
              ),
            ),
            const SizedBox(height: 8),
            _buildAssignedRolesCell(user, isUpdating),
            const SizedBox(height: 20),
            Text(
              'Ajouter un rôle',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey[800],
              ),
            ),
            const SizedBox(height: 8),
            _buildAvailableRolesCell(user, availableRoles, isUpdating),
            if (isUpdating) ...[
              const SizedBox(height: 16),
              Row(
                children: const [
                  Icon(Icons.sync, size: 18, color: Color(0xFF2196F3)),
                  SizedBox(width: 12),
                  Text(
                    'Mise à jour des rôles en cours...',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(AppUser user) {
    final initials = user.initiales.isNotEmpty ? user.initiales : '?';
    return CircleAvatar(
      radius: 28,
      backgroundColor: const Color(0xFF2196F3).withOpacity(0.12),
      foregroundColor: const Color(0xFF0D47A1),
      child: Text(
        initials,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  Widget _buildSiteBadge(String site) {
    if (site.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Site non défini',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF64B5F6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, size: 14, color: Color(0xFF1976D2)),
          const SizedBox(width: 6),
          Text(
            site,
            style: const TextStyle(
              color: Color(0xFF0D47A1),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleUserCell(AppUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.nomComplet,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        if (user.telephone.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            user.telephone,
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        ],
      ],
    );
  }

  Widget _buildAssignedRolesCell(AppUser user, bool isUpdating) {
    if (user.roles.isEmpty) {
      return Text(
        'Aucun rôle',
        style:
            TextStyle(color: Colors.orange[700], fontStyle: FontStyle.italic),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...user.roles.map((role) => InputChip(
              label: Text(role),
              avatar: user.primaryRole == role
                  ? const Icon(Icons.star, size: 16, color: Colors.amber)
                  : null,
              onDeleted: isUpdating
                  ? null
                  : () {
                      _handleRemoveRole(user, role);
                    },
              deleteIconColor: Colors.redAccent,
            )),
        if (isUpdating)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  Widget _buildAvailableRolesCell(
    AppUser user,
    List<String> availableRoles,
    bool isUpdating,
  ) {
    if (availableRoles.isEmpty) {
      return Text(
        'Tous les rôles sont déjà assignés',
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableRoles
          .map(
            (role) => ActionChip(
              label: Text(role),
              avatar: const Icon(Icons.add, size: 16, color: Colors.white),
              backgroundColor: const Color(0xFF2196F3),
              labelStyle: const TextStyle(color: Colors.white),
              onPressed: isUpdating ? null : () => _handleAddRole(user, role),
            ),
          )
          .toList(),
    );
  }

  Widget _buildStatisticsTab(bool isMobile, bool isTablet) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Obx(() => _hasInitialized.value
          ? UserStatisticsWidget(
              userService: _userService,
              isMobile: isMobile,
            )
          : const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
              ),
            )),
    );
  }

  Widget _buildHistoryTab(bool isMobile, bool isTablet) {
    return Obx(() => _hasInitialized.value
        ? UserActionsPage(service: _userService, isMobile: isMobile)
        : Center(
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
            ),
          ));
  }

  Widget _buildOnlineUsersTab(bool isMobile, bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône de maintenance
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange[200]!, width: 2),
              ),
              child: Icon(
                Icons.construction,
                size: 64,
                color: Colors.orange[600],
              ),
            ),

            const SizedBox(height: 24),

            // Titre
            Text(
              'Fonctionnalité en maintenance',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Message
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange[700],
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Fonctionnalité à implémenter en maintenance !!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cette fonctionnalité sera bientôt disponible.\nMerci de votre patience.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Badge de statut
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.orange[700],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'En cours de développement',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Actions des utilisateurs
  Future<void> _showCreateUserModal() async {
    await Get.to(() => const SignupPage());
    await _refreshData();
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
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            const Text('⚠️ SUPPRESSION DÉFINITIVE'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vous êtes sur le point de SUPPRIMER DÉFINITIVEMENT l\'utilisateur :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('👤 ${user.nomComplet}',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('📧 ${user.email}'),
                  Text('🏢 ${user.site}'),
                  Text('👔 ${user.role}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🚨 ATTENTION - Cette action va :',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red[700]),
                  ),
                  const SizedBox(height: 4),
                  Text('• Supprimer le compte de Firebase Auth',
                      style: TextStyle(color: Colors.red[600])),
                  Text('• Supprimer toutes les données Firestore',
                      style: TextStyle(color: Colors.red[600])),
                  Text('• Nettoyer les données associées',
                      style: TextStyle(color: Colors.red[600])),
                  const SizedBox(height: 8),
                  Text(
                    '⚠️ CETTE ACTION EST IRRÉVERSIBLE !',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red[800]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => _showFinalConfirmationDialog(user),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Continuer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFinalConfirmationDialog(AppUser user) {
    Get.back(); // Fermer le premier dialog
    final TextEditingController confirmController = TextEditingController();
    final RxBool isValid = false.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('🔒 Confirmation finale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Pour confirmer la suppression de ${user.nomComplet}, tapez exactement :'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'SUPPRIMER',
                style: TextStyle(
                    fontFamily: 'monospace', fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                labelText: 'Tapez "SUPPRIMER"',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                isValid.value = value == 'SUPPRIMER';
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          Obx(() => ElevatedButton(
                onPressed: isValid.value
                    ? () async {
                        Get.back();
                        await _executeUserDeletion(user);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isValid.value ? Colors.red : Colors.grey,
                ),
                child: const Text('SUPPRIMER DÉFINITIVEMENT',
                    style: TextStyle(color: Colors.white)),
              )),
        ],
      ),
    );
  }

  Future<void> _executeUserDeletion(AppUser user) async {
    // Afficher un loading
    Get.dialog(
      const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Suppression en cours...'),
            Text('Cette opération peut prendre quelques secondes.'),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final success = await _userService.deleteUser(user.id);
      Get.back(); // Fermer le loading

      if (success) {
        Get.snackbar(
          '✅ Suppression Firestore réussie',
          'L\'utilisateur ${user.nomComplet} a été supprimé de Firestore.\n⚠️ Peut rester dans Firebase Auth (nécessite Firebase Function).',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 8),
        );
        _refreshData();
      } else {
        Get.snackbar(
          '❌ Échec de suppression',
          'Impossible de supprimer l\'utilisateur. Vérifiez la console pour les détails.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      Get.back(); // Fermer le loading
      Get.snackbar(
        '❌ Erreur',
        'Exception lors de la suppression: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  // Supprimé: Vérification manuelle d'email (non souhaitée dans les actions)

  void _resendVerificationEmail(AppUser user) {
    Get.dialog(
      AlertDialog(
        title: const Text('Renvoyer email de vérification'),
        content: Text('Renvoyer l\'email de vérification à ${user.email} ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final success =
                  await _userService.resendVerificationEmail(user.id);
              if (success) {
                Get.snackbar(
                  'Succès',
                  'Email de vérification renvoyé',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.blue,
                  colorText: Colors.white,
                );
              } else {
                Get.snackbar(
                  'Erreur',
                  'Impossible de renvoyer l\'email',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Renvoyer'),
          ),
        ],
      ),
    );
  }

  // (supprimé) _generateTemporaryPassword: l'action et le flux ne sont plus exposés dans l'UI.

  void _toggleUserAccess(AppUser user) {
    final hasAccess = user.metadata?['hasAccess'] ?? true;
    Get.dialog(
      AlertDialog(
        title: Text(hasAccess ? 'Révoquer l\'accès' : 'Accorder l\'accès'),
        content: Text(
          hasAccess
              ? 'Révoquer l\'accès à la plateforme pour ${user.nomComplet} ?\n\nL\'utilisateur ne pourra plus se connecter.'
              : 'Accorder l\'accès à la plateforme pour ${user.nomComplet} ?\n\nL\'utilisateur pourra se connecter normalement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final success =
                  await _userService.toggleUserAccess(user.id, !hasAccess);
              if (success) {
                Get.snackbar(
                  'Succès',
                  hasAccess ? 'Accès révoqué' : 'Accès accordé',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: hasAccess ? Colors.orange : Colors.green,
                  colorText: Colors.white,
                );
                _refreshData();
              } else {
                Get.snackbar(
                  'Erreur',
                  'Impossible de modifier l\'accès',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: hasAccess ? Colors.orange : Colors.green,
            ),
            child: Text(hasAccess ? 'Révoquer' : 'Accorder'),
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

  void _testDatabaseConnection() async {
    Get.dialog(
      AlertDialog(
        title: const Text('🧪 Tests de la Base de Données'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choisissez le type de test à effectuer :'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.wifi, color: Colors.blue),
              title: const Text('Test de Connectivité'),
              subtitle: const Text('Vérifier la connexion Firestore'),
              onTap: () {
                Get.back();
                _runConnectivityTest();
              },
            ),
            if (_users.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.person, color: Colors.orange),
                title: const Text('Test d\'Action Utilisateur'),
                subtitle: const Text('Tester une action sur un utilisateur'),
                onTap: () {
                  Get.back();
                  _showUserActionTestDialog();
                },
              ),
            ListTile(
              leading: const Icon(Icons.security, color: Colors.red),
              title: const Text('Test des Permissions'),
              subtitle: const Text('Vérifier les permissions Firestore'),
              onTap: () {
                Get.back();
                _runPermissionsTest();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _runConnectivityTest() async {
    Get.snackbar(
      'Test en cours',
      'Vérification de la connectivité...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );

    try {
      final success = await _userService.testDatabaseConnection();
      if (success) {
        Get.snackbar(
          'Test réussi ✅',
          'Base de données connectée et fonctionnelle',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Test échoué ❌',
          'Problème de connectivité détecté - Vérifiez la console',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur de test ❌',
        'Exception: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  void _runPermissionsTest() async {
    if (_users.isEmpty) {
      Get.snackbar(
        'Aucun utilisateur',
        'Pas d\'utilisateur disponible pour le test',
        // Supprimé: génération de mot de passe temporaire

        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final testUser = _users.first;
    try {
      final success = await _userService.checkFirestorePermissions(testUser.id);
      if (success) {
        Get.snackbar(
          'Permissions OK ✅',
          'Lecture et écriture fonctionnelles',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Permissions limitées ❌',
          'Problème d\'accès détecté',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur permissions ❌',
        'Exception: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showUserActionTestDialog() {
    if (_users.isEmpty) {
      Get.snackbar(
        'Aucun utilisateur',
        'Pas d\'utilisateur disponible pour le test',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Tests d\'Action Utilisateur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Actions de test désactivées pour cette version.'),
            const SizedBox(height: 12),
            const Text(
                'Utilisez les actions réelles dans la liste des utilisateurs.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  // Supprimé: Génération de mot de passe temporaire (non souhaitée dans les actions)
}

/// Classe déléguée pour créer un header persistant des onglets
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;
  // Ajout de 1px pour compenser la bordure inférieure et éviter l'overflow
  static const double _borderThickness = 1.0;

  @override
  double get minExtent => _tabBar.preferredSize.height + _borderThickness;

  @override
  double get maxExtent => _tabBar.preferredSize.height + _borderThickness;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: _tabBar,
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
