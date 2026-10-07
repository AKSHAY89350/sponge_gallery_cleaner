import re

with open(r'lib/screens/swipe_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add _previewScrollController
content = content.replace(
    'class _SwipeScreenState extends State<SwipeScreen> {\n  int _currentIndex = 0;',
    'class _SwipeScreenState extends State<SwipeScreen> {\n  int _currentIndex = 0;\n  final ScrollController _previewScrollController = ScrollController();\n'
)

# 2. Add _scrollToCurrent()
scroll_logic = '''
  void _scrollToCurrent() {
    if (!_previewScrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_previewScrollController.hasClients) return;
      final itemWidth = 52.0; 
      final screenWidth = MediaQuery.of(context).size.width;
      final targetOffset = (_currentIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
      
      _previewScrollController.animateTo(
        targetOffset.clamp(0.0, _previewScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }
'''
content = content.replace(
    'void _jumpToIndex(int targetIndex) {',
    scroll_logic + '\n  void _jumpToIndex(int targetIndex) {'
)

# 3. Call _scrollToCurrent in state changes
# _jumpToIndex
content = content.replace(
    '_dragOffset = Offset.zero;\n    });\n  }',
    '_dragOffset = Offset.zero;\n    });\n    _scrollToCurrent();\n  }'
)
# _nextItem
content = content.replace(
    '_dragOffset = Offset.zero;\n      _swipeDirection = null;\n    });\n  }',
    '_dragOffset = Offset.zero;\n      _swipeDirection = null;\n    });\n    _scrollToCurrent();\n  }'
)
# _undo
content = content.replace(
    '_currentIndex--;\n      widget.group.currentIndex = _currentIndex;\n    });\n  }',
    '_currentIndex--;\n      widget.group.currentIndex = _currentIndex;\n    });\n    _scrollToCurrent();\n  }'
)

# 4. Replace _buildTopPreviewStrip
strip_pattern = r'Widget _buildTopPreviewStrip\(\) \{[\s\S]*?    \);\n  \}'

new_strip = '''Widget _buildTopPreviewStrip() {
    final items = widget.group.items;
    final total = items.length;
    if (total == 0) return const SizedBox.shrink();

    return Container(
      height: 80,
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ListView.builder(
        controller: _previewScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: total,
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width / 2 - 26, 
        ),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final item = items[index];
          final isCenter = index == _currentIndex;
          final isPast = index < _currentIndex;

          return Center(
            child: _PreviewThumbnailSlot(
              key: ValueKey('preview_${item.id}_$index'),
              item: item,
              isCenter: isCenter,
              isPast: isPast,
              onTap: () => _jumpToIndex(index),
            ),
          );
        },
      ),
    );
  }'''

content = re.sub(strip_pattern, new_strip, content)

with open(r'lib/screens/swipe_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated swipe_screen.dart")
