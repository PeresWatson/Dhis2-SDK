import 'dart:convert';
import 'dart:math';

/// Utilities for formatting and displaying values from DHIS2.
class ValueFormatter {
  /// Format a number with appropriate precision and notation
  static String formatNumber(
    num value, {
    int decimals = 2,
    bool compact = false,
    String? locale,
  }) {
    if (compact) {
      return _formatCompact(value);
    }
    
    if (value == value.truncate()) {
      return value.truncate().toString();
    }
    
    return value.toStringAsFixed(decimals);
  }

  /// Format a number as a percentage
  static String formatPercent(
    num value, {
    int decimals = 1,
    bool multiplyBy100 = false,
  }) {
    final percent = multiplyBy100 ? value * 100 : value;
    return '${percent.toStringAsFixed(decimals)}%';
  }

  /// Format a number with thousand separators
  static String formatWithSeparators(
    num value, {
    String separator = ',',
    String decimalSeparator = '.',
    int decimals = 2,
  }) {
    final parts = value.toStringAsFixed(decimals).split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '';

    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write(separator);
      }
      buffer.write(intPart[i]);
    }

    if (decPart.isNotEmpty && decimals > 0) {
      buffer.write(decimalSeparator);
      buffer.write(decPart);
    }

    return buffer.toString();
  }

  /// Format a value based on DHIS2 value type
  static String formatByType(
    dynamic value,
    String? valueType, {
    int decimals = 2,
  }) {
    if (value == null) return '-';

    switch (valueType) {
      case 'NUMBER':
      case 'UNIT_INTERVAL':
        return formatNumber(
          value is num ? value : double.tryParse(value.toString()) ?? 0,
          decimals: decimals,
        );
      case 'INTEGER':
      case 'INTEGER_POSITIVE':
      case 'INTEGER_NEGATIVE':
      case 'INTEGER_ZERO_OR_POSITIVE':
        return (value is num ? value.truncate() : 
            int.tryParse(value.toString()) ?? 0).toString();
      case 'PERCENTAGE':
        return formatPercent(
          value is num ? value : double.tryParse(value.toString()) ?? 0,
        );
      case 'BOOLEAN':
      case 'TRUE_ONLY':
        return value == true || value == 'true' ? 'Yes' : 'No';
      case 'DATE':
        return _formatDate(value.toString());
      case 'DATETIME':
        return _formatDateTime(value.toString());
      default:
        return value.toString();
    }
  }

  /// Format bytes to human-readable size
  static String formatBytes(int bytes, {int decimals = 1}) {
    if (bytes == 0) return '0 B';
    
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    final size = bytes / pow(1024, i);
    
    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  /// Format duration to human-readable string
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    }
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
    return '${duration.inSeconds}s';
  }

  /// Format relative time (e.g., "2 hours ago")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      return 'in the future';
    }
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    }
    if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    }
    if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    }
    return 'just now';
  }

  static String _formatCompact(num value) {
    final absValue = value.abs();
    
    if (absValue >= 1e12) {
      return '${(value / 1e12).toStringAsFixed(1)}T';
    }
    if (absValue >= 1e9) {
      return '${(value / 1e9).toStringAsFixed(1)}B';
    }
    if (absValue >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(1)}M';
    }
    if (absValue >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(1)}K';
    }
    
    if (value == value.truncate()) {
      return value.truncate().toString();
    }
    return value.toStringAsFixed(1);
  }

  static String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  static String _formatDateTime(String dateTimeStr) {
    try {
      final dt = DateTime.parse(dateTimeStr);
      return '${_formatDate(dateTimeStr)} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateTimeStr;
    }
  }
}

/// Color utilities for data visualization
class ColorUtils {
  /// Default DHIS2-style color palette
  static const List<String> defaultPalette = [
    '#1f77b4', // Blue
    '#ff7f0e', // Orange
    '#2ca02c', // Green
    '#d62728', // Red
    '#9467bd', // Purple
    '#8c564b', // Brown
    '#e377c2', // Pink
    '#7f7f7f', // Gray
    '#bcbd22', // Olive
    '#17becf', // Cyan
  ];

