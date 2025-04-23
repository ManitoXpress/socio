/// File: lib/utils/image_utils.dart
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageUtils {
  static Future<File> compressAndResize(File file) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes)!;
    final resized = img.copyResize(image, width: 600);
    final jpg = img.encodeJpg(resized, quality: 50);
    final dir = await getTemporaryDirectory();
    final target = File('${dir.path}/comp_${DateTime.now().millisecondsSinceEpoch}.jpg');
    return target..writeAsBytesSync(jpg);
  }
}