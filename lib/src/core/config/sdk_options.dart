/// SDK Runtime Options
/// 
/// These options control SDK behavior at runtime and can be
/// modified after initialization (unlike Dhis2Config).
/// 
/// ## Purpose
/// 
/// Provides flexible runtime configuration for:
/// - Pagination defaults
/// - Retry behavior
/// - Feature toggles
/// - Performance tuning
/// 
/// ## Why Separate from Dhis2Config?
/// 
/// Config = Static initialization settings (server URL, app name)
/// Options = Dynamic runtime behavior (page size, retries)
/// 
/// This separation allows changing behavior without re-initializing the SDK.
library;

import 'package:equatable/equatable.dart';

/// Runtime options for SDK behavior.
/// 
/// Example:
/// ```dart
/// final options = SdkOptions(
///   defaultPageSize: 50,
///   maxRetries: 3,
///   enableOfflineMode: true,
/// );
/// ```
class SdkOptions extends Equatable {
  /// Default number of items per page for paginated requests.
  /// 
  /// Higher values = fewer requests but more memory usage.
  /// Recommended: 50-100 for most use cases.
  final int defaultPageSize;

  /// Maximum page size allowed.
  /// 
  /// DHIS2 may limit this server-side, but this provides
  /// client-side validation.
  final int maxPageSize;

  /// Number of times to retry failed requests.
  /// 
  /// Applies to network errors, not HTTP error responses.
  final int maxRetries;

  /// Delay between retries in milliseconds.
  /// 
  /// Uses exponential backoff: delay * 2^attemptNumber
  final int retryDelayMs;

  /// Enable offline mode with local caching.
  /// 
  /// When enabled, SDK will serve cached data when offline
  /// and sync when connectivity is restored.
  final bool enableOfflineMode;

  /// Automatically refresh stale cache data.
  /// 
  /// When true, background refresh happens automatically
  /// based on cache age settings.
  final bool autoRefreshCache;

  /// Include metadata in analytics responses.
  /// 
  /// Adds dimension names, period labels, etc. to responses.
  /// Useful for display but increases response size.
  final bool includeMetadataInAnalytics;

  /// Preferred data output format for analytics.
  /// 
  /// Options: 'ANALYTICS', 'RAW_DATA'
  /// ANALYTICS is pre-aggregated, RAW_DATA is event-level.
  final String analyticsOutputFormat;

  /// Creates SDK options with sensible defaults.
  const SdkOptions({
    this.defaultPageSize = 50,
    this.maxPageSize = 1000,
    this.maxRetries = 3,
    this.retryDelayMs = 1000,
    this.enableOfflineMode = true,
    this.autoRefreshCache = true,
    this.includeMetadataInAnalytics = true,
    this.analyticsOutputFormat = 'ANALYTICS',
  });

  /// Default options instance.
  /// 
  /// Use this when you don't need custom options.
  static const SdkOptions defaults = SdkOptions();

  /// Creates a copy with modified values.
  SdkOptions copyWith({
    int? defaultPageSize,
    int? maxPageSize,
    int? maxRetries,
    int? retryDelayMs,
    bool? enableOfflineMode,
    bool? autoRefreshCache,
    bool? includeMetadataInAnalytics,
    String? analyticsOutputFormat,
  }) {
    return SdkOptions(
      defaultPageSize: defaultPageSize ?? this.defaultPageSize,
      maxPageSize: maxPageSize ?? this.maxPageSize,
      maxRetries: maxRetries ?? this.maxRetries,
      retryDelayMs: retryDelayMs ?? this.retryDelayMs,
      enableOfflineMode: enableOfflineMode ?? this.enableOfflineMode,
      autoRefreshCache: autoRefreshCache ?? this.autoRefreshCache,
      includeMetadataInAnalytics:
          includeMetadataInAnalytics ?? this.includeMetadataInAnalytics,
      analyticsOutputFormat:
          analyticsOutputFormat ?? this.analyticsOutputFormat,
    );
  }

  @override
  List<Object?> get props => [
        defaultPageSize,
        maxPageSize,
        maxRetries,
        retryDelayMs,
        enableOfflineMode,
        autoRefreshCache,
        includeMetadataInAnalytics,
        analyticsOutputFormat,
      ];
}
