import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Vertical gap using ScreenUtil height.
class VGap extends StatelessWidget {
  const VGap(this.size, {super.key});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(height: size.h);
}

/// Horizontal gap using ScreenUtil width.
class HGap extends StatelessWidget {
  const HGap(this.size, {super.key});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(width: size.w);
}

/// Standard screen padding wrapper.
class ScreenPadding extends StatelessWidget {
  const ScreenPadding({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.all(16.w),
      child: child,
    );
  }
}
