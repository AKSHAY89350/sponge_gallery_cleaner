import re

with open(r'lib/screens/swipe_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Remove _buildThumbnail method
content = re.sub(
    r'  Widget _buildThumbnail\(GalleryMediaItem item\) \{[\s\S]*?    \);\n  \}', 
    '', 
    content
)

# 2. Replace usages in _buildPhotoCard
content = content.replace(
    '_buildThumbnail(item)', 
    '_CachedMediaThumbnail(item: item)'
)

# 3. Replace FutureBuilder in _PreviewThumbnailSlot
preview_builder_pattern = r'''              FutureBuilder<Uint8List?>(
                future: AssetEntity.fromId(item.id).then(
                  (entity) => entity?.thumbnailDataWithSize(
                    const ThumbnailSize.square(140),
                    quality: 75,
                  ),
                ),
                builder: (ctx, snap) {
                  if (snap.hasData && snap.data != null) {
                    return Image.memory(
                      snap.data!,
                      fit: BoxFit.cover,
                    );
                  }
                  return Container(color: const Color(0xFF222222));
                },
              ),'''
              
cached_replacement = '''              _CachedMediaThumbnail(
                item: item,
                size: 140,
                quality: 75,
                placeholderColor: const Color(0xFF222222),
              ),'''

content = content.replace(preview_builder_pattern, cached_replacement)

# 4. Append _CachedMediaThumbnail class
cached_widget_code = """

class _CachedMediaThumbnail extends StatefulWidget {
  final GalleryMediaItem item;
  final int size;
  final int quality;
  final Color placeholderColor;

  const _CachedMediaThumbnail({
    super.key,
    required this.item,
    this.size = 800,
    this.quality = 85,
    this.placeholderColor = const Color(0xFF252525),
  });

  @override
  State<_CachedMediaThumbnail> createState() => _CachedMediaThumbnailState();
}

class _CachedMediaThumbnailState extends State<_CachedMediaThumbnail> {
  Future<Uint8List?>? _future;

  @override
  void initState() {
    super.initState();
    _loadFuture();
  }

  @override
  void didUpdateWidget(covariant _CachedMediaThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _loadFuture();
    }
  }

  void _loadFuture() {
    _future = AssetEntity.fromId(widget.item.id).then(
      (entity) => entity?.thumbnailDataWithSize(
        ThumbnailSize.square(widget.size),
        quality: widget.quality,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.hasData && snap.data != null) {
          return Image.memory(
            snap.data!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          );
        }
        return Container(
          color: widget.placeholderColor,
          child: widget.size > 200
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF6C63FF), strokeWidth: 2),
                )
              : null,
        );
      },
    );
  }
}
"""

content += cached_widget_code

with open(r'lib/screens/swipe_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
