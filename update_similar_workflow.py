import re

with open(r'lib/screens/similar_photos_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = r'''class _SimilarPhotosScreenState extends State<SimilarPhotosScreen> \{
  final Set<String> _selectedIds = \{\};

  void _trashSelected\(\) \{'''

new_logic = r'''class _SimilarPhotosScreenState extends State<SimilarPhotosScreen> {
  // Holds the IDs of photos the user wants to KEEP
  final Set<String> _selectedToKeepIds = {};

  void _keepSelectedAndTrashRest(List<GalleryMediaItem> group) {
    final provider = context.read<GalleryProvider>();
    
    final itemsToKeep = <GalleryMediaItem>[];
    final itemsToTrash = <GalleryMediaItem>[];
    
    for (final item in group) {
      if (_selectedToKeepIds.contains(item.id)) {
        itemsToKeep.add(item);
      } else {
        itemsToTrash.add(item);
      }
    }
    
    if (itemsToKeep.isNotEmpty) {
      provider.bulkKeepItems(itemsToKeep);
    }
    if (itemsToTrash.isNotEmpty) {
      provider.bulkAddToStagingBin(itemsToTrash);
    }
    
    setState(() {
      for (final item in group) {
        _selectedToKeepIds.remove(item.id);
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kept ${itemsToKeep.length} photos, Trashed ${itemsToTrash.length}.'),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // Dummy methods to avoid breaking regex parsing downstream if needed
  void _trashSelected() {'''

content = re.sub(target, new_logic, content)

# Now, we need to update the floating action bar and group header
# The floating action bar is no longer needed since actions are per-group!
floating_bar_target = r'''      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _selectedIds.isEmpty
          \? null
          : Container\([\s\S]*?            \),'''

content = re.sub(floating_bar_target, '', content)

# Update group header button
header_target = r'''                TextButton\(
                  onPressed: \(\) \{
                    // Auto-select all but first
                    setState\(\(\) \{
                      for \(int i = 1; i < group.length; i\+\+\) \{
                        _selectedIds.add\(group\[i\]\.id\);
                      \}
                      // Deselect first just in case
                      _selectedIds\.remove\(group\[0\]\.id\);
                    \}\);
                  \},
                  child: const Text\('Keep Best Only', style: TextStyle\(color: Color\(0xFF6C63FF\)\)\),
                \)'''

new_header = r'''                if (_selectedToKeepIds.intersection(group.map((e) => e.id).toSet()).isNotEmpty)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _keepSelectedAndTrashRest(group),
                    child: const Text('Keep Selected & Trash Rest'),
                  )
                else
                  const Text('Select best ones', style: TextStyle(color: Colors.white54, fontSize: 12))'''

content = re.sub(header_target, new_header, content)

# Update item tap logic and styling
grid_item_target = r'''                final item = group\[i\];
                final isSelected = _selectedIds\.contains\(item\.id\);
                return GestureDetector\(
                  onTap: \(\) \{
                    setState\(\(\) \{
                      if \(isSelected\) \{
                        _selectedIds\.remove\(item\.id\);
                      \} else \{
                        _selectedIds\.add\(item\.id\);
                      \}
                    \}\);
                  \},
                  child: Container\(
                    width: 120,
                    margin: const EdgeInsets\.symmetric\(horizontal: 4\),
                    decoration: BoxDecoration\(
                      borderRadius: BorderRadius\.circular\(12\),
                      border: Border\.all\(
                        color: isSelected \? Colors\.red : Colors\.transparent,
                        width: 3,
                      \),
                    \),
                    child: ClipRRect\(
                      borderRadius: BorderRadius\.circular\(9\),
                      child: Stack\(
                        fit: StackFit\.expand,
                        children: \[
                          _SimCachedThumbnail\(item: item\),
                          if \(isSelected\)
                            Container\(color: Colors\.red\.withValues\(alpha: 0\.2\)\),
                          if \(isSelected\)
                            const Center\(
                              child: Icon\(Icons\.delete_rounded, color: Colors\.white, size: 32\),
                            \),'''

new_grid_item = r'''                final item = group[i];
                final isSelected = _selectedToKeepIds.contains(item.id);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedToKeepIds.remove(item.id);
                      } else {
                        _selectedToKeepIds.add(item.id);
                      }
                    });
                  },
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.green : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _SimCachedThumbnail(item: item),
                          if (isSelected)
                            Container(color: Colors.green.withValues(alpha: 0.2)),
                          if (isSelected)
                            const Center(
                              child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 32),
                            ),'''

content = re.sub(grid_item_target, new_grid_item, content)

with open(r'lib/screens/similar_photos_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated similar photos workflow to Keep Selected and Trash Rest")
