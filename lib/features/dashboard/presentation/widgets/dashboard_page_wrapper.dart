import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class DashboardPageWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  final FloatingActionButton? floatingActionButton;

  const DashboardPageWrapper({
    super.key,
    required this.title,
    required this.child,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      floatingActionButton: floatingActionButton,
    );
  }
}
