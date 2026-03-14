import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories_impl/settings_repository_impl.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl();
});

class SettingsState {
  final bool darkMode;
  final String fontSize;
  final String flashcardFrontDisplay;
  final int defaultQuizCount;

  const SettingsState({
    this.darkMode = false,
    this.fontSize = 'medium',
    this.flashcardFrontDisplay = 'word',
    this.defaultQuizCount = 20,
  });

  double get fontScaleFactor {
    switch (fontSize) {
      case 'small':
        return 0.85;
      case 'large':
        return 1.15;
      default:
        return 1.0;
    }
  }

  SettingsState copyWith({
    bool? darkMode,
    String? fontSize,
    String? flashcardFrontDisplay,
    int? defaultQuizCount,
  }) {
    return SettingsState(
      darkMode: darkMode ?? this.darkMode,
      fontSize: fontSize ?? this.fontSize,
      flashcardFrontDisplay: flashcardFrontDisplay ?? this.flashcardFrontDisplay,
      defaultQuizCount: defaultQuizCount ?? this.defaultQuizCount,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    state = SettingsState(
      darkMode: await _repository.getDarkMode(),
      fontSize: await _repository.getFontSize(),
      flashcardFrontDisplay: await _repository.getFlashcardFrontDisplay(),
      defaultQuizCount: await _repository.getDefaultQuizCount(),
    );
  }

  Future<void> setDarkMode(bool value) async {
    await _repository.setDarkMode(value);
    state = state.copyWith(darkMode: value);
  }

  Future<void> setFontSize(String value) async {
    await _repository.setFontSize(value);
    state = state.copyWith(fontSize: value);
  }

  Future<void> setFlashcardFrontDisplay(String value) async {
    await _repository.setFlashcardFrontDisplay(value);
    state = state.copyWith(flashcardFrontDisplay: value);
  }

  Future<void> setDefaultQuizCount(int value) async {
    await _repository.setDefaultQuizCount(value);
    state = state.copyWith(defaultQuizCount: value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repository);
});
