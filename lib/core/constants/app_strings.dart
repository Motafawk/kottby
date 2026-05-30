/// روابط ونصوص ثابتة على مستوى التطبيق.
class AppStrings {
  AppStrings._();

  /// رابط الموقع الرئيسي.
  static const String siteUrl = 'https://www.kottby.net/';

  /// رابط صفحة «اتصل بنا» في الموقع.
  static const String contactUsUrl = 'https://www.kottby.net/contact-us/';

  /// رابط قناة/حساب «كتبي» على تيلجرام.
  static const String telegramUrl = 'https://t.me/kottbynet';

  /// رابط التطبيق على Google Play.
  static const String androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.mhma.kottby';

  /// رابط التطبيق على App Store (يستخدم في حالة المشاركة على iOS فقط).
  static const String iosStoreUrl = '';

  /// اسم الخط الافتراضي للتطبيق.
  static const String fontFamily = 'Almaria';

  /// اسم تطبيق الواجهة الرئيسي.
  static const String appName = 'كتبي';

  /// مجلد التنزيلات داخل دليل التطبيق (لا يتطلب صلاحيات).
  static const String downloadsFolderName = 'kottby_downloads';

  /// اسم ملف قاعدة البيانات (نفس اسم الإصدار القديم لتسهيل الترقية).
  static const String dbFileName = 'db.db';
}
