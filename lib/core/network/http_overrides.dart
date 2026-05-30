import 'dart:io';

/// تجاوز فحص الشهادة (مأخوذ من الإصدار القديم `classes.dart`).
///
/// الهدف: السماح للموقع بالعمل حتى لو كانت الشهادة الذاتية أو منتهية الصلاحية،
/// حتى لا يتعطل تصفح المستخدم بسبب أخطاء SSL مؤقتة.
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
