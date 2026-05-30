import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../routes/app_router.dart';

/// خدمة إدارة الإشعارات المحلية عبر `awesome_notifications`.
///
/// المهام:
/// - تهيئة القناة الافتراضية (`basic_channel`) واستخدام أيقونة `ic_notify`.
/// - طلب صلاحية الإشعار من المستخدم عند الحاجة.
/// - جدولة منبهات بدء/انتهاء المذاكرة باستخدام `NotificationCalendar`.
/// - معالجة الضغط على الإشعار وفتح شاشة المنبه.
///
/// الإشعار يعمل في الحالات الثلاث (foreground/background/terminated)
/// لأن awesome_notifications يستخدم `AlarmManager` على أندرويد.
class NotificationsService {
  NotificationsService._();

  /// مفتاح القناة (يستخدم في كل الإشعارات).
  static const String channelKey = 'basic_channel';
  static const String _askedPermissionPrefsKey = 'notifications_permission_asked';

  /// تهيئة الحزمة. تُستدعى مرة واحدة في `main()` قبل `runApp`.
  static Future<void> init() async {
    await AwesomeNotifications().initialize(
      // مهم: المسار يطابق ملف `android/app/src/main/res/drawable/ic_notify.png`.
      'resource://drawable/ic_notify',
      <NotificationChannel>[
        NotificationChannel(
          channelKey: channelKey,
          channelName: 'منبه المذاكرة',
          channelDescription: 'إشعارات تذكير ببدء وانتهاء وقت المذاكرة',
          defaultColor: const Color(0xff009345),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        ),
      ],
      debug: false,
    );
  }

  /// تسجيل المستمعين لأحداث الإشعار. تُستدعى بعد `runApp`.
  static Future<void> registerListeners() async {
    await AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );
  }

  /// طلب صلاحية الإشعارات (Android 13+) من المستخدم إن لم تكن ممنوحة.
  /// تُرجع `true` إذا أصبحت ممنوحة.
  static Future<bool> ensureAllowed() async {
    final bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (isAllowed) return true;
    return AwesomeNotifications().requestPermissionToSendNotifications();
  }

  /// طلب الصلاحية مرة واحدة (لإظهار نافذة Android 13+ عند أول تشغيل).
  ///
  /// - على Android < 13 لن تظهر نافذة نظام (لا يوجد runtime permission) وبالتالي ستُحفظ العلامة بدون إزعاج.
  /// - إذا رفض المستخدم، لن نعيد السؤال تلقائياً في كل تشغيل.
  static Future<bool> ensureAllowedOnce() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool alreadyAsked = prefs.getBool(_askedPermissionPrefsKey) ?? false;
    if (alreadyAsked) {
      return AwesomeNotifications().isNotificationAllowed();
    }

    final bool allowed = await ensureAllowed();
    await prefs.setBool(_askedPermissionPrefsKey, true);
    return allowed;
  }

  /// جدولة إشعار في تاريخ ووقت محددين.
  ///
  /// - [id]: معرف فريد للإشعار (يُحفظ في قاعدة البيانات لإمكانية الإلغاء لاحقاً).
  /// - [title]/[body]: عنوان ومحتوى الإشعار.
  /// - [year/month/day/hour/minute]: لحظة الإطلاق.
  static Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: channelKey,
        title: title,
        body: body,
        wakeUpScreen: true,
        category: NotificationCategory.Reminder,
        notificationLayout: NotificationLayout.Default,
        payload: const <String, String>{'target': 'study_timer'},
      ),
      schedule: NotificationCalendar(
        year: year,
        month: month,
        day: day,
        hour: hour,
        minute: minute,
        second: 0,
        millisecond: 0,
        // IMPORTANT:
        // preciseAlarm=true يحتاج غالباً إلى SCHEDULE_EXACT_ALARM وقد يسبب تعقيدات في Google Play.
        // نستخدم inexact alarm افتراضياً لتفادي مشاكل الرفع، مع احتمال تأخير بسيط على بعض الأجهزة.
        preciseAlarm: false,
        allowWhileIdle: true,
      ),
    );
  }

  /// إلغاء إشعار مجدوَل بمعرفه.
  static Future<void> cancelById(int id) async {
    await AwesomeNotifications().cancelSchedule(id);
  }

  /// إلغاء جميع الإشعارات المجدولة (يستخدم عند حذف كل المنبهات).
  static Future<void> cancelAll() async {
    await AwesomeNotifications().cancelAllSchedules();
  }

  // ----------------------------------------------------------------
  // مستمعو الأحداث (لازم أن يكونوا static + vm:entry-point)
  // ----------------------------------------------------------------

  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification _) async {/* لا حاجة لمعالجة الإنشاء */}

  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification _) async {/* لا حاجة لمعالجة العرض */}

  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction _) async {/* لا حاجة لمعالجة الإغلاق */}

  /// عند ضغط المستخدم على الإشعار: نفتح شاشة المنبه.
  ///
  /// نستخدم `AppRouter.router` (GoRouter العام) لأن السياق غير متاح هنا
  /// في حالات background/terminated.
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    final Map<String, String?>? payload = receivedAction.payload;
    if (payload == null) return;
    final String? target = payload['target'];
    if (target == 'study_timer') {
      // لو التطبيق غير مفتوح، الـ AwesomeNotifications يعيد فتحه ثم يستدعي هذا الـ callback،
      // عندها سيكون GoRouter جاهزاً.
      AppRouter.router.go('/study-timer');
    }
  }
}
