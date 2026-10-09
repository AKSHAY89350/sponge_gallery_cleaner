import re

path = 'lib/features/gallery_core/providers/gallery_provider.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = """          if (item.fileSize > 10 * 1024 * 1024) {
            largeFiles10To100?.items.add(item);
          }"""

replacement = """          if (item.fileSize > 10 * 1024 * 1024) {
            _categorizeLargeFile(item);
          }"""

if target in content:
    content = content.replace(target, replacement)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Fixed _categorizeLargeFile in background loop.")
else:
    print("Target not found.")
