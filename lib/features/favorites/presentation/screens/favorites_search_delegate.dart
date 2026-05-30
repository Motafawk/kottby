import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jiffy/jiffy.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/url_launcher_service.dart';
import '../../../../core/utils/digits.dart';
import '../../data/models/favorite_model.dart';
import '../providers/favorites_providers.dart';

/// `SearchDelegate` للبحث في المفضلة (مأخوذ من `search_favorite.dart` القديم).
class FavoritesSearchDelegate extends SearchDelegate<void> {
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
      builder: (BuildContext _, WidgetRef ref, _) {
        return FutureBuilder<List<FavoriteModel>>(
          future: ref.read(favoritesRepositoryProvider).getAll(search: query),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<List<FavoriteModel>> snapshot,
              ) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }
                final List<FavoriteModel> items =
                    snapshot.data ?? <FavoriteModel>[];
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد نتائج',
                      style: TextStyle(fontSize: AppSizes.lg),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (BuildContext _, int _) =>
                      Divider(height: 1, color: AppColors.tertiary),
                  itemBuilder: (BuildContext _, int i) {
                    final FavoriteModel item = items[i];
                    String time = '';
                    try {
                      time = toEnglishDigits(
                        Jiffy.parseFromDateTime(
                          DateTime.parse(item.createdAt),
                        ).fromNow(),
                      );
                    } catch (_) {
                      /* تجاهل */
                    }
                    return InkWell(
                      onTap: () {
                        if (item.url.contains('kottby')) {
                          close(context, null);
                          context.push(
                            '/browser?url=${Uri.encodeComponent(item.url)}',
                          );
                        } else {
                          UrlLauncherService.openExternal(
                            item.url,
                            context: context,
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.title.isEmpty
                                  ? AppStrings.appName
                                  : item.title,
                              style: const TextStyle(
                                fontSize: AppSizes.lg,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (time.isNotEmpty)
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: AppSizes.sm,
                                  color: AppColors.tertiary[700],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
        );
      },
    );
  }
}
