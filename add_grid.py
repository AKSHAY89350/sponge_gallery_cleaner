import re

with open(r'lib/screens/swipe_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add state variables
content = content.replace(
    '''  int _currentIndex = 0;
  final ScrollController _previewScrollController = ScrollController();''',
    '''  int _currentIndex = 0;
  final ScrollController _previewScrollController = ScrollController();
  
  bool _isGridView = false;
  final Set<String> _selectedIds = {};'''
)

# 2. Modify build
content = content.replace(
    '''        children: [
          _buildProgressBar(),
          if (!_isDone) _buildTopPreviewStrip(),
          Expanded(child: _isDone ? _buildDoneView() : _buildCardArea()),
          if (!_isDone) ...[_buildControls(), const SizedBox(height: 24)],
        ],''',
    '''        children: [
          _buildProgressBar(),
          if (!_isDone && !_isGridView) _buildTopPreviewStrip(),
          Expanded(child: _isDone ? _buildDoneView() : (_isGridView ? _buildGridView() : _buildCardArea())),
          if (!_isDone && !_isGridView) ...[_buildControls(), const SizedBox(height: 24)],
          if (!_isDone && _isGridView && _selectedIds.isNotEmpty) _buildGridControls(),
        ],'''
)

# 3. Add toggle to AppBar
appbar_pattern = r'''      actions: \[
        if \(trashCount > 0\)'''

appbar_replacement = r'''      actions: [
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
        if (trashCount > 0)'''

content = re.sub(appbar_pattern, appbar_replacement, content)


# 4. Append Grid View Methods at the end of the class
grid_methods = r'''
  // ────────────────────────────────────────────────────────────────────────
  // Grid View Area
  // ────────────────────────────────────────────────────────────────────────

  Widget _buildGridView() {
    final items = widget.group.items.skip(_currentIndex).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = _selectedIds.contains(item.id);

        return GestureDetector(
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
}'''

content = re.sub(r'\}$', grid_methods, content)

with open(r'lib/screens/swipe_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Added Grid View to Swipe Screen")
