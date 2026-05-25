import 'package:dio/dio.dart';
import '../../cache/cache_manager.dart';
import '../../cache/cache_policy.dart';
import '../../logging/sdk_logger.dart';

/// Interceptor that handles caching of HTTP responses.
/// 
/// Implements a cache-first strategy with configurable policies
/// for different endpoints and request types.
class CacheInterceptor extends Interceptor {
  final CacheManager _cacheManager;
  final SdkLogger _logger;
  final CachePolicy defaultPolicy;

  /// Header key used to specify cache policy per request
  static const String cachePolicyHeader = 'X-Cache-Policy';
  
  /// Header key used to specify cache duration per request
  static const String cacheDurationHeader = 'X-Cache-Duration';
  
  /// Response header indicating cache hit
  static const String cacheHitHeader = 'X-Cache-Hit';

  CacheInterceptor({
    required CacheManager cacheManager,
    SdkLogger? logger,
    this.defaultPolicy = CachePolicy.cacheFirst,
  })  : _cacheManager = cacheManager,
        _logger = logger ?? SdkLogger();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Only cache GET requests
    if (options.method.toUpperCase() != 'GET') {
      handler.next(options);
      return;
    }

    final policy = _getPolicyFromRequest(options);
    
    // Skip cache for network-only policy
    if (policy == CachePolicy.networkOnly) {
      handler.next(options);
      return;
    }

    final cacheKey = _generateCacheKey(options);
    
    try {
      final cachedResponse = await _cacheManager.get<Map<String, dynamic>>(
        cacheKey,
      );
      
      if (cachedResponse != null) {
        _logger.debug(
          'Cache hit for ${options.uri}',
          tag: 'CacheInterceptor',
        );
        
        // For cache-first, return cached response immediately
        if (policy == CachePolicy.cacheFirst || 
            policy == CachePolicy.cacheOnly) {
          final response = Response(
            requestOptions: options,
            data: cachedResponse,
            statusCode: 200,
            headers: Headers.fromMap({
              cacheHitHeader: ['true'],
            }),
          );
          handler.resolve(response);
          return;
        }
        
        // For stale-while-revalidate, return cache but trigger background refresh
        if (policy == CachePolicy.staleWhileRevalidate) {
          // Store the cached response to return
          options.extra['cachedResponse'] = cachedResponse;
        }
      } else if (policy == CachePolicy.cacheOnly) {
        // Cache-only but no cached data
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.unknown,
            message: 'No cached data available for cache-only request',
          ),
        );
        return;
      }
    } catch (e) {
      _logger.warning(
        'Cache read error: $e',
        tag: 'CacheInterceptor',
      );
    }
    
    handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    // Only cache successful GET responses
    if (response.requestOptions.method.toUpperCase() != 'GET' ||
        response.statusCode == null ||
        response.statusCode! < 200 ||
        response.statusCode! >= 300) {
      handler.next(response);
      return;
    }

    final policy = _getPolicyFromRequest(response.requestOptions);
    
    // Don't cache for cache-only (it's read-only)
    if (policy == CachePolicy.cacheOnly) {
      handler.next(response);
      return;
    }

    final cacheKey = _generateCacheKey(response.requestOptions);
    final duration = _getDurationFromRequest(response.requestOptions);
    
    try {
      await _cacheManager.set(
        cacheKey,
        response.data,
        duration: duration,
      );
      
      _logger.debug(
        'Cached response for ${response.requestOptions.uri}',
        tag: 'CacheInterceptor',
        data: {'duration': duration.inMinutes},
      );
    } catch (e) {
      _logger.warning(
        'Cache write error: $e',
        tag: 'CacheInterceptor',
      );
    }
    
    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // On network error, try to return cached data if available
    if (_isNetworkError(err)) {
      final cacheKey = _generateCacheKey(err.requestOptions);
      
      try {
        final cachedResponse = await _cacheManager.get<Map<String, dynamic>>(
          cacheKey,
        );
        
        if (cachedResponse != null) {
          _logger.info(
            'Returning cached data due to network error',
            tag: 'CacheInterceptor',
          );
          
          final response = Response(
            requestOptions: err.requestOptions,
            data: cachedResponse,
            statusCode: 200,
            headers: Headers.fromMap({
              cacheHitHeader: ['true'],
              'X-Cache-Fallback': ['true'],
            }),
          );
          handler.resolve(response);
          return;
        }
      } catch (e) {
        _logger.warning(
          'Cache fallback error: $e',
          tag: 'CacheInterceptor',
        );
      }
    }
    
    handler.next(err);
  }

  CachePolicy _getPolicyFromRequest(RequestOptions options) {
    final policyHeader = options.headers[cachePolicyHeader];
    if (policyHeader != null) {
      return CachePolicy.values.firstWhere(
        (p) => p.name == policyHeader,
        orElse: () => defaultPolicy,
      );
    }
    
    final extraPolicy = options.extra['cachePolicy'];
    if (extraPolicy is CachePolicy) {
      return extraPolicy;
    }
    
    return defaultPolicy;
  }

  Duration _getDurationFromRequest(RequestOptions options) {
    final durationHeader = options.headers[cacheDurationHeader];
    if (durationHeader != null) {
      final minutes = int.tryParse(durationHeader.toString());
      if (minutes != null) {
        return Duration(minutes: minutes);
      }
    }
    
    final extraDuration = options.extra['cacheDuration'];
    if (extraDuration is Duration) {
      return extraDuration;
    }
    
    // Default cache duration: 1 hour
    return const Duration(hours: 1);
  }

  String _generateCacheKey(RequestOptions options) {
    final uri = options.uri.toString();
    final queryParams = options.queryParameters.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    
    return 'http_cache:$uri${queryParams.isNotEmpty ? "?$queryParams" : ""}';
  }

  bool _isNetworkError(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;
  }
}
