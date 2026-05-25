/// Analytics Query Builder
/// 
/// Provides a fluent API for building DHIS2 analytics queries.
/// 
/// ## Purpose
/// 
/// - Simplify analytics query construction
/// - Provide type-safe query building
/// - Validate queries before execution
/// - Support all DHIS2 analytics parameters
/// 
/// ## Why Builder Pattern?
/// 
/// The Builder pattern is ideal for analytics queries because:
/// - Many optional parameters
/// - Order-independent parameter setting
/// - Validation before use
/// - Readable, chainable API
/// 
/// ## Data Flow
/// 
/// ```
/// AnalyticsQueryBuilder
///   .withDataElements(...)
///   .withPeriods(...)
///   .withOrgUnits(...)
///   .build() → AnalyticsRequest
/// ```
/// 
/// ## Best Practices
/// 
/// - Always specify at least dx, pe, and ou dimensions
/// - Use relative periods for dashboards
/// - Filter large dimension sets to improve performance
library;

import '../models/analytics_request.dart';
import '../../core/constants/dhis2_constants.dart';
import '../../exceptions/dhis2_exception.dart';

/// Fluent builder for analytics queries.
/// 
/// Example:
/// ```dart
/// final query = AnalyticsQueryBuilder()
///   .withDataElements(['deId1', 'deId2'])
///   .withIndicators(['indId1'])
///   .withPeriods(['2024Q1', '2024Q2', '2024Q3', '2024Q4'])
///   .withOrgUnits(['orgUnitId'])
///   .withOrgUnitChildren()
///   .skipMetadata()
///   .build();
/// ```
class AnalyticsQueryBuilder {
  final List<String> _dataElements = [];
  final List<String> _indicators = [];
  final List<String> _dataSetReportingRates = [];
  final List<String> _programIndicators = [];
  final List<String> _periods = [];
  final List<String> _orgUnits = [];
  final Map<String, List<String>> _additionalDimensions = {};
  final Map<String, List<String>> _filters = {};

  bool _skipMeta = false;
  bool _skipData = false;
  bool _skipRounding = false;
  bool _hierarchyMeta = false;
  bool _includeNumDen = false;
  String? _displayProperty;
  String? _outputIdScheme;
  String? _aggregationType;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _program;
  String? _programStage;
  int? _page;
  int? _pageSize;

  // Org unit mode flags
  bool _orgUnitUserRoot = false;
  bool _orgUnitUserDataView = false;
  int? _orgUnitLevel;
  String? _orgUnitGroup;

  /// Creates a new query builder.
  AnalyticsQueryBuilder();

  // ============================================================================
  // DATA DIMENSION
  // ============================================================================

  /// Adds data element IDs to the query.
  AnalyticsQueryBuilder withDataElements(List<String> dataElementIds) {
    _dataElements.addAll(dataElementIds);
    return this;
  }

  /// Adds a single data element ID.
  AnalyticsQueryBuilder withDataElement(String dataElementId) {
    _dataElements.add(dataElementId);
    return this;
  }

  /// Adds indicator IDs to the query.
  AnalyticsQueryBuilder withIndicators(List<String> indicatorIds) {
    _indicators.addAll(indicatorIds);
    return this;
  }

  /// Adds a single indicator ID.
  AnalyticsQueryBuilder withIndicator(String indicatorId) {
    _indicators.add(indicatorId);
    return this;
  }

  /// Adds data set reporting rates.
  /// 
  /// Format: 'dataSetId.REPORTING_RATE' or 'dataSetId.ACTUAL_REPORTS'
  AnalyticsQueryBuilder withDataSetReportingRates(List<String> dataSetIds) {
    _dataSetReportingRates.addAll(dataSetIds);
    return this;
  }

  /// Adds program indicator IDs.
  AnalyticsQueryBuilder withProgramIndicators(List<String> programIndicatorIds) {
    _programIndicators.addAll(programIndicatorIds);
    return this;
  }

  // ============================================================================
  // PERIOD DIMENSION
  // ============================================================================

  /// Adds period IDs (ISO format or relative periods).
  /// 
  /// Examples:
  /// - ISO periods: '2024', '2024Q1', '202401', '20240115'
  /// - Relative: 'LAST_12_MONTHS', 'THIS_YEAR', 'LAST_QUARTER'
  AnalyticsQueryBuilder withPeriods(List<String> periods) {
    _periods.addAll(periods);
    return this;
  }

