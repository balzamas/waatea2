import 'dart:typed_data';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'image_saver.dart';

class DesktopImageSaver implements ImageSaver {
  @override
  Future<void> save(Uint8List imageBytes) async {
    final dir = await getDownloadsDirectory();
    final path = '${dir!.path}/match_result.png';
    final file = File(path);
    await file.writeAsBytes(imageBytes);
    print('Saved to $path');
  }
}
