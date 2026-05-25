/// Credentials Model
/// 
/// Represents authentication credentials for DHIS2 login.
/// 
/// ## Purpose
/// 
/// - Encapsulate login credentials securely
/// - Support different authentication methods
/// - Validate credentials before use
/// 
/// ## Security
/// 
/// - Credentials are NOT stored in plain text in logs
/// - toString() masks sensitive values
/// - Use SecureStorage for persistence
library;

import 'dart:convert';

import 'package:equatable/equatable.dart';

/// Authentication credentials for DHIS2.
/// 
/// Example:
/// ```dart
/// final credentials = Credentials.basic(
///   username: 'admin',
///   password: 'district',
/// );
/// ```
class Credentials extends Equatable {
  /// Username for authentication.
  final String username;

  /// Password (for basic auth) - masked in toString.
  final String? _password;

  /// API token (for token-based auth) - masked in toString.
  final String? _token;

  /// Authentication type.
  final AuthType authType;

  const Credentials._({
    required this.username,
    String? password,
    String? token,
    required this.authType,
  })  : _password = password,
        _token = token;

  /// Creates basic auth credentials.
  factory Credentials.basic({
    required String username,
    required String password,
  }) {
    return Credentials._(
      username: username,
      password: password,
      authType: AuthType.basic,
    );
  }

  /// Creates token-based auth credentials.
  /// 
  /// Use for Personal Access Tokens (PAT).
  factory Credentials.token({
    required String username,
    required String token,
  }) {
    return Credentials._(
      username: username,
      token: token,
      authType: AuthType.token,
    );
  }

  /// Returns the Basic auth header value.
  /// 
  /// Format: 'Basic base64(username:password)'
  String? get basicAuthHeader {
    if (authType != AuthType.basic || _password == null) return null;
    final credentials = base64Encode(utf8.encode('$username:$_password'));
    return 'Basic $credentials';
  }

  /// Returns the API token.
  String? get token => _token;

  /// Returns the password (use carefully, sensitive data).
  String? get password => _password;

  /// Whether credentials appear valid (non-empty).
  bool get isValid {
    if (username.isEmpty) return false;
    return switch (authType) {
      AuthType.basic => _password != null && _password!.isNotEmpty,
      AuthType.token => _token != null && _token!.isNotEmpty,
    };
  }

  /// Creates a copy with a new password (for password change).
  Credentials withPassword(String newPassword) {
    return Credentials._(
      username: username,
      password: newPassword,
      authType: AuthType.basic,
    );
  }

  @override
  List<Object?> get props => [username, authType];

  @override
  String toString() => 'Credentials(username: $username, type: $authType)';
}

/// Type of authentication.
enum AuthType {
  /// Basic HTTP authentication (username/password).
  basic,

  /// Personal Access Token (PAT) authentication.
  token,
}
