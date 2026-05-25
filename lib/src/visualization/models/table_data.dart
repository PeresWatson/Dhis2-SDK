import '../analytics/models/analytics_response.dart';

/// Configuration for table data transformation
class TableConfig {
  /// Title for the table
  final String? title;
  
  /// Whether to show row numbers
  final bool showRowNumbers;
  
  /// Whether to show column totals
  final bool showColumnTotals;
  
  /// Whether to show row totals
  final bool showRowTotals;
  
  /// Whether to show subtotals
  final bool showSubtotals;
  
  /// Column to sort by
  final String? sortColumn;
  
  /// Sort direction
  final SortDirection sortDirection;
  
  /// Number format for values
  final NumberFormat numberFormat;
  
  /// Whether to highlight min/max values
  final bool highlightExtremes;
  
  /// Whether to show as pivot table
  final bool pivotTable;
  
  /// Column headers to freeze
  final int frozenColumns;
  
  /// Row headers to freeze
  final int frozenRows;

  const TableConfig({
    this.title,
    this.showRowNumbers = false,
    this.showColumnTotals = true,
    this.showRowTotals = false,
    this.showSubtotals = false,
    this.sortColumn,
    this.sortDirection = SortDirection.none,
    this.numberFormat = NumberFormat.decimal,
    this.highlightExtremes = false,
    this.pivotTable = false,
    this.frozenColumns = 0,
    this.frozenRows = 1,
  });

  TableConfig copyWith({
    String? title,
    bool? showRowNumbers,
    bool? showColumnTotals,
    bool? showRowTotals,
    bool? showSubtotals,
    String? sortColumn,
    SortDirection? sortDirection,
    NumberFormat? numberFormat,
    bool? highlightExtremes,
    bool? pivotTable,
    int? frozenColumns,
    int? frozenRows,
  }) {
    return TableConfig(
      title: title ?? this.title,
      showRowNumbers: showRowNumbers ?? this.showRowNumbers,
      showColumnTotals: showColumnTotals ?? this.showColumnTotals,
      showRowTotals: showRowTotals ?? this.showRowTotals,
      showSubtotals: showSubtotals ?? this.showSubtotals,
      sortColumn: sortColumn ?? this.sortColumn,
      sortDirection: sortDirection ?? this.sortDirection,
      numberFormat: numberFormat ?? this.numberFormat,
      highlightExtremes: highlightExtremes ?? this.highlightExtremes,
      pivotTable: pivotTable ?? this.pivotTable,
      frozenColumns: frozenColumns ?? this.frozenColumns,
      frozenRows: frozenRows ?? this.frozenRows,
    );
  }
}

/// Sort direction
enum SortDirection {
  none,
  ascending,
  descending,
}

/// Number format options
enum NumberFormat {
  decimal,
  integer,
  percent,
  currency,
  scientific,
}

/// Transformed table data ready for display
class TableData {
  final String? title;
  final List<TableColumn> columns;
  final List<TableRow> rows;
  final TableRow? totalsRow;
  final TableConfig config;
  final Map<String, dynamic>? metadata;

  const TableData({
    this.title,
    required this.columns,
    required this.rows,
    this.totalsRow,
    required this.config,
    this.metadata,
  });

  /// Number of data rows
  int get rowCount => rows.length;

  /// Number of columns
  int get columnCount => columns.length;

  /// Get a specific cell value
  dynamic getCellValue(int row, int column) {
    if (row < 0 || row >= rows.length) return null;
    if (column < 0 || column >= columns.length) return null;
    
    final columnKey = columns[column].key;
    return rows[row].cells[columnKey];
  }

  /// Get a column by key
  TableColumn? getColumn(String key) {
    try {
      return columns.firstWhere((c) => c.key == key);
    } catch (_) {
      return null;
    }
  }

  /// Convert to CSV string
  String toCsv({String separator = ','}) {
    final buffer = StringBuffer();
    
    // Headers
    buffer.writeln(columns.map((c) => _escapeCsv(c.label)).join(separator));
    
    // Data rows
    for (final row in rows) {
      final values = columns.map((c) => 
          _escapeCsv(row.cells[c.key]?.toString() ?? ''));
      buffer.writeln(values.join(separator));
    }
    
    // Totals row
    if (totalsRow != null) {
      final values = columns.map((c) => 
          _escapeCsv(totalsRow!.cells[c.key]?.toString() ?? ''));
      buffer.writeln(values.join(separator));
    }
    
    return buffer.toString();
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Convert to a list of maps
  List<Map<String, dynamic>> toListOfMaps() {
    return rows.map((row) {
      final map = <String, dynamic>{};
      for (final column in columns) {
        map[column.key] = row.cells[column.key];
      }
      return map;
    }).toList();
  }
}

/// A column in the table
class TableColumn {
  final String key;
  final String label;
  final ColumnType type;
  final int? width;
  final TextAlign align;
  final bool sortable;
  final bool visible;
  final String? format;

  const TableColumn({
    required this.key,
    required this.label,
    this.type = ColumnType.text,
    this.width,
    this.align = TextAlign.left,
    this.sortable = true,
    this.visible = true,
    this.format,
  });

  TableColumn copyWith({
    String? key,
    String? label,
    ColumnType? type,
    int? width,
    TextAlign? align,
    bool? sortable,
    bool? visible,
    String? format,
  }) {
    return TableColumn(
      key: key ?? this.key,
      label: label ?? this.label,
      type: type ?? this.type,
      width: width ?? this.width,
      align: align ?? this.align,
      sortable: sortable ?? this.sortable,
      visible: visible ?? this.visible,
      format: format ?? this.format,
    );
  }
}

/// Column data types
enum ColumnType {
  text,
  number,
  percent,
  date,
  boolean,
  currency,
}

/// Text alignment
enum TextAlign {
  left,
  center,
  right,
}

/// A row in the table
class TableRow {
  final String? id;
  final Map<String, dynamic> cells;
  final bool isHeader;
  final bool isTotal;
  final int? depth;

  const TableRow({
    this.id,
    required this.cells,
    this.isHeader = false,
    this.isTotal = false,
    this.depth,
  });

  /// Get a cell value by column key
  dynamic operator [](String key) => cells[key];

  /// Check if cell exists
  bool hasCell(String key) => cells.containsKey(key);

  TableRow copyWith({
    String? id,
    Map<String, dynamic>? cells,
    bool? isHeader,
    bool? isTotal,
    int? depth,
  }) {
    return TableRow(
      id: id ?? this.id,
      cells: cells ?? this.cells,
      isHeader: isHeader ?? this.isHeader,
      isTotal: isTotal ?? this.isTotal,
      depth: depth ?? this.depth,
    );
  }
}
