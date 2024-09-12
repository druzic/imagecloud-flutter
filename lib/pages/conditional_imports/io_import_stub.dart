// conditional_imports/io_import_stub.dart
// This is the stub file for when 'dart:io' is not available (e.g., on the web).

class Platform {
  static bool get isAndroid => false;
  static bool get isIOS => false;
}

class Directory {
  String? path;
}
