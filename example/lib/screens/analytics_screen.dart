import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dhis2_flutter_sdk/dhis2_flutter_sdk.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/sdk_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = false;
  String? _error;
  AnalyticsResponse? _response;
  ChartData? _chartData;
  
  // Query parameters
  String _selectedIndicator = 'Fbfj24BxbpB'; // ANC 1 Coverage
  String _selectedPeriod = 'LAST_12_MONTHS';
  String _selectedOrgUnit = 'ImspTQPwCqd'; // Sierra Leone

  final _indicators = [
    {'id': 'Fbfj24BxbpB', 'name': 'ANC 1 Coverage'},
    {'id': 'hCVSHjcml9g', 'name': 'ANC 4 Coverage'},
    {'id': 'ReUHfIn0pTQ', 'name': 'ANC 1-3 Dropout Rate'},
    {'id': 'dwEq7wi6nXV', 'name': 'Delivery rate (facility)'},
  ];

  final _periods = [
    {'id': 'LAST_12_MONTHS', 'name': 'Last 12 Months'},
    {'id': 'LAST_6_MONTHS', 'name': 'Last 6 Months'},
    {'id': 'LAST_4_QUARTERS', 'name': 'Last 4 Quarters'},
    {'id': 'THIS_YEAR', 'name': 'This Year'},
    {'id': 'LAST_YEAR', 'name': 'Last Year'},
  ];

  @override
  void initState() {
    super.initState();
    _runQuery();
  }

  Future<void> _runQuery() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final sdk = context.read<SdkProvider>().sdk;
    if (sdk == null) return;

    try {
      final result = await sdk.queryAnalytics()
          .withIndicators([_selectedIndicator])
          .withRelativePeriods([_selectedPeriod])
          .withOrganisationUnits([_selectedOrgUnit])
          .execute();

      if (result.isSuccess && result.data != null) {
        _response = result.data;
        
        // Transform to chart data
        _chartData = sdk.chartTransformer.transform(
          result.data!,
          config: const ChartConfig(
            type: ChartType.line,
            showDataLabels: false,
            showTooltips: true,
          ),
        );
      } else {
        _error = result.error?.toString() ?? 'Failed to load analytics';
      }
    } catch (e) {
      _error = e.toString();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runQuery,
          ),
        ],
      ),
      body: Column(
        children: [
          // Query Builder UI
          _buildQueryBuilder(theme),
          
          // Results
          Expanded(
            child: _buildResults(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildQueryBuilder(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Query Parameters',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            // Indicator dropdown
            DropdownButtonFormField<String>(
              value: _selectedIndicator,
              decoration: const InputDecoration(
                labelText: 'Indicator',
                isDense: true,
              ),
              items: _indicators.map((i) {
                return DropdownMenuItem(
                  value: i['id'],
                  child: Text(i['name']!, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedIndicator = value);
                }
              },
            ),
            const SizedBox(height: 12),
            
            // Period dropdown
            DropdownButtonFormField<String>(
              value: _selectedPeriod,
              decoration: const InputDecoration(
                labelText: 'Period',
                isDense: true,
              ),
              items: _periods.map((p) {
                return DropdownMenuItem(
                  value: p['id'],
                  child: Text(p['name']!),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedPeriod = value);
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Run Query button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _runQuery,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Run Query'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading analytics',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _runQuery,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_chartData == null || _chartData!.series.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No data available',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart
          _buildChart(theme),
          const SizedBox(height: 24),
          
          // Data Table
          _buildDataTable(theme),
        ],
      ),
    );
  }

  Widget _buildChart(ThemeData theme) {
    final series = _chartData!.series.first;
    final spots = <FlSpot>[];
    
    for (int i = 0; i < series.data.length; i++) {
      final value = series.data[i].value ?? 0;
      spots.add(FlSpot(i.toDouble(), value));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              series.name,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.colorScheme.outlineVariant,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: theme.textTheme.labelSmall,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 2,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _chartData!.categories.length) {
                            final label = _chartData!.categories[index];
                            // Shorten label
                            final shortLabel = label.length > 3 
                                ? label.substring(0, 3) 
                                : label;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                shortLabel,
                                style: theme.textTheme.labelSmall,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: theme.colorScheme.primary,
                            strokeWidth: 2,
                            strokeColor: theme.colorScheme.surface,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(ThemeData theme) {
    final series = _chartData!.series.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Table',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Period')),
                  DataColumn(label: Text('Value'), numeric: true),
                ],
                rows: List.generate(series.data.length, (index) {
                  final dataPoint = series.data[index];
                  final label = index < _chartData!.categories.length
                      ? _chartData!.categories[index]
                      : dataPoint.label ?? 'N/A';
                  
                  return DataRow(cells: [
                    DataCell(Text(label)),
                    DataCell(Text(dataPoint.formattedValue)),
                  ]);
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
