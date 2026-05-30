import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_strings.dart';

/// شريط العنوان الموحَّد المستوحى من الإصدار القديم.
///
/// عند الضغط على العنوان نعود إلى الشاشة الرئيسية (سلوك الإصدار القديم).
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.label = '',
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  final String label;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      title: GestureDetector(
        onTap: () => context.go('/'),
        child: Text(label.isNotEmpty ? label : AppStrings.appName),
      ),
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
