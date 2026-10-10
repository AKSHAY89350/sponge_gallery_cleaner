import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AiScanEngine {
  none,
  face,
  scene,
}

/// Double-Ended Work Stealing Controller for Bidirectional Scanning (Head + Tail)
class BidirectionalScanController<T> {
  final List<T> items;
  int _headIndex = 0;
  late int _tailIndex;
  bool _isCancelled = false;

  BidirectionalScanController(this.items) {
    _tailIndex = items.length - 1;
  }

  bool get isCompleted => _isCancelled || _headIndex > _tailIndex;
  int get remaining => (_tailIndex - _headIndex + 1).clamp(0, items.length);

  void cancel() {
    _isCancelled = true;
  }

  /// Atomically claim the next item from the head (newest photos)
  T? claimNextHead() {
    if (isCompleted) return null;
    final item = items[_headIndex];
    _headIndex++;
    return item;
  }

  /// Atomically claim the next item from the tail (oldest photos)
  T? claimNextTail() {
    if (isCompleted) return null;
    final item = items[_tailIndex];
    _tailIndex--;
    return item;
  }
}

/// Central Coordinator for AI Scanning Engines:
/// 1. Mutual Exclusion: Guarantees only 1 AI engine actively runs at a time (e.g. pauses Face scan if Scene scan starts).
/// 2. Concurrency Limit = 2: Coordinates exactly 2 bidirectional workers (Head + Tail) within the active engine.
/// 3. Cross-Engine Smart Skipping: Shares detected documents and reviewed items so other engines skip them with 0ms overhead.
class AiScanCoordinator {
  static final AiScanCoordinator instance = AiScanCoordinator._internal();
  AiScanCoordinator._internal();

  AiScanEngine _currentActiveEngine = AiScanEngine.none;
  AiScanEngine get currentActiveEngine => _currentActiveEngine;

  final Set<String> _documentIds = {};
  final Set<String> _reviewedIds = {};
  bool _isInitialized = false;

  /// Load cached smart skipping indices from persistent storage
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final docs = prefs.getStringList('scene_document_ids') ?? [];
      _documentIds.addAll(docs);
      _isInitialized = true;
    } catch (e) {
      debugPrint('AiScanCoordinator initialize error: $e');
    }
  }

  /// Request engine lock. Pauses any currently running conflicting AI engine.
  void requestExclusiveEngine(AiScanEngine engine, {VoidCallback? onConflictPause}) {
    if (_currentActiveEngine != AiScanEngine.none && _currentActiveEngine != engine) {
      onConflictPause?.call();
    }
    _currentActiveEngine = engine;
  }

  /// Release engine lock when scan finishes or pauses
  void releaseEngine(AiScanEngine engine) {
    if (_currentActiveEngine == engine) {
      _currentActiveEngine = AiScanEngine.none;
    }
  }

  // --- Cross-Engine Smart Skipping Cache ---

  /// Mark an image as a Document/Receipt so Face Detector skips it immediately
  void markDocument(String id) {
    _documentIds.add(id);
  }

  /// Check if image was identified as a Document/Receipt
  bool isDocument(String id) {
    return _documentIds.contains(id);
  }

  /// Mark an image as reviewed (kept or trashed) by the user
  void markReviewed(String id) {
    _reviewedIds.add(id);
  }

  /// Check if image was already reviewed by the user
  bool isReviewed(String id) {
    return _reviewedIds.contains(id);
  }

  /// Clean up deleted items from skipping indices
  void onItemsDeleted(List<String> ids) {
    _documentIds.removeAll(ids);
    _reviewedIds.removeAll(ids);
  }
}
