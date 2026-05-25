import 'dart:async';

import 'core/config/dhis2_config.dart';
import 'core/config/sdk_options.dart';
import 'auth/auth_service.dart';
import 'auth/auth_state.dart';
import 'auth/models/credentials.dart';
import 'auth/models/user.dart';
import 'analytics/analytics_service.dart';
import 'analytics/query/analytics_query_builder.dart';
import 'metadata/metadata_service.dart';
import 'network/http_client.dart';
import 'cache/cache_manager.dart';
import 'cache/cache_policy.dart';
import 'sync/sync_manager.dart';
import 'sync/sync_status.dart';
import 'sync/connectivity_manager.dart';
import 'visualization/transformers/chart_transformer.dart';
import 'visualization/transformers/table_transformer.dart';
import 'logging/sdk_logger.dart';
import 'logging/log_level.dart';

/// Main entry point for the DHIS2 Flutter SDK.
/// 
/// The SDK provides a comprehensive interface to interact with DHIS2 instances,
/// including authentication, analytics queries, metadata management, and
/// offline-first data synchronization.
/// 
/// ## Quick Start
/// 
/// ```dart
/// // Initialize the SDK
/// final sdk = await Dhis2Sdk.initialize(
///   config: Dhis2Config(
///     baseUrl: 'https://play.dhis2.org/40',
///     credentials: Credentials.basic('admin', 'district'),
///   ),
/// );
/// 
/// // Authenticate
/// final result = await sdk.auth.authenticate();
/// if (result.isSuccess) {
///   print('Logged in as: ${result.data!.displayName}');
/// }
/// 
/// // Query analytics
/// final analytics = await sdk.analytics.query()
///   .withDataElements(['fbfJHSPpUQD'])
///   .withPeriods(['LAST_12_MONTHS'])
///   .withOrganisationUnits(['ImspTQPwCqd'])
///   .execute();
/// ```
class Dhis2Sdk {
  final Dhis2Config _config;
  final SdkOptions _options;
  final SdkLogger _logger;
  
  late final Dhis2HttpClient _httpClient;
  late final CacheManager _cacheManager;
  late final AuthService _authService;
  late final AnalyticsService _analyticsService;
  late final MetadataService _metadataService;
  late final ConnectivityManager _connectivityManager;
  late final SyncManager _syncManager;
  late final ChartTransformer _chartTransformer;
  late final TableTransformer _tableTransformer;

  bool _isInitialized = false;

  Dhis2Sdk._({
    required Dhis2Config config,
    SdkOptions? options,
    SdkLogger? logger,
  })  : _config = config,
        _options = options ?? const SdkOptions(),
        _logger = logger ?? SdkLogger();

  /// Initialize the SDK with the provided configuration.
  /// 
  /// This must be called before using any other SDK functionality.
  /// 
  /// [config] - The DHIS2 configuration including base URL and credentials.
  /// [options] - Optional SDK configuration options.
  /// [cachePath] - Optional path for persistent cache storage.
  static Future<Dhis2Sdk> initialize({
    required Dhis2Config config,
    SdkOptions? options,
    String? cachePath,
  }) async {
    final sdk = Dhis2Sdk._(
      config: config,
      options: options,
    );
    
    await sdk._initialize(cachePath: cachePath);
    return sdk;
  }

  Future<void> _initialize({String? cachePath}) async {
    _logger.info(
      'Initializing DHIS2 SDK',
      tag: 'Dhis2Sdk',
      data: {'baseUrl': _config.baseUrl},
    );

    // Initialize cache manager
    _cacheManager = CacheManager(
      logger: _logger,
      maxEntries: _options.maxCacheEntries,
      defaultDuration: _options.defaultCacheDuration,
    );
    await _cacheManager.initialize(path: cachePath);

    // Initialize HTTP client
    _httpClient = Dhis2HttpClient(
      baseUrl: _config.baseUrl,
      logger: _logger,
      connectTimeout: _options.connectTimeout,
      receiveTimeout: _options.receiveTimeout,
    );

    // Initialize auth service
    _authService = AuthService(
      httpClient: _httpClient,
      cacheManager: _cacheManager,
      logger: _logger,
    );

    // Set initial credentials if provided
    if (_config.credentials != null) {
      await _authService.setCredentials(_config.credentials!);
    }

    // Initialize connectivity manager
    _connectivityManager = ConnectivityManager(
      httpClient: _httpClient,
      logger: _logger,
    );

    // Initialize sync manager
    _syncManager = SyncManager(
      httpClient: _httpClient,
      cacheManager: _cacheManager,
      connectivityManager: _connectivityManager,
      logger: _logger,
    );

    // Initialize services
    _analyticsService = AnalyticsService(
      httpClient: _httpClient,
      cacheManager: _cacheManager,
      logger: _logger,
    );

    _metadataService = MetadataService(
      httpClient: _httpClient,
      cacheManager: _cacheManager,
      logger: _logger,
    );

    // Initialize transformers
    _chartTransformer = ChartTransformer(logger: _logger);
    _tableTransformer = TableTransformer(logger: _logger);

    // Start connectivity monitoring if enabled
    if (_options.enableConnectivityMonitoring) {
      _connectivityManager.startMonitoring();
    }

    _isInitialized = true;
    
    _logger.info(
      'DHIS2 SDK initialized successfully',
      tag: 'Dhis2Sdk',
    );
  }

