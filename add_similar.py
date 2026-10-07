import re

with open(r'lib/providers/gallery_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add similarPhotoGroups variable
vars_target = r'''  double\? freeDiskSpaceMB;'''
vars_code = r'''  double? freeDiskSpaceMB;
  
  List<List<GalleryMediaItem>> similarPhotoGroups = [];'''
content = re.sub(vars_target, vars_code, content)

# Add _findSimilarPhotos method
methods_code = r'''
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
'''

# We need to append this method inside the class.
# We will just replace the last closing brace with the method and a closing brace.
content = content.rsplit('}', 1)[0] + methods_code + '}'

# We should call _findSimilarPhotos() after the background load finishes or updates.
# Let's call it inside `_loadRemainingBackground` after the while loop finishes, and also in `loadGallery` after initial load.
call_initial = r'''      _fetchSizesForInitialItems(_initialAssets);
      fetchDiskSpace();'''
call_initial_new = r'''      _fetchSizesForInitialItems(_initialAssets);
      fetchDiskSpace();
      _findSimilarPhotos();'''
content = content.replace(call_initial, call_initial_new)

call_bg = r'''      totalTrashedBytes = _stagingBin.fold(0, (s, item) => s + item.fileSize);
      notifyListeners();
    }

    isBackgroundLoading = false;
    notifyListeners();'''
call_bg_new = r'''      totalTrashedBytes = _stagingBin.fold(0, (s, item) => s + item.fileSize);
      _findSimilarPhotos();
      notifyListeners();
    }

    isBackgroundLoading = false;
    _findSimilarPhotos();
    notifyListeners();'''
content = content.replace(call_bg, call_bg_new)

with open(r'lib/providers/gallery_provider.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Added similar photos logic")
