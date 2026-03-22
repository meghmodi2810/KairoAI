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
    
    // Stripe toasts are usually simple and dark or matching type
    final bg = c.isDark ? c.bgSurface3 : const Color(0xFF1A1F36);
    final fg = Colors.white;

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
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
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
                      fontWeight: FontWeight.w600,
                      color: fg,
                      letterSpacing: -0.1,
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
      ),
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
        shape: BoxShape.circle,
        color: c.bgSurface3,
        border: Border.all(
          color: isBanned ? c.error : c.border2,
          width: isBanned ? 2 : 1,
        ),
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
    (LucideIcons.home, 'Home'),
    (LucideIcons.bookOpen, 'Content'),
    (LucideIcons.users, 'Learners'),
    (LucideIcons.barChart2, 'Trends'),
    (LucideIcons.activity, 'Alerts'),
    (LucideIcons.settings, 'Platform'),
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
    final safeTop = MediaQuery.of(context).padding.top;

    return Material(
      color: c.bgSurface,
      child: SizedBox(
        width: drawerWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Premium Identity Block
            Container(
              color: c.bgBase,
              padding: EdgeInsets.fromLTRB(14, safeTop + 24, 14, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminAvatar(name: widget.adminName, size: 48),
                  const SizedBox(height: 14),
                  Text(widget.adminName, style: adminH1(c.textPrimary)),
                  Text(widget.adminEmail, style: adminMeta(c.textSecondary)),
                ],
              ),
            ),
            const Divider(),

            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text('OVERVIEW', style: adminLabel(c.textMuted)),
            ),
            ..._navItems.take(3).toList().asMap().entries.map((e) => _item(e, c)),

            const Divider(indent: 14, endIndent: 14, height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text('SYSTEM', style: adminLabel(c.textMuted)),
            ),
            ..._navItems.skip(3).toList().asMap().entries.map((e) => _item(e, c, offset: 3)),

            const Spacer(),
            const Divider(),
            GestureDetector(
              onTap: widget.onSignOut,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Icon(LucideIcons.logOut, size: 16, color: c.error),
                    const SizedBox(width: 10),
                    Text('Sign out', 
                         style: TextStyle(
                           fontSize: 13,
                           fontWeight: FontWeight.w600,
                           color: c.error,
                         )),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(14, 0, 14, 24 + MediaQuery.of(context).padding.bottom),
              child: Text('KairoAI Admin v1.4', style: adminMeta(c.textMuted)),
            ),
          ],
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
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? c.accentFill : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
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
    (LucideIcons.layoutGrid, 'Home'),
    (LucideIcons.bookOpen, 'Content'),
    (LucideIcons.users, 'Learners'),
    (LucideIcons.barChart2, 'Trends'),
    (LucideIcons.activity, 'Alerts'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 52 + bottomPad,
      decoration: BoxDecoration(
        color: c.bgSurface,
        border: Border(top: BorderSide(color: c.border, width: 0.5)),
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
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? c.accentFill : Colors.transparent,
                    borderRadius: BorderRadius.circular(pillRadius),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 18,
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
