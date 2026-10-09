import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_manifest_provider.dart';

/// Widget to show loading indicator while manifest is being fetched/parsed
class ManifestLoadingIndicator extends ConsumerWidget {
  final Widget child;
  final Widget? loadingWidget;

  const ManifestLoadingIndicator({
    super.key,
    required this.child,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manifestAsync = ref.watch(audioManifestProvider);
    final loadingState = ref.watch(manifestLoadingStateProvider);

    return manifestAsync.when(
      data: (_) => child,
      loading: () => loadingWidget ?? _defaultLoadingWidget(loadingState),
      error: (error, stack) {
        // Show error but allow app to continue with cached data
        debugPrint('[ManifestLoading] Error: $error');
        return child; // Fallback to child even on error
      },
    );
  }

  Widget _defaultLoadingWidget(String? state) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              state ?? 'Loading audio data...',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to trigger manifest refresh with loading state
/// Usage: Call this function when you need to force refresh the manifest
Future<void> refreshManifest(WidgetRef ref) async {
  final service = ref.read(audioManifestServiceProvider);
  final loadingState = ref.read(manifestLoadingStateProvider.notifier);

  loadingState.state = 'Fetching manifests...';
  try {
    await service.getManifest(
      forceRefresh: true,
      onProgress: (progress) {
        loadingState.state = progress;
      },
    );
    // Invalidate provider to trigger rebuild
    ref.invalidate(audioManifestProvider);
  } finally {
    loadingState.state = null;
  }
}

