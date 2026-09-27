import 'package:flutter/material.dart';

/// Breakpoints and a small builder helper used throughout the presentation
/// layer instead of ad-hoc, screen-specific width checks. Keeping the
/// thresholds in one place is what lets every screen adapt consistently
/// rather than each hardcoding its own numbers.
class Breakpoints {
  const Breakpoints._();

  static const double compact = 600; // phones, portrait
  static const double medium = 905; // phones landscape / small tablets
  // >= medium is treated as an expanded/tablet layout.
}

enum ScreenSize { compact, medium, expanded }

extension ScreenSizeContext on BuildContext {
  ScreenSize get screenSize {
    final width = MediaQuery.sizeOf(this).width;
    if (width < Breakpoints.compact) return ScreenSize.compact;
    if (width < Breakpoints.medium) return ScreenSize.medium;
    return ScreenSize.expanded;
  }

  bool get isCompact => screenSize == ScreenSize.compact;
  bool get isLandscape => MediaQuery.orientationOf(this) == Orientation.landscape;
}

/// Chooses between a narrow/portrait-oriented layout and a wide/landscape
/// or tablet layout using a single [LayoutBuilder], so screens declare
/// *what* each layout looks like without duplicating breakpoint logic.
class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({
    super.key,
    required this.compact,
    required this.expanded,
  });

  final WidgetBuilder compact;

  /// Used for [ScreenSize.medium] and [ScreenSize.expanded].
  final WidgetBuilder expanded;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= Breakpoints.compact;
        return isWide ? expanded(context) : compact(context);
      },
    );
  }
}
