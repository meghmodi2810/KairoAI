import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kairo_ai/admin/theme/admin_theme.dart';

enum AdminTopBarVariant { root, sub }

class AdminTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final AdminTopBarVariant variant;
  final Widget? action;
  final String? backLabel;
  final VoidCallback? onBack;
  final VoidCallback? onMenuTap;

  const AdminTopBar({
    super.key,
    required this.title,
    this.variant = AdminTopBarVariant.root,
    this.action,
    this.backLabel,
    this.onBack,
    this.onMenuTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(topBarH + 20);

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    final h = topBarH + 20;
    
    return Container(
      height: h + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: c.bgSurface,
        border: Border(bottom: BorderSide(color: c.border, width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            if (variant == AdminTopBarVariant.root)
              _TopBarButton(
                onTap: onMenuTap,
                child: Icon(LucideIcons.menu, size: 20, color: c.textSecondary),
              )
            else
              GestureDetector(
                onTap: onBack ?? () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.arrowLeft, size: 18, color: c.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      backLabel ?? 'Back',
                      style: adminBody(c.textSecondary).copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title, 
                style: adminH1(c.textPrimary).copyWith(fontSize: 18),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (action != null)
              action!
            else ...[
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c.bgSurface2,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.border),
                ),
                child: Center(
                  child: Text(
                    'AD',
                    style: adminLabel(c.textSecondary),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _TopBarButton({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: topBarH,
        child: Center(child: child),
      ),
    );
  }
}

class AdminTopBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool showBadge;

  const AdminTopBarIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: topBarH,
        child: Center(
          child: Stack(
            children: [
              Icon(icon, size: 20, color: c.textSecondary),
              if (showBadge)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: c.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminTopBarSaveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const AdminTopBarSaveButton({
    super.key,
    this.label = 'Save',
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = ac(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        height: topBarH,
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.accent,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: onTap != null ? c.accent : c.textMuted,
                  ),
                ),
        ),
      ),
    );
  }
}
