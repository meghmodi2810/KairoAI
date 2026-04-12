import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kairo_ai/admin/theme/admin_theme.dart';
import 'package:kairo_ai/admin/widgets/a_inputs.dart';

enum AdminToastType { success, error, warning, info }

class AdminToast extends StatefulWidget {
  final String message;
  final AdminToastType type;
  final Duration duration;
  final VoidCallback? onDismiss;

  const AdminToast({
    super.key,
    required this.message,
    this.type = AdminToastType.success,
    this.duration = const Duration(seconds: 3),
    this.onDismiss,
  });

  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context,
    String message, {
    AdminToastType type = AdminToastType.success,
    Duration duration = const Duration(seconds: 3),
  }) {
    _currentEntry?.remove();
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => _ToastOverlay(
        message: message,
        type: type,
        duration: duration,
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
        },
      ),
    );
    _currentEntry = entry;
    overlay.insert(entry);
  }

  @override
  State<AdminToast> createState() => _AdminToastState();
}

class _ToastOverlay extends StatefulWidget {
  final String message;
  final AdminToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastOverlay({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _slideAnim = Tween<double>(begin: 12, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
    Future.delayed(widget.duration - const Duration(milliseconds: 160), () {
      if (mounted) {
        _ctrl.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    final mediaQuery = MediaQuery.of(context);

    Color bg;
    Color fg;
    Color border;
    switch (widget.type) {
      case AdminToastType.success:
        bg = c.successFill;
        fg = c.successText;
        border = c.success;
      case AdminToastType.error:
        bg = c.errorFill;
        fg = c.errorText;
        border = c.error;
      case AdminToastType.warning:
        bg = c.warningFill;
        fg = c.warningText;
        border = c.warning;
      case AdminToastType.info:
        bg = c.accentFill;
        fg = c.isDark ? c.accentBright : c.accent;
        border = c.isDark ? c.accentBright : c.accent;
    }

    IconData icon;
    Color iconColor = fg;
    switch (widget.type) {
      case AdminToastType.success:
        icon = LucideIcons.checkCircle2;
        iconColor = Colors.greenAccent;
      case AdminToastType.error:
        icon = LucideIcons.xCircle;
        iconColor = Colors.redAccent;
      case AdminToastType.warning:
        icon = LucideIcons.alertTriangle;
        iconColor = Colors.orangeAccent;
      case AdminToastType.info:
        icon = LucideIcons.info;
        iconColor = Colors.blueAccent;
    }

    return Positioned(
      bottom: mediaQuery.padding.bottom + 80,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: Opacity(opacity: _fadeAnim.value, child: child),
        ),
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null &&
                details.primaryVelocity! > 0) {
              _ctrl.reverse().then((_) => widget.onDismiss());
            }
          },
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF111111),
                  blurRadius: 0,
                  offset: Offset(4, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: fg,
                      letterSpacing: 0.15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminToastState extends State<AdminToast> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class AdminConfirmModal extends StatelessWidget {
  final String title;
  final String body;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  const AdminConfirmModal({
    super.key,
    required this.title,
    required this.body,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = true,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String body,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AdminConfirmModal(
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    return Dialog(
      backgroundColor: c.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusModal),
        side: BorderSide(color: c.border, width: 2.5),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDestructive)
              Icon(LucideIcons.alertTriangle, size: 28, color: c.error)
            else
              Icon(LucideIcons.helpCircle, size: 28, color: (c.isDark ? c.accentBright : c.accent)),
            const SizedBox(height: 16),
            Text(title, style: adminH2(c.textPrimary)),
            const SizedBox(height: 8),
            Text(body, style: adminBody(c.textSecondary)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AdminButton(
                    label: cancelLabel,
                    variant: AdminButtonVariant.secondary,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AdminButton(
                    label: confirmLabel,
                    variant: isDestructive ? AdminButtonVariant.destructive : AdminButtonVariant.accent,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AdminAvatar extends StatelessWidget {
  final String name;
  final double size;
  final bool isBanned;

  const AdminAvatar({
    super.key,
    required this.name,
    this.size = 32,
    this.isBanned = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: c.accentFill,
        border: Border.all(
          color: isBanned ? c.error : c.border2,
          width: isBanned ? 2.5 : 2,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0xFF111111), offset: Offset(2, 2), blurRadius: 0),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.38,
            fontWeight: FontWeight.w700,
            color: isBanned ? c.errorText : c.textPrimary,
          ),
        ),
      ),
    );
  }
}

class AdminDrawer extends StatefulWidget {
  final String adminName;
  final String adminEmail;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onSignOut;

  const AdminDrawer({
    super.key,
    required this.adminName,
    required this.adminEmail,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onSignOut,
  });

  @override
  State<AdminDrawer> createState() => _AdminDrawerState();
}

class _AdminDrawerState extends State<AdminDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  static const _navItems = [
    (LucideIcons.layoutGrid, 'Dashboard'),
    (LucideIcons.bookOpen, 'Lessons'),
    (LucideIcons.users, 'Learners'),
    (LucideIcons.barChart2, 'Analytics'),
    (LucideIcons.activity, 'Issues'),
    (LucideIcons.settings, 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = (screenWidth * 0.82).clamp(0.0, 320.0);
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Material(
      color: c.bgBase,
      child: SizedBox(
        width: drawerWidth,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 20),
                decoration: BoxDecoration(
                  color: c.bgSurface,
                  border: Border(bottom: BorderSide(color: c.border, width: 2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminAvatar(name: widget.adminName, size: 48),
                    const SizedBox(height: 14),
                    Text(
                      widget.adminName,
                      style: adminH1(c.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.adminEmail,
                      style: adminMeta(c.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 14, bottom: 14),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Text('NAVIGATION', style: adminLabel(c.textMuted)),
                    ),
                    ..._navItems.take(3).toList().asMap().entries.map((e) => _item(e, c)),
                    const SizedBox(height: 8),
                    Divider(indent: 14, endIndent: 14, height: 24, color: c.border),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Text('SYSTEM', style: adminLabel(c.textMuted)),
                    ),
                    ..._navItems.skip(3).toList().asMap().entries.map((e) => _item(e, c, offset: 3)),
                  ],
                ),
              ),

              Divider(height: 1, color: c.border),
              GestureDetector(
                onTap: widget.onSignOut,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: c.errorFill,
                    border: Border(top: BorderSide(color: c.error, width: 2)),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.logOut, size: 16, color: c.error),
                      const SizedBox(width: 10),
                      Text(
                        'Sign out',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: c.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(14, 0, 14, 14 + safeBottom),
                child: Text('KairoAI Admin v1.4', style: adminMeta(c.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(MapEntry<int, (IconData, String)> e, AdminColors c, {int offset = 0}) {
    final i = e.key + offset;
    final (icon, label) = e.value;
    final isSelected = widget.selectedIndex == i;

    return GestureDetector(
      onTap: () {
        widget.onTabSelected(i);
        Navigator.of(context).pop();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 42,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? c.accentFill : c.bgSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? (c.isDark ? c.accentBright : c.accent) : c.border,
            width: 2,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(color: Color(0xFF111111), offset: Offset(2, 2), blurRadius: 0),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? (c.isDark ? c.accentBright : c.accent) : c.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? (c.isDark ? c.accentBright : c.accent) : c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const AdminNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  static const _tabs = [
    (LucideIcons.layoutGrid, 'Dashboard'),
    (LucideIcons.bookOpen, 'Lessons'),
    (LucideIcons.users, 'Learners'),
    (LucideIcons.barChart2, 'Analytics'),
    (LucideIcons.activity, 'Issues'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 58 + bottomPad,
      decoration: BoxDecoration(
        color: c.bgSurface,
        border: Border(top: BorderSide(color: c.border, width: 2)),
        boxShadow: const [
          BoxShadow(color: Color(0xFF111111), offset: Offset(0, -2), blurRadius: 0),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, 0, 8, bottomPad),
        child: Row(
          children: _tabs.asMap().entries.map((e) {
            final i = e.key;
            final (icon, label) = e.value;
            final isSelected = selectedIndex == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTabSelected(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected ? c.accentFill : c.bgSurface2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? (c.isDark ? c.accentBright : c.accent) : c.border,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? const [
                            BoxShadow(color: Color(0xFF111111), offset: Offset(2, 2), blurRadius: 0),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: isSelected
                            ? (c.isDark ? c.accentBright : c.accent)
                            : c.textMuted,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? (c.isDark ? c.accentBright : c.accent) : c.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
