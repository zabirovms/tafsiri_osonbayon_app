import 'package:flutter/material.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

import '../../data/services/audio_service.dart';

class AudioPlayerControls extends StatelessWidget {
  final int surahNumber;
  final int? verseNumber; // if null -> surah mode; else -> verse mode
  final String edition;
  final bool compact; // compact header vs full controller
  final bool showPrevNext; // show previous/next when in verse mode

  const AudioPlayerControls({
    super.key,
    required this.surahNumber,
    required this.edition,
    this.verseNumber,
    this.compact = false,
    this.showPrevNext = true,
  });

  @override
  Widget build(BuildContext context) {
    final audio = QuranAudioService();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return StreamBuilder<PlaybackStateInfo>(
      stream: audio.uiStateStream,
      builder: (context, snapshot) {
        final info = snapshot.data;
        final position = info?.position ?? Duration.zero;
        final buffered = info?.bufferedPosition ?? Duration.zero;
        final total = info?.duration ?? Duration.zero;
        final isPlaying = info?.isPlaying ?? false;
        final isPlayingThis = verseNumber == null
            ? (info?.currentSurahNumber == surahNumber && isPlaying && info?.currentVerseNumber == null)
            : (info?.currentSurahNumber == surahNumber && info?.currentVerseNumber == verseNumber && isPlaying);

        if (compact) {
          return _buildCompact(context, colors, audio, position, total, isPlayingThis);
        }
        return _buildFull(context, colors, audio, position, buffered, total, isPlayingThis);
      },
    );
  }

  Widget _buildCompact(
    BuildContext context,
    ColorScheme colors,
    QuranAudioService audio,
    Duration position,
    Duration total,
    bool isPlayingThis,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show previous button for verse mode OR surah mode
            if (showPrevNext)
              IconButton(
                onPressed: () async {
                  if (verseNumber != null) {
                    await audio.playPreviousVerse(edition: edition);
                  } else {
                    await audio.playPreviousSurah(edition: edition);
                  }
                },
                icon: Icon(Icons.skip_previous, color: colors.onSurface.withValues(alpha: 0.9), size: 20),
                iconSize: 20,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            IconButton(
              onPressed: () async {
                await audio.togglePlayPause(
                  surahNumber: surahNumber,
                  verseNumber: verseNumber,
                  edition: edition,
                );
              },
              icon: Icon(
                isPlayingThis ? Icons.pause : Icons.play_arrow,
                color: colors.onSurface,
                size: 22,
              ),
              iconSize: 22,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
            // Show next button for verse mode OR surah mode
            if (showPrevNext)
              IconButton(
                onPressed: () async {
                  if (verseNumber != null) {
                    await audio.playNextVerse(edition: edition);
                  } else {
                    await audio.playNextSurah(edition: edition);
                  }
                },
                icon: Icon(Icons.skip_next, color: colors.onSurface.withValues(alpha: 0.9), size: 20),
                iconSize: 20,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFull(
    BuildContext context,
    ColorScheme colors,
    QuranAudioService audio,
    Duration position,
    Duration buffered,
    Duration total,
    bool isPlayingThis,
  ) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProgressBar(
          progress: position,
          buffered: buffered,
          total: total,
          onSeek: (d) async => audio.seekTo(d),
          progressBarColor: colors.primary,
          baseBarColor: colors.outline.withValues(alpha: 0.3),
          thumbColor: colors.primary,
          barHeight: 4.0,
          thumbRadius: 8.0,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(position), style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurface.withValues(alpha: 0.7))),
              Text(_fmt(total), style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurface.withValues(alpha: 0.7))),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Show previous button for verse mode OR surah mode
            if (showPrevNext)
              IconButton(
                onPressed: () async {
                  if (verseNumber != null) {
                    await audio.playPreviousVerse(edition: edition);
                  } else {
                    await audio.playPreviousSurah(edition: edition);
                  }
                },
                icon: const Icon(Icons.skip_previous),
                iconSize: 32,
                style: IconButton.styleFrom(backgroundColor: colors.surfaceContainerHighest),
              ),
            if (showPrevNext)
              const SizedBox(width: 16),
            Container(
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () async {
                  await audio.togglePlayPause(
                    surahNumber: surahNumber,
                    verseNumber: verseNumber,
                    edition: edition,
                  );
                },
                icon: Icon(isPlayingThis ? Icons.pause : Icons.play_arrow, color: colors.onPrimary, size: 32),
                iconSize: 32,
              ),
            ),
            if (showPrevNext)
              const SizedBox(width: 16),
            // Show next button for verse mode OR surah mode
            if (showPrevNext)
              IconButton(
                onPressed: () async {
                  if (verseNumber != null) {
                    await audio.playNextVerse(edition: edition);
                  } else {
                    await audio.playNextSurah(edition: edition);
                  }
                },
                icon: const Icon(Icons.skip_next),
                iconSize: 32,
                style: IconButton.styleFrom(backgroundColor: colors.surfaceContainerHighest),
              ),
          ],
        ),
      ],
    );
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }
}


