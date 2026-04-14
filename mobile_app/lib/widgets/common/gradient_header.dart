import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';

class GradientHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;
  final bool showWsStatus;
  final bool wsConnected;

  const GradientHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
    this.showWsStatus = false,
    this.wsConnected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.headerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3)),
                const SizedBox(height: 4),
                Row(children: [
                  if (showWsStatus) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: wsConnected ? const Color(0xFF4ADE80) : Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(wsConnected ? 'Connected' : 'Disconnected',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: Text(subtitle,
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                ]),
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 12), action!],
        ],
      ),
    );
  }
}
