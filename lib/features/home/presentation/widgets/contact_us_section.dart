import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/url_launcher_service.dart';

/// قسم «تواصل معنا» أسفل الصفحة الرئيسية.
///
/// بطاقة بيضاء تحتوي على عنوان «تواصل معنا» مع أيقونة استفسار، وزرّين:
/// - «التواصل معنا» (أخضر): يفتح صفحة الـ WebView داخل التطبيق على رابط التواصل.
/// - «تلغرام» (أزرق): يفتح رابط تيلجرام في تطبيق خارجي.
class ContactUsSection extends StatelessWidget {
  const ContactUsSection({super.key});

  // اللون الأزرق الخاص بزر تيلجرام (مطابق للتصميم).
  static const Color _telegramBlue = Color(0xff2aa8e0);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // العنوان مع أيقونة الاستفسار (محاذاة لليمين في RTL).
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '؟',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'تواصل معنا',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // الزرّان جنباً إلى جنب.
            Row(
              children: <Widget>[
                // زر التواصل معنا (أخضر) — يفتح WebView داخل التطبيق.
                Expanded(
                  child: _ContactButton(
                    color: AppColors.primary,
                    icon: FontAwesomeIcons.solidEnvelope,
                    label: 'التواصل معنا',
                    onTap: () => context.push(
                      '/browser?url=${Uri.encodeComponent(AppStrings.contactUsUrl)}',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // زر تيلجرام (أزرق) — يفتح الرابط خارجياً.
                Expanded(
                  child: _ContactButton(
                    color: _telegramBlue,
                    icon: FontAwesomeIcons.telegram,
                    label: 'تيلجرام',
                    onTap: () => UrlLauncherService.openExternal(
                      AppStrings.telegramUrl,
                      context: context,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// زر داخل قسم «تواصل معنا» (أيقونة + نص بخلفية ملوّنة).
class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final FaIconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FaIcon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