  /// Sequential color palettes for choropleth maps
  static const Map<String, List<String>> sequentialPalettes = {
    'blues': ['#f7fbff', '#deebf7', '#c6dbef', '#9ecae1', '#6baed6', '#4292c6', '#2171b5', '#084594'],
    'greens': ['#f7fcf5', '#e5f5e0', '#c7e9c0', '#a1d99b', '#74c476', '#41ab5d', '#238b45', '#005a32'],
    'reds': ['#fff5f0', '#fee0d2', '#fcbba1', '#fc9272', '#fb6a4a', '#ef3b2c', '#cb181d', '#99000d'],
    'oranges': ['#fff5eb', '#fee6ce', '#fdd0a2', '#fdae6b', '#fd8d3c', '#f16913', '#d94801', '#8c2d04'],
    'purples': ['#fcfbfd', '#efedf5', '#dadaeb', '#bcbddc', '#9e9ac8', '#807dba', '#6a51a3', '#4a1486'],
  };

  /// Diverging color palettes for highlighting above/below thresholds
  static const Map<String, List<String>> divergingPalettes = {
    'redBlue': ['#67001f', '#b2182b', '#d6604d', '#f4a582', '#fddbc7', '#d1e5f0', '#92c5de', '#4393c3', '#2166ac', '#053061'],
    'redGreen': ['#a50026', '#d73027', '#f46d43', '#fdae61', '#fee08b', '#d9ef8b', '#a6d96a', '#66bd63', '#1a9850', '#006837'],
    'brownTeal': ['#543005', '#8c510a', '#bf812d', '#dfc27d', '#f6e8c3', '#c7eae5', '#80cdc1', '#35978f', '#01665e', '#003c30'],
  };

  /// Get a color from the default palette by index
  static String getColor(int index) {
    return defaultPalette[index % defaultPalette.length];
  }

  /// Get a color for a value within a range using a sequential palette
  static String getSequentialColor(
    double value,
    double min,
    double max, {
    String palette = 'blues',
  }) {
    final colors = sequentialPalettes[palette] ?? sequentialPalettes['blues']!;
    
    if (max == min) return colors[colors.length ~/ 2];
    
    final normalized = (value - min) / (max - min);
    final index = (normalized * (colors.length - 1)).round().clamp(0, colors.length - 1);
    
    return colors[index];
  }

  /// Get a color for a value using a diverging palette
  static String getDivergingColor(
    double value,
    double min,
    double max,
    double midpoint, {
    String palette = 'redBlue',
  }) {
    final colors = divergingPalettes[palette] ?? divergingPalettes['redBlue']!;
    final midIndex = colors.length ~/ 2;

    if (value <= midpoint) {
      if (midpoint == min) return colors[midIndex];
      final normalized = (value - min) / (midpoint - min);
      final index = (normalized * midIndex).round().clamp(0, midIndex);
      return colors[index];
    } else {
      if (max == midpoint) return colors[midIndex];
      final normalized = (value - midpoint) / (max - midpoint);
      final index = (midIndex + normalized * midIndex).round().clamp(midIndex, colors.length - 1);
      return colors[index];
    }
  }

  /// Parse a hex color string to RGB values
  static List<int>? parseHex(String hex) {
    final cleanHex = hex.replaceAll('#', '');
    if (cleanHex.length != 6) return null;

    try {
      return [
        int.parse(cleanHex.substring(0, 2), radix: 16),
        int.parse(cleanHex.substring(2, 4), radix: 16),
        int.parse(cleanHex.substring(4, 6), radix: 16),
      ];
    } catch (_) {
      return null;
    }
  }

  /// Convert RGB values to hex string
  static String toHex(int r, int g, int b) {
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }

