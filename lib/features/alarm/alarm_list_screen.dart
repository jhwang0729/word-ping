import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/alarm.dart';
import '../../data/models/wordbook.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_provider.dart';

final _alarmsProvider = FutureProvider.autoDispose<List<_AlarmWithWordbook>>((ref) async {
  final alarmRepo = await ref.watch(alarmRepositoryProvider.future);
  final wordbookRepo = await ref.watch(wordbookRepositoryProvider.future);
  final alarms = await alarmRepo.getAll();
  final result = <_AlarmWithWordbook>[];
  for (final alarm in alarms) {
    Wordbook? wordbook;
    if (alarm.wordbookId != null) {
      wordbook = await wordbookRepo.getById(alarm.wordbookId!);
    }
    result.add(_AlarmWithWordbook(alarm: alarm, wordbook: wordbook));
  }
  return result;
});

class _AlarmWithWordbook {
  final Alarm alarm;
  final Wordbook? wordbook;
  _AlarmWithWordbook({required this.alarm, this.wordbook});
}

class AlarmListScreen extends ConsumerWidget {
  const AlarmListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmsAsync = ref.watch(_alarmsProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaleFactor = settings.fontScaleFactor;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '알람',
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
              child: alarmsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('오류: $e')),
                data: (alarms) => _AlarmListContent(
                  alarms: alarms,
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

class _AlarmListContent extends ConsumerWidget {
  final List<_AlarmWithWordbook> alarms;
  final double scaleFactor;
  final bool isDark;

  const _AlarmListContent({
    required this.alarms,
    required this.scaleFactor,
    required this.isDark,
  });

  bool _isAlarmTomorrow(Alarm alarm) {
    if (!alarm.isEnabled) return false;
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowWeekday = tomorrow.weekday % 7; // Convert to 0=Sun

    if (alarm.repeatDays.isEmpty) return true;
    return alarm.repeatDaysList.contains(tomorrowWeekday);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => context.push('/alarms/new'),
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
          if (alarms.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Text(
                '알람이 없습니다.\n+ 버튼을 눌러 추가해 보세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16 * scaleFactor,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            )
          else
            ...alarms.map((item) {
              final alarm = item.alarm;
              final isTomorrow = _isAlarmTomorrow(alarm);

              return GestureDetector(
                onTap: () => context.push('/alarms/${alarm.id}/edit'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
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
                  child: Row(
                    children: [
                      if (isTomorrow)
                        Container(
                          width: 4,
                          height: 60,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: alarm.hour < 12 ? '오전 ' : '오후 ',
                                    style: TextStyle(
                                      fontSize: 18 * scaleFactor,
                                      color: alarm.isEnabled
                                          ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                                          : AppColors.textHint,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '${(alarm.hour == 0 ? 12 : (alarm.hour > 12 ? alarm.hour - 12 : alarm.hour)).toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 32 * scaleFactor,
                                      fontWeight: FontWeight.bold,
                                      color: alarm.isEnabled
                                          ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                                          : AppColors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Text(
                                  alarm.name,
                                  style: TextStyle(
                                    fontSize: 14 * scaleFactor,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  alarm.repeatDaysDisplay,
                                  style: TextStyle(
                                    fontSize: 14 * scaleFactor,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            if (alarm.isQuizEnabled && item.wordbook != null) ...[
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.book,
                                    size: 12,
                                    color: alarm.isEnabled ? AppColors.primary : AppColors.textHint,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${item.wordbook!.name} (단어 ${alarm.quizWordCount}개)',
                                    style: TextStyle(
                                      fontSize: 12 * scaleFactor,
                                      color: alarm.isEnabled ? AppColors.primary : AppColors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final repo = await ref.read(alarmRepositoryProvider.future);
                          await repo.updateEnabled(alarm.id!, !alarm.isEnabled);
                          ref.invalidate(_alarmsProvider);
                        },
                        child: Container(
                          width: 50,
                          height: 28,
                          decoration: BoxDecoration(
                            color: alarm.isEnabled ? AppColors.primary : AppColors.disabled,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            alignment: alarm.isEnabled
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
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
