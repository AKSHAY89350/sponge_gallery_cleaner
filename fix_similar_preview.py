import re

with open(r'lib/screens/similar_photos_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update the caller
call_pattern = re.compile(r'builder: \(_\) => _PreviewDialog\(item: items\[i\]\),')
content = call_pattern.sub(r'builder: (_) => _PreviewDialog(items: items, initialIndex: i),', content)

# 2. Replace the _PreviewDialog classes completely
preview_pattern = re.compile(r'class _PreviewDialog extends StatefulWidget .*', re.DOTALL)

new_preview = """class _PreviewDialog extends StatefulWidget {
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

content = preview_pattern.sub(new_preview, content)

with open(r'lib/screens/similar_photos_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated SimilarPhotosScreen preview dialog via Python regex")
