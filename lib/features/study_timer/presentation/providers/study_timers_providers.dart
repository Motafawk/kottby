import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../favorites/presentation/providers/favorites_providers.dart' show dbHelperProvider;
import '../../data/models/study_timer_model.dart';
import '../../data/repositories/study_timers_repository.dart';

/// مزوّد مستودع منبهات المذاكرة.
final Provider<StudyTimersRepository> studyTimersRepositoryProvider =
    Provider<StudyTimersRepository>(
  (Ref ref) => StudyTimersRepository(ref.watch(dbHelperProvider)),
);

/// قائمة المنبهات + إجراءاتها.
class StudyTimersListNotifier extends AsyncNotifier<List<StudyTimerModel>> {
  @override
  Future<List<StudyTimerModel>> build() async {
    return ref.read(studyTimersRepositoryProvider).getAll();
  }

  Future<void> refresh() async {
    state = const AsyncValue<List<StudyTimerModel>>.loading();
    state = await AsyncValue.guard<List<StudyTimerModel>>(
      () => ref.read(studyTimersRepositoryProvider).getAll(),
    );
  }

  Future<StudyTimerModel> add({
    required String title,
    required DateTime date,
    required ({int hour, int minute, String formatted}) start,
    required ({int hour, int minute, String formatted}) end,
  }) async {
    final StudyTimerModel m = await ref.read(studyTimersRepositoryProvider).add(
          title: title,
          date: date,
          start: start,
          end: end,
        );
    await refresh();
    return m;
  }

  Future<void> remove(StudyTimerModel m) async {
    await ref.read(studyTimersRepositoryProvider).remove(m);
    await refresh();
  }

  Future<void> removeAll() async {
    await ref.read(studyTimersRepositoryProvider).removeAll();
    await refresh();
  }
}

final AsyncNotifierProvider<StudyTimersListNotifier, List<StudyTimerModel>>
    studyTimersListProvider =
    AsyncNotifierProvider<StudyTimersListNotifier, List<StudyTimerModel>>(
  StudyTimersListNotifier.new,
);
