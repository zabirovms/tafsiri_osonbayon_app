import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/surah_model.dart';
import '../../../../presentation/providers/quran_provider.dart';
import '../../../../presentation/providers/search_provider.dart';
import '../../../widgets/quran/juz_list_item.dart' show JuzInfo;
import '../../../widgets/quran/page_list_item.dart' show PageInfo;
import 'package:qcf_quran/qcf_quran.dart';

class UnifiedNavigator extends ConsumerStatefulWidget {
  final int? initialSurah;
  final int? initialVerse;

  const UnifiedNavigator({
    super.key,
    this.initialSurah,
    this.initialVerse,
  });

  @override
  ConsumerState<UnifiedNavigator> createState() => _UnifiedNavigatorState();
}

class _UnifiedNavigatorState extends ConsumerState<UnifiedNavigator> {
  // ─── Data ──────────────────────────────────────────────────────────────────
  List<SurahModel> _surahs = [];
  List<JuzInfo> _juzList = [];
  List<PageInfo> _pageList = [];
  bool _isLoading = true;

  // ─── Selected indices (0-based) ───────────────────────────────────────────
  int _juzIndex = 0; // 0 → Juz 1
  int _pageIndex = 0; // 0 → Page 1
  int _surahIndex = 0; // 0 → Surah 1 (Al-Fatiha)
  int _verseIndex = 0; // 0 → Verse 1

  // Multiplier for infinite-carousel trick
  static const int _kMult = 5000;

  // ─── Scroll controllers ───────────────────────────────────────────────────
  late FixedExtentScrollController _juzCtrl;
  late FixedExtentScrollController _pageCtrl;
  late FixedExtentScrollController _surahCtrl;
  FixedExtentScrollController _verseCtrl = FixedExtentScrollController();
  Key _verseWheelKey = const ValueKey('verse_0');

  int get _verseCount => _surahs.isEmpty ? 1 : _surahs[_surahIndex].versesCount;

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    if (widget.initialSurah != null) {
      final surah = widget.initialSurah!.clamp(1, 114);
      final verse = (widget.initialVerse ?? 1).clamp(1, 286);
      _surahIndex = surah - 1;
      try {
        final juz = getJuzNumber(surah, verse);
        _juzIndex = (juz - 1).clamp(0, 29);
      } catch (_) {}
      try {
        final page = getPageNumber(surah, verse);
        _pageIndex = (page - 1).clamp(0, 603);
      } catch (_) {}
    }
    if (widget.initialVerse != null) {
      _verseIndex = (widget.initialVerse! - 1).clamp(0, 999);
    }

