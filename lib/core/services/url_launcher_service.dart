import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// خدمة فتح الروابط الخارجية والاتصال والمراسلة.
///
/// نستبدل `fluttertoast` المستخدم في الإصدار القديم برسائل `SnackBar`
/// قياسية تظهر للمستخدم عند فشل فتح الرابط.
class UrlLauncherService {
  UrlLauncherService._();

  /// فتح رابط في المتصفح الخارجي.
  static Future<bool> openExternal(String url, {BuildContext? context}) async {
    Uri uri = Uri.parse(url.trim());
    if (uri.scheme.isEmpty) {
      // لو المستخدم أدخل رابط بدون scheme
      uri = Uri.parse('https://${url.trim()}');
    }

    try {
      final bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context != null && context.mounted) {
        _showError(context, 'تعذر فتح الرابط');
      }
      return ok;
    } catch (_) {
      if (context != null && context.mounted) {
        _showError(context, 'تعذر فتح الرابط');
      }
      return false;
    }
  }

  /// إجراء مكالمة هاتفية.
  static Future<bool> call(String phone) async {
    return launchUrl(Uri.parse('tel:$phone'));
  }

  /// إرسال SMS مع نص جاهز.
  static Future<bool> sms({required String phone, String message = ''}) async {
    return launchUrl(Uri.parse('sms:$phone?body=$message'));
  }

  /// إرسال بريد إلكتروني.
  static Future<bool> email({
    required String to,
    String subject = '',
    String body = '',
  }) async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: to,
      query: _encodeQueryParameters(<String, String>{
        if (subject.isNotEmpty) 'subject': subject,
        if (body.isNotEmpty) 'body': body,
      }),
    );
    return launchUrl(uri);
  }

  static String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  static void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
      ),
    );
  }
}
