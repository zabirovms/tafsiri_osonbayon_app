/// Strips HTML tags and decodes entities to produce plain formatted text.
/// Preserves paragraph/line breaks for readability.
String stripHtmlToPlainText(String html) {
  if (html.isEmpty) return '';
  String s = html;

  // Block boundaries -> newlines before stripping tags
  s = s.replaceAll(RegExp(r'</(?:p|div|tr|li|h[1-6])>\s*', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'<br\s*/?>\s*', caseSensitive: false), '\n');

  // Remove all remaining tags
  s = s.replaceAll(RegExp(r'<[^>]*>'), '');

  // Decode common HTML entities
  const entities = {
    '&quot;': '"',
    '&#34;': '"',
    '&amp;': '&',
    '&#38;': '&',
    '&lt;': '<',
    '&#60;': '<',
    '&gt;': '>',
    '&#62;': '>',
    '&nbsp;': ' ',
    '&#160;': ' ',
    '&apos;': "'",
    '&#39;': "'",
  };
  for (final e in entities.entries) {
    s = s.replaceAll(e.key, e.value);
  }

  // Numeric character references (&#123; and &#x7B;)
  s = s.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
    final g = m.group(1);
    if (g == null) return m.group(0) ?? '';
    final code = int.tryParse(g, radix: 16);
    return code != null && code > 0 && code < 0x10FFFF ? String.fromCharCode(code) : (m.group(0) ?? '');
  });
  s = s.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
    final g = m.group(1);
    if (g == null) return m.group(0) ?? '';
    final code = int.tryParse(g);
    return code != null && code > 0 && code < 0x10FFFF ? String.fromCharCode(code) : (m.group(0) ?? '');
  });

  // Normalize whitespace: collapse multiple newlines to at most 2, collapse spaces, trim
  s = s.replaceAll(RegExp(r'[ \t]+'), ' ');
  s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return s.trim();
}
