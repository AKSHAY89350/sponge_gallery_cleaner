enum SwipeAction { keep, trash, move }

class GalleryMediaItem {
  final String id;
  final String path;
  final int dateTaken; // Epoch milliseconds
  final int fileSize; // Bytes
  final bool isVideo;
  final Duration? videoDuration;
  final int width;
  final int height;
  final String? mimeType;

  SwipeAction? decision;
  String? targetAlbumId;

  GalleryMediaItem({
    required this.id,
    required this.path,
    required this.dateTaken,
    required this.fileSize,
    required this.isVideo,
    this.videoDuration,
    required this.width,
    required this.height,
    this.mimeType,
    this.decision,
    this.targetAlbumId,
  });

  String get formattedSize {
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(dateTaken);
}

class MonthGroup {
  final String label; // e.g. "September 2026"
  final String yearMonthKey; // e.g. "2026-09"
  final List<GalleryMediaItem> items;
  int currentIndex;
  final bool isScreenshots;
  final bool isLargeFiles;

  MonthGroup({
    required this.label,
    required this.yearMonthKey,
    required this.items,
    this.currentIndex = 0,
    this.isScreenshots = false,
    this.isLargeFiles = false,
  });

  int get totalItems => items.length;
  void recalculateCurrentIndex() {
    final idx = items.indexWhere((i) => i.decision == null);
    if (idx != -1) {
      currentIndex = idx;
    } else if (items.isNotEmpty) {
      currentIndex = items.length;
    } else {
      currentIndex = 0;
    }
  }
  int get trashedCount =>
      items.where((i) => i.decision == SwipeAction.trash).length;
  int get keptCount =>
      items.where((i) => i.decision == SwipeAction.keep).length;
  double get progressPercent =>
      totalItems == 0 ? 0 : (trashedCount + keptCount) / totalItems;
  bool get isComplete =>
      totalItems > 0 && (trashedCount + keptCount) == totalItems;
  int get totalTrashedBytes => items
      .where((i) => i.decision == SwipeAction.trash)
      .fold(0, (sum, i) => sum + i.fileSize);
}

