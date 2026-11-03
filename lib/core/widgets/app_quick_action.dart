import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class AppQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const AppQuickAction({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = sc.Theme.of(context);
    final scheme = theme.colorScheme;
    final isEnabled = onTap != null;

    return sc.Clickable(
      enabled: isEnabled,
      onPressed: onTap,
      child: Opacity(
        opacity: isEnabled ? 1 : 0.45,
        child: sc.Card(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          borderColor: scheme.border,
          borderRadius: theme.borderRadiusLg,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.muted,
                  borderRadius: theme.borderRadiusMd,
                ),
                child: Icon(icon, size: 20, color: scheme.foreground),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.foreground,
                    height: 1.3,
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
