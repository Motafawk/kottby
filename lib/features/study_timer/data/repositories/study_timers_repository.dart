import 'dart:math';

import '../../../../core/database/db_helper.dart';
import '../../../../core/database/tables.dart';
import '../../../../core/services/notifications_service.dart';
import '../models/study_timer_model.dart';

/// مستودع منبهات المذاكرة: قاعدة بيانات + جدولة الإشعارات.
class StudyTimersRepository {
  StudyTimersRepository(this._db);

  final DbHelper _db;

  /// جلب كل المنبهات مرتبة تنازلياً حسب وقت الإنشاء.
  Future<List<StudyTimerModel>> getAll() async {
    final List<Map<String, Object?>> rows = await _db.selectAll(
      DbTables.tableStudyTimers,
      orderBy: 'created_at DESC',
    );
    return rows.map(StudyTimerModel.fromMap).toList(growable: false);
  }

  /// إضافة منبه جديد + جدولة إشعارَي البدء والانتهاء.
  ///
  /// يتطلب أن يكون [date] هو يوم المنبه و [startAt]/[endAt] أوقاته، حيث
  /// تكون الـ DateTime المركَّبة من (date + startAt) في المستقبل.
  Future<StudyTimerModel> add({
    required String title,
    required DateTime date,
    required ({int hour, int minute, String formatted}) start,
    required ({int hour, int minute, String formatted}) end,
  }) async {
    final Random rng = Random();
    final int startId = rng.nextInt(1 << 30);
    final int endId = rng.nextInt(1 << 30);

    // جدولة إشعار البدء
    await NotificationsService.scheduleAt(
      id: startId,
      title: 'حان وقت المذاكرة',
      body: title,
      year: date.year,
      month: date.month,
      day: date.day,
      hour: start.hour,
      minute: start.minute,
    );

    // جدولة إشعار الانتهاء
    await NotificationsService.scheduleAt(
      id: endId,
      title: 'انتهى وقت المذاكرة',
      body: title,
      year: date.year,
      month: date.month,
      day: date.day,
      hour: end.hour,
      minute: end.minute,
    );

    final StudyTimerModel model = StudyTimerModel(
      title: title,
      subject: 'Study',
      date: date.toIso8601String(),
      startAt: start.formatted,
      endAt: end.formatted,
      startId: startId,
      endId: endId,
      createdAt: DateTime.now().toIso8601String(),
    );

    await _db.insert(DbTables.tableStudyTimers, model.toMap());
    return model;
  }

  /// حذف منبه واحد + إلغاء إشعاراته.
  Future<void> remove(StudyTimerModel m) async {
    await NotificationsService.cancelById(m.startId);
    await NotificationsService.cancelById(m.endId);
    await _db.delete(
      DbTables.tableStudyTimers,
      where: 'created_at = ?',
      whereArgs: <Object?>[m.createdAt],
    );
  }

  /// حذف جميع المنبهات + إلغاء كل الإشعارات المجدولة.
  Future<void> removeAll() async {
    await NotificationsService.cancelAll();
    await _db.delete(DbTables.tableStudyTimers);
  }
}
