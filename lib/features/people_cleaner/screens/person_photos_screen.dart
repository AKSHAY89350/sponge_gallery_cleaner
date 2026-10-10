import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sponge_gallery_cleaner/core/widgets/universal_preview_dialog.dart';
import 'package:sponge_gallery_cleaner/features/gallery_core/models/gallery_media_item.dart';
import 'package:sponge_gallery_cleaner/features/media_cleaners/swipe_screen.dart';
import 'package:sponge_gallery_cleaner/features/people_cleaner/models/person_cluster.dart';
import 'package:sponge_gallery_cleaner/features/people_cleaner/services/face_detection_service.dart';

class PersonPhotosScreen extends StatefulWidget {
  final PersonCluster person;
  final VoidCallback onUpdated;

  const PersonPhotosScreen({
    super.key,
    required this.person,
    required this.onUpdated,
  });

  @override
  State<PersonPhotosScreen> createState() => _PersonPhotosScreenState();
}

class _PersonPhotosScreenState extends State<PersonPhotosScreen> {
  void _renamePerson() {
    final controller = TextEditingController(text: widget.person.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16181F),
        title: const Text('Rename Person', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter name (e.g. Mom, Alex)',
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF7C3AED)),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                setState(() => widget.person.name = newName);
                FaceDetectionService.saveClusters();
                widget.onUpdated();
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _openSwipeClean() {
    final liveItems = widget.person.items.where((i) => i.decision == null).toList();
    if (liveItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All photos for this person have already been reviewed!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      return;
    }

    final swipeGroup = MonthGroup(
      label: widget.person.name,
      yearMonthKey: 'person_${widget.person.id}',
      items: liveItems,
    )..recalculateCurrentIndex();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SwipeScreen(group: swipeGroup)),
    ).then((_) {
      if (mounted) {
        setState(() {});
        if (widget.person.pendingPhotoCount == 0) {
          Navigator.pop(context);
        }
      }
      widget.onUpdated();
    });
  }

  void _showMergeDialog() {
    final otherPeople = FaceDetectionService.clusters
        .where((c) => c.id != widget.person.id && c.id != 'group_photos')
        .toList();

    if (otherPeople.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No other people found to merge with.'),
          backgroundColor: Color(0xFF16181F),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16181F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Merge "${widget.person.name}" with...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Text(
                    'Select person to combine photos into:',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: otherPeople.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (c, idx) {
                      final target = otherPeople[idx];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                          backgroundImage: target.avatarBytes != null
                              ? MemoryImage(target.avatarBytes!)
                              : null,
                          child: target.avatarBytes == null
                              ? const Icon(Icons.face_rounded, color: Color(0xFF7C3AED), size: 20)
                              : null,
                        ),
                        title: Text(
                          target.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${target.photoCount} photos',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.call_merge_rounded, color: Color(0xFF7C3AED)),
                        onTap: () async {
                          Navigator.pop(ctx);
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (alertCtx) => AlertDialog(
                              backgroundColor: const Color(0xFF16181F),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Text('Confirm Merge', style: TextStyle(color: Colors.white)),
                              content: Text(
                                'Merge all photos from "${widget.person.name}" into "${target.name}"?',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(alertCtx, false),
                                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7C3AED),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(alertCtx, true),
                                  child: const Text('Merge'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true && mounted) {
                            await FaceDetectionService.mergeClusters(target, widget.person);
                            widget.onUpdated();
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Merged photos into "${target.name}"'),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = widget.person.pendingPhotoCount;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.person.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (widget.person.id != 'group_photos')
            IconButton(
              icon: const Icon(Icons.merge_type_rounded, color: Colors.white70),
              tooltip: 'Merge with another person',
              onPressed: _showMergeDialog,
            ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white70),
            tooltip: 'Rename Person',
            onPressed: _renamePerson,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Profile Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16181F),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: widget.person.avatarBytes != null
                      ? Image.memory(
                          widget.person.avatarBytes!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 64,
                          height: 64,
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                          child: const Icon(Icons.face_rounded, color: Color(0xFF7C3AED), size: 36),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.person.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.person.photoCount} total photos • $pendingCount to review',
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onPressed: _openSwipeClean,
                  icon: const Icon(Icons.swipe_rounded, size: 16),
                  label: const Text('Swipe Clean', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ),

          // Photo Grid
          Expanded(
            child: widget.person.items.isEmpty
                ? const Center(
                    child: Text('No photos found for this person', style: TextStyle(color: Colors.white54)),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: widget.person.items.length,
                    itemBuilder: (ctx, index) {
                      final item = widget.person.items[index];
                      final isTrashed = item.decision == SwipeAction.trash;
                      final isKept = item.decision == SwipeAction.keep;

                      return GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => UniversalPreviewDialog(
                              items: widget.person.items,
                              initialIndex: index,
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _GridPhotoThumbnail(item: item),
                              if (isTrashed || isKept)
                                Container(
                                  color: Colors.black54,
                                  child: Center(
                                    child: Icon(
                                      isKept ? Icons.check_circle_rounded : Icons.delete_rounded,
                                      color: isKept ? const Color(0xFF10B981) : Colors.red,
                                      size: 28,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _GridPhotoThumbnail extends StatelessWidget {
  final GalleryMediaItem item;
  const _GridPhotoThumbnail({required this.item});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AssetEntity.fromId(item.id).then((entity) =>
          entity?.thumbnailDataWithSize(const ThumbnailSize.square(300), quality: 80)),
      builder: (ctx, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(snapshot.data!, fit: BoxFit.cover, gaplessPlayback: true);
        }
        return Container(color: const Color(0xFF1C1E26));
      },
    );
  }
}
