import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../providers/sensor_provider.dart';
import '../models/animal.dart';
import '../services/map_service.dart';

class LocationScreen extends StatelessWidget {
  final Animal animal;

  const LocationScreen({
    super.key,
    required this.animal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<SensorProvider>(
      builder: (context, provider, child) {
        final movementData =
            provider.getMovementDataForAnimal(animal.tagNumber);
        final currentData = provider.getAnimalData(animal.tagNumber);
        final currentLocation = currentData?.gps;
        final selectedDate = provider.selectedDate;
        final isLoading = provider.isLoading;

        LatLng? initialCenter;
        if (currentLocation != null) {
          initialCenter =
              LatLng(currentLocation.latitude, currentLocation.longitude);
        } else if (movementData.isNotEmpty) {
          initialCenter =
              LatLng(movementData.last.latitude, movementData.last.longitude);
        } else {
          initialCenter = const LatLng(0, 0);
        }

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
                    '${animal.name}\'s Location',
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
                                await provider.setDate(picked);
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
                          const Center(child: CircularProgressIndicator())
                        else if (movementData.isEmpty &&
                            currentLocation == null)
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_off,
                                  size: 64,
                                  color: theme.colorScheme.outline,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No location data available',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color:
                                    theme.colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                height: 350,
                                child: Stack(
                                  children: [
                                    FlutterMap(
                                      options: MapOptions(
                                        initialCenter: initialCenter,
                                        initialZoom: 15,
                                        minZoom: 5,
                                        maxZoom: 18,
                                      ),
                                      children: [
                                        TileLayer(
                                          urlTemplate:
                                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                          userAgentPackageName:
                                              'com.cowsense.farmer',
                                          tileProvider: CowSenseHttpClient
                                              .createCachedTileProvider(),
                                          fallbackUrl:
                                              'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                                          errorTileCallback:
                                              (tile, error, stackTrace) {
                                            debugPrint(
                                                'Error loading tile: $error\n$stackTrace');
                                          },
                                          additionalOptions: const {
                                            'User-Agent':
                                                'CowSense/1.0.0 (https://cowsense.app)',
                                          },
                                        ),
                                        if (movementData.isNotEmpty)
                                          PolylineLayer(
                                            polylines: [
                                              Polyline(
                                                points: movementData
                                                    .map((gps) => LatLng(
                                                        gps.latitude,
                                                        gps.longitude))
                                                    .toList(),
                                                color:
                                                    theme.colorScheme.primary,
                                                strokeWidth: 4,
                                              ),
                                            ],
                                          ),
                                        if (currentLocation != null)
                                          MarkerLayer(
                                            markers: [
                                              Marker(
                                                point: LatLng(
                                                    currentLocation.latitude,
                                                    currentLocation.longitude),
                                                width: 40,
                                                height: 40,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: theme
                                                        .colorScheme.primary
                                                        .withOpacity(0.2),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Center(
                                                    child: Icon(
                                                      Icons.location_on,
                                                      color: theme
                                                          .colorScheme.primary,
                                                      size: 32,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    Positioned(
                                      right: 16,
                                      bottom: 16,
                                      child: FloatingActionButton(
                                        onPressed: () {
                                          // TODO: Implement zoom to current location
                                        },
                                        backgroundColor:
                                            theme.colorScheme.primaryContainer,
                                        foregroundColor: theme
                                            .colorScheme.onPrimaryContainer,
                                        child: const Icon(Icons.my_location),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (!isLoading &&
                            (movementData.isNotEmpty ||
                                currentLocation != null)) ...[
                          const SizedBox(height: 24),
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color:
                                    theme.colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Location Details',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (currentLocation != null) ...[
                                    _buildLocationDetail(
                                      context,
                                      icon: Icons.location_on,
                                      title: 'Current Location',
                                      value:
                                          '${currentLocation.latitude.toStringAsFixed(6)}, ${currentLocation.longitude.toStringAsFixed(6)}',
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  if (movementData.isNotEmpty) ...[
                                    _buildLocationDetail(
                                      context,
                                      icon: Icons.route,
                                      title: 'Movement Path',
                                      value:
                                          '${movementData.length} recorded points',
                                    ),
                                    const SizedBox(height: 12),
                                    _buildLocationDetail(
                                      context,
                                      icon: Icons.timer,
                                      title: 'Last Update',
                                      value: provider
                                          .getHistoricalDataForAnimal(
                                              animal.tagNumber)
                                          .last
                                          .timestamp
                                          .toString(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
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

  Widget _buildLocationDetail(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
