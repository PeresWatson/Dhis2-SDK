/// SDK Logger
/// 
/// Provides structured logging for the SDK with configurable
/// output levels and formatting.
/// 
/// ## Purpose
/// 
/// - Consistent log output across SDK
/// - Configurable verbosity
/// - Structured log entries
/// - Easy filtering and searching
/// - Support for external log handlers
/// 
/// ## Data Flow
/// 
/// ```
/// SDK Component → SdkLogger → LogOutput (console/file/external)
/// ```
/// 
/// ## Extension Points
/// 
/// - Add custom LogOutput implementations
/// - Filter logs by tag or level
/// - Forward logs to analytics services
library;

import 'package:logger/logger.dart' as pkg;
import 'log_level.dart';

/// Callback type for external log handling.
typedef LogCallback = void Function(
  LogLevel level,
  String message,
  String? tag,
  Object? error,
  StackTrace? stackTrace,
);

/// SDK Logger with structured output.
/// 
/// Example:
/// ```dart
/// final logger = SdkLogger(
///   level: LogLevel.debug,
///   tag: 'MyService',
/// );
/// 
/// logger.debug('Processing request', {'id': '123'});
/// logger.error('Request failed', error, stackTrace);
/// ```
class SdkLogger {
  /// Current log level threshold.
  final LogLevel level;

  /// Tag prefix for log messages.
  final String? tag;

  /// External callback for log entries.
  final LogCallback? onLog;

  /// Internal logger instance.
  final pkg.Logger _logger;

  /// Creates a new SDK logger.
  /// 
  /// [level] - Minimum level to log.
  /// [tag] - Optional tag prefix for messages.
  /// [onLog] - Optional callback for external log handling.
  SdkLogger({
    this.level = LogLevel.info,
    this.tag,
    this.onLog,
  }) : _logger = pkg.Logger(
          filter: _SdkLogFilter(level),
          printer: pkg.PrettyPrinter(
            methodCount: 0,
            errorMethodCount: 5,
            lineLength: 80,
            colors: true,
            printEmojis: true,
            dateTimeFormat: pkg.DateTimeFormat.onlyTimeAndSinceStart,
          ),
          output: null,
        );

  /// Creates a child logger with a new tag.
  /// 
  /// Useful for creating service-specific loggers.
  SdkLogger withTag(String newTag) {
    return SdkLogger(
      level: level,
      tag: tag != null ? '$tag.$newTag' : newTag,
      onLog: onLog,
    );
  }

  /// Formats the message with optional tag.
  String _formatMessage(String message) {
    if (tag != null) {
      return '[$tag] $message';
    }
    return message;
  }

  /// Logs a verbose message.
  /// 
  /// Use for detailed traces during development.
  void verbose(String message, [Object? data]) {
    if (!level.shouldLog(LogLevel.verbose)) return;

    final formatted = _formatMessage(message);
    _logger.t(data != null ? '$formatted: $data' : formatted);
    onLog?.call(LogLevel.verbose, formatted, tag, data, null);
  }

  /// Logs a debug message.
  /// 
  /// Use for development and debugging information.
  void debug(String message, [Object? data]) {
    if (!level.shouldLog(LogLevel.debug)) return;

    final formatted = _formatMessage(message);
    _logger.d(data != null ? '$formatted: $data' : formatted);
    onLog?.call(LogLevel.debug, formatted, tag, data, null);
  }

  /// Logs an info message.
  /// 
  /// Use for important operational events.
  void info(String message, [Object? data]) {
    if (!level.shouldLog(LogLevel.info)) return;

    final formatted = _formatMessage(message);
    _logger.i(data != null ? '$formatted: $data' : formatted);
    onLog?.call(LogLevel.info, formatted, tag, data, null);
  }

  /// Logs a warning message.
  /// 
  /// Use for potential issues that don't stop operation.
  void warning(String message, [Object? data]) {
    if (!level.shouldLog(LogLevel.warning)) return;

    final formatted = _formatMessage(message);
    _logger.w(data != null ? '$formatted: $data' : formatted);
    onLog?.call(LogLevel.warning, formatted, tag, data, null);
  }

  /// Logs an error message.
  /// 
  /// Use for errors that affect functionality.
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (!level.shouldLog(LogLevel.error)) return;

    final formatted = _formatMessage(message);
    _logger.e(formatted, error: error, stackTrace: stackTrace);
    onLog?.call(LogLevel.error, formatted, tag, error, stackTrace);
  }

  /// Logs an API request.
  /// 
  /// Convenience method for HTTP request logging.
  void logRequest(String method, String url, [Map<String, dynamic>? headers]) {
    debug('→ $method $url', headers);
  }

  /// Logs an API response.
  /// 
  /// Convenience method for HTTP response logging.
  void logResponse(
    String method,
    String url,
    int statusCode,
    Duration duration,
  ) {
    final emoji = statusCode >= 400 ? '✗' : '✓';
    debug('$emoji $method $url ($statusCode) - ${duration.inMilliseconds}ms');
  }
}

/// Custom log filter based on SDK log level.
class _SdkLogFilter extends pkg.LogFilter {
  final LogLevel sdkLevel;

  _SdkLogFilter(this.sdkLevel);

  @override
  bool shouldLog(pkg.LogEvent event) {
    final eventLevel = switch (event.level) {
      pkg.Level.trace => LogLevel.verbose,
      pkg.Level.debug => LogLevel.debug,
      pkg.Level.info => LogLevel.info,
      pkg.Level.warning => LogLevel.warning,
      pkg.Level.error || pkg.Level.fatal => LogLevel.error,
      _ => LogLevel.none,
    };
    return sdkLevel.shouldLog(eventLevel);
  }
}

/// Extension for easy logger creation in services.
extension SdkLoggerExtension on String {
  /// Creates a logger with this string as the tag.
  SdkLogger toLogger([LogLevel level = LogLevel.info]) {
    return SdkLogger(level: level, tag: this);
  }
}
