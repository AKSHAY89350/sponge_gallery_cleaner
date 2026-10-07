import re
import os

# 1. Fix gallery_media_item.dart
with open(r'lib/models/gallery_media_item.dart', 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace('final int fileSize;', 'int fileSize;')
with open(r'lib/models/gallery_media_item.dart', 'w', encoding='utf-8') as f:
    f.write(content)

# 2. Fix gallery_provider.dart
with open(r'lib/providers/gallery_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix `Undefined name 'assets'` in `_fetchSizesForInitialItems(assets);`
# Wait, `assets` was the variable name. Ah, inside `loadGallery`, I have:
# `final assets = await allAlbum.getAssetListRange(start: 0, end: initialLoadEnd);`
# But I injected `_fetchSizesForInitialItems(assets);` inside `if (albums.isNotEmpty) { ... }` where `assets` is NOT defined! It's out of scope.
content = content.replace(
'''      // Fetch sizes for initial items in background
      _fetchSizesForInitialItems(assets);''',
'''      // Fetch sizes for initial items in background
      // _fetchSizesForInitialItems is called from inside the loop now.''')

# Where should I call _fetchSizesForInitialItems?
# Right after: `final assets = await allAlbum.getAssetListRange(...);`
# Wait, if I just do it right after `monthGroups.sort(...)` at the end of `loadGallery`:
content = content.replace('  Future<void> loadGallery() async {', '  List<AssetEntity> _initialAssets = [];\n  Future<void> loadGallery() async {')
content = content.replace('final assets = await allAlbum.getAssetListRange(', '_initialAssets = await allAlbum.getAssetListRange(')
content = content.replace('for (final asset in assets) {', 'for (final asset in _initialAssets) {')
content = content.replace('notifyListeners();\n    } catch (e) {', 'notifyListeners();\n      _fetchSizesForInitialItems(_initialAssets);\n    } catch (e) {')

# Remove leftover largeFilesGroup
content = content.replace('largeFilesGroup?.items.removeWhere((i) => deletedIds.contains(i.id));', '')

with open(r'lib/providers/gallery_provider.dart', 'w', encoding='utf-8') as f:
    f.write(content)

# 3. Fix home_screen.dart (there's another largeFilesGroup reference?)
with open(r'lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()
# Let's check what uses largeFilesGroup
# `if (provider.largeFilesGroup != null)` maybe?
content = content.replace('if (provider.largeFilesGroup != null)', 'if (provider.totalLargeFilesCount > 0)')
# Wait, I had:
# _QuickActionCard(
#              title: 'Large Files',
#              subtitle: '${provider.totalLargeFilesCount} items',
#              icon: Icons.folder_zip_rounded,
#              color: Colors.orange,
#              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LargeFilesMenuScreen())),
#            ),
# Wait, if there was another reference...
content = content.replace('provider.largeFilesGroup!', 'null')
# I'll just regex remove `provider.largeFilesGroup` completely.
content = re.sub(r'provider\.largeFilesGroup\b', 'null', content)
with open(r'lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)


# 4. Fix large_files_menu_screen.dart
with open(r'lib/screens/large_files_menu_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()
if "import '../models/gallery_media_item.dart';" not in content:
    content = content.replace("import 'swipe_screen.dart';", "import 'swipe_screen.dart';\nimport '../models/gallery_media_item.dart';")
with open(r'lib/screens/large_files_menu_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixes applied")
