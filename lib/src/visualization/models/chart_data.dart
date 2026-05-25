import '../analytics/models/analytics_response.dart';

/// Configuration for chart data transformation
class ChartConfig {
  /// Type of chart
  final ChartType type;
  
  /// Title for the chart
  final String? title;
  
  /// Subtitle for the chart
  final String? subtitle;
  
  /// Whether to show legend
  final bool showLegend;
  
  /// Legend position
  final LegendPosition legendPosition;
  
  /// Whether to show data labels
  final bool showDataLabels;
  
  /// Whether to show tooltips
  final bool showTooltips;
  
  /// Color palette for the chart
  final List<String>? colors;
  
  /// Whether to stack series
  final bool stacked;
  
  /// Whether to show as percentage
  final bool asPercentage;
  
  /// Sort order for data
  final SortOrder sortOrder;
  
  /// Maximum items to show (for pie/bar charts)
  final int? maxItems;
  
  /// Whether to group small items into "Other"
  final bool groupSmallItems;
  
  /// Threshold for grouping small items (as percentage)
  final double smallItemThreshold;

  const ChartConfig({
    this.type = ChartType.bar,
    this.title,
    this.subtitle,
    this.showLegend = true,
    this.legendPosition = LegendPosition.bottom,
    this.showDataLabels = false,
    this.showTooltips = true,
    this.colors,
    this.stacked = false,
    this.asPercentage = false,
    this.sortOrder = SortOrder.none,
    this.maxItems,
    this.groupSmallItems = false,
    this.smallItemThreshold = 2.0,
  });

  ChartConfig copyWith({
    ChartType? type,
    String? title,
    String? subtitle,
    bool? showLegend,
    LegendPosition? legendPosition,
    bool? showDataLabels,
    bool? showTooltips,
    List<String>? colors,
    bool? stacked,
    bool? asPercentage,
    SortOrder? sortOrder,
    int? maxItems,
    bool? groupSmallItems,
    double? smallItemThreshold,
  }) {
    return ChartConfig(
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      showLegend: showLegend ?? this.showLegend,
      legendPosition: legendPosition ?? this.legendPosition,
      showDataLabels: showDataLabels ?? this.showDataLabels,
      showTooltips: showTooltips ?? this.showTooltips,
      colors: colors ?? this.colors,
      stacked: stacked ?? this.stacked,
      asPercentage: asPercentage ?? this.asPercentage,
      sortOrder: sortOrder ?? this.sortOrder,
      maxItems: maxItems ?? this.maxItems,
      groupSmallItems: groupSmallItems ?? this.groupSmallItems,
      smallItemThreshold: smallItemThreshold ?? this.smallItemThreshold,
    );
  }
}

/// Types of charts supported
enum ChartType {
  bar,
  horizontalBar,
  line,
  area,
  pie,
  donut,
  radar,
  scatter,
  gauge,
  singleValue,
  table,
}

/// Legend position
enum LegendPosition {
  top,
  bottom,
  left,
  right,
  none,
}

/// Sort order for data
enum SortOrder {
  none,
  ascending,
  descending,
  alphabetical,
}

/// Transformed chart data ready for visualization
class ChartData {
  final ChartType type;
  final String? title;
  final String? subtitle;
  final List<ChartSeries> series;
  final List<String> categories;
  final ChartConfig config;
  final Map<String, dynamic>? metadata;

  const ChartData({
    required this.type,
    this.title,
    this.subtitle,
    required this.series,
    required this.categories,
    required this.config,
    this.metadata,
  });

  /// Total number of data points
  int get totalDataPoints => 
      series.fold(0, (sum, s) => sum + s.data.length);

  /// Whether chart has multiple series
  bool get hasMultipleSeries => series.length > 1;

  /// Get the maximum value across all series
  double get maxValue {
    double max = 0;
    for (final s in series) {
      for (final d in s.data) {
        if (d.value != null && d.value! > max) {
          max = d.value!;
        }
      }
    }
    return max;
  }

  /// Get the minimum value across all series
  double get minValue {
    double min = double.infinity;
    for (final s in series) {
      for (final d in s.data) {
        if (d.value != null && d.value! < min) {
          min = d.value!;
        }
      }
    }
    return min == double.infinity ? 0 : min;
  }

  /// Convert to a simple map for charting libraries
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'title': title,
      'subtitle': subtitle,
      'categories': categories,
      'series': series.map((s) => s.toMap()).toList(),
      'config': {
        'showLegend': config.showLegend,
        'showDataLabels': config.showDataLabels,
        'stacked': config.stacked,
        'colors': config.colors,
      },
    };
  }
}

/// A single series in a chart
class ChartSeries {
  final String name;
  final String? id;
  final List<ChartDataPoint> data;
  final String? color;
  final SeriesType? type;

  const ChartSeries({
    required this.name,
    this.id,
    required this.data,
    this.color,
    this.type,
  });

  /// Total value of all data points
  double get total => data.fold(0, (sum, d) => sum + (d.value ?? 0));

  /// Average value
  double get average => data.isEmpty ? 0 : total / data.length;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'id': id,
      'data': data.map((d) => d.toMap()).toList(),
      'color': color,
      'type': type?.name,
    };
  }
}

/// Type of series (for mixed charts)
enum SeriesType {
  bar,
  line,
  area,
}

/// A single data point in a chart
class ChartDataPoint {
  final String? category;
  final String? label;
  final double? value;
  final double? x;
  final double? y;
  final Map<String, dynamic>? metadata;

  const ChartDataPoint({
    this.category,
    this.label,
    this.value,
    this.x,
    this.y,
    this.metadata,
  });

  /// Formatted value for display
  String get formattedValue {
    if (value == null) return '-';
    if (value! >= 1000000) {
      return '${(value! / 1000000).toStringAsFixed(1)}M';
    }
    if (value! >= 1000) {
      return '${(value! / 1000).toStringAsFixed(1)}K';
    }
    if (value! == value!.truncate()) {
      return value!.truncate().toString();
    }
    return value!.toStringAsFixed(2);
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'label': label,
      'value': value,
      'x': x,
      'y': y,
      ...?metadata,
    };
  }
}
