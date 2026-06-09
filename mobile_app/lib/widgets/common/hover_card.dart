import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';

/// Card with hover effect for desktop
class HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  const HoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Only enable hover on desktop
    if (!Responsive.isDesktop(context) || !widget.enabled) {
      return GestureDetector(
        onTap: widget.onTap,
        child: widget.child,
      );
    }

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..scale(_isHovered ? 1.02 : 1.0),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isHovered ? 0.95 : 1.0,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
