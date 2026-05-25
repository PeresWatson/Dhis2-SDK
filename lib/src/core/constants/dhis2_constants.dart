/// DHIS2 Constants
/// 
/// Contains constant values used throughout the SDK that are
/// specific to DHIS2's data model and conventions.
/// 
/// ## Purpose
/// 
/// - Centralize magic strings and values
/// - Document DHIS2 conventions
/// - Ensure consistency across the SDK
/// - Simplify refactoring if DHIS2 changes
library;

/// Period type identifiers used in DHIS2.
/// 
/// These match DHIS2's internal period type codes.
abstract class PeriodTypes {
  static const String daily = 'Daily';
  static const String weekly = 'Weekly';
  static const String weeklyWednesday = 'WeeklyWednesday';
  static const String weeklyThursday = 'WeeklyThursday';
  static const String weeklySaturday = 'WeeklySaturday';
  static const String weeklySunday = 'WeeklySunday';
  static const String biWeekly = 'BiWeekly';
  static const String monthly = 'Monthly';
  static const String biMonthly = 'BiMonthly';
  static const String quarterly = 'Quarterly';
  static const String sixMonthly = 'SixMonthly';
  static const String sixMonthlyApril = 'SixMonthlyApril';
  static const String yearly = 'Yearly';
  static const String financialApril = 'FinancialApril';
  static const String financialJuly = 'FinancialJuly';
  static const String financialOct = 'FinancialOct';
  static const String financialNov = 'FinancialNov';
}

/// Relative period identifiers.
/// 
/// These are used in analytics queries to specify relative time ranges.
abstract class RelativePeriods {
  // Days
  static const String today = 'TODAY';
  static const String yesterday = 'YESTERDAY';
  static const String last3Days = 'LAST_3_DAYS';
  static const String last7Days = 'LAST_7_DAYS';
  static const String last14Days = 'LAST_14_DAYS';
  static const String last30Days = 'LAST_30_DAYS';
  static const String last60Days = 'LAST_60_DAYS';
  static const String last90Days = 'LAST_90_DAYS';
  static const String last180Days = 'LAST_180_DAYS';

  // Weeks
  static const String thisWeek = 'THIS_WEEK';
  static const String lastWeek = 'LAST_WEEK';
  static const String last4Weeks = 'LAST_4_WEEKS';
  static const String last12Weeks = 'LAST_12_WEEKS';
  static const String last52Weeks = 'LAST_52_WEEKS';

  // Months
  static const String thisMonth = 'THIS_MONTH';
  static const String lastMonth = 'LAST_MONTH';
  static const String last3Months = 'LAST_3_MONTHS';
  static const String last6Months = 'LAST_6_MONTHS';
  static const String last12Months = 'LAST_12_MONTHS';
  static const String monthsThisYear = 'MONTHS_THIS_YEAR';

  // Quarters
  static const String thisQuarter = 'THIS_QUARTER';
  static const String lastQuarter = 'LAST_QUARTER';
  static const String last4Quarters = 'LAST_4_QUARTERS';
  static const String quartersThisYear = 'QUARTERS_THIS_YEAR';

  // Years
  static const String thisYear = 'THIS_YEAR';
  static const String lastYear = 'LAST_YEAR';
  static const String last5Years = 'LAST_5_YEARS';
  static const String last10Years = 'LAST_10_YEARS';

  // Bi-monthly
  static const String thisBimonth = 'THIS_BIMONTH';
  static const String lastBimonth = 'LAST_BIMONTH';
  static const String last6BiMonths = 'LAST_6_BIMONTHS';

  // Six-monthly
  static const String thisSixMonth = 'THIS_SIX_MONTH';
  static const String lastSixMonth = 'LAST_SIX_MONTH';
  static const String last2SixMonths = 'LAST_2_SIXMONTHS';

  // Financial years
  static const String thisFinancialYear = 'THIS_FINANCIAL_YEAR';
  static const String lastFinancialYear = 'LAST_FINANCIAL_YEAR';
  static const String last5FinancialYears = 'LAST_5_FINANCIAL_YEARS';
}

/// Dimension identifiers used in analytics.
/// 
/// These are the standard dimension UIDs in DHIS2.
abstract class Dimensions {
  /// Data dimension (data elements, indicators, etc.)
  static const String data = 'dx';

  /// Period/time dimension
  static const String period = 'pe';

  /// Organisation unit dimension
  static const String orgUnit = 'ou';

  /// Category option combination dimension
  static const String categoryOptionCombo = 'co';

  /// Attribute option combination dimension
  static const String attributeOptionCombo = 'ao';
}

