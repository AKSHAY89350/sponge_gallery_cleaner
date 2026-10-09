import re

swipe_path = 'lib/features/media_cleaners/swipe_screen.dart'
with open(swipe_path, 'r', encoding='utf-8') as f:
    swipe_content = f.read()

target = """  @override
  void initState() {"""

replacement = """  @override
  void dispose() {
    _previewScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {"""

# Replace only the first occurrence
swipe_content = swipe_content.replace(target, replacement, 1)

with open(swipe_path, 'w', encoding='utf-8') as f:
    f.write(swipe_content)
print("Added dispose method correctly")
