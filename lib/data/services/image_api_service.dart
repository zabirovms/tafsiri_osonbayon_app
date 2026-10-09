import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/image_data.dart';

class ImageApiException implements Exception {
  final String message;
  ImageApiException(this.message);

  @override
  String toString() => message;
}

class ImageApiResult {
  final List<ImageData> images;
  final String? nextPageToken;

  ImageApiResult({
    required this.images,
    this.nextPageToken,
  });
}

class ImageApiService {
  // Cloudflare-backed CDN endpoints (same as web-static project)
  static const String _picturesListUrl = 'https://cdn.quran.tj/pictures/list';
  static const String _wallpapersListUrl =
      'https://cdn.quran.tj/wallpapers/list';
  static const String _picturesBaseUrl = 'https://cdn.quran.tj/pictures/';
  static const String _wallpapersBaseUrl = 'https://cdn.quran.tj/wallpapers/';

  // Cache for all filenames to enable client-side pagination
  static List<String>? _cachedPicturesFilenames;
  static List<String>? _cachedWallpapersFilenames;

  /// Fetches image data (URL and name) from the Cloudflare-backed CDN.
  ///
  /// This mirrors the data source used in the web-static project:
  /// - Pictures list:   https://cdn.quran.tj/pictures/list
  /// - Wallpapers list: https://cdn.quran.tj/wallpapers/list
  ///
  /// Since the CDN returns all filenames at once, we implement client-side
  /// pagination using pageToken as an integer offset.
  Future<ImageApiResult> fetchImageData({
    String prefix = 'pictures/',
    String? pageToken,
    int pageSize = 40,
  }) async {
    try {
      // Determine which CDN endpoint to use based on prefix
      final bool isWallpapers =
          prefix.toLowerCase().startsWith('wallpapers');

      final String listUrl =
          isWallpapers ? _wallpapersListUrl : _picturesListUrl;
      final String baseUrl =
          isWallpapers ? _wallpapersBaseUrl : _picturesBaseUrl;

      // Get or fetch all filenames (cache them to avoid repeated requests)
      List<String> allFilenames;
      if (isWallpapers) {
        if (_cachedWallpapersFilenames == null) {
          allFilenames = await _fetchAllFilenames(listUrl);
          _cachedWallpapersFilenames = allFilenames;
        } else {
          allFilenames = _cachedWallpapersFilenames!;
        }
      } else {
        if (_cachedPicturesFilenames == null) {
          allFilenames = await _fetchAllFilenames(listUrl);
          _cachedPicturesFilenames = allFilenames;
        } else {
          allFilenames = _cachedPicturesFilenames!;
        }
      }

      if (allFilenames.isEmpty) {
        return ImageApiResult(images: const [], nextPageToken: null);
      }

      // Parse pageToken as offset (client-side pagination)
      final offset = pageToken != null ? int.tryParse(pageToken) ?? 0 : 0;
      final endIndex = (offset + pageSize).clamp(0, allFilenames.length);
      final paginatedFilenames = allFilenames.sublist(
        offset.clamp(0, allFilenames.length),
        endIndex,
      );

      // Check if there are more images
      final hasMore = endIndex < allFilenames.length;
      final nextPageToken = hasMore ? endIndex.toString() : null;

      final imageDataList = paginatedFilenames.map((filename) {
        // Extract clean name from filename (remove extension and clean up)
        final parts = filename.split('.');
        if (parts.length > 1) {
          parts.removeLast(); // drop extension
        }
        final nameWithoutExt = parts.join('.');
        final cleanName =
            nameWithoutExt.replaceAll('_', ' ').replaceAll('-', ' ');

        final url = '$baseUrl${Uri.encodeComponent(filename)}';

        return ImageData(
          url: url,
          name: cleanName,
        );
      }).toList();

      return ImageApiResult(
        images: imageDataList,
        nextPageToken: nextPageToken,
      );
    } on SocketException {
      throw ImageApiException(
          'Network is unreachable. Please check your internet connection.');
    } on HttpException catch (e) {
      throw ImageApiException('HTTP error: ${e.message}');
    } on FormatException catch (_) {
      throw ImageApiException('Invalid response format from server.');
    } catch (e) {
      throw ImageApiException('Unexpected error: $e');
    }
  }

  /// Fetches all filenames from the CDN list endpoint
  Future<List<String>> _fetchAllFilenames(String listUrl) async {
    final response = await http.get(
      Uri.parse(listUrl),
      headers: {HttpHeaders.acceptHeader: 'application/json'},
    );

    if (response.statusCode != 200) {
      throw ImageApiException(
          'Failed to load images: HTTP ${response.statusCode}');
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) {
      throw ImageApiException('Invalid response format from server.');
    }

    return decoded.cast<String>();
  }

  /// Fetches image URLs from the CDN (for backward compatibility)
  Future<List<String>> fetchImageUrls({
    String prefix = 'pictures/',
    String? pageToken,
    int pageSize = 40,
  }) async {
    final result = await fetchImageData(
      prefix: prefix,
      pageToken: pageToken,
      pageSize: pageSize,
    );
    return result.images.map((data) => data.url).toList();
  }

  /// Extracts image title from URL
  String getImageTitle(String imageUrl) {
    final uri = Uri.parse(imageUrl);
    final pathSegments = uri.pathSegments;
    if (pathSegments.isNotEmpty) {
      final fileName = pathSegments.last;
      final nameWithoutExt = fileName.split('.').first;
      return nameWithoutExt.replaceAll('_', ' ').replaceAll('-', ' ');
    }
    return 'Image';
  }
}
