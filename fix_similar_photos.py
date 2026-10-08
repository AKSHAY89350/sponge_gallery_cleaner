import re

with open(r'lib/screens/similar_photos_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = """                return GestureDetector(
                  onTap: () {"""

replacement = """                return GestureDetector(
                  onLongPress: () {
                    HapticFeedback.heavyImpact();
                    showDialog(
                      context: context,
                      barrierColor: Colors.black.withValues(alpha: 0.9),
                      builder: (_) => UniversalPreviewDialog(items: group, initialIndex: i),
                    );
                  },
                  onTap: () {"""

content = content.replace(target, replacement)

with open(r'lib/screens/similar_photos_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Fixed similar photos screen")
