import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/gallery_media_item.dart';
import '../providers/gallery_provider.dart';
import '../widgets/video_card_player.dart';
import 'staging_bin_screen.dart';

class SwipeScreen extends StatefulWidget {
  final MonthGroup group;
  const SwipeScreen({super.key, required this.group});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  int _currentIndex = 0;
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
      widget.group.currentIndex = _currentIndex + 1;
      _currentIndex++;
      _dragOffset = Offset.zero;
    });
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    HapticFeedback.selectionClick();
    final last = _undoStack.removeLast();
    context.read<GalleryProvider>().removeFromStagingBin(last);
    setState(() {
      if (_currentIndex > 0) {
        _currentIndex--;
        widget.group.currentIndex = _currentIndex;
      }
    });
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
          Expanded(child: _isDone ? _buildDoneView() : _buildCardArea()),
          if (!_isDone) ...[_buildControls(), const SizedBox(height: 24)],
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
            '$_currentIndex / ${widget.group.totalItems}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
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
        : _currentIndex / widget.group.totalItems;
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

  Widget _buildThumbnail(GalleryMediaItem item) {
    return FutureBuilder<Uint8List?>(
      future: AssetEntity.fromId(item.id).then(
        (entity) => entity?.thumbnailDataWithSize(
          const ThumbnailSize(800, 800),
          quality: 85,
        ),
      ),
      builder: (ctx, snap) {
        if (snap.hasData && snap.data != null) {
          return Image.memory(
            snap.data!,
            fit: BoxFit.cover,
          );
        }
        return Container(
          color: const Color(0xFF252525),
          child: const Center(
            child: CircularProgressIndicator(
                color: Color(0xFF6C63FF), strokeWidth: 2),
          ),
        );
      },
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
              thumbnailWidget: _buildThumbnail(item),
            )
          else
            _buildThumbnail(item),

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
            const SizedBox(height: 14),
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
