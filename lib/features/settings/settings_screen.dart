import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
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
                      '설정',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Display group
                    _buildGroup(isDark, [
                      _buildSettingRow(
                        '다크 모드',
                        GestureDetector(
                          onTap: () => notifier.setDarkMode(!settings.darkMode),
                          child: Container(
                            width: 50,
                            height: 28,
                            decoration: BoxDecoration(
                              color: settings.darkMode ? AppColors.primary : AppColors.disabled,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 200),
                              alignment: settings.darkMode
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                        scaleFactor,
                        isDark,
                      ),
                      Divider(color: isDark ? AppColors.darkBorder : AppColors.border, height: 1),
                      _buildSettingRow(
                        '글자 크기',
                        DropdownButton<String>(
                          value: settings.fontSize,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'small', child: Text('작게')),
                            DropdownMenuItem(value: 'medium', child: Text('보통')),
                            DropdownMenuItem(value: 'large', child: Text('크게')),
                          ],
                          onChanged: (v) {
                            if (v != null) notifier.setFontSize(v);
                          },
                        ),
                        scaleFactor,
                        isDark,
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Study group
                    _buildGroup(isDark, [
                      _buildSettingRow(
                        '플래시카드 앞면 표시',
                        DropdownButton<String>(
                          value: settings.flashcardFrontDisplay,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'word', child: Text('단어')),
                            DropdownMenuItem(value: 'meaning', child: Text('뜻')),
                          ],
                          onChanged: (v) {
                            if (v != null) notifier.setFlashcardFrontDisplay(v);
                          },
                        ),
                        scaleFactor,
                        isDark,
                      ),
                      Divider(color: isDark ? AppColors.darkBorder : AppColors.border, height: 1),
                      _buildSettingRow(
                        '기본 퀴즈 개수',
                        DropdownButton<int>(
                          value: settings.defaultQuizCount,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 5, child: Text('5개')),
                            DropdownMenuItem(value: 10, child: Text('10개')),
                            DropdownMenuItem(value: 15, child: Text('15개')),
                            DropdownMenuItem(value: 20, child: Text('20개')),
                          ],
                          onChanged: (v) {
                            if (v != null) notifier.setDefaultQuizCount(v);
                          },
                        ),
                        scaleFactor,
                        isDark,
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Info group
                    _buildGroup(isDark, [
                      GestureDetector(
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'Word Ping',
                            applicationVersion: '1.0.0',
                            children: [
                              const Text('영단어 사전 & 퀴즈 알람 앱'),
                            ],
                          );
                        },
                        child: _buildSettingRow(
                          '앱 정보',
                          FaIcon(
                            FontAwesomeIcons.chevronRight,
                            size: 14,
                            color: AppColors.disabled,
                          ),
                          scaleFactor,
                          isDark,
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroup(bool isDark, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingRow(String label, Widget control, double scaleFactor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16 * scaleFactor,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),
          control,
        ],
      ),
    );
  }
}
