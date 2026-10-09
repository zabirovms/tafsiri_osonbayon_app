import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

/// Helper utility for cross-platform sharing with iOS popover positioning support.
class ShareHelper {
  ShareHelper._();

  /// Extract bounding box from [BuildContext] for iOS `sharePositionOrigin` anchor positioning.
  static Rect? getSharePositionOrigin(BuildContext? context) {
    if (context == null) return null;
    try {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize && box.attached) {
        final position = box.localToGlobal(Offset.zero);
        return position & box.size;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ShareHelper] Failed to compute share position origin: $e');
      }
    }
    return null;
  }

  /// Safely share text string across Android & iOS.
  static Future<ShareResult> share(
    String text, {
    String? subject,
    BuildContext? context,
  }) async {
    final origin = getSharePositionOrigin(context);
    return await Share.share(
      text,
      subject: subject,
      sharePositionOrigin: origin,
    );
  }

  /// Safely share files ([XFile]) across Android & iOS.
  static Future<ShareResult> shareXFiles(
    List<XFile> files, {
    String? text,
    String? subject,
    BuildContext? context,
  }) async {
    final origin = getSharePositionOrigin(context);
    return await Share.shareXFiles(
      files,
      text: text,
      subject: subject,
      sharePositionOrigin: origin,
    );
  }
}
