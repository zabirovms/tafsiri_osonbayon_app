import '../../data/services/image_api_service.dart';

class BackgroundService {
  BackgroundService({ImageApiService? imageApiService})
      : _imageApiService = imageApiService ?? ImageApiService();

  final ImageApiService _imageApiService;
  List<String>? _cachedBackgrounds;

  Future<List<String>> fetchBackgroundUrls() async {
    if (_cachedBackgrounds != null && _cachedBackgrounds!.isNotEmpty) {
      return _cachedBackgrounds!;
    }

    try {
      final result =
          await _imageApiService.fetchImageData(prefix: 'wallpapers/');
      var urls = result.images.map((image) => image.url).toList();

      if (urls.isEmpty) {
        final fallback =
            await _imageApiService.fetchImageData(prefix: 'pictures/');
        urls = fallback.images.map((image) => image.url).toList();
      }

      _cachedBackgrounds = urls;
      return urls;
    } catch (_) {
      return _cachedBackgrounds ?? const [];
    }
  }
}
