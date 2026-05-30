import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_strings.dart';
import '../core/widgets/scaffold_with_nav_bar.dart';
import '../features/browser/presentation/screens/browser_screen.dart';
import '../features/downloads/presentation/screens/downloads_screen.dart';
import '../features/favorites/presentation/screens/favorites_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/study_timer/presentation/screens/study_timer_form_screen.dart';
import '../features/study_timer/presentation/screens/study_timers_list_screen.dart';

/// تعريف مسارات التطبيق باستخدام `go_router`.
///
/// نستخدم [StatefulShellRoute.indexedStack] لإبقاء شريط التنقل السفلي ثابتاً
/// بينما يتغيّر محتوى الصفحة فقط، مع احتفاظ كل تبويب بحالته (scroll/route).
class AppRouter {
  AppRouter._();

  /// مفتاح الـNavigator الجذري (للصفحات التي تُفتح فوق التذييل بملء الشاشة).
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    navigatorKey: _rootNavigatorKey,
    routes: <RouteBase>[
      // صفحة المتصفح (WebView) تُفتح بملء الشاشة فوق شريط التنقل.
      GoRoute(
        path: '/browser',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, GoRouterState state) {
          final String url =
              state.uri.queryParameters['url'] ?? AppStrings.siteUrl;
          return BrowserScreen(initialUrl: url);
        },
      ),

      // عرض المفضلة بملء الشاشة (بدون شريط تنقل، مع زر تراجع) — يُفتح من المتصفح.
      GoRoute(
        path: '/favorites-view',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const FavoritesScreen(),
      ),

      // عرض التنزيلات بملء الشاشة (بدون شريط تنقل، مع زر تراجع) — يُفتح من المتصفح.
      GoRoute(
        path: '/downloads-view',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const DownloadsScreen(),
      ),

      // الهيكل الثابت: شريط تنقل سفلي ثابت + أربعة تبويبات بحالة مستقلة.
      StatefulShellRoute.indexedStack(
        builder: (_, _, StatefulNavigationShell navigationShell) =>
            ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          // 0 - الرئيسية
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
            ],
          ),
          // 1 - المفضلة
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/favorites',
                builder: (_, _) => const FavoritesScreen(),
              ),
            ],
          ),
          // 2 - التنزيلات
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/downloads',
                builder: (_, _) => const DownloadsScreen(),
              ),
            ],
          ),
          // 3 - التذكير (المنبه)
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/study-timer',
                builder: (_, _) => const StudyTimersListScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (_, _) => const StudyTimerFormScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
