import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:jiffy/jiffy.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/digits.dart';
import '../../../../core/widgets/delete_confirm_dialog.dart';
import '../../data/models/study_timer_model.dart';
import '../providers/study_timers_providers.dart';

/// شاشة قائمة منبهات المذاكرة (التذكير) — تصميم بطاقات عصري.
class StudyTimersListScreen extends ConsumerStatefulWidget {
  const StudyTimersListScreen({super.key});

  @override
  ConsumerState<StudyTimersListScreen> createState() =>
      _StudyTimersListScreenState();
}

class _StudyTimersListScreenState extends ConsumerState<StudyTimersListScreen> {
  // القيمة الافتراضية للفلتر: «لم تبدأ».
  _TimerFilter _filter = _TimerFilter.upcoming;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<StudyTimerModel>> async = ref.watch(
      studyTimersListProvider,
    );
    final List<StudyTimerModel> current =
        async.value ?? const <StudyTimerModel>[];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('التذكير'),
        titleSpacing: 15,
        actions: <Widget>[
          if (current.isNotEmpty)
            IconButton(
              tooltip: 'حذف الكل',
              onPressed: () => _confirmRemoveAll(context, ref),
              icon: const Icon(Icons.delete_sweep_rounded),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/study-timer/new'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text(
          'تذكير جديد',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(child: Text('خطأ: $e')),
        data: (List<StudyTimerModel> items) {
          if (items.isEmpty) return const _EmptyState();

          // فلترة العناصر حسب الحالة المختارة.
          final List<StudyTimerModel> filtered = _filter == _TimerFilter.all
              ? items
              : items
                    .where(
                      (StudyTimerModel it) =>
                          _computeTimerStatus(it) == _filter.status,
                    )
                    .toList(growable: false);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () =>
                ref.read(studyTimersListProvider.notifier).refresh(),
            child: Column(
              children: <Widget>[
                _FilterBar(
                  selected: _filter,
                  onChanged: (_TimerFilter f) => setState(() => _filter = f),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? _FilterEmptyState(filter: _filter)
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                          itemCount: filtered.length,
                          itemBuilder: (BuildContext _, int i) {
                            final StudyTimerModel item = filtered[i];
                            return _StudyTimerCard(
                              item: item,
                              onDelete: () =>
                                  _confirmRemoveOne(context, ref, item),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmRemoveOne(
    BuildContext context,
    WidgetRef ref,
    StudyTimerModel item,
  ) async {
    final bool ok = await showDeleteConfirmDialog(context);
    if (!ok) return;
    await ref.read(studyTimersListProvider.notifier).remove(item);
  }

  Future<void> _confirmRemoveAll(BuildContext context, WidgetRef ref) async {
    final bool ok = await showDeleteConfirmDialog(
      context,
      message: 'هل انت متأكد من حذف جميع المواعيد؟',
    );
    if (!ok) return;
    await ref.read(studyTimersListProvider.notifier).removeAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حذف جميع العناصر'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// خيارات فلترة الحالة في شاشة التذكير.
enum _TimerFilter {
  upcoming('لم تبدأ'),
  all('الكل'),
  running('قيد التذكير'),
  ended('منهية');

  const _TimerFilter(this.label);

  final String label;

  /// الحالة الزمنية المقابلة (null لخيار «الكل»).
  _TimerStatus? get status {
    switch (this) {
      case _TimerFilter.upcoming:
        return _TimerStatus.upcoming;
      case _TimerFilter.running:
        return _TimerStatus.running;
      case _TimerFilter.ended:
        return _TimerStatus.ended;
      case _TimerFilter.all:
        return null;
    }
  }
}

/// شريط فلترة الحالة (لم تبدأ / الكل / قيد التذكير / منهية).
class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final _TimerFilter selected;
  final ValueChanged<_TimerFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
        itemCount: _TimerFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final _TimerFilter f = _TimerFilter.values[index];
          final bool isSelected = f == selected;
          return GestureDetector(
            onTap: () => onChanged(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xffe2e8f0),
                ),
                boxShadow: isSelected
                    ? <BoxShadow>[
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                f.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textDark,
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// حالة فراغ نتيجة الفلترة (لا يوجد عناصر بهذه الحالة).
class _FilterEmptyState extends StatelessWidget {
  const _FilterEmptyState({required this.filter});

  final _TimerFilter filter;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: <Widget>[
        const SizedBox(height: 60),
        Center(
          child: Column(
            children: <Widget>[
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: FaIcon(
                  FontAwesomeIcons.bellSlash,
                  size: 36,
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'لا توجد تذكيرات «${filter.label}»',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// تركيب DateTime من تاريخ المنبه + نص الوقت المنسَّق (مثل "7:57 م").
DateTime? _composeTimerDateTime(String dateIso, String formattedTime) {
  try {
    final DateTime date = DateTime.parse(dateIso);
    final String t = toEnglishDigits(formattedTime);
    final RegExpMatch? m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(t);
    if (m == null) return null;
    int hour = int.parse(m.group(1)!);
    final int minute = int.parse(m.group(2)!);
    // علامات صباحًا/مساءً بالعربية أو الإنجليزية (لتحويل 12 ساعة → 24 ساعة).
    final bool isPm = t.contains('م') || t.toLowerCase().contains('pm');
    final bool isAm = t.contains('ص') || t.toLowerCase().contains('am');
    if (isPm && hour < 12) hour += 12;
    if (isAm && hour == 12) hour = 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  } catch (_) {
    return null;
  }
}

/// حساب حالة التذكير (انتهى / جارٍ الآن / لم يبدأ بعد).
_TimerStatus _computeTimerStatus(StudyTimerModel item) {
  final DateTime now = DateTime.now();
  final DateTime? start = _composeTimerDateTime(item.date, item.startAt);
  final DateTime? end = _composeTimerDateTime(item.date, item.endAt);
  if (end != null && now.isAfter(end)) return _TimerStatus.ended;
  if (start != null && now.isBefore(start)) return _TimerStatus.upcoming;
  if (start != null && end != null) return _TimerStatus.running;
  return _TimerStatus.upcoming;
}

class _StudyTimerCard extends StatelessWidget {
  const _StudyTimerCard({required this.item, required this.onDelete});

  final StudyTimerModel item;
  final VoidCallback onDelete;

  String _formatDateLongAr(String iso) {
    try {
      final DateTime dt = DateTime.parse(iso);
      return DateFormat('EEEE، d MMMM y', 'ar').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    String createdAt = '';
    try {
      createdAt = Jiffy.parseFromDateTime(
        DateTime.parse(item.createdAt),
      ).fromNow();
    } catch (_) {
      /* تجاهل */
    }
    createdAt = toEnglishDigits(createdAt);

    final String dateText = toEnglishDigits(_formatDateLongAr(item.date));
    final _TimerStatus status = _computeTimerStatus(item);
    final bool isEnded = status == _TimerStatus.ended;

    // تدرّج ترويسة البطاقة بحسب الحالة (رمادي للمنتهي).
    final List<Color> headerColors = isEnded
        ? <Color>[const Color(0xff94a3b8), const Color(0xff64748b)]
        : <Color>[AppColors.primaryLight, AppColors.primary];

    return Dismissible(
      key: ValueKey<String>(item.createdAt),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsetsDirectional.only(end: 22),
        alignment: AlignmentDirectional.centerEnd,
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 26),
      ),
      child: Opacity(
        opacity: isEnded ? 0.82 : 1,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ترويسة بتدرّج: أيقونة جرس + العنوان + زر حذف.
              Container(
                padding: const EdgeInsetsDirectional.only(
                  start: 14,
                  end: 6,
                  top: 12,
                  bottom: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: headerColors,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: FaIcon(
                        isEnded
                            ? FontAwesomeIcons.solidBellSlash
                            : FontAwesomeIcons.solidBell,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'حذف',
                      icon: const Icon(Icons.close),
                      color: Colors.white,
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // شارة الحالة + التاريخ + التصنيف.
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _StatusBadge(status: status),
                        if (dateText.isNotEmpty)
                          _InfoChip(icon: Icons.event_rounded, text: dateText),
                        _InfoChip(
                          icon: Icons.school_rounded,
                          text: item.subject == 'Study'
                              ? 'مذاكرة'
                              : item.subject,
                          background: AppColors.primary.withValues(alpha: 0.10),
                          foreground: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // الوقت من/إلى.
                    Row(
                      textDirection: TextDirection.rtl,
                      children: <Widget>[
                        Expanded(
                          child: _TimeBox(
                            label: 'من',
                            time: item.startAt,
                            icon: Icons.play_circle_fill_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TimeBox(
                            label: 'إلى',
                            time: item.endAt,
                            icon: Icons.stop_circle_rounded,
                          ),
                        ),
                      ],
                    ),

                    if (createdAt.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.schedule_rounded,
                            size: 15,
                            color: AppColors.tertiary[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'أُضيف $createdAt',
                            style: TextStyle(
                              color: AppColors.tertiary[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// حالة التذكير الزمنية.
enum _TimerStatus { upcoming, running, ended }

/// شارة تعرض حالة التذكير (لم يبدأ / جارٍ الآن / انتهى).
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _TimerStatus status;

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final String text;
    late final Color color;

    switch (status) {
      case _TimerStatus.upcoming:
        icon = Icons.hourglass_top_rounded;
        text = 'لم يبدأ بعد';
        color = AppColors.secondary;
      case _TimerStatus.running:
        icon = Icons.play_circle_fill_rounded;
        text = 'جارٍ الآن';
        color = const Color(0xff16a34a);
      case _TimerStatus.ended:
        icon = Icons.check_circle_rounded;
        text = 'انتهى';
        color = const Color(0xff64748b);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.text,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final String text;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final Color fg = foreground ?? const Color(0xFF4A5568);
    final Color bg = background ?? const Color(0xFFF1F5F9);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({required this.label, required this.time, required this.icon});

  final String label;
  final String time;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  color: AppColors.tertiary[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                toEnglishDigits(time),
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// حالة فراغ التذكير بتصميم لطيف.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: FaIcon(
                FontAwesomeIcons.solidBell,
                size: 42,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'لا توجد تذكيرات',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'أضف تذكيراً لأوقات مذاكرتك لينبّهك التطبيق في الوقت المحدد. اضغط زر «تذكير جديد» للبدء.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.9,
                color: AppColors.tertiary[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
