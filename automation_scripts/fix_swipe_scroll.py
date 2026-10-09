import re

swipe_path = 'lib/features/media_cleaners/swipe_screen.dart'
with open(swipe_path, 'r', encoding='utf-8') as f:
    swipe_content = f.read()

# Fix initState
target_init = """  @override
  void initState() {
    super.initState();
    // Resume from saved progress
    _currentIndex = widget.group.currentIndex;
  }"""

replacement_init = """  @override
  void initState() {
    super.initState();
    // Resume from saved progress
    _currentIndex = widget.group.currentIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrent();
    });
  }"""

swipe_content = swipe_content.replace(target_init, replacement_init)

# Fix _scrollToCurrent
target_scroll = """  void _scrollToCurrent() {
    if (!_previewScrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_previewScrollController.hasClients) return;
      final itemWidth = 52.0;
      final screenWidth = MediaQuery.of(context).size.width;
      final targetOffset =
          (_currentIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);

      _previewScrollController.animateTo(
        targetOffset.clamp(
            0.0, _previewScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }"""

replacement_scroll = """  void _scrollToCurrent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_previewScrollController.hasClients) return;
      final targetOffset = _currentIndex * 52.0;
      
      _previewScrollController.animateTo(
        targetOffset.clamp(0.0, _previewScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }"""

swipe_content = swipe_content.replace(target_scroll, replacement_scroll)

with open(swipe_path, 'w', encoding='utf-8') as f:
    f.write(swipe_content)

print("Fixed swipe_screen scroll logic")
