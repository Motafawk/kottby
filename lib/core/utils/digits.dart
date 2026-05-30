/// تحويل الأرقام العربية/الهندية إلى أرقام إنجليزية داخل النص.
///
/// مفيد خصوصًا مع نواتج `Jiffy` عند استخدام locale العربية.
String toEnglishDigits(String input) {
  if (input.isEmpty) return input;

  const Map<String, String> map = <String, String>{
    // Arabic-Indic digits
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
    // Eastern Arabic-Indic (Persian) digits
    '۰': '0',
    '۱': '1',
    '۲': '2',
    '۳': '3',
    '۴': '4',
    '۵': '5',
    '۶': '6',
    '۷': '7',
    '۸': '8',
    '۹': '9',
  };

  final StringBuffer out = StringBuffer();
  for (int i = 0; i < input.length; i++) {
    final String ch = input[i];
    out.write(map[ch] ?? ch);
  }
  return out.toString();
}

