import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class Logger {
  static Future<File> get _logFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/app_errors.log');
  }

  static Future<void> logError(
    String context,
    dynamic error, [
    StackTrace? stackTrace,
  ]) async {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '''
[$timestamp] ERROR in $context
Error: $error
${stackTrace != null ? 'Stack: $stackTrace' : ''}
---
''';

    // Always print to debug console
    debugPrint('❌ $logMessage');

    // Write to file (only in debug mode, not production)
    if (kDebugMode) {
      try {
        final file = await _logFile;
        await file.writeAsString(
          logMessage,
          mode: FileMode.append,
        );
      } catch (e) {
        debugPrint('Failed to write to log file: $e');
      }
    }
  }

  static Future<void> logInfo(String context, String message) async {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] INFO in $context: $message\n';

    debugPrint('ℹ️ $logMessage');

    if (kDebugMode) {
      try {
        final file = await _logFile;
        await file.writeAsString(
          logMessage,
          mode: FileMode.append,
        );
      } catch (e) {
        debugPrint('Failed to write to log file: $e');
      }
    }
  }

  static Future<String> getLogContents() async {
    try {
      final file = await _logFile;
      if (await file.exists()) {
        return await file.readAsString();
      }
      return 'No logs yet';
    } catch (e) {
      return 'Error reading logs: $e';
    }
  }

  static Future<void> clearLogs() async {
    try {
      final file = await _logFile;
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Failed to clear logs: $e');
    }
  }
}
