import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:jiffy/jiffy.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../../../core/utils/digits.dart';
import '../../../../core/widgets/delete_confirm_dialog.dart';
import '../../data/models/favorite_model.dart';
import '../providers/favorites_providers.dart';
import 'favorites_search_delegate.dart';

/// شاشة المفضلة — تصميم بطاقات عصري مع سحب للحذف وسحب للتحديث.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<FavoriteModel>> async = ref.watch(
      favoritesListProvider,
    );

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('المفضلة'),
        titleSpacing: 15,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'بحث',
            onPressed: () async {
              await showSearch(
                context: context,
                delegate: FavoritesSearchDelegate(),
              );
              ref.invalidate(favoritesListProvider);
            },
          ),
          // حذف الكل (يظهر فقط عند وجود عناصر).
          if ((async.value ?? const <FavoriteModel>[]).isNotEmpty)
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
        data: (List<FavoriteModel> items) {
          if (items.isEmpty) return const _EmptyState();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(favoritesListProvider.notifier).refresh(),
            child: Column(
              children: <Widget>[
                _CountHeader(count: items.length),
                Expanded(
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                    itemCount: items.length,
                    itemBuilder: (BuildContext context, int i) {
                      final FavoriteModel item = items[i];
                      return _FavoriteCard(
                        item: item,
                        onTap: () => _openItem(context, item),
                        onDelete: () => _confirmRemoveOne(context, ref, item),
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

  void _openItem(BuildContext context, FavoriteModel item) {
    if (item.url.contains('kottby')) {
      context.push('/browser?url=${Uri.encodeComponent(item.url)}');
    } else {
      UrlLauncherService.openExternal(item.url, context: context);
    }
  }

  Future<void> _confirmRemoveOne(
    BuildContext context,
    WidgetRef ref,
    FavoriteModel item,
  ) async {
    final bool ok = await showDeleteConfirmDialog(
      context,
      message: 'هل أنت متأكد من حذف هذا العنصر من المفضلة؟',
    );
    if (!ok) return;
    await ref.read(favoritesListProvider.notifier).remove(item.url);
  }

  Future<void> _confirmRemoveAll(BuildContext context, WidgetRef ref) async {
    final bool ok = await showDeleteConfirmDialog(
      context,
      message: 'هل أنت متأكد من تفريغ المفضلة؟',
    );
    if (!ok) return;
    await ref.read(favoritesListProvider.notifier).removeAll();
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

/// ترويسة تعرض عدد العناصر المحفوظة.
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
            FontAwesomeIcons.solidHeart,
            color: AppColors.secondary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '$count عنصر في مفضلتك',
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

/// بطاقة عنصر مفضّل.
class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final FavoriteModel item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String get _title => item.title.isEmpty ? AppStrings.appName : item.title;

  /// اسم النطاق المختصر (مثل: kottby.net) لعرضه أسفل العنوان.
  String get _host {
    try {
      final Uri uri = Uri.parse(item.url);
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return '';
    }
  }

  String get _relativeTime {
    try {
      return toEnglishDigits(
        Jiffy.parseFromDateTime(DateTime.parse(item.createdAt)).fromNow(),
      );
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String host = _host;
    final String time = _relativeTime;

    return Dismissible(
      key: ValueKey<String>(item.url),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsetsDirectional.only(end: 22),
        alignment: AlignmentDirectional.centerEnd,
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 26),
      ),
      child: Container(
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
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: <Widget>[
                  // أيقونة دائرية.
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const FaIcon(
                      FontAwesomeIcons.solidBookmark,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // العنوان + التفاصيل.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: <Widget>[
                            if (host.isNotEmpty) ...<Widget>[
                              Icon(
                                Icons.link_rounded,
                                size: 13,
                                color: AppColors.tertiary[600],
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  host,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.tertiary[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                            if (host.isNotEmpty && time.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: Text(
                                  '•',
                                  style: TextStyle(
                                    color: AppColors.tertiary[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            if (time.isNotEmpty)
                              Text(
                                time,
                                style: TextStyle(
                                  color: AppColors.tertiary[600],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // زر الحذف.
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
      ),
    );
  }
}

/// حالة فراغ المفضلة بتصميم لطيف.
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
                FontAwesomeIcons.heartCirclePlus,
                size: 46,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'مفضلتك فارغة',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'لم تقم بإضافة أي صفحة إلى المفضلة بعد. أثناء التصفح اضغط على أيقونة القلب ♡ لحفظ الصفحات التي تهمك هنا.',
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
