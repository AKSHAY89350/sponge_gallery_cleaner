import re
import os

files = [
    r'lib/screens/swipe_screen.dart',
    r'lib/screens/blurry_photos_screen.dart',
    r'lib/screens/similar_photos_screen.dart'
]

for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Add import
    if "import '../widgets/universal_preview_dialog.dart';" not in content:
        content = content.replace("import '../providers/gallery_provider.dart';", "import '../providers/gallery_provider.dart';\nimport '../widgets/universal_preview_dialog.dart';")
    
    # 2. Replace _PreviewDialog(items: items, initialIndex: i) with UniversalPreviewDialog(items: items, initialIndex: i)
    content = re.sub(r'_PreviewDialog\(\s*items:\s*([^,]+),\s*initialIndex:\s*([^\)]+)\)', r'UniversalPreviewDialog(items: \1, initialIndex: \2)', content)

    # 3. For SwipeScreen which uses _GridPreviewDialog(item: items[index])
    # We need to change it to UniversalPreviewDialog(items: items, initialIndex: index)
    if 'swipe_screen.dart' in file:
        content = re.sub(r'_GridPreviewDialog\(\s*item:\s*([^\[]+)\[([^\]]+)\]\s*\)', r'UniversalPreviewDialog(items: \1, initialIndex: \2)', content)
    
    # 4. Remove local _PreviewDialog and _GridPreviewDialog classes completely
    content = re.sub(r'class _PreviewDialog extends StatefulWidget \{.*', '', content, flags=re.DOTALL)
    content = re.sub(r'class _GridPreviewDialog extends StatefulWidget \{.*', '', content, flags=re.DOTALL)

    with open(file, 'w', encoding='utf-8') as f:
        f.write(content)
    
print("Updated all screens to use UniversalPreviewDialog")
