import re

with open(r'lib/screens/blurry_photos_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace _buildResultsList
build_results_pattern = re.compile(r'Widget _buildResultsList.*?return GridView\.builder\([^;]+;\s*\}\s*\}', re.DOTALL)
new_build_results = """Widget _buildResultsList(List<GalleryMediaItem> items, MonthGroup? group) {
    if (items.isEmpty) return const SizedBox.shrink();
    
    return GridView.builder(
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
    );
  }
}"""
content = build_results_pattern.sub(new_build_results, content)

# Replace _BlurryGridThumbnail classes completely
thumbnail_classes_pattern = re.compile(r'class _BlurryGridThumbnail extends StatefulWidget .*', re.DOTALL)
new_thumbnail_classes = """class _BlurryGridThumbnail extends StatefulWidget {
  final GalleryMediaItem item;
  final List<GalleryMediaItem> allItems;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  const _BlurryGridThumbnail({super.key, required this.item, required this.allItems, required this.index, required this.isSelected, required this.onTap});

  @override
  State<_BlurryGridThumbnail> createState() => _BlurryGridThumbnailState();
}

class _BlurryGridThumbnailState extends State<_BlurryGridThumbnail> {
  Future<Uint8List?>? _thumbFuture;

  @override
  void initState() {
    super.initState();
    _loadThumb();
  }

  void _loadThumb() async {
    final asset = await AssetEntity.fromId(widget.item.id);
    if (asset != null && mounted) {
      setState(() {
        _thumbFuture = asset.thumbnailDataWithSize(const ThumbnailSize.square(256));
      });
    }
  }

  @override
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
  }
}

class _PreviewDialog extends StatefulWidget {
  final List<GalleryMediaItem> items;
  final int initialIndex;
  const _PreviewDialog({required this.items, required this.initialIndex});

  @override
  State<_PreviewDialog> createState() => _PreviewDialogState();
}

class _PreviewDialogState extends State<_PreviewDialog> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            itemBuilder: (ctx, index) {
              return _PreviewPage(item: widget.items[index]);
            },
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPage extends StatefulWidget {
  final GalleryMediaItem item;
  const _PreviewPage({required this.item});
  @override
  State<_PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<_PreviewPage> {
  Future<Uint8List?>? _future;
  @override
  void initState() {
    super.initState();
    _future = AssetEntity.fromId(widget.item.id).then((e) => e?.thumbnailDataWithSize(const ThumbnailSize.square(1024)));
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: InteractiveViewer(
        minScale: 1.0,
        maxScale: 4.0,
        child: FutureBuilder<Uint8List?>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            if (snap.hasData && snap.data != null) {
              return Image.memory(snap.data!, fit: BoxFit.contain);
            }
            return const Center(child: Icon(Icons.error, color: Colors.white));
          },
        ),
      ),
    );
  }
}
"""

content = thumbnail_classes_pattern.sub(new_thumbnail_classes, content)

# Also fix the FAB logic so it shows up if _selectedIds.isNotEmpty REGARDLESS of isScanning
fab_pattern = re.compile(r'floatingActionButton: blurryItems\.isNotEmpty && !isScanning.*?:\s*null,', re.DOTALL)
new_fab = """floatingActionButton: _selectedIds.isNotEmpty 
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
          : (blurryItems.isNotEmpty && !isScanning
              ? FloatingActionButton.extended(
                  onPressed: () {
                    group!.recalculateCurrentIndex();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => SwipeScreen(group: group)));
                  },
                  backgroundColor: Colors.orangeAccent,
                  icon: const Icon(Icons.cleaning_services_rounded, color: Colors.black),
                  label: const Text('Review Blurry Photos', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                )
              : null),"""

content = fab_pattern.sub(new_fab, content)

with open(r'lib/screens/blurry_photos_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated blurry photos screen fully via python")
