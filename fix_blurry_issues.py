import re

with open(r'lib/screens/blurry_photos_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace floatingActionButton for selection
fab_target = """      floatingActionButton: _selectedIds.isNotEmpty 
          ? FloatingActionButton.extended(
              onPressed: () {
                HapticFeedback.heavyImpact();
                final itemsToTrash = blurryItems.where((i) => _selectedIds.contains(i.id)).toList();
                provider.bulkAddToStagingBin(itemsToTrash);
                setState(() {
                  _selectedIds.clear();
                });
              },
              backgroundColor: Colors.redAccent,
              icon: const Icon(Icons.delete_rounded, color: Colors.white),
              label: Text('Trash Selected (${_selectedIds.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )"""

fab_replacement = """      floatingActionButton: _selectedIds.isNotEmpty 
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton.extended(
                    heroTag: 'keep_btn',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      final itemsToKeep = blurryItems.where((i) => _selectedIds.contains(i.id)).toList();
                      provider.bulkKeepItems(itemsToKeep);
                      setState(() {
                        _selectedIds.clear();
                      });
                    },
                    backgroundColor: Colors.green,
                    icon: const Icon(Icons.favorite_rounded, color: Colors.white),
                    label: Text('Keep (${_selectedIds.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  FloatingActionButton.extended(
                    heroTag: 'trash_btn',
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      final itemsToTrash = blurryItems.where((i) => _selectedIds.contains(i.id)).toList();
                      provider.bulkAddToStagingBin(itemsToTrash);
                      setState(() {
                        _selectedIds.clear();
                      });
                    },
                    backgroundColor: Colors.redAccent,
                    icon: const Icon(Icons.delete_rounded, color: Colors.white),
                    label: Text('Trash (${_selectedIds.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )"""

content = content.replace(fab_target, fab_replacement)

# Replace _buildScanningIndicator
indicator_target = """    Widget _buildScanningIndicator(int scanned, int total) {
      final percent = total == 0 ? 0.0 : scanned / total;
      return Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            const Text('Analyzing Sharpness (AI)...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.white10,
              color: Colors.orangeAccent,
            ),
          ],
        ),
      );
    }"""

indicator_replacement = """    Widget _buildScanningIndicator(int scanned, int total) {
      final percent = total == 0 ? 0.0 : scanned / total;
      final percentText = (percent * 100).toStringAsFixed(0) + '%';
      return Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            const Text('Analyzing Sharpness (AI)...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$scanned / $total photos processed', style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 24,
                    backgroundColor: Colors.white10,
                    color: Colors.orangeAccent,
                  ),
                ),
                Text(percentText, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ]
            ),
          ],
        ),
      );
    }"""

content = content.replace(indicator_target, indicator_replacement)

with open(r'lib/screens/blurry_photos_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated blurry screen issues")
