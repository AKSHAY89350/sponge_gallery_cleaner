import re

with open(r'lib/providers/gallery_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add isBackgroundLoading
content = content.replace(
    'bool isLoading = false;\n  bool isInitialized = false;\n',
    'bool isLoading = false;\n  bool isInitialized = false;\n  bool isBackgroundLoading = false;\n'
)

# Modify loadGallery signature
load_pattern = r'final assets = await allAlbum\.getAssetListRange\(\s*start: 0,\s*end: total\.clamp\(0, 15000\), // Increased from 2000 to show more months\s*\);'
load_replacement = r'''final initialLoadEnd = total.clamp(0, 3000);
        final assets = await allAlbum.getAssetListRange(
          start: 0,
          end: initialLoadEnd,
        );'''
content = re.sub(load_pattern, load_replacement, content)


# Find the end of loadGallery() and add the trigger
end_pattern = r'isInitialized = true;\n    \} catch \(e\) \{\n      debugPrint\(\'Error loading gallery: \$e\'\);\n    \}\n\n    isLoading = false;\n    notifyListeners\(\);\n  \}'

end_replacement = r'''isInitialized = true;
      
      // Start background load if there's more data
      if (albums.isNotEmpty) {
         final total = await albums.first.assetCountAsync;
         if (total > 3000) {
            _loadRemainingBackground(albums.first, 3000, total.clamp(0, 20000));
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
    const chunkSize = 500;
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
  }'''

content = re.sub(end_pattern, end_replacement, content)

with open(r'lib/providers/gallery_provider.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("gallery_provider updated")
