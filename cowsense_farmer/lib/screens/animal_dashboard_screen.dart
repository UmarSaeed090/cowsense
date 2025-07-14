import 'package:cowsense/screens/disease_detection_screen.dart';
import 'package:cowsense/screens/hire_doctor_screen.dart';
import 'package:cowsense/screens/movement_monitoring_screen.dart';
import 'package:cowsense/services/movement_analysis_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/dashboard_card.dart';
import '../providers/sensor_provider.dart';
import '../models/animal.dart';
import 'charts_screen.dart';
import 'alerts_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AnimalDashboardScreen extends StatefulWidget {
  final Animal animal;

  const AnimalDashboardScreen({
    super.key,
    required this.animal,
  });

  @override
  State<AnimalDashboardScreen> createState() => _AnimalDashboardScreenState();
}

class _AnimalDashboardScreenState extends State<AnimalDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch latest data for this specific cow
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SensorProvider>(context, listen: false)
          .fetchLatestDataForCow(widget.animal.tagNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        title: Text(widget.animal.name),
        actions: [
          // Notifications button with unread indicator
          IconButton(
            icon: Consumer<SensorProvider>(
              builder: (context, provider, child) {
                final hasUnread = provider
                    .getAlertsForAnimal(widget.animal.tagNumber)
                    .any((alert) => !alert.read);
                return Stack(
                  children: [
                    const Icon(Icons.notifications),
                    if (hasUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFCB2213),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AlertsScreen(animal: widget.animal),
                ),
              );
            },
          ),
          // Hire Doctor button
          IconButton(
            icon: const Icon(Icons.medical_services),
            tooltip: 'Hire Doctor',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HireDoctorScreen(animal: widget.animal),
                ),
              );
            },
          ),
          // Disease Detection button
          IconButton(
            icon: const Icon(Icons.image_search),
            tooltip: 'Disease Detection',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DiseaseDetectionScreen(animal: widget.animal),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<SensorProvider>(
        builder: (context, provider, child) {
          final data = provider.getAnimalData(widget.animal.tagNumber);
          if (data == null) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No Data Available',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Access Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChartsScreen(animal: widget.animal),
                              ),
                            );
                          },
                          icon:
                              const Icon(Icons.show_chart, color: Colors.blue),
                          label: const Text('View Charts'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.blue[50],
                            foregroundColor: Colors.blue[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MovementMonitoringScreen(
                                    animal: widget.animal),
                              ),
                            );
                          },
                          icon: const Icon(Icons.directions_walk,
                              color: Colors.green),
                          label: const Text('View Movement'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.green[50],
                            foregroundColor: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Animal Info Card
                  Card(
                    margin: const EdgeInsets.all(8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          if (widget.animal.imageUrl != null)
                            ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: widget.animal.imageUrl!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ))
                          else
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.pets,
                                  size: 40, color: Colors.grey),
                            ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tag: ${widget.animal.tagNumber}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text('Species: ${widget.animal.species}'),
                                const SizedBox(height: 4),
                                Text('Age: ${widget.animal.age} years'),
                                const SizedBox(height: 4),
                                Text('Weight: ${widget.animal.weight} kg'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Health Metrics
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Health Metrics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DashboardCard(
                    title: 'Body Temperature',
                    value: data.ds18b20.temperature.toStringAsFixed(1),
                    unit: '°C',
                    status:
                        provider.getTemperatureStatus(data.ds18b20.temperature),
                    normalRange: '38°C - 39.3°C',
                    color:
                        provider.getTemperatureColor(data.ds18b20.temperature),
                    icon: Icons.thermostat,
                  ),
                  const SizedBox(height: 8),
                  DashboardCard(
                    title: 'Heart Rate',
                    value: data.max30100.heartRate.toString(),
                    unit: 'BPM',
                    status:
                        provider.getHeartRateStatus(data.max30100.heartRate),
                    normalRange: '60 - 90 BPM',
                    color: provider.getHeartRateColor(data.max30100.heartRate),
                    icon: Icons.favorite,
                  ),
                  const SizedBox(height: 8),
                  DashboardCard(
                    title: 'Blood Oxygen (SpO2)',
                    value: data.max30100.spo2.toString(),
                    unit: '%',
                    status: provider.getSpO2Status(data.max30100.spo2),
                    normalRange: '95% - 100%',
                    color: provider.getSpO2Color(data.max30100.spo2),
                    icon: Icons.bloodtype,
                  ),
                  const SizedBox(height: 8),
                  // Movement Status Card
                  DashboardCard(
                    title: 'Movement Status',
                    value: provider.getMovementStateStatus(provider
                        .getCurrentMovementState(widget.animal.tagNumber)),
                    unit: '',
                    status: provider
                        .getMovementIntensityForAnimal(widget.animal.tagNumber),
                    normalRange: 'Active 60% - 80% of day',
                    color: provider.getCurrentMovementState(
                                widget.animal.tagNumber) !=
                            null
                        ? MovementAnalysisService.getMovementStateColor(provider
                            .getCurrentMovementState(widget.animal.tagNumber)!)
                        : Colors.grey,
                    icon: Icons.pets,
                  ),
                  const SizedBox(height: 8),
                  // Activity Summary Card
                  Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.trending_up, color: Colors.green[700]),
                              const SizedBox(width: 8),
                              const Text('Daily Activity',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Activity Level',
                                      style: TextStyle(fontSize: 14)),
                                  Text(
                                      '${provider.getActivityPercentageForAnimal(widget.animal.tagNumber).toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18)),
                                  Text(
                                      provider.getActivityPercentageForAnimal(
                                                  widget.animal.tagNumber) >
                                              60
                                          ? 'Good'
                                          : provider.getActivityPercentageForAnimal(
                                                      widget.animal.tagNumber) >
                                                  40
                                              ? 'Moderate'
                                              : 'Low',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: provider
                                                      .getActivityPercentageForAnimal(
                                                          widget.animal
                                                              .tagNumber) >
                                                  60
                                              ? Colors.green
                                              : provider.getActivityPercentageForAnimal(
                                                          widget.animal
                                                              .tagNumber) >
                                                      40
                                                  ? Colors.orange
                                                  : Colors.red)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Step Count',
                                      style: TextStyle(fontSize: 14)),
                                  Text(
                                      '${provider.getDailyMovementSummary(widget.animal.tagNumber)?.stepCount ?? 0}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18)),
                                  const Text('Today',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('Optimal activity: 60% - 80%',
                              style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),

                  // Environment Card
                  Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.water_drop, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              const Text('Environment',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Temperature',
                                      style: TextStyle(fontSize: 14)),
                                  Text(
                                      '${data.dht22.temperature.toStringAsFixed(1)}°C',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Humidity',
                                      style: TextStyle(fontSize: 14)),
                                  Text(
                                      '${data.dht22.humidity.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: provider.getHumidityColor(
                                              data.dht22.humidity))),
                                  Text(
                                      provider.getHumidityStatus(
                                          data.dht22.humidity),
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: provider.getHumidityColor(
                                              data.dht22.humidity))),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('Optimal humidity: 40% - 80%',
                              style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
