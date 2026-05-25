/// Network Exception
/// 
/// Specific exceptions for network-related errors.
library;

import 'dhis2_exception.dart';

/// Exception for network failures.
/// 
/// Thrown when:
/// - No internet connection
/// - Connection timeout
/// - DNS resolution failed
/// - Server unreachable
class NetworkException extends Dhis2Exception {
  /// Whether the error is likely temporary and retryable.
  final bool isRetryable;

  const NetworkException({
    required super.message,
    super.code = 'NETWORK_ERROR',
    this.isRetryable = true,
    super.cause,
    super.stackTrace,
    super.context,
  });

  /// No internet connection available.
  factory NetworkException.noConnection() {
    return const NetworkException(
      message: 'No internet connection. Please check your network settings.',
      code: 'NETWORK_NO_CONNECTION',
      isRetryable: true,
    );
  }

  /// Connection timed out.
  factory NetworkException.timeout([String? operation]) {
    return NetworkException(
      message: operation != null
          ? 'Connection timed out while $operation'
          : 'Connection timed out. The server may be slow or unavailable.',
      code: 'NETWORK_TIMEOUT',
      isRetryable: true,
      context: operation != null ? {'operation': operation} : null,
    );
  }

  /// DNS resolution failed.
  factory NetworkException.dnsFailure(String host) {
    return NetworkException(
      message: 'Could not resolve server address: $host',
      code: 'NETWORK_DNS_FAILURE',
      isRetryable: true,
      context: {'host': host},
    );
  }

  /// Server refused connection.
  factory NetworkException.connectionRefused(String host) {
    return NetworkException(
      message: 'Connection refused by server: $host',
      code: 'NETWORK_CONNECTION_REFUSED',
      isRetryable: true,
      context: {'host': host},
    );
  }

  /// SSL/TLS certificate error.
  factory NetworkException.sslError(String host) {
    return NetworkException(
      message: 'SSL certificate error for: $host. '
          'The server certificate may be invalid or expired.',
      code: 'NETWORK_SSL_ERROR',
      isRetryable: false,
      context: {'host': host},
    );
  }

  /// Connection was reset.
  factory NetworkException.connectionReset() {
    return const NetworkException(
      message: 'Connection was reset. Please try again.',
      code: 'NETWORK_CONNECTION_RESET',
      isRetryable: true,
    );
  }

  /// Server is unreachable.
  factory NetworkException.hostUnreachable(String host) {
    return NetworkException(
      message: 'Server is unreachable: $host',
      code: 'NETWORK_HOST_UNREACHABLE',
      isRetryable: true,
      context: {'host': host},
    );
  }

  /// Request was cancelled.
  factory NetworkException.cancelled() {
    return const NetworkException(
      message: 'Request was cancelled',
      code: 'NETWORK_CANCELLED',
      isRetryable: false,
    );
  }

  @override
  String toString() => 'NetworkException[$code]: $message';
}
