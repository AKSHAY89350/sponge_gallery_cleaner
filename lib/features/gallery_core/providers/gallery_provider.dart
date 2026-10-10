import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:disk_space_2/disk_space_2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sponge_gallery_cleaner/core/utils/blur_detector.dart';
import 'package:sponge_gallery_cleaner/features/gallery_core/models/gallery_media_item.dart';
import 'package:sponge_gallery_cleaner/features/scene_classifier/services/scene_classifier_service.dart';
import 'package:sponge_gallery_cleaner/features/people_cleaner/services/face_detection_service.dart';
import 'dart:math';

class GalleryProvider extends ChangeNotifier {
  static final RegExp _waRegex = RegExp(r'^wa\d+');
  List<MonthGroup> monthGroups = [];
  MonthGroup? screenshotsGroup;
  MonthGroup? whatsappGroup;
  MonthGroup? randomGroup;
  MonthGroup? blurryGroup;

  bool isBlurryScanning = false;
  int blurryScannedCount = 0;
  int blurryTotalCount = 0;

  int get blurryAnalyzedCount => allItems.where((i) => i.isBlurry != null && !i.isVideo).length;
  int get blurryTotalTarget => allItems.where((i) => !i.isVideo).length;
  bool get hasUnscannedBlurry =>
      allItems.any((i) => i.isBlurry == null && !i.isVideo);

  void refreshRandomGroup() {
    if (allItems.length > 5) {
      final rng = Random();
      // Filter out items that already have a decision
      final availableItems = allItems.where((i) => i.decision == null).toList();
      if (availableItems.isNotEmpty) {
        availableItems.shuffle(rng);
        randomGroup = MonthGroup(
          label: 'Random Clean',
          yearMonthKey: 'random',
          items: availableItems.take(20).toList(),
        )..recalculateCurrentIndex();
        notifyListeners();
      }
    }
  }

  // Large Files Categories
  MonthGroup? largeFiles10To100;
  MonthGroup? largeFiles100To500;
  MonthGroup? largeFiles500To1GB;
  MonthGroup? largeFilesOver1GB;
  int get totalLargeFilesCount =>
      (largeFiles10To100?.items.where((i) => i.decision == null).length ?? 0) +
      (largeFiles100To500?.items.where((i) => i.decision == null).length ?? 0) +
      (largeFiles500To1GB?.items.where((i) => i.decision == null).length ?? 0) +
      (largeFilesOver1GB?.items.where((i) => i.decision == null).length ?? 0);

  bool isLoading = false;
  bool isInitialized = false;
  bool isBackgroundLoading = false;
  double backgroundLoadProgress = 0.0;
  int totalTrashedBytes = 0;

  double? totalDiskSpaceMB;
  double? freeDiskSpaceMB;
  List<GalleryMediaItem> allItems = [];

  List<List<GalleryMediaItem>> similarPhotoGroups = [];

  int get similarPhotosCount {
    return similarPhotoGroups
        .map((group) => group.where((i) => i.decision == null).toList())
        .where((group) => group.length > 1)
        .fold(0, (sum, g) => sum + g.length);
  }

  int get whatsappJunkCount =>
      whatsappGroup?.items.where((i) => i.decision == null).length ?? 0;

  int get screenshotsCount =>
      screenshotsGroup?.items.where((i) => i.decision == null).length ?? 0;

  Future<void> fetchDiskSpace() async {
    try {
      totalDiskSpaceMB = await DiskSpace.getTotalDiskSpace;
      freeDiskSpaceMB = await DiskSpace.getFreeDiskSpace;
      notifyListeners();
    } catch (_) {}
  }

  final List<GalleryMediaItem> _stagingBin = [];
  List<GalleryMediaItem> get stagingBin => List.unmodifiable(_stagingBin);

  Future<bool> checkPermissions() async {
    final result = await PhotoManager.requestPermissionExtend();
    return result.isAuth;
  }

