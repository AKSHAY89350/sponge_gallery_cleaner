import re

with open(r'lib/screens/swipe_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('_GridPreviewDialog(item: item)', 'UniversalPreviewDialog(items: dateItems, initialIndex: index)')

with open(r'lib/screens/swipe_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed swipe_screen dialog")
