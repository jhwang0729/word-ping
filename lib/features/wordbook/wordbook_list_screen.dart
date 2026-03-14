import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/wordbook.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_provider.dart';

final _wordbooksProvider = FutureProvider.autoDispose<List<_WordbookWithCount>>((ref) async {
  final wordbookRepo = await ref.watch(wordbookRepositoryProvider.future);
  final wordEntryRepo = await ref.watch(wordEntryRepositoryProvider.future);
  final wordbooks = await wordbookRepo.getAll();
  final result = <_WordbookWithCount>[];
  for (final wb in wordbooks) {
    final count = await wordEntryRepo.getCountByWordbookId(wb.id!);
    result.add(_WordbookWithCount(wordbook: wb, wordCount: count));
  }
  return result;
});

class _WordbookWithCount {
  final Wordbook wordbook;
  final int wordCount;
  _WordbookWithCount({required this.wordbook, required this.wordCount});
}

class WordbookListScreen extends ConsumerWidget {
  const WordbookListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordbooksAsync = ref.watch(_wordbooksProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaleFactor = settings.fontScaleFactor;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '단어장',
                    style: TextStyle(
                      fontSize: 24 * scaleFactor,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: wordbooksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('오류: $e')),
                data: (wordbooks) => _WordbookList(
                  wordbooks: wordbooks,
                  scaleFactor: scaleFactor,
                  isDark: isDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WordbookList extends ConsumerWidget {
  final List<_WordbookWithCount> wordbooks;
  final double scaleFactor;
  final bool isDark;

  const _WordbookList({
    required this.wordbooks,
    required this.scaleFactor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Add button
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => _showAddDialog(context, ref),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: FaIcon(FontAwesomeIcons.plus, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          if (wordbooks.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Text(
                '단어장이 없습니다.\n+ 버튼을 눌러 추가해 보세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16 * scaleFactor,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            )
          else
            ...wordbooks.map((item) => _WordbookCard(
                  item: item,
                  scaleFactor: scaleFactor,
                  isDark: isDark,
                )),
        ],
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('새 단어장'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '단어장 이름을 입력하세요'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('추가'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result != null && result.isNotEmpty) {
      final repo = await ref.read(wordbookRepositoryProvider.future);
      await repo.insert(Wordbook(name: result, createdAt: DateTime.now()));
      ref.invalidate(_wordbooksProvider);
    }
  }
}

class _WordbookCard extends ConsumerWidget {
  final _WordbookWithCount item;
  final double scaleFactor;
  final bool isDark;

  const _WordbookCard({
    required this.item,
    required this.scaleFactor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wb = item.wordbook;
    final count = item.wordCount;
    final canFlashcard = count > 0;
    final canQuiz = count >= AppConstants.minWordsForQuiz;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  wb.name,
                  style: TextStyle(
                    fontSize: 18 * scaleFactor,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkInputBackground : AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count 단어',
                      style: TextStyle(
                        fontSize: 14 * scaleFactor,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _confirmDelete(context, ref),
                    child: const FaIcon(
                      FontAwesomeIcons.trashCan,
                      size: 16,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: canFlashcard
                      ? () => context.go('/wordbooks/${wb.id}/flashcard')
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: canFlashcard
                          ? const Color(0xFFE3F2FD)
                          : (isDark ? AppColors.darkInputBackground : const Color(0xFFF5F5F5)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.clone,
                          size: 14,
                          color: canFlashcard ? AppColors.primary : AppColors.disabled,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '플래시카드',
                          style: TextStyle(
                            fontSize: 14 * scaleFactor,
                            fontWeight: FontWeight.w600,
                            color: canFlashcard ? AppColors.primary : AppColors.disabled,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: canQuiz
                      ? () => context.go('/wordbooks/${wb.id}/quiz')
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: canQuiz
                          ? const Color(0xFFE8F5E9)
                          : (isDark ? AppColors.darkInputBackground : const Color(0xFFF5F5F5)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.circleQuestion,
                          size: 14,
                          color: canQuiz ? AppColors.success : AppColors.disabled,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '퀴즈',
                          style: TextStyle(
                            fontSize: 14 * scaleFactor,
                            fontWeight: FontWeight.w600,
                            color: canQuiz ? AppColors.success : AppColors.disabled,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final alarmRepo = await ref.read(alarmRepositoryProvider.future);
    final connectedAlarms = await alarmRepo.getByWordbookId(item.wordbook.id!);

    if (!context.mounted) return;

    if (connectedAlarms.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('단어장 삭제'),
          content: Text('이 단어장에 연결된 알람이 ${connectedAlarms.length}개 있습니다.\n삭제하면 연결된 알람도 함께 삭제됩니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('삭제'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      // Delete connected alarms
      for (final alarm in connectedAlarms) {
        await alarmRepo.delete(alarm.id!);
      }
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('단어장 삭제'),
          content: const Text('단어장을 삭제하면 안에 있는 단어도 함께 삭제됩니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('삭제'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final repo = await ref.read(wordbookRepositoryProvider.future);
    await repo.delete(item.wordbook.id!);
    ref.invalidate(_wordbooksProvider);
  }
}
