import 'dart:io';

import 'package:share_plus/share_plus.dart';

import '../constants/app_strings.dart';

/// خدمة مشاركة عامة (نص + ملفات) عبر `share_plus`.
class ShareService {
  ShareService._();

  /// مشاركة رابط التطبيق على Google Play (يستخدم في زر «مشاركة التطبيق»).
  static Future<void> shareApp() async {
    await SharePlus.instance.share(
      ShareParams(text: AppStrings.androidStoreUrl),
    );
  }

  /// مشاركة رابط الموقع ورابط متجر التطبيقات بنفس صياغة الإصدار القديم.
  static Future<void> shareSiteAndStore() async {
    final String storeLabel = Platform.isIOS ? 'لل IOS' : 'للاندرويد';
    final String storeUrl = Platform.isIOS
        ? AppStrings.iosStoreUrl
        : AppStrings.androidStoreUrl;
    final String text =
        '''
              رابط موقع منهجي
              ${AppStrings.siteUrl}
              رابط التطبيق $storeLabel
              $storeUrl''';
    await SharePlus.instance.share(ShareParams(text: text));
  }

  /// مشاركة عنوان ورابط صفحة معينة من الـ WebView مع روابط المتجر.
  static Future<void> sharePage({
    required String title,
    required String url,
  }) async {
    final String storeLabel = Platform.isIOS ? 'لل IOS' : 'للاندرويد';
    final String storeUrl = Platform.isIOS
        ? AppStrings.iosStoreUrl
        : AppStrings.androidStoreUrl;
    final String text =
        '''
              $title
              $url
              رابط موقع منهجي
              ${AppStrings.siteUrl}
              رابط التطبيق $storeLabel
              $storeUrl''';
    await SharePlus.instance.share(ShareParams(text: text));
  }

  /// مشاركة ملف من مساره (يستخدم في شاشة التنزيلات).
  static Future<void> shareFile(String path) async {
    await SharePlus.instance.share(ShareParams(files: <XFile>[XFile(path)]));
  }
}
