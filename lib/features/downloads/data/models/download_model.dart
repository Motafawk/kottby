/// حالة عملية تنزيل.
enum DownloadStatus { pending, running, completed, failed, canceled }

extension DownloadStatusX on DownloadStatus {
  String get db => name;

  static DownloadStatus fromDb(String? value) {
    switch (value) {
      case 'pending':
        return DownloadStatus.pending;
      case 'running':
        return DownloadStatus.running;
      case 'completed':
        return DownloadStatus.completed;
      case 'failed':
        return DownloadStatus.failed;
      case 'canceled':
        return DownloadStatus.canceled;
      default:
        return DownloadStatus.pending;
    }
  }
}

/// نموذج تنزيل (يُمثّل صف من جدول `downloads`).
class DownloadModel {
  const DownloadModel({
    this.id,
    required this.url,
    required this.fileName,
    required this.savedPath,
    this.sizeBytes = 0,
    this.status = DownloadStatus.pending,
    this.progress = 0,
    required this.createdAt,
  });

  final int? id;
  final String url;
  final String fileName;
  final String savedPath;
  final int sizeBytes;
  final DownloadStatus status;
  final int progress; // 0..100
  final String createdAt;

  /// الحجم بصيغة "X.XX MB" أو 0 إذا غير معروف.
  String get sizeMb {
    if (sizeBytes <= 0) return '0';
    final double mb = sizeBytes / (1024 * 1024);
    String s = mb.toStringAsFixed(2);
    if (s.endsWith('.00')) s = s.substring(0, s.length - 3);
    return s;
  }

  DownloadModel copyWith({
    int? id,
    String? url,
    String? fileName,
    String? savedPath,
    int? sizeBytes,
    DownloadStatus? status,
    int? progress,
    String? createdAt,
  }) {
    return DownloadModel(
      id: id ?? this.id,
      url: url ?? this.url,
      fileName: fileName ?? this.fileName,
      savedPath: savedPath ?? this.savedPath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory DownloadModel.fromMap(Map<String, Object?> map) {
    return DownloadModel(
      id: map['id'] as int?,
      url: (map['url'] ?? '') as String,
      fileName: (map['file_name'] ?? '') as String,
      savedPath: (map['saved_path'] ?? '') as String,
      sizeBytes: (map['size_bytes'] ?? 0) as int,
      status: DownloadStatusX.fromDb(map['status'] as String?),
      progress: (map['progress'] ?? 0) as int,
      createdAt: (map['created_at'] ?? '') as String,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        if (id != null) 'id': id,
        'url': url,
        'file_name': fileName,
        'saved_path': savedPath,
        'size_bytes': sizeBytes,
        'status': status.db,
        'progress': progress,
        'created_at': createdAt,
      };
}
