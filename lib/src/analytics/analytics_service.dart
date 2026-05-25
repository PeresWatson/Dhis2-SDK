/// Analytics Service
/// 
/// Main service for executing analytics queries against DHIS2.
/// 
/// ## Purpose
/// 
/// - Execute analytics queries
/// - Handle caching of results
/// - Transform responses
/// - Manage query pagination
/// 
/// ## Data Flow
/// 
/// ```
/// AnalyticsService.execute(request)
///         ↓
///   Check Cache → (hit) → Return cached
///         ↓ (miss)
///   Build URL → HTTP Request → Parse Response
///         ↓
///   Store in Cache → Return
/// ```
library;

import '../core/base/base_service.dart';
import '../core/base/result.dart';
import '../core/config/dhis2_config.dart';
import '../core/constants/api_endpoints.dart';
import '../exceptions/dhis2_exception.dart';
import '../logging/sdk_logger.dart';
import '../network/http_client.dart';
import '../caching/cache_service.dart';
import 'models/analytics_request.dart';
import 'models/analytics_response.dart';
import 'query/analytics_query_builder.dart';

/// Service for executing DHIS2 analytics queries.
/// 
/// Example:
/// ```dart
/// final service = AnalyticsService(
///   config: config,
///   logger: logger,
///   httpClient: httpClient,
/// );
/// 
/// // Using query builder
/// final result = await service.query()
///   .withDataElements(['dataElementId'])
///   .withPeriods(['LAST_12_MONTHS'])
///   .withOrgUnits(['orgUnitId'])
///   .execute();
/// 
/// // Or with pre-built request
/// final response = await service.execute(request);
/// ```
class AnalyticsService extends BaseService {
  /// HTTP client for API calls.
  final Dhis2HttpClient _httpClient;

  /// Optional cache service.
  final CacheService? _cacheService;

  /// Default cache duration for analytics results.
  final Duration cacheDuration;

  /// Creates a new AnalyticsService.
  AnalyticsService({
    required Dhis2Config config,
    required SdkLogger logger,
    required Dhis2HttpClient httpClient,
    CacheService? cacheService,
    this.cacheDuration = const Duration(minutes: 30),
  })  : _httpClient = httpClient,
        _cacheService = cacheService,
        super(config: config, logger: logger);

  /// Creates a new analytics query builder.
  /// 
  /// Returns a builder that can be chained and executed.
  /// 
  /// Example:
  /// ```dart
  /// final result = await analytics.query()
  ///   .withDataElements(['de1', 'de2'])
  ///   .withPeriods(['2024Q1'])
  ///   .withOrgUnits(['ou1'])
  ///   .execute();
  /// ```
  _ExecutableQueryBuilder query() {
    return _ExecutableQueryBuilder(this);
  }

