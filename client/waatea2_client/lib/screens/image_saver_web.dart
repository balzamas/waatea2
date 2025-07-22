import 'dart:typed_data';
import 'dart:html' as html;

import 'image_saver.dart';

class WebImageSaver implements ImageSaver {
  @override
  Future<void> save(Uint8List imageBytes) async {
    final blob = html.Blob([imageBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "match_result.png")
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
