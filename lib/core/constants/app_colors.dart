import 'package:flutter/material.dart';

/// ألوان منصة «كتبي» (Kottby).
///
/// تم تحديثها لتطابق هوية المنصة:
/// - الأساسي: تركوازي `#08787a`.
/// - الثانوي: برتقالي `#ff8c00` (يُستخدم بشكل محدود للعناصر المحددة/المهمة).
class AppColors {
  AppColors._();

  /// اللون الأساسي (تركوازي) — يُستخدم في البانر وشريط التنقل والعناصر التفاعلية.
  static const Color primary = Color(0xff08787a);

  /// تدرّج أغمق قليلاً من الأساسي (يُستخدم في خلفية البانر المتدرجة).
  static const Color primaryDark = Color(0xff055f61);

  /// تدرّج أفتح قليلاً من الأساسي (يُستخدم في خلفية البانر المتدرجة).
  static const Color primaryLight = Color(0xff0a9a9d);

  /// اللون الثانوي (برتقالي) — يُستخدم بشكل محدود للعناصر المحددة أو المهمة.
  static const Color secondary = Color(0xffff8c00);

  /// لون خلفية التطبيق العام (Scaffold Background).
  static const Color scaffoldBackground = Color(0xfff6f7fb);

  /// اللون الرمادي المستخدم للنصوص الثانوية والحدود.
  static const MaterialColor tertiary = Colors.grey;

  /// لون نصوص العناوين الداكنة.
  static const Color textDark = Color(0xff2d3748);

  /// تدرج لوني للون الأساسي (يستخدم في `MaterialColor`).
  static Map<int, Color> primarySwatch = <int, Color>{
    50: primary.withValues(alpha: 0.1),
    100: primary.withValues(alpha: 0.2),
    200: primary.withValues(alpha: 0.3),
    300: primary.withValues(alpha: 0.4),
    400: primary.withValues(alpha: 0.5),
    500: primary.withValues(alpha: 0.6),
    600: primary.withValues(alpha: 0.7),
    700: primary.withValues(alpha: 0.8),
    800: primary.withValues(alpha: 0.9),
    900: primary,
  };
}
