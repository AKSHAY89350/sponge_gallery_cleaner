import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/gallery_media_item.dart';
import '../providers/gallery_provider.dart';
import '../utils/blur_detector.dart';
import 'swipe_screen.dart';

class BlurryPhotosScreen extends StatefulWidget {
  const BlurryPhotosScreen({super.key});

  @override
  State<BlurryPhotosScreen> createState() => _BlurryPhotosScreenState();
}

class _BlurryPhotosScreenState extends State<BlurryPhotosScreen> {
  bool _isScanning = false;
  int _scannedCount = 0;
  int _totalCount = 0;
  
  List<GalleryMediaItem> _blurryItems = [];
  MonthGroup? _blurryGroup;

  @override
  void initState() {
    super.initState();
    // Delay slightly to let animation finish before heavy scan
    Future.delayed(const Duration(milliseconds: 300), _startScan);
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _scannedCount = 0;
      _blurryItems = [];
    });

    final provider = context.read<GalleryProvider>();
    final itemsToScan = provider.allItems.where((i) => !i.isVideo && i.decision == null).toList();
    _totalCount = itemsToScan.length;

    // Scan in batches to not freeze the UI too much, even though it's in an isolate
    // Isolate overhead is high if we spawn 1000s of them. But `compute` handles an isolate pool.
    
    // We will scan max 500 items to save time in testing, or we can scan all.
    // Let's cap at 1000 for safety so user doesn't wait forever.
    final limit = _totalCount > 1000 ? 1000 : _totalCount;

    for (int i = 0; i < limit; i++) {
      if (!mounted) return; // User closed screen

      final item = itemsToScan[i];
      
      try {
        final entity = await AssetEntity.fromId(item.id);
        if (entity != null) {
          final bytes = await entity.thumbnailDataWithSize(const ThumbnailSize.square(256), quality: 70);
          if (bytes != null) {
            final isBlurry = await BlurDetector.isImageBlurry(bytes);
            if (isBlurry && mounted) {
              _blurryItems.add(item);
            }
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _scannedCount = i + 1;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isScanning = false;
        if (_blurryItems.isNotEmpty) {
          _blurryGroup = MonthGroup(
            label: 'Blurry Photos',
            yearMonthKey: 'blurry',
            items: _blurryItems,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Blurry Photo Detector', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: _isScanning
          ? _buildScanningView()
          : _buildResultView(),
    );
  }

  Widget _buildScanningView() {
    final percent = _totalCount == 0 ? 0.0 : (_scannedCount / (_totalCount > 1000 ? 1000 : _totalCount));
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 8,
                  backgroundColor: Colors.white10,
                  color: Colors.orangeAccent,
                ),
              ),
              const Icon(Icons.blur_on_rounded, size: 50, color: Colors.orangeAccent),
            ],
          ),
          const SizedBox(height: 32),
          const Text('Analyzing sharpness...', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('$_scannedCount / ${(_totalCount > 1000 ? 1000 : _totalCount)} photos scanned', style: const TextStyle(color: Colors.white54, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    if (_blurryItems.isEmpty) {
      return const Center(
        child: Text(
          'No blurry photos found! 🎉',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

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
            child: const Icon(Icons.warning_rounded, size: 80, color: Colors.orangeAccent),
          ),
          const SizedBox(height: 24),
          Text('${_blurryItems.length} Blurry Photos Found', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Review and delete them to save space.', style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => SwipeScreen(group: _blurryGroup!),
                ),
              );
            },
            child: const Text('Review Blurry Photos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}
