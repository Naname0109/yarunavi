import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';

import 'providers/ui_mode_provider.dart';
import 'providers/settings_provider.dart';
import 'theme/app_theme.dart';
import 'screens/ai_history_screen.dart';
import 'screens/ai_result_screen.dart';
import 'screens/category_manage_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/store_screen.dart';
import 'screens/v2/ai_result_screen.dart';
import 'screens/v2/archive_screen.dart';
import 'screens/v2/home_shell.dart';
import 'screens/v2/onboarding_screen.dart';
import 'screens/v2/premium_screen.dart';
import 'screens/v2/stats_screen.dart';
import 'screens/v2/task_detail_screen.dart';

Widget _slideFromRight(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
    child: child,
  );
}

/// useNewUi の値で v1/v2 のスクリーンを切り替えるユーティリティ。
class _V2Switch extends ConsumerWidget {
  const _V2Switch({required this.v1, required this.v2});
  final Widget Function() v1;
  final Widget Function() v2;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(useNewUiProvider) ? v2() : v1();
  }
}

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => _V2Switch(
        v1: () => const OnboardingScreen(),
        v2: () => const V2OnboardingScreen(),
      ),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) {
        final tab = int.tryParse(
                state.uri.queryParameters['tab'] ?? '') ??
            0;
        // オンボーディング完了直後など、初回タスク追加シートを自動で開く時に true
        final extras = state.extra;
        final openTaskForm =
            extras is Map && extras['openTaskForm'] == true;
        return _V2Switch(
          v1: () => HomeScreen(initialTab: tab),
          v2: () =>
              V2HomeShell(initialTab: tab, openTaskFormOnStart: openTaskForm),
        );
      },
    ),
    GoRoute(
      path: '/ai-result',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: _V2Switch(
          v1: () => const AiResultScreen(),
          v2: () => const V2AiResultScreen(),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/store',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: _V2Switch(
          v1: () => const StoreScreen(),
          v2: () => const V2PremiumScreen(),
        ),
        transitionsBuilder: _slideFromRight,
      ),
    ),
    GoRoute(
      path: '/stats',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const V2StatsScreen(),
        transitionsBuilder: _slideFromRight,
      ),
    ),
    GoRoute(
      path: '/task/:id',
      pageBuilder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? -1;
        return CustomTransitionPage(
          key: state.pageKey,
          child: V2TaskDetailScreen(taskId: id),
          transitionsBuilder: _slideFromRight,
        );
      },
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SettingsScreen(),
        transitionsBuilder: _slideFromRight,
      ),
    ),
    GoRoute(
      path: '/archive',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const V2ArchiveScreen(),
        transitionsBuilder: _slideFromRight,
      ),
    ),
    GoRoute(
      path: '/ai-history',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AiHistoryScreen(),
        transitionsBuilder: _slideFromRight,
      ),
    ),
    GoRoute(
      path: '/category-manage',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const CategoryManageScreen(),
        transitionsBuilder: _slideFromRight,
      ),
    ),
  ],
);

class YaruNaviApp extends ConsumerWidget {
  const YaruNaviApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'YaruNavi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      routerConfig: _router,
    );
  }
}
