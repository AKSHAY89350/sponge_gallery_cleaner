import re

with open(r'lib/screens/swipe_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if "import 'package:intl/intl.dart';" not in content:
    content = content.replace("import 'staging_bin_screen.dart';", "import 'staging_bin_screen.dart';\nimport 'package:intl/intl.dart';")

# Replace _buildGridView
old_grid_pattern = r'''  Widget _buildGridView\(\) \{[\s\S]*?    \);\n  \}'''

new_grid_method = r'''  Widget _buildGridView() {
    final remainingItems = widget.group.items.skip(_currentIndex).toList();
    if (remainingItems.isEmpty) return const SizedBox.shrink();

    // Group by Date (Day)
    final Map<String, List<GalleryMediaItem>> itemsByDate = {};
    for (final item in remainingItems) {
      final dateLabel = DateFormat('MMM d, yyyy').format(item.dateTime);
      itemsByDate.putIfAbsent(dateLabel, () => []).add(item);
    }

    final slivers = <Widget>[];

    for (final entry in itemsByDate.entries) {
      final dateLabel = entry.key;
      final dateItems = entry.value;

      final allSelected = dateItems.every((i) => _selectedIds.contains(i.id));

      // Header
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 4, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateLabel, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(
                    allSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: allSelected ? const Color(0xFF6C63FF) : Colors.white54,
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (allSelected) {
                        for (final i in dateItems) _selectedIds.remove(i.id);
                      } else {
                        for (final i in dateItems) _selectedIds.add(i.id);
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // Grid
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = dateItems[index];
                final isSelected = _selectedIds.contains(item.id);

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (isSelected) {
                        _selectedIds.remove(item.id);
                      } else {
                        _selectedIds.add(item.id);
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _CachedMediaThumbnail(item: item, size: 300, quality: 60),
                        if (item.isVideo)
                          const Positioned(
                            bottom: 4,
                            right: 4,
                            child: Icon(Icons.play_circle_fill, color: Colors.white, size: 20),
                          ),
                        if (isSelected)
                          Container(
                            color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                            child: const Center(
                              child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 32),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
              childCount: dateItems.length,
            ),
          ),
        ),
      );
    }

    // Bottom padding for controls
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 100)));

    return CustomScrollView(
      slivers: slivers,
    );
  }'''

content = re.sub(old_grid_pattern, new_grid_method, content)

with open(r'lib/screens/swipe_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated grid view with grouped dates")
