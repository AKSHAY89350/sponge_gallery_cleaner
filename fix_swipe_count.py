import sys

with open(r'lib/screens/swipe_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = """          Text(
            '$_currentIndex / ${widget.group.totalItems}',"""
replacement = """          Text(
            '${widget.group.trashedCount + widget.group.keptCount} / ${widget.group.totalItems}',"""

content = content.replace(target, replacement)

with open(r'lib/screens/swipe_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Fixed SwipeScreen header count")
