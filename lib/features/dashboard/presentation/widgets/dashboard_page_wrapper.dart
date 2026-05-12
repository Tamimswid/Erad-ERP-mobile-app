import 'package:flutter/material.dart';

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
      backgroundColor: const Color(0xFFF5F7FA),
      body: child,
      floatingActionButton: floatingActionButton,
    );
  }
}
