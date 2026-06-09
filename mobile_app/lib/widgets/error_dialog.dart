import 'package:flutter/material.dart';
import '../core/utils/error_handler.dart';

/// User-friendly error dialog
class ErrorDialog extends StatelessWidget {
  final String? message;
  final dynamic error;
  final VoidCallback? onRetry;
  final bool showDetails;

  const ErrorDialog({
    super.key,
    this.message,
    this.error,
    this.onRetry,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final errorMessage = message ?? ErrorHandler.getUserMessage(error);

    return AlertDialog(
      icon: const Icon(Icons.error_outline, size: 48, color: Colors.red),
      title: const Text('Error'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(errorMessage),
          if (showDetails && error != null) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('Technical Details'),
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(
                    error.toString(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        if (onRetry != null)
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// Show error dialog helper
void showErrorDialog(
  BuildContext context, {
  String? message,
  dynamic error,
  VoidCallback? onRetry,
  bool showDetails = false,
}) {
  // Log error for debugging
  if (error != null) {
    ErrorHandler.logError(error);
  }

  showDialog(
    context: context,
    builder: (context) => ErrorDialog(
      message: message,
      error: error,
      onRetry: onRetry,
      showDetails: showDetails,
    ),
  );
}

/// Show error snackbar (less intrusive)
void showErrorSnackbar(
  BuildContext context, {
  String? message,
  dynamic error,
  VoidCallback? onRetry,
}) {
  final errorMessage = message ?? ErrorHandler.getUserMessage(error);

  // Log error for debugging
  if (error != null) {
    ErrorHandler.logError(error);
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(errorMessage)),
        ],
      ),
      backgroundColor: Colors.red[700],
      duration: const Duration(seconds: 4),
      action: onRetry != null
          ? SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
    ),
  );
}
