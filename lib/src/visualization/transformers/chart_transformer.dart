import '../models/chart_data.dart';
import '../models/table_data.dart';
import '../../analytics/models/analytics_response.dart';
import '../../logging/sdk_logger.dart';

/// Transforms DHIS2 analytics responses into chart-ready data structures.
/// 
/// Handles the complex mapping from DHIS2's row-based analytics format
/// to visualization-specific data structures.
class ChartTransformer {
  final SdkLogger _logger;

  ChartTransformer({SdkLogger? logger}) : _logger = logger ?? SdkLogger();

  /// Transform analytics response to chart data
  ChartData transform(
    AnalyticsResponse response, {
    ChartConfig config = const ChartConfig(),
    String? periodDimension,
    String? categoryDimension,
    String? seriesDimension,
  }) {
    _logger.debug(
      'Transforming analytics to chart',
      tag: 'ChartTransformer',
      data: {'type': config.type.name, 'rows': response.rows.length},
    );

    // Determine dimensions from response if not specified
    final dimensions = _resolveDimensions(
      response,
      periodDimension: periodDimension,
      categoryDimension: categoryDimension,
      seriesDimension: seriesDimension,
    );

    switch (config.type) {
      case ChartType.pie:
      case ChartType.donut:
        return _transformToPieChart(response, config, dimensions);
      case ChartType.line:
      case ChartType.area:
        return _transformToLineChart(response, config, dimensions);
      case ChartType.scatter:
        return _transformToScatterChart(response, config, dimensions);
      case ChartType.singleValue:
        return _transformToSingleValue(response, config);
      case ChartType.gauge:
        return _transformToGauge(response, config);
      default:
        return _transformToBarChart(response, config, dimensions);
    }
  }

  _ResolvedDimensions _resolveDimensions(
    AnalyticsResponse response, {
    String? periodDimension,
    String? categoryDimension,
    String? seriesDimension,
  }) {
    final headers = response.headers;
    final dimensions = response.metaData?.dimensions ?? {};

    // Try to find period dimension
    String? period = periodDimension;
    if (period == null) {
      for (final header in headers) {
        if (header.name == 'pe' || header.name == 'period') {
          period = header.name;
          break;
        }
      }
    }

    // Try to find category dimension (usually org unit or data element)
    String? category = categoryDimension;
    if (category == null) {
      for (final header in headers) {
        if (header.name == 'ou' || header.name == 'dx') {
          category = header.name;
          break;
        }
      }
    }

    // Series dimension (optional, for multi-series charts)
    String? series = seriesDimension;

    return _ResolvedDimensions(
      period: period,
      category: category,
      series: series,
    );
  }

  ChartData _transformToBarChart(
    AnalyticsResponse response,
    ChartConfig config,
    _ResolvedDimensions dimensions,
  ) {
    final categoryIndex = _findHeaderIndex(response, dimensions.category ?? 'dx');
    final valueIndex = _findHeaderIndex(response, 'value');
    final seriesIndex = dimensions.series != null 
        ? _findHeaderIndex(response, dimensions.series!) 
        : null;

    // Group data by category and series
    final dataMap = <String, Map<String, double>>{};
    final allSeries = <String>{};
    final allCategories = <String>[];

    for (final row in response.rows) {
      final categoryId = categoryIndex >= 0 && categoryIndex < row.length 
          ? row[categoryIndex]?.toString() ?? 'Unknown'
          : 'Unknown';
      final value = _parseValue(valueIndex >= 0 ? row[valueIndex] : null);
      final seriesId = seriesIndex != null && seriesIndex >= 0 && seriesIndex < row.length
          ? row[seriesIndex]?.toString() ?? 'Default'
          : 'Default';

      if (!allCategories.contains(categoryId)) {
        allCategories.add(categoryId);
      }
      allSeries.add(seriesId);

      dataMap.putIfAbsent(categoryId, () => {});
      dataMap[categoryId]![seriesId] = value;
    }

    // Build series
    final chartSeries = <ChartSeries>[];
    for (final seriesId in allSeries) {
      final data = <ChartDataPoint>[];
      for (final categoryId in allCategories) {
        final value = dataMap[categoryId]?[seriesId] ?? 0;
        final label = _resolveName(response, dimensions.category ?? 'dx', categoryId);
        data.add(ChartDataPoint(
          category: categoryId,
          label: label,
          value: value,
        ));
      }

      final seriesName = _resolveName(
        response, 
        dimensions.series ?? 'dx', 
        seriesId,
      );
      chartSeries.add(ChartSeries(
        name: seriesName,
        id: seriesId,
        data: data,
      ));
    }

    // Resolve category labels
    final categoryLabels = allCategories.map((id) => 
        _resolveName(response, dimensions.category ?? 'dx', id)).toList();

    // Apply sorting
    final sortedData = _applySorting(chartSeries, categoryLabels, config.sortOrder);

    // Apply max items limit
    final limitedData = _applyMaxItems(sortedData, config);

    return ChartData(
      type: config.type,
      title: config.title,
      subtitle: config.subtitle,
      series: limitedData.series,
      categories: limitedData.categories,
      config: config,
    );
  }

