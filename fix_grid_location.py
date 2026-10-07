import re

with open(r'lib/screens/swipe_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Extract the methods
methods_start = content.find('  // Grid View Area')
methods_start = content.rfind('  // ──', 0, methods_start)

# End of methods is before `class _SwipeLabel extends StatelessWidget {`
class_end = content.find('class _SwipeLabel extends StatelessWidget {')

if methods_start != -1 and class_end != -1:
    methods_code = content[methods_start:class_end]
    # Remove from current location
    content = content[:methods_start] + content[class_end:]
    
    # Insert before the end of _SwipeScreenState
    # Let's find the `}` right before `// ── Helpers`
    helpers_idx = content.find('// ── Helpers')
    if helpers_idx != -1:
        # find the last `}` before helpers
        brace_idx = content.rfind('}', 0, helpers_idx)
        if brace_idx != -1:
            content = content[:brace_idx] + methods_code + content[brace_idx:]

with open(r'lib/screens/swipe_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Moved grid methods into class")
