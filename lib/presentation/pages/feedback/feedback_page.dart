import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/feedback_provider.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/constants/app_constants.dart';

class FeedbackPage extends ConsumerStatefulWidget {
  final String? source;
  final String? initialCategory;
  final String? initialFeedbackText;

  const FeedbackPage({
    super.key,
    this.source,
    this.initialCategory,
    this.initialFeedbackText,
  });

  @override
  ConsumerState<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends ConsumerState<FeedbackPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();
  
  late AnimationController _successController;
  late Animation<double> _scaleAnimation;

  final List<Map<String, dynamic>> _emojis = [
    {'emoji': '😞', 'label': 'Бад', 'value': 1},
    {'emoji': '🙁', 'label': 'Миёна', 'value': 2},
    {'emoji': '😐', 'label': 'Хуб', 'value': 3},
    {'emoji': '🙂', 'label': 'Олӣ', 'value': 4},
    {'emoji': '😍', 'label': 'Аъло', 'value': 5},
  ];

  final List<String> _categories = [
    '🐞 Хатогӣ дар барнома',
    '💡 Пешниҳод',
    '❤️ Фикри умумӣ',
    '📖 Матни Қуръон ва тафсир',
    '🔊 Овоз ва қироат',
    '🕋 Вақти Намоз',
    '❓ Дигар',
  ];

