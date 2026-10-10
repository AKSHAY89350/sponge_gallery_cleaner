import 'package:flutter/material.dart';
import 'package:sponge_gallery_cleaner/features/storage_analyzer/models/storage_file_item.dart';
import 'package:sponge_gallery_cleaner/features/storage_analyzer/services/storage_scanner_service.dart';

class CategoryFileListScreen extends StatefulWidget {
  final StorageCategorySummary category;
  final VoidCallback onDataChanged;

  const CategoryFileListScreen({
    super.key,
    required this.category,
    required this.onDataChanged,
  });

  @override
  State<CategoryFileListScreen> createState() => _CategoryFileListScreenState();
}

class _CategoryFileListScreenState extends State<CategoryFileListScreen> {
  late List<StorageFileItem> _items;
  final Set<String> _selectedPaths = {};
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.category.items);
  }

  int get _selectedBytes => _items
      .where((i) => _selectedPaths.contains(i.path))
      .fold(0, (sum, i) => sum + i.size);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<void> _deleteSelected() async {
    if (_selectedPaths.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1E26),
        title: const Text(
          'Delete Selected Files?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to permanently delete ${_selectedPaths.length} files (${_formatBytes(_selectedBytes)}) from your device storage? This cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    final pathsToDelete = List<String>.from(_selectedPaths);
    int deletedCount = 0;

    for (final path in pathsToDelete) {
      final itemIndex = _items.indexWhere((it) => it.path == path);
      if (itemIndex != -1) {
        final item = _items[itemIndex];
        final ok = await StorageScannerService.deleteFile(item);
        if (ok) {
          deletedCount++;
          _items.removeAt(itemIndex);
          _selectedPaths.remove(path);
        }
      }
    }

    widget.onDataChanged();

    if (mounted) {
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF16181F),
          content: Text(
            'Successfully deleted $deletedCount files.',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  Future<void> _deleteSingleItem(StorageFileItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1E26),
        title: const Text(
          'Delete File?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Permanently delete "${item.name}" (${item.formattedSize})? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await StorageScannerService.deleteFile(item);
    if (ok) {
      setState(() {
        _items.removeWhere((it) => it.path == item.path);
        _selectedPaths.remove(item.path);
      });
      widget.onDataChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16181F),
            content: Text(
              'Deleted ${item.name}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.category.color;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: const Color(0xFF13151A),
        elevation: 0,
        title: Row(
          children: [
            Icon(widget.category.icon, color: themeColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.category.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedPaths.length == _items.length) {
                    _selectedPaths.clear();
                  } else {
                    _selectedPaths.addAll(_items.map((i) => i.path));
                  }
                });
              },
              child: Text(
                _selectedPaths.length == _items.length ? 'Deselect All' : 'Select All',
                style: TextStyle(color: themeColor, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: _items.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open_rounded, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text(
                    'No files in this category',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  color: const Color(0xFF16181F),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_items.length} files found',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        'Total: ${_formatBytes(_items.fold(0, (s, i) => s + i.size))}',
                        style: TextStyle(
                          color: themeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final isSelected = _selectedPaths.contains(item.path);

                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedPaths.remove(item.path);
                            } else {
                              _selectedPaths.add(item.path);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16181F),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? themeColor : Colors.white10,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                activeColor: themeColor,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedPaths.add(item.path);
                                    } else {
                                      _selectedPaths.remove(item.path);
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.formattedSize} • ${item.modified.year}-${item.modified.month.toString().padLeft(2, '0')}-${item.modified.day.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.path,
                                      style: const TextStyle(
                                        color: Colors.white30,
                                        fontSize: 10,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.redAccent, size: 22),
                                onPressed: () => _deleteSingleItem(item),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_selectedPaths.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    decoration: const BoxDecoration(
                      color: Color(0xFF13151A),
                      border: Border(top: BorderSide(color: Colors.white10)),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${_selectedPaths.length} items selected',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Total: ${_formatBytes(_selectedBytes)}',
                                  style: TextStyle(
                                    color: themeColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isDeleting ? null : _deleteSelected,
                            icon: const Icon(Icons.delete_forever_rounded, size: 20),
                            label: Text(_isDeleting ? 'Deleting...' : 'Delete'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
