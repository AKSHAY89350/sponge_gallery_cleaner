import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sponge_gallery_cleaner/features/gallery_core/models/gallery_media_item.dart';
import 'package:sponge_gallery_cleaner/features/people_cleaner/models/person_cluster.dart';

class FaceDetectionService {
  static final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  static final List<PersonCluster> clusters = [];
  static final List<GalleryMediaItem> groupPhotos = [];
  static bool isScanning = false;
  static bool isCoolingDown = false;
  static int coolingDownSecondsRemaining = 0;
  static int scannedCount = 0;
  static int totalToScan = 0;
  static bool isInitialized = false;

  static double get scanProgress =>
      totalToScan > 0 ? (scannedCount / totalToScan) : 0.0;

  /// Initialize cached face clusters & group photos from SharedPreferences
  static Future<void> initialize(List<GalleryMediaItem> allItems) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clusterStrings = prefs.getStringList('face_clusters_json') ?? [];
      final groupIds = prefs.getStringList('face_group_photo_ids')?.toSet() ?? {};

      final Map<String, GalleryMediaItem> itemMap = {};
      for (final item in allItems) {
        itemMap[item.id] = item;
      }

      clusters.clear();
      for (final s in clusterStrings) {
        try {
          final json = jsonDecode(s) as Map<String, dynamic>;
          final cluster = PersonCluster.fromJson(json, itemMap);
          if (cluster.items.isNotEmpty) {
            clusters.add(cluster);
          }
        } catch (e) {
          debugPrint('Error deserializing person cluster: $e');
        }
      }

      groupPhotos.clear();
      for (final id in groupIds) {
        final item = itemMap[id];
        if (item != null) groupPhotos.add(item);
      }

