import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/neo_brutal_widgets.dart';

// Export everything from neo_brutal_widgets for convenience
export '../theme/neo_brutal_widgets.dart';

class NeoEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const NeoEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeoPanel(
              color: AppTheme.paperCream,
              padding: const EdgeInsets.all(24),
              child: Icon(icon, size: 64, color: AppTheme.inkBlack),
            ),
            const SizedBox(height: 32),
            Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 24,
                fontFamily: 'Archivo Black',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 32),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
