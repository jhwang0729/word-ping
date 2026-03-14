abstract class SettingsRepository {
  Future<bool> getDarkMode();
  Future<void> setDarkMode(bool value);
  Future<String> getFontSize();
  Future<void> setFontSize(String value);
  Future<String> getFlashcardFrontDisplay();
  Future<void> setFlashcardFrontDisplay(String value);
  Future<int> getDefaultQuizCount();
  Future<void> setDefaultQuizCount(int value);
}
