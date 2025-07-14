// import 'package:flutter/material.dart';
// import '../services/map_service.dart';
// import 'package:http/http.dart' as http;

// class MapTileSettings extends ChangeNotifier {
//   static final MapTileSettings _instance = MapTileSettings._internal();
  
//   factory MapTileSettings() => _instance;
  
//   MapTileSettings._internal();
  
//   // Settings
//   bool _useAlternativeSource = false;
//   bool _useProxy = false;
//   bool _cacheEnabled = true;
//   int _connectionTimeout = 30;
//   int _retryCount = 3;
  
//   // Getters
//   bool get useAlternativeSource => _useAlternativeSource;
//   bool get useProxy => _useProxy;
//   bool get cacheEnabled => _cacheEnabled;
//   int get connectionTimeout => _connectionTimeout;
//   int get retryCount => _retryCount;
  
//   // Create a tile provider with current settings
//   CowSenseMapTileProvider createTileProvider() {
//     final client = CowSenseHttpClient();
    
//     return CowSenseMapTileProvider(
//       httpClient: client,
//       timeout: Duration(seconds: _connectionTimeout),
//     );
//   }
  
//   // Update settings
//   void updateSettings({
//     bool? useAlternativeSource,
//     bool? useProxy,
//     bool? cacheEnabled,
//     int? connectionTimeout,
//     int? retryCount,
//   }) {
//     if (useAlternativeSource != null) _useAlternativeSource = useAlternativeSource;
//     if (useProxy != null) _useProxy = useProxy;
//     if (cacheEnabled != null) _cacheEnabled = cacheEnabled;
//     if (connectionTimeout != null) _connectionTimeout = connectionTimeout;
//     if (retryCount != null) _retryCount = retryCount;
    
//     notifyListeners();
//   }
  
//   // Reset to defaults
//   void resetToDefaults() {
//     _useAlternativeSource = false;
//     _useProxy = false;
//     _cacheEnabled = true;
//     _connectionTimeout = 30;
//     _retryCount = 3;
    
//     notifyListeners();
//   }
  
//   // Get primary tile source URL
//   String getPrimaryTileUrl() {
//     if (_useAlternativeSource) {
//       return 'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png';
//     }
//     return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
//   }
  
//   // Get fallback tile source URL
//   String getFallbackTileUrl() {
//     if (_useAlternativeSource) {
//       return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
//     }
//     return 'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png';
//   }
// }
