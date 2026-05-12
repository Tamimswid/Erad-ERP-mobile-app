import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class HeaderWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const HeaderWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return         Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        );
  }
}
