/// Result Type for Operation Outcomes
/// 
/// A functional approach to handling success and failure cases
/// without throwing exceptions for expected error conditions.
/// 
/// ## Purpose
/// 
/// - Explicit error handling at compile time
/// - No hidden control flow via exceptions
/// - Forces handling of both success and failure cases
/// - Better for async operations where try/catch is cumbersome
/// 
/// ## Why Use Result Instead of Exceptions?
/// 
/// Exceptions should be for exceptional circumstances, not
/// expected business logic failures like "user not found" or
/// "invalid credentials". Result makes these cases explicit.
/// 
/// ## Data Flow
/// 
/// ```
/// Service Method → Result<T, E> → match/fold → Handle Success or Failure
/// ```
/// 
/// ## Best Practices
/// 
/// - Use Result for operations that can fail expectedly
/// - Use exceptions for truly exceptional cases (programming errors)
/// - Always handle both cases with fold() or match()
/// - Prefer specific error types over generic ones
library;

import 'package:equatable/equatable.dart';

/// Represents the outcome of an operation that can succeed or fail.
/// 
/// [T] is the success value type.
/// [E] is the error value type.
/// 
/// Example:
/// ```dart
/// Result<User, AuthError> login(String username, String password) {
///   if (username.isEmpty) {
///     return Result.failure(AuthError.invalidUsername);
///   }
///   // ... perform login
///   return Result.success(user);
/// }
/// 
/// // Usage:
/// final result = await authService.login('admin', 'password');
/// result.fold(
///   onSuccess: (user) => print('Logged in as ${user.name}'),
///   onFailure: (error) => print('Login failed: $error'),
/// );
/// ```
sealed class Result<T, E> extends Equatable {
  const Result._();

  /// Creates a successful result containing [value].
  const factory Result.success(T value) = Success<T, E>;

  /// Creates a failed result containing [error].
  const factory Result.failure(E error) = Failure<T, E>;

  /// Returns true if this is a successful result.
  bool get isSuccess => this is Success<T, E>;

  /// Returns true if this is a failed result.
  bool get isFailure => this is Failure<T, E>;

  /// Returns the success value or null if this is a failure.
  T? get valueOrNull {
    return switch (this) {
      Success(:final value) => value,
      Failure() => null,
    };
  }

  /// Returns the error value or null if this is a success.
  E? get errorOrNull {
    return switch (this) {
      Success() => null,
      Failure(:final error) => error,
    };
  }

  /// Returns the success value or throws the error.
  /// 
  /// Only use this when you're certain the result is successful
  /// or when you want to convert expected errors to exceptions.
  T get valueOrThrow {
    return switch (this) {
      Success(:final value) => value,
      Failure(:final error) => throw error as Object,
    };
  }

  /// Returns the success value or the result of [orElse].
  T valueOr(T Function() orElse) {
    return switch (this) {
      Success(:final value) => value,
      Failure() => orElse(),
    };
  }

  /// Transforms the success value using [transform].
  /// 
  /// If this is a failure, returns the failure unchanged.
  Result<R, E> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success(:final value) => Result.success(transform(value)),
      Failure(:final error) => Result.failure(error),
    };
  }

  /// Transforms the error value using [transform].
  /// 
  /// If this is a success, returns the success unchanged.
  Result<T, R> mapError<R>(R Function(E error) transform) {
    return switch (this) {
      Success(:final value) => Result.success(value),
      Failure(:final error) => Result.failure(transform(error)),
    };
  }

  /// Transforms the success value using [transform] which returns a Result.
  /// 
  /// Useful for chaining operations that can fail.
  Result<R, E> flatMap<R>(Result<R, E> Function(T value) transform) {
    return switch (this) {
      Success(:final value) => transform(value),
      Failure(:final error) => Result.failure(error),
    };
  }

  /// Handles both success and failure cases.
  /// 
  /// This is the preferred way to handle Result values as it
  /// forces handling of both cases.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(E error) onFailure,
  }) {
    return switch (this) {
      Success(:final value) => onSuccess(value),
      Failure(:final error) => onFailure(error),
    };
  }

  /// Executes [action] if this is a success.
  /// 
  /// Returns this Result unchanged for chaining.
  Result<T, E> onSuccess(void Function(T value) action) {
    if (this case Success(:final value)) {
      action(value);
    }
    return this;
  }

  /// Executes [action] if this is a failure.
  /// 
  /// Returns this Result unchanged for chaining.
  Result<T, E> onFailure(void Function(E error) action) {
    if (this case Failure(:final error)) {
      action(error);
    }
    return this;
  }
}

/// Represents a successful result.
final class Success<T, E> extends Result<T, E> {
  /// The success value.
  final T value;

  /// Creates a successful result with [value].
  const Success(this.value) : super._();

  @override
  List<Object?> get props => [value];

  @override
  String toString() => 'Success($value)';
}

/// Represents a failed result.
final class Failure<T, E> extends Result<T, E> {
  /// The error value.
  final E error;

  /// Creates a failed result with [error].
  const Failure(this.error) : super._();

  @override
  List<Object?> get props => [error];

  @override
  String toString() => 'Failure($error)';
}

/// Extension methods for Result with nullable success type.
extension ResultNullableExtension<T, E> on Result<T?, E> {
  /// Converts a Result<T?, E> to Result<T, E> using [orError]
  /// when the success value is null.
  Result<T, E> requireValue(E orError) {
    return switch (this) {
      Success(:final value) when value != null => Result.success(value),
      Success() => Result.failure(orError),
      Failure(:final error) => Result.failure(error),
    };
  }
}

/// Extension methods for async Result operations.
extension FutureResultExtension<T, E> on Future<Result<T, E>> {
  /// Maps the success value asynchronously.
  Future<Result<R, E>> mapAsync<R>(
    Future<R> Function(T value) transform,
  ) async {
    final result = await this;
    return switch (result) {
      Success(:final value) => Result.success(await transform(value)),
      Failure(:final error) => Result.failure(error),
    };
  }

  /// Flat maps the success value asynchronously.
  Future<Result<R, E>> flatMapAsync<R>(
    Future<Result<R, E>> Function(T value) transform,
  ) async {
    final result = await this;
    return switch (result) {
      Success(:final value) => transform(value),
      Failure(:final error) => Result.failure(error),
    };
  }
}
