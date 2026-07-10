import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppAssets {
  static const logo = 'assets/images/app_icon.svg';
  static const githubIcon = 'assets/images/github_icon.svg';
  static const googleIcon = 'assets/images/google_icon.svg';
}

class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({super.key, this.size = 44, this.withBackground = false});

  final double size;
  final bool withBackground;

  @override
  Widget build(BuildContext context) {
    final logoSize = size * (withBackground ? 0.62 : 0.88);
    final logo = SvgPicture.asset(
      AppAssets.logo,
      width: logoSize,
      height: logoSize,
      fit: BoxFit.contain,
      placeholderBuilder: (_) => Icon(Icons.bolt_rounded, size: logoSize, color: const Color(0xFF863BFF)),
    );

    if (!withBackground) return logo;

    final bg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2E1065)
        : const Color(0xFFF5F0FF);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33863BFF),
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
          colors: [Color(0xFF863BFF), Color(0xFF47BFFF)],
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
