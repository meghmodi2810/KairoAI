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

enum _CreateUserRole { learner, admin }

class _CreateUserDialogResult {
  final AdminActionResult result;
  final _CreateUserRole role;

  const _CreateUserDialogResult({
    required this.result,
    required this.role,
  });
}

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
  String _scope = 'Learners';
  String _statusFilter = 'All';
  bool _creatingUser = false;
  String? _busyAdminId;

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
    if (_scope != 'Learners') return;
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

  List<UserModel> get _filteredLearners {
    var items = _users.where((u) => !u.isHidden).toList();
    switch (_statusFilter) {
      case 'Active':
        return items.where((u) => u.isActive).toList();
      case 'Inactive':
        return items.where((u) => !u.isActive).toList();
      default:
        return items;
    }
  }

  bool _matchesAdmin(AdminModel admin) {
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      final byName = admin.displayName.toLowerCase().contains(q);
      final byEmail = admin.email.toLowerCase().contains(q);
      if (!byName && !byEmail) {
        return false;
      }
    }

    switch (_statusFilter) {
      case 'Active':
        return admin.isActive;
      case 'Inactive':
        return !admin.isActive;
      default:
        return true;
    }
  }

  Future<void> _openCreateUserDialog() async {
    final hostContext = context;
    final nameCtrl = TextEditingController(text: 'Lisa Jisaheb');
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    var role = _scope == 'Admins' ? _CreateUserRole.admin : _CreateUserRole.learner;
    var submitting = false;

    final dialogResult = await showDialog<_CreateUserDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (localContext, setLocalState) {
            final c = ac(localContext);
            return AlertDialog(
              title: const Text('Create new user'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AdminInput(
                      label: 'Display name',
                      hint: 'Ayesha Khan',
                      controller: nameCtrl,
                    ),
                    const SizedBox(height: 12),
                    AdminInput(
                      label: 'Email',
                      hint: 'user@example.com',
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    AdminInput(
                      label: 'Temporary password',
                      hint: 'At least 6 characters',
                      controller: passwordCtrl,
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<_CreateUserRole>(
                      initialValue: role,
                      decoration: const InputDecoration(labelText: 'Account type'),
                      items: const [
                        DropdownMenuItem(
                          value: _CreateUserRole.learner,
                          child: Text('Learner'),
                        ),
                        DropdownMenuItem(
                          value: _CreateUserRole.admin,
                          child: Text('Admin'),
                        ),
                      ],
                      onChanged: submitting
                          ? null
                          : (nextRole) {
                              if (nextRole == null) return;
                              setLocalState(() => role = nextRole);
                            },
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        role == _CreateUserRole.admin
                            ? 'Admins get full governance access.'
                            : 'Learners can access lessons and assessments only.',
                        style: adminMeta(c.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext, rootNavigator: true).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          final displayName = nameCtrl.text.trim();
                          final email = emailCtrl.text.trim();
                          final tempPassword = passwordCtrl.text.trim();

                          if (displayName.isEmpty || email.isEmpty || tempPassword.isEmpty) {
                            AdminToast.show(
                              hostContext,
                              'Name, email, and password are required.',
                              type: AdminToastType.error,
                            );
                            return;
                          }

                          setLocalState(() => submitting = true);
                          if (mounted) setState(() => _creatingUser = true);

                          try {
                            final result = await _db.createManagedUser(
                              email: email,
                              displayName: displayName,
                              temporaryPassword: tempPassword,
                              createAsAdmin: role == _CreateUserRole.admin,
                              actingAdminId: widget.admin.id,
                            );

                            if (!mounted || !dialogContext.mounted) return;

                            if (!result.success) {
                              setLocalState(() => submitting = false);
                              AdminToast.show(
                                hostContext,
                                result.message,
                                type: AdminToastType.error,
                              );
                              return;
                            }

                            Navigator.of(dialogContext, rootNavigator: true).pop(
                              _CreateUserDialogResult(result: result, role: role),
                            );
                          } catch (_) {
                            if (dialogContext.mounted) {
                              setLocalState(() => submitting = false);
                            }
                            if (mounted) {
                              AdminToast.show(
                                hostContext,
                                'Could not create user account right now.',
                                type: AdminToastType.error,
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _creatingUser = false);
                          }
                        },
                  child: submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create user'),
                ),
              ],
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();

    if (!mounted || dialogResult == null) {
      return;
    }

    AdminToast.show(
      context,
      dialogResult.result.message,
      type: AdminToastType.success,
    );

    if (dialogResult.role == _CreateUserRole.learner) {
      await _loadFirst();
    } else {
      setState(() {
        _scope = 'Admins';
        _statusFilter = 'All';
      });
    }
  }

  Future<void> _toggleAdminStatus(AdminModel target, bool toActive) async {
    final confirmed = await AdminConfirmModal.show(
      context,
      title: toActive ? 'Reactivate admin?' : 'Deactivate admin?',
      body: toActive
          ? 'This admin will regain full access immediately.'
          : 'This admin will lose access until reactivated.',
      confirmLabel: toActive ? 'Reactivate' : 'Deactivate',
      isDestructive: !toActive,
    );

    if (!confirmed || !mounted) return;

    setState(() => _busyAdminId = target.id);
    final result = await _db.setAdminActiveStatus(
      adminId: target.id,
      isActive: toActive,
      actingAdminId: widget.admin.id,
    );
    if (!mounted) return;
    setState(() => _busyAdminId = null);

    AdminToast.show(
      context,
      result.message,
      type: result.success ? AdminToastType.success : AdminToastType.error,
    );
  }

  Future<void> _removeAdmin(AdminModel target) async {
    final confirmed = await AdminConfirmModal.show(
      context,
      title: 'Remove admin access?',
      body: 'This will remove admin privileges for ${target.email}.',
      confirmLabel: 'Remove admin',
      isDestructive: true,
    );

    if (!confirmed || !mounted) return;

    setState(() => _busyAdminId = target.id);
    final result = await _db.removeAdminAccess(
      adminId: target.id,
      actingAdminId: widget.admin.id,
    );
    if (!mounted) return;
    setState(() => _busyAdminId = null);

    AdminToast.show(
      context,
      result.message,
      type: result.success ? AdminToastType.success : AdminToastType.error,
    );
  }

  Future<void> _renameAdmin(AdminModel target) async {
    final hostContext = context;
    final nameCtrl = TextEditingController(text: target.displayName);
    var submitting = false;

    final result = await showDialog<AdminActionResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (localContext, setLocalState) {
            return AlertDialog(
              title: const Text('Update admin name'),
              content: AdminInput(
                label: 'Display name',
                hint: 'Admin display name',
                controller: nameCtrl,
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext, rootNavigator: true).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          final nextName = nameCtrl.text.trim();
                          if (nextName.isEmpty) {
                            AdminToast.show(
                              hostContext,
                              'Display name cannot be empty.',
                              type: AdminToastType.error,
                            );
                            return;
                          }

                          setLocalState(() => submitting = true);
                          final result = await _db.updateAdminDisplayName(
                            adminId: target.id,
                            displayName: nextName,
                            actingAdminId: widget.admin.id,
                          );
                          if (!localContext.mounted || !mounted) return;

                          if (!result.success) {
                            setLocalState(() => submitting = false);
                            AdminToast.show(
                              hostContext,
                              result.message,
                              type: AdminToastType.error,
                            );
                            return;
                          }

                          Navigator.of(dialogContext, rootNavigator: true).pop(result);
                        },
                  child: submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameCtrl.dispose();

    if (!mounted || result == null) return;

    AdminToast.show(
      context,
      result.message,
      type: AdminToastType.success,
    );
  }

  Future<void> _openDetail(UserModel user) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserDetailScreen(
          admin: widget.admin,
          userId: user.uid,
        ),
      ),
    );

    if (!mounted) return;

    if (result is Map && result['deleted'] == true) {
      final deletedId = (result['userId'] ?? '').toString();
      if (deletedId.isNotEmpty) {
        setState(() {
          _users.removeWhere((u) => u.uid == deletedId);
        });
      }
    }

    await _loadFirst();
  }

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    final filtered = _filteredLearners;

    return Scaffold(
      backgroundColor: c.bgBase,
      appBar: AdminTopBar(
        title: 'Users',
        onMenuTap: widget.onMenuTap,
        action: AdminTopBarIconButton(
          icon: LucideIcons.plus,
          onTap: () => AdminToast.show(
            context,
            'Learners are added when they sign up.',
            type: AdminToastType.info,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AdminSearchBar(
              controller: _searchCtrl,
              hint: _scope == 'Admins' ? 'Search admins...' : 'Search learners...',
              onChanged: (v) {
                _search = v;
                if (_scope == 'Learners') {
                  _loadFirst();
                } else {
                  setState(() {});
                }
              },
              onClear: () {
                _search = '';
                if (_scope == 'Learners') {
                  _loadFirst();
                } else {
                  setState(() {});
                }
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: ['Learners', 'Admins']
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AdminFilterChip(
                        label: f,
                        selected: _scope == f,
                        onTap: () {
                          if (_scope == f) return;
                          setState(() {
                            _scope = f;
                            _statusFilter = 'All';
                          });
                          if (f == 'Learners') {
                            _loadFirst();
                          }
                        },
                      ),
                    ),
                  )
                  .toList(),
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
                        selected: _statusFilter == f,
                        onTap: () => setState(() => _statusFilter = f),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _scope == 'Learners'
                ? (_loadingFirst
                    ? AdminSkeletonLoader.listRows(count: 10)
                    : _hasError
                        ? AdminErrorState(onRetry: _loadFirst)
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
                              ))
                : StreamBuilder<List<AdminModel>>(
                    stream: _db.adminsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return AdminSkeletonLoader.listRows(count: 8);
                      }
                      if (snapshot.hasError) {
                        return AdminErrorState(onRetry: () => setState(() {}));
                      }

                      final admins = (snapshot.data ?? <AdminModel>[])
                          .where(_matchesAdmin)
                          .toList(growable: false);

                      if (admins.isEmpty) {
                        return AdminEmptyState(
                          icon: LucideIcons.shield,
                          title: _search.isNotEmpty
                              ? 'No admins found'
                              : 'No admins found',
                          body: _search.isNotEmpty
                              ? 'Try a different search term.'
                              : 'Use the plus button to create an admin account.',
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: admins.length,
                        itemBuilder: (context, i) {
                          final admin = admins[i];
                          return _AdminAccountRow(
                            admin: admin,
                            isBusy: _busyAdminId == admin.id,
                            isLast: i == admins.length - 1,
                            onActionSelected: (action) {
                              if (action == 'edit') {
                                _renameAdmin(admin);
                              } else if (action == 'activate') {
                                _toggleAdminStatus(admin, true);
                              } else if (action == 'deactivate') {
                                _toggleAdminStatus(admin, false);
                              } else if (action == 'remove') {
                                _removeAdmin(admin);
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AdminAccountRow extends StatelessWidget {
  final AdminModel admin;
  final bool isBusy;
  final bool isLast;
  final ValueChanged<String> onActionSelected;

  const _AdminAccountRow({
    required this.admin,
    required this.isBusy,
    required this.isLast,
    required this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    return AdminRow(
      isLast: isLast,
      leading: AdminAvatar(
        name: admin.displayName.isNotEmpty ? admin.displayName : admin.email,
        isBanned: !admin.isActive,
      ),
      title: Text(
        admin.displayName.isNotEmpty ? admin.displayName : admin.email,
        style: adminH3(c.textPrimary),
      ),
      subtitle: Text(admin.email, style: adminMeta(c.textMuted)),
      trailing: isBusy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : PopupMenuButton<String>(
              icon: Icon(LucideIcons.moreVertical, size: 16, color: c.textMuted),
              onSelected: onActionSelected,
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('Edit display name'),
                ),
                PopupMenuItem<String>(
                  value: admin.isActive ? 'deactivate' : 'activate',
                  child: Text(admin.isActive ? 'Deactivate admin' : 'Reactivate admin'),
                ),
                const PopupMenuItem<String>(
                  value: 'remove',
                  child: Text('Remove admin access'),
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
