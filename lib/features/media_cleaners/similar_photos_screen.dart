import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sponge_gallery_cleaner/features/gallery_core/models/gallery_media_item.dart';
import 'package:sponge_gallery_cleaner/features/gallery_core/providers/gallery_provider.dart';
import 'package:sponge_gallery_cleaner/core/widgets/universal_preview_dialog.dart';

class SimilarPhotosScreen extends StatefulWidget {
  const SimilarPhotosScreen({super.key});

  @override
  State<SimilarPhotosScreen> createState() => _SimilarPhotosScreenState();
}

class _SimilarPhotosScreenState extends State<SimilarPhotosScreen> {
  // Holds the IDs of photos the user wants to KEEP globally
  final Set<String> _selectedToKeepIds = {};

  void _keepSelectedAndTrashRest(List<List<GalleryMediaItem>> liveGroups) {
    final provider = context.read<GalleryProvider>();

    final itemsToKeep = <GalleryMediaItem>[];
    final itemsToTrash = <GalleryMediaItem>[];

    for (final group in liveGroups) {
      // Check if this group has any selections
      bool hasSelection = group.any((item) => _selectedToKeepIds.contains(item.id));
      if (!hasSelection) continue; // Skip groups with no selections

      for (final item in group) {
        if (_selectedToKeepIds.contains(item.id)) {
          itemsToKeep.add(item);
        } else {
          itemsToTrash.add(item);
        }
      }
    }

    if (itemsToKeep.isNotEmpty) {
      provider.bulkKeepItems(itemsToKeep);
    }
    if (itemsToTrash.isNotEmpty) {
      provider.bulkAddToStagingBin(itemsToTrash);
    }

    setState(() {
      _selectedToKeepIds.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Kept ${itemsToKeep.length} photos, Trashed ${itemsToTrash.length}.'),
        backgroundColor: const Color(0xFF7C3AED),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GalleryProvider>();

    final liveGroups = provider.similarPhotoGroups
        .map((group) => group.where((i) => i.decision == null).toList())
        .where((group) => group.length > 1)
        .toList();

    int totalPhotos = liveGroups.fold(0, (sum, g) => sum + g.length);

    // Calculate freed space (unselected photos in groups that have >= 1 selection)
    int bytesToFree = 0;
    for (final group in liveGroups) {
      if (group.any((i) => _selectedToKeepIds.contains(i.id))) {
        for (final item in group) {
          if (!_selectedToKeepIds.contains(item.id)) {
            bytesToFree += item.fileSize;
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text('Similar photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            Text('${liveGroups.length} groups • $totalPhotos photos', style: const TextStyle(fontSize: 12, color: Colors.white54)),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          liveGroups.isEmpty
              ? const Center(
                  child: Text(
                    'No similar photos found!',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, _selectedToKeepIds.isNotEmpty ? 120 : 40),
                  itemCount: liveGroups.length,
                  itemBuilder: (ctx, index) {
                    final group = liveGroups[index];
                    return _buildSimilarGroup(group);
                  },
                ),
          if (_selectedToKeepIds.isNotEmpty)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: _buildBottomBar(liveGroups, bytesToFree),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(List<List<GalleryMediaItem>> liveGroups, int bytesToFree) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16181F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.photo_library_rounded, color: Color(0xFF7C3AED), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    children: [
                      TextSpan(
                        text: '${_selectedToKeepIds.length} photo${_selectedToKeepIds.length > 1 ? 's' : ''} ',
                        style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: 'selected to keep'),
                    ],
                  ),
                ),
                Text(
                  "You'll free up ${_formatBytes(bytesToFree)}",
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Review later', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: _selectedToKeepIds.isEmpty
                ? null
                : () => _keepSelectedAndTrashRest(liveGroups),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Keep selected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarGroup(List<GalleryMediaItem> group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF16181F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.burst_mode_rounded, color: Color(0xFF7C3AED), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${group.length} similar photos',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Choose the best shot',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${group.length} photos  >',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: group.length,
              itemBuilder: (ctx, i) {
                final item = group[i];
                final isSelected = _selectedToKeepIds.contains(item.id);
                return GestureDetector(
                  onLongPress: () {
                    HapticFeedback.heavyImpact();
                    showDialog(
                      context: context,
                      barrierColor: Colors.black.withOpacity(0.9),
                      builder: (_) => UniversalPreviewDialog(items: group, initialIndex: i),
                    );
                  },
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
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF7C3AED) : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: _SimCachedThumbnail(item: item),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF7C3AED),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                      ],
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
