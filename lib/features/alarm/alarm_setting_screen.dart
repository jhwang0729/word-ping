import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/alarm.dart';
import '../../data/models/wordbook.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_provider.dart';

class AlarmSettingScreen extends ConsumerStatefulWidget {
  final int? alarmId;

  const AlarmSettingScreen({super.key, this.alarmId});

  @override
  ConsumerState<AlarmSettingScreen> createState() => _AlarmSettingScreenState();
}

class _AlarmSettingScreenState extends ConsumerState<AlarmSettingScreen> {
  bool _isLoading = true;
  bool _isPM = false;
  int _hour = 7;
  int _minute = 0;
  final Set<int> _selectedDays = {};
  final _nameController = TextEditingController(text: '알람');
  String _soundName = 'default_alarm';
  bool _isQuizEnabled = false;
  int? _selectedWordbookId;
  int _quizWordCount = 3;
  List<Wordbook> _wordbooks = [];

  static const _sounds = [
    ('default_alarm', '기본 알람음'),
    ('bird', '새소리'),
    ('wave', '파도소리'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final wordbookRepo = await ref.read(wordbookRepositoryProvider.future);
    _wordbooks = await wordbookRepo.getAll();

    if (widget.alarmId != null) {
      final alarmRepo = await ref.read(alarmRepositoryProvider.future);
      final alarm = await alarmRepo.getById(widget.alarmId!);
      if (alarm != null) {
        _isPM = alarm.hour >= 12;
        _hour = alarm.hour == 0 ? 12 : (alarm.hour > 12 ? alarm.hour - 12 : alarm.hour);
        _minute = alarm.minute;
        _selectedDays.addAll(alarm.repeatDaysList);
        _nameController.text = alarm.name;
        _soundName = alarm.soundName;
        _isQuizEnabled = alarm.isQuizEnabled;
        _selectedWordbookId = alarm.wordbookId;
        _quizWordCount = alarm.quizWordCount;
      }
    }

    setState(() => _isLoading = false);
  }

  int get _hour24 {
    if (_isPM) {
      return _hour == 12 ? 12 : _hour + 12;
    } else {
      return _hour == 12 ? 0 : _hour;
    }
  }

  Future<void> _save() async {
    final repo = await ref.read(alarmRepositoryProvider.future);
    final sortedDays = _selectedDays.toList()..sort();
    final alarm = Alarm(
      id: widget.alarmId,
      name: _nameController.text.trim().isEmpty ? '알람' : _nameController.text.trim(),
      hour: _hour24,
      minute: _minute,
      repeatDays: sortedDays.join(','),
      soundName: _soundName,
      isEnabled: true,
      isQuizEnabled: _isQuizEnabled,
      wordbookId: _isQuizEnabled ? _selectedWordbookId : null,
      quizWordCount: _quizWordCount,
      createdAt: DateTime.now(),
    );

    if (widget.alarmId != null) {
      await repo.update(alarm);
    } else {
      await repo.insert(alarm);
    }

    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('알람 삭제'),
        content: const Text('이 알람을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = await ref.read(alarmRepositoryProvider.future);
      await repo.delete(widget.alarmId!);
      if (mounted) context.pop();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaleFactor = settings.fontScaleFactor;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                      '알람 설정',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20 * scaleFactor,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _save,
                    child: Text(
                      '저장',
                      style: TextStyle(
                        fontSize: 18 * scaleFactor,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Time picker group
                    _buildGroup(isDark, [
                      // AM/PM + Time
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _isPM = !_isPM),
                              child: Text(
                                _isPM ? '오후' : '오전',
                                style: TextStyle(
                                  fontSize: 24 * scaleFactor,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: TextEditingController(
                                  text: _hour.toString().padLeft(2, '0'),
                                ),
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  fontSize: 48 * scaleFactor,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                                decoration: const InputDecoration(border: InputBorder.none),
                                onChanged: (v) {
                                  final val = int.tryParse(v);
                                  if (val != null && val >= 1 && val <= 12) {
                                    _hour = val;
                                  }
                                },
                              ),
                            ),
                            Text(
                              ':',
                              style: TextStyle(
                                fontSize: 48 * scaleFactor,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: TextEditingController(
                                  text: _minute.toString().padLeft(2, '0'),
                                ),
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  fontSize: 48 * scaleFactor,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                                decoration: const InputDecoration(border: InputBorder.none),
                                onChanged: (v) {
                                  final val = int.tryParse(v);
                                  if (val != null && val >= 0 && val <= 59) {
                                    _minute = val;
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Day selector
                      Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(7, (i) {
                            final isSelected = _selectedDays.contains(i);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedDays.remove(i);
                                  } else {
                                    _selectedDays.add(i);
                                  }
                                });
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : const Color(0xFFDDDDDD)),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    Alarm.dayNames[i],
                                    style: TextStyle(
                                      fontSize: 14 * scaleFactor,
                                      color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Name & Sound group
                    _buildGroup(isDark, [
                      _buildSettingRow(
                        '알람 이름',
                        SizedBox(
                          width: 150,
                          child: TextField(
                            controller: _nameController,
                            maxLength: AppConstants.maxAlarmNameLength,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              counterText: '',
                              hintText: '최대 12자',
                            ),
                            style: TextStyle(fontSize: 16 * scaleFactor),
                          ),
                        ),
                        scaleFactor,
                        isDark,
                      ),
                      Divider(color: isDark ? AppColors.darkBorder : AppColors.border, height: 1),
                      _buildSettingRow(
                        '사운드',
                        DropdownButton<String>(
                          value: _soundName,
                          underline: const SizedBox(),
                          items: _sounds.map((s) => DropdownMenuItem(
                                value: s.$1,
                                child: Text(s.$2, style: TextStyle(fontSize: 16 * scaleFactor)),
                              )).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _soundName = v);
                          },
                        ),
                        scaleFactor,
                        isDark,
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Quiz group
                    _buildGroup(isDark, [
                      _buildSettingRow(
                        '단어 퀴즈 활성화',
                        GestureDetector(
                          onTap: () => setState(() => _isQuizEnabled = !_isQuizEnabled),
                          child: Container(
                            width: 50,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _isQuizEnabled ? AppColors.primary : AppColors.disabled,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 200),
                              alignment: _isQuizEnabled
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
                      if (_isQuizEnabled) ...[
                        Divider(color: isDark ? AppColors.darkBorder : AppColors.border, height: 1),
                        _buildSettingRow(
                          '단어장 선택',
                          DropdownButton<int?>(
                            value: _selectedWordbookId,
                            underline: const SizedBox(),
                            hint: Text('선택', style: TextStyle(fontSize: 16 * scaleFactor)),
                            items: _wordbooks.map((wb) => DropdownMenuItem(
                                  value: wb.id,
                                  child: Text(wb.name, style: TextStyle(fontSize: 16 * scaleFactor)),
                                )).toList(),
                            onChanged: (v) => setState(() => _selectedWordbookId = v),
                          ),
                          scaleFactor,
                          isDark,
                        ),
                        Divider(color: isDark ? AppColors.darkBorder : AppColors.border, height: 1),
                        _buildSettingRow(
                          '맞춰야 할 단어 수',
                          DropdownButton<int>(
                            value: _quizWordCount,
                            underline: const SizedBox(),
                            items: [1, 3, 5, 10].map((v) => DropdownMenuItem(
                                  value: v,
                                  child: Text('$v개', style: TextStyle(fontSize: 16 * scaleFactor)),
                                )).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _quizWordCount = v);
                            },
                          ),
                          scaleFactor,
                          isDark,
                        ),
                      ],
                    ]),

                    if (widget.alarmId != null) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _delete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            '알람 삭제',
                            style: TextStyle(
                              fontSize: 16 * scaleFactor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
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
          Text(
            label,
            style: TextStyle(
              fontSize: 16 * scaleFactor,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          control,
        ],
      ),
    );
  }
}
