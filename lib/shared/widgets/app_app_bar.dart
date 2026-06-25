import 'package:flutter/material.dart';

import 'app_image_assets.dart';
import 'app_widgets.dart';
import '../../core/theme/app_theme.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.centerTitle = false,
    this.showBrand = true,
    this.brandLabel = 'GitAnalyzer',
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool centerTitle;
  final bool showBrand;
  final String brandLabel;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = foregroundColor ?? context.appTextPrimary;
    final bg = backgroundColor ?? theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface;

    Widget? titleWidget;
    if (showBrand) {
      titleWidget = Row(
        children: [
          const AppBrandLogo(size: 28, withBackground: true),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppColors.primary, AppColors.purple],
                  ).createShader(bounds),
                  child: Text(
                    brandLabel,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: context.appTextSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      );
    } else if (subtitle != null) {
      titleWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fg)),
          Text(
            subtitle!,
            style: TextStyle(fontSize: 11, color: context.appTextSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    } else {
      titleWidget = Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fg));
    }

    return AppBar(
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      leading: leading,
      title: titleWidget,
      actions: actions,
    );
  }
}
