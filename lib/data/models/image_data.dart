class ImageData {
  final String url;
  final String name;
  final String? localPath; // Path to cached file on device

  ImageData({
    required this.url,
    required this.name,
    this.localPath,
  });

  ImageData copyWith({
    String? url,
    String? name,
    String? localPath,
  }) {
    return ImageData(
      url: url ?? this.url,
      name: name ?? this.name,
      localPath: localPath ?? this.localPath,
    );
  }
}

