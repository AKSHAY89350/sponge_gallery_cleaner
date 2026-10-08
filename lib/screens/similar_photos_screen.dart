import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/gallery_media_item.dart';
import '../providers/gallery_provider.dart';

class SimilarPhotosScreen extends StatefulWidget {
  const SimilarPhotosScreen({super.key});

  @override
  State<SimilarPhotosScreen> createState() => _SimilarPhotosScreenState();
}

class _SimilarPhotosScreenState extends State<SimilarPhotosScreen> {
  // Holds the IDs of photos the user wants to KEEP
  final Set<String> _selectedToKeepIds = {};

  void _keepSelectedAndTrashRest(List<GalleryMediaItem> group) {
    final provider = context.read<GalleryProvider>();
    
    final itemsToKeep = <GalleryMediaItem>[];
    final itemsToTrash = <GalleryMediaItem>[];
    
    for (final item in group) {
      if (_selectedToKeepIds.contains(item.id)) {
        itemsToKeep.add(item);
      } else {
        itemsToTrash.add(item);
      }
    }
    
    if (itemsToKeep.isNotEmpty) {
      provider.bulkKeepItems(itemsToKeep);
    }
    if (itemsToTrash.isNotEmpty) {
      provider.bulkAddToStagingBin(itemsToTrash);
    }
    
    setState(() {
      for (final item in group) {
        _selectedToKeepIds.remove(item.id);
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kept ${itemsToKeep.length} photos, Trashed ${itemsToTrash.length}.'),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GalleryProvider>();
    
    // Filter out items that already have a decision
    final liveGroups = provider.similarPhotoGroups.map((group) {
      return group.where((i) => i.decision == null).toList();
    }).where((group) => group.length > 1).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Similar & Burst', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: liveGroups.isEmpty
          ? const Center(
              child: Text(
                'No similar photos found!',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              itemCount: liveGroups.length,
              itemBuilder: (ctx, index) {
                final group = liveGroups[index];
                return _buildSimilarGroup(group);
              },
            ),
    );
  }

  Widget _buildSimilarGroup(List<GalleryMediaItem> group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${group.length} Similar Photos',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (_selectedToKeepIds.intersection(group.map((e) => e.id).toSet()).isNotEmpty)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _keepSelectedAndTrashRest(group),
                    child: const Text('Keep', style: TextStyle(fontSize: 12)),
                  )
                else
                  const Text('Select best ones', style: TextStyle(color: Colors.white54, fontSize: 12))
              ],
            ),
          ),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: group.length,
              itemBuilder: (ctx, i) {
                final item = group[i];
                final isSelected = _selectedToKeepIds.contains(item.id);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedToKeepIds.remove(item.id);
                      } else {
                        _selectedToKeepIds.add(item.id);
                      }
                    });
                  },
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.green : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _SimCachedThumbnail(item: item),
                          if (isSelected)
                            Container(color: Colors.green.withValues(alpha: 0.2)),
                          if (isSelected)
                            const Center(
                              child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 32),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SimCachedThumbnail extends StatefulWidget {
  final GalleryMediaItem item;
  const _SimCachedThumbnail({required this.item});

  @override
  State<_SimCachedThumbnail> createState() => _SimCachedThumbnailState();
}

class _SimCachedThumbnailState extends State<_SimCachedThumbnail> {
  Future<Uint8List?>? _future;

  @override
  void initState() {
    super.initState();
    _loadFuture();
  }

  @override
  void didUpdateWidget(covariant _SimCachedThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _loadFuture();
    }
  }

  void _loadFuture() {
    _future = AssetEntity.fromId(widget.item.id).then(
      (entity) => entity?.thumbnailDataWithSize(
        const ThumbnailSize.square(300),
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



class _PreviewDialog extends StatefulWidget {
  final GalleryMediaItem item;
  const _PreviewDialog({required this.item});

  @override
  State<_PreviewDialog> createState() => _PreviewDialogState();
}

class _PreviewDialogState extends State<_PreviewDialog> {
  Future<Uint8List?>? _future;

  @override
  void initState() {
    super.initState();
    _future = AssetEntity.fromId(widget.item.id).then((e) => e?.thumbnailDataWithSize(const ThumbnailSize.square(1024)));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
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




