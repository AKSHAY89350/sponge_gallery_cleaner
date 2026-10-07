import re

# 1. Update large_files_menu_screen.dart
with open(r'lib/screens/large_files_menu_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace(
    'final count = group?.items.length ?? 0;',
    'final count = group?.items.where((i) => i.decision == null).length ?? 0;'
)
with open(r'lib/screens/large_files_menu_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

# 2. Update gallery_provider.dart
with open(r'lib/providers/gallery_provider.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old_prop = r'''  int get totalLargeFilesCount => \(largeFiles10To100\?\.items\.length \?\? 0\) \+ 
                                  \(largeFiles100To500\?\.items\.length \?\? 0\) \+ 
                                  \(largeFiles500To1GB\?\.items\.length \?\? 0\) \+ 
                                  \(largeFilesOver1GB\?\.items\.length \?\? 0\);'''

new_prop = r'''  int get totalLargeFilesCount => 
      (largeFiles10To100?.items.where((i) => i.decision == null).length ?? 0) + 
      (largeFiles100To500?.items.where((i) => i.decision == null).length ?? 0) + 
      (largeFiles500To1GB?.items.where((i) => i.decision == null).length ?? 0) + 
      (largeFilesOver1GB?.items.where((i) => i.decision == null).length ?? 0);'''

content = re.sub(old_prop, new_prop, content)
with open(r'lib/providers/gallery_provider.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated item counts to reflect undecided items.")
