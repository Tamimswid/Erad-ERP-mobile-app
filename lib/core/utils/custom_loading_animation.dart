import 'package:erad/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

class CustomLoadingAnimation extends StatelessWidget {
  const CustomLoadingAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 300,
      width: 300,
      child: Column(
        children: [
          Image.asset(AppAssets.logo),
          Text(
            'تحميل...',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
