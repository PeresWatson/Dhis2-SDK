/// DHIS2 SDK Configuration
/// 
/// This class holds all configuration options needed to initialize
/// and connect to a DHIS2 instance.
/// 
/// ## Purpose
/// 
/// The configuration serves as the single source of truth for:
/// - Server connection details (URL, API version)
/// - Application identification
/// - Timeout settings
/// - Feature flags
/// 
/// ## Data Flow
/// 
/// ```
/// Dhis2Config → Dhis2Sdk.initialize() → All Services
/// ```
/// 
/// ## Extension Points
/// 
/// - Add custom headers via [additionalHeaders]
/// - Configure timeouts for slow connections
/// - Enable/disable features based on DHIS2 version
/// 
/// ## Best Practices
/// 
/// - Store sensitive config in environment variables
/// - Use different configs for dev/staging/production
/// - Validate baseUrl format before initialization
library;

import 'package:equatable/equatable.dart';

/// Configuration class for DHIS2 SDK initialization.
/// 
/// Example:
/// ```dart
/// final config = Dhis2Config(
///   baseUrl: 'https://play.dhis2.org/40',
///   appName: 'My Analytics App',
///   apiVersion: 40,
/// );
/// ```
class Dhis2Config extends Equatable {
  /// The base URL of the DHIS2 instance.
  /// 
  /// Should NOT include '/api' suffix - the SDK handles this.
  /// Example: 'https://play.dhis2.org/40'
  final String baseUrl;

  /// Human-readable name for your application.
  /// 
  /// Used in logging and potentially in user-agent headers.
  final String appName;

  /// The DHIS2 API version to target.
  /// 
  /// Defaults to 40 (latest stable as of SDK creation).
  /// The SDK adjusts API calls based on this version.
  final int apiVersion;

  /// Connection timeout in milliseconds.
  /// 
  /// How long to wait when establishing a connection.
  /// Increase for slow networks or distant servers.
  final int connectTimeoutMs;

  /// Receive timeout in milliseconds.
  /// 
  /// How long to wait for the server to send data.
  /// Analytics queries may need longer timeouts.
  final int receiveTimeoutMs;

  /// Send timeout in milliseconds.
  /// 
  /// How long to wait when sending data to server.
  final int sendTimeoutMs;

  /// Additional HTTP headers to include in all requests.
  /// 
  /// Useful for custom authentication or tracking headers.
  final Map<String, String> additionalHeaders;

  /// Enable verbose logging for debugging.
  /// 
  /// When true, all API requests/responses are logged.
  /// Should be false in production.
  final bool enableDebugLogging;

  /// Enable local caching of metadata.
  /// 
  /// Highly recommended for production apps to reduce
  /// API calls and improve performance.
  final bool enableCaching;

  /// Maximum age of cached data in hours.
  /// 
  /// After this duration, cached data is considered stale
  /// and will be refreshed on next access.
  final int cacheMaxAgeHours;

  /// Creates a new DHIS2 configuration.
  /// 
  /// Only [baseUrl] and [appName] are required.
  const Dhis2Config({
    required this.baseUrl,
    required this.appName,
    this.apiVersion = 40,
    this.connectTimeoutMs = 30000,
    this.receiveTimeoutMs = 60000,
    this.sendTimeoutMs = 30000,
    this.additionalHeaders = const {},
    this.enableDebugLogging = false,
    this.enableCaching = true,
    this.cacheMaxAgeHours = 24,
  });

  /// Returns the full API URL including version.
  /// 
  /// Example: 'https://play.dhis2.org/40/api/40'
  String get apiUrl => '$baseUrl/api/$apiVersion';

  /// Returns the base API URL without version.
  /// 
  /// Some endpoints don't use versioned paths.
  /// Example: 'https://play.dhis2.org/40/api'
  String get baseApiUrl => '$baseUrl/api';

  /// Creates a copy with modified values.
  /// 
  /// Useful for creating environment-specific configs.
  Dhis2Config copyWith({
    String? baseUrl,
    String? appName,
    int? apiVersion,
    int? connectTimeoutMs,
    int? receiveTimeoutMs,
    int? sendTimeoutMs,
    Map<String, String>? additionalHeaders,
    bool? enableDebugLogging,
    bool? enableCaching,
    int? cacheMaxAgeHours,
  }) {
    return Dhis2Config(
      baseUrl: baseUrl ?? this.baseUrl,
      appName: appName ?? this.appName,
      apiVersion: apiVersion ?? this.apiVersion,
      connectTimeoutMs: connectTimeoutMs ?? this.connectTimeoutMs,
      receiveTimeoutMs: receiveTimeoutMs ?? this.receiveTimeoutMs,
      sendTimeoutMs: sendTimeoutMs ?? this.sendTimeoutMs,
      additionalHeaders: additionalHeaders ?? this.additionalHeaders,
      enableDebugLogging: enableDebugLogging ?? this.enableDebugLogging,
      enableCaching: enableCaching ?? this.enableCaching,
      cacheMaxAgeHours: cacheMaxAgeHours ?? this.cacheMaxAgeHours,
    );
  }

  @override
  List<Object?> get props => [
        baseUrl,
        appName,
        apiVersion,
        connectTimeoutMs,
        receiveTimeoutMs,
        sendTimeoutMs,
        additionalHeaders,
        enableDebugLogging,
        enableCaching,
        cacheMaxAgeHours,
      ];

  @override
  String toString() => 'Dhis2Config(baseUrl: $baseUrl, appName: $appName, '
      'apiVersion: $apiVersion)';
}
