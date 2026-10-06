import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import '../providers/gallery_provider.dart';
import '../models/gallery_media_item.dart';

class StagingBinScreen extends StatefulWidget {
  const StagingBinScreen({super.key});

  @override
  State<StagingBinScreen> createState() => _StagingBinScreenState();
}

class _StagingBinScreenState extends State<StagingBinScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GalleryProvider>();
    final items = provider.stagingBin;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'Trash Bin 🗑️',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            Text(
              '${items.length} items staged',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: items.isEmpty ? _buildEmpty() : _buildContent(context, provider, items),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🗑️', style: TextStyle(fontSize: 64)),
          SizedBox(height: 20),
          Text('Trash is empty',
              style: TextStyle(color: Colors.white54, fontSize: 20, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text(
            'Swipe left on photos to add them here',
            style: TextStyle(color: Colors.white30, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    GalleryProvider provider,
    List<GalleryMediaItem> items,
  ) {
    return Column(
      children: [
        // Warning banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: Colors.orange, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tap any photo to restore it. Press Delete to permanently remove all ${items.length} items.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Photo grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _ThumbnailTile(item: items[index]);
            },
          ),
        ),
        // Delete CTA
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            children: [
              // Size freed info
              Text(
                'Frees ${provider.totalFreedFormatted} of storage',
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _isDeleting
                      ? null
                      : () => _confirmAndDelete(context, provider),
                  child: _isDeleting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          'Permanently Delete ${items.length} Items',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAndDelete(
      BuildContext context, GalleryProvider provider) async {
    // Capture context-dependent objects BEFORE any await
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '⚠️ Permanently Delete?',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              'This will permanently delete ${provider.stagingBin.length} items and free ${provider.totalFreedFormatted}. This action cannot be undone.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      final deletedCount = await provider.permanentlyDeleteStaged();
      if (mounted) {
        setState(() => _isDeleting = false);
        if (deletedCount > 0) {
          navigator.pop();
          messenger.showSnackBar(
            SnackBar(
              content: Text('✅ $deletedCount item${deletedCount > 1 ? "s" : ""} deleted permanently!'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('⚠️ Deletion cancelled or denied by system.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}

// ── Thumbnail Grid Tile ───────────────────────────────────────────────────────

class _ThumbnailTile extends StatelessWidget {
  final GalleryMediaItem item;
  const _ThumbnailTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Tap to restore from staging bin
        context.read<GalleryProvider>().removeFromStagingBin(item);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo restored ↩️'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail
          FutureBuilder<Uint8List?>(
            future: AssetEntity.fromId(item.id).then(
              (entity) => entity?.thumbnailDataWithSize(
                const ThumbnailSize.square(200),
                quality: 80,
              ),
            ),
            builder: (ctx, snap) {
              if (snap.hasData && snap.data != null) {
                return Image.memory(snap.data!, fit: BoxFit.cover);
              }
              return Container(color: const Color(0xFF252525));
            },
          ),
          // Red delete overlay
          Container(color: Colors.red.withValues(alpha: 0.25)),
          // Restore icon
          const Center(
            child: Icon(Icons.restore_from_trash_rounded,
                color: Colors.white70, size: 22),
          ),
          // Video badge
          if (item.isVideo)
            const Positioned(
              bottom: 4,
              left: 4,
              child: Icon(Icons.play_circle_filled_rounded,
                  color: Colors.white, size: 18),
            ),
        ],
      ),
    );
  }
}
