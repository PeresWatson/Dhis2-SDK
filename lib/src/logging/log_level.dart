/// Log Level Enumeration
/// 
/// Defines the severity levels for SDK logging.
library;

/// Log level severity from most to least verbose.
/// 
/// Levels filter what gets logged:
/// - [verbose] - Everything including detailed traces
/// - [debug] - Debugging info for development
/// - [info] - General operational messages
/// - [warning] - Potential issues that don't stop operation
/// - [error] - Errors that affect functionality
/// - [none] - Disable all logging
enum LogLevel {
  /// Most verbose - includes detailed traces.
  /// 
  /// Use during development for deep debugging.
  verbose(0),

  /// Debug information.
  /// 
  /// Use for development and debugging.
  debug(1),

  /// General information.
  /// 
  /// Use for important operational events.
  info(2),

  /// Potential issues.
  /// 
  /// Something unexpected but not an error.
  warning(3),

  /// Errors that affect functionality.
  /// 
  /// Operation failed but app can continue.
  error(4),

  /// Disable all logging.
  none(5);

  /// Numeric value for comparison.
  final int value;

  const LogLevel(this.value);

  /// Whether this level should log at [other] level.
  /// 
  /// A log entry is shown if its level >= configured level.
  bool shouldLog(LogLevel other) => other.value >= value;
}
