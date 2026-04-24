import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final double radius;
  final bool showOnlineIndicator;
  final bool isOnline;

  const UserAvatar({
    super.key,
    required this.photoUrl,
    required this.displayName,
    this.radius = 24,
    this.showOnlineIndicator = false,
    this.isOnline = false,
  });

  String get _initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Color _colorFromName() {
    final hash = displayName.codeUnits
        .fold<int>(0, (prev, c) => prev + c) % _palette.length;
    return _palette[hash];
  }

  static const _palette = [
    AppColors.primary,
    Color(0xFFEF5350),
    Color(0xFFEC407A),
    Color(0xFFAB47BC),
    Color(0xFF5C6BC0),
    Color(0xFF26A69A),
    Color(0xFF66BB6A),
    Color(0xFFFF7043),
  ];

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: _colorFromName(),
      child: (photoUrl != null && photoUrl!.isNotEmpty)
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: photoUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                placeholder: (_, __) => Center(
                  child: Text(
                    _initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: radius * 0.7,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Text(
                  _initials,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: radius * 0.7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          : Text(
              _initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.7,
                fontWeight: FontWeight.w600,
              ),
            ),
    );

    if (!showOnlineIndicator) return avatar;

    return Stack(
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: radius * 0.55,
            height: radius * 0.55,
            decoration: BoxDecoration(
              color: isOnline ? Colors.greenAccent.shade400 : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
