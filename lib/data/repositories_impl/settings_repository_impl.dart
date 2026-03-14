import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const _keyDarkMode = 'darkMode';
  static const _keyFontSize = 'fontSize';
  static const _keyFlashcardFront = 'flashcardFrontDisplay';
  static const _keyDefaultQuizCount = 'defaultQuizCount';

  @override
  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  @override
  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  @override
  Future<String> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFontSize) ?? 'medium';
  }

  @override
  Future<void> setFontSize(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFontSize, value);
  }

  @override
  Future<String> getFlashcardFrontDisplay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFlashcardFront) ?? 'word';
  }

  @override
  Future<void> setFlashcardFrontDisplay(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFlashcardFront, value);
  }

  @override
  Future<int> getDefaultQuizCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDefaultQuizCount) ?? 20;
  }

  @override
  Future<void> setDefaultQuizCount(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDefaultQuizCount, value);
  }
}
