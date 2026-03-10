import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import 'package:exif/exif.dart';

class MediaService {
  
  static Future<Map<String, dynamic>?> processImage(File file, {Map<String, double>? fallbackGps}) async {
    try {
      final bytes = await file.readAsBytes();

      // --- 1. EXTRACT GPS METADATA USING A DEDICATED PACKAGE ---
      Map<String, double>? gpsData;
      final Map<String, IfdTag> exifData = await readExifFromBytes(bytes);

      // Helper to find tags regardless of group prefix
      IfdTag? findTag(List<String> variants) {
        for (var v in variants) {
          if (exifData.containsKey(v)) return exifData[v];
        }
        return null;
      }

      final latTag = findTag(['GPS GPSLatitude', 'GPS Latitude', 'Latitude']);
      final lonTag = findTag(['GPS GPSLongitude', 'GPS Longitude', 'Longitude']);
      final latRefTag = findTag(['GPS GPSLatitudeRef', 'GPS LatitudeRef', 'LatitudeRef']);
      final lonRefTag = findTag(['GPS GPSLongitudeRef', 'GPS LongitudeRef', 'LongitudeRef']);

      String source = "exif";
      if (latTag != null && lonTag != null) {
        final latRef = latRefTag?.toString() ?? 'N';
        final lonRef = lonRefTag?.toString() ?? 'E';

        double convertToDecimal(IfdTag tag, String ref) {
          final values = tag.values.toList();
          if (values.length < 3) return 0.0;
          final double d = values[0].toDouble();
          final double m = values[1].toDouble();
          final double s = values[2].toDouble();
          double res = d + (m / 60.0) + (s / 3600.0);
          if (ref == 'S' || ref == 'W') res = -res;
          return res;
        }

        gpsData = {
          'latitude': convertToDecimal(latTag, latRef),
          'longitude': convertToDecimal(lonTag, lonRef),
        };
        print("ADAR_DEBUG: Real GPS Metadata Extracted: $gpsData");
      } else if (fallbackGps != null) {
        gpsData = fallbackGps;
        source = "device_signature";
        print("ADAR_DEBUG: Using Device Signature Fallback: $gpsData");
      } else {
        print("ADAR_DEBUG: No GPS Metadata found and no fallback provided.");
      }

      // --- 2. OFF-LOAD HEAVY PROCESSING TO ISOLATE ---
      final tempDir = await getTemporaryDirectory();
      final finalPath = p.join(tempDir.path, "processed_${DateTime.now().millisecondsSinceEpoch}.jpg");

      await compute(_isolateImageProcessing, _ImageProcessTask(bytes, finalPath));

      return {
        'file': File(finalPath),
        'metadata': gpsData,
        'source': source,
      };
    } catch (e) {
      return null;
    }
  }

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

  static Future<void> dispose() async {
    await VideoCompress.deleteAllCache();
  }
}

/// Helper class for image processing in Isolate
class _ImageProcessTask {
  final Uint8List bytes;
  final String outputPath;
  _ImageProcessTask(this.bytes, this.outputPath);
}

/// Top-level function for compute to handle heavy image work
Future<void> _isolateImageProcessing(_ImageProcessTask task) async {
  var image = img.decodeImage(task.bytes);
  if (image == null) return;

  // --- 1. RESIZE IF TOO LARGE (Max 1600px width/height) ---
  if (image.width > 1600 || image.height > 1600) {
    image = img.copyResize(image, width: image.width > image.height ? 1600 : null, height: image.height >= image.width ? 1600 : null);
  }

  // --- 2. CROP BOTTOM 10% (As per existing logic) ---
  final cropHeight = (image.height * 0.90).toInt();
  final croppedImage = img.copyCrop(
    image,
    x: 0,
    y: 0,
    width: image.width,
    height: cropHeight,
  );

  // --- 3. ENCODE WITH OPTIMIZED QUALITY (80) ---
  final encodedBytes = img.encodeJpg(croppedImage, quality: 80);
  await File(task.outputPath).writeAsBytes(encodedBytes);
}
