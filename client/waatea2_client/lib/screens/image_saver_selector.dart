// Corrected to conditional import
import 'image_saver.dart';
import 'image_saver_desktop.dart';
import 'image_saver_selector.dart';
import 'package:flutter/foundation.dart';


export 'image_saver_web.dart' if (dart.library.io) 'image_saver_desktop.dart';

ImageSaver getImageSaver() {
  // if (kIsWeb) {
  //   return WebImageSaver(); // Web-specific image saver
  // } else {
    return DesktopImageSaver(); // Desktop-specific image saver (Linux, macOS, Windows)
  }
//}
