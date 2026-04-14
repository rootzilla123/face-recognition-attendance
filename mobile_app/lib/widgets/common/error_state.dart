import 'package:flutter/material.dart';
import '../../core/utils/app_theme.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.error100,
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Icon(Icons.wifi_off_rounded, color: AppColors.error500, size: 36),
            ),
            const SizedBox(height: 16),
            const Text("Can't connect to server", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: AppColors.gray500, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({super.key, required this.emoji, required this.title, required this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray800)),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: AppColors.gray500, fontSize: 13), textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}
