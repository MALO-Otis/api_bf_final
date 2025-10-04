import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:apisavana_gestion/models/user_notification.dart';
import 'package:apisavana_gestion/authentication/user_session.dart';
import 'package:apisavana_gestion/services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with TickerProviderStateMixin {
  late final List<_NotificationTabConfig> _tabConfigs;
  late TabController _tabController;
  String selectedFilter = 'Toutes';
  late final UserSession _session;
  late final NotificationService _notificationService;
  Stream<List<UserNotification>>? _notificationsStream;

  @override
  void initState() {
    super.initState();
    _session = Get.find<UserSession>();
    _notificationService = Get.isRegistered<NotificationService>()
        ? Get.find<NotificationService>()
        : Get.put(NotificationService());

    _tabConfigs = [
      _NotificationTabConfig(
        label: 'Toutes',
        icon: Icons.inbox_outlined,
        predicate: (_) => true,
      ),
      _NotificationTabConfig(
        label: 'Compte',
        icon: Icons.person_outline,
        predicate: _isAccountNotification,
      ),
      _NotificationTabConfig(
        label: 'Sécurité',
        icon: Icons.security,
        predicate: _isSecurityNotification,
      ),
      _NotificationTabConfig(
        label: 'Système',
        icon: Icons.settings_outlined,
        predicate: _isSystemNotification,
      ),
    ];

    _tabController = TabController(length: _tabConfigs.length, vsync: this);

    final uid = _session.uid;
    if (uid != null && uid.isNotEmpty) {
      _notificationsStream = _notificationService.streamForUser(uid);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_notificationsStream == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        body: SafeArea(child: _buildNoUserPlaceholder()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: StreamBuilder<List<UserNotification>>(
          stream: _notificationsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return _buildLoadingState();
            }
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error);
            }

            final notifications = _sortedNotifications(snapshot.data ?? []);
            final unreadCount = notifications.where((n) => !n.isRead).length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPageHeader(unreadCount, notifications.length),
                _buildQuickFilters(notifications),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _buildTabBar(),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: _tabConfigs.map((config) {
                      final segmentNotifications = notifications
                          .where(config.predicate)
                          .toList(growable: false);
                      final filtered = _applyQuickFilter(segmentNotifications);
                      final emptyCopy = _emptyMessagesForTab(config.label);
                      return _buildNotificationsList(
                        filtered,
                        storageKey: PageStorageKey<String>(
                          'notifications-${config.label}',
                        ),
                        emptyStateCopy: emptyCopy,
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPageHeader(int unreadCount, int totalCount) {
    const accent = Color(0xFFF49101);
    final headline = unreadCount > 0
        ? '$unreadCount notification${unreadCount > 1 ? 's' : ''} non lue${unreadCount > 1 ? 's' : ''}'
        : 'Toutes vos notifications sont lues';
    final subline = totalCount > 0
        ? '$totalCount notification${totalCount > 1 ? 's' : ''} reçue${totalCount > 1 ? 's' : ''} au total'
        : 'Aucune notification pour le moment';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Centre de notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D0C0D),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    headline,
                    style: TextStyle(
                      color: unreadCount > 0 ? accent : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subline,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (unreadCount > 0)
                  ElevatedButton.icon(
                    onPressed: _markAllAsRead,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text(
                      'Tout marquer lu',
                      style: TextStyle(fontSize: 13),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.verified_outlined,
                          color: Colors.green,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'À jour',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                IconButton(
                  onPressed: _showNotificationSettings,
                  tooltip: 'Paramètres des notifications',
                  icon: const Icon(
                    Icons.tune,
                    color: Color(0xFF2D0C0D),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilters(List<UserNotification> notifications) {
    final now = DateTime.now();
    final filters = [
      _QuickFilterConfig(
        label: 'Toutes',
        icon: Icons.inbox_outlined,
        accentColor: const Color(0xFF2D0C0D),
        count: notifications.length,
      ),
      _QuickFilterConfig(
        label: 'Non lues',
        icon: Icons.mark_email_unread_outlined,
        accentColor: const Color(0xFFF49101),
        count: notifications.where((n) => !n.isRead).length,
      ),
      _QuickFilterConfig(
        label: 'Urgentes',
        icon: Icons.priority_high_rounded,
        accentColor: Colors.redAccent,
        count: notifications.where(_isHighPriority).length,
      ),
      _QuickFilterConfig(
        label: 'Aujourd\'hui',
        icon: Icons.today_outlined,
        accentColor: Colors.blueAccent,
        count: notifications
            .where(
              (n) =>
                  n.createdAt.year == now.year &&
                  n.createdAt.month == now.month &&
                  n.createdAt.day == now.day,
            )
            .length,
      ),
    ];

    return SizedBox(
      height: 62,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter.label;
          final label = filter.count != null
              ? '${filter.label} (${filter.count})'
              : filter.label;

          return ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  filter.icon,
                  size: 16,
                  color: isSelected ? filter.accentColor : Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(label),
              ],
            ),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            backgroundColor: Colors.white,
            selectedColor: filter.accentColor.withValues(alpha: 0.16),
            side: BorderSide(
              color: isSelected ? filter.accentColor : Colors.grey.shade300,
            ),
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? filter.accentColor : Colors.grey[700],
            ),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                selectedFilter = filter.label;
              });
            },
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: filters.length,
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          color: const Color(0x1AF49101),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        labelColor: const Color(0xFFF49101),
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
        tabs: _tabConfigs
            .map(
              (config) => Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(config.icon, size: 18),
                    const SizedBox(width: 6),
                    Text(config.label),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Impossible de charger les notifications',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D0C0D),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF49101),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D0C0D),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  (String, String) _emptyMessagesForTab(String label) {
    switch (label) {
      case 'Compte':
        return (
          'Aucune activité liée aux comptes.',
          'Les créations, suppressions et modifications de compte s\'afficheront ici.'
        );
      case 'Sécurité':
        return (
          'Vous êtes à jour sur la sécurité.',
          'Les alertes de connexion, réinitialisations de mot de passe et autres incidents seront affichés ici.'
        );
      case 'Système':
        return (
          'Pas de mises à jour système.',
          'Les messages de maintenance et d\'évolution techniques apparaîtront dans cet onglet.'
        );
      default:
        return (
          'Vous êtes à jour !',
          'Lorsque vous recevrez une nouvelle notification, elle apparaîtra immédiatement dans cette liste.'
        );
    }
  }

  String _channelLabel(String channel) {
    switch (channel.toLowerCase()) {
      case 'in-app':
      case 'in_app':
        return 'In-app';
      case 'email':
        return 'Email';
      case 'sms':
        return 'SMS';
      case 'push':
        return 'Push';
      default:
        return channel;
    }
  }

  List<UserNotification> _sortedNotifications(
      List<UserNotification> notifications) {
    final sorted = List<UserNotification>.from(notifications);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  List<UserNotification> _applyQuickFilter(
      List<UserNotification> notifications) {
    switch (selectedFilter) {
      case 'Toutes':
        return notifications;
      case 'Non lues':
        return notifications.where((n) => !n.isRead).toList();
      case 'Urgentes':
        return notifications.where(_isHighPriority).toList();
      case 'Aujourd\'hui':
        final now = DateTime.now();
        return notifications
            .where((n) =>
                n.createdAt.year == now.year &&
                n.createdAt.month == now.month &&
                n.createdAt.day == now.day)
            .toList();
      default:
        return notifications;
    }
  }

  bool _isHighPriority(UserNotification notification) {
    final value = notification.priority.toLowerCase();
    return value == 'high' || value == 'urgent' || value == 'critical';
  }

  bool _isAccountNotification(UserNotification notification) {
    const accountTypes = {'account', 'role', 'site', 'profile'};
    return accountTypes.contains(notification.type);
  }

  bool _isSecurityNotification(UserNotification notification) {
    const securityTypes = {'security', 'password', 'access', 'auth'};
    return securityTypes.contains(notification.type);
  }

  bool _isSystemNotification(UserNotification notification) {
    const systemTypes = {'system', 'maintenance', 'update', 'log', 'alert'};
    if (systemTypes.contains(notification.type)) {
      return true;
    }
    return !_isAccountNotification(notification) &&
        !_isSecurityNotification(notification);
  }

  String _sectionLabelFor(UserNotification notification) {
    switch (notification.type) {
      case 'account':
        return 'Compte';
      case 'role':
        return 'Rôle';
      case 'site':
        return 'Site';
      case 'security':
      case 'password':
        return 'Sécurité';
      case 'access':
        return 'Accès';
      case 'system':
        return 'Système';
      case 'maintenance':
        return 'Maintenance';
      case 'update':
        return 'Mise à jour';
      default:
        return 'Notification';
    }
  }

  Widget _buildNotificationsList(
    List<UserNotification> notifications, {
    Key? storageKey,
    required (String title, String subtitle) emptyStateCopy,
  }) {
    if (notifications.isEmpty) {
      return ListView(
        key: storageKey,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 60),
        children: [
          _buildEmptyState(emptyStateCopy.$1, emptyStateCopy.$2),
        ],
      );
    }

    return ListView.separated(
      key: storageKey,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        final (icon, color) = _iconAndColorFor(notification);
        final isUnread = !notification.isRead;
        final categoryLabel = _sectionLabelFor(notification);
        final priorityLabel = _priorityLabel(notification);
        final createdByDisplay = (notification.createdByName ??
                notification.createdByEmail ??
                notification.createdBy)
            ?.trim();
        final metadataSummary = _metadataSummary(notification);

        final chipWidgets = <Widget>[];
        if (categoryLabel.isNotEmpty) {
          chipWidgets.add(
            _buildTagChip(
              categoryLabel,
              backgroundColor: Colors.grey.shade200,
              textColor: Colors.grey.shade800,
              icon: Icons.label_outline,
            ),
          );
        }
        if (priorityLabel != null) {
          final (bgColor, textColor, priorityIcon) =
              _priorityStyles(notification.priority);
          chipWidgets.add(
            _buildTagChip(
              priorityLabel,
              backgroundColor: bgColor,
              textColor: textColor,
              icon: priorityIcon,
            ),
          );
        }
        if (createdByDisplay != null && createdByDisplay.isNotEmpty) {
          chipWidgets.add(
            _buildTagChip(
              'Par $createdByDisplay',
              backgroundColor: Colors.blueGrey.shade50,
              textColor: Colors.blueGrey.shade700,
              icon: Icons.admin_panel_settings,
            ),
          );
        }
        if (notification.channels.isNotEmpty) {
          chipWidgets.addAll(
            notification.channels.map(
              (channel) => _buildTagChip(
                _channelLabel(channel),
                backgroundColor: Colors.grey.shade100,
                textColor: Colors.grey.shade700,
                icon: Icons.send_outlined,
              ),
            ),
          );
        }

        return Card(
          elevation: isUnread ? 4 : 1,
          shadowColor: isUnread
              ? const Color(0xFFF49101).withValues(alpha: 0.25)
              : Colors.black12,
          color: isUnread ? const Color(0xFFFFF6E8) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: isUnread
                  ? const Color(0xFFF49101).withValues(alpha: 0.25)
                  : Colors.transparent,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _markAsRead(notification),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title.isNotEmpty
                                        ? notification.title
                                        : (categoryLabel.isNotEmpty
                                            ? categoryLabel
                                            : 'Notification'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      height: 1.2,
                                      fontWeight: isUnread
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: const Color(0xFF2D0C0D),
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    await _handleNotificationAction(
                                      value,
                                      notification,
                                    );
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'toggle_read',
                                      child: Text(
                                        notification.isRead
                                            ? 'Marquer comme non lue'
                                            : 'Marquer comme lue',
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Supprimer'),
                                    ),
                                  ],
                                  icon: const Icon(Icons.more_horiz),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(notification.createdAt),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (notification.message.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2D0C0D),
                      ),
                    ),
                  ],
                  if (metadataSummary != null &&
                      metadataSummary.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      metadataSummary,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (chipWidgets.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: chipWidgets,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _markAsRead(UserNotification notification) async {
    if (notification.isRead) return;
    try {
      await _notificationService.markAsRead(notification.id);
    } catch (e) {
      _showSnack('Impossible de marquer la notification comme lue: $e',
          isError: true);
    }
  }

  Future<void> _toggleReadStatus(UserNotification notification) async {
    try {
      if (notification.isRead) {
        await _notificationService.markAsUnread(notification.id);
        return;
      }
      await _notificationService.markAsRead(notification.id);
    } catch (e) {
      _showSnack('Action impossible: $e', isError: true);
    }
  }

  Future<void> _deleteNotification(UserNotification notification) async {
    try {
      await _notificationService.deleteNotification(notification.id);
      _showSnack('Notification supprimée',
          backgroundColor: Colors.orangeAccent);
    } catch (e) {
      _showSnack('Impossible de supprimer la notification: $e', isError: true);
    }
  }

  Future<void> _markAllAsRead() async {
    final uid = _session.uid;
    if (uid == null || uid.isEmpty) {
      return;
    }
    try {
      await _notificationService.markAllAsRead(uid);
      _showSnack('Toutes les notifications ont été marquées comme lues');
    } catch (e) {
      _showSnack(
          'Impossible de marquer toutes les notifications comme lues: $e',
          isError: true);
    }
  }

  Future<void> _handleNotificationAction(
      String action, UserNotification notification) async {
    switch (action) {
      case 'toggle_read':
        await _toggleReadStatus(notification);
        break;
      case 'delete':
        await _deleteNotification(notification);
        break;
    }
  }

  String? _priorityLabel(UserNotification notification) {
    final value = notification.priority.toLowerCase();
    switch (value) {
      case '':
      case 'normal':
        return null;
      case 'urgent':
      case 'high':
        return 'Urgent';
      case 'critical':
        return 'Critique';
      case 'medium':
        return 'Priorité moyenne';
      case 'low':
        return 'Priorité faible';
      default:
        return notification.priority;
    }
  }

  (Color, Color, IconData) _priorityStyles(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return (
          Colors.green.shade50,
          Colors.green.shade700,
          Icons.trending_down
        );
      case 'medium':
        return (Colors.orange.shade50, Colors.orange.shade700, Icons.flag);
      case 'critical':
        return (Colors.red.shade100, Colors.red.shade800, Icons.report);
      case 'urgent':
      case 'high':
      default:
        return (Colors.red.shade50, Colors.red.shade700, Icons.priority_high);
    }
  }

  String? _metadataSummary(UserNotification notification) {
    final metadata = notification.metadata;
    if (metadata.isEmpty) return null;

    final oldSite = metadata['oldSite']?.toString();
    final newSite = metadata['newSite']?.toString();
    if ((oldSite != null && oldSite.isNotEmpty) ||
        (newSite != null && newSite.isNotEmpty)) {
      final buffer = StringBuffer('Site: ');
      if (oldSite != null && oldSite.isNotEmpty) {
        buffer.write(oldSite);
        if (newSite != null && newSite.isNotEmpty) {
          buffer.write(' → ');
        }
      }
      if (newSite != null && newSite.isNotEmpty) {
        buffer.write(newSite);
      }
      return buffer.toString();
    }

    final oldRoles = _stringifyList(metadata['oldRole']);
    final newRoles = _stringifyList(metadata['newRole']);
    if (oldRoles.isNotEmpty || newRoles.isNotEmpty) {
      final oldPart = oldRoles.join(', ');
      final newPart = newRoles.join(', ');
      if (oldRoles.isNotEmpty && newRoles.isNotEmpty) {
        return 'Rôles: $oldPart → $newPart';
      }
      if (newRoles.isNotEmpty) {
        return 'Nouveaux rôles: $newPart';
      }
      return 'Ancien rôle: $oldPart';
    }

    final roles = _stringifyList(metadata['roles']);
    if (roles.isNotEmpty) {
      return 'Rôles: ${roles.join(', ')}';
    }

    final email = metadata['email']?.toString();
    if (email != null && email.isNotEmpty) {
      return 'Email: $email';
    }

    final targetName = metadata['targetUserName']?.toString();
    final targetEmail = metadata['targetUserEmail']?.toString();
    if ((targetName != null && targetName.isNotEmpty) ||
        (targetEmail != null && targetEmail.isNotEmpty)) {
      final buffer = StringBuffer('Utilisateur cible: ');
      if (targetName != null && targetName.isNotEmpty) {
        buffer.write(targetName);
        if (targetEmail != null && targetEmail.isNotEmpty) {
          buffer.write(' ($targetEmail)');
        }
      } else if (targetEmail != null && targetEmail.isNotEmpty) {
        buffer.write(targetEmail);
      }
      return buffer.toString();
    }

    final reason = metadata['reason']?.toString();
    if (reason != null && reason.isNotEmpty) {
      return 'Motif: $reason';
    }

    if (metadata.isNotEmpty) {
      const ignoredKeys = {
        'oldSite',
        'newSite',
        'oldRole',
        'newRole',
        'roles',
        'email',
        'targetUserName',
        'targetUserEmail',
        'reason',
      };
      final entries = metadata.entries
          .where((entry) => !ignoredKeys.contains(entry.key))
          .where((entry) =>
              entry.value != null && entry.value.toString().isNotEmpty)
          .take(2)
          .map((entry) => '${entry.key}: ${entry.value}')
          .toList();
      if (entries.isNotEmpty) {
        return entries.join(' • ');
      }
    }

    return null;
  }

  List<String> _stringifyList(dynamic value) {
    if (value is Iterable) {
      return value
          .map((item) => item == null ? '' : item.toString())
          .where((element) => element.isNotEmpty)
          .toList();
    }
    if (value is String && value.isNotEmpty) {
      return [value];
    }
    return const <String>[];
  }

  Widget _buildTagChip(
    String label, {
    required Color backgroundColor,
    required Color textColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _iconAndColorFor(UserNotification notification) {
    if (_isHighPriority(notification)) {
      return (Icons.warning_amber_rounded, Colors.redAccent);
    }

    switch (notification.type) {
      case 'security':
      case 'password':
        return (Icons.lock, Colors.deepPurple);
      case 'account':
        return (Icons.person, const Color(0xFF1976D2));
      case 'role':
        return (Icons.manage_accounts, Colors.teal);
      case 'site':
        return (Icons.place, Colors.deepOrange);
      case 'system':
      case 'maintenance':
      case 'update':
        return (Icons.settings, Colors.blueGrey);
      default:
        return (Icons.notifications, const Color(0xFFF49101));
    }
  }

  void _showSnack(String message,
      {Color backgroundColor = Colors.green, bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : backgroundColor,
      ),
    );
  }

  Widget _buildNoUserPlaceholder() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Text(
          'Aucun utilisateur connecté. Connectez-vous pour voir vos notifications.',
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            const Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.settings, color: Color(0xFFF49101)),
                  SizedBox(width: 12),
                  Text(
                    'Paramètres des notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D0C0D),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Settings
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSettingsTile(
                    'Notifications push',
                    'Recevoir des notifications sur votre appareil',
                    Icons.notifications,
                    true,
                  ),
                  _buildSettingsTile(
                    'Notifications par email',
                    'Recevoir les notifications importantes par email',
                    Icons.email,
                    false,
                  ),
                  _buildSettingsTile(
                    'Sons et vibrations',
                    'Activer les sons et vibrations',
                    Icons.volume_up,
                    true,
                  ),
                  _buildSettingsTile(
                    'Notifications de vente',
                    'Être notifié des nouvelles ventes',
                    Icons.shopping_cart,
                    true,
                  ),
                  _buildSettingsTile(
                    'Notifications de stock',
                    'Alertes de stock faible',
                    Icons.inventory,
                    true,
                  ),
                  _buildSettingsTile(
                    'Notifications système',
                    'Erreurs et maintenance',
                    Icons.settings,
                    false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
      String title, String subtitle, IconData icon, bool value) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFF49101)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: (newValue) {
          // TODO: gérer le changement de paramètre si nécessaire
        },
        activeColor: const Color(0xFFF49101),
      ),
    );
  }
}

class _NotificationTabConfig {
  const _NotificationTabConfig({
    required this.label,
    required this.icon,
    required this.predicate,
  });

  final String label;
  final IconData icon;
  final bool Function(UserNotification) predicate;
}

class _QuickFilterConfig {
  const _QuickFilterConfig({
    required this.label,
    required this.icon,
    required this.accentColor,
    this.count,
  });

  final String label;
  final IconData icon;
  final Color accentColor;
  final int? count;
}
