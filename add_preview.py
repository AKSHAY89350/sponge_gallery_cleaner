import re

with open(r'lib/screens/similar_photos_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add onLongPress to GestureDetector
target = r'''                return GestureDetector\(
                    onTap: \(\) \{
                      setState\(\(\) \{
                        if \(isSelected\) \{
                          _selectedToKeepIds\.remove\(item\.id\);
                        \} else \{
                          _selectedToKeepIds\.add\(item\.id\);
                        \}
                      \}\);
                    \},
                    child: Container\('''

replacement = r'''                return GestureDetector(
                    onLongPress: () {
                      HapticFeedback.heavyImpact();
                      showDialog(
                        context: context,
                        barrierColor: Colors.black.withValues(alpha: 0.9),
                        builder: (_) => _PreviewDialog(item: item),
                      );
                    },
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedToKeepIds.remove(item.id);
                        } else {
                          _selectedToKeepIds.add(item.id);
                        }
                      });
                    },
                    child: Container('''
content = re.sub(target, replacement, content)

# Add _PreviewDialog class at the end of the file
dialog_code = r'''
class _PreviewDialog extends StatefulWidget {
  final GalleryMediaItem item;
  const _PreviewDialog({required this.item});

  @override
  State<_PreviewDialog> createState() => _PreviewDialogState();
}

class _PreviewDialogState extends State<_PreviewDialog> {
  Future<Uint8List?>? _future;

  @override
  void initState() {
    super.initState();
    _future = AssetEntity.fromId(widget.item.id).then((e) => e?.originBytes);
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
'''
content += dialog_code

# Also need to import flutter/services.dart for HapticFeedback if it's not imported.
if "import 'package:flutter/services.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:flutter/services.dart';")

with open(r'lib/screens/similar_photos_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Preview dialog added")
