import re

with open(r'lib/providers/gallery_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update _scanBlurryQueue to save to SharedPreferences
scan_pattern = re.compile(r'(final isB = await BlurDetector\.isImageBlurry\(data\);\s*item\.isBlurry = isB;)', re.DOTALL)
new_scan = """\\1
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('blurry_${item.id}', isB);"""
content = scan_pattern.sub(new_scan, content)

# 2. Update GalleryMediaItem initialization to load blurry state
# There are 3 places: loadGallery, _loadScreenshotsInBackground, _loadRemainingBackground
item_pattern = re.compile(r'final savedDecision = prefs\.getString\(\'decision_\$\{item\.id\}\'\);')
new_item = """// Load blurry state
          final savedBlurry = prefs.getBool('blurry_${item.id}');
          if (savedBlurry != null) {
            item.isBlurry = savedBlurry;
            if (savedBlurry) {
              if (blurryGroup == null) {
                blurryGroup = MonthGroup(label: 'Blurry Photos', yearMonthKey: 'blurry_photos', items: [item]);
              } else if (!blurryGroup!.items.any((i) => i.id == item.id)) {
                blurryGroup!.items.add(item);
              }
              blurryGroup!.recalculateCurrentIndex();
            }
          }
          
          final savedDecision = prefs.getString('decision_${item.id}');"""
content = item_pattern.sub(new_item, content)


# 3. permanentlyDeleteStaged should also clear blurry state
delete_pattern = re.compile(r'(await prefs\.remove\(\'decision_\$id\'\);)')
new_delete = """\\1
        await prefs.remove('blurry_$id');"""
content = delete_pattern.sub(new_delete, content)

with open(r'lib/providers/gallery_provider.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated GalleryProvider with blurry persistency")
