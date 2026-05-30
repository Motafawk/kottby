import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../features/downloads/presentation/providers/downloads_providers.dart';
import '../../features/favorites/presentation/providers/favorites_providers.dart';
import '../constants/app_assets.dart';
import '../constants/app_colors.dart';
import '../services/share_service.dart';
import 'favorite_badge.dart';

/// شريط التنقل السفلي الثابت لمنصة «كتبي».
///
/// يستخدم [StatefulNavigationShell] للتبديل بين التبويبات دون إعادة بناء
/// التذييل نفسه — يتغيّر محتوى الصفحة فقط ويبقى الشريط ثابتاً.
///
/// - خلفية تركوازية `#08787a`.
/// - العنصر المحدد: أيقونة برتقالية `#ff8c00` ونص أبيض.
/// - العناصر غير المحددة: أيقونة ونص أبيضان.
/// - التبويبات: الرئيسية، المفضلة، التنزيلات، التذكير. وزر «مشاركة التطبيق» إجراء فقط.
class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// التبديل إلى تبويب معيّن (وإعادته لجذره عند إعادة الضغط عليه).
  ///
  /// عند الانتقال إلى تبويب المفضلة أو التنزيلات نُعيد جلب البيانات من قاعدة
  /// البيانات لضمان ظهور أحدث العناصر (مثل ما تمت إضافته من شاشة المتصفح).
  void _goBranch(WidgetRef ref, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
    switch (index) {
      case 1:
        ref.read(favoritesListProvider.notifier).refresh();
      case 2:
        ref.read(downloadsListProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<int> count = ref.watch(favoritesCountProvider);
    final int favCount = count.value ?? 0;
    final int current = navigationShell.currentIndex;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _NavItem(
                icon: Image.asset(
                  AppAssets.navHome,
                  width: 22,
                  height: 22,
                  color: current == 0 ? AppColors.secondary : Colors.white,
                ),
                label: 'الرئيسية',
                selected: current == 0,
                onTap: () => _goBranch(ref, 0),
              ),
              _NavItem(
                icon: FaIcon(
                  FontAwesomeIcons.solidHeart,
                  size: 20,
                  color: current == 1 ? AppColors.secondary : Colors.white,
                ),
                label: 'المفضلة',
                selected: current == 1,
                badgeCount: favCount,
                onTap: () => _goBranch(ref, 1),
              ),
              _NavItem(
                icon: FaIcon(
                  FontAwesomeIcons.download,
                  size: 20,
                  color: current == 2 ? AppColors.secondary : Colors.white,
                ),
                label: 'التنزيلات',
                selected: current == 2,
                onTap: () => _goBranch(ref, 2),
              ),
              _NavItem(
                icon: FaIcon(
                  FontAwesomeIcons.solidBell,
                  size: 20,
                  color: current == 3 ? AppColors.secondary : Colors.white,
                ),
                label: 'التذكير',
                selected: current == 3,
                onTap: () => _goBranch(ref, 3),
              ),
              const _NavItem(
                icon: FaIcon(
                  FontAwesomeIcons.share,
                  size: 20,
                  color: Colors.white,
                ),
                label: 'مشاركة',
                selected: false,
                onTap: ShareService.shareApp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// عنصر داخل [BottomNavBar] يجمع أيقونة + نص + شارة عدد اختيارية.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final Widget icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FavoriteBadge(count: badgeCount, child: icon),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  color: Colors.white,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
