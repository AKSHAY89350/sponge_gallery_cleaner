import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:sponge_gallery_cleaner/features/gallery_core/models/gallery_media_item.dart';
import 'package:sponge_gallery_cleaner/features/gallery_core/providers/gallery_provider.dart';
import 'package:sponge_gallery_cleaner/core/widgets/modern_notification_banner.dart';
import 'package:sponge_gallery_cleaner/core/widgets/universal_preview_dialog.dart';

class BlurryPhotosScreen extends StatefulWidget {
  const BlurryPhotosScreen({super.key});

  @override
  State<BlurryPhotosScreen> createState() => _BlurryPhotosScreenState();
}

class _BlurryPhotosScreenState extends State<BlurryPhotosScreen> {
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GalleryProvider>();
      if (provider.hasUnscannedBlurry && !provider.isBlurryScanning) {
        provider.scanMoreBlurry();
      }
    });
  }

  void _bulkTrash(BuildContext context, GalleryProvider provider) {
    if (_selectedIds.isEmpty) return;
    HapticFeedback.mediumImpact();

    final itemsToTrash = provider.blurryGroup?.items
            .where((i) => _selectedIds.contains(i.id))
            .toList() ??
        [];
    provider.bulkAddToStagingBin(itemsToTrash);

    ModernNotificationBanner.show(
      context,
      message: 'Moved ${itemsToTrash.length} blurry photos to trash',
      subtitle: 'Review them in Staging Bin anytime',
      type: ModernBannerType.trash,
    );

    setState(() {
      _selectedIds.clear();
      provider.blurryGroup?.recalculateCurrentIndex();
    });
  }

  void _bulkKeep(BuildContext context, GalleryProvider provider) {
    if (_selectedIds.isEmpty) return;
    HapticFeedback.lightImpact();

    final itemsToKeep = provider.blurryGroup?.items
            .where((i) => _selectedIds.contains(i.id))
            .toList() ??
        [];
    provider.bulkKeepItems(itemsToKeep);

    ModernNotificationBanner.show(
      context,
      message: 'Kept ${itemsToKeep.length} photos in gallery',
      type: ModernBannerType.success,
    );

    setState(() {
      _selectedIds.clear();
      provider.blurryGroup?.recalculateCurrentIndex();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GalleryProvider>();
    final items = provider.blurryGroup?.items.where((i) => i.decision == null).toList() ?? [];

    final isAllSelected = items.isNotEmpty && _selectedIds.length == items.length;

    // Calculate selected size
    final selectedItems = items.where((i) => _selectedIds.contains(i.id)).toList();
    final selectedSize = selectedItems.fold(0, (sum, i) => sum + i.fileSize);
    final sizeFormatted = _formatSize(selectedSize);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Blurry Photos',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          if (items.isNotEmpty)
            Row(
              children: [
                const Text('Select All',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(width: 4),
                Switch(
                  value: isAllSelected,
                  activeThumbColor: const Color(0xFF10B981),
                  onChanged: (val) {
                    setState(() {
                      if (val) {
                        _selectedIds.addAll(items.map((i) => i.id));
                      } else {
                        _selectedIds.clear();
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
              ],
            )
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildScanningIndicator(
                  provider.blurryAnalyzedCount, provider.blurryTotalTarget, provider.isBlurryScanning),
              
              if (items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    '${items.length} blurry photos identified',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),

              Expanded(
                child: items.isEmpty
                    ? _buildEmptyState(!provider.hasUnscannedBlurry)
                    : _buildResultsList(items),
              ),
            ],
          ),

          // Sticky Bottom Bar
          if (_selectedIds.isNotEmpty)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1E26),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _bulkKeep(context, provider),
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                        label: const Text('Keep Selected', style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                          foregroundColor: const Color(0xFF10B981),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _bulkTrash(context, provider),
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        label: Text('Trash ($sizeFormatted)', style: const TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanningIndicator(int scanned, int total, bool isScanning) {
    final percent = total == 0 ? 0.0 : scanned / total;
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('AI Analysis Progress',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              Text('${(percent * 100).toInt()}%',
                  style: const TextStyle(
                      color: Color(0xFF2DD4BF),
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.white10,
            color: const Color(0xFF2DD4BF),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Text(isScanning ? 'AI Scanning... $scanned / $total photos analyzed' : 'Scan Complete. $scanned / $total photos analyzed',
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isAllCaughtUp) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isAllCaughtUp
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : Colors.orangeAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
                isAllCaughtUp
                    ? Icons.check_circle_outline_rounded
                    : Icons.lens_blur_rounded,
                color: isAllCaughtUp
                    ? const Color(0xFF10B981)
                    : Colors.orangeAccent,
                size: 72),
          ),
          const SizedBox(height: 24),
          Text(isAllCaughtUp ? 'All Caught Up!' : 'Crystal Clear!',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
              isAllCaughtUp
                  ? 'You have resolved all blurry photos.'
                  : "We couldn't find any blurry\nor out-of-focus photos.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 15, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildResultsList(List<GalleryMediaItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        final isSelected = _selectedIds.contains(item.id);
        return _BlurryGridThumbnail(
          item: item,
          allItems: items,
          index: i,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedIds.remove(item.id);
              } else {
                _selectedIds.add(item.id);
              }
            });
          },
        );
      },
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _BlurryGridThumbnail extends StatefulWidget {
  final GalleryMediaItem item;
  final List<GalleryMediaItem> allItems;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  const _BlurryGridThumbnail(
      {required this.item,
      required this.allItems,
      required this.index,
      required this.isSelected,
      required this.onTap});

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

  @override
  void didUpdateWidget(covariant _BlurryGridThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _loadThumb();
    }
  }

  void _loadThumb() {
    _thumbFuture = AssetEntity.fromId(widget.item.id).then(
      (entity) => entity?.thumbnailDataWithSize(const ThumbnailSize.square(256))
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.heavyImpact();
        showDialog(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.9),
          builder: (_) => UniversalPreviewDialog(
              items: widget.allItems, initialIndex: widget.index),
        );
      },
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isSelected
                ? const Color(0xFF10B981)
                : Colors.transparent,
            width: 3,
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FutureBuilder<Uint8List?>(
              future: _thumbFuture,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Container(color: const Color(0xFF1C1E26));
                }
                if (snap.hasData && snap.data != null) {
                  return Image.memory(snap.data!,
                      fit: BoxFit.cover, gaplessPlayback: true);
                }
                return Container(color: const Color(0xFF1C1E26));
              },
            ),
            
            // Top Right Checkbox
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isSelected ? Colors.white : Colors.black.withValues(alpha: 0.3),
                ),
                child: Icon(
                  widget.isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: widget.isSelected ? const Color(0xFF10B981) : Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
