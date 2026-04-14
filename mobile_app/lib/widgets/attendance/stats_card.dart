import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';

class StatsCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final CardColor colorType;
  final String? subtitle;

  const StatsCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.colorType,
    this.subtitle,
  });

  const StatsCard.blue({super.key, required this.label, required this.value, required this.icon, this.subtitle})
      : colorType = CardColor.blue;
  const StatsCard.green({super.key, required this.label, required this.value, required this.icon, this.subtitle})
      : colorType = CardColor.green;
  const StatsCard.purple({super.key, required this.label, required this.value, required this.icon, this.subtitle})
      : colorType = CardColor.purple;
  const StatsCard.orange({super.key, required this.label, required this.value, required this.icon, this.subtitle})
      : colorType = CardColor.orange;
  const StatsCard.red({super.key, required this.label, required this.value, required this.icon, this.subtitle})
      : colorType = CardColor.red;

  @override
  Widget build(BuildContext context) {
    final scheme = _scheme(colorType);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.bgStart, scheme.bgEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: scheme.shadow.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: scheme.iconGradient),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: scheme.shadow.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 16))),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray700, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.gray900)),
          ),
          if (subtitle != null)
            Text(subtitle!, style: TextStyle(fontSize: 10, color: scheme.textColor, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
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
