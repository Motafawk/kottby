import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../constants/app_strings.dart';
import 'tables.dart';

/// مساعد التعامل مع قاعدة بيانات SQLite (Singleton).
///
/// يدير فتح القاعدة وإنشاء الجداول وترقيتها، بالإضافة إلى توفير
/// عمليات CRUD أساسية تستخدمها مستودعات الميزات (`favorites`, `downloads`).
class DbHelper {
  DbHelper._internal();
  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;

  static Database? _db;

  /// إصدار قاعدة البيانات.
  /// - الإصدار 1: الإصدار القديم (favorites + notifications + studyTimers + tmp).
  /// - الإصدار 2: جدول `downloads` الجديد.
  /// - الإصدار 3: إعادة تفعيل جدول `studyTimers` (منبه المذاكرة).
  ///
  /// عند الترقية من v1 إلى v3 يوجد الجدول فعلاً (من الإصدار القديم) فلا نفعل شيئاً؛
  /// وعند الترقية من v2 إلى v3 ننشئ جدول `studyTimers` الجديد.
  static const int _kDbVersion = 3;

  /// فتح قاعدة البيانات وإنشائها أو ترقيتها عند الحاجة.
  Future<Database> open() async {
    if (_db != null) return _db!;
    final String dbPath = p.join(
      await getDatabasesPath(),
      AppStrings.dbFileName,
    );
    _db = await openDatabase(
      dbPath,
      version: _kDbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    // إنشاء جداول الإصدار الحالي عند أول تثبيت للتطبيق.
    await db.execute(DbTables.createFavorites);
    await db.execute(DbTables.createDownloads);
    await db.execute(DbTables.createStudyTimers);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // v1→v2: إضافة جدول التنزيلات (لم يكن في الإصدار القديم).
    if (oldVersion < 2) {
      await db.execute(DbTables.createDownloads);
    }
    // v2→v3: إضافة/تأكيد وجود جدول منبه المذاكرة.
    if (oldVersion < 3) {
      await db.execute(DbTables.createStudyTimers);
    }
  }

  /// إغلاق قاعدة البيانات (يستخدم نادراً، عند تسجيل الخروج مثلاً).
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  // ----------------------------------------------------------------
  // عمليات CRUD المساعدة (تستخدمها المستودعات)
  // ----------------------------------------------------------------

  Future<List<Map<String, Object?>>> selectAll(
    String table, {
    String? orderBy,
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final Database db = await open();
    return db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  Future<int> insert(String table, Map<String, Object?> values) async {
    final Database db = await open();
    return db.insert(
      table,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> update(
    String table,
    Map<String, Object?> values, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final Database db = await open();
    return db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final Database db = await open();
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<int> count(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final Database db = await open();
    final String wherePart = (where == null || where.isEmpty)
        ? ''
        : ' WHERE $where';
    final List<Map<String, Object?>> result = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM $table$wherePart',
      whereArgs,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
