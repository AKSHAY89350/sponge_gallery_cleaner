import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class BlurDetector {
  static Future<bool> isImageBlurry(Uint8List bytes) async {
    return compute(_calculateBlur, bytes);
  }

  static bool _calculateBlur(Uint8List bytes) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return false;

      // Resize for performance
      final small = img.copyResize(image, width: 256);
      
      // Convert to grayscale
      final grayscale = img.grayscale(small);

      // Simple laplacian variance
      // Since convolution might be slow or API might differ in image package,
      // we can do manual laplacian calculation.
      
      double sum = 0;
      int count = 0;
      final width = grayscale.width;
      final height = grayscale.height;

      // Calculate laplacian and mean
      for (int y = 1; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) {
          final top = grayscale.getPixel(x, y - 1).r;
          final bottom = grayscale.getPixel(x, y + 1).r;
          final left = grayscale.getPixel(x - 1, y).r;
          final right = grayscale.getPixel(x + 1, y).r;
          final center = grayscale.getPixel(x, y).r;

          // Laplacian = top + bottom + left + right - 4 * center
          final laplacian = (top + bottom + left + right - 4 * center).abs();
          
          sum += laplacian;
          count++;
        }
      }

      final mean = sum / count;

      // Calculate variance
      double varianceSum = 0;
      for (int y = 1; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) {
          final top = grayscale.getPixel(x, y - 1).r;
          final bottom = grayscale.getPixel(x, y + 1).r;
          final left = grayscale.getPixel(x - 1, y).r;
          final right = grayscale.getPixel(x + 1, y).r;
          final center = grayscale.getPixel(x, y).r;

          final laplacian = (top + bottom + left + right - 4 * center).abs();
          varianceSum += (laplacian - mean) * (laplacian - mean);
        }
      }

      final variance = varianceSum / count;

      // Threshold: if variance is very low, it lacks edges -> blurry
      return variance < 100.0;
    } catch (e) {
      return false;
    }
  }
}
