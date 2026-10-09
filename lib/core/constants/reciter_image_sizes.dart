/// Standard image sizes for reciter images across the app
/// Follows Material Design 3 guidelines and ensures consistency
class ReciterImageSizes {
  /// Small size (40x40) - Used in:
  /// - List items
  /// - Mini audio player
  /// - Expansion tiles
  static const double small = 40.0;

  /// Medium size (56-64x56-64) - Used in:
  /// - Last seen cards
  /// - Translation cards
  static const double medium = 64.0;

  /// Large size (80-128x80-128) - Used in:
  /// - Profile headers
  /// - Grid cards
  static const double large = 128.0;

  /// Extra large size (200-300x200-300) - Used in:
  /// - Full player album art
  static const double extraLarge = 200.0;

  /// Get border radius for circular images based on size
  static double getCircularRadius(double size) {
    return size / 2;
  }

  /// Get standard border radius for rounded rectangles
  static const double standardBorderRadius = 12.0;
}
























