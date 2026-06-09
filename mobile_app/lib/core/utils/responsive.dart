import 'package:flutter/material.dart';

/// Responsive breakpoints and utilities for adaptive UI
class Responsive {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Check if current screen is mobile size
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  /// Check if current screen is tablet size
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;

  /// Check if current screen is desktop size
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  /// Get responsive value based on screen size
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  /// Get responsive padding
  static EdgeInsets padding(BuildContext context) {
    return EdgeInsets.all(isMobile(context) ? 16 : 24);
  }

  /// Get responsive spacing
  static double spacing(BuildContext context, {double mobile = 16, double desktop = 24}) {
    return isMobile(context) ? mobile : desktop;
  }

  /// Get responsive font scale
  static double fontScale(BuildContext context) {
    return isDesktop(context) ? 1.1 : 1.0;
  }

  /// Get responsive grid columns
  static int gridColumns(BuildContext context) {
    if (isDesktop(context)) return 4;
    if (isTablet(context)) return 2;
    return 1;
  }

  /// Get responsive font size
  static double fontSize(BuildContext context, double base) {
    return base * (isDesktop(context) ? 1.2 : 1.0);
  }

  /// Get responsive card size
  static double cardHeight(BuildContext context) {
    return isDesktop(context) ? 150 : 120;
  }

  /// Get responsive max width for content
  static double maxContentWidth(BuildContext context) {
    if (isMobile(context)) return 600;
    return double.infinity; // No limit on desktop
  }
}

/// Responsive widget that adapts to screen size
class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) return desktop;
    if (Responsive.isTablet(context)) return tablet ?? mobile;
    return mobile;
  }
}
