import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:sponge_gallery_cleaner/core/widgets/modern_notification_banner.dart';
import 'package:sponge_gallery_cleaner/features/gallery_core/providers/gallery_provider.dart';
import 'package:sponge_gallery_cleaner/features/gallery_core/models/gallery_media_item.dart';

class StagingBinScreen extends StatefulWidget {
  const StagingBinScreen({super.key});

  @override
  State<StagingBinScreen> createState() => _StagingBinScreenState();
}

class _StagingBinScreenState extends State<StagingBinScreen> {
  bool _isDeleting = false;

  Future<void> _confirmAndDelete(BuildContext context, GalleryProvider provider) async {
    final count = provider.stagingBin.length;
    if (count == 0) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1E26),
        title: const Text('Permanently Delete?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to permanently delete $count item${count > 1 ? "s" : ""} from your device? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      final deletedCount = await provider.permanentlyDeleteStaged();
      if (!mounted) return;
      setState(() => _isDeleting = false);
      if (deletedCount > 0) {
        navigator.pop();
        ModernNotificationBanner.show(
          null,
          messenger: messenger,
          message: '$deletedCount item${deletedCount > 1 ? "s" : ""} deleted permanently',
          subtitle: 'Storage space reclaimed from device',
          type: ModernBannerType.success,
        );
      } else {
        ModernNotificationBanner.show(
          null,
          messenger: messenger,
          message: 'Deletion cancelled by system',
          type: ModernBannerType.warning,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ModernNotificationBanner.show(
        null,
        messenger: messenger,
        message: 'Failed to delete some items. They might be locked.',
        type: ModernBannerType.error,
      );
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GalleryProvider>();
    final items = provider.stagingBin;

    if (items.isEmpty) {
      return _buildEmptyState(context);
    }

    final totalSize = items.fold(0, (sum, item) => sum + item.fileSize);
    final sizeFormatted = _formatSize(totalSize);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Trash Bin',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _isDeleting ? null : () => _confirmAndDelete(context, provider),
            child: const Text('Empty All',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              // Warning Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1E26),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Items here will be permanently deleted from your device.',
                        style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.warning_amber_rounded, color: Colors.white.withValues(alpha: 0.5), size: 24),
                  ],
                ),
              ),
              
              // Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _TrashBinThumbnail(item: items[index]);
                  },
                ),
              ),
            ],
          ),

          // Floating Bottom Bar
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: _isDeleting ? null : () => _confirmAndDelete(context, provider),
                  child: _isDeleting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Permanently Delete ($sizeFormatted)',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Colors.white54, size: 72),
            ),
            const SizedBox(height: 24),
            const Text(
              'Trash is Empty',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'No items waiting to be deleted.',
              style: TextStyle(color: Colors.white54, fontSize: 15),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _TrashBinThumbnail extends StatefulWidget {
  final GalleryMediaItem item;
  const _TrashBinThumbnail({required this.item});

  @override
  State<_TrashBinThumbnail> createState() => _TrashBinThumbnailState();
}

class _TrashBinThumbnailState extends State<_TrashBinThumbnail> {
  Future<Uint8List?>? _thumbFuture;

  @override
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF1C1E26),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<Uint8List?>(
            future: _thumbFuture,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              if (snap.hasData && snap.data != null) {
                return Image.memory(snap.data!, fit: BoxFit.cover, gaplessPlayback: true);
              }
              return const SizedBox.shrink();
            },
          ),
          
          // Red Tint Overlay
          Container(color: Colors.red.withValues(alpha: 0.15)),
          
          // Top Right Restore Button
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.read<GalleryProvider>().removeFromStagingBin(widget.item);
                ModernNotificationBanner.show(
                  context,
                  message: 'Photo restored to gallery',
                  type: ModernBannerType.restore,
                  duration: const Duration(seconds: 1),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.replay_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          
          // Video indicator
          if (widget.item.isVideo)
            Positioned(
              bottom: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow_rounded, color: Colors.white, size: 12),
                    SizedBox(width: 2),
                    Text('Video', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
