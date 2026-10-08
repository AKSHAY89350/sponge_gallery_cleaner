import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:sponge_gallery_cleaner/features/gallery_core/models/gallery_media_item.dart';

class VideoCardPlayer extends StatefulWidget {
  final GalleryMediaItem item;
  final Widget thumbnailWidget;

  const VideoCardPlayer({
    super.key,
    required this.item,
    required this.thumbnailWidget,
  });

  @override
  State<VideoCardPlayer> createState() => _VideoCardPlayerState();
}

class _VideoCardPlayerState extends State<VideoCardPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _showControls = true;
  bool _isDraggingSlider = false;
  double _sliderValue = 0.0;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    if (_controller != null) {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
      setState(() {});
      return;
    }

    setState(() => _isLoading = true);
    try {
      final entity = await AssetEntity.fromId(widget.item.id);
      if (entity == null) return;
      final file = await entity.file;
      if (file == null) return;

      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      controller.addListener(() {
        if (mounted && !_isDraggingSlider) {
          setState(() {
            _sliderValue = controller.value.position.inMilliseconds.toDouble();
          });
        }
      });
      await controller.play();

      if (mounted) {
        setState(() {
          _controller = controller;
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to play video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      final hours = duration.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void _seekBy(int seconds) {
    if (_controller == null || !_isInitialized) return;
    final current = _controller!.value.position;
    final target = current + Duration(seconds: seconds);
    final total = _controller!.value.duration;
    if (target < Duration.zero) {
      _controller!.seekTo(Duration.zero);
    } else if (target > total) {
      _controller!.seekTo(total);
    } else {
      _controller!.seekTo(target);
    }
  }

  void _openFullScreen(BuildContext context) {
    if (_controller == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenVideoPlayer(
          controller: _controller!,
          item: widget.item,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Stack(
        fit: StackFit.expand,
        children: [
          widget.thumbnailWidget,
          // Dark tint
          Container(color: Colors.black.withValues(alpha: 0.3)),
          // Center Play Button
          Center(
            child: GestureDetector(
              onTap: _initializePlayer,
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(18),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
              ),
            ),
          ),
          // Tap hint
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Tap to play video',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final duration = _controller!.value.duration;
    final position = _controller!.value.position;
    final isPlaying = _controller!.value.isPlaying;
    final maxMs = duration.inMilliseconds.toDouble();

    return GestureDetector(
      onTap: () {
        setState(() => _showControls = !_showControls);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video surface
          Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),

          // Controls overlay
          if (_showControls) ...[
            Container(color: Colors.black.withValues(alpha: 0.35)),
            // Center Play / Pause and skip buttons
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 34,
                    icon: const Icon(Icons.replay_10_rounded,
                        color: Colors.white),
                    onPressed: () => _seekBy(-10),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      if (isPlaying) {
                        _controller!.pause();
                      } else {
                        _controller!.play();
                      }
                      setState(() {});
                    },
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6C63FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    iconSize: 34,
                    icon: const Icon(Icons.forward_10_rounded,
                        color: Colors.white),
                    onPressed: () => _seekBy(10),
                  ),
                ],
              ),
            ),

            // Top right: Fullscreen button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.fullscreen_rounded,
                    color: Colors.white, size: 28),
                onPressed: () => _openFullScreen(context),
              ),
            ),

            // Bottom Seek Bar / Scrubber (jump to any minute/second)
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (_) {},
                onPanUpdate: (_) {},
                onPanEnd: (_) {},
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Slider
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          activeTrackColor: const Color(0xFF6C63FF),
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Colors.white,
                          overlayColor:
                              const Color(0xFF6C63FF).withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value:
                              _sliderValue.clamp(0.0, maxMs > 0 ? maxMs : 1.0),
                          min: 0.0,
                          max: maxMs > 0 ? maxMs : 1.0,
                          onChangeStart: (val) {
                            _isDraggingSlider = true;
                          },
                          onChanged: (val) {
                            setState(() {
                              _sliderValue = val;
                            });
                          },
                          onChangeEnd: (val) {
                            _isDraggingSlider = false;
                            _controller!
                                .seekTo(Duration(milliseconds: val.toInt()));
                          },
                        ),
                      ),
                      // Timestamp row (minute : second)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: const TextStyle(
                                color: Colors.white54,
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
            ),
          ],
        ],
      ),
    );
  }
}

// ── Fullscreen Video Player Modal ─────────────────────────────────────────────

class _FullScreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final GalleryMediaItem item;

  const _FullScreenVideoPlayer({
    required this.controller,
    required this.item,
  });

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  bool _showControls = true;
  bool _isDragging = false;
  double _sliderValue = 0.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onPositionChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPositionChanged);
    super.dispose();
  }

  void _onPositionChanged() {
    if (mounted && !_isDragging) {
      setState(() {
        _sliderValue =
            widget.controller.value.position.inMilliseconds.toDouble();
      });
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      final hours = duration.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void _seekBy(int seconds) {
    final current = widget.controller.value.position;
    final target = current + Duration(seconds: seconds);
    final total = widget.controller.value.duration;
    if (target < Duration.zero) {
      widget.controller.seekTo(Duration.zero);
    } else if (target > total) {
      widget.controller.seekTo(total);
    } else {
      widget.controller.seekTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.controller.value.duration;
    final position = widget.controller.value.position;
    final isPlaying = widget.controller.value.isPlaying;
    final maxMs = duration.inMilliseconds.toDouble();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => setState(() => _showControls = !_showControls),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: widget.controller.value.aspectRatio,
                  child: VideoPlayer(widget.controller),
                ),
              ),
              if (_showControls) ...[
                // Back button
                Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // Center Play / Pause & Seek
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 42,
                        icon: const Icon(Icons.replay_10_rounded,
                            color: Colors.white),
                        onPressed: () => _seekBy(-10),
                      ),
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: () {
                          if (isPlaying) {
                            widget.controller.pause();
                          } else {
                            widget.controller.play();
                          }
                          setState(() {});
                        },
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: const BoxDecoration(
                            color: Color(0xFF6C63FF),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        iconSize: 42,
                        icon: const Icon(Icons.forward_10_rounded,
                            color: Colors.white),
                        onPressed: () => _seekBy(10),
                      ),
                    ],
                  ),
                ),

                // Bottom Scrub Bar
                Positioned(
                  bottom: 24,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 7),
                            activeTrackColor: const Color(0xFF6C63FF),
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            value: _sliderValue.clamp(
                                0.0, maxMs > 0 ? maxMs : 1.0),
                            min: 0.0,
                            max: maxMs > 0 ? maxMs : 1.0,
                            onChangeStart: (_) => _isDragging = true,
                            onChanged: (val) =>
                                setState(() => _sliderValue = val),
                            onChangeEnd: (val) {
                              _isDragging = false;
                              widget.controller
                                  .seekTo(Duration(milliseconds: val.toInt()));
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: const TextStyle(color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
