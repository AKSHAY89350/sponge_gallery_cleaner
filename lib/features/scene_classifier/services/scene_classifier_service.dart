import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sponge_gallery_cleaner/core/services/ai_scan_coordinator.dart';
import 'package:sponge_gallery_cleaner/features/gallery_core/models/gallery_media_item.dart';
import 'package:sponge_gallery_cleaner/features/people_cleaner/services/face_detection_service.dart';

class SceneClassifierService {
  static final List<GalleryMediaItem> foodPhotos = [];
  static final List<GalleryMediaItem> sceneryPhotos = [];
  static final List<GalleryMediaItem> documentPhotos = [];

  static bool isScanning = false;
  static bool isCoolingDown = false;
  static int coolingDownSecondsRemaining = 0;
  static int scannedCount = 0;
  static int totalToScan = 0;
  static bool isInitialized = false;

  static double get scanProgress =>
      totalToScan > 0 ? (scannedCount / totalToScan) : 0.0;

  static const Set<String> _foodKeywords = {
    'food', 'dish', 'cuisine', 'fast food', 'dessert', 'meal',
    'drink', 'beverage', 'snack', 'fruit', 'meat', 'breakfast',
    'lunch', 'dinner', 'baked goods', 'plate', 'cocktail', 'coffee',
    'tea', 'cake', 'pizza', 'burger', 'sandwich', 'salad', 'bread',
    'tableware', 'soup', 'pastry', 'vegetable', 'sweet', 'ice cream',
    'seafood', 'cooking', 'restaurant', 'dining', 'recipe', 'snack food',
    'finger food', 'delicacy', 'junk food'
  };

  static const Set<String> _sceneryKeywords = {
    'nature', 'sky', 'sunset', 'sunrise', 'landscape', 'mountain',
    'sea', 'ocean', 'beach', 'tree', 'water', 'lake', 'cloud',
    'forest', 'scenery', 'wilderness', 'hill', 'coast', 'horizon',
    'river', 'natural landscape', 'sunlight', 'plant', 'flower',
    'valley', 'garden', 'waterfall', 'field', 'meadow', 'outdoor',
    'scenic', 'wildlife', 'woodland', 'scenic viewpoint', 'dawn', 'dusk',
    'bay', 'shore', 'reflection', 'countryside'
  };

  static const Set<String> _documentKeywords = {
    'document', 'receipt', 'paper', 'text', 'invoice', 'page',
    'handwriting', 'book', 'newspaper', 'bill', 'ticket', 'font',
    'label', 'identity document', 'whiteboard', 'prescription',
    'certificate', 'letter', 'contract', 'form', 'passport',
    'business card', 'diagram', 'poster', 'sheet music', 'stationery'
  };

  static bool _matchesKeywords(String text, Set<String> keywords) {
    if (keywords.contains(text)) return true;
    for (final kw in keywords) {
      if (text.contains(kw) || kw.contains(text)) return true;
    }
    return false;
  }

  /// Initialize cached categorization from SharedPreferences
  static Future<void> initialize(List<GalleryMediaItem> allItems) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final foodIds = prefs.getStringList('scene_food_ids')?.toSet() ?? {};
      final sceneryIds = prefs.getStringList('scene_scenery_ids')?.toSet() ?? {};
      final docIds = prefs.getStringList('scene_document_ids')?.toSet() ?? {};

      final Map<String, GalleryMediaItem> itemMap = {};
      for (final item in allItems) {
        itemMap[item.id] = item;
      }

      foodPhotos.clear();
      sceneryPhotos.clear();
      documentPhotos.clear();

      for (final id in foodIds) {
        final item = itemMap[id];
        if (item != null) foodPhotos.add(item);
      }

      for (final id in sceneryIds) {
        final item = itemMap[id];
        if (item != null) sceneryPhotos.add(item);
      }

      for (final id in docIds) {
        final item = itemMap[id];
        if (item != null) documentPhotos.add(item);
      }

