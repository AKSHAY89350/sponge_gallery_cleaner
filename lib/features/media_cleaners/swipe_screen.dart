import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sponge_gallery_cleaner/features/gallery_core/models/gallery_media_item.dart';
import 'package:sponge_gallery_cleaner/features/gallery_core/providers/gallery_provider.dart';
import 'package:sponge_gallery_cleaner/core/widgets/universal_preview_dialog.dart';
import 'package:sponge_gallery_cleaner/core/widgets/video_card_player.dart';
import 'package:sponge_gallery_cleaner/features/staging_bin/staging_bin_screen.dart';
import 'package:intl/intl.dart';

class SwipeScreen extends StatefulWidget {
  final MonthGroup group;
  final bool isEmbedded;
  const SwipeScreen({super.key, required this.group, this.isEmbedded = false});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  int _currentIndex = 0;
  final ScrollController _previewScrollController = ScrollController();

  bool _isGridView = false;
  final Set<String> _selectedIds = {};

  Offset _dragOffset = Offset.zero;
  final List<GalleryMediaItem> _undoStack = [];

  @override
  void dispose() {
    _previewScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Resume from saved progress
    _currentIndex = widget.group.currentIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrent();
    });
  }

  GalleryMediaItem? get _currentItem {
    if (_currentIndex >= widget.group.items.length) return null;
    return widget.group.items[_currentIndex];
  }

  bool get _isDone => _currentIndex >= widget.group.items.length;

  // ── Swipe Actions ────────────────────────────────────────────────────────

  void _trash() {
    if (_currentItem == null) return;
    HapticFeedback.mediumImpact();
    _undoStack.add(_currentItem!);
    context.read<GalleryProvider>().addToStagingBin(_currentItem!);
    _advance();
  }

  void _keep() {
    if (_currentItem == null) return;
    HapticFeedback.lightImpact();
    _undoStack.add(_currentItem!);
    context.read<GalleryProvider>().keepItem(_currentItem!);
    _advance();
  }

  void _advance() {
    setState(() {
      _dragOffset = Offset.zero;
      _currentIndex++;
      // Skip over items that already have a decision
      while (_currentIndex < widget.group.items.length &&
          widget.group.items[_currentIndex].decision != null) {
        _currentIndex++;
      }
      widget.group.currentIndex = _currentIndex;
    });
    _scrollToCurrent();
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    HapticFeedback.selectionClick();
    final last = _undoStack.removeLast();
    context.read<GalleryProvider>().removeFromStagingBin(last);

    setState(() {
      final lastIndex = widget.group.items.indexWhere((i) => i.id == last.id);
      if (lastIndex != -1) {
        _currentIndex = lastIndex;
        widget.group.currentIndex = lastIndex;
      }
    });
    _scrollToCurrent();
  }

  void _scrollToCurrent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_previewScrollController.hasClients) return;
      final targetOffset = _currentIndex * 52.0;
      
      _previewScrollController.animateTo(
        targetOffset.clamp(0.0, _previewScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _jumpToIndex(int targetIndex) {
    if (targetIndex < 0 || targetIndex >= widget.group.items.length) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = targetIndex;
      widget.group.currentIndex = targetIndex;
      _dragOffset = Offset.zero;
    });
    _scrollToCurrent();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              _buildProgressBar(),
              if (!_isDone && !_isGridView) _buildTopPreviewStrip(),
              Expanded(
                  child: _isDone
                      ? _buildDoneView()
                      : (_isGridView ? _buildGridView() : _buildCardArea())),
              if (!_isDone && !_isGridView) ...[
                _buildControls(),
                const SizedBox(height: 24)
              ],
            ],
          ),
          if (!_isDone && _isGridView && _selectedIds.isNotEmpty)
            _buildGridControls(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    final trashCount = context.watch<GalleryProvider>().stagingBin.length;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: widget.isEmbedded ? const SizedBox.shrink() : IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        children: [
          Text(widget.group.label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          Text(
            '${widget.group.trashedCount + widget.group.keptCount} / ${widget.group.totalItems}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(_isGridView
              ? Icons.view_carousel_rounded
              : Icons.grid_view_rounded),
          color: Colors.white70,
          onPressed: () {
            setState(() {
              _isGridView = !_isGridView;
              _selectedIds.clear();
              if (!_isGridView) {
                widget.group.recalculateCurrentIndex();
                _currentIndex = widget.group.currentIndex;
                _scrollToCurrent();
              }
            });
          },
        ),
        if (trashCount > 0)
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const StagingBinScreen())),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.delete_rounded, color: Colors.red, size: 14),
                  const SizedBox(width: 4),
                  Text('$trashCount',
                      style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final progress =
        widget.group.totalItems == 0 ? 0.0 : widget.group.progressPercent;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progress.toDouble(),
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          valueColor: const AlwaysStoppedAnimation(Color(0xFF6C63FF)),
          minHeight: 4,
        ),
      ),
    );
  }

  // ── Top 5-Item Preview Strip ─────────────────────────────────────────────

  Widget _buildTopPreviewStrip() {
    final items = widget.group.items;
    final total = items.length;
    if (total == 0) return const SizedBox.shrink();

    return Container(
      height: 80,
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ListView.builder(
        controller: _previewScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: total,
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width / 2 - 26,
        ),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final item = items[index];
          final isCenter = index == _currentIndex;
          final isPast = index < _currentIndex;

          return Center(
            child: _PreviewThumbnailSlot(
              key: ValueKey('preview_${item.id}_$index'),
              item: item,
              isCenter: isCenter,
              isPast: isPast,
              onTap: () => _jumpToIndex(index),
            ),
          );
        },
      ),
    );
  }

  // ── Card Swipe Area ──────────────────────────────────────────────────────

  Widget _buildCardArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: GestureDetector(
        onPanStart: (_) => setState(() {}),
        onPanUpdate: (d) => setState(() => _dragOffset += d.delta),
        onPanEnd: (d) {
          final vx = d.velocity.pixelsPerSecond.dx;
          if (_dragOffset.dx < -80 || vx < -600) {
            _trash();
          } else if (_dragOffset.dx > 80 || vx > 600) {
            _keep();
          } else {
            setState(() {
              _dragOffset = Offset.zero;
            });
          }
        },
        child: Stack(
          children: [
            // Back-deck cards (scale down for depth effect)
            if (_currentIndex + 2 < widget.group.items.length)
              Positioned.fill(
                child: Transform.scale(
                  scale: 0.88,
                  child:
                      _buildPhotoCard(widget.group.items[_currentIndex + 2], 0),
                ),
              ),
            if (_currentIndex + 1 < widget.group.items.length)
              Positioned.fill(
                child: Transform.scale(
                  scale: 0.94,
                  child:
                      _buildPhotoCard(widget.group.items[_currentIndex + 1], 0),
                ),
              ),
            // Active draggable card
            if (_currentItem != null)
              Positioned.fill(
                child: Transform(
                  transform: Matrix4.translationValues(
                      _dragOffset.dx, _dragOffset.dy * 0.25, 0.0)
                    ..rotateZ(_dragOffset.dx / 600),
                  alignment: Alignment.bottomCenter,
                  child: Stack(
                    children: [
                      _buildPhotoCard(_currentItem!, _dragOffset.dx),
                      // KEEP label overlay
                      if (_dragOffset.dx > 40)
                        const Positioned(
                          top: 32,
                          left: 24,
                          child: _SwipeLabel(
                              text: 'KEEP', color: Color(0xFF10B981)),
                        ),
                      // TRASH label overlay
                      if (_dragOffset.dx < -40)
                        const Positioned(
                          top: 32,
                          right: 24,
                          child: _SwipeLabel(text: 'TRASH', color: Colors.red),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(GalleryMediaItem item, double dragX) {
    final isTopCard = _currentItem?.id == item.id;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // If video and top card, show interactive video player with seek bar
          if (item.isVideo && isTopCard)
            VideoCardPlayer(
              key: ValueKey('video_${item.id}'),
              item: item,
              thumbnailWidget:
                  _CachedMediaThumbnail(item: item, fit: BoxFit.contain),
            )
          else
            _CachedMediaThumbnail(item: item, fit: BoxFit.contain),

          // Color tint on swipe
          if (dragX > 40)
            Container(color: const Color(0xFF10B981).withValues(alpha: 0.18)),
          if (dragX < -40) Container(color: Colors.red.withValues(alpha: 0.18)),

          // Bottom info gradient (for photos only, as videos have playback bar)
          if (!item.isVideo)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75)
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.photo_camera_rounded,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(item.formattedSize,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    Text(
                      '${item.width}×${item.height}',
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),

          // Background cards video badge
          if (item.isVideo && !isTopCard)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Video',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Action Buttons ───────────────────────────────────────────────────────

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Trash button
          _RoundButton(
            icon: Icons.close_rounded,
            color: Colors.red,
            size: 64,
            onTap: _trash,
          ),
          // Undo
          _RoundButton(
            icon: Icons.undo_rounded,
            color: Colors.white38,
            size: 46,
            onTap: _undoStack.isEmpty ? null : _undo,
          ),
          // Keep button
          _RoundButton(
            icon: Icons.favorite_rounded,
            color: const Color(0xFF10B981),
            size: 64,
            onTap: _keep,
          ),
        ],
      ),
    );
  }

  // ── Done View ────────────────────────────────────────────────────────────

  bool get _isMonthGroup {
    final key = widget.group.yearMonthKey;
    return RegExp(r'^\d{4}-\d{2}$').hasMatch(key);
  }

  String get _completionTitle {
    if (_isMonthGroup) return 'Month Cleaned!';
    final lower = widget.group.label.toLowerCase();
    if (lower.contains('screenshot')) return 'Screenshots Cleaned!';
    if (lower.contains('whatsapp')) return 'WhatsApp Cleaned!';
    if (lower.contains('blurry')) return 'Blurry Cleaned!';
    if (lower.contains('similar') || lower.contains('duplicate')) return 'Duplicates Cleaned!';
    if (lower.contains('food')) return 'Food Photos Cleaned!';
    if (lower.contains('scenery') || lower.contains('view')) return 'Views & Scenery Cleaned!';
    if (lower.contains('doc') || lower.contains('receipt')) return 'Documents Cleaned!';
    return '${widget.group.label} Cleaned!';
  }

  String get _completionSubtitle {
    final total = widget.group.totalItems;
    if (_isMonthGroup) {
      return 'All $total photos & videos in ${widget.group.label} reviewed';
    }
    return 'All $total items in ${widget.group.label} successfully reviewed';
  }

  MonthGroup? _getNextIncompleteMonth(GalleryProvider provider) {
    if (!_isMonthGroup) return null;
    final groups = provider.monthGroups;
    final currentIndex = groups.indexWhere((g) => g.yearMonthKey == widget.group.yearMonthKey);
    if (currentIndex != -1 && currentIndex + 1 < groups.length) {
      for (int i = currentIndex + 1; i < groups.length; i++) {
        if (!groups[i].isComplete) return groups[i];
      }
      return groups[currentIndex + 1];
    }
    return null;
  }

  String _formatReclaimedBytes(int bytes) {
    if (bytes <= 0) return '0 MB';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  Widget _buildDoneView() {
    final provider = context.watch<GalleryProvider>();
    final group = widget.group;
    final nextMonth = _getNextIncompleteMonth(provider);

    int trashedBytes = group.totalTrashedBytes;
    int keptBytes = group.items
        .where((i) => i.decision == SwipeAction.keep)
        .fold(0, (sum, i) => sum + i.fileSize);

    if (trashedBytes == 0 && group.trashedCount > 0) {
      trashedBytes = group.trashedCount * 2800000;
    }
    if (keptBytes == 0 && group.keptCount > 0) {
      keptBytes = group.keptCount * 2800000;
    }

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Celebratory Iridescent Medal Hero Badge ──
            Stack(
              alignment: Alignment.center,
              children: [
                // Soft ambient neon glow behind the badge
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                        blurRadius: 45,
                        spreadRadius: 8,
                      ),
                      BoxShadow(
                        color: const Color(0xFFA78BFA).withValues(alpha: 0.3),
                        blurRadius: 55,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
                // Shimmering outer border ring
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFE0E7FF),
                        Color(0xFF38BDF8),
                        Color(0xFFA78BFA),
                        Color(0xFF34D399),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1E293B),
                            Color(0xFF0F172A),
                          ],
                        ),
                      ),
                      child: Center(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFFFFFF),
                              Color(0xFF67E8F9),
                              Color(0xFFA78BFA),
                            ],
                          ).createShader(bounds),
                          child: const Icon(
                            Icons.military_tech_rounded,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Title & Subtitle ──
            Text(
              _completionTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _completionSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 30),

            // ── Frosted Glassmorphism Stats Card ──
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.09),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Side-by-side Kept & Trashed pills
                      Row(
                        children: [
                          // Kept Pill
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF064E3B).withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color:
                                      const Color(0xFF10B981).withValues(alpha: 0.35),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981)
                                          .withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.photo_library_rounded,
                                      color: Color(0xFF34D399),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${group.keptCount} Kept',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatReclaimedBytes(keptBytes),
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.5),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Trashed Pill
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7F1D1D).withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color:
                                      const Color(0xFFEF4444).withValues(alpha: 0.35),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444)
                                          .withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.delete_rounded,
                                      color: Color(0xFFF87171),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${group.trashedCount} Trashed',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          group.trashedCount > 0
                                              ? '${_formatReclaimedBytes(trashedBytes)} to clean'
                                              : '0 MB',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.5),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Subtle Divider
                      Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                      const SizedBox(height: 14),
                      // Space Reclaimed Energy Banner
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            color: Color(0xFFFBBF24),
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            group.trashedCount > 0
                                ? '${_formatReclaimedBytes(trashedBytes)} Space Reclaimed!'
                                : '0 MB To Clean (All Kept)',
                            style: const TextStyle(
                              color: Color(0xFFF1F5F9),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Primary Action Button (Review & Empty Trash) ──
            if (provider.stagingBin.isNotEmpty || group.trashedCount > 0) ...[
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF06B6D4),
                      Color(0xFF10B981),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StagingBinScreen(),
                    ),
                  ),
                  child: Text(
                    'Review & Empty Trash (${provider.stagingBin.length} Items)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ── Secondary Action Button (Continue to Next Month OR Back to Dashboard) ──
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.2,
                ),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () {
                  if (nextMonth != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SwipeScreen(group: nextMonth),
                      ),
                    );
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  nextMonth != null
                      ? 'Continue to ${nextMonth.label}'
                      : (_isMonthGroup ? 'Back to Dashboard' : 'Done'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Tertiary Action (Review Again) ──
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _currentIndex = 0;
                  widget.group.currentIndex = 0;
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF94A3B8)),
              label: const Text(
                'Review Again',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ────────────────────────────────────────────────────────────────────────
  // Grid View Area
  // ────────────────────────────────────────────────────────────────────────

  Widget _buildGridView() {
    final remainingItems =
        widget.group.items.where((i) => i.decision == null).toList();
    if (remainingItems.isEmpty) return const SizedBox.shrink();

    // Group by Date (Day)
    final Map<String, List<GalleryMediaItem>> itemsByDate = {};
    for (final item in remainingItems) {
      final dateLabel = DateFormat('MMM d').format(item.dateTime);
      itemsByDate.putIfAbsent(dateLabel, () => []).add(item);
    }

    final slivers = <Widget>[];

    for (final entry in itemsByDate.entries) {
      final dateLabel = entry.key;
      final dateItems = entry.value;

      final allSelected = dateItems.every((i) => _selectedIds.contains(i.id));

      // Header
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (allSelected) {
                        for (final i in dateItems) {
                          _selectedIds.remove(i.id);
                        }
                      } else {
                        for (final i in dateItems) {
                          _selectedIds.add(i.id);
                        }
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Text('Select All', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(width: 6),
                        Icon(
                          allSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: allSelected ? const Color(0xFF7C3AED) : Colors.white54,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Grid
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = dateItems[index];
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
                  onLongPress: () {
                    HapticFeedback.heavyImpact();
                    showDialog(
                      context: context,
                      barrierColor: Colors.black.withValues(alpha: 0.9),
                      builder: (_) => UniversalPreviewDialog(
                          items: remainingItems,
                          initialIndex: remainingItems.indexOf(item)),
                    );
                  },
                  child: Container(
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
                          child: _CachedMediaThumbnail(item: item),
                        ),
                        if (item.isVideo)
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        if (isSelected)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Color(0xFF7C3AED),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
              childCount: dateItems.length,
            ),
          ),
        ),
      );
    }

    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 120)));

    return CustomScrollView(
      slivers: slivers,
    );
  }

  Widget _buildGridControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _bulkTrash,
              icon: const Icon(Icons.delete_rounded),
              label: Text('Trash (${_selectedIds.length})'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.15),
                foregroundColor: Colors.red,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _bulkKeep,
              icon: const Icon(Icons.check_rounded),
              label: Text('Keep (${_selectedIds.length})'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF10B981).withValues(alpha: 0.15),
                foregroundColor: const Color(0xFF10B981),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _bulkTrash() {
    if (_selectedIds.isEmpty) return;
    HapticFeedback.mediumImpact();

    final itemsToTrash =
        widget.group.items.where((i) => _selectedIds.contains(i.id)).toList();
    context.read<GalleryProvider>().bulkAddToStagingBin(itemsToTrash);

    setState(() {
      _selectedIds.clear();
      widget.group.recalculateCurrentIndex();
      _currentIndex = widget.group.currentIndex;
    });
  }

  void _bulkKeep() {
    if (_selectedIds.isEmpty) return;
    HapticFeedback.lightImpact();

    final itemsToKeep =
        widget.group.items.where((i) => _selectedIds.contains(i.id)).toList();
    context.read<GalleryProvider>().bulkKeepItems(itemsToKeep);

    setState(() {
      _selectedIds.clear();
      widget.group.recalculateCurrentIndex();
      _currentIndex = widget.group.currentIndex;
    });
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _SwipeLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _SwipeLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback? onTap;

  const _RoundButton({
    required this.icon,
    required this.color,
    required this.size,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: enabled
              ? color.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.04),
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled
                ? color.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? color : Colors.white12,
          size: size * 0.42,
        ),
      ),
    );
  }
}

