// Stub class for mobile and desktop platforms (no-op for AnchorElement)
class AnchorElement {
  AnchorElement({required String href});

  String? download;
  String? target;

  void click() {
    // No-op on mobile/desktop
    throw UnsupportedError('AnchorElement is not supported on this platform.');
  }
}
