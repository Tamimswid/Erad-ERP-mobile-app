import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class WithdrawalsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onFilterPressed;

  const WithdrawalsAppBar({
    super.key,
    this.onFilterPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('السحوبات'),
      actions: [
        IconButton(
          icon: const Icon(sc.LucideIcons.filter),
          onPressed: onFilterPressed,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