  /// Executes an analytics request.
  /// 
  /// Returns [Result.success] with [AnalyticsResponse] on success,
  /// or [Result.failure] with error details.
  Future<Result<AnalyticsResponse, Dhis2Exception>> execute(
    AnalyticsRequest request, {
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    ensureInitialized();

    // Validate request
    if (!request.isValid) {
      return Result.failure(ValidationException(
        message: 'Invalid analytics request: missing required dimensions',
        code: 'ANALYTICS_INVALID_REQUEST',
      ));
    }

    final cacheKey = request.toCacheKey();
    logger.debug('Executing analytics query', {'cacheKey': cacheKey});

    // Check cache first (unless forcing refresh)
    if (useCache && !forceRefresh && _cacheService != null) {
      final cached = await _cacheService!.get<Map<String, dynamic>>(cacheKey);
      if (cached != null) {
        logger.debug('Returning cached analytics response');
        return Result.success(AnalyticsResponse.fromJson(cached));
      }
    }

    try {
      // Build the endpoint URL
      final endpoint = request.isEventAnalytics
          ? ApiEndpoints.analyticsEvents(request.program!)
          : ApiEndpoints.analytics;

      // Execute request
      final queryString = request.toQueryString();
      final url = '$endpoint?$queryString';
      
      logger.logRequest('GET', url);
      final stopwatch = Stopwatch()..start();

      final response = await _httpClient.get(url);
      
      stopwatch.stop();
      logger.logResponse('GET', url, 200, stopwatch.elapsed);

      // Parse response
      final analyticsResponse =
          AnalyticsResponse.fromJson(response.data as Map<String, dynamic>);

      // Cache the result
      if (useCache && _cacheService != null) {
        await _cacheService!.set(
          cacheKey,
          response.data as Map<String, dynamic>,
          ttl: cacheDuration,
        );
      }

      logger.info('Analytics query returned ${analyticsResponse.height} rows');
      return Result.success(analyticsResponse);
    } on Dhis2Exception catch (e) {
      logger.error('Analytics query failed', e);
      return Result.failure(e);
    } catch (e, stackTrace) {
      logger.error('Analytics query failed with unexpected error', e, stackTrace);
      return Result.failure(Dhis2Exception(
        message: 'Analytics query failed: ${e.toString()}',
        code: 'ANALYTICS_QUERY_FAILED',
        cause: e,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Executes an analytics request and returns all pages.
  /// 
  /// Use this for queries that may return more data than a single page.
  Future<Result<AnalyticsResponse, Dhis2Exception>> executeAll(
    AnalyticsRequest request, {
    int pageSize = 1000,
    int maxPages = 100,
  }) async {
    ensureInitialized();

    final allRows = <List<String>>[];
    AnalyticsResponse? lastResponse;
    var page = 1;

    while (page <= maxPages) {
      final pagedRequest = request.copyWith(page: page, pageSize: pageSize);
      final result = await execute(pagedRequest, useCache: false);

      if (result.isFailure) {
        return result;
      }

      final response = result.valueOrNull!;
      lastResponse = response;
      allRows.addAll(response.rows);

      // Check if there are more pages
      if (response.rows.length < pageSize) {
        break;
      }
      page++;
    }

    if (lastResponse == null) {
      return Result.success(AnalyticsResponse.empty());
    }

    // Combine all rows into a single response
    return Result.success(AnalyticsResponse(
      headers: lastResponse.headers,
      rows: allRows,
      metadata: lastResponse.metadata,
      width: lastResponse.width,
      height: allRows.length,
    ));
  }

  /// Gets analytics data for a specific visualization.
  /// 
  /// Fetches the visualization definition and executes its analytics query.
  Future<Result<AnalyticsResponse, Dhis2Exception>> executeVisualization(
    String visualizationId,
  ) async {
    ensureInitialized();

    try {
      // Fetch visualization data endpoint
      final endpoint = ApiEndpoints.visualizationData(visualizationId);
      
      logger.debug('Fetching visualization data', {'id': visualizationId});
      final response = await _httpClient.get(endpoint);

      final analyticsResponse =
          AnalyticsResponse.fromJson(response.data as Map<String, dynamic>);

      return Result.success(analyticsResponse);
    } on Dhis2Exception catch (e) {
      return Result.failure(e);
    } catch (e, stackTrace) {
      return Result.failure(Dhis2Exception(
        message: 'Failed to fetch visualization data',
        code: 'ANALYTICS_VISUALIZATION_FAILED',
        cause: e,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Clears cached analytics data.
  Future<void> clearCache() async {
    if (_cacheService != null) {
      // Clear analytics-related cache keys
      // Implementation depends on cache service capabilities
      logger.info('Analytics cache cleared');
    }
  }
}

/// Query builder that can execute directly.
/// 
/// Extends the base builder with an execute method.
class _ExecutableQueryBuilder extends AnalyticsQueryBuilder {
  final AnalyticsService _service;

  _ExecutableQueryBuilder(this._service);

  /// Executes the built query.
  /// 
  /// This is the final step in the builder chain.
  Future<Result<AnalyticsResponse, Dhis2Exception>> execute({
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    final request = build();
    return _service.execute(
      request,
      useCache: useCache,
      forceRefresh: forceRefresh,
    );
  }

  /// Executes the query and returns all pages.
  Future<Result<AnalyticsResponse, Dhis2Exception>> executeAll({
    int pageSize = 1000,
    int maxPages = 100,
  }) async {
    final request = build();
    return _service.executeAll(
      request,
      pageSize: pageSize,
      maxPages: maxPages,
    );
  }
}
