import 'package:flutter/material.dart';
import 'package:dhis2_flutter_sdk/dhis2_flutter_sdk.dart';

/// A widget that displays analytics data in a formatted table.
/// 
/// This widget transforms DHIS2 analytics response data into
/// a structured table with sortable columns and pagination.
class DataTableWidget extends StatefulWidget {
  final TableData tableData;
  final bool sortable;
  final bool paginated;
  final int rowsPerPage;
  final ValueChanged<TableCell>? onCellTap;

  const DataTableWidget({
    super.key,
    required this.tableData,
    this.sortable = true,
    this.paginated = true,
    this.rowsPerPage = 10,
    this.onCellTap,
  });

  @override
  State<DataTableWidget> createState() => _DataTableWidgetState();
}

class _DataTableWidgetState extends State<DataTableWidget> {
  late List<TableRow> _sortedRows;
  int _sortColumnIndex = -1;
  bool _sortAscending = true;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _sortedRows = List.from(widget.tableData.rows);
  }

  @override
  void didUpdateWidget(covariant DataTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tableData != widget.tableData) {
      _sortedRows = List.from(widget.tableData.rows);
      _sortColumnIndex = -1;
      _currentPage = 0;
    }
  }

  void _sort(int columnIndex) {
    if (!widget.sortable) return;

    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = columnIndex;
        _sortAscending = true;
      }

      _sortedRows.sort((a, b) {
        final aValue = columnIndex < a.cells.length ? a.cells[columnIndex].value : '';
        final bValue = columnIndex < b.cells.length ? b.cells[columnIndex].value : '';

        // Try numeric comparison first
        final aNum = num.tryParse(aValue?.toString() ?? '');
        final bNum = num.tryParse(bValue?.toString() ?? '');

        int result;
        if (aNum != null && bNum != null) {
          result = aNum.compareTo(bNum);
        } else {
          result = (aValue?.toString() ?? '').compareTo(bValue?.toString() ?? '');
        }

        return _sortAscending ? result : -result;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (widget.tableData.headers.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final totalPages = widget.paginated 
        ? (_sortedRows.length / widget.rowsPerPage).ceil()
        : 1;
    
    final displayRows = widget.paginated
        ? _sortedRows
            .skip(_currentPage * widget.rowsPerPage)
            .take(widget.rowsPerPage)
            .toList()
        : _sortedRows;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.tableData.title != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.tableData.title!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  sortColumnIndex: _sortColumnIndex >= 0 ? _sortColumnIndex : null,
                  sortAscending: _sortAscending,
                  headingRowColor: WidgetStateProperty.all(
                    theme.colorScheme.surfaceContainerHighest,
                  ),
                  columns: _buildColumns(),
                  rows: _buildRows(displayRows),
                ),
              ),
            ),
          ),
          if (widget.paginated && totalPages > 1)
            _buildPagination(totalPages),
        ],
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    return widget.tableData.headers.asMap().entries.map((entry) {
      final index = entry.key;
      final header = entry.value;
      
      return DataColumn(
        label: Expanded(
          child: Text(
            header.label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        numeric: header.isNumeric,
        onSort: widget.sortable ? (columnIndex, ascending) => _sort(index) : null,
      );
    }).toList();
  }

  List<DataRow> _buildRows(List<TableRow> rows) {
    return rows.asMap().entries.map((entry) {
      final rowIndex = entry.key;
      final row = entry.value;
      
      return DataRow(
        color: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5);
          }
          return rowIndex.isEven 
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).colorScheme.surfaceContainerLowest;
        }),
        cells: _buildCells(row),
      );
    }).toList();
  }

  List<DataCell> _buildCells(TableRow row) {
    return List.generate(widget.tableData.headers.length, (index) {
      final cell = index < row.cells.length ? row.cells[index] : TableCell(value: '');
      final header = widget.tableData.headers[index];
      
      String displayValue;
      if (header.isNumeric && cell.value != null) {
        final numValue = num.tryParse(cell.value.toString());
        if (numValue != null) {
          displayValue = ValueFormatter.formatNumber(
            numValue.toDouble(),
            decimals: header.decimals ?? 0,
          );
        } else {
          displayValue = cell.value?.toString() ?? '-';
        }
      } else {
        displayValue = cell.value?.toString() ?? '-';
      }
      
      return DataCell(
        Container(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Text(
            displayValue,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: cell.color,
              fontWeight: cell.isBold ? FontWeight.bold : null,
            ),
          ),
        ),
        onTap: widget.onCellTap != null ? () => widget.onCellTap!(cell) : null,
      );
    });
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${_currentPage + 1} of $totalPages',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: _currentPage > 0
                    ? () => setState(() => _currentPage = 0)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 0
                    ? () => setState(() => _currentPage--)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < totalPages - 1
                    ? () => setState(() => _currentPage++)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: _currentPage < totalPages - 1
                    ? () => setState(() => _currentPage = totalPages - 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Extension to add convenience methods to TableData
extension TableDataExtension on TableData {
  /// Export table data to CSV format
  String toCsv() {
    final buffer = StringBuffer();
    
    // Headers
    buffer.writeln(headers.map((h) => '"${h.label}"').join(','));
    
    // Rows
    for (final row in rows) {
      buffer.writeln(row.cells.map((c) => '"${c.value ?? ''}"').join(','));
    }
    
    return buffer.toString();
  }
}
