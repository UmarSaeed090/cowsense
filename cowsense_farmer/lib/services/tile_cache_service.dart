import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'dart:async';

/// A robust HTTP client for OpenStreetMap tiles
class OSMTileClient extends http.BaseClient {
  final http.Client _inner;

  OSMTileClient({int maxRetries = 3})
      : _inner = RetryClient(
          http.Client(),
          retries: maxRetries,
          when: (response) =>
              response.statusCode >= 500 || response.statusCode == 429,
          delay: (retryCount) => Duration(milliseconds: 300 * (retryCount + 1)),
        );

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Add appropriate headers for OpenStreetMap
    request.headers['User-Agent'] = 'CowSense/1.0.0 (https://cowsense.app)';
    request.headers['Accept'] = 'image/*';
    request.headers['Referer'] = 'https://cowsense.app/';

    try {
      return await _inner.send(request).timeout(const Duration(seconds: 15),
          onTimeout: () {
        debugPrint('Request timed out: ${request.url}');
        throw TimeoutException('Tile request timed out');
      });
    } catch (e) {
      debugPrint('Request failed: ${request.url} - $e');
      rethrow;
    }
  }

  @override
  void close() => _inner.close();
}

/// Factory to create tile providers for maps
class TileCacheService {
  static final TileCacheService _instance = TileCacheService._internal();
  factory TileCacheService() => _instance;
  TileCacheService._internal();

  bool _initialized = false;

  /// Initialize the cache service
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    debugPrint('Tile service initialized');
  }

  /// Create a network tile provider with optimized settings
  TileProvider createTileProvider() {
    return NetworkTileProvider(
      httpClient: OSMTileClient(maxRetries: 3),
    );
  }
}
