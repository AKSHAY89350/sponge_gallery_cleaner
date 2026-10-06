import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gallery_media_item.dart';
import 'dart:math';

class GalleryProvider extends ChangeNotifier {
  List<MonthGroup> monthGroups = [];
  MonthGroup? screenshotsGroup;
  MonthGroup? largeFilesGroup;
  MonthGroup? randomGroup;

  bool isLoading = false;
  bool isInitialized = false;
  bool isBackgroundLoading = false;
  int totalTrashedBytes = 0;

  final List<GalleryMediaItem> _stagingBin = [];
  List<GalleryMediaItem> get stagingBin => List.unmodifiable(_stagingBin);

  Future<bool> checkPermissions() async {
    final result = await PhotoManager.requestPermissionExtend();
    return result.isAuth;
  }

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
      final List<GalleryMediaItem> largeFiles = [];
      final List<GalleryMediaItem> allItems = [];

      final prefs = await SharedPreferences.getInstance();

      if (albums.isNotEmpty) {
        final allAlbum = albums.first;
        final total = await allAlbum.assetCountAsync;
        final initialLoadEnd = total.clamp(0, 3000);
        final assets = await allAlbum.getAssetListRange(
          start: 0,
          end: initialLoadEnd,
        );

        for (final asset in assets) {
          int fileSizeBytes = 0;
          String filePath = '';
          try {
            final originFile = await asset.originFile;
            filePath = originFile?.path ?? '';
            fileSizeBytes = originFile?.lengthSync() ?? 0;
          } catch (_) {
            // File might be restricted or deleted from storage
          }

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

          // Large files filter (>10MB)
          if (item.fileSize > 10 * 1024 * 1024) {
            largeFiles.add(item);
          }
        }
      }

      // ────────────────────────────────────────────────────────────────────────
      // DIRECT SCREENSHOTS ALBUM FETCH
      // Bypass the 2000 recent items limit to get ALL screenshots perfectly
      // ────────────────────────────────────────────────────────────────────────
      AssetPathEntity? screenshotAlbum;
      for (final album in albums) {
        if (album.name.toLowerCase().contains('screenshot')) {
          screenshotAlbum = album;
          break;
        }
      }

      if (screenshotAlbum != null) {
        final ssTotal = await screenshotAlbum.assetCountAsync;
        final ssAssets = await screenshotAlbum.getAssetListRange(
          start: 0, 
          end: ssTotal.clamp(0, 3000) // load up to 3000 screenshots
        );
        
        for (final asset in ssAssets) {
          // Skip if already found in the main "Recent" pass
          if (screenshots.any((i) => i.id == asset.id)) continue;

          int fileSizeBytes = 0;
          String filePath = '';
          try {
            final originFile = await asset.file; // .file is faster than .originFile
            filePath = originFile?.path ?? '';
            fileSizeBytes = originFile?.lengthSync() ?? 0;
          } catch (_) {}

          final item = GalleryMediaItem(
            id: asset.id,
            path: filePath,
            dateTaken: asset.createDateTime.millisecondsSinceEpoch,
            fileSize: fileSizeBytes,
            isVideo: asset.type == AssetType.video,
            videoDuration: asset.type == AssetType.video ? asset.videoDuration : null,
            width: asset.width,
            height: asset.height,
            mimeType: asset.mimeType,
          );

          // Load decision
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

          screenshots.add(item);
        }
      }

      // Sort screenshots by date newest first
      screenshots.sort((a, b) => b.dateTaken.compareTo(a.dateTaken));

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
        );
      }).toList()
        ..sort((a, b) => b.yearMonthKey.compareTo(a.yearMonthKey));

      if (screenshots.isNotEmpty) {
        screenshotsGroup = MonthGroup(
          label: 'Screenshots',
          yearMonthKey: 'screenshots',
          items: screenshots,
          isScreenshots: true,
        );
      }

      if (largeFiles.isNotEmpty) {
        largeFilesGroup = MonthGroup(
          label: 'Large Files (>10MB)',
          yearMonthKey: 'large',
          items: largeFiles,
          isLargeFiles: true,
        );
      }

      // Random group - pick 20 random items
      if (allItems.length > 5) {
        final rng = Random();
        final randomItems = List<GalleryMediaItem>.from(allItems)..shuffle(rng);
        randomGroup = MonthGroup(
          label: 'Random Clean',
          yearMonthKey: 'random',
          items: randomItems.take(20).toList(),
        );
      }

      // Recalculate trashed bytes
      totalTrashedBytes =
          _stagingBin.fold(0, (s, i) => s + i.fileSize);

      isInitialized = true;
      
      // Start background load if there's more data
      if (albums.isNotEmpty) {
         final total = await albums.first.assetCountAsync;
         if (total > 3000) {
            _loadRemainingBackground(albums.first, 3000, total.clamp(0, 50000));
         }
      }
    } catch (e) {
      debugPrint('Error loading gallery: $e');
    }

    isLoading = false;
    notifyListeners();
  }
  
  Future<void> _loadRemainingBackground(AssetPathEntity album, int start, int end) async {
    isBackgroundLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final Map<String, List<GalleryMediaItem>> byMonthLocal = {};
    
    // Process in chunks of 500 to keep UI extremely responsive
    const chunkSize = 3000;
    for (int i = start; i < end; i += chunkSize) {
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
          videoDuration: asset.type == AssetType.video ? asset.videoDuration : null,
          width: asset.width,
          height: asset.height,
          mimeType: asset.mimeType,
        );

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

        final key = '${item.dateTime.year}-${item.dateTime.month.toString().padLeft(2, '0')}';
        
        var groupIndex = monthGroups.indexWhere((g) => g.yearMonthKey == key);
        if (groupIndex == -1) {
           final parts = key.split('-');
           monthGroups.add(MonthGroup(
             label: _monthLabel(int.parse(parts[1]), int.parse(parts[0])),
             yearMonthKey: key,
             items: [item]
           ));
        } else {
           monthGroups[groupIndex].items.add(item);
        }

        if (item.fileSize > 10 * 1024 * 1024) {
           largeFilesGroup?.items.add(item);
        }
      }
      
      monthGroups.sort((a, b) => b.yearMonthKey.compareTo(a.yearMonthKey));
      totalTrashedBytes = _stagingBin.fold(0, (s, item) => s + item.fileSize);
      notifyListeners();
    }

    isBackgroundLoading = false;
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
    notifyListeners();
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
    }

    // Remove from all month groups
    for (final group in monthGroups) {
      group.items.removeWhere((i) => deletedIds.contains(i.id));
    }
    screenshotsGroup?.items.removeWhere((i) => deletedIds.contains(i.id));
    largeFilesGroup?.items.removeWhere((i) => deletedIds.contains(i.id));
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
}



