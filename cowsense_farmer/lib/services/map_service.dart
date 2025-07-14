import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter_map/flutter_map.dart';
import 'tile_cache_service.dart';

// Custom HTTP client for OpenStreetMap tiles
class CowSenseHttpClient extends http.BaseClient {
  final http.Client _inner;
  final int maxRetries;

  CowSenseHttpClient({this.maxRetries = 5})
      : _inner = RetryClient(
          http.Client(),
          retries: 5,
          // Retry on server errors and rate limits, plus connection errors
          when: (response) =>
              response.statusCode >= 500 || response.statusCode == 429,
          // Add a delay between retries with exponential backoff
          delay: (retryCount) =>
              Duration(milliseconds: 200 * (1 << retryCount)),
          // Custom onRetry handler for logging
          onRetry: (request, response, retryCount) {
            debugPrint('Retrying ${request.url} (attempt $retryCount)');
          },
        );

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Set appropriate headers for OpenStreetMap
    request.headers['User-Agent'] = 'CowSense/1.0.0 (https://cowsense.app)';
    request.headers['Accept'] = 'image/*';
    // Setting referer helps avoid being treated as a bot
    request.headers['Referer'] = 'https://cowsense.app/';

    try {
      // Set a longer timeout with a 20-second maximum
      return await _inner.send(request).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          debugPrint('Request timed out: ${request.url}');
          throw TimeoutException('OpenStreetMap tile request timed out');
        },
      );
    } on SocketException catch (e, stackTrace) {
      // Handle socket exceptions separately for better debugging
      debugPrint('Socket error fetching tile: $e\n$stackTrace');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('HTTP request failed: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Factory method to create a tile provider
  static TileProvider createCachedTileProvider() {
    return TileCacheService().createTileProvider();
  }

  @override
  void close() {
    _inner.close();
  }
}
