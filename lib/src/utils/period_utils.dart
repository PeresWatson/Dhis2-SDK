import 'package:intl/intl.dart';

/// Utilities for parsing and formatting DHIS2 period identifiers.
/// 
/// DHIS2 uses specific formats for different period types:
/// - Daily: 20230115 (YYYYMMDD)
/// - Weekly: 2023W3 (YYYY"W"W)
/// - Monthly: 202301 (YYYYMM)
/// - Quarterly: 2023Q1 (YYYY"Q"Q)
/// - Yearly: 2023 (YYYY)
/// - Financial Year: 2023April, 2023July, 2023Oct
class PeriodUtils {
  /// Parse a DHIS2 period identifier into a DateTime
  static DateTime? parse(String periodId) {
    // Yearly: 2023
    if (RegExp(r'^\d{4}$').hasMatch(periodId)) {
      return DateTime(int.parse(periodId));
    }
    
    // Monthly: 202301
    if (RegExp(r'^\d{6}$').hasMatch(periodId)) {
      return DateTime(
        int.parse(periodId.substring(0, 4)),
        int.parse(periodId.substring(4, 6)),
      );
    }
    
    // Daily: 20230115
    if (RegExp(r'^\d{8}$').hasMatch(periodId)) {
      return DateTime(
        int.parse(periodId.substring(0, 4)),
        int.parse(periodId.substring(4, 6)),
        int.parse(periodId.substring(6, 8)),
      );
    }
    
    // Weekly: 2023W3 or 2023W03
    final weekMatch = RegExp(r'^(\d{4})W(\d{1,2})$').firstMatch(periodId);
    if (weekMatch != null) {
      final year = int.parse(weekMatch.group(1)!);
      final week = int.parse(weekMatch.group(2)!);
      return _weekToDate(year, week);
    }
    
    // Quarterly: 2023Q1
    final quarterMatch = RegExp(r'^(\d{4})Q(\d)$').firstMatch(periodId);
    if (quarterMatch != null) {
      final year = int.parse(quarterMatch.group(1)!);
      final quarter = int.parse(quarterMatch.group(2)!);
      return DateTime(year, (quarter - 1) * 3 + 1);
    }
    
    // Bi-monthly: 202301B
    final biMonthlyMatch = RegExp(r'^(\d{4})(\d{2})B$').firstMatch(periodId);
    if (biMonthlyMatch != null) {
      final year = int.parse(biMonthlyMatch.group(1)!);
      final biMonth = int.parse(biMonthlyMatch.group(2)!);
      return DateTime(year, (biMonth - 1) * 2 + 1);
    }
    
    // Six-monthly: 2023S1 or 2023S2
    final sixMonthlyMatch = RegExp(r'^(\d{4})S(\d)$').firstMatch(periodId);
    if (sixMonthlyMatch != null) {
      final year = int.parse(sixMonthlyMatch.group(1)!);
      final half = int.parse(sixMonthlyMatch.group(2)!);
      return DateTime(year, half == 1 ? 1 : 7);
    }
    
    // Financial years
    final financialMatch = RegExp(r'^(\d{4})(April|July|Oct|Nov)$')
        .firstMatch(periodId);
    if (financialMatch != null) {
      final year = int.parse(financialMatch.group(1)!);
      final startMonth = _financialYearStartMonth(financialMatch.group(2)!);
      return DateTime(year, startMonth);
    }
    
    return null;
  }

  /// Format a period ID to a human-readable string
  static String format(String periodId, {PeriodFormat? formatType}) {
    // Yearly: 2023
    if (RegExp(r'^\d{4}$').hasMatch(periodId)) {
      return periodId;
    }
    
    // Monthly: 202301 -> January 2023 or Jan 2023
    if (RegExp(r'^\d{6}$').hasMatch(periodId)) {
      final year = periodId.substring(0, 4);
      final month = int.parse(periodId.substring(4, 6));
      final monthName = formatType == PeriodFormat.short 
          ? _shortMonthNames[month - 1] 
          : _monthNames[month - 1];
      return '$monthName $year';
    }
    
    // Daily: 20230115 -> 15 Jan 2023
    if (RegExp(r'^\d{8}$').hasMatch(periodId)) {
      final date = parse(periodId);
      if (date != null) {
        return DateFormat('d MMM yyyy').format(date);
      }
    }
    
    // Weekly: 2023W3 -> Week 3, 2023
    final weekMatch = RegExp(r'^(\d{4})W(\d{1,2})$').firstMatch(periodId);
    if (weekMatch != null) {
      return 'Week ${weekMatch.group(2)}, ${weekMatch.group(1)}';
    }
    
    // Quarterly: 2023Q1 -> Q1 2023
    final quarterMatch = RegExp(r'^(\d{4})Q(\d)$').firstMatch(periodId);
    if (quarterMatch != null) {
      return 'Q${quarterMatch.group(2)} ${quarterMatch.group(1)}';
    }
    
    // Six-monthly: 2023S1 -> Jan - Jun 2023
    final sixMonthlyMatch = RegExp(r'^(\d{4})S(\d)$').firstMatch(periodId);
    if (sixMonthlyMatch != null) {
      final year = sixMonthlyMatch.group(1);
      final half = int.parse(sixMonthlyMatch.group(2)!);
      return half == 1 ? 'Jan - Jun $year' : 'Jul - Dec $year';
    }
    
    return periodId;
  }

