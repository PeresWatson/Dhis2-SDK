import 'dart:convert';
import 'package:hive/hive.dart';
import '../logging/sdk_logger.dart';
import 'cache_policy.dart';

/// A cached entry with metadata for expiration and staleness tracking.
class CacheEntry<T> {
  final T data;
  final DateTime cachedAt;
  final DateTime expiresAt;
  final DateTime? staleAt;
  final String? etag;
  final int priority;

  CacheEntry({
    required this.data,
    required this.cachedAt,
    required this.expiresAt,
    this.staleAt,
    this.etag,
    this.priority = 0,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isStale => staleAt != null && DateTime.now().isAfter(staleAt!);
  bool get isFresh => !isExpired && !isStale;

  Duration get age => DateTime.now().difference(cachedAt);

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'cachedAt': cachedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'staleAt': staleAt?.toIso8601String(),
      'etag': etag,
      'priority': priority,
    };
  }

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      data: json['data'] as T,
      cachedAt: DateTime.parse(json['cachedAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      staleAt: json['staleAt'] != null 
          ? DateTime.parse(json['staleAt']) 
          : null,
      etag: json['etag'],
      priority: json['priority'] ?? 0,
    );
  }
}

/// Manages caching of data with support for multiple storage backends.
/// 
/// Uses Hive for persistent storage with support for expiration,
/// staleness tracking, and cache eviction policies.
class CacheManager {
  final SdkLogger _logger;
  final String boxName;
  final int maxEntries;
  final Duration defaultDuration;
  
  Box<String>? _box;
  bool _isInitialized = false;

  CacheManager({
    SdkLogger? logger,
    this.boxName = 'dhis2_cache',
    this.maxEntries = 1000,
    this.defaultDuration = const Duration(hours: 1),
  }) : _logger = logger ?? SdkLogger();

  /// Initialize the cache manager
  Future<void> initialize({String? path}) async {
    if (_isInitialized) return;

    try {
      if (path != null) {
        Hive.init(path);
      }
      
      _box = await Hive.openBox<String>(boxName);
      _isInitialized = true;
      
      _logger.info(
        'Cache manager initialized',
        tag: 'CacheManager',
        data: {'boxName': boxName, 'entries': _box?.length ?? 0},
      );
      
      // Clean up expired entries on init
      await _cleanupExpired();
    } catch (e) {
      _logger.error(
        'Failed to initialize cache manager',
        tag: 'CacheManager',
        error: e,
      );
      rethrow;
    }
  }

  /// Check if cache manager is initialized
  bool get isInitialized => _isInitialized;

  /// Get a cached value by key
  Future<T?> get<T>(
    String key, {
    bool allowStale = false,
    bool allowExpired = false,
  }) async {
    _ensureInitialized();

    try {
      final jsonString = _box?.get(key);
      if (jsonString == null) return null;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final entry = CacheEntry<T>.fromJson(json);

      if (entry.isExpired && !allowExpired) {
        _logger.debug(
          'Cache entry expired: $key',
          tag: 'CacheManager',
        );
        await delete(key);
        return null;
      }

      if (entry.isStale && !allowStale && !allowExpired) {
        _logger.debug(
          'Cache entry stale: $key',
          tag: 'CacheManager',
        );
        return null;
      }

      _logger.debug(
        'Cache hit: $key',
        tag: 'CacheManager',
        data: {'age': entry.age.inMinutes, 'isStale': entry.isStale},
      );

      return entry.data;
    } catch (e) {
      _logger.warning(
        'Error reading cache: $key',
        tag: 'CacheManager',
        data: {'error': e.toString()},
      );
      return null;
    }
  }

  /// Get a cached entry with full metadata
  Future<CacheEntry<T>?> getEntry<T>(String key) async {
    _ensureInitialized();

    try {
      final jsonString = _box?.get(key);
      if (jsonString == null) return null;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return CacheEntry<T>.fromJson(json);
    } catch (e) {
      _logger.warning(
        'Error reading cache entry: $key',
        tag: 'CacheManager',
        data: {'error': e.toString()},
      );
      return null;
    }
  }

  /// Set a cached value
  Future<void> set<T>(
    String key,
    T data, {
    Duration? duration,
    Duration? staleDuration,
    String? etag,
    int priority = 0,
  }) async {
    _ensureInitialized();

    try {
      // Check if we need to evict entries
      if ((_box?.length ?? 0) >= maxEntries) {
        await _evictEntries();
      }

      final now = DateTime.now();
      final effectiveDuration = duration ?? defaultDuration;
      
      final entry = CacheEntry<T>(
        data: data,
        cachedAt: now,
        expiresAt: now.add(effectiveDuration),
        staleAt: staleDuration != null ? now.add(staleDuration) : null,
        etag: etag,
        priority: priority,
      );

      await _box?.put(key, jsonEncode(entry.toJson()));
      
      _logger.debug(
        'Cache set: $key',
        tag: 'CacheManager',
        data: {'expiresIn': effectiveDuration.inMinutes},
      );
    } catch (e) {
      _logger.error(
        'Error writing cache: $key',
        tag: 'CacheManager',
        error: e,
      );
    }
  }

  /// Delete a cached entry
  Future<void> delete(String key) async {
    _ensureInitialized();
    await _box?.delete(key);
    _logger.debug('Cache deleted: $key', tag: 'CacheManager');
  }

