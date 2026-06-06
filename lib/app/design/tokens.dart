import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Brand and layout tokens for MGold.
abstract final class AppTokens {
  static const Color gold = Color(0xFF00897B);
  static const Color goldDark = Color(0xFF005B4F);
  static const Color goldLight = Color(0xFF4DB6AC);

  // Spacing
  static double get gap4 => 4.h;
  static double get gap8 => 8.h;
  static double get gap12 => 12.h;
  static double get gap16 => 16.h;
  static double get gap20 => 20.h;
  static double get gap24 => 24.h;
  static double get gap32 => 32.h;

  static EdgeInsets get screenPadding =>
      EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h);

  static EdgeInsets get cardPadding => EdgeInsets.all(16.w);

  // Radii
  static double get radiusSm => 8.r;
  static double get radiusMd => 12.r;
  static double get radiusLg => 16.r;
  static double get radiusXl => 20.r;

  static BorderRadius get borderRadiusSm => BorderRadius.circular(radiusSm);
  static BorderRadius get borderRadiusMd => BorderRadius.circular(radiusMd);
  static BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);

  // Icons
  static double get iconSm => 16.sp;
  static double get iconMd => 20.sp;
  static double get iconLg => 24.sp;
  static double get iconXl => 32.sp;
  static double get iconHero => 64.sp;

  // Elevation
  static const double elevationCard = 1;
  static const double elevationRaised = 3;

  // Nav
  static double get navIconSize => 24.sp;
  static double get navLabelSize => 11.sp;

  // Form
  static double get fieldGap => 12.h;
  static double get dialogMaxWidth => 400.w;

  // Grid
  static double get statAspectRatio => 1.55;
  static double get statGridSpacing => 12.w;
}
