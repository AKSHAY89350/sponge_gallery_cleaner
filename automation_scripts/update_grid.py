import re

path = 'lib/features/media_cleaners/swipe_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace _buildGridView
target_grid = """  Widget _buildGridView() {"""
replacement_grid = """  Widget _buildGridView() {
    final remainingItems =
        widget.group.items.where((i) => i.decision == null).toList();
    if (remainingItems.isEmpty) return const SizedBox.shrink();

    // Group by Date (Day)
    final Map<String, List<GalleryMediaItem>> itemsByDate = {};
    for (final item in remainingItems) {
      final dateLabel = DateFormat('MMM d').format(item.dateTime);
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
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (allSelected) {
                        for (final i in dateItems) {
                          _selectedIds.remove(i.id);
                        }
                      } else {
                        for (final i in dateItems) {
                          _selectedIds.add(i.id);
                        }
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Text('Select All', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(width: 6),
                        Icon(
                          allSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: allSelected ? const Color(0xFF7C3AED) : Colors.white54,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
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
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = dateItems[index];
                final isSelected = _selectedIds.contains(item.id);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedIds.remove(item.id);
                      } else {
                        _selectedIds.add(item.id);
                      }
                    });
                  },
                  onLongPress: () {
                    HapticFeedback.heavyImpact();
                    showDialog(
                      context: context,
                      barrierColor: Colors.black.withOpacity(0.9),
                      builder: (_) => UniversalPreviewDialog(
                          items: remainingItems,
                          initialIndex: remainingItems.indexOf(item)),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF7C3AED) : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: _CachedThumbnail(item: item),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Color(0xFF7C3AED),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
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

    // Add extra padding at the bottom so the last row isn't hidden by the floating bar
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 120)));

    return CustomScrollView(
      slivers: slivers,
    );
  }

  // REPLACED OLD METHOD BELOW
  Widget _oldBuildGridView() {"""

# Replace _buildGridControls
target_controls = """  Widget _buildGridControls() {"""
replacement_controls = """  Widget _buildGridControls() {
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF26262F), // Darker grey for modern floating bar
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ]
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${_selectedIds.length} items selected',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: _bulkKeep,
              child: const Text('Keep', style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                elevation: 0,
              ),
              onPressed: _bulkTrash,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Trash', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // REPLACED OLD METHOD BELOW
  Widget _oldBuildGridControls() {"""


# Let's fix the tree.
import re
content = re.sub(r'  Widget _buildGridView\(\) \{.*?(?=  Widget _buildGridControls\(\) \{)', replacement_grid + '\n', content, flags=re.DOTALL)
content = re.sub(r'  Widget _buildGridControls\(\) \{.*?(?=  Widget _buildCardArea\(\) \{)', replacement_controls + '\n', content, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated grid view and grid controls.")
