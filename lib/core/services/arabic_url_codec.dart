/// تحويل الأحرف العربية في عناوين URL.
///
/// نُعيد استخدام نفس الدوال من الإصدار القديم (`funs.dart`)
/// لأن أسماء الملفات على الموقع تأتي بصيغة مرمَّزة (HEX percent-encoded)
/// ونحتاج إلى تحويلها إلى عربي عند العرض، والعكس عند البحث.
class ArabicUrlCodec {
  ArabicUrlCodec._();

  static const Map<String, String> _arabicToHex = <String, String>{
    '٠': '%D9%A0', '١': '%D9%A1', '٢': '%D9%A2', '٣': '%D9%A3',
    '٤': '%D9%A4', '٥': '%D9%A5', '٦': '%D9%A6', '٧': '%D9%A7',
    '٨': '%D9%A8', '٩': '%D9%A9',
    'ا': '%D8%A7', 'ب': '%D8%A8', 'ت': '%D8%AA', 'ث': '%D8%AB',
    'ج': '%D8%AC', 'ح': '%D8%AD', 'خ': '%D8%AE', 'د': '%D8%AF',
    'ذ': '%D8%B0', 'ر': '%D8%B1', 'ز': '%D8%B2', 'س': '%D8%B3',
    'ش': '%D8%B4', 'ص': '%D8%B5', 'ض': '%D8%B6', 'ط': '%D8%B7',
    'ظ': '%D8%B8', 'ع': '%D8%B9', 'غ': '%D8%BA', 'ف': '%D9%81',
    'ق': '%D9%82', 'ك': '%D9%83', 'ل': '%D9%84', 'م': '%D9%85',
    'ن': '%D9%86', 'ه': '%D9%87', 'ة': '%D8%A9', 'و': '%D9%88',
    'ي': '%D9%8A', 'ؤ': '%D8%A4', 'ء': '%D8%A1', 'ئ': '%D8%A6',
    'أ': '%D8%A3', 'إ': '%D8%A5', 'آ': '%D8%A2', ' ': '%20',
    'َ': '%D9%8E', 'ً': '%D9%8B', 'ُ': '%D9%8F', 'ٌ': '%D9%8C',
    'ِ': '%D9%90', 'ٍ': '%D9%8D',
  };

  /// يحوّل النص العربي إلى صيغة hex المستخدمة في URL.
  static String arabicToHex(String url) {
    String result = url;
    _arabicToHex.forEach((String arabic, String hex) {
      result = result.replaceAll(arabic, hex);
    });
    return result;
  }

  /// يحوّل صيغة hex من URL إلى نص عربي قابل للعرض.
  static String hexToArabic(String url) {
    String result = url;
    _arabicToHex.forEach((String arabic, String hex) {
      result = result.replaceAll(hex, arabic);
    });
    return result;
  }
}
