import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;

class MediaService {
  /// Strips EXIF metadata and applies a "Safety Crop" (bottom 10%) to remove visual watermarks.
  static Future<File?> processImage(File file) async {
    try {
      // 1. Load the image for cropping
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return null;

      // 2. Perform Safety Crop (trim bottom 10%)
      // Most camera watermarks are in the bottom corners.
      final cropHeight = (image.height * 0.90).toInt();
      final croppedImage = img.copyCrop(
        image,
        x: 0,
        y: 0,
        width: image.width,
        height: cropHeight,
      );

      // 3. Save the cropped image to a temporary file
      final tempDir = await getTemporaryDirectory();
      final croppedPath = p.join(tempDir.path, "cropped_${DateTime.now().millisecondsSinceEpoch}.jpg");
      await File(croppedPath).writeAsBytes(img.encodeJpg(croppedImage, quality: 90));

      // 4. Further compress and ensure EXIF is stripped
      final finalPath = p.join(tempDir.path, "anon_${DateTime.now().millisecondsSinceEpoch}.jpg");
      final result = await FlutterImageCompress.compressAndGetFile(
        croppedPath,
        finalPath,
        quality: 80,
        keepExif: false, // Double check metadata is gone
        format: CompressFormat.jpeg,
      );

      // Cleanup intermediate file
      final intermediateFile = File(croppedPath);
      if (await intermediateFile.exists()) {
        await intermediateFile.delete();
      }

      return result != null ? File(result.path) : null;
    } catch (e) {
      return null;
    }
  }

  /// Re-encodes video to strip metadata. 
  /// Note: video_compress doesn't easily support arbitrary cropping via API, 
  /// but re-encoding itself often strips identifying metadata.
  static Future<File?> processVideo(File file) async {
    try {
      final info = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.DefaultQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      return info?.file;
    } catch (e) {
      return null;
    }
  }

  /// Clean up video compression cache
  static Future<void> dispose() async {
    await VideoCompress.deleteAllCache();
  }
}
