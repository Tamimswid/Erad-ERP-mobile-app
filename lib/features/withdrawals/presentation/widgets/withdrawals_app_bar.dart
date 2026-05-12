import 'package:flutter/material.dart';

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
          icon: const Icon(Icons.filter_list),
          onPressed: onFilterPressed,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
