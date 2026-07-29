import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            name.isNotEmpty ? name[0] : '?',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: phone != null ? Text(phone!) : null,
        trailing: const Icon(Iconsax.arrow_left),
        onTap: onTap,
      ),
    );
  }
}
