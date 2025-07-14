import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../util/sensor_data.dart';

class SensorChart extends StatelessWidget {
  final List<SensorData> data;
  final String title;
  final double Function(SensorData) valueSelector;
  final String valueLabel;
  final Color lineColor;

  const SensorChart({
    Key? key,
    required this.data,
    required this.title,
    required this.valueSelector,
    required this.valueLabel,
    required this.lineColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(child: Text('No data available for $title')),
        ),
      );
    }

    final minY = data.map(valueSelector).reduce((a, b) => a < b ? a : b) - 2;
    final maxY = data.map(valueSelector).reduce((a, b) => a > b ? a : b) + 2;

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(show: true, drawVerticalLine: true, horizontalInterval: 1),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text('${value.toStringAsFixed(0)}$valueLabel', style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= data.length) return const Text('');
                          final date = data[value.toInt()].timestamp;
                          return Text('${date.hour}:${date.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), valueSelector(data[i]))),
                      isCurved: true,
                      color: lineColor,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: lineColor.withOpacity(0.15)),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.white,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final idx = spot.x.toInt();
                          final date = data[idx].timestamp;
                          return LineTooltipItem(
                            '${date.hour}:${date.minute.toString().padLeft(2, '0')}\n${spot.y.toStringAsFixed(1)}$valueLabel',
                            const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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