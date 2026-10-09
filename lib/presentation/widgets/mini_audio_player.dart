import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/audio_service.dart';
import '../providers/reciter_provider.dart' show reciterProvider, recitersProvider;
import '../providers/translation_audio_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/reciter_image_sizes.dart';
import 'reciter_image.dart';

class MiniAudioPlayer extends ConsumerWidget {
  const MiniAudioPlayer({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = QuranAudioService();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<PlaybackStateInfo>(
      stream: audio.uiStateStream,
      builder: (context, snapshot) {
        final info = snapshot.data;
        // Show player if there's a current URL (even when paused)
        // Only hide if truly stopped (no URL)
        final hasActive = info?.currentUrl != null;
        
        if (!hasActive) {
          return const SizedBox.shrink();
        }

        final activeSurah = info!.currentSurahNumber;
        final isPlaying = info.isPlaying;
        final position = info.position;
        final duration = info.duration ?? Duration.zero;
        final progress = duration.inMilliseconds > 0 
            ? position.inMilliseconds / duration.inMilliseconds 
            : 0.0;

        // Get reciter/translation info - use currentEdition from PlaybackStateInfo
        final editionId = info.currentEdition;
        if (editionId == null) {
          return const SizedBox.shrink();
        }
        final isTranslation = !editionId.startsWith('ar.');
        
        // Watch async providers to detect loading states
        final recitersAsync = isTranslation ? null : ref.watch(recitersProvider);
        final reciter = isTranslation ? null : ref.watch(reciterProvider(editionId));
        final translation = isTranslation ? ref.watch(translationAudioEditionProvider(editionId)) : null;
        
        // Check if still loading reciter data
        final isLoadingReciter = !isTranslation && 
            (recitersAsync?.isLoading ?? false) && 
            reciter == null;
        
        // Get display name - show loading or proper name, never show fallback
        final displayName = isLoadingReciter
            ? '...'
            : (isTranslation
                ? (translation?.name ?? 'Тарҷума')
                : (reciter != null 
                    ? (reciter.nameTajik.isNotEmpty && reciter.nameTajik != reciter.id
                        ? reciter.nameTajik 
                        : (reciter.name.isNotEmpty && reciter.name != reciter.id
                            ? reciter.name
                            : null))
                    : null));

        // Get surah name
        String surahName = 'Қуръон';
        if (activeSurah != null) {
          // Simple surah name - could be enhanced with actual surah data
          surahName = 'Сураи $activeSurah';
        }

        return GestureDetector(
          onTap: () {
            final uri = Uri(
              path: '/audio-home/player',
              queryParameters: {
                'edition': editionId,
                if (activeSurah != null) 'surah': activeSurah.toString(),
              },
            );
            context.push(uri.toString());
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Reciter image
                Container(
                  width: ReciterImageSizes.small,
                  height: ReciterImageSizes.small,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                  child: ReciterImage(
                    reciterId: editionId,
                    width: ReciterImageSizes.small,
                    height: ReciterImageSizes.small,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    borderRadius: BorderRadius.circular(ReciterImageSizes.getCircularRadius(ReciterImageSizes.small)),
                    errorWidget: Center(
                      child: isTranslation && translation != null
                          ? Text(
                              translation.flag,
                              style: const TextStyle(fontSize: 20),
                            )
                          : reciter != null
                              ? Text(
                                  (reciter.nameTajik.isNotEmpty ? reciter.nameTajik : reciter.name).substring(0, 1),
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                )
                              : Icon(
                                  Icons.music_note,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title and progress
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      displayName != null
                          ? Text(
                              '$displayName - $surahName',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : Row(
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  surahName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                      const SizedBox(height: 4),
                      // Progress bar
                      Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(1),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Play/Pause button
                IconButton(
                  onPressed: () {
                    audio.togglePlayPause();
                  },
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: colorScheme.primary,
                  ),
                  iconSize: 24,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                const SizedBox(width: 4),
                // Close button - stop propagation to prevent navigation
                GestureDetector(
                  onTap: () {
                    audio.stop();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