  ChartData _transformToPieChart(
    AnalyticsResponse response,
    ChartConfig config,
    _ResolvedDimensions dimensions,
  ) {
    final categoryIndex = _findHeaderIndex(response, dimensions.category ?? 'dx');
    final valueIndex = _findHeaderIndex(response, 'value');

    final data = <ChartDataPoint>[];
    double total = 0;

    for (final row in response.rows) {
      final categoryId = categoryIndex >= 0 && categoryIndex < row.length 
          ? row[categoryIndex]?.toString() ?? 'Unknown'
          : 'Unknown';
      final value = _parseValue(valueIndex >= 0 ? row[valueIndex] : null);
      final label = _resolveName(response, dimensions.category ?? 'dx', categoryId);

      data.add(ChartDataPoint(
        category: categoryId,
        label: label,
        value: value,
      ));
      total += value;
    }

    // Sort by value descending for pie charts
    data.sort((a, b) => (b.value ?? 0).compareTo(a.value ?? 0));

    // Group small items if configured
    List<ChartDataPoint> processedData = data;
    if (config.groupSmallItems && total > 0) {
      final threshold = total * (config.smallItemThreshold / 100);
      final mainItems = <ChartDataPoint>[];
      double otherTotal = 0;

      for (final item in data) {
        if ((item.value ?? 0) >= threshold) {
          mainItems.add(item);
        } else {
          otherTotal += item.value ?? 0;
        }
      }

      if (otherTotal > 0) {
        mainItems.add(ChartDataPoint(
          category: 'other',
          label: 'Other',
          value: otherTotal,
        ));
      }
      processedData = mainItems;
    }

    // Apply max items
    if (config.maxItems != null && processedData.length > config.maxItems!) {
      final kept = processedData.take(config.maxItems! - 1).toList();
      final otherTotal = processedData
          .skip(config.maxItems! - 1)
          .fold<double>(0, (sum, d) => sum + (d.value ?? 0));
      kept.add(ChartDataPoint(
        category: 'other',
        label: 'Other',
        value: otherTotal,
      ));
      processedData = kept;
    }

    return ChartData(
      type: config.type,
      title: config.title,
      subtitle: config.subtitle,
      series: [ChartSeries(name: 'Data', data: processedData)],
      categories: processedData.map((d) => d.label ?? d.category ?? '').toList(),
      config: config,
      metadata: {'total': total},
    );
  }

  ChartData _transformToLineChart(
    AnalyticsResponse response,
    ChartConfig config,
    _ResolvedDimensions dimensions,
  ) {
    final periodIndex = _findHeaderIndex(response, dimensions.period ?? 'pe');
    final valueIndex = _findHeaderIndex(response, 'value');
    final seriesIndex = dimensions.series != null 
        ? _findHeaderIndex(response, dimensions.series!) 
        : _findHeaderIndex(response, 'dx');

    // Group data by period and series
    final dataMap = <String, Map<String, double>>{};
    final allPeriods = <String>[];
    final allSeries = <String>{};

    for (final row in response.rows) {
      final periodId = periodIndex >= 0 && periodIndex < row.length 
          ? row[periodIndex]?.toString() ?? 'Unknown'
          : 'Unknown';
      final value = _parseValue(valueIndex >= 0 ? row[valueIndex] : null);
      final seriesId = seriesIndex >= 0 && seriesIndex < row.length
          ? row[seriesIndex]?.toString() ?? 'Default'
          : 'Default';

      if (!allPeriods.contains(periodId)) {
        allPeriods.add(periodId);
      }
      allSeries.add(seriesId);

      dataMap.putIfAbsent(seriesId, () => {});
      dataMap[seriesId]![periodId] = value;
    }

    // Sort periods chronologically
    allPeriods.sort();

    // Build series
    final chartSeries = <ChartSeries>[];
    for (final seriesId in allSeries) {
      final data = <ChartDataPoint>[];
      for (final periodId in allPeriods) {
        final value = dataMap[seriesId]?[periodId];
        final label = _resolvePeriodName(response, periodId);
        data.add(ChartDataPoint(
          category: periodId,
          label: label,
          value: value,
        ));
      }

      final seriesName = _resolveName(response, 'dx', seriesId);
      chartSeries.add(ChartSeries(
        name: seriesName,
        id: seriesId,
        data: data,
      ));
    }

    final periodLabels = allPeriods.map((id) => 
        _resolvePeriodName(response, id)).toList();

    return ChartData(
      type: config.type,
      title: config.title,
      subtitle: config.subtitle,
      series: chartSeries,
      categories: periodLabels,
      config: config,
    );
  }

