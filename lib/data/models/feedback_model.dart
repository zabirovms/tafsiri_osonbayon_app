class FeedbackData {
  final String id;
  final DateTime createdAt;
  final String source;
  final int rating;
  final String category;
  final String message;
  final String? email;
  final Map<String, dynamic>? deviceInfo;
  final String? screenshotPath; // Local path for caching/resubmitting
  final String? screenshotUrl;  // Firebase Storage URL

  FeedbackData({
    required this.id,
    required this.createdAt,
    required this.source,
    required this.rating,
    required this.category,
    required this.message,
    this.email,
    this.deviceInfo,
    this.screenshotPath,
    this.screenshotUrl,
  });

  FeedbackData copyWith({
    String? id,
    DateTime? createdAt,
    String? source,
    int? rating,
    String? category,
    String? message,
    String? email,
    Map<String, dynamic>? deviceInfo,
    String? screenshotPath,
    String? screenshotUrl,
  }) {
    return FeedbackData(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      source: source ?? this.source,
      rating: rating ?? this.rating,
      category: category ?? this.category,
      message: message ?? this.message,
      email: email ?? this.email,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      screenshotPath: screenshotPath ?? this.screenshotPath,
      screenshotUrl: screenshotUrl ?? this.screenshotUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'source': source,
      'rating': rating,
      'category': category,
      'message': message,
      'email': email,
      'deviceInfo': deviceInfo,
      'screenshotPath': screenshotPath,
      'screenshotUrl': screenshotUrl,
    };
  }

  factory FeedbackData.fromJson(Map<String, dynamic> json) {
    return FeedbackData(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      source: json['source'] as String,
      rating: json['rating'] as int,
      category: json['category'] as String,
      message: json['message'] as String,
      email: json['email'] as String?,
      deviceInfo: json['deviceInfo'] != null
          ? Map<String, dynamic>.from(json['deviceInfo'] as Map)
          : null,
      screenshotPath: json['screenshotPath'] as String?,
      screenshotUrl: json['screenshotUrl'] as String?,
    );
  }
}
