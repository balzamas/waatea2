import 'dart:typed_data';

void downloadBytes(Uint8List bytes, String filename) {
  throw UnsupportedError('Browser download is only available on web.');
}

void downloadText(String content, String filename) {
  throw UnsupportedError('Browser download is only available on web.');
}