  void _categorizeLargeFile(GalleryMediaItem item) {
    if (item.fileSize <= 10 * 1024 * 1024) return; // not large

    MonthGroup getOrCreateGroup(MonthGroup? group, String label, String key) {
      if (group == null) {
        return MonthGroup(
            label: label, yearMonthKey: key, items: [item], isLargeFiles: true);
      }
      if (!group.items.any((i) => i.id == item.id)) {
        group.items.add(item);
        group.items.sort((a, b) =>
            b.fileSize.compareTo(a.fileSize)); // sort by size descending
        group.recalculateCurrentIndex();
      }
      return group;
    }

    final mb = item.fileSize / (1024 * 1024);
    if (mb > 10 && mb <= 100) {
      largeFiles10To100 = getOrCreateGroup(
          largeFiles10To100, 'Large Files (10MB - 100MB)', 'large_10_100');
    } else if (mb > 100 && mb <= 500) {
      largeFiles100To500 = getOrCreateGroup(
          largeFiles100To500, 'Huge Files (100MB - 500MB)', 'large_100_500');
    } else if (mb > 500 && mb <= 1024) {
      largeFiles500To1GB = getOrCreateGroup(
          largeFiles500To1GB, 'Massive Files (500MB - 1GB)', 'large_500_1gb');
    } else if (mb > 1024) {
      largeFilesOver1GB = getOrCreateGroup(
          largeFilesOver1GB, 'Gigantic Files (> 1GB)', 'large_1gb_plus');
    }
  }

