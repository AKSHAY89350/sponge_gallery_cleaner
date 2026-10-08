import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/gallery_media_item.dart';
import '../providers/gallery_provider.dart';
import '../widgets/video_card_player.dart';
import 'staging_bin_screen.dart';
import 'package:intl/intl.dart';

class SwipeScreen extends StatefulWidget {
  final MonthGroup group;
  const SwipeScreen({super.key, required this.group});

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
  void initState() {
    super.initState();
    // Resume from saved progress
    _currentIndex = widget.group.currentIndex;
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
      while (_currentIndex < widget.group.items.length && widget.group.items[_currentIndex].decision != null) {
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
    if (!_previewScrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_previewScrollController.hasClients) return;
      final itemWidth = 52.0; 
      final screenWidth = MediaQuery.of(context).size.width;
      final targetOffset = (_currentIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
      
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
      body: Column(
        children: [
          _buildProgressBar(),
          if (!_isDone && !_isGridView) _buildTopPreviewStrip(),
          Expanded(child: _isDone ? _buildDoneView() : (_isGridView ? _buildGridView() : _buildCardArea())),
          if (!_isDone && !_isGridView) ...[_buildControls(), const SizedBox(height: 24)],
          if (!_isDone && _isGridView && _selectedIds.isNotEmpty) _buildGridControls(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    final trashCount = context.watch<GalleryProvider>().stagingBin.length;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
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
          icon: Icon(_isGridView ? Icons.view_carousel_rounded : Icons.grid_view_rounded),
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
    final progress = widget.group.totalItems == 0
        ? 0.0
        : widget.group.progressPercent;
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
                  child: _buildPhotoCard(
                      widget.group.items[_currentIndex + 2], 0),
                ),
              ),
            if (_currentIndex + 1 < widget.group.items.length)
              Positioned.fill(
                child: Transform.scale(
                  scale: 0.94,
                  child: _buildPhotoCard(
                      widget.group.items[_currentIndex + 1], 0),
                ),
              ),
            // Active draggable card
            if (_currentItem != null)
              Positioned.fill(
                child: Transform(
                  transform: Matrix4.translationValues(_dragOffset.dx, _dragOffset.dy * 0.25, 0.0)
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
                          child:
                              _SwipeLabel(text: 'TRASH', color: Colors.red),
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
              thumbnailWidget: _CachedMediaThumbnail(item: item, fit: BoxFit.contain),
            )
          else
            _CachedMediaThumbnail(item: item, fit: BoxFit.contain),

          // Color tint on swipe
          if (dragX > 40)
            Container(
                color: const Color(0xFF10B981).withValues(alpha: 0.18)),
          if (dragX < -40)
            Container(color: Colors.red.withValues(alpha: 0.18)),

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
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11),
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

  Widget _buildDoneView() {
    final provider = context.read<GalleryProvider>();
    final group = widget.group;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            const Text(
              'All Done!',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              'You reviewed all ${group.totalItems} items in\n${group.label}.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 15),
            ),
            const SizedBox(height: 36),
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatBadge(
                    label: 'Kept',
                    count: group.keptCount,
                    color: const Color(0xFF10B981)),
                const SizedBox(width: 16),
                _StatBadge(
                    label: 'Trashed',
                    count: group.trashedCount,
                    color: Colors.red),
              ],
            ),
            const SizedBox(height: 40),
            if (provider.stagingBin.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StagingBinScreen()),
                  ),
                  child: Text(
                      'Review Trash (${provider.stagingBin.length} items)'),
                ),
              ),
            TextButton(
              onPressed: () {
                setState(() {
                  _currentIndex = 0;
                  widget.group.currentIndex = 0;
                });
              },
              child: const Text('Review Again 🔄',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Home',
                  style: TextStyle(color: Color(0xFF6C63FF), fontSize: 15)),
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
    final remainingItems = widget.group.items.where((i) => i.decision == null).toList();
    if (remainingItems.isEmpty) return const SizedBox.shrink();

    // Group by Date (Day)
    final Map<String, List<GalleryMediaItem>> itemsByDate = {};
    for (final item in remainingItems) {
      final dateLabel = DateFormat('MMM d, yyyy').format(item.dateTime);
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
            padding: const EdgeInsets.fromLTRB(16, 24, 4, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateLabel, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(
                    allSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: allSelected ? const Color(0xFF6C63FF) : Colors.white54,
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (allSelected) {
                        for (final i in dateItems) _selectedIds.remove(i.id);
                      } else {
                        for (final i in dateItems) _selectedIds.add(i.id);
                      }
                    });
                  },
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
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = dateItems[index];
                final isSelected = _selectedIds.contains(item.id);

                return GestureDetector(
                  onLongPress: () {
                    HapticFeedback.heavyImpact();
                    showDialog(
                      context: context,
                      barrierColor: Colors.black.withValues(alpha: 0.9),
                      builder: (_) => _GridPreviewDialog(item: item),
                    );
                  },
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (isSelected) {
                        _selectedIds.remove(item.id);
                      } else {
                        _selectedIds.add(item.id);
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _CachedMediaThumbnail(item: item, size: 300, quality: 60),
                        if (item.isVideo)
                          const Positioned(
                            bottom: 4,
                            right: 4,
                            child: Icon(Icons.play_circle_fill, color: Colors.white, size: 20),
                          ),
                        if (isSelected)
                          Container(
                            color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                            child: const Center(
                              child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 32),
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

    // Bottom padding for controls
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 100)));

    return CustomScrollView(
      slivers: slivers,
    );
  }

  Widget _buildGridControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                foregroundColor: const Color(0xFF10B981),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    
    final itemsToTrash = widget.group.items.where((i) => _selectedIds.contains(i.id)).toList();
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
    
    final itemsToKeep = widget.group.items.where((i) => _selectedIds.contains(i.id)).toList();
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
          color: enabled ? color.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? color.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.08),
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

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatBadge(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('$count',
              style: TextStyle(
                  color: color, fontSize: 30, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label,
              style:
                  TextStyle(color: color.withValues(alpha: 0.7), fontSize: 13)),
        ],
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
    super.key,
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




class _GridPreviewDialog extends StatefulWidget {
  final GalleryMediaItem item;
  const _GridPreviewDialog({required this.item});

  @override
  State<_GridPreviewDialog> createState() => _GridPreviewDialogState();
}

class _GridPreviewDialogState extends State<_GridPreviewDialog> {
  Future<Uint8List?>? _future;

  @override
  void initState() {
    super.initState();
    _future = AssetEntity.fromId(widget.item.id).then((e) => e?.thumbnailDataWithSize(const ThumbnailSize.square(1024)));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: FutureBuilder<Uint8List?>(
                future: _future,
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }
                  if (snap.hasData && snap.data != null) {
                    return Image.memory(snap.data!, fit: BoxFit.contain);
                  }
                  return const Center(child: Icon(Icons.error, color: Colors.white));
                },
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

