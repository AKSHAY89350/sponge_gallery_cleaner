import re

with open(r'lib/screens/swipe_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# find where "// ── Helpers" starts
# and remove one `}` above it.
helpers_line = -1
for i, line in enumerate(lines):
    if '// ── Helpers' in line or '// ───────────────────────────' in line and 'Helpers' in lines[i+1]:
        helpers_line = i
        break
    if 'class _SwipeLabel extends StatelessWidget {' in line:
        helpers_line = i
        break

if helpers_line != -1:
    for i in range(helpers_line - 1, -1, -1):
        if lines[i].strip() == '}':
            print("Removing extra brace at line", i+1)
            lines.pop(i)
            break

with open(r'lib/screens/swipe_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)
