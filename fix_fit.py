import re

with open(r'lib/screens/swipe_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update _CachedMediaThumbnail constructor
thumb_class_pattern = r'''class _CachedMediaThumbnail extends StatefulWidget \{
  final GalleryMediaItem item;
  final int size;
  final int quality;
  final Color placeholderColor;

  const _CachedMediaThumbnail\(\{
    super\.key,
    required this\.item,
    this\.size = 800,
    this\.quality = 85,
    this\.placeholderColor = const Color\(0xFF252525\),
  \}\);'''

thumb_class_replacement = r'''class _CachedMediaThumbnail extends StatefulWidget {
  final GalleryMediaItem item;
  final int size;
  final int quality;
  final Color placeholderColor;
  final BoxFit fit;

  const _CachedMediaThumbnail({
    super.key,
    required this.item,
    this.size = 800,
    this.quality = 85,
    this.placeholderColor = const Color(0xFF252525),
    this.fit = BoxFit.cover,
  });'''

content = re.sub(thumb_class_pattern, thumb_class_replacement, content)

# 2. Update Image.memory fit
img_mem_pattern = r'''          return Image\.memory\(
            snap\.data!,
            fit: BoxFit\.cover,
            gaplessPlayback: true,
          \);'''
          
img_mem_replacement = r'''          return Image.memory(
            snap.data!,
            fit: widget.fit,
            gaplessPlayback: true,
          );'''
          
content = re.sub(img_mem_pattern, img_mem_replacement, content)

# 3. Update the main card area to use BoxFit.contain
video_card_pattern = r'''          if \(item\.isVideo && isTopCard\)
            VideoCardPlayer\(
              key: ValueKey\('video_\$\{item\.id\}'\),
              item: item,
              thumbnailWidget: _CachedMediaThumbnail\(item: item\),
            \)
          else
            _CachedMediaThumbnail\(item: item\),'''

video_card_replacement = r'''          if (item.isVideo && isTopCard)
            VideoCardPlayer(
              key: ValueKey('video_${item.id}'),
              item: item,
              thumbnailWidget: _CachedMediaThumbnail(item: item, fit: BoxFit.contain),
            )
          else
            _CachedMediaThumbnail(item: item, fit: BoxFit.contain),'''

content = re.sub(video_card_pattern, video_card_replacement, content)

with open(r'lib/screens/swipe_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated image fit to contain")
