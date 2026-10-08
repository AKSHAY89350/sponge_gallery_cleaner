import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:disk_space_2/disk_space_2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sponge_gallery_cleaner/core/utils/blur_detector.dart';
import 'package:sponge_gallery_cleaner/features/gallery_core/models/gallery_media_item.dart';
import 'dart:math';

class GalleryProvider extends ChangeNotifier {
  List<MonthGroup> monthGroups = [];
  MonthGroup? screenshotsGroup;
  MonthGroup? whatsappGroup;
  MonthGroup? randomGroup;
  MonthGroup? blurryGroup;

  bool isBlurryScanning = false;
  int blurryScannedCount = 0;
  int blurryTotalCount = 0;

  bool get hasUnscannedBlurry =>
      allItems.any((i) => i.isBlurry == null && !i.isVideo);

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

  List<AssetEntity> _initialAssets = [];
  Future<void> loadGallery() async {
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
      final List<GalleryMediaItem> largeFiles = [];
      allItems = [];

      final prefs = await SharedPreferences.getInstance();

      if (albums.isNotEmpty) {
        final allAlbum = albums.first;
        final total = await allAlbum.assetCountAsync;
        final initialLoadEnd = total.clamp(0, 3000);
        _initialAssets = await allAlbum.getAssetListRange(
          start: 0,
          end: initialLoadEnd,
        );

        for (final asset in _initialAssets) {
          int fileSizeBytes = 0;
          String filePath = asset.title ?? '';
          // 🚀 SKIPPING await asset.file HERE FOR INSTANT STARTUP 🚀

          final item = GalleryMediaItem(
            id: asset.id,
            path: filePath,
            dateTaken: asset.createDateTime.millisecondsSinceEpoch,
            fileSize: fileSizeBytes,
            isVideo: asset.type == AssetType.video,
            videoDuration:
                asset.type == AssetType.video ? asset.videoDuration : null,
            width: asset.width,
            height: asset.height,
            mimeType: asset.mimeType,
          );

          // Load saved decision from prefs
          // Load blurry state
          final savedBlurry = prefs.getBool('blurry_${item.id}');
          if (savedBlurry != null) {
            item.isBlurry = savedBlurry;
            if (savedBlurry) {
              if (blurryGroup == null) {
                blurryGroup = MonthGroup(
                    label: 'Blurry Photos',
                    yearMonthKey: 'blurry_photos',
                    items: [item]);
              } else if (!blurryGroup!.items.any((i) => i.id == item.id)) {
                blurryGroup!.items.add(item);
              }
              blurryGroup!.recalculateCurrentIndex();
            }
          }

          final savedDecision = prefs.getString('decision_${item.id}');
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

          // Screenshots filter (by path or mime type)
          final pathLower = item.path.toLowerCase();
          if (pathLower.contains('screenshot') ||
              pathLower.contains('screen_record')) {
            screenshots.add(item);
          }
          if (item.isWhatsApp) {
            whatsappItems.add(item);
          }
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

      // Random group - pick 20 random items
      if (allItems.length > 5) {
        final rng = Random();
        final randomItems = List<GalleryMediaItem>.from(allItems)..shuffle(rng);
        randomGroup = MonthGroup(
          label: 'Random Clean',
          yearMonthKey: 'random',
          items: randomItems.take(20).toList(),
        )..recalculateCurrentIndex();
      }

      // Recalculate trashed bytes
      totalTrashedBytes = _stagingBin.fold(0, (s, i) => s + i.fileSize);

      isInitialized = true;

      // Start background load if there's more data
      if (albums.isNotEmpty) {
        AssetPathEntity? screenshotAlbum;
        for (final album in albums) {
          if (album.name.toLowerCase().contains('screenshot')) {
            screenshotAlbum = album;
            break;
          }
        }
        if (screenshotAlbum != null) {
          _loadScreenshotsInBackground(screenshotAlbum);
        }

        final total = await albums.first.assetCountAsync;
        if (total > 3000) {
          _loadRemainingBackground(albums.first, 3000, total.clamp(0, 50000));
        }
      }

      // Fetch sizes for initial items in background
      // Fetch sizes for initial items in background
      _fetchSizesForInitialItems(_initialAssets);
      fetchDiskSpace();
      _findSimilarPhotos();
    } catch (e) {
      debugPrint('Error loading gallery: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadScreenshotsInBackground(
      AssetPathEntity screenshotAlbum) async {
    final ssTotal = await screenshotAlbum.assetCountAsync;
    final ssAssets = await screenshotAlbum.getAssetListRange(
        start: 0, end: ssTotal.clamp(0, 5000));

    final prefs = await SharedPreferences.getInstance();
    final newScreenshots = <GalleryMediaItem>[];

    for (final asset in ssAssets) {
      if (screenshotsGroup?.items.any((i) => i.id == asset.id) ?? false)
        continue;

      int fileSizeBytes = 0;
      String filePath = '';
      try {
        final originFile = await asset.file;
        filePath = originFile?.path ?? '';
        fileSizeBytes = originFile?.lengthSync() ?? 0;
      } catch (_) {}

      final item = GalleryMediaItem(
        id: asset.id,
        path: filePath,
        dateTaken: asset.createDateTime.millisecondsSinceEpoch,
        fileSize: fileSizeBytes,
        isVideo: asset.type == AssetType.video,
        videoDuration:
            asset.type == AssetType.video ? asset.videoDuration : null,
        width: asset.width,
        height: asset.height,
        mimeType: asset.mimeType,
      );

      // Load blurry state
      final savedBlurry = prefs.getBool('blurry_${item.id}');
      if (savedBlurry != null) {
        item.isBlurry = savedBlurry;
        if (savedBlurry) {
          if (blurryGroup == null) {
            blurryGroup = MonthGroup(
                label: 'Blurry Photos',
                yearMonthKey: 'blurry_photos',
                items: [item]);
          } else if (!blurryGroup!.items.any((i) => i.id == item.id)) {
            blurryGroup!.items.add(item);
          }
          blurryGroup!.recalculateCurrentIndex();
        }
      }

      final savedDecision = prefs.getString('decision_${item.id}');
      if (savedDecision != null) {
        item.decision = SwipeAction.values.firstWhere(
          (e) => e.name == savedDecision,
          orElse: () => SwipeAction.keep,
        );
        if (item.decision == SwipeAction.trash) {
          if (!_stagingBin.any((existing) => existing.id == item.id)) {
            _stagingBin.add(item);
          }
        }
      }

      newScreenshots.add(item);
    }

    if (newScreenshots.isNotEmpty) {
      if (screenshotsGroup == null) {
        screenshotsGroup = MonthGroup(
          label: 'Screenshots',
          yearMonthKey: 'screenshots',
          items: newScreenshots,
          isScreenshots: true,
        );
      } else {
        screenshotsGroup!.items.addAll(newScreenshots);
      }
      screenshotsGroup!.items
          .sort((a, b) => b.dateTaken.compareTo(a.dateTaken));
      screenshotsGroup!.recalculateCurrentIndex();
      totalTrashedBytes = _stagingBin.fold(0, (s, item) => s + item.fileSize);
      notifyListeners();
    }
  }

  Future<void> _fetchSizesForInitialItems(List<AssetEntity> assets) async {
    for (int i = 0; i < assets.length; i++) {
      final asset = assets[i];
      try {
        final file = await asset.file;
        if (file != null) {
          final size = file.lengthSync();
          // Find the item and update it
          for (final group in monthGroups) {
            final idx = group.items.indexWhere((it) => it.id == asset.id);
            if (idx != -1) {
              group.items[idx].fileSize = size;
              _categorizeLargeFile(group.items[idx]);
              break;
            }
          }
        }
      } catch (_) {}

      if (i > 0 && i % 50 == 0) {
        notifyListeners();
      }
    }
    notifyListeners();
  }

  Future<void> _loadRemainingBackground(
      AssetPathEntity album, int start, int end) async {
    isBackgroundLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, List<GalleryMediaItem>> byMonthLocal = {};

      // Process in chunks of 500 to keep UI extremely responsive
      const chunkSize = 3000;
      final totalToLoad = end - start;
      for (int i = start; i < end; i += chunkSize) {
        backgroundLoadProgress = (i - start) / totalToLoad;
        final currentEnd = (i + chunkSize).clamp(start, end);
        final assets = await album.getAssetListRange(start: i, end: currentEnd);
        for (final asset in assets) {
          int fileSizeBytes = 0;
          String filePath = '';
          try {
            final originFile = await asset.file;
            filePath = originFile?.path ?? '';
            fileSizeBytes = originFile?.lengthSync() ?? 0;
          } catch (_) {}

          final item = GalleryMediaItem(
            id: asset.id,
            path: filePath,
            dateTaken: asset.createDateTime.millisecondsSinceEpoch,
            fileSize: fileSizeBytes,
            isVideo: asset.type == AssetType.video,
            videoDuration:
                asset.type == AssetType.video ? asset.videoDuration : null,
            width: asset.width,
            height: asset.height,
            mimeType: asset.mimeType,
          );

          allItems.add(item);
          // Load blurry state
          final savedBlurry = prefs.getBool('blurry_${item.id}');
          if (savedBlurry != null) {
            item.isBlurry = savedBlurry;
            if (savedBlurry) {
              if (blurryGroup == null) {
                blurryGroup = MonthGroup(
                    label: 'Blurry Photos',
                    yearMonthKey: 'blurry_photos',
                    items: [item]);
              } else if (!blurryGroup!.items.any((i) => i.id == item.id)) {
                blurryGroup!.items.add(item);
              }
              blurryGroup!.recalculateCurrentIndex();
            }
          }

          final savedDecision = prefs.getString('decision_${item.id}');
          if (savedDecision != null) {
            item.decision = SwipeAction.values.firstWhere(
              (e) => e.name == savedDecision,
              orElse: () => SwipeAction.keep,
            );
            if (item.decision == SwipeAction.trash) {
              if (!_stagingBin.any((existing) => existing.id == item.id)) {
                _stagingBin.add(item);
              }
            }
          }

          final key =
              '${item.dateTime.year}-${item.dateTime.month.toString().padLeft(2, '0')}';

          var groupIndex = monthGroups.indexWhere((g) => g.yearMonthKey == key);
          if (groupIndex == -1) {
            final parts = key.split('-');
            monthGroups.add(MonthGroup(
                label: _monthLabel(int.parse(parts[1]), int.parse(parts[0])),
                yearMonthKey: key,
                items: [item]));
          } else {
            monthGroups[groupIndex].items.add(item);
          }

          if (item.fileSize > 10 * 1024 * 1024) {
            largeFiles10To100?.items.add(item);
          }
        }

        monthGroups.sort((a, b) => b.yearMonthKey.compareTo(a.yearMonthKey));
        for (final g in monthGroups) g.recalculateCurrentIndex();
        totalTrashedBytes = _stagingBin.fold(0, (s, item) => s + item.fileSize);
        _findSimilarPhotos();
        notifyListeners();
      }

      _findSimilarPhotos();
    } finally {
      isBackgroundLoading = false;
      backgroundLoadProgress = 1.0;
      notifyListeners();
    }
  }

  void bulkAddToStagingBin(List<GalleryMediaItem> items) {
    for (final item in items) {
      item.decision = SwipeAction.trash;
      if (!_stagingBin.any((i) => i.id == item.id)) {
        _stagingBin.add(item);
      }
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

    // Remove from all month groups
    for (final group in monthGroups) {
      group.items.removeWhere((i) => deletedIds.contains(i.id));
    }
    screenshotsGroup?.items.removeWhere((i) => deletedIds.contains(i.id));
    whatsappGroup?.items.removeWhere((i) => deletedIds.contains(i.id));

    randomGroup?.items.removeWhere((i) => deletedIds.contains(i.id));

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
    final sortedItems = allItems.where((i) => !i.isVideo).toList()
      ..sort((a, b) => b.dateTaken.compareTo(a.dateTaken));

    List<List<GalleryMediaItem>> newGroups = [];
    List<GalleryMediaItem> currentGroup = [];

    for (int i = 0; i < sortedItems.length - 1; i++) {
      final current = sortedItems[i];
      final next = sortedItems[i + 1];

      // If taken within 3 seconds of each other
      final timeDiff = (current.dateTaken - next.dateTaken).abs();

      if (timeDiff <= 3000) {
        if (currentGroup.isEmpty) currentGroup.add(current);
        // Only add if not already in the group (prevent duplicates just in case)
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
