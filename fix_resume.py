import re

with open(r'lib/providers/gallery_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. loadGallery() monthGroups
content = content.replace(
    '''        return MonthGroup(
          label: label,
          yearMonthKey: entry.key,
          items: entry.value,
        );''',
    '''        return MonthGroup(
          label: label,
          yearMonthKey: entry.key,
          items: entry.value,
        )..recalculateCurrentIndex();'''
)

# 2. screenshotsGroup
content = content.replace(
    '''        screenshotsGroup = MonthGroup(
          label: 'Screenshots',
          yearMonthKey: 'screenshots',
          items: screenshots,
          isScreenshots: true,
        );''',
    '''        screenshotsGroup = MonthGroup(
          label: 'Screenshots',
          yearMonthKey: 'screenshots',
          items: screenshots,
          isScreenshots: true,
        )..recalculateCurrentIndex();'''
)

# 3. largeFilesGroup
content = content.replace(
    '''        largeFilesGroup = MonthGroup(
          label: 'Large Files (>10MB)',
          yearMonthKey: 'large',
          items: largeFiles,
          isLargeFiles: true,
        );''',
    '''        largeFilesGroup = MonthGroup(
          label: 'Large Files (>10MB)',
          yearMonthKey: 'large',
          items: largeFiles,
          isLargeFiles: true,
        )..recalculateCurrentIndex();'''
)

# 4. randomGroup
content = content.replace(
    '''        randomGroup = MonthGroup(
          label: 'Random Clean',
          yearMonthKey: 'random',
          items: randomItems.take(20).toList(),
        );''',
    '''        randomGroup = MonthGroup(
          label: 'Random Clean',
          yearMonthKey: 'random',
          items: randomItems.take(20).toList(),
        )..recalculateCurrentIndex();'''
)

# 5. _loadRemainingBackground
content = content.replace(
    '''      monthGroups.sort((a, b) => b.yearMonthKey.compareTo(a.yearMonthKey));
      totalTrashedBytes = _stagingBin.fold(0, (s, item) => s + item.fileSize);
      notifyListeners();''',
    '''      monthGroups.sort((a, b) => b.yearMonthKey.compareTo(a.yearMonthKey));
      for (final g in monthGroups) g.recalculateCurrentIndex();
      totalTrashedBytes = _stagingBin.fold(0, (s, item) => s + item.fileSize);
      notifyListeners();'''
)

# 6. _loadScreenshotsInBackground
content = content.replace(
    '''      screenshotsGroup!.items.sort((a, b) => b.dateTaken.compareTo(a.dateTaken));
      totalTrashedBytes = _stagingBin.fold(0, (s, item) => s + item.fileSize);
      notifyListeners();''',
    '''      screenshotsGroup!.items.sort((a, b) => b.dateTaken.compareTo(a.dateTaken));
      screenshotsGroup!.recalculateCurrentIndex();
      totalTrashedBytes = _stagingBin.fold(0, (s, item) => s + item.fileSize);
      notifyListeners();'''
)

with open(r'lib/providers/gallery_provider.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated Provider to use recalculateCurrentIndex")
