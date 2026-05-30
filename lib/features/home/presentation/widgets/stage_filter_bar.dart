import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../semester/data/grades_repository.dart';
import '../providers/stage_filter_provider.dart';

/// شريط فلترة المراحل الدراسية (الكل / الابتدائية / المتوسط / الثانوية).
///
/// يقرأ ويكتب القيمة عبر [stageFilterProvider] (محفوظة في SharedPreferences).
class StageFilterBar extends ConsumerWidget {
  const StageFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StudyStage selected = ref.watch(stageFilterProvider);

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: StudyStage.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (BuildContext context, int index) {
          final StudyStage stage = StudyStage.values[index];
          final bool isSelected = stage == selected;
          return _StageChip(
            label: stage.label,
            selected: isSelected,
            onTap: () => ref.read(stageFilterProvider.notifier).select(stage),
          );
        },
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xffe2e8f0),
          ),
          boxShadow: selected
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
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textDark,
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
