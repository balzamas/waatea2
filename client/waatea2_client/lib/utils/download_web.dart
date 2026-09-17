import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

void downloadBytes(Uint8List bytes, String filename) {
  final blob = web.Blob([bytes.toJS].toJS);

  final url = web.URL.createObjectURL(blob);

  final anchor =
      web.HTMLAnchorElement()
        ..href = url
        ..download = filename;

  anchor.click();

  web.URL.revokeObjectURL(url);
}

void downloadText(String content, String filename) {
  downloadBytes(Uint8List.fromList(utf8.encode(content)), filename);
}
