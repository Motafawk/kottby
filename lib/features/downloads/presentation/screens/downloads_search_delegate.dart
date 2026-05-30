import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/widgets/delete_confirm_dialog.dart';
import '../../data/models/download_model.dart';
import '../providers/downloads_providers.dart';
import 'downloads_screen.dart' show DownloadTile;

/// `SearchDelegate` للبحث في التنزيلات (مأخوذ من `search_file.dart` القديم).
class DownloadsSearchDelegate extends SearchDelegate<void> {
  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  List<Widget>? buildActions(BuildContext context) => <Widget>[
    IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () {
        if (query.isEmpty) {
          close(context, null);
        } else {
          query = '';
        }
      },
    ),
  ];

  @override
  Widget buildResults(BuildContext context) => _buildBody();

  @override
  Widget buildSuggestions(BuildContext context) => _buildBody();

  Widget _buildBody() {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, _) {
        return FutureBuilder<List<DownloadModel>>(
          future: ref.read(downloadsRepositoryProvider).getAll(search: query),
          builder:
              (BuildContext ctx, AsyncSnapshot<List<DownloadModel>> snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }
                final List<DownloadModel> items =
                    snapshot.data ?? <DownloadModel>[];
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد ملفات',
                      style: TextStyle(fontSize: AppSizes.lg),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (BuildContext _, int _) =>
                      Divider(height: 1, color: AppColors.tertiary),
                  itemBuilder: (BuildContext _, int i) {
                    final DownloadModel item = items[i];
                    return DownloadTile(
                      item: item,
                      onOpen: () {
                        final File f = File(item.savedPath);
                        if (!f.existsSync()) return;
                        OpenFilex.open(item.savedPath);
                      },
                      onShare: () => ShareService.shareFile(item.savedPath),
                      onDelete: () async {
                        final bool ok = await showDeleteConfirmDialog(context);
                        if (!ok) return;
                        await ref
                            .read(downloadsListProvider.notifier)
                            .remove(item);
                      },
                    );
                  },
                );
              },
        );
      },
    );
  }
}
