import re

with open(r'lib/providers/gallery_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if "import 'package:disk_space_2/disk_space_2.dart';" not in content:
    content = content.replace("import 'package:photo_manager/photo_manager.dart';", "import 'package:photo_manager/photo_manager.dart';\nimport 'package:disk_space_2/disk_space_2.dart';")

# Add variables
vars = r'''  int totalTrashedBytes = 0;

  double? totalDiskSpaceMB;
  double? freeDiskSpaceMB;
  
  Future<void> fetchDiskSpace() async {
    try {
      totalDiskSpaceMB = await DiskSpace.getTotalDiskSpace;
      freeDiskSpaceMB = await DiskSpace.getFreeDiskSpace;
      notifyListeners();
    } catch (_) {}
  }
'''
content = content.replace('  int totalTrashedBytes = 0;', vars)

# Call fetchDiskSpace inside loadGallery
call_fetch = r'''      // Fetch sizes for initial items in background
      _fetchSizesForInitialItems(_initialAssets);
      fetchDiskSpace();'''
content = content.replace('      _fetchSizesForInitialItems(_initialAssets);', call_fetch)

with open(r'lib/providers/gallery_provider.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Added disk_space_2 to GalleryProvider")
