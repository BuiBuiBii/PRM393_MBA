import 'package:flutter/material.dart';

/// Khoảng cách & breakpoint dùng chung (tiêu chí responsive).
class AppSizes {
  AppSizes._();

  static const double screenPadding = 16;
  static const double screenPaddingCompact = 12;
  static const double cardRadius = 12;
  static const double buttonHeight = 48;
  static const double compactPhoneWidth = 400;

  static EdgeInsets screenInsets(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < compactPhoneWidth ? screenPaddingCompact : screenPadding;
    return EdgeInsets.symmetric(horizontal: horizontal);
  }

  static bool isCompactPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactPhoneWidth;
}
