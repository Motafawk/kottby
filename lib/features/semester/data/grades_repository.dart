import '../../../core/constants/app_assets.dart';

/// المراحل الدراسية المستخدمة في شريط الفلترة بالصفحة الرئيسية.
enum StudyStage {
  all('الكل'),
  primary('الابتدائية'),
  intermediate('المتوسط'),
  secondary('الثانوية');

  const StudyStage(this.label);

  /// الاسم العربي المعروض في زر الفلترة.
  final String label;
}

/// نموذج صف دراسي واحد (رقمه + اسمه + صورته + رابطه + مرحلته).
class Grade {
  const Grade({
    required this.number,
    required this.name,
    required this.url,
    required this.stage,
  });

  final int number;
  final String name;
  final String url;
  final StudyStage stage;

  /// مسار صورة الصف داخل الأصول.
  String get image => AppAssets.gradeImage(number);
}

/// مستودع الصفوف الدراسية لمنصة «كتبي».
///
/// يحوي قائمة الصفوف الاثني عشر مع روابطها على `kottby.net`،
/// ويوفّر فلترة حسب المرحلة الدراسية.
class GradesRepository {
  GradesRepository._();

  /// كل الصفوف الدراسية (1 → 12) مع روابطها حسب جدول المتطلبات.
  static const List<Grade> grades = <Grade>[
    Grade(
      number: 1,
      name: 'الصف الأول الابتدائي',
      url: 'https://www.kottby.net/s1/',
      stage: StudyStage.primary,
    ),
    Grade(
      number: 2,
      name: 'الصف الثاني الابتدائي',
      url: 'https://www.kottby.net/s2/',
      stage: StudyStage.primary,
    ),
    Grade(
      number: 3,
      name: 'الصف الثالث الابتدائي',
      url: 'https://www.kottby.net/tnaf3/',
      stage: StudyStage.primary,
    ),
    Grade(
      number: 4,
      name: 'الصف الرابع الابتدائي',
      url: 'https://www.kottby.net/s4/',
      stage: StudyStage.primary,
    ),
    Grade(
      number: 5,
      name: 'الصف الخامس الابتدائي',
      url: 'https://www.kottby.net/s5/',
      stage: StudyStage.primary,
    ),
    Grade(
      number: 6,
      name: 'الصف السادس الابتدائي',
      url: 'https://www.kottby.net/s6/',
      stage: StudyStage.primary,
    ),
    Grade(
      number: 7,
      name: 'الصف الأول المتوسط',
      url: 'https://www.kottby.net/m1/',
      stage: StudyStage.intermediate,
    ),
    Grade(
      number: 8,
      name: 'الصف الثاني المتوسط',
      url: 'https://www.kottby.net/m2/',
      stage: StudyStage.intermediate,
    ),
    Grade(
      number: 9,
      name: 'الصف الثالث المتوسط',
      url: 'https://www.kottby.net/m3/',
      stage: StudyStage.intermediate,
    ),
    Grade(
      number: 10,
      name: 'الصف الأول الثانوي',
      url: 'https://www.kottby.net/t1/',
      stage: StudyStage.secondary,
    ),
    Grade(
      number: 11,
      name: 'الصف الثاني الثانوي',
      url: 'https://www.kottby.net/t2/',
      stage: StudyStage.secondary,
    ),
    Grade(
      number: 12,
      name: 'الصف الثالث الثانوي',
      url: 'https://www.kottby.net/t3/',
      stage: StudyStage.secondary,
    ),
  ];

  /// إرجاع الصفوف حسب المرحلة المختارة (الكل = جميع الصفوف).
  static List<Grade> byStage(StudyStage stage) {
    if (stage == StudyStage.all) return grades;
    return grades
        .where((Grade grade) => grade.stage == stage)
        .toList(growable: false);
  }
}