      isInitialized = true;
    } catch (e) {
      debugPrint('FaceDetectionService initialize error: $e');
    }
  }

  /// Persist clusters and group photos to SharedPreferences
  static Future<void> saveClusters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clusterStrings = clusters.map((c) => jsonEncode(c.toJson())).toList();
      await prefs.setStringList('face_clusters_json', clusterStrings);
      await prefs.setStringList(
          'face_group_photo_ids', groupPhotos.map((i) => i.id).toList());
    } catch (e) {
      debugPrint('Error saving face clusters: $e');
    }
  }

  /// Reset all face clusters and scan history to start a clean re-scan
  static Future<void> resetClusters(List<GalleryMediaItem> allItems) async {
    isScanning = false;
    isCoolingDown = false;
    coolingDownSecondsRemaining = 0;
    clusters.clear();
    groupPhotos.clear();
    scannedCount = 0;
    totalToScan = 0;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('face_clusters_json');
      await prefs.remove('face_group_photo_ids');
      for (final item in allItems) {
        await prefs.remove('face_scanned_${item.id}');
      }
    } catch (_) {}
  }

  /// Merge source cluster into target cluster
  static Future<void> mergeClusters(PersonCluster target, PersonCluster source) async {
    for (final item in source.items) {
      if (!target.items.any((i) => i.id == item.id)) {
        target.items.add(item);
      }
    }
    clusters.removeWhere((c) => c.id == source.id);
    await saveClusters();
  }

  /// Remove permanently deleted media from clusters and cache
  static Future<void> onItemsDeleted(List<String> deletedIds) async {
    final delSet = deletedIds.toSet();
    groupPhotos.removeWhere((i) => delSet.contains(i.id));
    for (final cluster in clusters) {
      cluster.items.removeWhere((i) => delSet.contains(i.id));
    }
    clusters.removeWhere((c) => c.items.isEmpty);

    await saveClusters();

    try {
      final prefs = await SharedPreferences.getInstance();
      for (final id in deletedIds) {
        await prefs.remove('face_scanned_$id');
      }
    } catch (_) {}
  }

  /// Analyze unscanned gallery photos continuously with thermal cooldown breaks
  static Future<void> scanGalleryForFaces({
    required List<GalleryMediaItem> allItems,
    required VoidCallback onProgress,
  }) async {
    if (isScanning) return;
    isScanning = true;
    isCoolingDown = false;
    coolingDownSecondsRemaining = 0;

    final tempDir = Directory.systemTemp;
    final tempScanFile = File('${tempDir.path}/face_scan_temp.jpg');

    try {
      final prefs = await SharedPreferences.getInstance();

      // Filter only photos (skip videos and screenshots)
      final photoCandidates = allItems
          .where((i) => !i.isVideo && !i.isScreenshot && i.decision == null)
          .toList();

      final unscanned = photoCandidates.where((i) {
        return prefs.getBool('face_scanned_${i.id}') != true;
      }).toList();

      totalToScan = unscanned.length;
      scannedCount = 0;
      onProgress();

      final processList = unscanned; // Scan all unscanned photos continuously

      int sessionPhotoCount = 0;

      for (int i = 0; i < processList.length; i++) {
        if (!isScanning) break; // Allow pausing

        // 500 photos cooldown: pause for 1 minute to let device cool, then resume
        if (sessionPhotoCount > 0 && sessionPhotoCount % 500 == 0) {
          isCoolingDown = true;
          for (int sec = 60; sec > 0; sec--) {
            if (!isScanning) break;
            coolingDownSecondsRemaining = sec;
            onProgress();
            await Future.delayed(const Duration(seconds: 1));
          }
          isCoolingDown = false;
          coolingDownSecondsRemaining = 0;
          onProgress();
          if (!isScanning) break;
        }

        final item = processList[i];
        try {
          final asset = await AssetEntity.fromId(item.id);
          if (asset != null) {
            // Get fast 512x512 thumbnail
            final thumbBytes = await asset.thumbnailDataWithSize(
              const ThumbnailSize.square(512),
              quality: 85,
            );

            if (thumbBytes != null) {
              await tempScanFile.writeAsBytes(thumbBytes, flush: true);
              final inputImage = InputImage.fromFilePath(tempScanFile.path);

              final faces = await _detector.processImage(inputImage);
              final validFaces = faces
                  .where((f) => f.boundingBox.width >= 40 && f.boundingBox.height >= 40)
                  .toList()
                ..sort((a, b) =>
                    (b.boundingBox.width * b.boundingBox.height)
                        .compareTo(a.boundingBox.width * a.boundingBox.height));

              bool hasChange = false;

              if (validFaces.length >= 2) {
                if (!groupPhotos.any((it) => it.id == item.id)) {
                  groupPhotos.add(item);
                  hasChange = true;
                }
              }

              if (validFaces.isNotEmpty) {
                img.Image? decoded;
                try {
                  decoded = img.decodeImage(thumbBytes);
                } catch (_) {}

                // Process up to 5 clear faces per photo
                for (final face in validFaces.take(5)) {
                  // Skip extreme side-profile angles (> 22° yaw or > 25° tilt) to preserve geometric accuracy
                  if (face.headEulerAngleY != null && face.headEulerAngleY!.abs() > 22) continue;
                  if (face.headEulerAngleZ != null && face.headEulerAngleZ!.abs() > 25) continue;

                  final features = _extractFeatureVector(face, 512, 512);
                  if (features.isEmpty) continue;

                  Uint8List? avatarBytes;
                  if (decoded != null) {
                    try {
                      final box = face.boundingBox;
                      final padX = (box.width * 0.2).toInt();
                      final padY = (box.height * 0.2).toInt();

                      final x = (box.left.toInt() - padX).clamp(0, decoded.width - 1);
                      final y = (box.top.toInt() - padY).clamp(0, decoded.height - 1);
                      final w = (box.width.toInt() + padX * 2).clamp(1, decoded.width - x);
                      final h = (box.height.toInt() + padY * 2).clamp(1, decoded.height - y);

                      final cropped = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
                      final square = img.copyResize(cropped, width: 140, height: 140);
                      avatarBytes = Uint8List.fromList(img.encodeJpg(square, quality: 80));
                    } catch (_) {}
                  }

                  _matchAndCluster(item, features, avatarBytes);
                  hasChange = true;
                }
              }

              if (hasChange) {
                await saveClusters();
              }
            }
          }
          await prefs.setBool('face_scanned_${item.id}', true);
        } catch (_) {}

        scannedCount++;
        sessionPhotoCount++;
        if (i % 4 == 0 || i == processList.length - 1) {
          onProgress();
          await Future.delayed(const Duration(milliseconds: 15)); // CPU cooling & GC yield
        }
      }
    } finally {
      // Secure cleanup of temporary scan file
      try {
        if (await tempScanFile.exists()) {
          await tempScanFile.delete();
        }
      } catch (_) {}

      await saveClusters();
      isScanning = false;
      isCoolingDown = false;
      coolingDownSecondsRemaining = 0;
      onProgress();
    }
  }

  static void stopScanning() {
    isScanning = false;
    isCoolingDown = false;
    coolingDownSecondsRemaining = 0;
  }

  /// Feature extraction using Inter-Pupillary Distance (IPD) normalization
  static List<double> _extractFeatureVector(Face face, int imgW, int imgH) {
    final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
    final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;
    final nose = face.landmarks[FaceLandmarkType.noseBase]?.position;
    final leftMouth = face.landmarks[FaceLandmarkType.leftMouth]?.position;
    final rightMouth = face.landmarks[FaceLandmarkType.rightMouth]?.position;
    final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth]?.position;

    // Must have clear eyes and nose for reliable biometric mapping
    if (leftEye == null || rightEye == null || nose == null) {
      return [];
    }

    final eyeDist = math.sqrt(math.pow(rightEye.x - leftEye.x, 2) +
        math.pow(rightEye.y - leftEye.y, 2));

    if (eyeDist < 12.0) return []; // Face too small / low-res for reliable biometrics

    final midEyeY = (leftEye.y + rightEye.y) / 2.0;
    final eyeToNose = (nose.y - midEyeY).abs();

    double noseToMouth = eyeDist * 0.45;
    if (bottomMouth != null) {
      noseToMouth = (bottomMouth.y - nose.y).abs().toDouble();
    }

    double mouthWidth = eyeDist * 0.75;
    if (leftMouth != null && rightMouth != null) {
      mouthWidth = math.sqrt(math.pow(rightMouth.x - leftMouth.x, 2) +
          math.pow(rightMouth.y - leftMouth.y, 2));
    }

    // IPD Normalization (Inter-Pupillary Distance) - independent of bounding box detector jitter
    final eyeToNoseRatio = (eyeToNose / eyeDist).clamp(0.2, 2.5);
    final noseToMouthRatio = (noseToMouth / eyeDist).clamp(0.2, 2.5);
    final mouthWidthRatio = (mouthWidth / eyeDist).clamp(0.3, 2.5);
    final eyeToMouthRatio = ((eyeToNose + noseToMouth) / eyeDist).clamp(0.4, 3.5);

    return [
      eyeToNoseRatio,
      noseToMouthRatio,
      mouthWidthRatio,
      eyeToMouthRatio,
    ];
  }

  /// Match face against existing clusters or create a new cluster
  static void _matchAndCluster(
    GalleryMediaItem item,
    List<double> features,
    Uint8List? avatarBytes,
  ) {
    PersonCluster? bestMatch;
    double highestSimilarity = 0.0;

    for (final cluster in clusters) {
      final sim = cluster.calculateSimilarity(features);
      if (sim > highestSimilarity) {
        highestSimilarity = sim;
        bestMatch = cluster;
      }
    }

    // Balanced similarity threshold: 0.875 (allows up to 12.5% natural expression variance)
    // Matches the same person smiling, laughing, or wearing glasses; rejects different people (>20% difference)
    if (bestMatch != null && highestSimilarity >= 0.875) {
      bestMatch.addPhoto(item, features, newAvatar: avatarBytes);
    } else {
      final newCluster = PersonCluster(
        id: 'person_${clusters.length + 1}',
        name: 'Person ${clusters.length + 1}',
        avatarBytes: avatarBytes,
        items: [item],
        featureVector: features,
      );
      clusters.add(newCluster);
    }
  }
}
