import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class DebtDetailHeader extends StatelessWidget {
  final String name;
  final String? phone;
  final VoidCallback onPdf;
  final bool isGeneratingPdf;

  const DebtDetailHeader({
    super.key,
    required this.name,
    required this.phone,
    required this.onPdf,
    this.isGeneratingPdf = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = sc.Theme.of(context);
    final scheme = theme.colorScheme;
    final initial = name.trim().isEmpty ? '؟' : name.trim().substring(0, 1);
    final hasPhone = (phone ?? '').trim().isNotEmpty;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.muted,
            borderRadius: theme.borderRadiusMd,
          ),
          child: Text(
            initial,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: scheme.foreground,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: scheme.foreground,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    sc.LucideIcons.phone,
                    size: 12,
                    color: scheme.mutedForeground,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      hasPhone ? phone! : 'بدون رقم',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.mutedForeground,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        sc.Button(
          alignment: Alignment.center,
          style: const sc.ButtonStyle.outline(),
          onPressed: isGeneratingPdf ? null : onPdf,
          leading: const Icon(sc.LucideIcons.fileText, size: 16),
          child: const Text('PDF', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