  /// Delete multiple entries by pattern
  Future<int> deleteByPattern(String pattern) async {
    _ensureInitialized();
    
    final regex = RegExp(pattern);
    final keysToDelete = _box?.keys
        .where((key) => regex.hasMatch(key.toString()))
        .toList() ?? [];
    
    for (final key in keysToDelete) {
      await _box?.delete(key);
    }
    
    _logger.debug(
      'Cache entries deleted by pattern',
      tag: 'CacheManager',
      data: {'pattern': pattern, 'count': keysToDelete.length},
    );
    
    return keysToDelete.length;
  }

  /// Clear all cached entries
  Future<void> clear() async {
    _ensureInitialized();
    await _box?.clear();
    _logger.info('Cache cleared', tag: 'CacheManager');
  }

  /// Get all cache keys
  List<String> get keys {
    _ensureInitialized();
    return _box?.keys.cast<String>().toList() ?? [];
  }

  /// Get cache statistics
  Future<CacheStats> getStats() async {
    _ensureInitialized();

    int totalEntries = 0;
    int expiredEntries = 0;
    int staleEntries = 0;
    int freshEntries = 0;
    int totalSizeBytes = 0;

    for (final key in _box?.keys ?? []) {
      try {
        final jsonString = _box?.get(key);
        if (jsonString != null) {
          totalEntries++;
          totalSizeBytes += jsonString.length * 2; // UTF-16

          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          final expiresAt = DateTime.parse(json['expiresAt']);
          final staleAt = json['staleAt'] != null 
              ? DateTime.parse(json['staleAt']) 
              : null;
          final now = DateTime.now();

          if (now.isAfter(expiresAt)) {
            expiredEntries++;
          } else if (staleAt != null && now.isAfter(staleAt)) {
            staleEntries++;
          } else {
            freshEntries++;
          }
        }
      } catch (_) {
        // Skip malformed entries
      }
    }

    return CacheStats(
      totalEntries: totalEntries,
      expiredEntries: expiredEntries,
      staleEntries: staleEntries,
      freshEntries: freshEntries,
      totalSizeBytes: totalSizeBytes,
      maxEntries: maxEntries,
    );
  }

  /// Close the cache manager
  Future<void> close() async {
    await _box?.close();
    _isInitialized = false;
    _logger.info('Cache manager closed', tag: 'CacheManager');
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'CacheManager not initialized. Call initialize() first.',
      );
    }
  }

  Future<void> _cleanupExpired() async {
    final keysToDelete = <dynamic>[];
    
    for (final key in _box?.keys ?? []) {
      try {
        final jsonString = _box?.get(key);
        if (jsonString != null) {
          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          final expiresAt = DateTime.parse(json['expiresAt']);
          if (DateTime.now().isAfter(expiresAt)) {
            keysToDelete.add(key);
          }
        }
      } catch (_) {
        // Delete malformed entries
        keysToDelete.add(key);
      }
    }

    for (final key in keysToDelete) {
      await _box?.delete(key);
    }

    if (keysToDelete.isNotEmpty) {
      _logger.info(
        'Cleaned up expired cache entries',
        tag: 'CacheManager',
        data: {'count': keysToDelete.length},
      );
    }
  }

  Future<void> _evictEntries() async {
    // Evict by priority (lowest first) and age (oldest first)
    final entries = <MapEntry<dynamic, _EvictionCandidate>>[];

    for (final key in _box?.keys ?? []) {
      try {
        final jsonString = _box?.get(key);
        if (jsonString != null) {
          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          final cachedAt = DateTime.parse(json['cachedAt']);
          final priority = json['priority'] as int? ?? 0;
          entries.add(MapEntry(
            key,
            _EvictionCandidate(cachedAt: cachedAt, priority: priority),
          ));
        }
      } catch (_) {
        // Malformed entries get highest eviction priority
        entries.add(MapEntry(
          key,
          _EvictionCandidate(
            cachedAt: DateTime.fromMillisecondsSinceEpoch(0),
            priority: -1000,
          ),
        ));
      }
    }

    // Sort by priority (ascending) then by age (descending)
    entries.sort((a, b) {
      final priorityCompare = a.value.priority.compareTo(b.value.priority);
      if (priorityCompare != 0) return priorityCompare;
      return a.value.cachedAt.compareTo(b.value.cachedAt);
    });

    // Evict 10% of max entries
    final evictCount = (maxEntries * 0.1).ceil();
    final keysToEvict = entries.take(evictCount).map((e) => e.key);

    for (final key in keysToEvict) {
      await _box?.delete(key);
    }

    _logger.info(
      'Evicted cache entries',
      tag: 'CacheManager',
      data: {'count': evictCount},
    );
  }
}

class _EvictionCandidate {
  final DateTime cachedAt;
  final int priority;

  _EvictionCandidate({required this.cachedAt, required this.priority});
}

/// Statistics about the cache
class CacheStats {
  final int totalEntries;
  final int expiredEntries;
  final int staleEntries;
  final int freshEntries;
  final int totalSizeBytes;
  final int maxEntries;

  const CacheStats({
    required this.totalEntries,
    required this.expiredEntries,
    required this.staleEntries,
    required this.freshEntries,
    required this.totalSizeBytes,
    required this.maxEntries,
  });

  double get utilizationPercent => (totalEntries / maxEntries) * 100;
  double get freshPercent => totalEntries > 0 
      ? (freshEntries / totalEntries) * 100 
      : 0;
  String get formattedSize {
    if (totalSizeBytes < 1024) return '$totalSizeBytes B';
    if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  String toString() {
    return 'CacheStats('
        'total: $totalEntries, '
        'fresh: $freshEntries, '
        'stale: $staleEntries, '
        'expired: $expiredEntries, '
        'size: $formattedSize)';
  }
}
