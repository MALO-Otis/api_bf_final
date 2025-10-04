import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apisavana_gestion/authentication/user_session.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String selectedFilter = 'Toutes';
  late final UserSession _session;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _session = Get.find<UserSession>();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Query<Map<String, dynamic>> _baseQuery() {
    Query<Map<String, dynamic>> q =
        FirebaseFirestore.instance.collection('notifications_caisse');
    final site = _session.site ?? '';
    if (site.isNotEmpty) {
      q = q.where('site', isEqualTo: site);
    }
    return q; // tri côté client
  }

  int _unreadFromDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs.where((d) => (d.data()['statut'] ?? 'non_lue') != 'lue').length;
  }

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
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _baseQuery().snapshots(),
              builder: (context, snap) {
                final docs =
                    List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                        snap.data?.docs ?? []);
                // tri dateCreation desc si dispo
                docs.sort((a, b) {
                  final ta = a.data()['dateCreation'];
                  final tb = b.data()['dateCreation'];
                  DateTime da = ta is Timestamp ? ta.toDate() : DateTime(0);
                  DateTime db = tb is Timestamp ? tb.toDate() : DateTime(0);
                  return db.compareTo(da);
                });
                final count = _unreadFromDocs(docs);
                return Text(
                  '$count non lues',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.normal,
                  ),
                );
              },
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
            onPressed: _showNotificationSettings,
            icon: const Icon(Icons.settings),
            tooltip: 'Paramètres des notifications',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(140),
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
                    ]
                        .map((filter) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                selected: selectedFilter == filter,
                                label: Text(filter),
                                onSelected: (selected) {
                                  setState(() {
                                    selectedFilter = filter;
                                  });
                                },
                                selectedColor:
                                    const Color(0xFFF49101).withOpacity(0.2),
                                checkmarkColor: const Color(0xFFF49101),
                              ),
                            ))
                        .toList(),
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
          // Toutes
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _baseQuery().snapshots(),
            builder: (context, snap) {
              final docs =
                  List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                      snap.data?.docs ?? []);
              // Tri côté client par dateCreation desc
              docs.sort((a, b) {
                final ta = a.data()['dateCreation'];
                final tb = b.data()['dateCreation'];
                DateTime da = ta is Timestamp ? ta.toDate() : DateTime(0);
                DateTime db = tb is Timestamp ? tb.toDate() : DateTime(0);
                return db.compareTo(da);
              });

              // Appliquer filtres rapides
              final filtered = docs.where((d) {
                final data = d.data();
                final statut = (data['statut'] ?? 'non_lue').toString();
                final priorite = (data['priorite'] ?? 'normale').toString();
                final ts = data['dateCreation'];
                DateTime when = ts is Timestamp ? ts.toDate() : DateTime.now();

                switch (selectedFilter) {
                  case 'Non lues':
                    return statut != 'lue';
                  case 'Urgentes':
                    return priorite == 'haute' ||
                        priorite == 'urgent' ||
                        priorite == 'high';
                  case 'Aujourd\'hui':
                    final now = DateTime.now();
                    return when.year == now.year &&
                        when.month == now.month &&
                        when.day == now.day;
                  default:
                    return true;
                }
              }).toList();

              return _buildNotificationsListFromDocs(filtered);
            },
          ),
          // Ventes / Finance
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _baseQuery().snapshots(),
            builder: (context, snap) {
              final docs =
                  List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                      snap.data?.docs ?? []);
              docs.sort((a, b) {
                final ta = a.data()['dateCreation'];
                final tb = b.data()['dateCreation'];
                DateTime da = ta is Timestamp ? ta.toDate() : DateTime(0);
                DateTime db = tb is Timestamp ? tb.toDate() : DateTime(0);
                return db.compareTo(da);
              });

              final filtered = docs.where((d) {
                final data = d.data();
                if (!_isVenteType((data['type'] ?? '').toString())) {
                  return false;
                }

                final statut = (data['statut'] ?? 'non_lue').toString();
                final priorite = (data['priorite'] ?? 'normale').toString();
                final ts = data['dateCreation'];
                DateTime when = ts is Timestamp ? ts.toDate() : DateTime.now();

                switch (selectedFilter) {
                  case 'Non lues':
                    return statut != 'lue';
                  case 'Urgentes':
                    return priorite == 'haute' ||
                        priorite == 'urgent' ||
                        priorite == 'high';
                  case 'Aujourd\'hui':
                    final now = DateTime.now();
                    return when.year == now.year &&
                        when.month == now.month &&
                        when.day == now.day;
                  default:
                    return true;
                }
              }).toList();

              return _buildNotificationsListFromDocs(filtered);
            },
          ),
          // Production / Collecte / Qualité
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _baseQuery().snapshots(),
            builder: (context, snap) {
              final docs =
                  List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                      snap.data?.docs ?? []);
              docs.sort((a, b) {
                final ta = a.data()['dateCreation'];
                final tb = b.data()['dateCreation'];
                DateTime da = ta is Timestamp ? ta.toDate() : DateTime(0);
                DateTime db = tb is Timestamp ? tb.toDate() : DateTime(0);
                return db.compareTo(da);
              });

              final filtered = docs.where((d) {
                final data = d.data();
                if (!_isProductionType((data['type'] ?? '').toString())) {
                  return false;
                }

                final statut = (data['statut'] ?? 'non_lue').toString();
                final priorite = (data['priorite'] ?? 'normale').toString();
                final ts = data['dateCreation'];
                DateTime when = ts is Timestamp ? ts.toDate() : DateTime.now();

                switch (selectedFilter) {
                  case 'Non lues':
                    return statut != 'lue';
                  case 'Urgentes':
                    return priorite == 'haute' ||
                        priorite == 'urgent' ||
                        priorite == 'high';
                  case 'Aujourd\'hui':
                    final now = DateTime.now();
                    return when.year == now.year &&
                        when.month == now.month &&
                        when.day == now.day;
                  default:
                    return true;
                }
              }).toList();

              return _buildNotificationsListFromDocs(filtered);
            },
          ),
          // Système / Maintenance
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _baseQuery().snapshots(),
            builder: (context, snap) {
              final docs =
                  List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                      snap.data?.docs ?? []);
              docs.sort((a, b) {
                final ta = a.data()['dateCreation'];
                final tb = b.data()['dateCreation'];
                DateTime da = ta is Timestamp ? ta.toDate() : DateTime(0);
                DateTime db = tb is Timestamp ? tb.toDate() : DateTime(0);
                return db.compareTo(da);
              });

              final filtered = docs.where((d) {
                final data = d.data();
                if (!_isSystemType((data['type'] ?? '').toString())) {
                  return false;
                }

                final statut = (data['statut'] ?? 'non_lue').toString();
                final priorite = (data['priorite'] ?? 'normale').toString();
                final ts = data['dateCreation'];
                DateTime when = ts is Timestamp ? ts.toDate() : DateTime.now();

                switch (selectedFilter) {
                  case 'Non lues':
                    return statut != 'lue';
                  case 'Urgentes':
                    return priorite == 'haute' ||
                        priorite == 'urgent' ||
                        priorite == 'high';
                  case 'Aujourd\'hui':
                    final now = DateTime.now();
                    return when.year == now.year &&
                        when.month == now.month &&
                        when.day == now.day;
                  default:
                    return true;
                }
              }).toList();

              return _buildNotificationsListFromDocs(filtered);
            },
          ),
        ],
      ),
    );
  }

  // Catégories de type pour onglets
  bool _isVenteType(String type) {
    final t = type.toLowerCase();
    return t == 'prelevement_termine' ||
        t == 'credit_overdue' ||
        t.startsWith('vente_') ||
        t.startsWith('finance_') ||
        t.contains('vente') ||
        t.contains('credit');
  }

  bool _isProductionType(String type) {
    final t = type.toLowerCase();
    return t.startsWith('collecte_') ||
        t.startsWith('extraction_') ||
        t.startsWith('filtrage') ||
        t.startsWith('conditionnement');
  }

  bool _isSystemType(String type) {
    final t = type.toLowerCase();
    return t.startsWith('system') ||
        t.startsWith('maintenance') ||
        t.contains('systeme');
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

  Future<void> _markAsRead(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications_caisse')
          .doc(id)
          .update({'statut': 'lue'});
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      final snap = await _baseQuery().get();
      final batch = FirebaseFirestore.instance.batch();
      for (final d in snap.docs) {
        if ((d.data()['statut'] ?? 'non_lue') != 'lue') {
          batch.update(d.reference, {'statut': 'lue'});
        }
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Toutes les notifications ont été marquées comme lues'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleNotificationAction(
      String action, Map<String, dynamic> notification) {
    switch (action) {
      case 'mark_read':
        _markAsRead(notification['id'] as String);
        break;
      case 'delete':
        FirebaseFirestore.instance
            .collection('notifications_caisse')
            .doc(notification['id'] as String)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification supprimée'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        break;
    }
  }

  // Transform Firestore docs to UI list
  Widget _buildNotificationsListFromDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('Aucune notification'),
        ),
      );
    }

    return ListView.separated(
      itemCount: docs.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final d = docs[index];
        final data = d.data();
        final id = d.id;
        final type = (data['type'] ?? 'info').toString();
        final titre = (data['titre'] ?? data['title'] ?? '').toString();
        final message = (data['message'] ?? '').toString();
        final priorite = (data['priorite'] ?? 'normale').toString();
        final ts = data['dateCreation'];
        final when = ts is Timestamp ? ts.toDate() : DateTime.now();
        final isRead = (data['statut'] ?? 'non_lue') == 'lue';

        final (icon, color) = _iconAndColorFor(type, priorite);

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            foregroundColor: color,
            child: Icon(icon),
          ),
          title: Text(
            titre.isNotEmpty ? titre : _titleForType(type),
            style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.isNotEmpty) Text(message),
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(when),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) => _handleNotificationAction(value, {
              'id': id,
            }),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'mark_read',
                child: Text(
                    isRead ? 'Marquer comme non lue' : 'Marquer comme lue'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Supprimer'),
              ),
            ],
          ),
          onTap: () => _markAsRead(id),
        );
      },
    );
  }

  (IconData, Color) _iconAndColorFor(String type, String priorite) {
    switch (type) {
      case 'credit_overdue':
        return (Icons.credit_card, Colors.red);
      case 'prelevement_termine':
        return (Icons.assignment_turned_in, Colors.indigo);
      case 'collecte_recolte':
        return (Icons.agriculture, Colors.green);
      case 'collecte_scoop':
        return (Icons.shopping_basket, Colors.teal);
      case 'collecte_individuel':
        return (Icons.person, Colors.blueGrey);
      case 'collecte_miellerie':
        return (Icons.hive, Colors.amber);
      default:
        return (Icons.notifications, Colors.blue);
    }
  }

  String _titleForType(String type) {
    switch (type) {
      case 'credit_overdue':
        return 'Crédit en retard (>= 30 jours)';
      case 'prelevement_termine':
        return 'Prélèvement terminé';
      case 'collecte_recolte':
        return 'Nouvelle collecte – Récoltes';
      case 'collecte_scoop':
        return 'Nouvel achat – SCOOP';
      case 'collecte_individuel':
        return 'Nouvel achat – Individuel';
      case 'collecte_miellerie':
        return 'Nouvelle collecte – Miellerie';
      default:
        return 'Notification';
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
