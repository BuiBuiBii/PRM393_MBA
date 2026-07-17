import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

EdgeInsets appScreenPadding(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  final bottom = MediaQuery.paddingOf(context).bottom;
  return EdgeInsets.fromLTRB(width < 400 ? 16 : 20, 12, width < 400 ? 16 : 20, 12 + bottom);
}

bool isCompactPhone(BuildContext context) => MediaQuery.sizeOf(context).width < 400;

class AppColors {
  static const primary = Color(0xFF4F46E5);
  static const surface = Color(0xFFF8FAFC);
  static const slate900 = Color(0xFF0F172A);
  static const slate600 = Color(0xFF475569);
  static const slate500 = Color(0xFF64748B);
  static const emerald = Color(0xFF059669);
  static const amber = Color(0xFFD97706);
  static const cyan = Color(0xFF0891B2);
  static const purple = Color(0xFF7C3AED);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const rose = Color(0xFFE11D48);
  static const blue = Color(0xFF2563EB);
}

class AppGradientBackground extends StatelessWidget {
  const AppGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF0F172A)]
              : const [Color(0xFFF8FAFC), Color(0xFFEEF2FF), Color(0xFFF8FAFC)],
        ),
      ),
      child: child,
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardTheme.color ?? cs.surface;
    final borderColor = context.appBorderColor;
    final content = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );

    if (onTap == null) {
      return Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        child: content,
      );
    }

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      ),
    );
  }
}

enum AppBadgeVariant { info, success, warning, neutral }

class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label, this.variant = AppBadgeVariant.neutral});

  final String label;
  final AppBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    Color bg;
    Color fg;
    switch (variant) {
      case AppBadgeVariant.info:
        bg = isDark ? const Color(0xFF164E63) : const Color(0xFFCFFAFE);
        fg = isDark ? const Color(0xFF67E8F9) : const Color(0xFF0E7490);
      case AppBadgeVariant.success:
        bg = isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5);
        fg = isDark ? const Color(0xFF6EE7B7) : AppColors.emerald;
      case AppBadgeVariant.warning:
        bg = isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7);
        fg = isDark ? const Color(0xFFFCD34D) : AppColors.amber;
      case AppBadgeVariant.neutral:
        bg = isDark ? AppTheme.darkBorder : Colors.grey.shade100;
        fg = isDark ? AppTheme.darkTextSecondary : AppColors.slate600;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.valueColor,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color? valueColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final bg = context.isDarkMode ? iconColor.withValues(alpha: 0.18) : iconBg;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isCompactPhone(context) ? 22 : 26,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                        color: valueColor ?? context.appTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: isCompactPhone(context) ? 24 : 26,
          color: context.appTextPrimary,
          letterSpacing: -0.3,
        );
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: titleStyle),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: TextStyle(color: context.appTextSecondary, height: 1.4)),
        ],
      ],
    );

    if (trailing == null) return titleBlock;

    if (isCompactPhone(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleBlock,
          const SizedBox(height: 12),
          trailing!,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        trailing!,
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, this.subtitle, this.action});

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: context.appTextPrimary)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, textAlign: TextAlign.center, style: TextStyle(color: context.appTextSecondary)),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class BannerMessage extends StatelessWidget {
  const BannerMessage({super.key, required this.message, this.isError = false, this.isWarning = false});

  final String message;
  final bool isError;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    Color bg;
    Color border;
    Color text;
    if (isError) {
      bg = isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2);
      border = isDark ? const Color(0xFF991B1B) : const Color(0xFFFECACA);
      text = isDark ? const Color(0xFFFECACA) : const Color(0xFFB91C1C);
    } else if (isWarning) {
      bg = isDark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB);
      border = isDark ? const Color(0xFF92400E) : const Color(0xFFFDE68A);
      text = isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309);
    } else {
      bg = isDark ? const Color(0xFF164E63) : const Color(0xFFECFEFF);
      border = isDark ? const Color(0xFF0E7490) : const Color(0xFFA5F3FC);
      text = isDark ? const Color(0xFF67E8F9) : const Color(0xFF0E7490);
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Text(message, style: TextStyle(color: text, fontSize: 13)),
    );
  }
}

class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorderColor),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x1A64748B),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: child,
    );
  }
}

class LabeledInput extends StatelessWidget {
  const LabeledInput({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.placeholder,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? placeholder;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.appTextPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(color: context.appTextPrimary),
          decoration: InputDecoration(
            hintText: placeholder,
            prefixIcon: icon != null ? Icon(icon, size: 18, color: context.appTextSecondary) : null,
            filled: true,
            fillColor: Theme.of(context).inputDecorationTheme.fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: context.appBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: context.appBorderColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(label, style: context.appCaptionStyle),
        ),
        Expanded(child: Divider(color: context.appBorderColor)),
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.leading,
    this.loading = false,
    this.outlined = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? leading;
  final bool loading;
  final bool outlined;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)] else if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    final button = outlined
        ? OutlinedButton(onPressed: loading ? null : onPressed, child: child)
        : FilledButton(onPressed: loading ? null : onPressed, child: child);

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
