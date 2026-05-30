import 'package:jiffy/jiffy.dart';

/// تهيئة Jiffy على اللغة العربية.
/// تُستدعى مرة واحدة في `main` بعد `WidgetsFlutterBinding.ensureInitialized()`.
class JiffyInit {
  JiffyInit._();

  static Future<void> setup() async {
    await Jiffy.setLocale('ar');
  }
}
