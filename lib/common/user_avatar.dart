import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../resource/app_colors.dart';
import '../resource/app_text.dart';

/// No image storage yet, so an avatar is the first letter of the name on a color
/// picked from the user id (the same person always gets the same color).
class UserAvatar extends StatelessWidget {
  final String userId;
  final String name;
  final double size;

  const UserAvatar({
    super.key,
    required this.userId,
    required this.name,
    this.size = 40,
  });

  static const _colors = [
    Color(0xFF2F80ED),
    Color(0xFF27AE60),
    Color(0xFFEB5757),
    Color(0xFFF2994A),
    Color(0xFF9B51E0),
    Color(0xFF00A3A3),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[userId.hashCode.abs() % _colors.length];
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: size.r / 2,
      backgroundColor: color,
      child: Text(
        letter,
        style: AppText.bold(size: size * 0.42, color: AppColors.white),
      ),
    );
  }
}
