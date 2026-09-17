import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'image_saver.dart';

class WebImageSaver implements ImageSaver {
  @override
  Future<void> save(Uint8List imageBytes) async {
    final blob = web.Blob([imageBytes.toJS].toJS);

    final url = web.URL.createObjectURL(blob);

    final anchor =
        web.HTMLAnchorElement()
          ..href = url
          ..download = 'match_result.png';

    anchor.click();

    web.URL.revokeObjectURL(url);
  }
}
