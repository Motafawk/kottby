import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/notifications_service.dart';
import '../../../semester/data/grades_repository.dart';
import '../providers/stage_filter_provider.dart';
import '../widgets/contact_us_section.dart';
import '../widgets/grade_card.dart';
import '../widgets/home_banner.dart';
import '../widgets/stage_filter_bar.dart';

/// الشاشة الرئيسية لمنصة «كتبي».
///
/// تتكوّن من:
/// - بانر علوي متدرّج (بدون AppBar أو Drawer).
/// - شريط فلترة المراحل الدراسية (يحفظ آخر اختيار).
/// - شبكة الصفوف الدراسية (عمودان).
/// - قسم «تواصل معنا».
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _asked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // نطلب الصلاحية بعد بناء أول إطار لضمان وجود Activity جاهزة على Android.
    if (_asked) return;
    _asked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bool allowed = await NotificationsService.ensureAllowedOnce();
      if (!mounted) return;
      if (!allowed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لن يعمل منبه المذاكرة بدون السماح بالإشعارات'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final StudyStage stage = ref.watch(stageFilterProvider);
    final List<Grade> grades = GradesRepository.byStage(stage);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF08787A),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          toolbarHeight: 0, // الارتفاع
        ),
        body: CustomScrollView(
          slivers: <Widget>[
            // البانر العلوي المتدرّج (يمتد خلف شريط الحالة).
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(left: 20, right: 20, top: 20),
                child: HomeBanner(),
              ),
            ),

            // شريط فلترة المراحل الدراسية.
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            const SliverToBoxAdapter(child: StageFilterBar()),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // عنوان الشبكة.
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'المراحل الدراسية',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),

            // شبكة الصفوف الدراسية (عمودان).
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.92,
                ),
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) =>
                      GradeCard(grade: grades[index]),
                  childCount: grades.length,
                ),
              ),
            ),

            // قسم «تواصل معنا».
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 28, 16, 24),
              sliver: SliverToBoxAdapter(child: ContactUsSection()),
            ),
          ],
        ),
      ),
    );
  }
}
