import re

with open(r'lib/screens/blurry_photos_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = "return _BlurryGridThumbnail(item: item);"
replacement = """final isSelected = _selectedIds.contains(item.id);
        return _BlurryGridThumbnail(
          item: item, 
          allItems: items, 
          index: i,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedIds.remove(item.id);
              } else {
                _selectedIds.add(item.id);
              }
            });
          },
        );"""

content = content.replace(target, replacement)

with open(r'lib/screens/blurry_photos_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Fixed blurry constructor")
