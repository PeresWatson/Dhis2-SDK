/// DHIS2 API Endpoints
/// 
/// Centralized definition of all DHIS2 API endpoints used by the SDK.
/// 
/// ## Purpose
/// 
/// - Single source of truth for API paths
/// - Easy version-specific endpoint handling
/// - Simplifies testing with mock endpoints
/// - Documents available API capabilities
/// 
/// ## Organization
/// 
/// Endpoints are grouped by domain:
/// - Authentication & System
/// - Analytics
/// - Metadata
/// - Dashboards & Visualizations
/// - Organization Units
/// 
/// ## Best Practices
/// 
/// - Always use these constants instead of hardcoded strings
/// - Use interpolation methods for dynamic segments
/// - Check DHIS2 docs when adding new endpoints
library;

/// Contains all DHIS2 API endpoint paths.
/// 
/// All paths are relative to the base API URL.
/// Example: Full URL = baseUrl + '/api/' + version + endpoint
abstract class ApiEndpoints {
  // ============================================================================
  // AUTHENTICATION & SYSTEM
  // ============================================================================

  /// Get current authenticated user details.
  /// GET /me
  static const String me = '/me';

  /// Get current user with specific fields.
  /// GET /me?fields=...
  static String meWithFields(List<String> fields) =>
      '/me?fields=${fields.join(',')}';

  /// System info endpoint.
  /// GET /system/info
  static const String systemInfo = '/system/info';

  /// Login endpoint (basic auth is typically used).
  /// This is mainly for documentation - auth is via headers.
  static const String login = '/me';

  /// Check if session is valid.
  /// GET /me (returns 401 if invalid)
  static const String sessionCheck = '/me';

  // ============================================================================
  // ANALYTICS
  // ============================================================================

  /// Main analytics endpoint.
  /// GET /analytics
  static const String analytics = '/analytics';

  /// Analytics with output in specific format.
  /// GET /analytics.json, /analytics.csv, etc.
  static String analyticsFormat(String format) => '/analytics.$format';

  /// Raw data analytics (event-level data).
  /// GET /analytics/rawData
  static const String analyticsRawData = '/analytics/rawData';

  /// Analytics for events/tracker programs.
  /// GET /analytics/events/query/{programId}
  static String analyticsEvents(String programId) =>
      '/analytics/events/query/$programId';

  /// Analytics for enrollments.
  /// GET /analytics/enrollments/query/{programId}
  static String analyticsEnrollments(String programId) =>
      '/analytics/enrollments/query/$programId';

  /// Aggregate analytics for programs.
  /// GET /analytics/events/aggregate/{programId}
  static String analyticsEventsAggregate(String programId) =>
      '/analytics/events/aggregate/$programId';

  // ============================================================================
  // METADATA
  // ============================================================================

  /// Data elements endpoint.
  /// GET /dataElements
  static const String dataElements = '/dataElements';

  /// Single data element.
  /// GET /dataElements/{id}
  static String dataElement(String id) => '/dataElements/$id';

  /// Indicators endpoint.
  /// GET /indicators
  static const String indicators = '/indicators';

  /// Single indicator.
  /// GET /indicators/{id}
  static String indicator(String id) => '/indicators/$id';

  /// Data sets endpoint.
  /// GET /dataSets
  static const String dataSets = '/dataSets';

  /// Single data set.
  /// GET /dataSets/{id}
  static String dataSet(String id) => '/dataSets/$id';

  /// Programs endpoint.
  /// GET /programs
  static const String programs = '/programs';

  /// Single program.
  /// GET /programs/{id}
  static String program(String id) => '/programs/$id';

  /// Program stages.
  /// GET /programStages
  static const String programStages = '/programStages';

  /// Categories endpoint.
  /// GET /categories
  static const String categories = '/categories';

  /// Category options endpoint.
  /// GET /categoryOptions
  static const String categoryOptions = '/categoryOptions';

  /// Category combos endpoint.
  /// GET /categoryCombos
  static const String categoryCombos = '/categoryCombos';

  /// Data element groups.
  /// GET /dataElementGroups
  static const String dataElementGroups = '/dataElementGroups';

