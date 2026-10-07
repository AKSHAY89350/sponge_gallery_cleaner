import re

with open(r'lib/providers/gallery_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

bulk_methods = '''  void bulkAddToStagingBin(List<GalleryMediaItem> items) {
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
'''

content = content.replace(
    '  void addToStagingBin(GalleryMediaItem item) {',
    bulk_methods + '\n  void addToStagingBin(GalleryMediaItem item) {'
)

with open(r'lib/providers/gallery_provider.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Added bulk methods to provider")
