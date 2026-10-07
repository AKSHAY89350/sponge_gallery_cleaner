import re

with open(r'lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the specific syntax errors
content = content.replace('g.progress > 0 && g.progress < 1.0', 'g.currentIndex > 0 && g.currentIndex < g.items.length')
content = content.replace('visibleGroups.map((g) => _MonthCard', 'visibleGroups.map<Widget>((g) => _MonthCard')

with open(r'lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("fixed")
