import re

path = 'lib/features/gallery_core/providers/gallery_provider.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = """  bool get hasUnscannedBlurry =>
      allItems.any((i) => i.isBlurry == null && !i.isVideo);"""

replacement = """  bool get hasUnscannedBlurry =>
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
  }"""

if target in content:
    content = content.replace(target, replacement)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Added refreshRandomGroup.")
else:
    print("Target not found.")
