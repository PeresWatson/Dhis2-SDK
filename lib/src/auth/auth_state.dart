/// Authentication State
/// 
/// Represents the current authentication state of the SDK.
/// 
/// ## Purpose
/// 
/// - Track authentication lifecycle
/// - Provide type-safe state handling
/// - Support reactive UI updates
/// 
/// ## States
/// 
/// ```
/// Initial → Authenticating → Authenticated
///                ↓                 ↓
///            AuthFailed      SessionExpired
///                               ↓
///                          Unauthenticated
/// ```
library;

import 'package:equatable/equatable.dart';

import 'models/user.dart';

/// Sealed class representing authentication states.
/// 
/// Use pattern matching to handle different states:
/// ```dart
/// switch (state) {
///   case Authenticated(:final user):
///     return HomePage(user: user);
///   case Authenticating():
///     return LoadingScreen();
///   case Unauthenticated():
///     return LoginScreen();
///   case AuthenticationFailed(:final message):
///     return LoginScreen(error: message);
/// }
/// ```
sealed class AuthState extends Equatable {
  const AuthState();
}

/// Initial state - no authentication attempted yet.
class AuthInitial extends AuthState {
  const AuthInitial();

  @override
  List<Object?> get props => [];
}

/// Authentication in progress.
class Authenticating extends AuthState {
  /// Optional message describing current step.
  final String? message;

  const Authenticating([this.message]);

  @override
  List<Object?> get props => [message];
}

/// Successfully authenticated.
class Authenticated extends AuthState {
  /// The authenticated user.
  final User user;

  /// When authentication occurred.
  final DateTime authenticatedAt;

  const Authenticated({
    required this.user,
    required this.authenticatedAt,
  });

  /// How long the session has been active.
  Duration get sessionDuration => DateTime.now().difference(authenticatedAt);

  @override
  List<Object?> get props => [user, authenticatedAt];
}

/// Not authenticated (logged out or never logged in).
class Unauthenticated extends AuthState {
  /// Optional reason for being unauthenticated.
  final String? reason;

  const Unauthenticated([this.reason]);

  @override
  List<Object?> get props => [reason];
}

/// Authentication attempt failed.
class AuthenticationFailed extends AuthState {
  /// Error message describing the failure.
  final String message;

  /// Error code for programmatic handling.
  final String? code;

  /// Whether the user can retry.
  final bool canRetry;

  const AuthenticationFailed({
    required this.message,
    this.code,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [message, code, canRetry];
}

/// Session has expired.
class SessionExpired extends AuthState {
  /// The previously authenticated user.
  final User? previousUser;

  /// Message for the user.
  final String message;

  const SessionExpired({
    this.previousUser,
    this.message = 'Your session has expired. Please log in again.',
  });

  @override
  List<Object?> get props => [previousUser, message];
}

/// Extension methods for AuthState.
extension AuthStateExtension on AuthState {
  /// Whether currently authenticated.
  bool get isAuthenticated => this is Authenticated;

  /// Whether authentication is in progress.
  bool get isAuthenticating => this is Authenticating;

  /// Get user if authenticated, null otherwise.
  User? get userOrNull {
    return switch (this) {
      Authenticated(:final user) => user,
      _ => null,
    };
  }

  /// Get error message if in error state.
  String? get errorMessage {
    return switch (this) {
      AuthenticationFailed(:final message) => message,
      SessionExpired(:final message) => message,
      _ => null,
    };
  }
}
