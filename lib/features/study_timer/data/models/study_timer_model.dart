/// نموذج موعد مذاكرة (يُمثّل صف من جدول `studyTimers`).
class StudyTimerModel {
  const StudyTimerModel({
    required this.title,
    required this.subject,
    required this.date,
    required this.startAt,
    required this.endAt,
    required this.startId,
    required this.endId,
    required this.createdAt,
  });

  /// العنوان الذي يدخله المستخدم.
  final String title;

  /// التصنيف (نتركه ثابتاً 'Study' لتطابق الإصدار القديم).
  final String subject;

  /// تاريخ المذاكرة (ISO8601).
  final String date;

  /// وقت البدء (نص مُنسَّق مثل "9:00 AM").
  final String startAt;

  /// وقت الانتهاء (نص مُنسَّق).
  final String endAt;

  /// معرف إشعار البدء (لإلغائه عند الحذف).
  final int startId;

  /// معرف إشعار الانتهاء (لإلغائه عند الحذف).
  final int endId;

  /// تاريخ الإنشاء (يستخدم كمفتاح أساسي للصف).
  final String createdAt;

  factory StudyTimerModel.fromMap(Map<String, Object?> map) {
    return StudyTimerModel(
      title: (map['title'] ?? '') as String,
      subject: (map['subject'] ?? '') as String,
      date: (map['date'] ?? '') as String,
      startAt: (map['startAt'] ?? '') as String,
      endAt: (map['endAt'] ?? '') as String,
      startId: _toInt(map['startID']),
      endId: _toInt(map['endID']),
      createdAt: (map['created_at'] ?? '') as String,
    );
  }

  static int _toInt(Object? v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'title': title,
        'subject': subject,
        'date': date,
        'startAt': startAt,
        'endAt': endAt,
        'startID': startId,
        'endID': endId,
        'created_at': createdAt,
      };
}
