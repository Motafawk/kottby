import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'bottom_nav_bar.dart';

/// الهيكل العام (Shell) الذي يحمل شريط التنقل السفلي الثابت.
///
/// يبقى شريط التذييل ثابتاً بينما يتغيّر محتوى الصفحة فقط عبر
/// [StatefulNavigationShell] (كل تبويب يحتفظ بحالته الخاصة).
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  /// غلاف التنقّل الذي يوفّره `StatefulShellRoute`.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavBar(navigationShell: navigationShell),
    );
  }
}
