import 'package:flutter/material.dart';

import 'app_widgets.dart';

enum AppSnackVariant { info, success, warning, error }

class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context, {
    required String message,
    AppSnackVariant variant = AppSnackVariant.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colors = _variantColors(variant);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: TextStyle(color: colors.$2)),
          backgroundColor: colors.$1,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: actionLabel != null
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: colors.$2,
                  onPressed: onAction ?? () {},
                )
              : null,
        ),
      );
  }

  static (Color, Color) _variantColors(AppSnackVariant variant) {
    switch (variant) {
      case AppSnackVariant.success:
        return (const Color(0xFF065F46), Colors.white);
      case AppSnackVariant.warning:
        return (const Color(0xFFB45309), Colors.white);
      case AppSnackVariant.error:
        return (const Color(0xFFB91C1C), Colors.white);
      case AppSnackVariant.info:
        return (const Color(0xFF0E7490), Colors.white);
    }
  }
}

class AppDialog {
  AppDialog._();

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Xác nhận',
    String cancelLabel = 'Hủy',
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(cancelLabel)),
          if (destructive)
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB91C1C)),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmLabel),
            )
          else
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(confirmLabel)),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<void> alert(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'Đã hiểu',
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(buttonLabel)),
        ],
      ),
    );
  }

  static Future<void> custom(
    BuildContext context, {
    required String title,
    required Widget content,
    List<Widget>? actions,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: content,
        actions: actions ??
            [
              PrimaryButton(
                label: 'Đóng',
                outlined: true,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
      ),
    );
  }
}
