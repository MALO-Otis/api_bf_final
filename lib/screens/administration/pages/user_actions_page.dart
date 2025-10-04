import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/user_management_models.dart';
import '../services/user_management_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Page complète d'historique avec filtres et pagination
class UserActionsPage extends StatefulWidget {
  final UserManagementService service;
  final bool isMobile;
  const UserActionsPage(
      {super.key, required this.service, required this.isMobile});

  @override
  State<UserActionsPage> createState() => _UserActionsPageState();
}

class _UserActionsPageState extends State<UserActionsPage> {
  final RxList<UserAction> _actions = <UserAction>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isLoadingMore = false.obs;
  final ScrollController _scroll = ScrollController();

  DocumentSnapshot? _cursor;
  bool _hasMore = true;

  // Filtres
  UserActionType? _type;
  String? _adminEmail;
  String? _userId;
  DateTime? _start;
  DateTime? _end;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load(first: true);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore.value) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load({bool first = false}) async {
    if (_isLoading.value) return;
    _isLoading.value = true;
    if (first) {
      _cursor = null;
      _hasMore = true;
      _actions.clear();
    }
    final res = await widget.service.getActionsPaginated(
      limit: 50,
      startAfter: _cursor,
      type: _type,
      adminEmail: _adminEmail,
      userId: _userId,
      start: _start,
      end: _end,
      search: _searchCtrl.text.trim(),
    );
    _actions.addAll(res.actions);
    _cursor = res.lastDocument;
    _hasMore = res.hasMore;
    _isLoading.value = false;
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore.value || !_hasMore) return;
    _isLoadingMore.value = true;
    final res = await widget.service.getActionsPaginated(
      limit: 50,
      startAfter: _cursor,
      type: _type,
      adminEmail: _adminEmail,
      userId: _userId,
      start: _start,
      end: _end,
      search: _searchCtrl.text.trim(),
    );
    _actions.addAll(res.actions);
    _cursor = res.lastDocument;
    _hasMore = res.hasMore;
    _isLoadingMore.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilters(),
        const SizedBox(height: 8),
        Expanded(
          child: Obx(() {
            if (_isLoading.value && _actions.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_actions.isEmpty) {
              return _buildEmpty();
            }
            return RefreshIndicator(
              onRefresh: () => _load(first: true),
              child: ListView.separated(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemBuilder: (ctx, i) {
                  if (i == _actions.length) {
                    return Obx(() => _isLoadingMore.value
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : const SizedBox.shrink());
                  }
                  final a = _actions[i];
                  return _buildActionTile(a);
                },
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: _actions.length + 1,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 220,
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Recherche (desc/admin)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _load(first: true),
            ),
          ),
          DropdownButton<UserActionType>(
            hint: const Text('Type'),
            value: _type,
            items: UserActionType.values
                .map((t) =>
                    DropdownMenuItem(value: t, child: Text(t.displayName)))
                .toList(),
            onChanged: (v) {
              setState(() => _type = v);
              _load(first: true);
            },
          ),
          ElevatedButton.icon(
            onPressed: () => _load(first: true),
            icon: const Icon(Icons.filter_alt),
            label: const Text('Appliquer'),
          ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _type = null;
                _adminEmail = null;
                _userId = null;
                _start = null;
                _end = null;
                _searchCtrl.clear();
              });
              _load(first: true);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('Aucune action trouvée',
              style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildActionTile(UserAction a) {
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey[200]!)),
      leading: CircleAvatar(
        backgroundColor: _color(a.type).withOpacity(0.15),
        child: Text(a.type.icon),
      ),
      title: Text(a.type.displayName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(a.description),
          const SizedBox(height: 4),
          Text('${a.adminEmail} · ${a.timestamp}'),
        ],
      ),
    );
  }

  Color _color(UserActionType t) {
    switch (t) {
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
}
