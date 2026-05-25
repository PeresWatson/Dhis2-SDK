/// Cache policies that determine how requests interact with the cache.
enum CachePolicy {
  /// Try cache first, fall back to network if cache miss or expired.
  /// This is the default policy for most read operations.
  cacheFirst,

  /// Always fetch from network, update cache with response.
  /// Use for data that must be fresh.
  networkFirst,

  /// Only use network, never read or write to cache.
  /// Use for sensitive or one-time requests.
  networkOnly,

  /// Only use cache, never make network request.
  /// Use for offline-first scenarios or when network is unavailable.
  cacheOnly,

  /// Return cached data immediately (if available), then fetch from network
  /// and update cache in background. Best for UX-critical data.
  staleWhileRevalidate,
}

/// Extension methods for CachePolicy
extension CachePolicyExtension on CachePolicy {
  /// Whether this policy allows reading from cache
  bool get allowsCacheRead {
    return this != CachePolicy.networkOnly && 
           this != CachePolicy.networkFirst;
  }

  /// Whether this policy allows writing to cache
  bool get allowsCacheWrite {
    return this != CachePolicy.networkOnly && 
           this != CachePolicy.cacheOnly;
  }

  /// Whether this policy requires network access
  bool get requiresNetwork {
    return this != CachePolicy.cacheOnly;
  }

  /// Whether this policy prefers cache over network
  bool get prefersCacheFirst {
    return this == CachePolicy.cacheFirst || 
           this == CachePolicy.cacheOnly ||
           this == CachePolicy.staleWhileRevalidate;
  }

  /// Get a human-readable description
  String get description {
    switch (this) {
      case CachePolicy.cacheFirst:
        return 'Cache first, network fallback';
      case CachePolicy.networkFirst:
        return 'Network first, cache fallback';
      case CachePolicy.networkOnly:
        return 'Network only, no caching';
      case CachePolicy.cacheOnly:
        return 'Cache only, no network';
      case CachePolicy.staleWhileRevalidate:
        return 'Return stale cache, revalidate in background';
    }
  }
}

/// Configuration for cache entry behavior
class CacheEntryConfig {
  /// The cache policy to use
  final CachePolicy policy;

  /// How long the cached data is considered fresh
  final Duration freshDuration;

  /// How long the cached data can be used when stale
  /// (only applicable for staleWhileRevalidate)
  final Duration staleDuration;

  /// Whether to compress cached data
  final bool compress;

  /// Priority for cache eviction (higher = less likely to evict)
  final int priority;

  const CacheEntryConfig({
    this.policy = CachePolicy.cacheFirst,
    this.freshDuration = const Duration(hours: 1),
    this.staleDuration = const Duration(hours: 24),
    this.compress = false,
    this.priority = 0,
  });

  /// Default configuration for analytics data
  static const analytics = CacheEntryConfig(
    policy: CachePolicy.cacheFirst,
    freshDuration: Duration(minutes: 15),
    staleDuration: Duration(hours: 4),
    priority: 5,
  );

  /// Default configuration for metadata (org units, data elements, etc.)
  static const metadata = CacheEntryConfig(
    policy: CachePolicy.cacheFirst,
    freshDuration: Duration(hours: 24),
    staleDuration: Duration(days: 7),
    priority: 10,
  );

  /// Default configuration for user data
  static const userData = CacheEntryConfig(
    policy: CachePolicy.networkFirst,
    freshDuration: Duration(minutes: 5),
    staleDuration: Duration(hours: 1),
    priority: 3,
  );

  /// Default configuration for system info
  static const systemInfo = CacheEntryConfig(
    policy: CachePolicy.staleWhileRevalidate,
    freshDuration: Duration(hours: 6),
    staleDuration: Duration(days: 1),
    priority: 8,
  );

  /// Create a copy with modified values
  CacheEntryConfig copyWith({
    CachePolicy? policy,
    Duration? freshDuration,
    Duration? staleDuration,
    bool? compress,
    int? priority,
  }) {
    return CacheEntryConfig(
      policy: policy ?? this.policy,
      freshDuration: freshDuration ?? this.freshDuration,
      staleDuration: staleDuration ?? this.staleDuration,
      compress: compress ?? this.compress,
      priority: priority ?? this.priority,
    );
  }
}
