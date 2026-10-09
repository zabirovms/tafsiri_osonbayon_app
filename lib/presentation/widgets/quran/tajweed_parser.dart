import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parseFragment;
import 'package:html/dom.dart' as dom;
import '../../../core/utils/tajweed_rules.dart';

/// Parses a Tajweed word string containing rule tags (e.g. `<rule class="ghunnah">نَّ</rule>`)
/// into a styled `TextSpan` with theme-adaptive Tajweed colors.
TextSpan parseTajweedWord({
  required String wordText,
  required TextStyle baseStyle,
  required BuildContext context,
  int? wordIndex,
  VoidCallback? onWordTap,
}) {
  final spans = <TextSpan>[];
  final brightness = Theme.of(context).brightness;
  final isLight = brightness == Brightness.light;
  final tajweedColors = getTajweedThemeColors(isLight);

  final defaultColor = baseStyle.color ??
      Theme.of(context).textTheme.bodyMedium?.color ??
      (isLight ? Colors.black : Colors.white);

  final processingStyle = baseStyle.copyWith(color: defaultColor);

  void processNode(dom.Node node, Color currentColor) {
    if (node.nodeType == dom.Node.TEXT_NODE) {
      spans.add(
        TextSpan(
          text: node.text,
          style: processingStyle.copyWith(color: currentColor),
          recognizer: onWordTap != null
              ? (TapGestureRecognizer()..onTap = onWordTap)
              : null,
        ),
      );
    } else if (node.nodeType == dom.Node.ELEMENT_NODE) {
      final element = node as dom.Element;
      Color nextColor = currentColor;

      if (element.localName == "rule") {
        final ruleClass = element.attributes["class"];
        if (ruleClass != null && tajweedColors.containsKey(ruleClass)) {
          nextColor = tajweedColors[ruleClass]!;
        }
      }

      if (element.nodes.isNotEmpty) {
        for (final childNode in element.nodes) {
          processNode(childNode, nextColor);
        }
      }
    }
  }

  final fragment = parseFragment('$wordText ');
  for (final node in fragment.nodes) {
    processNode(node, defaultColor);
  }

  return TextSpan(children: spans, style: processingStyle);
}
