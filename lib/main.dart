import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/theme/app_theme.dart';
import 'core/network/http_overrides.dart';
import 'core/services/notifications_service.dart';
import 'core/utils/jiffy_init.dart';
import 'routes/app_router.dart';

/// نقطة بداية تطبيق منهجي v5.
///
/// - بدون Firebase / بدون FCM (حسب طلب المستخدم).
/// - يدعم منبه المذاكرة عبر `awesome_notifications` (foreground/background/terminated).
/// - دعم اللغة العربية + RTL.
/// - شريط الحالة وشريط التنقل السفلي شفافان (الـAppBar الأخضر يمتد خلفهما).
Future<void> main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();

  // شريط حالة وتنقل شفّافان (يمتد لون الـAppBar خلفهما).
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // تهيئة Jiffy على العربية.
  await JiffyInit.setup();

  // تهيئة قنوات awesome_notifications قبل تشغيل التطبيق.
  await NotificationsService.init();

  runApp(const ProviderScope(child: MyApp()));

  // تسجيل المستمعين بعد runApp (المنصوص عليه في وثائق awesome_notifications).
  await NotificationsService.registerListeners();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'كتبي',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: AppRouter.router,
      // اللغة العربية + RTL
      locale: const Locale('ar'),
      supportedLocales: const <Locale>[Locale('ar')],
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
    );
  }
}
