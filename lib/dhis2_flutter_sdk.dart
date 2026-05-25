/// DHIS2 Flutter SDK
/// 
/// A production-ready Flutter SDK for DHIS2 analytics, dashboards,
/// and read-only visualization systems.
/// 
/// ## Features
/// 
/// - **Authentication**: Secure login with token management
/// - **Analytics**: Powerful query builder for DHIS2 analytics API
/// - **Caching**: Intelligent metadata and data caching
/// - **Network**: Robust network handling with offline support
/// - **Visualization**: Transform analytics data into chart-ready formats
/// - **Organization Units**: Hierarchical org unit filtering
/// - **Logging**: Comprehensive debugging and logging system
/// 
/// ## Quick Start
/// 
/// ```dart
/// import 'package:dhis2_flutter_sdk/dhis2_flutter_sdk.dart';
/// 
/// void main() async {
///   // Initialize the SDK
///   final sdk = await Dhis2Sdk.initialize(
///     config: Dhis2Config(
///       baseUrl: 'https://play.dhis2.org/40',
///       appName: 'My Analytics App',
///     ),
///   );
/// 
///   // Authenticate
///   await sdk.auth.login(
///     username: 'admin',
///     password: 'district',
///   );
/// 
///   // Query analytics
///   final analytics = await sdk.analytics
///       .query()
///       .withDataElements(['dataElementId'])
///       .withPeriods(['2024Q1', '2024Q2'])
///       .withOrgUnits(['orgUnitId'])
///       .execute();
/// 
///   // Transform for visualization
///   final chartData = sdk.transformers.toChartData(analytics);
/// }
/// ```
/// 
/// ## Architecture
/// 
/// This SDK follows Clean Architecture principles with clear separation:
/// 
/// - **Core**: Configuration, constants, and base classes
/// - **Auth**: Authentication and session management
/// - **Analytics**: Query building and data retrieval
/// - **Caching**: Local storage and cache invalidation
/// - **Network**: HTTP client and connectivity handling
/// - **Models**: Data models and DTOs
/// - **Services**: Business logic and API abstractions
/// - **Transformers**: Data transformation for visualizations
/// - **Utils**: Helpers for periods, dates, and org units
/// 
/// ## DHIS2 API Version
/// 
/// This SDK targets DHIS2 API version 40+ with support for:
/// - Analytics API v2
/// - Metadata API
/// - Dashboard API
/// - Visualization API
library dhis2_flutter_sdk;

// ============================================================================
// CORE EXPORTS
// ============================================================================

// Configuration
export 'src/core/config/dhis2_config.dart';
export 'src/core/config/sdk_options.dart';

// Constants
export 'src/core/constants/api_endpoints.dart';
export 'src/core/constants/dhis2_constants.dart';

// Base Classes
export 'src/core/base/base_repository.dart';
export 'src/core/base/base_service.dart';
export 'src/core/base/result.dart';

// ============================================================================
// AUTHENTICATION EXPORTS
// ============================================================================

export 'src/auth/auth_service.dart';
export 'src/auth/auth_state.dart';
export 'src/auth/models/user.dart';
export 'src/auth/models/credentials.dart';

// ============================================================================
// ANALYTICS EXPORTS
// ============================================================================

export 'src/analytics/analytics_service.dart';
export 'src/analytics/query/analytics_query_builder.dart';
export 'src/analytics/models/analytics_response.dart';
export 'src/analytics/models/analytics_request.dart';

// ============================================================================
// CACHING EXPORTS
// ============================================================================

export 'src/caching/cache_service.dart';
export 'src/caching/cache_config.dart';

// ============================================================================
// NETWORK EXPORTS
// ============================================================================

export 'src/network/http_client.dart';
export 'src/network/connectivity_service.dart';
export 'src/network/interceptors/auth_interceptor.dart';

// ============================================================================
// MODELS EXPORTS
// ============================================================================

export 'src/models/metadata/data_element.dart';
export 'src/models/metadata/indicator.dart';
export 'src/models/metadata/organisation_unit.dart';
export 'src/models/metadata/period.dart';
export 'src/models/metadata/program.dart';
export 'src/models/dashboard/dashboard.dart';
export 'src/models/dashboard/dashboard_item.dart';
export 'src/models/visualization/visualization.dart';

// ============================================================================
// SERVICES EXPORTS
// ============================================================================

export 'src/services/metadata_service.dart';
export 'src/services/dashboard_service.dart';
export 'src/services/visualization_service.dart';
export 'src/services/org_unit_service.dart';

// ============================================================================
// TRANSFORMERS EXPORTS
// ============================================================================

export 'src/transformers/chart_transformer.dart';
export 'src/transformers/table_transformer.dart';
export 'src/transformers/map_transformer.dart';

// ============================================================================
// UTILS EXPORTS
// ============================================================================

export 'src/utils/period_utils.dart';
export 'src/utils/date_utils.dart';
export 'src/utils/org_unit_utils.dart';

// ============================================================================
// LOGGING EXPORTS
// ============================================================================

export 'src/logging/sdk_logger.dart';
export 'src/logging/log_level.dart';

// ============================================================================
// EXCEPTIONS EXPORTS
// ============================================================================

export 'src/exceptions/dhis2_exception.dart';
export 'src/exceptions/auth_exception.dart';
export 'src/exceptions/network_exception.dart';
export 'src/exceptions/cache_exception.dart';

// ============================================================================
// MAIN SDK CLASS
// ============================================================================

export 'src/dhis2_sdk.dart';
