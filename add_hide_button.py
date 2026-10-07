import re

with open(r'lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Pattern to replace
pattern = r'''             if \(_showAllMonths\) \{
               return provider\.monthGroups\.map\(\(g\) => _MonthCard\(group: g, onTap: \(\) => _openGroup\(context, g\)\)\)\.toList\(\);
             \} else \{'''

replacement = r'''             if (_showAllMonths) {
               final cards = provider.monthGroups.map<Widget>((g) => _MonthCard(group: g, onTap: () => _openGroup(context, g))).toList();
               cards.add(
                 Padding(
                   padding: const EdgeInsets.only(top: 8.0, bottom: 20),
                   child: TextButton(
                     onPressed: () => setState(() => _showAllMonths = false),
                     style: TextButton.styleFrom(
                       foregroundColor: const Color(0xFF6C63FF),
                     ),
                     child: const Text('Hide Months', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                   ),
                 )
               );
               return cards;
             } else {'''

content = re.sub(pattern, replacement, content)

with open(r'lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Added Hide Months button")
