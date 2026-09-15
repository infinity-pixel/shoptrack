import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/theme/theme_presets.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.photo,
    this.googlePhoto,
    this.radius = 34,
  });
  final String name;
  final Uint8List? photo;
  final String? googlePhoto;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final p = ShopTrackThemeTokens.of(context).palette;
    final ImageProvider? provider = photo != null
        ? MemoryImage(photo!)
        : googlePhoto?.isNotEmpty == true
        ? NetworkImage(googlePhoto!)
        : null;
    return CircleAvatar(
      radius: radius,
      backgroundColor: p.primary.withValues(alpha: .18),
      foregroundImage: provider,
      onForegroundImageError: provider == null ? null : (_, _) {},
      child: Text(
        name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase(),
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: p.onSurface,
        ),
      ),
    );
  }
}
