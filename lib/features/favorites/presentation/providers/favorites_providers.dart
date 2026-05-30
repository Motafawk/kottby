import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/db_helper.dart';
import '../../data/models/favorite_model.dart';
import '../../data/repositories/favorites_repository.dart';

/// مزوّد قاعدة البيانات (singleton مع DbHelper).
final Provider<DbHelper> dbHelperProvider =
    Provider<DbHelper>((Ref ref) => DbHelper());

/// مزوّد مستودع المفضلة.
final Provider<FavoritesRepository> favoritesRepositoryProvider =
    Provider<FavoritesRepository>(
  (Ref ref) => FavoritesRepository(ref.watch(dbHelperProvider)),
);

/// عدد عناصر المفضلة (يستخدم في الشارة على أيقونة المفضلة في القائمة الجانبية والـBottomNavBar).
final FutureProvider<int> favoritesCountProvider = FutureProvider<int>((Ref ref) async {
  // عند تغير قائمة المفضلة (أي مرة نحدّثها) سنُعيد قراءة العدد.
  ref.watch(favoritesListProvider);
  return ref.watch(favoritesRepositoryProvider).count();
});

/// قائمة المفضلة + إجراءات التحديث/الحذف.
class FavoritesListNotifier extends AsyncNotifier<List<FavoriteModel>> {
  String _search = '';

  String get search => _search;

  @override
  Future<List<FavoriteModel>> build() async {
    return ref.watch(favoritesRepositoryProvider).getAll(search: _search);
  }

  /// تحديث نص البحث وإعادة جلب القائمة.
  Future<void> setSearch(String q) async {
    _search = q;
    state = const AsyncValue<List<FavoriteModel>>.loading();
    state = await AsyncValue.guard<List<FavoriteModel>>(() async {
      return ref.read(favoritesRepositoryProvider).getAll(search: _search);
    });
  }

  /// إعادة تحميل من القاعدة (تستخدم لزر التحديث وأيضاً عند الإضافة من شاشة WebView).
  Future<void> refresh() async {
    state = const AsyncValue<List<FavoriteModel>>.loading();
    state = await AsyncValue.guard<List<FavoriteModel>>(() async {
      return ref.read(favoritesRepositoryProvider).getAll(search: _search);
    });
  }

  /// حذف عنصر واحد.
  Future<void> remove(String url) async {
    await ref.read(favoritesRepositoryProvider).remove(url);
    await refresh();
  }

  /// حذف جميع العناصر.
  Future<void> removeAll() async {
    await ref.read(favoritesRepositoryProvider).removeAll();
    await refresh();
  }
}

/// AsyncNotifier للقائمة (بدلاً من FutureProvider لأننا نحتاج actions).
final AsyncNotifierProvider<FavoritesListNotifier, List<FavoriteModel>>
    favoritesListProvider =
    AsyncNotifierProvider<FavoritesListNotifier, List<FavoriteModel>>(
  FavoritesListNotifier.new,
);
