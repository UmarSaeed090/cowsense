import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../providers/sensor_provider.dart';
import '../models/animal.dart';
import '../services/movement_analysis_service.dart';
import '../widgets/movement_chart.dart';

class MovementMonitoringScreen extends StatelessWidget {
  final Animal animal;

  const MovementMonitoringScreen({
    super.key,
    required this.animal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<SensorProvider>(
      builder: (context, provider, child) {
        final movementData =
            provider.getMovementAnalysisForAnimal(animal.tagNumber);
        final currentState = provider.getCurrentMovementState(animal.tagNumber);
        final dailySummary = provider.getDailyMovementSummary(animal.tagNumber);
        final selectedDate = provider.selectedDate;
        final isLoading = provider.isLoading;

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
                    '${animal.name}\'s Movement Tracking',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
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
                              );
                              if (picked != null) {
                                await provider.setDate(picked);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isLoading)
                          const Center(child: CircularProgressIndicator()),
                        if (!isLoading) ...[
                          // Current Status Card
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.directions_walk,
                                        color: currentState != null
                                            ? MovementAnalysisService
                                                .getMovementStateColor(
                                                    currentState)
                                            : Colors.grey,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Current Status',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Activity State',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            currentState != null
                                                ? MovementAnalysisService
                                                    .getMovementStateDisplayName(
                                                        currentState)
                                                : 'Unknown',
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: currentState != null
                                                  ? MovementAnalysisService
                                                      .getMovementStateColor(
                                                          currentState)
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Intensity Level',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            provider
                                                .getMovementIntensityForAnimal(
                                                    animal.tagNumber),
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Daily Summary Card
                          if (dailySummary != null) ...[
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.analytics,
                                            color: Colors.blue[700]),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Daily Summary',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildSummaryItem(
                                            'Active Time',
                                            '${dailySummary.activeTime.inHours}h ${dailySummary.activeTime.inMinutes % 60}m',
                                            Icons.timer,
                                            Colors.green,
                                            theme,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildSummaryItem(
                                            'Resting Time',
                                            '${dailySummary.restingTime.inHours}h ${dailySummary.restingTime.inMinutes % 60}m',
                                            Icons.hotel,
                                            Colors.blue,
                                            theme,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildSummaryItem(
                                            'Step Count',
                                            '${dailySummary.stepCount}',
                                            Icons.directions_walk,
                                            Colors.orange,
                                            theme,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildSummaryItem(
                                            'Activity %',
                                            '${provider.getActivityPercentageForAnimal(animal.tagNumber).toStringAsFixed(1)}%',
                                            Icons.trending_up,
                                            Colors.purple,
                                            theme,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (dailySummary
                                        .abnormalMovementTimes.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.red.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.warning,
                                                color: Colors.red.shade700,
                                                size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${dailySummary.abnormalMovementTimes.length} abnormal movement(s) detected',
                                              style: TextStyle(
                                                color: Colors.red.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Movement Charts
                          if (movementData.isNotEmpty) ...[
                            MovementChart(
                              movementData: movementData,
                              title: 'Movement Intensity Throughout Day',
                              lineColor: Colors.blue,
                            ),
                            const SizedBox(height: 16),
                            MovementStateChart(
                              movementData: movementData,
                              title: 'Activity State Distribution',
                            ),
                          ] else ...[
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                height: 200,
                                padding: const EdgeInsets.all(20),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.directions_walk_outlined,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No movement data available for this date',
                                        style:
                                            theme.textTheme.bodyLarge?.copyWith(
                                          color: Colors.grey.shade600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Current Location Map
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.location_on,
                                          color: Colors.blue[700]),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Current Location',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildLocationMap(context, provider,
                                      animal.tagNumber, theme),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(
      String title, String value, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMap(BuildContext context, SensorProvider provider,
      String tagNumber, ThemeData theme) {
    try {
      final locationData = provider.getLocationDataForAnimal(tagNumber);
      final latLng = LatLng(locationData.latitude, locationData.longitude);

      // Check if we have valid coordinates
      if (locationData.latitude == 0.0 && locationData.longitude == 0.0) {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade100,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'No GPS Data Available',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.blue.shade50,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: latLng,
              initialZoom: 13.0,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
                errorTileCallback: (tile, error, stackTrace) {
                  // Handle tile loading error
                  debugPrint('Error loading map tile: $error');
                },
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40.0,
                    height: 40.0,
                    point: latLng,
                    child: Container(
                      child: Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      // Error handling for map display
      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.red.shade50,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 8),
              Text(
                'Error Loading Map',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