  /// Blend two colors
  static String blend(String color1, String color2, double ratio) {
    final rgb1 = parseHex(color1);
    final rgb2 = parseHex(color2);
    
    if (rgb1 == null || rgb2 == null) return color1;

    final r = (rgb1[0] * (1 - ratio) + rgb2[0] * ratio).round();
    final g = (rgb1[1] * (1 - ratio) + rgb2[1] * ratio).round();
    final b = (rgb1[2] * (1 - ratio) + rgb2[2] * ratio).round();

    return toHex(r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255));
  }

  /// Get a contrasting text color (black or white) for a background
  static String getContrastingTextColor(String backgroundColor) {
    final rgb = parseHex(backgroundColor);
    if (rgb == null) return '#000000';

    // Calculate relative luminance
    final luminance = (0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2]) / 255;
    
    return luminance > 0.5 ? '#000000' : '#ffffff';
  }
}

/// Statistics utilities for analytics data
class StatisticsUtils {
  /// Calculate basic statistics for a list of numbers
  static Statistics calculate(List<num> values) {
    if (values.isEmpty) {
      return const Statistics(
        count: 0,
        sum: 0,
        mean: 0,
        min: 0,
        max: 0,
        median: 0,
        stdDev: 0,
        variance: 0,
      );
    }

    final sorted = List<num>.from(values)..sort();
    final count = values.length;
    final sum = values.fold<num>(0, (a, b) => a + b);
    final mean = sum / count;
    final minVal = sorted.first;
    final maxVal = sorted.last;

    // Median
    num median;
    if (count % 2 == 0) {
      median = (sorted[count ~/ 2 - 1] + sorted[count ~/ 2]) / 2;
    } else {
      median = sorted[count ~/ 2];
    }

    // Variance and standard deviation
    final variance = values.fold<num>(0, (sum, v) => sum + pow(v - mean, 2)) / count;
    final stdDev = sqrt(variance);

    return Statistics(
      count: count,
      sum: sum.toDouble(),
      mean: mean.toDouble(),
      min: minVal.toDouble(),
      max: maxVal.toDouble(),
      median: median.toDouble(),
      stdDev: stdDev,
      variance: variance.toDouble(),
    );
  }

  /// Calculate percentile
  static double percentile(List<num> values, double p) {
    if (values.isEmpty) return 0;
    if (p <= 0) return values.reduce(min).toDouble();
    if (p >= 100) return values.reduce(max).toDouble();

    final sorted = List<num>.from(values)..sort();
    final index = (p / 100) * (sorted.length - 1);
    final lower = sorted[index.floor()];
    final upper = sorted[index.ceil()];
    
    return lower + (upper - lower) * (index - index.floor());
  }

  /// Calculate quartiles (Q1, Q2/median, Q3)
  static Quartiles quartiles(List<num> values) {
    return Quartiles(
      q1: percentile(values, 25),
      q2: percentile(values, 50),
      q3: percentile(values, 75),
    );
  }
}

/// Container for basic statistics
class Statistics {
  final int count;
  final double sum;
  final double mean;
  final double min;
  final double max;
  final double median;
  final double stdDev;
  final double variance;

  const Statistics({
    required this.count,
    required this.sum,
    required this.mean,
    required this.min,
    required this.max,
    required this.median,
    required this.stdDev,
    required this.variance,
  });

  double get range => max - min;

  @override
  String toString() {
    return 'Statistics(count: $count, mean: ${mean.toStringAsFixed(2)}, '
        'min: ${min.toStringAsFixed(2)}, max: ${max.toStringAsFixed(2)}, '
        'stdDev: ${stdDev.toStringAsFixed(2)})';
  }
}

/// Container for quartile values
class Quartiles {
  final double q1;
  final double q2;
  final double q3;

  const Quartiles({
    required this.q1,
    required this.q2,
    required this.q3,
  });

  double get iqr => q3 - q1;

  @override
  String toString() => 'Quartiles(Q1: $q1, Q2: $q2, Q3: $q3)';
}