// ── Top Preview Strip Thumbnail Slot ──────────────────────────────────────────

class _PreviewThumbnailSlot extends StatelessWidget {
  final GalleryMediaItem item;
  final bool isCenter;
  final bool isPast;
  final VoidCallback? onTap;

  const _PreviewThumbnailSlot({
    super.key,
    required this.item,
    required this.isCenter,
    required this.isPast,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = isCenter ? 52.0 : 44.0;
    final height = isCenter ? 62.0 : 52.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: width,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCenter
                ? const Color(0xFF6C63FF)
                : (isPast && item.decision == SwipeAction.trash
                    ? Colors.red.withValues(alpha: 0.6)
                    : (isPast && item.decision == SwipeAction.keep
                        ? const Color(0xFF10B981).withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.1))),
            width: isCenter ? 2.5 : 1.2,
          ),
          boxShadow: isCenter
              ? [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isCenter ? 7.5 : 8.8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail
              _CachedMediaThumbnail(
                item: item,
                size: 140,
                quality: 75,
                placeholderColor: const Color(0xFF222222),
              ),

              // Slight dim for non-center items to make center pop
              if (!isCenter)
                Container(
                  color: Colors.black.withValues(
                    alpha: isPast ? 0.35 : 0.25,
                  ),
                ),

              // Left side / Past item decision badge ("jo rhega and jo nhi rhega")
              if (isPast && item.decision != null)
                Positioned(
                  top: 3,
                  left: 3,
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: item.decision == SwipeAction.trash
                          ? Colors.red
                          : const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      item.decision == SwipeAction.trash
                          ? Icons.delete_rounded
                          : Icons.check_rounded,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),

              // Video indicator icon
              if (item.isVideo)
                Positioned(
                  bottom: 3,
                  right: 3,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CachedMediaThumbnail extends StatefulWidget {
  final GalleryMediaItem item;
  final int size;
  final int quality;
  final Color placeholderColor;
  final BoxFit fit;

  const _CachedMediaThumbnail({
    required this.item,
    this.size = 800,
    this.quality = 85,
    this.placeholderColor = const Color(0xFF252525),
    this.fit = BoxFit.cover,
  });

  @override
  State<_CachedMediaThumbnail> createState() => _CachedMediaThumbnailState();
}

class _CachedMediaThumbnailState extends State<_CachedMediaThumbnail> {
  Future<Uint8List?>? _future;

  @override
  void initState() {
    super.initState();
    _loadFuture();
  }

  @override
  void didUpdateWidget(covariant _CachedMediaThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _loadFuture();
    }
  }

  void _loadFuture() {
    _future = AssetEntity.fromId(widget.item.id).then(
      (entity) => entity?.thumbnailDataWithSize(
        ThumbnailSize.square(widget.size),
        quality: widget.quality,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.hasData && snap.data != null) {
          return Image.memory(
            snap.data!,
            fit: widget.fit,
            gaplessPlayback: true,
          );
        }
        return Container(
          color: widget.placeholderColor,
          child: widget.size > 200
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF6C63FF), strokeWidth: 2),
                )
              : null,
        );
      },
    );
  }
}
