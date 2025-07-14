// import 'package:flutter/material.dart';
// import '../services/map_tile_settings.dart';
// import '../services/map_service.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';

// class MapSettingsScreen extends StatefulWidget {
//   const MapSettingsScreen({Key? key}) : super(key: key);

//   @override
//   State<MapSettingsScreen> createState() => _MapSettingsScreenState();
// }

// class _MapSettingsScreenState extends State<MapSettingsScreen> {
//   final MapTileSettings _settings = MapTileSettings();
//   bool _isTestingConnection = false;
//   String _testResult = '';
//   bool _showTestResult = false;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Map Settings', style: theme.textTheme.titleLarge),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Troubleshoot Map Connection Issues',
//               style: theme.textTheme.titleMedium?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             Card(
//               elevation: 0,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 side: BorderSide(
//                   color: theme.colorScheme.outline.withOpacity(0.2),
//                 ),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildSettingSwitch(
//                       title: 'Use Alternative Map Source',
//                       subtitle:
//                           'Try this if the default source is not loading tiles',
//                       value: _settings.useAlternativeSource,
//                       onChanged: (value) {
//                         setState(() {
//                           _settings.updateSettings(useAlternativeSource: value);
//                         });
//                       },
//                     ),
//                     const Divider(),
//                     _buildSettingSwitch(
//                       title: 'Enable Map Tile Caching',
//                       subtitle: 'Save map tiles to load maps faster',
//                       value: _settings.cacheEnabled,
//                       onChanged: (value) {
//                         setState(() {
//                           _settings.updateSettings(cacheEnabled: value);
//                         });
//                       },
//                     ),
//                     const Divider(),
//                     _buildSettingSlider(
//                       title: 'Connection Timeout',
//                       subtitle:
//                           'Increase this if you have a slow internet connection',
//                       value: _settings.connectionTimeout.toDouble(),
//                       min: 10.0,
//                       max: 90.0,
//                       divisions: 8,
//                       labelFormat: (value) => '${value.toInt()} seconds',
//                       onChanged: (value) {
//                         setState(() {
//                           _settings.updateSettings(
//                               connectionTimeout: value.toInt());
//                         });
//                       },
//                     ),
//                     const Divider(),
//                     _buildSettingSlider(
//                       title: 'Retry Count',
//                       subtitle:
//                           'How many times to retry loading a tile if it fails',
//                       value: _settings.retryCount.toDouble(),
//                       min: 1.0,
//                       max: 5.0,
//                       divisions: 4,
//                       labelFormat: (value) => '${value.toInt()} ${value.toInt() == 1 ? 'retry' : 'retries'}',
//                       onChanged: (value) {
//                         setState(() {
//                           _settings.updateSettings(retryCount: value.toInt());
//                         });
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Center(
//               child: ElevatedButton.icon(
//                 onPressed: _testMapConnection,
//                 icon: const Icon(Icons.network_check),
//                 label: Text(_isTestingConnection
//                     ? 'Testing Connection...'
//                     : 'Test Map Connection'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: theme.colorScheme.primary,
//                   foregroundColor: theme.colorScheme.onPrimary,
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                 ),
//               ),
//             ),
//             if (_showTestResult) ...[
//               const SizedBox(height: 16),
//               Center(
//                 child: Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: _testResult.contains('Success')
//                         ? Colors.green.withOpacity(0.1)
//                         : Colors.red.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(
//                       color: _testResult.contains('Success')
//                           ? Colors.green
//                           : Colors.red,
//                       width: 1,
//                     ),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         _testResult.contains('Success')
//                             ? Icons.check_circle
//                             : Icons.error,
//                         color:
//                             _testResult.contains('Success') ? Colors.green : Colors.red,
//                       ),
//                       const SizedBox(width: 8),
//                       Flexible(
//                         child: Text(
//                           _testResult,
//                           style: theme.textTheme.bodyMedium?.copyWith(
//                             color: _testResult.contains('Success')
//                                 ? Colors.green
//                                 : Colors.red,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//             const SizedBox(height: 24),
//             const Text(
//               'Map Preview',
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//             ),
//             const SizedBox(height: 8),
//             SizedBox(
//               height: 200,
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(12),
//                 child: FlutterMap(
//                   options: MapOptions(
//                     initialCenter: const LatLng(0, 0),
//                     initialZoom: 1,
//                     minZoom: 1,
//                     maxZoom: 18,
//                   ),
//                   children: [
//                     TileLayer(
//                       urlTemplate: _settings.getPrimaryTileUrl(),
//                       userAgentPackageName: 'com.cowsense.farmer',
//                       tileProvider: _settings.createTileProvider(),
//                       fallbackUrl: _settings.getFallbackTileUrl(),
//                       errorTileCallback: (tile, error, stackTrace) {
//                         debugPrint('Error in preview: $error\n$stackTrace');
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Center(
//               child: TextButton.icon(
//                 onPressed: () {
//                   setState(() {
//                     _settings.resetToDefaults();
//                   });
//                 },
//                 icon: const Icon(Icons.restore),
//                 label: const Text('Reset to Default Settings'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSettingSwitch({
//     required String title,
//     required String subtitle,
//     required bool value,
//     required ValueChanged<bool> onChanged,
//   }) {
//     return Row(
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
//               const SizedBox(height: 4),
//               Text(
//                 subtitle,
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Switch(
//           value: value,
//           onChanged: onChanged,
//         ),
//       ],
//     );
//   }

//   Widget _buildSettingSlider({
//     required String title,
//     required String subtitle,
//     required double value,
//     required double min,
//     required double max,
//     required int divisions,
//     required String Function(double) labelFormat,
//     required ValueChanged<double> onChanged,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
//         const SizedBox(height: 4),
//         Text(
//           subtitle,
//           style: TextStyle(
//             fontSize: 12,
//             color: Colors.grey[600],
//           ),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           children: [
//             Expanded(
//               child: Slider(
//                 value: value,
//                 min: min,
//                 max: max,
//                 divisions: divisions,
//                 label: labelFormat(value),
//                 onChanged: onChanged,
//               ),
//             ),
//             Container(
//               width: 60,
//               alignment: Alignment.center,
//               child: Text(labelFormat(value)),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Future<void> _testMapConnection() async {
//     setState(() {
//       _isTestingConnection = true;
//       _showTestResult = false;
//     });

//     try {
//       final client = CowSenseHttpClient();
      
//       // Try primary source
//       final primaryUrl = _settings.getPrimaryTileUrl()
//           .replaceAll('{z}', '1')
//           .replaceAll('{x}', '1')
//           .replaceAll('{y}', '1');
      
//       bool primarySuccess = false;
//       String primaryError = '';
      
//       try {
//         final primaryResponse = await client
//             .get(Uri.parse(primaryUrl))
//             .timeout(Duration(seconds: _settings.connectionTimeout));
//         primarySuccess = primaryResponse.statusCode < 400;
//       } catch (e) {
//         primaryError = e.toString();
//       }
      
//       // Try fallback source
//       final fallbackUrl = _settings.getFallbackTileUrl()
//           .replaceAll('{z}', '1')
//           .replaceAll('{x}', '1')
//           .replaceAll('{y}', '1');
          
//       bool fallbackSuccess = false;
      
//       try {
//         final fallbackResponse = await client
//             .get(Uri.parse(fallbackUrl))
//             .timeout(Duration(seconds: _settings.connectionTimeout));
//         fallbackSuccess = fallbackResponse.statusCode < 400;
//       } catch (e) {
//         // Ignore fallback error
//       }
      
//       // Set test result
//       if (primarySuccess) {
//         _testResult = 'Success! Map tiles are loading correctly.';
//       } else if (fallbackSuccess) {
//         _testResult = 'Primary source failed but fallback is working. Using fallback source is recommended.';
//       } else {
//         _testResult = 'Connection failed: $primaryError. Try increasing the timeout or check your internet connection.';
//       }
      
//       client.close();
      
//     } catch (e) {
//       _testResult = 'Test failed: ${e.toString()}';
//     } finally {
//       setState(() {
//         _isTestingConnection = false;
//         _showTestResult = true;
//       });
//     }
//   }
// }