      isInitialized = true;
    } catch (e) {
      debugPrint('SceneClassifierService initialize error: $e');
    }
  }

  /// Remove permanently deleted media from scene categories and cache
  static Future<void> onItemsDeleted(List<String> deletedIds) async {
    final delSet = deletedIds.toSet();
    foodPhotos.removeWhere((i) => delSet.contains(i.id));
    sceneryPhotos.removeWhere((i) => delSet.contains(i.id));
    documentPhotos.removeWhere((i) => delSet.contains(i.id));

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('scene_food_ids', foodPhotos.map((i) => i.id).toList());
      await prefs.setStringList('scene_scenery_ids', sceneryPhotos.map((i) => i.id).toList());
      await prefs.setStringList('scene_document_ids', documentPhotos.map((i) => i.id).toList());
      for (final id in deletedIds) {
        await prefs.remove('scene_scanned_$id');
      }
    } catch (e) {
      debugPrint('Error updating scene cache after deletion: $e');
    }
    AiScanCoordinator.instance.onItemsDeleted(deletedIds);
  }

  static void stopScanning() {
    isScanning = false;
    isCoolingDown = false;
    coolingDownSecondsRemaining = 0;
    AiScanCoordinator.instance.releaseEngine(AiScanEngine.scene);
  }

  /// Scan gallery photos for scenes using Bidirectional Two-Pointer concurrency (Limit = 2)
  static Future<void> scanGalleryForScenes({
    required List<GalleryMediaItem> allItems,
    required VoidCallback onProgress,
  }) async {
    if (isScanning) return;
    isScanning = true;
    isCoolingDown = false;
    coolingDownSecondsRemaining = 0;

    // Enforce Mutual Exclusion: Pause conflicting AI engine
    AiScanCoordinator.instance.requestExclusiveEngine(
      AiScanEngine.scene,
      onConflictPause: () => FaceDetectionService.stopScanning(),
    );
    await AiScanCoordinator.instance.initialize();

    final tempDir = Directory.systemTemp;
    final tempHeadFile = File('${tempDir.path}/scene_scan_worker_head.jpg');
    final tempTailFile = File('${tempDir.path}/scene_scan_worker_tail.jpg');

    ImageLabeler? labelerHead;
    ImageLabeler? labelerTail;

    final Set<String> foodIds = {};
    final Set<String> sceneryIds = {};
    final Set<String> docIds = {};
    SharedPreferences? prefsInstance;

    try {
      final prefs = await SharedPreferences.getInstance();
      prefsInstance = prefs;
      foodIds.addAll(prefs.getStringList('scene_food_ids') ?? []);
      sceneryIds.addAll(prefs.getStringList('scene_scenery_ids') ?? []);
      docIds.addAll(prefs.getStringList('scene_document_ids') ?? []);

      labelerHead = ImageLabeler(
        options: ImageLabelerOptions(confidenceThreshold: 0.60),
      );
      labelerTail = ImageLabeler(
        options: ImageLabelerOptions(confidenceThreshold: 0.60),
      );

      final photoCandidates = allItems
          .where((i) => !i.isVideo && !i.isScreenshot && i.decision == null)
          .toList();

      final unscanned = photoCandidates.where((i) {
        return prefs.getBool('scene_scanned_${i.id}') != true;
      }).toList();

      totalToScan = unscanned.length;
      scannedCount = 0;
      onProgress();

      if (unscanned.isEmpty) {
        return;
      }

      final controller = BidirectionalScanController<GalleryMediaItem>(unscanned);
      int sessionPhotoCount = 0;
      int changesCount = 0;

      Future<void> runWorker({
        required bool isHead,
        required ImageLabeler labeler,
        required File tempFile,
      }) async {
        while (!controller.isCompleted && isScanning) {
          // Wait cooperatively if cooldown break is active
          while (isCoolingDown && isScanning) {
            await Future.delayed(const Duration(milliseconds: 300));
          }
          if (!isScanning || controller.isCompleted) break;

          final item = isHead ? controller.claimNextHead() : controller.claimNextTail();
          if (item == null) break;

          // 1. SMART SKIPPING:
          // Skip if already reviewed/cleaned by user
          if (AiScanCoordinator.instance.isReviewed(item.id)) {
            await prefs.setBool('scene_scanned_${item.id}', true);
            scannedCount++;
            continue;
          }

          // 2. Cooldown check (every 500 photos across both workers)
          sessionPhotoCount++;
          if (sessionPhotoCount > 0 && sessionPhotoCount % 500 == 0 && !isCoolingDown) {
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

          try {
            final asset = await AssetEntity.fromId(item.id);
            if (asset != null) {
              final thumbBytes = await asset.thumbnailDataWithSize(
                const ThumbnailSize.square(384),
                quality: 80,
              );

              if (thumbBytes != null) {
                await tempFile.writeAsBytes(thumbBytes, flush: true);
                final inputImage = InputImage.fromFilePath(tempFile.path);

                final labels = await labeler.processImage(inputImage);

                bool isFood = false;
                bool isScenery = false;
                bool isDoc = false;

                for (final label in labels) {
                  final text = label.label.toLowerCase();
                  final conf = label.confidence;

                  if (conf >= 0.55) {
                    if (_matchesKeywords(text, _foodKeywords)) isFood = true;
                    if (_matchesKeywords(text, _sceneryKeywords)) isScenery = true;
                    if (_matchesKeywords(text, _documentKeywords)) isDoc = true;
                  }
                }

                bool hasNewCategory = false;
                if (isFood) {
                  if (!foodPhotos.any((it) => it.id == item.id)) {
                    foodPhotos.add(item);
                    foodIds.add(item.id);
                    hasNewCategory = true;
                  }
                }

                if (isScenery) {
                  if (!sceneryPhotos.any((it) => it.id == item.id)) {
                    sceneryPhotos.add(item);
                    sceneryIds.add(item.id);
                    hasNewCategory = true;
                  }
                }

                if (isDoc) {
                  // Register document with cross-engine coordinator for instant FaceDetector skip
                  AiScanCoordinator.instance.markDocument(item.id);
                  if (!documentPhotos.any((it) => it.id == item.id)) {
                    documentPhotos.add(item);
                    docIds.add(item.id);
                    hasNewCategory = true;
                  }
                }

                if (hasNewCategory) {
                  changesCount++;
                  if (changesCount % 5 == 0) {
                    await prefs.setStringList('scene_food_ids', foodIds.toList());
                    await prefs.setStringList('scene_scenery_ids', sceneryIds.toList());
                    await prefs.setStringList('scene_document_ids', docIds.toList());
                  }
                }
              }
            }
            await prefs.setBool('scene_scanned_${item.id}', true);
          } catch (e) {
            debugPrint('Error classifying item ${item.id}: $e');
          }

          scannedCount++;
          if (scannedCount % 4 == 0) {
            onProgress();
            await Future.delayed(const Duration(milliseconds: 15)); // CPU cooling & GC yield
          }
        }
      }

      // Concurrency Limit = 2: Bidirectional Dual Workers (Head + Tail)
      await Future.wait([
        runWorker(isHead: true, labeler: labelerHead, tempFile: tempHeadFile),
        runWorker(isHead: false, labeler: labelerTail, tempFile: tempTailFile),
      ]);
    } catch (e) {
      debugPrint('Scene classification error: $e');
    } finally {
      try {
        if (await tempHeadFile.exists()) await tempHeadFile.delete();
      } catch (_) {}
      try {
        if (await tempTailFile.exists()) await tempTailFile.delete();
      } catch (_) {}

      try {
        await labelerHead?.close();
      } catch (_) {}
      try {
        await labelerTail?.close();
      } catch (_) {}

      if (prefsInstance != null) {
        await prefsInstance.setStringList('scene_food_ids', foodIds.toList());
        await prefsInstance.setStringList('scene_scenery_ids', sceneryIds.toList());
        await prefsInstance.setStringList('scene_document_ids', docIds.toList());
      }
      AiScanCoordinator.instance.releaseEngine(AiScanEngine.scene);
      isScanning = false;
      isCoolingDown = false;
      coolingDownSecondsRemaining = 0;
      onProgress();
    }
  }

  /// Create MonthGroup for Food & Dining photos
  static MonthGroup createFoodGroup() {
    return MonthGroup(
      label: 'Food & Dining',
      yearMonthKey: 'scene_food',
      items: List.from(foodPhotos),
    )..recalculateCurrentIndex();
  }

  /// Create MonthGroup for Views & Scenery photos
  static MonthGroup createSceneryGroup() {
    return MonthGroup(
      label: 'Views & Scenery',
      yearMonthKey: 'scene_scenery',
      items: List.from(sceneryPhotos),
    )..recalculateCurrentIndex();
  }

  /// Create MonthGroup for Views & Scenery photos
  static MonthGroup createDocumentGroup() {
    return MonthGroup(
      label: 'Documents & Receipts',
      yearMonthKey: 'scene_document',
      items: List.from(documentPhotos),
    )..recalculateCurrentIndex();
  }
}