  /// Indicator groups.
  /// GET /indicatorGroups
  static const String indicatorGroups = '/indicatorGroups';

  // ============================================================================
  // ORGANISATION UNITS
  // ============================================================================

  /// Organisation units endpoint.
  /// GET /organisationUnits
  static const String organisationUnits = '/organisationUnits';

  /// Single organisation unit.
  /// GET /organisationUnits/{id}
  static String organisationUnit(String id) => '/organisationUnits/$id';

  /// Organisation unit levels.
  /// GET /organisationUnitLevels
  static const String organisationUnitLevels = '/organisationUnitLevels';

  /// Organisation unit groups.
  /// GET /organisationUnitGroups
  static const String organisationUnitGroups = '/organisationUnitGroups';

  /// Organisation unit group sets.
  /// GET /organisationUnitGroupSets
  static const String organisationUnitGroupSets = '/organisationUnitGroupSets';

  /// User's assigned organisation units.
  /// Accessed via /me endpoint
  static const String userOrgUnits = '/me?fields=organisationUnits[id,name,level,path]';

  // ============================================================================
  // DASHBOARDS & VISUALIZATIONS
  // ============================================================================

  /// Dashboards endpoint.
  /// GET /dashboards
  static const String dashboards = '/dashboards';

  /// Single dashboard.
  /// GET /dashboards/{id}
  static String dashboard(String id) => '/dashboards/$id';

  /// Visualizations endpoint (charts, tables, maps).
  /// GET /visualizations
  static const String visualizations = '/visualizations';

  /// Single visualization.
  /// GET /visualizations/{id}
  static String visualization(String id) => '/visualizations/$id';

  /// Visualization data.
  /// GET /visualizations/{id}/data
  static String visualizationData(String id) => '/visualizations/$id/data';

  /// Maps endpoint.
  /// GET /maps
  static const String maps = '/maps';

  /// Single map.
  /// GET /maps/{id}
  static String map(String id) => '/maps/$id';

  /// Event charts.
  /// GET /eventCharts
  static const String eventCharts = '/eventCharts';

  /// Event reports.
  /// GET /eventReports
  static const String eventReports = '/eventReports';

  /// Report tables.
  /// GET /reportTables
  static const String reportTables = '/reportTables';

  // ============================================================================
  // DIMENSIONS
  // ============================================================================

  /// Dimensions endpoint (for analytics queries).
  /// GET /dimensions
  static const String dimensions = '/dimensions';

  /// Single dimension.
  /// GET /dimensions/{id}
  static String dimension(String id) => '/dimensions/$id';

  /// Dimension items for a dimension.
  /// GET /dimensions/{id}/items
  static String dimensionItems(String id) => '/dimensions/$id/items';

  // ============================================================================
  // PERIODS
  // ============================================================================

  /// Relative periods.
  /// GET /periodTypes
  static const String periodTypes = '/periodTypes';

  // ============================================================================
  // USER & PERMISSIONS
  // ============================================================================

  /// Current user authorities.
  /// GET /me?fields=authorities
  static const String userAuthorities = '/me?fields=authorities';

  /// Current user data view org units.
  /// GET /me?fields=dataViewOrganisationUnits
  static const String userDataViewOrgUnits =
      '/me?fields=dataViewOrganisationUnits[id,name,level]';

  /// User roles.
  /// GET /userRoles
  static const String userRoles = '/userRoles';

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Adds paging parameters to an endpoint.
  static String withPaging(String endpoint, int page, int pageSize) {
    final separator = endpoint.contains('?') ? '&' : '?';
    return '$endpoint${separator}page=$page&pageSize=$pageSize';
  }

  /// Adds fields parameter to an endpoint.
  static String withFields(String endpoint, List<String> fields) {
    final separator = endpoint.contains('?') ? '&' : '?';
    return '$endpoint${separator}fields=${fields.join(',')}';
  }

  /// Adds filter parameter to an endpoint.
  static String withFilter(String endpoint, String filter) {
    final separator = endpoint.contains('?') ? '&' : '?';
    return '$endpoint${separator}filter=$filter';
  }
}
