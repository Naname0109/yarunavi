import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';

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

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) {
        final tab = int.tryParse(
                state.uri.queryParameters['tab'] ?? '') ??
            0;
        return HomeScreen(initialTab: tab);
      },
    ),
    GoRoute(
      path: '/ai-result',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AiResultScreen(),
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
        child: const StoreScreen(),
        transitionsBuilder: _slideFromRight,
      ),
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
