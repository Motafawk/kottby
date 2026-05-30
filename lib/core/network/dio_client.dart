import 'package:dio/dio.dart';

/// عميل Dio موحّد يستخدم لتنزيل الملفات وأي طلبات HTTP في التطبيق.
///
/// نُعطي مهلة طويلة نسبياً لتنزيل الملفات الكبيرة (PDF) من الموقع.
class DioClient {
  DioClient._();

  static Dio? _instance;

  static Dio get instance {
    _instance ??= Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 10),
        followRedirects: true,
        validateStatus: (int? status) =>
            status != null && status >= 200 && status < 400,
      ),
    );
    return _instance!;
  }
}