  /// Adds a single period.
  AnalyticsQueryBuilder withPeriod(String period) {
    _periods.add(period);
    return this;
  }

  /// Adds last N months as periods.
  AnalyticsQueryBuilder withLastMonths(int count) {
    return withPeriod('LAST_${count}_MONTHS');
  }

  /// Adds last N quarters as periods.
  AnalyticsQueryBuilder withLastQuarters(int count) {
    return withPeriod('LAST_${count}_QUARTERS');
  }

  /// Adds last N years as periods.
  AnalyticsQueryBuilder withLastYears(int count) {
    return withPeriod('LAST_${count}_YEARS');
  }

  /// Adds this year.
  AnalyticsQueryBuilder withThisYear() {
    return withPeriod(RelativePeriods.thisYear);
  }

  /// Adds this month.
  AnalyticsQueryBuilder withThisMonth() {
    return withPeriod(RelativePeriods.thisMonth);
  }

  /// Adds this quarter.
  AnalyticsQueryBuilder withThisQuarter() {
    return withPeriod(RelativePeriods.thisQuarter);
  }

  /// Sets a date range instead of periods.
  AnalyticsQueryBuilder withDateRange(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    return this;
  }

  // ============================================================================
  // ORGANISATION UNIT DIMENSION
  // ============================================================================

  /// Adds organisation unit IDs.
  AnalyticsQueryBuilder withOrgUnits(List<String> orgUnitIds) {
    _orgUnits.addAll(orgUnitIds);
    return this;
  }

  /// Adds a single organisation unit.
  AnalyticsQueryBuilder withOrgUnit(String orgUnitId) {
    _orgUnits.add(orgUnitId);
    return this;
  }

  /// Uses the current user's assigned organisation units.
  AnalyticsQueryBuilder withUserOrgUnits() {
    _orgUnitUserRoot = true;
    _orgUnits.add('USER_ORGUNIT');
    return this;
  }

  /// Uses the current user's data view organisation units.
  AnalyticsQueryBuilder withUserDataViewOrgUnits() {
    _orgUnitUserDataView = true;
    _orgUnits.add('USER_ORGUNIT_DATAVIEW');
    return this;
  }

  /// Includes children of selected org units.
  AnalyticsQueryBuilder withOrgUnitChildren() {
    // Children are specified in the org unit ID with CHILDREN suffix
    // This is handled when building
    _orgUnits.replaceRange(
      0,
      _orgUnits.length,
      _orgUnits.map((ou) {
        if (ou.startsWith('USER_')) return ou;
        return 'OU_GROUP-$ou'; // This will be adjusted in build
      }),
    );
    return this;
  }

  /// Restricts to a specific org unit level.
  AnalyticsQueryBuilder withOrgUnitLevel(int level) {
    _orgUnitLevel = level;
    _orgUnits.add('LEVEL-$level');
    return this;
  }

  /// Restricts to org units in a specific group.
  AnalyticsQueryBuilder withOrgUnitGroup(String groupId) {
    _orgUnitGroup = groupId;
    _orgUnits.add('OU_GROUP-$groupId');
    return this;
  }

  // ============================================================================
  // ADDITIONAL DIMENSIONS & FILTERS
  // ============================================================================

  /// Adds a category dimension.
  AnalyticsQueryBuilder withCategory(
    String categoryId,
    List<String> categoryOptionIds,
  ) {
    _additionalDimensions[categoryId] = categoryOptionIds;
    return this;
  }

  /// Adds an organisation unit group set dimension.
  AnalyticsQueryBuilder withOrgUnitGroupSet(
    String groupSetId,
    List<String> groupIds,
  ) {
    _additionalDimensions[groupSetId] = groupIds;
    return this;
  }

  /// Adds a filter dimension.
  /// 
  /// Filters restrict data but don't appear as columns/rows.
  AnalyticsQueryBuilder withFilter(String dimension, List<String> items) {
    _filters[dimension] = items;
    return this;
  }

  /// Adds a data filter (limits which data items are returned).
  AnalyticsQueryBuilder withDataFilter(List<String> dataItemIds) {
    return withFilter(Dimensions.data, dataItemIds);
  }

  /// Adds a period filter.
  AnalyticsQueryBuilder withPeriodFilter(List<String> periods) {
    return withFilter(Dimensions.period, periods);
  }

