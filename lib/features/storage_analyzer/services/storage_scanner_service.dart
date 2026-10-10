import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:sponge_gallery_cleaner/features/storage_analyzer/models/storage_file_item.dart';

class StorageScannerResult {
  final List<StorageFileItem> documents;
  final List<StorageFileItem> apks;
  final List<StorageFileItem> audioFiles;
  final List<StorageFileItem> archives;
  final bool hasDeepPermission;

  const StorageScannerResult({
    required this.documents,
    required this.apks,
    required this.audioFiles,
    required this.archives,
    required this.hasDeepPermission,
  });

  int get totalDocumentsBytes => documents.fold(0, (s, i) => s + i.size);
  int get totalApksBytes => apks.fold(0, (s, i) => s + i.size);
  int get totalAudioBytes => audioFiles.fold(0, (s, i) => s + i.size);
  int get totalArchivesBytes => archives.fold(0, (s, i) => s + i.size);
}

class StorageScannerService {
  static const Set<String> documentExtensions = {
    '.pdf',
    '.doc',
    '.docx',
    '.xls',
    '.xlsx',
    '.ppt',
    '.pptx',
    '.txt',
    '.rtf',
    '.epub',
    '.csv',
  };

  static const Set<String> apkExtensions = {
    '.apk',
    '.xapk',
    '.apks',
  };

  static const Set<String> audioExtensions = {
    '.mp3',
    '.m4a',
    '.wav',
    '.aac',
    '.flac',
    '.ogg',
    '.opus',
    '.wma',
  };

  static const Set<String> archiveExtensions = {
    '.zip',
    '.rar',
    '.7z',
    '.tar',
    '.gz',
  };

  /// Check if All Files Access (MANAGE_EXTERNAL_STORAGE) is granted on Android
  static Future<bool> hasAllFilesPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final status = await Permission.manageExternalStorage.status;
      if (status.isGranted) return true;
      // Fallback for older Android (<=10)
      return await Permission.storage.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Request All Files Access
  static Future<bool> requestAllFilesPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) return true;
      // If denied, open system settings so user can toggle toggle
      return await openAppSettings();
    } catch (_) {
      return false;
    }
  }

  /// Scan device directories for Documents, APKs, Audios, and Archives
  static Future<StorageScannerResult> scanStorage() async {
    final docs = <StorageFileItem>[];
    final apks = <StorageFileItem>[];
    final audios = <StorageFileItem>[];
    final archives = <StorageFileItem>[];

    final hasDeep = await hasAllFilesPermission();

    if (!Platform.isAndroid) {
      // Mock/fallback when running outside Android
      return StorageScannerResult(
        documents: docs,
        apks: apks,
        audioFiles: audios,
        archives: archives,
        hasDeepPermission: hasDeep,
      );
    }

    final targetDirs = <Directory>[];

    if (hasDeep) {
      // With deep access, scan public root
      final root = Directory('/storage/emulated/0');
      if (await root.exists()) {
        targetDirs.add(root);
      }
    } else {
      // Without deep access, scan accessible common folders
      final candidates = [
        Directory('/storage/emulated/0/Download'),
        Directory('/storage/emulated/0/Documents'),
        Directory('/storage/emulated/0/Document'),
        Directory('/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Documents'),
      ];
      for (final d in candidates) {
        if (await d.exists()) {
          targetDirs.add(d);
        }
      }
    }

    final visitedPaths = <String>{};

    for (final baseDir in targetDirs) {
      try {
        await _scanDirectory(
          dir: baseDir,
          documents: docs,
          apks: apks,
          audioFiles: audios,
          archives: archives,
          visitedPaths: visitedPaths,
          depth: 0,
          maxDepth: hasDeep ? 5 : 4,
        );
      } catch (e) {
        debugPrint('Error scanning dir ${baseDir.path}: $e');
      }
    }

    // Sort by largest file size first
    docs.sort((a, b) => b.size.compareTo(a.size));
    apks.sort((a, b) => b.size.compareTo(a.size));
    audios.sort((a, b) => b.size.compareTo(a.size));
    archives.sort((a, b) => b.size.compareTo(a.size));

    return StorageScannerResult(
      documents: docs,
      apks: apks,
      audioFiles: audios,
      archives: archives,
      hasDeepPermission: hasDeep,
    );
  }

  static Future<void> _scanDirectory({
    required Directory dir,
    required List<StorageFileItem> documents,
    required List<StorageFileItem> apks,
    required List<StorageFileItem> audioFiles,
    required List<StorageFileItem> archives,
    required Set<String> visitedPaths,
    required int depth,
    required int maxDepth,
  }) async {
    if (depth > maxDepth) return;

    try {
      final entries = dir.listSync(followLinks: false);

      for (final entity in entries) {
        final path = entity.path;
        final baseName = p.basename(path);

        // Skip hidden folders & system sandbox folders
        if (baseName.startsWith('.')) continue;

        if (entity is Directory) {
          final lower = baseName.toLowerCase();
          // Skip app sandboxes & media buckets already handled by PhotoManager
          if (lower == 'android' || lower == 'dcim' || lower == 'pictures') {
            continue;
          }
          if (visitedPaths.add(path)) {
            await _scanDirectory(
              dir: entity,
              documents: documents,
              apks: apks,
              audioFiles: audioFiles,
              archives: archives,
              visitedPaths: visitedPaths,
              depth: depth + 1,
              maxDepth: maxDepth,
            );
          }
        } else if (entity is File) {
          if (!visitedPaths.add(path)) continue;

          final ext = p.extension(path).toLowerCase();
          final stat = entity.statSync();
          final size = stat.size;

          if (documentExtensions.contains(ext)) {
            documents.add(StorageFileItem(
              name: baseName,
              path: path,
              size: size,
              modified: stat.modified,
              extension: ext,
              category: StorageCategoryType.documents,
            ));
          } else if (apkExtensions.contains(ext)) {
            apks.add(StorageFileItem(
              name: baseName,
              path: path,
              size: size,
              modified: stat.modified,
              extension: ext,
              category: StorageCategoryType.apks,
            ));
          } else if (audioExtensions.contains(ext)) {
            audioFiles.add(StorageFileItem(
              name: baseName,
              path: path,
              size: size,
              modified: stat.modified,
              extension: ext,
              category: StorageCategoryType.audio,
            ));
          } else if (archiveExtensions.contains(ext)) {
            archives.add(StorageFileItem(
              name: baseName,
              path: path,
              size: size,
              modified: stat.modified,
              extension: ext,
              category: StorageCategoryType.documents,
            ));
          }
        }
      }
    } catch (_) {
      // Permission restricted or folder access skipped safely
    }
  }

  /// Delete a file from disk
  static Future<bool> deleteFile(StorageFileItem item) async {
    try {
      final f = File(item.path);
      if (await f.exists()) {
        await f.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to delete file ${item.path}: $e');
      return false;
    }
  }
}
