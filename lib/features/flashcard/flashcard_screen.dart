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

class FlashcardScreen extends ConsumerStatefulWidget {
  final int wordbookId;

  const FlashcardScreen({super.key, required this.wordbookId});

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  List<WordEntry> _words = [];
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadWords();
  }

  Future<void> _loadWords() async {
    final repo = await ref.read(wordEntryRepositoryProvider.future);
    final words = await repo.getByWordbookId(widget.wordbookId);
    setState(() {
      _words = QuizUtils.shuffle(words);
      _isLoading = false;
    });
  }

  void _flip() {
    if (_isFlipped) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    _isFlipped = !_isFlipped;
  }

  void _next() {
    if (_currentIndex < _words.length - 1) {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
        _animationController.reset();
      });
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isFlipped = false;
        _animationController.reset();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaleFactor = settings.fontScaleFactor;
    final showWordFront = settings.flashcardFrontDisplay == 'word';

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_words.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, scaleFactor, isDark),
              const Expanded(child: Center(child: Text('단어가 없습니다.'))),
            ],
          ),
        ),
      );
    }

    final word = _words[_currentIndex];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, scaleFactor, isDark),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '${_currentIndex + 1} / ${_words.length}',
                style: TextStyle(
                  fontSize: 16 * scaleFactor,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: _flip,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      final angle = _animation.value * pi;
                      final isFrontVisible = angle < pi / 2;

                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        child: isFrontVisible
                            ? _buildFront(word, scaleFactor, isDark, showWordFront)
                            : Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateY(pi),
                                child: _buildBack(word, scaleFactor, isDark, showWordFront),
                              ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _currentIndex > 0 ? _prev : null,
                    icon: FaIcon(
                      FontAwesomeIcons.chevronLeft,
                      size: 30,
                      color: _currentIndex > 0 ? AppColors.primary : AppColors.disabled,
                    ),
                  ),
                  IconButton(
                    onPressed: _currentIndex < _words.length - 1 ? _next : null,
                    icon: FaIcon(
                      FontAwesomeIcons.chevronRight,
                      size: 30,
                      color: _currentIndex < _words.length - 1
                          ? AppColors.primary
                          : AppColors.disabled,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double scaleFactor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 20),
          ),
          Expanded(
            child: Text(
              '플래시카드',
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
    );
  }

  Widget _buildFront(WordEntry word, double scaleFactor, bool isDark, bool showWordFront) {
    if (showWordFront) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          border: Border.all(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              word.word,
              style: TextStyle(
                fontSize: 40 * scaleFactor,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            if (word.phonetic.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                word.phonetic,
                style: TextStyle(
                  fontSize: 20 * scaleFactor,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ],
        ),
      );
    } else {
      // Show meaning on front
      final firstMeaning = word.meanings.isNotEmpty ? word.meanings.first : null;
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          border: Border.all(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (firstMeaning != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  firstMeaning.definition,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24 * scaleFactor,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ),
          ],
        ),
      );
    }
  }

  Widget _buildBack(WordEntry word, double scaleFactor, bool isDark, bool showWordFront) {
    if (showWordFront) {
      // Back shows meanings
      final meanings = word.meanings.take(2).toList();
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < meanings.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: FractionallySizedBox(
                    widthFactor: 0.8,
                    child: Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              Text(
                '${i + 1}. ${meanings[i].definition}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24 * scaleFactor,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (meanings[i].example != null) ...[
                const SizedBox(height: 8),
                Text(
                  '"${meanings[i].example}"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16 * scaleFactor,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ],
          ],
        ),
      );
    } else {
      // Back shows word
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              word.word,
              style: TextStyle(
                fontSize: 40 * scaleFactor,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (word.phonetic.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                word.phonetic,
                style: TextStyle(
                  fontSize: 20 * scaleFactor,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ],
        ),
      );
    }
  }
}
