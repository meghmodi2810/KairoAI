import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kairo_ai/admin/models/admin_models.dart';
import 'package:kairo_ai/admin/services/admin_database_service.dart';
import 'package:kairo_ai/admin/theme/admin_theme.dart';
import 'package:kairo_ai/admin/widgets/a_top_bar.dart';
import 'package:kairo_ai/admin/widgets/a_components.dart';
import 'package:kairo_ai/admin/widgets/a_inputs.dart';
import 'package:kairo_ai/admin/widgets/a_overlays.dart';
import 'package:kairo_ai/admin/screens/users/user_detail_screen.dart';
import 'package:kairo_ai/models/app_models.dart';

class AdminUsersScreen extends StatefulWidget {
  final AdminModel admin;
  final VoidCallback onMenuTap;

  const AdminUsersScreen({
    super.key,
    required this.admin,
    required this.onMenuTap,
  });

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _db = AdminDatabaseService();
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _filter = 'All';

  // Pagination
  final List<UserModel> _users = [];
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _loadingFirst = true;
  bool _loadingMore = false;
  bool _hasError = false;
  final _scrollCtrl = ScrollController();

  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadFirst();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 80 &&
        !_loadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadFirst() async {
    setState(() {
      _loadingFirst = true;
      _hasError = false;
      _users.clear();
      _lastDoc = null;
      _hasMore = true;
    });
    await _fetchPage();
    if (mounted) setState(() => _loadingFirst = false);
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    await _fetchPage();
    if (mounted) setState(() => _loadingMore = false);
  }

  Future<void> _fetchPage() async {
    try {
      final result = await _db.getLearners(
        limit: _pageSize,
        startAfter: _lastDoc,
        searchQuery: _search.isNotEmpty ? _search : null,
      );
      if (!mounted) return;
      setState(() {
        _users.addAll(result.learners);
        _lastDoc = result.lastDocument;
        _hasMore = result.hasMore;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  List<UserModel> get _filtered {
    var items = _users;
    // Client side filtering for the 'filter' tabs
    switch (_filter) {
      case 'Active':
        return items.where((u) => u.isActive).toList();
      case 'Inactive':
        return items.where((u) => !u.isActive).toList();
      default:
        return items;
    }
  }

  void _openDetail(UserModel user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserDetailScreen(
          admin: widget.admin,
          userId: user.uid,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: c.bgBase,
      appBar: AdminTopBar(
        title: 'Learners',
        onMenuTap: widget.onMenuTap,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AdminSearchBar(
              controller: _searchCtrl,
              hint: 'Search learners...',
              onChanged: (v) {
                _search = v;
                // debounce would be good, but for now just reload
                _loadFirst();
              },
              onClear: () {
                _search = '';
                _loadFirst();
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: ['All', 'Active', 'Inactive']
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AdminFilterChip(
                        label: f,
                        selected: _filter == f,
                        onTap: () => setState(() => _filter = f),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loadingFirst
                ? AdminSkeletonLoader.listRows(count: 10)
                : _hasError
                    ? AdminErrorState(
                        onRetry: _loadFirst,
                      )
                    : filtered.isEmpty
                        ? AdminEmptyState(
                            icon: LucideIcons.users,
                            title: _search.isNotEmpty
                                ? 'No results found'
                                : 'No learners yet',
                            body: _search.isNotEmpty
                                ? 'We couldn\'t find any learners named "$_search"'
                                : 'Active learners will appear here.',
                          )
                        : RefreshIndicator(
                            onRefresh: _loadFirst,
                            color: c.accent,
                            child: ListView.builder(
                              controller: _scrollCtrl,
                              padding: const EdgeInsets.only(bottom: 100),
                              itemCount: filtered.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, i) {
                                if (i == filtered.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  );
                                }
                                final user = filtered[i];
                                return _UserRow(
                                  user: user,
                                  isLast: i == filtered.length - 1,
                                  onTap: () => _openDetail(user),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final UserModel user;
  final bool isLast;
  final VoidCallback onTap;

  const _UserRow({
    required this.user,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    return AdminRow(
      leading: AdminAvatar(
        name: user.displayName,
        isBanned: !user.isActive,
      ),
      title: Text(
        user.displayName.isNotEmpty ? user.displayName : 'Anonymous',
        style: adminH3(c.textPrimary),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.email, style: adminMeta(c.textMuted)),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(LucideIcons.zap, size: 10, color: c.accent),
              const SizedBox(width: 4),
              Text('${user.xp} XP · Lv ${user.currentLevel}',
                   style: adminMeta(c.textSecondary)),
            ],
          ),
        ],
      ),
      trailing: AdminTag(
        label: user.isActive ? 'Active' : 'Inactive',
        variant: user.isActive ? AdminTagVariant.active : AdminTagVariant.inactive,
      ),
      showChevron: true,
      isLast: isLast,
      onTap: onTap,
      minHeight: 68,
    );
  }
}
