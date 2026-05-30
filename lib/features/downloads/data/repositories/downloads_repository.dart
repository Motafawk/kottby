import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/database/db_helper.dart';
import '../../../../core/database/tables.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/arabic_url_codec.dart';
import '../models/download_model.dart';

/// مستودع التنزيلات: يدمج Dio + sqflite + path_provider.
///
/// نحفظ الملفات في `getApplicationDocumentsDirectory()/mnhaji_downloads/`
/// لتجنّب الحاجة لطلب صلاحيات (يمكن الوصول إليها بدون أي permission).
class DownloadsRepository {
  DownloadsRepository(this._db);

  final DbHelper _db;

  /// عمليات تنزيل نشطة (كي نستطيع إلغاءها أو متابعة تقدمها).
  final Map<int, CancelToken> _activeTokens = <int, CancelToken>{};

  /// الحصول على مسار مجلد التنزيلات داخل دليل التطبيق.
  Future<Directory> _getDownloadsDir() async {
    final Directory base = await getApplicationDocumentsDirectory();
    final Directory dir = Directory(p.join(base.path, AppStrings.downloadsFolderName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// استخراج اسم الملف من URL (مع decode للأحرف العربية).
  String fileNameFromUrl(String url) {
    final String last = url.split('/').last;
    return ArabicUrlCodec.hexToArabic(last);
  }

  /// جلب كل التنزيلات (مع بحث اختياري على اسم الملف).
  Future<List<DownloadModel>> getAll({String? search}) async {
    String? where;
    List<Object?>? args;
    if (search != null && search.isNotEmpty) {
      where = 'file_name LIKE ?';
      args = <Object?>['%$search%'];
    }
    final List<Map<String, Object?>> rows = await _db.selectAll(
      DbTables.tableDownloads,
      where: where,
      whereArgs: args,
      orderBy: 'datetime(created_at) DESC',
    );
    return rows.map(DownloadModel.fromMap).toList(growable: false);
  }

  /// التحقق إذا كان الرابط منزّلاً مسبقاً (status = completed).
  Future<DownloadModel?> getCompleted(String url) async {
    final List<Map<String, Object?>> rows = await _db.selectAll(
      DbTables.tableDownloads,
      where: "url = ? AND status = 'completed'",
      whereArgs: <Object?>[url],
    );
    if (rows.isEmpty) return null;
    return DownloadModel.fromMap(rows.first);
  }

  /// إدراج صف تنزيل جديد وإرجاع id.
  Future<int> _insert(DownloadModel model) async {
    return _db.insert(DbTables.tableDownloads, model.toMap());
  }

  /// تحديث تقدم/حالة/حجم تنزيل.
  Future<void> _updateRow(int id, Map<String, Object?> values) async {
    await _db.update(
      DbTables.tableDownloads,
      values,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// بدء تنزيل جديد (يُرجع DownloadModel بـ id جديد).
  ///
  /// إذا كان نفس الرابط قد اكتمل سابقاً والملف موجود → يُرجعه دون تنزيل جديد
  /// (ويُعلن via [onAlreadyExists]).
  Future<DownloadModel> startDownload(
    String url, {
    void Function(DownloadModel existing)? onAlreadyExists,
  }) async {
    // فحص ما إذا كان الملف منزّلاً مسبقاً
    final DownloadModel? existing = await getCompleted(url);
    if (existing != null && File(existing.savedPath).existsSync()) {
      onAlreadyExists?.call(existing);
      return existing;
    }

    final Directory dir = await _getDownloadsDir();
    final String fileName = fileNameFromUrl(url);
    final String savedPath = p.join(dir.path, fileName);

    // إنشاء صف بحالة pending
    final DownloadModel pending = DownloadModel(
      url: url,
      fileName: fileName,
      savedPath: savedPath,
      createdAt: DateTime.now().toIso8601String(),
      status: DownloadStatus.running,
    );
    final int id = await _insert(pending);
    final DownloadModel withId = pending.copyWith(id: id);

    // بدء التنزيل بشكل متزامن في الخلفية (لا ننتظره هنا)
    // ملاحظة: نُرجع النموذج فوراً ليتمكّن المستخدم من رؤية العنصر في القائمة.
    final CancelToken token = CancelToken();
    _activeTokens[id] = token;
    unawaited(_runDownload(withId, token));
    return withId;
  }

  Future<void> _runDownload(DownloadModel model, CancelToken token) async {
    final int id = model.id!;
    try {
      final Response<dynamic> response = await DioClient.instance.download(
        model.url,
        model.savedPath,
        cancelToken: token,
        onReceiveProgress: (int received, int total) {
          if (total > 0) {
            final int progress = ((received / total) * 100).round();
            _updateRow(id, <String, Object?>{
              'progress': progress,
              'size_bytes': total,
              'status': DownloadStatus.running.db,
            });
          }
        },
      );
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 400) {
        final File f = File(model.savedPath);
        final int size = f.existsSync() ? f.lengthSync() : 0;
        await _updateRow(id, <String, Object?>{
          'progress': 100,
          'size_bytes': size,
          'status': DownloadStatus.completed.db,
        });
      } else {
        await _updateRow(id, <String, Object?>{
          'status': DownloadStatus.failed.db,
        });
      }
    } catch (_) {
      // في حال فشل التنزيل أو إلغائه: نضع الحالة فشل ونحذف الملف الجزئي إن وُجد.
      await _updateRow(id, <String, Object?>{
        'status': DownloadStatus.failed.db,
      });
      try {
        final File f = File(model.savedPath);
        if (f.existsSync()) await f.delete();
      } catch (_) {/* تجاهل */}
    } finally {
      _activeTokens.remove(id);
    }
  }

  /// حذف عنصر واحد + ملفه على القرص.
  Future<void> remove(DownloadModel model) async {
    final CancelToken? token = _activeTokens[model.id];
    if (token != null && !token.isCancelled) {
      token.cancel('removed');
    }
    try {
      final File f = File(model.savedPath);
      if (f.existsSync()) await f.delete();
    } catch (_) {/* تجاهل */}
    if (model.id != null) {
      await _db.delete(
        DbTables.tableDownloads,
        where: 'id = ?',
        whereArgs: <Object?>[model.id],
      );
    }
  }

  /// حذف كل التنزيلات + ملفاتها.
  Future<void> removeAll() async {
    // إلغاء الجاري
    for (final CancelToken t in _activeTokens.values) {
      if (!t.isCancelled) t.cancel('removeAll');
    }
    _activeTokens.clear();
    // حذف الملفات الفعلية
    try {
      final Directory dir = await _getDownloadsDir();
      if (dir.existsSync()) {
        for (final FileSystemEntity e in dir.listSync()) {
          try {
            if (e is File) await e.delete();
          } catch (_) {}
        }
      }
    } catch (_) {/* تجاهل */}
    await _db.delete(DbTables.tableDownloads);
  }
}
