import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../favorites/presentation/providers/favorites_providers.dart' show dbHelperProvider;
import '../../data/models/download_model.dart';
import '../../data/repositories/downloads_repository.dart';

/// مزوّد مستودع التنزيلات (يستخدم نفس DbHelper المشترك).
final Provider<DownloadsRepository> downloadsRepositoryProvider =
    Provider<DownloadsRepository>(
  (Ref ref) => DownloadsRepository(ref.watch(dbHelperProvider)),
);

/// قائمة التنزيلات + إجراءات.
class DownloadsListNotifier extends AsyncNotifier<List<DownloadModel>> {
  String _search = '';
  Timer? _autoRefresh;

  @override
  Future<List<DownloadModel>> build() async {
    // تحديث دوري كل ثانية أثناء وجود تنزيل جارٍ.
    ref.onDispose(() {
      _autoRefresh?.cancel();
    });
    _setupAutoRefresh();
    return ref.read(downloadsRepositoryProvider).getAll(search: _search);
  }

  void _setupAutoRefresh() {
    _autoRefresh?.cancel();
    _autoRefresh = Timer.periodic(const Duration(seconds: 1), (Timer t) async {
      // إذا لم تكن هناك أي تنزيلات جارية، نوقف التحديث الدوري.
      final List<DownloadModel> current = state.value ?? <DownloadModel>[];
      final bool hasRunning = current.any((DownloadModel d) => d.status == DownloadStatus.running);
      if (!hasRunning) return;
      final List<DownloadModel> fresh =
          await ref.read(downloadsRepositoryProvider).getAll(search: _search);
      state = AsyncValue<List<DownloadModel>>.data(fresh);
    });
  }

  Future<void> setSearch(String q) async {
    _search = q;
    state = const AsyncValue<List<DownloadModel>>.loading();
    state = await AsyncValue.guard<List<DownloadModel>>(() async {
      return ref.read(downloadsRepositoryProvider).getAll(search: _search);
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue<List<DownloadModel>>.loading();
    state = await AsyncValue.guard<List<DownloadModel>>(() async {
      return ref.read(downloadsRepositoryProvider).getAll(search: _search);
    });
  }

  /// بدء تنزيل ملف من رابط (يُستخدم من شاشة WebView).
  Future<DownloadModel> startDownload(
    String url, {
    void Function(DownloadModel existing)? onAlreadyExists,
  }) async {
    final DownloadModel m = await ref
        .read(downloadsRepositoryProvider)
        .startDownload(url, onAlreadyExists: onAlreadyExists);
    await refresh();
    return m;
  }

  Future<void> remove(DownloadModel m) async {
    await ref.read(downloadsRepositoryProvider).remove(m);
    await refresh();
  }

  Future<void> removeAll() async {
    await ref.read(downloadsRepositoryProvider).removeAll();
    await refresh();
  }
}

final AsyncNotifierProvider<DownloadsListNotifier, List<DownloadModel>>
    downloadsListProvider =
    AsyncNotifierProvider<DownloadsListNotifier, List<DownloadModel>>(
  DownloadsListNotifier.new,
);
