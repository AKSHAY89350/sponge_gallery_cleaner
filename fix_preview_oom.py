import re

with open(r'lib/screens/similar_photos_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = r'''    _future = AssetEntity\.fromId\(widget\.item\.id\)\.then\(\(e\) => e\?\.originBytes\);'''

# Change it to load a high-res thumbnail (1024x1024) instead of full bytes which could be 50MB!
new_code = r'''    _future = AssetEntity.fromId(widget.item.id).then((e) => e?.thumbnailDataWithSize(const ThumbnailSize.square(1024)));'''

content = re.sub(target, new_code, content)

with open(r'lib/screens/similar_photos_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("OOM protection added to preview")
