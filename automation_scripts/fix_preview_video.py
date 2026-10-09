import re

path = 'lib/core/widgets/universal_preview_dialog.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Make sure to import VideoCardPlayer
if "video_card_player.dart" not in content:
    content = content.replace("import 'package:sponge_gallery_cleaner/features/gallery_core/providers/gallery_provider.dart';", "import 'package:sponge_gallery_cleaner/features/gallery_core/providers/gallery_provider.dart';\nimport 'package:sponge_gallery_cleaner/core/widgets/video_card_player.dart';")

target_preview_page = """class _PreviewPageState extends State<_PreviewPage> {
  Future<Uint8List?>? _future;
  @override
  void initState() {
    super.initState();
    _future = AssetEntity.fromId(widget.item.id).then(
        (e) => e?.thumbnailDataWithSize(const ThumbnailSize.square(1024)));
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
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
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
}"""

replacement_preview_page = """class _PreviewPageState extends State<_PreviewPage> {
  Future<Uint8List?>? _future;
  @override
  void initState() {
    super.initState();
    _future = AssetEntity.fromId(widget.item.id).then(
        (e) => e?.thumbnailDataWithSize(const ThumbnailSize.square(1024)));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.item.type != AssetType.video) {
           Navigator.pop(context);
        }
      },
      child: InteractiveViewer(
        minScale: 1.0,
        maxScale: 4.0,
        child: FutureBuilder<Uint8List?>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }
            if (snap.hasData && snap.data != null) {
              final thumb = Image.memory(snap.data!, fit: BoxFit.contain);
              if (widget.item.type == AssetType.video) {
                return VideoCardPlayer(
                  item: widget.item,
                  thumbnailWidget: thumb,
                );
              }
              return thumb;
            }
            return const Center(child: Icon(Icons.error, color: Colors.white));
          },
        ),
      ),
    );
  }
}"""

if target_preview_page in content:
    content = content.replace(target_preview_page, replacement_preview_page)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Updated UniversalPreviewDialog with VideoCardPlayer.")
else:
    print("Target not found.")
