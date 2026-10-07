import 'dart:typed_data';
import 'package:flutter/material.dart';
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
  final Set<String> _selectedIds = {};

  void _trashSelected() {
    if (_selectedIds.isEmpty) return;
    final provider = context.read<GalleryProvider>();
    final itemsToTrash = provider.allItems
        .where((i) => _selectedIds.contains(i.id))
        .toList();
    
    provider.bulkAddToStagingBin(itemsToTrash);
    setState(() {
      _selectedIds.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${itemsToTrash.length} items moved to Staging Bin'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _keepSelected() {
    if (_selectedIds.isEmpty) return;
    final provider = context.read<GalleryProvider>();
    final itemsToKeep = provider.allItems
        .where((i) => _selectedIds.contains(i.id))
        .toList();
    
    provider.bulkKeepItems(itemsToKeep);
    setState(() {
      _selectedIds.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${itemsToKeep.length} items kept'),
        backgroundColor: Colors.green,
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              itemCount: liveGroups.length,
              itemBuilder: (ctx, index) {
                final group = liveGroups[index];
                return _buildSimilarGroup(group);
              },
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _selectedIds.isEmpty
          ? null
          : Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_selectedIds.length} Selected',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: _trashSelected,
                    child: const Text('Trash', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: _keepSelected,
                    child: const Text('Keep', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
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
                TextButton(
                  onPressed: () {
                    // Auto-select all but first
                    setState(() {
                      for (int i = 1; i < group.length; i++) {
                        _selectedIds.add(group[i].id);
                      }
                      // Deselect first just in case
                      _selectedIds.remove(group[0].id);
                    });
                  },
                  child: const Text('Keep Best Only', style: TextStyle(color: Color(0xFF6C63FF))),
                )
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
                final isSelected = _selectedIds.contains(item.id);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedIds.remove(item.id);
                      } else {
                        _selectedIds.add(item.id);
                      }
                    });
                  },
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.red : Colors.transparent,
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
                            Container(color: Colors.red.withValues(alpha: 0.2)),
                          if (isSelected)
                            const Center(
                              child: Icon(Icons.delete_rounded, color: Colors.white, size: 32),
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
