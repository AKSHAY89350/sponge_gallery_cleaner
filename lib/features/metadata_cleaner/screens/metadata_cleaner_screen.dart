import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:sponge_gallery_cleaner/core/widgets/modern_notification_banner.dart';
import 'package:sponge_gallery_cleaner/features/gallery_core/models/gallery_media_item.dart';
import 'package:sponge_gallery_cleaner/features/gallery_core/providers/gallery_provider.dart';
import 'package:sponge_gallery_cleaner/features/metadata_cleaner/services/metadata_stripper_service.dart';

enum MediaTypeFilter { image, video }

class MetadataCleanerScreen extends StatefulWidget {
  const MetadataCleanerScreen({super.key});

  @override
  State<MetadataCleanerScreen> createState() => _MetadataCleanerScreenState();
}

class _MetadataCleanerScreenState extends State<MetadataCleanerScreen> {
  MediaTypeFilter _activeFilter = MediaTypeFilter.image;
  bool _isBatchMode = true;
  bool _replaceOriginal = false;
  bool _isProcessing = false;
  double _progress = 0.0;
  int _processedCount = 0;
  int _totalToProcess = 0;
  String _statusText = '';

  final Set<String> _selectedItemIds = {};

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GalleryProvider>();
    final allPhotos = provider.allItems.where((i) => !i.isVideo).toList();
    final allVideos = provider.allItems.where((i) => i.isVideo).toList();
    final currentList = _activeFilter == MediaTypeFilter.image ? allPhotos : allVideos;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0E12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0E12),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Metadata Cleaner',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white70),
            tooltip: 'About Metadata Stripping',
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  _buildHeaderDescription(),
                  const SizedBox(height: 20),
                  _buildTypeSelector(allPhotos.length, allVideos.length),
                  const SizedBox(height: 20),
                  _buildSettingsCard(currentList.length),
                  const SizedBox(height: 20),
                  if (!_isBatchMode) ...[
                    _buildSelectionHeader(currentList),
                    const SizedBox(height: 12),
                    _buildMediaGrid(currentList),
                  ],
                ],
              ),
            ),
            _buildBottomActionSection(currentList),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderDescription() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16181F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_rounded, color: Color(0xFF3B82F6), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy & AI Metadata Wipe',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Erase EXIF, IPTC, XMP tags, GPS location, camera serials, and AI generation tool signatures losslessly.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(int photoCount, int videoCount) {
    return Row(
      children: [
        Expanded(
          child: _buildTypeCard(
            filter: MediaTypeFilter.image,
            title: 'Image',
            count: photoCount,
            icon: Icons.camera_alt_rounded,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildTypeCard(
            filter: MediaTypeFilter.video,
            title: 'Video',
            count: videoCount,
            icon: Icons.movie_filter_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required MediaTypeFilter filter,
    required String title,
    required int count,
    required IconData icon,
  }) {
    final isSelected = _activeFilter == filter;
    const activeColor = Color(0xFF3B82F6);

    return GestureDetector(
      onTap: () {
        if (_isProcessing) return;
        HapticFeedback.lightImpact();
        setState(() {
          _activeFilter = filter;
          _selectedItemIds.clear();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.15) : const Color(0xFF16181F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : Colors.white60,
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count items',
              style: TextStyle(
                color: isSelected ? activeColor : Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(int totalAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16181F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.folder_copy_rounded, color: Colors.white70, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Batch Mode',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _isBatchMode,
                activeThumbColor: const Color(0xFF3B82F6),
                onChanged: _isProcessing
                    ? null
                    : (val) {
                        setState(() {
                          _isBatchMode = val;
                          if (!val && _selectedItemIds.isEmpty) {
                            // Default to first few selected
                          }
                        });
                      },
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.delete_sweep_rounded, color: Colors.white70, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Replace Original',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _replaceOriginal,
                activeThumbColor: Colors.redAccent,
                onChanged: _isProcessing
                    ? null
                    : (val) {
                        setState(() => _replaceOriginal = val);
                      },
              ),
            ],
          ),
          if (!_replaceOriginal)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: Color(0xFF10B981), size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Saves clean copy as "clean_..." in gallery.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionHeader(List<GalleryMediaItem> items) {
    final allSelected = items.isNotEmpty && _selectedItemIds.length == items.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Select Items (${_selectedItemIds.length}/${items.length})',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              if (allSelected) {
                _selectedItemIds.clear();
              } else {
                _selectedItemIds.addAll(items.map((i) => i.id));
              }
            });
          },
          child: Text(
            allSelected ? 'Deselect All' : 'Select All',
            style: const TextStyle(
              color: Color(0xFF3B82F6),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaGrid(List<GalleryMediaItem> items) {
    if (items.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: const Text('No media items found',
            style: TextStyle(color: Colors.white38)),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length > 60 ? 60 : items.length, // Display preview batch
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = _selectedItemIds.contains(item.id);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedItemIds.remove(item.id);
              } else {
                _selectedItemIds.add(item.id);
              }
            });
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FutureBuilder<Uint8List?>(
                  future: AssetEntity.fromId(item.id).then(
                    (e) => e?.thumbnailDataWithSize(const ThumbnailSize.square(150)),
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      );
                    }
                    return Container(color: const Color(0xFF1C1E26));
                  },
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.35)
                      : Colors.transparent,
                  border: isSelected
                      ? Border.all(color: const Color(0xFF3B82F6), width: 2.5)
                      : null,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? const Color(0xFF3B82F6) : Colors.black45,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomActionSection(List<GalleryMediaItem> currentList) {
    final count = _isBatchMode ? currentList.length : _selectedItemIds.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF16181F),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isProcessing) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _statusText.isEmpty
                      ? 'Stripping metadata...'
                      : _statusText,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$_processedCount / $_totalToProcess',
                  style: const TextStyle(
                    color: Color(0xFF3B82F6),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 6,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              ),
            ),
            const SizedBox(height: 14),
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _isProcessing || count == 0
                  ? null
                  : () => _startCleaning(currentList),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_fix_high_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _isProcessing
                        ? 'Cleaning in progress...'
                        : 'Strip Metadata ($count ${count == 1 ? "item" : "items"})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
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

  Future<void> _startCleaning(List<GalleryMediaItem> items) async {
    final targets = _isBatchMode
        ? items
        : items.where((i) => _selectedItemIds.contains(i.id)).toList();

    if (targets.isEmpty) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _processedCount = 0;
      _totalToProcess = targets.length;
      _statusText = 'Starting metadata wipe...';
    });

    int successCount = 0;
    int totalBytesSaved = 0;

    for (int i = 0; i < targets.length; i++) {
      final item = targets[i];
      final entity = await AssetEntity.fromId(item.id);

      if (entity != null) {
        final result = await MetadataStripperService.cleanAsset(
          asset: entity,
          replaceOriginal: _replaceOriginal,
        );

        if (result.success) {
          successCount++;
          totalBytesSaved += result.bytesSaved;
        }
      }

      if (mounted) {
        setState(() {
          _processedCount = i + 1;
          _progress = (i + 1) / targets.length;
          _statusText = 'Stripping metadata (${i + 1}/${targets.length})...';
        });
      }
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _progress = 1.0;
        _statusText = 'Complete!';
        _selectedItemIds.clear();
      });

      // Reload gallery to show updated clean items
      context.read<GalleryProvider>().loadGallery();

      final String sizeStr = totalBytesSaved > 0
          ? ' • ${(totalBytesSaved / 1024).toStringAsFixed(1)} KB removed'
          : '';
      ModernNotificationBanner.show(
        context,
        message: 'Stripped metadata from $successCount items$sizeStr',
        subtitle: _replaceOriginal
            ? 'Originals replaced with sanitized copies'
            : 'Clean copies saved to your gallery',
        type: ModernBannerType.success,
      );
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16181F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.privacy_tip_rounded, color: Color(0xFF3B82F6), size: 22),
            SizedBox(width: 8),
            Text('Metadata Stripping', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What gets removed:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              '• EXIF tags (camera model, lens, exposure)\n'
              '• GPS location coordinates\n'
              '• IPTC & XMP author & copyright fields\n'
              '• AI-generation tool prompts & metadata\n'
              '• Video container udta & user tags',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              'Zero Image Quality Loss: Image pixels are never re-compressed.',
              style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it', style: TextStyle(color: Color(0xFF3B82F6))),
          ),
        ],
      ),
    );
  }
}
