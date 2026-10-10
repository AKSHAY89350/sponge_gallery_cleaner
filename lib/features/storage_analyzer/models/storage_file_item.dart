import 'package:flutter/material.dart';

enum StorageCategoryType {
  videos,
  photos,
  documents,
  apks,
  audio,
  whatsapp,
  screenshots,
  trash,
  systemOther,
}

class StorageFileItem {
  final String name;
  final String path;
  final int size; // bytes
  final DateTime modified;
  final String extension;
  final StorageCategoryType category;

  StorageFileItem({
    required this.name,
    required this.path,
    required this.size,
    required this.modified,
    required this.extension,
    required this.category,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class StorageCategorySummary {
  final StorageCategoryType type;
  final String title;
  final IconData icon;
  final Color color;
  final int totalBytes;
  final int itemCount;
  final List<StorageFileItem> items;

  const StorageCategorySummary({
    required this.type,
    required this.title,
    required this.icon,
    required this.color,
    required this.totalBytes,
    required this.itemCount,
    this.items = const [],
  });

  String get formattedSize {
    if (totalBytes < 1024) return '$totalBytes B';
    if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (totalBytes < 1024 * 1024 * 1024) {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  double percentageOf(int totalUsedBytes) {
    if (totalUsedBytes <= 0) return 0.0;
    return (totalBytes / totalUsedBytes).clamp(0.0, 1.0);
  }
}
