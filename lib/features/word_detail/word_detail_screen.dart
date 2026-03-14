import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/datasources/dictionary_api.dart';
import '../../data/models/dictionary_response.dart';
import '../../data/models/word_entry.dart';
import '../../data/models/meaning.dart';
import '../../data/models/wordbook.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tts_provider.dart';

final _searchResultProvider = FutureProvider.family<DictionaryResponse, String>((ref, word) async {
  final api = ref.read(dictionaryApiProvider);
  return api.search(word);
});

class WordDetailScreen extends ConsumerWidget {
  final String word;

  const WordDetailScreen({super.key, required this.word});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResult = ref.watch(_searchResultProvider(word));
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaleFactor = settings.fontScaleFactor;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 20),
                  ),
                  Expanded(
                    child: Text(
                      '검색 결과',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20 * scaleFactor,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // Content
            Expanded(
              child: searchResult.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorView(
                  error: error,
                  onRetry: () => ref.invalidate(_searchResultProvider(word)),
                ),
                data: (response) => _WordDetailContent(
                  response: response,
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

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final message = error is WordNotFoundException
        ? '단어를 찾을 수 없습니다.\n정확한 영단어를 입력해 주세요.'
        : '네트워크 오류가 발생했습니다.\n인터넷 연결을 확인해 주세요.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              error is WordNotFoundException
                  ? FontAwesomeIcons.circleQuestion
                  : FontAwesomeIcons.triangleExclamation,
              size: 48,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            if (error is! WordNotFoundException) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('다시 시도'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WordDetailContent extends ConsumerWidget {
  final DictionaryResponse response;
  final double scaleFactor;
  final bool isDark;

  const _WordDetailContent({
    required this.response,
    required this.scaleFactor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meanings = response.meanings.take(AppConstants.maxMeaningsToDisplay).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Word header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        response.word,
                        style: TextStyle(
                          fontSize: 32 * scaleFactor,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (response.phonetic.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Text(
                        response.phonetic,
                        style: TextStyle(
                          fontSize: 18 * scaleFactor,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showSaveDialog(context, ref),
                icon: const FaIcon(FontAwesomeIcons.solidStar, size: 28),
                color: AppColors.disabled,
              ),
            ],
          ),

          // US pronunciation + TTS
          if (response.phonetic.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  Text(
                    '미국식: ${response.phonetic}',
                    style: TextStyle(
                      fontSize: 16 * scaleFactor,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => ref.read(ttsServiceProvider).speak(response.word),
                    child: const FaIcon(
                      FontAwesomeIcons.volumeHigh,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

          // Meanings
          ...meanings.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkInputBackground : const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}. ${m.definition} (${m.partOfSpeech})',
                    style: TextStyle(
                      fontSize: 18 * scaleFactor,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF222222),
                    ),
                  ),
                  if (m.example != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '"${m.example}"',
                      style: TextStyle(
                        fontSize: 15 * scaleFactor,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF555555),
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _showSaveDialog(BuildContext context, WidgetRef ref) async {
    final wordbookRepo = await ref.read(wordbookRepositoryProvider.future);
    final wordEntryRepo = await ref.read(wordEntryRepositoryProvider.future);
    if (!context.mounted) return;

    final wordbooks = await wordbookRepo.getAll();
    if (!context.mounted) return;

    final nameController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '단어장에 저장',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 15),
                if (wordbooks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      '단어장이 없습니다. 새 단어장을 만들어 주세요.',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  ...wordbooks.map((wb) => ListTile(
                        title: Text(wb.name),
                        onTap: () async {
                          await _saveWord(context, ref, wordEntryRepo, wb.id!);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      )),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          hintText: '새 단어장 이름',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;
                        final id = await wordbookRepo.insert(
                          Wordbook(name: name, createdAt: DateTime.now()),
                        );
                        if (!ctx.mounted) return;
                        await _saveWord(ctx, ref, wordEntryRepo, id);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('추가'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    nameController.dispose();
  }

  Future<void> _saveWord(
    BuildContext context,
    WidgetRef ref,
    dynamic wordEntryRepo,
    int wordbookId,
  ) async {
    // Check duplicate
    final exists = await wordEntryRepo.existsInWordbook(response.word, wordbookId);
    if (exists) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 저장된 단어입니다.')),
        );
      }
      return;
    }

    // Check word limit
    final count = await wordEntryRepo.getCountByWordbookId(wordbookId);
    if (count >= AppConstants.maxWordsPerWordbook) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('단어장에 최대 100개까지 저장할 수 있습니다.')),
        );
      }
      return;
    }

    final meaningsToSave = response.meanings
        .take(AppConstants.maxMeaningsToSave)
        .toList();

    final entry = WordEntry(
      word: response.word.toLowerCase(),
      phonetic: response.phonetic,
      wordbookId: wordbookId,
      createdAt: DateTime.now(),
      meanings: meaningsToSave.asMap().entries.map((e) {
        return Meaning(
          wordEntryId: 0,
          partOfSpeech: e.value.partOfSpeech,
          definition: e.value.definition,
          example: e.value.example,
          orderIndex: e.key,
        );
      }).toList(),
    );

    await wordEntryRepo.insert(entry);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('단어가 저장되었습니다!')),
      );
    }
  }
}
