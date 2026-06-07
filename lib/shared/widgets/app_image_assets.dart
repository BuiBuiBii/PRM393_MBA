import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppAssets {
  static const logo = 'assets/images/logo.svg';
  static const githubIcon = 'assets/images/github_icon.svg';
  static const googleIcon = 'assets/images/google_icon.svg';
}

class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({super.key, this.size = 44, this.withBackground = false});

  final double size;
  final bool withBackground;

  @override
  Widget build(BuildContext context) {
    final iconSize = size * (withBackground ? 0.58 : 0.72);
    final iconColor = withBackground ? Colors.white : const Color(0xFF4F46E5);
    final logo = _BrandBoltFallback(size: iconSize, color: iconColor);

    if (!withBackground) return logo;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5),
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x334F46E5),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: logo,
    );
  }
}

class _BrandBoltFallback extends StatelessWidget {
  const _BrandBoltFallback({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _BrandBoltPainter(color),
    );
  }
}

class _BrandBoltPainter extends CustomPainter {
  _BrandBoltPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const viewW = 48.0;
    const viewH = 46.0;
    double sx(double x) => x / viewW * size.width;
    double sy(double y) => y / viewH * size.height;

    final path = Path()
      ..moveTo(sx(25.946), sy(44.938))
      ..cubicTo(sx(25.282), sy(45.783), sx(23.925), sy(45.313), sx(23.925), sy(44.24))
      ..lineTo(sx(23.925), sy(33.937))
      ..cubicTo(sx(21.663), sy(33.937), sx(19.663), sy(31.937), sx(19.663), sy(29.675))
      ..lineTo(sx(10.287), sy(20.299))
      ..cubicTo(sx(9.367), sy(19.379), sx(9.367), sy(17.819), sx(10.287), sy(16.899))
      ..lineTo(sx(17.767), sy(6.428))
      ..cubicTo(sx(18.837), sy(4.931), sx(17.767), sy(2.85), sx(15.925), sy(2.85))
      ..lineTo(sx(1.237), sy(2.85))
      ..cubicTo(sx(0.317), sy(2.85), sx(-0.219), sy(1.81), sx(0.317), sy(0.89))
      ..lineTo(sx(10.013), sy(0.474))
      ..cubicTo(sx(10.227), sy(0.177), sx(10.569), sy(0), sx(10.933), sy(0))
      ..lineTo(sx(39.827), sy(0))
      ..cubicTo(sx(40.747), sy(0), sx(41.283), sy(1.04), sx(40.747), sy(1.96))
      ..lineTo(sx(33.267), sy(12.431))
      ..cubicTo(sx(32.197), sy(13.929), sx(33.267), sy(16.01), sx(35.109), sy(16.01))
      ..lineTo(sx(46.486), sy(16.01))
      ..cubicTo(sx(47.429), sy(16.01), sx(47.959), sy(17.098), sx(47.376), sy(17.84))
      ..lineTo(sx(25.947), sy(44.94))
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon({
    super.key,
    required this.asset,
    this.size = 20,
    this.color,
  });

  final String asset;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 44,
  });

  final String? imageUrl;
  final String? name;
  final double size;

  String get _initials {
    final parts = (name ?? 'U').trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.34,
        ),
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty) return fallback;

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}

class AuthShowcasePanel extends StatelessWidget {
  const AuthShowcasePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF020617), Color(0xFF111827), Color(0xFF172554)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33020617),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppBrandLogo(size: 40, withBackground: true),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GitAnalyzer AI',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Text(
                      'Bảng phân tích dành cho lập trình viên',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _ShowcaseItem(
            icon: Icons.auto_awesome,
            title: 'Phân tích bằng AI',
            description: 'Chấm điểm kiến trúc, tài liệu, quy ước code và mức độ sẵn sàng portfolio.',
          ),
          const SizedBox(height: 10),
          const _ShowcaseItem(
            icon: Icons.trending_up,
            title: 'Định hướng nghề nghiệp',
            description: 'Chuyển khoảng trống kỹ năng thành roadmap tập trung cho vai trò tiếp theo.',
          ),
          const SizedBox(height: 10),
          const _ShowcaseItem(
            icon: Icons.shield_outlined,
            title: 'Kết nối GitHub an toàn',
            description: 'Kết nối repository với luồng quyền minh bạch và rõ ràng.',
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: _StatTile(icon: Icons.bar_chart, value: '82', label: 'Điểm mẫu')),
              SizedBox(width: 8),
              Expanded(child: _StatTile(icon: Icons.folder_copy, value: '5', label: 'Repository')),
              SizedBox(width: 8),
              Expanded(child: _StatTile(icon: Icons.chat_bubble_outline, value: 'AI', label: 'Chat mentor')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShowcaseItem extends StatelessWidget {
  const _ShowcaseItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF67E8F9), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF67E8F9), size: 16),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
        ],
      ),
    );
  }
}