  Future<void> loadGallery() async {
    if (isLoading) return;
    isLoading = true;
    notifyListeners();

    try {
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        filterOption: FilterOptionGroup(
          orders: [
            const OrderOption(type: OrderOptionType.createDate, asc: false)
          ],
        ),
      );

      final Map<String, List<GalleryMediaItem>> byMonth = {};
      final List<GalleryMediaItem> screenshots = [];
      final List<GalleryMediaItem> whatsappItems = [];
      allItems = [];
      _stagingBin.clear();
      largeFiles10To100 = null;
      largeFiles100To500 = null;
      largeFiles500To1GB = null;
      largeFilesOver1GB = null;
      screenshotsGroup = null;
      whatsappGroup = null;
      blurryGroup = null;

      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final decisionMap = <String, String>{};
      final blurrySet = <String>{};
      for (final k in keys) {
        if (k.startsWith('decision_')) {
          final val = prefs.getString(k);
          if (val != null) decisionMap[k.substring(9)] = val;
        } else if (k.startsWith('blurry_')) {
          if (prefs.getBool(k) == true) blurrySet.add(k.substring(7));
        }
      }

      if (albums.isNotEmpty) {
        // 1. Collect asset IDs from specialized Screenshot album (single album, quick query)
        final screenshotAssetIds = <String>{};

        for (final album in albums) {
          if (album.isAll) continue;

          final nameLower = album.name.toLowerCase().trim();
          if (nameLower == 'screenshots' || nameLower == 'screenshot') {
            final count = await album.assetCountAsync;
            final list = await album.getAssetListRange(start: 0, end: count);
            for (final a in list) {
              screenshotAssetIds.add(a.id);
            }
            break; // Dedicated Screenshots album found, no need to scan remaining albums
          }
        }

        // 2. Fetch all assets from allAlbum (Recents/All)
        final allAlbum = albums.first;
        final total = await allAlbum.assetCountAsync;
        final List<AssetEntity> allAssets = [];

        const chunkSize = 2500;
        for (int i = 0; i < total; i += chunkSize) {
          final end = (i + chunkSize).clamp(0, total);
          final chunk = await allAlbum.getAssetListRange(start: i, end: end);
          allAssets.addAll(chunk);
        }

        // 3. Convert all assets to GalleryMediaItem
        for (final asset in allAssets) {
          final titleLower = (asset.title ?? '').toLowerCase();
          final relLower = (asset.relativePath ?? '').toLowerCase();
          final filePath = "${asset.relativePath ?? ''}/${asset.title ?? ''}";

          final isTitleWhatsApp = titleLower.contains('whatsapp') ||
              titleLower.contains('-wa') ||
              titleLower.startsWith('img-wa') ||
              titleLower.startsWith('vid-wa') ||
              _waRegex.hasMatch(titleLower);

          final isWhatsApp =
              relLower.contains('whatsapp') || isTitleWhatsApp;

          final isTitleScreenshot = titleLower.startsWith('screenshot') ||
              titleLower.startsWith('screen_') ||
              titleLower.startsWith('screen-');
          final isRelScreenshot = relLower.startsWith('pictures/screenshots') ||
              relLower.startsWith('dcim/screenshots') ||
              relLower.contains('/screenshots') ||
              relLower == 'screenshots' ||
              relLower == 'screenshots/';

          final isScreenshot = screenshotAssetIds.contains(asset.id) ||
              (isRelScreenshot && isTitleScreenshot) ||
              (screenshotAssetIds.isEmpty && (isRelScreenshot || isTitleScreenshot));

          final dateTakenMs = asset.createDateTime.millisecondsSinceEpoch > 0
              ? asset.createDateTime.millisecondsSinceEpoch
              : (asset.modifiedDateTime.millisecondsSinceEpoch > 0
                  ? asset.modifiedDateTime.millisecondsSinceEpoch
                  : DateTime.now().millisecondsSinceEpoch);

          final item = GalleryMediaItem(
            id: asset.id,
            path: filePath,
            dateTaken: dateTakenMs,
            fileSize: 0,
            isVideo: asset.type == AssetType.video,
            videoDuration:
                asset.type == AssetType.video ? asset.videoDuration : null,
            width: asset.width,
            height: asset.height,
            mimeType: asset.mimeType,
          );

          // Restore saved blurry state (instant O(1))
          if (blurrySet.contains(item.id)) {
            item.isBlurry = true;
            if (blurryGroup == null) {
              blurryGroup = MonthGroup(
                  label: 'Blurry Photos',
                  yearMonthKey: 'blurry_photos',
                  items: [item]);
            } else {
              blurryGroup!.items.add(item);
            }
          }

          // Restore saved decision (instant O(1))
          final savedDecision = decisionMap[item.id];
          if (savedDecision != null) {
            item.decision = SwipeAction.values.firstWhere(
              (e) => e.name == savedDecision,
              orElse: () => SwipeAction.keep,
            );
            if (item.decision == SwipeAction.trash) {
              _stagingBin.add(item);
            }
          }

          allItems.add(item);

          // Group by year-month key
          final key =
              '${item.dateTime.year}-${item.dateTime.month.toString().padLeft(2, '0')}';
          byMonth.putIfAbsent(key, () => []).add(item);

          if (isScreenshot) {
            screenshots.add(item);
          }
          if (isWhatsApp) {
            whatsappItems.add(item);
          }
        }

        // Build sorted month groups (newest first)
        monthGroups = byMonth.entries.map((entry) {
          final parts = entry.key.split('-');
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final label = _monthLabel(month, year);
          return MonthGroup(
            label: label,
            yearMonthKey: entry.key,
            items: entry.value,
          )..recalculateCurrentIndex();
        }).toList()
          ..sort((a, b) => b.yearMonthKey.compareTo(a.yearMonthKey));

        if (screenshots.isNotEmpty) {
          screenshotsGroup = MonthGroup(
            label: 'Screenshots',
            yearMonthKey: 'screenshots',
            items: screenshots,
            isScreenshots: true,
          )..recalculateCurrentIndex();
        }

        if (whatsappItems.isNotEmpty) {
          whatsappGroup = MonthGroup(
            label: 'WhatsApp Junk',
            yearMonthKey: 'whatsapp',
            items: whatsappItems,
          )..recalculateCurrentIndex();
        }

        if (blurryGroup != null) {
          blurryGroup!.recalculateCurrentIndex();
        }

        // Random group - pick 20 random items
        if (allItems.length > 5) {
          final rng = Random();
          final availableItems =
              allItems.where((i) => i.decision == null).toList();
          if (availableItems.isNotEmpty) {
            availableItems.shuffle(rng);
            randomGroup = MonthGroup(
              label: 'Random Clean',
              yearMonthKey: 'random',
              items: availableItems.take(20).toList(),
            )..recalculateCurrentIndex();
          }
        }

        totalTrashedBytes = _stagingBin.fold(0, (s, i) => s + i.fileSize);
        isInitialized = true;

        // Immediate complete analysis across all assets
        _findSimilarPhotos();
        fetchDiskSpace();

        // Background size fetch for Large Files & Trashed Bytes
        _fetchSizesForAssets(allAssets);
      }
    } catch (e) {
      debugPrint('Error loading gallery: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _ensureItemFileSize(GalleryMediaItem item) {
    if (item.fileSize <= 0) {
      AssetEntity.fromId(item.id).then((entity) async {
        if (entity != null) {
          final f = await entity.file;
          if (f != null) {
            item.fileSize = f.lengthSync();
            totalTrashedBytes = _stagingBin.fold(0, (s, i) => s + i.fileSize);
            notifyListeners();
          }
        }
      });
    }
  }

  Future<void> _fetchSizesForAssets(List<AssetEntity> assets) async {
    // Instant O(1) item map
    final itemMap = {for (final it in allItems) it.id: it};

    // Phase 1: High Priority (Videos & Staged Trash Items)
    // Videos are primary candidates for Large Files (>10MB). Staged items impact Trash size counter.
    final priorityAssets = assets.where((a) =>
      a.type == AssetType.video || _stagingBin.any((s) => s.id == a.id)
    ).toList();

    for (final asset in priorityAssets) {
      try {
        final originFile = await asset.file;
        if (originFile != null) {
          final size = originFile.lengthSync();
          final item = itemMap[asset.id];
          if (item != null) {
            item.fileSize = size;
            _categorizeLargeFile(item);
          }
        }
      } catch (_) {}
    }

    // Update trash bytes and notify UI ONCE after priority pass
    totalTrashedBytes = _stagingBin.fold(0, (s, item) => s + item.fileSize);
    notifyListeners();

    // Phase 2: Background Low-Priority Scan for remaining photos
    // Non-video photos are rarely >10MB, so scan them quietly and yield UI thread
    final remainingPhotos = assets.where((a) => a.type != AssetType.video).toList();
    bool foundNewLarge = false;

    for (int i = 0; i < remainingPhotos.length; i++) {
      final asset = remainingPhotos[i];
      try {
        final originFile = await asset.file;
        if (originFile != null) {
          final size = originFile.lengthSync();
          final item = itemMap[asset.id];
          if (item != null) {
            item.fileSize = size;
            if (size > 10 * 1024 * 1024) {
              _categorizeLargeFile(item);
              foundNewLarge = true;
            }
          }
        }
      } catch (_) {}

      // Yield frame every 40 items to preserve 60/120 FPS UI smoothness
      if (i > 0 && i % 40 == 0) {
        if (foundNewLarge) {
          notifyListeners();
          foundNewLarge = false;
        }
        await Future.delayed(const Duration(milliseconds: 16));
      }
    }

    totalTrashedBytes = _stagingBin.fold(0, (s, item) => s + item.fileSize);
    notifyListeners();
  }

  void bulkAddToStagingBin(List<GalleryMediaItem> items) {
    for (final item in items) {
      item.decision = SwipeAction.trash;
      if (!_stagingBin.any((i) => i.id == item.id)) {
        _stagingBin.add(item);
      }
      _ensureItemFileSize(item);
      _saveDecision(item.id, SwipeAction.trash);
    }
    totalTrashedBytes = _stagingBin.fold(0, (s, i) => s + i.fileSize);
    notifyListeners();
  }

  void bulkKeepItems(List<GalleryMediaItem> items) {
    for (final item in items) {
      item.decision = SwipeAction.keep;
      _stagingBin.removeWhere((i) => i.id == item.id);
      _saveDecision(item.id, SwipeAction.keep);
    }
    totalTrashedBytes = _stagingBin.fold(0, (s, i) => s + i.fileSize);
    notifyListeners();
  }

  void addToStagingBin(GalleryMediaItem item) {
    item.decision = SwipeAction.trash;
    if (!_stagingBin.any((i) => i.id == item.id)) {
      _stagingBin.add(item);
    }
    _ensureItemFileSize(item);
    totalTrashedBytes = _stagingBin.fold(0, (s, i) => s + i.fileSize);
    _saveDecision(item.id, SwipeAction.trash);
    notifyListeners();
  }

  void keepItem(GalleryMediaItem item) {
    item.decision = SwipeAction.keep;
    _stagingBin.removeWhere((i) => i.id == item.id);
    totalTrashedBytes = _stagingBin.fold(0, (s, i) => s + i.fileSize);
    _saveDecision(item.id, SwipeAction.keep);
    notifyListeners();
  }

  void removeFromStagingBin(GalleryMediaItem item) {
    item.decision = null;
    _stagingBin.removeWhere((i) => i.id == item.id);
    totalTrashedBytes = _stagingBin.fold(0, (s, i) => s + i.fileSize);
    _clearDecision(item.id);

    for (final g in monthGroups) {
      g.recalculateCurrentIndex();
    }
    screenshotsGroup?.recalculateCurrentIndex();
    whatsappGroup?.recalculateCurrentIndex();
    randomGroup?.recalculateCurrentIndex();
    blurryGroup?.recalculateCurrentIndex();
    largeFiles10To100?.recalculateCurrentIndex();
    largeFiles100To500?.recalculateCurrentIndex();
    largeFiles500To1GB?.recalculateCurrentIndex();
    largeFilesOver1GB?.recalculateCurrentIndex();

    notifyListeners();
  }

  Future<void> scanMoreBlurry() async {
    await _scanBlurryQueue(1000);
  }

  Future<void> _scanBlurryQueue(int limit) async {
    if (isBlurryScanning) return;
    isBlurryScanning = true;
    notifyListeners();

    try {
      final unscanned = allItems
          .where((i) => i.isBlurry == null && !i.isVideo)
          .take(limit)
          .toList();
      blurryTotalCount += unscanned.length;
      notifyListeners();

      final newBlurries = <GalleryMediaItem>[];

      for (final item in unscanned) {
        try {
          // Wait, PhotoManager doesn't have assetEntity directly easily? AssetEntity.fromId
          final assetEntity = await AssetEntity.fromId(item.id);
          final data = await assetEntity
              ?.thumbnailDataWithSize(const ThumbnailSize.square(512));
          if (data != null) {
            final isB = await BlurDetector.isImageBlurry(data);
            item.isBlurry = isB;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('blurry_${item.id}', isB);
            if (isB) {
              newBlurries.add(item);
            }
          } else {
            item.isBlurry = false;
          }
        } catch (e) {
          item.isBlurry = false;
        }
        blurryScannedCount++;
        if (blurryScannedCount % 50 == 0) notifyListeners();
      }

      if (newBlurries.isNotEmpty) {
        if (blurryGroup == null) {
          blurryGroup = MonthGroup(
            label: 'Blurry Photos',
            yearMonthKey: 'blurry',
            items: newBlurries,
          )..recalculateCurrentIndex();
        } else {
          blurryGroup!.items.addAll(newBlurries);
          blurryGroup!.recalculateCurrentIndex();
        }
      }
    } finally {
      isBlurryScanning = false;
      notifyListeners();
      
      if (hasUnscannedBlurry) {
        Future.microtask(() => scanMoreBlurry());
      }
    }
  }

  Future<int> permanentlyDeleteStaged() async {
    final ids = _stagingBin.map((i) => i.id).toList();
    if (ids.isEmpty) return 0;

    final deletedIds = await PhotoManager.editor.deleteWithIds(ids);
    if (deletedIds.isEmpty) {
      // User tapped Deny on system dialog or operation was cancelled
      return 0;
    }

    _stagingBin.removeWhere((i) => deletedIds.contains(i.id));
    totalTrashedBytes = _stagingBin.fold(0, (s, i) => s + i.fileSize);

    // Clear saved decisions for deleted items
    final prefs = await SharedPreferences.getInstance();
    for (final id in deletedIds) {
      await prefs.remove('decision_$id');
      await prefs.remove('blurry_$id');
    }

    // Remove from allItems list
    allItems.removeWhere((i) => deletedIds.contains(i.id));

    // Remove from all month groups
    for (final group in monthGroups) {
      group.items.removeWhere((i) => deletedIds.contains(i.id));
      group.recalculateCurrentIndex();
    }
    screenshotsGroup?.items.removeWhere((i) => deletedIds.contains(i.id));
    screenshotsGroup?.recalculateCurrentIndex();

    whatsappGroup?.items.removeWhere((i) => deletedIds.contains(i.id));
    whatsappGroup?.recalculateCurrentIndex();

    blurryGroup?.items.removeWhere((i) => deletedIds.contains(i.id));
    blurryGroup?.recalculateCurrentIndex();

    largeFiles10To100?.items.removeWhere((i) => deletedIds.contains(i.id));
    largeFiles10To100?.recalculateCurrentIndex();

    largeFiles100To500?.items.removeWhere((i) => deletedIds.contains(i.id));
    largeFiles100To500?.recalculateCurrentIndex();

    largeFiles500To1GB?.items.removeWhere((i) => deletedIds.contains(i.id));
    largeFiles500To1GB?.recalculateCurrentIndex();

    largeFilesOver1GB?.items.removeWhere((i) => deletedIds.contains(i.id));
    largeFilesOver1GB?.recalculateCurrentIndex();

    randomGroup?.items.removeWhere((i) => deletedIds.contains(i.id));
    randomGroup?.recalculateCurrentIndex();

    // Clean up similar photo groups
    for (final g in similarPhotoGroups) {
      g.removeWhere((i) => deletedIds.contains(i.id));
    }
    similarPhotoGroups.removeWhere((g) => g.length < 2);

    // Prune deleted items from AI Scene & Face services
    SceneClassifierService.onItemsDeleted(deletedIds);
    FaceDetectionService.onItemsDeleted(deletedIds);

    // Refetch disk space so the home screen storage widget updates!
    await fetchDiskSpace();

    notifyListeners();
    return deletedIds.length;
  }

  Future<void> _saveDecision(String id, SwipeAction action) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('decision_$id', action.name);
  }

