import re

# Fix 1: Remove > sign from home_screen.dart
home_path = 'lib/features/dashboard/home_screen.dart'
with open(home_path, 'r', encoding='utf-8') as f:
    home_content = f.read()

home_content = home_content.replace("'$percent%  >'", "'$percent%'")
with open(home_path, 'w', encoding='utf-8') as f:
    f.write(home_content)
print("Fixed home_screen.dart")

# Fix 2: Add video icon to Grid View in swipe_screen.dart
swipe_path = 'lib/features/media_cleaners/swipe_screen.dart'
with open(swipe_path, 'r', encoding='utf-8') as f:
    swipe_content = f.read()

# We need to find the _CachedMediaThumbnail inside _buildGridView
target_thumb = """                        ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: _CachedMediaThumbnail(item: item),
                        ),
                        if (isSelected)"""

replacement_thumb = """                        ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: _CachedMediaThumbnail(item: item),
                        ),
                        if (item.isVideo)
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        if (isSelected)"""

swipe_content = swipe_content.replace(target_thumb, replacement_thumb)
with open(swipe_path, 'w', encoding='utf-8') as f:
    f.write(swipe_content)
print("Fixed swipe_screen.dart video icon")
