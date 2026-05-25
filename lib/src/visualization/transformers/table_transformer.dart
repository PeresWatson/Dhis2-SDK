import '../models/table_data.dart';
import '../../analytics/models/analytics_response.dart';
import '../../logging/sdk_logger.dart';

/// Transforms DHIS2 analytics responses into table-ready data structures.
/// 
/// Handles pivot tables, cross-tabulation, and various table layouts
/// commonly used in DHIS2 dashboards.
class TableTransformer {
  final SdkLogger _logger;

  TableTransformer({SdkLogger? logger}) : _logger = logger ?? SdkLogger();

  /// Transform analytics response to table data
  TableData transform(
    AnalyticsResponse response, {
    TableConfig config = const TableConfig(),
    String? rowDimension,
    String? columnDimension,
  }) {
    _logger.debug(
      'Transforming analytics to table',
      tag: 'TableTransformer',
      data: {'rows': response.rows.length, 'headers': response.headers.length},
    );

    if (config.pivotTable && rowDimension != null && columnDimension != null) {
      return _transformToPivotTable(
        response, 
        config, 
        rowDimension, 
        columnDimension,
      );
    }

    return _transformToFlatTable(response, config);
  }

  TableData _transformToFlatTable(
    AnalyticsResponse response,
    TableConfig config,
  ) {
    // Build columns from headers
    final columns = <TableColumn>[];
    for (final header in response.headers) {
      columns.add(TableColumn(
        key: header.name,
        label: header.column ?? header.name,
        type: _mapColumnType(header.valueType),
        align: _getAlignment(header.valueType),
      ));
    }

    // Build rows from data
    final rows = <TableRow>[];
    final totals = <String, double>{};

    for (int i = 0; i < response.rows.length; i++) {
      final rowData = response.rows[i];
      final cells = <String, dynamic>{};

      for (int j = 0; j < response.headers.length && j < rowData.length; j++) {
        final header = response.headers[j];
        var value = rowData[j];

        // Resolve names for dimension values
        if (header.valueType != 'NUMBER') {
          value = _resolveName(response, value?.toString() ?? '');
        } else if (value != null) {
          // Accumulate totals for numeric columns
          final numValue = _parseDouble(value);
          totals[header.name] = (totals[header.name] ?? 0) + numValue;
        }

        cells[header.name] = value;
      }

      rows.add(TableRow(
        id: i.toString(),
        cells: cells,
      ));
    }

    // Apply sorting
    if (config.sortColumn != null) {
      _sortRows(rows, config.sortColumn!, config.sortDirection, columns);
    }

    // Build totals row
    TableRow? totalsRow;
    if (config.showColumnTotals && totals.isNotEmpty) {
      final totalsCells = <String, dynamic>{};
      for (final column in columns) {
        if (totals.containsKey(column.key)) {
          totalsCells[column.key] = _formatNumber(
            totals[column.key]!, 
            config.numberFormat,
          );
        } else if (column == columns.first) {
          totalsCells[column.key] = 'Total';
        } else {
          totalsCells[column.key] = '';
        }
      }
      totalsRow = TableRow(
        cells: totalsCells,
        isTotal: true,
      );
    }

    return TableData(
      title: config.title,
      columns: columns,
      rows: rows,
      totalsRow: totalsRow,
      config: config,
    );
  }

