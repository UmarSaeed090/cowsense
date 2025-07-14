import '../util/loader_animation_widget.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../util/sensor_data.dart'; // Assume this is your sensor data model
import '../util/sensor_chart.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = 'https://sensors-backend-k6qw.onrender.com';

class ChartsScreen extends StatefulWidget {

  const ChartsScreen({
    super.key,
  });

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();
  late String animalTagNumber;
  List<SensorData> data = [];

  @override
  void initState() {
    super.initState();
    _fetchHistoricalData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null || !args.containsKey('animalTagNumber')) {
      // Handle missing argument, maybe pop or show error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No animalTagNumber provided')),
        );
        Navigator.of(context).pop();
      });
      return;
    }

    animalTagNumber = args['animalTagNumber'];

    _fetchHistoricalData();
  }

  Future<List<SensorData>> getHistoricalData(DateTime date) async {
    try {
      final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await http.get(
        Uri.parse('$baseUrl/api/sensors/all?date=$formattedDate'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        return responseData.map((json) => SensorData.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load historical data');
      }
    } catch (e) {
      print('Error fetching historical data: $e');
      rethrow;
    }
  }

  Future<void> _fetchHistoricalData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final allData = await getHistoricalData(selectedDate);
      // Replace 'tagNumber' below with actual field name in your SensorData class
      final filteredData = allData.where((d) => d.tagNumber == animalTagNumber).toList();

      setState(() {
        data = filteredData;
      });
    } catch (e) {
      setState(() {
        data = [];
      });
      debugPrint('Error fetching historical data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  Future<void> _onDatePicked(DateTime date) async {
    setState(() {
      selectedDate = date;
    });
    await _fetchHistoricalData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: theme.colorScheme.surface,
              elevation: 0,
              title: Text(
                'Health Metrics',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.calendar_today,
                            color: theme.colorScheme.onPrimaryContainer),
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: theme.copyWith(
                                  colorScheme: theme.colorScheme.copyWith(
                                    primary: theme.colorScheme.primary,
                                    onPrimary: theme.colorScheme.onPrimary,
                                    surface: theme.colorScheme.surface,
                                    onSurface: theme.colorScheme.onSurface,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            await _onDatePicked(picked);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isLoading)
                      const Center(child: LoaderAnimationWidget()),
                    if (!isLoading && data.isNotEmpty) ...[
                      _buildChartSection(
                        context,
                        title: 'Body Temperature',
                        subtitle: 'Core body temperature monitoring',
                        icon: Icons.thermostat,
                        color: Colors.orange,
                        child: SensorChart(
                          data: data,
                          title: '',
                          valueSelector: (d) => d.ds18b20.temperature,
                          valueLabel: '°C',
                          lineColor: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildChartSection(
                        context,
                        title: 'Heart Rate & Blood Oxygen',
                        subtitle: 'Vital signs monitoring',
                        icon: Icons.favorite,
                        color: Colors.red,
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: theme.colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: SizedBox(
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
                                            value.toInt().toString(),
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
                                          if (value.toInt() >= data.length) return const Text('');
                                          final date = data[value.toInt()].timestamp;
                                          return Text(
                                            '${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                            style: theme.textTheme.bodySmall,
                                          );
                                        },
                                      ),
                                    ),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border.all(
                                      color: theme.colorScheme.outline.withOpacity(0.2),
                                    ),
                                  ),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: List.generate(
                                        data.length,
                                            (i) => FlSpot(i.toDouble(), data[i].max30100.heartRate.toDouble()),
                                      ),
                                      isCurved: true,
                                      color: Colors.blue,
                                      barWidth: 4,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(show: true),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: Colors.blue.withOpacity(0.15),
                                      ),
                                    ),
                                    LineChartBarData(
                                      spots: List.generate(
                                        data.length,
                                            (i) => FlSpot(i.toDouble(), data[i].max30100.spo2.toDouble()),
                                      ),
                                      isCurved: true,
                                      color: Colors.red,
                                      barWidth: 4,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(show: true),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: Colors.red.withOpacity(0.15),
                                      ),
                                    ),
                                  ],
                                  lineTouchData: LineTouchData(
                                    touchTooltipData: LineTouchTooltipData(
                                      tooltipBgColor: theme.colorScheme.surface,
                                      tooltipRoundedRadius: 8,
                                      getTooltipItems: (touchedSpots) {
                                        return touchedSpots.map((spot) {
                                          final idx = spot.x.toInt();
                                          final date = data[idx].timestamp;
                                          return LineTooltipItem(
                                            '${date.hour}:${date.minute.toString().padLeft(2, '0')}\n${spot.y.toStringAsFixed(1)}',
                                            theme.textTheme.bodyMedium!.copyWith(
                                              color: theme.colorScheme.onSurface,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        }).toList();
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildChartSection(
                        context,
                        title: 'Environmental Temperature',
                        subtitle: 'Ambient temperature monitoring',
                        icon: Icons.wb_sunny,
                        color: Colors.teal,
                        child: SensorChart(
                          data: data,
                          title: '',
                          valueSelector: (d) => d.dht22.temperature,
                          valueLabel: '°C',
                          lineColor: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildChartSection(
                        context,
                        title: 'Environmental Humidity',
                        subtitle: 'Relative humidity monitoring',
                        icon: Icons.water_drop,
                        color: Colors.blue,
                        child: SensorChart(
                          data: data,
                          title: '',
                          valueSelector: (d) => d.dht22.humidity,
                          valueLabel: '%',
                          lineColor: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildChartSection(
                        context,
                        title: 'Movement',
                        subtitle: 'Activity and distance tracking',
                        icon: Icons.directions_walk,
                        color: Colors.purple,
                        child: SensorChart(
                          data: data,
                          title: '',
                          valueSelector: (d) => d.gps.latitude + d.gps.longitude,
                          valueLabel: '',
                          lineColor: Colors.purple,
                        ),
                      ),
                    ],
                    if (!isLoading && data.isEmpty)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bar_chart,
                              size: 64,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No data available for this date',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
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

  Widget _buildChartSection(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required Widget child,
      }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}
