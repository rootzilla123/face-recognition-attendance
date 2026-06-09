import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/utils/app_theme.dart';

class StatsCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final CardColor colorType;
  final String? subtitle;
  final int index; // For staggered animations

  const StatsCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.colorType,
    this.subtitle,
    this.index = 0,
  });

  const StatsCard.blue({super.key, required this.label, required this.value, required this.icon, this.subtitle, this.index = 0})
      : colorType = CardColor.blue;
  const StatsCard.green({super.key, required this.label, required this.value, required this.icon, this.subtitle, this.index = 0})
      : colorType = CardColor.green;
  const StatsCard.purple({super.key, required this.label, required this.value, required this.icon, this.subtitle, this.index = 0})
      : colorType = CardColor.purple;
  const StatsCard.orange({super.key, required this.label, required this.value, required this.icon, this.subtitle, this.index = 0})
      : colorType = CardColor.orange;
  const StatsCard.red({super.key, required this.label, required this.value, required this.icon, this.subtitle, this.index = 0})
      : colorType = CardColor.red;

  @override
  Widget build(BuildContext context) {
    final scheme = _scheme(colorType);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.premiumShadow,
      ),
      child: Stack(
        children: [
          // Background accent
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: scheme.shadow.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: scheme.iconGradient),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: scheme.shadow.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
                  ),
                  Icon(Icons.more_horiz, color: AppColors.gray300, size: 18),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, 
                    style: const TextStyle(fontSize: 11, color: AppColors.gray500, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value, 
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.gray900, letterSpacing: -0.5)),
                  ),
                  if (subtitle != null)
                    Text(subtitle!, 
                      style: TextStyle(fontSize: 10, color: scheme.textColor, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate()
     .fadeIn(delay: (100 * index).ms, duration: 400.ms)
     .slideY(begin: 0.1, delay: (100 * index).ms, duration: 400.ms, curve: Curves.easeOutQuad);
  }

  _ColorScheme _scheme(CardColor c) {
    switch (c) {
      case CardColor.blue:
        return _ColorScheme(
          bgStart: AppColors.primary50, bgEnd: const Color(0xFFECFEFF),
          iconGradient: AppColors.blueGradient,
          shadow: AppColors.primary500, textColor: AppColors.primary700,
        );
      case CardColor.green:
        return _ColorScheme(
          bgStart: AppColors.success50, bgEnd: const Color(0xFFECFDF5),
          iconGradient: AppColors.greenGradient,
          shadow: AppColors.success500, textColor: AppColors.success700,
        );
      case CardColor.purple:
        return _ColorScheme(
          bgStart: const Color(0xFFFAF5FF), bgEnd: const Color(0xFFFDF4FF),
          iconGradient: AppColors.purpleGradient,
          shadow: AppColors.secondary500, textColor: AppColors.secondary700,
        );
      case CardColor.orange:
        return _ColorScheme(
          bgStart: AppColors.warning50, bgEnd: const Color(0xFFFFF7ED),
          iconGradient: AppColors.orangeGradient,
          shadow: AppColors.orange500, textColor: AppColors.orange700,
        );
      case CardColor.red:
        return _ColorScheme(
          bgStart: AppColors.error50, bgEnd: const Color(0xFFFFF1F2),
          iconGradient: [AppColors.error700, AppColors.error500, const Color(0xFFEF4444)],
          shadow: AppColors.error500, textColor: AppColors.error700,
        );
    }
  }
}

enum CardColor { blue, green, purple, orange, red }

class _ColorScheme {
  final Color bgStart, bgEnd, shadow, textColor;
  final List<Color> iconGradient;
  const _ColorScheme({required this.bgStart, required this.bgEnd, required this.iconGradient, required this.shadow, required this.textColor});
}
