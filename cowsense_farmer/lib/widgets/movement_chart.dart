import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/movement_analysis_service.dart';

class MovementChart extends StatelessWidget {
  final List<MovementData> movementData;
  final String title;
  final Color lineColor;

  const MovementChart({
    super.key,
    required this.movementData,
    required this.title,
    this.lineColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (movementData.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Container(
          height: 220,
          padding: const EdgeInsets.all(20),
          child: const Center(
            child: Text(
              'No movement data available',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: theme.colorScheme.outline.withOpacity(0.2),
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
                            value.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= movementData.length) {
                            return const Text('');
                          }
                          final data = movementData[value.toInt()];
                          return Text(
                            '${data.timestamp.hour}:${data.timestamp.minute.toString().padLeft(2, '0')}',
                            style: theme.textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  minX: 0,
                  maxX: movementData.length.toDouble() - 1,
                  minY: 0,
                  maxY: movementData.isNotEmpty
                      ? movementData
                              .map((d) => d.magnitude)
                              .reduce((a, b) => a > b ? a : b) +
                          1
                      : 10,
                  lineBarsData: [
                    LineChartBarData(
                      spots: movementData.asMap().entries.map((entry) {
                        return FlSpot(
                            entry.key.toDouble(), entry.value.magnitude);
                      }).toList(),
                      isCurved: true,
                      color: lineColor,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(
                        show: false,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: lineColor.withOpacity(0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: theme.colorScheme.surface,
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          final data = movementData[barSpot.x.toInt()];
                          return LineTooltipItem(
                            '${data.timestamp.hour}:${data.timestamp.minute.toString().padLeft(2, '0')}\\n'
                            'Magnitude: ${data.magnitude.toStringAsFixed(2)}\\n'
                            'State: ${MovementAnalysisService.getMovementStateDisplayName(data.state)}',
                            TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MovementStateChart extends StatelessWidget {
  final List<MovementData> movementData;
  final String title;

  const MovementStateChart({
    super.key,
    required this.movementData,
    this.title = 'Movement States',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (movementData.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Container(
          height: 300,
          padding: const EdgeInsets.all(20),
          child: const Center(
            child: Text(
              'No movement data available',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    // Calculate state distribution
    final stateMap = <MovementState, int>{};
    for (final data in movementData) {
      stateMap[data.state] = (stateMap[data.state] ?? 0) + 1;
    }

    final sections = stateMap.entries.map((entry) {
      final percentage = (entry.value / movementData.length) * 100;
      return PieChartSectionData(
        color: MovementAnalysisService.getMovementStateColor(entry.key),
        value: percentage,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: stateMap.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: MovementAnalysisService
                                      .getMovementStateColor(entry.key),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  MovementAnalysisService
                                      .getMovementStateDisplayName(entry.key),
                                  style: theme.textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
