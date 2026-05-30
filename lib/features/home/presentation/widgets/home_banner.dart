import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

/// البانر العلوي في الصفحة الرئيسية.
///
/// خلفية متدرّجة باللون الأساسي `#08787a` مع صورة بانر شفافة فوقها،
/// وبداخله شعار «كتبي» الأبيض + اسم التطبيق + وصف مختصر للمنصة.
/// عند الضغط على البانر تُفتح صفحة الويب على رابط الموقع الرئيسي.
class HomeBanner extends StatelessWidget {
  const HomeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;

    return GestureDetector(
      onTap: () => context.push(
        '/browser?url=${Uri.encodeComponent(AppStrings.siteUrl)}',
      ),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: <Color>[
              AppColors.primaryLight,
              AppColors.primary,
              AppColors.primaryDark,
            ],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(22),
            bottomRight: Radius.circular(22),
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Color(0x3308787a),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: <Widget>[
            // صورة البانر كطبقة خلفية خفيفة فوق التدرّج.
            Positioned.fill(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
                child: Opacity(
                  opacity: 0.18,
                  child: Image.asset(
                    AppAssets.banner,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: topPadding + 24,
                bottom: 28,
                left: 20,
                right: 20,
              ),
              child: Column(
                children: <Widget>[
                  // الشعار الأبيض.
                  // Image.asset(
                  //   AppAssets.iconWhite,
                  //   height: 84,
                  //   errorBuilder: (_, _, _) => const SizedBox(height: 84),
                  // ),
                  const SizedBox(height: 12),
                  // اسم التطبيق.
                  const Text(
                    'تطبيق كتبي',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // الوصف.
                  Text(
                    'حلول اسئلة المناهج والكتب المدرسية وحلول التمارين وكل ما يطلبه '
                    'المعلمين والمعلمات لكافة المراحل الدراسية السعودية بشكل مباشر '
                    'ومجاني بالكامل.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 13.5,
                      height: 1.9,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
