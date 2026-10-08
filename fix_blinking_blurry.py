import re

with open(r'lib/screens/blurry_photos_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = r'''      itemBuilder: (ctx, i) {
        final item = items[i];
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FutureBuilder<AssetEntity?>(
                future: AssetEntity.fromId(item.id),
                builder: (ctx, snap) {
                  if (snap.hasData && snap.data != null) {
                    return FutureBuilder<Uint8List?>(
                      future: snap.data!.thumbnailDataWithSize(const ThumbnailSize.square(256)),
                      builder: (ctx, imgSnap) {
                        if (imgSnap.hasData && imgSnap.data != null) {
                          return Image.memory(imgSnap.data!, fit: BoxFit.cover, gaplessPlayback: true);
                        }
                        return Container(color: const Color(0xFF252525));
                      }
                    );
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
      },'''

new_code = r'''      itemBuilder: (ctx, i) {
        final item = items[i];
        return _BlurryGridThumbnail(item: item);
      },'''

content = content.replace(target, new_code)

widget_code = r'''
class _BlurryGridThumbnail extends StatefulWidget {
  final GalleryMediaItem item;
  const _BlurryGridThumbnail({required this.item});

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
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_thumbFuture == null)
            Container(color: const Color(0xFF252525))
          else
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
  }
}
'''

content = content + widget_code

with open(r'lib/screens/blurry_photos_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated BlurryPhotosScreen")
