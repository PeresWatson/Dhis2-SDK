/// Authentication Exception
/// 
/// Specific exceptions for authentication-related errors.
library;

import 'dhis2_exception.dart';

/// Exception for authentication failures.
/// 
/// Thrown when:
/// - Login credentials are invalid
/// - Session has expired
/// - Token is invalid or revoked
/// - User account is locked
class AuthException extends Dhis2Exception {
  /// Whether the user should be prompted to re-authenticate.
  final bool requiresReauth;

  const AuthException({
    required super.message,
    super.code = 'AUTH_ERROR',
    this.requiresReauth = false,
    super.cause,
    super.stackTrace,
    super.context,
  });

  /// Invalid username or password.
  factory AuthException.invalidCredentials() {
    return const AuthException(
      message: 'Invalid username or password',
      code: 'AUTH_INVALID_CREDENTIALS',
      requiresReauth: true,
    );
  }

  /// Session has expired.
  factory AuthException.sessionExpired() {
    return const AuthException(
      message: 'Your session has expired. Please log in again.',
      code: 'AUTH_SESSION_EXPIRED',
      requiresReauth: true,
    );
  }

  /// User is not authenticated.
  factory AuthException.notAuthenticated() {
    return const AuthException(
      message: 'Authentication required. Please log in.',
      code: 'AUTH_NOT_AUTHENTICATED',
      requiresReauth: true,
    );
  }

  /// User account is locked or disabled.
  factory AuthException.accountLocked() {
    return const AuthException(
      message: 'Your account has been locked. Contact your administrator.',
      code: 'AUTH_ACCOUNT_LOCKED',
      requiresReauth: false,
    );
  }

  /// Insufficient permissions for the requested action.
  factory AuthException.insufficientPermissions([String? requiredAuthority]) {
    return AuthException(
      message: requiredAuthority != null
          ? 'You do not have the required permission: $requiredAuthority'
          : 'You do not have permission to perform this action',
      code: 'AUTH_INSUFFICIENT_PERMISSIONS',
      requiresReauth: false,
      context:
          requiredAuthority != null ? {'required': requiredAuthority} : null,
    );
  }

  /// Token is invalid or malformed.
  factory AuthException.invalidToken() {
    return const AuthException(
      message: 'Authentication token is invalid',
      code: 'AUTH_INVALID_TOKEN',
      requiresReauth: true,
    );
  }

  /// Two-factor authentication required.
  factory AuthException.twoFactorRequired() {
    return const AuthException(
      message: 'Two-factor authentication is required',
      code: 'AUTH_2FA_REQUIRED',
      requiresReauth: false,
    );
  }

  @override
  String toString() => 'AuthException[$code]: $message';
}
