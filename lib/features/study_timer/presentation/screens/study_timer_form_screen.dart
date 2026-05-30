import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/notifications_service.dart';
import '../providers/study_timers_providers.dart';

/// شاشة إضافة منبه مذاكرة (تذكير) — تصميم بطاقات عصري.
///
/// شروط التحقق (حسب طلب المستخدم):
/// - **التاريخ**: اليوم أو بعده (يضمنه `firstDate: DateTime.now()`).
/// - **وقت البدء**: مجموع (التاريخ + وقت البدء) يجب أن يكون **بعد اللحظة الحالية**.
/// - **وقت الانتهاء**: يجب أن يكون **بعد** وقت البدء.
class StudyTimerFormScreen extends ConsumerStatefulWidget {
  const StudyTimerFormScreen({super.key});

  @override
  ConsumerState<StudyTimerFormScreen> createState() =>
      _StudyTimerFormScreenState();
}

class _StudyTimerFormScreenState extends ConsumerState<StudyTimerFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _txtTitle = TextEditingController();
  final TextEditingController _txtStart = TextEditingController();
  final TextEditingController _txtEnd = TextEditingController();

  DateTime? _date;
  TimeOfDay? _startAt;
  TimeOfDay? _endAt;

  bool _saving = false;

  @override
  void dispose() {
    _txtTitle.dispose();
    _txtStart.dispose();
    _txtEnd.dispose();
    super.dispose();
  }

  String get _dateText =>
      _date == null ? '' : DateFormat('EEEE، d MMMM y', 'ar').format(_date!);

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final DateTime now = DateTime.now();
    final DateTime initial = _date ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day);
    });
    _formKey.currentState?.validate();
  }

  Future<void> _pickStart() async {
    FocusScope.of(context).unfocus();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startAt ?? TimeOfDay.now(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _startAt = picked;
      _txtStart.text = picked.format(context);
    });
    _formKey.currentState?.validate();
  }

  Future<void> _pickEnd() async {
    FocusScope.of(context).unfocus();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endAt ?? TimeOfDay.now(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _endAt = picked;
      _txtEnd.text = picked.format(context);
    });
    _formKey.currentState?.validate();
  }

  String? _validateDate() =>
      _date == null ? 'لا يمكن ترك هذا الحقل فارغ' : null;

  /// التحقق من أن (التاريخ + وقت البدء) في المستقبل.
  String? _validateStart() {
    if (_startAt == null) return 'لا يمكن ترك هذا الحقل فارغ';
    if (_date == null) return null; // التحقق من التاريخ في حقله
    final DateTime startDt = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _startAt!.hour,
      _startAt!.minute,
    );
    if (!startDt.isAfter(DateTime.now())) {
      return 'يجب أن يكون وقت البدء بعد الوقت الحالي';
    }
    return null;
  }

  /// التحقق من أن وقت الانتهاء بعد وقت البدء.
  String? _validateEnd() {
    if (_endAt == null) return 'لا يمكن ترك هذا الحقل فارغ';
    if (_startAt == null) return null;
    final double start = _startAt!.hour + _startAt!.minute / 60.0;
    final double end = _endAt!.hour + _endAt!.minute / 60.0;
    if (end <= start) {
      return 'يجب أن يكون وقت الانتهاء بعد وقت البدء';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    // طلب صلاحية الإشعار قبل الجدولة (Android 13+).
    final bool allowed = await NotificationsService.ensureAllowed();
    if (!mounted) return;
    if (!allowed) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب السماح بالإشعارات لاستخدام منبه المذاكرة'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await ref
          .read(studyTimersListProvider.notifier)
          .add(
            title: _txtTitle.text.trim(),
            date: _date!,
            start: (
              hour: _startAt!.hour,
              minute: _startAt!.minute,
              formatted: _txtStart.text,
            ),
            end: (
              hour: _endAt!.hour,
              minute: _endAt!.minute,
              formatted: _txtEnd.text,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت الإضافة إلى أوقات المذاكرة'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذّر الحفظ: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(title: const Text('إضافة تذكير'), titleSpacing: 15),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.disabled,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: <Widget>[
              const _FormHeader(),
              const SizedBox(height: 20),

              _SectionCard(
                children: <Widget>[
                  // العنوان.
                  TextFormField(
                    controller: _txtTitle,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    maxLength: 50,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    validator: (String? v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'لا يمكن ترك هذا الحقل فارغ';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'عنوان التذكير',
                      hintText: 'مثال: مراجعة مادة الرياضيات',
                      prefixIcon: const Icon(
                        Icons.title_rounded,
                        color: AppColors.primary,
                      ),
                      filled: true,
                      fillColor: AppColors.scaffoldBackground,
                      border: _fieldBorder(),
                      enabledBorder: _fieldBorder(),
                      focusedBorder: _fieldBorder(focused: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _SectionCard(
                title: 'الموعد',
                children: <Widget>[
                  // التاريخ.
                  FormField<DateTime>(
                    validator: (_) => _validateDate(),
                    builder: (FormFieldState<DateTime> field) => _PickerTile(
                      icon: Icons.calendar_month_rounded,
                      label: 'تاريخ المذاكرة',
                      value: _dateText,
                      placeholder: 'اختر التاريخ',
                      error: field.errorText,
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // وقت البدء.
                      Expanded(
                        child: FormField<TimeOfDay>(
                          validator: (_) => _validateStart(),
                          builder: (FormFieldState<TimeOfDay> field) =>
                              _PickerTile(
                                icon: Icons.play_circle_fill_rounded,
                                label: 'وقت البدء',
                                value: _txtStart.text,
                                placeholder: 'اختر',
                                error: field.errorText,
                                onTap: _pickStart,
                              ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // وقت الانتهاء.
                      Expanded(
                        child: FormField<TimeOfDay>(
                          validator: (_) => _validateEnd(),
                          builder: (FormFieldState<TimeOfDay> field) =>
                              _PickerTile(
                                icon: Icons.stop_circle_rounded,
                                label: 'وقت الانتهاء',
                                value: _txtEnd.text,
                                placeholder: 'اختر',
                                error: field.errorText,
                                onTap: _pickEnd,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // زر الحفظ.
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _saving
                      ? const SizedBox.shrink()
                      : const Icon(Icons.notifications_active_rounded),
                  label: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'حفظ التذكير',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _fieldBorder({bool focused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: focused ? AppColors.primary : const Color(0xffe2e8f0),
        width: focused ? 1.6 : 1,
      ),
    );
  }
}

/// ترويسة الصفحة (أيقونة جرس + نص توضيحي).
class _FormHeader extends StatelessWidget {
  const _FormHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: <Color>[AppColors.primaryLight, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const FaIcon(
              FontAwesomeIcons.solidBell,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'تذكير جديد للمذاكرة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'سننبّهك عند بدء وانتهاء وقت مذاكرتك.',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة قسم بيضاء بعنوان اختياري.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children, this.title});

  final List<Widget> children;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 12, right: 2),
              child: Text(
                title!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
          ...children,
        ],
      ),
    );
  }
}

/// عنصر اختيار (تاريخ/وقت) قابل للضغط مع عرض خطأ التحقق.
class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.error,
  });

  final IconData icon;
  final String label;
  final String value;
  final String placeholder;
  final VoidCallback onTap;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final bool hasError = error != null;
    final bool hasValue = value.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Material(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasError
                      ? Colors.red.shade300
                      : const Color(0xffe2e8f0),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(icon, size: 20, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.tertiary[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          hasValue ? value : placeholder,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: hasValue
                                ? AppColors.textDark
                                : AppColors.tertiary[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.tertiary[500],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 4),
            child: Text(
              error!,
              style: TextStyle(color: Colors.red.shade600, fontSize: 11.5),
            ),
          ),
      ],
    );
  }
}
