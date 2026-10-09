import re

path = 'lib/features/media_cleaners/swipe_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target1 = """class SwipeScreen extends StatefulWidget {
  final MonthGroup group;
  const SwipeScreen({super.key, required this.group});"""

replacement1 = """class SwipeScreen extends StatefulWidget {
  final MonthGroup group;
  final bool isEmbedded;
  const SwipeScreen({super.key, required this.group, this.isEmbedded = false});"""

target2 = """      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),"""

replacement2 = """      leading: widget.isEmbedded ? const SizedBox.shrink() : IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),"""

if target1 in content and target2 in content:
    content = content.replace(target1, replacement1).replace(target2, replacement2)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Updated SwipeScreen.")
else:
    print("Target not found.")
