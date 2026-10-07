import re

with open(r'lib/screens/swipe_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Fix _advance()
old_advance = r'''  void _advance\(\) \{
    setState\(\(\) \{
      widget\.group\.currentIndex = _currentIndex \+ 1;
      _currentIndex\+\+;
      _dragOffset = Offset\.zero;
    \}\);
    _scrollToCurrent\(\);
  \}'''

new_advance = r'''  void _advance() {
    setState(() {
      _dragOffset = Offset.zero;
      _currentIndex++;
      // Skip over items that already have a decision
      while (_currentIndex < widget.group.items.length && widget.group.items[_currentIndex].decision != null) {
        _currentIndex++;
      }
      widget.group.currentIndex = _currentIndex;
    });
    _scrollToCurrent();
  }'''

content = re.sub(old_advance, new_advance, content)

# 2. Fix _undo()
old_undo = r'''  void _undo\(\) \{
    if \(_undoStack\.isEmpty\) return;
    HapticFeedback\.selectionClick\(\);
    final last = _undoStack\.removeLast\(\);
    context\.read<GalleryProvider>\(\)\.removeFromStagingBin\(last\);
    setState\(\(\) \{
      if \(_currentIndex > 0\) \{
        _currentIndex--;
        widget\.group\.currentIndex = _currentIndex;
      \}
    \}\);
  \}'''

new_undo = r'''  void _undo() {
    if (_undoStack.isEmpty) return;
    HapticFeedback.selectionClick();
    final last = _undoStack.removeLast();
    context.read<GalleryProvider>().removeFromStagingBin(last);
    
    setState(() {
      final lastIndex = widget.group.items.indexWhere((i) => i.id == last.id);
      if (lastIndex != -1) {
        _currentIndex = lastIndex;
        widget.group.currentIndex = lastIndex;
      }
    });
    _scrollToCurrent();
  }'''

content = re.sub(old_undo, new_undo, content)

with open(r'lib/screens/swipe_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed state navigation bugs")
