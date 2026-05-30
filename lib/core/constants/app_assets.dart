/// مسارات الصور والأصول المستخدمة في التطبيق.
class AppAssets {
  AppAssets._();

  static const String _imagesPath = 'assets/images';

  /// صورة خلفية البانر العلوي في الصفحة الرئيسية.
  static const String banner = '$_imagesPath/banner.png';

  /// شعار «كتبي» الأبيض (يُستخدم داخل البانر العلوي).
  static const String iconWhite = '$_imagesPath/icon_white.png';

  /// شعار «كتبي» (يستخدم عند الحاجة لخلفية فاتحة).
  static const String icon = '$_imagesPath/icon.png';

  /// أيقونة تُستخدم لعنصر «الرئيسية» في شريط التنقل السفلي.
  static const String navHome = '$_imagesPath/home.png';

  /// صور المراحل/الصفوف الدراسية (1.png إلى 12.png) داخل مجلد الصور.
  static String gradeImage(int gradeNum) => '$_imagesPath/$gradeNum.png';
}
