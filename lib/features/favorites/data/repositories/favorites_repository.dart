import '../../../../core/database/db_helper.dart';
import '../../../../core/database/tables.dart';
import '../models/favorite_model.dart';

/// مستودع المفضلة: يتعامل مع جدول `favorites` في SQLite.
class FavoritesRepository {
  FavoritesRepository(this._db);

  final DbHelper _db;

  /// جلب كل العناصر المفضلة مرتبة من الأحدث إلى الأقدم.
  /// [search] للبحث في العنوان أو الرابط (اختياري).
  Future<List<FavoriteModel>> getAll({String? search}) async {
    String? where;
    List<Object?>? whereArgs;
    if (search != null && search.isNotEmpty) {
      where = 'title LIKE ? OR url LIKE ?';
      whereArgs = <Object?>['%$search%', '%$search%'];
    }
    final List<Map<String, Object?>> rows = await _db.selectAll(
      DbTables.tableFavorites,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    return rows.map(FavoriteModel.fromMap).toList(growable: false);
  }

  /// التحقق من وجود رابط في المفضلة.
  Future<bool> isFavorite(String url) async {
    final int count = await _db.count(
      DbTables.tableFavorites,
      where: 'url = ?',
      whereArgs: <Object?>[url],
    );
    return count > 0;
  }

  /// عدد عناصر المفضلة (لشارة العدد على أيقونة المفضلة).
  Future<int> count() async {
    return _db.count(DbTables.tableFavorites);
  }

  /// إضافة عنصر للمفضلة (insert with replace on conflict).
  Future<void> add({required String url, required String title}) async {
    final FavoriteModel item = FavoriteModel(
      url: url,
      title: title,
      createdAt: DateTime.now().toIso8601String(),
    );
    await _db.insert(DbTables.tableFavorites, item.toMap());
  }

  /// تبديل حالة المفضلة (إضافة/حذف). تُرجع true إذا أصبحت مفضّلة.
  Future<bool> toggle({required String url, required String title}) async {
    final bool exists = await isFavorite(url);
    if (exists) {
      await remove(url);
      return false;
    }
    await add(url: url, title: title);
    return true;
  }

  /// حذف عنصر واحد من المفضلة.
  Future<void> remove(String url) async {
    await _db.delete(
      DbTables.tableFavorites,
      where: 'url = ?',
      whereArgs: <Object?>[url],
    );
  }

  /// حذف جميع عناصر المفضلة.
  Future<void> removeAll() async {
    await _db.delete(DbTables.tableFavorites);
  }
}