  TableData _transformToPivotTable(
    AnalyticsResponse response,
    TableConfig config,
    String rowDimension,
    String columnDimension,
  ) {
    final rowIndex = _findHeaderIndex(response, rowDimension);
    final columnIndex = _findHeaderIndex(response, columnDimension);
    final valueIndex = _findHeaderIndex(response, 'value');

    if (rowIndex < 0 || columnIndex < 0 || valueIndex < 0) {
      _logger.warning(
        'Invalid dimensions for pivot table',
        tag: 'TableTransformer',
      );
      return _transformToFlatTable(response, config);
    }

    // Collect unique row and column values
    final rowValues = <String>{};
    final columnValues = <String>{};
    final dataMap = <String, Map<String, double>>{};

    for (final row in response.rows) {
      final rowId = row[rowIndex]?.toString() ?? '';
      final colId = row[columnIndex]?.toString() ?? '';
      final value = _parseDouble(row[valueIndex]);

      rowValues.add(rowId);
      columnValues.add(colId);

      dataMap.putIfAbsent(rowId, () => {});
      dataMap[rowId]![colId] = value;
    }

    // Sort values
    final sortedRowValues = rowValues.toList()..sort();
    final sortedColumnValues = columnValues.toList()..sort();

    // Build columns
    final columns = <TableColumn>[
      TableColumn(
        key: 'row_header',
        label: _resolveDimensionName(response, rowDimension),
        type: ColumnType.text,
        align: TextAlign.left,
      ),
    ];

    for (final colId in sortedColumnValues) {
      columns.add(TableColumn(
        key: colId,
        label: _resolveName(response, colId),
        type: ColumnType.number,
        align: TextAlign.right,
      ));
    }

    if (config.showRowTotals) {
      columns.add(TableColumn(
        key: 'row_total',
        label: 'Total',
        type: ColumnType.number,
        align: TextAlign.right,
      ));
    }

    // Build rows
    final rows = <TableRow>[];
    final columnTotals = <String, double>{};

    for (final rowId in sortedRowValues) {
      final cells = <String, dynamic>{
        'row_header': _resolveName(response, rowId),
      };

      double rowTotal = 0;
      for (final colId in sortedColumnValues) {
        final value = dataMap[rowId]?[colId] ?? 0;
        cells[colId] = _formatNumber(value, config.numberFormat);
        rowTotal += value;
        columnTotals[colId] = (columnTotals[colId] ?? 0) + value;
      }

      if (config.showRowTotals) {
        cells['row_total'] = _formatNumber(rowTotal, config.numberFormat);
        columnTotals['row_total'] = (columnTotals['row_total'] ?? 0) + rowTotal;
      }

      rows.add(TableRow(
        id: rowId,
        cells: cells,
      ));
    }

    // Build totals row
    TableRow? totalsRow;
    if (config.showColumnTotals) {
      final totalsCells = <String, dynamic>{
        'row_header': 'Total',
      };
      for (final colId in sortedColumnValues) {
        totalsCells[colId] = _formatNumber(
          columnTotals[colId] ?? 0, 
          config.numberFormat,
        );
      }
      if (config.showRowTotals) {
        totalsCells['row_total'] = _formatNumber(
          columnTotals['row_total'] ?? 0, 
          config.numberFormat,
        );
      }
      totalsRow = TableRow(
        cells: totalsCells,
        isTotal: true,
      );
    }

    return TableData(
      title: config.title,
      columns: columns,
      rows: rows,
      totalsRow: totalsRow,
      config: config,
      metadata: {
        'rowDimension': rowDimension,
        'columnDimension': columnDimension,
        'rowCount': sortedRowValues.length,
        'columnCount': sortedColumnValues.length,
      },
    );
  }

  int _findHeaderIndex(AnalyticsResponse response, String name) {
    for (int i = 0; i < response.headers.length; i++) {
      if (response.headers[i].name == name) {
        return i;
      }
    }
    return -1;
  }

  String _resolveName(AnalyticsResponse response, String id) {
    final items = response.metaData?.items;
    if (items != null && items.containsKey(id)) {
      return items[id]?['name']?.toString() ?? id;
    }
    return id;
  }

  String _resolveDimensionName(AnalyticsResponse response, String dimension) {
    // Map common dimension IDs to readable names
    switch (dimension) {
      case 'pe':
        return 'Period';
      case 'ou':
        return 'Organisation Unit';
      case 'dx':
        return 'Data';
      default:
        return _resolveName(response, dimension);
    }
  }

  ColumnType _mapColumnType(String? valueType) {
    switch (valueType) {
      case 'NUMBER':
        return ColumnType.number;
      case 'INTEGER':
        return ColumnType.number;
      case 'PERCENTAGE':
        return ColumnType.percent;
      case 'DATE':
        return ColumnType.date;
      case 'BOOLEAN':
        return ColumnType.boolean;
      default:
        return ColumnType.text;
    }
  }

  TextAlign _getAlignment(String? valueType) {
    switch (valueType) {
      case 'NUMBER':
      case 'INTEGER':
      case 'PERCENTAGE':
        return TextAlign.right;
      default:
        return TextAlign.left;
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _formatNumber(double value, NumberFormat format) {
    switch (format) {
      case NumberFormat.integer:
        return value.truncate().toString();
      case NumberFormat.percent:
        return '${(value * 100).toStringAsFixed(1)}%';
      case NumberFormat.currency:
        return '\$${value.toStringAsFixed(2)}';
      case NumberFormat.scientific:
        return value.toStringAsExponential(2);
      case NumberFormat.decimal:
      default:
        if (value == value.truncate()) {
          return value.truncate().toString();
        }
        return value.toStringAsFixed(2);
    }
  }

  void _sortRows(
    List<TableRow> rows,
    String columnKey,
    SortDirection direction,
    List<TableColumn> columns,
  ) {
    if (direction == SortDirection.none) return;

    final column = columns.firstWhere(
      (c) => c.key == columnKey,
      orElse: () => columns.first,
    );

    rows.sort((a, b) {
      final aValue = a.cells[columnKey];
      final bValue = b.cells[columnKey];

      int comparison;
      if (column.type == ColumnType.number || column.type == ColumnType.percent) {
        final aNum = _parseDouble(aValue);
        final bNum = _parseDouble(bValue);
        comparison = aNum.compareTo(bNum);
      } else {
        comparison = (aValue?.toString() ?? '')
            .compareTo(bValue?.toString() ?? '');
      }

      return direction == SortDirection.descending ? -comparison : comparison;
    });
  }
}
