import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
        bottom: 24,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.meshBlue,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary900.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (Navigator.canPop(context)) ...[
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.8
                      )
                    ).animate().fadeIn().slideX(begin: -0.1),
                    const SizedBox(height: 4),
                    Row(children: [
                      if (showWsStatus) ...[
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: wsConnected ? const Color(0xFF4ADE80) : Colors.redAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              if (wsConnected) BoxShadow(color: const Color(0xFF4ADE80).withOpacity(0.5), blurRadius: 8, spreadRadius: 1)
                            ]
                          ),
                        ).animate(onPlay: (c) => wsConnected ? c.repeat(reverse: true) : null)
                         .scale(duration: 1.seconds, begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(subtitle,
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500)
                        ),
                      ),
                    ]).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                  ],
                ),
              ),
              if (action != null) ...[const SizedBox(width: 12), action!],
            ],
          ),
        ],
      ),
    );
  }
}
