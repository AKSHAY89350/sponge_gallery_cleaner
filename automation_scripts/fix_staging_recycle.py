import re

path = 'lib/features/staging_bin/staging_bin_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = """  @override
  void initState() {
    super.initState();
    _thumbFuture = AssetEntity.fromId(widget.item.id).then(
      (entity) => entity?.thumbnailDataWithSize(const ThumbnailSize.square(256))
    );
  }"""

replacement = """  @override
  void initState() {
    super.initState();
    _loadThumb();
  }

  @override
  void didUpdateWidget(covariant _TrashBinThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _loadThumb();
    }
  }

  void _loadThumb() {
    _thumbFuture = AssetEntity.fromId(widget.item.id).then(
      (entity) => entity?.thumbnailDataWithSize(const ThumbnailSize.square(256))
    );
  }"""

content = content.replace(target, replacement)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Added didUpdateWidget to staging bin")
