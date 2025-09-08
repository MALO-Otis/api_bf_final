import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String selectedFilter = 'Toutes';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Données fictives des notifications
  final List<Map<String, dynamic>> notifications = [
    {
      'id': '1',
      'type': 'success',
      'title': 'Nouvelle vente réalisée',
      'message': 'Vente #2024-157 pour 25kg miel toutes fleurs - Client: Épicerie Bio Nature',
      'amount': '412,500 FCFA',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 15)),
      'isRead': false,
      'priority': 'normal',
      'category': 'vente',
      'icon': Icons.shopping_cart,
      'color': Colors.green,
    },
    {
      'id': '2',
      'type': 'warning',
      'title': 'Stock faible détecté',
      'message': 'Miel acacia 500g - Il ne reste que 12 unités en stock',
      'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
      'isRead': false,
      'priority': 'high',
      'category': 'stock',
      'icon': Icons.inventory_2,
      'color': Colors.orange,
    },
    {
      'id': '3',
      'type': 'info',
      'title': 'Nouvelle collecte enregistrée',
      'message': 'Apiculteur Marie TRAORE: 38kg miel toutes fleurs collectés - Site: Koudougou',
      'amount': '190,000 FCFA',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'isRead': true,
      'priority': 'normal',
      'category': 'collecte',
      'icon': Icons.local_florist,
      'color': Colors.blue,
    },
    {
      'id': '4',
      'type': 'error',
      'title': 'Crédit en retard',
      'message': 'Client Boulangerie SANKARA: 2,850,000 FCFA depuis 52 jours - Action requise',
      'amount': '2,850,000 FCFA',
      'timestamp': DateTime.now().subtract(const Duration(hours: 3)),
      'isRead': false,
      'priority': 'urgent',
      'category': 'finance',
      'icon': Icons.credit_card,
      'color': Colors.red,
    },
    {
      'id': '5',
      'type': 'success',
      'title': 'Extraction terminée',
      'message': 'Lot EXT-2024-089: 45kg de miel extrait avec succès - Technicien: Ousmane KONE',
      'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
      'isRead': true,
      'priority': 'normal',
      'category': 'production',
      'icon': Icons.science,
      'color': Colors.green,
    },
    {
      'id': '6',
      'type': 'info',
      'title': 'Nouveau contrôle qualité',
      'message': 'Échantillon #CQ-2024-156 en attente de validation - Prélèvement site Bobo-Dioulasso',
      'timestamp': DateTime.now().subtract(const Duration(hours: 6)),
      'isRead': false,
      'priority': 'normal',
      'category': 'qualite',
      'icon': Icons.verified,
      'color': Colors.blue,
    },
    {
      'id': '7',
      'type': 'warning',
      'title': 'Maintenance programmée',
      'message': 'Maintenance des extracteurs prévue demain à 14h00 - Durée estimée: 2h',
      'timestamp': DateTime.now().subtract(const Duration(hours: 8)),
      'isRead': true,
      'priority': 'normal',
      'category': 'maintenance',
      'icon': Icons.build,
      'color': Colors.orange,
    },
    {
      'id': '8',
      'type': 'success',
      'title': 'Filtrage complété',
      'message': 'Lot FIL-2024-078: 32kg de miel filtré - Prêt pour conditionnement',
      'timestamp': DateTime.now().subtract(const Duration(hours: 10)),
      'isRead': true,
      'priority': 'normal',
      'category': 'production',
      'icon': Icons.filter_alt,
      'color': Colors.green,
    },
    {
      'id': '9',
      'type': 'info',
      'title': 'Rapport mensuel disponible',
      'message': 'Le rapport de production de novembre 2024 est maintenant disponible',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'isRead': false,
      'priority': 'low',
      'category': 'rapport',
      'icon': Icons.assessment,
      'color': Colors.blue,
    },
    {
      'id': '10',
      'type': 'error',
      'title': 'Erreur système détectée',
      'message': 'Problème de synchronisation avec la base de données - Support technique contacté',
      'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      'isRead': true,
      'priority': 'urgent',
      'category': 'systeme',
      'icon': Icons.error,
      'color': Colors.red,
    },
  ];

  List<Map<String, dynamic>> get filteredNotifications {
    switch (selectedFilter) {
      case 'Non lues':
        return notifications.where((n) => !n['isRead']).toList();
      case 'Urgentes':
        return notifications.where((n) => n['priority'] == 'urgent' || n['priority'] == 'high').toList();
      case 'Aujourd\'hui':
        final today = DateTime.now();
        return notifications.where((n) {
          final notifDate = n['timestamp'] as DateTime;
          return notifDate.day == today.day &&
                 notifDate.month == today.month &&
                 notifDate.year == today.year;
        }).toList();
      default:
        return notifications;
    }
  }

  int get unreadCount => notifications.where((n) => !n['isRead']).length;

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D0C0D),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D0C0D),
              ),
            ),
            Text(
              '$unreadCount non lues',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          // Bouton marquer toutes comme lues
          IconButton(
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.done_all),
            tooltip: 'Marquer toutes comme lues',
          ),
          // Bouton paramètres
          IconButton(
            onPressed: () {
              _showNotificationSettings();
            },
            icon: const Icon(Icons.settings),
            tooltip: 'Paramètres des notifications',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Filtres rapides
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'Toutes',
                      'Non lues',
                      'Urgentes',
                      'Aujourd\'hui',
                    ].map((filter) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: selectedFilter == filter,
                        label: Text(filter),
                        onSelected: (selected) {
                          setState(() {
                            selectedFilter = filter;
                          });
                        },
                        selectedColor: const Color(0xFFF49101).withOpacity(0.2),
                        checkmarkColor: const Color(0xFFF49101),
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                // Onglets par catégorie
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: const Color(0xFFF49101),
                  labelColor: const Color(0xFFF49101),
                  unselectedLabelColor: Colors.grey[600],
                  tabs: const [
                    Tab(text: 'Toutes'),
                    Tab(text: 'Ventes'),
                    Tab(text: 'Production'),
                    Tab(text: 'Système'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsList(filteredNotifications),
          _buildNotificationsList(notifications.where((n) => 
            n['category'] == 'vente' || n['category'] == 'finance').toList()),
          _buildNotificationsList(notifications.where((n) => 
            n['category'] == 'production' || n['category'] == 'collecte' || 
            n['category'] == 'qualite').toList()),
          _buildNotificationsList(notifications.where((n) => 
            n['category'] == 'systeme' || n['category'] == 'maintenance').toList()),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<Map<String, dynamic>> notifs) {
    if (notifs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune notification',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous êtes à jour !',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifs.length,
      itemBuilder: (context, index) {
        final notification = notifs[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isUrgent = notification['priority'] == 'urgent';
    final isHigh = notification['priority'] == 'high';
    final isRead = notification['isRead'] as bool;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent ? Colors.red.shade200 : 
                 isHigh ? Colors.orange.shade200 : 
                 Colors.grey.shade200,
          width: isUrgent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _markAsRead(notification['id']),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône avec indicateur de priorité
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (notification['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  notification['icon'],
                  color: notification['color'],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Indicateur non lu
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF49101),
                              shape: BoxShape.circle,
                            ),
                          ),
                        // Titre
                        Expanded(
                          child: Text(
                            notification['title'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                              color: const Color(0xFF2D0C0D),
                            ),
                          ),
                        ),
                        // Badge de priorité
                        if (isUrgent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'URGENT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Message
                    Text(
                      notification['message'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                    // Montant si présent
                    if (notification['amount'] != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF49101).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          notification['amount'],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF49101),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Timestamp
                    Text(
                      _formatTimestamp(notification['timestamp']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                onSelected: (action) => _handleNotificationAction(action, notification),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'mark_read',
                    child: Row(
                      children: [
                        Icon(isRead ? Icons.mark_email_unread : Icons.mark_email_read),
                        const SizedBox(width: 8),
                        Text(isRead ? 'Marquer non lu' : 'Marquer comme lu'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert, color: Colors.grey),
              ),
            ],
          ),
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

  void _markAsRead(String id) {
    setState(() {
      final index = notifications.indexWhere((n) => n['id'] == id);
      if (index != -1) {
        notifications[index]['isRead'] = true;
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in notifications) {
        notification['isRead'] = true;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Toutes les notifications ont été marquées comme lues'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleNotificationAction(String action, Map<String, dynamic> notification) {
    switch (action) {
      case 'mark_read':
        setState(() {
          notification['isRead'] = !notification['isRead'];
        });
        break;
      case 'delete':
        setState(() {
          notifications.removeWhere((n) => n['id'] == notification['id']);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification supprimée'),
            backgroundColor: Colors.orange,
          ),
        );
        break;
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.settings, color: Color(0xFFF49101)),
                  const SizedBox(width: 12),
                  const Text(
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

  Widget _buildSettingsTile(String title, String subtitle, IconData icon, bool value) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFF49101)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: (newValue) {
          // Ici vous pouvez gérer les changements de paramètres
        },
        activeColor: const Color(0xFFF49101),
      ),
    );
  }
}
