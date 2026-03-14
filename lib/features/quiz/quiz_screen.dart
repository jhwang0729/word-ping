import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/quiz_utils.dart';
import '../../data/models/word_entry.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_provider.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final int wordbookId;

  const QuizScreen({super.key, required this.wordbookId});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  List<WordEntry> _quizWords = [];
  List<WordEntry> _allWords = [];
  int _currentIndex = 0;
  int _correctCount = 0;
  final List<Map<String, String>> _incorrectWords = [];
  List<String> _currentOptions = [];
  int? _selectedIndex;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    final repo = await ref.read(wordEntryRepositoryProvider.future);
    final settings = ref.read(settingsProvider);
    final allWords = await repo.getByWordbookId(widget.wordbookId);

    final quizCount = min(settings.defaultQuizCount, allWords.length);
    final shuffled = QuizUtils.shuffle(allWords);
    final quizWords = shuffled.take(quizCount).toList();

    setState(() {
      _allWords = allWords;
      _quizWords = quizWords;
      _isLoading = false;
      _generateOptions();
    });
  }

  void _generateOptions() {
    if (_currentIndex >= _quizWords.length) return;

    final currentWord = _quizWords[_currentIndex];
    final correctDef = currentWord.meanings.isNotEmpty
        ? currentWord.meanings.first.definition
        : '';

    final allDefs = _allWords
        .where((w) => w.id != currentWord.id)
        .map((w) => w.meanings.isNotEmpty ? w.meanings.first.definition : '')
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList();

    _currentOptions = QuizUtils.generateOptions(
      correctAnswer: correctDef,
      allAnswers: [...allDefs, correctDef],
    );
  }

  void _selectAnswer(int index) {
    if (_selectedIndex != null) return;

    final currentWord = _quizWords[_currentIndex];
    final correctDef = currentWord.meanings.isNotEmpty
        ? currentWord.meanings.first.definition
        : '';
    final isCorrect = _currentOptions[index] == correctDef;

    setState(() {
      _selectedIndex = index;
      if (isCorrect) {
        _correctCount++;
      } else {
        _incorrectWords.add({
          'word': currentWord.word,
          'meaning': correctDef,
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (_currentIndex < _quizWords.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedIndex = null;
          _generateOptions();
        });
      } else {
        context.go(
          '/wordbooks/${widget.wordbookId}/quiz/result',
          extra: {
            'correctCount': _correctCount,
            'totalCount': _quizWords.length,
            'incorrectWords': _incorrectWords,
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaleFactor = settings.fontScaleFactor;

    if (_isLoading || _quizWords.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentWord = _quizWords[_currentIndex];
    final correctDef = currentWord.meanings.isNotEmpty
        ? currentWord.meanings.first.definition
        : '';

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
                    icon: const FaIcon(FontAwesomeIcons.xmark, size: 20),
                  ),
                  Expanded(
                    child: Text(
                      '단어 퀴즈',
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

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '문제 ${_currentIndex + 1} / ${_quizWords.length}',
                      style: TextStyle(
                        fontSize: 16 * scaleFactor,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      currentWord.word,
                      style: TextStyle(
                        fontSize: 48 * scaleFactor,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 40),
                    ..._currentOptions.asMap().entries.map((entry) {
                      final i = entry.key;
                      final option = entry.value;
                      final isSelected = _selectedIndex == i;
                      final isCorrectOption = option == correctDef;

                      Color bgColor;
                      Color borderColor;
                      Color textColor;

                      if (_selectedIndex != null) {
                        if (isCorrectOption) {
                          bgColor = const Color(0xFFD4EDDA);
                          borderColor = AppColors.success;
                          textColor = const Color(0xFF155724);
                        } else if (isSelected) {
                          bgColor = const Color(0xFFF8D7DA);
                          borderColor = AppColors.danger;
                          textColor = const Color(0xFF721C24);
                        } else {
                          bgColor = isDark ? AppColors.darkSurface : Colors.white;
                          borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE0E0E0);
                          textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
                        }
                      } else {
                        bgColor = isDark ? AppColors.darkSurface : Colors.white;
                        borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE0E0E0);
                        textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: GestureDetector(
                          onTap: () => _selectAnswer(i),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: bgColor,
                              border: Border.all(color: borderColor, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${i + 1}. $option',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18 * scaleFactor,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
