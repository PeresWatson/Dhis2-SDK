/// Analytics Response Model
/// 
/// Represents the response from DHIS2 Analytics API.
/// 
/// ## Purpose
/// 
/// - Parse DHIS2 analytics JSON response
/// - Provide typed access to data rows
/// - Access metadata for display
/// - Support transformation to charts/tables
/// 
/// ## Response Structure
/// 
/// DHIS2 analytics responses have this structure:
/// ```json
/// {
///   "headers": [...],
///   "rows": [[...], [...]],
///   "metaData": {
///     "items": {...},
///     "dimensions": {...}
///   },
///   "width": 4,
///   "height": 100
/// }
/// ```
library;

import 'package:equatable/equatable.dart';

/// Response from DHIS2 Analytics API.
/// 
/// Example:
/// ```dart
/// final response = AnalyticsResponse.fromJson(apiResponse);
/// 
/// // Access data
/// for (final row in response.dataRows) {
///   print('Data: ${row.dataElement}, Period: ${row.period}, '
///         'OrgUnit: ${row.orgUnit}, Value: ${row.value}');
/// }
/// 
/// // Get display name for an ID
/// final name = response.getDisplayName('dataElementId');
/// ```
class AnalyticsResponse extends Equatable {
  /// Column headers describing each data position.
  final List<AnalyticsHeader> headers;

  /// Raw data rows as string arrays.
  final List<List<String>> rows;

  /// Metadata about dimensions and items.
  final AnalyticsMetadata metadata;

  /// Number of columns in each row.
  final int width;

  /// Number of data rows.
  final int height;

  /// Creates a new AnalyticsResponse.
  const AnalyticsResponse({
    required this.headers,
    required this.rows,
    required this.metadata,
    required this.width,
    required this.height,
  });

  /// Creates an empty response.
  factory AnalyticsResponse.empty() {
    return const AnalyticsResponse(
      headers: [],
      rows: [],
      metadata: AnalyticsMetadata(items: {}, dimensions: {}),
      width: 0,
      height: 0,
    );
  }

  /// Creates from JSON response.
  factory AnalyticsResponse.fromJson(Map<String, dynamic> json) {
    // Parse headers
    final headersJson = json['headers'] as List<dynamic>? ?? [];
    final headers = headersJson
        .map((h) => AnalyticsHeader.fromJson(h as Map<String, dynamic>))
        .toList();

    // Parse rows
    final rowsJson = json['rows'] as List<dynamic>? ?? [];
    final rows = rowsJson.map((r) {
      if (r is List) {
        return r.map((v) => v?.toString() ?? '').toList();
      }
      return <String>[];
    }).toList();

    // Parse metadata
    final metaJson = json['metaData'] as Map<String, dynamic>? ?? {};
    final metadata = AnalyticsMetadata.fromJson(metaJson);

    return AnalyticsResponse(
      headers: headers,
      rows: rows,
      metadata: metadata,
      width: json['width'] as int? ?? headers.length,
      height: json['height'] as int? ?? rows.length,
    );
  }

  /// Whether this response has data.
  bool get hasData => rows.isNotEmpty;

  /// Whether this response is empty.
  bool get isEmpty => rows.isEmpty;

  /// Gets the column index for a dimension.
  int? getColumnIndex(String dimension) {
    for (var i = 0; i < headers.length; i++) {
      if (headers[i].name == dimension) return i;
    }
    return null;
  }

  /// Gets the value at a specific row and column.
  String? getValue(int row, int column) {
    if (row < 0 || row >= rows.length) return null;
    if (column < 0 || column >= rows[row].length) return null;
    return rows[row][column];
  }

  /// Gets the display name for an item ID.
  String getDisplayName(String id) {
    return metadata.getDisplayName(id);
  }

  /// Parses rows into typed data rows for easier access.
  List<AnalyticsDataRow> get dataRows {
    final dxIndex = getColumnIndex('dx');
    final peIndex = getColumnIndex('pe');
    final ouIndex = getColumnIndex('ou');
    final valueIndex = getColumnIndex('value');

    return rows.map((row) {
      return AnalyticsDataRow(
        dataElement: dxIndex != null && dxIndex < row.length ? row[dxIndex] : null,
        period: peIndex != null && peIndex < row.length ? row[peIndex] : null,
        orgUnit: ouIndex != null && ouIndex < row.length ? row[ouIndex] : null,
        value: valueIndex != null && valueIndex < row.length
            ? double.tryParse(row[valueIndex])
            : null,
        rawValues: row,
      );
    }).toList();
  }

  /// Converts to a map structure for JSON serialization.
  Map<String, dynamic> toJson() {
    return {
      'headers': headers.map((h) => h.toJson()).toList(),
      'rows': rows,
      'metaData': metadata.toJson(),
      'width': width,
      'height': height,
    };
  }

