import re

with open(r'lib/providers/gallery_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = r'''          if \(item\.fileSize > 10 \* 1024 \* 1024\) \{
             largeFiles10To100\?\.items\.add\(item\);
          \}'''

replacement = r'''          _categorizeLargeFile(item);'''

content = re.sub(target, replacement, content)

with open(r'lib/providers/gallery_provider.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Large file categorization fixed")
