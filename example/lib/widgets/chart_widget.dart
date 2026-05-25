import 'package:flutter/material.dart';
import 'package:dhis2_flutter_sdk/dhis2_flutter_sdk.dart';

/// A widget that displays analytics data as various chart types.
/// 
/// This widget transforms DHIS2 analytics response data into
/// visual chart representations using the SDK's chart transformer.
class ChartWidget extends StatelessWidget {
  final ChartData chartData;
  final ChartType chartType;
  final double height;
  final bool showLegend;
  final bool showLabels;

  const ChartWidget({
    super.key,
    required this.chartData,
    this.chartType = ChartType.bar,
    this.height = 300,
    this.showLegend = true,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (chartData.title != null) ...[
            Text(
              chartData.title!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (chartData.subtitle != null) ...[
            Text(
              chartData.subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: _buildChart(context),
          ),
          if (showLegend && chartData.series.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildLegend(context),
          ],
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    switch (chartType) {
      case ChartType.bar:
        return _buildBarChart(context);
      case ChartType.line:
        return _buildLineChart(context);
      case ChartType.pie:
        return _buildPieChart(context);
      case ChartType.stackedBar:
        return _buildStackedBarChart(context);
      case ChartType.area:
        return _buildAreaChart(context);
      default:
        return _buildBarChart(context);
    }
  }

  Widget _buildBarChart(BuildContext context) {
    if (chartData.series.isEmpty || chartData.categories.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final maxValue = _calculateMaxValue();
    final barWidth = 40.0;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(chartData.categories.length, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ...chartData.series.map((series) {
                      final value = index < series.data.length 
                          ? series.data[index].value ?? 0 
                          : 0;
                      final normalizedHeight = maxValue > 0 
                          ? (value / maxValue) * (constraints.maxHeight - 60)
                          : 0.0;
                      
                      return Column(
                        children: [
                          if (showLabels)
                            Text(
                              ValueFormatter.formatNumber(value.toDouble()),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          const SizedBox(height: 4),
                          Container(
                            width: barWidth,
                            height: normalizedHeight,
                            decoration: BoxDecoration(
                              color: series.color ?? _getDefaultColor(chartData.series.indexOf(series)),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: barWidth + 16,
                      child: Text(
                        chartData.categories[index],
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildLineChart(BuildContext context) {
    return CustomPaint(
      painter: LineChartPainter(
        chartData: chartData,
        showLabels: showLabels,
      ),
      size: Size.infinite,
    );
  }

  Widget _buildPieChart(BuildContext context) {
    if (chartData.series.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final series = chartData.series.first;
    final total = series.data.fold<num>(0, (sum, point) => sum + (point.value ?? 0));

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxHeight < constraints.maxWidth 
            ? constraints.maxHeight 
            : constraints.maxWidth;
        
        return Center(
          child: CustomPaint(
            painter: PieChartPainter(
              data: series.data,
              total: total.toDouble(),
              categories: chartData.categories,
            ),
            size: Size(size * 0.8, size * 0.8),
          ),
        );
      },
    );
  }

  Widget _buildStackedBarChart(BuildContext context) {
    // Similar to bar chart but with stacked series
    return _buildBarChart(context);
  }

  Widget _buildAreaChart(BuildContext context) {
    return CustomPaint(
      painter: AreaChartPainter(
        chartData: chartData,
        showLabels: showLabels,
      ),
      size: Size.infinite,
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: chartData.series.map((series) {
        final index = chartData.series.indexOf(series);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: series.color ?? _getDefaultColor(index),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              series.name,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      }).toList(),
    );
  }

  double _calculateMaxValue() {
    double max = 0;
    for (final series in chartData.series) {
      for (final point in series.data) {
        if (point.value != null && point.value! > max) {
          max = point.value!.toDouble();
        }
      }
    }
    return max;
  }

  Color _getDefaultColor(int index) {
    final colors = [
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFFC107),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
      const Color(0xFFFF5722),
      const Color(0xFF607D8B),
    ];
    return colors[index % colors.length];
  }
}

/// Custom painter for line charts
class LineChartPainter extends CustomPainter {
  final ChartData chartData;
  final bool showLabels;

  LineChartPainter({
    required this.chartData,
    this.showLabels = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (chartData.series.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final pointPaint = Paint()..style = PaintingStyle.fill;

    for (var seriesIndex = 0; seriesIndex < chartData.series.length; seriesIndex++) {
      final series = chartData.series[seriesIndex];
      if (series.data.isEmpty) continue;

      final color = series.color ?? _getDefaultColor(seriesIndex);
      paint.color = color;
      pointPaint.color = color;

      final maxValue = _calculateMaxValue();
      final path = Path();
      
      for (var i = 0; i < series.data.length; i++) {
        final value = series.data[i].value ?? 0;
        final x = (i / (series.data.length - 1)) * size.width;
        final y = size.height - ((value / maxValue) * size.height * 0.9);
        
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
        
        canvas.drawCircle(Offset(x, y), 4, pointPaint);
      }
      
      canvas.drawPath(path, paint);
    }
  }

  double _calculateMaxValue() {
    double max = 0;
    for (final series in chartData.series) {
      for (final point in series.data) {
        if (point.value != null && point.value! > max) {
          max = point.value!.toDouble();
        }
      }
    }
    return max > 0 ? max : 1;
  }

  Color _getDefaultColor(int index) {
    final colors = [
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFFC107),
      const Color(0xFFE91E63),
    ];
    return colors[index % colors.length];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom painter for pie charts
class PieChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final double total;
  final List<String> categories;

  PieChartPainter({
    required this.data,
    required this.total,
    required this.categories,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final paint = Paint()..style = PaintingStyle.fill;
    
    double startAngle = -90 * (3.14159 / 180);
    
    for (var i = 0; i < data.length; i++) {
      final value = data[i].value ?? 0;
      final sweepAngle = (value / total) * 2 * 3.14159;
      
      paint.color = _getDefaultColor(i);
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    }
  }

  Color _getDefaultColor(int index) {
    final colors = [
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFFC107),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
    ];
    return colors[index % colors.length];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom painter for area charts
class AreaChartPainter extends CustomPainter {
  final ChartData chartData;
  final bool showLabels;

  AreaChartPainter({
    required this.chartData,
    this.showLabels = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (chartData.series.isEmpty) return;

    for (var seriesIndex = 0; seriesIndex < chartData.series.length; seriesIndex++) {
      final series = chartData.series[seriesIndex];
      if (series.data.isEmpty) continue;

      final color = series.color ?? _getDefaultColor(seriesIndex);
      
      final linePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      final fillPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      final maxValue = _calculateMaxValue();
      final linePath = Path();
      final fillPath = Path();
      
      fillPath.moveTo(0, size.height);
      
      for (var i = 0; i < series.data.length; i++) {
        final value = series.data[i].value ?? 0;
        final x = (i / (series.data.length - 1)) * size.width;
        final y = size.height - ((value / maxValue) * size.height * 0.9);
        
        if (i == 0) {
          linePath.moveTo(x, y);
          fillPath.lineTo(x, y);
        } else {
          linePath.lineTo(x, y);
          fillPath.lineTo(x, y);
        }
      }
      
      fillPath.lineTo(size.width, size.height);
      fillPath.close();
      
      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(linePath, linePaint);
    }
  }

  double _calculateMaxValue() {
    double max = 0;
    for (final series in chartData.series) {
      for (final point in series.data) {
        if (point.value != null && point.value! > max) {
          max = point.value!.toDouble();
        }
      }
    }
    return max > 0 ? max : 1;
  }

  Color _getDefaultColor(int index) {
    final colors = [
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFFC107),
      const Color(0xFFE91E63),
    ];
    return colors[index % colors.length];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
