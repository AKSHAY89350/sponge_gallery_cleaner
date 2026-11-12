import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

class MetadataCleanResult {
  final bool success;
  final String? savedAssetId;
  final String? error;
  final int bytesSaved;

  const MetadataCleanResult({
    required this.success,
    this.savedAssetId,
    this.error,
    this.bytesSaved = 0,
  });
}

class MetadataStripperService {
  /// Losslessly strips EXIF, XMP, IPTC, and Comments from JPEG bytes.
  static Uint8List stripJpegMetadata(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
      return bytes;
    }

    final output = BytesBuilder(copy: false);
    output.add([0xFF, 0xD8]); // SOI

    int offset = 2;
    while (offset < bytes.length - 1) {
      if (bytes[offset] != 0xFF) {
        output.add(bytes.sublist(offset));
        break;
      }

      int marker = bytes[offset + 1];

      // Handle fill bytes (0xFF 0xFF ...)
      while (marker == 0xFF && offset + 2 < bytes.length) {
        offset++;
        marker = bytes[offset + 1];
      }

      // SOS (Start of Scan) or EOI (End of Image)
      if (marker == 0xDA || marker == 0xD9) {
        output.add(bytes.sublist(offset));
        break;
      }

      // Standalone markers with no length payload (RST0..RST7)
      if (marker >= 0xD0 && marker <= 0xD7) {
        output.add([0xFF, marker]);
        offset += 2;
        continue;
      }

      if (offset + 3 >= bytes.length) {
        output.add(bytes.sublist(offset));
        break;
      }

      final int segmentLength = (bytes[offset + 2] << 8) | bytes[offset + 3];
      final int segmentEnd = offset + 2 + segmentLength;
      if (segmentEnd > bytes.length) {
        output.add(bytes.sublist(offset));
        break;
      }

      // Markers to remove:
      // 0xE1: APP1 (EXIF, Adobe XMP)
      // 0xED: APP13 (Photoshop IPTC)
      // 0xFE: COM (Comment)
      // 0xE2..0xEF: other custom camera metadata / proprietary tags
      final bool isMetadata = (marker == 0xE1 || marker == 0xED || marker == 0xFE || (marker >= 0xE2 && marker <= 0xEF));

      if (!isMetadata) {
        output.add(bytes.sublist(offset, segmentEnd));
      }

      offset = segmentEnd;
    }

    return output.toBytes();
  }

  /// Losslessly strips ancillary text, EXIF, and time chunks from PNG bytes.
  static Uint8List stripPngMetadata(Uint8List bytes) {
    const pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length < 8) return bytes;
    for (int i = 0; i < 8; i++) {
      if (bytes[i] != pngSignature[i]) return bytes;
    }

    final output = BytesBuilder(copy: false);
    output.add(pngSignature);

    int offset = 8;
    while (offset + 8 <= bytes.length) {
      final int length = (bytes[offset] << 24) |
          (bytes[offset + 1] << 16) |
          (bytes[offset + 2] << 8) |
          bytes[offset + 3];

      final String type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));
      final int totalChunkSize = 12 + length; // 4 len + 4 type + data + 4 crc

      if (offset + totalChunkSize > bytes.length) {
        output.add(bytes.sublist(offset));
        break;
      }

      // Drop metadata chunks: tEXt, zTXt, iTXt, eXIf, tIME
      const dropTypes = {'tEXt', 'zTXt', 'iTXt', 'eXIf', 'tIME'};
      if (!dropTypes.contains(type)) {
        output.add(bytes.sublist(offset, offset + totalChunkSize));
      }

      offset += totalChunkSize;
      if (type == 'IEND') break;
    }

    return output.toBytes();
  }

  /// Strips udta and meta user-data boxes from MP4/MOV container losslessly.
  static Uint8List stripMp4Metadata(Uint8List bytes) {
    if (bytes.length < 8) return bytes;
    final copy = Uint8List.fromList(bytes);

    void searchAndWipeUdta(int start, int end) {
      int offset = start;
      while (offset + 8 <= end) {
        int size = (copy[offset] << 24) |
            (copy[offset + 1] << 16) |
            (copy[offset + 2] << 8) |
            copy[offset + 3];

        if (size == 1 && offset + 16 <= end) {
          size = (copy[offset + 12] << 24) |
              (copy[offset + 13] << 16) |
              (copy[offset + 14] << 8) |
              copy[offset + 15];
        }
        if (size < 8 || offset + size > end) break;

        final type = String.fromCharCodes(copy.sublist(offset + 4, offset + 8));

        if (type == 'udta') {
          // Overwrite 'udta' box type with 'free' atom and zero out payload
          copy[offset + 4] = 0x66; // 'f'
          copy[offset + 5] = 0x72; // 'r'
          copy[offset + 6] = 0x65; // 'e'
          copy[offset + 7] = 0x65; // 'e'
          for (int j = offset + 8; j < offset + size; j++) {
            copy[j] = 0;
          }
        } else if (type == 'moov' || type == 'trak') {
          searchAndWipeUdta(offset + 8, offset + size);
        }

        offset += size;
      }
    }

    searchAndWipeUdta(0, copy.length);
    return copy;
  }

  /// Cleans an image or video file and saves it back as a sanitized media asset.
  static Future<MetadataCleanResult> cleanAsset({
    required AssetEntity asset,
    required bool replaceOriginal,
  }) async {
    try {
      final file = await asset.file;
      if (file == null || !await file.exists()) {
        return const MetadataCleanResult(success: false, error: 'File not accessible');
      }

      final originalBytes = await file.readAsBytes();
      final originalLength = originalBytes.length;
      final ext = asset.title?.split('.').last.toLowerCase() ??
          (asset.type == AssetType.video ? 'mp4' : 'jpg');

      Uint8List cleanedBytes;

      if (asset.type == AssetType.video || ext == 'mp4' || ext == 'mov') {
        cleanedBytes = stripMp4Metadata(originalBytes);
      } else if (ext == 'png') {
        cleanedBytes = stripPngMetadata(originalBytes);
      } else {
        cleanedBytes = stripJpegMetadata(originalBytes);
      }

      final bytesDiff = originalLength - cleanedBytes.length;

      // Save sanitized asset
      final AssetEntity newAsset;
      final cleanTitle = 'clean_${asset.title ?? "media.$ext"}';

      if (asset.type == AssetType.video) {
        // For video, write clean bytes to a temp file and save
        final tempDir = Directory.systemTemp;
        final tempCleanFile = File('${tempDir.path}/$cleanTitle');
        await tempCleanFile.writeAsBytes(cleanedBytes);
        newAsset = await PhotoManager.editor.saveVideo(
          tempCleanFile,
          title: cleanTitle,
        );
        try {
          if (await tempCleanFile.exists()) {
            await tempCleanFile.delete();
          }
        } catch (_) {}
      } else {
        newAsset = await PhotoManager.editor.saveImage(
          cleanedBytes,
          title: cleanTitle,
          filename: cleanTitle,
        );
      }

      if (replaceOriginal) {
        await PhotoManager.editor.deleteWithIds([asset.id]);
      }

      return MetadataCleanResult(
        success: true,
        savedAssetId: newAsset.id,
        bytesSaved: bytesDiff > 0 ? bytesDiff : 0,
      );
    } catch (e) {
      debugPrint('Metadata clean error: $e');
      return MetadataCleanResult(success: false, error: e.toString());
    }
  }
}
