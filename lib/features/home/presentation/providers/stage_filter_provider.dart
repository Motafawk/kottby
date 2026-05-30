import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../semester/data/grades_repository.dart';

/// مزوّد لإدارة فلتر المرحلة الدراسية في الصفحة الرئيسية.
///
/// يحفظ آخر اختيار في `SharedPreferences` ويسترجعه تلقائياً عند إعادة فتح
/// التطبيق. القيمة الافتراضية هي «الكل».
class StageFilterNotifier extends Notifier<StudyStage> {
  static const String _prefsKey = 'selected_study_stage';

  @override
  StudyStage build() {
    // القيمة الافتراضية قبل اكتمال القراءة من التخزين.
    _restore();
    return StudyStage.all;
  }

  Future<void> _restore() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_prefsKey);
    if (saved == null) return;
    final StudyStage restored = StudyStage.values.firstWhere(
      (StudyStage stage) => stage.name == saved,
      orElse: () => StudyStage.all,
    );
    state = restored;
  }

  /// تحديث الفلتر وحفظه في التخزين.
  Future<void> select(StudyStage stage) async {
    state = stage;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, stage.name);
  }
}

/// المرحلة الدراسية المختارة حالياً في الصفحة الرئيسية.
final NotifierProvider<StageFilterNotifier, StudyStage> stageFilterProvider =
    NotifierProvider<StageFilterNotifier, StudyStage>(StageFilterNotifier.new);