  /// Ensure the SDK is initialized before use.
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'DHIS2 SDK not initialized. Call Dhis2Sdk.initialize() first.',
      );
    }
  }

  // ============================================================
  // Public Accessors
  // ============================================================

  /// Authentication service for login, logout, and session management.
  AuthService get auth {
    _ensureInitialized();
    return _authService;
  }

  /// Analytics service for querying DHIS2 analytics.
  AnalyticsService get analytics {
    _ensureInitialized();
    return _analyticsService;
  }

  /// Metadata service for organisation units, data elements, etc.
  MetadataService get metadata {
    _ensureInitialized();
    return _metadataService;
  }

  /// Sync manager for offline data synchronization.
  SyncManager get sync {
    _ensureInitialized();
    return _syncManager;
  }

  /// Connectivity manager for network status monitoring.
  ConnectivityManager get connectivity {
    _ensureInitialized();
    return _connectivityManager;
  }

  /// Cache manager for data caching operations.
  CacheManager get cache {
    _ensureInitialized();
    return _cacheManager;
  }

  /// Chart transformer for converting analytics to chart data.
  ChartTransformer get chartTransformer {
    _ensureInitialized();
    return _chartTransformer;
  }

  /// Table transformer for converting analytics to table data.
  TableTransformer get tableTransformer {
    _ensureInitialized();
    return _tableTransformer;
  }

  /// SDK configuration.
  Dhis2Config get config => _config;

  /// SDK options.
  SdkOptions get options => _options;

  /// Whether the SDK is initialized.
  bool get isInitialized => _isInitialized;

  /// Whether the user is authenticated.
  bool get isAuthenticated => _authService.isAuthenticated;

  /// Current authentication state.
  AuthState get authState => _authService.authState;

  /// Stream of authentication state changes.
  Stream<AuthState> get authStateStream => _authService.authStateStream;

  /// Current user (if authenticated).
  User? get currentUser => _authService.currentUser;

  /// Current connectivity status.
  bool get isOnline => _connectivityManager.isOnline;

  /// Stream of connectivity status changes.
  Stream<ConnectivityStatus> get connectivityStream => 
      _connectivityManager.connectivityStream;

  /// Current sync status.
  SyncStatus get syncStatus => _syncManager.currentStatus;

  /// Stream of sync status changes.
  Stream<SyncStatus> get syncStatusStream => _syncManager.syncStatusStream;

  // ============================================================
  // Convenience Methods
  // ============================================================

  /// Create a new analytics query builder.
  AnalyticsQueryBuilder queryAnalytics() {
    _ensureInitialized();
    return _analyticsService.query();
  }

  /// Perform a full data sync.
  Future<SyncResult> performSync() {
    _ensureInitialized();
    return _syncManager.sync();
  }

  /// Clear all cached data.
  Future<void> clearCache() async {
    _ensureInitialized();
    await _cacheManager.clear();
    _logger.info('Cache cleared', tag: 'Dhis2Sdk');
  }

  /// Get cache statistics.
  Future<CacheStats> getCacheStats() {
    _ensureInitialized();
    return _cacheManager.getStats();
  }

  /// Logout and clear session.
  Future<void> logout() async {
    _ensureInitialized();
    await _authService.logout();
    await _cacheManager.clear();
    _logger.info('User logged out', tag: 'Dhis2Sdk');
  }

  /// Dispose of all resources.
  Future<void> dispose() async {
    _logger.info('Disposing DHIS2 SDK', tag: 'Dhis2Sdk');
    
    _connectivityManager.dispose();
    _syncManager.dispose();
    await _cacheManager.close();
    _httpClient.dispose();
    
    _isInitialized = false;
  }
}