  /// Get the period type from a period ID
  static PeriodType? getPeriodType(String periodId) {
    if (RegExp(r'^\d{4}$').hasMatch(periodId)) {
      return PeriodType.yearly;
    }
    if (RegExp(r'^\d{6}$').hasMatch(periodId)) {
      return PeriodType.monthly;
    }
    if (RegExp(r'^\d{8}$').hasMatch(periodId)) {
      return PeriodType.daily;
    }
    if (RegExp(r'^\d{4}W\d{1,2}$').hasMatch(periodId)) {
      return PeriodType.weekly;
    }
    if (RegExp(r'^\d{4}Q\d$').hasMatch(periodId)) {
      return PeriodType.quarterly;
    }
    if (RegExp(r'^\d{4}S\d$').hasMatch(periodId)) {
      return PeriodType.sixMonthly;
    }
    if (RegExp(r'^\d{4}(April|July|Oct|Nov)$').hasMatch(periodId)) {
      return PeriodType.financialYear;
    }
    return null;
  }

  /// Generate a list of period IDs for a given type and range
  static List<String> generatePeriods(
    PeriodType type,
    DateTime start,
    DateTime end,
  ) {
    final periods = <String>[];
    var current = start;

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      periods.add(_formatPeriodId(current, type));
      current = _nextPeriod(current, type);
    }

    return periods;
  }

  /// Get relative periods for DHIS2 queries
  static List<String> getRelativePeriods(RelativePeriod period) {
    switch (period) {
      case RelativePeriod.thisMonth:
        return ['THIS_MONTH'];
      case RelativePeriod.lastMonth:
        return ['LAST_MONTH'];
      case RelativePeriod.last3Months:
        return ['LAST_3_MONTHS'];
      case RelativePeriod.last6Months:
        return ['LAST_6_MONTHS'];
      case RelativePeriod.last12Months:
        return ['LAST_12_MONTHS'];
      case RelativePeriod.thisQuarter:
        return ['THIS_QUARTER'];
      case RelativePeriod.lastQuarter:
        return ['LAST_QUARTER'];
      case RelativePeriod.last4Quarters:
        return ['LAST_4_QUARTERS'];
      case RelativePeriod.thisYear:
        return ['THIS_YEAR'];
      case RelativePeriod.lastYear:
        return ['LAST_YEAR'];
      case RelativePeriod.last5Years:
        return ['LAST_5_YEARS'];
    }
  }

  /// Sort period IDs chronologically
  static List<String> sortPeriods(List<String> periods, {bool descending = false}) {
    final sorted = List<String>.from(periods);
    sorted.sort((a, b) {
      final dateA = parse(a);
      final dateB = parse(b);
      if (dateA == null || dateB == null) {
        return a.compareTo(b);
      }
      return descending 
          ? dateB.compareTo(dateA) 
          : dateA.compareTo(dateB);
    });
    return sorted;
  }

  static DateTime _weekToDate(int year, int week) {
    final jan1 = DateTime(year, 1, 1);
    final jan1Weekday = jan1.weekday;
    final daysToAdd = (week - 1) * 7 + (8 - jan1Weekday);
    return jan1.add(Duration(days: daysToAdd));
  }

  static int _financialYearStartMonth(String type) {
    switch (type) {
      case 'April':
        return 4;
      case 'July':
        return 7;
      case 'Oct':
        return 10;
      case 'Nov':
        return 11;
      default:
        return 1;
    }
  }

  static String _formatPeriodId(DateTime date, PeriodType type) {
    switch (type) {
      case PeriodType.daily:
        return DateFormat('yyyyMMdd').format(date);
      case PeriodType.weekly:
        final week = _weekNumber(date);
        return '${date.year}W$week';
      case PeriodType.monthly:
        return DateFormat('yyyyMM').format(date);
      case PeriodType.quarterly:
        final quarter = ((date.month - 1) ~/ 3) + 1;
        return '${date.year}Q$quarter';
      case PeriodType.sixMonthly:
        final half = date.month <= 6 ? 1 : 2;
        return '${date.year}S$half';
      case PeriodType.yearly:
        return date.year.toString();
      case PeriodType.financialYear:
        return '${date.year}April';
    }
  }

  static DateTime _nextPeriod(DateTime date, PeriodType type) {
    switch (type) {
      case PeriodType.daily:
        return date.add(const Duration(days: 1));
      case PeriodType.weekly:
        return date.add(const Duration(days: 7));
      case PeriodType.monthly:
        return DateTime(date.year, date.month + 1);
      case PeriodType.quarterly:
        return DateTime(date.year, date.month + 3);
      case PeriodType.sixMonthly:
        return DateTime(date.year, date.month + 6);
      case PeriodType.yearly:
        return DateTime(date.year + 1);
      case PeriodType.financialYear:
        return DateTime(date.year + 1, date.month);
    }
  }

  static int _weekNumber(DateTime date) {
    final jan1 = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(jan1).inDays;
    return ((dayOfYear + jan1.weekday) / 7).ceil();
  }

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static const _shortMonthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
}

/// Period types supported by DHIS2
enum PeriodType {
  daily,
  weekly,
  monthly,
  quarterly,
  sixMonthly,
  yearly,
  financialYear,
}

/// Format options for period display
enum PeriodFormat {
  short,
  long,
}

/// Relative periods for DHIS2 queries
enum RelativePeriod {
  thisMonth,
  lastMonth,
  last3Months,
  last6Months,
  last12Months,
  thisQuarter,
  lastQuarter,
  last4Quarters,
  thisYear,
  lastYear,
  last5Years,
}
