/// نموذج عنصر مفضّل (يُمثّل صف من جدول `favorites`).
class FavoriteModel {
  const FavoriteModel({
    required this.url,
    required this.title,
    required this.createdAt,
  });

  final String url;
  final String title;
  final String createdAt;

  factory FavoriteModel.fromMap(Map<String, Object?> map) {
    return FavoriteModel(
      url: (map['url'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      createdAt: (map['created_at'] ?? '') as String,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'url': url,
        'title': title,
        'created_at': createdAt,
      };
}
