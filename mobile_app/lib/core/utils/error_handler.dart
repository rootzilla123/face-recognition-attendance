import 'package:flutter/foundation.dart';

/// Centralized error handling with user-friendly messages
class ErrorHandler {
  /// Convert technical errors to user-friendly messages
  static String getUserMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Connection errors
    if (errorString.contains('socketexception') ||
        errorString.contains('connection refused') ||
        errorString.contains('failed host lookup')) {
      return 'Unable to connect to server. Please check your internet connection.';
    }

    // Timeout errors
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    // Authentication errors
    if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return 'Session expired. Please log in again.';
    }

    // Permission errors
    if (errorString.contains('forbidden') || errorString.contains('403')) {
      return 'You don\'t have permission to perform this action.';
    }

    // Not found errors
    if (errorString.contains('not found') || errorString.contains('404')) {
      return 'The requested resource was not found.';
    }

    // Server errors
    if (errorString.contains('500') || errorString.contains('internal server')) {
      return 'Server error. Please try again later.';
    }

    // Database errors (hide technical details)
    if (errorString.contains('psycopg2') ||
        errorString.contains('sql') ||
        errorString.contains('database')) {
      return 'A database error occurred. Please contact support if this persists.';
    }

    // Format errors
    if (errorString.contains('format') || errorString.contains('parse')) {
      return 'Invalid data format. Please try again.';
    }

    // Generic fallback
    return 'An unexpected error occurred. Please try again.';
  }

  /// Log error for debugging (only in debug mode)
  static void logError(dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('ERROR: $error');
      if (stackTrace != null) {
        debugPrint('STACK TRACE:\n$stackTrace');
      }
      debugPrint('═══════════════════════════════════════');
    }
    // TODO: Send to error tracking service (Sentry, Firebase Crashlytics, etc.)
  }

  /// Check if error is a network error
  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socket') ||
        errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('timeout');
  }

  /// Check if error requires re-authentication
  static bool requiresReauth(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('unauthorized') ||
        errorString.contains('401') ||
        errorString.contains('token') ||
        errorString.contains('session');
  }
}
