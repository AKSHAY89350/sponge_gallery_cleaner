import re

with open(r'lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Import
content = content.replace("import 'staging_bin_screen.dart';", "import 'staging_bin_screen.dart';\nimport 'large_files_menu_screen.dart';")

# Replace Large Files Quick card build
old_large = r'''            if \(provider\.largeFilesGroup != null\)
              _QuickActionCard\(
                title: 'Large Files',
                subtitle: '>\s?10MB',
                icon: Icons\.folder_zip_rounded,
                color: Colors\.orange,
                onTap: \(\) => _openGroup\(context, provider\.largeFilesGroup!\),
              \),'''

new_large = r'''            _QuickActionCard(
              title: 'Large Files',
              subtitle: '${provider.totalLargeFilesCount} items',
              icon: Icons.folder_zip_rounded,
              color: Colors.orange,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LargeFilesMenuScreen())),
            ),'''

content = re.sub(old_large, new_large, content)

with open(r'lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("HomeScreen updated to use LargeFilesMenuScreen")
