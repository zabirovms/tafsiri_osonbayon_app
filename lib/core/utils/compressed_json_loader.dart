import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Utility class for handling gzip-compressed JSON files.
/// Decompress + parse run in an isolate so the UI thread stays responsive.
class CompressedJsonLoader {
  /// Load compressed bytes from asset (main thread), then decompress + decode in isolate.
  static Future<String> loadCompressedJson(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = _copyByteData(data);
      return compute(_decodeGzipToString, bytes);
    } catch (e) {
      throw Exception('Failed to load compressed JSON from $assetPath: $e');
    }
  }

  /// Load JSON map: load bytes on main thread, decompress + parse in isolate.
  static Future<Map<String, dynamic>> loadCompressedJsonAsMap(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = _copyByteData(data);
      return compute(_decodeGzipJsonAsMap, bytes);
    } catch (e) {
      throw Exception('Failed to load compressed JSON from $assetPath: $e');
    }
  }

  /// Load JSON list: load bytes on main thread, decompress + parse in isolate.
  static Future<List<dynamic>> loadCompressedJsonAsList(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = _copyByteData(data);
      return compute(_decodeGzipJsonAsList, bytes);
    } catch (e) {
      throw Exception('Failed to load compressed JSON from $assetPath: $e');
    }
  }

  static Uint8List _copyByteData(ByteData data) {
    return Uint8List.fromList(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  /// Load a regular (non-compressed) JSON file and parse it as a List
  static Future<List<dynamic>> loadJsonAsList(String assetPath) async {
    try {
      final String jsonString = await rootBundle.loadString(assetPath);
      return json.decode(jsonString) as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to load JSON from $assetPath: $e');
    }
  }

  /// Load a regular (non-compressed) JSON file and parse it as a Map
  static Future<Map<String, dynamic>> loadJsonAsMap(String assetPath) async {
    try {
      final String jsonString = await rootBundle.loadString(assetPath);
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load JSON from $assetPath: $e');
    }
  }

  /// Parse a JSON string as Map in an isolate (keeps decode off the main thread).
  /// Use after rootBundle.loadString(assetPath) for small JSON assets.
  static Future<Map<String, dynamic>> parseJsonMapInIsolate(String jsonString) async {
    return compute(_parseJsonMapIsolate, jsonString);
  }
}

Map<String, dynamic> _parseJsonMapIsolate(String jsonString) {
  return jsonDecode(jsonString) as Map<String, dynamic>;
}

// Top-level functions for compute() — decompress + parse in isolate (keeps UI responsive).
String _decodeGzipToString(Uint8List compressedBytes) {
  final decoded = gzip.decode(compressedBytes);
  return utf8.decode(decoded);
}

Map<String, dynamic> _decodeGzipJsonAsMap(Uint8List compressedBytes) {
  final decoded = gzip.decode(compressedBytes);
  final jsonString = utf8.decode(decoded);
  return jsonDecode(jsonString) as Map<String, dynamic>;
}

List<dynamic> _decodeGzipJsonAsList(Uint8List compressedBytes) {
  final decoded = gzip.decode(compressedBytes);
  final jsonString = utf8.decode(decoded);
  return jsonDecode(jsonString) as List<dynamic>;
}