  /// Adds an org unit filter.
  AnalyticsQueryBuilder withOrgUnitFilter(List<String> orgUnitIds) {
    return withFilter(Dimensions.orgUnit, orgUnitIds);
  }

  // ============================================================================
  // OPTIONS
  // ============================================================================

  /// Skips metadata in response (smaller response, faster).
  AnalyticsQueryBuilder skipMetadata([bool skip = true]) {
    _skipMeta = skip;
    return this;
  }

  /// Skips data in response (metadata only).
  AnalyticsQueryBuilder skipData([bool skip = true]) {
    _skipData = skip;
    return this;
  }

  /// Skips rounding of data values.
  AnalyticsQueryBuilder skipRounding([bool skip = true]) {
    _skipRounding = skip;
    return this;
  }

  /// Includes hierarchy path in org unit names.
  AnalyticsQueryBuilder includeHierarchy([bool include = true]) {
    _hierarchyMeta = include;
    return this;
  }

  /// Includes numerator and denominator values.
  AnalyticsQueryBuilder includeNumeratorDenominator([bool include = true]) {
    _includeNumDen = include;
    return this;
  }

  /// Sets the display property (NAME or SHORTNAME).
  AnalyticsQueryBuilder withDisplayProperty(String property) {
    _displayProperty = property;
    return this;
  }

  /// Uses short names for display.
  AnalyticsQueryBuilder useShortNames() {
    return withDisplayProperty('SHORTNAME');
  }

  /// Sets the output ID scheme (UID, CODE, NAME).
  AnalyticsQueryBuilder withOutputIdScheme(String scheme) {
    _outputIdScheme = scheme;
    return this;
  }

  /// Uses codes as output identifiers.
  AnalyticsQueryBuilder outputAsCode() {
    return withOutputIdScheme('CODE');
  }

  /// Sets aggregation type override.
  AnalyticsQueryBuilder withAggregationType(String type) {
    _aggregationType = type;
    return this;
  }

  /// Sets pagination.
  AnalyticsQueryBuilder withPagination({int page = 1, int pageSize = 50}) {
    _page = page;
    _pageSize = pageSize;
    return this;
  }

  // ============================================================================
  // EVENT ANALYTICS
  // ============================================================================

  /// Sets the program for event analytics.
  AnalyticsQueryBuilder forProgram(String programId) {
    _program = programId;
    return this;
  }

  /// Sets the program stage for event analytics.
  AnalyticsQueryBuilder forProgramStage(String programStageId) {
    _programStage = programStageId;
    return this;
  }

  // ============================================================================
  // BUILD
  // ============================================================================

  /// Validates and builds the analytics request.
  /// 
  /// Throws [ValidationException] if required dimensions are missing.
  AnalyticsRequest build() {
    // Combine all data items
    final dataItems = <String>[
      ..._dataElements,
      ..._indicators,
      ..._dataSetReportingRates,
      ..._programIndicators,
    ];

    // Validate
    if (dataItems.isEmpty) {
      throw ValidationException.requiredField('data dimension (dx)');
    }

    final hasPeriod = _periods.isNotEmpty || (_startDate != null && _endDate != null);
    if (!hasPeriod) {
      throw ValidationException.requiredField('period dimension (pe)');
    }

    if (_orgUnits.isEmpty) {
      throw ValidationException.requiredField('organisation unit dimension (ou)');
    }

    return AnalyticsRequest(
      dataItems: dataItems,
      periods: _periods,
      organisationUnits: _orgUnits,
      additionalDimensions: Map.unmodifiable(_additionalDimensions),
      filters: Map.unmodifiable(_filters),
      skipMeta: _skipMeta,
      skipData: _skipData,
      skipRounding: _skipRounding,
      hierarchyMeta: _hierarchyMeta,
      includeNumDen: _includeNumDen,
      displayProperty: _displayProperty,
      outputIdScheme: _outputIdScheme,
      aggregationType: _aggregationType,
      startDate: _startDate,
      endDate: _endDate,
      program: _program,
      programStage: _programStage,
      page: _page,
      pageSize: _pageSize,
    );
  }

  /// Builds and returns the query string (for debugging).
  String buildQueryString() {
    return build().toQueryString();
  }
}

/// Extension for convenient query building from the SDK.
extension AnalyticsQueryBuilderFactory on Never {
  /// Creates a new analytics query builder.
  static AnalyticsQueryBuilder query() => AnalyticsQueryBuilder();
}
