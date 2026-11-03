import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class AppDialog {
  static Future<T?> showConfirmation<T>({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'تأكيد',
    String cancelText = 'إلغاء',
    bool isDangerous = false,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        title: Row(
          children: [
            Icon(
              isDangerous ? sc.LucideIcons.triangleAlert : sc.LucideIcons.circleHelp,
              color: isDangerous ? AppColors.error : AppColors.primary,
            ),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(message),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(cancelText),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDangerous ? AppColors.error : AppColors.primary,
                    ),
                    child: Text(confirmText),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<T?> showInfo<T>({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'موافق',
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        title: Row(
          children: [
            const Icon(sc.LucideIcons.info, color: AppColors.info),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(message),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<T?> showSuccess<T>({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'موافق',
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        title: Row(
          children: [
            const Icon(sc.LucideIcons.circleCheck, color: AppColors.success),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(message),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                child: Text(buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<T?> showError<T>({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'موافق',
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        title: Row(
          children: [
            const Icon(sc.LucideIcons.circleAlert, color: AppColors.error),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(message),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                child: Text(buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<T?> showCustom<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              content,
              if (actions != null) ...[
                const SizedBox(height: 24),
                ...actions,
              ],
            ],
          ),
        ),
      ),
    );
  }

  static void showLoading(BuildContext context, {String message = 'جاري التحميل...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        content: SingleChildScrollView(
          child: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }

  static void hideLoading(BuildContext context) {
    Navigator.of(context).pop();
  }
}
