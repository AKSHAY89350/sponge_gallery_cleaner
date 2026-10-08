import sys

with open(r'lib/screens/swipe_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = """                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();"""

replacement = """                return GestureDetector(
                  onLongPress: () {
                    HapticFeedback.heavyImpact();
                    showDialog(
                      context: context,
                      barrierColor: Colors.black.withValues(alpha: 0.9),
                      builder: (_) => _GridPreviewDialog(item: item),
                    );
                  },
                  onTap: () {
                    HapticFeedback.selectionClick();"""

content = content.replace(target, replacement)

with open(r'lib/screens/swipe_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Added onLongPress to SwipeScreen GridView")
