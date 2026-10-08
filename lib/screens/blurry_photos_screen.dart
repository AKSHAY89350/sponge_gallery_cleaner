import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/gallery_media_item.dart';
import '../providers/gallery_provider.dart';
import 'swipe_screen.dart';

class BlurryPhotosScreen extends StatefulWidget {
  const BlurryPhotosScreen({super.key});

  @override
  State<BlurryPhotosScreen> createState() => _BlurryPhotosScreenState();
}

class _BlurryPhotosScreenState extends State<BlurryPhotosScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<GalleryProvider>().scanMoreBlurry();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GalleryProvider>();
    final isScanning = provider.isBlurryScanning;
    final total = provider.blurryTotalCount;
    final scanned = provider.blurryScannedCount;
    final group = provider.blurryGroup;
    
    final blurryItems = group?.items.where((i) => i.decision == null).toList() ?? [];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Blurry Photos', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (isScanning) _buildScanningIndicator(scanned, total),
          Expanded(
            child: blurryItems.isEmpty && !isScanning
                ? _buildEmptyState()
                : _buildResultsList(blurryItems, group),
          ),
        ],
      ),
      floatingActionButton: blurryItems.isNotEmpty && !isScanning
          ? FloatingActionButton.extended(
              onPressed: () {
                group!.recalculateCurrentIndex();
                Navigator.push(context, MaterialPageRoute(builder: (_) => SwipeScreen(group: group)));
              },
              backgroundColor: Colors.orangeAccent,
              icon: const Icon(Icons.cleaning_services_rounded, color: Colors.black),
              label: const Text('Review Blurry Photos', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildScanningIndicator(int scanned, int total) {
    final percent = total == 0 ? 0.0 : scanned / total;
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Text('Analyzing Sharpness (AI)...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.white10,
            color: Colors.orangeAccent,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Text('\ / \ photos processed', style: const TextStyle(color: Colors.white54, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lens_blur_rounded, color: Colors.orangeAccent, size: 72),
          ),
          const SizedBox(height: 24),
          const Text('Crystal Clear!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('We couldn''t find any blurry\nor out-of-focus photos.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 15, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildResultsList(List<GalleryMediaItem> items, MonthGroup? group) {
    if (items.isEmpty) return const SizedBox.shrink();
    
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FutureBuilder<AssetEntity?>(
                future: AssetEntity.fromId(item.id),
                builder: (ctx, snap) {
                  if (snap.hasData && snap.data != null) {
                    return FutureBuilder<Uint8List?>(
                      future: snap.data!.thumbnailDataWithSize(const ThumbnailSize.square(256)),
                      builder: (ctx, imgSnap) {
                        if (imgSnap.hasData && imgSnap.data != null) {
                          return Image.memory(imgSnap.data!, fit: BoxFit.cover, gaplessPlayback: true);
                        }
                        return Container(color: const Color(0xFF252525));
                      }
                    );
                  }
                  return Container(color: const Color(0xFF252525));
                },
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                  child: const Text('Blurry', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

