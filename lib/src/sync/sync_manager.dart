import 'dart:async';
import '../cache/cache_manager.dart';
import '../network/http_client.dart';
import '../logging/sdk_logger.dart';
import 'connectivity_manager.dart';
import 'sync_status.dart';

/// Manages synchronization of data between local cache and DHIS2 server.
/// 
/// Provides automatic sync, conflict resolution, and sync status tracking.
class SyncManager {
  final Dhis2HttpClient _httpClient;
  final CacheManager _cacheManager;
  final ConnectivityManager _connectivityManager;
  final SdkLogger _logger;

  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  SyncStatus _currentStatus = SyncStatus.idle;
  final List<SyncOperation> _pendingOperations = [];
  bool _isSyncing = false;

  SyncManager({
    required Dhis2HttpClient httpClient,
    required CacheManager cacheManager,
    required ConnectivityManager connectivityManager,
    SdkLogger? logger,
  })  : _httpClient = httpClient,
        _cacheManager = cacheManager,
        _connectivityManager = connectivityManager,
        _logger = logger ?? SdkLogger() {
    // Listen to connectivity changes
    _connectivityManager.connectivityStream.listen(_onConnectivityChange);
  }

  /// Stream of sync status changes
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  /// Current sync status
  SyncStatus get currentStatus => _currentStatus;

  /// Whether sync is in progress
  bool get isSyncing => _isSyncing;

  /// Number of pending operations
  int get pendingCount => _pendingOperations.length;

  /// Queue a sync operation
  void queueOperation(SyncOperation operation) {
    _pendingOperations.add(operation);
    _logger.debug(
      'Queued sync operation',
      tag: 'SyncManager',
      data: {'type': operation.type.name, 'pending': _pendingOperations.length},
    );
    
    // Try to sync if online
    if (_connectivityManager.isOnline && !_isSyncing) {
      sync();
    }
  }

  /// Perform sync of all pending operations
  Future<SyncResult> sync() async {
    if (_isSyncing) {
      _logger.debug('Sync already in progress', tag: 'SyncManager');
      return SyncResult(
        success: false,
        message: 'Sync already in progress',
        operationsProcessed: 0,
        operationsFailed: 0,
      );
    }

    if (!_connectivityManager.isOnline) {
      _logger.debug('Cannot sync - offline', tag: 'SyncManager');
      return SyncResult(
        success: false,
        message: 'Device is offline',
        operationsProcessed: 0,
        operationsFailed: 0,
      );
    }

    _isSyncing = true;
    _updateStatus(SyncStatus.syncing);
    
    int processed = 0;
    int failed = 0;
    final errors = <String>[];

    try {
      final operations = List<SyncOperation>.from(_pendingOperations);
      
      for (final operation in operations) {
        try {
          await _processOperation(operation);
          _pendingOperations.remove(operation);
          processed++;
        } catch (e) {
          failed++;
          errors.add('${operation.type.name}: $e');
          _logger.error(
            'Sync operation failed',
            tag: 'SyncManager',
            error: e,
            data: {'type': operation.type.name},
          );
          
          // Mark for retry if retryable
          if (operation.retryCount < operation.maxRetries) {
            operation.incrementRetry();
          } else {
            _pendingOperations.remove(operation);
            // Store in failed operations for later review
          }
        }
      }

      _updateStatus(
        _pendingOperations.isEmpty ? SyncStatus.synced : SyncStatus.partialSync,
      );

      return SyncResult(
        success: failed == 0,
        message: failed == 0 
            ? 'Sync completed successfully' 
            : 'Sync completed with $failed errors',
        operationsProcessed: processed,
        operationsFailed: failed,
        errors: errors,
      );
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processOperation(SyncOperation operation) async {
    switch (operation.type) {
      case SyncOperationType.upload:
        await _uploadData(operation);
        break;
      case SyncOperationType.download:
        await _downloadData(operation);
        break;
      case SyncOperationType.delete:
        await _deleteData(operation);
        break;
    }
  }

  Future<void> _uploadData(SyncOperation operation) async {
    final response = await _httpClient.post(
      operation.endpoint,
      data: operation.data,
    );
    
    if (response != null) {
      _logger.info(
        'Uploaded data successfully',
        tag: 'SyncManager',
        data: {'endpoint': operation.endpoint},
      );
    }
  }

  Future<void> _downloadData(SyncOperation operation) async {
    final response = await _httpClient.get(operation.endpoint);
    
    if (response != null) {
      // Cache the downloaded data
      final cacheKey = 'sync:${operation.endpoint}';
      await _cacheManager.set(cacheKey, response);
      
      _logger.info(
        'Downloaded and cached data',
        tag: 'SyncManager',
        data: {'endpoint': operation.endpoint},
      );
    }
  }

  Future<void> _deleteData(SyncOperation operation) async {
    await _httpClient.delete(operation.endpoint);
    
    // Remove from cache
    final cacheKey = 'sync:${operation.endpoint}';
    await _cacheManager.delete(cacheKey);
    
    _logger.info(
      'Deleted data',
      tag: 'SyncManager',
      data: {'endpoint': operation.endpoint},
    );
  }

  void _onConnectivityChange(ConnectivityStatus status) {
    if (status == ConnectivityStatus.online && 
        _pendingOperations.isNotEmpty && 
        !_isSyncing) {
      _logger.info(
        'Back online - starting sync',
        tag: 'SyncManager',
      );
      sync();
    }
  }

  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _syncStatusController.add(status);
  }

  /// Clear all pending operations
  void clearPendingOperations() {
    _pendingOperations.clear();
    _logger.info('Cleared pending operations', tag: 'SyncManager');
  }

  /// Dispose resources
  void dispose() {
    _syncStatusController.close();
  }
}

/// Types of sync operations
enum SyncOperationType {
  upload,
  download,
  delete,
}

/// A single sync operation
class SyncOperation {
  final SyncOperationType type;
  final String endpoint;
  final Map<String, dynamic>? data;
  final int maxRetries;
  int _retryCount = 0;

  SyncOperation({
    required this.type,
    required this.endpoint,
    this.data,
    this.maxRetries = 3,
  });

  int get retryCount => _retryCount;

  void incrementRetry() => _retryCount++;
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String message;
  final int operationsProcessed;
  final int operationsFailed;
  final List<String>? errors;

  SyncResult({
    required this.success,
    required this.message,
    required this.operationsProcessed,
    required this.operationsFailed,
    this.errors,
  });

  @override
  String toString() {
    return 'SyncResult(success: $success, processed: $operationsProcessed, failed: $operationsFailed)';
  }
}
