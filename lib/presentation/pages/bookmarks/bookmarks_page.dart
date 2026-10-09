import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/bookmark_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/quran_provider.dart';
import '../settings/settings_page.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../widgets/bottom_navigation_bar_widget.dart';

class BookmarksPage extends ConsumerWidget {
  final String userId;
  
  const BookmarksPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkState = ref.watch(bookmarkNotifierProvider(userId));
    final surahsAsync = ref.watch(surahsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Захирагоҳ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          if (bookmarkState.bookmarks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showClearAllDialog(context, ref),
              tooltip: 'Clear all bookmarks',
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _buildBody(context, ref, bookmarkState, surahsAsync),
      ),
      bottomNavigationBar: const BottomNavigationBarWidget(),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    BookmarkState bookmarkState,
    AsyncValue<List<dynamic>> surahsAsync,
  ) {
    if (bookmarkState.isLoading) {
      return LoadingFullScreenWidget(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      );
    }

    if (bookmarkState.error != null) {
      return Center(
        child: CustomErrorWidget(
          title: 'Хатоги дар захирагоҳ',
          message: bookmarkState.error!,
          onRetry: () {
            ref.read(bookmarkNotifierProvider(userId).notifier).refreshBookmarks();
          },
        ),
      );
    }

    if (bookmarkState.bookmarks.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        // Bookmark count
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.bookmark,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${bookmarkState.bookmarks.length} захира',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        
        // Bookmarks list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: bookmarkState.bookmarks.length,
            itemBuilder: (context, index) {
              final bookmark = bookmarkState.bookmarks[index];
              return _buildBookmarkItem(context, ref, bookmark, surahsAsync);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookmarkItem(
    BuildContext context,
    WidgetRef ref,
    BookmarkModel bookmark,
    AsyncValue<List<dynamic>> surahsAsync,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: InkWell(
          onTap: () {
            context.push('/surah/${bookmark.surahNumber}/verse/${bookmark.verseNumber}');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Surah and verse info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${bookmark.surahNumber}:${bookmark.verseNumber}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bookmark.surahName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeBookmark(context, ref, bookmark),
                      icon: const Icon(Icons.bookmark, color: Colors.red),
                      tooltip: 'Remove bookmark',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Arabic text - fixed spacing
                Text(
                  bookmark.arabicText,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontFamily: AppConstants.getEffectiveFontFamily(ref.watch(settingsProvider).arabicFont),
                    height: 1.5,
                    letterSpacing: 0,
                    fontSize: 18,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                ),
                
                const SizedBox(height: 6),
                
                // Tajik translation
                Text(
                  bookmark.ayatiText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.3,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Created date
                Text(
                  'Сохта шуд: ${_formatDate(bookmark.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Ҳеҷ захиаре нест',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Оёти дӯстдоштаро захира кунед',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Имрӯз';
    } else if (difference.inDays == 1) {
      return 'Дирӯз';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} рӯз пеш';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _removeBookmark(
    BuildContext context,
    WidgetRef ref,
    BookmarkModel bookmark,
  ) async {
    debugPrint('Bookmark to remove: ID=${bookmark.id}, verseKey=${bookmark.verseKey}, surah=${bookmark.surahNumber}:${bookmark.verseNumber}');
    
    final notifier = ref.read(bookmarkNotifierProvider(userId).notifier);
    bool success = false;
    String? errorMessage;
    
    try {
      // Try verse key-based removal first (most reliable)
      if (bookmark.verseKey.isNotEmpty) {
        debugPrint('Attempting removal by verse key: ${bookmark.verseKey}');
        success = await notifier.removeBookmarkByVerseKey(bookmark.verseKey);
        debugPrint('Verse key removal result: $success');
      }
      
      // If verse key removal failed and we have a valid ID, try ID-based removal
      if (!success && bookmark.id > 0) {
        debugPrint('Verse key removal failed, trying ID-based removal with ID: ${bookmark.id}');
        success = await notifier.removeBookmark(bookmark.id);
        debugPrint('ID-based removal result: $success');
      }
      
      // If both failed, check if bookmark still exists in state
      if (!success) {
        debugPrint('Both removal methods failed. Checking bookmark state...');
        final bookmarkState = ref.read(bookmarkNotifierProvider(userId));
        final stillExists = bookmarkState.bookmarks.any((b) => 
          b.verseKey == bookmark.verseKey || b.id == bookmark.id
        );
        debugPrint('Bookmark still exists in state: $stillExists');
        
        // If it doesn't exist in state, it might have been removed already
        if (!stillExists) {
          debugPrint('Bookmark not found in state, refreshing from database...');
          await notifier.refreshBookmarks();
          success = true; // Consider it successful if it's not in state
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error during bookmark removal: $e');
      debugPrint('Stack trace: $stackTrace');
      errorMessage = e.toString();
      success = false;
    }
    
    debugPrint('Final removal success: $success');
    
    if (context.mounted) {
      if (success) {
        SnackBarHelper.showSuccess(
          context: context,
          message: 'Захира хориҷ карда шуд',
          duration: const Duration(seconds: 2),
        );
      } else {
        SnackBarHelper.showError(
          context: context,
          message: errorMessage != null 
              ? 'Хатоги: $errorMessage' 
              : 'Хатоги дар хориҷ кардани захира',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> _showClearAllDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Пок кардани ҳамаи захираҳо'),
        content: const Text('Оё шумо мехоҳед ҳамаи захираҳоро пок кунед?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Бекор кардан'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Пок кардан'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      final notifier = ref.read(bookmarkNotifierProvider(userId).notifier);
      final success = await notifier.clearAllBookmarks();
      
      if (success) {
        SnackBarHelper.showSuccess(
          context: context,
          message: 'Ҳамаи захираҳо пок карда шуданд',
          duration: const Duration(seconds: 2),
        );
      }
    }
  }
}