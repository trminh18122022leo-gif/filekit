import 'package:flutter/material.dart';

enum DeviceType { phone, tablet, desktop }

class R {
  static DeviceType type(BuildContext ctx) {
    final w = MediaQuery.of(ctx).size.shortestSide;
    if (w > 900) return DeviceType.desktop;
    if (w > 600) return DeviceType.tablet;
    return DeviceType.phone;
  }

  static bool isDesktop(BuildContext ctx) => type(ctx) == DeviceType.desktop;
  static bool isTablet(BuildContext ctx) => type(ctx) == DeviceType.tablet;
  static bool isMobile(BuildContext ctx) => type(ctx) == DeviceType.phone;

  // Số cột grid
  static int cols(BuildContext ctx) => switch (type(ctx)) {
        DeviceType.desktop => 6,
        DeviceType.tablet => 4,
        DeviceType.phone => 2,
      };

  // Max width cho Windows (không bị stretched)
  static double maxW(BuildContext ctx) => switch (type(ctx)) {
        DeviceType.desktop => 1100,
        DeviceType.tablet => 900,
        DeviceType.phone => double.infinity,
      };

  // Padding nội dung
  static EdgeInsets padding(BuildContext ctx) => EdgeInsets.symmetric(
        horizontal: isDesktop(ctx) ? 32 : (isTablet(ctx) ? 20 : 16),
        vertical: 16,
      );
}
