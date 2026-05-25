/// Cache Exception
/// 
/// Specific exceptions for caching-related errors.
library;

import 'dhis2_exception.dart';

/// Exception for cache failures.
/// 
/// Thrown when:
/// - Cache is corrupted
/// - Cache storage is full
/// - Cache read/write fails
/// - Cache data is invalid
class CacheException extends Dhis2Exception {
  const CacheException({
    required super.message,
    super.code = 'CACHE_ERROR',
    super.cause,
    super.stackTrace,
    super.context,
  });

  /// Cache is empty or data not found.
  factory CacheException.notFound(String key) {
    return CacheException(
      message: 'No cached data found for: $key',
      code: 'CACHE_NOT_FOUND',
      context: {'key': key},
    );
  }

  /// Cached data has expired.
  factory CacheException.expired(String key, DateTime expiredAt) {
    return CacheException(
      message: 'Cached data has expired for: $key',
      code: 'CACHE_EXPIRED',
      context: {
        'key': key,
        'expiredAt': expiredAt.toIso8601String(),
      },
    );
  }

  /// Cache data is corrupted or invalid.
  factory CacheException.corrupted(String key) {
    return CacheException(
      message: 'Cached data is corrupted for: $key',
      code: 'CACHE_CORRUPTED',
      context: {'key': key},
    );
  }

  /// Cache storage is full.
  factory CacheException.storageFull() {
    return const CacheException(
      message: 'Cache storage is full. Please clear some data.',
      code: 'CACHE_STORAGE_FULL',
    );
  }

  /// Failed to write to cache.
  factory CacheException.writeFailed(String key, Object? error) {
    return CacheException(
      message: 'Failed to write to cache: $key',
      code: 'CACHE_WRITE_FAILED',
      cause: error,
      context: {'key': key},
    );
  }

  /// Failed to read from cache.
  factory CacheException.readFailed(String key, Object? error) {
    return CacheException(
      message: 'Failed to read from cache: $key',
      code: 'CACHE_READ_FAILED',
      cause: error,
      context: {'key': key},
    );
  }

  /// Cache initialization failed.
  factory CacheException.initFailed(Object? error) {
    return CacheException(
      message: 'Failed to initialize cache storage',
      code: 'CACHE_INIT_FAILED',
      cause: error,
    );
  }

  /// Failed to clear cache.
  factory CacheException.clearFailed(Object? error) {
    return CacheException(
      message: 'Failed to clear cache',
      code: 'CACHE_CLEAR_FAILED',
      cause: error,
    );
  }

  @override
  String toString() => 'CacheException[$code]: $message';
}