  Future<void> _clearDecision(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('decision_$id');
    await prefs.remove('blurry_$id');
  }

  String _monthLabel(int month, int year) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[month - 1]} $year';
  }

  String get totalFreedFormatted {
    if (totalTrashedBytes < 1024 * 1024) {
      return '${(totalTrashedBytes / 1024).toStringAsFixed(1)} KB';
    } else if (totalTrashedBytes < 1024 * 1024 * 1024) {
      return '${(totalTrashedBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalTrashedBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  void _findSimilarPhotos() {
    final sortedItems = allItems.where((i) => !i.isVideo && i.dateTaken > 0).toList()
      ..sort((a, b) => b.dateTaken.compareTo(a.dateTaken));

    List<List<GalleryMediaItem>> newGroups = [];
    List<GalleryMediaItem> currentGroup = [];

    for (int i = 0; i < sortedItems.length - 1; i++) {
      final current = sortedItems[i];
      final next = sortedItems[i + 1];

      // Time difference between consecutive photos <= 3 seconds
      final diffFromPrevious = (current.dateTaken - next.dateTaken).abs();
      // Total cluster span should not exceed 15 seconds from the first photo in this cluster
      final clusterStart =
          currentGroup.isNotEmpty ? currentGroup.first.dateTaken : current.dateTaken;
      final diffFromStart = (clusterStart - next.dateTaken).abs();

      if (diffFromPrevious <= 3000 && diffFromStart <= 15000 && currentGroup.length < 15) {
        if (currentGroup.isEmpty) currentGroup.add(current);
        if (!currentGroup.any((item) => item.id == next.id)) {
          currentGroup.add(next);
        }
      } else {
        if (currentGroup.length > 1) {
          newGroups.add(List.from(currentGroup));
        }
        currentGroup.clear();
      }
    }

    if (currentGroup.length > 1) {
      newGroups.add(List.from(currentGroup));
    }

    similarPhotoGroups = newGroups;
  }
}
