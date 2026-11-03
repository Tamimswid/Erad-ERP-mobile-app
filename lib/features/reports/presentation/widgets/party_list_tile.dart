import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../../../../core/constants/app_constants.dart';

class PartyListTile extends StatelessWidget {
  final String name;
  final String? phone;
  final VoidCallback onTap;

  const PartyListTile({
    super.key,
    required this.name,
    this.phone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: sc.Card(
        padding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppColors.muted,
              child: Text(
                name.isNotEmpty ? name[0] : '?',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: phone != null ? Text(phone!) : null,
            trailing: const Icon(sc.LucideIcons.arrowLeft),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
