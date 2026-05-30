import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jiffy/jiffy.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/utils/digits.dart';
import '../../../../core/widgets/delete_confirm_dialog.dart';
import '../../data/models/download_model.dart';
import '../providers/downloads_providers.dart';
import 'downloads_search_delegate.dart';

/// شاشة التنزيلات — تصميم بطاقات عصري مع سحب للتحديث وحالة فراغ لطيفة.
class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<DownloadModel>> async = ref.watch(
      downloadsListProvider,
    );

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('التنزيلات'),
        titleSpacing: 15,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'بحث',
            onPressed: () async {
              await showSearch(
                context: context,
                delegate: DownloadsSearchDelegate(),
              );
              ref.invalidate(downloadsListProvider);
            },
          ),
          if ((async.value ?? const <DownloadModel>[]).isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'حذف الكل',
              onPressed: () => _confirmRemoveAll(context, ref),
            ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(child: Text('خطأ: $e')),
        data: (List<DownloadModel> items) {
          if (items.isEmpty) return const _EmptyState();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(downloadsListProvider.notifier).refresh(),
            child: Column(
              children: <Widget>[
                _CountHeader(count: items.length),
                Expanded(
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                    itemCount: items.length,
                    itemBuilder: (BuildContext _, int i) => DownloadTile(
                      item: items[i],
                      onOpen: () => _openFile(context, items[i]),
                      onShare: () => ShareService.shareFile(items[i].savedPath),
                      onDelete: () => _confirmRemoveOne(context, ref, items[i]),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openFile(BuildContext context, DownloadModel item) {
    final File file = File(item.savedPath);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('عذرا الملف غير موجود في الهاتف'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (item.status != DownloadStatus.completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الملف قيد التنزيل'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    OpenFilex.open(item.savedPath);
  }

  Future<void> _confirmRemoveOne(
    BuildContext context,
    WidgetRef ref,
    DownloadModel item,
  ) async {
    final bool ok = await showDeleteConfirmDialog(
      context,
      message: 'هل أنت متأكد من حذف هذا الملف؟',
    );
    if (!ok) return;
    await ref.read(downloadsListProvider.notifier).remove(item);
  }

  Future<void> _confirmRemoveAll(BuildContext context, WidgetRef ref) async {
    final bool ok = await showDeleteConfirmDialog(
      context,
      message: 'هل انت متاكد من حذف جميع التنزيلات؟',
    );
    if (!ok) return;
    await ref.read(downloadsListProvider.notifier).removeAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حذف جميع الملفات'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// ترويسة تعرض عدد الملفات المنزّلة.
class _CountHeader extends StatelessWidget {
  const _CountHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Row(
        children: <Widget>[
          const FaIcon(
            FontAwesomeIcons.download,
            color: AppColors.primary,
            size: 15,
          ),
          const SizedBox(width: 8),
          Text(
            '$count ملف في التنزيلات',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// أداة عرض نوع الملف (أيقونة + لون) بحسب الامتداد.
class _FileVisual {
  const _FileVisual(this.icon, this.color);
  final FaIconData icon;
  final Color color;

  static _FileVisual fromName(String name) {
    final String ext = name.contains('.')
        ? name.split('.').last.toLowerCase()
        : '';
    switch (ext) {
      case 'pdf':
        return const _FileVisual(FontAwesomeIcons.filePdf, Color(0xffe53935));
      case 'doc':
      case 'docx':
        return const _FileVisual(FontAwesomeIcons.fileWord, Color(0xff1565c0));
      case 'xls':
      case 'xlsx':
        return const _FileVisual(FontAwesomeIcons.fileExcel, Color(0xff2e7d32));
      case 'ppt':
      case 'pptx':
        return const _FileVisual(
          FontAwesomeIcons.filePowerpoint,
          Color(0xffd84315),
        );
      case 'zip':
      case 'rar':
        return const _FileVisual(
          FontAwesomeIcons.fileZipper,
          Color(0xff6a1b9a),
        );
      case 'apk':
        return const _FileVisual(FontAwesomeIcons.android, Color(0xff2e7d32));
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return const _FileVisual(FontAwesomeIcons.fileImage, Color(0xff00897b));
      default:
        return const _FileVisual(FontAwesomeIcons.file, AppColors.primary);
    }
  }
}

/// بطاقة ملف منزَّل (تُستخدم في الشاشة الرئيسية وفي البحث).
class DownloadTile extends StatelessWidget {
  const DownloadTile({
    super.key,
    required this.item,
    required this.onOpen,
    required this.onShare,
    required this.onDelete,
    this.isLast = false,
  });

  final DownloadModel item;
  final bool isLast;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    String createdAt = '';
    try {
      createdAt = toEnglishDigits(
        Jiffy.parseFromDateTime(DateTime.parse(item.createdAt)).fromNow(),
      );
    } catch (_) {
      /* تجاهل */
    }

    final _FileVisual visual = _FileVisual.fromName(item.fileName);
    final bool isRunning = item.status == DownloadStatus.running;
    final bool isFailed = item.status == DownloadStatus.failed;
    final bool isCompleted = item.status == DownloadStatus.completed;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // أيقونة نوع الملف.
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: visual.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: FaIcon(visual.icon, color: visual.color, size: 20),
                ),
                const SizedBox(width: 12),
                // تفاصيل الملف.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.fileName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          if (item.sizeBytes > 0) ...<Widget>[
                            Text(
                              '${item.sizeMb} MB',
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                color: AppColors.tertiary[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (createdAt.isNotEmpty) _dotSeparator(),
                          ],
                          if (createdAt.isNotEmpty)
                            Flexible(
                              child: Text(
                                createdAt,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.tertiary[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      // شريط التقدم أثناء التنزيل.
                      if (isRunning) ...<Widget>[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: item.progress / 100,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            color: AppColors.primary,
                            minHeight: 5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'جاري التنزيل... ${item.progress}%',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (isFailed) ...<Widget>[
                        const SizedBox(height: 6),
                        Row(
                          children: const <Widget>[
                            Icon(
                              Icons.error_outline,
                              size: 14,
                              color: Colors.red,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'فشل التنزيل',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // إجراءات الملف.
                if (isCompleted)
                  PopupMenuButton<int>(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.more_vert, color: AppColors.tertiary[600]),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (BuildContext _) => <PopupMenuEntry<int>>[
                      const PopupMenuItem<int>(
                        value: 0,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.share, color: AppColors.primary),
                          title: Text('مشاركة'),
                        ),
                      ),
                      const PopupMenuItem<int>(
                        value: 1,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('حذف'),
                        ),
                      ),
                    ],
                    onSelected: (int v) {
                      if (v == 0) {
                        onShare();
                      } else if (v == 1) {
                        onDelete();
                      }
                    },
                  )
                else
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.tertiary[500],
                      size: 20,
                    ),
                    splashRadius: 20,
                    onPressed: onDelete,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dotSeparator() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Text(
      '•',
      style: TextStyle(color: AppColors.tertiary[500], fontSize: 12),
    ),
  );
}

/// حالة فراغ التنزيلات بتصميم لطيف.
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
                FontAwesomeIcons.cloudArrowDown,
                size: 44,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'لا توجد تنزيلات',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'الملفات التي تقوم بتنزيلها أثناء التصفح ستظهر هنا لتتمكن من فتحها ومشاركتها بسهولة.',
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
