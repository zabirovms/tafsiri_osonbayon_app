import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/share_helper.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/models/verse_model.dart';
import '../../../data/services/audio_service.dart';
import '../../../data/services/settings_service.dart';
import '../../../core/platform/service_registry.dart';
import '../../providers/user_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../translation_selection_dialog.dart';

class VerseActionBottomSheet extends ConsumerStatefulWidget {
  final VerseModel verse;
  final String surahName;
  final VoidCallback? onPlayAudio;
  final String? selectedTafsirSourceKey;

  const VerseActionBottomSheet({
    super.key,
    required this.verse,
    required this.surahName,
    this.onPlayAudio,
    this.selectedTafsirSourceKey,
  });

  static Future<void> show(
    BuildContext context, {
    required VerseModel verse,
    required String surahName,
    VoidCallback? onPlayAudio,
    String? selectedTafsirSourceKey,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VerseActionBottomSheet(
        verse: verse,
        surahName: surahName,
        onPlayAudio: onPlayAudio,
        selectedTafsirSourceKey: selectedTafsirSourceKey,
      ),
    );
  }

  @override
  ConsumerState<VerseActionBottomSheet> createState() => _VerseActionBottomSheetState();
}

class _VerseActionBottomSheetState extends ConsumerState<VerseActionBottomSheet> {
  late String _tafsirSourceKey;

  @override
  void initState() {
    super.initState();
    _tafsirSourceKey = widget.selectedTafsirSourceKey ?? AppConstants.tafsirSourceTajik;
  }

  Future<String> _buildCopyText() async {
    final buffer = StringBuffer();
    final cleanArabicText = widget.verse.arabicText.trim();
    buffer.writeln('{$cleanArabicText}');
    buffer.writeln();

    final settingsService = SettingsService();
    await settingsService.init();
    final currentLang = settingsService.getTranslationLanguage();
    final translationText = widget.verse.getTranslation(currentLang);
    final translatorName = AppConstants.getTranslationName(currentLang);

    if (translationText.isNotEmpty) {
      buffer.writeln(translationText.trim());
      buffer.writeln('— $translatorName');
      buffer.writeln();
    }

    buffer.writeln('(Қуръон ${widget.verse.surahId}:${widget.verse.verseNumber})');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userId = ref.watch(currentUserIdProvider);
    final bookmarkState = ref.watch(bookmarkNotifierProvider(userId));
    final isBookmarked = bookmarkState.bookmarkStatus[widget.verse.uniqueKey] ?? false;
    final audio = QuranAudioService();
    final isPlaying = audio.isPlayingVerse(widget.verse.surahId, widget.verse.verseNumber);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 24, left: 16, right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle indicator
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Verse title header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.verse.surahId}:${widget.verse.verseNumber}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Сураи ${widget.surahName}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const Divider(height: 20),

          // Primary Actions (Play, Bookmark, Copy, Share)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionTile(
                context,
                icon: isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                label: isPlaying ? 'Ист кардан' : 'Пахш кардан',
                color: colorScheme.primary,
                onTap: () {
                  Navigator.pop(context);
                  if (widget.onPlayAudio != null) {
                    widget.onPlayAudio!();
                  } else {
                    audio.togglePlayPause(
                      surahNumber: widget.verse.surahId,
                      verseNumber: widget.verse.verseNumber,
                    );
                  }
                },
              ),
              _buildActionTile(
                context,
                icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                label: isBookmarked ? 'Дар захира' : 'Захира',
                color: isBookmarked ? colorScheme.primary : colorScheme.onSurface,
                onTap: () async {
                  final notifier = ref.read(bookmarkNotifierProvider(userId).notifier);
                  await notifier.toggleBookmark(widget.verse, widget.surahName);
                  if (context.mounted) {
                    SnackBarHelper.showSuccess(
                      context: context,
                      message: isBookmarked ? 'Захира пок карда шуд' : 'Оят ба захирагоҳ илова карда шуд',
                      duration: const Duration(seconds: 2),
                    );
                  }
                  setState(() {});
                },
              ),
              _buildActionTile(
                context,
                icon: Icons.copy,
                label: 'Нусха',
                color: colorScheme.onSurface,
                onTap: () async {
                  final text = await _buildCopyText();
                  await Clipboard.setData(ClipboardData(text: text));
                  if (context.mounted) {
                    Navigator.pop(context);
                    SnackBarHelper.showSuccess(
                      context: context,
                      message: 'Оят нусхабардорӣ карда шуд',
                      duration: const Duration(seconds: 2),
                    );
                  }
                },
              ),
              _buildActionTile(
                context,
                icon: Icons.share,
                label: 'Мубодила',
                color: colorScheme.onSurface,
                onTap: () async {
                  final text = await _buildCopyText();
                  final nav = Navigator.of(context);
                  final uniqueKey = widget.verse.uniqueKey;
                  nav.pop();
                  await ShareHelper.share(text);
                  ServiceRegistry().analyticsService.logShare('verse', id: uniqueKey);
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Translation Preview Section
          ExpansionTile(
            title: Text(
              'Тарҷума',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.translate, size: 20),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            children: [
              Text(
                widget.verse.ayatiText,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.settings_suggest, size: 16),
                  label: const Text('Интихоби дигар тарҷума'),
                  onPressed: () async {
                    final s = SettingsService();
                    await s.init();
                    final currentLang = s.getTranslationLanguage();
                    if (!context.mounted) return;
                    final selectedLang = await showDialog<String>(
                      context: context,
                      builder: (context) => TranslationSelectionDialog(
                        currentTranslation: currentLang,
                        surahNumber: widget.verse.surahId,
                      ),
                    );
                    if (selectedLang != null && context.mounted) {
                      setState(() {});
                    }
                  },
                ),
              ),
            ],
          ),

          // Tafsir Section
          if (widget.verse.tafsir != null || widget.verse.tafsirRu != null) ...[
            const SizedBox(height: 8),
            ExpansionTile(
              title: Text(
                'Тафсир',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(Icons.menu_book, size: 20),
              childrenPadding: const EdgeInsets.all(8),
              children: [
                SingleChildScrollView(
                  child: Text(
                    _tafsirSourceKey == AppConstants.tafsirSourceRuIbnKathir
                        ? (widget.verse.tafsirRu ?? 'Тафсир нест.')
                        : (widget.verse.tafsir ?? 'Тафсири ин оят мавҷуд нест.'),
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
