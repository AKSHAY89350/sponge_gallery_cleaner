import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class BlurDetector {
  static Future<bool> isImageBlurry(Uint8List bytes) async {
    return compute(_calculateBlurOptionB, bytes);
  }

  // OPTION B: High Precision Laplacian Variance Algorithm
  static bool _calculateBlurOptionB(Uint8List bytes) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return false;

      // In Option B, we use a much higher resolution (512x512) for precision
      // instead of 256. This takes ~4x more CPU and RAM.
      final resize = img.copyResize(image, width: 512);

      // Strict luminance calculation (High fidelity grayscale)
      final width = resize.width;
      final height = resize.height;
      final gray = List<double>.filled(width * height, 0.0);

      int idx = 0;
      for (final p in resize) {
        // Rec. 709 luma coefficients
        gray[idx++] = (p.r * 0.2126 + p.g * 0.7152 + p.b * 0.0722).toDouble();
      }

      // 3x3 Laplacian Convolution Kernel
      double sumLaplacian = 0.0;
      double sumLaplacianSq = 0.0;
      int count = 0;

      for (int y = 1; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) {
          final center = gray[y * width + x];
          final top = gray[(y - 1) * width + x];
          final bottom = gray[(y + 1) * width + x];
          final left = gray[y * width + (x - 1)];
          final right = gray[y * width + (x + 1)];

          final lap = top + bottom + left + right - (4 * center);

          sumLaplacian += lap;
          sumLaplacianSq += lap * lap;
          count++;
        }
      }

      if (count == 0) return false;

      final mean = sumLaplacian / count;
      final variance = (sumLaplacianSq / count) - (mean * mean);

      // High precision threshold (adjustable).
      // Higher variance = sharper image. Lower variance = blurry.
      return variance < 80.0;
    } catch (e) {
      return false;
    }
  }
}
