// Stub for web platform (dart:io not available)
class File {
  final String path;
  File(this.path);
  
  Future<bool> exists() async => false;
}

class Directory {
  final String path;
  Directory(this.path);
  
  Future<bool> exists() async => false;
  Future<Directory> create({bool recursive = false}) async => this;
}
