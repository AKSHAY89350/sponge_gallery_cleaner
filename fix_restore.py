import re

with open(r'lib/providers/gallery_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = r'''  void removeFromStagingBin\(GalleryMediaItem item\) \{
    item\.decision = null;
    _stagingBin\.removeWhere\(\(i\) => i\.id == item\.id\);
    totalTrashedBytes = _stagingBin\.fold\(0, \(s, i\) => s \+ i\.fileSize\);
    _clearDecision\(item\.id\);
    notifyListeners\(\);
  \}'''

replacement = r'''  void removeFromStagingBin(GalleryMediaItem item) {
    item.decision = null;
    _stagingBin.removeWhere((i) => i.id == item.id);
    totalTrashedBytes = _stagingBin.fold(0, (s, i) => s + i.fileSize);
    _clearDecision(item.id);
    
    for (final g in monthGroups) { g.recalculateCurrentIndex(); }
    screenshotsGroup?.recalculateCurrentIndex();
    whatsappGroup?.recalculateCurrentIndex();
    randomGroup?.recalculateCurrentIndex();
    
    notifyListeners();
  }'''

content = re.sub(target, replacement, content)

with open(r'lib/providers/gallery_provider.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed restore")
