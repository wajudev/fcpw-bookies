import 'package:flutter/foundation.dart';
import 'logger.dart';

class AppException implements Exception {
  final String message;
  final String? technicalDetails;

  AppException(this.message, {this.technicalDetails});

  @override
  String toString() => message;
}

class ValidationException extends AppException {
  ValidationException(super.message);
}

class NetworkException extends AppException {
  NetworkException() : super('No internet connection. Please check your network and try again.');
}

class PermissionException extends AppException {
  PermissionException(super.message);
}

class NotFoundException extends AppException {
  NotFoundException(super.message);
}

class ErrorHandler {
  static String getUserMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }

    // Parse Supabase errors
    final errorStr = error.toString().toLowerCase();

    // Network errors
    if (errorStr.contains('socket') ||
        errorStr.contains('network') ||
        errorStr.contains('connection') ||
        errorStr.contains('timeout')) {
      return 'No internet connection. Please check your network.';
    }

    // Permission errors (RLS)
    if (errorStr.contains('permission') ||
        errorStr.contains('42501') ||
        errorStr.contains('forbidden')) {

      // Specific permission cases
      if (errorStr.contains('prediction') || errorStr.contains('tipp')) {
        return 'Prediction locked (2 hours before kickoff)';
      }

      if (errorStr.contains('golden_boot') || errorStr.contains('boot')) {
        return 'Golden boot selection is locked (season started)';
      }

      return 'You don\'t have permission for this action';
    }

    // Unique constraint (duplicate)
    if (errorStr.contains('unique') || errorStr.contains('23505')) {
      return 'This already exists. Please try a different value.';
    }

    // Not found
    if (errorStr.contains('not found') || errorStr.contains('404')) {
      return 'Item not found';
    }

    // Auth errors
    if (errorStr.contains('invalid_grant') ||
        errorStr.contains('invalid credentials')) {
      return 'Invalid email or password';
    }

    if (errorStr.contains('email') && errorStr.contains('already')) {
      return 'This email is already registered';
    }

    // Generic fallback
    return 'Something went wrong. Please try again.';
  }

  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    // Log to file + console
    Logger.logError(context, error, stackTrace);
  }

  static AppException parse(dynamic error) {
    final message = getUserMessage(error);

    if (message.contains('internet') || message.contains('network')) {
      return NetworkException();
    }

    if (message.contains('permission') || message.contains('locked')) {
      return PermissionException(message);
    }

    if (message.contains('not found')) {
      return NotFoundException(message);
    }

    return AppException(message, technicalDetails: error.toString());
  }
}
