import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/verse_model.dart';
import '../../providers/bookmark_provider.dart';

class BookmarkButton extends ConsumerWidget {
  final VerseModel verse;
  final String surahName;
  final String userId;
  final double? size;
  final Color? color;

  const BookmarkButton({
    super.key,
    required this.verse,
    required this.surahName,
    required this.userId,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkState = ref.watch(bookmarkNotifierProvider(userId));
    final isBookmarked = bookmarkState.bookmarkStatus[verse.uniqueKey] ?? false;

    return IconButton(
      onPressed: () async {
        final notifier = ref.read(bookmarkNotifierProvider(userId).notifier);
        await notifier.toggleBookmark(verse, surahName);
      },
      icon: Icon(
        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
        size: size ?? 24,
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
      tooltip: isBookmarked ? 'Remove bookmark' : 'Add bookmark',
    );
  }
}

class BookmarkStatusIcon extends ConsumerWidget {
  final String verseKey;
  final String userId;
  final double? size;
  final Color? color;

  const BookmarkStatusIcon({
    super.key,
    required this.verseKey,
    required this.userId,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarked = ref.watch(isVerseBookmarkedProvider((userId, verseKey)));

    return Icon(
      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
      size: size ?? 20,
      color: color ?? Theme.of(context).colorScheme.primary,
    );
  }
}
