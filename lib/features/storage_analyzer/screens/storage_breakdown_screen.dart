import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sponge_gallery_cleaner/features/gallery_core/providers/gallery_provider.dart';
import 'package:sponge_gallery_cleaner/features/media_cleaners/swipe_screen.dart';
import 'package:sponge_gallery_cleaner/features/staging_bin/staging_bin_screen.dart';
import 'package:sponge_gallery_cleaner/features/storage_analyzer/models/storage_file_item.dart';
import 'package:sponge_gallery_cleaner/features/storage_analyzer/services/storage_scanner_service.dart';
import 'package:sponge_gallery_cleaner/features/storage_analyzer/screens/category_file_list_screen.dart';

class StorageBreakdownScreen extends StatefulWidget {
  const StorageBreakdownScreen({super.key});

  @override
  State<StorageBreakdownScreen> createState() => _StorageBreakdownScreenState();
}

class _StorageBreakdownScreenState extends State<StorageBreakdownScreen> {
  bool _isScanningFiles = false;
  StorageScannerResult? _scanResult;
  bool _hasDeepPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndScan();
  }

  Future<void> _checkPermissionAndScan() async {
    setState(() => _isScanningFiles = true);
    final hasPerm = await StorageScannerService.hasAllFilesPermission();
    final result = await StorageScannerService.scanStorage();
    if (mounted) {
      setState(() {
        _hasDeepPermission = hasPerm;
        _scanResult = result;
        _isScanningFiles = false;
      });
    }
  }

  Future<void> _requestDeepPermission() async {
    final granted = await StorageScannerService.requestAllFilesPermission();
    if (mounted) {
      setState(() => _hasDeepPermission = granted);
      _checkPermissionAndScan();
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
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

    final totalDiskMB = provider.totalDiskSpaceMB ?? 0.0;
    final freeDiskMB = provider.freeDiskSpaceMB ?? 0.0;
    final usedDiskMB = totalDiskMB > 0 ? totalDiskMB - freeDiskMB : 0.0;
    final totalUsedBytes = (usedDiskMB * 1024 * 1024).toInt();
    final totalCapacityBytes = (totalDiskMB * 1024 * 1024).toInt();
    final freeBytes = (freeDiskMB * 1024 * 1024).toInt();

    // Calculate Media Sizes from allItems
    int videosBytes = 0;
    int videosCount = 0;
    int photosBytes = 0;
    int photosCount = 0;

    for (final item in provider.allItems) {
      if (item.decision == null) {
        final size = item.fileSize > 0 ? item.fileSize : (item.isVideo ? 35 * 1024 * 1024 : 3 * 1024 * 1024);
        if (item.isVideo) {
          videosBytes += size;
          videosCount++;
        } else {
          photosBytes += size;
          photosCount++;
        }
      }
    }

    final screenshotsGroupItems = provider.screenshotsGroup?.items.where((i) => i.decision == null).toList() ?? [];
    final screenshotsCount = provider.screenshotsCount;
    final screenshotsBytes = screenshotsGroupItems.fold(
      0,
      (sum, i) => sum + (i.fileSize > 0 ? i.fileSize : (i.isVideo ? 35 * 1024 * 1024 : 3 * 1024 * 1024)),
    );

    final whatsappGroupItems = provider.whatsappGroup?.items.where((i) => i.decision == null).toList() ?? [];
    final whatsappCount = provider.whatsappJunkCount;
    final whatsappBytes = whatsappGroupItems.fold(
      0,
      (sum, i) => sum + (i.fileSize > 0 ? i.fileSize : (i.isVideo ? 35 * 1024 * 1024 : 3 * 1024 * 1024)),
    );

    final trashBytes = provider.stagingBin.fold(
      0,
      (s, i) => s + (i.fileSize > 0 ? i.fileSize : (i.isVideo ? 35 * 1024 * 1024 : 3 * 1024 * 1024)),
    );
    final trashCount = provider.stagingBin.length;

    // Scanned non-media files
    final docBytes = _scanResult?.totalDocumentsBytes ?? 0;
    final docCount = _scanResult?.documents.length ?? 0;
    final apkBytes = _scanResult?.totalApksBytes ?? 0;
    final apkCount = _scanResult?.apks.length ?? 0;
    final audioBytes = _scanResult?.totalAudioBytes ?? 0;
    final audioCount = _scanResult?.audioFiles.length ?? 0;

    final mediaTotalBytes = videosBytes + photosBytes + docBytes + apkBytes + audioBytes + trashBytes;
    final otherSystemBytes = (totalUsedBytes - mediaTotalBytes).clamp(0, totalUsedBytes);

    // Build categories for the Circles
    final categories = <StorageCategorySummary>[
      StorageCategorySummary(
        type: StorageCategoryType.videos,
        title: 'Videos',
        icon: Icons.videocam_rounded,
        color: const Color(0xFF8B5CF6), // Purple
        totalBytes: videosBytes,
        itemCount: videosCount,
      ),
      StorageCategorySummary(
        type: StorageCategoryType.photos,
        title: 'Photos',
        icon: Icons.photo_rounded,
        color: const Color(0xFF38BDF8), // Cyan
        totalBytes: photosBytes,
        itemCount: photosCount,
      ),
      StorageCategorySummary(
        type: StorageCategoryType.documents,
        title: 'Documents',
        icon: Icons.description_rounded,
        color: const Color(0xFFF59E0B), // Amber
        totalBytes: docBytes,
        itemCount: docCount,
        items: _scanResult?.documents ?? [],
      ),
      StorageCategorySummary(
        type: StorageCategoryType.apks,
        title: 'APKs & Apps',
        icon: Icons.android_rounded,
        color: const Color(0xFF10B981), // Emerald
        totalBytes: apkBytes,
        itemCount: apkCount,
        items: _scanResult?.apks ?? [],
      ),
      StorageCategorySummary(
        type: StorageCategoryType.audio,
        title: 'Audio & Music',
        icon: Icons.music_note_rounded,
        color: const Color(0xFFEC4899), // Pink
        totalBytes: audioBytes,
        itemCount: audioCount,
        items: _scanResult?.audioFiles ?? [],
      ),
      StorageCategorySummary(
        type: StorageCategoryType.whatsapp,
        title: 'WhatsApp',
        icon: Icons.chat_rounded,
        color: const Color(0xFF14B8A6), // Teal
        totalBytes: whatsappBytes,
        itemCount: whatsappCount,
      ),
      StorageCategorySummary(
        type: StorageCategoryType.screenshots,
        title: 'Screenshots',
        icon: Icons.screenshot_rounded,
        color: const Color(0xFF6366F1), // Indigo
        totalBytes: screenshotsBytes,
        itemCount: screenshotsCount,
      ),
      StorageCategorySummary(
        type: StorageCategoryType.trash,
        title: 'Trash Bin',
        icon: Icons.delete_rounded,
        color: const Color(0xFFEF4444), // Red
        totalBytes: trashBytes,
        itemCount: trashCount,
      ),
      StorageCategorySummary(
        type: StorageCategoryType.systemOther,
        title: 'System/Other',
        icon: Icons.pie_chart_outline_rounded,
        color: const Color(0xFF64748B), // Slate
        totalBytes: otherSystemBytes,
        itemCount: 0,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: const Color(0xFF13151A),
        elevation: 0,
        title: const Text(
          'Storage Breakdown',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: _isScanningFiles
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Color(0xFF7C3AED),
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _isScanningFiles ? null : _checkPermissionAndScan,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF7C3AED),
        backgroundColor: const Color(0xFF16181F),
        onRefresh: () async {
          await provider.fetchDiskSpace();
          await _checkPermissionAndScan();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            // Hero Card: Overall Storage Ring
            _buildHeroStorageCard(
              totalCapacityBytes: totalCapacityBytes,
              totalUsedBytes: totalUsedBytes,
              freeBytes: freeBytes,
              usedPercent: totalCapacityBytes > 0
                  ? (totalUsedBytes / totalCapacityBytes)
                  : 0.0,
            ),
            const SizedBox(height: 20),

            // Deep scan permission banner if not granted
            if (!_hasDeepPermission && Platform.isAndroid)
              _buildPermissionBanner(),

            const SizedBox(height: 16),
            const Text(
              'Categories Overview',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap any circle card to inspect or clean files',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // The Grid of Circles requested by user
            _buildCirclesGrid(context, categories, totalUsedBytes, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStorageCard({
    required int totalCapacityBytes,
    required int totalUsedBytes,
    required int freeBytes,
    required double usedPercent,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16181F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // Big Circular Chart
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: usedPercent.clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFF222530),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                  strokeWidth: 10,
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(usedPercent * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'Used',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Internal Storage',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatBytes(totalUsedBytes),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_formatBytes(freeBytes)} Free of ${_formatBytes(totalCapacityBytes)}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.security_update_good_rounded,
                color: Color(0xFFA78BFA), size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deep Cleaner Access',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Grant All Files permission to scan all hidden APKs and documents across device storage.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: _requestDeepPermission,
            child: const Text('Enable', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCirclesGrid(
    BuildContext context,
    List<StorageCategorySummary> categories,
    int totalUsedBytes,
    GalleryProvider provider,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final cat = categories[index];
        final percent = cat.percentageOf(totalUsedBytes);

        return _buildCircularCard(
          context: context,
          category: cat,
          percent: percent,
          onTap: () => _handleCategoryTap(context, cat, provider),
        );
      },
    );
  }

  Widget _buildCircularCard({
    required BuildContext context,
    required StorageCategorySummary category,
    required double percent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF16181F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: category.color.withValues(alpha: 0.2),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular Progress Indicator around Icon
            SizedBox(
              width: 58,
              height: 58,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: percent > 0.0 ? percent.clamp(0.02, 1.0) : 0.0,
                    backgroundColor: category.color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(category.color),
                    strokeWidth: 4.5,
                  ),
                  Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(category.icon, color: category.color, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Category Name
            Text(
              category.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Formatted MB / GB
            Text(
              category.formattedSize,
              style: TextStyle(
                color: category.color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            // Item count or percent
            Text(
              category.itemCount > 0 ? '${category.itemCount} files' : '${(percent * 100).toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white38, fontSize: 10),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  void _handleCategoryTap(
    BuildContext context,
    StorageCategorySummary cat,
    GalleryProvider provider,
  ) {
    switch (cat.type) {
      case StorageCategoryType.documents:
      case StorageCategoryType.apks:
      case StorageCategoryType.audio:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryFileListScreen(
              category: cat,
              onDataChanged: _checkPermissionAndScan,
            ),
          ),
        );
        break;
      case StorageCategoryType.trash:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StagingBinScreen()),
        );
        break;
      case StorageCategoryType.whatsapp:
        if (provider.whatsappGroup != null && provider.whatsappGroup!.totalItems > 0) {
          provider.whatsappGroup!.recalculateCurrentIndex();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SwipeScreen(group: provider.whatsappGroup!),
            ),
          );
        } else {
          _showEmptySnack(cat.title);
        }
        break;
      case StorageCategoryType.screenshots:
        if (provider.screenshotsGroup != null && provider.screenshotsGroup!.totalItems > 0) {
          provider.screenshotsGroup!.recalculateCurrentIndex();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SwipeScreen(group: provider.screenshotsGroup!),
            ),
          );
        } else {
          _showEmptySnack(cat.title);
        }
        break;
      case StorageCategoryType.videos:
      case StorageCategoryType.photos:
      case StorageCategoryType.systemOther:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16181F),
            content: Text(
              '${cat.title}: ${cat.formattedSize} (${cat.itemCount > 0 ? "${cat.itemCount} items" : "Allocated Space"})',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
        break;
    }
  }

  void _showEmptySnack(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF16181F),
        content: Text(
          'No $title to clean right now.',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
