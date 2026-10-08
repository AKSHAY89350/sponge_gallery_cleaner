import sys

with open(r'lib/screens/blurry_photos_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add _selectedIds to _BlurryPhotosScreenState
target = """class _BlurryPhotosScreenState extends State<BlurryPhotosScreen> {"""
replacement = """class _BlurryPhotosScreenState extends State<BlurryPhotosScreen> {
  final Set<String> _selectedIds = {};"""
content = content.replace(target, replacement)

# 2. Update FloatingActionButton
target = """      floatingActionButton: blurryItems.isNotEmpty && !isScanning
          ? FloatingActionButton.extended(
              onPressed: () {
                group!.recalculateCurrentIndex();
                Navigator.push(context, MaterialPageRoute(builder: (_) => SwipeScreen(group: group)));
              },
              backgroundColor: Colors.orangeAccent,
              icon: const Icon(Icons.cleaning_services_rounded, color: Colors.black),
              label: const Text('Review Blurry Photos', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          : null,"""

replacement = """      floatingActionButton: blurryItems.isNotEmpty && !isScanning
          ? (_selectedIds.isNotEmpty 
              ? FloatingActionButton.extended(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    final itemsToTrash = blurryItems.where((i) => _selectedIds.contains(i.id)).toList();
                    provider.bulkAddToStagingBin(itemsToTrash);
                    setState(() {
                      _selectedIds.clear();
                    });
                  },
                  backgroundColor: Colors.redAccent,
                  icon: const Icon(Icons.delete_rounded, color: Colors.white),
                  label: Text('Trash Selected (${_selectedIds.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              : FloatingActionButton.extended(
                  onPressed: () {
                    group!.recalculateCurrentIndex();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => SwipeScreen(group: group)));
                  },
                  backgroundColor: Colors.orangeAccent,
                  icon: const Icon(Icons.cleaning_services_rounded, color: Colors.black),
                  label: const Text('Review Blurry Photos', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ))
          : null,"""
content = content.replace(target, replacement)

# 3. Update _buildResultsList to pass selection state
target = """      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final item = items[i];
          return _BlurryGridThumbnail(item: item, allItems: items, index: i);
        },
      );"""

replacement = """      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final item = items[i];
          final isSelected = _selectedIds.contains(item.id);
          return _BlurryGridThumbnail(
            item: item, 
            allItems: items, 
            index: i,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedIds.remove(item.id);
                } else {
                  _selectedIds.add(item.id);
                }
              });
            },
          );
        },
      );"""
content = content.replace(target, replacement)


# 4. Update _BlurryGridThumbnail signature
target = """class _BlurryGridThumbnail extends StatefulWidget {
  final GalleryMediaItem item;
  final List<GalleryMediaItem> allItems;
  final int index;
  const _BlurryGridThumbnail({required this.item, required this.allItems, required this.index});"""

replacement = """class _BlurryGridThumbnail extends StatefulWidget {
  final GalleryMediaItem item;
  final List<GalleryMediaItem> allItems;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  const _BlurryGridThumbnail({required this.item, required this.allItems, required this.index, required this.isSelected, required this.onTap});"""
content = content.replace(target, replacement)

# 5. Update _BlurryGridThumbnail build method to add GestureDetector
target = """  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<Uint8List?>(
            future: _thumbFuture,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Container(color: const Color(0xFF252525));
              }
              if (snap.hasData && snap.data != null) {
                return Image.memory(snap.data!, fit: BoxFit.cover, gaplessPlayback: true);
              }
              return Container(color: const Color(0xFF252525));
            },
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
              child: const Text('Blurry', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }"""

replacement = """  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.heavyImpact();
        showDialog(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.9),
          builder: (_) => _PreviewDialog(items: widget.allItems, initialIndex: widget.index),
        );
      },
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
            width: 3,
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FutureBuilder<Uint8List?>(
              future: _thumbFuture,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Container(color: const Color(0xFF252525));
                }
                if (snap.hasData && snap.data != null) {
                  return Image.memory(snap.data!, fit: BoxFit.cover, gaplessPlayback: true);
                }
                return Container(color: const Color(0xFF252525));
              },
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                child: const Text('Blurry', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
            if (widget.isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF6C63FF), size: 24),
              ),
          ],
        ),
      ),
    );
  }"""
content = content.replace(target, replacement)

with open(r'lib/screens/blurry_photos_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated blurry selection")
