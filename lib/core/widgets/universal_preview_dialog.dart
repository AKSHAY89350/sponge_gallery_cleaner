import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sponge_gallery_cleaner/features/gallery_core/models/gallery_media_item.dart';
import 'package:sponge_gallery_cleaner/features/gallery_core/providers/gallery_provider.dart';

class UniversalPreviewDialog extends StatefulWidget {
  final List<GalleryMediaItem> items;
  final int initialIndex;
  const UniversalPreviewDialog(
      {super.key, required this.items, required this.initialIndex});

  @override
  State<UniversalPreviewDialog> createState() => _UniversalPreviewDialogState();
}

class _UniversalPreviewDialogState extends State<UniversalPreviewDialog> {
  late PageController _pageController;
  late List<GalleryMediaItem> _localItems;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _localItems = List.from(widget.items);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleAction(bool isKeep) {
    if (_localItems.isEmpty) return;

    final item = _localItems[_currentIndex];
    final provider = context.read<GalleryProvider>();

    if (isKeep) {
      provider.keepItem(item);
    } else {
      provider.addToStagingBin(item);
    }

    setState(() {
      _localItems.removeAt(_currentIndex);
      if (_localItems.isEmpty) {
        Navigator.pop(context);
      } else {
        if (_currentIndex >= _localItems.length) {
          _currentIndex = _localItems.length - 1;
        }
        // Since the item count changed, we might need to jump the controller if it's out of bounds
        // but PageView handles structural changes automatically based on index.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_localItems.isEmpty) return const SizedBox.shrink();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _localItems.length,
            onPageChanged: (idx) {
              setState(() {
                _currentIndex = idx;
              });
            },
            itemBuilder: (ctx, index) {
              return _PreviewPage(
                key: ValueKey(_localItems[index].id),
                item: _localItems[index],
              );
            },
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20)),
              child: Text(
                '${_currentIndex + 1} / ${_localItems.length}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'keep_btn_preview',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _handleAction(true);
                  },
                  backgroundColor: Colors.green,
                  icon: const Icon(Icons.favorite_rounded, color: Colors.white),
                  label: const Text('Keep',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                FloatingActionButton.extended(
                  heroTag: 'trash_btn_preview',
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    _handleAction(false);
                  },
                  backgroundColor: Colors.redAccent,
                  icon: const Icon(Icons.delete_rounded, color: Colors.white),
                  label: const Text('Trash',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPage extends StatefulWidget {
  final GalleryMediaItem item;
  const _PreviewPage({super.key, required this.item});
  @override
  State<_PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<_PreviewPage> {
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
}
