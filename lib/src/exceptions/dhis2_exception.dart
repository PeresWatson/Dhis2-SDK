/// DHIS2 Exception Hierarchy
/// 
/// Provides a structured exception system for the SDK.
/// 
/// ## Purpose
/// 
/// - Type-safe error handling
/// - Consistent error information
/// - Easy error categorization
/// - Debuggable error messages
/// 
/// ## Exception Hierarchy
/// 
/// ```
/// Dhis2Exception (base)
/// ├── AuthException
/// ├── NetworkException
/// ├── CacheException
/// ├── ValidationException
/// └── ApiException
/// ```
/// 
/// ## Best Practices
/// 
/// - Catch specific exception types when possible
/// - Use Result type for expected failures
/// - Let unexpected exceptions propagate
/// - Log exceptions with context
library;

import 'package:equatable/equatable.dart';

/// Base exception class for all SDK exceptions.
/// 
/// All SDK exceptions extend this class, allowing:
/// - Catching all SDK errors with one type
/// - Consistent error message format
/// - Stack trace preservation
/// - Error codes for programmatic handling
/// 
/// Example:
/// ```dart
/// try {
///   await sdk.analytics.query(...);
/// } on Dhis2Exception catch (e) {
///   logger.error('SDK error: ${e.message}', e.code);
/// }
/// ```
class Dhis2Exception extends Equatable implements Exception {
  /// Human-readable error message.
  final String message;

  /// Error code for programmatic handling.
  /// 
  /// Format: 'CATEGORY_SPECIFIC_ERROR'
  /// Example: 'AUTH_INVALID_CREDENTIALS'
  final String code;

  /// Original error that caused this exception, if any.
  final Object? cause;

  /// Stack trace from the original error.
  final StackTrace? stackTrace;

  /// Additional context for debugging.
  final Map<String, dynamic>? context;

  /// Creates a new DHIS2 exception.
  const Dhis2Exception({
    required this.message,
    required this.code,
    this.cause,
    this.stackTrace,
    this.context,
  });

  /// Creates an exception from a generic error.
  /// 
  /// Useful for wrapping unknown exceptions.
  factory Dhis2Exception.fromError(Object error, [StackTrace? trace]) {
    if (error is Dhis2Exception) {
      return error;
    }
    return Dhis2Exception(
      message: error.toString(),
      code: 'UNKNOWN_ERROR',
      cause: error,
      stackTrace: trace,
    );
  }

  @override
  List<Object?> get props => [message, code, cause];

  @override
  String toString() => 'Dhis2Exception[$code]: $message';

  /// Returns a detailed string for logging.
  String toDetailedString() {
    final buffer = StringBuffer()
      ..writeln('Dhis2Exception[$code]')
      ..writeln('Message: $message');

    if (context != null && context!.isNotEmpty) {
      buffer.writeln('Context: $context');
    }

    if (cause != null) {
      buffer.writeln('Cause: $cause');
    }

    if (stackTrace != null) {
      buffer.writeln('Stack Trace:');
      buffer.writeln(stackTrace);
    }

    return buffer.toString();
  }
}

/// Exception for validation errors.
/// 
/// Thrown when input validation fails before making API calls.
class ValidationException extends Dhis2Exception {
  /// The field that failed validation.
  final String? field;

  /// The invalid value.
  final dynamic invalidValue;

  const ValidationException({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    this.field,
    this.invalidValue,
    super.context,
  });

  /// Creates a required field exception.
  factory ValidationException.requiredField(String fieldName) {
    return ValidationException(
      message: '$fieldName is required',
      code: 'VALIDATION_REQUIRED_FIELD',
      field: fieldName,
    );
  }

  /// Creates an invalid format exception.
  factory ValidationException.invalidFormat(
    String fieldName,
    String expectedFormat,
  ) {
    return ValidationException(
      message: '$fieldName has invalid format. Expected: $expectedFormat',
      code: 'VALIDATION_INVALID_FORMAT',
      field: fieldName,
    );
  }

  /// Creates an invalid value exception.
  factory ValidationException.invalidValue(
    String fieldName,
    dynamic value,
    String reason,
  ) {
    return ValidationException(
      message: '$fieldName has invalid value: $reason',
      code: 'VALIDATION_INVALID_VALUE',
      field: fieldName,
      invalidValue: value,
    );
  }

  @override
  String toString() => 'ValidationException[$code]: $message (field: $field)';
}

/// Exception for API errors.
/// 
/// Thrown when the DHIS2 API returns an error response.
class ApiException extends Dhis2Exception {
  /// HTTP status code from the response.
  final int? statusCode;

  /// Error response body from the API.
  final Map<String, dynamic>? responseBody;

  /// The API endpoint that failed.
  final String? endpoint;

  const ApiException({
    required super.message,
    super.code = 'API_ERROR',
    this.statusCode,
    this.responseBody,
    this.endpoint,
    super.cause,
    super.stackTrace,
    super.context,
  });

  /// Creates an exception from HTTP status code.
  factory ApiException.fromStatusCode(
    int statusCode,
    String endpoint, {
    Map<String, dynamic>? body,
  }) {
    final message = _messageForStatusCode(statusCode);
    final code = _codeForStatusCode(statusCode);

    return ApiException(
      message: message,
      code: code,
      statusCode: statusCode,
      endpoint: endpoint,
      responseBody: body,
    );
  }

  static String _messageForStatusCode(int code) {
    return switch (code) {
      400 => 'Bad request - check your query parameters',
      401 => 'Authentication required',
      403 => 'Access forbidden - insufficient permissions',
      404 => 'Resource not found',
      409 => 'Conflict - resource already exists or is locked',
      429 => 'Too many requests - rate limit exceeded',
      500 => 'Internal server error',
      502 => 'Bad gateway - server is temporarily unavailable',
      503 => 'Service unavailable - server is overloaded',
      504 => 'Gateway timeout - server took too long to respond',
      _ => 'HTTP error $code',
    };
  }

  static String _codeForStatusCode(int code) {
    return switch (code) {
      400 => 'API_BAD_REQUEST',
      401 => 'API_UNAUTHORIZED',
      403 => 'API_FORBIDDEN',
      404 => 'API_NOT_FOUND',
      409 => 'API_CONFLICT',
      429 => 'API_RATE_LIMITED',
      >= 500 => 'API_SERVER_ERROR',
      _ => 'API_HTTP_ERROR',
    };
  }

  /// Whether this is a retryable error.
  bool get isRetryable =>
      statusCode != null &&
      (statusCode! >= 500 || statusCode == 429 || statusCode == 408);

  @override
  String toString() =>
      'ApiException[$code]: $message (status: $statusCode, endpoint: $endpoint)';
}
