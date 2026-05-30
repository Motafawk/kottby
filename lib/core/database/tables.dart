/// تعريفات جداول قاعدة بيانات SQLite.
///
/// نُبقي اسم جدول `favorites` ومخططه مطابقَين للإصدار القديم
/// لتسهيل الترقية من v4 → v5 دون فقد بيانات المستخدم.
class DbTables {
  DbTables._();

  /// جدول المفضلة (مطابق للإصدار القديم).
  static const String createFavorites = '''
    CREATE TABLE IF NOT EXISTS favorites(
      url        TEXT PRIMARY KEY,
      title      TEXT,
      created_at TEXT
    );
  ''';

  /// جدول التنزيلات (جديد في الإصدار 5، يحلّ محل قاعدة `flutter_downloader`).
  ///
  /// الحالة `status` تأخذ قيمة من: pending | running | completed | failed | canceled.
  static const String createDownloads = '''
    CREATE TABLE IF NOT EXISTS downloads(
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      url         TEXT NOT NULL,
      file_name   TEXT NOT NULL,
      saved_path  TEXT NOT NULL,
      size_bytes  INTEGER DEFAULT 0,
      status      TEXT DEFAULT 'pending',
      progress    INTEGER DEFAULT 0,
      created_at  TEXT NOT NULL
    );
  ''';

  /// جدول مواعيد المذاكرة (أعيد تفعيله بنفس إعداد الإصدار القديم).
  ///
  /// `startID` و `endID` تخزّن معرّفّي الإشعارين المجدولين في awesome_notifications
  /// لنتمكّن من إلغائهما عند حذف الموعد.
  static const String createStudyTimers = '''
    CREATE TABLE IF NOT EXISTS studyTimers(
      title       TEXT,
      subject     TEXT,
      date        TEXT,
      startAt     TEXT,
      endAt       TEXT,
      startID     INTEGER,
      endID       INTEGER,
      created_at  TEXT PRIMARY KEY
    );
  ''';

  static const String tableFavorites = 'favorites';
  static const String tableDownloads = 'downloads';
  static const String tableStudyTimers = 'studyTimers';
}
