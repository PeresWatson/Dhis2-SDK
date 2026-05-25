/// Base Service Class
/// 
/// Provides common functionality for all services in the SDK.
/// 
/// ## Purpose
/// 
/// - Standardize service initialization and disposal
/// - Provide access to shared dependencies (logger, config)
/// - Define service lifecycle methods
/// - Enable consistent error handling
/// 
/// ## Why Base Service?
/// 
/// Services contain business logic and coordinate between:
/// - Repositories (data access)
/// - Other services (cross-cutting concerns)
/// - External systems (APIs)
/// 
/// A base class ensures:
/// - Consistent initialization pattern
/// - Access to common utilities
/// - Predictable lifecycle management
/// 
/// ## Data Flow
/// 
/// ```
/// Dhis2Sdk → Service → Repository → Data Source
///          ↓
///    Logger, Config (from base class)
/// ```
/// 
/// ## Extension Points
/// 
/// - Override initialize() for custom setup
/// - Override dispose() for cleanup
/// - Add mixins for cross-cutting concerns
library;

import '../config/dhis2_config.dart';
import '../../logging/sdk_logger.dart';

/// Base class for all services in the SDK.
/// 
/// Example:
/// ```dart
/// class AnalyticsService extends BaseService {
///   AnalyticsService({required super.config, required super.logger});
/// 
///   @override
///   Future<void> initialize() async {
///     await super.initialize();
///     // Custom initialization
///   }
/// 
///   Future<AnalyticsResponse> query(AnalyticsRequest request) async {
///     logger.debug('Executing analytics query', request.toJson());
///     // ... implementation
///   }
/// }
/// ```
abstract class BaseService {
  /// SDK configuration.
  final Dhis2Config config;

  /// Logger instance for this service.
  final SdkLogger logger;

  /// Whether the service has been initialized.
  bool _isInitialized = false;

  /// Whether the service has been disposed.
  bool _isDisposed = false;

  /// Creates a new service instance.
  BaseService({
    required this.config,
    required this.logger,
  });

  /// Whether the service is ready to use.
  bool get isInitialized => _isInitialized;

  /// Whether the service has been disposed.
  bool get isDisposed => _isDisposed;

  /// Initializes the service.
  /// 
  /// Called automatically by the SDK during initialization.
  /// Override to add custom initialization logic.
  /// Always call super.initialize() first.
  Future<void> initialize() async {
    if (_isDisposed) {
      throw StateError('Cannot initialize a disposed service');
    }
    if (_isInitialized) {
      logger.warning('Service already initialized, skipping');
      return;
    }

    logger.debug('Initializing ${runtimeType.toString()}');
    _isInitialized = true;
  }

  /// Disposes the service and releases resources.
  /// 
  /// Called automatically by the SDK during shutdown.
  /// Override to add custom cleanup logic.
  /// Always call super.dispose() last.
  Future<void> dispose() async {
    if (_isDisposed) {
      logger.warning('Service already disposed, skipping');
      return;
    }

    logger.debug('Disposing ${runtimeType.toString()}');
    _isDisposed = true;
  }

  /// Ensures the service is initialized before use.
  /// 
  /// Call this at the start of public methods that require initialization.
  void ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        '${runtimeType.toString()} is not initialized. '
        'Call initialize() first or use Dhis2Sdk.initialize().',
      );
    }
    if (_isDisposed) {
      throw StateError(
        '${runtimeType.toString()} has been disposed and cannot be used.',
      );
    }
  }
}

/// Mixin for services that need periodic refresh capabilities.
/// 
/// Use this for services that fetch data that should be
/// refreshed on a schedule (e.g., metadata cache).
mixin RefreshableService on BaseService {
  /// Duration between automatic refreshes.
  Duration get refreshInterval;

  /// Timestamp of last refresh.
  DateTime? _lastRefresh;

  /// Whether auto-refresh is currently enabled.
  bool _autoRefreshEnabled = false;

  /// Timestamp of last successful refresh.
  DateTime? get lastRefresh => _lastRefresh;

  /// Starts automatic refresh at [refreshInterval].
  void startAutoRefresh() {
    if (_autoRefreshEnabled) return;
    _autoRefreshEnabled = true;
    _scheduleNextRefresh();
  }

  /// Stops automatic refresh.
  void stopAutoRefresh() {
    _autoRefreshEnabled = false;
  }

  /// Manually triggers a refresh.
  Future<void> refresh();

  void _scheduleNextRefresh() {
    if (!_autoRefreshEnabled) return;

    Future.delayed(refreshInterval, () async {
      if (_autoRefreshEnabled && !isDisposed) {
        await refresh();
        _lastRefresh = DateTime.now();
        _scheduleNextRefresh();
      }
    });
  }
}

/// Mixin for services that support offline operation.
mixin OfflineCapableService on BaseService {
  /// Whether the service is currently in offline mode.
  bool get isOffline;

  /// Called when connectivity changes.
  void onConnectivityChanged(bool isOnline);
}
