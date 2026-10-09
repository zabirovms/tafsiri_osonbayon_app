import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/reciter_model.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../core/constants/reciter_image_sizes.dart';
import 'reciter_image.dart';

/// Widget that displays reciters categorized by A-Z
/// Supports both vertical and horizontal scrolling
class CategorizedRecitersList extends ConsumerStatefulWidget {
  final List<ReciterModel> reciters;
  final bool horizontal;
  final Function(ReciterModel)? onReciterTap;

  const CategorizedRecitersList({
    super.key,
    required this.reciters,
    this.horizontal = false,
    this.onReciterTap,
  });

  @override
  ConsumerState<CategorizedRecitersList> createState() =>
      _CategorizedRecitersListState();
}

class _CategorizedRecitersListState
    extends ConsumerState<CategorizedRecitersList> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final Map<String, int> _sectionIndices = {};
  String? _selectedLetter;

  @override
  void initState() {
    super.initState();
    _buildSectionIndices();
  }

  void _buildSectionIndices() {
    // Group reciters by first letter of English name
    final grouped = <String, List<ReciterModel>>{};
    for (final reciter in widget.reciters) {
      final firstLetter = reciter.name.isNotEmpty
          ? reciter.name[0].toUpperCase()
          : '#';
      if (!RegExp(r'[A-Z]').hasMatch(firstLetter)) {
        grouped.putIfAbsent('#', () => []).add(reciter);
      } else {
        grouped.putIfAbsent(firstLetter, () => []).add(reciter);
      }
    }

    // Sort groups and build indices
    final sortedLetters = grouped.keys.toList()..sort();
    int index = 0;
    for (final letter in sortedLetters) {
      _sectionIndices[letter] = index;
      index += grouped[letter]!.length + 1; // +1 for section header
    }
  }

  Map<String, List<ReciterModel>> _getGroupedReciters() {
    final grouped = <String, List<ReciterModel>>{};
    for (final reciter in widget.reciters) {
      final firstLetter = reciter.name.isNotEmpty
          ? reciter.name[0].toUpperCase()
          : '#';
      if (!RegExp(r'[A-Z]').hasMatch(firstLetter)) {
        grouped.putIfAbsent('#', () => []).add(reciter);
      } else {
        grouped.putIfAbsent(firstLetter, () => []).add(reciter);
      }
    }

    // Sort within each group
    for (final letter in grouped.keys) {
      grouped[letter]!.sort((a, b) => a.name.compareTo(b.name));
    }

    return grouped;
  }

  void _scrollToSection(String letter) {
    final index = _sectionIndices[letter];
    if (index != null && _itemScrollController.isAttached) {
      _itemScrollController.jumpTo(index: index);
      setState(() {
        _selectedLetter = letter;
      });
      // Clear selection after animation
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _selectedLetter = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final grouped = _getGroupedReciters();
    final sortedLetters = grouped.keys.toList()..sort();

    if (widget.horizontal) {
      return _buildHorizontalView(grouped, sortedLetters, colorScheme);
    } else {
      return _buildVerticalView(grouped, sortedLetters, colorScheme);
    }
  }

  Widget _buildVerticalView(
    Map<String, List<ReciterModel>> grouped,
    List<String> sortedLetters,
    ColorScheme colorScheme,
  ) {
    final items = <Widget>[];

    for (final letter in sortedLetters) {
      final reciters = grouped[letter]!;
      // Section header
      items.add(
        _SectionHeader(
          letter: letter,
          count: reciters.length,
          isSelected: _selectedLetter == letter,
        ),
      );
      // Reciter items
      for (final reciter in reciters) {
        items.add(
          _ReciterListItem(
            reciter: reciter,
            onTap: () {
              if (widget.onReciterTap != null) {
                widget.onReciterTap!(reciter);
              } else {
                context.push('/audio-home/reciter/${reciter.id}');
              }
            },
          ),
        );
      }
    }

    return Row(
      children: [
        // A-Z index sidebar
        _buildAlphabetIndex(sortedLetters, colorScheme),
        // Main list
        Expanded(
          child: ScrollablePositionedList.builder(
            itemScrollController: _itemScrollController,
            itemPositionsListener: _itemPositionsListener,
            itemCount: items.length,
            itemBuilder: (context, index) => items[index],
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalView(
    Map<String, List<ReciterModel>> grouped,
    List<String> sortedLetters,
    ColorScheme colorScheme,
  ) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: sortedLetters.length,
      itemBuilder: (context, index) {
        final letter = sortedLetters[index];
        final reciters = grouped[letter]!;

        return Container(
          width: 200,
          margin: const EdgeInsets.only(right: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  letter,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                ),
              ),
              // Reciters in this section
              Expanded(
                child: ListView.builder(
                  itemCount: reciters.length,
                  itemBuilder: (context, idx) {
                    final reciter = reciters[idx];
                    return _ReciterListItem(
                      reciter: reciter,
                      onTap: () {
                        if (widget.onReciterTap != null) {
                          widget.onReciterTap!(reciter);
                        } else {
                          context.push('/audio-home/reciter/${reciter.id}');
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlphabetIndex(List<String> letters, ColorScheme colorScheme) {
    return Container(
      width: 40,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        itemCount: letters.length,
        itemBuilder: (context, index) {
          final letter = letters[index];
          final isSelected = _selectedLetter == letter;

          return GestureDetector(
            onTap: () => _scrollToSection(letter),
            child: Container(
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String letter;
  final int count;
  final bool isSelected;

  const _SectionHeader({
    required this.letter,
    required this.count,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primary.withValues(alpha: 0.1)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            letter,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($count)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReciterListItem extends StatelessWidget {
  final ReciterModel reciter;
  final VoidCallback onTap;

  const _ReciterListItem({
    required this.reciter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: ReciterImage(
        reciterId: reciter.id,
        width: ReciterImageSizes.small,
        height: ReciterImageSizes.small,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        borderRadius: BorderRadius.circular(ReciterImageSizes.getCircularRadius(ReciterImageSizes.small)),
        errorWidget: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.primary.withValues(alpha: 0.1),
          ),
          child: Center(
            child: Text(
              reciter.nameTajik.isNotEmpty
                  ? reciter.nameTajik[0]
                  : reciter.name[0],
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      title: Text(
        (reciter.nameTajik.isNotEmpty && reciter.nameTajik != reciter.id)
            ? reciter.nameTajik 
            : (reciter.name.isNotEmpty && reciter.name != reciter.id
                ? reciter.name
                : '...'),
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reciter.name,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          if (reciter.nameArabic.isNotEmpty)
            Text(
              reciter.nameArabic,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                fontFamily: 'Noto_Naskh_Arabic',
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

