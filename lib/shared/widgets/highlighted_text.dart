import 'package:flutter/material.dart';

class HighlightedText extends StatelessWidget {
  final String text;
  final String highlight;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final int? maxLines;
  final TextOverflow? overflow;

  const HighlightedText({
    super.key,
    required this.text,
    required this.highlight,
    this.style,
    this.highlightStyle,
    this.textAlign,
    this.textDirection,
    this.maxLines,
    this.overflow,
  });

  // Find all matches - use exact matching for Arabic (diacritics are part of meaning)
  List<_Match> _findMatches(String originalText, String originalHighlight) {
    final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(originalText) || 
                     RegExp(r'[\u0600-\u06FF]').hasMatch(originalHighlight);
    
    String searchText;
    String searchHighlight;
    
    if (isArabic) {
      // For Arabic, use exact matching (diacritics are part of the word meaning)
      searchText = originalText;
      searchHighlight = originalHighlight;
    } else {
      // For non-Arabic, use case-insensitive matching
      searchText = originalText.toLowerCase();
      searchHighlight = originalHighlight.toLowerCase();
    }
    
    if (searchHighlight.isEmpty || !searchText.contains(searchHighlight)) {
      return [];
    }
    
    final matches = <_Match>[];
    int searchStart = 0;
    
    while (searchStart < searchText.length) {
      final index = searchText.indexOf(searchHighlight, searchStart);
      if (index == -1) break;
      
      // For exact matching, positions in searchText match originalText
      matches.add(_Match(index, index + searchHighlight.length));
      searchStart = index + searchHighlight.length;
    }
    
    return matches;
  }

  @override
  Widget build(BuildContext context) {
    if (highlight.isEmpty || text.isEmpty) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        textDirection: textDirection,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final matches = _findMatches(text, highlight);
    
    if (matches.isEmpty) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        textDirection: textDirection,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    // Ensure we have a default color - use style color or create a default
    // When style is provided, use it; otherwise create a style that will inherit from theme
    final defaultTextStyle = style ?? const TextStyle();
    
    final List<TextSpan> spans = [];
    int lastEnd = 0;
    
    for (final match in matches) {
      // Add text before match - ensure it has all style properties including color
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: defaultTextStyle,
        ));
      }
      
      // Add highlighted text - merge with base style to preserve all properties
      final baseHighlightStyle = highlightStyle ?? 
               defaultTextStyle.copyWith(
                 backgroundColor: Colors.yellow.withValues(alpha: 0.3),
                 fontWeight: FontWeight.bold,
               );
      
      // Ensure highlight style inherits color from base style if not explicitly set
      final finalHighlightStyle = baseHighlightStyle.color == null 
          ? baseHighlightStyle.copyWith(color: defaultTextStyle.color)
          : baseHighlightStyle;
      
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: finalHighlightStyle,
      ));
      
      lastEnd = match.end;
    }
    
    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: defaultTextStyle,
      ));
    }

    return RichText(
      text: TextSpan(
        style: defaultTextStyle,
        children: spans,
      ),
      textAlign: textAlign ?? TextAlign.start,
      textDirection: textDirection,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}

class _Match {
  final int start;
  final int end;
  
  _Match(this.start, this.end);
}
