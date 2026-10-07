import re

with open(r'lib/providers/gallery_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add allItems.add(item) for screenshots in background
target_ss = r'''        final savedDecision = prefs\.getString\('decision_\$\{item\.id\}'\);
        if \(savedDecision != null\) \{
          item\.decision = SwipeAction\.values\.firstWhere\('''
replacement_ss = r'''        allItems.add(item);
        final savedDecision = prefs.getString('decision_${item.id}');
        if (savedDecision != null) {
          item.decision = SwipeAction.values.firstWhere('''
content = re.sub(target_ss, replacement_ss, content)

# It matches both! Let's check how many times it matched.
# It should match twice (once for ssAssets, once for main assets)

# Next, wrap in try/finally
target_func = r'''  Future<void> _loadRemainingBackground\(AssetPathEntity album, int start, int end\) async \{
    isBackgroundLoading = true;
    notifyListeners\(\);

    final prefs = await SharedPreferences\.getInstance\(\);'''

replacement_func = r'''  Future<void> _loadRemainingBackground(AssetPathEntity album, int start, int end) async {
    isBackgroundLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();'''
content = re.sub(target_func, replacement_func, content)

target_end = r'''      isBackgroundLoading = false;
      _findSimilarPhotos\(\);
      notifyListeners\(\);
    \}'''
replacement_end = r'''      _findSimilarPhotos();
    } finally {
      isBackgroundLoading = false;
      notifyListeners();
    }
  }'''
content = re.sub(target_end, replacement_end, content)

with open(r'lib/providers/gallery_provider.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Bug fixed")