    _juzCtrl =
        FixedExtentScrollController(initialItem: 30 * _kMult ~/ 2 + _juzIndex);
    _pageCtrl = FixedExtentScrollController(
        initialItem: 604 * _kMult ~/ 2 + _pageIndex);
    _surahCtrl = FixedExtentScrollController(
        initialItem: 114 * _kMult ~/ 2 + _surahIndex);
    _verseCtrl = FixedExtentScrollController(
        initialItem: 300 * _kMult ~/ 2 + _verseIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _juzCtrl.dispose();
    _pageCtrl.dispose();
    _surahCtrl.dispose();
    _verseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final surahDS = ref.read(surahLocalDataSourceProvider);
      final surahs = await surahDS.getAllSurahs()
        ..sort((a, b) => a.number.compareTo(b.number));

      final metadata = await ref.read(quranMetadataProvider.future);

      if (!mounted) return;
      setState(() {
        _surahs = surahs;
        _juzList = metadata.juzList;
        _pageList = metadata.pageList;
        _isLoading = false;

        final maxVerse = _verseCount - 1;
        if (_verseIndex > maxVerse) _verseIndex = 0;

        final oldCtrl = _verseCtrl;
        _verseCtrl = FixedExtentScrollController(
          initialItem: _verseCount * _kMult ~/ 2 + _verseIndex,
        );
        oldCtrl.dispose();
        _verseWheelKey = ValueKey('verse_loaded_$_surahIndex');
      });
    } catch (e) {
      debugPrint('UnifiedNavigator load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Navigation actions ───────────────────────────────────────────────────
  void _goToJuz() {
    if (_juzList.isEmpty) return;
    final idx = _juzIndex.clamp(0, _juzList.length - 1);
    final juz = _juzList[idx];
    final label = 'Ҷузъи ${idx + 1}';
    final href = '/surah/${juz.surahNumber}/verse/${juz.ayahNumber}';

    ref.read(searchNotifierProvider.notifier).saveRecentNavigation(
          label: label,
          href: href,
          type: 'juz',
        );
    context.push(href);
  }

  void _goToPage() {
    if (_pageList.isEmpty) return;
    final idx = _pageIndex.clamp(0, _pageList.length - 1);
    final pageNum = idx + 1;
    final label = 'Саҳифаи $pageNum';
    final href = '/mushaf?page=$pageNum';

    ref.read(searchNotifierProvider.notifier).saveRecentNavigation(
          label: label,
          href: href,
          type: 'page',
        );
    context.push(href);
  }

  void _goToSurahVerse() {
    if (_surahs.isEmpty) return;
    final surah = _surahs[_surahIndex];
    final verse = (_verseIndex + 1).clamp(1, surah.versesCount);
    final label = 'Сураи ${surah.nameTajik}, Ояти $verse';
    final href = '/surah/${surah.number}/verse/$verse';

    ref.read(searchNotifierProvider.notifier).saveRecentNavigation(
          label: label,
          href: href,
          type: 'verse',
        );
    context.push(href);
  }

  void _onSurahChanged(int index) {
    HapticFeedback.selectionClick();
    final newVerseCount = _surahs[index].versesCount;

    final oldCtrl = _verseCtrl;
    _verseCtrl = FixedExtentScrollController(
      initialItem: newVerseCount * _kMult ~/ 2,
    );
    oldCtrl.dispose();

    setState(() {
      _surahIndex = index;
      _verseIndex = 0;
      _verseWheelKey = ValueKey('verse_$index');
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Surah + Verse card ───────────────────────────────
        if (_surahs.isNotEmpty) ...[
          _SurahVersePicker(
            surahs: _surahs,
            surahController: _surahCtrl,
            verseController: _verseCtrl,
            verseWheelKey: _verseWheelKey,
            selectedSurahIndex: _surahIndex,
            selectedVerseIndex: _verseIndex,
            verseCount: _verseCount,
            onSurahChanged: _onSurahChanged,
            onVerseChanged: (i) {
              HapticFeedback.selectionClick();
              setState(() => _verseIndex = i);
            },
            onGo: _goToSurahVerse,
          ),
          const SizedBox(height: 12),
        ],

        // ── Row: Juz | Page ──────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _PickerCard(
                title: 'Ҷузъ',
                subtitle: '30',
                controller: _juzCtrl,
                total: 30,
                selectedIndex: _juzIndex,
                itemLabel: (i) => '${i + 1}',
                onChanged: (i) {
                  HapticFeedback.selectionClick();
                  setState(() => _juzIndex = i);
                },
                onGo: _goToJuz,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PickerCard(
                title: 'Саҳифа',
                subtitle: _pageList.isEmpty ? '604' : '${_pageList.length}',
                controller: _pageCtrl,
                total: _pageList.isEmpty ? 604 : _pageList.length,
                selectedIndex: _pageIndex,
                itemLabel: (i) => '${i + 1}',
                onChanged: (i) {
                  HapticFeedback.selectionClick();
                  setState(() => _pageIndex = i);
                },
                onGo: _goToPage,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable: Picker Card (Juz / Page)
// ─────────────────────────────────────────────────────────────────────────────
class _PickerCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final FixedExtentScrollController controller;
  final int total;
  final int selectedIndex;
  final String Function(int index) itemLabel;
  final void Function(int index) onChanged;
  final VoidCallback onGo;

  const _PickerCard({
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.total,
    required this.selectedIndex,
    required this.itemLabel,
    required this.onChanged,
    required this.onGo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
      child: Column(
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 6),
          _buildDivider(cs),
          _WheelPicker(
            controller: controller,
            total: total,
            selectedIndex: selectedIndex,
            onChanged: onChanged,
            itemBuilder: (context, index, isSelected) => Center(
              child: Text(
                itemLabel(index),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color:
                      isSelected ? cs.primary : cs.onSurface.withOpacity(0.5),
                  fontSize: isSelected ? 22 : 18,
                ),
              ),
            ),
          ),
          _buildDivider(cs),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onGo,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Рафтан'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ColorScheme cs) => Divider(
        color: cs.outlineVariant.withOpacity(0.6),
        height: 1,
        thickness: 1,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Surah + Verse Picker Card
// ─────────────────────────────────────────────────────────────────────────────
class _SurahVersePicker extends StatelessWidget {
  final List<SurahModel> surahs;
  final FixedExtentScrollController surahController;
  final FixedExtentScrollController verseController;
  final Key verseWheelKey;
  final int selectedSurahIndex;
  final int selectedVerseIndex;
  final int verseCount;
  final void Function(int) onSurahChanged;
  final void Function(int) onVerseChanged;
  final VoidCallback onGo;

  const _SurahVersePicker({
    required this.surahs,
    required this.surahController,
    required this.verseController,
    required this.verseWheelKey,
    required this.selectedSurahIndex,
    required this.selectedVerseIndex,
    required this.verseCount,
    required this.onSurahChanged,
    required this.onVerseChanged,
    required this.onGo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Сура ва оят',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '114 сура',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: onGo,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Рафтан'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: cs.outlineVariant.withOpacity(0.6), height: 1),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'Сура',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.55),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _WheelPicker(
                      controller: surahController,
                      total: surahs.length,
                      selectedIndex: selectedSurahIndex,
                      onChanged: onSurahChanged,
                      itemBuilder: (context, index, isSelected) => Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '${surahs[index].number}. ${surahs[index].nameTajik}',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w400,
                            color: isSelected
                                ? cs.primary
                                : cs.onSurface.withOpacity(0.5),
                            fontSize: isSelected ? 22 : 18,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              VerticalDivider(
                color: cs.outlineVariant.withOpacity(0.6),
                width: 24,
                thickness: 1,
              ),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'Оят',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.55),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _WheelPicker(
                      key: verseWheelKey,
                      controller: verseController,
                      total: verseCount,
                      selectedIndex: selectedVerseIndex,
                      onChanged: onVerseChanged,
                      itemBuilder: (context, index, isSelected) => Center(
                        child: Text(
                          '${index + 1}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w400,
                            color: isSelected
                                ? cs.primary
                                : cs.onSurface.withOpacity(0.5),
                            fontSize: isSelected ? 22 : 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(color: cs.outlineVariant.withOpacity(0.6), height: 1),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Core drum-roll wheel widget
// ─────────────────────────────────────────────────────────────────────────────
class _WheelPicker extends StatelessWidget {
  final FixedExtentScrollController controller;
  final int total;
  final int selectedIndex;
  final void Function(int index) onChanged;
  final Widget Function(BuildContext context, int index, bool isSelected)
      itemBuilder;

  const _WheelPicker({
    super.key,
    required this.controller,
    required this.total,
    required this.selectedIndex,
    required this.onChanged,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const kMult = _UnifiedNavigatorState._kMult;
    final childCount = total * kMult;

    return SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 40,
            diameterRatio: 2.0,
            perspective: 0.002,
            physics: const FixedExtentScrollPhysics(),
            overAndUnderCenterOpacity: 0.55,
            onSelectedItemChanged: (rawIndex) {
              onChanged(rawIndex % total);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: childCount,
              builder: (context, rawIndex) {
                final logicalIndex = rawIndex % total;
                final isSelected = logicalIndex == selectedIndex;
                return itemBuilder(context, logicalIndex, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }
}
