import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/audio_manifest_service_v2.dart';
import '../../data/models/audio_manifest_model.dart';

/// Provider for audio manifest service (v2 with background parsing)
final audioManifestServiceProvider = Provider<AudioManifestServiceV2>((ref) {
  return AudioManifestServiceV2();
});

/// Provider for audio manifest data with loading state
/// Preloads manifest on app start for better UX
final audioManifestProvider = FutureProvider<AudioManifest>((ref) async {
  final service = ref.watch(audioManifestServiceProvider);
  // Get manifest (will use cache if available, fetch if needed)
  final manifest = await service.getManifest();
  debugPrint('[ManifestProvider] Manifest loaded: ${manifest.arabicReciters.length} reciters, ${manifest.translations.length} translations');
  return manifest;
});

/// Provider for manifest loading state
final manifestLoadingStateProvider = StateProvider<String?>((ref) => null);

/// Provider for Arabic reciters from manifest
final manifestRecitersProvider = FutureProvider<List<AudioEdition>>((ref) async {
  final manifest = await ref.watch(audioManifestProvider.future);
  return manifest.arabicReciters;
});

/// Provider for translations from manifest
final manifestTranslationsProvider = FutureProvider<List<AudioEdition>>((ref) async {
  final manifest = await ref.watch(audioManifestProvider.future);
  return manifest.translations;
});

/// Provider to find edition by ID (handles app IDs with underscores)
final editionByIdProvider = Provider.family<AudioEdition?, String>((ref, editionId) {
  final manifestAsync = ref.watch(audioManifestProvider);
  return manifestAsync.when(
    data: (manifest) => manifest.findEdition(editionId),
    loading: () => null,
    error: (_, __) => null,
  );
});

