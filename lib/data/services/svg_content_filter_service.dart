import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

/// Service for filtering SVG content to extract only the main content area
/// Removes decorative elements on the left and right sides while preserving top and bottom
class SvgContentFilterService {
  // Singleton pattern
  static final SvgContentFilterService _instance = SvgContentFilterService._internal();
  factory SvgContentFilterService() => _instance;
  SvgContentFilterService._internal();

  // Cache for filtered SVGs to avoid re-processing
  final Map<String, String> _filteredSvgCache = {};

  /// Fetch SVG from URL and filter to keep only main content area
  /// Returns filtered SVG string
  Future<String> fetchAndFilterSvg(String svgUrl) async {
    // Check cache first
    if (_filteredSvgCache.containsKey(svgUrl)) {
      return _filteredSvgCache[svgUrl]!;
    }

    try {
      // Fetch SVG as string
      final response = await http.get(Uri.parse(svgUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch SVG: ${response.statusCode}');
      }

      final svgString = utf8.decode(response.bodyBytes);
      
      // Validate we got actual SVG content
      if (!svgString.contains('<svg') || svgString.length < 100) {
        throw Exception('Invalid SVG content received');
      }
      
      // Filter the SVG
      debugPrint('=== Starting SVG filtering for: $svgUrl ===');
      debugPrint('Original SVG size: ${svgString.length} chars');
      final filteredSvg = _filterSvgContent(svgString, svgUrl);
      debugPrint('After filtering, result size: ${filteredSvg.length} chars');
      
      // Validate filtered result
      if (!filteredSvg.contains('<svg') || filteredSvg.length < 100) {
        debugPrint('Warning: Filtered SVG is invalid (${filteredSvg.length} chars), using original');
        _filteredSvgCache[svgUrl] = svgString;
        return svgString;
      }
      
      debugPrint('SVG filtering completed: original=${svgString.length} chars, filtered=${filteredSvg.length} chars');
      
      // Only cache if the filtered result is reasonable (at least 5% of original for pages 3+)
      final pageNumber = _extractPageNumberFromUrl(svgUrl);
      if (pageNumber == null || pageNumber <= 2 || filteredSvg.length >= svgString.length * 0.05) {
        _filteredSvgCache[svgUrl] = filteredSvg;
      } else {
        debugPrint('Warning: Not caching filtered SVG for page $pageNumber (too small), will use original next time');
        _filteredSvgCache[svgUrl] = svgString; // Cache original instead
      }
      
      return filteredSvg;
    } catch (e, stackTrace) {
      // If filtering fails, return original SVG
      debugPrint('Error filtering SVG: $e');
      debugPrint('Stack trace: $stackTrace');
      try {
        final response = await http.get(Uri.parse(svgUrl));
        final originalSvg = utf8.decode(response.bodyBytes);
        // Cache original as fallback
        _filteredSvgCache[svgUrl] = originalSvg;
        return originalSvg;
      } catch (fetchError) {
        rethrow;
      }
    }
  }

  /// Filter SVG content based on page-specific rules
  String _filterSvgContent(String svgString, String svgUrl) {
    try {
      final document = XmlDocument.parse(svgString);
      final svgElement = document.rootElement;

      // Extract page number from URL (e.g., "003.svg" from URL)
      final pageNumber = _extractPageNumberFromUrl(svgUrl);
      
      if (pageNumber == null) {
        debugPrint('Warning: Could not extract page number from URL, returning original');
        return svgString;
      }

      debugPrint('Processing page $pageNumber from URL: $svgUrl');

      // Skip pages 1 and 2 (keep them as is)
      if (pageNumber <= 2) {
        return svgString;
      }
      
      // For pages 3+, extract only 3rd and 4th groups - NO FALLBACK
      _extractAndCenterGroups(svgElement, pageNumber);
      
      // Return the modified SVG - no validation, no fallback
      return document.toXmlString(pretty: false);
    } catch (e, stackTrace) {
      debugPrint('Error parsing SVG: $e');
      debugPrint('Stack trace: $stackTrace');
      return svgString; // Return original if parsing fails
    }
  }

  /// Extract page number from SVG URL
  /// Returns null if page number cannot be extracted
  int? _extractPageNumberFromUrl(String url) {
    try {
      // URL format: https://storage.googleapis.com/quran-tajik/quran-pages-svg/003.svg
      final match = RegExp(r'/(\d{3})\.svg').firstMatch(url);
      if (match != null) {
        return int.tryParse(match.group(1) ?? '');
      }
      return null;
    } catch (e) {
      debugPrint('Error extracting page number: $e');
      return null;
    }
  }

  /// Keep root <g> with its transform, navigate to g14, extract only 3rd and 4th groups, wrap them in centered container
  /// Used for pages 3 and above (pages 1 and 2 are kept as is)
  /// Returns true if extraction was successful, false otherwise
  bool _extractAndCenterGroups(XmlElement svgElement, int pageNumber) {
    try {
      // Find the root <g> element (typically has id="g10" or is the first major group)
      XmlElement? rootGroup;
      
      // Look for the root group - typically it's the first <g> child after defs/metadata
      for (final child in svgElement.children) {
        if (child is XmlElement && child.localName == 'g') {
          rootGroup = child;
          break;
        }
      }
      
      if (rootGroup == null) return false;
      
      XmlElement? g12;
      for (final child in rootGroup.children) {
        if (child is XmlElement && child.localName == 'g') {
          g12 = child;
          break;
        }
      }
      if (g12 == null) return false;
      
      XmlElement? g14;
      for (final child in g12.children) {
        if (child is XmlElement && child.localName == 'g') {
          final clipPath = child.getAttribute('clip-path');
          if (clipPath != null && clipPath.contains('clipPath')) {
            g14 = child;
            break;
          }
        }
      }
      if (g14 == null) return false;
      
      // Get ALL children of g14 (not just <g> elements)
      final allG14Children = g14.children.toList();
      
      // Find all <g> children to identify which ones to keep
      final gChildren = allG14Children
          .whereType<XmlElement>()
          .where((child) => child.localName == 'g')
          .toList();
      
      if (gChildren.length < 4) return false;
      
      // Get the 3rd and 4th groups (indices 2 and 3)
      final thirdG = gChildren[2];
      final fourthG = gChildren[3];
      
      // Clone them by serializing and parsing
      final thirdGString = thirdG.toXmlString(pretty: false);
      final fourthGString = fourthG.toXmlString(pretty: false);
      
      final thirdGXmlDoc = XmlDocument.parse('<temp>$thirdGString</temp>');
      final fourthGXmlDoc = XmlDocument.parse('<temp>$fourthGString</temp>');
      
      final thirdGClone = thirdGXmlDoc.rootElement.children
          .whereType<XmlElement>()
          .firstOrNull;
      final fourthGClone = fourthGXmlDoc.rootElement.children
          .whereType<XmlElement>()
          .firstOrNull;
      
      if (thirdGClone == null || fourthGClone == null) return false;
      
      // First, remove ALL other children from g12 (like g70, etc.) - only keep g14
      final allG12Children = g12.children.toList();
      for (final child in allG12Children) {
        if (child is XmlElement && child != g14) {
          g12.children.remove(child);
        }
      }
      
      // Now remove ALL children from g14 - including 1st and 2nd groups
      final allG14ChildrenCopy = g14.children.toList();
      for (final child in allG14ChildrenCopy) {
        g14.children.remove(child);
      }
      
      // Add back ONLY the cloned 3rd and 4th groups - NOTHING ELSE
      g14.children.add(thirdGClone);
      g14.children.add(fourthGClone);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear the cache (useful for memory management)
  void clearCache() {
    _filteredSvgCache.clear();
  }

  /// Get cache size
  int getCacheSize() {
    return _filteredSvgCache.length;
  }
}
