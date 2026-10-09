/// Maps https://quran.tj / https://www.quran.tj URLs to in-app [GoRouter] locations.
///
/// Paths follow the public site sitemap (`web-static/public/sitemap.xml`) and
/// [lib/app/app.dart] routes. Verse URLs on the site are `/surah/{s}/{v}`; the app
/// uses `/surah/{s}/verse/{v}` — both are accepted here. Web Bukhari book URLs
/// (`/bukhari/{id}`) open `/bukhari`. URLs that target screens that require
/// non-serialized `extra` are sent to a safe parent route instead.
class AppLinkMapper {
  AppLinkMapper._();

  static const _hosts = {'quran.tj', 'www.quran.tj'};

  /// Returns a location string for [GoRouter.go], or null if the URI is not handled.
  static String? toGoLocation(Uri uri) {
    if (uri.scheme != 'https') return null;
    final host = uri.host.toLowerCase();
    if (!_hosts.contains(host)) return null;

    var path = uri.path;
    if (path.isEmpty) return '/';
    if (path != '/' && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    if (path == '/privacy-policy.html') {
      path = '/privacy-policy';
    }

    // Site + sitemap use `/surah/{n}/{ayah}` (e.g. …/surah/21/107). App routes use
    // `/surah/{n}/verse/{ayah}`. Accept both; normalize web shape to the app path.
    final surahAyah = RegExp(r'^/surah/(\d+)/(\d+)$').firstMatch(path);
    if (surahAyah != null) {
      path = '/surah/${surahAyah.group(1)}/verse/${surahAyah.group(2)}';
    }

    final query = uri.hasQuery ? '?${uri.query}' : '';

    // Bukhari routes that require `extra` — open catalog instead.
    if (path == '/bukhari/book' || path.startsWith('/bukhari/book/')) {
      return '/bukhari';
    }
    if (path == '/bukhari/chapter' || path.startsWith('/bukhari/chapter/')) {
      return '/bukhari';
    }
    if (path == '/bukhari/intro' || path.startsWith('/bukhari/intro/')) {
      return '/bukhari';
    }

    if (path == '/duas/prophets/detail' ||
        path.startsWith('/duas/prophets/detail/')) {
      return '/duas/prophets';
    }
    if (path == '/prophets/detail' || path.startsWith('/prophets/detail/')) {
      return '/prophets';
    }

    // Sitemap uses `/bukhari/{bookKey}` (e.g. `/bukhari/8-1`). The app has no route
    // for that shape (books use `extra`), so open the Bukhari home.
    if (path.startsWith('/bukhari/')) {
      const bukhariAppSegments = <String>{
        'book',
        'chapter',
        'bookmarks',
        'search-hadiths',
        'intro',
      };
      final tail = path.substring('/bukhari/'.length);
      final first = tail.split('/').first;
      if (first.isNotEmpty && !bukhariAppSegments.contains(first)) {
        return '/bukhari';
      }
    }

    return '$path$query';
  }
}
