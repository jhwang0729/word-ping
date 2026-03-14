import 'dart:math';

class QuizUtils {
  QuizUtils._();

  static final _random = Random();

  static List<T> shuffle<T>(List<T> items) {
    final list = List<T>.from(items);
    list.shuffle(_random);
    return list;
  }

  static List<String> generateOptions({
    required String correctAnswer,
    required List<String> allAnswers,
    int optionCount = 4,
  }) {
    final wrongAnswers = allAnswers
        .where((a) => a != correctAnswer)
        .toList()
      ..shuffle(_random);

    final options = <String>[correctAnswer];
    for (final wrong in wrongAnswers) {
      if (options.length >= optionCount) break;
      options.add(wrong);
    }

    options.shuffle(_random);
    return options;
  }
}
