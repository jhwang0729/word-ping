import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/quiz_utils.dart';
import '../../data/models/alarm.dart';
import '../../data/models/word_entry.dart';
import '../../providers/repository_providers.dart';

class AlarmRingScreen extends ConsumerStatefulWidget {
  final int alarmId;

  const AlarmRingScreen({super.key, required this.alarmId});

  @override
  ConsumerState<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends ConsumerState<AlarmRingScreen> {
  Alarm? _alarm;
  List<WordEntry> _words = [];
  List<WordEntry> _quizQueue = [];
  int _wordsLeft = 0;
  int _currentQuizIndex = 0;
  List<String> _currentOptions = [];
  int? _selectedIndex;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlarm();
  }

  Future<void> _loadAlarm() async {
    final alarmRepo = await ref.read(alarmRepositoryProvider.future);
    final alarm = await alarmRepo.getById(widget.alarmId);

    if (alarm != null && alarm.isQuizEnabled && alarm.wordbookId != null) {
      final wordRepo = await ref.read(wordEntryRepositoryProvider.future);
      final words = await wordRepo.getByWordbookId(alarm.wordbookId!);
      final shuffled = QuizUtils.shuffle(words);
      final quizWords = shuffled.take(alarm.quizWordCount).toList();

      setState(() {
        _alarm = alarm;
        _words = words;
        _quizQueue = quizWords;
        _wordsLeft = quizWords.length;
        _isLoading = false;
        _generateOptions();
      });
    } else {
      setState(() {
        _alarm = alarm;
        _isLoading = false;
      });
    }
  }

  void _generateOptions() {
    if (_currentQuizIndex >= _quizQueue.length) return;

    final currentWord = _quizQueue[_currentQuizIndex];
    final correctDef = currentWord.meanings.isNotEmpty
        ? currentWord.meanings.first.definition
        : '';

    final allDefs = _words
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

    final currentWord = _quizQueue[_currentQuizIndex];
    final correctDef = currentWord.meanings.isNotEmpty
        ? currentWord.meanings.first.definition
        : '';
    final isCorrect = _currentOptions[index] == correctDef;

    setState(() {
      _selectedIndex = index;
      if (isCorrect) {
        _wordsLeft--;
      } else {
        _wordsLeft++;
        // Add another random word to the queue
        if (_words.length > 1) {
          final remaining = _words.where((w) => w.id != currentWord.id).toList();
          remaining.shuffle();
          _quizQueue.add(remaining.first);
        } else {
          _quizQueue.add(currentWord);
        }
      }
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      if (_wordsLeft <= 0) {
        _dismissAlarm();
      } else {
        setState(() {
          _currentQuizIndex++;
          _selectedIndex = null;
          _generateOptions();
        });
      }
    });
  }

  void _dismissAlarm() {
    if (mounted) context.go('/alarms');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.danger,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.danger,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Time + Title
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _alarm?.name ?? '알람',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),

                if (_alarm?.isQuizEnabled == true && _quizQueue.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const FaIcon(FontAwesomeIcons.bell, size: 14, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        '알람을 해제하려면 퀴즈를 맞추세요',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Quiz card
                  if (_currentQuizIndex < _quizQueue.length)
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            '남은 단어: $_wordsLeft개',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.danger,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _quizQueue[_currentQuizIndex].word,
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 30),
                          ..._currentOptions.asMap().entries.map((entry) {
                            final i = entry.key;
                            final option = entry.value;
                            final correctDef = _quizQueue[_currentQuizIndex].meanings.isNotEmpty
                                ? _quizQueue[_currentQuizIndex].meanings.first.definition
                                : '';
                            final isCorrectOption = option == correctDef;

                            Color bgColor = const Color(0xFFF8F9FA);
                            Color borderColor = const Color(0xFFE9ECEF);
                            Color textColor = AppColors.textPrimary;

                            if (_selectedIndex != null) {
                              if (isCorrectOption) {
                                bgColor = const Color(0xFFD4EDDA);
                                borderColor = AppColors.success;
                                textColor = const Color(0xFF155724);
                              } else if (_selectedIndex == i) {
                                bgColor = const Color(0xFFF8D7DA);
                                borderColor = AppColors.danger;
                                textColor = const Color(0xFF721C24);
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 15),
                              child: GestureDetector(
                                onTap: () => _selectAnswer(i),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    border: Border.all(color: borderColor, width: 2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${i + 1}. $option',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
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
                ] else ...[
                  const SizedBox(height: 60),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _dismissAlarm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.danger,
                        padding: const EdgeInsets.all(20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        '알람 해제',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
