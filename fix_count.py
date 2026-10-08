import re

with open(r'lib/screens/swipe_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = r'''            Text\(
              '\$_currentIndex / \$\{widget\.group\.totalItems\}',
              style: const TextStyle\(color: Colors\.white54, fontSize: 12\),
            \),'''

new_code = r'''            Text(
              '${widget.group.items.where((i) => i.decision != null).length} / ${widget.group.totalItems}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),'''

content = re.sub(target, new_code, content)

with open(r'lib/screens/swipe_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Count fixed")
