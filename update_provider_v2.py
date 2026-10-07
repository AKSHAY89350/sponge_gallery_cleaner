import re

with open(r'lib/providers/gallery_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update properties
content = content.replace(
    '''  List<MonthGroup> monthGroups = [];
  MonthGroup? screenshotsGroup;
  MonthGroup? largeFilesGroup;
  MonthGroup? randomGroup;''',
    '''  List<MonthGroup> monthGroups = [];
  MonthGroup? screenshotsGroup;
  MonthGroup? randomGroup;
  
  // Large Files Categories
  MonthGroup? largeFiles10To100;
  MonthGroup? largeFiles100To500;
  MonthGroup? largeFiles500To1GB;
  MonthGroup? largeFilesOver1GB;
  int get totalLargeFilesCount => (largeFiles10To100?.items.length ?? 0) + 
                                  (largeFiles100To500?.items.length ?? 0) + 
                                  (largeFiles500To1GB?.items.length ?? 0) + 
                                  (largeFilesOver1GB?.items.length ?? 0);'''
)

# 2. Add categorize method
categorize_method = r'''
  void _categorizeLargeFile(GalleryMediaItem item) {
    if (item.fileSize <= 10 * 1024 * 1024) return; // not large

    MonthGroup getOrCreateGroup(MonthGroup? group, String label, String key) {
      if (group == null) {
        return MonthGroup(label: label, yearMonthKey: key, items: [item], isLargeFiles: true);
      }
      if (!group.items.any((i) => i.id == item.id)) {
        group.items.add(item);
        group.items.sort((a, b) => b.fileSize.compareTo(a.fileSize)); // sort by size descending
        group.recalculateCurrentIndex();
      }
      return group;
    }

    final mb = item.fileSize / (1024 * 1024);
    if (mb > 10 && mb <= 100) {
      largeFiles10To100 = getOrCreateGroup(largeFiles10To100, 'Large Files (10MB - 100MB)', 'large_10_100');
    } else if (mb > 100 && mb <= 500) {
      largeFiles100To500 = getOrCreateGroup(largeFiles100To500, 'Huge Files (100MB - 500MB)', 'large_100_500');
    } else if (mb > 500 && mb <= 1024) {
      largeFiles500To1GB = getOrCreateGroup(largeFiles500To1GB, 'Massive Files (500MB - 1GB)', 'large_500_1gb');
    } else if (mb > 1024) {
      largeFilesOver1GB = getOrCreateGroup(largeFilesOver1GB, 'Gigantic Files (> 1GB)', 'large_1gb_plus');
    }
  }

'''

# Insert it before `Future<void> loadGallery()`
content = content.replace('  Future<void> loadGallery() async {', categorize_method + '  Future<void> loadGallery() async {')

# 3. Update loadGallery to launch the size fetcher
# Find where the background tasks are launched
bg_tasks = r'''      // Start background load if there's more data
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
      }'''

bg_tasks_replacement = bg_tasks + r'''
      
      // Fetch sizes for initial items in background
      _fetchSizesForInitialItems(assets);
'''

content = content.replace(bg_tasks, bg_tasks_replacement)

# Remove old largeFiles logic in loadGallery
old_large = r'''          // Large files filter (>10MB)
          if (item.fileSize > 10 * 1024 * 1024) {
            largeFiles.add(item);
          }'''
content = content.replace(old_large, '')

old_large_group = r'''      if (largeFiles.isNotEmpty) {
        largeFilesGroup = MonthGroup(
          label: 'Large Files (>10MB)',
          yearMonthKey: 'large',
          items: largeFiles,
          isLargeFiles: true,
        )..recalculateCurrentIndex();
      }'''
content = content.replace(old_large_group, '')
content = content.replace('final largeFiles = <GalleryMediaItem>[];\n', '')
content = content.replace('final largeFiles = <GalleryMediaItem>[];', '')

# 4. Update _loadRemainingBackground to use _categorizeLargeFile
content = content.replace(
    '''      if (item.fileSize > 10 * 1024 * 1024) {
        largeFilesGroup?.items.add(item);
      }''',
    '''      _categorizeLargeFile(item);'''
)

content = content.replace('      largeFilesGroup?.items.removeWhere((i) => deletedIds.contains(i.id));',
'''      largeFiles10To100?.items.removeWhere((i) => deletedIds.contains(i.id));
      largeFiles100To500?.items.removeWhere((i) => deletedIds.contains(i.id));
      largeFiles500To1GB?.items.removeWhere((i) => deletedIds.contains(i.id));
      largeFilesOver1GB?.items.removeWhere((i) => deletedIds.contains(i.id));''')


# 5. Add _fetchSizesForInitialItems method
fetch_method = r'''
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
'''

content = content.replace('  Future<void> _loadRemainingBackground', fetch_method + '  Future<void> _loadRemainingBackground')

with open(r'lib/providers/gallery_provider.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("GalleryProvider updated with Large File categories")