/// Aggregation types supported by DHIS2.
abstract class AggregationTypes {
  static const String sum = 'SUM';
  static const String average = 'AVERAGE';
  static const String averageSumOrgUnit = 'AVERAGE_SUM_ORG_UNIT';
  static const String count = 'COUNT';
  static const String stddev = 'STDDEV';
  static const String variance = 'VARIANCE';
  static const String min = 'MIN';
  static const String max = 'MAX';
  static const String none = 'NONE';
  static const String custom = 'CUSTOM';
  static const String defaultType = 'DEFAULT';
}

/// Value types for data elements and attributes.
abstract class ValueTypes {
  static const String text = 'TEXT';
  static const String longText = 'LONG_TEXT';
  static const String letter = 'LETTER';
  static const String phoneNumber = 'PHONE_NUMBER';
  static const String email = 'EMAIL';
  static const String boolean = 'BOOLEAN';
  static const String trueOnly = 'TRUE_ONLY';
  static const String date = 'DATE';
  static const String dateTime = 'DATETIME';
  static const String time = 'TIME';
  static const String number = 'NUMBER';
  static const String unitInterval = 'UNIT_INTERVAL';
  static const String percentage = 'PERCENTAGE';
  static const String integer = 'INTEGER';
  static const String integerPositive = 'INTEGER_POSITIVE';
  static const String integerNegative = 'INTEGER_NEGATIVE';
  static const String integerZeroOrPositive = 'INTEGER_ZERO_OR_POSITIVE';
  static const String tracker = 'TRACKER_ASSOCIATE';
  static const String username = 'USERNAME';
  static const String coordinate = 'COORDINATE';
  static const String organisationUnit = 'ORGANISATION_UNIT';
  static const String age = 'AGE';
  static const String url = 'URL';
  static const String file = 'FILE_RESOURCE';
  static const String image = 'IMAGE';
}

/// Visualization types in DHIS2.
abstract class VisualizationTypes {
  static const String column = 'COLUMN';
  static const String stackedColumn = 'STACKED_COLUMN';
  static const String bar = 'BAR';
  static const String stackedBar = 'STACKED_BAR';
  static const String line = 'LINE';
  static const String area = 'AREA';
  static const String stackedArea = 'STACKED_AREA';
  static const String pie = 'PIE';
  static const String radar = 'RADAR';
  static const String gauge = 'GAUGE';
  static const String yearOverYear = 'YEAR_OVER_YEAR_LINE';
  static const String yearOverYearColumn = 'YEAR_OVER_YEAR_COLUMN';
  static const String singleValue = 'SINGLE_VALUE';
  static const String pivotTable = 'PIVOT_TABLE';
  static const String scatter = 'SCATTER';
}

/// Organisation unit selection modes.
abstract class OrgUnitSelectionModes {
  /// Only selected org units
  static const String selected = 'SELECTED';

  /// Selected org units and all children
  static const String children = 'CHILDREN';

  /// Selected org units and all descendants
  static const String descendants = 'DESCENDANTS';

  /// All org units accessible to user
  static const String accessible = 'ACCESSIBLE';

  /// All org units in capture scope
  static const String capture = 'CAPTURE';

  /// All org units
  static const String all = 'ALL';
}

/// User authority constants.
/// 
/// Common authorities needed for analytics operations.
abstract class Authorities {
  static const String seeAnalytics = 'M_dhis-web-data-visualizer';
  static const String seeDashboard = 'M_dhis-web-dashboard';
  static const String seeReports = 'M_dhis-web-reports';
  static const String seeMaps = 'M_dhis-web-maps';
  static const String seeEventReports = 'M_dhis-web-event-reports';
  static const String seeEventVisualizer = 'M_dhis-web-event-visualizer';

  /// Check if user has any analytics view authority
  static bool hasAnyAnalyticsAuthority(List<String> userAuthorities) {
    return userAuthorities.any((auth) => [
          seeAnalytics,
          seeDashboard,
          seeReports,
          seeMaps,
          seeEventReports,
          seeEventVisualizer,
        ].contains(auth));
  }
}

/// Default field selections for API queries.
/// 
/// Pre-defined field lists to reduce response sizes.
abstract class DefaultFields {
  /// Minimal fields for list views
  static const List<String> minimal = ['id', 'displayName'];

  /// Standard fields for most use cases
  static const List<String> standard = [
    'id',
    'displayName',
    'name',
    'code',
    'created',
    'lastUpdated',
  ];

  /// Fields for organisation units
  static const List<String> orgUnit = [
    'id',
    'displayName',
    'name',
    'code',
    'level',
    'path',
    'parent[id,displayName]',
    'children[id,displayName]',
  ];

  /// Fields for data elements
  static const List<String> dataElement = [
    'id',
    'displayName',
    'name',
    'code',
    'valueType',
    'aggregationType',
    'domainType',
    'categoryCombo[id,displayName]',
  ];

  /// Fields for dashboards
  static const List<String> dashboard = [
    'id',
    'displayName',
    'name',
    'dashboardItems[id,type,visualization,map,eventChart,eventReport]',
  ];
}
