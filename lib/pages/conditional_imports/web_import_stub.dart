// conditional_imports/web_import_stub.dart
// Stub class for non-web platforms to avoid errors

class AnchorElement {
  AnchorElement({required String href});

  String? download;
  String? target;

  void click() {
    throw UnsupportedError(
        'Downloading via AnchorElement is not supported on this platform.');
  }
}
