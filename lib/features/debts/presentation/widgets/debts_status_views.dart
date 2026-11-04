import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class DebtsEmptyView extends StatelessWidget {
  final String title;
  final String subtitle;

  const DebtsEmptyView({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = sc.Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(sc.LucideIcons.wallet, size: 40, color: scheme.mutedForeground),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: scheme.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: scheme.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class DebtsErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const DebtsErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = sc.Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              sc.LucideIcons.circleAlert,
              size: 40,
              color: scheme.destructive,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: scheme.mutedForeground),
            ),
            const SizedBox(height: 16),
            sc.Button(
              alignment: Alignment.center,
              style: const sc.ButtonStyle.outline(),
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

class DebtsLoadingView extends StatelessWidget {
  const DebtsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: sc.CircularProgressIndicator());
  }
}