  ChartData _transformToScatterChart(
    AnalyticsResponse response,
    ChartConfig config,
    _ResolvedDimensions dimensions,
  ) {
    // For scatter charts, we need two value dimensions
    final headers = response.headers;
    final valueIndices = <int>[];
    
    for (int i = 0; i < headers.length; i++) {
      if (headers[i].valueType == 'NUMBER') {
        valueIndices.add(i);
      }
    }

    final data = <ChartDataPoint>[];
    
    for (final row in response.rows) {
      final x = valueIndices.isNotEmpty 
          ? _parseValue(row[valueIndices[0]]) 
          : 0.0;
      final y = valueIndices.length > 1 
          ? _parseValue(row[valueIndices[1]]) 
          : 0.0;
      
      data.add(ChartDataPoint(x: x, y: y));
    }

    return ChartData(
      type: config.type,
      title: config.title,
      subtitle: config.subtitle,
      series: [ChartSeries(name: 'Data', data: data)],
      categories: [],
      config: config,
    );
  }

  ChartData _transformToSingleValue(
    AnalyticsResponse response,
    ChartConfig config,
  ) {
    final valueIndex = _findHeaderIndex(response, 'value');
    double value = 0;
    
    if (response.rows.isNotEmpty) {
      value = _parseValue(
        valueIndex >= 0 ? response.rows.first[valueIndex] : null,
      );
    }

    return ChartData(
      type: config.type,
      title: config.title,
      subtitle: config.subtitle,
      series: [
        ChartSeries(
          name: 'Value',
          data: [ChartDataPoint(value: value)],
        ),
      ],
      categories: [],
      config: config,
    );
  }

  ChartData _transformToGauge(
    AnalyticsResponse response,
    ChartConfig config,
  ) {
    return _transformToSingleValue(response, config);
  }

  int _findHeaderIndex(AnalyticsResponse response, String name) {
    for (int i = 0; i < response.headers.length; i++) {
      if (response.headers[i].name == name) {
        return i;
      }
    }
    return -1;
  }

  double _parseValue(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _resolveName(
    AnalyticsResponse response,
    String dimension,
    String id,
  ) {
    final items = response.metaData?.items;
    if (items != null && items.containsKey(id)) {
      return items[id]?['name']?.toString() ?? id;
    }
    return id;
  }

  String _resolvePeriodName(AnalyticsResponse response, String periodId) {
    final items = response.metaData?.items;
    if (items != null && items.containsKey(periodId)) {
      return items[periodId]?['name']?.toString() ?? periodId;
    }
    
    // Format common period patterns
    if (periodId.length == 6) {
      // Monthly: 202301 -> Jan 2023
      final year = periodId.substring(0, 4);
      final month = int.tryParse(periodId.substring(4, 6)) ?? 1;
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${monthNames[month - 1]} $year';
    }
    if (periodId.length == 4) {
      // Yearly: 2023
      return periodId;
    }
    
    return periodId;
  }

  _SortedData _applySorting(
    List<ChartSeries> series,
    List<String> categories,
    SortOrder order,
  ) {
    if (order == SortOrder.none || series.isEmpty) {
      return _SortedData(series: series, categories: categories);
    }

    // Create index mapping based on first series values
    final firstSeries = series.first;
    final indices = List.generate(categories.length, (i) => i);

    switch (order) {
      case SortOrder.ascending:
        indices.sort((a, b) => (firstSeries.data[a].value ?? 0)
            .compareTo(firstSeries.data[b].value ?? 0));
        break;
      case SortOrder.descending:
        indices.sort((a, b) => (firstSeries.data[b].value ?? 0)
            .compareTo(firstSeries.data[a].value ?? 0));
        break;
      case SortOrder.alphabetical:
        indices.sort((a, b) => categories[a].compareTo(categories[b]));
        break;
      case SortOrder.none:
        break;
    }

    // Reorder data
    final sortedCategories = indices.map((i) => categories[i]).toList();
    final sortedSeries = series.map((s) {
      final sortedData = indices.map((i) => s.data[i]).toList();
      return ChartSeries(
        name: s.name,
        id: s.id,
        data: sortedData,
        color: s.color,
      );
    }).toList();

    return _SortedData(series: sortedSeries, categories: sortedCategories);
  }

  _SortedData _applyMaxItems(_SortedData data, ChartConfig config) {
    if (config.maxItems == null || data.categories.length <= config.maxItems!) {
      return data;
    }

    final keepCount = config.maxItems!;
    final limitedCategories = data.categories.take(keepCount).toList();
    final limitedSeries = data.series.map((s) {
      return ChartSeries(
        name: s.name,
        id: s.id,
        data: s.data.take(keepCount).toList(),
        color: s.color,
      );
    }).toList();

    return _SortedData(series: limitedSeries, categories: limitedCategories);
  }
}

class _ResolvedDimensions {
  final String? period;
  final String? category;
  final String? series;

  _ResolvedDimensions({this.period, this.category, this.series});
}

class _SortedData {
  final List<ChartSeries> series;
  final List<String> categories;

  _SortedData({required this.series, required this.categories});
}
