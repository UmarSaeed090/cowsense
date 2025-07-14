import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/sensor_data.dart';
import '../services/map_service.dart';

class LocationMap extends StatelessWidget {
  final List<GPSData> movementData;
  final GPSData? currentLocation;

  const LocationMap({
    Key? key,
    required this.movementData,
    this.currentLocation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (movementData.isEmpty && currentLocation == null) {
      return const Center(child: Text('No location data available'));
    }

    final initialLocation = currentLocation ?? movementData.last;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cow Location',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(
                      initialLocation.latitude, initialLocation.longitude),
                  initialZoom: 15,
                  minZoom: 5,
                  maxZoom: 18,
                  onMapReady: () {
                    // Map is ready
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.cowsense.farmer',
                    fallbackUrl:
                        'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                    tileProvider: CowSenseHttpClient.createCachedTileProvider(),
                    errorTileCallback: (tile, error, stackTrace) {
                      debugPrint('Error loading tile: $error\n$stackTrace');
                    },
                    additionalOptions: const {
                      'User-Agent': 'CowSense/1.0.0',
                    },
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: movementData
                            .map((gps) => LatLng(gps.latitude, gps.longitude))
                            .toList(),
                        color: Colors.blue,
                        strokeWidth: 3,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      if (currentLocation != null)
                        Marker(
                          point: LatLng(
                            currentLocation!.latitude,
                            currentLocation!.longitude,
                          ),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Color(0xFFCB2213),
                            size: 40,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // LatLngBounds? _calculateBounds() {
  //   if (movementData.isEmpty) return null;

  //   double minLat = double.infinity;
  //   double maxLat = -double.infinity;
  //   double minLng = double.infinity;
  //   double maxLng = -double.infinity;

  //   for (final gps in movementData) {
  //     minLat = minLat < gps.latitude ? minLat : gps.latitude;
  //     maxLat = maxLat > gps.latitude ? maxLat : gps.latitude;
  //     minLng = minLng < gps.longitude ? minLng : gps.longitude;
  //     maxLng = maxLng > gps.longitude ? maxLng : gps.longitude;
  //   }

  //   return LatLngBounds(
  //     LatLng(minLat, minLng),
  //     LatLng(maxLat, maxLng),
  //   );
  // }
}
