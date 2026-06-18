import 'package:flutter/material.dart';

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
}

class AppGradientBackground extends StatelessWidget {
  const AppGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFEEF2FF), Color(0xFFF8FAFC)],
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
    final content = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );

    if (onTap == null) {
      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: content,
      );
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      ),
    );
  }
}

class GithubMarkIcon extends StatelessWidget {
  const GithubMarkIcon({super.key, this.size = 24, this.color = Colors.black});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GithubMarkPainter(color),
    );
  }
}

class _GithubMarkPainter extends CustomPainter {
  _GithubMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.04)
      ..cubicTo(size.width * 0.28, size.height * 0.04, size.width * 0.04, size.height * 0.24, size.width * 0.04, size.height * 0.5)
      ..cubicTo(size.width * 0.04, size.height * 0.7, size.width * 0.16, size.height * 0.87, size.width * 0.34, size.height * 0.94)
      ..lineTo(size.width * 0.34, size.height * 0.82)
      ..cubicTo(size.width * 0.3, size.height * 0.8, size.width * 0.28, size.height * 0.76, size.width * 0.28, size.height * 0.72)
      ..cubicTo(size.width * 0.28, size.height * 0.7, size.width * 0.29, size.height * 0.68, size.width * 0.3, size.height * 0.66)
      ..cubicTo(size.width * 0.22, size.height * 0.64, size.width * 0.16, size.height * 0.58, size.width * 0.16, size.height * 0.5)
      ..cubicTo(size.width * 0.16, size.height * 0.44, size.width * 0.18, size.height * 0.4, size.width * 0.22, size.height * 0.36)
      ..cubicTo(size.width * 0.2, size.height * 0.3, size.width * 0.2, size.height * 0.22, size.width * 0.22, size.height * 0.16)
      ..cubicTo(size.width * 0.28, size.height * 0.18, size.width * 0.34, size.height * 0.2, size.width * 0.4, size.height * 0.2)
      ..cubicTo(size.width * 0.44, size.height * 0.14, size.width * 0.52, size.height * 0.1, size.width * 0.6, size.height * 0.1)
      ..cubicTo(size.width * 0.66, size.height * 0.1, size.width * 0.72, size.height * 0.12, size.width * 0.76, size.height * 0.16)
      ..cubicTo(size.width * 0.82, size.height * 0.14, size.width * 0.88, size.height * 0.12, size.width * 0.94, size.height * 0.1)
      ..cubicTo(size.width * 0.96, size.height * 0.16, size.width * 0.96, size.height * 0.22, size.width * 0.94, size.height * 0.28)
      ..cubicTo(size.width * 0.98, size.height * 0.32, size.width, size.height * 0.38, size.width, size.height * 0.44)
      ..cubicTo(size.width, size.height * 0.52, size.width * 0.96, size.height * 0.58, size.width * 0.9, size.height * 0.62)
      ..cubicTo(size.width * 0.92, size.height * 0.66, size.width * 0.92, size.height * 0.7, size.width * 0.92, size.height * 0.72)
      ..cubicTo(size.width * 0.92, size.height * 0.76, size.width * 0.9, size.height * 0.8, size.width * 0.86, size.height * 0.82)
      ..lineTo(size.width * 0.86, size.height * 0.94)
      ..cubicTo(size.width * 0.94, size.height * 0.91, size.width, size.height * 0.84, size.width, size.height * 0.76)
      ..cubicTo(size.width, size.height * 0.7, size.width * 0.98, size.height * 0.64, size.width * 0.94, size.height * 0.6)
      ..cubicTo(size.width * 0.98, size.height * 0.54, size.width, size.height * 0.48, size.width, size.height * 0.42)
      ..cubicTo(size.width, size.height * 0.22, size.width * 0.78, size.height * 0.04, size.width * 0.5, size.height * 0.04)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum AppBadgeVariant { info, success, warning, neutral }

class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label, this.variant = AppBadgeVariant.neutral});

  final String label;
  final AppBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (variant) {
      case AppBadgeVariant.info:
        bg = const Color(0xFFCFFAFE);
        fg = const Color(0xFF0E7490);
      case AppBadgeVariant.success:
        bg = const Color(0xFFD1FAE5);
        fg = AppColors.emerald;
      case AppBadgeVariant.warning:
        bg = const Color(0xFFFEF3C7);
        fg = AppColors.amber;
      case AppBadgeVariant.neutral:
        bg = Colors.grey.shade100;
        fg = AppColors.slate600;
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
                    Text(label, style: const TextStyle(color: AppColors.slate500, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isCompactPhone(context) ? 22 : 26,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                        color: valueColor ?? AppColors.slate900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, style: const TextStyle(color: AppColors.slate500, fontSize: 12)),
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
          fontSize: isCompactPhone(context) ? 22 : null,
        );
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: titleStyle),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: const TextStyle(color: AppColors.slate500, height: 1.4)),
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.slate500)),
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
    Color bg;
    Color border;
    Color text;
    if (isError) {
      bg = const Color(0xFFFEF2F2);
      border = const Color(0xFFFECACA);
      text = const Color(0xFFB91C1C);
    } else if (isWarning) {
      bg = const Color(0xFFFFFBEB);
      border = const Color(0xFFFDE68A);
      text = const Color(0xFFB45309);
    } else {
      bg = const Color(0xFFECFEFF);
      border = const Color(0xFFA5F3FC);
      text = const Color(0xFF0E7490);
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.8)),
        boxShadow: const [
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: placeholder,
            prefixIcon: icon != null ? Icon(icon, size: 18, color: AppColors.slate500) : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
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
        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.slate500)),
        ),
        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
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
