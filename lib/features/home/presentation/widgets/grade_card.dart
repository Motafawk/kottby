import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../semester/data/grades_repository.dart';

/// كرت مرحلة/صف دراسي داخل شبكة الصفحة الرئيسية.
///
/// يحتوي على صورة الصف في الأعلى واسمه أسفلها، وكلاهما في المنتصف.
/// عند الضغط يفتح صفحة الـ WebView على رابط الصف في `kottby.net`.
class GradeCard extends StatelessWidget {
  const GradeCard({super.key, required this.grade});

  final Grade grade;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.push('/browser?url=${Uri.encodeComponent(grade.url)}'),
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // صورة الصف.
              Expanded(
                child: Image.asset(
                  grade.image,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.menu_book_rounded,
                    size: 56,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // اسم الصف.
              Text(
                grade.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
