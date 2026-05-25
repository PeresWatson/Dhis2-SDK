import 'dart:async';
import '../network/http_client.dart';
import '../logging/sdk_logger.dart';

/// Monitors network connectivity and provides sync status.
class ConnectivityManager {
  final Dhis2HttpClient _httpClient;
  final SdkLogger _logger;
  final Duration checkInterval;
  
  Timer? _connectivityTimer;
  final _connectivityController = StreamController<ConnectivityStatus>.broadcast();
  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;

  ConnectivityManager({
    required Dhis2HttpClient httpClient,
    SdkLogger? logger,
    this.checkInterval = const Duration(seconds: 30),
  })  : _httpClient = httpClient,
        _logger = logger ?? SdkLogger();

  /// Stream of connectivity status changes
  Stream<ConnectivityStatus> get connectivityStream => 
      _connectivityController.stream;

  /// Current connectivity status
  ConnectivityStatus get currentStatus => _currentStatus;

  /// Whether currently online
  bool get isOnline => _currentStatus == ConnectivityStatus.online;

  /// Start monitoring connectivity
  void startMonitoring() {
    _logger.info('Starting connectivity monitoring', tag: 'Connectivity');
    
    // Initial check
    checkConnectivity();
    
    // Periodic checks
    _connectivityTimer = Timer.periodic(checkInterval, (_) {
      checkConnectivity();
    });
  }

  /// Stop monitoring connectivity
  void stopMonitoring() {
    _connectivityTimer?.cancel();
    _connectivityTimer = null;
    _logger.info('Stopped connectivity monitoring', tag: 'Connectivity');
  }

  /// Check connectivity status
  Future<ConnectivityStatus> checkConnectivity() async {
    try {
      // Try to reach the DHIS2 server
      final response = await _httpClient.get(
        '/api/system/ping',
        options: RequestOptions(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      final newStatus = response != null 
          ? ConnectivityStatus.online 
          : ConnectivityStatus.offline;
      
      _updateStatus(newStatus);
      return newStatus;
    } catch (e) {
      _logger.debug(
        'Connectivity check failed',
        tag: 'Connectivity',
        data: {'error': e.toString()},
      );
      _updateStatus(ConnectivityStatus.offline);
      return ConnectivityStatus.offline;
    }
  }

  void _updateStatus(ConnectivityStatus newStatus) {
    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      _connectivityController.add(newStatus);
      
      _logger.info(
        'Connectivity status changed',
        tag: 'Connectivity',
        data: {'status': newStatus.name},
      );
    }
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _connectivityController.close();
  }
}

/// Placeholder for Dio RequestOptions used in connectivity check
class RequestOptions {
  final Duration? receiveTimeout;
  final Duration? sendTimeout;

  RequestOptions({this.receiveTimeout, this.sendTimeout});
}

/// Connectivity status enum
enum ConnectivityStatus {
  unknown,
  online,
  offline,
}

/// Extension methods for ConnectivityStatus
extension ConnectivityStatusExtension on ConnectivityStatus {
  bool get isKnown => this != ConnectivityStatus.unknown;
  
  String get displayName {
    switch (this) {
      case ConnectivityStatus.unknown:
        return 'Unknown';
      case ConnectivityStatus.online:
        return 'Online';
      case ConnectivityStatus.offline:
        return 'Offline';
    }
  }
}