  @override
  List<Object?> get props => [headers, rows, metadata, width, height];
}

/// Header definition for an analytics column.
class AnalyticsHeader extends Equatable {
  /// Column identifier (e.g., 'dx', 'pe', 'ou', 'value').
  final String name;

  /// Column name for display.
  final String column;

  /// Value type (TEXT, NUMBER, etc.).
  final String valueType;

  /// Data type.
  final String type;

  /// Whether this is hidden.
  final bool hidden;

  /// Whether this contains metadata.
  final bool meta;

  const AnalyticsHeader({
    required this.name,
    required this.column,
    required this.valueType,
    required this.type,
    this.hidden = false,
    this.meta = false,
  });

  factory AnalyticsHeader.fromJson(Map<String, dynamic> json) {
    return AnalyticsHeader(
      name: json['name'] as String? ?? '',
      column: json['column'] as String? ?? '',
      valueType: json['valueType'] as String? ?? 'TEXT',
      type: json['type'] as String? ?? 'java.lang.String',
      hidden: json['hidden'] as bool? ?? false,
      meta: json['meta'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'column': column,
      'valueType': valueType,
      'type': type,
      'hidden': hidden,
      'meta': meta,
    };
  }

  @override
  List<Object?> get props => [name, column, valueType, type, hidden, meta];
}

/// Metadata from analytics response.
class AnalyticsMetadata extends Equatable {
  /// Map of item IDs to their metadata.
  final Map<String, AnalyticsItem> items;

  /// Map of dimension names to their item IDs.
  final Map<String, List<String>> dimensions;

  const AnalyticsMetadata({
    required this.items,
    required this.dimensions,
  });

  factory AnalyticsMetadata.fromJson(Map<String, dynamic> json) {
    // Parse items
    final itemsJson = json['items'] as Map<String, dynamic>? ?? {};
    final items = <String, AnalyticsItem>{};
    for (final entry in itemsJson.entries) {
      if (entry.value is Map) {
        items[entry.key] =
            AnalyticsItem.fromJson(entry.value as Map<String, dynamic>);
      }
    }

    // Parse dimensions
    final dimensionsJson = json['dimensions'] as Map<String, dynamic>? ?? {};
    final dimensions = <String, List<String>>{};
    for (final entry in dimensionsJson.entries) {
      if (entry.value is List) {
        dimensions[entry.key] =
            (entry.value as List).map((e) => e.toString()).toList();
      }
    }

    return AnalyticsMetadata(items: items, dimensions: dimensions);
  }

  /// Gets the display name for an item ID.
  String getDisplayName(String id) {
    return items[id]?.name ?? id;
  }

  /// Gets items for a dimension.
  List<AnalyticsItem> getItemsForDimension(String dimension) {
    final itemIds = dimensions[dimension] ?? [];
    return itemIds
        .map((id) => items[id])
        .whereType<AnalyticsItem>()
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((k, v) => MapEntry(k, v.toJson())),
      'dimensions': dimensions,
    };
  }

  @override
  List<Object?> get props => [items, dimensions];
}

/// Individual metadata item.
class AnalyticsItem extends Equatable {
  /// Unique identifier.
  final String uid;

  /// Display name.
  final String name;

  /// Code (if available).
  final String? code;

  /// Dimension type.
  final String? dimensionItemType;

  const AnalyticsItem({
    required this.uid,
    required this.name,
    this.code,
    this.dimensionItemType,
  });

  factory AnalyticsItem.fromJson(Map<String, dynamic> json) {
    return AnalyticsItem(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      dimensionItemType: json['dimensionItemType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      if (code != null) 'code': code,
      if (dimensionItemType != null) 'dimensionItemType': dimensionItemType,
    };
  }

  @override
  List<Object?> get props => [uid, name, code, dimensionItemType];
}

/// Typed data row for easier access.
class AnalyticsDataRow extends Equatable {
  /// Data element/indicator ID.
  final String? dataElement;

  /// Period ID.
  final String? period;

  /// Organisation unit ID.
  final String? orgUnit;

  /// Numeric value.
  final double? value;

  /// All raw values from the row.
  final List<String> rawValues;

  const AnalyticsDataRow({
    this.dataElement,
    this.period,
    this.orgUnit,
    this.value,
    required this.rawValues,
  });

  /// Gets the value as a formatted string.
  String get formattedValue {
    if (value == null) return '-';
    if (value == value!.roundToDouble()) {
      return value!.toInt().toString();
    }
    return value!.toStringAsFixed(2);
  }

  @override
  List<Object?> get props => [dataElement, period, orgUnit, value, rawValues];
}
