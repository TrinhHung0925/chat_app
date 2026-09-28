import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_colors.dart';

abstract class AppText {
  static TextStyle regular({double size = 14, Color color = AppColors.textPrimary}) =>
      TextStyle(fontSize: size.sp, fontWeight: FontWeight.w400, color: color);

  static TextStyle medium({double size = 14, Color color = AppColors.textPrimary}) =>
      TextStyle(fontSize: size.sp, fontWeight: FontWeight.w500, color: color);

  static TextStyle bold({double size = 14, Color color = AppColors.textPrimary}) =>
      TextStyle(fontSize: size.sp, fontWeight: FontWeight.w700, color: color);
}