  String _getCategoryHint(String? category) {
    switch (category) {
      case '🐞 Хатогӣ дар барнома':
        return 'Хатогиро тавсиф кунед: чӣ рӯй дод ва дар куҷо?';
      case '💡 Пешниҳод':
        return 'Идеяи худро тавсиф кунед: чӣ чиз ва чаро лозим аст?';
      case '❤️ Фикри умумӣ':
        return 'Фикри умумии худро дар бораи барнома нависед...';
      case '📖 Матни Қуръон ва тафсир':
        return 'Сура, оят ва нуқсони дидаатонро нависед...';
      case '🔊 Овоз ва қироат':
        return 'Номи қорӣ ва мушкилоти шунидаатонро нависед...';
      case '🕋 Вақти Намоз':
        return 'Шаҳр ва ихтилофи вақтро нависед...';
      default:
        return 'Фикр ё мушкилоти худро нависед...';
    }
  }

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );

    // Initialize state on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(feedbackProvider.notifier);
      notifier.reset();
      
      // Prefill fields if provided
      if (widget.initialCategory != null) {
        // Try to match category
        final matched = _categories.firstWhere(
          (c) => c.toLowerCase().contains(widget.initialCategory!.toLowerCase()),
          orElse: () => _categories.first,
        );
        notifier.updateCategory(matched);
      } else if (widget.source == 'quick_action') {
        notifier.updateCategory('❓ Дигар');
        notifier.updateRating(3); // Neutral for uninstall
      }
      
      if (widget.initialFeedbackText != null) {
        _messageController.text = widget.initialFeedbackText!;
        notifier.updateMessage(widget.initialFeedbackText!);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final formState = ref.watch(feedbackProvider);
    final notifier = ref.read(feedbackProvider.notifier);

    // Watch status change to animate success tick
    ref.listen<FeedbackFormState>(feedbackProvider, (previous, next) {
      if (next.submitStatus == FeedbackSubmitStatus.success ||
          next.submitStatus == FeedbackSubmitStatus.cached) {
        _successController.forward(from: 0.0);
      }
      if (next.submitStatus == FeedbackSubmitStatus.error && next.errorMessage != null) {
        SnackBarHelper.showError(context: context, message: next.errorMessage!);
      }
    });

    final isUninstall = widget.source == 'quick_action';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isUninstall 
              ? 'Чаро удалит мекунед?' 
              : (widget.source == 'error_report' ? 'Гузориши мушкилот' : 'Фикру мулоҳизаҳо'),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              GoRouter.of(context).pop();
            } else {
              GoRouter.of(context).go('/');
            }
          },
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: formState.submitStatus == FeedbackSubmitStatus.success
              ? _buildSuccessView(theme, cs, formState.category)
              : formState.submitStatus == FeedbackSubmitStatus.cached
                  ? _buildCachedView(theme, cs)
                  : _buildFormView(theme, cs, formState, notifier, isUninstall),
        ),
      ),
    );
  }

  Widget _buildFormView(
    ThemeData theme,
    ColorScheme cs,
    FeedbackFormState state,
    FeedbackNotifier notifier,
    bool isUninstall,
  ) {
    final devInfoString = state.deviceInfo != null
        ? '${state.deviceInfo!['platform'] == 'android' ? 'Android' : 'iOS'} ${state.deviceInfo!['osVersion']} · Осонбаён ${state.deviceInfo!['appVersion']}'
        : 'Осонбаён ${AppConstants.appVersion}';

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            children: [
              // 1. Header (Dynamic Title & Subtitle)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      isUninstall ? 'Чӣ рӯй дод?' : 'Фикри шумо барои мо муҳим аст',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isUninstall
                          ? 'Лутфан ба мо бигӯед, ки чӣ кор кунем, то барномаро беҳтар созем.'
                          : 'Барои беҳтар ва муфидтар кардани барномаи Тафсири Осонбаён кӯмак кунед.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // 2. Rating Selector
              Center(
                child: Text(
                  'Баҳо диҳед',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _emojis.map((item) {
                  final isSelected = state.rating == item['value'];
                  return GestureDetector(
                    onTap: () => notifier.updateRating(item['value']),
                    child: AnimatedScale(
                      scale: isSelected ? 1.35 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: AnimatedOpacity(
                        opacity: state.rating == null || isSelected ? 1.0 : 0.4,
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                              child: Text(
                                item['emoji'],
                                style: const TextStyle(fontSize: 34),
                              ),
                            ),
                            Text(
                              item['label'],
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? cs.primary : cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // 3. Category Bottom Sheet Selector
              Text(
                'Бахш',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (ctx) {
                      return SafeArea(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 12),
                              Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: cs.outlineVariant,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Бахшро интихоб кунед',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Flexible(
                                child: ListView(
                                  shrinkWrap: true,
                                  children: [
                                    ..._categories.map((c) {
                                      final isSelected = state.category == c;
                                      return ListTile(
                                        leading: Text(
                                          c.split(' ').first,
                                          style: const TextStyle(fontSize: 22),
                                        ),
                                        title: Text(
                                          c.substring(c.indexOf(' ') + 1),
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? cs.primary : cs.onSurface,
                                          ),
                                        ),
                                        trailing: isSelected
                                            ? Icon(Icons.check_rounded, color: cs.primary)
                                            : null,
                                        onTap: () {
                                          notifier.updateCategory(c);
                                          Navigator.of(ctx).pop();
                                        },
                                      );
                                    }),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        state.category.split(' ').first,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.category.substring(state.category.indexOf(' ') + 1),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Icon(Icons.expand_more_rounded, color: cs.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4. Feedback Message
              Text(
                'Матни муроҷиат',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: isUninstall
                    ? 'Сабаби рафтанатон чист? Чӣ чизро беҳтар кунем?'
                    : _getCategoryHint(state.category),
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                  ),
                ),
                style: theme.textTheme.bodyMedium,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Лутфан матнро ворид кунед';
                  }
                  return null;
                },
                onChanged: notifier.updateMessage,
              ),
              const SizedBox(height: 20),

              // 5. Email (Optional)
              Text(
                'Почтаи электронӣ (ихтиёрӣ)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'you@example.com',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                  ),
                ),
                style: theme.textTheme.bodyMedium,
                onChanged: notifier.updateEmail,
              ),
              const SizedBox(height: 20),

              // 6. Screenshot Selector
              Text(
                'Акси экран (ихтиёрӣ)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: state.screenshotPath == null ? notifier.pickScreenshot : null,
                child: Container(
                  width: double.infinity,
                  height: 64,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: state.screenshotPath == null
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, color: cs.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Илова кардани акс',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(state.screenshotPath!),
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Акс бомуваффақият илова шуд',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline_rounded, color: cs.error),
                              onPressed: notifier.removeScreenshot,
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // 7. Device Info (Low-profile Toggle Checkbox)
              CheckboxListTile(
                value: state.includeDeviceInfo,
                onChanged: (val) {
                  if (val != null) notifier.toggleDeviceInfo(val);
                },
                title: const Text(
                  'Мубодилаи маълумоти техникӣ',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  state.includeDeviceInfo 
                      ? 'Барои муайян кардани хатогиҳо кӯмак мекунад: $devInfoString'
                      : 'Маълумоти дастгоҳ ва версияи барнома фиристода намешавад',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: cs.primary,
                dense: true,
              ),
              const SizedBox(height: 32),

              // 8. Submit Button
              ElevatedButton(
                onPressed: state.submitStatus == FeedbackSubmitStatus.loading
                    ? null
                    : () {
                        if (_formKey.currentState?.validate() ?? false) {
                          notifier.submitFeedback(source: widget.source ?? 'general');
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: state.submitStatus == FeedbackSubmitStatus.loading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: cs.onPrimary, strokeWidth: 2),
                      )
                    : const Text(
                        'Фиристодан',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(ThemeData theme, ColorScheme cs, String category) {
    String successMsg;
    if (category.contains('🐞') || category.toLowerCase().contains('хатогӣ')) {
      successMsg = 'Гузориши хатогии шумо қабул шуд. Ташаккур, ки ба мо дар беҳтар кардани барнома кӯмак мекунед! Мо кӯшиш мекунем, ки онро дар зудтарин фурсат ислоҳ кунем.';
    } else if (category.contains('💡') || category.toLowerCase().contains('пешниҳод')) {
      successMsg = 'Пешниҳоди шумо бомуваффақият қабул шуд. Идеяҳои шумо барои боз ҳам муфидтар сохтани барнома ба мо кӯмак мерасонанд.';
    } else if (category.contains('📖') || category.toLowerCase().contains('матни')) {
      successMsg = 'Муроҷиати шумо дар бораи матн ё тафсири Қуръон қабул шуд. Мутахассисони мо онро бодиққат тафтиш карда, ислоҳ менамоянд. Ташаккур барои таваҷҷӯҳатон!';
    } else if (category.contains('🔊') || category.toLowerCase().contains('овоз')) {
      successMsg = 'Гузориши шумо дар бораи овоз ва қироат бомуваффақият қабул шуд. Мо файлҳои аудиоиро тафтиш хоҳем кард.';
    } else if (category.contains('🕋') || category.toLowerCase().contains('вақти')) {
      successMsg = 'Муроҷиати шумо дар бораи вақтҳои намоз қабул шуд. Мо ҳисобкуниҳо ва танзимоти ҷуғрофиро тафтиш карда, ислоҳ менамоем.';
    } else if (category.contains('❤️') || category.toLowerCase().contains('фикри')) {
      successMsg = 'Ташаккур барои фикру мулоҳизаҳои гарми шумо! Дастгирии шумо ба мо барои идомаи беҳтарсозии барнома илҳом мебахшад.';
    } else {
      successMsg = 'Муроҷиати шумо бомуваффақият қабул шуд. Ташаккури зиёд барои таваҷҷӯҳ ва кӯмакатон!';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 72,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Ташаккури зиёд!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              successMsg,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                if (GoRouter.of(context).canPop()) {
                  GoRouter.of(context).pop();
                } else {
                  GoRouter.of(context).go('/');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                minimumSize: const Size(160, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('ОК', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCachedView(ThemeData theme, ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_upload_outlined,
                  color: Colors.orange,
                  size: 60,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Маҳаллан захира шуд',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Фикри шумо захира шуд. Ҳангоми пайдо шудани интернет, он ба таври худкор фиристода мешавад.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                if (GoRouter.of(context).canPop()) {
                  GoRouter.of(context).pop();
                } else {
                  GoRouter.of(context).go('/');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                minimumSize: const Size(160, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('ОК', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
