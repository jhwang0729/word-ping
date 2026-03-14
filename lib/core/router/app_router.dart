import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../features/home/home_screen.dart';
import '../../features/word_detail/word_detail_screen.dart';
import '../../features/wordbook/wordbook_list_screen.dart';
import '../../features/flashcard/flashcard_screen.dart';
import '../../features/quiz/quiz_screen.dart';
import '../../features/quiz/quiz_result_screen.dart';
import '../../features/alarm/alarm_list_screen.dart';
import '../../features/alarm/alarm_setting_screen.dart';
import '../../features/alarm/alarm_ring_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../constants/app_colors.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _shellNavigatorWordbookKey = GlobalKey<NavigatorState>(debugLabel: 'wordbook');
final _shellNavigatorAlarmKey = GlobalKey<NavigatorState>(debugLabel: 'alarm');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'word/:word',
                    builder: (context, state) => WordDetailScreen(
                      word: state.pathParameters['word']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorWordbookKey,
            routes: [
              GoRoute(
                path: '/wordbooks',
                builder: (context, state) => const WordbookListScreen(),
                routes: [
                  GoRoute(
                    path: ':id/flashcard',
                    builder: (context, state) => FlashcardScreen(
                      wordbookId: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                  GoRoute(
                    path: ':id/quiz',
                    builder: (context, state) => QuizScreen(
                      wordbookId: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                  GoRoute(
                    path: ':id/quiz/result',
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>;
                      return QuizResultScreen(
                        correctCount: extra['correctCount'] as int,
                        totalCount: extra['totalCount'] as int,
                        incorrectWords: extra['incorrectWords'] as List<Map<String, String>>,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorAlarmKey,
            routes: [
              GoRoute(
                path: '/alarms',
                builder: (context, state) => const AlarmListScreen(),
              ),
            ],
          ),
        ],
      ),
      // Independent routes (no bottom nav)
      GoRoute(
        path: '/alarms/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AlarmSettingScreen(),
      ),
      GoRoute(
        path: '/alarms/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => AlarmSettingScreen(
          alarmId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/alarms/:id/ring',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => AlarmRingScreen(
          alarmId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.surface;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
          ),
        ),
        height: 70 + MediaQuery.of(context).padding.bottom,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: FontAwesomeIcons.book,
              label: '단어장',
              isActive: navigationShell.currentIndex == 1,
              onTap: () => navigationShell.goBranch(1),
            ),
            _CenterNavButton(
              isActive: navigationShell.currentIndex == 0,
              onTap: () => navigationShell.goBranch(0),
            ),
            _NavItem(
              icon: FontAwesomeIcons.bell,
              label: '알람',
              isActive: navigationShell.currentIndex == 2,
              onTap: () => navigationShell.goBranch(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textHint;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 24, color: color),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterNavButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _CenterNavButton({
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: FaIcon(
              FontAwesomeIcons.magnifyingGlass,
              size: 28,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
