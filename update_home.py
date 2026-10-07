import re

with open(r'lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add _showAllMonths state
content = content.replace(
    'class _HomeScreenState extends State<HomeScreen> {\n  @override\n  void initState() {',
    'class _HomeScreenState extends State<HomeScreen> {\n  bool _showAllMonths = false;\n\n  @override\n  void initState() {'
)

# Replace the monthGroups mapping logic in _buildGroupList
list_pattern = r'''        if \(provider\.monthGroups\.isEmpty\)
          const Padding\(
            padding: EdgeInsets\.only\(top: 20\),
            child: Center\(
              child: Text\('No photos found',
                  style: TextStyle\(color: Colors\.white38\)\),
            \),
          \)
        else
          \.\.\.provider\.monthGroups
              \.map\(\(g\) => _MonthCard\(group: g, onTap: \(\) => _openGroup\(context, g\)\)\),'''

list_replacement = r'''        if (provider.monthGroups.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Center(
              child: Text('No photos found',
                  style: TextStyle(color: Colors.white38)),
            ),
          )
        else
          ...(() {
             if (_showAllMonths) {
               return provider.monthGroups.map((g) => _MonthCard(group: g, onTap: () => _openGroup(context, g))).toList();
             } else {
               final visibleGroups = <MonthGroup>[];
               if (provider.monthGroups.isNotEmpty) {
                 visibleGroups.add(provider.monthGroups.first);
               }
               for (var i = 1; i < provider.monthGroups.length; i++) {
                 final g = provider.monthGroups[i];
                 if (g.currentIndex > 0 && g.currentIndex < g.items.length) {
                   visibleGroups.add(g);
                 }
               }
               
               final cards = visibleGroups.map<Widget>((g) => _MonthCard(group: g, onTap: () => _openGroup(context, g))).toList();
               
               if (provider.monthGroups.length > visibleGroups.length) {
                 cards.add(
                   Padding(
                     padding: const EdgeInsets.only(top: 8.0, bottom: 20),
                     child: TextButton(
                       onPressed: () => setState(() => _showAllMonths = true),
                       style: TextButton.styleFrom(
                         foregroundColor: const Color(0xFF6C63FF),
                       ),
                       child: const Text('View All Months', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                     ),
                   )
                 );
               }
               return cards;
             }
          })(),

          if (_showAllMonths && provider.isBackgroundLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                   children: [
                      CircularProgressIndicator(color: Color(0xFF6C63FF), strokeWidth: 2),
                      SizedBox(height: 12),
                      Text("Loading older months in background...", style: TextStyle(color: Colors.white54, fontSize: 13)),
                   ]
                )
              )
            ),'''

content = re.sub(list_pattern, list_replacement, content)

with open(r'lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("home_screen updated")

