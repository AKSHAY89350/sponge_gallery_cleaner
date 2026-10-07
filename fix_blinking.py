import re

with open(r'lib/screens/staging_bin_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace _ThumbnailTile FutureBuilder logic
old_thumbnail = r'''          // Thumbnail
          FutureBuilder<Uint8List\?>\(
            future: AssetEntity\.fromId\(item\.id\)\.then\(
              \(entity\) => entity\?\.thumbnailDataWithSize\(
                const ThumbnailSize\.square\(200\),
                quality: 80,
              \),
            \),
            builder: \(ctx, snap\) \{
              if \(snap\.hasData && snap\.data != null\) \{
                return Image\.memory\(snap\.data!, fit: BoxFit\.cover\);
              \}
              return Container\(color: const Color\(0xFF252525\)\);
            \},
          \),'''

new_thumbnail = r'''          // Thumbnail
          _StagingCachedThumbnail(item: item),'''

content = re.sub(old_thumbnail, new_thumbnail, content)

# Add the StatefulWidget class at the end
cached_thumbnail_class = r'''
class _StagingCachedThumbnail extends StatefulWidget {
  final GalleryMediaItem item;
  const _StagingCachedThumbnail({required this.item});

  @override
  State<_StagingCachedThumbnail> createState() => _StagingCachedThumbnailState();
}

class _StagingCachedThumbnailState extends State<_StagingCachedThumbnail> {
  Future<Uint8List?>? _future;

  @override
  void initState() {
    super.initState();
    _loadFuture();
  }

  @override
  void didUpdateWidget(covariant _StagingCachedThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _loadFuture();
    }
  }

  void _loadFuture() {
    _future = AssetEntity.fromId(widget.item.id).then(
      (entity) => entity?.thumbnailDataWithSize(
        const ThumbnailSize.square(200),
        quality: 80,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
           return Container(color: const Color(0xFF252525));
        }
        if (snap.hasData && snap.data != null) {
          return Image.memory(snap.data!, fit: BoxFit.cover, gaplessPlayback: true);
        }
        return Container(color: const Color(0xFF252525));
      },
    );
  }
}
'''

content += cached_thumbnail_class

with open(r'lib/screens/staging_bin_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed flickering in staging bin")
